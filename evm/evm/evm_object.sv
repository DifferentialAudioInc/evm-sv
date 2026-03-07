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
    // Utility Methods
    //==========================================================================
    
    // Convert to string representation
    virtual function string convert2string();
        return $sformatf("%s [%s]", m_name, get_type_name());
    endfunction
    
    // Print object information
    virtual function void print();
        $display("%s", convert2string());
    endfunction
    
endclass : evm_object
