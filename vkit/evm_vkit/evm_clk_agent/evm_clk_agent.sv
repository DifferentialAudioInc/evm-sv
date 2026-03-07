//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_clk_agent
// Description: Clock generator agent for EVM
//              Active agent with monitor for clock verification
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_clk_agent extends evm_agent#(virtual evm_clk_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_clk_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_clk_agent", evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);  // Clock gen is always active
        cfg = new();  // Create default configuration
    endfunction
    
    //==========================================================================
    // Factory Methods
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_clk_if) create_monitor(string name);
        evm_clk_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_clk_if) create_driver(string name);
        evm_clk_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function evm_clk_driver get_driver();
        evm_clk_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_clk_monitor get_monitor();
        evm_clk_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    task set_frequency(real freq_mhz);
        evm_clk_driver drv = get_driver();
        if (drv != null) begin
            drv.set_frequency(freq_mhz);
        end
    endtask
    
endclass : evm_clk_agent
