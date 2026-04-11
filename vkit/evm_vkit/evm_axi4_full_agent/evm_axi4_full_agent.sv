//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi4_full_master_agent
// Description: AXI4 Full Master Agent for EVM
//              Bundles driver, monitor, and optional sequencer into one object.
//              Provides both direct-call API and sequencer-based API.
//
//              Active mode (is_active=1, default):
//                - Has driver + sequencer + monitor
//                - Can initiate write/read burst transactions
//
//              Passive mode (is_active=0):
//                - Has monitor only
//                - Suitable for monitoring a bus you don't drive
//
//              Usage (active):
//                // In env build_phase:
//                axi4_agent = new("axi4_agent", this, cfg);
//                axi4_agent.set_vif(axi4_vif);
//
//                // Direct calls in test:
//                axi4_agent.write_single(32'h1000, 64'hDEAD_BEEF, resp);
//                axi4_agent.read_burst(32'h2000, data, 8'h7, resp);  // 8-beat burst
//
//                // Connect scoreboard to composite port:
//                axi4_agent.monitor.ap_write.connect(sb.analysis_imp.get_mailbox());
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

class evm_axi4_full_master_agent extends evm_component;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi4_full_cfg cfg;
    
    //==========================================================================
    // Sub-components
    //==========================================================================
    evm_axi4_full_master_driver  driver;
    evm_axi4_full_monitor        monitor;
    
    //==========================================================================
    // Virtual Interface
    //==========================================================================
    virtual evm_axi4_full_if vif;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi4_full_master_agent", 
                 evm_component parent = null,
                 evm_axi4_full_cfg cfg = null);
        super.new(name, parent);
        // Avoid 'new' in ternary — xvlog compatibility
        if (cfg != null) this.cfg = cfg;
        else this.cfg = new("cfg");
    endfunction
    
    //==========================================================================
    // Build Phase - Create driver and monitor
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // Always create monitor (active and passive modes)
        monitor = new("monitor", this, cfg);
        
        // Create driver only in active mode
        if (cfg.is_active) begin
            driver = new("driver", this, cfg);
        end
    endfunction
    
    //==========================================================================
    // Connect Phase - Pass VIF to sub-components
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        
        if (vif == null) begin
            log_warning("AXI4 agent: VIF not set in connect_phase - check set_vif() call");
            return;
        end
        
        monitor.set_vif(vif);
        if (driver != null) driver.set_vif(vif);
    endfunction
    
    //==========================================================================
    // Set Virtual Interface - Call this before simulation starts
    //==========================================================================
    function void set_vif(virtual evm_axi4_full_if vif_handle);
        this.vif = vif_handle;
        // Also propagate immediately if already built
        if (monitor != null) monitor.set_vif(vif_handle);
        if (driver  != null) driver.set_vif(vif_handle);
        log_info("AXI4 Full agent: VIF set", EVM_MEDIUM);
    endfunction
    
    //==========================================================================
    // Type-cast accessors
    //==========================================================================
    function evm_axi4_full_master_driver get_driver();
        return driver;
    endfunction
    
    function evm_axi4_full_monitor get_monitor();
        return monitor;
    endfunction
    
    //==========================================================================
    // Direct API - Write Single Beat
    //==========================================================================
    task write_single(
        input  logic [31:0] addr,
        input  logic [63:0] data,
        output logic [1:0]  resp,
        input  logic [7:0]  id   = 8'h00,
        input  logic [7:0]  strb = 8'hFF
    );
        if (driver == null) begin
            log_error("AXI4 agent write_single: no driver (passive mode?)");
            return;
        end
        driver.write_single(addr, data, id, strb, resp);
    endtask
    
    //==========================================================================
    // Direct API - Write Burst
    //==========================================================================
    task write_burst(
        input  logic [31:0] addr,
        input  logic [63:0] data[],
        output logic [1:0]  resp,
        input  logic [7:0]  id         = 8'h00,
        input  logic [7:0]  len        = 8'h00,
        input  logic [2:0]  size       = 3'b011,
        input  logic [1:0]  burst_type = 2'b01
    );
        logic [7:0] strb[];
        if (driver == null) begin
            log_error("AXI4 agent write_burst: no driver (passive mode?)");
            return;
        end
        // Default: all bytes valid
        strb = new[data.size()];
        foreach (strb[i]) strb[i] = '1;
        driver.write_burst(addr, data, strb, len, size, burst_type, id, resp);
    endtask
    
    //==========================================================================
    // Direct API - Read Single Beat
    //==========================================================================
    task read_single(
        input  logic [31:0] addr,
        output logic [63:0] data,
        output logic [1:0]  resp,
        input  logic [7:0]  id = 8'h00
    );
        if (driver == null) begin
            log_error("AXI4 agent read_single: no driver (passive mode?)");
            return;
        end
        driver.read_single(addr, data, id, resp);
    endtask
    
    //==========================================================================
    // Direct API - Read Burst
    //==========================================================================
    task read_burst(
        input  logic [31:0] addr,
        output logic [63:0] data[],
        input  logic [7:0]  len        = 8'h00,
        output logic [1:0]  resp[],
        input  logic [7:0]  id         = 8'h00,
        input  logic [2:0]  size       = 3'b011,
        input  logic [1:0]  burst_type = 2'b01
    );
        if (driver == null) begin
            log_error("AXI4 agent read_burst: no driver (passive mode?)");
            return;
        end
        driver.read_burst(addr, data, len, size, burst_type, id, resp);
    endtask
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_axi4_full_master_agent";
    endfunction
    
endclass : evm_axi4_full_master_agent
