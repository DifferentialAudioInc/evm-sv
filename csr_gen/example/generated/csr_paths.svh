//==============================================================================
// File: csr_paths.svh
// Description: SystemVerilog include paths for CSR modules
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

// Include this file to get all CSR package paths
// Usage: `include "csr_paths.svh"

// CSR module include paths
`define CSR_SYSTEM_PKG_PATH "system/system_csr_pkg.sv"
`define CSR_SYSTEM_RTL_PATH "system/system_csr.sv"
`define CSR_ADC_PKG_PATH "adc/adc_csr_pkg.sv"
`define CSR_ADC_RTL_PATH "adc/adc_csr.sv"
`define CSR_FFT_PKG_PATH "fft/fft_csr_pkg.sv"
`define CSR_FFT_RTL_PATH "fft/fft_csr.sv"

// Import all CSR packages
// import system_csr_pkg::*;
// import adc_csr_pkg::*;
// import fft_csr_pkg::*;