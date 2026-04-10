#==============================================================================
# run_batch.tcl - Vivado Batch Mode Simulation Script
# Runs a single test, generates waves, simulates for up to 100us
#
# USAGE FROM WINDOWS COMMAND LINE:
#   vivado -mode batch -source c:/evm/evm-sv/examples/example1/sim/run_batch.tcl
#
# With test selection:
#   vivado -mode batch -source c:/evm/evm-sv/examples/example1/sim/run_batch.tcl -tclargs basic_write_test
#
# With other tests:
#   vivado -mode batch -source ... -tclargs multi_xform_test
#   vivado -mode batch -source ... -tclargs random_test
#
# OUTPUT:
#   - Console log: simulation output + pass/fail
#   - waves.wdb:   Vivado waveform database (open with: vivado waves.wdb)
#   - waves.vcd:   VCD waveform (open with any VCD viewer)
#
# Author: Eric Dyer (Differential Audio Inc.)
#==============================================================================

# Self-referencing paths
set SIM_DIR     [file normalize [file dirname [info script]]]
set EXAMPLE_DIR [file normalize "$SIM_DIR/.."]
set EVM_DIR     [file normalize "$EXAMPLE_DIR/../.."]

# Test name from command-line argument or default
set TEST_NAME "basic_write_test"
if {[llength $argv] > 0} {
    set TEST_NAME [lindex $argv 0]
}

puts "============================================================"
puts "  EVM example1 - Vivado Batch Simulation"
puts "  Test:    $TEST_NAME"
puts "  Runtime: 100us"
puts "============================================================"

#------------------------------------------------------------------------------
# Create project
#------------------------------------------------------------------------------
create_project -in_memory -part xc7k325tffg900-2 -force
set_property simulator_language Mixed [current_project]

#------------------------------------------------------------------------------
# Source files
#------------------------------------------------------------------------------
set all_files [list \
    "$EVM_DIR/vkit/evm_vkit/evm_axi_lite_agent/evm_axi_lite_if.sv" \
    "$EXAMPLE_DIR/dv/tb/intf/gpio_if.sv" \
    "$EVM_DIR/vkit/src/evm_pkg.sv" \
    "$EVM_DIR/vkit/evm_vkit/evm_vkit_pkg.sv" \
    "$EXAMPLE_DIR/csr/generated/axi_data_xform/axi_data_xform_csr_pkg.sv" \
    "$EXAMPLE_DIR/csr/generated/axi_data_xform/axi_data_xform_csr.sv" \
    "$EXAMPLE_DIR/rtl/example1.sv" \
    "$EXAMPLE_DIR/dv/env/example1_pkg.sv" \
    "$EXAMPLE_DIR/dv/tb/tb_top.sv" \
]

foreach f $all_files {
    if {[file exists $f]} {
        add_files -fileset sim_1 $f
        set_property FILE_TYPE {SystemVerilog} [get_files $f]
    } else {
        puts "WARNING: Missing file: $f"
    }
}

set_property include_dirs [list \
    "$EVM_DIR/vkit/src" \
    "$EVM_DIR/vkit/evm_vkit" \
    "$EVM_DIR/vkit/evm_vkit/evm_axi_lite_agent" \
    "$EXAMPLE_DIR/csr/generated/axi_data_xform" \
    "$EXAMPLE_DIR/dv/tb" \
    "$EXAMPLE_DIR/dv/tb/intf" \
    "$EXAMPLE_DIR/dv/env" \
    "$EXAMPLE_DIR/dv/tests" \
] [get_filesets sim_1]

set_property top tb_top            [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Pass test name as plusarg
set_property -name {xsim.simulate.xsim.more_options} \
    -value "+EVM_TESTNAME=$TEST_NAME" \
    -objects [get_filesets sim_1]

# Simulation runtime
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]

# Enable waveform logging (creates waves.wdb)
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

#------------------------------------------------------------------------------
# Compile
#------------------------------------------------------------------------------
puts ""
puts "Compiling..."
if {[catch {launch_simulation -simset sim_1 -mode behavioral} err]} {
    puts "COMPILATION FAILED: $err"
    exit 1
}
puts "Compilation successful."

#------------------------------------------------------------------------------
# Capture waveforms for all signals, then run
#------------------------------------------------------------------------------
# Add all signals to waveform database
log_wave -recursive *

puts ""
puts "Running simulation for 100us (+EVM_TESTNAME=$TEST_NAME)..."
run 100us

puts ""
puts "============================================================"
puts "  Simulation complete."
puts "  Waveforms: open waves.wdb in Vivado GUI"
puts "             (vivado waves.wdb)"
puts "  VCD:       waves.vcd (compatible with GTKWave, etc.)"
puts "============================================================"

# Save and close
close_sim
