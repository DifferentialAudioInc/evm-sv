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

virtual class evm_monitor #(type VIF) extends evm_component;
    
    //==========================================================================
    // Virtual Interface
    //==========================================================================
    VIF vif;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_monitor", evm_component parent = null);
        super.new(name, parent);
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
    // Monitor Main Phase - Override in derived monitors
    //==========================================================================
    virtual task main_phase();
        if (vif == null) begin
            log_error("Virtual interface not set - cannot monitor");
            return;
        end
        log_info("Monitor main_phase started", EVM_LOW);
        // Override in derived class to monitor interface
    endtask
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_monitor";
    endfunction
    
endclass : evm_monitor
