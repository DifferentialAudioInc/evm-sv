//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_report_handler.sv
// Description: Enhanced reporting infrastructure for EVM
//              Inspired by UVM reporting but lightweight for embedded use
// Author: EVM Contributors
// Date: 2026-03-28
// Updated: 2026-04-23 - P0.3 Expected Error / Negative Test Infrastructure
//   + evm_error_catcher virtual class (custom logic filtering)
//   + expect_error(), expect_error_range(), expect_error_optional()
//   + suppress_error() and warning equivalents
//   + register_error_catcher() / unregister_error_catcher()
//   + print_expectation_report()
//   + Modified report() to route expected messages through filter chain
//   + Modified print_summary() to include expectation results in PASS/FAIL
//
// API — Public Interface:
//   [evm_error_catcher] — virtual base class for custom error/warning filtering [P0.3]
//   evm_error_catcher.new(n)                     — constructor, sets catcher_name
//   evm_error_catcher.catch_error(id,msg,ctx)    — pure virtual; return 1 to absorb
//   evm_error_catcher.catch_warning(id,msg,ctx)  — virtual; return 1 to absorb
//   evm_error_catcher.get_name()                 — returns catcher_name
//
//   [evm_report_handler] — centralized singleton report handler
//   evm_report_handler::get()                    — singleton access / create
//   evm_report_handler::report(sev,id,msg,...)   — core report; P0.3 filter chain
//   evm_report_handler::evm_report_info(...)     — convenience: EVM_INFO
//   evm_report_handler::evm_report_warning(...)  — convenience: EVM_WARNING
//   evm_report_handler::evm_report_error(...)    — convenience: EVM_ERROR
//   evm_report_handler::evm_report_fatal(...)    — convenience: EVM_FATAL
//   evm_report_handler::set_verbosity(v)         — set global verbosity
//   evm_report_handler::get_verbosity()          — get global verbosity
//   evm_report_handler::set_stop_on_error(v)     — stop sim on unexpected error
//   evm_report_handler::set_stop_on_warning(v)   — stop sim on unexpected warning
//   evm_report_handler::set_max_quit_count(n)    — max errors before $finish
//   evm_report_handler::set_fatal_delay_ns(ns)   — delay before $finish on FATAL
//   evm_report_handler::enable_file_logging(f)   — open log file
//   evm_report_handler::disable_file_logging()   — close log file
//   evm_report_handler::is_file_logging_enabled()
//   evm_report_handler::get_log_filename()
//   evm_report_handler::get_info_count()
//   evm_report_handler::get_warning_count()      — unexpected warnings only [P0.3]
//   evm_report_handler::get_error_count()        — unexpected errors only [P0.3]
//   evm_report_handler::get_fatal_count()
//   evm_report_handler::get_severity_count(sev)
//   evm_report_handler::reset_counts()
//   evm_report_handler::print_summary()          — PASS/FAIL + expectation table [P0.3]
//   evm_report_handler::expect_error(pat,n=1)          — exact count [P0.3]
//   evm_report_handler::expect_error_range(pat,min,max)— range (max=-1=unlimited) [P0.3]
//   evm_report_handler::expect_error_optional(pat)     — 0 or 1 OK [P0.3]
//   evm_report_handler::suppress_error(pat)            — mute always, no min [P0.3]
//   evm_report_handler::expect_warning(pat,n=1)        [P0.3]
//   evm_report_handler::expect_warning_range(pat,mn,mx)[P0.3]
//   evm_report_handler::expect_warning_optional(pat)   [P0.3]
//   evm_report_handler::suppress_warning(pat)          [P0.3]
//   evm_report_handler::clear_expected()               — clear pattern lists [P0.3]
//   evm_report_handler::get_unexpected_error_count()   — = error_count [P0.3]
//   evm_report_handler::get_unmet_expectation_count()  — > 0 = FAIL [P0.3]
//   evm_report_handler::print_expectation_report()     — expectation table [P0.3]
//   evm_report_handler::str_contains(haystack,needle)  — public substr search [P0.3]
//   evm_report_handler::register_error_catcher(c)      — add catcher [P0.3]
//   evm_report_handler::unregister_error_catcher(c)    — remove catcher [P0.3]
//
//   [Global convenience functions]
//   evm_info(id, msg, verbosity)   — shorthand for evm_report_info()
//   evm_warning(id, msg)           — shorthand for evm_report_warning()
//   evm_error(id, msg)             — shorthand for evm_report_error()
//   evm_fatal(id, msg)             — shorthand for evm_report_fatal()
//==============================================================================

