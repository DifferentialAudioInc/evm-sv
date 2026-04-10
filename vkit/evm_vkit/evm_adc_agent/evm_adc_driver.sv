//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_adc_driver
// Description: ADC behavioral model driver for EVM
//              Simulates AD9634 4-channel ADC with sine wave generation
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

class evm_adc_driver extends evm_driver#(virtual evm_adc_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_adc_cfg cfg;
    
    //==========================================================================
    // Parameters
    //==========================================================================
    parameter real PI = 3.14159265359;
    parameter int  ADC_BITS = 12;
    parameter real SAMPLE_RATE_HZ = 100e6;  // 100 MSPS
    
    //==========================================================================
    // Channel Configuration
    //==========================================================================
    typedef struct {
        bit   enabled;
        real  sine_freq_hz;
        real  sine_amplitude;
        real  sine_phase_deg;
        real  sine_dc_offset;
        real  time_sec;
        int   sample_count;
    } channel_cfg_t;
    
    channel_cfg_t ch_cfg[4];
    
    real sample_period_sec;
    bit  running = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_adc_driver", evm_component parent = null, evm_adc_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
        if (cfg != null) begin
            sample_period_sec = 1.0 / cfg.sample_rate_hz;
        end else begin
            sample_period_sec = 1.0 / SAMPLE_RATE_HZ;
        end
        
        // Initialize all channels with default configuration
        foreach(ch_cfg[i]) begin
            if (cfg != null) begin
                ch_cfg[i].enabled = (i == 0) ? cfg.ch0_enable : 
                                   (i == 1) ? cfg.ch1_enable :
                                   (i == 2) ? cfg.ch2_enable : cfg.ch3_enable;
                ch_cfg[i].sine_freq_hz = cfg.default_sine_freq_hz;
                ch_cfg[i].sine_amplitude = cfg.default_sine_amplitude;
                ch_cfg[i].sine_phase_deg = cfg.default_sine_phase_deg;
                ch_cfg[i].sine_dc_offset = cfg.default_sine_dc_offset;
            end else begin
                ch_cfg[i].enabled = 0;
                ch_cfg[i].sine_freq_hz = 1.0e6;      // Default 1MHz
                ch_cfg[i].sine_amplitude = 2047.0;    // Full scale
                ch_cfg[i].sine_phase_deg = 0.0;
                ch_cfg[i].sine_dc_offset = 0.0;
            end
            ch_cfg[i].time_sec = 0.0;
            ch_cfg[i].sample_count = 0;
        end
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    function void configure_channel(int ch_id, real freq_hz, real amplitude, 
                                   real phase_deg = 0.0, real dc_offset = 0.0);
        if (ch_id >= 0 && ch_id < 4) begin
            ch_cfg[ch_id].sine_freq_hz = freq_hz;
            ch_cfg[ch_id].sine_amplitude = amplitude;
            ch_cfg[ch_id].sine_phase_deg = phase_deg;
            ch_cfg[ch_id].sine_dc_offset = dc_offset;
            log_info($sformatf("Channel %0d configured: freq=%.2fMHz, amp=%.0f, phase=%.1f°", 
                     ch_id, freq_hz/1e6, amplitude, phase_deg), EVM_MED);
        end else begin
            log_error($sformatf("Invalid channel ID: %0d", ch_id));
        end
    endfunction
    
    function void enable_channel(int ch_id);
        if (ch_id >= 0 && ch_id < 4) begin
            ch_cfg[ch_id].enabled = 1;
            log_info($sformatf("Channel %0d enabled", ch_id), EVM_LOW);
        end
    endfunction
    
    function void disable_channel(int ch_id);
        if (ch_id >= 0 && ch_id < 4) begin
            ch_cfg[ch_id].enabled = 0;
            log_info($sformatf("Channel %0d disabled", ch_id), EVM_LOW);
        end
    endfunction
    
    function void enable_all_channels();
        foreach(ch_cfg[i]) begin
            ch_cfg[i].enabled = 1;
        end
        log_info("All channels enabled", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Main Phase - Start ADC generation
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        running = 1;
        vif.adc_enabled = 1;
        log_info("Starting ADC data generation", EVM_LOW);
        
        fork
            run_adc();
        join_none
    endtask
    
    //==========================================================================
    // ADC Data Generation
    //==========================================================================
    task run_adc();
        real sine_value;
        real phase_rad;
        int  adc_code;
        
        while (running) begin
            // Generate data for all enabled channels
            for (int ch = 0; ch < 4; ch++) begin
                if (ch_cfg[ch].enabled) begin
                    // Calculate current phase
                    phase_rad = 2.0 * PI * ch_cfg[ch].sine_freq_hz * ch_cfg[ch].time_sec + 
                               (ch_cfg[ch].sine_phase_deg * PI / 180.0);
                    
                    // Generate sine wave
                    sine_value = ch_cfg[ch].sine_amplitude * $sin(phase_rad) + ch_cfg[ch].sine_dc_offset;
                    
                    // Convert to ADC code (12-bit signed)
                    adc_code = int'(sine_value);
                    
                    // Clip to 12-bit range
                    if (adc_code > 2047) adc_code = 2047;
                    if (adc_code < -2048) adc_code = -2048;
                    
                    // Convert to unsigned 12-bit
                    vif.data_ch[ch] = adc_code[11:0];
                    
                    // Simplified: output MSB as differential signal
                    vif.data_out[ch] = vif.data_ch[ch][11];
                    
                    // Update channel time and count
                    ch_cfg[ch].time_sec += sample_period_sec;
                    ch_cfg[ch].sample_count++;
                end else begin
                    vif.data_ch[ch] = 12'h000;
                    vif.data_out[ch] = 0;
                end
            end
            
            // Wait for next sample period
            #(sample_period_sec * 1e9);  // Convert to ns
        end
    endtask
    
    //==========================================================================
    // Control Methods
    //==========================================================================
    task stop();
        running = 0;
        vif.adc_enabled = 0;
        log_info("ADC stopped", EVM_LOW);
    endtask
    
    task reset_channel(int ch_id);
        if (ch_id >= 0 && ch_id < 4) begin
            ch_cfg[ch_id].time_sec = 0.0;
            ch_cfg[ch_id].sample_count = 0;
            log_info($sformatf("Channel %0d reset", ch_id), EVM_LOW);
        end
    endtask
    
    function int get_sample_count(int ch_id);
        if (ch_id >= 0 && ch_id < 4) begin
            return ch_cfg[ch_id].sample_count;
        end
        return 0;
    endfunction
    
endclass : evm_adc_driver
