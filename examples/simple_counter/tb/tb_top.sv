//==============================================================================
// Testbench Top
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Module: tb_top
// Description: Top-level testbench module
//              Instantiates DUT, interfaces, and runs test
//==============================================================================

`timescale 1ns/1ps

module tb_top;
    
    //==========================================================================
    // Import packages
    //==========================================================================
    import evm_pkg::*;
    import agents_pkg::*;
    import test_pkg::*;
    
    //==========================================================================
    // Parameters
    //==========================================================================
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    
    //==========================================================================
    // Interfaces
    //==========================================================================
    clk_if clk_vif();
    rst_if rst_vif();
    
    //==========================================================================
    // DUT Signals
    //==========================================================================
    logic       enable;
    logic [7:0] count;
    
    //==========================================================================
    // DUT Instance
    //==========================================================================
    simple_counter dut (
        .clk     (clk_vif.clk),
        .rst_n   (rst_vif.rst_n),
        .enable  (enable),
        .count   (count)
    );
    
    //==========================================================================
    // Test Execution
    //==========================================================================
    initial begin
        simple_test test;
        
        // Set verbosity level
        evm_log::set_verbosity(EVM_HIGH);
        
        // Create test
        test = new("simple_test");
        
        // Connect interfaces to test
        test.set_interfaces(clk_vif, rst_vif, enable, count);
        
        // Run test through all phases
        evm_root::get().run_test(test);
        
        // Finish simulation
        #100ns;  // Extra time to see final waveforms
        $display("\n=== SIMULATION COMPLETE ===\n");
        $finish;
    end
    
    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #100us;  // Maximum simulation time
        $display("\nERROR: Simulation timeout at 100us!");
        $finish;
    end
    
    //==========================================================================
    // Waveform Dumping
    //==========================================================================
    initial begin
        $dumpfile("sim/simple_counter_tb.vcd");
        $dumpvars(0, tb_top);
    end
    
endmodule : tb_top
