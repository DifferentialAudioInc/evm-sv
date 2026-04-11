//==============================================================================
// EVM - Embedded Verification Methodology
// Command-line Argument Processing
// Provides UVM-style plusarg handling
//==============================================================================

class evm_cmdline;
    
    //==========================================================================
    // Get test name from command line
    // Usage: +evm_testname=my_test or +EVM_TESTNAME=my_test
    //==========================================================================
    static function string get_test_name(string default_name = "");
        string test_name;
        
        if ($value$plusargs("evm_testname=%s", test_name) ||
            $value$plusargs("EVM_TESTNAME=%s", test_name) ||
            $value$plusargs("testname=%s", test_name) ||
            $value$plusargs("TESTNAME=%s", test_name)) begin
            return test_name;
        end
        
        return default_name;
    endfunction
    
    //==========================================================================
    // Get verbosity from command line
    // Usage: +evm_verbosity=300 or +EVM_VERBOSITY=HIGH
    //==========================================================================
    static function evm_verbosity_e get_verbosity(evm_verbosity_e default_verb = EVM_MEDIUM);
        int verb_int;
        string verb_str;
        
        // Try integer value first
        if ($value$plusargs("evm_verbosity=%d", verb_int) ||
            $value$plusargs("EVM_VERBOSITY=%d", verb_int) ||
            $value$plusargs("verbosity=%d", verb_int)) begin
            return evm_verbosity_e'(verb_int);
        end
        
        // Try string value
        if ($value$plusargs("evm_verbosity=%s", verb_str) ||
            $value$plusargs("EVM_VERBOSITY=%s", verb_str) ||
            $value$plusargs("verbosity=%s", verb_str)) begin
            
            verb_str = verb_str.toupper();
            
            case (verb_str)
                "NONE":   return EVM_NONE;
                "LOW":    return EVM_LOW;
                "MEDIUM", "MED": return EVM_MEDIUM;
                "HIGH":   return EVM_HIGH;
                "FULL":   return EVM_FULL;
                "DEBUG":  return EVM_DEBUG;
                default: begin
                    $display("Warning: Unknown verbosity '%s', using default", verb_str);
                    return default_verb;
                end
            endcase
        end
        
        return default_verb;
    endfunction
    
    //==========================================================================
    // Get random seed from command line
    // Usage: +evm_seed=12345 or +seed=12345
    //==========================================================================
    static function int get_seed(int default_seed = 0);
        int seed;
        
        if ($value$plusargs("evm_seed=%d", seed) ||
            $value$plusargs("EVM_SEED=%d", seed) ||
            $value$plusargs("seed=%d", seed) ||
            $value$plusargs("SEED=%d", seed)) begin
            return seed;
        end
        
        // If no seed provided, generate random one
        if (default_seed == 0) begin
            return $urandom();
        end
        
        return default_seed;
    endfunction
    
    //==========================================================================
    // Get log file name from command line
    // Usage: +evm_log=mytest.log
    //==========================================================================
    static function string get_log_file(string default_log = "evm.log");
        string log_file;
        
        if ($value$plusargs("evm_log=%s", log_file) ||
            $value$plusargs("EVM_LOG=%s", log_file) ||
            $value$plusargs("log=%s", log_file)) begin
            return log_file;
        end
        
        return default_log;
    endfunction
    
    //==========================================================================
    // Get timeout from command line
    // Usage: +evm_timeout=1000 (microseconds)
    //==========================================================================
    static function int get_timeout(int default_timeout_us = 1000);
        int timeout;
        
        if ($value$plusargs("evm_timeout=%d", timeout) ||
            $value$plusargs("EVM_TIMEOUT=%d", timeout) ||
            $value$plusargs("timeout=%d", timeout)) begin
            return timeout;
        end
        
        return default_timeout_us;
    endfunction
    
    //==========================================================================
    // Check if plusarg exists (for boolean flags)
    // Usage: +evm_debug, +evm_waveform
    //==========================================================================
    static function bit has_plusarg(string arg);
        // $test$plusargs(variable) crashes XSim — XSim only supports string literals
        // Workaround: use $value$plusargs which handles variable format strings correctly
        string dummy;
        return $value$plusargs({arg, "=%s"}, dummy);
    endfunction
    
    //==========================================================================
    // Get integer plusarg
    // Usage: +my_value=100
    //==========================================================================
    static function bit get_int(string arg, output int value);
        string full_arg = {arg, "=%d"};
        return $value$plusargs(full_arg, value);
    endfunction
    
    //==========================================================================
    // Get string plusarg
    // Usage: +my_string=hello
    //==========================================================================
    static function bit get_string(string arg, output string value);
        string full_arg = {arg, "=%s"};
        return $value$plusargs(full_arg, value);
    endfunction
    
    //==========================================================================
    // Print all EVM-related plusargs
    //==========================================================================
    static function void print_args();
        $display("================================================================================");
        $display("EVM Command-line Arguments:");
        $display("================================================================================");
        $display("  Test Name:    %s", get_test_name("(not specified)"));
        $display("  Verbosity:    %s (%0d)", get_verbosity().name(), get_verbosity());
        $display("  Seed:         %0d", get_seed());
        $display("  Log File:     %s", get_log_file());
        $display("  Timeout:      %0d us", get_timeout());
        $display("  Debug:        %s", has_plusarg("evm_debug") ? "ON" : "OFF");
        $display("  Waveform:     %s", has_plusarg("evm_waveform") ? "ON" : "OFF");
        $display("================================================================================");
    endfunction
    
endclass
