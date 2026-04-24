//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_device_model.sv
// Description: Per-device SPI target model with memory backing.
//              Wraps evm_memory_model with a generic SPI command state machine.
//              Supports READ, WRITE, and READ_ID opcodes.
//              Designed for SPI flash, EEPROM, ADC, sensor, etc.
//              Multiple instances live in evm_spi_cfg.devices[].
//
// API — Public Interface:
//   new(name, index, mem_size)      — constructor; creates backing evm_memory_model
//   begin_transfer()                — call when CS_N asserts; resets FSM
//   process_byte(mosi_byte)         — call for each byte received; returns MISO byte
//   end_transfer()                  — call when CS_N deasserts (logging, stats)
//
//   Backdoor API (call from test without going through SPI protocol):
//   load_byte(addr, data)           — write one byte directly to memory
//   peek_byte(addr)                 — read one byte directly from memory
//   load_array(base_addr, data[])   — load byte array starting at base_addr
//   load_file_hex(base_addr, fname) — load Intel-hex format file
//   fill(base_addr, n_bytes, pat)   — fill N bytes with pattern (default 0xFF = erased)
//   clear()                         — fill entire device with 0xFF
//   dump(base_addr, n_bytes)        — print memory contents to log
//   mem                             — direct access to evm_memory_model handle
//==============================================================================

