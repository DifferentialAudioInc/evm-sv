//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_master_driver
// Description: AXI4-Lite Master Driver for EVM
//              Protocol-compliant CSR register access driver
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

class evm_axi_lite_master_driver extends evm_driver#(virtual evm_axi_lite_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi_lite_cfg cfg;
    
    int aw_delay_cycles;
    int w_delay_cycles;
    int ar_delay_cycles;
    
    bit enable_delays;
    
    // Statistics
    int write_count = 0;
    int read_count = 0;
    int write_error_count = 0;
    int read_error_count = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_master_driver", evm_component parent = null, evm_axi_lite_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
        if (cfg != null) begin
            aw_delay_cycles = cfg.aw_delay_cycles;
            w_delay_cycles  = cfg.w_delay_cycles;
            ar_delay_cycles = cfg.ar_delay_cycles;
            enable_delays   = cfg.enable_delays;
        end else begin
            aw_delay_cycles = 0;
            w_delay_cycles  = 0;
            ar_delay_cycles = 0;
            enable_delays   = 0;
        end
    endfunction
    
    //==========================================================================
    // Main Phase - Ready to accept transactions
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        log_info("AXI-Lite Master driver ready", EVM_LOW);
    endtask
    
    //==========================================================================
    // Write Transaction
    // Handles AW and W channels independently per AXI spec
    //==========================================================================
    task write(input logic [31:0] addr, 
               input logic [31:0] data,
               input logic [3:0]  strb = 4'b1111,
               output logic [1:0] resp);
        
        log_info($sformatf("AXI Write: Addr=0x%08h Data=0x%08h Strb=0x%h", 
                 addr, data, strb), EVM_LOW);
        
        // Check address alignment
        if (addr[1:0] != 2'b00) begin
            log_error($sformatf("Write address not word-aligned: 0x%08h", addr));
        end
        
        // Fork both address and data channels (can complete independently)
        fork
            write_address_channel(addr);
            write_data_channel(data, strb);
        join
        
        // Wait for write response
        write_response_channel(resp);
        
        // Update statistics
        write_count++;
        if (resp != 2'b00) begin
            write_error_count++;
            log_error($sformatf("Write error response: 0x%h", resp));
        end
    endtask
    
    //==========================================================================
    // Write Address Channel
    //==========================================================================
    task write_address_channel(input logic [31:0] addr);
        // Optional delay
        if (enable_delays && aw_delay_cycles > 0) begin
            repeat(aw_delay_cycles) @(posedge vif.aclk);
        end
        
        // Drive address
        @(posedge vif.aclk);
        vif.awaddr  <= addr;
        vif.awprot  <= 3'b000;  // Normal, non-secure, data access
        vif.awvalid <= 1'b1;
        
        // Wait for ready
        @(posedge vif.aclk);
        while (!vif.awready) begin
            @(posedge vif.aclk);
        end
        
        // Deassert valid
        vif.awvalid <= 1'b0;
        vif.awaddr  <= '0;
    endtask
    
    //==========================================================================
    // Write Data Channel
    //==========================================================================
    task write_data_channel(input logic [31:0] data, input logic [3:0] strb);
        // Optional delay
        if (enable_delays && w_delay_cycles > 0) begin
            repeat(w_delay_cycles) @(posedge vif.aclk);
        end
        
        // Drive data
        @(posedge vif.aclk);
        vif.wdata  <= data;
        vif.wstrb  <= strb;
        vif.wvalid <= 1'b1;
        
        // Wait for ready
        @(posedge vif.aclk);
        while (!vif.wready) begin
            @(posedge vif.aclk);
        end
        
        // Deassert valid
        vif.wvalid <= 1'b0;
        vif.wdata  <= '0;
        vif.wstrb  <= 4'b0000;
    endtask
    
    //==========================================================================
    // Write Response Channel
    //==========================================================================
    task write_response_channel(output logic [1:0] resp);
        // Wait for valid response (bready is always high)
        @(posedge vif.aclk);
        while (!vif.bvalid) begin
            @(posedge vif.aclk);
        end
        
        // Capture response
        resp = vif.bresp;
        
        // Response acknowledged by bready (already asserted)
        @(posedge vif.aclk);
    endtask
    
    //==========================================================================
    // Read Transaction
    //==========================================================================
    task read(input  logic [31:0] addr,
              output logic [31:0] data,
              output logic [1:0]  resp);
        
        log_info($sformatf("AXI Read: Addr=0x%08h", addr), EVM_LOW);
        
        // Check address alignment
        if (addr[1:0] != 2'b00) begin
            log_error($sformatf("Read address not word-aligned: 0x%08h", addr));
        end
        
        // Send read address
        read_address_channel(addr);
        
        // Get read data
        read_data_channel(data, resp);
        
        log_info($sformatf("AXI Read Complete: Addr=0x%08h Data=0x%08h Resp=0x%h", 
                 addr, data, resp), EVM_LOW);
        
        // Update statistics
        read_count++;
        if (resp != 2'b00) begin
            read_error_count++;
            log_error($sformatf("Read error response: 0x%h", resp));
        end
    endtask
    
    //==========================================================================
    // Read Address Channel
    //==========================================================================
    task read_address_channel(input logic [31:0] addr);
        // Optional delay
        if (enable_delays && ar_delay_cycles > 0) begin
            repeat(ar_delay_cycles) @(posedge vif.aclk);
        end
        
        // Drive address
        @(posedge vif.aclk);
        vif.araddr  <= addr;
        vif.arprot  <= 3'b000;  // Normal, non-secure, data access
        vif.arvalid <= 1'b1;
        
        // Wait for ready
        @(posedge vif.aclk);
        while (!vif.arready) begin
            @(posedge vif.aclk);
        end
        
        // Deassert valid
        vif.arvalid <= 1'b0;
        vif.araddr  <= '0;
    endtask
    
    //==========================================================================
    // Read Data Channel
    //==========================================================================
    task read_data_channel(output logic [31:0] data, output logic [1:0] resp);
        // Wait for valid data (rready is always high)
        @(posedge vif.aclk);
        while (!vif.rvalid) begin
            @(posedge vif.aclk);
        end
        
        // Capture data and response
        data = vif.rdata;
        resp = vif.rresp;
        
        // Data acknowledged by rready (already asserted)
        @(posedge vif.aclk);
    endtask
    
    //==========================================================================
    // Convenience Methods
    //==========================================================================
    
    // Write with automatic error checking
    task write_check(input logic [31:0] addr, 
                     input logic [31:0] data,
                     input logic [3:0]  strb = 4'b1111);
        logic [1:0] resp;
        write(addr, data, strb, resp);
        if (resp != 2'b00) begin
            log_error($sformatf("Write failed at 0x%08h with resp=0x%h", addr, resp));
        end
    endtask
    
    // Read with automatic error checking
    task read_check(input  logic [31:0] addr,
                    output logic [31:0] data);
        logic [1:0] resp;
        read(addr, data, resp);
        if (resp != 2'b00) begin
            log_error($sformatf("Read failed at 0x%08h with resp=0x%h", addr, resp));
        end
    endtask
    
    // Read-modify-write
    task rmw(input logic [31:0] addr,
             input logic [31:0] mask,
             input logic [31:0] value);
        logic [31:0] rdata, wdata;
        logic [1:0] resp;
        
        read(addr, rdata, resp);
        if (resp == 2'b00) begin
            wdata = (rdata & ~mask) | (value & mask);
            write(addr, wdata, 4'b1111, resp);
        end
    endtask
    
    // Poll register until condition met (with timeout)
    task poll(input logic [31:0] addr,
              input logic [31:0] mask,
              input logic [31:0] expected,
              input int timeout_cycles = 1000,
              output bit success);
        logic [31:0] data;
        logic [1:0] resp;
        int cycles = 0;
        
        success = 0;
        while (cycles < timeout_cycles) begin
            read(addr, data, resp);
            if ((data & mask) == (expected & mask)) begin
                success = 1;
                log_info($sformatf("Poll successful at 0x%08h after %0d cycles", 
                         addr, cycles), EVM_MED);
                return;
            end
            repeat(10) @(posedge vif.aclk);
            cycles += 10;
        end
        
        log_error($sformatf("Poll timeout at 0x%08h: got 0x%08h, expected 0x%08h (mask 0x%08h)", 
                  addr, data, expected, mask));
    endtask
    
    // Get statistics
    function void print_stats();
        log_info("=== AXI-Lite Master Statistics ===", EVM_HIGH);
        log_info($sformatf("Writes:       %0d", write_count), EVM_HIGH);
        log_info($sformatf("Reads:        %0d", read_count), EVM_HIGH);
        log_info($sformatf("Write Errors: %0d", write_error_count), EVM_HIGH);
        log_info($sformatf("Read Errors:  %0d", read_error_count), EVM_HIGH);
    endfunction
    
endclass : evm_axi_lite_master_driver
