//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_target_agent.sv
// Description: SPI target agent — EVM emulates SPI peripheral device(s).
//              DUT is the SPI initiator (master); this agent responds.
//              PRIMARY use case for embedded FPGA verification.
//
//              Contains:
//                - evm_spi_target_driver: drives MISO, responds to DUT's SCLK/CS_N
//                - evm_spi_monitor: observes all bus activity, publishes txns
//                - cfg.devices[]: array of memory-backed device models
//
// Usage:
//   // In env build_phase:
//   cfg = new("spi_cfg");
//   cfg.mode   = EVM_SPI_TARGET;
//   cfg.num_cs = 2;        // two SPI devices
//   cfg.cpol   = 0;
//   cfg.cpha   = 0;        // Mode 0
//   cfg.build_devices();
//
//   // Configure device 0 as 4KB SPI flash
//   cfg.devices[0].mem_size_bytes = 4096;
//   cfg.devices[0].addr_bytes     = 2;
//
//   // Backdoor load data into device 0
//   cfg.devices[0].load_array(0, my_data);
//   // or: cfg.devices[0].mem.write_byte(addr, val);
//
//   // Create and wire agent
//   spi_tgt = new("spi_tgt", this);
//   spi_tgt.cfg = cfg;   // set cfg BEFORE build_phase runs
//
//   // In connect_phase:
//   spi_tgt.set_vif(spi_vif);
//
//   // After simulation: monitor publishes transactions on analysis_port
//   spi_tgt.analysis_port.connect(sb.analysis_imp.get_mailbox());
//
// API — Public Interface:
//   [evm_spi_target_agent extends evm_agent#(virtual evm_spi_if, evm_spi_txn)]
//   cfg             — evm_spi_cfg handle; set before build_phase
//   get_driver()    — returns typed evm_spi_target_driver handle
//   get_monitor()   — returns typed evm_spi_monitor handle
//==============================================================================

class evm_spi_target_agent extends evm_agent#(virtual evm_spi_if, evm_spi_txn);
    
    //==========================================================================
    // Configuration (must be set before build_phase)
    //==========================================================================
    evm_spi_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_target_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // build_phase — create driver + monitor with cfg propagated
    //==========================================================================
    virtual function void build_phase();
        if (cfg == null) begin
            log_fatal("evm_spi_target_agent: cfg must be set before build_phase");
            return;
        end
        if (cfg.devices.size() == 0) begin
            log_warning("evm_spi_target_agent: cfg.build_devices() not called — calling now");
            cfg.build_devices();
        end
        super.build_phase();  // calls create_monitor() and create_driver()
        log_info($sformatf("[SPI TGT AGENT] Built: %s", cfg.convert2string()), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Factory: create monitor with cfg propagated
    //==========================================================================
    virtual function evm_monitor#(virtual evm_spi_if, evm_spi_txn) create_monitor(string name);
        evm_spi_monitor mon;
        mon     = new(name, this);
        mon.cfg = cfg;  // propagate cfg (cfg must be set before build_phase)
        return mon;
    endfunction
    
    //==========================================================================
    // Factory: create target driver with cfg propagated
    //==========================================================================
    virtual function evm_driver#(virtual evm_spi_if, evm_spi_txn, evm_spi_txn) create_driver(string name);
        evm_spi_target_driver drv;
        drv     = new(name, this);
        drv.cfg = cfg;
        return drv;
    endfunction
    
    //==========================================================================
    // Typed accessors
    //==========================================================================
    
    // Return the target driver (cast from evm_driver base)
    function evm_spi_target_driver get_driver();
        evm_spi_target_driver tgt;
        if ($cast(tgt, driver))
            return tgt;
        log_error("evm_spi_target_agent: driver is not evm_spi_target_driver");
        return null;
    endfunction
    
    // Return the monitor (cast from evm_monitor base)
    function evm_spi_monitor get_monitor();
        evm_spi_monitor mon;
        if ($cast(mon, monitor))
            return mon;
        log_error("evm_spi_target_agent: monitor is not evm_spi_monitor");
        return null;
    endfunction
    
    //==========================================================================
    // Backdoor convenience: directly access devices through agent
    //==========================================================================
    function evm_spi_device_model get_device(int cs_index);
        if (cfg != null) return cfg.get_device(cs_index);
        return null;
    endfunction
    
    virtual function string get_type_name();
        return "evm_spi_target_agent";
    endfunction
    
endclass : evm_spi_target_agent
