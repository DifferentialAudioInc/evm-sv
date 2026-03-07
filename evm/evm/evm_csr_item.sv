//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_csr_item
// Description: CSR (Control/Status Register) transaction item
//              Extends generic sequence_item with address/data pairs
//              Used for simple register access protocols (AXI-Lite, APB, etc.)
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_csr_item extends evm_sequence_item;
    
    //==========================================================================
    // CSR Transaction Fields (protocol-specific)
    //==========================================================================
    rand bit [31:0] addr;         // Register address
    rand bit [31:0] data;         // Write data or read result
    rand bit        read_write;   // 0=read, 1=write
    
    //==========================================================================
    // CSR Verification Fields
    //==========================================================================
    string      reg_name;         // Register name (optional)
    bit [31:0]  expected;         // Expected read data (for read operations)
    bit         check_read;       // Check read data against expected
    bit [31:0]  mask;             // Mask for read check (default all 1s)
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_csr_item");
        super.new(name);
        reg_name = "";
        check_read = 0;
        mask = 32'hFFFFFFFF;
        expected = 0;
    endfunction
    
    //==========================================================================
    // Factory Methods for Common Operations
    //==========================================================================
    
    // Create write transaction
    static function evm_csr_item create_write(bit [31:0] addr, bit [31:0] data, string name = "");
        evm_csr_item item = new("csr_write");
        item.addr = addr;
        item.data = data;
        item.read_write = 1;  // Write
        item.reg_name = name;
        return item;
    endfunction
    
    // Create read transaction
    static function evm_csr_item create_read(bit [31:0] addr, string name = "");
        evm_csr_item item = new("csr_read");
        item.addr = addr;
        item.data = 0;
        item.read_write = 0;  // Read
        item.reg_name = name;
        return item;
    endfunction
    
    // Create read-check transaction
    static function evm_csr_item create_read_check(bit [31:0] addr, bit [31:0] expected, 
                                                     bit [31:0] mask = 32'hFFFFFFFF, string name = "");
        evm_csr_item item = new("csr_read_check");
        item.addr = addr;
        item.read_write = 0;  // Read
        item.expected = expected;
        item.mask = mask;
        item.check_read = 1;
        item.reg_name = name;
        return item;
    endfunction
    
    //==========================================================================
    // CSR-Specific Utility Methods
    //==========================================================================
    virtual function bit is_read();
        return (read_write == 0);
    endfunction
    
    virtual function bit is_write();
        return (read_write == 1);
    endfunction
    
    //==========================================================================
    // Required: convert2string Implementation
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("CSR %s: addr=0x%08x", is_read() ? "READ" : "WRITE", addr);
        if (reg_name != "") begin
            s = {s, $sformatf(" (%s)", reg_name)};
        end
        if (is_write()) begin
            s = {s, $sformatf(" data=0x%08x", data)};
        end else if (check_read) begin
            s = {s, $sformatf(" expected=0x%08x mask=0x%08x", expected, mask)};
        end
        return s;
    endfunction
    
endclass : evm_csr_item
