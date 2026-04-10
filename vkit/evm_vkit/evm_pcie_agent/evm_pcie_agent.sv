//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_pcie_agent
// Description: PCIe agent for EVM
//              Manages PCIe Bus Functional Model
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

class evm_pcie_agent extends evm_agent#(virtual evm_pcie_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_pcie_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_pcie_agent", evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);  // PCIe agent is active by default
        cfg = new();  // Create default configuration
    endfunction
    
    //==========================================================================
    // Factory Methods
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_pcie_if) create_monitor(string name);
        evm_pcie_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_pcie_if) create_driver(string name);
        evm_pcie_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function evm_pcie_driver get_driver();
        evm_pcie_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_pcie_monitor get_monitor();
        evm_pcie_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    // Convenience methods for easy access
    function void configure(bit [15:0] dev_id, bit [15:0] vend_id, 
                           int speed = 2, int width = 4);
        evm_pcie_driver pcie_drv = get_driver();
        if (pcie_drv != null) begin
            pcie_drv.configure(dev_id, vend_id, speed, width);
        end
    endfunction
    
    task link_training();
        evm_pcie_driver pcie_drv = get_driver();
        if (pcie_drv != null) begin
            pcie_drv.link_training();
        end
    endtask
    
    task mem_write(bit [63:0] addr, bit [31:0] data, int size_bytes);
        evm_pcie_driver pcie_drv = get_driver();
        if (pcie_drv != null) begin
            pcie_drv.mem_write(addr, data, size_bytes);
        end
    endtask
    
    task mem_read(bit [63:0] addr, output bit [31:0] data, int size_bytes);
        evm_pcie_driver pcie_drv = get_driver();
        if (pcie_drv != null) begin
            pcie_drv.mem_read(addr, data, size_bytes);
        end
    endtask
    
endclass : evm_pcie_agent
