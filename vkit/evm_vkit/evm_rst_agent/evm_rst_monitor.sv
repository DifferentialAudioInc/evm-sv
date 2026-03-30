//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_rst_monitor
// Description: Reset monitor for EVM
//              Monitors reset assertion and deassertion
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_rst_monitor extends evm_monitor#(virtual evm_rst_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_rst_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_rst_monitor", evm_component parent = null, evm_rst_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
    endfunction
    
    //==========================================================================
    // Run Phase - Continuous reset monitoring
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        log_info("Reset monitor started - continuous monitoring", EVM_LOW);
        
        fork
            monitor_sys_reset();
            monitor_adc_reset();
            monitor_pcie_reset();
        join_none
    endtask
    
    //==========================================================================
    // Reset Monitoring Tasks
    // Note: Can propagate reset events to parent hierarchy
    //==========================================================================
    task monitor_sys_reset();
        bit prev_state = 1;
        forever begin
            @(vif.sys_rst_n);
            if (vif.sys_rst_n != prev_state) begin
                if (vif.sys_rst_n == 0) begin
                    log_info("System reset ASSERTED", EVM_MED);
                    // Optional: Propagate to parent if configured
                    // if (cfg != null && cfg.propagate_reset_events && m_parent != null)
                    //     m_parent.assert_reset();
                end else begin
                    log_info("System reset RELEASED", EVM_MED);
                    // Optional: Propagate to parent if configured
                    // if (cfg != null && cfg.propagate_reset_events && m_parent != null)
                    //     m_parent.deassert_reset();
                end
                prev_state = vif.sys_rst_n;
            end
        end
    endtask
    
    task monitor_adc_reset();
        bit prev_state = 1;
        forever begin
            @(vif.adc_reset_n);
            if (vif.adc_reset_n != prev_state) begin
                if (vif.adc_reset_n == 0) begin
                    log_info("ADC reset ASSERTED", EVM_MED);
                end else begin
                    log_info("ADC reset RELEASED", EVM_MED);
                end
                prev_state = vif.adc_reset_n;
            end
        end
    endtask
    
    task monitor_pcie_reset();
        bit prev_state = 1;
        forever begin
            @(vif.pcie_perst_n);
            if (vif.pcie_perst_n != prev_state) begin
                if (vif.pcie_perst_n == 0) begin
                    log_info("PCIe reset ASSERTED", EVM_MED);
                end else begin
                    log_info("PCIe reset RELEASED", EVM_MED);
                end
                prev_state = vif.pcie_perst_n;
            end
        end
    endtask
    
endclass : evm_rst_monitor
