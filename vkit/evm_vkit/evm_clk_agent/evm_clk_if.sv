//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_clk_if
// Description: Generic clock interface for clock generator
//              Single clock - instantiate multiple times for multiple clocks
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

interface evm_clk_if;
    
    //==========================================================================
    // Clock Signal (generic)
    //==========================================================================
    logic clk;
    
    //==========================================================================
    // Initial Value
    //==========================================================================
    initial begin
        clk = 0;
    end
    
endinterface : evm_clk_if
