//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_qc.sv
// Description: EVM Quiescence Counter (evm_qc)
//              Automatic activity watchdog that holds objections until
//              the system goes quiet for a specified number of cycles
// Source: EVM-specific feature (inspired by UVM drain_time but enhanced)
// Rationale: CRITICAL for embedded verification:
//            - Transactions may complete at unpredictable times
//            - Need automatic detection of "done" state
//            - Manual objection management error-prone
//            - Acts as watchdog to prevent early termination
// Author: EVM Contributors
// Date: 2026-03-29
//==============================================================================

//==============================================================================
// Class: evm_qc (Quiescence Counter)
// Description: Monitors activity and automatically manages test objections
//              Raises objection on first tick(), drops after quiet period
// Usage: 
//   - Driver/Monitor calls qc.tick() on each transaction
//   - QC auto-raises objection when activity detected
//   - QC auto-drops objection after quiescent_cycles of inactivity
//   - Test ends gracefully when all activity completes
//==============================================================================
class evm_qc extends evm_component;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    int quiescent_cycles = 100;  // Cycles of inactivity before done
    string objection_name = "qc"; // Objection identifier
    
    //==========================================================================
    // State
    //==========================================================================
    local int activity_counter = 0;
    local bit objection_raised = 0;
    local bit enabled = 1;
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int total_ticks = 0;
    int max_counter_value = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "qc", evm_component parent = null);
        super.new(name, parent);
        log_info($sformatf("Quiescence Counter created (threshold=%0d cycles)", 
                          quiescent_cycles), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // tick() - Called by drivers/monitors on each transaction/activity
    // Source: EVM-specific
    // Rationale: Simple API for components to signal activity
    //            Automatically raises objection on first tick
    //            Resets inactivity counter
    //==========================================================================
    function void tick();
        if (!enabled) return;
        
        total_ticks++;
        
        // Raise objection on first activity
        if (!objection_raised) begin
            evm_root::get().raise_objection(objection_name);
            objection_raised = 1;
            log_info("Activity detected - objection raised", EVM_HIGH);
        end
        
        // Reset inactivity counter
        activity_counter = 0;
        log_info($sformatf("Activity tick #%0d (counter reset)", total_ticks), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // reset() - Called on DUT reset
    // Source: EVM reset pattern
    // Rationale: Must clear state on reset
    //            Drops any pending objection
    //==========================================================================
    virtual task reset();
        super.reset();
        
        log_info("Quiescence Counter reset", EVM_MEDIUM);
        
        // Drop objection if raised
        if (objection_raised) begin
            evm_root::get().drop_objection(objection_name);
            objection_raised = 0;
        end
        
        // Reset counters
        activity_counter = 0;
        total_ticks = 0;
        max_counter_value = 0;
    endtask
    
    //==========================================================================
    // Main Phase - Monitor for quiescence
    // Source: EVM phasing
    // Rationale: Background task that counts inactive cycles
    //            Auto-drops objection after threshold reached
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        if (!enabled) begin
            log_info("Quiescence Counter disabled", EVM_MEDIUM);
            return;
        end
        
        log_info("Quiescence Counter monitoring started", EVM_MEDIUM);
        
        // Monitor loop
        forever begin
            // Wait one cycle
            #1ns;  // TODO: Should be configurable or use clock edge
            
            if (objection_raised) begin
                activity_counter++;
                
                // Track max for statistics
                if (activity_counter > max_counter_value) begin
                    max_counter_value = activity_counter;
                end
                
                // Check for quiescence
                if (activity_counter >= quiescent_cycles) begin
                    log_info($sformatf("Quiescence detected after %0d inactive cycles", 
                                      activity_counter), EVM_LOW);
                    
                    // Drop objection
                    evm_root::get().drop_objection(objection_name);
                    objection_raised = 0;
                    activity_counter = 0;
                    
                    log_info("Objection dropped - system quiescent", EVM_MEDIUM);
                end
            end
        end
    endtask
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    
    function void set_threshold(int cycles);
        quiescent_cycles = cycles;
        log_info($sformatf("Quiescence threshold set to %0d cycles", cycles), EVM_MEDIUM);
    endfunction
    
    function int get_threshold();
        return quiescent_cycles;
    endfunction
    
    function void enable();
        enabled = 1;
        log_info("Quiescence Counter enabled", EVM_MEDIUM);
    endfunction
    
    function void set_disabled();   // renamed: 'disable' is a SV keyword
        enabled = 0;
        log_info("Quiescence Counter disabled", EVM_MEDIUM);
    endfunction
    
    function bit is_enabled();
        return enabled;
    endfunction
    
    function bit is_active();
        return objection_raised;
    endfunction
    
    function int get_counter();
        return activity_counter;
    endfunction
    
    //==========================================================================
    // Report Phase - Print statistics
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        
        log_info("=========================================", EVM_LOW);
        log_info("   QUIESCENCE COUNTER STATISTICS", EVM_LOW);
        log_info("=========================================", EVM_LOW);
        log_info($sformatf("Total Activity Ticks:  %0d", total_ticks), EVM_LOW);
        log_info($sformatf("Quiescence Threshold:  %0d cycles", quiescent_cycles), EVM_LOW);
        log_info($sformatf("Max Inactive Count:    %0d cycles", max_counter_value), EVM_LOW);
        log_info($sformatf("Final State:           %s", 
                          objection_raised ? "ACTIVE" : "QUIESCENT"), EVM_LOW);
        log_info("=========================================", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_qc";
    endfunction
    
endclass : evm_qc
