//==============================================================================
// EVM - Embedded Verification Methodology
// Assertion Wrapper
// Simplifies assertion usage with EVM reporting
//==============================================================================

//==============================================================================
// EVM Assertion Macros
// Usage: `EVM_ASSERT(condition, "message")
//        `EVM_ASSERT_FATAL(condition, "critical error")
//==============================================================================

// Standard assertion - logs ERROR on failure
`define EVM_ASSERT(COND, MSG="Assertion failed") \
    if (!(COND)) begin \
        evm_report_handler::report_error($sformatf("ASSERT_FAILED: %s at %s:%0d", MSG, `__FILE__, `__LINE__)); \
    end

// Fatal assertion - logs FATAL and stops simulation
`define EVM_ASSERT_FATAL(COND, MSG="Fatal assertion failed") \
    if (!(COND)) begin \
        evm_report_handler::report_fatal($sformatf("ASSERT_FATAL: %s at %s:%0d", MSG, `__FILE__, `__LINE__)); \
    end

// Warning assertion - logs WARNING on failure
`define EVM_ASSERT_WARN(COND, MSG="Assertion warning") \
    if (!(COND)) begin \
        evm_report_handler::report_warning($sformatf("ASSERT_WARN: %s at %s:%0d", MSG, `__FILE__, `__LINE__)); \
    end

// Info assertion - logs INFO on failure (non-critical)
`define EVM_ASSERT_INFO(COND, MSG="Assertion info") \
    if (!(COND)) begin \
        evm_report_handler::report_info($sformatf("ASSERT_INFO: %s at %s:%0d", MSG, `__FILE__, `__LINE__), EVM_MEDIUM); \
    end

//==============================================================================
// Class: evm_assertion_checker
// Description: Object-oriented assertion checker with statistics
//              Can be used as a component in testbench
//==============================================================================
class evm_assertion_checker extends evm_component;
    
    // Statistics
    protected int passed_count;
    protected int failed_count;
    protected int warning_count;
    protected int total_checks;
    
    // Configuration
    protected bit stop_on_error;
    protected bit enable_checks;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "assertion_checker", evm_component parent = null);
        super.new(name, parent);
        passed_count = 0;
        failed_count = 0;
        warning_count = 0;
        total_checks = 0;
        stop_on_error = 0;
        enable_checks = 1;
    endfunction
    
    //==========================================================================
    // Configuration
    //==========================================================================
    function void set_stop_on_error(bit stop);
        stop_on_error = stop;
    endfunction
    
    function void set_enable(bit enable);
        enable_checks = enable;
        log_info($sformatf("Assertion checking %s", enable ? "enabled" : "disabled"), EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Check assertion
    //==========================================================================
    virtual function void check(bit condition, string msg = "Check failed", 
                               evm_severity_e severity = EVM_ERROR);
        if (!enable_checks) return;
        
        total_checks++;
        
        if (condition) begin
            passed_count++;
            log_info($sformatf("PASS: %s", msg), EVM_DEBUG);
        end else begin
            failed_count++;
            
            case (severity)
                EVM_INFO: begin
                    log_info($sformatf("CHECK_FAIL: %s", msg), EVM_MEDIUM);
                end
                EVM_WARNING: begin
                    warning_count++;
                    log_warning($sformatf("CHECK_FAIL: %s", msg));
                end
                EVM_ERROR: begin
                    log_error($sformatf("CHECK_FAIL: %s", msg));
                    if (stop_on_error) begin
                        log_fatal("Stopping on assertion error");
                    end
                end
                EVM_FATAL: begin
                    log_fatal($sformatf("CHECK_FAIL: %s", msg));
                end
            endcase
        end
    endfunction
    
    //==========================================================================
    // Convenience methods
    //==========================================================================
    virtual function void check_equal(int actual, int expected, string msg = "Values not equal");
        string full_msg = $sformatf("%s (expected: %0d, actual: %0d)", msg, expected, actual);
        check(actual == expected, full_msg);
    endfunction
    
    virtual function void check_not_equal(int actual, int unexpected, string msg = "Values should differ");
        string full_msg = $sformatf("%s (both are: %0d)", msg, actual);
        check(actual != unexpected, full_msg);
    endfunction
    
    virtual function void check_range(int value, int min, int max, string msg = "Value out of range");
        string full_msg = $sformatf("%s (value: %0d, range: [%0d:%0d])", msg, value, min, max);
        check(value >= min && value <= max, full_msg);
    endfunction
    
    virtual function void check_not_null(ref logic ptr, string msg = "Pointer is null");
        check(ptr !== 1'bx && ptr !== 1'bz, msg);
    endfunction
    
    //==========================================================================
    // Report Phase
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        
        log_info("================================================================================", EVM_LOW);
        log_info($sformatf("Assertion Checker Report: %s", get_name()), EVM_LOW);
        log_info("================================================================================", EVM_LOW);
        log_info($sformatf("  Total Checks:     %0d", total_checks), EVM_LOW);
        log_info($sformatf("  Passed:           %0d", passed_count), EVM_LOW);
        log_info($sformatf("  Failed:           %0d", failed_count), EVM_LOW);
        log_info($sformatf("  Warnings:         %0d", warning_count), EVM_LOW);
        
        if (total_checks > 0) begin
            real pass_rate = (real'(passed_count) / real'(total_checks)) * 100.0;
            log_info($sformatf("  Pass Rate:        %.2f%%", pass_rate), EVM_LOW);
        end
        
        log_info("================================================================================", EVM_LOW);
        
        if (failed_count > 0) begin
            log_error($sformatf("%0d assertion(s) failed!", failed_count));
        end else if (total_checks > 0) begin
            log_info("*** ALL ASSERTIONS PASSED! ***", EVM_LOW);
        end
    endfunction
    
    //==========================================================================
    // Get statistics
    //==========================================================================
    function int get_passed_count();
        return passed_count;
    endfunction
    
    function int get_failed_count();
        return failed_count;
    endfunction
    
    function int get_total_count();
        return total_checks;
    endfunction
    
    function real get_pass_rate();
        if (total_checks == 0) return 0.0;
        return (real'(passed_count) / real'(total_checks)) * 100.0;
    endfunction
    
endclass

//==============================================================================
// Concurrent Assertion Wrappers
// These map SystemVerilog assertions to EVM reporting
//==============================================================================

// Example of binding concurrent assertions to EVM reporting
// bind dut_module assertion_monitor #(.NAME("dut_assertions")) asm_inst (.*);
//
// module assertion_monitor #(parameter string NAME = "assertions") (
//     input clk,
//     input reset_n,
//     input valid,
//     input ready
// );
//     
//     // Example assertion
//     property valid_implies_ready;
//         @(posedge clk) disable iff (!reset_n)
//         valid |-> ready;
//     endproperty
//     
//     assert property (valid_implies_ready)
//         else evm_report_handler::report_error($sformatf("%s: valid without ready", NAME));
//     
// endmodule
//==============================================================================
