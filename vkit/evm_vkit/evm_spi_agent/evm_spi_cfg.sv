//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_cfg.sv
// Description: Configuration class for the EVM SPI agent.
//              Supports 1-8 devices on a single bus via cs_n[7:0].
//              Contains an array of evm_spi_device_model (one per CS line).
//
// API — Public Interface:
//   [evm_spi_cfg]
//   new(name)                     — constructor
//   build_devices()               — create device models (call before build_phase)
//   get_device(cs_index)          — return device model for CS line N
//
//   Backdoor convenience wrappers (delegate to devices[cs]):
//   load_device(cs, base, data[]) — load byte array into device N
//   fill_device(cs, pattern)      — fill device N with pattern
//   clear_device(cs)              — erase device N (fill with 0xFF)
//   load_device_file(cs, addr, f) — load hex file into device N
//   dump_device(cs, addr, n)      — dump device N to log
//
//   Mode enum: EVM_SPI_INITIATOR, EVM_SPI_TARGET, EVM_SPI_PASSIVE
//
// Usage:
//   evm_spi_cfg cfg = new("spi_cfg");
//   cfg.num_cs         = 2;         // two SPI devices on bus
//   cfg.cpol           = 0;
//   cfg.cpha           = 0;         // Mode 0 (most common)
//   cfg.mode           = EVM_SPI_TARGET;
//   // Configure per-device settings BEFORE calling build_devices()
//   // (or configure after and call build_devices again)
//   cfg.build_devices();
//   // Device 0: 4KB SPI flash, 2-byte address
//   cfg.devices[0].mem_size_bytes = 4096;
//   cfg.devices[0].addr_bytes     = 2;
//   // Backdoor load:
//   cfg.load_device(0, 0, firmware_bytes);
//   cfg.clear_device(1);            // erase device 1
//==============================================================================

// Mode enum: declared at package scope so it is visible to both agent classes
typedef enum {
    EVM_SPI_INITIATOR,   // EVM drives SPI bus (EVM=master, DUT=target)
    EVM_SPI_TARGET,      // EVM emulates SPI peripheral(s) (DUT=master, EVM=target)
    EVM_SPI_PASSIVE      // Monitor only — no driving
} evm_spi_mode_e;

