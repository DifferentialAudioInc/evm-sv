//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_pcie_monitor
// Description: PCIe monitor for EVM
//              Monitors PCIe transactions
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

class evm_pcie_monitor extends evm_monitor#(virtual evm_pcie_if);
    
    //==========================================================================
    // Configuration
    //==========================================================================
    evm_pcie_cfg cfg;
    
    int trans_count = 0;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_pcie_monitor", evm_component parent = null, evm_pcie_cfg cfg = null);
        super.new(name, parent);
        this.cfg = cfg;
    endfunction
    
    //==========================================================================
    // Main Phase - Monitor PCIe transactions
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        log_info("Starting PCIe monitoring", EVM_LOW);
        
        fork
            monitor_transactions();
            monitor_link_status();
        join_none
    endtask
    
    //==========================================================================
    // Monitoring Tasks
    //==========================================================================
    task monitor_transactions();
        forever begin
            @(posedge vif.trans_valid);
            trans_count++;
            
            if (vif.trans_is_write) begin
                log_info($sformatf("Monitored WR: Addr=0x%016h Data=0x%08h [#%0d]", 
                         vif.trans_addr, vif.trans_data, trans_count), EVM_LOW);
            end else begin
                log_info($sformatf("Monitored RD: Addr=0x%016h [#%0d]", 
                         vif.trans_addr, trans_count), EVM_LOW);
            end
        end
    endtask
    
    task monitor_link_status();
        bit prev_link_up = 0;
        
        forever begin
            #100ns;
            if (vif.link_up != prev_link_up) begin
                prev_link_up = vif.link_up;
                if (vif.link_up) begin
                    log_info($sformatf("PCIe link UP detected: Gen%0d x%0d", 
                             vif.link_speed, vif.link_width), EVM_MED);
                end else begin
                    log_info("PCIe link DOWN detected", EVM_MED);
                end
            end
        end
    endtask
    
    function int get_trans_count();
        return trans_count;
    endfunction
    
endclass : evm_pcie_monitor
