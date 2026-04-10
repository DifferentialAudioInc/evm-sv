#==============================================================================
# run_sim.tcl - Vivado simulation setup and single-test runner
# Location: example1/sim/run_sim.tcl
#
# Usage (from Vivado Tcl console):
#   cd c:/evm/evm-sv/examples/example1/sim
#   source run_sim.tcl
#   run_test basic_write_test
#
# Available tests: basic_write_test  multi_xform_test  random_test
#
# Author: Eric Dyer (Differential Audio Inc.)
#==============================================================================

# Self-referencing path setup
set SIM_DIR     [file normalize [file dirname [info script]]]
set EXAMPLE_DIR [file normalize "$SIM_DIR/.."]
set EVM_DIR     [file normalize "$EXAMPLE_DIR/../.."]

puts "============================================================"
puts "EVM Example 1: AXI Data Transform"
puts "SIM_DIR     : $SIM_DIR"
puts "EXAMPLE_DIR : $EXAMPLE_DIR"
puts "EVM_DIR     : $EVM_DIR"
puts "============================================================"

#------------------------------------------------------------------------------
# Create Vivado in-memory simulation project
#------------------------------------------------------------------------------
proc setup_project {} {
    global SIM_DIR EXAMPLE_DIR EVM_DIR
    
    create_project -in_memory -part xc7k325tffg900-2 -force
    set_property simulator_language Mixed [current_project]
    
    # Interface files (compiled before packages)
    set iface_files [list \
        "$EVM_DIR/vkit/evm_vkit/evm_axi_lite_agent/evm_axi_lite_if.sv" \
        "$EXAMPLE_DIR/dv/tb/intf/gpio_if.sv" \
    ]
    
    # EVM Framework package
    set evm_files [list \
        "$EVM_DIR/vkit/src/evm_pkg.sv" \
    ]
    
    # EVM VKit package
    set vkit_files [list \
        "$EVM_DIR/vkit/evm_vkit/evm_vkit_pkg.sv" \
    ]
    
    # Generated CSR files (from csr_gen/gen_csr.py)
    set csr_files [list \
        "$EXAMPLE_DIR/csr/generated/axi_data_xform/axi_data_xform_csr_pkg.sv" \
        "$EXAMPLE_DIR/csr/generated/axi_data_xform/axi_data_xform_csr.sv" \
    ]
    
    # DUT RTL
    set rtl_files [list \
        "$EXAMPLE_DIR/rtl/example1.sv" \
    ]
    
    # DV package and testbench top
    set dv_files [list \
        "$EXAMPLE_DIR/dv/env/example1_pkg.sv" \
        "$EXAMPLE_DIR/dv/tb/tb_top.sv" \
    ]
    
    # Add all files
    set all_files [concat $iface_files $evm_files $vkit_files $csr_files $rtl_files $dv_files]
    foreach f $all_files {
        if {[file exists $f]} {
            add_files -fileset sim_1 $f
            set_property FILE_TYPE {SystemVerilog} [get_files $f]
        } else {
            puts "WARNING: File not found: $f"
        }
    }
    
    # Include directories (for `include directives inside packages)
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
    
    # Set simulation top
    set_property top tb_top [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    
    puts "Project setup complete. [llength $all_files] source files."
}

#------------------------------------------------------------------------------
# Run a single named test
#------------------------------------------------------------------------------
proc run_test {test_name} {
    puts "============================================================"
    puts "Running: $test_name"
    puts "============================================================"
    
    if {[catch {launch_simulation -simset sim_1 -mode behavioral -noclean_dir} err]} {
        puts "ERROR during compile: $err"
        return -1
    }
    
    restart
    add_wave -recursive /tb_top
    set_property -name {xsim.simulate.runtime}          -value {10ms}  -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.log_all_signals}  -value {true}  -objects [get_filesets sim_1]
    
    run -all
    puts "Test $test_name complete."
}

#------------------------------------------------------------------------------
# Auto-run setup on source
#------------------------------------------------------------------------------
setup_project
puts ""
puts "Ready. Run with:"
puts "  run_test basic_write_test"
puts "  run_test multi_xform_test"
puts "  run_test random_test"
puts ""
puts "Or full regression:"
puts "  source run_regression.tcl"
