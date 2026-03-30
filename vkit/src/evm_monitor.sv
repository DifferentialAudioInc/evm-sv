//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_monitor
// Description: Parameterized base monitor class for EVM
//              Uses virtual interface for signal monitoring
//              No config database - direct virtual interface assignment
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_monitor #(type VIF, type T = int) extends evm_component;
    
    //==========================================================================
    // Virtual Interface
    //==========================================================================
    VIF vif;
    
    //==========================================================================
    // Analysis Port - Broadcast collected transactions
    // Source: UVM pattern - all monitors have analysis_port
    // Rationale: Monitors MUST broadcast to multiple components:
    //            - Scoreboard needs transactions for checking
    //            - Coverage needs transactions for functional coverage
    //            - Checkers need transactions for protocol verification
    //            This is THE standard way monitors communicate in verification
    // Usage: In monitor: analysis_port.write(collected_transaction);
    //        In env: scoreboard.analysis_imp.connect(monitor.analysis_port);
    // UVM Equivalent: uvm_analysis_port#(transaction_type) analysis_port
    //==========================================================================
    evm_analysis_port#(T) analysis_port;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_monitor", evm_component parent = null);
        super.new(name, parent);
        // Create analysis port
        analysis_port = new({name, ".analysis_port"}, this);
    endfunction
    
    //==========================================================================
    // Set Virtual Interface - Called by agent or test
    //==========================================================================
    function void set_vif(VIF vif_handle);
        if (vif_handle == null) begin
            log_error("Attempting to set null virtual interface");
        end else begin
            this.vif = vif_handle;
            log_info("Virtual interface set", EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Monitor Run Phase - Continuous monitoring (override in derived monitors)
    // Source: Moved from main_phase to run_phase for continuous operation
    // Rationale: Monitors must run continuously during all test phases
    //            - Collect during reset, configure, main, shutdown
    //            - Prevents data loss during phase transitions
    //            - Essential for mid-sim reset support
    //==========================================================================
    virtual task run_phase();
        if (vif == null) begin
            log_error("Virtual interface not set - cannot monitor");
            return;
        end
        log_info("Monitor run_phase started - continuous monitoring active", EVM_LOW);
        
        // Fork reset event monitoring with collection
        fork
            begin
                // Monitor for reset events
                forever begin
                    @(reset_asserted);
                    on_reset_assert();
                    @(reset_deasserted);
                    on_reset_deassert();
                end
            end
            begin
                // Continuous monitoring loop
                // Override this in derived class
                // Default: do nothing (derived class must implement)
            end
        join_none
    endtask
    
    //==========================================================================
    // Reset Event Handlers - Override in derived monitors
    //==========================================================================
    
    // Handle reset assertion - pause monitoring
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("Monitor paused due to reset assertion", EVM_MEDIUM);
        // Derived class can flush partial transactions here
    endtask
    
    // Handle reset deassertion - resume monitoring  
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("Monitor resumed after reset deassertion", EVM_MEDIUM);
        // Derived class can reinitialize state here
    endtask
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_monitor";
    endfunction
    
endclass : evm_monitor
