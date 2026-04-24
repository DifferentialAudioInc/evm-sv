//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_cfg.sv
// Description: Configuration class for the EVM I2C agent.
//              Supports multiple target devices at different I2C addresses.
//
// API — Public Interface:
//   [evm_i2c_cfg]
//   new(name)                        — constructor
//   add_device(i2c_addr, reg_size)   — add a device at the given 7-bit address
//   get_device(i2c_addr)             — find device by I2C address (null if not found)
//   get_device_by_index(n)           — get nth device in the list
//   num_devices                      — number of configured devices
//
//   Backdoor convenience wrappers:
//   load_device(addr, base, data[])  — load registers into device at addr
//   fill_device(addr, pattern)       — fill all device registers with pattern
//   clear_device(addr)               — clear device registers (fill 0x00)
//
//   Mode enum: EVM_I2C_INITIATOR, EVM_I2C_TARGET, EVM_I2C_PASSIVE
//
// Usage:
//   evm_i2c_cfg cfg = new("i2c_cfg");
//   cfg.mode    = EVM_I2C_TARGET;    // EVM emulates the peripheral device(s)
//   cfg.speed   = EVM_I2C_FAST;      // 400 kHz
//
//   // Add devices at specific I2C addresses
//   cfg.add_device(7'h50, 256);       // EEPROM at address 0x50, 256 bytes
//   cfg.add_device(7'h68, 16);        // RTC at address 0x68, 16 registers
//
//   // Backdoor: preload register values
//   begin
//     byte temp_data[] = '{8'h19, 8'h00}; // 25.0°C in typical sensor format
//     cfg.load_device(7'h48, 0, temp_data);
//   end
//==============================================================================

// Speed enum
typedef enum {
    EVM_I2C_STANDARD  = 100,   // 100 kHz
    EVM_I2C_FAST      = 400,   // 400 kHz
    EVM_I2C_FAST_PLUS = 1000   // 1 MHz
} evm_i2c_speed_e;

// Mode enum
typedef enum {
    EVM_I2C_INITIATOR,  // EVM drives SCL, initiates transactions (DUT=target)
    EVM_I2C_TARGET,     // EVM emulates peripheral(s) (DUT=initiator/master)
    EVM_I2C_PASSIVE     // Monitor only
} evm_i2c_mode_e;

class evm_i2c_cfg extends evm_object;
    
    //==========================================================================
    // Operating mode
    //==========================================================================
    evm_i2c_mode_e mode = EVM_I2C_TARGET;
    
    //==========================================================================
    // I2C Protocol Parameters
    //==========================================================================
    evm_i2c_speed_e speed     = EVM_I2C_STANDARD;  // bus speed
    int             addr_width = 7;                  // 7 or 10-bit addressing
    
    // Initiator timing (derived from speed, adjustable)
    int scl_period_ns  = 10000;  // 100 kHz default: 10 μs period
    int t_hd_sta_ns    = 4000;   // hold time after START
    int t_su_sto_ns    = 4000;   // setup time before STOP
    int t_buf_ns       = 4700;   // bus-free time between STOP and START
    
    //==========================================================================
    // Device list (array of device models at different addresses)
    //==========================================================================
    evm_i2c_device_model devices[$];  // all configured devices
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_i2c_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Set speed and update timing parameters
    //==========================================================================
    function void set_speed(evm_i2c_speed_e spd);
        speed = spd;
        case (spd)
            EVM_I2C_STANDARD: begin
                scl_period_ns = 10000;  // 100 kHz
                t_hd_sta_ns   = 4000;
                t_su_sto_ns   = 4000;
                t_buf_ns      = 4700;
            end
            EVM_I2C_FAST: begin
                scl_period_ns = 2500;   // 400 kHz
                t_hd_sta_ns   = 600;
                t_su_sto_ns   = 600;
                t_buf_ns      = 1300;
            end
            EVM_I2C_FAST_PLUS: begin
                scl_period_ns = 1000;   // 1 MHz
                t_hd_sta_ns   = 260;
                t_su_sto_ns   = 260;
                t_buf_ns      = 500;
            end
        endcase
    endfunction
    
    //==========================================================================
    // add_device() — register a device at a specific I2C address
    //==========================================================================
    function evm_i2c_device_model add_device(bit [6:0] i2c_addr, int reg_size = 256,
                                              int reg_addr_bytes = 1);
        evm_i2c_device_model dev;
        string dev_name;
        dev_name = $sformatf("%s.dev_0x%02x", get_name(), i2c_addr);
        dev = new(dev_name, i2c_addr, reg_size);
        dev.reg_addr_bytes = reg_addr_bytes;
        devices.push_back(dev);
        log_info($sformatf("[I2C CFG] Added device at 0x%02x: %0d bytes, %0d-byte reg addr",
                           i2c_addr, reg_size, reg_addr_bytes), EVM_LOW);
        return dev;
    endfunction
    
    //==========================================================================
    // get_device() — find device by I2C address (null if not found)
    //==========================================================================
    function evm_i2c_device_model get_device(bit [6:0] i2c_addr);
        int i;
        for (i = 0; i < devices.size(); i++) begin
            if (devices[i].matches_addr(i2c_addr))
                return devices[i];
        end
        return null;
    endfunction
    
    //==========================================================================
    // get_device_by_index() — get device by position in list
    //==========================================================================
    function evm_i2c_device_model get_device_by_index(int n);
        if (n >= 0 && n < devices.size())
            return devices[n];
        log_error($sformatf("[I2C CFG] Device index %0d out of range (num_devices=%0d)",
                            n, devices.size()));
        return null;
    endfunction
    
    //==========================================================================
    // num_devices — number of configured devices
    //==========================================================================
    function int get_num_devices();
        return devices.size();
    endfunction
    
    //==========================================================================
    // Mode helpers
    //==========================================================================
    function bit is_initiator(); return (mode == EVM_I2C_INITIATOR); endfunction
    function bit is_target();    return (mode == EVM_I2C_TARGET);    endfunction
    function bit is_passive();   return (mode == EVM_I2C_PASSIVE);   endfunction
    
    //==========================================================================
    // Backdoor convenience wrappers
    //==========================================================================
    function void load_device(bit [6:0] i2c_addr, int base_addr, byte data[]);
        evm_i2c_device_model dev;
        dev = get_device(i2c_addr);
        if (dev != null) dev.load_array(base_addr, data);
        else log_error($sformatf("[I2C CFG] No device at address 0x%02x", i2c_addr));
    endfunction
    
    function void fill_device(bit [6:0] i2c_addr, byte pattern = 8'h00);
        evm_i2c_device_model dev;
        dev = get_device(i2c_addr);
        if (dev != null) dev.fill(0, dev.reg_size_bytes, pattern);
    endfunction
    
    function void clear_device(bit [6:0] i2c_addr);
        evm_i2c_device_model dev;
        dev = get_device(i2c_addr);
        if (dev != null) dev.clear();
    endfunction
    
    virtual function string convert2string();
        return $sformatf("I2C_CFG: mode=%s speed=%0dkHz addr_width=%0d num_devices=%0d",
                         mode.name(), speed, addr_width, devices.size());
    endfunction
    
    virtual function string get_type_name();
        return "evm_i2c_cfg";
    endfunction
    
endclass : evm_i2c_cfg
