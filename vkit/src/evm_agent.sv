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
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

virtual class evm_agent #(type VIF, type T = int) extends evm_component;
    
    //==========================================================================
    // Agent Mode
    //==========================================================================
    typedef enum {
        EVM_PASSIVE,  // Monitor only
        EVM_ACTIVE    // Monitor + Driver
    } evm_agent_mode_e;
    
    //==========================================================================
    // Properties
    // Source: UVM agent structure (uvm_agent has monitor, driver, sequencer)
    // Rationale: Agent encapsulates all components for one interface:
    //            - Monitor (PASSIVE & ACTIVE): Observes interface activity
    //            - Driver (ACTIVE only): Drives stimulus to interface  
    //            - Sequencer (ACTIVE only): Manages sequence execution
    // Note: T parameter added for transaction type (NEW in this implementation)
    // UVM Equivalent: uvm_agent contains monitor, driver, sequencer
    //==========================================================================
    evm_agent_mode_e           mode;
    evm_monitor#(VIF, T)       monitor;
    evm_driver#(VIF, T, T)     driver;
    evm_sequencer#(T, T)       sequencer;
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
        
        // Create driver and sequencer only in active mode
        if (mode == EVM_ACTIVE) begin
            driver = create_driver("driver");
            if (driver == null) begin
                log_error("Failed to create driver");
            end else begin
                driver.set_vif(vif);  // Pass virtual interface to driver
                log_info("Created driver (ACTIVE mode)", EVM_MED);
            end
            
            sequencer = create_sequencer("sequencer");
            if (sequencer == null) begin
                log_error("Failed to create sequencer");
            end else begin
                log_info("Created sequencer (ACTIVE mode)", EVM_MED);
            end
        end else begin
            log_info("No driver/sequencer created (PASSIVE mode)", EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Connect Phase - Connect agent components
    // Source: UVM pattern - agent connects its internal components
    // Rationale: CRITICAL connection that makes sequences work!
    //            - Driver's seq_item_port must connect to sequencer's export
    //            - This connection allows driver to pull sequence items
    //            - Without this, driver can't get stimulus from sequences
    // Auto-connection: Happens automatically in ACTIVE mode
    // UVM Equivalent: driver.seq_item_port.connect(sequencer.seq_item_export)
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        
        // Connect driver to sequencer in active mode
        if (mode == EVM_ACTIVE && driver != null && sequencer != null) begin
            if (driver.seq_item_port != null && sequencer.seq_item_export != null) begin
                driver.seq_item_port.connect(
                    sequencer.seq_item_export.get_req_fifo(),
                    sequencer.seq_item_export.get_rsp_fifo()
                );
                log_info("Connected driver.seq_item_port to sequencer.seq_item_export", EVM_MEDIUM);
            end
        end
    endfunction
    
    //==========================================================================
    // Factory Methods - Override in derived agents
    // Source: EVM pattern (simplified from UVM factory)
    // Rationale: Derived agents must create protocol-specific components:
    //            - create_monitor() returns YOUR custom monitor
    //            - create_driver() returns YOUR custom driver
    //            - create_sequencer() has default implementation
    // Why: Allows base agent to manage lifecycle while derived class
    //      controls which specific types get created
    // EVM Note: Direct instantiation, not UVM factory (too complex for embedded)
    //==========================================================================
    
    // Create monitor - must be overridden
    virtual function evm_monitor#(VIF, T) create_monitor(string name);
        log_error("create_monitor() must be overridden in derived agent");
        return null;
    endfunction
    
    // Create driver - must be overridden for active agents
    virtual function evm_driver#(VIF, T, T) create_driver(string name);
        log_error("create_driver() must be overridden in derived agent");
        return null;
    endfunction
    
    // Create sequencer - can be overridden for custom sequencers
    virtual function evm_sequencer#(T, T) create_sequencer(string name);
        // Default implementation creates standard sequencer
        return new(name, this);
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
