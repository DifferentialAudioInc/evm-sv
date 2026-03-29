#==============================================================================
# Create Vivado Project Script
# Copyright (c) 2026 Differential Audio Inc.
# Licensed under MIT License
#==============================================================================
#
# This script creates a Vivado project that you can open in the GUI
# Usage: Just run this once to create the project, then open the .xpr file
#
#==============================================================================

# Project settings
set project_name "simple_counter_project"
set project_dir [file normalize [file dirname [info script]]]

# Source directories
set rtl_dir "[file normalize $project_dir/../rtl]"
set tb_dir "[file normalize $project_dir/../tb]"
set vkit_dir "[file normalize $project_dir/../../../vkit/src]"

puts ""
puts "========================================="
puts "Creating Vivado Project"
puts "========================================="
puts "Project: $project_name"
puts "Location: $project_dir"
puts ""

# Create project
create_project $project_name $project_dir/$project_name -force -part xc7a35tcpg236-1
set_property target_language SystemVerilog [current_project]
set_property simulator_language SystemVerilog [current_project]

#==============================================================================
# Add RTL Files (Design Sources)
#==============================================================================
puts "Adding RTL files..."
add_files -fileset sources_1 [glob -nocomplain $rtl_dir/*.sv]

#==============================================================================
# Add EVM Framework Files (vkit)
#==============================================================================
puts "Adding EVM framework files..."
add_files -fileset sources_1 [glob -nocomplain $vkit_dir/*.sv]
add_files -fileset sources_1 [glob -nocomplain $vkit_dir/*.svh]

#==============================================================================
# Add Testbench Files (Simulation Sources)
#==============================================================================
puts "Adding testbench files..."

# Interfaces
if {[file exists $tb_dir/interfaces]} {
    add_files -fileset sim_1 [glob -nocomplain $tb_dir/interfaces/*.sv]
}

# Agents
if {[file exists $tb_dir/agents]} {
    add_files -fileset sim_1 [glob -nocomplain $tb_dir/agents/*.sv]
}
if {[file exists $tb_dir/agents/pkg]} {
    add_files -fileset sim_1 [glob -nocomplain $tb_dir/agents/pkg/*.sv]
}

# Tests
if {[file exists $tb_dir/tests]} {
    add_files -fileset sim_1 [glob -nocomplain $tb_dir/tests/*.sv]
}
if {[file exists $tb_dir/tests/pkg]} {
    add_files -fileset sim_1 [glob -nocomplain $tb_dir/tests/pkg/*.sv]
}

# Testbench top
add_files -fileset sim_1 $tb_dir/tb_top.sv

#==============================================================================
# Set Include Directories
#==============================================================================
puts "Setting include directories..."
set_property include_dirs [list \
    $vkit_dir \
    $tb_dir/interfaces \
    $tb_dir/agents \
    $tb_dir/tests \
] [get_filesets sim_1]

#==============================================================================
# Set Simulation Properties
#==============================================================================
puts "Configuring simulation settings..."

# Set top module for simulation
set_property top tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Simulation runtime (100us)
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]

# Enable debug
set_property -name {xsim.elaborate.debug_level} -value {all} -objects [get_filesets sim_1]

# Log all signals for waveform viewing
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Use SystemVerilog
set_property source_mgmt_mode All [current_project]

#==============================================================================
# Save and Close
#==============================================================================
puts ""
puts "Saving project..."
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts ""
puts "========================================="
puts "Project Created Successfully!"
puts "========================================="
puts ""
puts "Project file: $project_dir/$project_name/${project_name}.xpr"
puts ""
puts "To open in Vivado GUI:"
puts "  1. Launch Vivado"
puts "  2. File > Open Project"
puts "  3. Browse to: $project_dir/$project_name/${project_name}.xpr"
puts ""
puts "Or double-click: ${project_name}.xpr"
puts ""
puts "========================================="
puts ""

# Don't close Vivado - leave it open for user
# exit
