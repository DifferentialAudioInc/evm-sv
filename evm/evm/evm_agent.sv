//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_agent
// Description: Parameterized base agent class for EVM
//              Contains monitor and optional driver with virtual interfaces
//              No config database - direct virtual interface assignment
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_agent #(type VIF) extends evm_component;
    
    //==========================================================================
    // Agent Mode
    //==========================================================================
    typedef enum {
        EVM_PASSIVE,  // Monitor only
        EVM_ACTIVE    // Monitor + Driver
    } evm_agent_mode_e;
    
    //==========================================================================
    // Properties
    //==========================================================================
    evm_agent_mode_e           mode;
    evm_monitor#(VIF)          monitor;
    evm_driver#(VIF)           driver;
    VIF                        vif;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_agent", evm_component parent = null);
        super.new(name, parent);
        mode = EVM_ACTIVE;  // Default to active mode
    endfunction
    
    //==========================================================================
    // Set Virtual Interface - Called from test or environment
    //==========================================================================
    function void set_vif(VIF vif_handle);
        if (vif_handle == null) begin
            log_error("Attempting to set null virtual interface");
        end else begin
            this.vif = vif_handle;
            log_info("Virtual interface set", EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Build Phase - Create monitor and driver based on mode
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        if (vif == null) begin
            log_error("Virtual interface not set before build_phase");
        end
        
        // Always create monitor
        monitor = create_monitor("monitor");
        if (monitor == null) begin
            log_error("Failed to create monitor");
        end else begin
            monitor.set_vif(vif);  // Pass virtual interface to monitor
            log_info($sformatf("Created monitor in %s mode", 
                     mode == EVM_ACTIVE ? "ACTIVE" : "PASSIVE"), EVM_MED);
        end
        
        // Create driver only in active mode
        if (mode == EVM_ACTIVE) begin
            driver = create_driver("driver");
            if (driver == null) begin
                log_error("Failed to create driver");
            end else begin
                driver.set_vif(vif);  // Pass virtual interface to driver
                log_info("Created driver (ACTIVE mode)", EVM_MED);
            end
        end else begin
            log_info("No driver created (PASSIVE mode)", EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Connect Phase - Connect agent components
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        // Override to make connections between driver, monitor, sequencer
    endfunction
    
    //==========================================================================
    // Factory Methods - Override in derived agents
    //==========================================================================
    
    // Create monitor - must be overridden
    virtual function evm_monitor#(VIF) create_monitor(string name);
        log_error("create_monitor() must be overridden in derived agent");
        return null;
    endfunction
    
    // Create driver - must be overridden for active agents
    virtual function evm_driver#(VIF) create_driver(string name);
        log_error("create_driver() must be overridden in derived agent");
        return null;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Set agent mode
    function void set_mode(evm_agent_mode_e new_mode);
        mode = new_mode;
        log_info($sformatf("Agent mode set to %s", 
                 mode == EVM_ACTIVE ? "ACTIVE" : "PASSIVE"), EVM_MED);
    endfunction
    
    // Get agent mode
    function evm_agent_mode_e get_mode();
        return mode;
    endfunction
    
    // Check if agent is active
    function bit is_active();
        return (mode == EVM_ACTIVE);
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_agent";
    endfunction
    
endclass : evm_agent
