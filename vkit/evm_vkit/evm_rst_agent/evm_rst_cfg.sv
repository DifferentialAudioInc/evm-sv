//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_rst_cfg
// Description: Lightweight configuration class for reset agent
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

class evm_rst_cfg extends evm_object;
    
    //==========================================================================
    // Basic Reset Durations
    //==========================================================================
    int pcie_reset_duration_ns = 100;  // PCIe reset duration (default 100ns)
    int sys_reset_duration_ns  = 100;  // System reset duration (default 100ns)
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_rst_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    virtual function string convert2string();
        return $sformatf("%s: PCIe=%0dns Sys=%0dns", 
                         super.convert2string(), pcie_reset_duration_ns, sys_reset_duration_ns);
    endfunction
    
    virtual function string get_type_name();
        return "evm_rst_cfg";
    endfunction
    
endclass : evm_rst_cfg
