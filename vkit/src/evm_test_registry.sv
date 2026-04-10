//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// File: evm_test_registry.sv
// Description: Test registry for EVM - enables +EVM_TESTNAME plusarg test selection
//
//              Provides a static registry mapping test names to factory creators.
//              Tests register themselves using the `EVM_REGISTER_TEST macro.
//              evm_root::run_test_by_name() reads +EVM_TESTNAME and instantiates.
//
//              Usage in test file (module or package scope):
//
//                // After your test class definition:
//                `EVM_REGISTER_TEST(my_test)
//
//              Usage in tb_top:
//
//                initial begin
//                    evm_root::get().run_test_by_name();
//                end
//
//              Simulation command:
//
//                +EVM_TESTNAME=my_test
//
//              List all registered tests:
//
//                +EVM_LIST_TESTS
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

//==============================================================================
// Abstract Creator Base Class
// Source: Factory Method pattern - enables type-safe test instantiation
// Rationale: SV does not support runtime class instantiation by name.
//            Creator objects encapsulate the "new" call so the registry can
//            create test objects by string name without needing DPI or macros
//            that define classes inside initial blocks.
//==============================================================================
virtual class evm_test_creator;
    
    // Create a test instance with the given name
    pure virtual function evm_base_test create(string name);
    
    // Return the class name this creator produces
    virtual function string get_type_name();
        return "evm_test_creator";
    endfunction
    
endclass : evm_test_creator

//==============================================================================
// Generic Creator - Parameterized to produce any evm_base_test subclass
// Usage: evm_test_creator_t#(my_test) creator = new();
//        evm_test_registry::register("my_test", creator);
//==============================================================================
class evm_test_creator_t #(type T = evm_base_test) extends evm_test_creator;
    
    virtual function evm_base_test create(string name);
        T t = new(name);
        return t;
    endfunction
    
    virtual function string get_type_name();
        return "evm_test_creator_t";
    endfunction
    
endclass : evm_test_creator_t

//==============================================================================
// Test Registry - Static class (never instantiated directly)
// Holds all registered test creators indexed by string name
//==============================================================================
class evm_test_registry;
    
    //==========================================================================
    // Static registry storage (associative array: name → creator)
    //==========================================================================
    local static evm_test_creator m_creators[string];
    
    //==========================================================================
    // Register a test creator
    // Called by the `EVM_REGISTER_TEST macro in initial blocks
    //==========================================================================
    static function void register(string name, evm_test_creator creator);
        if (m_creators.exists(name)) begin
            evm_report_handler::report(EVM_WARNING, "evm_test_registry",
                $sformatf("Test '%s' already registered - overwriting", name));
        end
        m_creators[name] = creator;
        evm_report_handler::report(EVM_DEBUG, "evm_test_registry",
            $sformatf("Registered test: '%s' (total: %0d)", name, m_creators.size()));
    endfunction
    
    //==========================================================================
    // Create a test by name
    // Returns null if name not found (caller must check)
    //==========================================================================
    static function evm_base_test create_test(string name);
        if (!m_creators.exists(name)) begin
            evm_report_handler::report(EVM_ERROR, "evm_test_registry",
                $sformatf("Test '%s' not registered. Available: [%s]",
                          name, get_test_list_str()));
            return null;
        end
        evm_report_handler::report(EVM_LOW, "evm_test_registry",
            $sformatf("Creating test: '%s'", name));
        return m_creators[name].create(name);
    endfunction
    
    //==========================================================================
    // Check if a test is registered
    //==========================================================================
    static function bit test_exists(string name);
        return m_creators.exists(name);
    endfunction
    
    //==========================================================================
    // Get count of registered tests
    //==========================================================================
    static function int get_test_count();
        return m_creators.size();
    endfunction
    
    //==========================================================================
    // Print all registered tests to log
    //==========================================================================
    static function void list_tests();
        string name;
        evm_report_handler::report(EVM_NONE, "evm_test_registry",
            "============================================");
        evm_report_handler::report(EVM_NONE, "evm_test_registry",
            $sformatf("Registered Tests (%0d):", m_creators.size()));
        if (m_creators.first(name)) begin
            do begin
                evm_report_handler::report(EVM_NONE, "evm_test_registry",
                    $sformatf("  %s", name));
            end while (m_creators.next(name));
        end else begin
            evm_report_handler::report(EVM_NONE, "evm_test_registry",
                "  (none registered)");
        end
        evm_report_handler::report(EVM_NONE, "evm_test_registry",
            "============================================");
    endfunction
    
    //==========================================================================
    // Get comma-separated list of test names (for error messages)
    //==========================================================================
    local static function string get_test_list_str();
        string result = "";
        string name;
        if (m_creators.first(name)) begin
            result = name;
            while (m_creators.next(name)) begin
                result = {result, ", ", name};
            end
        end
        return result;
    endfunction
    
endclass : evm_test_registry

//==============================================================================
// Macro: EVM_REGISTER_TEST
// Usage: Place after your test class definition at module/package scope.
//
//   class my_test extends evm_base_test;
//     ...
//   endclass
//   `EVM_REGISTER_TEST(my_test)
//
// This creates a creator object and registers it in an initial block.
// The initial block executes at time 0 before any test code runs.
//==============================================================================
`define EVM_REGISTER_TEST(TNAME) \
    evm_test_creator_t#(TNAME) TNAME``_evm_reg_creator; \
    initial begin \
        TNAME``_evm_reg_creator = new(); \
        evm_test_registry::register(`"TNAME`", TNAME``_evm_reg_creator); \
    end
