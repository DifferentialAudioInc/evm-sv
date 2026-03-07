//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_sequence
// Description: Base sequence class - container for sequence items
//              Executes items through sequencer
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

virtual class evm_sequence extends evm_object;
    
    //==========================================================================
    // Properties
    //==========================================================================
    evm_sequence_item items[$];
    int item_count;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_sequence");
        super.new(name);
        item_count = 0;
    endfunction
    
    //==========================================================================
    // Item Management
    //==========================================================================
    virtual function void add_item(evm_sequence_item item);
        items.push_back(item);
        item_count++;
    endfunction
    
    virtual function void clear_items();
        items.delete();
        item_count = 0;
    endfunction
    
    virtual function int get_item_count();
        return items.size();
    endfunction
    
    //==========================================================================
    // Sequence Execution (to be implemented by derived classes or agents)
    //==========================================================================
    virtual task execute();
        log_info($sformatf("Executing sequence '%s' with %0d items", get_name(), items.size()), EVM_MED);
    endtask
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("Sequence '%s': %0d items", get_name(), items.size());
        return s;
    endfunction
    
endclass : evm_sequence
