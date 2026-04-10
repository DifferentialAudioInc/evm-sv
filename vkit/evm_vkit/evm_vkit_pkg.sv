//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Package: evm_vkit_pkg
// Description: EVM Verification Kit (VKit) Package
//              Contains all reusable verification agents and protocol support.
//
//              Interfaces (compile separately, NOT in this package):
//                evm_axi_lite_if     → vkit/evm_vkit/evm_axi_lite_agent/evm_axi_lite_if.sv
//                evm_axi4_full_if    → vkit/evm_vkit/evm_axi4_full_agent/evm_axi4_full_if.sv
//                evm_clk_if          → vkit/evm_vkit/evm_clk_agent/evm_clk_if.sv
//                (etc.)
//
// Author: Eric Dyer
// Date: 2026-03-06
// Updated: 2026-04-09 - Added AXI-Lite txn types, updated monitor, added AXI4 Full agent
//==============================================================================

package evm_vkit_pkg;
    
    import evm_pkg::*;  // Import EVM framework
    
    //--------------------------------------------------------------------------
    // CLK Agent
    //--------------------------------------------------------------------------
    `include "evm_clk_agent/evm_clk_cfg.sv"
    `include "evm_clk_agent/evm_clk_driver.sv"
    `include "evm_clk_agent/evm_clk_monitor.sv"
    `include "evm_clk_agent/evm_clk_agent.sv"
    
    //--------------------------------------------------------------------------
    // RST Agent
    //--------------------------------------------------------------------------
    `include "evm_rst_agent/evm_rst_cfg.sv"
    `include "evm_rst_agent/evm_rst_driver.sv"
    `include "evm_rst_agent/evm_rst_monitor.sv"
    `include "evm_rst_agent/evm_rst_agent.sv"
    
    //--------------------------------------------------------------------------
    // ADC Agent
    //--------------------------------------------------------------------------
    `include "evm_adc_agent/evm_adc_cfg.sv"
    `include "evm_adc_agent/evm_adc_driver.sv"
    `include "evm_adc_agent/evm_adc_monitor.sv"
    `include "evm_adc_agent/evm_adc_agent.sv"
    
    //--------------------------------------------------------------------------
    // PCIe Agent
    //--------------------------------------------------------------------------
    `include "evm_pcie_agent/evm_pcie_cfg.sv"
    `include "evm_pcie_agent/evm_pcie_driver.sv"
    `include "evm_pcie_agent/evm_pcie_monitor.sv"
    `include "evm_pcie_agent/evm_pcie_agent.sv"
    
    //--------------------------------------------------------------------------
    // AXI4-Lite Agent
    // Order: cfg → txn types → driver → monitor (uses txn types) → agent
    //--------------------------------------------------------------------------
    `include "evm_axi_lite_agent/evm_axi_lite_cfg.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_txn.sv"       // NEW: transaction types
    `include "evm_axi_lite_agent/evm_axi_lite_driver.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_monitor.sv"   // UPDATED: 7 analysis ports
    `include "evm_axi_lite_agent/evm_axi_lite_agent.sv"     // UPDATED: sequencer support
    `include "evm_axi_lite_agent/evm_axi_lite_reg_predictor.sv"  // NEW: concrete RAL predictor
    
    //--------------------------------------------------------------------------
    // AXI4 Full Agent (NEW)
    // Order: cfg → txn types → driver → monitor → agent
    // Note: evm_axi4_full_if is an interface - compile separately (not in pkg)
    //--------------------------------------------------------------------------
    `include "evm_axi4_full_agent/evm_axi4_full_cfg.sv"
    `include "evm_axi4_full_agent/evm_axi4_full_txn.sv"
    `include "evm_axi4_full_agent/evm_axi4_full_driver.sv"
    `include "evm_axi4_full_agent/evm_axi4_full_monitor.sv"
    `include "evm_axi4_full_agent/evm_axi4_full_agent.sv"
    
endpackage : evm_vkit_pkg
