//==============================================================================
// EVM Full Phases Example - Testbench Top
// Complete testbench showing all phases with clock/reset agents
//==============================================================================

//==============================================================================
// Test Package
//==============================================================================
package test_pkg;
    import evm_pkg::*;
    
    // Include all test components
    `include "clk_agent.sv"
    `include "rst_agent.sv"
    `include "base_test.sv"
    
endpackage

//==============================================================================
// Testbench Top Module
//==============================================================================
module tb_top;
    import evm_pkg::*;
    import test_pkg::*;
    
    //==========================================================================
    // Clock Generation
    //==========================================================================
    logic sys_clk = 0;
    always #5ns sys_clk = ~sys_clk;  // 100MHz clock
    
    //==========================================================================
    // Interface Instances
    //==========================================================================
    clk_if clk_vif();
    rst_if rst_vif(sys_clk);
    dut_if dut_vif(sys_clk);
    
    // Connect clock interface to actual clock
    assign clk_vif.clk = sys_clk;
    
    //==========================================================================
    // DUT Instance
    //==========================================================================
    simple_dut dut(
        .clk(sys_clk),
        .reset_n(rst_vif.reset_n),
        .data_in(dut_vif.data_in),
        .data_valid(dut_vif.data_valid),
        .data_out(dut_vif.data_out),
        .data_ready(dut_vif.data_ready)
    );
    
    //==========================================================================
    // Connect DUT to interfaces
    //==========================================================================
    assign dut_vif.reset_n = rst_vif.reset_n;
    
    //==========================================================================
    // Simple Stimulus (for demonstration)
    //==========================================================================
    initial begin
        dut_vif.data_in = 8'h00;
        dut_vif.data_valid = 1'b0;
        
        // Wait for reset
        wait(rst_vif.reset_n == 1);
        @(posedge sys_clk);
        @(posedge sys_clk);
        
        // Send some data
        repeat(5) begin
            @(posedge sys_clk);
            dut_vif.data_in = $random;
            dut_vif.data_valid = 1'b1;
            
            wait(dut_vif.data_ready == 1);
            @(posedge sys_clk);
            dut_vif.data_valid = 1'b0;
            
            #100ns;
        end
    end
    
    //==========================================================================
    // Test Execution
    //==========================================================================
    initial begin
        base_test test;
        
        $display("");
        $display("================================================================================");
        $display("  EVM FULL PHASES EXAMPLE");
        $display("  Demonstrates all 12 phases with proper super calls");
        $display("================================================================================");
        $display("");
        
        // Create test
        test = new("full_phases_test");
        
        // Connect interfaces
        test.set_interfaces(clk_vif, rst_vif);
        
        // Run test (all phases executed automatically)
        evm_root::get().run_test(test);
        
        $display("");
        $display("================================================================================");
        $display("  SIMULATION COMPLETE");
        $display("================================================================================");
        $display("");
        
        $finish;
    end
    
    //==========================================================================
    // Waveform Dumping
    //==========================================================================
    initial begin
        $dumpfile("full_phases_test.vcd");
        $dumpvars(0, tb_top);
    end
    
    //==========================================================================
    // Timeout
    //==========================================================================
    initial begin
        #10ms;
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule
