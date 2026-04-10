//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_reg
// Description: Lightweight register model (similar to UVM RAL)
//              Contains fields and generates evm_csr_item transactions
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_reg extends evm_object;
    
    //==========================================================================
    // Register Properties
    //==========================================================================
    protected bit [63:0]        address;        // Register address
    protected int               n_bits;         // Register width (8, 16, 32, 64)
    protected evm_reg_field     fields[$];      // List of fields
    protected string            reg_name;       // Register name
    
    // Parent block and agent references
    protected evm_reg_block     parent_block;
    protected evm_component     target_agent;   // Agent that executes transactions
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name, bit [63:0] addr, int n_bits = 32);
        super.new(name);
        this.reg_name = name;
        this.address = addr;
        this.n_bits = n_bits;
        this.parent_block = null;
        this.target_agent = null;
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    function void set_parent(evm_reg_block parent);
        this.parent_block = parent;
    endfunction
    
    function void set_agent(evm_component agent);
        this.target_agent = agent;
    endfunction
    
    function bit [63:0] get_address();
        return address;
    endfunction
    
    function int get_n_bits();
        return n_bits;
    endfunction
    
    //==========================================================================
    // Field Management
    //==========================================================================
    
    // Add a field to this register
    virtual function void add_field(evm_reg_field field);
        field.set_parent(this);
        fields.push_back(field);
        log_info($sformatf("Added field %s to register %s", field.get_name(), reg_name), EVM_DEBUG);
    endfunction
    
    // Get field by name
    virtual function evm_reg_field get_field_by_name(string name);
        foreach (fields[i]) begin
            if (fields[i].get_name() == name)
                return fields[i];
        end
        log_warning($sformatf("Field %s not found in register %s", name, reg_name));
        return null;
    endfunction
    
    // Get all fields
    virtual function void get_fields(ref evm_reg_field field_list[$]);
        field_list = fields;
    endfunction
    
    //==========================================================================
    // Value Assembly/Disassembly
    //==========================================================================
    
    // Get full register value from fields
    virtual function bit [63:0] get();
        bit [63:0] value = 0;
        foreach (fields[i]) begin
            bit [63:0] field_val = fields[i].get();
            bit [63:0] field_mask = fields[i].get_mask();
            value |= (field_val << fields[i].get_lsb_pos()) & field_mask;
        end
        return value;
    endfunction
    
    // Set full register value (updates all fields)
    virtual function void set(bit [63:0] value);
        foreach (fields[i]) begin
            bit [63:0] field_val = (value >> fields[i].get_lsb_pos()) & ((1 << fields[i].get_size()) - 1);
            fields[i].set(field_val);
        end
    endfunction
    
    //==========================================================================
    // Reset
    //==========================================================================
    virtual function void reset(string kind = "HARD");
        foreach (fields[i]) begin
            fields[i].reset(kind);
        end
        log_info($sformatf("Register %s reset", reg_name), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // Predict - Update mirror based on transaction
    //==========================================================================
    virtual function void predict(bit [63:0] value, bit is_read);
        foreach (fields[i]) begin
            bit [63:0] field_val = (value >> fields[i].get_lsb_pos()) & ((1 << fields[i].get_size()) - 1);
            fields[i].predict(field_val, is_read);
        end
    endfunction
    
    //==========================================================================
    // Write Task - Generates evm_csr_item and executes via agent
    //==========================================================================
    virtual task write(bit [63:0] value, output bit status);
        evm_csr_item item;
        
        if (target_agent == null) begin
            log_error($sformatf("No agent configured for register %s", reg_name));
            status = 0;
            return;
        end
        
        // Create write transaction
        item = evm_csr_item::create_write(address[31:0], value[31:0], reg_name);
        
        log_info($sformatf("Writing register %s @0x%08x = 0x%08x", 
                          reg_name, address, value), EVM_MED);
        
        // Execute transaction via agent
        execute_item(item, status);
        
        // Update mirror if successful
        if (status) begin
            predict(value, 0);  // 0 = write
        end
    endtask
    
    //==========================================================================
    // Read Task - Generates evm_csr_item and executes via agent
    //==========================================================================
    virtual task read(output bit [63:0] value, output bit status);
        evm_csr_item item;
        
        if (target_agent == null) begin
            log_error($sformatf("No agent configured for register %s", reg_name));
            status = 0;
            value = 0;
            return;
        end
        
        // Create read transaction
        item = evm_csr_item::create_read(address[31:0], reg_name);
        
        log_info($sformatf("Reading register %s @0x%08x", reg_name, address), EVM_MED);
        
        // Execute transaction via agent
        execute_item(item, status);
        
        // Get result
        value = item.data;
        
        // Update mirror if successful
        if (status) begin
            predict(value, 1);  // 1 = read
        end
        
        log_info($sformatf("Read register %s @0x%08x = 0x%08x", 
                          reg_name, address, value), EVM_MED);
    endtask
    
    //==========================================================================
    // Read-Check Task - Read and verify against expected value
    //==========================================================================
    virtual task read_check(bit [63:0] expected, bit [63:0] mask = '1, output bit status);
        bit [63:0] read_value;
        bit [63:0] masked_read, masked_exp;
        
        read(read_value, status);
        
        if (status) begin
            masked_read = read_value & mask;
            masked_exp = expected & mask;
            
            if (masked_read !== masked_exp) begin
                log_error($sformatf("Register %s read check failed: read=0x%08x expected=0x%08x mask=0x%08x",
                                   reg_name, read_value, expected, mask));
                status = 0;
            end else begin
                log_info($sformatf("Register %s read check passed: 0x%08x", 
                                  reg_name, read_value), EVM_MED);
            end
        end
    endtask
    
    //==========================================================================
    // Mirror Read - Read and compare with mirrored value
    //==========================================================================
    virtual task mirror(output bit status);
        bit [63:0] read_value, mirror_value;
        
        mirror_value = get();
        read(read_value, status);
        
        if (status) begin
            if (read_value !== mirror_value) begin
                log_warning($sformatf("Register %s mirror mismatch: read=0x%08x mirror=0x%08x",
                                     reg_name, read_value, mirror_value));
                // Update mirror with actual value
                set(read_value);
            end else begin
                log_info($sformatf("Register %s mirror matches: 0x%08x", 
                                  reg_name, read_value), EVM_DEBUG);
            end
        end
    endtask
    
    //==========================================================================
    // Execute Item - Send transaction to agent (to be overridden if needed)
    //==========================================================================
    protected virtual task execute_item(evm_csr_item item, output bit status);
        // This is a placeholder - in real implementation, this would:
        // 1. Send item to agent's sequencer, or
        // 2. Call agent's driver directly
        // For now, we'll use a simple mechanism
        
        // Example: If agent has a "execute_csr" task, call it
        // Otherwise, user must override this method
        
        log_warning("execute_item not implemented - override in derived class or configure agent");
        status = 1;  // Assume success for now
        
        // Simulation: update item.data for reads
        if (item.is_read()) begin
            item.data = get();  // Return mirrored value
        end
    endtask
    
    //==========================================================================
    // String Conversion
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("%s @0x%08x [%0d-bit] = 0x%0x\n", reg_name, address, n_bits, get());
        foreach (fields[i]) begin
            s = {s, "  ", fields[i].convert2string(), "\n"};
        end
        return s;
    endfunction
    
endclass : evm_reg
