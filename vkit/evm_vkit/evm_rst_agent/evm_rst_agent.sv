//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_rst_agent
// Description: Reset agent for EVM
//              Active agent with monitor for reset verification
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

class evm_rst_agent extends evm_agent#(virtual evm_rst_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_rst_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_rst_agent", evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);  // Reset agent is always active
        cfg = new();  // Create default configuration
    endfunction
    
    //==========================================================================
    // Factory Methods
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_rst_if) create_monitor(string name);
        evm_rst_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_rst_if) create_driver(string name);
        evm_rst_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function evm_rst_driver get_driver();
        evm_rst_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_rst_monitor get_monitor();
        evm_rst_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    task apply_pcie_reset();
        evm_rst_driver drv = get_driver();
        if (drv != null) drv.apply_pcie_reset();
    endtask
    
    task apply_sys_reset();
        evm_rst_driver drv = get_driver();
        if (drv != null) drv.apply_sys_reset();
    endtask
    
    task apply_all_resets();
        evm_rst_driver drv = get_driver();
        if (drv != null) drv.apply_all_resets();
    endtask
    
endclass : evm_rst_agent
