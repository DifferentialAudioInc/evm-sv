//==============================================================================
// EVM - Embedded Verification Methodology
// Quiescence Counter Example Test
// Demonstrates automatic test completion using built-in QC
//==============================================================================

`timescale 1ns/1ps

module qc_test;
    import evm_pkg::*;
    
    //==========================================================================
    // Simple Transaction
    //==========================================================================
    class simple_txn extends evm_sequence_item;
        rand int data;
        
        function new(string name = "simple_txn");
            super.new(name);
        endfunction
    endclass
    
    //==========================================================================
    // Simple Driver - Signals activity to QC
    //==========================================================================
    class simple_driver extends evm_driver#(simple_txn);
        evm_qc qc;  // Reference to QC
        
        function new(string name, evm_component parent);
            super.new(name, parent);
        endfunction
        
        // Set QC reference
        function void set_qc(evm_qc qc_handle);
            this.qc = qc_handle;
        endfunction
        
        virtual task run_phase();
            simple_txn txn;
            
            forever begin
                // Get transaction from sequencer
                seq_item_port.get_next_item(txn);
                
                // Drive transaction
                log_info($sformatf("Driving txn with data=%0d", txn.data), EVM_MEDIUM);
                #100ns;
                
                // Signal activity to QC
                if (qc != null) begin
                    qc.tick();
                    log_info("Activity tick sent to QC", EVM_HIGH);
                end
                
                seq_item_port.item_done();
            end
        endtask
    endclass
    
    //==========================================================================
    // Simple Sequence - Generates transactions
    //==========================================================================
    class simple_sequence extends evm_sequence#(simple_txn);
        int num_txns = 10;
        
        function new(string name = "simple_sequence");
            super.new(name);
        endfunction
        
        virtual task body();
            log_info($sformatf("Starting sequence with %0d transactions", num_txns), EVM_MEDIUM);
            
            repeat(num_txns) begin
                simple_txn txn = new("txn");
                assert(txn.randomize());
                start_item(txn);
                finish_item(txn);
                #50ns;  // Gap between transactions
            end
            
            log_info("Sequence complete", EVM_MEDIUM);
        endtask
    endclass
    
    //==========================================================================
    // Test with Quiescence Counter
    //==========================================================================
    class qc_example_test extends evm_base_test;
        simple_driver driver;
        evm_sequencer#(simple_txn) sequencer;
        simple_sequence seq;
        
        function new(string name = "qc_example_test");
            super.new(name);
            
            // Enable quiescence counter BEFORE build_phase
            // Threshold = 200 cycles (2x transaction time)
            enable_quiescence_counter(200);
        endfunction
        
        virtual function void build_phase();
            super.build_phase();  // Creates QC automatically!
            
            // Create driver and sequencer
            driver = new("driver", this);
            sequencer = new("sequencer", this);
            
            // Create sequence
            seq = new("seq");
            seq.num_txns = 10;
            
            log_info("Test components created", EVM_MEDIUM);
        endfunction
        
        virtual function void connect_phase();
            super.connect_phase();
            
            // Connect driver to sequencer
            driver.seq_item_port.connect(
                sequencer.seq_item_export.get_req_fifo(),
                sequencer.seq_item_export.get_rsp_fifo()
            );
            
            // Give driver access to QC for tick() calls
            driver.set_qc(qc);
            
            log_info("Connections complete", EVM_MEDIUM);
        endfunction
        
        virtual task main_phase();
            super.main_phase();
            
            // NO manual objection needed!
            // QC will automatically:
            // 1. Raise objection on first tick()
            // 2. Drop objection after 200 cycles of inactivity
            
            log_info("Starting test sequence...", EVM_LOW);
            
            // Start sequence on sequencer
            seq.start(sequencer);
            
            log_info("Sequence started - QC will handle test completion", EVM_LOW);
            
            // Test continues until QC detects quiescence
            // NO manual drop_objection() needed!
        endtask
        
        virtual function void report_phase();
            super.report_phase();
            
            // QC automatically prints statistics
            log_info("==============================================", EVM_LOW);
            log_info("Test completed via Quiescence Counter!", EVM_LOW);
            log_info("==============================================", EVM_LOW);
        endfunction
    endclass
    
    //==========================================================================
    // Traditional Test (Manual Objections)
    //==========================================================================
    class manual_test extends evm_base_test;
        simple_driver driver;
        evm_sequencer#(simple_txn) sequencer;
        simple_sequence seq;
        
        function new(string name = "manual_test");
            super.new(name);
            // QC disabled by default
        endfunction
        
        virtual function void build_phase();
            super.build_phase();
            driver = new("driver", this);
            sequencer = new("sequencer", this);
            seq = new("seq");
            seq.num_txns = 10;
        endfunction
        
        virtual function void connect_phase();
            super.connect_phase();
            driver.seq_item_port.connect(
                sequencer.seq_item_export.get_req_fifo(),
                sequencer.seq_item_export.get_rsp_fifo()
            );
        endfunction
        
        virtual task main_phase();
            super.main_phase();
            
            // Manual objection management
            raise_objection("manual_test");
            
            log_info("Starting manual test sequence...", EVM_LOW);
            seq.start(sequencer);
            
            // Wait for sequence to complete
            #5us;
            
            drop_objection("manual_test");
        endtask
    endclass
    
    //==========================================================================
    // Testbench Top
    //==========================================================================
    initial begin
        evm_root root;
        qc_example_test test;
        
        // Initialize root
        root = evm_root::init("qc_test_tb");
        
        // Configure reporting
        evm_report_handler::set_verbosity(EVM_MEDIUM);
        evm_report_handler::enable_file_logging("qc_test.log");
        
        // Create and run test
        test = new("qc_example_test");
        
        $display("================================================================================");
        $display("EVM Quiescence Counter Example");
        $display("================================================================================");
        $display("This test demonstrates automatic test completion using QC");
        $display("- Driver calls qc.tick() on each transaction");
        $display("- QC auto-raises objection on first activity");
        $display("- QC auto-drops objection after 200 cycles of inactivity");
        $display("- Test ends gracefully without manual objection management!");
        $display("================================================================================");
        
        // Run all phases
        root.run_test(test);
        
        // Print final summary
        evm_report_handler::print_summary();
        
        $display("");
        $display("Test complete - check qc_test.log for details");
        $finish;
    end
    
endmodule
