//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_base_test
// Description: Base test class for Embedded Verification Methodology (EVM)
//              Extends evm_component (not root!)
//              Accesses root singleton for phase control and objections
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_base_test extends evm_component;
    
    //==========================================================================
    // Properties
    //==========================================================================
    string test_name;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_base_test");
        super.new(name, null);  // Tests have no parent
        this.test_name = name;
    endfunction
    
    //==========================================================================
    // Convenience methods to access root objections
    //==========================================================================
    
    function void raise_objection(string description = "");
        evm_root::get().raise_objection(description);
    endfunction
    
    function void drop_objection(string description = "");
        evm_root::get().drop_objection(description);
    endfunction
    
    //==========================================================================
    // Override main_phase - This is where test stimulus goes
    //==========================================================================
    virtual task main_phase();
        log_info("EVM Base Test main_phase (override in derived test)", EVM_LOW);
        
        // Example: Raise objection at start of test
        raise_objection("base_test_activity");
        
        // Test activity here
        #50us;
        
        // Drop objection when done
        drop_objection("base_test_activity");
    endtask
    
    //==========================================================================
    // Override report_phase for test results
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        log_info("========================================", EVM_LOW);
        log_info($sformatf("Test: %s", test_name), EVM_LOW);
        log_info($sformatf("Errors: %0d", evm_log::error_count), EVM_LOW);
        log_info($sformatf("Warnings: %0d", evm_log::warning_count), EVM_LOW);
        if (evm_log::error_count == 0) begin
            log_info($sformatf("%s PASSED", test_name), EVM_LOW);
        end else begin
            log_error($sformatf("%s FAILED with %0d errors", test_name, evm_log::error_count));
        end
        log_info("========================================", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Get test result
    function bit get_test_result();
        return (evm_log::error_count == 0);
    endfunction
    
    // Get type name
    virtual function string get_type_name();
        return "evm_base_test";
    endfunction
    
endclass : evm_base_test
