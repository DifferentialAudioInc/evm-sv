//==============================================================================
// Package: system_csr_pkg
// Description: CSR definitions for System control and status module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

package system_csr_pkg;

    // Module base address
    localparam logic [31:0] SYSTEM_BASE_ADDR = 32'h00000000;

    // Register offsets
    localparam logic [31:0] SYSTEM_VERSION_OFFSET = 32'h00000000;
    localparam logic [31:0] SYSTEM_CONTROL_OFFSET = 32'h00000004;
    localparam logic [31:0] SYSTEM_STATUS_OFFSET = 32'h00000008;
    localparam logic [31:0] SYSTEM_LED_CONTROL_OFFSET = 32'h0000000C;
    localparam logic [31:0] SYSTEM_SCRATCH0_OFFSET = 32'h00000010;
    localparam logic [31:0] SYSTEM_SCRATCH1_OFFSET = 32'h00000014;
    localparam logic [31:0] SYSTEM_TIMESTAMP_LO_OFFSET = 32'h00000018;
    localparam logic [31:0] SYSTEM_TIMESTAMP_HI_OFFSET = 32'h0000001C;
    localparam logic [31:0] SYSTEM_TEST_REG_OFFSET = 32'h00000020;

    // Version and identification register
    typedef struct packed {
        logic [ 7:0] major               ; // [31:24] Major version number
        logic [ 7:0] minor               ; // [23:16] Minor version number
        logic [ 7:0] patch               ; // [15:8] Patch version number
        logic [ 7:0] build               ; // [7:0] Build number
    } system_version_t;

    // System control register
    typedef struct packed {
        logic [28:0] reserved            ; // [31:3] Reserved for future use
        logic        debug_mode          ; // [2] Debug mode enable
        logic        enable              ; // [1] System enable (1=enabled, 0=disabled)
        logic        reset               ; // [0] Software reset (write 1 to reset)
    } system_control_t;

    // System status register
    typedef struct packed {
        logic [28:0] reserved            ; // [31:3] Reserved
        logic        locked              ; // [2] Clock locked status
        logic        error               ; // [1] Error flag
        logic        ready               ; // [0] System ready flag
    } system_status_t;

    // LED control register
    typedef struct packed {
        logic [27:0] reserved            ; // [31:4] Reserved
        logic        led3                ; // [3] LED3 control (1=on, 0=off)
        logic        led2                ; // [2] LED2 control (1=on, 0=off)
        logic        led1                ; // [1] LED1 control (1=on, 0=off)
        logic        led0                ; // [0] LED0 control (1=on, 0=off)
    } system_led_control_t;

    // Scratch register 0 for testing
    typedef struct packed {
        logic [31:0] data                ; // [31:0] Scratch data
    } system_scratch0_t;

    // Scratch register 1 for testing
    typedef struct packed {
        logic [31:0] data                ; // [31:0] Scratch data
    } system_scratch1_t;

    // Timestamp counter lower 32 bits
    typedef struct packed {
        logic [31:0] count               ; // [31:0] Lower 32 bits of timestamp
    } system_timestamp_lo_t;

    // Timestamp counter upper 32 bits
    typedef struct packed {
        logic [31:0] count               ; // [31:0] Upper 32 bits of timestamp
    } system_timestamp_hi_t;

    // Read only test register
    typedef struct packed {
        logic [31:0] val                 ; // [31:0] Read only test register
    } system_test_reg_t;

    // Register block union
    typedef union packed {
        system_version_t version;
        system_control_t control;
        system_status_t status;
        system_led_control_t led_control;
        system_scratch0_t scratch0;
        system_scratch1_t scratch1;
        system_timestamp_lo_t timestamp_lo;
        system_timestamp_hi_t timestamp_hi;
        system_test_reg_t test_reg;
        logic [31:0] raw;
    } system_reg_t;

    // Complete register file structure
    typedef struct {
        system_reg_t version             ; // Offset: 0
        system_reg_t control             ; // Offset: 4
        system_reg_t status              ; // Offset: 8
        system_reg_t led_control         ; // Offset: 12
        system_reg_t scratch0            ; // Offset: 16
        system_reg_t scratch1            ; // Offset: 20
        system_reg_t timestamp_lo        ; // Offset: 24
        system_reg_t timestamp_hi        ; // Offset: 28
        system_reg_t test_reg            ; // Offset: 32
    } system_regs_t;

endpackage : system_csr_pkg