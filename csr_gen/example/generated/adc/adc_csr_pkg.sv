//==============================================================================
// Package: adc_csr_pkg
// Description: CSR definitions for ADC control and status module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

package adc_csr_pkg;

    // Module base address
    localparam logic [31:0] ADC_BASE_ADDR = 32'h00001000;

    // Register offsets
    localparam logic [31:0] ADC_CONFIG_OFFSET = 32'h00000000;
    localparam logic [31:0] ADC_STATUS_OFFSET = 32'h00000004;
    localparam logic [31:0] ADC_SAMPLE_COUNT_OFFSET = 32'h00000008;

    // ADC configuration register
    typedef struct packed {
        logic [19:0] reserved            ; // [31:12] Reserved
        logic [ 3:0] sample_rate         ; // [11:8] Sample rate divider
        logic        enable_ch3          ; // [3] Enable channel 3
        logic        enable_ch2          ; // [2] Enable channel 2
        logic        enable_ch1          ; // [1] Enable channel 1
        logic        enable_ch0          ; // [0] Enable channel 0
    } adc_config_t;

    // ADC status register
    typedef struct packed {
        logic [28:0] reserved            ; // [31:3] Reserved
        logic        overflow            ; // [2] Data overflow detected
        logic        aligned             ; // [1] Channels aligned
        logic        locked              ; // [0] ADC clock locked
    } adc_status_t;

    // Sample counter
    typedef struct packed {
        logic [31:0] count               ; // [31:0] Number of samples captured
    } adc_sample_count_t;

    // Register block union
    typedef union packed {
        adc_config_t config;
        adc_status_t status;
        adc_sample_count_t sample_count;
        logic [31:0] raw;
    } adc_reg_t;

    // Complete register file structure
    typedef struct {
        adc_reg_t config              ; // Offset: 0
        adc_reg_t status              ; // Offset: 4
        adc_reg_t sample_count        ; // Offset: 8
    } adc_regs_t;

endpackage : adc_csr_pkg