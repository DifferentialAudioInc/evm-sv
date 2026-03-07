//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_gpio_monitor
// Description: GPIO monitor - observes pin changes
// Author: Engineering Team
// Date: 2026-03-07
//==============================================================================

class evm_gpio_monitor extends evm_monitor#(virtual evm_gpio_if);
    
    evm_gpio_cfg cfg;
    bit [31:0] last_gpio_out;
    int pin_toggle_count[32];
    
    function new(string name = "evm_gpio_monitor", evm_component parent = null, evm_gpio_cfg cfg = null);
        super.new(name, parent);
        this.cfg = (cfg != null) ? cfg : new();
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        fork
            monitor_gpio();
        join_none
    endtask
    
    virtual task monitor_gpio();
        @(posedge vif.rst_n);
        last_gpio_out = vif.gpio_out;
        
        forever begin
            @(posedge vif.clk);
            
            // Detect changes
            if (vif.gpio_out != last_gpio_out) begin
                for (int i = 0; i < cfg.num_pins; i++) begin
                    if (vif.gpio_out[i] != last_gpio_out[i]) begin
                        pin_toggle_count[i]++;
                        log_info($sformatf("GPIO[%0d] changed: %b -> %b", 
                                          i, last_gpio_out[i], vif.gpio_out[i]), EVM_LOW);
                    end
                end
                last_gpio_out = vif.gpio_out;
            end
        end
    endtask
    
    function void print_statistics();
        log_info("=== GPIO Monitor Statistics ===", EVM_HIGH);
        for (int i = 0; i < cfg.num_pins; i++) begin
            if (pin_toggle_count[i] > 0) begin
                log_info($sformatf("GPIO[%0d]: %0d toggles", i, pin_toggle_count[i]), EVM_HIGH);
            end
        end
    endfunction
    
    virtual function void final_phase();
        super.final_phase();
        print_statistics();
    endfunction
    
endclass : evm_gpio_monitor
