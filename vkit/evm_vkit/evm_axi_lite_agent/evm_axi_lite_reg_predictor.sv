//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_write_predictor
// Description: Concrete RAL predictor for AXI4-Lite write transactions.
//              Extends the generic evm_reg_predictor and implements the three
//              abstract methods for evm_axi_lite_write_txn.
//
//              Connect to the monitor's ap_write port:
//
//                // In env connect_phase:
//                agent.monitor.ap_write.connect(
//                    write_predictor.analysis_imp.get_mailbox());
//
//              The predictor will automatically update the RAL mirror
//              whenever a write transaction is observed on the bus.
//
// Class: evm_axi_lite_read_predictor  
// Description: Concrete RAL predictor for AXI4-Lite read transactions.
//              Connects to ap_read and validates reads against the mirror.
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

//------------------------------------------------------------------------------
// Write Predictor - Updates mirror on observed writes
//------------------------------------------------------------------------------
class evm_axi_lite_write_predictor extends evm_reg_predictor#(evm_axi_lite_write_txn);
    
    function new(string name = "axi_lite_write_predictor", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Extract address from AXI-Lite write transaction
    virtual function bit [63:0] get_addr(evm_axi_lite_write_txn txn);
        return {32'h0, txn.addr};
    endfunction
    
    // Extract data from AXI-Lite write transaction
    virtual function bit [63:0] get_data(evm_axi_lite_write_txn txn);
        return {32'h0, txn.data};
    endfunction
    
    // Write transactions are always writes
    virtual function bit is_write(evm_axi_lite_write_txn txn);
        return 1;
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_write_predictor";
    endfunction
    
endclass : evm_axi_lite_write_predictor

//------------------------------------------------------------------------------
// Read Predictor - Validates reads against mirror
//------------------------------------------------------------------------------
class evm_axi_lite_read_predictor extends evm_reg_predictor#(evm_axi_lite_read_txn);
    
    function new(string name = "axi_lite_read_predictor", evm_component parent = null);
        super.new(name, parent);
        check_reads = 1;  // Enable read checking by default
    endfunction
    
    // Extract address from AXI-Lite read transaction
    virtual function bit [63:0] get_addr(evm_axi_lite_read_txn txn);
        return {32'h0, txn.addr};
    endfunction
    
    // Extract data from AXI-Lite read transaction
    virtual function bit [63:0] get_data(evm_axi_lite_read_txn txn);
        return {32'h0, txn.data};
    endfunction
    
    // Read transactions are reads (returns 0 = not a write)
    virtual function bit is_write(evm_axi_lite_read_txn txn);
        return 0;
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_read_predictor";
    endfunction
    
endclass : evm_axi_lite_read_predictor
