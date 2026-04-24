# ==============================================================================
# EVM UART Agent Unit Test — Vivado xvlog filelist
# ==============================================================================
# File: filelist.f
# Location: evm_uart_agent/unit_test/sim/
# Usage: xvlog -sv -f filelist.f
#
# Compile order:
#   1. EVM core package (evm_pkg)
#   2. UART interface (module — outside package)
#   3. EVM vkit package (evm_vkit_pkg — includes UART agent)
#   4. Unit test package (uart_unit_test_pkg)
#   5. Testbench top module
# ==============================================================================

# ── EVM Core Package ──────────────────────────────────────────────────────────
# From: evm_uart_agent/unit_test/sim/ → vkit/src/
../../../../src/evm_pkg.sv

# ── UART Interface (module — outside any package) ─────────────────────────────
# From: evm_uart_agent/unit_test/sim/ → evm_uart_agent/
../../evm_uart_if.sv

# ── EVM VKit Package ──────────────────────────────────────────────────────────
# From: evm_uart_agent/unit_test/sim/ → evm_vkit/
../../../evm_vkit_pkg.sv

# ── Unit Test Package ─────────────────────────────────────────────────────────
# From: evm_uart_agent/unit_test/sim/ → unit_test/dv/env/
../../dv/env/uart_unit_test_pkg.sv

# ── Testbench Top ─────────────────────────────────────────────────────────────
# From: evm_uart_agent/unit_test/sim/ → unit_test/tb/
../../tb/tb_top.sv
