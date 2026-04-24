//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_monitor.sv
// Description: Passive SPI bus observer.
//              Detects CS_N assertion, samples MOSI+MISO bits per CPOL/CPHA,
//              assembles bytes, decodes cmd/addr/data using cfg, and publishes
//              completed transactions on ap_txn.
//
//              Works with both initiator and target agents — purely passive.
//              Used by both evm_spi_initiator_agent and evm_spi_target_agent.
//
// API — Public Interface:
//   [evm_spi_monitor extends evm_monitor#(virtual evm_spi_if, evm_spi_txn)]
//   cfg                  — must be set before run_phase (by agent.build_phase)
//   ap_txn               — analysis port; publishes evm_spi_txn on each transfer
//   run_phase()          — continuous monitoring loop
//==============================================================================

class evm_spi_monitor extends evm_monitor#(virtual evm_spi_if, evm_spi_txn);
    
    //==========================================================================
    // Configuration reference (set by agent before build_phase)
    //==========================================================================
    evm_spi_cfg cfg;
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int txn_count = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_monitor", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // run_phase — continuous monitor loop
    // Uses run_phase per EVM pattern (parallel to sequential phases)
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_spi_monitor: VIF not set — call agent.set_vif()");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_spi_monitor: cfg not set — set agent.cfg before build_phase");
            return;
        end
        fork
            monitor_loop();
            reset_monitor();
        join_none
    endtask
    
    //==========================================================================
    // reset_monitor — pause collection on reset
    //==========================================================================
    virtual task reset_monitor();
        forever begin
            @(reset_asserted);
            log_info("[SPI MON] Reset asserted — pausing", EVM_HIGH);
            @(reset_deasserted);
            log_info("[SPI MON] Reset deasserted — resuming", EVM_HIGH);
        end
    endtask
    
    //==========================================================================
    // monitor_loop — detect CS_N, collect bytes, publish txn
    //==========================================================================
    virtual task monitor_loop();
        int          cs_sel;
        evm_spi_txn  txn;
        bit [7:0]    raw_bytes_mosi[$];
        bit [7:0]    raw_bytes_miso[$];
        bit [7:0]    mosi_byte;
        bit [7:0]    miso_byte;
        evm_spi_device_model dev;
        int          dev_addr_bytes;
        
        forever begin
            // Wait for any CS_N to go low (active)
            // Poll cs_n until one line asserts
            wait (vif.cs_n != 8'hFF);
            
            if (in_reset) begin
                @(reset_deasserted);
                continue;
            end
            
            // Identify which CS asserted (first low bit)
            cs_sel = -1;
            begin : find_cs
                int i;
                for (i = 0; i < 8; i++) begin
                    if (vif.cs_n[i] == 1'b0) begin
                        cs_sel = i;
                        break;
                    end
                end
            end
            
            if (cs_sel < 0) begin
                // Spurious — wait a bit and re-check
                #1;
                continue;
            end
            
            // Validate CS is within configured num_cs range
            if (cs_sel >= cfg.num_cs) begin
                log_warning($sformatf("[SPI MON] CS[%0d] activity detected but num_cs=%0d",
                                      cs_sel, cfg.num_cs));
            end
            
            // Get device config for addr_bytes decode
            dev = cfg.get_device(cs_sel);
            if (dev != null)
                dev_addr_bytes = dev.addr_bytes;
            else
                dev_addr_bytes = 1;  // default
            
            // Clear byte collectors
            raw_bytes_mosi.delete();
            raw_bytes_miso.delete();
            
            // Collect bytes until CS_N deasserts
            while (vif.cs_n[cs_sel] == 1'b0) begin
                collect_byte(mosi_byte, miso_byte);
                raw_bytes_mosi.push_back(mosi_byte);
                raw_bytes_miso.push_back(miso_byte);
            end
            
            // Build and publish transaction
            txn = build_txn(cs_sel, raw_bytes_mosi, raw_bytes_miso, dev_addr_bytes);
            txn.mark_completed();
            txn_count++;
            
            log_info($sformatf("[SPI MON] %s", txn.convert2string()), EVM_HIGH);
            analysis_port.write(txn);
        end
    endtask
    
    //==========================================================================
    // collect_byte — sample one byte of MOSI and MISO based on CPOL/CPHA
    // All local variables declared at top (Vivado rule)
    //==========================================================================
    virtual task collect_byte(output bit [7:0] mosi_byte, output bit [7:0] miso_byte);
        int i;
        int bit_pos;
        
        mosi_byte = 8'h00;
        miso_byte = 8'h00;
        
        for (i = 0; i < cfg.word_size; i++) begin
            // bit_pos: MSB first = (word_size-1-i), LSB first = i
            if (cfg.lsb_first)
                bit_pos = i;
            else
                bit_pos = cfg.word_size - 1 - i;
            
            // Wait for sample edge
            if (cfg.sample_on_posedge()) begin
                @(posedge vif.sclk);
            end else begin
                @(negedge vif.sclk);
            end
            
            // Sample both MOSI and MISO simultaneously on the sample edge
            mosi_byte[bit_pos] = vif.mosi;
            miso_byte[bit_pos] = vif.miso;
        end
    endtask
    
    //==========================================================================
    // build_txn — interpret raw byte stream as cmd/addr/data
    //==========================================================================
    virtual function evm_spi_txn build_txn(
        int cs_sel,
        ref bit [7:0] mosi_q[$],
        ref bit [7:0] miso_q[$],
        int addr_bytes_cfg
    );
        evm_spi_txn txn;
        int         i;
        int         n_total;
        int         data_start;
        bit [31:0]  assembled_addr;
        bit [7:0]   mosi_arr[];
        bit [7:0]   miso_arr[];
        evm_spi_device_model dev;
        
        txn = new("spi_txn");
        txn.mark_started();
        txn.cs_select  = cs_sel;
        n_total        = mosi_q.size();
        
        if (n_total == 0) begin
            txn.cmd            = 8'hFF;
            txn.num_data_bytes = 0;
            txn.data_mosi      = new[0];
            txn.data_miso      = new[0];
            return txn;
        end
        
        // First byte = command
        txn.cmd = mosi_q[0];
        
        // Determine if this is a read or write command
        dev = cfg.get_device(cs_sel);
        if (dev != null) begin
            txn.is_read = (txn.cmd == dev.read_cmd || txn.cmd == dev.read_id_cmd);
        end else begin
            txn.is_read = (txn.cmd == 8'h03);  // default READ
        end
        
        // Extract address bytes (bytes 1..addr_bytes_cfg)
        assembled_addr = 32'h0;
        data_start     = 1 + addr_bytes_cfg;
        
        if (n_total > 1) begin
            int addr_bytes_actual;
            addr_bytes_actual = (n_total - 1 < addr_bytes_cfg) ? (n_total - 1) : addr_bytes_cfg;
            txn.addr_num_bytes = addr_bytes_actual;
            for (i = 0; i < addr_bytes_actual; i++) begin
                assembled_addr = (assembled_addr << 8) | bit'(mosi_q[1 + i]);
            end
            txn.addr = assembled_addr;
        end else begin
            txn.addr_num_bytes = 0;
            data_start         = 1;
        end
        
        // Remaining bytes are data
        if (data_start < n_total) begin
            int n_data;
            n_data             = n_total - data_start;
            txn.num_data_bytes = n_data;
            mosi_arr           = new[n_data];
            miso_arr           = new[n_data];
            for (i = 0; i < n_data; i++) begin
                mosi_arr[i] = mosi_q[data_start + i];
                miso_arr[i] = miso_q[data_start + i];
            end
            txn.data_mosi = mosi_arr;
            txn.data_miso = miso_arr;
        end else begin
            txn.num_data_bytes = 0;
            txn.data_mosi      = new[0];
            txn.data_miso      = new[0];
        end
        
        return txn;
    endfunction
    
    //==========================================================================
    // report_phase
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        log_info($sformatf("[SPI MON] Total transactions captured: %0d", txn_count), EVM_LOW);
    endfunction
    
    virtual function string get_type_name();
        return "evm_spi_monitor";
    endfunction
    
endclass : evm_spi_monitor
