//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_adc_cfg
// Description: Lightweight configuration class for ADC agent
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_adc_cfg extends evm_object;
    
    //==========================================================================
    // Basic ADC Parameters
    //==========================================================================
    real sample_rate_hz = 100e6;           // Sample rate (default 100 MSPS)
    real default_sine_freq_hz = 1.0e6;     // Default sine frequency (1 MHz)
    real default_sine_amplitude = 2047.0;  // Default amplitude (full scale 12-bit)
    real default_sine_phase_deg = 0.0;     // Default phase offset
    real default_sine_dc_offset = 0.0;     // Default DC offset
    
    // Channel enables
    bit ch0_enable = 1;
    bit ch1_enable = 1;
    bit ch2_enable = 1;
    bit ch3_enable = 1;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_adc_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    virtual function string convert2string();
        return $sformatf("%s: %.1fMSPS, Sine=%.2fMHz", 
                         super.convert2string(), sample_rate_hz/1e6, default_sine_freq_hz/1e6);
    endfunction
    
    virtual function string get_type_name();
        return "evm_adc_cfg";
    endfunction
    
endclass : evm_adc_cfg
