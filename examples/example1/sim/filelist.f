//==============================================================================
// filelist.f - File list for VCS / Questa / Xcelium
// Location: example1/sim/filelist.f
//
// Usage:
//   vcs  -sverilog -f filelist.f +EVM_TESTNAME=basic_write_test -o simv
//   xrun -f filelist.f +EVM_TESTNAME=basic_write_test
//   vlog -sv -f filelist.f
//
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

// Include directories
+incdir+../../../vkit/src
+incdir+../../../vkit/evm_vkit
+incdir+../../../vkit/evm_vkit/evm_axi_lite_agent
+incdir+../csr/generated/axi_data_xform
+incdir+../dv/tb
+incdir+../dv/tb/intf
+incdir+../dv/env
+incdir+../dv/tests

// Interfaces (compiled first)
../../../vkit/evm_vkit/evm_axi_lite_agent/evm_axi_lite_if.sv
../dv/tb/intf/gpio_if.sv

// EVM framework package
../../../vkit/src/evm_pkg.sv

// EVM VKit package (AXI-Lite agent etc.)
../../../vkit/evm_vkit/evm_vkit_pkg.sv

// Generated CSR files
../csr/generated/axi_data_xform/axi_data_xform_csr_pkg.sv
../csr/generated/axi_data_xform/axi_data_xform_csr.sv

// DUT RTL
../rtl/example1.sv

// Testbench package (includes all DV classes + tests via `include)
../dv/env/example1_pkg.sv

// Testbench top
../dv/tb/tb_top.sv
