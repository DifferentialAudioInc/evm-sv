#==============================================================================
# Vivado Project Setup Script for EVM Full Phases Test
# Usage: vivado -mode batch -source vivado_setup.tcl
#        or in Vivado TCL Console: source vivado_setup.tcl
#==============================================================================

# Project settings
set project_name "evm_full_phases_test"
set project_dir "./vivado_project"

# Create project
create_project $project_name $project_dir -part xc7a35tcpg236-1 -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add EVM package files (in dependency order)
add_files -norecurse {
    ../../vkit/src/evm_report_handler.sv
    ../../vkit/src/evm_log.sv
    ../../vkit/src/evm_object.sv
    ../../vkit/src/evm_component.sv
    ../../vkit/src/evm_cmdline.sv
    ../../vkit/src/evm_tlm.sv
    ../../vkit/src/evm_sequence_item.sv
    ../../vkit/src/evm_csr_item.sv
    ../../vkit/src/evm_sequence.sv
    ../../vkit/src/evm_csr_sequence.sv
    ../../vkit/src/evm_sequencer.sv
    ../../vkit/src/evm_monitor.sv
    ../../vkit/src/evm_driver.sv
    ../../vkit/src/evm_agent.sv
    ../../vkit/src/evm_reg_field.sv
    ../../vkit/src/evm_reg.sv
    ../../vkit/src/evm_reg_block.sv
    ../../vkit/src/evm_stream_cfg.sv
    ../../vkit/src/evm_stream_driver.sv
    ../../vkit/src/evm_stream_monitor.sv
    ../../vkit/src/evm_stream_agent.sv
    ../../vkit/src/evm_qc.sv
    ../../vkit/src/evm_scoreboard.sv
    ../../vkit/src/evm_coverage.sv
    ../../vkit/src/evm_assertions.sv
    ../../vkit/src/evm_virtual_sequence.sv
    ../../vkit/src/evm_root.sv
    ../../vkit/src/evm_base_test.sv
    ../../vkit/src/evm_pkg.sv
}

# Add test files
add_files -norecurse {
    clk_rst_if.sv
    clk_agent.sv
    rst_agent.sv
    base_test.sv
    simple_dut.sv
}

# Add testbench
add_files -fileset sim_1 -norecurse {
    tb_top.sv
}

# Set tb_top as top
set_property top tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "================================================================================
"
puts "Vivado project created successfully!"
puts "Project: $project_name"
puts "Location: $project_dir"
puts ""
puts "To run simulation:"
puts "  1. In Vivado GUI: Flow -> Run Simulation -> Run Behavioral Simulation"
puts "  2. Or use: launch_simulation"
puts "================================================================================
"


