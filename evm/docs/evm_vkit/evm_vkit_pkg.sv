//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Package: evm_vkit_pkg
// Description: EVM Verification Kit (VKit) Package
//              Contains all reusable verification agents
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

package evm_vkit_pkg;
    
    import evm_pkg::*;  // Import EVM framework
    
    // CLK Agent
    `include "evm_clk_agent/evm_clk_cfg.sv"
    `include "evm_clk_agent/evm_clk_driver.sv"
    `include "evm_clk_agent/evm_clk_monitor.sv"
    `include "evm_clk_agent/evm_clk_agent.sv"
    
    // RST Agent
    `include "evm_rst_agent/evm_rst_cfg.sv"
    `include "evm_rst_agent/evm_rst_driver.sv"
    `include "evm_rst_agent/evm_rst_monitor.sv"
    `include "evm_rst_agent/evm_rst_agent.sv"
    
    // ADC Agent
    `include "evm_adc_agent/evm_adc_cfg.sv"
    `include "evm_adc_agent/evm_adc_driver.sv"
    `include "evm_adc_agent/evm_adc_monitor.sv"
    `include "evm_adc_agent/evm_adc_agent.sv"
    
    // PCIe Agent
    `include "evm_pcie_agent/evm_pcie_cfg.sv"
    `include "evm_pcie_agent/evm_pcie_driver.sv"
    `include "evm_pcie_agent/evm_pcie_monitor.sv"
    `include "evm_pcie_agent/evm_pcie_agent.sv"
    
    // AXI-Lite Agent
    `include "evm_axi_lite_agent/evm_axi_lite_cfg.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_driver.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_monitor.sv"
    `include "evm_axi_lite_agent/evm_axi_lite_agent.sv"
    
endpackage : evm_vkit_pkg
