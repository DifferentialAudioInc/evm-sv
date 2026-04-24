//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: uart_unit_test_pkg.sv
// Description: Package for UART unit test.
//              Includes all test classes in dependency order.
//==============================================================================

package uart_unit_test_pkg;
    
    import evm_pkg::*;
    import evm_vkit_pkg::*;
    
    `include "uart_scoreboard.sv"
    `include "uart_unit_test_env.sv"
    `include "uart_basic_test.sv"
    
endpackage : uart_unit_test_pkg
