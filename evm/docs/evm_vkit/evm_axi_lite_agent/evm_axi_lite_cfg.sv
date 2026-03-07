//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_cfg
// Description: Lightweight configuration class for AXI4-Lite agent
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_axi_lite_cfg extends evm_object;
    
    //==========================================================================
    // Basic Timing Parameters
    //==========================================================================
    int aw_delay_cycles = 0;  // Delay before asserting AWVALID
    int w_delay_cycles  = 0;  // Delay before asserting WVALID
    int ar_delay_cycles = 0;  // Delay before asserting ARVALID
    bit enable_delays   = 0;  // Enable delays
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    virtual function string convert2string();
        return $sformatf("%s: Delays=%s AW=%0d W=%0d AR=%0d", 
                         super.convert2string(), enable_delays ? "ON" : "OFF",
                         aw_delay_cycles, w_delay_cycles, ar_delay_cycles);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_cfg";
    endfunction
    
endclass : evm_axi_lite_cfg
