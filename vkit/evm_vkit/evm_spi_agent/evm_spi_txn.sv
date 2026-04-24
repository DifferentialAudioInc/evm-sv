//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_txn.sv
// Description: SPI transaction item — represents one complete CS_N assertion.
//              Covers both initiator (EVM drives) and target (DUT drives) cases.
//              Captures: CS select, command byte, address, MOSI data, MISO data.
//
// API — Public Interface:
//   [evm_spi_txn extends evm_sequence_item]
//   cs_select            — which CS line was active (0-7)
//   cmd                  — first byte of transfer (command opcode)
//   addr                 — address bytes assembled as 32-bit value
//   addr_num_bytes       — how many address bytes (1-4)
//   data_mosi[]          — bytes from initiator to target (write data)
//   data_miso[]          — bytes from target to initiator (read data)
//   num_data_bytes       — data bytes transferred (excludes cmd + addr)
//   is_read              — 1 = read command, 0 = write command
//   convert2string()
//   get_mosi_byte(n)     — return nth MOSI data byte
//   get_miso_byte(n)     — return nth MISO data byte
//==============================================================================

class evm_spi_txn extends evm_sequence_item;
    
    //==========================================================================
    // Transaction fields
    //==========================================================================
    rand int          cs_select;       // which CS was active (0-7)
    rand bit [7:0]    cmd;             // command byte (first byte of transfer)
    bit [31:0]        addr;            // address field (assembled from addr_num_bytes)
    int               addr_num_bytes;  // how many address bytes in transfer
    rand bit [7:0]    data_mosi[];     // initiator → target bytes (write data or dummy)
    bit [7:0]         data_miso[];     // target → initiator bytes (read data)
    int               num_data_bytes;  // data bytes transferred (excludes cmd+addr)
    bit               is_read;         // 1=read command (miso has data), 0=write
    
    //==========================================================================
    // Constraints
    //==========================================================================
    constraint valid_cs {
        cs_select >= 0;
        cs_select <= 7;
    }
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_txn");
        super.new(name);
        cs_select      = 0;
        cmd            = 8'h03;  // READ default
        addr           = 0;
        addr_num_bytes = 1;
        num_data_bytes = 0;
        is_read        = 1;
        data_mosi      = new[0];
        data_miso      = new[0];
    endfunction
    
    //==========================================================================
    // Accessor helpers
    //==========================================================================
    
    function bit [7:0] get_mosi_byte(int n);
        if (n >= 0 && n < data_mosi.size())
            return data_mosi[n];
        return 8'hFF;
    endfunction
    
    function bit [7:0] get_miso_byte(int n);
        if (n >= 0 && n < data_miso.size())
            return data_miso[n];
        return 8'hFF;
    endfunction
    
    //==========================================================================
    // String conversion
    //==========================================================================
    virtual function string convert2string();
        string s;
        int    i;
        int    max_show;
        
        s = $sformatf("SPI_TXN CS[%0d] cmd=0x%02x", cs_select, cmd);
        
        if (addr_num_bytes > 0)
            s = {s, $sformatf(" addr=0x%0x(%0dB)", addr, addr_num_bytes)};
        
        s = {s, $sformatf(" %s %0d_data_bytes", is_read ? "READ" : "WRITE", num_data_bytes)};
        
        // Show up to 8 data bytes
        max_show = num_data_bytes;
        if (max_show > 8) max_show = 8;
        
        if (is_read && data_miso.size() > 0) begin
            s = {s, " MISO["};
            for (i = 0; i < max_show; i++) begin
                s = {s, $sformatf("%02x", data_miso[i])};
                if (i < max_show - 1) s = {s, " "};
            end
            if (num_data_bytes > 8) s = {s, "..."};
            s = {s, "]"};
        end else if (!is_read && data_mosi.size() > 0) begin
            s = {s, " MOSI["};
            for (i = 0; i < max_show; i++) begin
                s = {s, $sformatf("%02x", data_mosi[i])};
                if (i < max_show - 1) s = {s, " "};
            end
            if (num_data_bytes > 8) s = {s, "..."};
            s = {s, "]"};
        end
        
        s = {s, $sformatf(" @[%.1f..%.1f]ns", real'(start_time)/1.0, real'(end_time)/1.0)};
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_spi_txn";
    endfunction
    
endclass : evm_spi_txn
