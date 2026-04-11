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
// Updated: 2026-04-10 - Reordered for Vivado xvlog compatibility:
//                       evm_qc moved after evm_root (evm_root forward ref fix)
//                       Streaming files excluded (add separately if needed)
//==============================================================================

package evm_pkg;
    
    //--------------------------------------------------------------------------
    // Core infrastructure (report handler must come first)
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
    // Sequence infrastructure
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
    // Register model (RAL): field → reg → block → map → predictor
    //--------------------------------------------------------------------------
    `include "evm_reg_field.sv"
    `include "evm_reg.sv"
    `include "evm_reg_block.sv"
    `include "evm_reg_map.sv"
    `include "evm_reg_predictor.sv"
    
    //--------------------------------------------------------------------------
    // Streaming components (Vivado xvlog compatibility fixed 2026-04-10)
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
    // Scoreboard
    //--------------------------------------------------------------------------
    `include "evm_scoreboard.sv"
    
    //--------------------------------------------------------------------------
    // Coverage and assertion infrastructure
    //--------------------------------------------------------------------------
    `include "evm_coverage.sv"
    `include "evm_assertions.sv"
    
    //--------------------------------------------------------------------------
    // Environment base class
    //--------------------------------------------------------------------------
    `include "evm_env.sv"
    
    //--------------------------------------------------------------------------
    // Test infrastructure
    // ORDER MATTERS for Vivado xvlog:
    //   evm_root must come before evm_qc (qc uses evm_root::get())
    //   evm_root must come before evm_virtual_sequence (vseq uses evm_root::get())
    //   evm_base_test must come before evm_test_registry (registry uses base_test)
    //   evm_qc must come after evm_root but before evm_base_test (base_test uses qc)
    //--------------------------------------------------------------------------
    `include "evm_root.sv"
    `include "evm_qc.sv"
    
    //--------------------------------------------------------------------------
    // Virtual sequences and sequence library (after root — reference evm_root::get())
    //--------------------------------------------------------------------------
    `include "evm_virtual_sequence.sv"
    `include "evm_sequence_library.sv"
    
    `include "evm_base_test.sv"
    `include "evm_test_registry.sv"
    
endpackage : evm_pkg
