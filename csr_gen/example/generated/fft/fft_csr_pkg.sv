//==============================================================================
// Package: fft_csr_pkg
// Description: CSR definitions for FFT processing module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

package fft_csr_pkg;

    // Module base address
    localparam logic [31:0] FFT_BASE_ADDR = 32'h00002000;

    // Register offsets
    localparam logic [31:0] FFT_CONFIG_OFFSET = 32'h00000000;
    localparam logic [31:0] FFT_STATUS_OFFSET = 32'h00000004;

    // FFT configuration register
    typedef struct packed {
        logic [21:0] reserved            ; // [31:10] Reserved
        logic [ 1:0] overlap             ; // [9:8] Overlap (0=0%, 1=25%, 2=50%, 3=75%)
        logic [ 2:0] window              ; // [7:5] Window function (0=Rect, 1=Hanning, 2=Hamming, 3=Blackman)
        logic [ 3:0] size                ; // [4:1] FFT size (0=1K, 1=2K, 2=4K, 3=8K)
        logic        enable              ; // [0] FFT enable
    } fft_config_t;

    // FFT status register
    typedef struct packed {
        logic [28:0] reserved            ; // [31:3] Reserved
        logic        overflow            ; // [2] Output overflow detected
        logic        done                ; // [1] FFT processing complete
        logic        busy                ; // [0] FFT processing active
    } fft_status_t;

    // Register block union
    typedef union packed {
        fft_config_t config;
        fft_status_t status;
        logic [31:0] raw;
    } fft_reg_t;

    // Complete register file structure
    typedef struct {
        fft_reg_t config              ; // Offset: 0
        fft_reg_t status              ; // Offset: 4
    } fft_regs_t;

endpackage : fft_csr_pkg