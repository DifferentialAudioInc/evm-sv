//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_uart_cfg.sv
// Description: Configuration for the EVM UART agent.
//              Covers standard UART framing: baud rate, data bits,
//              parity, stop bits, and optional CTS/RTS flow control.
//
// API — Public Interface:
//   [evm_uart_cfg]
//   new(name)               — constructor; call compute_timing() after setting baud_rate
//   compute_timing()        — derive bit_period_ns from baud_rate
//   calc_parity(data)       — calculate parity bit for given data byte
//   bit_period_ns           — nanoseconds per bit (derived from baud_rate)
//
// Usage:
//   evm_uart_cfg cfg = new("uart_cfg");
//   cfg.baud_rate = 115200;
//   cfg.data_bits = 8;
//   cfg.parity    = EVM_UART_PARITY_NONE;
//   cfg.stop_bits = 1.0;
//   cfg.compute_timing();   // must call after setting baud_rate
//==============================================================================

// Parity enum (package scope)
typedef enum int {
    EVM_UART_PARITY_NONE  = 0,
    EVM_UART_PARITY_ODD   = 1,
    EVM_UART_PARITY_EVEN  = 2,
    EVM_UART_PARITY_MARK  = 3,   // parity bit always 1
    EVM_UART_PARITY_SPACE = 4    // parity bit always 0
} evm_uart_parity_e;

class evm_uart_cfg extends evm_object;
    
    //==========================================================================
    // UART frame parameters
    //==========================================================================
    int               baud_rate    = 115200;           // baud rate (bits/sec)
    int               data_bits    = 8;                // 5, 6, 7, 8, or 9
    evm_uart_parity_e parity       = EVM_UART_PARITY_NONE;
    real              stop_bits    = 1.0;              // 1, 1.5, or 2
    bit               flow_control = 0;                // 1 = enable CTS/RTS
    
    //==========================================================================
    // Derived timing (set by compute_timing())
    //==========================================================================
    int  bit_period_ns   = 8680;  // ns per bit at 115200 baud (default)
    int  sample_offset_ns;        // half-bit offset for center sampling
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_uart_cfg");
        super.new(name);
        compute_timing();
    endfunction
    
    //==========================================================================
    // compute_timing() — derive bit_period_ns from baud_rate
    // Must be called after changing baud_rate.
    //==========================================================================
    function void compute_timing();
        if (baud_rate <= 0) begin
            log_error("[UART CFG] baud_rate must be > 0");
            return;
        end
        bit_period_ns   = 1000000000 / baud_rate;
        sample_offset_ns = bit_period_ns / 2;
        log_info($sformatf("[UART CFG] baud=%0d bit_period=%0dns data=%0d parity=%s stop=%.1f",
                           baud_rate, bit_period_ns, data_bits, parity.name(), stop_bits), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // calc_parity() — calculate parity bit for a data word
    //==========================================================================
    function bit calc_parity(bit [8:0] data);
        int      i;
        int      ones;
        bit      par_bit;
        ones = 0;
        for (i = 0; i < data_bits; i++) begin
            if (data[i]) ones++;
        end
        case (parity)
            EVM_UART_PARITY_ODD:   par_bit = (ones % 2 == 0) ? 1'b1 : 1'b0;
            EVM_UART_PARITY_EVEN:  par_bit = (ones % 2 == 0) ? 1'b0 : 1'b1;
            EVM_UART_PARITY_MARK:  par_bit = 1'b1;
            EVM_UART_PARITY_SPACE: par_bit = 1'b0;
            default:               par_bit = 1'b0;
        endcase
        return par_bit;
    endfunction
    
    //==========================================================================
    // Helper: does this config have a parity bit?
    //==========================================================================
    function bit has_parity();
        return (parity != EVM_UART_PARITY_NONE);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("UART_CFG: %0d baud %0dN%.1f%s",
                         baud_rate, data_bits, stop_bits,
                         has_parity() ? $sformatf(" parity=%s", parity.name()) : "");
    endfunction
    
    virtual function string get_type_name();
        return "evm_uart_cfg";
    endfunction
    
endclass : evm_uart_cfg
