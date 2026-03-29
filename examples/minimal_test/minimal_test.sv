//==============================================================================
// EVM - Embedded Verification Methodology
// Minimal Test Example
// Demonstrates basic EVM test structure with quiescence counter
//==============================================================================

//==============================================================================
// Minimal Test - Shows essential EVM test structure
//==============================================================================
class minimal_test extends evm_base_test;
    
    // Quiescence counter - automatic objection management
    evm_qc qc;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "minimal_test");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Build Phase - Create components
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // Create quiescence counter
        qc = new("qc", this);
        qc.set_threshold(50);  // 50 cycles of inactivity = done
        
        log_info("Minimal test built", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Main Phase - Test execution
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        log_info("========================================", EVM_LOW);
        log_info("   MINIMAL TEST STARTING", EVM_LOW);
        log_info("========================================", EVM_LOW);
        
        // Manual objection (optional - shows manual control)
        raise_objection("test");
        
        // Simulate some activity
        repeat(10) begin
            #10ns;
            qc.tick();  // Signal activity
            log_info("Test activity...", EVM_MEDIUM);
        end
        
        // Drop manual objection
        drop_objection("test");
        
        // QC will auto-drop after 50 cycles of inactivity
        log_info("Test stimulus complete - waiting for quiescence...", EVM_LOW);
    endtask
    
    //==========================================================================
    // Final Phase - Print results
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        // Print summary
        evm_report_handler::print_summary();
        
        log_info("========================================", EVM_LOW);
        log_info("   MINIMAL TEST COMPLETE", EVM_LOW);
        log_info("========================================", EVM_LOW);
    endfunction
    
endclass : minimal_test

//==============================================================================
// Test Top Module
//==============================================================================
module minimal_test_top;
    
    // Import EVM package
    import evm_pkg::*;
    
    // Test instance
    minimal_test test;
    
    // Initial block - runs test
    initial begin
        // Create and run test
        test = new("minimal_test");
        
        // Execute test (calls all phases)
        evm_root::get().run_test(test);
        
        // Test complete - simulator will $finish after objections drop
    end
    
endmodule : minimal_test_top
