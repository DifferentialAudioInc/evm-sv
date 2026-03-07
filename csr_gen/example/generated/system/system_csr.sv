//==============================================================================
// Module: system_csr
// Description: CSR implementation for System control and status module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

import system_csr_pkg::*;

module system_csr (
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
    output system_reg_t control_o,
    output system_reg_t led_control_o,
    output system_reg_t scratch0_o,
    output system_reg_t scratch1_o,
    
    // Register inputs (from logic)
    input  system_reg_t version_i,
    input  system_reg_t status_i,
    input  system_reg_t timestamp_lo_i,
    input  system_reg_t timestamp_hi_i,
    input  system_reg_t test_reg_i
);

    // Register storage
    system_reg_t control_q, control_d;
    system_reg_t led_control_q, led_control_d;
    system_reg_t scratch0_q, scratch0_d;
    system_reg_t scratch1_q, scratch1_d;

    // Address decode
    logic [8:0] reg_sel_wr;
    logic [8:0] reg_sel_rd;

    always_comb begin
        reg_sel_wr = '0;
        reg_sel_rd = '0;
        
        case (csr_addr)
            SYSTEM_BASE_ADDR + SYSTEM_VERSION_OFFSET: begin
                reg_sel_wr[0] = csr_wr_en;
                reg_sel_rd[0] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_CONTROL_OFFSET: begin
                reg_sel_wr[1] = csr_wr_en;
                reg_sel_rd[1] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_STATUS_OFFSET: begin
                reg_sel_wr[2] = csr_wr_en;
                reg_sel_rd[2] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_LED_CONTROL_OFFSET: begin
                reg_sel_wr[3] = csr_wr_en;
                reg_sel_rd[3] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_SCRATCH0_OFFSET: begin
                reg_sel_wr[4] = csr_wr_en;
                reg_sel_rd[4] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_SCRATCH1_OFFSET: begin
                reg_sel_wr[5] = csr_wr_en;
                reg_sel_rd[5] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_TIMESTAMP_LO_OFFSET: begin
                reg_sel_wr[6] = csr_wr_en;
                reg_sel_rd[6] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_TIMESTAMP_HI_OFFSET: begin
                reg_sel_wr[7] = csr_wr_en;
                reg_sel_rd[7] = csr_rd_en;
            end
            SYSTEM_BASE_ADDR + SYSTEM_TEST_REG_OFFSET: begin
                reg_sel_wr[8] = csr_wr_en;
                reg_sel_rd[8] = csr_rd_en;
            end
            default: begin
                reg_sel_wr = '0;
                reg_sel_rd = '0;
            end
        endcase
    end

    // Write logic
    always_comb begin
        control_d = control_q;
        if (reg_sel_wr[1]) begin
            control_d.raw = csr_wr_data;
        end
    end

    always_comb begin
        led_control_d = led_control_q;
        if (reg_sel_wr[3]) begin
            led_control_d.raw = csr_wr_data;
        end
    end

    always_comb begin
        scratch0_d = scratch0_q;
        if (reg_sel_wr[4]) begin
            scratch0_d.raw = csr_wr_data;
        end
    end

    always_comb begin
        scratch1_d = scratch1_q;
        if (reg_sel_wr[5]) begin
            scratch1_d.raw = csr_wr_data;
        end
    end

    // Register update
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            control_q.raw <= 32'h00000000;
            led_control_q.raw <= 32'h00000000;
            scratch0_q.raw <= 32'h00000000;
            scratch1_q.raw <= 32'hDEADBEEF;
        end else begin
            control_q <= control_d;
            led_control_q <= led_control_d;
            scratch0_q <= scratch0_d;
            scratch1_q <= scratch1_d;
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
                reg_sel_rd[0]: csr_rd_data <= version_i.raw;
                reg_sel_rd[1]: csr_rd_data <= control_q.raw;
                reg_sel_rd[2]: csr_rd_data <= status_i.raw;
                reg_sel_rd[3]: csr_rd_data <= led_control_q.raw;
                reg_sel_rd[4]: csr_rd_data <= scratch0_q.raw;
                reg_sel_rd[5]: csr_rd_data <= scratch1_q.raw;
                reg_sel_rd[6]: csr_rd_data <= timestamp_lo_i.raw;
                reg_sel_rd[7]: csr_rd_data <= timestamp_hi_i.raw;
                reg_sel_rd[8]: csr_rd_data <= test_reg_i.raw;
                default: csr_rd_data <= 32'h0;
            endcase
        end
    end

    // Output assignments
    assign control_o = control_q;
    assign led_control_o = led_control_q;
    assign scratch0_o = scratch0_q;
    assign scratch1_o = scratch1_q;

endmodule : system_csr