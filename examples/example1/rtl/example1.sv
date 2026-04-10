//==============================================================================
// Module: example1
// Description: Simple AXI Data Transform DUT for EVM framework example
//
//   AXI4-Lite Slave ──► CSR registers ──► Transform engine ──► AXI4-Lite Master
//                                                               GPIO output pins
//
// Register Map (AXI4-Lite Slave, base 0x0000):
//   0x00 CTRL:    [0]=enable  [2:1]=xform_sel (0=pass 1=inv 2=bswap 3=bitrev)
//   0x04 DATA_IN: [31:0]=data (write triggers transform when ENABLE=1)
//   0x08 STATUS:  [0]=busy  [1]=done  (hardware-driven, RO)
//   0x0C RESULT:  [31:0]=last result  (hardware-driven, RO)
//   0x10 GPIO_OUT:[7:0]=gpio  (directly drives gpio_out[7:0] output pins)
//
// Behavior:
//   1. Write CTRL.ENABLE=1 and optionally CTRL.XFORM_SEL
//   2. Write DATA_IN → triggers 4-cycle transform pipeline
//   3. After 4 cycles: RESULT updated, STATUS.DONE asserts
//   4. DUT drives AXI4-Lite Master write to OUTPUT_ADDR with result
//   5. GPIO_OUT[7:0] directly drives gpio_out pins at all times
//
// Author: Eric Dyer (Differential Audio Inc.)
// Date:   2026-04-10
//==============================================================================

import axi_data_xform_csr_pkg::*;

