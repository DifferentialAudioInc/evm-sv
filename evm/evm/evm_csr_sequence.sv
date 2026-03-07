//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_csr_sequence
// Description: CSR access sequence - collection of CSR transactions
//              Provides convenient methods for building register sequences
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_csr_sequence extends evm_sequence;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_csr_sequence");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Convenient CSR Access Methods
    //==========================================================================
    
    // Add write operation
    virtual function void add_write(bit [31:0] addr, bit [31:0] data, string name = "");
        evm_csr_item item = evm_csr_item::create_write(addr, data, name);
        add_item(item);
        log_info($sformatf("Added CSR write: 0x%08x = 0x%08x %s", 
                 addr, data, name != "" ? $sformatf("(%s)", name) : ""), EVM_DEBUG);
    endfunction
    
    // Add read operation
    virtual function void add_read(bit [31:0] addr, string name = "");
        evm_csr_item item = evm_csr_item::create_read(addr, name);
        add_item(item);
        log_info($sformatf("Added CSR read: 0x%08x %s", 
                 addr, name != "" ? $sformatf("(%s)", name) : ""), EVM_DEBUG);
    endfunction
    
    // Add read-check operation
    virtual function void add_read_check(bit [31:0] addr, bit [31:0] expected, 
                                          bit [31:0] mask = 32'hFFFFFFFF, string name = "");
        evm_csr_item item = evm_csr_item::create_read_check(addr, expected, mask, name);
        add_item(item);
        log_info($sformatf("Added CSR read-check: 0x%08x expect=0x%08x mask=0x%08x %s", 
                 addr, expected, mask, name != "" ? $sformatf("(%s)", name) : ""), EVM_DEBUG);
    endfunction
    
    // Add delay between transactions
    virtual function void add_delay(int cycles);
        // Could implement delay item if needed
        log_info($sformatf("Added delay: %0d cycles", cycles), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // Predefined Register Sequences
    //==========================================================================
    
    // Read all registers in a range
    virtual function void add_reg_dump(bit [31:0] start_addr, bit [31:0] end_addr, int stride = 4);
        for (bit [31:0] addr = start_addr; addr <= end_addr; addr += stride) begin
            add_read(addr, $sformatf("dump_0x%08x", addr));
        end
        log_info($sformatf("Added register dump: 0x%08x to 0x%08x (stride=%0d)", 
                 start_addr, end_addr, stride), EVM_MED);
    endfunction
    
    // Write-Read-Verify sequence
    virtual function void add_write_read_verify(bit [31:0] addr, bit [31:0] data, string name = "");
        add_write(addr, data, name);
        add_read_check(addr, data, 32'hFFFFFFFF, name);
        log_info($sformatf("Added write-read-verify: 0x%08x = 0x%08x %s", 
                 addr, data, name != "" ? $sformatf("(%s)", name) : ""), EVM_MED);
    endfunction
    
endclass : evm_csr_sequence
