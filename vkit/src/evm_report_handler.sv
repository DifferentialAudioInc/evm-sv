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
//==============================================================================

//==============================================================================
// Enum: evm_severity_e
// Description: Severity levels for EVM reporting
//              Aligned with UVM severity model
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
// Class: evm_report_handler
// Source: Inspired by UVM reporting (uvm_report_handler, uvm_report_server)
// Description: Centralized report handling for EVM
//              Manages all reporting, counting, and actions
//              Lightweight singleton pattern
// Rationale: CRITICAL for verification:
//            - All messages must be counted (INFO, WARNING, ERROR, FATAL)
//            - FATAL must terminate simulation (after delay for waveforms!)
//            - Must support verbosity filtering
//            - Must provide summary at end
// UVM Equivalent: Combines uvm_report_handler + uvm_report_server
// EVM Simplification: Single singleton, no report catcher, simpler actions
// CRITICAL FEATURE: FATAL waits 1μs before $finish for waveform capture!
//==============================================================================
class evm_report_handler;
    
    //==========================================================================
    // Static Properties
    //==========================================================================
    static local evm_report_handler m_inst = null;
    
    //==========================================================================
    // Message Counters
    //==========================================================================
    static int info_count    = 0;
    static int warning_count = 0;
    static int error_count   = 0;
    static int fatal_count   = 0;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    static evm_verbosity_e global_verbosity = EVM_MEDIUM;
    static bit stop_on_error = 0;  // Continue by default
    static bit stop_on_warning = 0; // Continue by default
    static int max_quit_count = 0;  // 0 = no limit
    static int fatal_delay_ns = 1000; // 1us delay before $finish
    
    //==========================================================================
    // File Logging
    //==========================================================================
    static int log_file_handle = 0;  // File handle for log file
    static bit file_logging_enabled = 0;  // Enable/disable file logging
    static string log_filename = "evm.log";  // Default log filename
    
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
    // Constructor (private for singleton)
    //==========================================================================
    local function new();
        // Private constructor
    endfunction
    
    //==========================================================================
    // Singleton Access
    //==========================================================================
    static function evm_report_handler get();
        if (m_inst == null) begin
            m_inst = new();
        end
        return m_inst;
    endfunction
    
    //==========================================================================
    // Core Reporting Function
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
        int total_errors;
        string severity_str;
        string full_msg;
        string location_str;
        string context_str;
        
        // Check verbosity filtering (doesn't apply to ERROR and FATAL)
        if (severity == EVM_INFO && verbosity > global_verbosity) begin
            return; // Message filtered out
        end
        
        // Build location string
        if (filename != "" && line > 0) begin
            location_str = $sformatf(" [%s:%0d]", filename, line);
        end else begin
            location_str = "";
        end
        
        // Build context string (component hierarchy)
        if (context_name != "") begin
            context_str = $sformatf(" [%s]", context_name);
        end else begin
            context_str = "";
        end
        
        // Get severity string
        severity_str = severity_names[severity];
        
        // Update counters
        case (severity)
            EVM_INFO:    info_count++;
            EVM_WARNING: warning_count++;
            EVM_ERROR:   error_count++;
            EVM_FATAL:   fatal_count++;
        endcase
        
        // Build and display full message
        full_msg = $sformatf("[%0t] [%s]%s [%s] %s%s",
                           $time,
                           severity_str,
                           context_str,
                           id,
                           message,
                           location_str);
        
        // Display to console
        $display("%s", full_msg);
        
        // Write to log file if enabled
        if (file_logging_enabled && log_file_handle != 0) begin
            $fdisplay(log_file_handle, "%s", full_msg);
            $fflush(log_file_handle);  // Flush to ensure write
        end
        
        // Handle severity-specific actions
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
                    // Note: no #delay in function — waveforms captured via log_wave
                    $finish(2);
                end else if (stop_on_error) begin
                    $display("[%0t] [EVM] Stopping simulation due to ERROR (stop_on_error=1)", $time);
                    $stop;
                end
            end
            
            EVM_FATAL: begin
                $display("[%0t] [FATAL] Terminating simulation", $time);
                // Note: no #delay in function — waveforms captured via log_wave
                $finish(2);
            end
            
            default: begin
                // EVM_INFO - no action needed
            end
        endcase
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
    
    // Enable file logging
    static function bit enable_file_logging(string filename = "evm.log");
        if (log_file_handle != 0) begin
            $display("[%0t] [EVM WARNING] Log file already open, closing previous file", $time);
            $fclose(log_file_handle);
        end
        
        log_filename = filename;
        log_file_handle = $fopen(filename, "w");
        
        if (log_file_handle == 0) begin
            $display("[%0t] [EVM ERROR] Failed to open log file: %s", $time, filename);
            file_logging_enabled = 0;
            return 0;
        end
        
        file_logging_enabled = 1;
        $display("[%0t] [EVM] File logging enabled: %s", $time, filename);
        
        // Write header to log file
        $fdisplay(log_file_handle, "================================================================================");
        $fdisplay(log_file_handle, "EVM Simulation Log");
        $fdisplay(log_file_handle, "Started: %0t", $time);
        $fdisplay(log_file_handle, "================================================================================");
        $fflush(log_file_handle);
        
        return 1;
    endfunction
    
    // Disable file logging and close file
    static function void disable_file_logging();
        if (log_file_handle != 0) begin
            // Write footer
            $fdisplay(log_file_handle, "");
            $fdisplay(log_file_handle, "================================================================================");
            $fdisplay(log_file_handle, "Simulation ended: %0t", $time);
            $fdisplay(log_file_handle, "================================================================================");
            
            $fclose(log_file_handle);
            log_file_handle = 0;
            file_logging_enabled = 0;
            $display("[%0t] [EVM] File logging disabled", $time);
        end
    endfunction
    
    // Check if file logging is enabled
    static function bit is_file_logging_enabled();
        return file_logging_enabled;
    endfunction
    
    // Get log filename
    static function string get_log_filename();
        return log_filename;
    endfunction
    
    //==========================================================================
    // Statistics Functions
    //==========================================================================
    
    static function int get_info_count();
        return info_count;
    endfunction
    
    static function int get_warning_count();
        return warning_count;
    endfunction
    
    static function int get_error_count();
        return error_count;
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
        info_count = 0;
        warning_count = 0;
        error_count = 0;
        fatal_count = 0;
    endfunction
    
    static function void print_summary();
        string pass_fail;
        
        // Determine pass/fail status
        if (error_count > 0 || fatal_count > 0) begin
            pass_fail = $sformatf("*** TEST FAILED with %0d errors ***", 
                                error_count + fatal_count);
        end else if (warning_count > 0) begin
            pass_fail = $sformatf("*** TEST PASSED with %0d warnings ***", 
                                warning_count);
        end else begin
            pass_fail = "*** TEST PASSED ***";
        end
        
        // Print to console
        $display("");
        $display("==============================================================================");
        $display("                        EVM REPORT SUMMARY");
        $display("==============================================================================");
        $display("[%0t] INFO messages:    %0d", $time, info_count);
        $display("[%0t] WARNINGs:          %0d", $time, warning_count);
        $display("[%0t] ERRORs:            %0d", $time, error_count);
        $display("[%0t] FATALs:            %0d", $time, fatal_count);
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
            $fdisplay(log_file_handle, "[%0t] INFO messages:    %0d", $time, info_count);
            $fdisplay(log_file_handle, "[%0t] WARNINGs:          %0d", $time, warning_count);
            $fdisplay(log_file_handle, "[%0t] ERRORs:            %0d", $time, error_count);
            $fdisplay(log_file_handle, "[%0t] FATALs:            %0d", $time, fatal_count);
            $fdisplay(log_file_handle, "==============================================================================");
            $fdisplay(log_file_handle, "[%0t] %s", $time, pass_fail);
            $fdisplay(log_file_handle, "==============================================================================");
            $fdisplay(log_file_handle, "");
            $fflush(log_file_handle);
            
            // Close log file
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
