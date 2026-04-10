//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_gpio_cfg
// Description: Configuration for GPIO agent
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_gpio_cfg extends evm_object;
    
    //==========================================================================
    // Configuration Parameters
    //==========================================================================
    int num_pins = 32;                     // Number of GPIO pins
    
    // Default pin values
    bit [31:0] default_input_value = 0;    // Default input values
    bit [31:0] pin_pullup_enable = 0;      // Pull-up enable per pin
    bit [31:0] pin_pulldown_enable = 0;    // Pull-down enable per pin
    
    // Stimulus generation
    rand bit [31:0] random_input_mask = 0; // Mask for randomized inputs
    int update_period_cycles = 100;        // Cycles between updates
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_gpio_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Pin Configuration Methods
    //==========================================================================
    
    function void set_pin_value(int pin, bit value);
        if (pin < num_pins) begin
            default_input_value[pin] = value;
        end
    endfunction
    
    function bit get_pin_value(int pin);
        return (pin < num_pins) ? default_input_value[pin] : 0;
    endfunction
    
    function void enable_pin_random(int pin);
        if (pin < num_pins) begin
            random_input_mask[pin] = 1;
        end
    endfunction
    
    virtual function string convert2string();
        return $sformatf("%s: %0d pins", super.convert2string(), num_pins);
    endfunction
    
    virtual function string get_type_name();
        return "evm_gpio_cfg";
    endfunction
    
endclass : evm_gpio_cfg
