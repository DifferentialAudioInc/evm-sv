//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi4_full_monitor
// Description: AXI4 Full Monitor for EVM
//              Monitors burst transactions and publishes at channel and
//              composite transaction granularity.
//
//              Channel-level ports (one transaction per AXI handshake):
//                ap_aw  - AW channel (write address + burst info)
//                ap_w   - W  channel (one per beat, with beat_num and last)
//                ap_b   - B  channel (write response)
//                ap_ar  - AR channel (read address + burst info)
//                ap_r   - R  channel (one per beat, with beat_num and last)
//
//              Composite ports (one per complete burst transaction):
//                ap_write - Complete write burst (AW + all W beats + B)
//                ap_read  - Complete read  burst (AR + all R beats)
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

class evm_axi4_full_monitor extends evm_monitor#(virtual evm_axi4_full_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi4_full_cfg cfg;
    
    //==========================================================================
    // Channel-Level Analysis Ports
    //==========================================================================
    evm_analysis_port#(evm_axi4_aw_txn)    ap_aw;
    evm_analysis_port#(evm_axi4_w_txn)     ap_w;
    evm_analysis_port#(evm_axi4_b_txn)     ap_b;
    evm_analysis_port#(evm_axi4_ar_txn)    ap_ar;
    evm_analysis_port#(evm_axi4_r_txn)     ap_r;
    
    //==========================================================================
    // Composite Transaction Ports
    //==========================================================================
    evm_analysis_port#(evm_axi4_write_txn) ap_write;
    evm_analysis_port#(evm_axi4_read_txn)  ap_read;
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int writes_observed   = 0;
    int reads_observed    = 0;
    int write_beats_total = 0;
    int read_beats_total  = 0;
    int write_errors      = 0;
    int read_errors       = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi4_full_monitor", 
                 evm_component parent = null,
                 evm_axi4_full_cfg cfg = null);
        super.new(name, parent);
        // Avoid 'new' in ternary — xvlog compatibility
        if (cfg != null) this.cfg = cfg;
        else this.cfg = new("cfg");
        
        ap_aw    = new({name, ".ap_aw"},    this);
        ap_w     = new({name, ".ap_w"},     this);
        ap_b     = new({name, ".ap_b"},     this);
        ap_ar    = new({name, ".ap_ar"},    this);
        ap_r     = new({name, ".ap_r"},     this);
        ap_write = new({name, ".ap_write"}, this);
        ap_read  = new({name, ".ap_read"},  this);
    endfunction
    
    //==========================================================================
    // Run Phase - Fork write and read monitoring threads
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        
        if (vif == null) begin
            log_error("AXI4 Full Monitor: VIF not set");
            return;
        end
        
        log_info("AXI4 Full Monitor: continuous monitoring started", EVM_LOW);
        
        fork
            monitor_writes();
            monitor_reads();
        join_none
    endtask
    
    //==========================================================================
    // Reset Handlers
    //==========================================================================
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("AXI4 Monitor: paused due to reset", EVM_MEDIUM);
    endtask
    
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("AXI4 Monitor: resumed after reset", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Monitor Write Transactions
    // Waits for AW, captures W beats (tracking WLAST), then captures B.
    //==========================================================================
    local task monitor_writes();
        forever begin
            evm_axi4_aw_txn    aw_txn;
            evm_axi4_w_txn     w_txn;
            evm_axi4_b_txn     b_txn;
            evm_axi4_write_txn write_txn;
            int                num_beats;
            
            if (in_reset) begin @(reset_deasserted); continue; end
            
            @(posedge vif.aclk);
            if (!vif.awvalid || !vif.aresetn) continue;
            
            // Capture AW handshake
            while (!(vif.awvalid && vif.awready)) @(posedge vif.aclk);
            
            aw_txn         = new("aw4_txn");
            aw_txn.id      = vif.awid[7:0];
            aw_txn.addr    = vif.awaddr[31:0];
            aw_txn.len     = vif.awlen;
            aw_txn.size    = vif.awsize;
            aw_txn.burst   = vif.awburst;
            aw_txn.lock    = vif.awlock;
            aw_txn.cache   = vif.awcache;
            aw_txn.prot    = vif.awprot;
            aw_txn.qos     = vif.awqos;
            aw_txn.time_ns = $realtime;
            ap_aw.write(aw_txn);
            
            num_beats  = int'(vif.awlen) + 1;
            write_txn  = new("write4_txn");
            write_txn.id           = aw_txn.id;
            write_txn.addr         = aw_txn.addr;
            write_txn.len          = aw_txn.len;
            write_txn.size         = aw_txn.size;
            write_txn.burst        = aw_txn.burst;
            write_txn.prot         = aw_txn.prot;
            write_txn.aw_time_ns   = aw_txn.time_ns;
            write_txn.data         = new[num_beats];
            write_txn.strb         = new[num_beats];
            
            // Capture all W beats
            for (int beat = 0; beat < num_beats; beat++) begin
                if (in_reset) break;
                @(posedge vif.aclk);
                while (!(vif.wvalid && vif.wready)) @(posedge vif.aclk);
                
                w_txn          = new("w4_txn");
                w_txn.data     = vif.wdata[63:0];
                w_txn.strb     = vif.wstrb[7:0];
                w_txn.last     = vif.wlast;
                w_txn.beat_num = beat;
                w_txn.time_ns  = $realtime;
                ap_w.write(w_txn);
                
                write_txn.data[beat]    = w_txn.data;
                write_txn.strb[beat]    = w_txn.strb;
                write_txn.last_w_time_ns = w_txn.time_ns;
                write_beats_total++;
                
                // Warn if WLAST timing is unexpected
                if (beat == num_beats-1 && !vif.wlast) begin
                    log_error($sformatf("AXI4 Monitor: WLAST not seen on last beat %0d", beat));
                end
                if (beat < num_beats-1 && vif.wlast) begin
                    log_error($sformatf("AXI4 Monitor: Early WLAST on beat %0d (expected beat %0d)",
                                       beat, num_beats-1));
                end
            end
            
            // Capture B channel response
            @(posedge vif.aclk);
            while (!(vif.bvalid && vif.bready)) @(posedge vif.aclk);
            
            b_txn         = new("b4_txn");
            b_txn.id      = vif.bid[7:0];
            b_txn.resp    = vif.bresp;
            b_txn.time_ns = $realtime;
            ap_b.write(b_txn);
            
            write_txn.resp       = b_txn.resp;
            write_txn.b_time_ns  = b_txn.time_ns;
            ap_write.write(write_txn);
            
            writes_observed++;
            if (!b_txn.is_okay()) write_errors++;
            
            log_info($sformatf("Observed %s", write_txn.convert2string()), EVM_LOW);
        end
    endtask
    
    //==========================================================================
    // Monitor Read Transactions
    // Waits for AR, captures all R beats (tracking RLAST).
    //==========================================================================
    local task monitor_reads();
        forever begin
            evm_axi4_ar_txn   ar_txn;
            evm_axi4_r_txn    r_txn;
            evm_axi4_read_txn read_txn;
            int               num_beats;
            
            if (in_reset) begin @(reset_deasserted); continue; end
            
            @(posedge vif.aclk);
            if (!vif.arvalid || !vif.aresetn) continue;
            
            // Capture AR handshake
            while (!(vif.arvalid && vif.arready)) @(posedge vif.aclk);
            
            ar_txn         = new("ar4_txn");
            ar_txn.id      = vif.arid[7:0];
            ar_txn.addr    = vif.araddr[31:0];
            ar_txn.len     = vif.arlen;
            ar_txn.size    = vif.arsize;
            ar_txn.burst   = vif.arburst;
            ar_txn.lock    = vif.arlock;
            ar_txn.cache   = vif.arcache;
            ar_txn.prot    = vif.arprot;
            ar_txn.qos     = vif.arqos;
            ar_txn.time_ns = $realtime;
            ap_ar.write(ar_txn);
            
            num_beats = int'(vif.arlen) + 1;
            read_txn  = new("read4_txn");
            read_txn.id         = ar_txn.id;
            read_txn.addr       = ar_txn.addr;
            read_txn.len        = ar_txn.len;
            read_txn.size       = ar_txn.size;
            read_txn.burst      = ar_txn.burst;
            read_txn.prot       = ar_txn.prot;
            read_txn.ar_time_ns = ar_txn.time_ns;
            read_txn.data       = new[num_beats];
            read_txn.resp       = new[num_beats];
            
            // Capture all R beats
            for (int beat = 0; beat < num_beats; beat++) begin
                if (in_reset) break;
                @(posedge vif.aclk);
                while (!(vif.rvalid && vif.rready)) @(posedge vif.aclk);
                
                r_txn          = new("r4_txn");
                r_txn.id       = vif.rid[7:0];
                r_txn.data     = vif.rdata[63:0];
                r_txn.resp     = vif.rresp;
                r_txn.last     = vif.rlast;
                r_txn.beat_num = beat;
                r_txn.time_ns  = $realtime;
                ap_r.write(r_txn);
                
                read_txn.data[beat]       = r_txn.data;
                read_txn.resp[beat]       = r_txn.resp;
                read_txn.last_r_time_ns   = r_txn.time_ns;
                read_beats_total++;
                
                if (beat == num_beats-1 && !vif.rlast) begin
                    log_error($sformatf("AXI4 Monitor: RLAST not seen on last beat %0d", beat));
                end
            end
            
            ap_read.write(read_txn);
            reads_observed++;
            if (!read_txn.all_okay()) read_errors++;
            
            log_info($sformatf("Observed %s", read_txn.convert2string()), EVM_LOW);
        end
    endtask
    
    //==========================================================================
    // Report Phase
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        log_info("=== AXI4 Full Monitor Statistics ===", EVM_HIGH);
        log_info($sformatf("  Writes: %0d (%0d beats, %0d errors)",
                          writes_observed, write_beats_total, write_errors), EVM_HIGH);
        log_info($sformatf("  Reads:  %0d (%0d beats, %0d errors)",
                          reads_observed, read_beats_total, read_errors), EVM_HIGH);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_full_monitor";
    endfunction
    
endclass : evm_axi4_full_monitor
