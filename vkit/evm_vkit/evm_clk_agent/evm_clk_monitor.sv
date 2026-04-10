//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_clk_monitor
// Description: Clock monitor for EVM
//              Monitors clock frequency and duty cycle
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

class evm_clk_monitor extends evm_monitor#(virtual evm_clk_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_clk_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_clk_monitor", evm_component parent = null, evm_clk_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
    endfunction
    
    //==========================================================================
    // Run Phase - Continuous clock monitoring
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        log_info("Clock monitor started - continuous monitoring", EVM_LOW);
        
        fork
            monitor_clock();
        join_none
    endtask
    
    //==========================================================================
    // Clock Monitoring Task
    //==========================================================================
    task monitor_clock();
        realtime period_start, period_end, measured_period;
        real freq_mhz;
        int cycle_count = 0;
        
        forever begin
            @(posedge vif.clk);
            period_start = $realtime;
            @(posedge vif.clk);
            period_end = $realtime;
            measured_period = period_end - period_start;
            
            if (measured_period > 0) begin
                freq_mhz = 1000.0 / measured_period;
                cycle_count++;
                
                // Log periodically (every 1000 cycles)
                if (cycle_count % 1000 == 0) begin
                    log_info($sformatf("Clock frequency: %.2f MHz (period: %.2f ns)", 
                             freq_mhz, measured_period), EVM_LOW);
                end
            end
        end
    endtask
    
endclass : evm_clk_monitor
