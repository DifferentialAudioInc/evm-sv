//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_stream_driver
// Description: Base streaming driver - reads stimulus file and drives interface
//              Outputs samples every clock cycle (no handshake)
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_stream_driver extends evm_driver#(virtual evm_stream_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_stream_cfg cfg;
    
    //==========================================================================
    // Internal State
    //==========================================================================
    real samples[$][$];  // [channel][sample]
    int sample_index;
    int num_samples;
    bit streaming;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_stream_driver", evm_component parent = null, evm_stream_cfg cfg = null);
        super.new(name, parent);
        if (cfg != null) begin
            this.cfg = cfg;
        end else begin
            this.cfg = new("evm_stream_cfg");
        end
        sample_index = 0;
        streaming = 0;
    endfunction
    
    //==========================================================================
    // Load Stimulus File
    //==========================================================================
    virtual function void load_stimulus();
        int file_handle;
        string line;
        int status;
        
        log_info($sformatf("Loading stimulus from: %s", cfg.stimulus_file), EVM_MED);
        
        file_handle = $fopen(cfg.stimulus_file, "r");
        if (file_handle == 0) begin
            log_error($sformatf("Failed to open stimulus file: %s", cfg.stimulus_file));
            return;
        end
        
        // Clear existing samples
        samples.delete();
        for (int ch = 0; ch < cfg.num_channels; ch++) begin
            samples.push_back({});
        end
        
        // Read file line by line
        while (!$feof(file_handle)) begin
            status = $fgets(line, file_handle);
            if (status == 0) break;
            
            // Skip comments and empty lines
            if (line[0] == "#" || line[0] == "\n") continue;
            
            // Parse comma-separated values
            // Format: time, ch0, ch1, ch2, ...
            automatic string tokens[$];
            int token_start = 0;
            
            for (int i = 0; i < line.len(); i++) begin
                if (line[i] == "," || line[i] == "\n") begin
                    string token = line.substr(token_start, i-1);
                    tokens.push_back(token);
                    token_start = i + 1;
                end
            end
            
            // Skip time column (first token), read channel data
            for (int ch = 0; ch < cfg.num_channels && (ch+1) < tokens.size(); ch++) begin
                real sample;
                status = $sscanf(tokens[ch+1], "%f", sample);
                if (status > 0) begin
                    samples[ch].push_back(sample);
                end
            end
        end
        
        $fclose(file_handle);
        num_samples = samples[0].size();
        log_info($sformatf("Loaded %0d samples per channel", num_samples), EVM_MED);
    endfunction
    
    //==========================================================================
    // Main Phase - Start Streaming
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        
        if (!cfg.enabled) begin
            log_info("Streaming disabled", EVM_MED);
            return;
        end
        
        // Load stimulus
        load_stimulus();
        
        if (num_samples == 0) begin
            log_warning("No samples loaded - streaming disabled");
            return;
        end
        
        // Start streaming
        streaming = 1;
        sample_index = 0;
        
        log_info($sformatf("Starting stream: %0d samples, %s mode", 
                 num_samples, cfg.loop_mode ? "loop" : "one-shot"), EVM_MED);
        
        fork
            stream_samples();
        join_none
    endtask
    
    //==========================================================================
    // Stream Samples Task
    //==========================================================================
    virtual task stream_samples();
        while (streaming) begin
            @(posedge vif.clk);
            
            // Output current sample for all channels
            for (int ch = 0; ch < cfg.num_channels; ch++) begin
                if (sample_index < samples[ch].size()) begin
                    // Convert real to integer based on bit width
                    real normalized = samples[ch][sample_index];
                    int max_val = (1 << (cfg.bit_width - 1)) - 1;
                    int sample_int = int'(normalized * max_val);
                    
                    vif.data[ch] <= sample_int;
                    vif.valid[ch] <= 1'b1;
                end else begin
                    vif.valid[ch] <= 1'b0;
                end
            end
            
            // Advance sample index
            sample_index++;
            
            // Handle end of samples
            if (sample_index >= num_samples) begin
                if (cfg.loop_mode) begin
                    sample_index = 0;  // Loop back
                    log_info("Looping stimulus", EVM_DEBUG);
                end else begin
                    log_info("Stimulus complete", EVM_MED);
                    streaming = 0;  // Done
                end
            end
        end
    endtask
    
    //==========================================================================
    // Control Methods
    //==========================================================================
    task stop_streaming();
        streaming = 0;
        log_info("Streaming stopped", EVM_MED);
    endtask
    
    task restart_streaming();
        sample_index = 0;
        streaming = 1;
        log_info("Streaming restarted", EVM_MED);
    endtask
    
endclass : evm_stream_driver
