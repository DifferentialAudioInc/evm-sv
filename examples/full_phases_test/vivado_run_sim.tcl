#==============================================================================
# Vivado Simulation Run Script
# Usage: vivado -mode batch -source vivado_run_sim.tcl
#==============================================================================

# Open project (create if doesn't exist)
if {[file exists "./vivado_project/evm_full_phases_test.xpr"]} {
    open_project ./vivado_project/evm_full_phases_test.xpr
} else {
    source vivado_setup.tcl
}

# Launch simulation
launch_simulation

# Run simulation for 10ms
run 10ms

# Close simulation
close_sim

puts "Simulation complete! Check simulation log for results."
