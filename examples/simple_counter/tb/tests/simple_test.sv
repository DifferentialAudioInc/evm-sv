//==============================================================================
// Simple Test
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Class: simple_test
// Description: Simple test demonstrating EVM phasing
//              Creates clock and reset agents, runs for 10us
//==============================================================================

class simple_test extends evm_base_test;
    
    //==========================================================================
    // Agents
    //==========================================================================
    clk_agent clk_agt;
    rst_agent rst_agt;
    
    //==========================================================================
    // DUT Signals (for monitoring)
    //==========================================================================
    virtual clk_if clk_vif;
    virtual rst_if rst_vif;
    logic enable;
    logic [7:0] count;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "simple_test");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Build Phase - Create agents
    //==========================================================================
    function void build_phase();
        super.build_phase();
        
        // Create clock agent
        clk_agt = new("clk_agt", this);
        clk_agt.period_ns = 10;  // 100MHz clock
        
        // Create reset agent
        rst_agt = new("rst_agt", this);
        
        log_info("Agents created", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Connect Phase - Connect interfaces
    //==========================================================================
    function void connect_phase();
        super.connect_phase();
        
        // Connect interfaces to agents
        clk_agt.set_vif(clk_vif);
        rst_agt.set_vif(rst_vif, clk_vif);
        
        log_info("Interfaces connected", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // End of Elaboration - Validate setup
    //==========================================================================
    function void end_of_elaboration_phase();
        super.end_of_elaboration_phase();
        
        if (clk_vif == null) begin
            log_error("Clock interface not set!");
        end
        
        if (rst_vif == null) begin
            log_error("Reset interface not set!");
        end
    endfunction
    
    //==========================================================================
    // Start of Simulation - Initialize
    //==========================================================================
    function void start_of_simulation_phase();
        super.start_of_simulation_phase();
        
        // Start clock generation
        clk_agt.start_clock();
        
        // Initialize enable to 0
        enable = 1'b0;
        
        log_info("=== SIMPLE COUNTER TEST STARTING ===", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Reset Phase - Apply reset
    //==========================================================================
    task reset_phase();
        super.reset_phase();
        
        // Apply reset sequence (10 clock cycles)
        rst_agt.apply_reset(10);
        
        log_info("Reset complete", EVM_LOW);
    endtask
    
    //==========================================================================
    // Configure Phase - Enable counter
    //==========================================================================
    task configure_phase();
        super.configure_phase();
        
        // Wait a few clocks
        clk_agt.wait_clocks(5);
        
        // Enable counter
        enable = 1'b1;
        log_info("Counter enabled", EVM_LOW);
    endtask
    
    //==========================================================================
    // Main Phase - Run test for 10us
    //==========================================================================
    task main_phase();
        super.main_phase();
        
        // Raise objection to prevent phase from ending
        raise_objection("test_activity");
        
        log_info("=== MAIN PHASE STARTING ===", EVM_LOW);
        
        // Run for 10us
        #10us;
        
        log_info("=== MAIN PHASE COMPLETE ===", EVM_LOW);
        
        // Drop objection to allow phase to end
        drop_objection("test_activity");
    endtask
    
    //==========================================================================
    // Shutdown Phase - Disable counter
    //==========================================================================
    task shutdown_phase();
        super.shutdown_phase();
        
        // Disable counter
        enable = 1'b0;
        log_info("Counter disabled", EVM_LOW);
    endtask
    
    //==========================================================================
    // Extract Phase - Read final values
    //==========================================================================
    function void extract_phase();
        super.extract_phase();
        
        log_info($sformatf("Final counter value: %0d (0x%02h)", count, count), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Check Phase - Verify results
    //==========================================================================
    function void check_phase();
        super.check_phase();
        
        // Check that counter incremented (should be non-zero after 10us)
        if (count == 0) begin
            log_error("Counter did not increment!");
        end else begin
            log_info($sformatf("Counter incremented to %0d - PASS", count), EVM_LOW);
        end
    endfunction
    
    //==========================================================================
    // Report Phase - Print summary
    //==========================================================================
    function void report_phase();
        super.report_phase();
        // Base class handles pass/fail reporting
    endfunction
    
    //==========================================================================
    // Final Phase - Cleanup
    //==========================================================================
    function void final_phase();
        super.final_phase();
        
        // Stop clock
        clk_agt.stop_clock();
    endfunction
    
    //==========================================================================
    // Helper method to set interfaces
    //==========================================================================
    function void set_interfaces(virtual clk_if clk_vif, 
                                 virtual rst_if rst_vif,
                                 ref logic enable,
                                 ref logic [7:0] count);
        this.clk_vif = clk_vif;
        this.rst_vif = rst_vif;
        this.enable = enable;
        this.count = count;
    endfunction
    
    //==========================================================================
    // Get type name
    //==========================================================================
    virtual function string get_type_name();
        return "simple_test";
    endfunction
    
endclass : simple_test