//==============================================================================
// Enum: evm_severity_e
// Description: Severity levels for EVM reporting
//==============================================================================
typedef enum int {
    EVM_INFO    = 0,  // Informational message
    EVM_WARNING = 1,  // Warning - simulation continues
    EVM_ERROR   = 2,  // Error - simulation continues
    EVM_FATAL   = 3   // Fatal error - simulation terminates after delay
} evm_severity_e;

//==============================================================================
// Enum: evm_verbosity_e
// Description: Verbosity levels for filtering messages
//==============================================================================
typedef enum int {
    EVM_NONE   = 0,   // No messages
    EVM_LOW    = 100, // Low verbosity (critical only)
    EVM_MEDIUM = 200, // Medium verbosity (default)
    EVM_HIGH   = 300, // High verbosity (detailed)
    EVM_FULL   = 400, // Full verbosity (everything)
    EVM_DEBUG  = 500  // Debug level (extremely detailed)
} evm_verbosity_e;

//==============================================================================
// Enum: evm_action_e
// Description: Actions to take when report is generated
//==============================================================================
typedef enum int {
    EVM_NO_ACTION = 0,
    EVM_DISPLAY   = 1,
    EVM_LOG       = 2,
    EVM_COUNT     = 4,
    EVM_EXIT      = 8,
    EVM_STOP      = 16
} evm_action_e;

//==============================================================================
// Class: evm_error_catcher  [P0.3]
// Description: Virtual base class for custom error/warning filtering.
//              Extend this class and register with
//              evm_report_handler::register_error_catcher() to intercept
//              errors with custom logic.
//
// Use cases:
//   - ISR race conditions: suppress SLVERR only while ISR window is open
//   - DMA burst windows: absorb up to N errors during active DMA transfer
//   - Conditional suppression: suppress only if IRQ register already cleared
//   - Latency-dependent counts: 1-3 errors OK depending on ISR latency
//
// Pattern:
//   return 1 from catch_error() to ABSORB (suppress, won't count as failure)
//   return 0 to let it through as a normal unexpected error
//
// Usage example:
//   class dma_slverr_catcher extends evm_error_catcher;
//     bit window_open = 0;
//     int caught      = 0;
//     int max_allowed;
//     function new(string n, int max); super.new(n); max_allowed = max; endfunction
//     virtual function bit catch_error(string id, string msg, string ctx);
//       if (!window_open) return 0;
//       if (caught < max_allowed && evm_report_handler::str_contains(msg, "SLVERR")) begin
//         caught++; return 1;  // absorb
//       end
//       return 0;
//     endfunction
//   endclass
//
//   dma_slverr_catcher c = new("dma_catcher", 3);
//   evm_report_handler::register_error_catcher(c);
//   c.window_open = 1;
//   start_dma();
//   wait_dma_done();
//   c.window_open = 0;
//   evm_report_handler::unregister_error_catcher(c);
//   if (c.caught < 1) log_error("Expected at least 1 SLVERR during DMA");
//==============================================================================
virtual class evm_error_catcher;
    string catcher_name;
    
    function new(string n = "evm_error_catcher");
        catcher_name = n;
    endfunction
    
    // Override: return 1 to absorb/suppress this error (won't fail the test).
    //           return 0 to let it through as a real unexpected error.
    // id:           report ID (e.g., "ERROR")
    // message:      full message text
    // context_name: component hierarchy path (e.g., "env.agent.monitor")
    pure virtual function bit catch_error(string id, string message, string context_name);
    
    // Override (optional): return 1 to absorb warnings.
    // Default: don't catch any warnings.
    virtual function bit catch_warning(string id, string message, string context_name);
        return 0;
    endfunction
    
    function string get_name();
        return catcher_name;
    endfunction
endclass : evm_error_catcher


