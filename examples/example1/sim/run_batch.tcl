#==============================================================================
# run_batch.tcl - Vivado Batch Mode Simulation Script
# Creates a disk-based project, compiles, simulates 100us, saves waves.
#
# USAGE FROM WINDOWS COMMAND LINE:
#   vivado -mode batch -source c:/evm/evm-sv/examples/example1/sim/run_batch.tcl
#
# With test selection:
#   vivado -mode batch -source c:/evm/evm-sv/examples/example1/sim/run_batch.tcl -tclargs basic_write_test
#
# OUTPUT:
#   - sim/sim_work/   Vivado project (auto-generated, gitignored)
#   - waves.wdb       Open with: vivado waves.wdb
#
# Author: Eric Dyer (Differential Audio Inc.)
#==============================================================================

set SIM_DIR     [file normalize [file dirname [info script]]]
set EXAMPLE_DIR [file normalize "$SIM_DIR/.."]
set EVM_DIR     [file normalize "$EXAMPLE_DIR/../.."]
set PROJ_DIR    "$SIM_DIR/sim_work"

set TEST_NAME "basic_write_test"
if {[llength $argv] > 0} { set TEST_NAME [lindex $argv 0] }

puts "============================================================"
puts "  EVM example1 - Vivado Batch Simulation"
puts "  Test:    $TEST_NAME"
puts "  Runtime: 1000us"
puts "============================================================"

#------------------------------------------------------------------------------
# Auto-detect installed part (behavioral sim works with any part)
#------------------------------------------------------------------------------
set _parts [get_parts]
set _part  [lindex $_parts 0]
foreach _p $_parts {
    if {[string match "xc7a*" $_p] || [string match "xc7z*" $_p]} {
        set _part $_p; break
    }
}
puts "Using part: $_part"

#------------------------------------------------------------------------------
# Create a real disk project (required for launch_simulation in batch mode)
# Delete old project first to force clean rebuild of compiled objects
#------------------------------------------------------------------------------
file delete -force $PROJ_DIR
file mkdir $PROJ_DIR
create_project -force example1_sim $PROJ_DIR -part $_part
set_property simulator_language Mixed [current_project]

#------------------------------------------------------------------------------
# Add source files
#------------------------------------------------------------------------------
set all_files [list \
    "$EVM_DIR/vkit/evm_vkit/evm_axi_lite_agent/evm_axi_lite_if.sv" \
    "$EVM_DIR/vkit/evm_vkit/evm_axi4_full_agent/evm_axi4_full_if.sv" \
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
        puts "WARNING: Missing: $f"
    }
}

set_property include_dirs [list \
    "$EVM_DIR/vkit/src" \
    "$EVM_DIR/vkit/evm_vkit" \
    "$EVM_DIR/vkit/evm_vkit/evm_axi_lite_agent" \
    "$EVM_DIR/vkit/evm_vkit/evm_axi4_full_agent" \
    "$EXAMPLE_DIR/csr/generated/axi_data_xform" \
    "$EXAMPLE_DIR/dv/tb" \
    "$EXAMPLE_DIR/dv/tb/intf" \
    "$EXAMPLE_DIR/dv/env" \
    "$EXAMPLE_DIR/dv/tests" \
] [get_filesets sim_1]

set_property top        tb_top         [get_filesets sim_1]
set_property top_lib    xil_defaultlib [get_filesets sim_1]

# Plusargs: test name
# XSim uses -testplusarg syntax (NOT +ARG=VALUE which is positional in XSim)
set_property -name {xsim.simulate.xsim.more_options} \
    -value "-testplusarg EVM_TESTNAME=$TEST_NAME" -objects [get_filesets sim_1]

# Runtime — extend to 1000us to allow full test completion
set_property -name {xsim.simulate.runtime}         -value {1000us} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true}  -objects [get_filesets sim_1]

#------------------------------------------------------------------------------
# Compile and simulate
#------------------------------------------------------------------------------
puts "\nCompiling..."
launch_simulation -simset sim_1 -mode behavioral

puts "\nLogging all waves..."
log_wave -recursive *

puts "\nRunning 1000us (+EVM_TESTNAME=$TEST_NAME)..."
run 1000us

puts ""
puts "============================================================"
puts "  Done. To view waves:"
puts "    vivado $PROJ_DIR/example1_sim.sim/sim_1/behav/xsim/wave.wdb"
puts "  Or from the directory where vivado was launched:"
puts "    vivado waves.wdb   (if wdb was written here)"
puts "============================================================"

close_sim
