//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_initiator_agent.sv
// Description: SPI initiator agent — EVM acts as the SPI bus master.
//              DUT is the SPI target; EVM drives SCLK, MOSI, CS_N.
//
//              Use case: DUT has an SPI target (slave) interface and EVM
//              needs to send commands to it — e.g., a DUT with an SPI
//              control register interface.
//
//              Contains:
//                - evm_spi_initiator_driver: drives SCLK, MOSI, CS_N
//                - evm_spi_monitor: observes all bus activity
//
//              Direct API via driver handle (most common — no sequencer needed):
//                agent.get_driver().transfer(mosi, miso, cs)
//                agent.get_driver().write_mem(cs, addr, n, data)
//                agent.get_driver().read_mem(cs, addr, n, count, data)
//
// Usage:
//   evm_spi_cfg cfg = new("spi_cfg");
//   cfg.mode           = EVM_SPI_INITIATOR;
//   cfg.cpol           = 0;
//   cfg.cpha           = 0;
//   cfg.sclk_period_ns = 100;   // 10 MHz
//   cfg.num_cs         = 1;
//   cfg.build_devices();        // not strictly needed for initiator but harmless
//
//   spi_init = new("spi_init", this);
//   spi_init.cfg = cfg;         // set BEFORE build_phase
//
//   // In connect_phase:
//   spi_init.set_vif(spi_vif);
//
//   // In main_phase (direct API):
//   bit [7:0] write_data[] = '{8'hAB, 8'hCD};
//   spi_init.get_driver().write_mem(0, 32'h0010, 1, write_data);
//   spi_init.get_driver().read_mem(0, 32'h0010, 1, 2, read_data);
//
// API — Public Interface:
//   [evm_spi_initiator_agent extends evm_agent#(virtual evm_spi_if, evm_spi_txn)]
//   cfg             — evm_spi_cfg handle; set before build_phase
//   get_driver()    — returns typed evm_spi_initiator_driver handle
//   get_monitor()   — returns typed evm_spi_monitor handle
//==============================================================================

class evm_spi_initiator_agent extends evm_agent#(virtual evm_spi_if, evm_spi_txn);
    
    //==========================================================================
    // Configuration (must be set before build_phase)
    //==========================================================================
    evm_spi_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_initiator_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // build_phase — create driver + monitor with cfg propagated
    //==========================================================================
    virtual function void build_phase();
        if (cfg == null) begin
            log_fatal("evm_spi_initiator_agent: cfg must be set before build_phase");
            return;
        end
        super.build_phase();  // calls create_monitor() and create_driver()
        log_info($sformatf("[SPI INIT AGENT] Built: %s", cfg.convert2string()), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Factory: create monitor with cfg propagated
    //==========================================================================
    virtual function evm_monitor#(virtual evm_spi_if, evm_spi_txn) create_monitor(string name);
        evm_spi_monitor mon;
        mon     = new(name, this);
        mon.cfg = cfg;
        return mon;
    endfunction
    
    //==========================================================================
    // Factory: create initiator driver with cfg propagated
    //==========================================================================
    virtual function evm_driver#(virtual evm_spi_if, evm_spi_txn, evm_spi_txn) create_driver(string name);
        evm_spi_initiator_driver drv;
        drv     = new(name, this);
        drv.cfg = cfg;
        return drv;
    endfunction
    
    //==========================================================================
    // Typed accessors
    //==========================================================================
    
    // Return the initiator driver (cast from evm_driver base)
    function evm_spi_initiator_driver get_driver();
        evm_spi_initiator_driver init_drv;
        if ($cast(init_drv, driver))
            return init_drv;
        log_error("evm_spi_initiator_agent: driver is not evm_spi_initiator_driver");
        return null;
    endfunction
    
    // Return the monitor (cast from evm_monitor base)
    function evm_spi_monitor get_monitor();
        evm_spi_monitor mon;
        if ($cast(mon, monitor))
            return mon;
        log_error("evm_spi_initiator_agent: monitor is not evm_spi_monitor");
        return null;
    endfunction
    
    virtual function string get_type_name();
        return "evm_spi_initiator_agent";
    endfunction
    
endclass : evm_spi_initiator_agent
