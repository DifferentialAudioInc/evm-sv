//==============================================================================
// Module: adc_csr
// Description: CSR implementation for ADC control and status module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

import adc_csr_pkg::*;

module adc_csr (
    // Clock and Reset
    input  logic        clk,
    input  logic        rst_n,
    
    // CPU Interface (simple read/write)
    input  logic        csr_wr_en,
    input  logic        csr_rd_en,
    input  logic [31:0] csr_addr,
    input  logic [31:0] csr_wr_data,
    output logic [31:0] csr_rd_data,
    output logic        csr_rd_valid,
    
    // Register outputs (to logic)
    output adc_reg_t config_o,
    
    // Register inputs (from logic)
    input  adc_reg_t status_i,
    input  adc_reg_t sample_count_i
);

    // Register storage
    adc_reg_t config_q, config_d;

    // Address decode
    logic [2:0] reg_sel_wr;
    logic [2:0] reg_sel_rd;

    always_comb begin
        reg_sel_wr = '0;
        reg_sel_rd = '0;
        
        case (csr_addr)
            ADC_BASE_ADDR + ADC_CONFIG_OFFSET: begin
                reg_sel_wr[0] = csr_wr_en;
                reg_sel_rd[0] = csr_rd_en;
            end
            ADC_BASE_ADDR + ADC_STATUS_OFFSET: begin
                reg_sel_wr[1] = csr_wr_en;
                reg_sel_rd[1] = csr_rd_en;
            end
            ADC_BASE_ADDR + ADC_SAMPLE_COUNT_OFFSET: begin
                reg_sel_wr[2] = csr_wr_en;
                reg_sel_rd[2] = csr_rd_en;
            end
            default: begin
                reg_sel_wr = '0;
                reg_sel_rd = '0;
            end
        endcase
    end

    // Write logic
    always_comb begin
        config_d = config_q;
        if (reg_sel_wr[0]) begin
            config_d.raw = csr_wr_data;
        end
    end

    // Register update
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            config_q.raw <= 32'h00000000;
        end else begin
            config_q <= config_d;
        end
    end

    // Read logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            csr_rd_data  <= 32'h0;
            csr_rd_valid <= 1'b0;
        end else begin
            csr_rd_valid <= |reg_sel_rd;
            csr_rd_data  <= 32'h0;
            
            case (1'b1)
                reg_sel_rd[0]: csr_rd_data <= config_q.raw;
                reg_sel_rd[1]: csr_rd_data <= status_i.raw;
                reg_sel_rd[2]: csr_rd_data <= sample_count_i.raw;
                default: csr_rd_data <= 32'h0;
            endcase
        end
    end

    // Output assignments
    assign config_o = config_q;

endmodule : adc_csr