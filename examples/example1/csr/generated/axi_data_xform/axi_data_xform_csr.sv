//==============================================================================
// Module: axi_data_xform_csr
// Description: CSR implementation for AXI Data Transform DUT registers
// Generated: 2026-04-10 15:26:15
// Source: c:\evm\evm-sv\examples\example1\csr\example1.yaml
//==============================================================================

import axi_data_xform_csr_pkg::*;

module axi_data_xform_csr (
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
    output axi_data_xform_reg_t ctrl_o,
    output axi_data_xform_reg_t data_in_o,
    output axi_data_xform_reg_t gpio_out_o,
    
    // Register inputs (from logic)
    input  axi_data_xform_reg_t status_i,
    input  axi_data_xform_reg_t result_i
);

    // Register storage
    axi_data_xform_reg_t ctrl_q, ctrl_d;
    axi_data_xform_reg_t data_in_q, data_in_d;
    axi_data_xform_reg_t gpio_out_q, gpio_out_d;

    // Address decode
    logic [4:0] reg_sel_wr;
    logic [4:0] reg_sel_rd;

    always_comb begin
        reg_sel_wr = '0;
        reg_sel_rd = '0;
        
        case (csr_addr)
            AXI_DATA_XFORM_BASE_ADDR + AXI_DATA_XFORM_CTRL_OFFSET: begin
                reg_sel_wr[0] = csr_wr_en;
                reg_sel_rd[0] = csr_rd_en;
            end
            AXI_DATA_XFORM_BASE_ADDR + AXI_DATA_XFORM_DATA_IN_OFFSET: begin
                reg_sel_wr[1] = csr_wr_en;
                reg_sel_rd[1] = csr_rd_en;
            end
            AXI_DATA_XFORM_BASE_ADDR + AXI_DATA_XFORM_STATUS_OFFSET: begin
                reg_sel_wr[2] = csr_wr_en;
                reg_sel_rd[2] = csr_rd_en;
            end
            AXI_DATA_XFORM_BASE_ADDR + AXI_DATA_XFORM_RESULT_OFFSET: begin
                reg_sel_wr[3] = csr_wr_en;
                reg_sel_rd[3] = csr_rd_en;
            end
            AXI_DATA_XFORM_BASE_ADDR + AXI_DATA_XFORM_GPIO_OUT_OFFSET: begin
                reg_sel_wr[4] = csr_wr_en;
                reg_sel_rd[4] = csr_rd_en;
            end
            default: begin
                reg_sel_wr = '0;
                reg_sel_rd = '0;
            end
        endcase
    end

    // Write logic
    always_comb begin
        ctrl_d = ctrl_q;
        if (reg_sel_wr[0]) begin
            ctrl_d.raw = csr_wr_data;
        end
    end

    always_comb begin
        data_in_d = data_in_q;
        if (reg_sel_wr[1]) begin
            data_in_d.raw = csr_wr_data;
        end
    end

    always_comb begin
        gpio_out_d = gpio_out_q;
        if (reg_sel_wr[4]) begin
            gpio_out_d.raw = csr_wr_data;
        end
    end

    // Register update
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ctrl_q.raw <= 32'h00000000;
            data_in_q.raw <= 32'h00000000;
            gpio_out_q.raw <= 32'h00000000;
        end else begin
            ctrl_q <= ctrl_d;
            data_in_q <= data_in_d;
            gpio_out_q <= gpio_out_d;
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
                reg_sel_rd[0]: csr_rd_data <= ctrl_q.raw;
                reg_sel_rd[1]: csr_rd_data <= data_in_q.raw;
                reg_sel_rd[2]: csr_rd_data <= status_i.raw;
                reg_sel_rd[3]: csr_rd_data <= result_i.raw;
                reg_sel_rd[4]: csr_rd_data <= gpio_out_q.raw;
                default: csr_rd_data <= 32'h0;
            endcase
        end
    end

    // Output assignments
    assign ctrl_o = ctrl_q;
    assign data_in_o = data_in_q;
    assign gpio_out_o = gpio_out_q;

endmodule : axi_data_xform_csr