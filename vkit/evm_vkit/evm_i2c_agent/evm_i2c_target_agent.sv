//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_target_agent.sv
// Description: I2C target agent — EVM emulates I2C peripheral device(s).
//              DUT is the I2C initiator (master). PRIMARY use case.
//
// Usage:
//   evm_i2c_cfg cfg = new("i2c_cfg");
//   cfg.mode = EVM_I2C_TARGET;
//   cfg.set_speed(EVM_I2C_FAST);
//   cfg.add_device(7'h50, 256);      // EEPROM at 0x50
//   cfg.add_device(7'h48, 8);        // temp sensor at 0x48
//   // Preload sensor register:
//   cfg.get_device(7'h48).load_byte(0, 8'h19);  // 25°C
//
//   i2c_tgt = new("i2c_tgt", this);
//   i2c_tgt.cfg = cfg;      // set BEFORE build_phase
//   i2c_tgt.set_vif(i2c_vif);
//
//   // Monitor publishes transactions:
//   i2c_tgt.analysis_port.connect(sb.analysis_imp.get_mailbox());
//==============================================================================

class evm_i2c_target_agent extends evm_agent#(virtual evm_i2c_if, evm_i2c_txn);
    
    evm_i2c_cfg cfg;
    
    function new(string name = "evm_i2c_target_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        if (cfg == null) begin
            log_fatal("evm_i2c_target_agent: cfg must be set before build_phase");
            return;
        end
        super.build_phase();
        log_info($sformatf("[I2C TGT AGENT] Built: %s", cfg.convert2string()), EVM_LOW);
    endfunction
    
    virtual function evm_monitor#(virtual evm_i2c_if, evm_i2c_txn) create_monitor(string name);
        evm_i2c_monitor mon = new(name, this);
        mon.cfg = cfg;
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_i2c_if, evm_i2c_txn, evm_i2c_txn) create_driver(string name);
        evm_i2c_target_driver drv = new(name, this);
        drv.cfg = cfg;
        return drv;
    endfunction
    
    function evm_i2c_target_driver get_driver();
        evm_i2c_target_driver tgt;
        if ($cast(tgt, driver)) return tgt;
        log_error("evm_i2c_target_agent: driver is not evm_i2c_target_driver");
        return null;
    endfunction
    
    function evm_i2c_monitor get_monitor();
        evm_i2c_monitor mon;
        if ($cast(mon, monitor)) return mon;
        log_error("evm_i2c_target_agent: monitor is not evm_i2c_monitor");
        return null;
    endfunction
    
    function evm_i2c_device_model get_device(bit [6:0] i2c_addr);
        if (cfg != null) return cfg.get_device(i2c_addr);
        return null;
    endfunction
    
    virtual function string get_type_name();
        return "evm_i2c_target_agent";
    endfunction
    
endclass : evm_i2c_target_agent
