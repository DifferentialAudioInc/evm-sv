//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Package: evm_pkg
// Description: Embedded Verification Methodology (EVM) Framework Package
//              Contains all base classes for the EVM framework
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

package evm_pkg;
    
    // Include all EVM framework files in dependency order
    
    // Core infrastructure (report handler must come first)
    `include "evm_report_handler.sv"
    `include "evm_log.sv"
    `include "evm_object.sv"
    `include "evm_component.sv"
    
    // Command-line processing
    `include "evm_cmdline.sv"
    
    // TLM infrastructure (before components that use it)
    `include "evm_tlm.sv"
    
    // Sequence infrastructure
    `include "evm_sequence_item.sv"
    `include "evm_csr_item.sv"
    `include "evm_sequence.sv"
    `include "evm_csr_sequence.sv"
    `include "evm_sequencer.sv"
    
    // Agent components
    `include "evm_monitor.sv"
    `include "evm_driver.sv"
    `include "evm_agent.sv"
    
    // Register model (lightweight RAL)
    `include "evm_reg_field.sv"
    `include "evm_reg.sv"
    `include "evm_reg_block.sv"
    
    // Streaming components
    `include "evm_stream_cfg.sv"
    `include "evm_stream_driver.sv"
    `include "evm_stream_monitor.sv"
    `include "evm_stream_agent.sv"
    
    // Quiescence counter (activity watchdog)
    `include "evm_qc.sv"
    
    // Scoreboard
    `include "evm_scoreboard.sv"
    
    // Coverage infrastructure
    `include "evm_coverage.sv"
    
    // Assertion infrastructure
    `include "evm_assertions.sv"
    
    // Virtual sequences
    `include "evm_virtual_sequence.sv"
    
    // Test infrastructure
    `include "evm_root.sv"
    `include "evm_base_test.sv"
    
endpackage : evm_pkg
