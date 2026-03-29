#!/bin/bash
#==============================================================================
# Run Simulation Script (Linux)
# Copyright (c) 2026 Differential Audio Inc.
# Licensed under MIT License
#==============================================================================

echo "=== Simple Counter Simulation ==="
echo ""

# Check if Vivado is in PATH
if ! command -v vivado &> /dev/null; then
    echo "ERROR: Vivado not found in PATH!"
    echo "Please source Vivado settings:"
    echo "  source /tools/Xilinx/Vivado/2023.2/settings64.sh"
    exit 1
fi

# Run Vivado simulation
echo "Starting Vivado simulation..."
vivado -mode batch -source vivado_sim.tcl

echo ""
echo "=== Simulation Complete ==="
echo ""
echo "To view waveforms:"
echo "  vivado simple_counter_sim/simple_counter_sim.xpr"
echo "  Then: Flow > Run Simulation > Run Behavioral Simulation"
echo ""
