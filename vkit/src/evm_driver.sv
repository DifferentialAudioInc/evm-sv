//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_driver
// Description: Parameterized base driver class for EVM
//              Uses virtual interface for driving signals
//              No config database - direct virtual interface assignment
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_driver #(type VIF) extends evm_component;
    
    //==========================================================================
    // Virtual Interface
    //==========================================================================
    VIF vif;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_driver", evm_component parent = null);
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
    // Driver Main Phase - Override in derived drivers
    //==========================================================================
    virtual task main_phase();
        if (vif == null) begin
            log_error("Virtual interface not set - cannot drive");
            return;
        end
        log_info("Driver main_phase started", EVM_LOW);
        // Override in derived class to drive interface
    endtask
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_driver";
    endfunction
    
endclass : evm_driver
