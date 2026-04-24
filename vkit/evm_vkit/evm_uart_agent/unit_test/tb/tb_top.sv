//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: tb_top.sv
// Description: UART unit test top-level testbench.
//              Two back-to-back UART interfaces — no DUT, pure agent loopback.
//
// Signal routing:
//   if_a.tx → if_b.rx   (Agent A transmits → Agent B receives)
//   if_b.tx → if_a.rx   (Agent B transmits → Agent A receives)
//
// No "DUT" needed — the loopback verifies the UART agent transmitter and
// receiver against each other, exercising all four analysis ports and both
// scoreboards.
//
// Run: +EVM_TESTNAME=uart_basic_test
//      +evm_verbosity=HIGH
//      (Vivado: add tb_top.v to simulation set, set top to tb_top)
//==============================================================================

`timescale 1ns/1ps

module tb_top;

    //==========================================================================
    // Imports
    //==========================================================================
    import evm_pkg::*;
    import evm_vkit_pkg::*;
    import uart_unit_test_pkg::*;

    //==========================================================================
    // System clock (100 MHz — not used by UART, but needed for EVM infrastructure)
    //==========================================================================
    logic sys_clk  = 1'b0;
    logic sys_rst_n = 1'b1;
    always #5ns sys_clk = ~sys_clk;  // 100 MHz
    
    //==========================================================================
    // UART Interfaces
    //   if_a: Agent A's perspective (A.tx drives the wire, A.rx reads it)
    //   if_b: Agent B's perspective (B.tx drives the wire, B.rx reads it)
    //==========================================================================
    evm_uart_if if_a();
    evm_uart_if if_b();
    
    //==========================================================================
    // Cross-connect: loopback without a DUT
    //   A.tx → B.rx: what A sends, B receives
    //   B.tx → A.rx: what B sends, A receives
    //==========================================================================
    assign if_b.rx = if_a.tx;   // Agent A transmits → Agent B receives
    assign if_a.rx = if_b.tx;   // Agent B transmits → Agent A receives
    
    // CTS loopback (not used in 8N1 mode, always assert)
    assign if_a.cts = 1'b1;
    assign if_b.cts = 1'b1;
    
    //==========================================================================
    // EVM test runner — runs default test or +EVM_TESTNAME= selected test
    //==========================================================================
    initial begin : evm_run
        automatic string       testname;
        automatic evm_base_test test;
        
        // Apply random seed
        evm_cmdline::set_random_seed();
        
        // Print plusargs if debug mode
        if (evm_cmdline::has_plusarg("evm_debug"))
            evm_cmdline::print_args();
        
        // Select and run test
        if ($value$plusargs("EVM_TESTNAME=%s", testname)) begin
            test = evm_test_registry::create_test(testname);
            if (test == null) begin
                $display("[TB] ERROR: Test '%s' not registered. Available tests:", testname);
                evm_test_registry::list_tests();
                $finish(1);
            end
        end else begin
            // Default: run uart_basic_test
            begin
                automatic uart_basic_test t = new("uart_basic_test");
                test = t;
            end
        end
        
        evm_root::get().run_test(test);
        
        // Final pass/fail
        if (evm_report_handler::get_error_count() == 0 &&
            evm_report_handler::get_unmet_expectation_count() == 0) begin
            $display("[TB] *** SIMULATION PASSED ***");
        end else begin
            $display("[TB] *** SIMULATION FAILED ***");
        end
        
        $finish;
    end : evm_run
    
    //==========================================================================
    // Waveform capture (Vivado xsim: auto-captured; GTKWave: uncomment below)
    //==========================================================================
    // initial begin
    //     $dumpfile("uart_unit_test.vcd");
    //     $dumpvars(0, tb_top);
    // end
    
    //==========================================================================
    // Simulation timeout safety net
    //==========================================================================
    initial begin
        #50ms;
        $display("[TB] TIMEOUT: Simulation exceeded 50ms limit");
        $finish(2);
    end

endmodule : tb_top
