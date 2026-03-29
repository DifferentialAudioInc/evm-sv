#!/bin/bash
#==============================================================================
# EVM Compilation Check Script
# Tests that evm_pkg.sv compiles without errors
#==============================================================================

echo "================================================================================"
echo "EVM Package Compilation Check"
echo "================================================================================"
echo ""

# Check if vlog (Questa) is available
if command -v vlog &> /dev/null; then
    echo "Testing with Questa/ModelSim (vlog)..."
    vlog -sv +incdir+. evm_pkg.sv
    if [ $? -eq 0 ]; then
        echo "✓ Questa compilation PASSED"
    else
        echo "✗ Questa compilation FAILED"
        exit 1
    fi
    echo ""
fi

# Check if xrun (Xcelium) is available
if command -v xrun &> /dev/null; then
    echo "Testing with Xcelium (xrun)..."
    xrun -compile -sv +incdir+. evm_pkg.sv
    if [ $? -eq 0 ]; then
        echo "✓ Xcelium compilation PASSED"
    else
        echo "✗ Xcelium compilation FAILED"
        exit 1
    fi
    echo ""
fi

# Check if vcs is available
if command -v vcs &> /dev/null; then
    echo "Testing with VCS..."
    vcs -sverilog +incdir+. evm_pkg.sv -o simv_check
    if [ $? -eq 0 ]; then
        echo "✓ VCS compilation PASSED"
        rm -rf simv_check* csrc
    else
        echo "✗ VCS compilation FAILED"
        exit 1
    fi
    echo ""
fi

echo "================================================================================"
echo "All available simulators compiled successfully!"
echo "================================================================================"
