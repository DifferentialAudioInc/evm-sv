//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_rst_driver
// Description: Reset control driver for EVM
//              Manages multiple reset domains
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_rst_driver extends evm_driver#(virtual evm_rst_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_rst_cfg cfg;
    
    //==========================================================================
    // Reset Parameters
    //==========================================================================
    int pcie_reset_duration_ns;
    int sys_reset_duration_ns;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_rst_driver", evm_component parent = null, evm_rst_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
        if (cfg != null) begin
            pcie_reset_duration_ns = cfg.pcie_reset_duration_ns;
            sys_reset_duration_ns  = cfg.sys_reset_duration_ns;
        end else begin
            // Defaults if no config provided
            pcie_reset_duration_ns = 100;
            sys_reset_duration_ns  = 100;
        end
    endfunction
    
    //==========================================================================
    // Reset Tasks
    //==========================================================================
    
    // Apply PCIe reset
    task apply_pcie_reset();
        log_info("Applying PCIe reset", EVM_LOW);
        vif.pcie_perst_n = 0;
        #(pcie_reset_duration_ns * 1ns);
        vif.pcie_perst_n = 1;
        log_info("PCIe reset released", EVM_LOW);
    endtask
    
    // Apply system reset
    task apply_sys_reset();
        log_info("Applying system reset", EVM_LOW);
        vif.sys_rst_n = 0;
        #(sys_reset_duration_ns * 1ns);
        vif.sys_rst_n = 1;
        log_info("System reset released", EVM_LOW);
    endtask
    
    // Apply all resets
    task apply_all_resets();
        fork
            apply_pcie_reset();
            apply_sys_reset();
        join
    endtask
    
    //==========================================================================
    // Configuration
    //==========================================================================
    task set_pcie_reset_duration(int duration_ns);
        pcie_reset_duration_ns = duration_ns;
        log_info($sformatf("PCIe reset duration set to %0d ns", duration_ns), EVM_MED);
    endtask
    
    task set_sys_reset_duration(int duration_ns);
        sys_reset_duration_ns = duration_ns;
        log_info($sformatf("System reset duration set to %0d ns", duration_ns), EVM_MED);
    endtask
    
endclass : evm_rst_driver