class evm_spi_device_model extends evm_object;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    int          device_index    = 0;       // which CS line (0-7)
    int          mem_size_bytes  = 256;     // backing store size (bytes)
    int          addr_bytes      = 1;       // address field width: 1=256B 2=64KB 3=16MB
    bit [7:0]    read_cmd        = 8'h03;   // READ opcode (SPI flash standard)
    bit [7:0]    write_cmd       = 8'h02;   // WRITE/PAGE PROGRAM opcode
    bit [7:0]    read_id_cmd     = 8'h9F;   // JEDEC READ ID opcode
    bit [23:0]   device_id       = 24'hEF4017; // JEDEC ID (default: W25Q64)
    
    //==========================================================================
    // Backing memory model
    //==========================================================================
    evm_memory_model mem;   // direct access allowed (backdoor loads)
    
    //==========================================================================
    // Internal FSM state
    //==========================================================================
    // FSM states as int (avoids local enum issues in some simulators)
    local int    FSM_IDLE  ;  // = 0 — waiting for command byte
    local int    FSM_ADDR  ;  // = 1 — receiving address bytes
    local int    FSM_READ  ;  // = 2 — sending memory data on MISO
    local int    FSM_WRITE ;  // = 3 — receiving write data on MOSI
    local int    FSM_ID    ;  // = 4 — sending device ID
    local int    FSM_OTHER ;  // = 5 — unknown command
    
    local int      m_state;
    local bit [7:0] m_cmd;
    local longint   m_addr;        // assembled address
    local int       m_addr_rem;    // address bytes remaining
    local longint   m_rw_addr;     // current read/write pointer
    local int       m_byte_num;    // byte counter within transfer
    local bit       m_is_read;
    local int       m_id_idx;      // byte index within device_id
    
    //==========================================================================
    // Statistics
    //==========================================================================
    longint read_count  = 0;
    longint write_count = 0;
    longint transfer_count = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_device", int index = 0, int sz = 256);
        super.new(name);
        device_index   = index;
        mem_size_bytes = sz;
        // Initialize FSM state constants
        FSM_IDLE  = 0;
        FSM_ADDR  = 1;
        FSM_READ  = 2;
        FSM_WRITE = 3;
        FSM_ID    = 4;
        FSM_OTHER = 5;
        m_state   = FSM_IDLE;
        // Create backing memory
        mem = new($sformatf("%s.mem", name), sz);
        // Erase flash: fill with 0xFF
        fill(0, sz, 8'hFF);
    endfunction
    
    //==========================================================================
    // Protocol: call when CS_N asserts — resets FSM for new transfer
    //==========================================================================
    function void begin_transfer();
        m_state    = FSM_IDLE;
        m_cmd      = 8'h00;
        m_addr     = 0;
        m_addr_rem = 0;
        m_rw_addr  = 0;
        m_byte_num = 0;
        m_is_read  = 0;
        m_id_idx   = 0;
        transfer_count++;
    endfunction
    
    //==========================================================================
    // Protocol: call for each byte received from initiator (MOSI).
    // Returns: the byte to drive on MISO for THIS byte transfer.
    //
    // Timing model:
    //   The returned MISO byte is driven DURING the transmission of mosi_byte.
    //   This means the MISO byte returned by call N is clocked out while
    //   call N+1's mosi_byte is being received. One byte pipelining.
    //   The driver uses the PREVIOUS call's returned byte for MISO.
    //   Exception: first byte (m_byte_num=0) returned value is sent during
    //   the SECOND byte, which is correct for the SPI timing model.
    //==========================================================================
    function bit [7:0] process_byte(bit [7:0] mosi_byte);
        bit [7:0] miso_byte;
        longint   mem_addr;
        miso_byte = 8'hFF;  // default: MISO idles high
        
        if (m_state == FSM_IDLE) begin
            // First byte = command
            m_cmd      = mosi_byte;
            m_byte_num = 0;
            
            if (mosi_byte == read_cmd) begin
                m_addr     = 0;
                m_addr_rem = addr_bytes;
                m_is_read  = 1;
                m_state    = FSM_ADDR;
                log_info($sformatf("[SPI DEV%0d] READ command received", device_index), EVM_DEBUG);
            end else if (mosi_byte == write_cmd) begin
                m_addr     = 0;
                m_addr_rem = addr_bytes;
                m_is_read  = 0;
                m_state    = FSM_ADDR;
                log_info($sformatf("[SPI DEV%0d] WRITE command received", device_index), EVM_DEBUG);
            end else if (mosi_byte == read_id_cmd) begin
                m_id_idx = 0;
                m_state  = FSM_ID;
                // Return first byte of device ID immediately
                miso_byte = device_id[23:16];
                log_info($sformatf("[SPI DEV%0d] READ_ID command, ID=0x%06x", device_index, device_id), EVM_DEBUG);
            end else begin
                m_state = FSM_OTHER;
                log_info($sformatf("[SPI DEV%0d] Unknown command 0x%02x", device_index, mosi_byte), EVM_HIGH);
            end
            
        end else if (m_state == FSM_ADDR) begin
            // Accumulate address bytes (MSB first)
            m_addr     = (m_addr << 8) | longint'(mosi_byte);
            m_addr_rem = m_addr_rem - 1;
            
            if (m_addr_rem == 0) begin
                // Address complete
                if (m_is_read) begin
                    // Pre-fetch first byte for MISO pipeline
                    mem_addr  = m_addr % longint'(mem_size_bytes);
                    miso_byte = byte'(mem.read_byte(mem_addr));
                    m_rw_addr = m_addr + 1;
                    m_state   = FSM_READ;
                    read_count++;
                    log_info($sformatf("[SPI DEV%0d] READ addr=0x%06x data[0]=0x%02x",
                                       device_index, m_addr, miso_byte), EVM_DEBUG);
                end else begin
                    m_rw_addr = m_addr;
                    m_state   = FSM_WRITE;
                    write_count++;
                    log_info($sformatf("[SPI DEV%0d] WRITE addr=0x%06x", device_index, m_addr), EVM_DEBUG);
                end
            end
            
        end else if (m_state == FSM_READ) begin
            // READ phase: mosi_byte is don't-care; return next memory byte on MISO
            mem_addr  = m_rw_addr % longint'(mem_size_bytes);
            miso_byte = byte'(mem.read_byte(mem_addr));
            m_rw_addr = m_rw_addr + 1;
            
        end else if (m_state == FSM_WRITE) begin
            // WRITE phase: store mosi_byte into memory
            mem_addr = m_rw_addr % longint'(mem_size_bytes);
            mem.write_byte(mem_addr, mosi_byte);
            m_rw_addr = m_rw_addr + 1;
            
        end else if (m_state == FSM_ID) begin
            // READ ID: send device ID bytes (3 bytes: manufacturer, mem type, capacity)
            m_id_idx = m_id_idx + 1;
            case (m_id_idx)
                1: miso_byte = device_id[15:8];
                2: miso_byte = device_id[7:0];
                default: miso_byte = 8'hFF;
            endcase
            
        end  // FSM_OTHER: miso_byte stays 0xFF
        
        m_byte_num = m_byte_num + 1;
        return miso_byte;
    endfunction
    
    //==========================================================================
    // Protocol: call when CS_N deasserts — complete transfer logging
    //==========================================================================
    function void end_transfer();
        log_info($sformatf("[SPI DEV%0d] Transfer complete: %0d bytes, cmd=0x%02x",
                           device_index, m_byte_num, m_cmd), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // Backdoor API — load/inspect memory without SPI protocol
    //==========================================================================
    
    // Write one byte directly
    function void load_byte(int addr, byte data);
        if (addr < mem_size_bytes)
            mem.write_byte(longint'(addr), data);
        else
            log_error($sformatf("[SPI DEV%0d] Backdoor addr 0x%0x out of range (size=%0d)",
                                device_index, addr, mem_size_bytes));
    endfunction
    
    // Read one byte directly (non-destructive peek)
    function byte peek_byte(int addr);
        if (addr < mem_size_bytes)
            return mem.read_byte(longint'(addr));
        else begin
            log_error($sformatf("[SPI DEV%0d] Backdoor peek addr 0x%0x out of range",
                                device_index, addr));
            return 8'hFF;
        end
    endfunction
    
    // Load a byte array starting at base_addr
    function void load_array(int base_addr, byte data[]);
        int i;
        int n;
        n = data.size();
        for (i = 0; i < n; i++) begin
            if ((base_addr + i) < mem_size_bytes)
                mem.write_byte(longint'(base_addr + i), data[i]);
        end
        log_info($sformatf("[SPI DEV%0d] Backdoor loaded %0d bytes at addr 0x%0x",
                           device_index, n, base_addr), EVM_LOW);
    endfunction
    
    // Load from a hex file (one byte per line, hex format)
    function void load_file_hex(int base_addr, string filename);
        mem.load_from_file(filename, longint'(base_addr));
        log_info($sformatf("[SPI DEV%0d] Backdoor loaded from file: %s", device_index, filename), EVM_LOW);
    endfunction
    
    // Fill a range with a pattern (0xFF = erased flash state)
    function void fill(int base_addr, int n_bytes, byte pattern = 8'hFF);
        int i;
        for (i = 0; i < n_bytes; i++) begin
            if ((base_addr + i) < mem_size_bytes)
                mem.write_byte(longint'(base_addr + i), pattern);
        end
    endfunction
    
    // Fill entire device with 0xFF (erase)
    function void clear();
        fill(0, mem_size_bytes, 8'hFF);
        log_info($sformatf("[SPI DEV%0d] Device erased (filled with 0xFF)", device_index), EVM_LOW);
    endfunction
    
    // Dump memory contents to log (for debug)
    function void dump(int base_addr = 0, int n_bytes = -1);
        int    i;
        int    end_addr;
        string line;
        string hex_str;
        
        if (n_bytes < 0) n_bytes = mem_size_bytes - base_addr;
        end_addr = base_addr + n_bytes;
        if (end_addr > mem_size_bytes) end_addr = mem_size_bytes;
        
        log_info($sformatf("[SPI DEV%0d] Memory dump [0x%04x..0x%04x]:",
                           device_index, base_addr, end_addr - 1), EVM_LOW);
        
        i = base_addr;
        while (i < end_addr) begin
            int  j;
            int  row_end;
            line = $sformatf("  0x%04x: ", i);
            row_end = i + 16;
            if (row_end > end_addr) row_end = end_addr;
            for (j = i; j < row_end; j++) begin
                line = {line, $sformatf("%02x ", peek_byte(j))};
            end
            log_info(line, EVM_LOW);
            i = i + 16;
        end
    endfunction
    
    virtual function string convert2string();
        return $sformatf("SPI_DEV[%0d]: size=%0dB addr_bytes=%0d rd=0x%02x wr=0x%02x R/W=%0d/%0d",
                         device_index, mem_size_bytes, addr_bytes,
                         read_cmd, write_cmd, read_count, write_count);
    endfunction
    
    virtual function string get_type_name();
        return "evm_spi_device_model";
    endfunction
    
endclass : evm_spi_device_model
