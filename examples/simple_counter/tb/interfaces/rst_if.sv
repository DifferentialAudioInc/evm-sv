//==============================================================================
// Reset Interface
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Interface: rst_if
// Description: Reset interface for testbench
//==============================================================================

interface rst_if;
    
    logic rst_n;
    
    // Initialize reset to inactive
    initial begin
        rst_n = 1'b1;
    end
    
endinterface : rst_if
