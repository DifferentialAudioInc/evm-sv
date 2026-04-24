//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: uart_basic_test.sv
// Description: UART unit test — exercises bidirectional UART communication
//              between two back-to-back UART agents.
//
// Test sequence:
//   Phase 1: A sends "Hello!" to B (6 bytes) — sequential
//   Phase 2: B sends "World!" to A (6 bytes) — sequential
//   Phase 3: A→B and B→A simultaneously (both directions at once)
//   Phase 4: Binary data bytes including 0x00, 0xFF, 0xAA, 0x55
//   Scoreboards verify each byte in order, log errors if mismatch.
//==============================================================================

class uart_basic_test extends evm_base_test;
    
    uart_unit_test_env env;
    
    function new(string name = "uart_basic_test");
        super.new(name);
    endfunction
    
    //==========================================================================
    // build_phase — create environment
    //==========================================================================
    virtual function void build_phase();
        super.build_phase();
        env = new("env", this);
    endfunction
    
    //==========================================================================
    // connect_phase — set VIFs from tb_top interface handles
    //==========================================================================
    virtual function void connect_phase();
        super.connect_phase();
        // VIFs are accessed via hierarchical path from tb_top
        env.agent_a.set_vif(tb_top.if_a);
        env.agent_b.set_vif(tb_top.if_b);
    endfunction
    
    //==========================================================================
    // main_phase — run the test stimulus
    //==========================================================================
    virtual task main_phase();
        super.main_phase();
        raise_objection("uart_basic_test");
        
        evm_report_handler::set_verbosity(EVM_HIGH);
        log_info("=== UART Unit Test Starting ===", EVM_LOW);
        log_info($sformatf("Baud rate: %0d | Bit period: %0dns",
                           env.uart_cfg.baud_rate,
                           env.uart_cfg.bit_period_ns), EVM_LOW);
        
        // ── Phase 1: A sends "Hello!" to B ──────────────────────────────────
        log_info("--- Phase 1: A→B: 'Hello!' ---", EVM_LOW);
        env.send_string_a_to_b("Hello!");
        
        // Wait for all bytes to be received (6 bytes @ 115200 = ~520us each)
        # 4000us;
        
        // ── Phase 2: B sends "World!" to A ──────────────────────────────────
        log_info("--- Phase 2: B→A: 'World!' ---", EVM_LOW);
        env.send_string_b_to_a("World!");
        # 4000us;
        
        // ── Phase 3: Simultaneous bidirectional transfer ─────────────────────
        log_info("--- Phase 3: Simultaneous A→B and B→A ---", EVM_LOW);
        fork
            begin
                // A sends binary pattern to B
                env.send_a_to_b(8'hAA);
                env.send_a_to_b(8'h55);
                env.send_a_to_b(8'hDE);
                env.send_a_to_b(8'hAD);
            end
            begin
                // B sends binary pattern to A (slight offset to avoid collision)
                # 500us;
                env.send_b_to_a(8'hBE);
                env.send_b_to_a(8'hEF);
                env.send_b_to_a(8'hCA);
                env.send_b_to_a(8'hFE);
            end
        join
        # 5000us;
        
        // ── Phase 4: Edge-case bytes ─────────────────────────────────────────
        log_info("--- Phase 4: Edge-case bytes (0x00, 0xFF) ---", EVM_LOW);
        env.send_a_to_b(8'h00);  // all zeros
        env.send_a_to_b(8'hFF);  // all ones
        # 2000us;
        
        // ── Final wait — allow last bytes to propagate ───────────────────────
        log_info("--- Waiting for all bytes to arrive ---", EVM_LOW);
        # 5000us;
        
        log_info("=== UART Unit Test Complete ===", EVM_LOW);
        drop_objection("uart_basic_test");
    endtask
    
    //==========================================================================
    // report_phase — print test summary
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        log_info("=== UART Scoreboard Summary ===", EVM_LOW);
        log_info($sformatf("sb_b_rx: match=%0d mismatch=%0d orphan_exp=%0d orphan_act=%0d",
                           env.sb_b_rx.match_count, env.sb_b_rx.mismatch_count,
                           env.sb_b_rx.orphan_expected, env.sb_b_rx.orphan_actual), EVM_LOW);
        log_info($sformatf("sb_a_rx: match=%0d mismatch=%0d orphan_exp=%0d orphan_act=%0d",
                           env.sb_a_rx.match_count, env.sb_a_rx.mismatch_count,
                           env.sb_a_rx.orphan_expected, env.sb_a_rx.orphan_actual), EVM_LOW);
    endfunction
    
    virtual function string get_type_name();
        return "uart_basic_test";
    endfunction
    
endclass : uart_basic_test

`EVM_REGISTER_TEST(uart_basic_test)
