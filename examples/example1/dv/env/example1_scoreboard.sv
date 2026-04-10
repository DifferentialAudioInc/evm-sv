//==============================================================================
// Class: example1_scoreboard
// Description: Scoreboard for example1 (AXI Data Transform)
//
//   Observes writes on the DUT's AXI4-Lite Master output interface.
//   Compares observed result data against expected transform of DATA_IN.
//
//   Connect: master_mon.monitor.ap_write → analysis_imp
//   Expect:  test calls insert_expected(txn) after each DATA_IN write
//
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

class example1_scoreboard extends evm_scoreboard#(evm_axi_lite_write_txn);
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "example1_scoreboard", evm_component parent = null);
        super.new(name, parent);
        mode              = EVM_SB_FIFO;  // in-order results expected
        stop_on_mismatch  = 0;
    endfunction
    
    //==========================================================================
    // compare_transactions — only check data field (not address)
    //==========================================================================
    virtual function bit compare_transactions(
        evm_axi_lite_write_txn expected,
        evm_axi_lite_write_txn actual
    );
        if (expected.data !== actual.data) begin
            mismatch_count++;
            log_error($sformatf(
                "RESULT MISMATCH: expected=0x%08h  actual=0x%08h  addr=0x%08h",
                expected.data, actual.data, actual.addr));
            return 0;
        end
        
        match_count++;
        log_info($sformatf(
            "RESULT MATCH: data=0x%08h  latency=%.1fns",
            actual.data, actual.get_write_latency()), EVM_LOW);
        return 1;
    endfunction
    
    //==========================================================================
    // Helper: create expected transaction for a given transform
    //==========================================================================
    static function evm_axi_lite_write_txn make_expected(logic [31:0] data);
        evm_axi_lite_write_txn t = new("expected");
        t.addr = 32'h0000_2000;  // OUTPUT_ADDR from DUT
        t.data = data;
        t.resp = 2'b00;
        return t;
    endfunction
    
    virtual function string get_type_name();
        return "example1_scoreboard";
    endfunction
    
endclass : example1_scoreboard
