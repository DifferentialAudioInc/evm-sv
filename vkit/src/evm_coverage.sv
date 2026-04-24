//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_coverage.sv
// Description: Functional coverage infrastructure for EVM.
//              Provides a base class for SV covergroups, a global registration
//              database, per-run CSV log export, and PASS/FAIL threshold checking.
// Author: EVM Contributors
// Date: 2026-03-06
// Updated: 2026-04-24 - P0.2: added coverage_target, set_target(), write_log(),
//          evm_coverage_db::check_all_targets(), evm_coverage_db::write_log(),
//          improved reporting with PASS/FAIL per threshold
//
// API — Public Interface:
//
//   [evm_coverage] — virtual base class for all coverage models
//   new(name, parent)          — constructor; call evm_coverage_db::register(this)
//   sample()                   — override: call cg.sample() inside
//   get_coverage()             — override: return cg.get_inst_coverage()
//   set_target(real pct)       — minimum coverage % required for PASS (0 = no check)
//   get_target()               — return coverage_target
//   set_coverage_enable(bit)   — enable/disable sampling
//   report_phase()             — prints coverage% + PASS/FAIL vs target
//
//   [evm_coverage_collector#(T)] — virtual base; receives txn via analysis_imp
//   new(name, parent)          — constructor; creates analysis_imp
//   analysis_imp               — connect monitor.ap.connect(cov.analysis_imp.get_mailbox())
//   write(T txn)               — override: set covergroup sample inputs, call sample()
//   main_phase()               — starts background thread that calls write() on each txn
//
//   [evm_coverage_db] — global registry (static singleton)
//   register(cov)              — add an evm_coverage instance to the registry
//   get_total_coverage()       — average coverage across all registered models
//   check_all_targets()        — return 0 if any model is below its target (→ FAIL)
//   print_summary()            — display coverage table with targets and PASS/FAIL
//   write_log(testname, file)  — write per-run CSV to file for evm_cov_merge.py
//
// Per-Run Log Format (for evm_cov_merge.py):
//   # EVM Coverage Log
//   # testname,model_name,coverage_pct,target_pct,status
//   basic_write_test,env.monitor.axi_cov,87.50,90.00,BELOW_TARGET
//
// Registration pattern (in env or test build_phase):
//   cov_model = new("axi_cov", this);
//   evm_coverage_db::register(cov_model);
//
// Threshold pattern (in coverage model constructor):
//   set_target(90.0);  // this test fails if this model < 90%
//==============================================================================

