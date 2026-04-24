//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_rand_sequence.sv
// Description: Base class for constrained-random sequences.
//              Extends evm_sequence with seed logging and CRV conventions.
//              Derived classes declare transaction items with rand fields
//              and call randomize_item() in execute().
// Author: EVM Contributors
// Date: 2026-04-24
// Tag: P0.1 — Constrained Random Verification
//
// API — Public Interface:
//   [evm_rand_sequence] — virtual base class for CRV sequences
//   new(name)           — constructor
//   execute()           — override: logs seed, then calls body()
//   body()              — override THIS in derived class (stimulus goes here)
//   log_crv_seed()      — print seed to log (LOW verbosity); call manually if
//                         you override execute() directly instead of body()
//   get_type_name()
//
// CRV Pattern (recommended — extend evm_rand_sequence, override body()):
//   class my_seq extends evm_rand_sequence;
//     virtual task body();
//       my_txn txn;
//       repeat (20) begin
//         txn = new("txn");
//         if (!txn.randomize_item()) return;   // error + FAIL on bad constraints
//         add_item(txn);
//       end
//     endtask
//   endclass
//
// Alternative (extend evm_rand_sequence, override execute(), call super first):
//   class my_seq extends evm_rand_sequence;
//     virtual task execute();
//       super.execute();   // ← logs seed (REQUIRED for replay info in logs)
//       // ... then build and send items ...
//     endtask
//   endclass
//
// Seed management:
//   The seed logged by log_crv_seed() is read from +evm_seed plusarg.
//   If +evm_seed is not provided, a random seed is auto-generated.
//   Call evm_cmdline::set_random_seed() from tb_top or build_phase to apply it.
//   To replay a failed run: +evm_seed=<N from log>
//==============================================================================

virtual class evm_rand_sequence extends evm_sequence;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_rand_sequence");
        super.new(name);
    endfunction
    
    //==========================================================================
    // execute() — logs the active seed then calls body()
    //
    // ALWAYS call super.execute() first if you override execute() directly.
    // This ensures the seed appears in the log for every random sequence run.
    //
    // Preferred pattern: override body() instead of execute().
    //==========================================================================
    virtual task execute();
        log_crv_seed();
        body();
    endtask
    
    //==========================================================================
    // body() — override this in derived classes
    //
    // This is the recommended override point for CRV sequences.
    // Build items here using new() + randomize_item() + add_item().
    //==========================================================================
    virtual task body();
        // Default: empty. Derived classes override this.
    endtask
    
    //==========================================================================
    // log_crv_seed() — log active seed for run reproduction [P0.1]
    //
    // Reads the configured seed from evm_cmdline and logs it at EVM_LOW
    // verbosity so it always appears in normal-verbosity runs.
    //
    // Output format:
    //   [CRV] Sequence 'my_seq' running — replay: +evm_seed=12345
    //==========================================================================
    virtual function void log_crv_seed();
        int seed;
        seed = evm_cmdline::get_seed();
        log_info($sformatf("[CRV] Sequence '%s' running — to replay: +evm_seed=%0d",
                           get_name(), seed), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_rand_sequence";
    endfunction
    
endclass : evm_rand_sequence
