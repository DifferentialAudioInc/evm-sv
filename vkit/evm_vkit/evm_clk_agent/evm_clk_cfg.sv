//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_clk_cfg
// Description: Configuration for clock generator
//              Generic single clock configuration
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

class evm_clk_cfg extends evm_object;
    
    //==========================================================================
    // Configuration Parameters
    //==========================================================================
    real freq_mhz = 100.0;    // Clock frequency in MHz
    real duty_cycle = 0.5;     // Duty cycle (0.0 to 1.0)
    time start_delay = 0ns;    // Delay before starting clock
    bit  enabled = 1;          // Clock enable
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_clk_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    function real get_period_ns();
        return 1000.0 / freq_mhz;  // Convert MHz to ns period
    endfunction
    
    function time get_period();
        return time'(get_period_ns() * 1ns);
    endfunction
    
    function time get_high_time();
        return time'(get_period_ns() * duty_cycle * 1ns);
    endfunction
    
    function time get_low_time();
        return time'(get_period_ns() * (1.0 - duty_cycle) * 1ns);
    endfunction
    
endclass : evm_clk_cfg
