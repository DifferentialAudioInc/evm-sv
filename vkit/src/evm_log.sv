//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_log
// Description: Base logging class for all EVM classes
//              Provides logging infrastructure for entire EVM framework
//              Now integrates with evm_report_handler for enhanced reporting
// Author: Eric Dyer  
// Date: 2026-03-05
// Updated: 2026-03-28 - Integrated with evm_report_handler
// Updated: 2026-04-23 - P0.3: added log_expected_error()
//
// API — Public Interface:
//   [evm_log] — virtual base class; all EVM classes extend this
//   log_info(msg, level=EVM_MED)   — info message, verbosity-filtered
//   log_warning(msg)               — warning; always shown
//   log_error(msg)                 — error; always shown; increments error_count
//   log_fatal(msg)                 — fatal; terminates simulation
//   log_expected_error(msg)        — WARNING [EXPECTED]; no error_count [P0.3]
//   set_global_verbosity(verb)     — set global verbosity (static)
//   set_verbosity(verb)            — set instance verbosity
//   get_verbosity()                — get instance verbosity
//   get_error_count()   [static]   — unexpected errors only after P0.3
//   get_warning_count() [static]   — unexpected warnings only after P0.3
//   get_info_count()    [static]
//   get_fatal_count()   [static]
//   reset_stats()       [static]   — delegates to evm_report_handler::reset_counts()
//   print_summary()     [static]   — delegates to evm_report_handler::print_summary()
//   get_name()                     — returns m_name
//   set_name(name)                 — sets m_name
//
//   Verbosity enum: EVM_NONE=0, EVM_LOW=100, EVM_MED=200, EVM_HIGH=300, EVM_DEBUG=500
//==============================================================================

virtual class evm_log;
    
    //==========================================================================
    // Legacy Verbosity Enum (for backward compatibility)
    // NOTE: New code should use evm_verbosity_e from evm_report_handler
    //==========================================================================
    typedef enum int {
        EVM_NONE  = 0,    // Maps to EVM_NONE (0)
        EVM_LOW   = 100,  // Maps to EVM_LOW (100)
        EVM_MED   = 200,  // Maps to EVM_MEDIUM (200)
        EVM_HIGH  = 300,  // Maps to EVM_HIGH (300)
        EVM_DEBUG = 500   // Maps to EVM_DEBUG (500)
    } evm_verbosity_e;
    
    //==========================================================================
    // Properties
    //==========================================================================
    protected string m_name;
    protected int m_verbosity;  // Changed to int to support new verbosity levels
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_base");
        m_name = name;
        m_verbosity = evm_report_handler::get_verbosity(); // Use global setting
    endfunction
    
    //==========================================================================
    // Logging Methods - Now use evm_report_handler
    //==========================================================================
    
    // Log info - with verbosity filtering
    function void log_info(string msg, int level = EVM_MED);
        evm_report_handler::evm_report_info(
            "INFO",
            msg,
            level,
            "",
            0,
            m_name
        );
    endfunction
    
    // Log warning - always shown, simulation continues
    function void log_warning(string msg);
        evm_report_handler::evm_report_warning(
            "WARNING",
            msg,
            "",
            0,
            m_name
        );
    endfunction
    
    // Log error - always shown, simulation continues (unless configured otherwise)
    function void log_error(string msg);
        evm_report_handler::evm_report_error(
            "ERROR",
            msg,
            "",
            0,
            m_name
        );
    endfunction
    
    // Log fatal - always shown, simulation terminates after delay
    function void log_fatal(string msg);
        evm_report_handler::evm_report_fatal(
            "FATAL",
            msg,
            "",
            0,
            m_name
        );
    endfunction
    
    // Log an expected error condition (P0.3).
    // Use when this component itself knows an error is safe and expected.
    // Logs as WARNING with [EXPECTED] prefix — does NOT increment error_count.
    //
    // Alternative pattern (from test): evm_report_handler::expect_error(pattern)
    // which intercepts a later log_error() call instead of replacing it.
    function void log_expected_error(string msg);
        log_warning($sformatf("[EXPECTED] %s", msg));
    endfunction
    
    //==========================================================================
    // Verbosity Control
    //==========================================================================
    
    // Set global verbosity (delegates to evm_report_handler)
    static function void set_global_verbosity(int verb);
        // Use case to select package-level enum values, avoiding enum type mismatch
        case (verb)
            0:       evm_report_handler::set_verbosity(EVM_NONE);
            100:     evm_report_handler::set_verbosity(EVM_LOW);
            200:     evm_report_handler::set_verbosity(EVM_MEDIUM);
            300:     evm_report_handler::set_verbosity(EVM_HIGH);
            400:     evm_report_handler::set_verbosity(EVM_FULL);
            500:     evm_report_handler::set_verbosity(EVM_DEBUG);
            default: evm_report_handler::set_verbosity(EVM_MEDIUM);
        endcase
    endfunction
    
    // Set instance verbosity
    function void set_verbosity(int verb);
        m_verbosity = verb;
    endfunction
    
    // Get verbosity
    function int get_verbosity();
        return m_verbosity;
    endfunction
    
    //==========================================================================
    // Statistics (delegates to evm_report_handler)
    //==========================================================================
    
    static function int get_error_count();
        return evm_report_handler::get_error_count();
    endfunction
    
    static function int get_warning_count();
        return evm_report_handler::get_warning_count();
    endfunction
    
    static function int get_info_count();
        return evm_report_handler::get_info_count();
    endfunction
    
    static function int get_fatal_count();
        return evm_report_handler::get_fatal_count();
    endfunction
    
    static function void reset_stats();
        evm_report_handler::reset_counts();
    endfunction
    
    static function void print_summary();
        evm_report_handler::print_summary();
    endfunction
    
    //==========================================================================
    // Backward compatibility aliases
    //==========================================================================
    
    // Legacy statistics (map to new handler)
    static int error_count = 0;    // Deprecated - use get_error_count()
    static int warning_count = 0;  // Deprecated - use get_warning_count()
    
    // Update legacy counters for backward compatibility
    static function void update_legacy_counts();
        error_count = evm_report_handler::get_error_count();
        warning_count = evm_report_handler::get_warning_count();
    endfunction
    
    //==========================================================================
    // Accessor Methods
    //==========================================================================
    
    virtual function string get_name();
        return m_name;
    endfunction
    
    virtual function void set_name(string name);
        m_name = name;
    endfunction
    
endclass : evm_log
