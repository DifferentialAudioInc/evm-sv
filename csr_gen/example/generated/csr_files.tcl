# CSR SystemVerilog TCL Source Script
# Generated: 2026-03-07 16:48:06
# Source: evm/csr_gen/example/example_csr_definitions.yaml
#
# Usage in Vivado: source csr_files.tcl
# Usage in Quartus: source csr_files.tcl

# Get the directory of this script
set csr_dir [file dirname [info script]]

# Add CSR package files
read_verilog -sv ${csr_dir}/system/system_csr_pkg.sv
read_verilog -sv ${csr_dir}/adc/adc_csr_pkg.sv
read_verilog -sv ${csr_dir}/fft/fft_csr_pkg.sv

# Add CSR RTL files
read_verilog -sv ${csr_dir}/system/system_csr.sv
read_verilog -sv ${csr_dir}/adc/adc_csr.sv
read_verilog -sv ${csr_dir}/fft/fft_csr.sv

puts "CSR files loaded successfully"