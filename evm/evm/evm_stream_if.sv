//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_stream_if
// Description: Generic streaming interface for continuous data transfer
//              Used for ADC/DAC and other streaming agents
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

interface evm_stream_if #(
    parameter int DATA_WIDTH = 16,
    parameter int NUM_CHANNELS = 1
);
    
    //==========================================================================
    // Signals
    //==========================================================================
    logic                              clk;
    logic [NUM_CHANNELS-1:0][DATA_WIDTH-1:0] data;
    logic [NUM_CHANNELS-1:0]           valid;
    logic [NUM_CHANNELS-1:0]           enable;
    
    //==========================================================================
    // Initial Values
    //==========================================================================
    initial begin
        data = '0;
        valid = '0;
        enable = '0;
    end
    
endinterface : evm_stream_if
