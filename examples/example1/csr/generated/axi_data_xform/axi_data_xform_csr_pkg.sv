//==============================================================================
// Package: axi_data_xform_csr_pkg
// Description: CSR definitions for AXI Data Transform DUT registers
// Generated: 2026-04-10 00:05:08
// Source: c:\evm\evm-sv\examples\axi_data_xform\rtl\axi_data_xform_csr.yaml
//==============================================================================

package axi_data_xform_csr_pkg;

    // Module base address
    localparam logic [31:0] AXI_DATA_XFORM_BASE_ADDR = 32'h00000000;

    // Register offsets
    localparam logic [31:0] AXI_DATA_XFORM_CTRL_OFFSET = 32'h00000000;
    localparam logic [31:0] AXI_DATA_XFORM_DATA_IN_OFFSET = 32'h00000004;
    localparam logic [31:0] AXI_DATA_XFORM_STATUS_OFFSET = 32'h00000008;
    localparam logic [31:0] AXI_DATA_XFORM_RESULT_OFFSET = 32'h0000000C;
    localparam logic [31:0] AXI_DATA_XFORM_GPIO_OUT_OFFSET = 32'h00000010;

    // Control register
    typedef struct packed {
        logic [ 1:0] xform_sel           ; // [2:1] Transform select:
  0 = passthrough  (result = data)
  1 = invert       (result = ~data)
  2 = byte_swap    (result = {d[7:0],d[15:8],d[23:16],d[31:24]})
  3 = bit_reverse  (result = data bit-reversed)

        logic        enable              ; // [0] Enable transform engine (1=enabled)
    } axi_data_xform_ctrl_t;

    // Input data register. Writing triggers transform when ENABLE=1.
    typedef struct packed {
        logic [31:0] data                ; // [31:0] Input data value
    } axi_data_xform_data_in_t;

    // Status register (hardware driven)
    typedef struct packed {
        logic        done                ; // [1] Last transform complete
        logic        busy                ; // [0] Transform in progress
    } axi_data_xform_status_t;

    // Transform result (hardware driven, valid when STATUS.DONE=1)
    typedef struct packed {
        logic [31:0] data                ; // [31:0] Transform result value
    } axi_data_xform_result_t;

    // GPIO output register. Drives gpio_out[7:0] pins directly.
    typedef struct packed {
        logic [ 7:0] gpio                ; // [7:0] GPIO output value (8-bit, drives physical pins)
    } axi_data_xform_gpio_out_t;

    // Register block union
    typedef union packed {
        axi_data_xform_ctrl_t ctrl;
        axi_data_xform_data_in_t data_in;
        axi_data_xform_status_t status;
        axi_data_xform_result_t result;
        axi_data_xform_gpio_out_t gpio_out;
        logic [31:0] raw;
    } axi_data_xform_reg_t;

    // Complete register file structure
    typedef struct {
        axi_data_xform_reg_t ctrl                ; // Offset: 0
        axi_data_xform_reg_t data_in             ; // Offset: 4
        axi_data_xform_reg_t status              ; // Offset: 8
        axi_data_xform_reg_t result              ; // Offset: 12
        axi_data_xform_reg_t gpio_out            ; // Offset: 16
    } axi_data_xform_regs_t;

endpackage : axi_data_xform_csr_pkg