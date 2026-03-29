//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_object
// Description: Base object class for Embedded Verification Methodology (EVM)
//              Extends evm_base for logging support
//              Lightweight alternative to uvm_object
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_object extends evm_log;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_object");
        super.new(name);
        log_info($sformatf("Created %s", get_type_name()), EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    
    // Get type name (for identification)
    virtual function string get_type_name();
        return "evm_object";
    endfunction
    
    //==========================================================================
    // Copy/Clone Methods
    // Source: Inspired by uvm_object::copy() and uvm_object::clone()
    // Rationale: Essential for verification to duplicate objects for:
    //            - Reference models (copy expected transactions)
    //            - Scoreboards (save transaction snapshots)
    //            - Debugging (preserve state for analysis)
    // UVM Equivalent: uvm_object::copy(), uvm_object::clone(), do_copy()
    //==========================================================================
    
    // Copy from another object
    virtual function void copy(evm_object rhs);
        if (rhs == null) begin
            log_error("Attempting to copy from null object");
            return;
        end
        if (rhs.get_type_name() != this.get_type_name()) begin
            log_warning($sformatf("Type mismatch in copy: %s != %s",
                                 this.get_type_name(), rhs.get_type_name()));
        end
        do_copy(rhs);
    endfunction
    
    // Clone - create new instance and copy (must override in derived classes)
    virtual function evm_object clone();
        log_fatal("clone() must be overridden in derived class to create proper type");
        return null;
    endfunction
    
    // Override in derived classes to implement field copying
    virtual function void do_copy(evm_object rhs);
        // Base class copies name
        if (rhs != null) begin
            m_name = rhs.get_name();
        end
    endfunction
    
    //==========================================================================
    // Compare Methods
    // Source: Inspired by uvm_object::compare() and do_compare()
    // Rationale: Critical for verification to check correctness:
    //            - Scoreboards need deep object comparison
    //            - Cannot verify without comparing expected vs actual
    //            - Must report mismatches with detailed messages
    // UVM Equivalent: uvm_object::compare(uvm_object rhs, uvm_comparer comparer)
    // EVM Simplification: No comparer policy object, uses output msg instead
    //==========================================================================
    
    // Compare with another object
    virtual function bit compare(evm_object rhs, output string msg);
        msg = "";
        
        if (rhs == null) begin
            msg = "Comparing with null object";
            log_error(msg);
            return 0;
        end
        
        if (rhs.get_type_name() != this.get_type_name()) begin
            msg = $sformatf("Type mismatch: %s != %s",
                           this.get_type_name(), rhs.get_type_name());
            log_error(msg);
            return 0;
        end
        
        return do_compare(rhs, msg);
    endfunction
    
    // Override in derived classes to implement field comparison
    virtual function bit do_compare(evm_object rhs, output string msg);
        // Base implementation always returns 1 (override in derived classes)
        msg = "Base evm_object compare (no fields to compare)";
        return 1;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Convert to string representation
    virtual function string convert2string();
        return $sformatf("%s [%s]", m_name, get_type_name());
    endfunction
    
    // Sprint - return formatted string
    virtual function string sprint();
        return convert2string();
    endfunction
    
    // Print object information
    virtual function void print();
        $display("%s", convert2string());
    endfunction
    
endclass : evm_object
