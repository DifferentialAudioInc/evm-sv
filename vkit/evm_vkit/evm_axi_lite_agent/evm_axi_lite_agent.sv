//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_master_agent
// Description: AXI4-Lite Master Agent for EVM
//              Complete agent for CSR register access.
//              Updated 2026-04-09: Added optional sequencer support and
//              AXI-Lite predictor convenience method.
//
//              Direct API (original - unchanged for backward compatibility):
//                agent.write(addr, data, strb, resp)
//                agent.read(addr, data, resp)
//                agent.write_check(addr, data)
//                agent.read_check(addr, data)
//                agent.rmw(addr, mask, value)
//                agent.poll(addr, mask, expected, timeout, success)
//
//              Sequencer-based API (new - enabled via cfg.use_sequencer):
//                agent.sequencer.execute_sequence(my_seq)
//                driver.seq_item_port.connect(sequencer.seq_item_export...)
//
//              Analysis port connections:
//                agent.monitor.ap_write → scoreboard / predictor
//                agent.monitor.ap_read  → scoreboard
//                agent.monitor.ap_aw    → protocol checker
//                ...etc
//
// Author: Eric Dyer
// Date: 2026-03-05
// Updated: 2026-04-09 - Added sequencer support, updated monitor reference
//==============================================================================

class evm_axi_lite_master_agent extends evm_agent#(virtual evm_axi_lite_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi_lite_cfg cfg;
    
    //==========================================================================
    // Optional Sequencer (enabled by cfg.use_sequencer)
    //==========================================================================
    evm_sequencer#(evm_csr_item) sequencer;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_master_agent", 
                 evm_component parent = null);
        super.new(name, parent);
        set_mode(EVM_ACTIVE);      // Active by default
        cfg = new();               // Create default configuration
    endfunction
    
    //==========================================================================
    // Build Phase - Create sub-components
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();  // Creates driver and monitor via factory methods
        
        // Create sequencer if configured
        if (cfg.use_sequencer) begin
            sequencer = new("sequencer", this);
            log_info("AXI-Lite agent: sequencer enabled", EVM_MEDIUM);
        end
    endfunction
    
    //==========================================================================
    // Connect Phase - Wire sequencer to driver if enabled
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        
        // Connect sequencer to driver if both exist
        if (cfg.use_sequencer && sequencer != null && driver != null) begin
            driver.seq_item_port.connect(
                sequencer.seq_item_export.get_req_fifo(),
                sequencer.seq_item_export.get_rsp_fifo()
            );
            log_info("AXI-Lite agent: sequencer connected to driver", EVM_MEDIUM);
        end
    endfunction
    
    //==========================================================================
    // Factory Methods - Create typed driver and monitor
    //==========================================================================
    virtual function evm_monitor#(virtual evm_axi_lite_if) create_monitor(string name);
        evm_axi_lite_monitor mon = new(name, this, cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_axi_lite_if) create_driver(string name);
        evm_axi_lite_master_driver drv = new(name, this, cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Typed Accessors
    //==========================================================================
    function evm_axi_lite_master_driver get_driver();
        evm_axi_lite_master_driver drv;
        if (driver != null) $cast(drv, driver);
        return drv;
    endfunction
    
    function evm_axi_lite_monitor get_monitor();
        evm_axi_lite_monitor mon;
        if (monitor != null) $cast(mon, monitor);
        return mon;
    endfunction
    
    //==========================================================================
    // Direct API - Write (backward compatible)
    //==========================================================================
    task write(input  logic [31:0] addr, 
               input  logic [31:0] data,
               input  logic [3:0]  strb = 4'b1111,
               output logic [1:0]  resp);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.write(addr, data, strb, resp);
        end
    endtask
    
    task read(input  logic [31:0] addr,
              output logic [31:0] data,
              output logic [1:0]  resp);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.read(addr, data, resp);
        end
    endtask
    
    task write_check(input logic [31:0] addr, 
                     input logic [31:0] data,
                     input logic [3:0]  strb = 4'b1111);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.write_check(addr, data, strb);
        end
    endtask
    
    task read_check(input  logic [31:0] addr,
                    output logic [31:0] data);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.read_check(addr, data);
        end
    endtask
    
    task rmw(input logic [31:0] addr,
             input logic [31:0] mask,
             input logic [31:0] value);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.rmw(addr, mask, value);
        end
    endtask
    
    task poll(input  logic [31:0] addr,
              input  logic [31:0] mask,
              input  logic [31:0] expected,
              input  int          timeout_cycles = 1000,
              output bit          success);
        evm_axi_lite_master_driver axi_drv = get_driver();
        if (axi_drv != null) begin
            axi_drv.poll(addr, mask, expected, timeout_cycles, success);
        end
    endtask
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_axi_lite_master_agent";
    endfunction
    
endclass : evm_axi_lite_master_agent
