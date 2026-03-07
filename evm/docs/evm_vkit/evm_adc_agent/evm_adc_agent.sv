//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_adc_agent
// Description: ADC agent for EVM
//              Manages ADC behavioral model
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

class evm_adc_agent extends evm_agent#(virtual evm_adc_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_adc_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_adc_agent", evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);  // ADC agent is active by default
        cfg = new();  // Create default configuration
    endfunction
    
    //==========================================================================
    // Factory Methods
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_adc_if) create_monitor(string name);
        evm_adc_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_adc_if) create_driver(string name);
        evm_adc_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function evm_adc_driver get_driver();
        evm_adc_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_adc_monitor get_monitor();
        evm_adc_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    // Convenience methods for easy access
    function void configure_channel(int ch_id, real freq_hz, real amplitude, 
                                   real phase_deg = 0.0, real dc_offset = 0.0);
        evm_adc_driver drv = get_driver();
        if (drv != null) begin
            drv.configure_channel(ch_id, freq_hz, amplitude, phase_deg, dc_offset);
        end
    endfunction
    
    function void enable_channel(int ch_id);
        evm_adc_driver drv = get_driver();
        if (drv != null) begin
            drv.enable_channel(ch_id);
        end
    endfunction
    
    function void enable_all_channels();
        evm_adc_driver drv = get_driver();
        if (drv != null) begin
            drv.enable_all_channels();
        end
    endfunction
    
endclass : evm_adc_agent
