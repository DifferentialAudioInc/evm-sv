//==============================================================================
// EVM - Embedded Verification Methodology
// Functional Coverage Wrapper
// Simplifies working with SystemVerilog covergroups
//==============================================================================

//==============================================================================
// Class: evm_coverage
// Description: Base class for functional coverage collectors
//              Wraps SystemVerilog covergroups with EVM infrastructure
//==============================================================================
virtual class evm_coverage extends evm_component;
    
    // Coverage statistics
    protected real coverage_percent;
    protected bit coverage_enabled;
    protected int sample_count;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_coverage", evm_component parent = null);
        super.new(name, parent);
        coverage_enabled = 1;
        coverage_percent = 0.0;
        sample_count = 0;
    endfunction
    
    //==========================================================================
    // Enable/Disable coverage collection
    //==========================================================================
    virtual function void set_coverage_enable(bit enable);
        coverage_enabled = enable;
        log_info($sformatf("Coverage %s", enable ? "enabled" : "disabled"), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Sample coverage (override in derived class)
    //==========================================================================
    virtual function void sample();
        if (!coverage_enabled) return;
        sample_count++;
    endfunction
    
    //==========================================================================
    // Get coverage percentage (override in derived class)
    //==========================================================================
    virtual function real get_coverage();
        return coverage_percent;
    endfunction
    
    //==========================================================================
    // Report Phase - Print coverage results
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        
        if (!coverage_enabled) begin
            log_info("Coverage collection was disabled", EVM_LOW);
            return;
        end
        
        coverage_percent = get_coverage();
        
        log_info("================================================================================", EVM_LOW);
        log_info($sformatf("Coverage Report: %s", get_name()), EVM_LOW);
        log_info("================================================================================", EVM_LOW);
        log_info($sformatf("  Total Samples:    %0d", sample_count), EVM_LOW);
        log_info($sformatf("  Coverage:         %.2f%%", coverage_percent), EVM_LOW);
        log_info("================================================================================", EVM_LOW);
        
        if (coverage_percent >= 100.0) begin
            log_info("*** FULL COVERAGE ACHIEVED! ***", EVM_LOW);
        end else if (coverage_percent < 80.0) begin
            log_warning($sformatf("Coverage is below 80%% (%.2f%%)", coverage_percent));
        end
    endfunction
    
endclass

//==============================================================================
// Class: evm_coverage_collector
// Description: Transaction-based coverage collector
//              Receives transactions via analysis_imp and samples coverage
// Usage: Create covergroup in derived class, sample in write() method
//==============================================================================
virtual class evm_coverage_collector#(type T = evm_sequence_item) extends evm_coverage;
    
    // Analysis implementation for receiving transactions
    evm_analysis_imp#(T) analysis_imp;
    
    // Transaction queue for processing
    protected mailbox#(T) txn_mailbox;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "coverage_collector", evm_component parent = null);
        super.new(name, parent);
        analysis_imp = new({name, ".analysis_imp"}, 0);  // Unbounded
        txn_mailbox = analysis_imp.get_mailbox();
    endfunction
    
    //==========================================================================
    // Main Phase - Process transactions
    //==========================================================================
    virtual task main_phase();
        T txn;
        super.main_phase();
        
        if (!coverage_enabled) begin
            log_info("Coverage disabled, skipping collection", EVM_MEDIUM);
            return;
        end
        
        log_info("Coverage collector started", EVM_MEDIUM);
        
        fork
            forever begin
                txn_mailbox.get(txn);
                write(txn);
            end
        join_none
    endtask
    
    //==========================================================================
    // Write - Called when transaction received (override in derived class)
    //==========================================================================
    virtual function void write(T txn);
        if (!coverage_enabled) return;
        
        log_info($sformatf("Sampling coverage for: %s", txn.convert2string()), EVM_DEBUG);
        sample();
        // Override and add: my_covergroup.sample();
    endfunction
    
endclass

//==============================================================================
// Example: How to use evm_coverage_collector
//==============================================================================
// class my_coverage extends evm_coverage_collector#(my_txn);
//     
//     covergroup transaction_cg;
//         addr_cp: coverpoint txn.addr {
//             bins low   = {[0:63]};
//             bins mid   = {[64:191]};
//             bins high  = {[192:255]};
//         }
//         data_cp: coverpoint txn.data {
//             bins zero     = {0};
//             bins nonzero  = {[1:$]};
//         }
//         cross addr_cp, data_cp;
//     endgroup
//     
//     function new(string name = "my_coverage", evm_component parent = null);
//         super.new(name, parent);
//         transaction_cg = new();
//     endfunction
//     
//     virtual function void write(my_txn txn);
//         super.write(txn);
//         if (coverage_enabled) begin
//             transaction_cg.sample();
//         end
//     endfunction
//     
//     virtual function real get_coverage();
//         return transaction_cg.get_coverage();
//     endfunction
//     
// endclass
//==============================================================================

//==============================================================================
// Global Coverage Database
// Tracks all coverage instances for reporting
//==============================================================================
class evm_coverage_db;
    
    static local evm_coverage coverage_list[$];
    
    // Register coverage instance
    static function void register(evm_coverage cov);
        coverage_list.push_back(cov);
    endfunction
    
    // Get total coverage across all instances
    static function real get_total_coverage();
        real total = 0.0;
        int count = 0;
        
        foreach (coverage_list[i]) begin
            total += coverage_list[i].get_coverage();
            count++;
        end
        
        if (count > 0) begin
            return total / count;
        end
        
        return 0.0;
    endfunction
    
    // Print summary of all coverage
    static function void print_summary();
        real total_cov;
        
        $display("================================================================================");
        $display("FUNCTIONAL COVERAGE SUMMARY");
        $display("================================================================================");
        
        foreach (coverage_list[i]) begin
            $display("  %-30s: %6.2f%%", 
                     coverage_list[i].get_name(), 
                     coverage_list[i].get_coverage());
        end
        
        total_cov = get_total_coverage();
        $display("--------------------------------------------------------------------------------");
        $display("  %-30s: %6.2f%%", "TOTAL COVERAGE", total_cov);
        $display("================================================================================");
        
        if (total_cov >= 100.0) begin
            $display("*** FULL COVERAGE ACHIEVED! ***");
        end else if (total_cov >= 90.0) begin
            $display("*** GOOD COVERAGE (>90%%) ***");
        end else if (total_cov < 80.0) begin
            $display("WARNING: Coverage is below 80%%");
        end
        
        $display("================================================================================");
    endfunction
    
endclass
