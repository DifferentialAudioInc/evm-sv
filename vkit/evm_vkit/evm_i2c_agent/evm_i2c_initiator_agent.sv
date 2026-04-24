//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_initiator_agent.sv
// Description: I2C initiator agent — EVM acts as the I2C bus master.
//              DUT is the I2C target.
//
// Usage:
//   evm_i2c_cfg cfg = new("i2c_cfg");
//   cfg.mode = EVM_I2C_INITIATOR;
//   cfg.set_speed(EVM_I2C_STANDARD);
//
//   i2c_init = new("i2c_init", this);
//   i2c_init.cfg = cfg;
//   i2c_init.set_vif(i2c_vif);
//
//   // Direct API in main_phase:
//   begin
//     bit [7:0] d[] = '{8'h42};
//     i2c_init.get_driver().write(7'h50, 16'h0010, 1, d);
//   end
//   i2c_init.get_driver().read_byte(7'h50, 16'h0010, rb);
//==============================================================================

class evm_i2c_initiator_agent extends evm_agent#(virtual evm_i2c_if, evm_i2c_txn);
    
    evm_i2c_cfg cfg;
    
    function new(string name = "evm_i2c_initiator_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        if (cfg == null) begin
            log_fatal("evm_i2c_initiator_agent: cfg must be set before build_phase");
            return;
        end
        super.build_phase();
        log_info($sformatf("[I2C INIT AGENT] Built: %s", cfg.convert2string()), EVM_LOW);
    endfunction
    
    virtual function evm_monitor#(virtual evm_i2c_if, evm_i2c_txn) create_monitor(string name);
        evm_i2c_monitor mon = new(name, this);
        mon.cfg = cfg;
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_i2c_if, evm_i2c_txn, evm_i2c_txn) create_driver(string name);
        evm_i2c_initiator_driver drv = new(name, this);
        drv.cfg = cfg;
        return drv;
    endfunction
    
    function evm_i2c_initiator_driver get_driver();
        evm_i2c_initiator_driver init_drv;
        if ($cast(init_drv, driver)) return init_drv;
        log_error("evm_i2c_initiator_agent: driver is not evm_i2c_initiator_driver");
        return null;
    endfunction
    
    function evm_i2c_monitor get_monitor();
        evm_i2c_monitor mon;
        if ($cast(mon, monitor)) return mon;
        log_error("evm_i2c_initiator_agent: monitor is not evm_i2c_monitor");
        return null;
    endfunction
    
    virtual function string get_type_name();
        return "evm_i2c_initiator_agent";
    endfunction
    
endclass : evm_i2c_initiator_agent
