//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_base_test.sv
// Description: Base test class for EVM.
//              Extends evm_component (not root!).
//              Accesses root singleton for phase control and objections.
//              Includes optional Quiescence Counter (evm_qc).
//              P0.2: auto-reports coverage from evm_coverage_db in report_phase.
// Author: Eric Dyer
// Date: 2026-03-05
// Updated: 2026-03-29 - Added optional quiescence counter support
// Updated: 2026-04-24 - P0.2: added coverage summary + +evm_cov_log export
//                       Fixed deprecated evm_log::error_count → get_error_count()
//
// API — Public Interface:
//   [evm_base_test] — virtual base class for all EVM tests
//   new(name)                         — constructor; no parent (tests are top-level)
//   build_phase()                     — processes cmdline + creates QC if enabled
//   process_cmdline_args()            — verbosity, log file, seed, cov_log [P0.2]
//   raise_objection(description)      — delegates to evm_root::get().raise_objection()
//   drop_objection(description)       — delegates to evm_root::get().drop_objection()
//   enable_quiescence_counter(thresh) — create evm_qc with given threshold
//   disable_quiescence_counter()
//   get_qc()                          — returns qc handle
//   is_qc_enabled()                   — 1 if QC is active
//   main_phase()                      — override: implement test stimulus
//   report_phase()                    — prints results + coverage summary [P0.2]
//   get_test_result()                 — 1=PASS, 0=FAIL
//   get_type_name()
//
// Plusargs processed in process_cmdline_args():
//   +evm_verbosity=<NONE|LOW|MEDIUM|HIGH|FULL|DEBUG>
//   +evm_log=<filename>    — enable file logging
//   +evm_seed=<int>        — set random seed
//   +evm_cov_log=<file>    — export per-run coverage CSV [P0.2]
//   +evm_debug             — print all plusargs
//==============================================================================