class evm_spi_cfg extends evm_object;
    
    //==========================================================================
    // Operating mode
    //==========================================================================
    evm_spi_mode_e mode = EVM_SPI_TARGET;  // default: EVM emulates peripherals
    
    //==========================================================================
    // SPI Protocol Parameters
    //==========================================================================
    int  cpol           = 0;       // clock polarity: 0=idle low, 1=idle high
    int  cpha           = 0;       // clock phase: 0=sample leading, 1=sample trailing
    int  word_size      = 8;       // bits per word (almost always 8)
    bit  lsb_first      = 0;       // bit order: 0=MSB first (standard), 1=LSB first
    int  num_cs         = 1;       // number of devices on bus (1-8)
    
    // Initiator timing (used by evm_spi_initiator_driver)
    int  sclk_period_ns = 100;     // SCLK period in ns → 10 MHz default
    int  cs_setup_ns    = 10;      // CS assert to first SCLK edge (ns)
    int  cs_hold_ns     = 10;      // last SCLK edge to CS deassert (ns)
    int  cs_deassert_ns = 50;      // min CS deassertion time between transfers (ns)
    
    //==========================================================================
    // Device array (one evm_spi_device_model per CS line)
    // Size = num_cs after build_devices() is called.
    // Array is dynamic so num_cs can be set before build_devices().
    //==========================================================================
    evm_spi_device_model devices[];
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // build_devices()
    // Must be called after num_cs is set and before build_phase of the agent.
    // Creates evm_spi_device_model instances for each CS line.
    // Safe to call multiple times — recreates device array each call.
    //==========================================================================
    function void build_devices();
        int i;
        if (num_cs < 1) begin
            log_error("[SPI CFG] num_cs must be >= 1");
            num_cs = 1;
        end
        if (num_cs > 8) begin
            log_warning("[SPI CFG] num_cs > 8 is not supported; clamping to 8");
            num_cs = 8;
        end
        devices = new[num_cs];
        for (i = 0; i < num_cs; i++) begin
            devices[i] = new($sformatf("%s.dev%0d", get_name(), i), i);
        end
        log_info($sformatf("[SPI CFG] Created %0d device model(s), mode=%s cpol=%0d cpha=%0d",
                           num_cs, mode.name(), cpol, cpha), EVM_LOW);
    endfunction
    
    //==========================================================================
    // get_device() — return device model for a given CS index
    //==========================================================================
    function evm_spi_device_model get_device(int cs_index);
        if (devices.size() == 0) begin
            log_error("[SPI CFG] build_devices() has not been called — devices[] is empty");
            return null;
        end
        if (cs_index < 0 || cs_index >= num_cs) begin
            log_error($sformatf("[SPI CFG] CS index %0d out of range (num_cs=%0d)",
                                cs_index, num_cs));
            return null;
        end
        return devices[cs_index];
    endfunction
    
    //==========================================================================
    // Helpers: SPI mode detection
    //==========================================================================
    function bit is_initiator(); return (mode == EVM_SPI_INITIATOR); endfunction
    function bit is_target();    return (mode == EVM_SPI_TARGET);    endfunction
    function bit is_passive();   return (mode == EVM_SPI_PASSIVE);   endfunction
    
    //==========================================================================
    // Sample edge detection (used by drivers and monitor)
    // Returns: 1 = sample on posedge SCLK, 0 = sample on negedge SCLK
    //==========================================================================
    function bit sample_on_posedge();
        // Mode 0 (CPOL=0,CPHA=0): posedge   Mode 3 (CPOL=1,CPHA=1): posedge
        // Mode 1 (CPOL=0,CPHA=1): negedge   Mode 2 (CPOL=1,CPHA=0): negedge
        return ((cpol == 0 && cpha == 0) || (cpol == 1 && cpha == 1));
    endfunction
    
    //==========================================================================
    // Backdoor convenience wrappers
    //==========================================================================
    
    // Load byte array into device cs starting at base_addr
    function void load_device(int cs, int base_addr, byte data[]);
        evm_spi_device_model dev;
        dev = get_device(cs);
        if (dev != null) dev.load_array(base_addr, data);
    endfunction
    
    // Fill device cs entirely with pattern (0xFF = erase)
    function void fill_device(int cs, byte pattern = 8'hFF);
        evm_spi_device_model dev;
        dev = get_device(cs);
        if (dev != null) dev.fill(0, dev.mem_size_bytes, pattern);
    endfunction
    
    // Erase device cs (fill with 0xFF)
    function void clear_device(int cs);
        evm_spi_device_model dev;
        dev = get_device(cs);
        if (dev != null) dev.clear();
    endfunction
    
    // Load hex file into device cs
    function void load_device_file(int cs, int base_addr, string filename);
        evm_spi_device_model dev;
        dev = get_device(cs);
        if (dev != null) dev.load_file_hex(base_addr, filename);
    endfunction
    
    // Dump device cs memory to log
    function void dump_device(int cs, int base_addr = 0, int n_bytes = -1);
        evm_spi_device_model dev;
        dev = get_device(cs);
        if (dev != null) dev.dump(base_addr, n_bytes);
    endfunction
    
    //==========================================================================
    // Utility
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("SPI_CFG: mode=%s cpol=%0d cpha=%0d lsb=%0d num_cs=%0d sclk=%0dns",
                      mode.name(), cpol, cpha, lsb_first, num_cs, sclk_period_ns);
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_spi_cfg";
    endfunction
    
endclass : evm_spi_cfg
