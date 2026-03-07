//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_reg_block
// Description: Lightweight register block model (similar to UVM RAL block)
//              Contains multiple registers and manages register access
// Author: Engineering Team
// Date: 2026-03-07
//==============================================================================

class evm_reg_block extends evm_object;
    
    //==========================================================================
    // Block Properties
    //==========================================================================
    protected evm_reg           registers[$];    // List of registers
    protected evm_reg           reg_map[string]; // Name-based lookup
    protected bit [63:0]        base_address;    // Block base address
    protected evm_component     default_agent;   // Default agent for all regs
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name, bit [63:0] base_addr = 0);
        super.new(name);
        this.base_address = base_addr;
        this.default_agent = null;
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    
    // Set default agent for all registers
    function void set_agent(evm_component agent);
        this.default_agent = agent;
        // Apply to existing registers
        foreach (registers[i]) begin
            registers[i].set_agent(agent);
        end
        log_info($sformatf("Set default agent for block %s", get_name()), EVM_DEBUG);
    endfunction
    
    function bit [63:0] get_base_address();
        return base_address;
    endfunction
    
    //==========================================================================
    // Register Management
    //==========================================================================
    
    // Add register to block
    virtual function void add_reg(evm_reg reg);
        reg.set_parent(this);
        
        // If default agent configured, assign to register
        if (default_agent != null) begin
            reg.set_agent(default_agent);
        end
        
        registers.push_back(reg);
        reg_map[reg.get_name()] = reg;
        
        log_info($sformatf("Added register %s @0x%08x to block %s", 
                          reg.get_name(), reg.get_address(), get_name()), EVM_DEBUG);
    endfunction
    
    // Get register by name
    virtual function evm_reg get_reg_by_name(string name);
        if (reg_map.exists(name)) begin
            return reg_map[name];
        end
        log_warning($sformatf("Register %s not found in block %s", name, get_name()));
        return null;
    endfunction
    
    // Get register by address
    virtual function evm_reg get_reg_by_address(bit [63:0] addr);
        foreach (registers[i]) begin
            if (registers[i].get_address() == addr) begin
                return registers[i];
            end
        end
        log_warning($sformatf("Register @0x%08x not found in block %s", addr, get_name()));
        return null;
    endfunction
    
    // Get all registers
    virtual function void get_registers(ref evm_reg reg_list[$]);
        reg_list = registers;
    endfunction
    
    //==========================================================================
    // Reset - Reset all registers in block
    //==========================================================================
    virtual function void reset(string kind = "HARD");
        foreach (registers[i]) begin
            registers[i].reset(kind);
        end
        log_info($sformatf("Block %s reset (%s)", get_name(), kind), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Write by Name - Convenience method
    //==========================================================================
    virtual task write_reg(string reg_name, bit [63:0] value, output bit status);
        evm_reg reg;
        
        reg = get_reg_by_name(reg_name);
        if (reg == null) begin
            log_error($sformatf("Cannot write - register %s not found", reg_name));
            status = 0;
            return;
        end
        
        reg.write(value, status);
    endtask
    
    //==========================================================================
    // Read by Name - Convenience method
    //==========================================================================
    virtual task read_reg(string reg_name, output bit [63:0] value, output bit status);
        evm_reg reg;
        
        reg = get_reg_by_name(reg_name);
        if (reg == null) begin
            log_error($sformatf("Cannot read - register %s not found", reg_name));
            status = 0;
            value = 0;
            return;
        end
        
        reg.read(value, status);
    endtask
    
    //==========================================================================
    // Read-Check by Name - Convenience method
    //==========================================================================
    virtual task read_check_reg(string reg_name, bit [63:0] expected, 
                                bit [63:0] mask = '1, output bit status);
        evm_reg reg;
        
        reg = get_reg_by_name(reg_name);
        if (reg == null) begin
            log_error($sformatf("Cannot read-check - register %s not found", reg_name));
            status = 0;
            return;
        end
        
        reg.read_check(expected, mask, status);
    endtask
    
    //==========================================================================
    // Mirror - Read and check all registers
    //==========================================================================
    virtual task mirror(output bit status);
        bit reg_status;
        status = 1;
        
        log_info($sformatf("Mirroring block %s (%0d registers)", get_name(), registers.size()), EVM_MED);
        
        foreach (registers[i]) begin
            registers[i].mirror(reg_status);
            if (!reg_status) status = 0;
        end
        
        if (status) begin
            log_info($sformatf("Block %s mirror passed", get_name()), EVM_LOW);
        end else begin
            log_error($sformatf("Block %s mirror failed", get_name()));
        end
    endtask
    
    //==========================================================================
    // Write All - Write all registers with their current mirrored values
    //==========================================================================
    virtual task write_all(output bit status);
        bit reg_status;
        status = 1;
        
        log_info($sformatf("Writing all registers in block %s", get_name()), EVM_MED);
        
        foreach (registers[i]) begin
            bit [63:0] value = registers[i].get();
            registers[i].write(value, reg_status);
            if (!reg_status) status = 0;
        end
    endtask
    
    //==========================================================================
    // Read All - Read all registers
    //==========================================================================
    virtual task read_all(output bit status);
        bit reg_status;
        bit [63:0] value;
        status = 1;
        
        log_info($sformatf("Reading all registers in block %s", get_name()), EVM_MED);
        
        foreach (registers[i]) begin
            registers[i].read(value, reg_status);
            if (!reg_status) status = 0;
        end
    endtask
    
    //==========================================================================
    // Dump - Print all register values
    //==========================================================================
    virtual function void dump();
        log_info($sformatf("=== Register Block: %s @0x%08x ===", get_name(), base_address), EVM_NONE);
        foreach (registers[i]) begin
            log_info(registers[i].convert2string(), EVM_NONE);
        end
    endfunction
    
    //==========================================================================
    // String Conversion
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("Register Block: %s @0x%08x (%0d registers)\n", 
                     get_name(), base_address, registers.size());
        foreach (registers[i]) begin
            s = {s, registers[i].convert2string()};
        end
        return s;
    endfunction
    
endclass : evm_reg_block
