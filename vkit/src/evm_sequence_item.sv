//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_sequence_item
// Description: Generic base class for all transaction items
//              Provides timing, status tracking, and CRV helpers.
//              Derived classes add protocol-specific fields and rand constraints.
// Author: Eric Dyer
// Date: 2026-03-06
// Updated: 2026-04-24 - P0.1: added randomize_item() CRV helper
//
// API — Public Interface:
//   [evm_sequence_item] — virtual base class for all EVM transactions
//   new(name)                  — constructor
//   get_duration()             — elapsed time in ns (end_time - start_time)
//   mark_started()             — records start_time = $realtime
//   mark_completed()           — records end_time, sets completed=1
//   randomize_item()           — calls randomize(); logs failure as error [P0.1]
//   convert2string()  [pure]   — must be implemented by derived classes
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
    // CRV Helper (P0.1)
    //==========================================================================
    
    // Randomize this transaction using the SV constraint solver.
    // Calls this.randomize() — honors all rand fields and constraint blocks
    // declared in the derived class.
    //
    // Returns: 1 on success, 0 on failure (over-constrained or impossible)
    // On failure: logs an EVM_ERROR so the test is marked FAILED.
    // On success: logs at EVM_DEBUG verbosity.
    //
    // Usage in a sequence execute() task:
    //   my_txn txn = new("txn");
    //   if (!txn.randomize_item()) return;  // auto-failure on bad constraints
    //   add_item(txn);
    //
    // For inline constraint override (SV syntax — no EVM wrapper needed):
    //   if (!txn.randomize() with { txn.addr < 32'h100; }) ...
    virtual function bit randomize_item();
        bit ok;
        ok = this.randomize();
        if (!ok) begin
            log_error($sformatf("[CRV] randomize() FAILED on %s — constraints may be unsatisfiable",
                                get_type_name()));
            return 0;
        end
        log_info($sformatf("[CRV] %s randomized OK", get_type_name()), EVM_DEBUG);
        return 1;
    endfunction
    
    //==========================================================================
    // Virtual Methods (to be implemented by derived classes)
    //==========================================================================
    
    // Convert to string - must be implemented by derived classes
    pure virtual function string convert2string();
    
endclass : evm_sequence_item
