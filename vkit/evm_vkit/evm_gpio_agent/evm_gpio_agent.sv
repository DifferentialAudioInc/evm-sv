//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_gpio_agent
// Description: GPIO agent for EVM - controls GPIO pins
// Author: Engineering Team
// Date: 2026-03-07
//==============================================================================

class evm_gpio_agent extends evm_agent#(virtual evm_gpio_if);
    
    evm_gpio_cfg cfg;
    
    function new(string name = "evm_gpio_agent", evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);
        cfg = new();
    endfunction
    
    virtual function evm_monitor#(virtual evm_gpio_if) create_monitor(string name);
        evm_gpio_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_gpio_if) create_driver(string name);
        evm_gpio_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    function evm_gpio_driver get_driver();
        evm_gpio_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_gpio_monitor get_monitor();
        evm_gpio_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    // Convenience methods
    task set_pin(int pin, bit value);
        evm_gpio_driver drv = get_driver();
        if (drv != null) drv.set_pin(pin, value);
    endtask
    
    task set_pins(bit [31:0] value);
        evm_gpio_driver drv = get_driver();
        if (drv != null) drv.set_pins(value);
    endtask
    
    task toggle_pin(int pin);
        evm_gpio_driver drv = get_driver();
        if (drv != null) drv.toggle_pin(pin);
    endtask
    
endclass : evm_gpio_agent