//==============================================================================
// Class: evm_coverage  [P0.2]
// Description: Virtual base class for functional coverage models.
//              Extend this class, declare a covergroup in the constructor,
//              and override sample() and get_coverage().
//==============================================================================
virtual class evm_coverage extends evm_component;
    
    //==========================================================================
    // Coverage Configuration
    //==========================================================================
    protected real coverage_percent;   // cached from last get_coverage() call
    protected bit  coverage_enabled;   // enable/disable sampling
    protected int  sample_count;       // number of times sample() was called
    real           coverage_target;    // [P0.2] minimum % for PASS (0 = no check)
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_coverage", evm_component parent = null);
        super.new(name, parent);
        coverage_enabled = 1;
        coverage_percent = 0.0;
        sample_count     = 0;
        coverage_target  = 0.0;  // no threshold by default
    endfunction
    
    //==========================================================================
    // Enable/Disable coverage collection
    //==========================================================================
    virtual function void set_coverage_enable(bit enable);
        coverage_enabled = enable;
        log_info($sformatf("Coverage %s", enable ? "enabled" : "disabled"), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // set_target / get_target [P0.2]
    // Set the minimum coverage percentage required for this model to PASS.
    // 0.0 = no threshold (always passes regardless of coverage).
    //==========================================================================
    function void set_target(real pct);
        coverage_target = pct;
    endfunction
    
    function real get_target();
        return coverage_target;
    endfunction
    
    //==========================================================================
    // sample() — override in derived class
    // Call your covergroup.sample() here.
    // Base class increments sample_count and checks enabled flag.
    //==========================================================================
    virtual function void sample();
        if (!coverage_enabled) return;
        sample_count++;
        // Derived class calls: my_cg.sample();
    endfunction
    
    //==========================================================================
    // get_coverage() — override in derived class
    // Return cg.get_inst_coverage() or a composite of multiple covergroups.
    // Returns 0.0–100.0 (percentage of coverage bins hit).
    //==========================================================================
    virtual function real get_coverage();
        return coverage_percent;
        // Derived class returns: return my_cg.get_inst_coverage();
    endfunction
    
    //==========================================================================
    // report_phase [P0.2] — prints coverage + PASS/FAIL vs target
    //==========================================================================
    virtual function void report_phase();
        string status_str;
        real   pct;
        super.report_phase();
        
        if (!coverage_enabled) begin
            log_info($sformatf("[COV] %s: disabled", get_full_name()), EVM_LOW);
            return;
        end
        
        pct = get_coverage();
        coverage_percent = pct;
        
        if (coverage_target > 0.0) begin
            if (pct >= coverage_target)
                status_str = "PASS";
            else
                status_str = $sformatf("BELOW TARGET (%.1f%%)", coverage_target);
        end else begin
            status_str = "OK (no target)";
        end
        
        log_info($sformatf("[COV] %-40s %.1f%%  %s  (samples: %0d)",
                           get_full_name(), pct, status_str, sample_count), EVM_LOW);
        
        // Log error if below target so test FAILS
        if (coverage_target > 0.0 && pct < coverage_target) begin
            log_error($sformatf("[COV] %s coverage %.1f%% is below target %.1f%%",
                                get_full_name(), pct, coverage_target));
        end
    endfunction
    
endclass : evm_coverage


//==============================================================================
// Class: evm_coverage_collector#(T)
// Description: Coverage model that receives transactions via an analysis_imp.
//              Extend this, declare covergroups, override write() to sample.
//
// Connection pattern (in env connect_phase):
//   agent.analysis_port.connect(cov.analysis_imp.get_mailbox());
//==============================================================================
virtual class evm_coverage_collector#(type T = evm_sequence_item) extends evm_coverage;
    
    // Analysis implementation for receiving transactions
    evm_analysis_imp#(T) analysis_imp;
    
    // Transaction mailbox (from analysis_imp)
    protected mailbox#(T) txn_mailbox;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "coverage_collector", evm_component parent = null);
        super.new(name, parent);
        analysis_imp = new({name, ".analysis_imp"}, 0);  // unbounded
        txn_mailbox  = analysis_imp.get_mailbox();
    endfunction
    
    //==========================================================================
    // main_phase — background thread: calls write() on each received transaction
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
    // write() — override in derived class
    // Set your covergroup sample inputs from txn, then call sample() / cg.sample().
    //==========================================================================
    virtual function void write(T txn);
        if (!coverage_enabled) return;
        log_info($sformatf("Sampling coverage for: %s", txn.convert2string()), EVM_DEBUG);
        sample();
        // Derived class: my_cg.sample() after updating covergroup inputs
    endfunction
    
endclass : evm_coverage_collector


//==============================================================================
// Class: evm_coverage_db  [P0.2]
// Description: Global registry of all evm_coverage instances.
//              Provides aggregate reporting, threshold checking, and CSV log export.
//
// Usage:
//   // In build_phase:
//   cov_model = new("axi_cov", this);
//   evm_coverage_db::register(cov_model);   // ← required registration
//
//   // In report_phase (or call from evm_base_test automatically):
//   evm_coverage_db::print_summary();
//   if (!evm_coverage_db::check_all_targets())
//       evm_report_handler::evm_report_error("COV", "Coverage target(s) not met");
//
//   // For regression CSV output (after each run):
//   evm_coverage_db::write_log("basic_write_test", "evm_cov_basic_write.csv");
//==============================================================================
class evm_coverage_db;
    
    static local evm_coverage coverage_list[$];
    
    //==========================================================================
    // register() — add a coverage model to the global list
    //==========================================================================
    static function void register(evm_coverage cov);
        if (cov != null)
            coverage_list.push_back(cov);
    endfunction
    
    //==========================================================================
    // get_total_coverage() — average coverage across all registered models
    //==========================================================================
    static function real get_total_coverage();
        real total;
        int  count;
        int  i;
        total = 0.0;
        count = 0;
        for (i = 0; i < coverage_list.size(); i++) begin
            total += coverage_list[i].get_coverage();
            count++;
        end
        if (count > 0)
            return total / real'(count);
        return 0.0;
    endfunction
    
    //==========================================================================
    // check_all_targets() [P0.2]
    // Returns 1 if ALL registered models meet their targets, 0 if any fail.
    // Models with target=0 are ignored (always pass).
    //==========================================================================
    static function bit check_all_targets();
        int  i;
        real pct;
        for (i = 0; i < coverage_list.size(); i++) begin
            if (coverage_list[i].get_target() > 0.0) begin
                pct = coverage_list[i].get_coverage();
                if (pct < coverage_list[i].get_target())
                    return 0;
            end
        end
        return 1;
    endfunction
    
    //==========================================================================
    // print_summary() [P0.2 enhanced]
    // Displays a formatted table with coverage%, target, PASS/FAIL per model.
    //==========================================================================
    static function void print_summary();
        real   total_cov;
        int    i;
        string status_str;
        real   pct;
        real   tgt;
        
        if (coverage_list.size() == 0) return;
        
        $display("");
        $display("==============================================================================");
        $display("                    EVM FUNCTIONAL COVERAGE SUMMARY");
        $display("==============================================================================");
        $display("  %-40s  %7s  %7s  %s", "Model", "Coverage", "Target", "Status");
        $display("  %s", {78{"-"}});
        
        for (i = 0; i < coverage_list.size(); i++) begin
            pct = coverage_list[i].get_coverage();
            tgt = coverage_list[i].get_target();
            if (tgt > 0.0) begin
                if (pct >= tgt)
                    status_str = "PASS";
                else
                    status_str = "FAIL";
            end else begin
                status_str = "---";
            end
            if (tgt > 0.0)
                $display("  %-40s  %6.1f%%  %6.1f%%  %s",
                         coverage_list[i].get_full_name(), pct, tgt, status_str);
            else
                $display("  %-40s  %6.1f%%    (none)  %s",
                         coverage_list[i].get_full_name(), pct, status_str);
        end
        
        total_cov = get_total_coverage();
        $display("  %s", {78{"-"}});
        $display("  %-40s  %6.1f%%", "OVERALL (average)", total_cov);
        $display("==============================================================================");
        
        if (check_all_targets()) begin
            if (total_cov >= 100.0)
                $display("  [COV] *** FULL COVERAGE ACHIEVED ***");
            else
                $display("  [COV] *** ALL COVERAGE TARGETS MET ***");
        end else begin
            $display("  [COV] *** ONE OR MORE COVERAGE TARGETS NOT MET ***");
        end
        $display("==============================================================================");
        $display("");
    endfunction
    
    //==========================================================================
    // write_log() [P0.2] — export per-run coverage data to a CSV file
    //
    // Output format (parseable by evm_cov_merge.py):
    //   # EVM Coverage Log
    //   # testname,model_name,coverage_pct,target_pct,status
    //   basic_write,env.monitor.cov,87.50,90.00,BELOW_TARGET
    //
    // Call from evm_base_test.report_phase() when +evm_cov_log=<file> is set.
    //==========================================================================
    static function void write_log(string testname, string filename);
        int    fh;
        int    i;
        real   pct;
        real   tgt;
        string status_str;
        
        fh = $fopen(filename, "w");
        if (fh == 0) begin
            $display("[EVM COV] ERROR: Cannot open coverage log file: %s", filename);
            return;
        end
        
        $fdisplay(fh, "# EVM Coverage Log — generated by evm_coverage_db::write_log()");
        $fdisplay(fh, "# Merge multiple runs: python evm_cov_merge.py *.evm_cov");
        $fdisplay(fh, "# testname,model_name,coverage_pct,target_pct,status");
        
        for (i = 0; i < coverage_list.size(); i++) begin
            pct = coverage_list[i].get_coverage();
            tgt = coverage_list[i].get_target();
            if (tgt > 0.0)
                status_str = (pct >= tgt) ? "PASS" : "BELOW_TARGET";
            else
                status_str = "NO_TARGET";
            $fdisplay(fh, "%s,%s,%.2f,%.2f,%s",
                      testname,
                      coverage_list[i].get_full_name(),
                      pct, tgt, status_str);
        end
        
        $fclose(fh);
        $display("[EVM COV] Coverage log written: %s (%0d model(s))",
                 filename, coverage_list.size());
    endfunction
    
endclass : evm_coverage_db


//==============================================================================
// Example: How to use evm_coverage / evm_coverage_collector
//
// class my_axi_cov extends evm_coverage;
//     evm_axi_lite_write_txn last_txn;   // set before calling sample()
//
//     covergroup axi_write_cg;
//         addr_cp: coverpoint last_txn.addr[15:12] {
//             bins low  = {[0:3]};
//             bins mid  = {[4:11]};
//             bins high = {[12:15]};
//         }
//         strb_cp: coverpoint last_txn.strb {
//             bins full = {4'hF};
//             bins partial = {4'h1, 4'h3, 4'hC};
//         }
//         cross addr_cp, strb_cp;
//     endgroup
//
//     function new(string name, evm_component parent);
//         super.new(name, parent);
//         axi_write_cg = new();
//         set_target(90.0);  // require 90% coverage for PASS
//     endfunction
//
//     virtual function void sample();
//         if (!coverage_enabled) return;
//         sample_count++;
//         axi_write_cg.sample();
//     endfunction
//
//     virtual function real get_coverage();
//         return axi_write_cg.get_inst_coverage();
//     endfunction
// endclass
//
// // In env build_phase:
// cov = new("axi_cov", this);
// evm_coverage_db::register(cov);
//
// // In monitor run_phase:
// cov.last_txn = collected_txn;
// cov.sample();
//==============================================================================
