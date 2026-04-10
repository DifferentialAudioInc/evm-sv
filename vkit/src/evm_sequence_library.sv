//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// File: evm_sequence_library.sv
// Description: Sequence library for EVM - named sequence registry and runner
//
//              Provides a registry of named sequences. Tests register sequences
//              and can run them by name, randomly, or in order.
//
//              Usage:
//
//                // Define sequences
//                class my_write_seq extends evm_sequence; ... endclass
//                class my_read_seq  extends evm_sequence; ... endclass
//
//                // Register at module/package scope
//                `EVM_REGISTER_SEQUENCE(my_write_seq)
//                `EVM_REGISTER_SEQUENCE(my_read_seq)
//
//                // In test:
//                evm_sequence_library lib = new("lib");
//                lib.run_sequence("my_write_seq", my_sqr);
//                lib.run_random(my_sqr);         // pick one at random
//                lib.run_all(my_sqr);            // run all registered
//
//                // Or from command line: +EVM_SEQ=my_write_seq
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

//==============================================================================
// Abstract Sequence Creator Base Class
// Enables creating sequences by name without runtime class lookup
//==============================================================================
virtual class evm_sequence_creator;
    
    pure virtual function evm_sequence create(string name);
    
    virtual function string get_type_name();
        return "evm_sequence_creator";
    endfunction
    
endclass : evm_sequence_creator

//==============================================================================
// Generic Sequence Creator - Parameterized by sequence type
//==============================================================================
class evm_sequence_creator_t #(type T = evm_sequence) extends evm_sequence_creator;
    
    virtual function evm_sequence create(string name);
        T seq = new(name);
        return seq;
    endfunction
    
    virtual function string get_type_name();
        return "evm_sequence_creator_t";
    endfunction
    
endclass : evm_sequence_creator_t