//==============================================================================
// Class: evm_report_handler
// Source: Inspired by UVM reporting (uvm_report_handler, uvm_report_server)
// Description: Centralized report handling for EVM.
//              Manages all reporting, counting, and actions.
//              Lightweight singleton pattern.
//
// P0.3 additions: Two-layer expected-error filter chain
//   Layer 1 — evm_error_catcher: custom class-based logic (for complex cases)
//   Layer 2 — Pattern list: simple substring matching with count ranges
//
//   Filter priority: catchers → pattern list → unexpected error
//   Absorbed messages: still displayed, tagged [EXPECTED], not counted.
//   Test FAILS if: error_count > 0 (unexpected errors)
//              OR: get_unmet_expectation_count() > 0 (expected never occurred)
//==============================================================================
class evm_report_handler;
    
    //==========================================================================
    // Singleton Instance
    //==========================================================================
    static local evm_report_handler m_inst = null;
    
    //==========================================================================
    // Message Counters
    // Note (P0.3): error_count tracks UNEXPECTED errors only.
    //              Expected/absorbed errors tracked in absorbed_error_count.
    //==========================================================================
    static int info_count          = 0;
    static int warning_count       = 0;  // unexpected warnings only
    static int error_count         = 0;  // unexpected errors only (not absorbed)
    static int fatal_count         = 0;
    static int absorbed_error_count = 0; // errors absorbed by catcher or pattern
    
    //==========================================================================
    // Configuration
    //==========================================================================
    static evm_verbosity_e global_verbosity = EVM_MEDIUM;
    static bit stop_on_error   = 0;  // Continue by default
    static bit stop_on_warning = 0;  // Continue by default
    static int max_quit_count  = 0;  // 0 = no limit
    static int fatal_delay_ns  = 1000; // 1us delay before $finish
    
    //==========================================================================
    // File Logging
    //==========================================================================
    static int    log_file_handle      = 0;
    static bit    file_logging_enabled = 0;
    static string log_filename         = "evm.log";
    
    //==========================================================================
    // P0.3 — Expected Error/Warning Pattern Tables
    // Parallel arrays (safer than struct queues for Vivado compatibility).
    //
    //   exp_err_patterns[i] — substring to match against error message
    //   exp_err_min[i]      — minimum required occurrences (0 = optional)
    //   exp_err_max[i]      — maximum allowed (-1 = unlimited, any count OK)
    //   exp_err_seen[i]     — actual occurrence count during simulation
    //
    // FAIL if: exp_err_seen[i] < exp_err_min[i] for any i (unmet expectation)
    // Errors matching pattern but exceeding max_count pass through as unexpected.
    //==========================================================================
    static string exp_err_patterns[$];
    static int    exp_err_min[$];
    static int    exp_err_max[$];
    static int    exp_err_seen[$];
    
    static string exp_warn_patterns[$];
    static int    exp_warn_min[$];
    static int    exp_warn_max[$];
    static int    exp_warn_seen[$];
    
    //==========================================================================
    // P0.3 — Registered Error Catchers
    //==========================================================================
    static evm_error_catcher registered_catchers[$];
    
    //==========================================================================
    // Severity Name Strings
    //==========================================================================
    static string severity_names[evm_severity_e] = '{
        EVM_INFO:    "INFO   ",
        EVM_WARNING: "WARNING",
        EVM_ERROR:   "ERROR  ",
        EVM_FATAL:   "FATAL  "
    };
    
    //==========================================================================
    // Constructor (private — use get() singleton accessor)
    //==========================================================================
    local function new();
        // Private constructor — use get()
    endfunction
    
    //==========================================================================
    // Singleton Access
    //==========================================================================
    static function evm_report_handler get();
        if (m_inst == null)
            m_inst = new();
        return m_inst;
    endfunction
    
    //==========================================================================
    // P0.3 Private: str_contains
    // Case-sensitive substring search.
    // Returns 1 if needle is a substring of haystack.
    // Uses string.substr() — IEEE 1800-2012 §6.16, Vivado-compatible.
    // Made public to allow use in evm_error_catcher derived classes.
    //==========================================================================
    static function bit str_contains(string haystack, string needle);
        int hlen;
        int nlen;
        int i;
        hlen = haystack.len();
        nlen = needle.len();
        if (nlen == 0 || nlen > hlen) return 0;
        for (i = 0; i <= hlen - nlen; i++) begin
            if (haystack.substr(i, i + nlen - 1) == needle) return 1;
        end
        return 0;
    endfunction
    
    //==========================================================================
    // P0.3 Private: run_catchers_error
    // Runs all registered catchers for an ERROR message.
    // Returns 1 (short-circuit) if any catcher absorbs the message.
    //==========================================================================
    static function bit run_catchers_error(string id, string message, string ctx);
        int i;
        for (i = 0; i < registered_catchers.size(); i++) begin
            if (registered_catchers[i] != null) begin
                if (registered_catchers[i].catch_error(id, message, ctx))
                    return 1;
            end
        end
        return 0;
    endfunction
    
    //==========================================================================
    // P0.3 Private: run_catchers_warning
    // Runs all registered catchers for a WARNING message.
    //==========================================================================
    static function bit run_catchers_warning(string id, string message, string ctx);
        int i;
        for (i = 0; i < registered_catchers.size(); i++) begin
            if (registered_catchers[i] != null) begin
                if (registered_catchers[i].catch_warning(id, message, ctx))
                    return 1;
            end
        end
        return 0;
    endfunction
    
    //==========================================================================
    // P0.3 Private: match_expected_error
    // Checks message against registered pattern list.
    // If matched within allowed count range: increments seen[], returns 1.
    // If matched but over max: returns 0 (passes through as unexpected error).
    //==========================================================================
    static function bit match_expected_error(string message);
        int i;
        for (i = 0; i < exp_err_patterns.size(); i++) begin
            if (str_contains(message, exp_err_patterns[i])) begin
                // Within range (or unlimited)?
                if (exp_err_max[i] == -1 || exp_err_seen[i] < exp_err_max[i]) begin
                    exp_err_seen[i]++;
                    return 1;  // absorb
                end
                // Pattern matched but over max — fall through: unexpected error
            end
        end
        return 0;
    endfunction
    
    //==========================================================================
    // P0.3 Private: match_expected_warning
    //==========================================================================
    static function bit match_expected_warning(string message);
        int i;
        for (i = 0; i < exp_warn_patterns.size(); i++) begin
            if (str_contains(message, exp_warn_patterns[i])) begin
                if (exp_warn_max[i] == -1 || exp_warn_seen[i] < exp_warn_max[i]) begin
                    exp_warn_seen[i]++;
                    return 1;
                end
            end
        end
        return 0;
    endfunction
    
    //==========================================================================
    // Core Reporting Function
    // P0.3: Filter chain runs before counter increment.
    //       Absorbed messages still displayed, tagged [EXPECTED].
    //==========================================================================
    static function void report(
        evm_severity_e severity,
        string id,
        string message,
        int verbosity = EVM_MEDIUM,
        string filename = "",
        int line = 0,
        string context_name = ""
    );
        int    total_errors;
        string severity_str;
        string full_msg;
        string location_str;
        string context_str;
        bit    absorbed;
        string expected_tag;
        
        // Verbosity filtering (only applies to INFO)
        if (severity == EVM_INFO && verbosity > global_verbosity)
            return;
        
        // ── P0.3: Filter chain ──────────────────────────────────────────────
        // Layer 1: registered catchers (custom logic — most flexible)
        // Layer 2: pattern list (simple substring matching)
        // Absorbed messages: still displayed, tagged [EXPECTED], not counted.
        absorbed     = 0;
        expected_tag = "";
        
        if (severity == EVM_ERROR) begin
            absorbed = run_catchers_error(id, message, context_name);
            if (!absorbed)
                absorbed = match_expected_error(message);
            if (absorbed)
                expected_tag = "[EXPECTED] ";
        end else if (severity == EVM_WARNING) begin
            absorbed = run_catchers_warning(id, message, context_name);
            if (!absorbed)
                absorbed = match_expected_warning(message);
            if (absorbed)
                expected_tag = "[EXPECTED] ";
        end
        // ────────────────────────────────────────────────────────────────────
        
        // Build location string
        if (filename != "" && line > 0)
            location_str = $sformatf(" [%s:%0d]", filename, line);
        else
            location_str = "";
        
        // Build context string (component hierarchy)
        if (context_name != "")
            context_str = $sformatf(" [%s]", context_name);
        else
            context_str = "";
        
        // Get severity string
        severity_str = severity_names[severity];
        
        // Update counters
        // Only unexpected (non-absorbed) errors count toward failure total.
        case (severity)
            EVM_INFO: info_count++;
            EVM_WARNING: begin
                if (!absorbed)
                    warning_count++;
                // absorbed warnings tracked in exp_warn_seen[] only
            end
            EVM_ERROR: begin
                if (absorbed)
                    absorbed_error_count++;
                else
                    error_count++;
            end
            EVM_FATAL: fatal_count++;
        endcase
        
        // Build and display full message
        // Absorbed messages are tagged [EXPECTED] for visibility in logs
        full_msg = $sformatf("[%0t] [%s]%s [%s] %s%s%s",
                           $time,
                           severity_str,
                           context_str,
                           id,
                           expected_tag,
                           message,
                           location_str);
        
        $display("%s", full_msg);
        
        if (file_logging_enabled && log_file_handle != 0) begin
            $fdisplay(log_file_handle, "%s", full_msg);
            $fflush(log_file_handle);
        end
        
        // Handle severity-specific actions
        // NOTE: actions only fire for non-absorbed messages
        if (!absorbed) begin
            case (severity)
                EVM_WARNING: begin
                    if (stop_on_warning) begin
                        $display("[%0t] [EVM] Stopping simulation due to WARNING (stop_on_warning=1)", $time);
                        $stop;
                    end
                end
                EVM_ERROR: begin
                    total_errors = error_count + fatal_count;
                    if (max_quit_count > 0 && total_errors >= max_quit_count) begin
                        $display("[%0t] [EVM] Maximum error count (%0d) reached - stopping simulation",
                               $time, max_quit_count);
                        $finish(2);
                    end else if (stop_on_error) begin
                        $display("[%0t] [EVM] Stopping simulation due to ERROR (stop_on_error=1)", $time);
                        $stop;
                    end
                end
                EVM_FATAL: begin
                    $display("[%0t] [FATAL] Terminating simulation", $time);
                    $finish(2);
                end
                default: ; // EVM_INFO — no action
            endcase
        end
    endfunction
    
    //==========================================================================
    // Convenience Functions (match UVM naming)
    //==========================================================================
    
    static function void evm_report_info(
        string id,
        string message,
        int verbosity = EVM_MEDIUM,
        string filename = "",
        int line = 0,
        string context_name = ""
    );
        report(EVM_INFO, id, message, verbosity, filename, line, context_name);
    endfunction
    
    static function void evm_report_warning(
        string id,
        string message,
        string filename = "",
        int line = 0,
        string context_name = ""
    );
        report(EVM_WARNING, id, message, EVM_NONE, filename, line, context_name);
    endfunction
    
    static function void evm_report_error(
        string id,
        string message,
        string filename = "",
        int line = 0,
        string context_name = ""
    );
        report(EVM_ERROR, id, message, EVM_NONE, filename, line, context_name);
    endfunction
    
    static function void evm_report_fatal(
        string id,
        string message,
        string filename = "",
        int line = 0,
        string context_name = ""
    );
        report(EVM_FATAL, id, message, EVM_NONE, filename, line, context_name);
    endfunction
    
    //==========================================================================
    // Configuration Functions
    //==========================================================================
    
    static function void set_verbosity(evm_verbosity_e verbosity);
        global_verbosity = verbosity;
        $display("[%0t] [EVM] Global verbosity set to %0d", $time, verbosity);
    endfunction
    
    static function evm_verbosity_e get_verbosity();
        return global_verbosity;
    endfunction
    
    static function void set_stop_on_error(bit value);
        stop_on_error = value;
        $display("[%0t] [EVM] stop_on_error = %0d", $time, value);
    endfunction
    
    static function void set_stop_on_warning(bit value);
        stop_on_warning = value;
        $display("[%0t] [EVM] stop_on_warning = %0d", $time, value);
    endfunction
    
    static function void set_max_quit_count(int count);
        max_quit_count = count;
        $display("[%0t] [EVM] max_quit_count = %0d (0=unlimited)", $time, count);
    endfunction
    
    static function void set_fatal_delay_ns(int delay_ns);
        fatal_delay_ns = delay_ns;
        $display("[%0t] [EVM] fatal_delay_ns = %0d", $time, delay_ns);
    endfunction
    
    //==========================================================================
    // File Logging Functions
    //==========================================================================
    
    static function bit enable_file_logging(string filename = "evm.log");
        if (log_file_handle != 0) begin
            $display("[%0t] [EVM WARNING] Log file already open, closing previous file", $time);
            $fclose(log_file_handle);
        end
        log_filename       = filename;
        log_file_handle    = $fopen(filename, "w");
        if (log_file_handle == 0) begin
            $display("[%0t] [EVM ERROR] Failed to open log file: %s", $time, filename);
            file_logging_enabled = 0;
            return 0;
        end
        file_logging_enabled = 1;
        $display("[%0t] [EVM] File logging enabled: %s", $time, filename);
        $fdisplay(log_file_handle, "================================================================================");
        $fdisplay(log_file_handle, "EVM Simulation Log");
        $fdisplay(log_file_handle, "Started: %0t", $time);
        $fdisplay(log_file_handle, "================================================================================");
        $fflush(log_file_handle);
        return 1;
    endfunction
    
    static function void disable_file_logging();
        if (log_file_handle != 0) begin
            $fdisplay(log_file_handle, "");
            $fdisplay(log_file_handle, "================================================================================");
            $fdisplay(log_file_handle, "Simulation ended: %0t", $time);
            $fdisplay(log_file_handle, "================================================================================");
            $fclose(log_file_handle);
            log_file_handle      = 0;
            file_logging_enabled = 0;
            $display("[%0t] [EVM] File logging disabled", $time);
        end
    endfunction
    
    static function bit is_file_logging_enabled();
        return file_logging_enabled;
    endfunction
    
    static function string get_log_filename();
        return log_filename;
    endfunction
    
    //==========================================================================
    // Statistics Functions
    // Note: get_error_count() returns UNEXPECTED errors only (P0.3).
    //       Use absorbed_error_count for expected errors that were absorbed.
    //==========================================================================
    
    static function int get_info_count();
        return info_count;
    endfunction
    
    static function int get_warning_count();
        return warning_count;
    endfunction
    
    static function int get_error_count();
        return error_count;  // unexpected errors only
    endfunction
    
    static function int get_fatal_count();
        return fatal_count;
    endfunction
    
    static function int get_severity_count(evm_severity_e severity);
        case (severity)
            EVM_INFO:    return info_count;
            EVM_WARNING: return warning_count;
            EVM_ERROR:   return error_count;
            EVM_FATAL:   return fatal_count;
            default:     return 0;
        endcase
    endfunction
    
    static function void reset_counts();
        info_count           = 0;
        warning_count        = 0;
        error_count          = 0;
        fatal_count          = 0;
        absorbed_error_count = 0;
    endfunction
    
    //==========================================================================
    // P0.3 — Expected Error/Warning Registration
    //==========================================================================
    
    // Expect exactly count occurrences of errors matching pattern.
    // FAIL if seen < count (expected error never occurred).
    // Errors beyond count pass through as unexpected (also causes FAIL).
    static function void expect_error(string pattern, int count=1);
        exp_err_patterns.push_back(pattern);
        exp_err_min.push_back(count);
        exp_err_max.push_back(count);
        exp_err_seen.push_back(0);
    endfunction
    
    // Expect between min_count and max_count occurrences.
    //   min_count=0 → optional  (0 occurrences → still PASS)
    //   max_count=-1 → unlimited (any count >= min_count → PASS)
    // Errors matched within range are absorbed; beyond max pass through.
    static function void expect_error_range(string pattern, int min_count=0, int max_count=1);
        exp_err_patterns.push_back(pattern);
        exp_err_min.push_back(min_count);
        exp_err_max.push_back(max_count);
        exp_err_seen.push_back(0);
    endfunction
    
    // Optional: error may appear 0 or 1 times — both outcomes are OK.
    // Ideal for ISR race conditions where occurrence is timing-dependent.
    // If it appears more than once, passes through as unexpected error.
    static function void expect_error_optional(string pattern);
        expect_error_range(pattern, 0, 1);
    endfunction
    
    // Suppress: mute ALL occurrences permanently — no minimum required.
    // Test PASSES regardless of how many times this error appears (even 0).
    // Use for known-noisy 3rd-party IP messages or startup transients.
    static function void suppress_error(string pattern);
        expect_error_range(pattern, 0, -1);
    endfunction
    
    // Warning variants (same semantics as error variants above)
    static function void expect_warning(string pattern, int count=1);
        exp_warn_patterns.push_back(pattern);
        exp_warn_min.push_back(count);
        exp_warn_max.push_back(count);
        exp_warn_seen.push_back(0);
    endfunction
    
    static function void expect_warning_range(string pattern, int min_count=0, int max_count=1);
        exp_warn_patterns.push_back(pattern);
        exp_warn_min.push_back(min_count);
        exp_warn_max.push_back(max_count);
        exp_warn_seen.push_back(0);
    endfunction
    
    static function void expect_warning_optional(string pattern);
        expect_warning_range(pattern, 0, 1);
    endfunction
    
    static function void suppress_warning(string pattern);
        expect_warning_range(pattern, 0, -1);
    endfunction
    
    // Clear all expectations (call between test phases if needed)
    static function void clear_expected();
        exp_err_patterns.delete();
        exp_err_min.delete();
        exp_err_max.delete();
        exp_err_seen.delete();
        exp_warn_patterns.delete();
        exp_warn_min.delete();
        exp_warn_max.delete();
        exp_warn_seen.delete();
        absorbed_error_count = 0;
    endfunction
    
    //==========================================================================
    // P0.3 — Catcher Registration
    //==========================================================================
    
    // Register a custom evm_error_catcher — it will be called for every
    // EVM_ERROR and EVM_WARNING before the pattern list is checked.
    static function void register_error_catcher(evm_error_catcher catcher);
        if (catcher != null)
            registered_catchers.push_back(catcher);
    endfunction
    
    // Unregister a previously registered catcher.
    static function void unregister_error_catcher(evm_error_catcher catcher);
        int del_idx;
        int i;
        del_idx = -1;
        for (i = 0; i < registered_catchers.size(); i++) begin
            if (registered_catchers[i] == catcher) begin
                del_idx = i;
                break;
            end
        end
        if (del_idx >= 0)
            registered_catchers.delete(del_idx);
    endfunction
    
    //==========================================================================
    // P0.3 — Query Functions
    //==========================================================================
    
    // Returns number of errors NOT matched by any expectation or catcher.
    // Non-zero means test FAILS.
    static function int get_unexpected_error_count();
        return error_count;
    endfunction
    
    // Returns number of pattern entries where seen < min (unmet expectations).
    // Non-zero means test FAILS — expected error/warning never occurred.
    // This catches the "bug in the negative test" scenario:
    //   if you expect an error and the DUT silently ignores the fault,
    //   the expectation is unmet → test fails correctly.
    static function int get_unmet_expectation_count();
        int count;
        int i;
        count = 0;
        for (i = 0; i < exp_err_patterns.size(); i++) begin
            if (exp_err_seen[i] < exp_err_min[i])
                count++;
        end
        for (i = 0; i < exp_warn_patterns.size(); i++) begin
            if (exp_warn_seen[i] < exp_warn_min[i])
                count++;
        end
        return count;
    endfunction
    
    //==========================================================================
    // P0.3 — Expectation Report
    // Prints a formatted table of all registered patterns with
    // min/max/seen/status. Called automatically from print_summary().
    //==========================================================================
    static function void print_expectation_report();
        int    i;
        string status_str;
        string max_str;
        string log_line;
        
        if (exp_err_patterns.size() == 0 && exp_warn_patterns.size() == 0)
            return;
        
        $display("[EVM] -----------------------------------------------------------------------");
        $display("[EVM] Expected Message Report:");
        $display("[EVM]  %-4s  %-38s  %5s  %5s  %5s  %s",
                 "Type", "Pattern", "Min", "Max", "Seen", "Status");
        $display("[EVM] -----------------------------------------------------------------------");
        
        for (i = 0; i < exp_err_patterns.size(); i++) begin
            if (exp_err_max[i] == -1)
                max_str = "  INF";
            else
                max_str = $sformatf("%5d", exp_err_max[i]);
            if (exp_err_seen[i] < exp_err_min[i])
                status_str = "UNMET-FAIL";
            else
                status_str = "PASS";
            log_line = $sformatf("[EVM]  ERR   %-38s  %5d  %s  %5d  %s",
                         exp_err_patterns[i], exp_err_min[i], max_str,
                         exp_err_seen[i], status_str);
            $display("%s", log_line);
            if (file_logging_enabled && log_file_handle != 0)
                $fdisplay(log_file_handle, "%s", log_line);
        end
        
        for (i = 0; i < exp_warn_patterns.size(); i++) begin
            if (exp_warn_max[i] == -1)
                max_str = "  INF";
            else
                max_str = $sformatf("%5d", exp_warn_max[i]);
            if (exp_warn_seen[i] < exp_warn_min[i])
                status_str = "UNMET-FAIL";
            else
                status_str = "PASS";
            log_line = $sformatf("[EVM]  WARN  %-38s  %5d  %s  %5d  %s",
                         exp_warn_patterns[i], exp_warn_min[i], max_str,
                         exp_warn_seen[i], status_str);
            $display("%s", log_line);
            if (file_logging_enabled && log_file_handle != 0)
                $fdisplay(log_file_handle, "%s", log_line);
        end
        $display("[EVM] -----------------------------------------------------------------------");
    endfunction
    
    //==========================================================================
    // print_summary — Enhanced for P0.3
    // FAIL conditions:
    //   1. error_count > 0      (unexpected errors occurred)
    //   2. fatal_count > 0      (fatal errors occurred)
    //   3. unmet > 0            (expected error never occurred — negative test bug)
    //==========================================================================
    static function void print_summary();
        string pass_fail;
        int    unmet;
        
        unmet = get_unmet_expectation_count();
        
        if (error_count > 0 || fatal_count > 0) begin
            pass_fail = $sformatf("*** TEST FAILED with %0d unexpected error(s) ***",
                                error_count + fatal_count);
        end else if (unmet > 0) begin
            pass_fail = $sformatf("*** TEST FAILED - %0d expected message(s) never occurred ***",
                                unmet);
        end else if (warning_count > 0) begin
            pass_fail = $sformatf("*** TEST PASSED with %0d warning(s) ***", warning_count);
        end else begin
            pass_fail = "*** TEST PASSED ***";
        end
        
        // Print expectation report first (if any registered patterns)
        print_expectation_report();
        
        // Print summary to console
        $display("");
        $display("==============================================================================");
        $display("                        EVM REPORT SUMMARY");
        $display("==============================================================================");
        $display("[%0t] INFO messages:            %0d", $time, info_count);
        $display("[%0t] WARNINGs (unexpected):    %0d", $time, warning_count);
        $display("[%0t] ERRORs (unexpected):      %0d", $time, error_count);
        $display("[%0t] ERRORs (absorbed/expected):%0d", $time, absorbed_error_count);
        $display("[%0t] FATALs:                   %0d", $time, fatal_count);
        if (exp_err_patterns.size() > 0 || exp_warn_patterns.size() > 0)
            $display("[%0t] Unmet expectations:       %0d", $time, unmet);
        $display("==============================================================================");
        $display("[%0t] %s", $time, pass_fail);
        $display("==============================================================================");
        $display("");
        
        // Write to log file if enabled
        if (file_logging_enabled && log_file_handle != 0) begin
            $fdisplay(log_file_handle, "");
            $fdisplay(log_file_handle, "==============================================================================");
            $fdisplay(log_file_handle, "                        EVM REPORT SUMMARY");
            $fdisplay(log_file_handle, "==============================================================================");
            $fdisplay(log_file_handle, "[%0t] INFO messages:            %0d", $time, info_count);
            $fdisplay(log_file_handle, "[%0t] WARNINGs (unexpected):    %0d", $time, warning_count);
            $fdisplay(log_file_handle, "[%0t] ERRORs (unexpected):      %0d", $time, error_count);
            $fdisplay(log_file_handle, "[%0t] ERRORs (absorbed/expected):%0d", $time, absorbed_error_count);
            $fdisplay(log_file_handle, "[%0t] FATALs:                   %0d", $time, fatal_count);
            if (exp_err_patterns.size() > 0 || exp_warn_patterns.size() > 0)
                $fdisplay(log_file_handle, "[%0t] Unmet expectations:       %0d", $time, unmet);
            $fdisplay(log_file_handle, "==============================================================================");
            $fdisplay(log_file_handle, "[%0t] %s", $time, pass_fail);
            $fdisplay(log_file_handle, "==============================================================================");
            $fdisplay(log_file_handle, "");
            $fflush(log_file_handle);
            disable_file_logging();
        end
    endfunction
    
endclass : evm_report_handler

// Global convenience functions for easy access (similar to UVM macros)
function void evm_info(string id, string message, int verbosity = EVM_MEDIUM);
    evm_report_handler::evm_report_info(id, message, verbosity);
endfunction

function void evm_warning(string id, string message);
    evm_report_handler::evm_report_warning(id, message);
endfunction

function void evm_error(string id, string message);
    evm_report_handler::evm_report_error(id, message);
endfunction

function void evm_fatal(string id, string message);
    evm_report_handler::evm_report_fatal(id, message);
endfunction
