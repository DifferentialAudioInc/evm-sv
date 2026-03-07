//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_dac_cfg
// Description: Configuration class for DAC agent (passive monitoring)
//              Supports Python analysis of captured DAC output
// Author: Engineering Team
// Date: 2026-03-07
//==============================================================================

class evm_dac_cfg extends evm_object;
    
    //==========================================================================
    // Basic DAC Parameters
    //==========================================================================
    real sample_rate_hz = 100e6;           // Sample rate (default 100 MSPS)
    int num_channels = 4;                  // Number of DAC channels
    int resolution_bits = 12;              // DAC resolution
    
    //==========================================================================
    // Capture Configuration
    //==========================================================================
    bit enable_capture = 1;                // Enable data capture
    int max_capture_samples = 16384;       // Maximum samples to capture
    bit capture_all_channels = 1;          // Capture all enabled channels
    
    // Per-channel capture enable
    bit ch0_capture = 1;
    bit ch1_capture = 1;
    bit ch2_capture = 1;
    bit ch3_capture = 1;
    
    //==========================================================================
    // Python Script Integration
    //==========================================================================
    
    // Automatic Python script execution
    bit auto_analyze_results = 1;          // Auto-run analysis after sim
    
    // Analysis parameters
    bit enable_fft_analysis = 1;           // Enable FFT analysis
    bit enable_thd_analysis = 1;           // Enable THD (total harmonic distortion)
    bit enable_snr_analysis = 1;           // Enable SNR (signal-to-noise ratio)
    bit generate_plots = 1;                // Generate spectrum plots
    string plot_format = "png";            // Plot format: "png", "pdf", "svg"
    
    //==========================================================================
    // File Paths
    //==========================================================================
    string capture_dir = "results";
    string plots_dir = "plots";
    string report_dir = "reports";
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_dac_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Get channel capture status
    function bit is_channel_capture_enabled(int ch_id);
        if (!capture_all_channels) return 0;
        case (ch_id)
            0: return ch0_capture;
            1: return ch1_capture;
            2: return ch2_capture;
            3: return ch3_capture;
            default: return 0;
        endcase
    endfunction
    
    // Enable/disable channel capture
    function void set_channel_capture(int ch_id, bit enable);
        case (ch_id)
            0: ch0_capture = enable;
            1: ch1_capture = enable;
            2: ch2_capture = enable;
            3: ch3_capture = enable;
        endcase
    endfunction
    
    // Enable all channel captures
    function void enable_all_captures();
        ch0_capture = 1;
        ch1_capture = 1;
        ch2_capture = 1;
        ch3_capture = 1;
        capture_all_channels = 1;
    endfunction
    
    // Get number of enabled capture channels
    function int get_num_capture_channels();
        return ch0_capture + ch1_capture + ch2_capture + ch3_capture;
    endfunction
    
    // Calculate sample period in nanoseconds
    function real get_sample_period_ns();
        return 1.0e9 / sample_rate_hz;
    endfunction
    
    // Calculate nyquist frequency
    function real get_nyquist_freq_hz();
        return sample_rate_hz / 2.0;
    endfunction
    
    // Calculate capture duration in microseconds
    function real get_capture_duration_us();
        return (max_capture_samples * 1.0e6) / sample_rate_hz;
    endfunction
    
    virtual function string convert2string();
        string s;
        s = $sformatf("%s: %.1f MSPS, %0d-bit, %0d channels", 
                     super.convert2string(), 
                     sample_rate_hz/1e6, 
                     resolution_bits,
                     num_channels);
        if (enable_capture)
            s = {s, $sformatf(", capture=%0d samples", max_capture_samples)};
        if (auto_analyze_results)
            s = {s, ", auto-analyze"};
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_dac_cfg";
    endfunction
    
endclass : evm_dac_cfg
