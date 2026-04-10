//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Package: evm_pkg
// Description: Embedded Verification Methodology (EVM) Framework Package
//              Contains all base classes for the EVM framework
// Author: Eric Dyer
// Date: 2026-03-06
// Updated: 2026-04-09 - Added evm_env, evm_test_registry, evm_sequence_library,
//                       evm_reg_map, evm_reg_predictor
//==============================================================================

package evm_pkg;
    
    //--------------------------------------------------------------------------
    // Core infrastructure (report handler must come first - others depend on it)
    //--------------------------------------------------------------------------
    `include "evm_report_handler.sv"
    `include "evm_log.sv"
    `include "evm_object.sv"
    `include "evm_component.sv"
    
    //--------------------------------------------------------------------------
    // Command-line processing
    //--------------------------------------------------------------------------
    `include "evm_cmdline.sv"
    
    //--------------------------------------------------------------------------
    // TLM infrastructure (before components that use it)
    //--------------------------------------------------------------------------
    `include "evm_tlm.sv"
    
    //--------------------------------------------------------------------------
    // Sequence infrastructure (before agents/sequencer that reference them)
    //--------------------------------------------------------------------------
    `include "evm_sequence_item.sv"
    `include "evm_csr_item.sv"
    `include "evm_sequence.sv"
    `include "evm_csr_sequence.sv"
    `include "evm_sequencer.sv"
    
    //--------------------------------------------------------------------------
    // Agent base components
    //--------------------------------------------------------------------------
    `include "evm_monitor.sv"
    `include "evm_driver.sv"
    `include "evm_agent.sv"
    
    //--------------------------------------------------------------------------
    // Register model (lightweight RAL)
    // Order: field → reg → block → map → predictor
    //--------------------------------------------------------------------------
    `include "evm_reg_field.sv"
    `include "evm_reg.sv"
    `include "evm_reg_block.sv"
    `include "evm_reg_map.sv"         // NEW: address map (multiple blocks)
    `include "evm_reg_predictor.sv"   // NEW: auto-update mirror from bus traffic
    
    //--------------------------------------------------------------------------
    // Streaming components
    //--------------------------------------------------------------------------
    `include "evm_stream_cfg.sv"
    `include "evm_stream_driver.sv"
    `include "evm_stream_monitor.sv"
    `include "evm_stream_agent.sv"
    
    //--------------------------------------------------------------------------
    // Memory model
    //--------------------------------------------------------------------------
    `include "evm_memory_model.sv"
    
    //--------------------------------------------------------------------------
    // Quiescence counter (activity watchdog)
    //--------------------------------------------------------------------------
    `include "evm_qc.sv"
    
    //--------------------------------------------------------------------------
    // Scoreboard
    //--------------------------------------------------------------------------
    `include "evm_scoreboard.sv"
    
    //--------------------------------------------------------------------------
    // Coverage and assertion infrastructure
    //--------------------------------------------------------------------------
    `include "evm_coverage.sv"
    `include "evm_assertions.sv"
    
    //--------------------------------------------------------------------------
    // Virtual sequences and sequence library
    //--------------------------------------------------------------------------
    `include "evm_virtual_sequence.sv"
    `include "evm_sequence_library.sv"  // NEW: named sequence registry + runner
    
    //--------------------------------------------------------------------------
    // Environment base class
    //--------------------------------------------------------------------------
    `include "evm_env.sv"               // NEW: env layer between test and agents
    
    //--------------------------------------------------------------------------
    // Test infrastructure
    // Order: root → base_test → test_registry (registry needs base_test defined)
    //--------------------------------------------------------------------------
    `include "evm_root.sv"
    `include "evm_base_test.sv"
    `include "evm_test_registry.sv"     // NEW: +EVM_TESTNAME test selection
    
endpackage : evm_pkg
