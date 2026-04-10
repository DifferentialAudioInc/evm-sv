//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_env
// Description: Base environment class for EVM
//              Provides the standard environment layer between test and agents.
//              Derive from this class to build your verification environment.
//
//              Environment hierarchy:
//                evm_base_test
//                  └── evm_env          ← this class
//                        ├── agent_a
//                        ├── agent_b
//                        └── evm_scoreboard
//
//              Usage:
//                class my_env extends evm_env;
//                    my_agent    agent;
//                    my_scoreboard sb;
//
//                    virtual function void build_phase();
//                        super.build_phase();
//                        agent = new("agent", this);
//                        sb    = new("sb", this);
//                    endfunction
//
//                    virtual function void connect_phase();
//                        super.connect_phase();
//                        agent.monitor.ap_write.connect(sb.analysis_imp.get_mailbox());
//                    endfunction
//                endclass
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

virtual class evm_env extends evm_component;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_env", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // End of Elaboration - Print topology automatically
    // Rationale: Environments always benefit from a topology dump at start.
    //            Saves the user from manually calling print_topology() in tests.
    //            Override and call super first to preserve this behavior.
    //==========================================================================
    virtual function void end_of_elaboration_phase();
        super.end_of_elaboration_phase();
        log_info($sformatf("=== Environment Topology: %s ===", get_full_name()), EVM_LOW);
        print_topology();
        log_info("===========================================", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_env";
    endfunction
    
endclass : evm_env
