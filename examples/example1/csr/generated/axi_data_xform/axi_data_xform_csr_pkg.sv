//==============================================================================
// Package: axi_data_xform_csr_pkg
// Description: CSR definitions for AXI Data Transform DUT registers
// Generated: 2026-04-10 15:26:15
// Source: c:\evm\evm-sv\examples\example1\csr\example1.yaml
// Fixed: 2026-04-10 - Padded partial structs to 32 bits for packed union compatibility
//   (gen_csr.py bug: structs must match register width in packed unions)
//==============================================================================

package axi_data_xform_csr_pkg;

    // Module base address
    localparam logic [31:0] AXI_DATA_XFORM_BASE_ADDR = 32'h00000000;

    // Register offsets
    localparam logic [31:0] AXI_DATA_XFORM_CTRL_OFFSET     = 32'h00000000;
    localparam logic [31:0] AXI_DATA_XFORM_DATA_IN_OFFSET  = 32'h00000004;
    localparam logic [31:0] AXI_DATA_XFORM_STATUS_OFFSET   = 32'h00000008;
    localparam logic [31:0] AXI_DATA_XFORM_RESULT_OFFSET   = 32'h0000000C;
    localparam logic [31:0] AXI_DATA_XFORM_GPIO_OUT_OFFSET = 32'h00000010;

    // Control register — padded to 32 bits for packed union
    typedef struct packed {
        logic [28:0] _reserved;              // bits [31:3] unused
        logic  [1:0] xform_sel;              // [2:1] Transform select
        logic        enable;                 // [0] Enable transform engine
    } axi_data_xform_ctrl_t;

    // Input data register (full 32 bits)
    typedef struct packed {
        logic [31:0] data;                   // [31:0] Input data value
    } axi_data_xform_data_in_t;

    // Status register — padded to 32 bits for packed union
    typedef struct packed {
        logic [29:0] _reserved;              // bits [31:2] unused
        logic        done;                   // [1] Last transform complete
        logic        busy;                   // [0] Transform in progress
    } axi_data_xform_status_t;

    // Transform result (full 32 bits)
    typedef struct packed {
        logic [31:0] data;                   // [31:0] Transform result value
    } axi_data_xform_result_t;

    // GPIO output register — padded to 32 bits for packed union
    typedef struct packed {
        logic [23:0] _reserved;              // bits [31:8] unused
        logic  [7:0] gpio;                   // [7:0] GPIO output value
    } axi_data_xform_gpio_out_t;

    // Register block union — all members must be exactly 32 bits
    typedef union packed {
        axi_data_xform_ctrl_t      ctrl;
        axi_data_xform_data_in_t   data_in;
        axi_data_xform_status_t    status;
        axi_data_xform_result_t    result;
        axi_data_xform_gpio_out_t  gpio_out;
        logic [31:0]               raw;
    } axi_data_xform_reg_t;

    // Complete register file structure
    typedef struct {
        axi_data_xform_reg_t ctrl;            // Offset: 0x00
        axi_data_xform_reg_t data_in;         // Offset: 0x04
        axi_data_xform_reg_t status;          // Offset: 0x08
        axi_data_xform_reg_t result;          // Offset: 0x0C
        axi_data_xform_reg_t gpio_out;        // Offset: 0x10
    } axi_data_xform_regs_t;

endpackage : axi_data_xform_csr_pkg
