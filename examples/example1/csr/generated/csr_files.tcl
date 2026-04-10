# CSR SystemVerilog TCL Source Script
# Generated: 2026-04-10 00:05:08
# Source: c:\evm\evm-sv\examples\axi_data_xform\rtl\axi_data_xform_csr.yaml
#
# Usage in Vivado: source csr_files.tcl
# Usage in Quartus: source csr_files.tcl

# Get the directory of this script
set csr_dir [file dirname [info script]]

# Add CSR package files
read_verilog -sv ${csr_dir}/axi_data_xform/axi_data_xform_csr_pkg.sv

# Add CSR RTL files
read_verilog -sv ${csr_dir}/axi_data_xform/axi_data_xform_csr.sv

puts "CSR files loaded successfully"