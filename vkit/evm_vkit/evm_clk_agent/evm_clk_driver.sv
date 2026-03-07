//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_clk_driver
// Description: Clock generator driver for EVM
//              Generates a single clock with configurable frequency
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_clk_driver extends evm_driver#(virtual evm_clk_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_clk_cfg cfg;
    
    //==========================================================================
    // Control
    //==========================================================================
    bit running = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_clk_driver", evm_component parent = null, evm_clk_cfg cfg = null);
        super.new(name, parent);
        if (cfg != null) begin
            this.cfg = cfg;
        end else begin
            this.cfg = new("evm_clk_cfg");
        end
    endfunction
    
    //==========================================================================
    // Main Phase - Start clock generation
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        running = 1;
        
        if (cfg.enabled) begin
            log_info($sformatf("Starting clock generation: %.2f MHz", cfg.freq_mhz), EVM_MED);
            
            // Initial delay
            if (cfg.start_delay > 0) begin
                #(cfg.start_delay);
            end
            
            fork
                generate_clock();
            join_none
        end else begin
            log_info("Clock generation disabled", EVM_MED);
        end
    endtask
    
    //==========================================================================
    // Clock Generation
    //==========================================================================
    task generate_clock();
        time high_time = cfg.get_high_time();
        time low_time = cfg.get_low_time();
        
        vif.clk = 0;
        
        while (running && cfg.enabled) begin
            #(low_time);
            vif.clk = 1;
            #(high_time);
            vif.clk = 0;
        end
    endtask
    
    //==========================================================================
    // Control Methods
    //==========================================================================
    task stop_clock();
        running = 0;
        log_info("Clock stopped", EVM_MED);
    endtask
    
    task set_frequency(real freq_mhz);
        cfg.freq_mhz = freq_mhz;
        log_info($sformatf("Clock frequency changed to %.2f MHz", freq_mhz), EVM_MED);
    endtask
    
    function bit is_running();
        return running;
    endfunction
    
endclass : evm_clk_driver
