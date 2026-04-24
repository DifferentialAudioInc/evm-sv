//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: uart_unit_test_env.sv
// Description: UART unit test environment.
//              Two active UART agents (A and B) connected back-to-back via
//              cross-connected interfaces in tb_top.
//              Two scoreboards verify bidirectional data transfer.
//
// Back-to-back wiring (in tb_top):
//   assign if_a.rx = if_b.tx;  // B sends → A receives
//   assign if_b.rx = if_a.tx;  // A sends → B receives
//
// Scoreboard connections:
//   sb_a_rx: checks A receives what B sent (agent_b.ap_tx → expected, agent_a.analysis_port → actual)
//   sb_b_rx: checks B receives what A sent (agent_a.ap_tx → expected, agent_b.analysis_port → actual)
//
// Usage — test calls these helpers to send + load scoreboards atomically:
//   env.send_a_to_b(data);   // insert expected into sb_b_rx, then send via agent_a
//   env.send_b_to_a(data);   // insert expected into sb_a_rx, then send via agent_b
//==============================================================================

class uart_unit_test_env extends evm_env;
    
    //==========================================================================
    // Components
    //==========================================================================
    evm_uart_agent  agent_a;    // "Side A" — A.tx → B.rx
    evm_uart_agent  agent_b;    // "Side B" — B.tx → A.rx
    uart_scoreboard sb_a_rx;    // Checks A receives what B sent
    uart_scoreboard sb_b_rx;    // Checks B receives what A sent
    evm_uart_cfg    uart_cfg;   // Shared UART configuration
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "uart_env", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // build_phase — create all components
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        
        // UART configuration: 115200 8N1
        uart_cfg = new("uart_cfg");
        uart_cfg.baud_rate = 115200;
        uart_cfg.data_bits = 8;
        uart_cfg.parity    = EVM_UART_PARITY_NONE;
        uart_cfg.stop_bits = 1.0;
        uart_cfg.compute_timing();
        
        // Create agents with shared config
        agent_a        = new("agent_a", this);
        agent_a.cfg    = uart_cfg;
        
        agent_b        = new("agent_b", this);
        agent_b.cfg    = uart_cfg;
        
        // Create scoreboards
        sb_a_rx = new("sb_a_rx", this);
        sb_b_rx = new("sb_b_rx", this);
        
        log_info("[UART ENV] Built: 2 agents (A↔B), 2 scoreboards", EVM_LOW);
    endfunction
    
    //==========================================================================
    // connect_phase — connect agents to scoreboards (actual side)
    // Connect to agent.analysis_port — agent owns the primary observable port.
    // The monitor writes to analysis_port; agent redirects it here (port aliasing).
    // Expected side is loaded manually by test via send_a_to_b/send_b_to_a
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        // A's agent.analysis_port → sb_a_rx actual (A receives what B sent)
        agent_a.analysis_port.connect(sb_a_rx.analysis_imp.get_mailbox());
        // B's agent.analysis_port → sb_b_rx actual (B receives what A sent)
        agent_b.analysis_port.connect(sb_b_rx.analysis_imp.get_mailbox());
        log_info("[UART ENV] Agent analysis ports connected to scoreboards", EVM_LOW);
    endfunction
    
    //==========================================================================
    // Convenience helpers — insert expected THEN send
    // Call these from the test to ensure expected arrives before actual.
    //==========================================================================
    
    // Send byte from A; B should receive it
    task send_a_to_b(input bit [7:0] data_byte);
        evm_uart_txn exp;
        exp      = new("exp");
        exp.data = 9'(data_byte);
        exp.is_tx = 0;  // expected on RX side
        sb_b_rx.insert_expected(exp);
        agent_a.get_driver().send_byte(9'(data_byte));
    endtask
    
    // Send byte from B; A should receive it
    task send_b_to_a(input bit [7:0] data_byte);
        evm_uart_txn exp;
        exp      = new("exp");
        exp.data = 9'(data_byte);
        exp.is_tx = 0;
        sb_a_rx.insert_expected(exp);
        agent_b.get_driver().send_byte(9'(data_byte));
    endtask
    
    // Send ASCII string from A; B should receive each character
    task send_string_a_to_b(input string str);
        int i;
        for (i = 0; i < str.len(); i++)
            send_a_to_b(byte'(str[i]));
    endtask
    
    // Send ASCII string from B; A should receive each character
    task send_string_b_to_a(input string str);
        int i;
        for (i = 0; i < str.len(); i++)
            send_b_to_a(byte'(str[i]));
    endtask
    
    virtual function string get_type_name();
        return "uart_unit_test_env";
    endfunction
    
endclass : uart_unit_test_env
