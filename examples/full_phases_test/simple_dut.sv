//==============================================================================
// EVM Full Phases Example - Simple DUT
// A basic counter/passthrough module for testing
//==============================================================================

module simple_dut(
    input logic clk,
    input logic reset_n,
    input logic [7:0] data_in,
    input logic data_valid,
    output logic [7:0] data_out,
    output logic data_ready
);
    
    //==========================================================================
    // Counter
    //==========================================================================
    logic [7:0] counter;
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 8'h00;
        end else begin
            counter <= counter + 1;
        end
    end
    
    //==========================================================================
    // Data Path - Simple passthrough with registered output
    //==========================================================================
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 8'h00;
            data_ready <= 1'b0;
        end else begin
            if (data_valid) begin
                data_out <= data_in + counter;  // Add counter for fun
                data_ready <= 1'b1;
            end else begin
                data_ready <= 1'b0;
            end
        end
    end
    
endmodule
