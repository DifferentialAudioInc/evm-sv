//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: uart_scoreboard.sv
// Description: UART scoreboard for unit test.
//              Extends evm_scoreboard to compare UART transactions by data byte.
//              Ignores is_tx flag — compares only data content and error flags.
//
// Connection pattern (in env connect_phase):
//   // B's RX scoreboard:
//   agent_a.get_driver().ap_tx.connect(sb_b_rx.analysis_imp.get_mailbox()); // expected
//   agent_b.get_monitor().analysis_port.connect(sb_b_rx.analysis_imp.get_mailbox()); // actual
//   NOTE: use insert_expected / insert_actual pattern instead (see env)
//==============================================================================

class uart_scoreboard extends evm_scoreboard#(evm_uart_txn);
    
    function new(string name = "uart_scoreboard", evm_component parent = null);
        super.new(name, parent);
        mode = EVM_SB_FIFO;  // strict in-order checking
    endfunction
    
    //==========================================================================
    // compare_transactions — check data byte and no error flags
    //==========================================================================
    virtual function bit compare_transactions(evm_uart_txn expected, evm_uart_txn actual);
        bit match;
        match = 1;
        
        // Check data byte
        if (expected.data[7:0] !== actual.data[7:0]) begin
            log_error($sformatf("[UART SB %s] DATA MISMATCH: expected=0x%02x got=0x%02x",
                                get_name(), expected.data[7:0], actual.data[7:0]));
            match = 0;
        end
        
        // Check no framing errors
        if (actual.framing_error) begin
            log_error($sformatf("[UART SB %s] FRAMING ERROR on byte 0x%02x",
                                get_name(), actual.data[7:0]));
            match = 0;
        end
        
        // Check no parity errors
        if (actual.parity_error) begin
            log_error($sformatf("[UART SB %s] PARITY ERROR on byte 0x%02x",
                                get_name(), actual.data[7:0]));
            match = 0;
        end
        
        // Check no break condition
        if (actual.break_detect) begin
            log_warning($sformatf("[UART SB %s] BREAK detected", get_name()));
        end
        
        if (match) begin
            log_info($sformatf("[UART SB %s] MATCH: 0x%02x %s",
                               get_name(), actual.data[7:0],
                               actual.data >= 32 && actual.data <= 126 ?
                               $sformatf("'%s'", string'(byte'(actual.data))) : ""), EVM_HIGH);
        end
        
        return match;
    endfunction
    
    virtual function string get_type_name();
        return "uart_scoreboard";
    endfunction
    
endclass : uart_scoreboard
