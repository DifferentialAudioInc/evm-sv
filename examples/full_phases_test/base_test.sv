//==============================================================================
// EVM Full Phases Example - Base Test with ALL Phases
// Demonstrates proper phase usage with super calls
//==============================================================================

//==============================================================================
// Base Environment
//==============================================================================
class base_env extends evm_component;
    
    clk_agent clk_agt;
    rst_agent rst_agt;
    
    function new(string name = "base_env", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Phase 1: build_phase - Create all components
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();  // ALWAYS call super first!
        
        log_info("=== build_phase ===", EVM_LOW);
        
        // Create clock agent
        clk_agt = new("clk_agt", this);
        clk_agt.cfg.freq_mhz = 100.0;
        clk_agt.cfg.auto_start = 1;
        
        // Create reset agent
        rst_agt = new("rst_agt", this);
        rst_agt.cfg.reset_cycles = 10;
        rst_agt.cfg.active_low = 1;
        rst_agt.is_active = 1;
        
        log_info("Environment components created", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 2: connect_phase - Make all connections
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();  // ALWAYS call super first!
        
        log_info("=== connect_phase ===", EVM_LOW);
        
        // Connections would go here (TLM ports, etc.)
        log_info("Environment connections complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 3: end_of_elaboration_phase - Final checks before sim
    //==========================================================================
    virtual function void end_of_elaboration_phase();
        super.end_of_elaboration_phase();
        
        log_info("=== end_of_elaboration_phase ===", EVM_LOW);
        log_info("Environment elaboration complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 4: start_of_simulation_phase - Pre-run initialization
    //==========================================================================
    virtual function void start_of_simulation_phase();
        super.start_of_simulation_phase();
        
        log_info("=== start_of_simulation_phase ===", EVM_LOW);
        log_info("Simulation ready to start", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 5: reset_phase - Apply resets
    //==========================================================================
    virtual task reset_phase();
        super.reset_phase();
        
        log_info("=== reset_phase ===", EVM_LOW);
        // Reset is driven by rst_agent.driver
    endtask
    
    //==========================================================================
    // Phase 6: configure_phase - Configure DUT
    //==========================================================================
    virtual task configure_phase();
        super.configure_phase();
        
        log_info("=== configure_phase ===", EVM_LOW);
        log_info("DUT configuration complete", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Phase 7: main_phase - Main test execution
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        log_info("=== main_phase ===", EVM_LOW);
        // Test stimulus happens here
    endtask
    
    //==========================================================================
    // Phase 8: shutdown_phase - Graceful shutdown
    //==========================================================================
    virtual task shutdown_phase();
        super.shutdown_phase();
        
        log_info("=== shutdown_phase ===", EVM_LOW);
        log_info("Environment shutting down", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Phase 9: extract_phase - Extract results
    //==========================================================================
    virtual function void extract_phase();
        super.extract_phase();
        
        log_info("=== extract_phase ===", EVM_LOW);
        log_info("Results extracted", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 10: check_phase - Check results
    //==========================================================================
    virtual function void check_phase();
        super.check_phase();
        
        log_info("=== check_phase ===", EVM_LOW);
        log_info("Checks complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 11: report_phase - Report results
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        
        log_info("=== report_phase ===", EVM_LOW);
        log_info("Environment report complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 12: final_phase - Final cleanup
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        log_info("=== final_phase ===", EVM_LOW);
        log_info("Environment cleanup complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    function void set_clk_vif(virtual clk_if vif);
        clk_agt.set_vif(vif);
    endfunction
    
    function void set_rst_vif(virtual rst_if vif);
        rst_agt.set_vif(vif);
    endfunction
    
    virtual function string get_type_name();
        return "base_env";
    endfunction
endclass

//==============================================================================
// Base Test - Shows ALL phases with proper super calls
//==============================================================================
class base_test extends evm_base_test;
    
    base_env env;
    
    function new(string name = "base_test");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Phase 1: build_phase - Create environment
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();  // CRITICAL: Always call super first!
        
        log_info("=== TEST build_phase ===", EVM_LOW);
        
        // Enable file logging
        evm_report_handler::enable_file_logging("full_phases_test.log");
        
        // Set verbosity
        evm_report_handler::set_verbosity(EVM_MEDIUM);
        
        // Create environment
        env = new("env", this);
        
        log_info("Test environment created", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Phase 2: connect_phase - Make connections
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        
        log_info("=== TEST connect_phase ===", EVM_LOW);
        log_info("Test connections complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 3: end_of_elaboration_phase - Print topology
    //==========================================================================
    virtual function void end_of_elaboration_phase();
        super.end_of_elaboration_phase();
        
        log_info("=== TEST end_of_elaboration_phase ===", EVM_LOW);
        
        // Print component hierarchy
        print_topology();
        
        log_info("Test elaboration complete", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 4: start_of_simulation_phase - Pre-simulation
    //==========================================================================
    virtual function void start_of_simulation_phase();
        super.start_of_simulation_phase();
        
        log_info("=== TEST start_of_simulation_phase ===", EVM_LOW);
        log_info("Test ready to run", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 5: reset_phase - Wait for reset
    //==========================================================================
    virtual task reset_phase();
        super.reset_phase();
        
        log_info("=== TEST reset_phase ===", EVM_LOW);
        log_info("Reset phase complete", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Phase 6: configure_phase - Configure test
    //==========================================================================
    virtual task configure_phase();
        super.configure_phase();
        
        log_info("=== TEST configure_phase ===", EVM_LOW);
        log_info("Test configuration complete", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Phase 7: main_phase - Run test stimulus
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        log_info("=== TEST main_phase START ===", EVM_LOW);
        
        raise_objection("test_stimulus");
        
        // Wait for simulation
        #1us;
        
        log_info("=== TEST main_phase END ===", EVM_LOW);
        
        drop_objection("test_stimulus");
    endtask
    
    //==========================================================================
    // Phase 8: shutdown_phase - Shutdown
    //==========================================================================
    virtual task shutdown_phase();
        super.shutdown_phase();
        
        log_info("=== TEST shutdown_phase ===", EVM_LOW);
        log_info("Test shutdown complete", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Phase 9: extract_phase - Extract test results
    //==========================================================================
    virtual function void extract_phase();
        super.extract_phase();
        
        log_info("=== TEST extract_phase ===", EVM_LOW);
        log_info("Test results extracted", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Phase 10: check_phase - Check test results
    //==========================================================================
    virtual function void check_phase();
        super.check_phase();
        
        log_info("=== TEST check_phase ===", EVM_LOW);
        
        // Check results
        if (evm_report_handler::get_error_count() > 0) begin
            log_error("Test FAILED with errors");
        end else begin
            log_info("Test PASSED", EVM_LOW);
        end
    endfunction
    
    //==========================================================================
    // Phase 11: report_phase - Report test results
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        
        log_info("=== TEST report_phase ===", EVM_LOW);
        
        // Print statistics
        log_info($sformatf("Errors:   %0d", evm_report_handler::get_error_count()), EVM_LOW);
        log_info($sformatf("Warnings: %0d", evm_report_handler::get_warning_count()), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Phase 12: final_phase - Final cleanup and summary
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        log_info("=== TEST final_phase ===", EVM_LOW);
        
        // Print summary
        evm_report_handler::print_summary();
        
        log_info("Test complete", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    function void set_interfaces(virtual clk_if clk_vif, virtual rst_if rst_vif);
        env.set_clk_vif(clk_vif);
        env.set_rst_vif(rst_vif);
    endfunction
    
endclass
