//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_gpio_driver
// Description: GPIO driver - drives input pins to DUT
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_gpio_driver extends evm_driver#(virtual evm_gpio_if);
    
    evm_gpio_cfg cfg;
    bit [31:0] current_value;
    
    function new(string name = "evm_gpio_driver", evm_component parent = null, evm_gpio_cfg cfg = null);
        super.new(name, parent);
        this.cfg = (cfg != null) ? cfg : new();
        current_value = cfg.default_input_value;
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        fork
            drive_gpio();
        join_none
    endtask
    
    virtual task drive_gpio();
        @(posedge vif.rst_n);
        vif.gpio_in = current_value;
        
        forever begin
            repeat(cfg.update_period_cycles) @(posedge vif.clk);
            
            // Update randomized pins
            for (int i = 0; i < cfg.num_pins; i++) begin
                if (cfg.random_input_mask[i]) begin
                    current_value[i] = $urandom();
                end
            end
            
            vif.gpio_in = current_value;
        end
    endtask
    
    // API methods
    task set_pin(int pin, bit value);
        if (pin < cfg.num_pins) begin
            current_value[pin] = value;
            vif.gpio_in = current_value;
        end
    endtask
    
    task set_pins(bit [31:0] value);
        current_value = value;
        vif.gpio_in = current_value;
    endtask
    
    task toggle_pin(int pin);
        if (pin < cfg.num_pins) begin
            current_value[pin] = ~current_value[pin];
            vif.gpio_in = current_value;
        end
    endtask
    
endclass : evm_gpio_driver
