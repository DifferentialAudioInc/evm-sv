//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_uart_agent.sv
// Description: Unified UART agent — combines TX driver and RX monitor.
//              Unlike SPI/I2C, UART is bidirectional with no addressing,
//              so a single agent handles both TX (driver) and RX (monitor).
//
// Usage:
//   evm_uart_cfg cfg = new("uart_cfg");
//   cfg.baud_rate = 115200;
//   cfg.data_bits = 8;
//   cfg.parity    = EVM_UART_PARITY_NONE;
//   cfg.stop_bits = 1.0;
//   cfg.compute_timing();
//
//   uart_agent = new("uart", this);
//   uart_agent.cfg = cfg;     // set BEFORE build_phase
//   uart_agent.set_vif(uart_vif);
//
//   // TX (from test or sequence):
//   uart_agent.get_driver().send_string("Hello DUT\r\n");
//   uart_agent.get_driver().send_bytes(hex_data);
//
//   // RX (from scoreboard via analysis_port):
//   uart_agent.analysis_port.connect(sb.analysis_imp.get_mailbox());
//   uart_agent.get_monitor().ap_err.connect(err_monitor.get_mailbox());
//
// API — Public Interface:
//   [evm_uart_agent extends evm_agent#(virtual evm_uart_if, evm_uart_txn)]
//   cfg              — evm_uart_cfg; set before build_phase
//   get_driver()     — typed evm_uart_driver (TX)
//   get_monitor()    — typed evm_uart_monitor (RX; has ap_err port)
//==============================================================================

class evm_uart_agent extends evm_agent#(virtual evm_uart_if, evm_uart_txn);
    
    evm_uart_cfg cfg;
    
    function new(string name = "evm_uart_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        if (cfg == null) begin
            log_fatal("evm_uart_agent: cfg must be set before build_phase");
            return;
        end
        super.build_phase();
        log_info($sformatf("[UART AGENT] Built: %s", cfg.convert2string()), EVM_LOW);
    endfunction
    
    virtual function evm_monitor#(virtual evm_uart_if, evm_uart_txn) create_monitor(string name);
        evm_uart_monitor mon = new(name, this);
        mon.cfg = cfg;
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_uart_if, evm_uart_txn, evm_uart_txn) create_driver(string name);
        evm_uart_driver drv = new(name, this);
        drv.cfg = cfg;
        return drv;
    endfunction
    
    //==========================================================================
    // Typed accessors
    //==========================================================================
    function evm_uart_driver get_driver();
        evm_uart_driver drv;
        if ($cast(drv, driver)) return drv;
        log_error("evm_uart_agent: driver is not evm_uart_driver");
        return null;
    endfunction
    
    function evm_uart_monitor get_monitor();
        evm_uart_monitor mon;
        if ($cast(mon, monitor)) return mon;
        log_error("evm_uart_agent: monitor is not evm_uart_monitor");
        return null;
    endfunction
    
    //==========================================================================
    // Convenience TX wrappers (delegate to driver)
    //==========================================================================
    task send_byte(input bit [8:0] data);
        evm_uart_driver drv = get_driver();
        if (drv != null) drv.send_byte(data);
    endtask
    
    task send_string(input string str);
        evm_uart_driver drv = get_driver();
        if (drv != null) drv.send_string(str);
    endtask
    
    task send_bytes(input bit [7:0] data[]);
        evm_uart_driver drv = get_driver();
        if (drv != null) drv.send_bytes(data);
    endtask
    
    virtual function string get_type_name();
        return "evm_uart_agent";
    endfunction
    
endclass : evm_uart_agent
