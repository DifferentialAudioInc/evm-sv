//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_device_model.sv
// Description: Per-device I2C target model with register-map memory backing.
//              Each instance represents one I2C device address.
//              Uses evm_memory_model as backing store for register data.
//
// API — Public Interface:
//   new(name, i2c_addr, reg_size)   — constructor; creates backing memory
//   matches_addr(addr)              — returns 1 if addr matches i2c_addr
//   read_reg(reg_addr)              — read register at reg_addr (1 or 2 byte addr)
//   write_reg(reg_addr, data)       — write register at reg_addr
//   set_reg_ptr(reg_addr)           — set internal pointer (for sequential reads)
//   get_reg_ptr()                   — return current pointer
//   advance_ptr()                   — increment pointer (sequential access)
//
//   Backdoor API:
//   load_byte(reg_addr, data)       — directly write a register
//   peek_byte(reg_addr)             — directly read a register
//   load_array(base, data[])        — load multiple registers from array
//   fill(base, n, pattern)          — fill registers with pattern
//   clear()                         — fill all registers with 0x00
//   dump(base, n)                   — print register contents to log
//   mem                             — direct evm_memory_model handle
//==============================================================================

class evm_i2c_device_model extends evm_object;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    bit [6:0]    i2c_addr;           // 7-bit I2C device address (0x00-0x7F)
    int          reg_size_bytes = 256; // register address space size
    int          reg_addr_bytes = 1;   // register address width: 1=256 regs, 2=64K regs
    
    //==========================================================================
    // Backing memory (register map)
    //==========================================================================
    evm_memory_model mem;  // direct access for backdoor
    
    //==========================================================================
    // Internal state — sequential register access pointer
    //==========================================================================
    local int m_reg_ptr;  // current register pointer for sequential R/W
    
    //==========================================================================
    // Statistics
    //==========================================================================
    longint read_count  = 0;
    longint write_count = 0;
    longint txn_count   = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_i2c_device", bit [6:0] addr = 7'h50, int sz = 256);
        super.new(name);
        i2c_addr       = addr;
        reg_size_bytes = sz;
        m_reg_ptr      = 0;
        mem            = new($sformatf("%s.mem", name), sz);
        fill(0, sz, 8'h00);  // initialize to 0
    endfunction
    
    //==========================================================================
    // Address matching
    //==========================================================================
    function bit matches_addr(bit [6:0] addr);
        return (addr == i2c_addr);
    endfunction
    
    //==========================================================================
    // Register pointer (for sequential access)
    //==========================================================================
    function void set_reg_ptr(int reg_addr);
        m_reg_ptr = reg_addr % reg_size_bytes;
    endfunction
    
    function int get_reg_ptr();
        return m_reg_ptr;
    endfunction
    
    function void advance_ptr();
        m_reg_ptr = (m_reg_ptr + 1) % reg_size_bytes;
    endfunction
    
    //==========================================================================
    // Protocol: read one byte from current register pointer, advance
    //==========================================================================
    function byte read_reg(int reg_addr = -1);
        int addr;
        if (reg_addr >= 0)
            addr = reg_addr % reg_size_bytes;
        else
            addr = m_reg_ptr;
        read_count++;
        advance_ptr();
        return mem.read_byte(longint'(addr));
    endfunction
    
    //==========================================================================
    // Protocol: write one byte to register address
    //==========================================================================
    function void write_reg(int reg_addr, byte data);
        int addr;
        addr = reg_addr % reg_size_bytes;
        mem.write_byte(longint'(addr), data);
        m_reg_ptr = (addr + 1) % reg_size_bytes;  // advance pointer after write
        write_count++;
    endfunction
    
    //==========================================================================
    // Backdoor API
    //==========================================================================
    function void load_byte(int reg_addr, byte data);
        if (reg_addr < reg_size_bytes)
            mem.write_byte(longint'(reg_addr), data);
        else
            log_error($sformatf("[I2C DEV 0x%02x] Backdoor addr %0d out of range", i2c_addr, reg_addr));
    endfunction
    
    function byte peek_byte(int reg_addr);
        if (reg_addr < reg_size_bytes)
            return mem.read_byte(longint'(reg_addr));
        log_error($sformatf("[I2C DEV 0x%02x] Peek addr %0d out of range", i2c_addr, reg_addr));
        return 8'h00;
    endfunction
    
    function void load_array(int base_addr, byte data[]);
        int i;
        for (i = 0; i < data.size(); i++) begin
            if ((base_addr + i) < reg_size_bytes)
                mem.write_byte(longint'(base_addr + i), data[i]);
        end
        log_info($sformatf("[I2C DEV 0x%02x] Loaded %0d bytes at addr %0d",
                           i2c_addr, data.size(), base_addr), EVM_LOW);
    endfunction
    
    function void fill(int base_addr, int n_bytes, byte pattern = 8'h00);
        int i;
        for (i = 0; i < n_bytes; i++) begin
            if ((base_addr + i) < reg_size_bytes)
                mem.write_byte(longint'(base_addr + i), pattern);
        end
    endfunction
    
    function void clear();
        fill(0, reg_size_bytes, 8'h00);
        log_info($sformatf("[I2C DEV 0x%02x] Cleared (filled 0x00)", i2c_addr), EVM_LOW);
    endfunction
    
    function void dump(int base_addr = 0, int n_bytes = -1);
        int    i;
        int    end_addr;
        string line;
        if (n_bytes < 0) n_bytes = reg_size_bytes - base_addr;
        end_addr = base_addr + n_bytes;
        if (end_addr > reg_size_bytes) end_addr = reg_size_bytes;
        log_info($sformatf("[I2C DEV 0x%02x] Register dump [0x%02x..0x%02x]:",
                           i2c_addr, base_addr, end_addr-1), EVM_LOW);
        i = base_addr;
        while (i < end_addr) begin
            int j;
            int row_end;
            line = $sformatf("  0x%04x: ", i);
            row_end = i + 16;
            if (row_end > end_addr) row_end = end_addr;
            for (j = i; j < row_end; j++)
                line = {line, $sformatf("%02x ", peek_byte(j))};
            log_info(line, EVM_LOW);
            i = i + 16;
        end
    endfunction
    
    virtual function string convert2string();
        return $sformatf("I2C_DEV[0x%02x]: regs=%0d ptr=%0d R/W=%0d/%0d",
                         i2c_addr, reg_size_bytes, m_reg_ptr, read_count, write_count);
    endfunction
    
    virtual function string get_type_name();
        return "evm_i2c_device_model";
    endfunction
    
endclass : evm_i2c_device_model
