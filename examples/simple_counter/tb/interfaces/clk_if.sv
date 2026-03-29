//==============================================================================
// Clock Interface
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Interface: clk_if
// Description: Clock interface for testbench
//==============================================================================

interface clk_if;
    
    logic clk;
    
    // Initialize clock to 0
    initial begin
        clk = 1'b0;
    end
    
endinterface : clk_if
