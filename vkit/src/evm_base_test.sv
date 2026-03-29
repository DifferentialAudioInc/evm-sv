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
//              Includes optional built-in Quiescence Counter (evm_qc)
// Author: Engineering Team
// Date: 2026-03-05
// Updated: 2026-03-29 - Added optional quiescence counter support
//==============================================================================

virtual class evm_base_test extends evm_component;
    
    //==========================================================================
    // Properties
    //==========================================================================
    string test_name;
    
    //==========================================================================
    // Built-in Quiescence Counter (optional)
    //==========================================================================
    evm_qc qc;                          // Quiescence counter component
    bit enable_qc = 0;                  // Enable/disable QC (default: disabled)
    int qc_threshold = 100;             // Quiescence threshold in cycles
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_base_test");
        super.new(name, null);  // Tests have no parent
        this.test_name = name;
    endfunction
    
    //==========================================================================
    // Build Phase - Create optional quiescence counter + process command-line
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // Process command-line arguments
        process_cmdline_args();
        
        // Create quiescence counter if enabled
        if (enable_qc) begin
            qc = new("qc", this);
            qc.set_threshold(qc_threshold);
            log_info($sformatf("Quiescence Counter enabled (threshold=%0d)", qc_threshold), EVM_MEDIUM);
        end else begin
            log_info("Quiescence Counter disabled (enable_qc=0)", EVM_HIGH);
        end
    endfunction
    
    //==========================================================================
    // Process Command-line Arguments
    //==========================================================================
    virtual function void process_cmdline_args();
        evm_verbosity_e cmdline_verbosity;
        string log_file;
        int seed;
        
        // Process verbosity
        cmdline_verbosity = evm_cmdline::get_verbosity(EVM_MEDIUM);
        evm_report_handler::set_verbosity(cmdline_verbosity);
        
        // Process log file
        if (evm_cmdline::has_plusarg("evm_log") || evm_cmdline::has_plusarg("log")) begin
            log_file = evm_cmdline::get_log_file();
            evm_report_handler::enable_file_logging(log_file);
            log_info($sformatf("File logging enabled: %s", log_file), EVM_MEDIUM);
        end
        
        // Process seed
        seed = evm_cmdline::get_seed();
        if (seed != 0) begin
            $urandom(seed);
            log_info($sformatf("Random seed set to: %0d", seed), EVM_MEDIUM);
        end
        
        // Print command-line args if debug mode
        if (evm_cmdline::has_plusarg("evm_debug")) begin
            evm_cmdline::print_args();
        end
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
    // Quiescence Counter Configuration
    //==========================================================================
    
    // Enable quiescence counter with optional threshold
    function void enable_quiescence_counter(int threshold = 100);
        enable_qc = 1;
        qc_threshold = threshold;
        log_info($sformatf("Quiescence Counter will be enabled with threshold=%0d", threshold), EVM_MEDIUM);
    endfunction
    
    // Disable quiescence counter
    function void disable_quiescence_counter();
        enable_qc = 0;
        if (qc != null) begin
            qc.disable();
        end
        log_info("Quiescence Counter disabled", EVM_MEDIUM);
    endfunction
    
    // Get quiescence counter handle (for manual tick() calls)
    function evm_qc get_qc();
        return qc;
    endfunction
    
    // Check if QC is enabled
    function bit is_qc_enabled();
        return (enable_qc && qc != null);
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
