//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_uart_monitor.sv
// Description: UART RX monitor — watches vif.rx, reconstructs UART frames,
//              checks parity and framing, detects breaks, and publishes
//              evm_uart_txn on analysis_port (all frames) and ap_err (errors).
//
// Detection algorithm:
//   1. Wait for negedge on RX (start bit)
//   2. Wait 0.5 bit periods to center in start bit, verify it's still 0
//   3. Sample data bits at 1 bit period intervals (LSB first)
//   4. Check parity bit if enabled
//   5. Check stop bit(s) — framing error if 0
//   6. Publish transaction
//   7. Break detection: if start of frame and RX stays 0 for >1 frame period
//
// API — Public Interface:
//   [evm_uart_monitor extends evm_monitor#(virtual evm_uart_if, evm_uart_txn)]
//   cfg         — must be set before run_phase
//   analysis_port — all received frames (inherited)
//   ap_err        — error frames only (parity/framing errors, breaks)
//==============================================================================

class evm_uart_monitor extends evm_monitor#(virtual evm_uart_if, evm_uart_txn);
    
    evm_uart_cfg            cfg;
    evm_analysis_port#(evm_uart_txn) ap_err;   // error frames only
    
    longint rx_count    = 0;
    longint err_count   = 0;
    
    function new(string name = "evm_uart_monitor", evm_component parent = null);
        super.new(name, parent);
        ap_err = new("ap_err", this);
    endfunction
    
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_uart_monitor: VIF not set");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_uart_monitor: cfg not set");
            return;
        end
        fork
            receive_loop();
        join_none
    endtask
    
    //==========================================================================
    // receive_loop — continuously receive UART frames from vif.rx
    //==========================================================================
    virtual task receive_loop();
        evm_uart_txn txn;
        bit [8:0]    data;
        bit          par_received;
        bit          par_expected;
        bit          stop_ok;
        bit          parity_err;
        bit          framing_err;
        bit          break_det;
        int          i;
        int          bp;
        int          half_bp;
        int          stop_ns;
        
        bp      = cfg.bit_period_ns;
        half_bp = bp / 2;
        
        forever begin
            // Wait for start bit (negedge on RX)
            @(negedge vif.rx);
            
            if (in_reset) begin
                @(reset_deasserted);
                continue;
            end
            
            txn = new("uart_rx");
            txn.mark_started();
            txn.is_tx         = 0;
            data              = 9'h000;
            parity_err        = 0;
            framing_err       = 0;
            break_det         = 0;
            
            // Center in start bit
            # (half_bp * 1ns);
            
            // Verify start bit is still 0 (not a glitch)
            if (vif.rx != 1'b0) begin
                // Glitch — ignore
                continue;
            end
            
            // Check for break: if RX is still 0 after a full frame period
            // (roughly: data_bits + parity + stop bits all 0)
            // Simple approach: sample first data bit to confirm it's a real frame
            
            // Wait 1 bit period (to data bit 0)
            # (bp * 1ns);
            
            // Sample data bits (LSB first)
            data[0] = vif.rx;
            for (i = 1; i < cfg.data_bits; i++) begin
                # (bp * 1ns);
                data[i] = vif.rx;
            end
            
            // Sample parity bit if enabled
            par_received = 0;
            if (cfg.has_parity()) begin
                # (bp * 1ns);
                par_received = vif.rx;
                par_expected = cfg.calc_parity(data);
                parity_err   = (par_received !== par_expected);
            end
            
            // Sample stop bit
            stop_ns = int'(cfg.stop_bits * real'(bp));
            # (half_bp * 1ns);  // center of stop bit
            stop_ok = (vif.rx == 1'b1);
            framing_err = !stop_ok;
            
            // Check for break: framing error AND all data bits were 0
            if (framing_err && (data == '0)) begin
                break_det   = 1;
                framing_err = 0;  // not a framing error when it's a break
            end
            
            // Wait remainder of stop bit
            # (half_bp * 1ns);
            
            // Build transaction
            txn.data          = data;
            txn.parity_error  = parity_err;
            txn.framing_error = framing_err;
            txn.break_detect  = break_det;
            txn.mark_completed();
            
            rx_count++;
            if (txn.is_error()) err_count++;
            
            log_info($sformatf("[UART RX] %s", txn.convert2string()), EVM_HIGH);
            
            // Publish on main port (all frames)
            analysis_port.write(txn);
            
            // Publish on error port if error
            if (txn.is_error())
                ap_err.write(txn);
        end
    endtask
    
    virtual function void report_phase();
        super.report_phase();
        log_info($sformatf("[UART RX] Total: %0d frames, %0d errors", rx_count, err_count), EVM_LOW);
    endfunction
    
    virtual function string get_type_name();
        return "evm_uart_monitor";
    endfunction
    
endclass : evm_uart_monitor
