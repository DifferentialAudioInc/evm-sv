//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi4_full_master_driver
// Description: AXI4 Full Master Driver for EVM
//              Supports burst transactions with full protocol compliance.
//              Data width: 64-bit (matching default interface parameters).
//
//              Direct-call API (no sequencer required):
//                write_single(addr, data, id)
//                read_single(addr, id) → data
//                write_burst(addr, data[], id)
//                read_burst(addr, num_beats, id) → data[]
//
//              Protocol compliance:
//                - AW and W channels driven simultaneously (INCR burst)
//                - WLAST asserted on final W beat
//                - Handles READY backpressure on all channels
//                - Full reset support via run_phase() + on_reset_assert()
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

class evm_axi4_full_master_driver extends evm_driver#(virtual evm_axi4_full_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi4_full_cfg cfg;
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int write_count       = 0;
    int read_count        = 0;
    int write_beat_count  = 0;
    int read_beat_count   = 0;
    int write_error_count = 0;
    int read_error_count  = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi4_full_master_driver", 
                 evm_component parent = null,
                 evm_axi4_full_cfg cfg = null);
        super.new(name, parent);
        this.cfg = (cfg != null) ? cfg : new("cfg");
    endfunction
    
    //==========================================================================
    // Run Phase - Reset monitoring (stimulus in main_phase via direct calls)
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        
        if (vif == null) begin
            log_warning("AXI4 driver: VIF not set, skipping reset monitor");
            return;
        end
        
        // Assert bready/rready continuously (configurable)
        fork
            if (cfg.always_bready) drive_bready_always();
            if (cfg.always_rready) drive_rready_always();
        join_none
    endtask
    
    //==========================================================================
    // Main Phase - idle notification only
    //==========================================================================
    virtual task main_phase();
        if (vif == null) begin
            log_error("AXI4 Full driver: virtual interface not set");
            return;
        end
        log_info("AXI4 Full master driver ready", EVM_LOW);
    endtask
    
    //==========================================================================
    // Reset Handlers
    //==========================================================================
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("AXI4 driver: reset asserted, idling all channels", EVM_MEDIUM);
        if (vif != null) begin
            // Idle all output signals
            @(posedge vif.aclk);
            vif.awvalid <= 0; vif.awid <= '0; vif.awaddr <= '0;
            vif.wvalid  <= 0; vif.wdata <= '0; vif.wstrb <= '0; vif.wlast <= 0;
            vif.bready  <= cfg.always_bready;
            vif.arvalid <= 0; vif.arid <= '0; vif.araddr <= '0;
            vif.rready  <= cfg.always_rready;
        end
    endtask
    
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("AXI4 driver: reset deasserted, ready", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Write Single Beat (convenience wrapper for write_burst with len=0)
    //==========================================================================
    task write_single(
        input  logic [31:0] addr,
        input  logic [63:0] data,
        input  logic [7:0]  id    = 8'h00,
        input  logic [7:0]  strb  = 8'hFF,
        output logic [1:0]  resp
    );
        logic [63:0] data_arr[];
        logic [7:0]  strb_arr[];
        data_arr = new[1]; data_arr[0] = data;
        strb_arr = new[1]; strb_arr[0] = strb;
        write_burst(addr, data_arr, strb_arr, 8'h00, cfg.get_default_size(), 
                    cfg.default_burst, id, resp);
    endtask
    
    //==========================================================================
    // Write Burst Transaction
    // Drives AW and W channels (pipelined), waits for B response.
    //==========================================================================
    task write_burst(
        input  logic [31:0] addr,
        input  logic [63:0] data[],
        input  logic [7:0]  strb[],
        input  logic [7:0]  len        = 8'h00,   // 0 = 1 beat
        input  logic [2:0]  size       = 3'b011,  // 8 bytes
        input  logic [1:0]  burst_type = 2'b01,   // INCR
        input  logic [7:0]  id         = 8'h00,
        output logic [1:0]  resp
    );
        int num_beats = int'(len) + 1;
        
        log_info($sformatf("AXI4 Write: id=%0d addr=0x%08h len=%0d(%0d beats)", 
                          id, addr, len, num_beats), EVM_LOW);
        
        // AW and W channels can be driven simultaneously
        fork
            // Drive AW channel
            begin
                if (cfg.aw_delay_cycles > 0)
                    repeat(cfg.aw_delay_cycles) @(posedge vif.aclk);
                
                @(posedge vif.aclk);
                vif.awid    <= id;
                vif.awaddr  <= addr;
                vif.awlen   <= len;
                vif.awsize  <= size;
                vif.awburst <= burst_type;
                vif.awlock  <= 1'b0;
                vif.awcache <= cfg.default_cache;
                vif.awprot  <= cfg.default_prot;
                vif.awqos   <= cfg.default_qos;
                vif.awvalid <= 1'b1;
                
                // Wait for AW handshake
                @(posedge vif.aclk);
                while (!vif.awready) @(posedge vif.aclk);
                
                vif.awvalid <= 1'b0;
                vif.awid    <= '0;
                vif.awaddr  <= '0;
            end
            
            // Drive W channel (all beats)
            begin
                for (int i = 0; i < num_beats; i++) begin
                    // Optional inter-beat delay
                    if (i > 0 && cfg.w_beat_delay > 0)
                        repeat(cfg.w_beat_delay) @(posedge vif.aclk);
                    
                    @(posedge vif.aclk);
                    vif.wdata  <= (i < data.size()) ? data[i] : '0;
                    vif.wstrb  <= (i < strb.size()) ? strb[i] : '1;
                    vif.wlast  <= (i == num_beats-1) ? 1'b1 : 1'b0;
                    vif.wvalid <= 1'b1;
                    
                    // Wait for W handshake
                    @(posedge vif.aclk);
                    while (!vif.wready) @(posedge vif.aclk);
                    
                    write_beat_count++;
                end
                
                // Deassert W
                vif.wvalid <= 1'b0;
                vif.wlast  <= 1'b0;
                vif.wdata  <= '0;
                vif.wstrb  <= '0;
            end
        join
        
        // Wait for B channel response
        // bready is always asserted (or driven by run_phase thread)
        @(posedge vif.aclk);
        while (!vif.bvalid) @(posedge vif.aclk);
        
        resp = vif.bresp;
        @(posedge vif.aclk);
        
        write_count++;
        if (resp != 2'b00) begin
            write_error_count++;
            log_error($sformatf("AXI4 Write Error: id=%0d addr=0x%08h resp=0x%h",
                               id, addr, resp));
        end else begin
            log_info($sformatf("AXI4 Write OK: id=%0d addr=0x%08h %0d beats",
                              id, addr, num_beats), EVM_LOW);
        end
    endtask
    
    //==========================================================================
    // Read Single Beat (convenience wrapper)
    //==========================================================================
    task read_single(
        input  logic [31:0] addr,
        output logic [63:0] data,
        input  logic [7:0]  id   = 8'h00,
        output logic [1:0]  resp
    );
        logic [63:0] data_arr[];
        logic [1:0]  resp_arr[];
        read_burst(addr, data_arr, 8'h00, cfg.get_default_size(),
                  cfg.default_burst, id, resp_arr);
        data = (data_arr.size() > 0) ? data_arr[0] : '0;
        resp = (resp_arr.size() > 0) ? resp_arr[0] : 2'b10; // SLVERR if empty
    endtask
    
    //==========================================================================
    // Read Burst Transaction
    // Drives AR channel, collects all R beats (identified by RLAST).
    //==========================================================================
    task read_burst(
        input  logic [31:0] addr,
        output logic [63:0] data[],
        input  logic [7:0]  len        = 8'h00,   // 0 = 1 beat
        input  logic [2:0]  size       = 3'b011,  // 8 bytes
        input  logic [1:0]  burst_type = 2'b01,   // INCR
        input  logic [7:0]  id         = 8'h00,
        output logic [1:0]  resp[]
    );
        int num_beats = int'(len) + 1;
        int beat = 0;
        
        log_info($sformatf("AXI4 Read: id=%0d addr=0x%08h len=%0d(%0d beats)",
                          id, addr, len, num_beats), EVM_LOW);
        
        // Drive AR channel
        if (cfg.ar_delay_cycles > 0)
            repeat(cfg.ar_delay_cycles) @(posedge vif.aclk);
        
        @(posedge vif.aclk);
        vif.arid    <= id;
        vif.araddr  <= addr;
        vif.arlen   <= len;
        vif.arsize  <= size;
        vif.arburst <= burst_type;
        vif.arlock  <= 1'b0;
        vif.arcache <= cfg.default_cache;
        vif.arprot  <= cfg.default_prot;
        vif.arqos   <= cfg.default_qos;
        vif.arvalid <= 1'b1;
        
        // Wait for AR handshake
        @(posedge vif.aclk);
        while (!vif.arready) @(posedge vif.aclk);
        
        vif.arvalid <= 1'b0;
        vif.arid    <= '0;
        vif.araddr  <= '0;
        
        // Collect all R beats
        data = new[num_beats];
        resp = new[num_beats];
        
        for (beat = 0; beat < num_beats; beat++) begin
            @(posedge vif.aclk);
            while (!vif.rvalid) @(posedge vif.aclk);
            
            data[beat] = vif.rdata;
            resp[beat] = vif.rresp;
            read_beat_count++;
            
            // Verify RLAST on expected last beat
            if (beat == num_beats-1 && !vif.rlast) begin
                log_error($sformatf("AXI4 Read: RLAST not asserted on beat %0d (expected last)", beat));
            end
        end
        
        read_count++;
        
        // Check for errors
        foreach (resp[i]) begin
            if (resp[i] != 2'b00) begin
                read_error_count++;
                log_error($sformatf("AXI4 Read Error: id=%0d beat=%0d resp=0x%h",
                                   id, i, resp[i]));
            end
        end
        
        log_info($sformatf("AXI4 Read OK: id=%0d addr=0x%08h %0d beats data[0]=0x%08h",
                          id, addr, num_beats, data[0]), EVM_LOW);
    endtask
    
    //==========================================================================
    // Background: Keep bready asserted
    //==========================================================================
    local task drive_bready_always();
        forever begin
            @(posedge vif.aclk);
            if (!in_reset) vif.bready <= 1'b1;
        end
    endtask
    
    //==========================================================================
    // Background: Keep rready asserted
    //==========================================================================
    local task drive_rready_always();
        forever begin
            @(posedge vif.aclk);
            if (!in_reset) vif.rready <= 1'b1;
        end
    endtask
    
    //==========================================================================
    // Print statistics
    //==========================================================================
    function void print_stats();
        log_info("=== AXI4 Full Master Statistics ===", EVM_HIGH);
        log_info($sformatf("  Writes: %0d (%0d beats, %0d errors)", 
                          write_count, write_beat_count, write_error_count), EVM_HIGH);
        log_info($sformatf("  Reads:  %0d (%0d beats, %0d errors)", 
                          read_count, read_beat_count, read_error_count), EVM_HIGH);
    endfunction
    
    virtual function void report_phase();
        super.report_phase();
        print_stats();
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_full_master_driver";
    endfunction
    
endclass : evm_axi4_full_master_driver
