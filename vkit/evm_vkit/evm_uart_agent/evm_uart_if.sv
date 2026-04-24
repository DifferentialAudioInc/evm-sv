//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_uart_if.sv
// Description: UART interface — TX, RX, and optional CTS/RTS flow control.
//              Full-duplex: TX driven by testbench driver, RX driven by DUT.
//              Fixed signal set (Vivado xvlog compatible).
//
// Signal ownership (from testbench perspective):
//   tx:  driven by evm_uart_driver  → connect to DUT.rx input
//   rx:  driven by DUT              → connect to DUT.tx output
//   rts: driven by evm_uart_driver  → testbench "ready to receive" (output)
//   cts: driven by DUT              → DUT "clear to send" (input to testbench)
//
// tb_top wiring:
//   evm_uart_if uart_if();
//   assign dut_inst.rx     = uart_if.tx;   // EVM sends → DUT receives
//   assign uart_if.rx      = dut_inst.tx;  // DUT sends → EVM receives
//==============================================================================

interface evm_uart_if;
    logic tx   = 1'b1;  // testbench → DUT; idle high
    logic rx   = 1'b1;  // DUT → testbench; idle high
    logic rts  = 1'b1;  // testbench ready-to-receive (output)
    logic cts  = 1'b1;  // DUT clear-to-send (input, driven by DUT)
endinterface : evm_uart_if
