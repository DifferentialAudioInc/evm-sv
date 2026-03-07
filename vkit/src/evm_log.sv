//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_log
// Description: Base logging class for all EVM classes
//              Provides logging infrastructure for entire EVM framework
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_log;
    
    //==========================================================================
    // EVM Logging Levels
    //==========================================================================
    typedef enum int {
        EVM_NONE  = 0,  // No logging
        EVM_LOW   = 1,  // Critical messages only
        EVM_MED   = 2,  // Medium verbosity
        EVM_HIGH  = 3,  // High verbosity (detailed)
        EVM_ERROR = 4   // Error level (always shown)
    } evm_verbosity_e;
    
    //==========================================================================
    // Global Verbosity Control
    //==========================================================================
    static evm_verbosity_e global_verbosity = EVM_MED;
    
    //==========================================================================
    // Properties
    //==========================================================================
    protected string m_name;
    protected evm_verbosity_e m_verbosity;
    
    // Statistics
    static int error_count = 0;
    static int warning_count = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_base");
        m_name = name;
        m_verbosity = global_verbosity;
    endfunction
    
    //==========================================================================
    // Logging Methods
    //==========================================================================
    
    // Log message at specified verbosity
    function void log_msg(string msg, evm_verbosity_e level = EVM_MED);
        if (m_verbosity >= level) begin
            $display("[%0t] [%s] %s", $time, m_name, msg);
        end
    endfunction
    
    // Log info
    function void log_info(string msg, evm_verbosity_e level = EVM_MED);
        if (m_verbosity >= level) begin
            $display("[%0t] [INFO ] [%s] %s", $time, m_name, msg);
        end
    endfunction
    
    // Log warning
    function void log_warning(string msg);
        warning_count++;
        $display("[%0t] [WARN ] [%s] %s", $time, m_name, msg);
    endfunction
    
    // Log error
    function void log_error(string msg);
        error_count++;
        $display("[%0t] [ERROR] [%s] %s", $time, m_name, msg);
    endfunction
    
    
    //==========================================================================
    // Verbosity Control
    //==========================================================================
    
    // Set global verbosity
    static function void set_global_verbosity(evm_verbosity_e verb);
        global_verbosity = verb;
        $display("[%0t] [INFO ] [EVM] Global verbosity set to %s", $time, verb.name());
    endfunction
    
    // Set instance verbosity
    function void set_verbosity(evm_verbosity_e verb);
        m_verbosity = verb;
    endfunction
    
    // Get verbosity
    function evm_verbosity_e get_verbosity();
        return m_verbosity;
    endfunction
    
    //==========================================================================
    // Statistics
    //==========================================================================
    
    static function int get_error_count();
        return error_count;
    endfunction
    
    static function int get_warning_count();
        return warning_count;
    endfunction
    
    static function void reset_stats();
        error_count = 0;
        warning_count = 0;
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
