//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_pcie_cfg
// Description: Lightweight configuration class for PCIe agent
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_pcie_cfg extends evm_object;
    
    //==========================================================================
    // Basic PCIe Parameters
    //==========================================================================
    bit [15:0] device_id  = 16'hDEAD;
    bit [15:0] vendor_id  = 16'hBEEF;
    int link_speed = 2;  // 1=Gen1, 2=Gen2, 3=Gen3
    int link_width = 4;  // Link width (1, 2, 4, 8, or 16 lanes)
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_pcie_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    virtual function string convert2string();
        return $sformatf("%s: DevID=0x%04h VenID=0x%04h Gen%0d x%0d", 
                         super.convert2string(), device_id, vendor_id, link_speed, link_width);
    endfunction
    
    virtual function string get_type_name();
        return "evm_pcie_cfg";
    endfunction
    
endclass : evm_pcie_cfg
