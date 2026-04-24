//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_initiator_driver.sv
// Description: SPI initiator driver — EVM acts as the SPI bus master.
//              DUT is the SPI target; EVM drives SCLK, MOSI, CS_N.
//
//              Primary use case: EVM drives SPI peripherals when the DUT
//              has an SPI target (slave) interface (e.g., SPI register interface).
//
//              Provides a direct API for common operations:
//                transfer()     — raw byte exchange
//                write_mem()    — write N bytes to device at address
//                read_mem()     — read N bytes from device at address
//
//              Also supports sequencer-based driving via seq_item_port
//              when cfg.use_sequencer = 1.
//
// API — Public Interface:
//   [evm_spi_initiator_driver extends evm_driver#(virtual evm_spi_if, evm_spi_txn)]
//   cfg                                — must be set before run_phase
//   transfer(mosi[], miso[], cs)       — raw byte transfer on CS line N
//   write_mem(cs, addr, addr_n, data[])— write bytes: cmd+addr+data
//   read_mem(cs, addr, addr_n, n, out[])— read bytes: cmd+addr then capture MISO
//   send_cmd(cmd_byte, cs)             — send single command byte
//==============================================================================

class evm_spi_initiator_driver extends evm_driver#(virtual evm_spi_if, evm_spi_txn);
    
    //==========================================================================
    // Configuration reference (set by agent in create_driver)
    //==========================================================================
    evm_spi_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_initiator_driver", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // run_phase — launches sequencer processing if enabled
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_spi_initiator_driver: VIF not set — call agent.set_vif()");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_spi_initiator_driver: cfg not set — set agent.cfg before build_phase");
            return;
        end
        // Initialize idle state
        vif.sclk = (cfg.cpol == 1) ? 1'b1 : 1'b0;  // idle per CPOL
        vif.mosi = 1'b1;
        vif.cs_n = 8'hFF;  // all CS deasserted
    endtask
    
    //==========================================================================
    // main_phase — process sequence items from sequencer
    //==========================================================================
    virtual task main_phase();
        evm_spi_txn req;
        bit [7:0]   miso_data[];
        int         i;
        
        // Only run sequencer loop if connected
        if (!seq_item_port.is_connected()) return;
        
        forever begin
            if (in_reset) begin
                vif.cs_n = 8'hFF;
                vif.sclk = (cfg.cpol == 1) ? 1'b1 : 1'b0;
                @(reset_deasserted);
                continue;
            end
            
            seq_item_port.get_next_item(req);
            drive_transaction(req, miso_data);
            // Copy captured MISO back to txn
            req.data_miso = miso_data;
            seq_item_port.item_done();
        end
    endtask
    
    //==========================================================================
    // drive_transaction — drive a complete SPI transaction from a txn object
    //==========================================================================
    virtual task drive_transaction(evm_spi_txn txn, output bit [7:0] miso_out[]);
        bit [7:0]  mosi_stream[];
        bit [7:0]  miso_stream[];
        int        n_total;
        int        i;
        byte       addr_byte;
        
        // Build MOSI stream: cmd + addr bytes + data bytes
        n_total = 1 + txn.addr_num_bytes + txn.num_data_bytes;
        mosi_stream = new[n_total];
        miso_stream = new[n_total];
        
        // Command byte
        mosi_stream[0] = txn.cmd;
        
        // Address bytes (MSB first)
        for (i = 0; i < txn.addr_num_bytes; i++) begin
            int shift;
            shift = (txn.addr_num_bytes - 1 - i) * 8;
            mosi_stream[1 + i] = (txn.addr >> shift) & 8'hFF;
        end
        
        // Data bytes
        for (i = 0; i < txn.num_data_bytes; i++) begin
            mosi_stream[1 + txn.addr_num_bytes + i] = txn.get_mosi_byte(i);
        end
        
        // Execute transfer
        transfer(mosi_stream, miso_stream, txn.cs_select);
        
        // Extract data bytes from MISO stream
        if (txn.num_data_bytes > 0) begin
            int data_start;
            data_start = 1 + txn.addr_num_bytes;
            miso_out = new[txn.num_data_bytes];
            for (i = 0; i < txn.num_data_bytes; i++) begin
                miso_out[i] = miso_stream[data_start + i];
            end
        end else begin
            miso_out = new[0];
        end
    endtask
    
    //==========================================================================
    // transfer — raw byte transfer: drive mosi_bytes, capture miso_bytes
    //
    // mosi_bytes[]: bytes to drive on MOSI (sent LSB or MSB first per cfg)
    // miso_bytes[]: output array for bytes captured from MISO (same size)
    // cs:           which CS_N to assert (0-7)
    //
    // All local variables declared at top (Vivado rule)
    //==========================================================================
    virtual task transfer(
        input  bit [7:0] mosi_bytes[],
        output bit [7:0] miso_bytes[],
        input  int       cs = 0
    );
        int i;
        int n;
        int half_period_ns;
        
        n               = mosi_bytes.size();
        half_period_ns  = cfg.sclk_period_ns / 2;
        
        miso_bytes = new[n];
        
        // Assert CS_N (active low)
        vif.cs_n[cs] = 1'b0;
        
        // CS setup delay
        # (cfg.cs_setup_ns * 1ns);
        
        // Ensure SCLK is at idle level
        vif.sclk = (cfg.cpol == 1) ? 1'b1 : 1'b0;
        
        // For CPHA=0: drive first MOSI bit before first SCLK edge
        if (n > 0 && cfg.cpha == 0) begin
            int first_bit;
            if (cfg.lsb_first)
                first_bit = 0;
            else
                first_bit = cfg.word_size - 1;
            vif.mosi = mosi_bytes[0][first_bit];
        end
        
        // Transfer all bytes
        for (i = 0; i < n; i++) begin
            drive_byte(mosi_bytes[i], miso_bytes[i], half_period_ns);
        end
        
        // CS hold delay
        # (cfg.cs_hold_ns * 1ns);
        
        // Deassert CS_N
        vif.cs_n[cs] = 1'b1;
        vif.sclk     = (cfg.cpol == 1) ? 1'b1 : 1'b0;  // return to idle
        vif.mosi     = 1'b1;
        
        // CS minimum deassertion time between transfers
        # (cfg.cs_deassert_ns * 1ns);
    endtask
    
    //==========================================================================
    // drive_byte — drive one word on SCLK/MOSI, capture one word from MISO
    // All local variables at top (Vivado rule)
    //==========================================================================
    virtual task drive_byte(
        input  bit [7:0] tx_byte,
        output bit [7:0] rx_byte,
        input  int       half_ns
    );
        int i;
        int bit_pos;
        int next_bit_pos;
        
        rx_byte = 8'h00;
        
        for (i = 0; i < cfg.word_size; i++) begin
            if (cfg.lsb_first) begin
                bit_pos = i;
                next_bit_pos = i + 1;
            end else begin
                bit_pos = cfg.word_size - 1 - i;
                next_bit_pos = cfg.word_size - 2 - i;
            end
            
            if (cfg.sample_on_posedge()) begin
                // Mode 0 or Mode 3: drive MOSI before posedge, sample on posedge
                // For CPHA=1: drive MOSI on posedge, sample on negedge
                if (cfg.cpha == 0) begin
                    // MOSI already driven before first edge by caller
                    // For subsequent bits: driven on negedge (previous loop iteration)
                    // First clock edge: posedge (leading edge for CPOL=0)
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // rising edge
                    rx_byte[bit_pos] = vif.miso; // sample MISO
                    
                    // Setup next bit
                    if (i < cfg.word_size - 1) begin
                        vif.mosi = tx_byte[next_bit_pos];
                    end
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;  // falling edge (setup edge for next bit)
                end else begin
                    // CPHA=1, Mode 3: sample on posedge, drive on negedge
                    // First: negedge (setup) → drive MOSI
                    vif.mosi = tx_byte[bit_pos];
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // rising edge (sample)
                    rx_byte[bit_pos] = vif.miso;
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // falling edge
                end
            end else begin
                // Mode 1 or Mode 2: drive MOSI before negedge, sample on negedge
                if (cfg.cpha == 0) begin
                    // For Mode 2 (CPOL=1,CPHA=0): falling edge = leading edge = sample
                    if (i == 0) begin
                        vif.mosi = tx_byte[bit_pos];  // drive first bit before any edge
                    end
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // falling edge (sample)
                    rx_byte[bit_pos] = vif.miso;
                    if (i < cfg.word_size - 1) begin
                        vif.mosi = tx_byte[next_bit_pos];
                    end
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // rising edge
                end else begin
                    // CPHA=1, Mode 1: drive on rising edge, sample on falling edge
                    vif.mosi = tx_byte[bit_pos];
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // rising edge (setup)
                    # (half_ns * 1ns);
                    vif.sclk = ~vif.sclk;       // falling edge (sample)
                    rx_byte[bit_pos] = vif.miso;
                end
            end
        end
    endtask
    
    //==========================================================================
    // Direct API — write N bytes to address on device cs
    // Sends: [write_cmd][addr_bytes][data_bytes]
    //==========================================================================
    virtual task write_mem(
        input int       cs,
        input bit [31:0] addr,
        input int       addr_num_bytes,
        input bit [7:0] data[]
    );
        bit [7:0] mosi_stream[];
        bit [7:0] miso_stream[];
        int       n;
        int       i;
        evm_spi_device_model dev;
        bit [7:0] write_op;
        
        dev      = cfg.get_device(cs);
        write_op = (dev != null) ? dev.write_cmd : 8'h02;
        
        n = 1 + addr_num_bytes + data.size();
        mosi_stream = new[n];
        
        mosi_stream[0] = write_op;
        for (i = 0; i < addr_num_bytes; i++) begin
            int shift;
            shift = (addr_num_bytes - 1 - i) * 8;
            mosi_stream[1 + i] = (addr >> shift) & 8'hFF;
        end
        for (i = 0; i < data.size(); i++) begin
            mosi_stream[1 + addr_num_bytes + i] = data[i];
        end
        
        transfer(mosi_stream, miso_stream, cs);
        log_info($sformatf("[SPI INIT] WRITE CS[%0d] addr=0x%0x %0d bytes", cs, addr, data.size()), EVM_HIGH);
    endtask
    
    //==========================================================================
    // Direct API — read N bytes from address on device cs
    // Sends: [read_cmd][addr_bytes][N dummy bytes], captures MISO data bytes
    //==========================================================================
    virtual task read_mem(
        input  int       cs,
        input  bit [31:0] addr,
        input  int       addr_num_bytes,
        input  int       num_bytes,
        output bit [7:0] data[]
    );
        bit [7:0] mosi_stream[];
        bit [7:0] miso_stream[];
        int       n;
        int       i;
        evm_spi_device_model dev;
        bit [7:0] read_op;
        
        dev     = cfg.get_device(cs);
        read_op = (dev != null) ? dev.read_cmd : 8'h03;
        
        n = 1 + addr_num_bytes + num_bytes;
        mosi_stream = new[n];
        
        mosi_stream[0] = read_op;
        for (i = 0; i < addr_num_bytes; i++) begin
            int shift;
            shift = (addr_num_bytes - 1 - i) * 8;
            mosi_stream[1 + i] = (addr >> shift) & 8'hFF;
        end
        // Dummy bytes for read phase
        for (i = 0; i < num_bytes; i++) begin
            mosi_stream[1 + addr_num_bytes + i] = 8'hFF;
        end
        
        transfer(mosi_stream, miso_stream, cs);
        
        // Extract data from MISO (after cmd + addr bytes)
        data = new[num_bytes];
        for (i = 0; i < num_bytes; i++) begin
            data[i] = miso_stream[1 + addr_num_bytes + i];
        end
        
        log_info($sformatf("[SPI INIT] READ CS[%0d] addr=0x%0x %0d bytes", cs, addr, num_bytes), EVM_HIGH);
    endtask
    
    //==========================================================================
    // Direct API — send single command byte (no addr, no data)
    //==========================================================================
    virtual task send_cmd(input bit [7:0] cmd_byte, input int cs = 0);
        bit [7:0] mosi_stream[];
        bit [7:0] miso_stream[];
        
        mosi_stream    = new[1];
        mosi_stream[0] = cmd_byte;
        transfer(mosi_stream, miso_stream, cs);
        log_info($sformatf("[SPI INIT] CMD=0x%02x on CS[%0d]", cmd_byte, cs), EVM_HIGH);
    endtask
    
    //==========================================================================
    // Reset handlers
    //==========================================================================
    virtual task on_reset_assert();
        if (vif != null) begin
            vif.cs_n = 8'hFF;
            vif.sclk = (cfg != null && cfg.cpol == 1) ? 1'b1 : 1'b0;
            vif.mosi = 1'b1;
        end
    endtask
    
    virtual function string get_type_name();
        return "evm_spi_initiator_driver";
    endfunction
    
endclass : evm_spi_initiator_driver