//==============================================================================
// Sequence Library - Static global registry + instance-based runner
//==============================================================================
class evm_sequence_library extends evm_object;
    
    //==========================================================================
    // Static global registry: name → creator
    // Shared across all library instances (registered at elaboration time)
    //==========================================================================
    local static evm_sequence_creator m_global_creators[string];
    
    //==========================================================================
    // Instance-level enabled sequences (subset of global registry)
    // A library instance can restrict which sequences are active
    //==========================================================================
    local string m_enabled[$];
    local bit    m_use_all = 1;  // 1=use all global, 0=use m_enabled only
    
    //==========================================================================
    // Selection mode for run_random()
    //==========================================================================
    typedef enum { SEQ_RANDOM, SEQ_ROUND_ROBIN } evm_seq_select_e;
    evm_seq_select_e selection_mode = SEQ_RANDOM;
    
    local int m_rr_index = 0;  // Round-robin state
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int sequences_run = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_sequence_library");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Static: Register a sequence creator globally
    // Called by the `EVM_REGISTER_SEQUENCE macro at time 0
    //==========================================================================
    static function void register(string name, evm_sequence_creator creator);
        if (m_global_creators.exists(name)) begin
            evm_report_handler::report(EVM_WARNING, "evm_sequence_library",
                $sformatf("Sequence '%s' already registered - overwriting", name));
        end
        m_global_creators[name] = creator;
        evm_report_handler::report(EVM_DEBUG, "evm_sequence_library",
            $sformatf("Registered sequence: '%s'", name));
    endfunction
    
    //==========================================================================
    // Static: Create a sequence by name (returns null if not found)
    //==========================================================================
    static function evm_sequence create_sequence(string name);
        if (!m_global_creators.exists(name)) begin
            evm_report_handler::report(EVM_ERROR, "evm_sequence_library",
                $sformatf("Sequence '%s' not registered", name));
            return null;
        end
        return m_global_creators[name].create(name);
    endfunction
    
    //==========================================================================
    // Static: List all globally registered sequences
    //==========================================================================
    static function void list_all();
        string name;
        evm_report_handler::report(EVM_NONE, "evm_sequence_library",
            "============================================");
        evm_report_handler::report(EVM_NONE, "evm_sequence_library",
            $sformatf("Registered Sequences (%0d):", m_global_creators.size()));
        if (m_global_creators.first(name)) begin
            do begin
                evm_report_handler::report(EVM_NONE, "evm_sequence_library",
                    $sformatf("  %s", name));
            end while (m_global_creators.next(name));
        end else begin
            evm_report_handler::report(EVM_NONE, "evm_sequence_library",
                "  (none registered)");
        end
        evm_report_handler::report(EVM_NONE, "evm_sequence_library",
            "============================================");
    endfunction
    
    //==========================================================================
    // Instance: Enable specific sequences (use subset of global registry)
    //==========================================================================
    function void enable_sequence(string name);
        if (!m_global_creators.exists(name)) begin
            log_error($sformatf("Cannot enable '%s' - not registered", name));
            return;
        end
        m_enabled.push_back(name);
        m_use_all = 0;
        log_info($sformatf("Enabled sequence: '%s'", name), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Instance: Enable all registered sequences (default behavior)
    //==========================================================================
    function void enable_all();
        m_use_all = 1;
        m_enabled.delete();
        log_info("All registered sequences enabled", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Instance: Run a specific sequence by name on the given sequencer
    //==========================================================================
    task run_sequence(string name, evm_sequencer sqr);
        evm_sequence seq;
        
        seq = create_sequence(name);
        if (seq == null) return;
        
        log_info($sformatf("Running sequence: '%s'", name), EVM_LOW);
        sqr.execute_sequence(seq);
        sequences_run++;
    endtask
    
    //==========================================================================
    // Instance: Run a randomly selected sequence
    //==========================================================================
    task run_random(evm_sequencer sqr);
        string names[$];
        string name;
        int idx;
        
        get_active_names(names);
        if (names.size() == 0) begin
            log_error("No sequences available to run");
            return;
        end
        
        case (selection_mode)
            SEQ_RANDOM: begin
                idx = $urandom_range(0, names.size()-1);
                name = names[idx];
            end
            SEQ_ROUND_ROBIN: begin
                name = names[m_rr_index % names.size()];
                m_rr_index++;
            end
        endcase
        
        run_sequence(name, sqr);
    endtask
    
    //==========================================================================
    // Instance: Run all enabled sequences in order
    //==========================================================================
    task run_all(evm_sequencer sqr);
        string names[$];
        get_active_names(names);
        
        log_info($sformatf("Running all %0d sequences", names.size()), EVM_LOW);
        foreach (names[i]) begin
            run_sequence(names[i], sqr);
        end
    endtask
    
    //==========================================================================
    // Instance: Run sequence from +EVM_SEQ=<name> plusarg (or run_random)
    //==========================================================================
    task run_from_plusarg(evm_sequencer sqr);
        string seq_name;
        if ($value$plusargs("EVM_SEQ=%s", seq_name)) begin
            log_info($sformatf("Running sequence from plusarg: '%s'", seq_name), EVM_LOW);
            run_sequence(seq_name, sqr);
        end else begin
            log_info("No +EVM_SEQ plusarg, running random sequence", EVM_MEDIUM);
            run_random(sqr);
        end
    endtask
    
    //==========================================================================
    // Instance: Check if a sequence exists in active set
    //==========================================================================
    function bit sequence_exists(string name);
        if (m_use_all) return m_global_creators.exists(name);
        foreach (m_enabled[i]) begin
            if (m_enabled[i] == name) return 1;
        end
        return 0;
    endfunction
    
    //==========================================================================
    // Instance: Get active sequence names
    //==========================================================================
    local function void get_active_names(ref string names[$]);
        names.delete();
        if (m_use_all) begin
            string name;
            if (m_global_creators.first(name)) begin
                do begin
                    names.push_back(name);
                end while (m_global_creators.next(name));
            end
        end else begin
            names = m_enabled;
        end
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_sequence_library";
    endfunction
    
endclass : evm_sequence_library

//==============================================================================
// Macro: EVM_REGISTER_SEQUENCE
// Usage: Place after your sequence class definition at module/package scope.
//
//   class my_write_seq extends evm_sequence;
//     ...
//   endclass
//   `EVM_REGISTER_SEQUENCE(my_write_seq)
//
//==============================================================================
`define EVM_REGISTER_SEQUENCE(SNAME) \
    evm_sequence_creator_t#(SNAME) SNAME``_evm_seq_creator; \
    initial begin \
        SNAME``_evm_seq_creator = new(); \
        evm_sequence_library::register(`"SNAME`", SNAME``_evm_seq_creator); \
    end
