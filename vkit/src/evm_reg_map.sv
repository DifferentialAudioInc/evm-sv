//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_reg_map
// Description: Address map - maps register blocks to bus address spaces
//              Allows multiple register blocks to share a single bus interface.
//              Provides unified register lookup by absolute bus address.
//
//              Usage:
//                // Create register blocks from CSR generator output
//                my_ctrl_reg_model  ctrl_regs  = new("ctrl_regs",  32'h0000_0000);
//                my_status_reg_model status_regs = new("status_regs", 32'h0000_1000);
//
//                // Create address map and add blocks
//                evm_reg_map reg_map = new("reg_map");
//                reg_map.add_reg_block("ctrl",   ctrl_regs,   32'h0000_0000);
//                reg_map.add_reg_block("status", status_regs, 32'h0000_1000);
//
//                // Set the agent used for bus access
//                reg_map.set_agent(axi_lite_agent);
//
//                // Lookup registers by absolute address (used by predictor)
//                evm_reg r = reg_map.get_reg_by_address(32'h0000_0004);
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

class evm_reg_map extends evm_object;
    
    //==========================================================================
    // Internal structure to hold block + its base offset in this map
    //==========================================================================
    typedef struct {
        string          name;
        evm_reg_block   block;
        bit [63:0]      offset;  // Offset of this block within the map
    } evm_reg_block_entry_s;
    
    //==========================================================================
    // Properties
    //==========================================================================
    local evm_reg_block_entry_s m_blocks[$];   // Ordered list of block entries
    local evm_component         m_agent;       // Default agent for all blocks
    local bit [63:0]            m_base_addr;   // Base address of this map
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_reg_map", bit [63:0] base_addr = 0);
        super.new(name);
        m_base_addr = base_addr;
        m_agent = null;
    endfunction
    
    //==========================================================================
    // Add a register block at the given offset within this map
    // The block's absolute address = map.base_addr + offset + reg.offset
    //==========================================================================
    function void add_reg_block(string name, evm_reg_block blk, bit [63:0] offset = 0);
        evm_reg_block_entry_s entry;
        
        if (blk == null) begin
            log_error($sformatf("Cannot add null register block '%s'", name));
            return;
        end
        
        entry.name   = name;
        entry.block  = blk;
        entry.offset = offset;
        m_blocks.push_back(entry);
        
        // Apply agent if already configured
        if (m_agent != null) begin
            blk.set_agent(m_agent);
        end
        
        log_info($sformatf("Added register block '%s' at offset 0x%08x", 
                          name, offset), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Set the agent for all blocks in this map
    // Propagates to all currently added blocks, and to future blocks added later
    //==========================================================================
    function void set_agent(evm_component agent);
        m_agent = agent;
        foreach (m_blocks[i]) begin
            m_blocks[i].block.set_agent(agent);
        end
        log_info($sformatf("Set agent for all %0d blocks in map '%s'", 
                          m_blocks.size(), get_name()), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Get the default agent
    //==========================================================================
    function evm_component get_agent();
        return m_agent;
    endfunction
    
    //==========================================================================
    // Get map base address
    //==========================================================================
    function bit [63:0] get_base_address();
        return m_base_addr;
    endfunction
    
    //==========================================================================
    // Get number of blocks
    //==========================================================================
    function int get_block_count();
        return m_blocks.size();
    endfunction
    
    //==========================================================================
    // Get a register block by name
    //==========================================================================
    function evm_reg_block get_block(string name);
        foreach (m_blocks[i]) begin
            if (m_blocks[i].name == name) begin
                return m_blocks[i].block;
            end
        end
        log_warning($sformatf("Block '%s' not found in map '%s'", name, get_name()));
        return null;
    endfunction
    
    //==========================================================================
    // Lookup a register by absolute bus address
    // Absolute address = map.base_addr + block.offset + reg.offset_within_block
    // Returns null if no register found at that address
    //==========================================================================
    function evm_reg get_reg_by_address(bit [63:0] abs_addr);
        evm_reg found;
        bit [63:0] block_relative_addr;
        
        foreach (m_blocks[i]) begin
            // Compute address relative to this block's base
            // Block base in bus space = map.base + block.offset + block.get_base_address()
            bit [63:0] block_bus_base = m_base_addr + m_blocks[i].offset 
                                       + m_blocks[i].block.get_base_address();
            
            // Check if abs_addr falls within this block's range
            // We search by subtracting the bus base and looking for a matching register
            if (abs_addr >= block_bus_base) begin
                block_relative_addr = abs_addr - block_bus_base;
                found = m_blocks[i].block.get_reg_by_address(block_relative_addr);
                if (found != null) begin
                    return found;
                end
            end
        end
        
        log_info($sformatf("No register found at address 0x%08x in map '%s'", 
                          abs_addr, get_name()), EVM_DEBUG);
        return null;
    endfunction
    
    //==========================================================================
    // Lookup a register by name (searches all blocks)
    //==========================================================================
    function evm_reg get_reg_by_name(string reg_name);
        evm_reg found;
        foreach (m_blocks[i]) begin
            found = m_blocks[i].block.get_reg_by_name(reg_name);
            if (found != null) return found;
        end
        log_warning($sformatf("Register '%s' not found in any block in map '%s'", 
                             reg_name, get_name()));
        return null;
    endfunction
    
    //==========================================================================
    // Reset all blocks in this map
    //==========================================================================
    function void reset(string kind = "HARD");
        foreach (m_blocks[i]) begin
            m_blocks[i].block.reset(kind);
        end
        log_info($sformatf("Map '%s' reset (%s) - %0d blocks", 
                          get_name(), kind, m_blocks.size()), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Dump all blocks and registers
    //==========================================================================
    function void dump();
        log_info($sformatf("=== Register Map: %s (base=0x%08x) ===", 
                          get_name(), m_base_addr), EVM_NONE);
        foreach (m_blocks[i]) begin
            log_info($sformatf("  Block: %s @offset=0x%08x", 
                              m_blocks[i].name, m_blocks[i].offset), EVM_NONE);
            m_blocks[i].block.dump();
        end
    endfunction
    
    //==========================================================================
    // String Conversion
    //==========================================================================
    virtual function string convert2string();
        return $sformatf("evm_reg_map '%s' @0x%08x (%0d blocks)", 
                        get_name(), m_base_addr, m_blocks.size());
    endfunction
    
endclass : evm_reg_map
