//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_stream_cfg
// Description: Configuration for streaming agents
//              Controls stimulus generation and capture
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_stream_cfg extends evm_object;
    
    //==========================================================================
    // File Configuration
    //==========================================================================
    string stimulus_file = "stimulus.txt";     // Input stimulus file
    string capture_file = "capture.txt";       // Output capture file
    string python_gen_script = "";              // Python generation script
    string python_analyze_script = "";          // Python analysis script
    
    //==========================================================================
    // Stream Configuration
    //==========================================================================
    real   sample_rate_hz = 100e6;             // Sample rate in Hz
    int    bit_width = 16;                     // Data width in bits
    int    num_channels = 1;                   // Number of channels
    bit    signed_data = 1;                    // Signed or unsigned
    bit    complex_data = 0;                   // Real or complex (I/Q)
    
    //==========================================================================
    // Mode Configuration
    //==========================================================================
    bit    loop_mode = 0;                      // Loop stimulus file
    bit    auto_generate = 0;                  // Auto-generate stimulus
    bit    auto_analyze = 0;                   // Auto-analyze capture
    bit    enabled = 1;                        // Stream enable
    
    //==========================================================================
    // Signal Generation Parameters (for Python script)
    //==========================================================================
    string signal_type = "sine";               // sine, chirp, noise, multi_tone
    real   signal_freq_hz = 10e6;              // Signal frequency
    real   signal_amplitude = 1.0;             // Signal amplitude (full scale)
    real   signal_offset = 0.0;                // DC offset
    real   noise_level = 0.0;                  // Noise level
    real   duration_sec = 100e-6;              // Signal duration
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_stream_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    function real get_sample_period();
        return 1.0 / sample_rate_hz;
    endfunction
    
    function int get_num_samples();
        return int'(duration_sec * sample_rate_hz);
    endfunction
    
    function string get_python_gen_cmd();
        string cmd;
        if (python_gen_script != "") begin
            cmd = $sformatf("python %s --type %s --freq %.0f --fs %.0f --amp %.3f --duration %.9f --output %s",
                python_gen_script, signal_type, signal_freq_hz, sample_rate_hz, 
                signal_amplitude, duration_sec, stimulus_file);
        end
        return cmd;
    endfunction
    
    function string get_python_analyze_cmd();
        string cmd;
        if (python_analyze_script != "") begin
            cmd = $sformatf("python %s %s --fs %.0f --freq %.0f",
                python_analyze_script, capture_file, sample_rate_hz, signal_freq_hz);
        end
        return cmd;
    endfunction
    
endclass : evm_stream_cfg
