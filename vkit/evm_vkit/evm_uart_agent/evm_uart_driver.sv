//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_uart_driver.sv
// Description: UART TX driver — drives the vif.tx signal.
//              Sends UART frames: start bit → data bits (LSB first)
//              → optional parity → stop bit(s).
//              Also supports sequencer-based driving via seq_item_port.
//
// API — Public Interface:
//   [evm_uart_driver extends evm_driver#(virtual evm_uart_if, evm_uart_txn)]
//   cfg                   — must be set before run_phase
//   send_byte(data)       — transmit one UART frame
//   send_string(str)      — transmit ASCII string (each char as a frame)
//   send_bytes(data[])    — transmit byte array
//   send_break(ns)        — hold TX low for break_ns nanoseconds
//
// ── EVM Agent Architecture Rule ──────────────────────────────────────────────
// DRIVERS NEVER PUBLISH TRANSACTIONS TO SCOREBOARDS.
// Only monitors observe the bus and publish via analysis_port.
// Expected scoreboard values come from the test/sequence level via
// scoreboard.insert_expected() — NOT from the driver.
//
// In ACTIVE mode:  Sequencer → Driver → VIF (drives bus)
//                  VIF → Monitor → analysis_port → Scoreboard (observes bus)
// In PASSIVE mode: VIF → Monitor → analysis_port → Scoreboard (observes only)
//==============================================================================

class evm_uart_driver extends evm_driver#(virtual evm_uart_if, evm_uart_txn);
    
    evm_uart_cfg cfg;
    longint      tx_count = 0;
    
    function new(string name = "evm_uart_driver", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_uart_driver: VIF not set — call agent.set_vif()");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_uart_driver: cfg not set — set agent.cfg before build_phase");
            return;
        end
        // Initialize TX to idle high
        vif.tx = 1'b1;
        if (cfg.flow_control)
            vif.rts = 1'b1;
    endtask
    
    //==========================================================================
    // main_phase — process sequence items if sequencer is connected
    //==========================================================================
    virtual task main_phase();
        evm_uart_txn req;
        
        if (!seq_item_port.is_connected()) return;
        
        forever begin
            if (in_reset) begin
                vif.tx = 1'b1;
                @(reset_deasserted);
                continue;
            end
            seq_item_port.get_next_item(req);
            send_frame(req.data);
            req.is_tx = 1;
            seq_item_port.item_done();
            // NOTE: we do NOT call analysis_port.write() here.
            // The monitor observes vif.rx on the receiving agent and publishes there.
        end
    endtask
    
    //==========================================================================
    // send_frame() — transmit one UART frame (internal)
    // All local variables at top (Vivado rule)
    //==========================================================================
    virtual task send_frame(input bit [8:0] data);
        int  i;
        int  bp;
        bit  par_bit;
        int  stop_ns;
        
        bp       = cfg.bit_period_ns;
        par_bit  = cfg.calc_parity(data);
        stop_ns  = int'(cfg.stop_bits * real'(bp));
        
        // Wait for CTS if flow control enabled
        if (cfg.flow_control) begin
            while (vif.cts == 1'b0) # (bp * 1ns);
        end
        
        // Start bit
        vif.tx = 1'b0;
        # (bp * 1ns);
        
        // Data bits (LSB first)
        for (i = 0; i < cfg.data_bits; i++) begin
            vif.tx = data[i];
            # (bp * 1ns);
        end
        
        // Parity bit (optional)
        if (cfg.has_parity()) begin
            vif.tx = par_bit;
            # (bp * 1ns);
        end
        
        // Stop bit(s)
        vif.tx = 1'b1;
        # (stop_ns * 1ns);
        
        tx_count++;
        log_info($sformatf("[UART TX] 0x%02x", data[7:0]), EVM_DEBUG);
    endtask
    
    //==========================================================================
    // Direct API — send one byte
    // NOTE: No analysis_port.write() here — the monitor publishes on the
    //       receiving side when it observes the byte on its vif.rx.
    //==========================================================================
    virtual task send_byte(input bit [8:0] data);
        send_frame(data);
        tx_count++;
        log_info($sformatf("[UART TX] 0x%02x", data[7:0]), EVM_HIGH);
    endtask
    
    //==========================================================================
    // Direct API — send ASCII string (each char as one UART frame)
    //==========================================================================
    virtual task send_string(input string str);
        int i;
        for (i = 0; i < str.len(); i++) begin
            send_byte(9'(str[i]));
        end
        log_info($sformatf("[UART TX] string: \"%s\"", str), EVM_HIGH);
    endtask
    
    //==========================================================================
    // Direct API — send byte array
    //==========================================================================
    virtual task send_bytes(input bit [7:0] data[]);
        int i;
        for (i = 0; i < data.size(); i++) begin
            send_byte(9'(data[i]));
        end
    endtask
    
    //==========================================================================
    // send_break() — hold TX low for an extended period (break signal)
    //==========================================================================
    virtual task send_break(input int break_ns = 0);
        int hold_ns;
        hold_ns = (break_ns > 0) ? break_ns : (13 * cfg.bit_period_ns);
        vif.tx = 1'b0;
        # (hold_ns * 1ns);
        vif.tx = 1'b1;
        # (cfg.bit_period_ns * 1ns);
        log_info($sformatf("[UART TX] BREAK sent (%0dns)", hold_ns), EVM_HIGH);
    endtask
    
    virtual task on_reset_assert();
        if (vif != null) vif.tx = 1'b1;
    endtask
    
    virtual function string get_type_name();
        return "evm_uart_driver";
    endfunction
    
endclass : evm_uart_driver