module example1 #(
    parameter logic [31:0] OUTPUT_ADDR = 32'h0000_2000  // AXI master output address
)(
    input  logic        aclk,
    input  logic        aresetn,

    //--------------------------------------------------------------------------
    // AXI4-Lite Slave (TB → DUT: CSR access)
    //--------------------------------------------------------------------------
    input  logic [11:0] s_awaddr,
    input  logic        s_awvalid,
    output logic        s_awready,
    input  logic [31:0] s_wdata,
    input  logic [3:0]  s_wstrb,
    input  logic        s_wvalid,
    output logic        s_wready,
    output logic [1:0]  s_bresp,
    output logic        s_bvalid,
    input  logic        s_bready,
    input  logic [11:0] s_araddr,
    input  logic        s_arvalid,
    output logic        s_arready,
    output logic [31:0] s_rdata,
    output logic [1:0]  s_rresp,
    output logic        s_rvalid,
    input  logic        s_rready,

    //--------------------------------------------------------------------------
    // AXI4-Lite Master (DUT → downstream: result output writes)
    //--------------------------------------------------------------------------
    output logic [31:0] m_awaddr,
    output logic        m_awvalid,
    input  logic        m_awready,
    output logic [31:0] m_wdata,
    output logic [3:0]  m_wstrb,
    output logic        m_wvalid,
    input  logic        m_wready,
    input  logic [1:0]  m_bresp,
    input  logic        m_bvalid,
    output logic        m_bready,

    //--------------------------------------------------------------------------
    // GPIO Output (directly driven by GPIO_OUT CSR register [7:0])
    //--------------------------------------------------------------------------
    output logic [7:0]  gpio_out
);

    //==========================================================================
    // Generated CSR Module Interface
    //==========================================================================
    logic        csr_wr_en;
    logic        csr_rd_en;
    logic [31:0] csr_wr_addr;   // separate write address
    logic [31:0] csr_rd_addr;   // separate read address
    logic [31:0] csr_wr_data;
    logic [31:0] csr_rd_data;
    logic        csr_rd_valid;

    // mux addr — only one active at a time per AXI4-Lite
    logic [31:0] csr_addr;
    assign csr_addr = csr_wr_en ? csr_wr_addr : csr_rd_addr;

    axi_data_xform_reg_t ctrl_o;
    axi_data_xform_reg_t data_in_o;
    axi_data_xform_reg_t gpio_out_o;
    axi_data_xform_reg_t status_hw;   // hardware drives into CSR
    axi_data_xform_reg_t result_hw;   // hardware drives into CSR

    //==========================================================================
    // Instantiate Generated CSR Module
    //==========================================================================
    axi_data_xform_csr u_csr (
        .clk          (aclk),
        .rst_n        (aresetn),
        .csr_wr_en    (csr_wr_en),
        .csr_rd_en    (csr_rd_en),
        .csr_addr     (csr_addr),
        .csr_wr_data  (csr_wr_data),
        .csr_rd_data  (csr_rd_data),
        .csr_rd_valid (csr_rd_valid),
        .ctrl_o       (ctrl_o),
        .data_in_o    (data_in_o),
        .gpio_out_o   (gpio_out_o),
        .status_i     (status_hw),
        .result_i     (result_hw)
    );

    //==========================================================================
    // AXI4-Lite Slave → CSR Bridge: Write Path
    //==========================================================================
    typedef enum logic [1:0] {WR_IDLE, WR_WAIT_W, WR_RESP} wr_state_t;
    wr_state_t wr_state;
    logic [11:0] wr_addr_q;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_state    <= WR_IDLE;
            s_awready   <= 1'b0;
            s_wready    <= 1'b0;
            s_bvalid    <= 1'b0;
            s_bresp     <= 2'b00;
            csr_wr_en   <= 1'b0;
            csr_wr_addr <= '0;
            csr_wr_data <= '0;
            wr_addr_q   <= '0;
        end else begin
            csr_wr_en <= 1'b0;
            s_awready <= 1'b0;
            s_wready  <= 1'b0;

            case (wr_state)
                WR_IDLE: begin
                    if (s_awvalid && s_wvalid) begin
                        // Both AW and W available simultaneously
                        s_awready   <= 1'b1;
                        s_wready    <= 1'b1;
                        csr_wr_addr <= {20'b0, s_awaddr};
                        csr_wr_data <= s_wdata;
                        csr_wr_en   <= 1'b1;
                        s_bvalid    <= 1'b1;
                        wr_state    <= WR_RESP;
                    end else if (s_awvalid) begin
                        // AW arrived first — accept it, wait for W
                        s_awready <= 1'b1;
                        wr_addr_q <= s_awaddr;
                        wr_state  <= WR_WAIT_W;
                    end
                end

                WR_WAIT_W: begin
                    if (s_wvalid) begin
                        s_wready    <= 1'b1;
                        csr_wr_addr <= {20'b0, wr_addr_q};
                        csr_wr_data <= s_wdata;
                        csr_wr_en   <= 1'b1;
                        s_bvalid    <= 1'b1;
                        wr_state    <= WR_RESP;
                    end
                end

                WR_RESP: begin
                    if (s_bready) begin
                        s_bvalid <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end
            endcase
        end
    end

    //==========================================================================
    // AXI4-Lite Slave → CSR Bridge: Read Path
    //==========================================================================
    typedef enum logic [1:0] {RD_IDLE, RD_WAIT, RD_RESP} rd_state_t;
    rd_state_t rd_state;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd_state    <= RD_IDLE;
            s_arready   <= 1'b0;
            s_rvalid    <= 1'b0;
            s_rdata     <= '0;
            s_rresp     <= 2'b00;
            csr_rd_en   <= 1'b0;
            csr_rd_addr <= '0;
        end else begin
            csr_rd_en <= 1'b0;
            s_arready <= 1'b0;

            case (rd_state)
                RD_IDLE: begin
                    if (s_arvalid) begin
                        s_arready   <= 1'b1;
                        csr_rd_addr <= {20'b0, s_araddr};
                        csr_rd_en   <= 1'b1;
                        rd_state    <= RD_WAIT;
                    end
                end

                RD_WAIT: begin
                    // CSR read data valid 1 cycle after csr_rd_en
                    if (csr_rd_valid) begin
                        s_rvalid <= 1'b1;
                        s_rdata  <= csr_rd_data;
                        s_rresp  <= 2'b00;
                        rd_state <= RD_RESP;
                    end
                end

                RD_RESP: begin
                    if (s_rready) begin
                        s_rvalid <= 1'b0;
                        rd_state <= RD_IDLE;
                    end
                end
            endcase
        end
    end

    //==========================================================================
    // Transform Pipeline (4-stage registered)
    // Triggers when DATA_IN is written and ENABLE=1
    //==========================================================================
    logic        data_in_wr;   // DATA_IN write detected
    logic [31:0] pipe_data [0:3];
    logic        pipe_vld  [0:4];  // valid bit per stage (4 is the output)

    // Detect DATA_IN write (occurs same cycle as csr_wr_en)
    assign data_in_wr = csr_wr_en &&
                        (csr_wr_addr == (AXI_DATA_XFORM_BASE_ADDR + AXI_DATA_XFORM_DATA_IN_OFFSET)) &&
                        ctrl_o.raw[0];  // CTRL.ENABLE must be 1

    // Transform function
    function automatic logic [31:0] apply_xform(
        input logic [31:0] data,
        input logic  [1:0] sel
    );
        logic [31:0] r;
        case (sel)
            2'b00: r = data;
            2'b01: r = ~data;
            2'b10: r = {data[7:0], data[15:8], data[23:16], data[31:24]};
            2'b11: begin
                for (int k = 0; k < 32; k++) r[k] = data[31-k];
            end
        endcase
        return r;
    endfunction

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            for (int i = 0; i < 4; i++) begin
                pipe_data[i] <= '0;
                pipe_vld[i]  <= 1'b0;
            end
            pipe_vld[4]    <= 1'b0;
            result_hw.raw  <= '0;
        end else begin
            // Stage 0: capture write data at write time
            pipe_vld[0]  <= data_in_wr;
            pipe_data[0] <= csr_wr_data;  // raw write data (before CSR register)

            // Stages 1-3: propagate
            for (int i = 1; i < 4; i++) begin
                pipe_vld[i]  <= pipe_vld[i-1];
                pipe_data[i] <= pipe_data[i-1];
            end

            // Stage 4 output: compute and register result
            pipe_vld[4] <= pipe_vld[3];
            if (pipe_vld[3])
                result_hw.raw <= apply_xform(pipe_data[3], ctrl_o.raw[2:1]);
        end
    end

    // STATUS: BUSY = any stage valid; DONE = result stage valid
    wire busy = pipe_vld[0] | pipe_vld[1] | pipe_vld[2] | pipe_vld[3];
    assign status_hw.raw = {30'b0, pipe_vld[4], busy};

    //==========================================================================
    // AXI4-Lite Master FSM
    // Initiates one write to OUTPUT_ADDR when transform result is ready
    //==========================================================================
    typedef enum logic [1:0] {M_IDLE, M_DRIVE, M_RESP} m_state_t;
    m_state_t m_state;
    logic m_aw_done, m_w_done;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_state   <= M_IDLE;
            m_awaddr  <= OUTPUT_ADDR;
            m_awvalid <= 1'b0;
            m_wdata   <= '0;
            m_wstrb   <= 4'hF;
            m_wvalid  <= 1'b0;
            m_bready  <= 1'b0;
            m_aw_done <= 1'b0;
            m_w_done  <= 1'b0;
        end else begin
            case (m_state)
                M_IDLE: begin
                    m_aw_done <= 1'b0;
                    m_w_done  <= 1'b0;
                    if (pipe_vld[4]) begin
                        m_awaddr  <= OUTPUT_ADDR;
                        m_awvalid <= 1'b1;
                        m_wdata   <= result_hw.raw;
                        m_wstrb   <= 4'hF;
                        m_wvalid  <= 1'b1;
                        m_state   <= M_DRIVE;
                    end
                end

                M_DRIVE: begin
                    if (m_awvalid && m_awready) begin
                        m_awvalid <= 1'b0;
                        m_aw_done <= 1'b1;
                    end
                    if (m_wvalid && m_wready) begin
                        m_wvalid <= 1'b0;
                        m_w_done <= 1'b1;
                    end

                    // Both handshakes done → wait for B
                    if ((m_aw_done || (m_awvalid && m_awready)) &&
                        (m_w_done  || (m_wvalid  && m_wready))) begin
                        m_bready <= 1'b1;
                        m_state  <= M_RESP;
                    end
                end

                M_RESP: begin
                    if (m_bvalid && m_bready) begin
                        m_bready <= 1'b0;
                        m_state  <= M_IDLE;
                    end
                end
            endcase
        end
    end

    //==========================================================================
    // GPIO Output
    //==========================================================================
    assign gpio_out = gpio_out_o.raw[7:0];

endmodule : example1
