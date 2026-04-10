//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_sequence_item
// Description: Generic base class for all transaction items
//              Provides only timing and status tracking
//              Derived classes add protocol-specific fields
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

virtual class evm_sequence_item extends evm_object;
    
    //==========================================================================
    // Generic Transaction Metadata (common to all protocols)
    //==========================================================================
    time   start_time;      // Transaction start time
    time   end_time;        // Transaction end time
    bit    completed;       // Transaction completion status
    int    transaction_id;  // Unique ID for tracking
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_sequence_item");
        super.new(name);
        completed = 0;
        start_time = 0;
        end_time = 0;
        transaction_id = 0;
    endfunction
    
    //==========================================================================
    // Timing Utilities
    //==========================================================================
    virtual function real get_duration();
        if (end_time > start_time) begin
            return real'(end_time - start_time) / 1ns;
        end
        return 0.0;
    endfunction
    
    virtual function void mark_started();
        start_time = $realtime;
    endfunction
    
    virtual function void mark_completed();
        end_time = $realtime;
        completed = 1;
    endfunction
    
    //==========================================================================
    // Virtual Methods (to be implemented by derived classes)
    //==========================================================================
    
    // Convert to string - must be implemented by derived classes
    pure virtual function string convert2string();
    
endclass : evm_sequence_item
