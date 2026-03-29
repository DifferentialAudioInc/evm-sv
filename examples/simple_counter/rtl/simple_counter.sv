//==============================================================================
// Simple Counter DUT
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Module: simple_counter
// Description: Simple 8-bit counter with enable
//              - Active-low async reset
//              - Counts on positive clock edge when enabled
//==============================================================================

module simple_counter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] count
);

    //==========================================================================
    // Counter Logic
    //==========================================================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'h00;
        end else if (enable) begin
            count <= count + 1'b1;
        end
    end

endmodule : simple_counter
