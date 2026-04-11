//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_stream_monitor
// Description: Base streaming monitor - captures data and writes to file
//              Captures samples every clock cycle when valid
// Author: Eric Dyer
// Date: 2026-03-06
//==============================================================================

class evm_stream_monitor extends evm_monitor#(virtual evm_stream_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_stream_cfg cfg;
    
    //==========================================================================
    // Internal State
    //==========================================================================
    int file_handle;
    int sample_count;
    bit capturing;
    realtime start_time;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_stream_monitor", evm_component parent = null, evm_stream_cfg cfg = null);
        super.new(name, parent);
        if (cfg != null) begin
            this.cfg = cfg;
        end else begin
            this.cfg = new("evm_stream_cfg");
        end
        sample_count = 0;
        capturing = 0;
    endfunction
    
    //==========================================================================
    // Main Phase - Start Capture
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        log_info($sformatf("Opening capture file: %s", cfg.capture_file), EVM_MED);
        
        file_handle = $fopen(cfg.capture_file, "w");
        if (file_handle == 0) begin
            log_error($sformatf("Failed to open capture file: %s", cfg.capture_file));
            return;
        end
        
        // Write header
        $fwrite(file_handle, "# Capture File\n");
        $fwrite(file_handle, "# Sample Rate: %.0f Hz\n", cfg.sample_rate_hz);
        $fwrite(file_handle, "# Channels: %0d\n", cfg.num_channels);
        $fwrite(file_handle, "# Bit Width: %0d\n", cfg.bit_width);
        $fwrite(file_handle, "#\n");
        $fwrite(file_handle, "# Format: time");
        for (int ch = 0; ch < cfg.num_channels; ch++) begin
            $fwrite(file_handle, ", ch%0d", ch);
        end
        $fwrite(file_handle, "\n");
        
        capturing = 1;
        start_time = $realtime;
        sample_count = 0;
        
        log_info("Starting capture", EVM_MED);
        
        fork
            capture_samples();
        join_none
    endtask
    
    //==========================================================================
    // Capture Samples Task
    //==========================================================================
    virtual task capture_samples();
        // ALL declarations at top — Vivado xvlog requires this
        bit any_valid;
        realtime current_time;
        real time_sec;
        
        while (capturing) begin
            @(posedge vif.clk);
            
            // Check if any channel is valid
            any_valid = 0;
            for (int ch = 0; ch < cfg.num_channels; ch++) begin
                if (vif.valid[ch]) any_valid = 1;
            end
            
            if (any_valid) begin
                // Calculate timestamp
                current_time = $realtime;
                time_sec = (current_time - start_time) / 1s;
                
                // Write timestamp
                $fwrite(file_handle, "%.9f", time_sec);
                
                // Write channel data
                for (int ch = 0; ch < cfg.num_channels; ch++) begin
                    if (vif.valid[ch]) begin
                        // Convert integer to real (normalized)
                        int max_val = (1 << (cfg.bit_width - 1)) - 1;
                        real normalized = real'($signed(vif.data[ch])) / real'(max_val);
                        $fwrite(file_handle, ", %.6f", normalized);
                    end else begin
                        $fwrite(file_handle, ", 0.0");
                    end
                end
                
                $fwrite(file_handle, "\n");
                sample_count++;
                
                // Periodic status
                if (sample_count % 10000 == 0) begin
                    log_info($sformatf("Captured %0d samples", sample_count), EVM_DEBUG);
                end
            end
        end
    endtask
    
    //==========================================================================
    // Final Phase - Close File
    //==========================================================================
    virtual function void final_phase();
        super.final_phase();
        
        if (file_handle != 0) begin
            capturing = 0;
            $fclose(file_handle);
            log_info($sformatf("Capture complete: %0d samples written to %s", 
                     sample_count, cfg.capture_file), EVM_MED);
        end
    endfunction
    
    //==========================================================================
    // Control Methods
    //==========================================================================
    task stop_capture();
        capturing = 0;
        log_info("Capture stopped", EVM_MED);
    endtask
    
    function int get_sample_count();
        return sample_count;
    endfunction
    
endclass : evm_stream_monitor
