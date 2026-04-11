//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Package: evm_vkit_pkg
// Description: EVM Verification Kit (VKit) Package
// Author: Eric Dyer
// Date: 2026-03-06
// Updated: 2026-04-09 - Added AXI-Lite txn types, updated monitor, added AXI4 Full agent
//==============================================================================

package evm_vkit_pkg;
    
    import evm_pkg::*;
    
    `include "evm_clk_agent/evm_clk_cfg.sv"
    `include "evm_clk_agent/evm_clk_driver.sv"
    `include "evm_clk_agent/evm_clk_monitor.sv"
    `include "evm_clk_agent/evm_clk_agent.sv"

    `include "evm_rst_agent/evm_rst_cfg.sv"
    `include "evm_rst_agent/evm_rst_driver.sv"
    `include "evm_rst_agent/evm_rst_monitor.sv"
    `include "evm_rst_agent/evm_rst_agent.sv"

    `include "evm_adc_agent/evm_adc_cfg.sv"
    `include "evm_adc_agent/evm_adc_driver.sv"
    `include "evm_adc_agent/evm_adc_monitor.sv"
    `include "evm_adc_agent/evm_adc_agent.sv"

    `include "evm_pcie_agent/evm_pcie_cfg.sv"
    `include "evm_pcie_agent/evm_pcie_driver.sv"
    `include "evm_pcie_agent/evm_pcie_monitor.sv"
    `include "evm_pcie_agent/evm_pcie_agent.sv"

    `include "evm_axi_lite_agent/evm_axi_lite_cfg.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_txn.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_driver.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_monitor.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_agent.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_reg_predictor.sv"

    // AXI4 Full: evm_axi4_full_agent uses direct 'virtual evm_axi4_full_if vif' member.
    // Vivado xvlog cannot resolve non-parameterized virtual interfaces inside packages.
    // FIX NEEDED: Refactor to extend evm_agent#(virtual evm_axi4_full_if) like AXI-Lite does.
    // Cfg and Txn types are safe to include (no direct interface references).
    `include "evm_axi4_full_agent/evm_axi4_full_cfg.sv"
    `include "evm_axi4_full_agent/evm_axi4_full_txn.sv"
    // `include "evm_axi4_full_agent/evm_axi4_full_driver.sv"  // needs refactor
    // `include "evm_axi4_full_agent/evm_axi4_full_monitor.sv" // needs refactor
    // `include "evm_axi4_full_agent/evm_axi4_full_agent.sv"   // needs refactor
    
endpackage : evm_vkit_pkg
