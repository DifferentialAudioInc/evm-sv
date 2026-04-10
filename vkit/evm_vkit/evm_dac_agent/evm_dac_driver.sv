//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_dac_driver
// Description: DAC driver stub (DAC agent is passive-only)
//              This driver is not used but required for agent structure
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_dac_driver extends evm_stream_driver;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_dac_cfg dac_cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_dac_driver", evm_component parent = null, evm_dac_cfg cfg = null);
        super.new(name, parent, null);
        this.dac_cfg = (cfg != null) ? cfg : new();
    endfunction
    
    //==========================================================================
    // Main Phase - Not used (passive agent)
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        log_info("DAC Driver (passive - not used)", EVM_LOW);
        // DAC is passive, driver does nothing
    endtask
    
endclass : evm_dac_driver
