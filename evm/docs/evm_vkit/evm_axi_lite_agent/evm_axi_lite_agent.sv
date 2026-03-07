//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_master_agent
// Description: AXI4-Lite Master Agent for EVM
//              Complete agent for CSR register access
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

class evm_axi_lite_master_agent extends evm_agent#(virtual evm_axi_lite_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi_lite_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_master_agent", evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);  // Active by default
        cfg = new();  // Create default configuration
    endfunction
    
    //==========================================================================
    // Factory Methods
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_axi_lite_if) create_monitor(string name);
        evm_axi_lite_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_axi_lite_if) create_driver(string name);
        evm_axi_lite_master_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function evm_axi_lite_master_driver get_driver();
        evm_axi_lite_master_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_axi_lite_monitor get_monitor();
        evm_axi_lite_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    // Convenience methods for easy access
    task write(input logic [31:0] addr, 
               input logic [31:0] data,
               input logic [3:0]  strb = 4'b1111,
               output logic [1:0] resp);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.write(addr, data, strb, resp);
        end
    endtask
    
    task read(input  logic [31:0] addr,
              output logic [31:0] data,
              output logic [1:0]  resp);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.read(addr, data, resp);
        end
    endtask
    
    task write_check(input logic [31:0] addr, 
                     input logic [31:0] data,
                     input logic [3:0]  strb = 4'b1111);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.write_check(addr, data, strb);
        end
    endtask
    
    task read_check(input  logic [31:0] addr,
                    output logic [31:0] data);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.read_check(addr, data);
        end
    endtask
    
    task rmw(input logic [31:0] addr,
             input logic [31:0] mask,
             input logic [31:0] value);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.rmw(addr, mask, value);
        end
    endtask
    
    task poll(input logic [31:0] addr,
              input logic [31:0] mask,
              input logic [31:0] expected,
              input int timeout_cycles = 1000,
              output bit success);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.poll(addr, mask, expected, timeout_cycles, success);
        end
    endtask
    
endclass : evm_axi_lite_master_agent
