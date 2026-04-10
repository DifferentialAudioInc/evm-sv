//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_dac_monitor
// Description: DAC passive monitor - captures DAC output data
//              Writes captured data to file for Python analysis
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_dac_monitor extends evm_stream_monitor;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_dac_cfg dac_cfg;
    
    //==========================================================================
    // Capture Buffers
    //==========================================================================
    int ch0_buffer[$];
    int ch1_buffer[$];
    int ch2_buffer[$];
    int ch3_buffer[$];
    
    int samples_captured = 0;
    bit capture_complete = 0;
    
    //==========================================================================
    // Statistics
    //==========================================================================
    longint total_samples = 0;
    longint valid_cycles = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_dac_monitor", evm_component parent = null, evm_dac_cfg cfg = null);
        super.new(name, parent, null);
        this.dac_cfg = (cfg != null) ? cfg : new();
    endfunction
    
    //==========================================================================
    // Main Phase - Monitor DAC output
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        log_info("DAC Monitor started", EVM_MED);
        
        fork
            monitor_dac_output();
        join_none
    endtask
    
    //==========================================================================
    // Monitor DAC Output
    //==========================================================================
    virtual task monitor_dac_output();
        virtual evm_dac_if dac_vif;
        
        // Cast to DAC interface
        if (!$cast(dac_vif, vif)) begin
            log_error("Failed to cast to evm_dac_if");
            return;
        end
        
        // Wait for reset deassertion
        @(posedge dac_vif.rst_n);
        log_info("DAC monitor active after reset", EVM_LOW);
        
        // Monitor loop
        forever begin
            @(posedge dac_vif.clk);
            
            // Check if valid data
            if (dac_vif.valid && dac_vif.dac_enable) begin
                valid_cycles++;
                
                // Capture data if enabled and not full
                if (dac_cfg.enable_capture && !capture_complete) begin
                    capture_sample(
                        dac_vif.ch0_data,
                        dac_vif.ch1_data,
                        dac_vif.ch2_data,
                        dac_vif.ch3_data,
                        dac_vif.ch_enable
                    );
                end
                
                total_samples++;
            end
        end
    endtask
    
    //==========================================================================
    // Capture Sample
    //==========================================================================
    function void capture_sample(
        logic [11:0] ch0_data,
        logic [11:0] ch1_data,
        logic [11:0] ch2_data,
        logic [11:0] ch3_data,
        logic [3:0]  ch_enable
    );
        // Check if we've reached capture limit
        if (samples_captured >= dac_cfg.max_capture_samples) begin
            if (!capture_complete) begin
                capture_complete = 1;
                log_info($sformatf("Capture complete: %0d samples", samples_captured), EVM_HIGH);
            end
            return;
        end
        
        // Capture each enabled channel
        if (dac_cfg.is_channel_capture_enabled(0) && ch_enable[0])
            ch0_buffer.push_back(ch0_data);
            
        if (dac_cfg.is_channel_capture_enabled(1) && ch_enable[1])
            ch1_buffer.push_back(ch1_data);
            
        if (dac_cfg.is_channel_capture_enabled(2) && ch_enable[2])
            ch2_buffer.push_back(ch2_data);
            
        if (dac_cfg.is_channel_capture_enabled(3) && ch_enable[3])
            ch3_buffer.push_back(ch3_data);
        
        samples_captured++;
        
        // Log progress periodically
        if (samples_captured % 1000 == 0) begin
            log_info($sformatf("Captured %0d/%0d samples", 
                              samples_captured, dac_cfg.max_capture_samples), EVM_LOW);
        end
    endfunction
    
    //==========================================================================
    // Write Capture to File
    //==========================================================================
    function void write_capture_to_file(string filename);
        int fd;
        int max_samples;
        
        fd = $fopen(filename, "w");
        if (fd == 0) begin
            log_error($sformatf("Failed to open file for writing: %s", filename));
            return;
        end
        
        // Write header
        $fwrite(fd, "# DAC Capture Data\n");
        $fwrite(fd, "# Sample Rate: %.0f Hz\n", dac_cfg.sample_rate_hz);
        $fwrite(fd, "# Samples: %0d\n", samples_captured);
        $fwrite(fd, "# Columns: CH0 CH1 CH2 CH3\n");
        
        // Determine how many samples to write
        max_samples = ch0_buffer.size();
        if (ch1_buffer.size() > max_samples) max_samples = ch1_buffer.size();
        if (ch2_buffer.size() > max_samples) max_samples = ch2_buffer.size();
        if (ch3_buffer.size() > max_samples) max_samples = ch3_buffer.size();
        
        // Write data (one sample per line)
        for (int i = 0; i < max_samples; i++) begin
            int ch0_val = (i < ch0_buffer.size()) ? ch0_buffer[i] : 0;
            int ch1_val = (i < ch1_buffer.size()) ? ch1_buffer[i] : 0;
            int ch2_val = (i < ch2_buffer.size()) ? ch2_buffer[i] : 0;
            int ch3_val = (i < ch3_buffer.size()) ? ch3_buffer[i] : 0;
            
            $fwrite(fd, "%0d %0d %0d %0d\n", ch0_val, ch1_val, ch2_val, ch3_val);
        end
        
        $fclose(fd);
        log_info($sformatf("Wrote %0d samples to %s", max_samples, filename), EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Final Phase - Write captured data
    //==========================================================================
    virtual function void final_phase();
        string capture_file;
        
        super.final_phase();
        
        if (samples_captured > 0) begin
            // Write capture to file
            capture_file = {dac_cfg.capture_dir, "/dac_output.txt"};
            write_capture_to_file(capture_file);
            
            // Print statistics
            print_statistics();
        end else begin
            log_warning("No DAC samples captured");
        end
    endfunction
    
    //==========================================================================
    // Statistics
    //==========================================================================
    function void print_statistics();
        real capture_percent;
        
        log_info("=== DAC Monitor Statistics ===", EVM_HIGH);
        log_info($sformatf("Total Samples:    %0d", total_samples), EVM_HIGH);
        log_info($sformatf("Valid Cycles:     %0d", valid_cycles), EVM_HIGH);
        log_info($sformatf("Captured Samples: %0d", samples_captured), EVM_HIGH);
        log_info($sformatf("CH0 Samples:      %0d", ch0_buffer.size()), EVM_HIGH);
        log_info($sformatf("CH1 Samples:      %0d", ch1_buffer.size()), EVM_HIGH);
        log_info($sformatf("CH2 Samples:      %0d", ch2_buffer.size()), EVM_HIGH);
        log_info($sformatf("CH3 Samples:      %0d", ch3_buffer.size()), EVM_HIGH);
        
        if (dac_cfg.max_capture_samples > 0) begin
            capture_percent = (samples_captured * 100.0) / dac_cfg.max_capture_samples;
            log_info($sformatf("Capture Progress: %.1f%%", capture_percent), EVM_HIGH);
        end
    endfunction
    
endclass : evm_dac_monitor
