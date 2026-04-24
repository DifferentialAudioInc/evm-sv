//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_uart_txn.sv
// Description: UART transaction — one transmitted or received UART frame.
//
// API — Public Interface:
//   [evm_uart_txn extends evm_sequence_item]
//   data            — data bits (up to 9 bits)
//   parity_error    — 1 if received parity didn't match expected
//   framing_error   — 1 if stop bit was 0 (noise or baud mismatch)
//   break_detect    — 1 if RX was held low for > 1 full frame
//   is_tx           — 1=transmitted by EVM, 0=received from DUT
//   convert2string()
//==============================================================================

class evm_uart_txn extends evm_sequence_item;
    
    //==========================================================================
    // Transaction fields
    //==========================================================================
    rand bit [8:0]  data;           // data word (LSBs used per cfg.data_bits)
    bit             parity_error;   // 1 = parity mismatch (RX only)
    bit             framing_error;  // 1 = stop bit was 0 (RX only)
    bit             break_detect;   // 1 = line held low > 1 frame (RX only)
    bit             is_tx;          // 1=transmitted by EVM, 0=received from DUT
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_uart_txn");
        super.new(name);
        data          = 9'h000;
        parity_error  = 0;
        framing_error = 0;
        break_detect  = 0;
        is_tx         = 0;
    endfunction
    
    //==========================================================================
    // Helpers
    //==========================================================================
    function bit is_error();
        return (parity_error || framing_error || break_detect);
    endfunction
    
    function string get_char();
        if (data >= 32 && data <= 126)
            return $sformatf("'%s'", string'(byte'(data)));
        return "   ";
    endfunction
    
    //==========================================================================
    // String conversion
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("UART_%s 0x%02x %s",
                      is_tx ? "TX" : "RX",
                      data[7:0],
                      get_char());
        if (parity_error)  s = {s, " PARITY_ERR"};
        if (framing_error) s = {s, " FRAMING_ERR"};
        if (break_detect)  s = {s, " BREAK"};
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_uart_txn";
    endfunction
    
endclass : evm_uart_txn
