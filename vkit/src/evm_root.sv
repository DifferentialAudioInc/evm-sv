//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_root
// Description: Root singleton for Embedded Verification Methodology (EVM)
//              Central phase controller with objection mechanism
//              All tests extend from this root
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

class evm_root extends evm_component;
    
    //==========================================================================
    // Singleton Instance
    //==========================================================================
    local static evm_root m_inst = null;
    
    //==========================================================================
    // Properties
    //==========================================================================
    
    // Objection mechanism for phase control
    protected int   objection_count;
    protected event objection_dropped;
    
    // Timeout configuration
    int             default_timeout_us;
    
    // Test name
    string          test_name;
    
    //==========================================================================
    // Constructor (protected for singleton)
    //==========================================================================
    protected function new(string name = "evm_root");
        super.new(name, null);  // Root has no parent
        
        // Initialize objection
        objection_count = 0;
        default_timeout_us = 1000;  // 1ms default
        test_name = name;
    endfunction
    
    //==========================================================================
    // Singleton Access
    //==========================================================================
    
    // Get singleton instance
    static function evm_root get();
        if (m_inst == null) begin
            m_inst = new("evm_root");
        end
        return m_inst;
    endfunction
    
    // Initialize root with test name
    static function evm_root init(string name);
        if (m_inst != null) begin
            $display("WARNING: evm_root already initialized, reinitializing with %s", name);
        end
        m_inst = new(name);
        return m_inst;
    endfunction
    
    //==========================================================================
    // Objection Control (Global for all components)
    //==========================================================================
    
    // Raise objection - prevents phases from ending
    function void raise_objection(string description = "");
        objection_count++;
        if (description != "") begin
            log_info($sformatf("Objection raised [%0d]: %s", objection_count, description), 
                     EVM_HIGH);
        end else begin
            log_info($sformatf("Objection raised [count=%0d]", objection_count), 
                     EVM_HIGH);
        end
    endfunction
    
    // Drop objection - allows phases to end when count reaches 0
    function void drop_objection(string description = "");
        if (objection_count > 0) begin
            objection_count--;
            if (description != "") begin
                log_info($sformatf("Objection dropped [%0d]: %s", objection_count, description), 
                         EVM_HIGH);
            end else begin
                log_info($sformatf("Objection dropped [count=%0d]", objection_count), 
                         EVM_HIGH);
            end
            
            // Trigger event when all objections are dropped
            if (objection_count == 0) begin
                ->objection_dropped;
                log_info("All objections dropped - phase can end", EVM_HIGH);
            end
        end else begin
            log_warning("Attempted to drop objection when count is already 0");
        end
    endfunction
    
    // Get current objection count
    function int get_objection_count();
        return objection_count;
    endfunction
    
    // Wait for all objections to be dropped
    task wait_for_objections();
        if (objection_count > 0) begin
            log_info($sformatf("Waiting for %0d objections to be dropped...", objection_count), 
                     EVM_HIGH);
            @(objection_dropped);
        end
    endtask
    
    //==========================================================================
    // Phase Execution Wrappers with Logging
    //==========================================================================
    
    // Execute build phase
    virtual function void execute_build_phase();
        log_info(">>> Starting BUILD phase", EVM_HIGH);
        build_phase();
        log_info("<<< BUILD phase complete", EVM_HIGH);
    endfunction
    
    // Execute connect phase
    virtual function void execute_connect_phase();
        log_info(">>> Starting CONNECT phase", EVM_HIGH);
        connect_phase();
        log_info("<<< CONNECT phase complete", EVM_HIGH);
    endfunction
    
    // Execute end of elaboration phase
    virtual function void execute_end_of_elaboration_phase();
        log_info(">>> Starting END_OF_ELABORATION phase", EVM_HIGH);
        end_of_elaboration_phase();
        log_info("<<< END_OF_ELABORATION phase complete", EVM_HIGH);
    endfunction
    
    // Execute start of simulation phase
    virtual function void execute_start_of_simulation_phase();
        log_info(">>> Starting START_OF_SIMULATION phase", EVM_HIGH);
        start_of_simulation_phase();
        log_info("<<< START_OF_SIMULATION phase complete", EVM_HIGH);
    endfunction
    
    // Execute reset phase
    virtual task execute_reset_phase();
        log_info(">>> Starting RESET phase", EVM_HIGH);
        reset_phase();
        log_info("<<< RESET phase complete", EVM_HIGH);
    endtask
    
    // Execute configure phase
    virtual task execute_configure_phase();
        log_info(">>> Starting CONFIGURE phase", EVM_HIGH);
        configure_phase();
        log_info("<<< CONFIGURE phase complete", EVM_HIGH);
    endtask
    
    // Execute main phase with objection and timeout control
    virtual task execute_main_phase();
        int timeout_us;
        
        // Get timeout from plusarg or use default
        if ($value$plusargs("EVM_TIMEOUT=%d", timeout_us)) begin
            log_info($sformatf("Using EVM_TIMEOUT=%0dus from plusarg", timeout_us), 
                     EVM_HIGH);
        end else begin
            timeout_us = default_timeout_us;
        end
        
        log_info(">>> Starting MAIN phase", EVM_HIGH);
        
        fork
            begin
                // Run the main phase
                main_phase();
                
                // Wait for all objections to be dropped
                wait_for_objections();
                log_info("MAIN phase complete (all objections dropped)", EVM_HIGH);
            end
            
            begin
                // Timeout watchdog
                #(timeout_us * 1us);
                if (objection_count > 0) begin
                    log_error($sformatf("EVM_TIMEOUT: Main phase timeout after %0dus with %0d objections still raised", 
                                       timeout_us, objection_count));
                end else begin
                    log_error($sformatf("EVM_TIMEOUT: Main phase timeout after %0dus", timeout_us));
                end
            end
        join_any
        disable fork;
        
        log_info("<<< MAIN phase complete", EVM_HIGH);
    endtask
    
    // Execute shutdown phase
    virtual task execute_shutdown_phase();
        log_info(">>> Starting SHUTDOWN phase", EVM_HIGH);
        shutdown_phase();
        log_info("<<< SHUTDOWN phase complete", EVM_HIGH);
    endtask
    
    // Execute extract phase
    virtual function void execute_extract_phase();
        log_info(">>> Starting EXTRACT phase", EVM_HIGH);
        extract_phase();
        log_info("<<< EXTRACT phase complete", EVM_HIGH);
    endfunction
    
    // Execute check phase
    virtual function void execute_check_phase();
        log_info(">>> Starting CHECK phase", EVM_HIGH);
        check_phase();
        log_info("<<< CHECK phase complete", EVM_HIGH);
    endfunction
    
    // Execute report phase
    virtual function void execute_report_phase();
        log_info(">>> Starting REPORT phase", EVM_HIGH);
        report_phase();
        log_info("<<< REPORT phase complete", EVM_HIGH);
    endfunction
    
    // Execute final phase
    virtual function void execute_final_phase();
        log_info(">>> Starting FINAL phase", EVM_HIGH);
        final_phase();
        log_info("<<< FINAL phase complete", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Test Runner - Called from tb_top to run a test
    //==========================================================================
    task run_test(evm_component test);
        log_info($sformatf("EVM: Running Test: %s", test.get_full_name()));
        
        // Run all phases with the test
        run_all_phases_with_test(test);
    endtask
    
    //==========================================================================
    // Main Phase Runner - Executes all phases in order on given test
    // Note: run_phase() executes in parallel with sequential runtime phases
    //==========================================================================
    task run_all_phases_with_test(evm_component test);
        // Function phases (pre-simulation)
        test.build_phase();
        execute_build_phase();
        
        test.connect_phase();
        execute_connect_phase();
        
        test.end_of_elaboration_phase();
        execute_end_of_elaboration_phase();
        
        test.start_of_simulation_phase();
        execute_start_of_simulation_phase();
        
        // Task phases (runtime)
        // Fork run_phase to execute in parallel with sequential phases
        fork
            begin
                // Continuous parallel execution (monitors/scoreboards)
                log_info(">>> Starting RUN phase (parallel)", EVM_HIGH);
                test.run_phase();
                log_info("<<< RUN phase complete", EVM_HIGH);
            end
            
            begin
                // Sequential runtime phases
                fork
                    test.reset_phase();
                join_none
                execute_reset_phase();
                wait fork;
                
                fork
                    test.configure_phase();
                join_none
                execute_configure_phase();
                wait fork;
                
                fork
                    test.main_phase();
                join_none
                execute_main_phase();
                wait fork;
                
                fork
                    test.shutdown_phase();
                join_none
                execute_shutdown_phase();
                wait fork;
            end
        join
        
        // Function phases (post-simulation)
        test.extract_phase();
        execute_extract_phase();
        
        test.check_phase();
        execute_check_phase();
        
        test.report_phase();
        execute_report_phase();
        
        test.final_phase();
        execute_final_phase();
    endtask
    
    //==========================================================================
    // Legacy phase runner (kept for backward compatibility)
    //==========================================================================
    virtual task run_all_phases();
        // Function phases (pre-simulation)
        execute_build_phase();
        execute_connect_phase();
        execute_end_of_elaboration_phase();
        execute_start_of_simulation_phase();
        
        // Task phases (runtime)
        execute_reset_phase();
        execute_configure_phase();
        execute_main_phase();
        execute_shutdown_phase();
        
        // Function phases (post-simulation)
        execute_extract_phase();
        execute_check_phase();
        execute_report_phase();
        execute_final_phase();
    endtask
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Set default timeout
    function void set_default_timeout(int timeout);
        default_timeout_us = timeout;
        log_info($sformatf("Default timeout set to %0dus", timeout), EVM_HIGH);
    endfunction
    
    // Get type name
    virtual function string get_type_name();
        return "evm_root";
    endfunction
    
endclass : evm_root
