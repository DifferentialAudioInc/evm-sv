//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_cmdline.sv
// Description: Command-line argument processing for EVM.
//              Provides UVM-style plusarg handling for test configuration.
// Author: Eric Dyer
// Date: 2026-03-06
// Updated: 2026-04-24 - P0.1: added set_random_seed(), get_active_seed(),
//                       seed caching so get_seed() returns consistent value.
//
// API — Public Interface:
//   [evm_cmdline] — static utility class for plusarg processing
//   get_test_name(default)     — read +evm_testname= / +EVM_TESTNAME=
//   get_verbosity(default)     — read +evm_verbosity= (int or string)
//   get_seed(default)          — read +evm_seed= ; auto-generate + cache if absent
//   get_active_seed()          — returns the seed set by set_random_seed() [P0.1]
//   set_random_seed()          — apply seed to process generator + log it [P0.1]
//   get_log_file(default)      — read +evm_log=
//   get_timeout(default)       — read +evm_timeout= (microseconds)
//   has_plusarg(arg)           — check if +arg is present
//   get_int(arg, value)        — generic +arg=<int> reader
//   get_string(arg, value)     — generic +arg=<str> reader
//   print_args()               — display all EVM plusargs to console
//
// Key Plusargs:
//   +evm_seed=<N>              — set random seed (int); logged for replay
//   +evm_testname=<name>       — test to run
//   +evm_verbosity=<N|string>  — verbosity level
//   +evm_log=<filename>        — log file
//   +evm_timeout=<us>          — simulation timeout in microseconds
//   +evm_debug                 — print all plusargs at start
//==============================================================================

class evm_cmdline;
    
    //==========================================================================
    // P0.1 — Seed Cache
    // get_seed() stores the first resolved seed and returns it consistently.
    // This ensures log_crv_seed() and set_random_seed() see the same value.
    //==========================================================================
    static int m_cached_seed   = 0;
    static bit m_seed_resolved = 0;
    static bit m_seed_applied  = 0;  // set by set_random_seed()
    
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
    // Get random seed from command line  [P0.1: now cached]
    // Usage: +evm_seed=12345 or +seed=12345
    //
    // On first call: resolves seed from plusarg or auto-generates via $urandom.
    //                Stores result in m_cached_seed.
    // On subsequent calls: returns the same cached value.
    //
    // This ensures consistent seed reporting across log_crv_seed() calls
    // and set_random_seed() application.
    //==========================================================================
    static function int get_seed(int default_seed = 0);
        int seed;
        
        // Return cached value if already resolved
        if (m_seed_resolved) return m_cached_seed;
        
        if ($value$plusargs("evm_seed=%d", seed) ||
            $value$plusargs("EVM_SEED=%d", seed) ||
            $value$plusargs("seed=%d", seed) ||
            $value$plusargs("SEED=%d", seed)) begin
            m_cached_seed   = seed;
            m_seed_resolved = 1;
            return seed;
        end
        
        // No plusarg provided — auto-generate a seed and cache it
        if (default_seed == 0) begin
            seed = $urandom();  // generates one random seed for the whole sim
        end else begin
            seed = default_seed;
        end
        m_cached_seed   = seed;
        m_seed_resolved = 1;
        return seed;
    endfunction
    
    //==========================================================================
    // Get the active seed (same as get_seed() but documents intent) [P0.1]
    // Use this from log_crv_seed() or anywhere needing the simulation seed.
    //==========================================================================
    static function int get_active_seed();
        return get_seed();
    endfunction
    
    //==========================================================================
    // Apply the random seed to the process random generator [P0.1]
    //
    // Call once at the start of simulation — from build_phase, or from the
    // tb_top initial block before any randomize() calls.
    //
    // Seeds $urandom (and by extension randomize() for objects created in
    // the same process) with the configured seed.
    //
    // Logs the seed at LOW verbosity for easy grep and replay:
    //   [EVM CRV] Random seed: 12345  (replay: +evm_seed=12345)
    //
    // Note: This is a function (not task) for Vivado class compatibility.
    // Call from a task/initial context for $urandom seeding to take effect.
    //==========================================================================
    static function void set_random_seed();
        int seed;
        seed = get_seed();          // resolve + cache seed
        void'($urandom(seed));      // seed the process random generator
        m_seed_applied = 1;
        $display("[%0t] [EVM CRV] Random seed: %0d  (replay: +evm_seed=%0d)",
                 $time, seed, seed);
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
    // Print all EVM-related plusargs to console
    //==========================================================================
    static function void print_args();
        $display("================================================================================");
        $display("EVM Command-line Arguments:");
        $display("================================================================================");
        $display("  Test Name:    %s", get_test_name("(not specified)"));
        $display("  Verbosity:    %s (%0d)", get_verbosity().name(), get_verbosity());
        $display("  Seed:         %0d%s", get_seed(),
                 m_seed_applied ? " (applied)" : " (not yet applied — call set_random_seed())");
        $display("  Log File:     %s", get_log_file());
        $display("  Timeout:      %0d us", get_timeout());
        $display("  Debug:        %s", has_plusarg("evm_debug") ? "ON" : "OFF");
        $display("  Waveform:     %s", has_plusarg("evm_waveform") ? "ON" : "OFF");
        $display("================================================================================");
    endfunction
    
endclass
