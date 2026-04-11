//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_stream_driver
// Description: Buffered streaming driver - generates samples on-demand
//              Supports two modes:
//              1. File-based: Load entire stimulus file at start
//              2. Buffered: Dynamically generate buffers via Python script
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

class evm_stream_driver extends evm_driver#(virtual evm_stream_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_stream_cfg cfg;
    
    //==========================================================================
    // Internal State
    //==========================================================================
    real buffer[$][$];       // [channel][sample] - circular buffer
    int buffer_read_ptr;     // Current read position in buffer
    int buffer_write_ptr;    // Current write position in buffer
    int buffer_samples;      // Number of valid samples in buffer
    
    int total_samples_output; // Total samples output (for phase tracking)
    bit streaming;
    bit buffer_underrun;
    
    // Statistics
    int buffer_refills;
    int max_buffer_usage;
    
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
        buffer_read_ptr = 0;
        buffer_write_ptr = 0;
        buffer_samples = 0;
        total_samples_output = 0;
        streaming = 0;
        buffer_underrun = 0;
        buffer_refills = 0;
        max_buffer_usage = 0;
    endfunction
    
    //==========================================================================
    // Initialize Buffer
    //==========================================================================
    virtual function void init_buffer();
        buffer.delete();
        for (int ch = 0; ch < cfg.num_channels; ch++) begin
            buffer.push_back({});
            // Pre-allocate buffer space
            for (int i = 0; i < cfg.buffer_size; i++) begin
                buffer[ch].push_back(0.0);
            end
        end
        buffer_read_ptr = 0;
        buffer_write_ptr = 0;
        buffer_samples = 0;
        log_info($sformatf("Initialized buffer: %0d samples x %0d channels", 
                 cfg.buffer_size, cfg.num_channels), EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Generate Buffer via Python
    //==========================================================================
    virtual function int generate_buffer(int start_sample, int num_samples);
        string cmd;
        int status;
        
        // Build Python command with sample offset
        cmd = cfg.get_python_buffer_cmd(start_sample, num_samples);
        
        if (cmd == "") begin
            log_error("Python script not configured");
            return 0;
        end
        
        log_info($sformatf("Generating buffer: samples %0d-%0d", 
                 start_sample, start_sample + num_samples - 1), EVM_DEBUG);
        
        // Call Python script
        status = $system(cmd);
        
        if (status != 0) begin
            log_error($sformatf("Python generation failed: status=%0d", status));
            return 0;
        end
        
        // Load generated samples into buffer
        return load_buffer_from_file(cfg.temp_buffer_file, num_samples);
    endfunction
    
    //==========================================================================
    // Load Buffer from File
    //==========================================================================
    virtual function int load_buffer_from_file(string filename, int max_samples);
        // ALL declarations at top — Vivado xvlog requires this
        int file_handle;
        string line;
        int status;
        int samples_loaded;
        string tokens[$];
        int token_start;
        string token;
        
        samples_loaded = 0;
        file_handle = $fopen(filename, "r");
        if (file_handle == 0) begin
            log_error($sformatf("Failed to open buffer file: %s", filename));
            return 0;
        end
        
        // Read samples into buffer (circular)
        while (!$feof(file_handle) && samples_loaded < max_samples) begin
            status = $fgets(line, file_handle);
            if (status == 0) break;
            
            // Skip comments and empty lines
            if (line[0] == "#" || line[0] == "\n") continue;
            
            // Parse comma-separated values: time, ch0, ch1, ...
            tokens = {};  token_start = 0;  // reset for each line
            for (int i = 0; i < line.len(); i++) begin
                if (line[i] == "," || line[i] == "\n") begin
                    if (i > token_start) begin
                        token = line.substr(token_start, i-1);  // 'token' declared at top
                        tokens.push_back(token);
                    end
                    token_start = i + 1;
                    while (token_start < line.len() && line[token_start] == " ") token_start++;
                end
            end
            
            if (tokens.size() < 2) continue; // Need at least time + 1 channel
            
            // Write to buffer at write pointer (skip time, load channels)
            // Note: 'sample' is not needed here; use a class-level temp below
            for (int ch = 0; ch < cfg.num_channels && (ch+1) < tokens.size(); ch++) begin
                real sample_val;  // needed as output arg for $sscanf — Vivado allows in for
                status = $sscanf(tokens[ch+1], "%f", sample_val);
                if (status > 0) begin
                    buffer[ch][buffer_write_ptr] = sample_val;
                end
            end
            
            // Advance write pointer (circular)
            buffer_write_ptr = (buffer_write_ptr + 1) % cfg.buffer_size;
            buffer_samples++;
            samples_loaded++;
            
            // Track max buffer usage
            if (buffer_samples > max_buffer_usage) begin
                max_buffer_usage = buffer_samples;
            end
        end
        
        $fclose(file_handle);
        
        log_info($sformatf("Loaded %0d samples into buffer (buffer level: %0d/%0d)", 
                 samples_loaded, buffer_samples, cfg.buffer_size), EVM_DEBUG);
        
        return samples_loaded;
    endfunction
    
    //==========================================================================
    // Load Complete File (Non-buffered Mode)
    //==========================================================================
    virtual function int load_complete_file();
        // ALL declarations at top — Vivado xvlog requires this
        int file_handle;
        string line;
        int status;
        int samples_loaded;
        string tokens[$];
        int token_start;
        string token;
        real sample;
        
        samples_loaded = 0;
        log_info($sformatf("Loading complete stimulus from: %s", cfg.stimulus_file), EVM_MED);
        
        file_handle = $fopen(cfg.stimulus_file, "r");
        if (file_handle == 0) begin
            log_error($sformatf("Failed to open stimulus file: %s", cfg.stimulus_file));
            return 0;
        end
        
        // Clear and resize buffer for entire file
        buffer.delete();
        for (int ch = 0; ch < cfg.num_channels; ch++) begin
            buffer.push_back({});
        end
        
        // Read all samples
        while (!$feof(file_handle)) begin
            status = $fgets(line, file_handle);
            if (status == 0) break;
            
            if (line[0] == "#" || line[0] == "\n") continue;
            
            tokens = {};  token_start = 0;  // reset for each line
            for (int i = 0; i < line.len(); i++) begin
                if (line[i] == "," || line[i] == "\n") begin
                    if (i > token_start) begin
                        token = line.substr(token_start, i-1);
                        tokens.push_back(token);
                    end
                    token_start = i + 1;
                    while (token_start < line.len() && line[token_start] == " ") token_start++;
                end
            end
            
            if (tokens.size() < 2) continue;
            
            for (int ch = 0; ch < cfg.num_channels && (ch+1) < tokens.size(); ch++) begin
                status = $sscanf(tokens[ch+1], "%f", sample);
                if (status > 0) begin
                    buffer[ch].push_back(sample);
                end
            end
            samples_loaded++;
        end
        
        $fclose(file_handle);
        buffer_samples = samples_loaded;
        
        log_info($sformatf("Loaded %0d samples per channel", samples_loaded), EVM_MED);
        return samples_loaded;
    endfunction
    
    //==========================================================================
    // Check and Refill Buffer
    //==========================================================================
    virtual task check_and_refill_buffer();
        // Declarations at top — Vivado xvlog requires this
        int samples_to_generate;
        int samples_generated;
        if (buffer_samples < cfg.buffer_refill_threshold) begin
            samples_to_generate = cfg.buffer_size - buffer_samples;
            
            log_info($sformatf("Buffer low (%0d samples), refilling with %0d samples", 
                     buffer_samples, samples_to_generate), EVM_MED);
            
            samples_generated = generate_buffer(total_samples_output + buffer_samples, 
                                               samples_to_generate);
            
            if (samples_generated > 0) begin
                buffer_refills++;
            end else begin
                log_warning("Buffer refill failed - may cause underrun");
            end
        end
    endtask
    
    //==========================================================================
    // Main Phase - Start Streaming
    //==========================================================================
    virtual task main_phase();
        // ALL declarations at top — Vivado xvlog requires this
        int samples_generated;
        int samples_loaded;
        
        super.main_phase();
        
        if (!cfg.enabled) begin
            log_info("Streaming disabled", EVM_MED);
            return;
        end
        
        // Initialize based on mode
        if (cfg.buffered_mode) begin
            // Buffered mode: dynamic generation
            init_buffer();
            samples_generated = generate_buffer(0, cfg.buffer_size);
            if (samples_generated == 0) begin
                log_error("Failed to generate initial buffer");
                return;
            end
            
            log_info($sformatf("Buffered streaming mode: %0d sample buffer, refill at %0d", 
                     cfg.buffer_size, cfg.buffer_refill_threshold), EVM_LOW);
        end else begin
            // File mode: load entire file
            samples_loaded = load_complete_file();
            if (samples_loaded == 0) begin
                log_warning("No samples loaded - streaming disabled");
                return;
            end
            
            log_info($sformatf("File streaming mode: %0d samples, %s", 
                     buffer_samples, cfg.loop_mode ? "loop" : "one-shot"), EVM_LOW);
        end
        
        // Start streaming
        streaming = 1;
        total_samples_output = 0;
        
        fork
            stream_samples();
            if (cfg.buffered_mode) begin
                buffer_manager();
            end
        join_none
    endtask
    
    //==========================================================================
    // Buffer Manager Task (monitors and refills buffer)
    //==========================================================================
    virtual task buffer_manager();
        while (streaming) begin
            @(posedge vif.clk);
            
            // Check if refill needed
            if (buffer_samples < cfg.buffer_refill_threshold) begin
                check_and_refill_buffer();
            end
        end
    endtask
    
    //==========================================================================
    // Stream Samples Task
    //==========================================================================
    virtual task stream_samples();
        while (streaming) begin
            @(posedge vif.clk);
            
            // Check for buffer underrun
            if (buffer_samples == 0) begin
                if (!buffer_underrun) begin
                    log_error("Buffer underrun!");
                    buffer_underrun = 1;
                end
                // Output zeros on underrun
                for (int ch = 0; ch < cfg.num_channels; ch++) begin
                    vif.data[ch] <= '0;
                    vif.valid[ch] <= 1'b0;
                end
                continue;
            end
            
            // Output current sample for all channels
            for (int ch = 0; ch < cfg.num_channels; ch++) begin
                real normalized;
                int  max_val;
                int  sample_int;
                normalized = buffer[ch][buffer_read_ptr];
                max_val    = (1 << (cfg.bit_width - 1)) - 1;
                sample_int = int'(normalized * max_val);
                
                vif.data[ch] <= sample_int;
                vif.valid[ch] <= 1'b1;
            end
            
            // Advance read pointer (circular)
            buffer_read_ptr = (buffer_read_ptr + 1) % cfg.buffer_size;
            buffer_samples--;
            total_samples_output++;
            
            // In file mode with loop, refill from file when buffer empty
            if (!cfg.buffered_mode && cfg.loop_mode && buffer_samples == 0) begin
                buffer_read_ptr = 0;
                buffer_samples = buffer[0].size();
                log_info("Looping file stimulus", EVM_DEBUG);
            end
            
            // In file mode without loop, stop when done
            if (!cfg.buffered_mode && !cfg.loop_mode && buffer_samples == 0) begin
                log_info($sformatf("Stimulus complete: %0d samples output", 
                         total_samples_output), EVM_LOW);
                streaming = 0;
            end
        end
    endtask
    
    //==========================================================================
    // Shutdown Phase - Report Statistics
    //==========================================================================
    virtual function void shutdown_phase();
        super.shutdown_phase();
        log_info("=== Streaming Statistics ===", EVM_LOW);
        log_info($sformatf("  Total samples output: %0d", total_samples_output), EVM_LOW);
        if (cfg.buffered_mode) begin
            log_info($sformatf("  Buffer refills: %0d", buffer_refills), EVM_LOW);
            log_info($sformatf("  Max buffer usage: %0d/%0d", max_buffer_usage, cfg.buffer_size), EVM_LOW);
        end
        if (buffer_underrun) begin
            log_warning("  Buffer underruns occurred!");
        end
    endfunction
    
    //==========================================================================
    // Control Methods
    //==========================================================================
    task stop_streaming();
        streaming = 0;
        log_info("Streaming stopped", EVM_MED);
    endtask
    
    task restart_streaming();
        buffer_read_ptr = 0;
        buffer_samples = buffer[0].size();
        total_samples_output = 0;
        streaming = 1;
        buffer_underrun = 0;
        log_info("Streaming restarted", EVM_MED);
    endtask
    
    function int get_buffer_level();
        return buffer_samples;
    endfunction
    
    function int get_total_samples();
        return total_samples_output;
    endfunction
    
endclass : evm_stream_driver
