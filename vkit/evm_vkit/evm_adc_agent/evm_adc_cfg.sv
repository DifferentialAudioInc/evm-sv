//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_adc_cfg
// Description: Configuration class for ADC agent with Python integration
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_adc_cfg extends evm_object;
    
    //==========================================================================
    // Basic ADC Parameters
    //==========================================================================
    real sample_rate_hz = 100e6;           // Sample rate (default 100 MSPS)
    int num_channels = 4;                  // Number of ADC channels
    int resolution_bits = 12;              // ADC resolution
    
    // Signal generation defaults
    real default_sine_freq_hz = 1.0e6;     // Default sine frequency (1 MHz)
    real default_sine_amplitude = 2047.0;  // Default amplitude (full scale 12-bit)
    real default_sine_phase_deg = 0.0;     // Default phase offset
    real default_sine_dc_offset = 0.0;     // Default DC offset
    
    // Channel enables
    bit ch0_enable = 1;
    bit ch1_enable = 1;
    bit ch2_enable = 1;
    bit ch3_enable = 1;
    
    //==========================================================================
    // Python Script Integration
    //==========================================================================
    
    // Automatic Python script execution
    bit auto_generate_stimulus = 0;        // Auto-run gen_stimulus.py before sim
    bit auto_analyze_results = 0;          // Auto-run analyze_spectrum.py after sim
    
    // Stimulus generation parameters
    int num_stimulus_samples = 8192;       // Number of samples to generate
    string stimulus_format = "hex";        // Format: "hex", "decimal", "binary"
    
    // Analysis parameters
    bit enable_fft_analysis = 1;           // Enable FFT analysis
    bit generate_plots = 1;                // Generate spectrum plots
    string plot_format = "png";            // Plot format: "png", "pdf", "svg"
    
    //==========================================================================
    // File Paths
    //==========================================================================
    string stimulus_dir = "stimulus";
    string results_dir = "results";
    string plots_dir = "plots";
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_adc_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Get channel enable status
    function bit is_channel_enabled(int ch_id);
        case (ch_id)
            0: return ch0_enable;
            1: return ch1_enable;
            2: return ch2_enable;
            3: return ch3_enable;
            default: return 0;
        endcase
    endfunction
    
    // Enable/disable channel
    function void set_channel_enable(int ch_id, bit enable);
        case (ch_id)
            0: ch0_enable = enable;
            1: ch1_enable = enable;
            2: ch2_enable = enable;
            3: ch3_enable = enable;
        endcase
    endfunction
    
    // Enable all channels
    function void enable_all_channels();
        ch0_enable = 1;
        ch1_enable = 1;
        ch2_enable = 1;
        ch3_enable = 1;
    endfunction
    
    // Disable all channels
    function void disable_all_channels();
        ch0_enable = 0;
        ch1_enable = 0;
        ch2_enable = 0;
        ch3_enable = 0;
    endfunction
    
    // Get number of enabled channels
    function int get_num_enabled_channels();
        return ch0_enable + ch1_enable + ch2_enable + ch3_enable;
    endfunction
    
    // Calculate sample period in nanoseconds
    function real get_sample_period_ns();
        return 1.0e9 / sample_rate_hz;
    endfunction
    
    // Calculate nyquist frequency
    function real get_nyquist_freq_hz();
        return sample_rate_hz / 2.0;
    endfunction
    
    // Check if frequency is within nyquist limit
    function bit is_freq_valid(real freq_hz);
        return (freq_hz <= get_nyquist_freq_hz());
    endfunction
    
    virtual function string convert2string();
        string s;
        s = $sformatf("%s: %.1f MSPS, %0d-bit, %0d channels", 
                     super.convert2string(), 
                     sample_rate_hz/1e6, 
                     resolution_bits,
                     num_channels);
        if (auto_generate_stimulus)
            s = {s, ", auto-gen"};
        if (auto_analyze_results)
            s = {s, ", auto-analyze"};
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_adc_cfg";
    endfunction
    
endclass : evm_adc_cfg
