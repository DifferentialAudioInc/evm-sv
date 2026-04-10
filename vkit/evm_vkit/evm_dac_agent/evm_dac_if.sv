//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_dac_if
// Description: DAC output interface for passive monitoring
//              Captures DAC data streams for analysis
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

interface evm_dac_if(
    input logic clk,
    input logic rst_n
);

    //==========================================================================
    // DAC Data Signals (4 channels)
    //==========================================================================
    logic        valid;           // Data valid
    logic [11:0] ch0_data;        // Channel 0 data (12-bit)
    logic [11:0] ch1_data;        // Channel 1 data (12-bit)
    logic [11:0] ch2_data;        // Channel 2 data (12-bit)
    logic [11:0] ch3_data;        // Channel 3 data (12-bit)
    
    //==========================================================================
    // Control Signals
    //==========================================================================
    logic        dac_enable;      // DAC enable
    logic [3:0]  ch_enable;       // Per-channel enable [3:0]
    
    //==========================================================================
    // Modports
    //==========================================================================
    
    // Monitor modport (passive observation)
    modport monitor (
        input clk,
        input rst_n,
        input valid,
        input ch0_data,
        input ch1_data,
        input ch2_data,
        input ch3_data,
        input dac_enable,
        input ch_enable
    );
    
    // DUT modport (design drives DAC)
    modport dut (
        input  clk,
        input  rst_n,
        output valid,
        output ch0_data,
        output ch1_data,
        output ch2_data,
        output ch3_data,
        output dac_enable,
        output ch_enable
    );
    
endinterface : evm_dac_if
