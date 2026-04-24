//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_monitor
// Description: Parameterized base monitor class for EVM.
//              Uses virtual interface for signal monitoring.
//              No config database — direct virtual interface assignment.
//
// ── ANALYSIS PORT OWNERSHIP ─────────────────────────────────────────────────
// evm_monitor creates analysis_port in its constructor, but evm_agent.build_phase()
// immediately replaces it with the agent's own analysis_port (port aliasing).
// After build_phase, monitor.analysis_port IS agent.analysis_port — same object.
//
// In derived monitors: call analysis_port.write(txn) as always.
// In env connect_phase: connect to agent.analysis_port, NOT monitor.analysis_port.
// ─────────────────────────────────────────────────────────────────────────────
//
// Author: Eric Dyer
// Date: 2026-03-05
// Updated: 2026-04-24 — analysis_port aliased to agent's port in build_phase
//
// API — Public Interface:
//   [evm_monitor#(VIF, T)] — virtual base class
//   analysis_port            — aliased to agent.analysis_port after build_phase
//   set_vif(vif_handle)      — set the virtual interface handle
//   run_phase()              — forks reset event monitor; override for collection
//   on_reset_assert()        — called when reset asserted; pause collection
//   on_reset_deassert()      — called when reset deasserted; resume collection
//==============================================================================

virtual class evm_monitor #(type VIF, type T = int) extends evm_component;
    
    //==========================================================================
    // Virtual Interface
    //==========================================================================
    VIF vif;
    
    //==========================================================================
    // Analysis Port — broadcast collected transactions
    // Created here in the monitor constructor, then immediately ALIASED to
    // the agent's analysis_port in evm_agent.build_phase() (port aliasing).
    //
    // In derived monitor code:  analysis_port.write(txn);   ← unchanged
    // In env connect_phase:     agent.analysis_port.connect(sb.analysis_imp.get_mailbox());
    //                           ← connect to AGENT, not to monitor
    //
    // Protocol-specific extra ports (ap_write, ap_read, ap_err, etc.) are
    // declared in derived monitors and remain there — accessed via get_monitor().
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
