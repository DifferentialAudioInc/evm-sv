//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_adc_if
// Description: ADC interface for ADC behavioral model
//              Simulates AD9634 ADC outputs (4 channels)
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

interface evm_adc_if;
    
    //==========================================================================
    // Parameters
    //==========================================================================
    parameter int NUM_CHANNELS = 4;
    parameter int ADC_BITS = 12;
    
    //==========================================================================
    // ADC Data Signals
    //==========================================================================
    logic [NUM_CHANNELS-1:0] data_out;      // Differential data outputs (simplified)
    logic [ADC_BITS-1:0]     data_ch[NUM_CHANNELS];  // Full ADC data per channel
    
    //==========================================================================
    // Control Signals
    //==========================================================================
    logic adc_clk;          // ADC sample clock (reference)
    logic adc_enabled;      // ADC enable status
    
    //==========================================================================
    // Initial Values
    //==========================================================================
    initial begin
        data_out = '0;
        foreach(data_ch[i]) data_ch[i] = '0;
        adc_enabled = 0;
    end
    
endinterface : evm_adc_if
