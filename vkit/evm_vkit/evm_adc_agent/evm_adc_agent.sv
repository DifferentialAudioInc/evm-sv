//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_adc_agent
// Description: ADC streaming agent for EVM
//              Extends stream agent for Python script integration
//              Manages ADC behavioral model with signal generation
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_adc_agent extends evm_stream_agent;
    
    //==========================================================================
    // ADC-Specific Configuration
    //==========================================================================
    evm_adc_cfg adc_cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_adc_agent", evm_component parent = null);
        super.new(name, parent);
        
        // Create ADC configuration
        adc_cfg = new();
        
        // Set up Python script paths for signal generation
        cfg.python_gen_script = "evm/python/gen_stimulus.py";
        cfg.python_analyze_script = "evm/python/analyze_spectrum.py";
        cfg.stimulus_file = "stimulus/adc_input.txt";
        cfg.capture_file = "results/adc_output.txt";
        
        set_mode(EVM_ACTIVE);  // ADC agent is active by default
    endfunction
    
    //==========================================================================
    // Build Phase - Initialize agent and generate stimulus
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // Generate stimulus before simulation if enabled
        if (adc_cfg.auto_generate_stimulus) begin
            generate_stimulus();
        end
    endfunction
    
    //==========================================================================
    // Final Phase - Analyze captured data
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        // Analyze captured data if enabled
        if (adc_cfg.auto_analyze_results) begin
            analyze_capture();
        end
    endfunction
    
    //==========================================================================
    // Factory Methods - Create ADC-specific driver/monitor
    //==========================================================================
    
    virtual function evm_monitor#(virtual evm_stream_if) create_monitor(string name);
        evm_adc_monitor mon = new(name, this, adc_cfg);
        return mon;
    endfunction
    
    virtual function evm_driver#(virtual evm_stream_if) create_driver(string name);
        evm_adc_driver drv = new(name, this, adc_cfg);
        return drv;
    endfunction
    
    //==========================================================================
    // Utility Methods - ADC-specific accessors
    //==========================================================================
    
    function evm_adc_driver get_adc_driver();
        evm_adc_driver drv;
        evm_stream_driver sdrv = get_driver();
        if (sdrv != null) $cast(drv, sdrv);
        return drv;
    endfunction
    
    function evm_adc_monitor get_adc_monitor();
        evm_adc_monitor mon;
        evm_stream_monitor smon = get_monitor();
        if (smon != null) $cast(mon, smon);
        return mon;
    endfunction
    
    //==========================================================================
    // ADC Channel Configuration - Convenience Methods
    //==========================================================================
    
    function void configure_channel(int ch_id, real freq_hz, real amplitude, 
                                   real phase_deg = 0.0, real dc_offset = 0.0);
        evm_adc_driver drv = get_adc_driver();
        if (drv != null) begin
            drv.configure_channel(ch_id, freq_hz, amplitude, phase_deg, dc_offset);
            log_info($sformatf("Channel %0d configured: %0.2f Hz, %0.3f Vpp", 
                              ch_id, freq_hz, amplitude), EVM_MED);
        end else begin
            log_warning("ADC driver not available for channel configuration");
        end
    endfunction
    
    function void enable_channel(int ch_id);
        evm_adc_driver drv = get_adc_driver();
        if (drv != null) begin
            drv.enable_channel(ch_id);
            log_info($sformatf("Channel %0d enabled", ch_id), EVM_MED);
        end
    endfunction
    
    function void disable_channel(int ch_id);
        evm_adc_driver drv = get_adc_driver();
        if (drv != null) begin
            drv.disable_channel(ch_id);
            log_info($sformatf("Channel %0d disabled", ch_id), EVM_MED);
        end
    endfunction
    
    function void enable_all_channels();
        evm_adc_driver drv = get_adc_driver();
        if (drv != null) begin
            drv.enable_all_channels();
            log_info("All ADC channels enabled", EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Python Script Integration - Enhanced methods
    //==========================================================================
    
    // Generate ADC stimulus using Python script
    virtual function void generate_adc_stimulus(
        real sample_rate_hz = 100e6,
        int num_samples = 8192,
        int num_channels = 4
    );
        string cmd;
        
        // Build Python command with ADC-specific parameters
        cmd = $sformatf("python %s --sample_rate %0.0f --num_samples %0d --num_channels %0d --output %s",
                       cfg.python_gen_script,
                       sample_rate_hz,
                       num_samples,
                       num_channels,
                       cfg.stimulus_file);
        
        log_info($sformatf("Generating ADC stimulus: %s", cmd), EVM_MED);
        log_info("NOTE: Run this command before simulation", EVM_HIGH);
        
        // User must run manually or use $system(cmd) if enabled
    endfunction
    
    // Analyze ADC capture using Python script
    virtual function void analyze_adc_spectrum(
        real sample_rate_hz = 100e6,
        string output_plot = "results/spectrum.png"
    );
        string cmd;
        
        cmd = $sformatf("python %s --sample_rate %0.0f --input %s --output %s",
                       cfg.python_analyze_script,
                       sample_rate_hz,
                       cfg.capture_file,
                       output_plot);
        
        log_info($sformatf("Analyzing ADC capture: %s", cmd), EVM_MED);
        log_info("NOTE: Run this command after simulation", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    
    function void set_sample_rate(real sample_rate_hz);
        adc_cfg.sample_rate_hz = sample_rate_hz;
        log_info($sformatf("ADC sample rate set to %0.2f MHz", 
                          sample_rate_hz/1e6), EVM_MED);
    endfunction
    
    function void set_num_channels(int num_channels);
        adc_cfg.num_channels = num_channels;
        log_info($sformatf("ADC num_channels set to %0d", num_channels), EVM_MED);
    endfunction
    
    function void enable_auto_generate(bit enable = 1);
        adc_cfg.auto_generate_stimulus = enable;
    endfunction
    
    function void enable_auto_analyze(bit enable = 1);
        adc_cfg.auto_analyze_results = enable;
    endfunction
    
endclass : evm_adc_agent
