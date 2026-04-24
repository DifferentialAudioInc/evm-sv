# ==============================================================================
# EVM UART Unit Test — Vivado xsim simulation script
# ==============================================================================
# File: run_sim.tcl
# Usage (from Vivado Tcl Console or xsim command line):
#   In Vivado GUI: Tools → Run Tcl Script → select this file
#   In Vivado batch: vivado -mode batch -source run_sim.tcl
#   xsim standalone: see "Standalone xsim" section below
#
# What this script does:
#   1. Compiles all SystemVerilog sources (evm_pkg + evm_vkit_pkg + test)
#   2. Elaborates with tb_top as top module
#   3. Runs simulation with waveform capture
#   4. Opens wave viewer with key signals added
# ==============================================================================

# ── Configuration ──────────────────────────────────────────────────────────────
set SCRIPT_DIR [file dirname [info script]]
set EVM_ROOT   [file normalize "$SCRIPT_DIR/../../../.."]
set VKIT_SRC   "$EVM_ROOT/evm-sv/vkit"
set TEST_DIR   [file normalize "$SCRIPT_DIR/.."]

set SIM_DIR    "$SCRIPT_DIR/xsim_work"
set TOP_MODULE "tb_top"
set SIM_NAME   "uart_unit_test"

# UART test plusargs
set PLUSARGS "+EVM_TESTNAME=uart_basic_test +evm_verbosity=HIGH"

# ── Create work directory ──────────────────────────────────────────────────────
file mkdir $SIM_DIR

# ── Compile ───────────────────────────────────────────────────────────────────
puts "=== Compiling EVM UART Unit Test ==="

# EVM core package
puts "  Compiling evm_pkg.sv..."
exec xvlog -sv --work xil_defaultlib \
    "$VKIT_SRC/src/evm_pkg.sv" \
    -log "$SIM_DIR/compile_evm_pkg.log"

# UART interface (module — must be outside package)
puts "  Compiling evm_uart_if.sv..."
exec xvlog -sv --work xil_defaultlib \
    "$VKIT_SRC/evm_vkit/evm_uart_agent/evm_uart_if.sv" \
    -log "$SIM_DIR/compile_uart_if.log"

# EVM vkit package (includes UART agent and all other agents)
puts "  Compiling evm_vkit_pkg.sv..."
exec xvlog -sv --work xil_defaultlib \
    -i "$VKIT_SRC/evm_vkit" \
    "$VKIT_SRC/evm_vkit/evm_vkit_pkg.sv" \
    -log "$SIM_DIR/compile_vkit.log"

# Test package (scoreboard, env, test)
puts "  Compiling uart_unit_test_pkg.sv..."
exec xvlog -sv --work xil_defaultlib \
    -i "$TEST_DIR/dv/env" \
    "$TEST_DIR/dv/env/uart_unit_test_pkg.sv" \
    -log "$SIM_DIR/compile_test_pkg.log"

# Testbench top
puts "  Compiling tb_top.sv..."
exec xvlog -sv --work xil_defaultlib \
    "$TEST_DIR/tb/tb_top.sv" \
    -log "$SIM_DIR/compile_tb_top.log"

puts "  Compilation complete."

# ── Elaborate ─────────────────────────────────────────────────────────────────
puts "=== Elaborating ==="
exec xelab -sv --debug all \
    -s $SIM_NAME \
    --snapshot $SIM_NAME \
    xil_defaultlib.$TOP_MODULE \
    -log "$SIM_DIR/elaborate.log"
puts "  Elaboration complete."

# ── Simulate ──────────────────────────────────────────────────────────────────
puts "=== Starting Simulation ==="
puts "  Plusargs: $PLUSARGS"

# Open simulator
open_wave_config

# Run with waveform
xsim $SIM_NAME -testplusarg [join [split $PLUSARGS " "] " -testplusarg "] \
    -log "$SIM_DIR/simulate.log" \
    -wdb "$SIM_DIR/${SIM_NAME}.wdb"

# ── Add waveforms ──────────────────────────────────────────────────────────────
puts "=== Adding Waveforms ==="

# Top-level UART signals
add_wave /tb_top/if_a/tx
add_wave /tb_top/if_a/rx
add_wave /tb_top/if_b/tx
add_wave /tb_top/if_b/rx

# Separator
add_wave_divider "Agent A TX"
add_wave /tb_top/if_a/tx

add_wave_divider "Agent B RX (receives A's TX)"
add_wave /tb_top/if_b/rx

add_wave_divider "Agent B TX"
add_wave /tb_top/if_b/tx

add_wave_divider "Agent A RX (receives B's TX)"
add_wave /tb_top/if_a/rx

# Run simulation to completion
run -all

puts "=== Simulation Complete ==="
puts "  Log: $SIM_DIR/simulate.log"
puts "  Waveform: $SIM_DIR/${SIM_NAME}.wdb"
puts ""
puts "To view waveforms: xsim --gui $SIM_DIR/${SIM_NAME}.wdb"

# ==============================================================================
# Standalone xsim commands (run from terminal, not Vivado GUI):
# ==============================================================================
# Step 1 — Compile:
#   xvlog -sv -f filelist.f --work xil_defaultlib
#
# Step 2 — Elaborate:
#   xelab --debug all -s uart_unit_test xil_defaultlib.tb_top
#
# Step 3 — Simulate:
#   xsim uart_unit_test -testplusarg +EVM_TESTNAME=uart_basic_test \
#         -testplusarg +evm_verbosity=HIGH -runall -log simulate.log
#
# Step 4 — View waveforms (GUI):
#   xsim uart_unit_test --gui
# ==============================================================================
