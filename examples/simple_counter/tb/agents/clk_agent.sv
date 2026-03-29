//==============================================================================
// Clock Agent
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Class: clk_agent
// Description: Clock generation agent
//              Extends evm_component to get phasing support
//==============================================================================

class clk_agent extends evm_component;
    
    //==========================================================================
    // Properties
    //==========================================================================
    virtual clk_if vif;
    int period_ns = 10;  // Default 10ns period (100MHz)
    bit running = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "clk_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase();
        super.build_phase();
        log_info("Clock agent created", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Set Interface
    //==========================================================================
    function void set_vif(virtual clk_if vif);
        this.vif = vif;
    endfunction
    
    //==========================================================================
    // Start Clock Generation
    //==========================================================================
    task start_clock();
        if (vif == null) begin
            log_error("Clock interface not set!");
            return;
        end
        
        running = 1;
        log_info($sformatf("Starting clock generation (period=%0dns)", period_ns), EVM_LOW);
        
        fork
            forever begin
                #(period_ns/2 * 1ns);
                vif.clk = ~vif.clk;
                if (!running) break;
            end
        join_none
    endtask
    
    //==========================================================================
    // Stop Clock Generation
    //==========================================================================
    task stop_clock();
        running = 0;
        log_info("Stopping clock generation", EVM_LOW);
    endtask
    
    //==========================================================================
    // Wait for N clock cycles
    //==========================================================================
    task wait_clocks(int n);
        repeat(n) @(posedge vif.clk);
    endtask
    
    //==========================================================================
    // Get type name
    //==========================================================================
    virtual function string get_type_name();
        return "clk_agent";
    endfunction
    
endclass : clk_agent
