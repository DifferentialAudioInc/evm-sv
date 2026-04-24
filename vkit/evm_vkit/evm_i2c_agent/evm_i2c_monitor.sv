//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_monitor.sv
// Description: Passive I2C bus observer.
//              Detects START/STOP conditions, samples bits, assembles bytes,
//              decodes address/data, and publishes evm_i2c_txn on analysis_port.
//
// API — Public Interface:
//   [evm_i2c_monitor extends evm_monitor#(virtual evm_i2c_if, evm_i2c_txn)]
//   cfg                — must be set before run_phase
//   analysis_port      — publishes evm_i2c_txn per transaction
//==============================================================================

class evm_i2c_monitor extends evm_monitor#(virtual evm_i2c_if, evm_i2c_txn);
    
    evm_i2c_cfg cfg;
    int         txn_count = 0;
    
    function new(string name = "evm_i2c_monitor", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_i2c_monitor: VIF not set");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_i2c_monitor: cfg not set");
            return;
        end
        fork
            monitor_loop();
        join_none
    endtask
    
    //==========================================================================
    // monitor_loop — wait for START, collect transaction, publish
    //==========================================================================
    virtual task monitor_loop();
        evm_i2c_txn   txn;
        bit [7:0]      addr_byte;
        bit [7:0]      raw_byte;
        bit            addr_ack;
        bit [7:0]      data_bytes[$];
        bit            acks[$];
        bit            got_stop;
        bit [6:0]      dev_addr;
        bit            is_write;
        evm_i2c_device_model dev;
        int            reg_addr_bytes;
        int            i;
        
        forever begin
            // Wait for START condition: SDA falls while SCL is high
            wait_for_start();
            
            if (in_reset) begin
                @(reset_deasserted);
                continue;
            end
            
            txn = new("i2c_txn");
            txn.mark_started();
            data_bytes.delete();
            acks.delete();
            
            // Receive address byte (7 bits + R/W bit)
            receive_byte(addr_byte, addr_ack);
            
            dev_addr  = addr_byte[7:1];
            is_write  = !addr_byte[0];   // R/W bit: 0=write, 1=read
            
            txn.dev_addr   = dev_addr;
            txn.is_write   = is_write;
            txn.addr_nack  = !addr_ack;
            
            // Get device info for reg_addr_bytes
            dev = cfg.get_device(dev_addr);
            reg_addr_bytes = (dev != null) ? dev.reg_addr_bytes : 1;
            txn.reg_addr_bytes = reg_addr_bytes;
            
            if (!addr_ack) begin
                // No device responded — wait for STOP and publish NACK txn
                wait_for_stop_or_start(got_stop);
                txn.data         = new[0];
                txn.ack_received = new[0];
                txn.mark_completed();
                txn_count++;
                analysis_port.write(txn);
                continue;
            end
            
            if (is_write) begin
                // WRITE transaction: receive reg_addr then data bytes
                bit [15:0] reg_addr;
                reg_addr = 0;
                
                // Receive register address bytes
                for (i = 0; i < reg_addr_bytes; i++) begin
                    bit [7:0] rb;
                    bit       rack;
                    receive_byte(rb, rack);
                    reg_addr = (reg_addr << 8) | 16'(rb);
                    acks.push_back(rack);
                end
                txn.reg_addr = reg_addr;
                
                // Receive data bytes until STOP or Repeated START
                got_stop = 0;
                while (!got_stop) begin
                    // Check for STOP or Repeated START before next byte
                    if (is_stop_or_start()) begin
                        got_stop = check_for_stop(got_stop);
                        break;
                    end
                    receive_byte(raw_byte, addr_ack);
                    data_bytes.push_back(raw_byte);
                    acks.push_back(addr_ack);
                    if (!addr_ack) break;  // NACK from device ends write
                end
                txn.repeated_start = !got_stop;
                
            end else begin
                // READ transaction: receive data bytes, initiator sends ACK/NACK
                bit [7:0] rb;
                bit       rack;
                got_stop = 0;
                while (!got_stop) begin
                    if (is_stop_or_start()) begin
                        got_stop = check_for_stop(got_stop);
                        break;
                    end
                    receive_byte(rb, rack);
                    data_bytes.push_back(rb);
                    acks.push_back(rack);
                    if (!rack) break;  // NACK from initiator = last byte
                end
                txn.repeated_start = !got_stop;
            end
            
            // Pack arrays
            begin
                int n;
                n = data_bytes.size();
                txn.data         = new[n];
                txn.ack_received = new[n];
                for (i = 0; i < n; i++) begin
                    txn.data[i]         = data_bytes[i];
                    txn.ack_received[i] = (i < acks.size()) ? acks[i] : 1;
                end
            end
            
            txn.mark_completed();
            txn_count++;
            log_info($sformatf("[I2C MON] %s", txn.convert2string()), EVM_HIGH);
            analysis_port.write(txn);
        end
    endtask
    
    //==========================================================================
    // wait_for_start — block until START condition (SDA falls while SCL=1)
    //==========================================================================
    virtual task wait_for_start();
        forever begin
            @(negedge vif.sda);
            if (vif.scl == 1'b1) return;  // START detected
        end
    endtask
    
    //==========================================================================
    // receive_byte — clock in 8 bits then check ACK bit
    //==========================================================================
    virtual task receive_byte(output bit [7:0] data_out, output bit ack);
        int i;
        int bit_pos;
        data_out = 8'h00;
        for (i = 7; i >= 0; i--) begin
            @(posedge vif.scl);
            data_out[i] = vif.sda;
        end
        // 9th clock: ACK bit (low = ACK)
        @(posedge vif.scl);
        ack = !vif.sda;  // 0=NACK, 1=ACK (SDA low means ACK)
    endtask
    
    //==========================================================================
    // is_stop_or_start — quick check without blocking
    //==========================================================================
    virtual function bit is_stop_or_start();
        return (vif.scl == 1'b1);
    endfunction
    
    //==========================================================================
    // check_for_stop — determine if we saw STOP or Repeated START
    //==========================================================================
    virtual task check_for_stop(output bit got_stop);
        // Wait a short time then check SDA direction
        // If SDA rises while SCL=1: STOP condition
        // If SDA falls while SCL=1: Repeated START
        @(vif.sda);
        got_stop = (vif.sda == 1'b1);  // SDA rose = STOP; SDA fell = rSTART
    endtask
    
    //==========================================================================
    // wait_for_stop_or_start
    //==========================================================================
    virtual task wait_for_stop_or_start(output bit got_stop);
        // Wait for SCL to go high then detect SDA direction change
        @(posedge vif.scl);
        @(vif.sda);
        got_stop = (vif.sda == 1'b1);
    endtask
    
    virtual function void report_phase();
        super.report_phase();
        log_info($sformatf("[I2C MON] Total transactions: %0d", txn_count), EVM_LOW);
    endfunction
    
    virtual function string get_type_name();
        return "evm_i2c_monitor";
    endfunction
    
endclass : evm_i2c_monitor
