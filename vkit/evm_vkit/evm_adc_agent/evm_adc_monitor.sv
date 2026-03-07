//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_adc_monitor
// Description: ADC monitor for EVM
//              Monitors ADC outputs for verification
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

class evm_adc_monitor extends evm_monitor#(virtual evm_adc_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_adc_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_adc_monitor", evm_component parent = null, evm_adc_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
    endfunction
    
    //==========================================================================
    // Main Phase - Monitor ADC outputs
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        log_info("Starting ADC monitoring", EVM_LOW);
        
        fork
            monitor_adc();
        join_none
    endtask
    
    //==========================================================================
    // Monitoring Task
    //==========================================================================
    task monitor_adc();
        int sample_count = 0;
        
        forever begin
            @(posedge vif.adc_clk);
            if (vif.adc_enabled) begin
                sample_count++;
                if (sample_count % 1000000 == 0) begin
                    log_info($sformatf("Monitored %0d samples", sample_count), EVM_LOW);
                end
            end
        end
    endtask
    
endclass : evm_adc_monitor
