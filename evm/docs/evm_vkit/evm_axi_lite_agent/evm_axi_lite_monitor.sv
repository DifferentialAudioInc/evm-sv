//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_monitor
// Description: AXI4-Lite Monitor for EVM
//              Monitors and logs AXI-Lite transactions
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

class evm_axi_lite_monitor extends evm_monitor#(virtual evm_axi_lite_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_axi_lite_cfg cfg;
    
    int write_observed = 0;
    int read_observed = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_monitor", evm_component parent = null, evm_axi_lite_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
    endfunction
    
    //==========================================================================
    // Main Phase - Monitor transactions
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        log_info("AXI-Lite Monitor started", EVM_LOW);
        
        fork
            monitor_writes();
            monitor_reads();
        join_none
    endtask
    
    //==========================================================================
    // Monitor Write Transactions
    //==========================================================================
    task monitor_writes();
        logic [31:0] addr, data;
        logic [3:0] strb;
        logic [1:0] resp;
        
        forever begin
            // Wait for write address
            @(posedge vif.aclk);
            if (vif.awvalid && vif.awready) begin
                addr = vif.awaddr;
                
                // Also capture write data (may come before or after AW)
                fork
                    begin
                        while (!(vif.wvalid && vif.wready)) @(posedge vif.aclk);
                        data = vif.wdata;
                        strb = vif.wstrb;
                    end
                join_none
                
                // Wait for write response
                while (!vif.bvalid) @(posedge vif.aclk);
                resp = vif.bresp;
                
                log_info($sformatf("Monitored WRITE: Addr=0x%08h Data=0x%08h Strb=0x%h Resp=%s", 
                         addr, data, strb, resp_to_string(resp)), EVM_LOW);
                write_observed++;
            end
        end
    endtask
    
    //==========================================================================
    // Monitor Read Transactions
    //==========================================================================
    task monitor_reads();
        logic [31:0] addr, data;
        logic [1:0] resp;
        
        forever begin
            // Wait for read address
            @(posedge vif.aclk);
            if (vif.arvalid && vif.arready) begin
                addr = vif.araddr;
                
                // Wait for read data
                while (!vif.rvalid) @(posedge vif.aclk);
                data = vif.rdata;
                resp = vif.rresp;
                
                log_info($sformatf("Monitored READ: Addr=0x%08h Data=0x%08h Resp=%s", 
                         addr, data, resp_to_string(resp)), EVM_LOW);
                read_observed++;
            end
        end
    endtask
    
    //==========================================================================
    // Utility Functions
    //==========================================================================
    function string resp_to_string(logic [1:0] resp);
        case (resp)
            2'b00: return "OKAY";
            2'b01: return "EXOKAY";
            2'b10: return "SLVERR";
            2'b11: return "DECERR";
            default: return "UNKNOWN";
        endcase
    endfunction
    
    function void print_stats();
        log_info("=== AXI-Lite Monitor Statistics ===", EVM_HIGH);
        log_info($sformatf("Writes Observed: %0d", write_observed), EVM_HIGH);
        log_info($sformatf("Reads Observed:  %0d", read_observed), EVM_HIGH);
    endfunction
    
endclass : evm_axi_lite_monitor
