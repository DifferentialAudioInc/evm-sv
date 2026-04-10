//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_stream_agent
// Description: Base streaming agent - combines driver and monitor
//              Provides Python script integration
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

class evm_stream_agent extends evm_agent#(virtual evm_stream_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_stream_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_stream_agent", evm_component parent = null);
        super.new(name, parent);
        cfg = new();
    endfunction
    
    //==========================================================================
    // Factory Methods
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_stream_if) create_monitor(string name);
        evm_stream_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_stream_if) create_driver(string name);
        evm_stream_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Python Integration
    //==========================================================================
    
    // Generate stimulus before simulation
    function void generate_stimulus();
        string cmd = cfg.get_python_gen_cmd();
        if (cmd != "") begin
            log_info($sformatf("Generating stimulus: %s", cmd), EVM_MED);
            // In real implementation, would call $system(cmd)
            // For now, user must run manually before simulation
        end
    endfunction
    
    // Analyze captured data after simulation
    function void analyze_capture();
        string cmd = cfg.get_python_analyze_cmd();
        if (cmd != "") begin
            log_info($sformatf("Analysis command: %s", cmd), EVM_MED);
            // In real implementation, would call $system(cmd)
            // For now, user must run manually after simulation
        end
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    function evm_stream_driver get_driver();
        evm_stream_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_stream_monitor get_monitor();
        evm_stream_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
endclass : evm_stream_agent
