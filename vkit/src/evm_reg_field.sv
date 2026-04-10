//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_reg_field
// Description: Lightweight register field model (similar to UVM RAL)
//              Represents a field within a register with access policies
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

typedef enum {
    EVM_REG_RW,     // Read-Write
    EVM_REG_RO,     // Read-Only
    EVM_REG_WO,     // Write-Only
    EVM_REG_RC,     // Read-Clears
    EVM_REG_RS,     // Read-Sets
    EVM_REG_WC,     // Write-Clears
    EVM_REG_WS,     // Write-Sets
    EVM_REG_W1C,    // Write-1-to-Clear
    EVM_REG_W1S     // Write-1-to-Set
} evm_reg_access_e;

class evm_reg_field extends evm_object;
    
    //==========================================================================
    // Field Properties
    //==========================================================================
    protected string            field_name;
    protected int               lsb_pos;        // LSB position in register
    protected int               size;           // Field width in bits
    protected bit [63:0]        reset_value;    // Reset value
    protected bit [63:0]        current_value;  // Current value
    protected evm_reg_access_e  access_type;    // Access policy
    protected bit               volatile_field; // Can change without write
    
    // Parent register reference
    protected evm_reg           parent_reg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name, int lsb, int size, evm_reg_access_e access = EVM_REG_RW, 
                 bit [63:0] reset = 0, bit is_volatile = 0);
        super.new(name);
        this.field_name = name;
        this.lsb_pos = lsb;
        this.size = size;
        this.access_type = access;
        this.reset_value = reset;
        this.current_value = reset;
        this.volatile_field = is_volatile;
        this.parent_reg = null;
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    function void set_parent(evm_reg parent);
        this.parent_reg = parent;
    endfunction
    
    //==========================================================================
    // Value Access Methods
    //==========================================================================
    
    // Get current value
    virtual function bit [63:0] get();
        return current_value;
    endfunction
    
    // Set current value (mirror only, doesn't generate transaction)
    virtual function void set(bit [63:0] value);
        bit [63:0] mask = (1 << size) - 1;
        current_value = value & mask;
    endfunction
    
    // Get field properties
    function int get_lsb_pos();
        return lsb_pos;
    endfunction
    
    function int get_msb_pos();
        return lsb_pos + size - 1;
    endfunction
    
    function int get_size();
        return size;
    endfunction
    
    function bit [63:0] get_mask();
        return ((64'h1 << size) - 1) << lsb_pos;
    endfunction
    
    function evm_reg_access_e get_access();
        return access_type;
    endfunction
    
    function bit is_volatile();
        return volatile_field;
    endfunction
    
    //==========================================================================
    // Reset Method
    //==========================================================================
    virtual function void reset(string kind = "HARD");
        current_value = reset_value;
        log_info($sformatf("Field %s reset to 0x%0x", field_name, reset_value), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // Check Access Rights
    //==========================================================================
    function bit is_readable();
        return (access_type != EVM_REG_WO);
    endfunction
    
    function bit is_writable();
        return (access_type != EVM_REG_RO);
    endfunction
    
    //==========================================================================
    // Predict - Update mirrored value based on access
    //==========================================================================
    virtual function void predict(bit [63:0] write_value, bit is_read);
        bit [63:0] mask = (1 << size) - 1;
        
        if (is_read) begin
            // Handle read side effects
            case (access_type)
                EVM_REG_RC: current_value = 0;  // Read clears
                EVM_REG_RS: current_value = mask;  // Read sets
                default: ; // No side effect
            endcase
        end else begin
            // Handle write
            case (access_type)
                EVM_REG_RW, EVM_REG_WO: 
                    current_value = write_value & mask;
                EVM_REG_WC: 
                    current_value = 0;  // Write clears
                EVM_REG_WS: 
                    current_value = mask;  // Write sets
                EVM_REG_W1C: 
                    current_value = current_value & ~(write_value & mask);  // Write 1 to clear
                EVM_REG_W1S: 
                    current_value = current_value | (write_value & mask);  // Write 1 to set
                default: ;  // Read-only, no change
            endcase
        end
    endfunction
    
    //==========================================================================
    // String Conversion
    //==========================================================================
    virtual function string convert2string();
        return $sformatf("%s[%0d:%0d]=%0x (%s)", 
                        field_name, get_msb_pos(), lsb_pos, current_value,
                        access_type.name());
    endfunction
    
endclass : evm_reg_field
