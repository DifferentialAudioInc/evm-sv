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
    `include "evm_log.sv"
    `include "evm_object.sv"
    `include "evm_component.sv"
    `include "evm_monitor.sv"
    `include "evm_driver.sv"
    `include "evm_agent.sv"
    `include "evm_root.sv"
    `include "evm_base_test.sv"
    
endpackage : evm_pkg
