//==============================================================================
// EVM Complete Test Example
// Demonstrates full EVM flow: Monitor → Scoreboard with TLM
//==============================================================================

//==============================================================================
// Package: complete_test_pkg
//==============================================================================
package complete_test_pkg;
    import evm_pkg::*;
    
    //==========================================================================
    // Transaction
    //==========================================================================
    class my_txn extends evm_sequence_item;
        rand bit [7:0] addr;
        rand bit [31:0] data;
        rand bit write;
        
        function new(string name = "my_txn");
            super.new(name);
        endfunction
        
        // Comparison for scoreboard
        virtual function bit do_compare(evm_object rhs, output string msg);
            my_txn t;
            if (!$cast(t, rhs)) begin
                msg = "Cast failed";
                return 0;
            end
            
            if (this.addr != t.addr) begin
                msg = $sformatf("addr: 0x%02h != 0x%02h", this.addr, t.addr);
                return 0;
            end
            if (this.data != t.data) begin
                msg = $sformatf("data: 0x%08h != 0x%08h", this.data, t.data);
                return 0;
            end
            if (this.write != t.write) begin
                msg = $sformatf("write: %0b != %0b", this.write, t.write);
                return 0;
            end
            return 1;
        endfunction
        
        virtual function string convert2string();
            return $sformatf("addr=0x%02h data=0x%08h %s",
                            addr, data, write ? "WR" : "RD");
        endfunction
    endclass
    
    //==========================================================================
    // Monitor - Uses run_phase for continuous monitoring
    //==========================================================================
    class my_monitor extends evm_monitor#(virtual my_if, my_txn);
        
        function new(string name = "my_monitor", evm_component parent = null);
            super.new(name, parent);
        endfunction
        
        // Moved from main_phase to run_phase for continuous operation
        virtual task run_phase();
            my_txn txn;
            
            super.run_phase();  // Starts reset event monitoring
            
            // Wait for reset
            wait(vif.reset_n == 1);
            log_info("Monitor active after reset", EVM_MEDIUM);
            
            fork
                begin
                    // Continuous monitoring loop
                    forever begin
                        // Check if in reset
                        if (!in_reset) begin
                            // Collect transaction
                            txn = new("monitored_txn");
                            
                            // Wait for valid transaction
                            @(posedge vif.clk);
                            if (vif.valid && vif.ready) begin
                                txn.addr = vif.addr;
                                txn.data = vif.data;
                                txn.write = vif.write;
                                
                                // Broadcast to all subscribers
                                analysis_port.write(txn);
                                
                                log_info($sformatf("Monitored: %s", txn.convert2string()), EVM_HIGH);
                            end
                        end
                        else begin
                            // Paused during reset - wait for deassertion
                            @(reset_deasserted);
                        end
                    end
                end
            join_none
        endtask
        
        // Handle reset assertion - flush any partial transactions
        virtual task on_reset_assert();
            super.on_reset_assert();
            log_info("Monitor: Pausing collection due to reset", EVM_HIGH);
        endtask
        
        // Handle reset deassertion - resume monitoring
        virtual task on_reset_deassert();
            super.on_reset_deassert();
            log_info("Monitor: Resuming collection after reset", EVM_HIGH);
        endtask
        
        virtual function string get_type_name();
            return "my_monitor";
        endfunction
    endclass
    
    //==========================================================================
    // Scoreboard
    //==========================================================================
    class my_scoreboard extends evm_scoreboard#(my_txn);
        
        function new(string name = "my_scoreboard", evm_component parent = null);
            super.new(name, parent);
            
            // Configure
            mode = EVM_SB_FIFO;
            enable_auto_check = 1;
            stop_on_mismatch = 0;
        endfunction
        
        // Override compare for custom messages
        virtual function bit compare_transactions(my_txn expected, my_txn actual);
            string msg;
            bit match = expected.compare(actual, msg);
            
            if (match) begin
                match_count++;
                log_info($sformatf("MATCH #%0d: %s", 
                                  match_count, actual.convert2string()), EVM_MEDIUM);
            end else begin
                mismatch_count++;
                log_error($sformatf("MISMATCH #%0d: %s", mismatch_count, msg));
                log_error($sformatf("  Expected: %s", expected.convert2string()));
                log_error($sformatf("  Actual:   %s", actual.convert2string()));
            end
            
            return match;
        endfunction
    endclass
    
    //==========================================================================
    // Environment
    //==========================================================================
    class my_env extends evm_component;
        
        my_monitor monitor;
        my_scoreboard scoreboard;
        
        function new(string name = "my_env", evm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase();
            super.build_phase();
            
            monitor = new("monitor", this);
            scoreboard = new("scoreboard", this);
            
            log_info("Environment built", EVM_MEDIUM);
        endfunction
        
        virtual function void connect_phase();
            super.connect_phase();
            
            // Connect monitor to scoreboard via TLM
            monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
            
            log_info("Monitor → Scoreboard connected", EVM_MEDIUM);
        endfunction
        
        function void set_vif(virtual my_if vif);
            monitor.set_vif(vif);
        endfunction
    endclass
    
    //==========================================================================
    // Test
    //==========================================================================
    class my_test extends evm_base_test;
        
        my_env env;
        
        function new(string name = "my_test");
            super.new(name);
        endfunction
        
        virtual function void build_phase();
            super.build_phase();
            
            // Enable file logging
            evm_report_handler::enable_file_logging("complete_test.log");
            
            // Set verbosity
            evm_report_handler::set_verbosity(EVM_MEDIUM);
            
            // Create environment
            env = new("env", this);
            
            log_info("Test built", EVM_LOW);
        endfunction
        
        virtual function void end_of_elaboration_phase();
            super.end_of_elaboration_phase();
            
            // Print topology
            print_topology();
        endfunction
        
        virtual task main_phase();
            my_txn expected;
            
            super.main_phase();
            raise_objection("test_stimulus");
            
            log_info("=== Test Starting ===", EVM_LOW);
            
            // Generate expected transactions
            repeat(10) begin
                expected = new("expected");
                assert(expected.randomize());
                
                env.scoreboard.insert_expected(expected);
                
                log_info($sformatf("Expected: %s", expected.convert2string()), EVM_MEDIUM);
                
                #100ns;
            end
            
            // Wait for all transactions to be monitored
            #500ns;
            
            log_info("=== Test Complete ===", EVM_LOW);
            drop_objection("test_stimulus");
        endtask
        
        virtual function void final_phase();
            super.final_phase();
            
            // Print summary
            evm_report_handler::print_summary();
        endfunction
    endclass
    
endpackage

//==============================================================================
// Interface
//==============================================================================
interface my_if(input logic clk);
    logic reset_n;
    logic [7:0] addr;
    logic [31:0] data;
    logic write;
    logic valid;
    logic ready;
    
    clocking mon_cb @(posedge clk);
        input addr, data, write, valid, ready;
    endclocking
endinterface

//==============================================================================
// DUT (Simple passthrough for demonstration)
//==============================================================================
module my_dut(
    input logic clk,
    input logic reset_n,
    input logic [7:0] addr,
    input logic [31:0] data,
    input logic write,
    input logic valid,
    output logic ready
);
    // Simple passthrough with 1-cycle delay
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ready <= 0;
        end else begin
            ready <= valid;
        end
    end
endmodule

//==============================================================================
// Testbench Top
//==============================================================================
module tb_top;
    import evm_pkg::*;
    import complete_test_pkg::*;
    
    // Clock generation
    logic clk = 0;
    always #5 clk = ~clk;  // 100MHz
    
    // Interface
    my_if dut_if(clk);
    
    // DUT
    my_dut dut(
        .clk(clk),
        .reset_n(dut_if.reset_n),
        .addr(dut_if.addr),
        .data(dut_if.data),
        .write(dut_if.write),
        .valid(dut_if.valid),
        .ready(dut_if.ready)
    );
    
    // Stimulus generator (simulates actual DUT activity)
    initial begin
        dut_if.reset_n = 0;
        dut_if.addr = 0;
        dut_if.data = 0;
        dut_if.write = 0;
        dut_if.valid = 0;
        
        // Release reset
        #50ns;
        dut_if.reset_n = 1;
        #10ns;
        
        // Generate random transactions
        repeat(10) begin
            @(posedge clk);
            dut_if.addr = $random;
            dut_if.data = $random;
            dut_if.write = $random;
            dut_if.valid = 1;
            
            // Wait for ready
            wait(dut_if.ready);
            @(posedge clk);
            dut_if.valid = 0;
            
            #100ns;
        end
    end
    
    // Test execution
    initial begin
        my_test test;
        
        // Create test
        test = new("complete_test");
        
        // Connect interface
        test.env.set_vif(dut_if);
        
        // Run test
        evm_root::get().run_test(test);
        
        $finish;
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("complete_test.vcd");
        $dumpvars(0, tb_top);
    end
    
endmodule
