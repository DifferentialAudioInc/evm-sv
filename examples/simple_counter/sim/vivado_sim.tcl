#==============================================================================
# Vivado Simulation Script
# Copyright (c) 2026 Differential Audio Inc.
# Licensed under MIT License
#==============================================================================

#==============================================================================
# Simple Counter Testbench - Vivado Simulation
#==============================================================================

# Set project variables
set project_name "simple_counter_sim"
set top_module "tb_top"

# Get script directory
set script_dir [file dirname [file normalize [info script]]]
set proj_dir "$script_dir"
set rtl_dir "[file normalize $script_dir/../rtl]"
set tb_dir "[file normalize $script_dir/../tb]"
set vkit_dir "[file normalize $script_dir/../../../vkit/src]"

puts "=== Vivado Simulation Script ==="
puts "Project: $project_name"
puts "RTL Dir: $rtl_dir"
puts "TB Dir:  $tb_dir"
puts "VKIT Dir: $vkit_dir"
puts ""

# Create project
create_project $project_name $proj_dir -force
set_property target_language SystemVerilog [current_project]
set_property simulator_language SystemVerilog [current_project]

#==============================================================================
# Add Source Files
#==============================================================================

puts "Adding source files..."

# Add RTL files
add_files -fileset sources_1 [glob -nocomplain $rtl_dir/*.sv]

# Add EVM framework files (vkit)
add_files -fileset sources_1 [glob -nocomplain $vkit_dir/*.sv]
add_files -fileset sources_1 [glob -nocomplain $vkit_dir/*.svh]

# Add testbench interface files
add_files -fileset sim_1 [glob -nocomplain $tb_dir/interfaces/*.sv]

# Add testbench agent files  
add_files -fileset sim_1 [glob -nocomplain $tb_dir/agents/*.sv]
add_files -fileset sim_1 [glob -nocomplain $tb_dir/agents/pkg/*.sv]

# Add testbench test files
add_files -fileset sim_1 [glob -nocomplain $tb_dir/tests/*.sv]
add_files -fileset sim_1 [glob -nocomplain $tb_dir/tests/pkg/*.sv]

# Add testbench top
add_files -fileset sim_1 $tb_dir/tb_top.sv

# Set include directories
set_property include_dirs [list \
    $vkit_dir \
    $tb_dir/interfaces \
    $tb_dir/agents \
    $tb_dir/tests \
] [current_fileset -simset]

puts "Source files added."

#==============================================================================
# Set Simulation Properties
#==============================================================================

puts "Configuring simulation..."

# Set top module
set_property top $top_module [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Set simulation runtime
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]

# Set simulation options
set_property -name {xsim.elaborate.debug_level} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

puts "Simulation configured."

#==============================================================================
# Compile and Run
#==============================================================================

puts ""
puts "=== Launching Simulation ==="
puts ""

# Launch simulation
launch_simulation

# Run all
run all

# Save waveform
save_wave_config simple_counter_waves.wcfg

puts ""
puts "=== Simulation Complete ==="
puts "Waveform database: $proj_dir/${project_name}.sim/sim_1/behav/xsim/tb_top_behav.wdb"
puts ""

# Keep Vivado open for waveform viewing
# Comment out 'exit' to keep Vivado open
# exit
