//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_scoreboard
// Description: Scoreboard for comparing expected vs actual transactions
//              Supports FIFO and associative matching
// Author: Engineering Team
// Date: 2026-03-07
//==============================================================================

typedef enum {
    EVM_SB_FIFO,         // Strict FIFO order matching
    EVM_SB_ASSOCIATIVE,  // Match by key (out of order OK)
    EVM_SB_UNORDERED     // Match any expected with any actual
} evm_scoreboard_mode_e;

class evm_scoreboard #(type T = int) extends evm_component;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_scoreboard_mode_e mode = EVM_SB_FIFO;
    bit enable_auto_check = 1;           // Auto-compare on insert
    bit stop_on_mismatch = 0;            // Stop sim on first mismatch
    int max_expected_queue_size = 1000;  // Max entries before warning
    
    //==========================================================================
    // Storage Queues
    //==========================================================================
    T expected_queue[$];                 // Expected transactions
    T actual_queue[$];                   // Actual transactions (for deferred check)
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int match_count = 0;
    int mismatch_count = 0;
    int expected_count = 0;
    int actual_count = 0;
    int orphan_expected = 0;             // Expected with no actual
    int orphan_actual = 0;               // Actual with no expected
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_scoreboard", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Insert Expected Transaction
    //==========================================================================
    function void insert_expected(T item);
        expected_queue.push_back(item);
        expected_count++;
        
        if (expected_queue.size() > max_expected_queue_size) begin
            log_warning($sformatf("Expected queue size exceeded %0d entries", 
                                 max_expected_queue_size));
        end
        
        log_info($sformatf("Expected transaction inserted (queue size: %0d)", 
                          expected_queue.size()), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Insert Actual Transaction (with auto-check)
    //==========================================================================
    function void insert_actual(T item);
        actual_count++;
        
        if (enable_auto_check) begin
            check_transaction(item);
        end else begin
            actual_queue.push_back(item);
        end
    endfunction
    
    //==========================================================================
    // Check Transaction
    //==========================================================================
    function bit check_transaction(T actual);
        T expected;
        bit match = 0;
        
        if (expected_queue.size() == 0) begin
            log_error("No expected transaction available for comparison");
            orphan_actual++;
            if (stop_on_mismatch) $stop;
            return 0;
        end
        
        case (mode)
            EVM_SB_FIFO: begin
                expected = expected_queue.pop_front();
                match = compare_transactions(expected, actual);
            end
            
            EVM_SB_ASSOCIATIVE: begin
                // Find matching expected by key (user must override compare)
                int idx = find_matching_expected(actual);
                if (idx >= 0) begin
                    expected = expected_queue[idx];
                    expected_queue.delete(idx);
                    match = compare_transactions(expected, actual);
                end else begin
                    log_error("No matching expected transaction found");
                    orphan_actual++;
                    return 0;
                end
            end
            
            EVM_SB_UNORDERED: begin
                // Try to match with any expected
                int idx = find_exact_match(actual);
                if (idx >= 0) begin
                    expected = expected_queue[idx];
                    expected_queue.delete(idx);
                    match = 1;
                    match_count++;
                end else begin
                    log_error("No matching expected transaction found");
                    orphan_actual++;
                    mismatch_count++;
                    return 0;
                end
            end
        endcase
        
        return match;
    endfunction
    
    //==========================================================================
    // Compare Transactions (Virtual - override for custom comparison)
    //==========================================================================
    virtual function bit compare_transactions(T expected, T actual);
        // Default comparison (bitwise)
        if (expected == actual) begin
            match_count++;
            log_info($sformatf("Transaction MATCH (%0d matches)", match_count), EVM_MED);
            return 1;
        end else begin
            mismatch_count++;
            log_error($sformatf("Transaction MISMATCH (%0d mismatches)", mismatch_count));
            log_error($sformatf("Expected: %p", expected));
            log_error($sformatf("Actual:   %p", actual));
            if (stop_on_mismatch) $stop;
            return 0;
        end
    endfunction
    
    //==========================================================================
    // Find Matching Expected (Virtual - override for custom key matching)
    //==========================================================================
    virtual function int find_matching_expected(T actual);
        // Default: return first (FIFO behavior)
        return (expected_queue.size() > 0) ? 0 : -1;
    endfunction
    
    //==========================================================================
    // Find Exact Match
    //==========================================================================
    function int find_exact_match(T actual);
        foreach (expected_queue[i]) begin
            if (expected_queue[i] == actual) begin
                return i;
            end
        end
        return -1;
    endfunction
    
    //==========================================================================
    // Check All Remaining
    //==========================================================================
    function void check_all();
        int checked = 0;
        
        while (expected_queue.size() > 0 && actual_queue.size() > 0) begin
            T actual = actual_queue.pop_front();
            check_transaction(actual);
            checked++;
        end
        
        log_info($sformatf("Checked %0d transactions", checked), EVM_MED);
    endfunction
    
    //==========================================================================
    // Reset Methods - Clear State on Reset
    //==========================================================================
    
    // Pre-reset: Save any needed state before clearing
    virtual task pre_reset();
        super.pre_reset();
        log_info("Scoreboard pre-reset: preparing for reset", EVM_HIGH);
        // Could save state here if needed for analysis
    endtask
    
    // Reset: Clear all queues and state
    virtual task reset();
        super.reset();
        log_info("Scoreboard reset: clearing all queues and statistics", EVM_MEDIUM);
        
        // Clear all queues
        expected_queue.delete();
        actual_queue.delete();
        
        // Reset statistics
        match_count = 0;
        mismatch_count = 0;
        expected_count = 0;
        actual_count = 0;
        orphan_expected = 0;
        orphan_actual = 0;
    endtask
    
    // Post-reset: Reinitialize after reset
    virtual task post_reset();
        super.post_reset();
        log_info("Scoreboard post-reset: ready for operation", EVM_HIGH);
        // Queues are empty and ready for new data
    endtask
    
    //==========================================================================
    // Final Phase - Report Results
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        // Check for orphans
        orphan_expected = expected_queue.size();
        orphan_actual += actual_queue.size();
        
        print_report();
        
        if (mismatch_count > 0 || orphan_expected > 0 || orphan_actual > 0) begin
            log_error("Scoreboard FAILED - mismatches or orphans detected");
        end else begin
            log_info("Scoreboard PASSED - all transactions matched", EVM_HIGH);
        end
    endfunction
    
    //==========================================================================
    // Print Report
    //==========================================================================
    function void print_report();
        log_info("===============================================", EVM_HIGH);
        log_info("          SCOREBOARD REPORT", EVM_HIGH);
        log_info("===============================================", EVM_HIGH);
        log_info($sformatf("Mode:              %s", mode.name()), EVM_HIGH);
        log_info($sformatf("Expected Count:    %0d", expected_count), EVM_HIGH);
        log_info($sformatf("Actual Count:      %0d", actual_count), EVM_HIGH);
        log_info($sformatf("Matches:           %0d", match_count), EVM_HIGH);
        log_info($sformatf("Mismatches:        %0d", mismatch_count), EVM_HIGH);
        log_info($sformatf("Orphan Expected:   %0d", orphan_expected), EVM_HIGH);
        log_info($sformatf("Orphan Actual:     %0d", orphan_actual), EVM_HIGH);
        
        if (expected_queue.size() > 0) begin
            log_warning($sformatf("%0d expected transactions never matched", 
                                 expected_queue.size()));
        end
        
        if (actual_queue.size() > 0) begin
            log_warning($sformatf("%0d actual transactions never checked", 
                                 actual_queue.size()));
        end
        
        // Calculate pass percentage
        if ((expected_count > 0) || (actual_count > 0)) begin
            real pass_pct = (match_count * 100.0) / expected_count;
            log_info($sformatf("Pass Rate:         %.1f%%", pass_pct), EVM_HIGH);
        end
        
        log_info("===============================================", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function void clear();
        expected_queue.delete();
        actual_queue.delete();
        match_count = 0;
        mismatch_count = 0;
        expected_count = 0;
        actual_count = 0;
        orphan_expected = 0;
        orphan_actual = 0;
    endfunction
    
    function int get_expected_size();
        return expected_queue.size();
    endfunction
    
    function int get_actual_size();
        return actual_queue.size();
    endfunction
    
endclass : evm_scoreboard
