//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_monitor
// Description: AXI4-Lite Monitor for EVM
//              Monitors and publishes AXI4-Lite transactions at two levels:
//
//              Channel-level ports (fire on each AXI handshake):
//                ap_aw  - AW channel handshake (write address)
//                ap_w   - W  channel handshake (write data)
//                ap_b   - B  channel handshake (write response)
//                ap_ar  - AR channel handshake (read address)
//                ap_r   - R  channel handshake (read data)
//
//              Composite ports (fire on complete transaction):
//                ap_write - Complete write  (AW + W + B resolved)
//                ap_read  - Complete read   (AR + R resolved)
//
//              Connection examples:
//                // Scoreboard receives complete writes
//                agent.monitor.ap_write.connect(sb.analysis_imp.get_mailbox());
//
//                // RAL predictor tracks writes for mirror update
//                agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
//
//                // Protocol checker monitors all channels separately
//                agent.monitor.ap_aw.connect(proto_checker.aw_imp.get_mailbox());
//                agent.monitor.ap_b.connect(proto_checker.b_imp.get_mailbox());
//
// Author: Eric Dyer
// Date: 2026-03-05
// Updated: 2026-04-09 - Moved to run_phase, added 7 analysis ports
//==============================================================================

class evm_axi_lite_monitor extends evm_monitor#(virtual evm_axi_lite_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi_lite_cfg cfg;
    
    //==========================================================================
    // Channel-Level Analysis Ports - fire on each AXI handshake
    //==========================================================================
    evm_analysis_port#(evm_axi_lite_aw_txn)    ap_aw;    // AW channel
    evm_analysis_port#(evm_axi_lite_w_txn)     ap_w;     // W  channel
    evm_analysis_port#(evm_axi_lite_b_txn)     ap_b;     // B  channel
    evm_analysis_port#(evm_axi_lite_ar_txn)    ap_ar;    // AR channel
    evm_analysis_port#(evm_axi_lite_r_txn)     ap_r;     // R  channel
    
    //==========================================================================
    // Composite Transaction Ports - fire on complete transaction
    //==========================================================================
    evm_analysis_port#(evm_axi_lite_write_txn) ap_write; // Full write: AW+W+B
    evm_analysis_port#(evm_axi_lite_read_txn)  ap_read;  // Full read:  AR+R
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int write_observed = 0;
    int read_observed  = 0;
    int write_errors   = 0;
    int read_errors    = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_monitor", 
                 evm_component parent = null, 
                 evm_axi_lite_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
        
        // Create all analysis ports
        ap_aw    = new({name, ".ap_aw"},    this);
        ap_w     = new({name, ".ap_w"},     this);
        ap_b     = new({name, ".ap_b"},     this);
        ap_ar    = new({name, ".ap_ar"},    this);
        ap_r     = new({name, ".ap_r"},     this);
        ap_write = new({name, ".ap_write"}, this);
        ap_read  = new({name, ".ap_read"},  this);
    endfunction
    
    //==========================================================================
    // Run Phase - Continuous monitoring (replaces old main_phase)
    // Forks independent write and read monitoring threads that run forever.
    // Reset handling inherited from evm_monitor base class.
    //==========================================================================
    virtual task run_phase();
        // Call parent to start reset event monitoring thread
        super.run_phase();
        
        if (vif == null) begin
            log_error("AXI-Lite Monitor: virtual interface not set - cannot monitor");
            return;
        end
        
        log_info("AXI-Lite Monitor: continuous monitoring started", EVM_LOW);
        
        fork
            monitor_writes();
            monitor_reads();
        join_none
    endtask
    
    //==========================================================================
    // Reset Handlers - Override to pause/flush monitoring on reset
    //==========================================================================
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("AXI-Lite Monitor: paused due to reset", EVM_MEDIUM);
        // Monitor threads check in_reset flag to pause
    endtask
    
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("AXI-Lite Monitor: resumed after reset", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Monitor Write Transactions
    // Captures AW and W channels concurrently (AXI spec allows independent
    // ordering), then waits for B response to complete the transaction.
    //==========================================================================
    local task monitor_writes();
        forever begin
            evm_axi_lite_aw_txn    aw_txn;
            evm_axi_lite_w_txn     w_txn;
            evm_axi_lite_b_txn     b_txn;
            evm_axi_lite_write_txn write_txn;
            
            // Pause monitoring during reset
            if (in_reset) begin
                @(reset_deasserted);
                continue;
            end
            
            // Wait for AW valid (start of write transaction)
            @(posedge vif.aclk);
            if (!vif.awvalid || !vif.aresetn) continue;
            
            aw_txn = new("aw_txn");
            w_txn  = new("w_txn");
            
            // Capture AW and W channels concurrently
            // AXI spec: AW and W may complete in any order
            fork
                begin : aw_thread
                    // Already saw awvalid this cycle; wait for awready
                    while (!(vif.awvalid && vif.awready)) @(posedge vif.aclk);
                    aw_txn.addr    = vif.awaddr;
                    aw_txn.prot    = vif.awprot;
                    aw_txn.time_ns = $realtime;
                    ap_aw.write(aw_txn);
                end
                begin : w_thread
                    // Wait for W channel handshake (may arrive before or after AW)
                    while (!(vif.wvalid && vif.wready)) @(posedge vif.aclk);
                    w_txn.data    = vif.wdata;
                    w_txn.strb    = vif.wstrb;
                    w_txn.time_ns = $realtime;
                    ap_w.write(w_txn);
                end
            join
            
            // Wait for B channel response
            @(posedge vif.aclk);
            while (!(vif.bvalid && vif.bready)) @(posedge vif.aclk);
            
            b_txn          = new("b_txn");
            b_txn.resp     = vif.bresp;
            b_txn.time_ns  = $realtime;
            ap_b.write(b_txn);
            
            // Compose and publish complete write transaction
            write_txn            = new("write_txn");
            write_txn.addr       = aw_txn.addr;
            write_txn.data       = w_txn.data;
            write_txn.strb       = w_txn.strb;
            write_txn.prot       = aw_txn.prot;
            write_txn.resp       = b_txn.resp;
            write_txn.aw_time_ns = aw_txn.time_ns;
            write_txn.w_time_ns  = w_txn.time_ns;
            write_txn.b_time_ns  = b_txn.time_ns;
            ap_write.write(write_txn);
            
            write_observed++;
            if (!b_txn.is_okay()) write_errors++;
            
            log_info($sformatf("Observed %s", write_txn.convert2string()), EVM_LOW);
        end
    endtask
    
    //==========================================================================
    // Monitor Read Transactions
    // Waits for AR handshake, then R data to complete the read transaction.
    //==========================================================================
    local task monitor_reads();
        forever begin
            evm_axi_lite_ar_txn   ar_txn;
            evm_axi_lite_r_txn    r_txn;
            evm_axi_lite_read_txn read_txn;
            
            // Pause monitoring during reset
            if (in_reset) begin
                @(reset_deasserted);
                continue;
            end
            
            // Wait for AR valid (start of read transaction)
            @(posedge vif.aclk);
            if (!vif.arvalid || !vif.aresetn) continue;
            
            // Capture AR channel handshake
            while (!(vif.arvalid && vif.arready)) @(posedge vif.aclk);
            
            ar_txn          = new("ar_txn");
            ar_txn.addr     = vif.araddr;
            ar_txn.prot     = vif.arprot;
            ar_txn.time_ns  = $realtime;
            ap_ar.write(ar_txn);
            
            // Wait for R channel data
            @(posedge vif.aclk);
            while (!(vif.rvalid && vif.rready)) @(posedge vif.aclk);
            
            r_txn          = new("r_txn");
            r_txn.data     = vif.rdata;
            r_txn.resp     = vif.rresp;
            r_txn.time_ns  = $realtime;
            ap_r.write(r_txn);
            
            // Compose and publish complete read transaction
            read_txn             = new("read_txn");
            read_txn.addr        = ar_txn.addr;
            read_txn.data        = r_txn.data;
            read_txn.prot        = ar_txn.prot;
            read_txn.resp        = r_txn.resp;
            read_txn.ar_time_ns  = ar_txn.time_ns;
            read_txn.r_time_ns   = r_txn.time_ns;
            ap_read.write(read_txn);
            
            read_observed++;
            if (!r_txn.is_okay()) read_errors++;
            
            log_info($sformatf("Observed %s", read_txn.convert2string()), EVM_LOW);
        end
    endtask
    
    //==========================================================================
    // Statistics
    //==========================================================================
    function void print_stats();
        log_info("=== AXI-Lite Monitor Statistics ===", EVM_HIGH);
        log_info($sformatf("Writes Observed: %0d (%0d errors)", 
                          write_observed, write_errors), EVM_HIGH);
        log_info($sformatf("Reads  Observed: %0d (%0d errors)", 
                          read_observed, read_errors), EVM_HIGH);
    endfunction
    
    virtual function void report_phase();
        super.report_phase();
        print_stats();
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_axi_lite_monitor";
    endfunction
    
endclass : evm_axi_lite_monitor
