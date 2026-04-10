//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_dac_agent
// Description: DAC passive monitoring agent for EVM
//              Extends stream agent for Python script integration
//              Captures and analyzes DAC output data (passive-only)
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_dac_agent extends evm_stream_agent;
    
    //==========================================================================
    // DAC-Specific Configuration
    //==========================================================================
    evm_dac_cfg dac_cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_dac_agent", evm_component parent = null);
        super.new(name, parent);
        
        // Create DAC configuration
        dac_cfg = new();
        
        // Set up Python script paths for analysis
        cfg.python_analyze_script = "evm/python/analyze_spectrum.py";
        cfg.capture_file = "results/dac_output.txt";
        
        // DAC agent is always PASSIVE (monitor-only)
        set_mode(EVM_PASSIVE);
        
        log_info("DAC Agent created (PASSIVE mode)", EVM_MED);
    endfunction
    
    //==========================================================================
    // Build Phase - Initialize agent
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // Ensure mode stays passive
        if (mode != EVM_PASSIVE) begin
            log_warning("DAC agent mode changed from PASSIVE - forcing back to PASSIVE");
            set_mode(EVM_PASSIVE);
        end
    endfunction
    
    //==========================================================================
    // Final Phase - Analyze captured data
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        // Analyze captured data if enabled
        if (dac_cfg.auto_analyze_results) begin
            analyze_capture();
        end
    endfunction
    
    //==========================================================================
    // Factory Methods - Create DAC-specific monitor/driver
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_stream_if) create_monitor(string name);
        evm_dac_monitor mon = new(name, this, dac_cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_stream_if) create_driver(string name);
        // Driver stub (not used in passive mode)
        evm_dac_driver drv = new(name, this, dac_cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods - DAC-specific accessors
    //==========================================================================
    
    function evm_dac_driver get_dac_driver();
        evm_dac_driver drv;
        evm_stream_driver sdrv = get_driver();
        if (sdrv != null) $cast(drv, sdrv);
        return drv;
    endfunction
    
    function evm_dac_monitor get_dac_monitor();
        evm_dac_monitor mon;
        evm_stream_monitor smon = get_monitor();
        if (smon != null) $cast(mon, smon);
        return mon;
    endfunction
    
    //==========================================================================
    // Python Script Integration - DAC Analysis
    //==========================================================================
    
    // Analyze DAC output using Python script
    virtual function void analyze_dac_spectrum(
        real sample_rate_hz = 100e6,
        string output_plot = "plots/dac_spectrum.png"
    );
        string cmd;
        
        cmd = $sformatf("python %s --sample_rate %0.0f --input %s --output %s",
                       cfg.python_analyze_script,
                       sample_rate_hz,
                       cfg.capture_file,
                       output_plot);
        
        log_info($sformatf("Analyzing DAC output: %s", cmd), EVM_MED);
        log_info("NOTE: Run this command after simulation", EVM_HIGH);
    endfunction
    
    // Analyze with THD (Total Harmonic Distortion)
    virtual function void analyze_dac_thd(
        real sample_rate_hz = 100e6,
        real fundamental_freq_hz = 1e6
    );
        string cmd;
        
        cmd = $sformatf("python %s --sample_rate %0.0f --input %s --thd --fundamental %0.0f",
                       cfg.python_analyze_script,
                       sample_rate_hz,
                       cfg.capture_file,
                       fundamental_freq_hz);
        
        log_info($sformatf("Analyzing DAC THD: %s", cmd), EVM_MED);
        log_info("NOTE: Run this command after simulation", EVM_HIGH);
    endfunction
    
    // Analyze with SNR (Signal-to-Noise Ratio)
    virtual function void analyze_dac_snr(
        real sample_rate_hz = 100e6
    );
        string cmd;
        
        cmd = $sformatf("python %s --sample_rate %0.0f --input %s --snr",
                       cfg.python_analyze_script,
                       sample_rate_hz,
                       cfg.capture_file);
        
        log_info($sformatf("Analyzing DAC SNR: %s", cmd), EVM_MED);
        log_info("NOTE: Run this command after simulation", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    
    function void set_sample_rate(real sample_rate_hz);
        dac_cfg.sample_rate_hz = sample_rate_hz;
        log_info($sformatf("DAC sample rate set to %0.2f MHz", 
                          sample_rate_hz/1e6), EVM_MED);
    endfunction
    
    function void set_capture_samples(int num_samples);
        dac_cfg.max_capture_samples = num_samples;
        log_info($sformatf("DAC capture samples set to %0d", num_samples), EVM_MED);
    endfunction
    
    function void enable_auto_analyze(bit enable = 1);
        dac_cfg.auto_analyze_results = enable;
    endfunction
    
    function void enable_fft_analysis(bit enable = 1);
        dac_cfg.enable_fft_analysis = enable;
    endfunction
    
    function void enable_thd_analysis(bit enable = 1);
        dac_cfg.enable_thd_analysis = enable;
    endfunction
    
    function void enable_snr_analysis(bit enable = 1);
        dac_cfg.enable_snr_analysis = enable;
    endfunction
    
    function void set_channel_capture(int ch_id, bit enable);
        dac_cfg.set_channel_capture(ch_id, enable);
        log_info($sformatf("DAC channel %0d capture %s", 
                          ch_id, enable ? "enabled" : "disabled"), EVM_LOW);
    endfunction
    
    //==========================================================================
    // Status Methods
    //==========================================================================
    
    function void print_configuration();
        log_info("=== DAC Agent Configuration ===", EVM_HIGH);
        log_info($sformatf("Mode: %s (PASSIVE)", mode.name()), EVM_HIGH);
        log_info($sformatf("Sample Rate: %.1f MHz", dac_cfg.sample_rate_hz/1e6), EVM_HIGH);
        log_info($sformatf("Capture Samples: %0d", dac_cfg.max_capture_samples), EVM_HIGH);
        log_info($sformatf("Auto Analyze: %s", dac_cfg.auto_analyze_results ? "ON" : "OFF"), EVM_HIGH);
        log_info($sformatf("FFT Analysis: %s", dac_cfg.enable_fft_analysis ? "ON" : "OFF"), EVM_HIGH);
        log_info($sformatf("THD Analysis: %s", dac_cfg.enable_thd_analysis ? "ON" : "OFF"), EVM_HIGH);
        log_info($sformatf("SNR Analysis: %s", dac_cfg.enable_snr_analysis ? "ON" : "OFF"), EVM_HIGH);
    endfunction
    
endclass : evm_dac_agent
