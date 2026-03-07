//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_memory_model
// Description: Behavioral memory model for DMA buffers and storage
//              Supports byte-addressable read/write with latency
// Author: Engineering Team
// Date: 2026-03-07
//==============================================================================

class evm_memory_model extends evm_object;
    
    //==========================================================================
    // Memory Storage
    //==========================================================================
    byte memory[longint];                  // Sparse memory array
    longint memory_size = 64 * 1024 * 1024; // 64 MB default
    int read_latency_cycles = 1;           // Read latency
    int write_latency_cycles = 1;          // Write latency
    
    //==========================================================================
    // Statistics
    //==========================================================================
    longint read_count = 0;
    longint write_count = 0;
    longint read_bytes = 0;
    longint write_bytes = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_memory_model", longint size = 64*1024*1024);
        super.new(name);
        memory_size = size;
    endfunction
    
    //==========================================================================
    // Write Methods
    //==========================================================================
    
    // Write byte
    function void write_byte(longint addr, byte data);
        if (addr < memory_size) begin
            memory[addr] = data;
            write_count++;
            write_bytes++;
        end else begin
            log_error($sformatf("Write address out of range: 0x%h", addr));
        end
    endfunction
    
    // Write word (32-bit)
    function void write_word(longint addr, bit [31:0] data);
        if ((addr + 3) < memory_size) begin
            memory[addr+0] = data[7:0];
            memory[addr+1] = data[15:8];
            memory[addr+2] = data[23:16];
            memory[addr+3] = data[31:24];
            write_count++;
            write_bytes += 4;
        end else begin
            log_error($sformatf("Write address out of range: 0x%h", addr));
        end
    endfunction
    
    // Write burst
    function void write_burst(longint addr, byte data[], int num_bytes);
        for (int i = 0; i < num_bytes; i++) begin
            if ((addr + i) < memory_size) begin
                memory[addr + i] = data[i];
                write_bytes++;
            end
        end
        write_count++;
    endfunction
    
    //==========================================================================
    // Read Methods
    //==========================================================================
    
    // Read byte
    function byte read_byte(longint addr);
        if (addr < memory_size) begin
            read_count++;
            read_bytes++;
            return memory.exists(addr) ? memory[addr] : 8'h00;
        end else begin
            log_error($sformatf("Read address out of range: 0x%h", addr));
            return 8'h00;
        end
    endfunction
    
    // Read word (32-bit)
    function bit [31:0] read_word(longint addr);
        bit [31:0] data;
        if ((addr + 3) < memory_size) begin
            data[7:0]   = memory.exists(addr+0) ? memory[addr+0] : 8'h00;
            data[15:8]  = memory.exists(addr+1) ? memory[addr+1] : 8'h00;
            data[23:16] = memory.exists(addr+2) ? memory[addr+2] : 8'h00;
            data[31:24] = memory.exists(addr+3) ? memory[addr+3] : 8'h00;
            read_count++;
            read_bytes += 4;
            return data;
        end else begin
            log_error($sformatf("Read address out of range: 0x%h", addr));
            return 32'h00000000;
        end
    endfunction
    
    // Read burst
    function void read_burst(longint addr, output byte data[], int num_bytes);
        data = new[num_bytes];
        for (int i = 0; i < num_bytes; i++) begin
            if ((addr + i) < memory_size) begin
                data[i] = memory.exists(addr + i) ? memory[addr + i] : 8'h00;
                read_bytes++;
            end else begin
                data[i] = 8'h00;
            end
        end
        read_count++;
    endfunction
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Clear memory
    function void clear();
        memory.delete();
        log_info("Memory cleared", EVM_MED);
    endfunction
    
    // Initialize with pattern
    function void init_pattern(longint start_addr, int num_bytes, byte pattern = 8'h00);
        for (longint i = 0; i < num_bytes; i++) begin
            if ((start_addr + i) < memory_size) begin
                memory[start_addr + i] = pattern;
            end
        end
        log_info($sformatf("Initialized %0d bytes at 0x%h with pattern 0x%02h", 
                          num_bytes, start_addr, pattern), EVM_MED);
    endfunction
    
    // Load from file
    function void load_from_file(string filename, longint start_addr = 0);
        int fd;
        byte data;
        longint addr = start_addr;
        
        fd = $fopen(filename, "r");
        if (fd == 0) begin
            log_error($sformatf("Failed to open file: %s", filename));
            return;
        end
        
        while (!$feof(fd)) begin
            void'($fscanf(fd, "%h\n", data));
            if (addr < memory_size) begin
                memory[addr] = data;
                addr++;
            end
        end
        
        $fclose(fd);
        log_info($sformatf("Loaded %0d bytes from %s", addr - start_addr, filename), EVM_HIGH);
    endfunction
    
    // Save to file
    function void save_to_file(string filename, longint start_addr, int num_bytes);
        int fd;
        
        fd = $fopen(filename, "w");
        if (fd == 0) begin
            log_error($sformatf("Failed to open file for writing: %s", filename));
            return;
        end
        
        for (longint i = 0; i < num_bytes; i++) begin
            longint addr = start_addr + i;
            byte data = memory.exists(addr) ? memory[addr] : 8'h00;
            $fwrite(fd, "%02h\n", data);
        end
        
        $fclose(fd);
        log_info($sformatf("Saved %0d bytes to %s", num_bytes, filename), EVM_HIGH);
    endfunction
    
    // Print statistics
    function void print_statistics();
        log_info("=== Memory Model Statistics ===", EVM_HIGH);
        log_info($sformatf("Memory Size:  %0d MB", memory_size/(1024*1024)), EVM_HIGH);
        log_info($sformatf("Read Count:   %0d", read_count), EVM_HIGH);
        log_info($sformatf("Write Count:  %0d", write_count), EVM_HIGH);
        log_info($sformatf("Read Bytes:   %0d", read_bytes), EVM_HIGH);
        log_info($sformatf("Write Bytes:  %0d", write_bytes), EVM_HIGH);
        log_info($sformatf("Used Entries: %0d", memory.size()), EVM_HIGH);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("%s: %0d MB, R=%0d W=%0d", 
                        super.convert2string(), memory_size/(1024*1024),
                        read_count, write_count);
    endfunction
    
endclass : evm_memory_model
