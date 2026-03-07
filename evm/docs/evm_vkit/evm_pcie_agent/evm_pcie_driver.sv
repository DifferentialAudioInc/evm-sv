//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_pcie_driver
// Description: PCIe Bus Functional Model driver for EVM
//              Simplified PCIe transaction generator
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

class evm_pcie_driver extends evm_driver#(virtual evm_pcie_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_pcie_cfg cfg;
    
    //==========================================================================
    // Transaction Queue
    //==========================================================================
    typedef struct {
        bit [63:0] addr;
        bit [31:0] data;
        bit        is_write;
        int        size_bytes;
    } pcie_trans_t;
    
    pcie_trans_t trans_queue[$];
    
    //==========================================================================
    // Configuration (local copies)
    //==========================================================================
    bit [15:0] device_id;
    bit [15:0] vendor_id;
    int        link_speed;  // 1=Gen1, 2=Gen2, 3=Gen3
    int        link_width;  // 1, 2, 4, 8, 16
    
    bit running = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_pcie_driver", evm_component parent = null, evm_pcie_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
        if (cfg != null) begin
            device_id  = cfg.device_id;
            vendor_id  = cfg.vendor_id;
            link_speed = cfg.link_speed;
            link_width = cfg.link_width;
        end else begin
            device_id  = 16'hDEAD;
            vendor_id  = 16'hBEEF;
            link_speed = 2;  // Gen2
            link_width = 4;  // x4
        end
    endfunction
    
    //==========================================================================
    // Configuration Methods
    //==========================================================================
    function void configure(bit [15:0] dev_id, bit [15:0] vend_id, 
                           int speed = 2, int width = 4);
        device_id = dev_id;
        vendor_id = vend_id;
        link_speed = speed;
        link_width = width;
        
        vif.device_id = device_id;
        vif.vendor_id = vendor_id;
        vif.link_speed = link_speed;
        vif.link_width = link_width;
        
        log_info($sformatf("PCIe configured: DevID=0x%04h VendID=0x%04h Gen%0d x%0d", 
                 dev_id, vend_id, speed, width), EVM_MED);
    endfunction
    
    //==========================================================================
    // Main Phase - Start PCIe operations
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        running = 1;
        log_info("Starting PCIe BFM", EVM_LOW);
        
        fork
            process_transactions();
        join_none
    endtask
    
    //==========================================================================
    // Link Control
    //==========================================================================
    task link_training();
        log_info("Starting PCIe link training...", EVM_MED);
        #1us;
        vif.link_up = 1;
        log_info($sformatf("PCIe Link UP: Gen%0d x%0d", link_speed, link_width), EVM_MED);
    endtask
    
    task link_down();
        vif.link_up = 0;
        log_info("PCIe Link DOWN", EVM_MED);
    endtask
    
    function bit is_link_up();
        return vif.link_up;
    endfunction
    
    //==========================================================================
    // Memory Transaction Methods
    //==========================================================================
    task mem_write(bit [63:0] addr, bit [31:0] data, int size_bytes);
        pcie_trans_t trans;
        trans.addr = addr;
        trans.data = data;
        trans.is_write = 1;
        trans.size_bytes = size_bytes;
        trans_queue.push_back(trans);
        log_info($sformatf("PCIe MEM_WR queued: Addr=0x%016h Data=0x%08h", addr, data), EVM_LOW);
    endtask
    
    task mem_read(bit [63:0] addr, output bit [31:0] data, int size_bytes);
        pcie_trans_t trans;
        trans.addr = addr;
        trans.is_write = 0;
        trans.size_bytes = size_bytes;
        trans_queue.push_back(trans);
        
        // Wait for transaction to complete (simplified)
        wait_for_trans_complete();
        
        // Return dummy data for now (in full implementation, would return actual data)
        data = 32'hDEADBEEF;
        log_info($sformatf("PCIe MEM_RD: Addr=0x%016h Data=0x%08h", addr, data), EVM_LOW);
    endtask
    
    //==========================================================================
    // DMA Operations
    //==========================================================================
    task dma_read(bit [63:0] addr, int length_bytes);
        log_info($sformatf("PCIe DMA_RD: Addr=0x%016h Len=%0d bytes", addr, length_bytes), EVM_MED);
        // Simplified DMA read simulation
        #(length_bytes * 4ns);  // Approximate transfer time
    endtask
    
    task dma_write(bit [63:0] addr, int length_bytes);
        log_info($sformatf("PCIe DMA_WR: Addr=0x%016h Len=%0d bytes", addr, length_bytes), EVM_MED);
        // Simplified DMA write simulation
        #(length_bytes * 4ns);  // Approximate transfer time
    endtask
    
    //==========================================================================
    // Configuration Space Access
    //==========================================================================
    task cfg_read(bit [11:0] addr, output bit [31:0] data);
        if (addr == 12'h000) begin
            data[31:16] = device_id;
            data[15:0] = vendor_id;
        end else if (addr == 12'h004) begin
            data = 32'h00100007;  // Command/Status
        end else if (addr == 12'h00C) begin
            data = {8'h00, 8'h00, 8'h00, 8'h00};  // Class code
        end else begin
            data = 32'h00000000;
        end
        log_info($sformatf("PCIe CFG_RD: Addr=0x%03h Data=0x%08h", addr, data), EVM_LOW);
    endtask
    
    task cfg_write(bit [11:0] addr, bit [31:0] data);
        log_info($sformatf("PCIe CFG_WR: Addr=0x%03h Data=0x%08h", addr, data), EVM_LOW);
        // Handle configuration writes
        if (addr == 12'h004) begin
            // Command register write
        end
    endtask
    
    //==========================================================================
    // Transaction Processing
    //==========================================================================
    task process_transactions();
        pcie_trans_t trans;
        
        while (running) begin
            if (trans_queue.size() > 0) begin
                trans = trans_queue.pop_front();
                execute_transaction(trans);
            end else begin
                #10ns;
            end
        end
    endtask
    
    task execute_transaction(pcie_trans_t trans);
        // Simulate transaction on interface
        vif.trans_addr = trans.addr;
        vif.trans_data = trans.data;
        vif.trans_is_write = trans.is_write;
        vif.trans_size = (trans.size_bytes == 1) ? 0 : 
                        (trans.size_bytes == 2) ? 1 : 2;
        vif.trans_valid = 1;
        
        @(posedge vif.trans_ready);
        #10ns;
        vif.trans_valid = 0;
        #50ns;  // Transaction latency
    endtask
    
    task wait_for_trans_complete();
        #100ns;  // Simplified completion time
    endtask
    
    //==========================================================================
    // Control Methods
    //==========================================================================
    task stop();
        running = 0;
        log_info("PCIe BFM stopped", EVM_LOW);
    endtask
    
endclass : evm_pcie_driver
