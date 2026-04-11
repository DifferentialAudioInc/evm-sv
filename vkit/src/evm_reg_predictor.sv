//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_reg_predictor #(TXN)
// Description: RAL predictor - observes bus transactions and updates the
//              register mirror model automatically.
//
//              The predictor connects to a monitor's analysis port and receives
//              every completed transaction. For writes, it updates the register
//              mirror so the model stays in sync with the DUT. For reads, it
//              optionally validates the read data against the mirror.
//
//              This is a parameterized base class. Users must extend it and
//              implement the three pure virtual methods to extract addr/data/
//              direction from their specific transaction type.
//
//              EVM provides a concrete AXI-Lite predictor in the vkit layer:
//              evm_axi_lite_reg_predictor (see evm_axi_lite_agent/).
//
//              Usage:
//                // Extend for your transaction type
//                class my_axi_predictor extends
//                    evm_reg_predictor#(evm_axi_lite_write_txn);
//
//                    virtual function bit [63:0] get_addr(evm_axi_lite_write_txn t);
//                        return t.addr;
//                    endfunction
//                    virtual function bit [63:0] get_data(evm_axi_lite_write_txn t);
//                        return t.data;
//                    endfunction
//                    virtual function bit is_write(evm_axi_lite_write_txn t);
//                        return 1;  // write_txn is always a write
//                    endfunction
//                endclass
//
//                // In env connect_phase():
//                predictor.reg_map = my_reg_map;
//                axi_agent.monitor.ap_write.connect(
//                    predictor.analysis_imp.get_mailbox());
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

virtual class evm_reg_predictor #(type TXN = evm_sequence_item) extends evm_component;
    
    //==========================================================================
    // Analysis Implementation - receives transactions from monitor
    // Connect monitor.ap_write (or ap_read) to this port
    //==========================================================================
    evm_analysis_imp#(TXN) analysis_imp;
    
    //==========================================================================
    // Register Map - set before simulation starts
    //==========================================================================
    evm_reg_map reg_map;
    
    //==========================================================================
    // Configuration
    //==========================================================================
    bit check_reads  = 0;  // Set 1 to validate reads against mirror
    bit verbose      = 0;  // Set 1 for per-transaction logging
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int write_predictions = 0;  // Registers predicted from writes
    int read_checks       = 0;  // Read checks performed
    int read_mismatches   = 0;  // Read values that didn't match mirror
    int unknown_addr      = 0;  // Transactions to unmapped addresses
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_reg_predictor", evm_component parent = null);
        super.new(name, parent);
        analysis_imp = new({name, ".analysis_imp"}, 0);
        reg_map = null;
    endfunction
    
    //==========================================================================
    // Abstract Methods - Implement in derived class for specific transaction type
    //==========================================================================
    
    // Extract bus address from transaction
    pure virtual function bit [63:0] get_addr(TXN txn);
    
    // Extract write data from transaction
    pure virtual function bit [63:0] get_data(TXN txn);
    
    // Return 1 if transaction is a write, 0 if read
    pure virtual function bit is_write(TXN txn);
    
    //==========================================================================
    // Run Phase - Continuous prediction from monitor observations
    //==========================================================================
    virtual task run_phase();
        TXN txn;
        super.run_phase();
        
        log_info("RAL predictor run_phase started", EVM_LOW);
        
        fork
            begin
                forever begin
                    if (!in_reset) begin
                        // Block until a transaction arrives from the monitor
                        analysis_imp.get(txn);
                        process_txn(txn);
                    end else begin
                        // Pause during reset
                        @(reset_deasserted);
                    end
                end
            end
            begin
                // Reset event monitor
                forever begin
                    @(reset_asserted);
                    on_reset_assert();
                    @(reset_deasserted);
                    on_reset_deassert();
                end
            end
        join_none
    endtask
    
    //==========================================================================
    // Process a single transaction - update mirror or check read data
    //==========================================================================
    virtual function void process_txn(TXN txn);
        evm_reg     csr;    // 'csr' avoids SV keyword 'reg'
        bit [63:0]  addr;
        bit [63:0]  data;
        bit         write;
        
        if (reg_map == null) begin
            log_warning("RAL predictor: reg_map not set, ignoring transaction");
            return;
        end
        
        addr  = get_addr(txn);
        data  = get_data(txn);
        write = is_write(txn);
        
        // Lookup register in the address map
        csr = reg_map.get_reg_by_address(addr);
        
        if (csr == null) begin
            unknown_addr++;
            if (verbose) begin
                log_info($sformatf("RAL predictor: no register at addr=0x%08x", 
                                  addr), EVM_DEBUG);
            end
            return;
        end
        
        if (write) begin
            // Update mirror value from observed write (is_read=0)
            csr.predict(data, 0);
            write_predictions++;
            if (verbose) begin
                log_info($sformatf("RAL predictor: WRITE to %s addr=0x%08x data=0x%08x", 
                                  csr.get_name(), addr, data), EVM_DEBUG);
            end
        end else begin
            // Optionally check read data against mirror
            if (check_reads) begin
                bit [63:0] mirror_val = csr.get();
                read_checks++;
                if (mirror_val !== data) begin
                    read_mismatches++;
                    log_error($sformatf(
                        "RAL predictor: READ MISMATCH at %s addr=0x%08x " ,
                        csr.get_name(), addr));
                    log_error($sformatf(
                        "  Expected (mirror): 0x%08x  Got: 0x%08x",
                        mirror_val, data));
                end else if (verbose) begin
                    log_info($sformatf("RAL predictor: READ OK at %s addr=0x%08x data=0x%08x",
                                      csr.get_name(), addr, data), EVM_DEBUG);
                end
            end
        end
    endfunction
    
    //==========================================================================
    // Reset Handlers - Clear prediction state on reset
    //==========================================================================
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("RAL predictor: reset asserted, model will re-sync after reset", EVM_MEDIUM);
        // Reset the register map mirror on DUT reset
        if (reg_map != null) begin
            reg_map.reset("HARD");
            log_info("RAL predictor: register map mirror reset to power-on values", EVM_MEDIUM);
        end
    endtask
    
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("RAL predictor: reset deasserted, ready to track transactions", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Report Phase
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        log_info("=== RAL Predictor Report ===", EVM_LOW);
        log_info($sformatf("  Write predictions: %0d", write_predictions), EVM_LOW);
        log_info($sformatf("  Read checks:       %0d", read_checks), EVM_LOW);
        log_info($sformatf("  Read mismatches:   %0d", read_mismatches), EVM_LOW);
        log_info($sformatf("  Unknown addresses: %0d", unknown_addr), EVM_LOW);
        if (read_mismatches > 0) begin
            log_error("RAL Predictor: read mismatches detected!");
        end
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_reg_predictor";
    endfunction
    
endclass : evm_reg_predictor
