//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_rst_if
// Description: Reset interface for reset agent
//              Contains reset signals for testbench
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

interface evm_rst_if;
    
    //==========================================================================
    // Reset Signals
    //==========================================================================
    logic pcie_perst_n;   // PCIe reset (active low)
    logic sys_rst_n;      // System reset (active low)
    logic adc_reset_n;    // ADC reset (active low)
    
    //==========================================================================
    // Initial Values
    //==========================================================================
    initial begin
        pcie_perst_n = 0;
        sys_rst_n    = 0;
        adc_reset_n  = 0;
    end
    
endinterface : evm_rst_if
