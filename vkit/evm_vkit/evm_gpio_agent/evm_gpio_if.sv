//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_gpio_if
// Description: General Purpose I/O interface
//              Supports input, output, and bidirectional pins
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

interface evm_gpio_if #(
    parameter NUM_PINS = 32
)(
    input logic clk,
    input logic rst_n
);

    //==========================================================================
    // GPIO Signals
    //==========================================================================
    logic [NUM_PINS-1:0] gpio_out;        // Output from DUT
    logic [NUM_PINS-1:0] gpio_in;         // Input to DUT
    logic [NUM_PINS-1:0] gpio_dir;        // Direction: 1=output, 0=input
    logic [NUM_PINS-1:0] gpio_enable;     // Pin enable
    
    //==========================================================================
    // Common GPIO Aliases (for convenience)
    //==========================================================================
    logic [7:0] leds;           // LED outputs
    logic [7:0] buttons;        // Button inputs
    logic [3:0] interrupts;     // Interrupt signals
    
    // Map to gpio signals
    assign leds = gpio_out[7:0];
    assign gpio_in[15:8] = buttons;
    assign interrupts = gpio_out[19:16];
    
    //==========================================================================
    // Modports
    //==========================================================================
    
    // DUT modport
    modport dut (
        input  clk, rst_n,
        output gpio_out,
        input  gpio_in,
        output gpio_dir,
        output gpio_enable
    );
    
    // Driver modport (drives inputs to DUT)
    modport driver (
        input  clk, rst_n,
        input  gpio_out,
        output gpio_in,
        input  gpio_dir,
        input  gpio_enable
    );
    
    // Monitor modport
    modport monitor (
        input clk, rst_n,
        input gpio_out,
        input gpio_in,
        input gpio_dir,
        input gpio_enable
    );
    
endinterface : evm_gpio_if
