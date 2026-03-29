//==============================================================================
// Agents Package
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Package: agents_pkg
// Description: Package containing all agent definitions
//==============================================================================

package agents_pkg;
    
    // Import EVM base classes
    import evm_pkg::*;
    
    // Include agent files
    `include "clk_agent.sv"
    `include "rst_agent.sv"
    
endpackage : agents_pkg