virtual class evm_base_test extends evm_component;
    
    //==========================================================================
    // Properties
    //==========================================================================
    string test_name;
    
    //==========================================================================
    // Built-in Quiescence Counter (optional)
    //==========================================================================
    evm_qc qc;              // Quiescence counter component
    bit    enable_qc = 0;   // Enable/disable QC (default: disabled)
    int    qc_threshold = 100; // Quiescence threshold in cycles
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_base_test");
        super.new(name, null);  // Tests have no parent
        this.test_name = name;
    endfunction
    
    //==========================================================================
    // Build Phase — Create optional QC + process command-line args
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        process_cmdline_args();
        if (enable_qc) begin
            qc = new("qc", this);
            qc.set_threshold(qc_threshold);
            log_info($sformatf("Quiescence Counter enabled (threshold=%0d)", qc_threshold), EVM_MEDIUM);
        end else begin
            log_info("Quiescence Counter disabled (enable_qc=0)", EVM_HIGH);
        end
    endfunction
    
    //==========================================================================
    // Process Command-line Arguments [P0.2: added +evm_cov_log]
    //==========================================================================
    virtual function void process_cmdline_args();
        evm_verbosity_e cmdline_verbosity;
        string log_file;
        
        // Verbosity
        cmdline_verbosity = evm_cmdline::get_verbosity(EVM_MEDIUM);
        evm_report_handler::set_verbosity(cmdline_verbosity);
        
        // File logging
        if (evm_cmdline::has_plusarg("evm_log") || evm_cmdline::has_plusarg("log")) begin
            log_file = evm_cmdline::get_log_file();
            evm_report_handler::enable_file_logging(log_file);
            log_info($sformatf("File logging enabled: %s", log_file), EVM_MEDIUM);
        end
        
        // Random seed — use evm_cmdline::set_random_seed() for CRV (P0.1)
        // Note: $srandom is valid in function contexts and seeds process RNG
        begin
            int seed;
            seed = evm_cmdline::get_seed();  // cached — same value every call
            if (seed != 0) begin
                $srandom(seed);
                log_info($sformatf("[CRV] Random seed: %0d  (replay: +evm_seed=%0d)",
                                   seed, seed), EVM_MEDIUM);
            end
        end
        
        // Debug: print all plusargs
        if (evm_cmdline::has_plusarg("evm_debug")) begin
            evm_cmdline::print_args();
        end
        
        // +evm_cov_log is checked in report_phase (after coverage is sampled)
    endfunction
    
    //==========================================================================
    // Convenience methods — delegate to evm_root singleton
    //==========================================================================
    
    function void raise_objection(string description = "");
        evm_root::get().raise_objection(description);
    endfunction
    
    function void drop_objection(string description = "");
        evm_root::get().drop_objection(description);
    endfunction
    
    //==========================================================================
    // Quiescence Counter Configuration
    //==========================================================================
    
    function void enable_quiescence_counter(int threshold = 100);
        enable_qc     = 1;
        qc_threshold  = threshold;
        log_info($sformatf("Quiescence Counter will be enabled with threshold=%0d", threshold), EVM_MEDIUM);
    endfunction
    
    function void disable_quiescence_counter();
        enable_qc = 0;
        if (qc != null)
            qc.set_disabled();  // 'disable' is SV keyword — use set_disabled()
        log_info("Quiescence Counter disabled", EVM_MEDIUM);
    endfunction
    
    function evm_qc get_qc();
        return qc;
    endfunction
    
    function bit is_qc_enabled();
        return (enable_qc && qc != null);
    endfunction
    
    //==========================================================================
    // main_phase — override in derived test
    //==========================================================================
    virtual task main_phase();
        log_info("EVM Base Test main_phase (override in derived test)", EVM_LOW);
        raise_objection("base_test_activity");
        #50us;
        drop_objection("base_test_activity");
    endtask
    
    //==========================================================================
    // report_phase [P0.2 enhanced]
    // Prints test results + coverage summary + exports coverage log if requested.
    //==========================================================================
    virtual function void report_phase();
        int    err_count;
        int    warn_count;
        string cov_log_file;
        super.report_phase();
        
        // Use evm_report_handler for correct counts (P0.3 aware — unexpected only)
        err_count  = evm_report_handler::get_error_count();
        warn_count = evm_report_handler::get_warning_count();
        
        // ── P0.2: Coverage summary ──────────────────────────────────────────
        // Print coverage table for all registered evm_coverage_db models.
        // Coverage models report themselves in their own report_phase,
        // but evm_coverage_db::print_summary() gives the aggregate view.
        evm_coverage_db::print_summary();
        
        // Export per-run coverage CSV if +evm_cov_log is present
        if (evm_cmdline::has_plusarg("evm_cov_log")) begin
            void'(evm_cmdline::get_string("evm_cov_log", cov_log_file));
            if (cov_log_file == "") begin
                cov_log_file = {test_name, ".evm_cov"};
            end
            evm_coverage_db::write_log(test_name, cov_log_file);
        end
        // ───────────────────────────────────────────────────────────────────
        
        // ── Test result summary ─────────────────────────────────────────────
        log_info("========================================", EVM_LOW);
        log_info($sformatf("Test:          %s", test_name), EVM_LOW);
        log_info($sformatf("Errors:        %0d", err_count), EVM_LOW);
        log_info($sformatf("Warnings:      %0d", warn_count), EVM_LOW);
        
        if (err_count == 0 && evm_report_handler::get_unmet_expectation_count() == 0) begin
            if (!evm_coverage_db::check_all_targets()) begin
                log_error($sformatf("%s FAILED — coverage target(s) not met", test_name));
            end else begin
                log_info($sformatf("%s PASSED", test_name), EVM_LOW);
            end
        end else begin
            log_error($sformatf("%s FAILED with %0d error(s)", test_name, err_count));
        end
        log_info("========================================", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Utility
    //==========================================================================
    
    function bit get_test_result();
        return (evm_report_handler::get_error_count() == 0 &&
                evm_report_handler::get_unmet_expectation_count() == 0 &&
                evm_coverage_db::check_all_targets());
    endfunction
    
    virtual function string get_type_name();
        return "evm_base_test";
    endfunction
    
endclass : evm_base_test
