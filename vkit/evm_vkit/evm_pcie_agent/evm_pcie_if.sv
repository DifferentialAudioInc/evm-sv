//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_pcie_if
// Description: PCIe interface for PCIe Bus Functional Model
//              Simplified interface for basic PCIe transaction modeling
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

interface evm_pcie_if;
    
    //==========================================================================
    // Link Status Signals
    //==========================================================================
    logic        link_up;
    logic [2:0]  link_speed;    // 1=Gen1, 2=Gen2, 3=Gen3
    logic [4:0]  link_width;    // 1, 2, 4, 8, 16
    
    //==========================================================================
    // Configuration Space
    //==========================================================================
    logic [15:0] device_id;
    logic [15:0] vendor_id;
    
    //==========================================================================
    // Transaction Interface (simplified)
    //==========================================================================
    logic        trans_valid;
    logic        trans_ready;
    logic        trans_is_write;
    logic [63:0] trans_addr;
    logic [31:0] trans_data;
    logic [1:0]  trans_size;     // 0=byte, 1=word, 2=dword
    
    //==========================================================================
    // Initial Values
    //==========================================================================
    initial begin
        link_up = 0;
        link_speed = 2;      // Gen2
        link_width = 4;      // x4
        device_id = 16'hDEAD;
        vendor_id = 16'hBEEF;
        trans_valid = 0;
        trans_ready = 1;
        trans_is_write = 0;
        trans_addr = '0;
        trans_data = '0;
        trans_size = 2;      // Default to DWORD
    end
    
endinterface : evm_pcie_if
