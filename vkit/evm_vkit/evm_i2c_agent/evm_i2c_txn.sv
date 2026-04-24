//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_txn.sv
// Description: I2C transaction item — represents one complete I2C transaction
//              (START to STOP, or START to repeated-START).
//
// API — Public Interface:
//   [evm_i2c_txn extends evm_sequence_item]
//   dev_addr        — 7-bit device address (bits[6:0])
//   is_write        — 1=write transaction, 0=read transaction
//   reg_addr        — register address (16-bit, width set by cfg.reg_addr_bytes)
//   reg_addr_bytes  — how many bytes used for register address (1 or 2)
//   data[]          — data bytes transferred (written or read)
//   ack_received[]  — ACK/NACK for each byte (1=ACK, 0=NACK)
//   addr_nack       — 1 if device did not ACK the address byte
//   repeated_start  — 1 if transaction ended with repeated START (not STOP)
//   convert2string()
//==============================================================================

class evm_i2c_txn extends evm_sequence_item;
    
    //==========================================================================
    // Transaction fields
    //==========================================================================
    rand bit [6:0]  dev_addr;       // 7-bit device I2C address
    rand bit        is_write;       // 1=WRITE, 0=READ
    rand bit [15:0] reg_addr;       // register address (1 or 2 bytes per reg_addr_bytes)
    int             reg_addr_bytes; // bytes used for register address
    rand bit [7:0]  data[];         // data bytes (written for write, read for read)
    bit             ack_received[]; // ACK status per data byte (1=ACK, 0=NACK)
    bit             addr_nack;      // 1 = device didn't ACK the address phase
    bit             repeated_start; // 1 = ended with Repeated START (not STOP)
    
    //==========================================================================
    // Constraints
    //==========================================================================
    constraint valid_addr {
        dev_addr inside {[7'h08:7'h77]};  // valid I2C address range
    }
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_i2c_txn");
        super.new(name);
        dev_addr       = 7'h50;
        is_write       = 1;
        reg_addr       = 16'h0000;
        reg_addr_bytes = 1;
        addr_nack      = 0;
        repeated_start = 0;
        data           = new[0];
        ack_received   = new[0];
    endfunction
    
    //==========================================================================
    // Helpers
    //==========================================================================
    function int get_num_bytes();
        return data.size();
    endfunction
    
    function bit all_acked();
        int i;
        for (i = 0; i < ack_received.size(); i++) begin
            if (!ack_received[i]) return 0;
        end
        return 1;
    endfunction
    
    //==========================================================================
    // String conversion
    //==========================================================================
    virtual function string convert2string();
        string s;
        int    i;
        int    max_show;
        
        s = $sformatf("I2C_TXN [0x%02x] %s reg=0x%0x(%0dB) %0d_bytes",
                      dev_addr, is_write ? "WR" : "RD",
                      reg_addr, reg_addr_bytes, data.size());
        
        if (addr_nack) s = {s, " ADDR_NACK"};
        if (repeated_start) s = {s, " rSTART"};
        
        // Show up to 8 data bytes
        max_show = data.size();
        if (max_show > 8) max_show = 8;
        
        if (max_show > 0) begin
            s = {s, " ["};
            for (i = 0; i < max_show; i++) begin
                s = {s, $sformatf("%02x", data[i])};
                if (i < ack_received.size() && !ack_received[i]) s = {s, "!"};
                if (i < max_show - 1) s = {s, " "};
            end
            if (data.size() > 8) s = {s, "..."};
            s = {s, "]"};
        end
        
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_i2c_txn";
    endfunction
    
endclass : evm_i2c_txn
