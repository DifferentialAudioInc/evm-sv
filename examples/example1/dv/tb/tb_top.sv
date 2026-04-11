//==============================================================================
// Module: tb_top
// Description: Testbench top for the AXI Data Transform example
//
//   Instantiates:
//     - Clock/reset generation (100 MHz, sync active-low reset)
//     - slave_if  (TB → DUT AXI4-Lite slave port)
//     - master_if (DUT AXI4-Lite master → TB sink)
//     - gpio_if   (DUT GPIO output → observation)
    //     - example1 DUT
//     - Simple AXI4-Lite slave sink (accepts DUT master writes)
//
//   Test selection via plusarg: +EVM_TESTNAME=<name>
//   Available tests: basic_write_test, multi_xform_test, random_test
//
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

import evm_pkg::*;
import evm_vkit_pkg::*;
import example1_pkg::*;
import axi_data_xform_csr_pkg::*;

module tb_top;
    
    //==========================================================================
    // Clock and Reset
    //==========================================================================
    logic clk   = 1'b0;
    logic rst_n = 1'b0;
    
    always #5ns clk = ~clk;  // 100 MHz
    
    initial begin
        rst_n = 1'b0;
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        $display("[TB_TOP] Reset released at %0t", $realtime);
    end
    
    //==========================================================================
    // Interfaces
    //==========================================================================
    
    // AXI4-Lite slave interface (TB → DUT)
    evm_axi_lite_if slave_if(.aclk(clk), .aresetn(rst_n));
    
    // AXI4-Lite master interface (DUT → TB sink)
    evm_axi_lite_if master_if(.aclk(clk), .aresetn(rst_n));
    
    // GPIO observation interface
    gpio_if gpio_port();
    
    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    example1 dut (
        .aclk       (clk),
        .aresetn    (rst_n),
        
        // Slave (TB → DUT)
        .s_awaddr   (slave_if.awaddr[11:0]),
        .s_awvalid  (slave_if.awvalid),
        .s_awready  (slave_if.awready),
        .s_wdata    (slave_if.wdata),
        .s_wstrb    (slave_if.wstrb),
        .s_wvalid   (slave_if.wvalid),
        .s_wready   (slave_if.wready),
        .s_bresp    (slave_if.bresp),
        .s_bvalid   (slave_if.bvalid),
        .s_bready   (slave_if.bready),
        .s_araddr   (slave_if.araddr[11:0]),
        .s_arvalid  (slave_if.arvalid),
        .s_arready  (slave_if.arready),
        .s_rdata    (slave_if.rdata),
        .s_rresp    (slave_if.rresp),
        .s_rvalid   (slave_if.rvalid),
        .s_rready   (slave_if.rready),
        
        // Master (DUT → TB sink)
        .m_awaddr   (master_if.awaddr),
        .m_awvalid  (master_if.awvalid),
        .m_awready  (master_if.awready),
        .m_wdata    (master_if.wdata),
        .m_wstrb    (master_if.wstrb),
        .m_wvalid   (master_if.wvalid),
        .m_wready   (master_if.wready),
        .m_bresp    (master_if.bresp),
        .m_bvalid   (master_if.bvalid),
        .m_bready   (master_if.bready),
        
        .gpio_out   (gpio_port.gpio)
    );
    
    //==========================================================================
    // Simple AXI4-Lite Slave Sink
    // Accepts all writes from DUT master interface immediately.
    // The monitor passively observes everything on master_if.
    //==========================================================================
    logic sink_wr_pending;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            master_if.awready   <= 1'b0;
            master_if.wready    <= 1'b0;
            master_if.bvalid    <= 1'b0;
            master_if.bresp     <= 2'b00;
            master_if.arready   <= 1'b0;
            master_if.rdata     <= 32'h0;
            master_if.rresp     <= 2'b00;
            master_if.rvalid    <= 1'b0;
            sink_wr_pending     <= 1'b0;
        end else begin
            // Always accept AW and W
            master_if.awready <= 1'b1;
            master_if.wready  <= 1'b1;
            
            // Drive B response when DUT sends a write
            if (!sink_wr_pending) begin
                if (master_if.awvalid && master_if.wvalid) begin
                    sink_wr_pending  <= 1'b1;
                    master_if.bvalid <= 1'b1;
                    master_if.bresp  <= 2'b00;  // OKAY
                end
            end else begin
                if (master_if.bvalid && master_if.bready) begin
                    master_if.bvalid <= 1'b0;
                    sink_wr_pending  <= 1'b0;
                end
            end
        end
    end
    
    //==========================================================================
    // Test Execution
    // Variables declared at top of initial block (Vivado xvlog requirement)
    //==========================================================================
    initial begin
        // All declarations at top of initial block
        automatic example1_base_test t     = null;
        automatic evm_base_test      base_t = null;
        automatic basic_write_test   dflt   = null;
        automatic string             testname = "";
        
        // Wait for reset
        @(posedge rst_n);
        repeat(2) @(posedge clk);
        
        // Create test via registry (+EVM_TESTNAME=<name>)
        if ($value$plusargs("EVM_TESTNAME=%s", testname)) begin
            base_t = evm_test_registry::create_test(testname);
            if (base_t == null) begin
                $fatal(1, "[TB_TOP] Unknown test: %s", testname);
            end
            if (!$cast(t, base_t)) begin
                $fatal(1, "[TB_TOP] Test %s is not an example1_base_test", testname);
            end
        end else begin
            // Default test — instantiate concrete subclass (not virtual base)
            $display("[TB_TOP] No +EVM_TESTNAME — running basic_write_test");
            dflt = new("basic_write_test");
            t = dflt;
        end
        
        // Pass virtual interfaces to test
        t.slave_vif  = slave_if;
        t.master_vif = master_if;
        t.gpio_vif   = gpio_port;
        
        // Run all phases
        evm_root::get().run_test(t);
        
        $finish;
    end
    
    //==========================================================================
    // Test Registry — EVM_REGISTER_TEST at MODULE scope (macro contains initial block)
    // Each macro expands to: class declaration + initial begin...end
    // initial blocks only allowed in modules, NOT inside packages
    //==========================================================================
    `EVM_REGISTER_TEST(basic_write_test)
    `EVM_REGISTER_TEST(multi_xform_test)
    `EVM_REGISTER_TEST(random_test)
    
    //==========================================================================
    // Waveform dump
    //==========================================================================
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
    end
    
    //==========================================================================
    // Timeout watchdog
    //==========================================================================
    initial begin
        #10ms;
        $fatal(1, "[TB_TOP] Simulation timeout after 10ms");
    end
    
endmodule : tb_top
