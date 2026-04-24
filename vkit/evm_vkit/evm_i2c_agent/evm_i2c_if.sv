//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_if.sv
// Description: I2C bus interface — simulates open-drain SCL and SDA.
//              Fixed signal set (not parameterized) for Vivado xvlog compatibility.
//
//   Naming: "initiator" = I2C master (drives SCL, initiates START/STOP)
//           "target"    = I2C peripheral (responds to addressed transactions)
//           — "master"/"slave" are not used in this agent —
//
// Open-drain simulation:
//   The assign statements simulate open-drain (wired-AND) behavior:
//     scl = 0 only if initiator drives it low (clock stretching: target holds low)
//     sda = 0 if initiator OR target drives it low (ACK from either)
//   When neither drives low, the implicit pull-up returns 1'b1.
//
// Connections in tb_top:
//   evm_i2c_if i2c_if(sys_clk, sys_rst_n);
//   DUT.scl → i2c_if.scl (observe)
//   DUT.sda → i2c_if.sda (observe)
//   i2c_if.scl_pull_low → DUT SCL input (if EVM is initiator)
//==============================================================================

interface evm_i2c_if (
    input logic sys_clk,
    input logic sys_rst_n
);
    //--------------------------------------------------------------------------
    // Observed bus signals (resultant open-drain values)
    //--------------------------------------------------------------------------
    logic scl;    // SCL bus level (result of open-drain simulation)
    logic sda;    // SDA bus level (result of open-drain simulation)
    
    //--------------------------------------------------------------------------
    // Drive signals — initiator (master) side
    //--------------------------------------------------------------------------
    logic scl_pull_low;   // 1 = initiator pulling SCL low (clock stretching: target can also)
    logic sda_i_pull_low; // 1 = initiator pulling SDA low (START, data 0, NACK)
    
    //--------------------------------------------------------------------------
    // Drive signals — target (peripheral) side
    //--------------------------------------------------------------------------
    logic sda_t_pull_low; // 1 = target pulling SDA low (ACK, read data bits)
    logic scl_t_pull_low; // 1 = target holding SCL low (clock stretching, optional)
    
    //--------------------------------------------------------------------------
    // Open-drain simulation: pulled high unless driven low
    //--------------------------------------------------------------------------
    assign scl = (scl_pull_low || scl_t_pull_low) ? 1'b0 : 1'b1;
    assign sda = (sda_i_pull_low || sda_t_pull_low) ? 1'b0 : 1'b1;
    
    //--------------------------------------------------------------------------
    // Helpers
    //--------------------------------------------------------------------------
    // Returns 1 if a START condition is currently in progress (SCL=1, SDA=0)
    function automatic bit start_active();
        return (scl == 1'b1 && sda == 1'b0 && !scl_pull_low && !scl_t_pull_low);
    endfunction

endinterface : evm_i2c_if
