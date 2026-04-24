//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_initiator_driver.sv
// Description: I2C initiator driver — EVM acts as the I2C bus master.
//              DUT is the I2C target; EVM drives SCL and SDA.
//
// Direct API (most common pattern, no sequencer):
//   write(dev_addr, reg_addr, reg_addr_bytes, data[])
//   read(dev_addr, reg_addr, reg_addr_bytes, num_bytes, data[])
//   write_byte(dev_addr, reg_addr, data_byte)
//   read_byte(dev_addr, reg_addr) → bit [7:0]
//
// API — Public Interface:
//   [evm_i2c_initiator_driver extends evm_driver#(virtual evm_i2c_if, evm_i2c_txn)]
//   cfg                                      — must be set before run_phase
//   write(dev_addr, reg_addr, n, data[])     — write N bytes starting at reg_addr
//   read(dev_addr, reg_addr, n, nbytes, out[]) — read nbytes from reg_addr
//   write_byte(dev_addr, reg_addr, data)     — write single byte
//   read_byte(dev_addr, reg_addr)            — read single byte
//==============================================================================

class evm_i2c_initiator_driver extends evm_driver#(virtual evm_i2c_if, evm_i2c_txn);
    
    evm_i2c_cfg cfg;
    
    function new(string name = "evm_i2c_initiator_driver", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_i2c_initiator_driver: VIF not set");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_i2c_initiator_driver: cfg not set");
            return;
        end
        // Initialize: release bus (both high)
        vif.scl_pull_low   = 0;
        vif.sda_i_pull_low = 0;
    endtask
    
    virtual task main_phase();
        evm_i2c_txn req;
        bit [7:0]   out[];
        
        if (!seq_item_port.is_connected()) return;
        
        forever begin
            if (in_reset) begin
                idle_bus();
                @(reset_deasserted);
                continue;
            end
            seq_item_port.get_next_item(req);
            drive_transaction(req, out);
            req.data = out;
            seq_item_port.item_done();
        end
    endtask
    
    //==========================================================================
    // drive_transaction — drive from a txn object
    //==========================================================================
    virtual task drive_transaction(evm_i2c_txn txn, output bit [7:0] data_out[]);
        if (txn.is_write) begin
            write(txn.dev_addr, txn.reg_addr, txn.reg_addr_bytes, txn.data);
            data_out = new[0];
        end else begin
            read(txn.dev_addr, txn.reg_addr, txn.reg_addr_bytes,
                 txn.data.size(), data_out);
        end
    endtask
    
    //==========================================================================
    // write() — write N bytes to register address on device
    //==========================================================================
    virtual task write(
        input bit [6:0]  dev_addr,
        input bit [15:0] reg_addr,
        input int        reg_addr_bytes,
        input bit [7:0]  data[]
    );
        bit addr_ack;
        bit data_ack;
        int i;
        int half_ns;
        
        half_ns = cfg.scl_period_ns / 2;
        
        // START condition
        start_condition(half_ns);
        
        // Send address byte with WRITE bit (bit0=0)
        send_byte({dev_addr, 1'b0}, half_ns);
        receive_ack_bit(addr_ack, half_ns);
        if (!addr_ack) begin
            stop_condition(half_ns);
            log_warning($sformatf("[I2C INIT] WRITE addr NACK from 0x%02x", dev_addr));
            return;
        end
        
        // Send register address bytes (MSB first)
        for (i = 0; i < reg_addr_bytes; i++) begin
            int shift;
            bit [7:0] rb;
            shift = (reg_addr_bytes - 1 - i) * 8;
            rb = (reg_addr >> shift) & 8'hFF;
            send_byte(rb, half_ns);
            receive_ack_bit(data_ack, half_ns);
        end
        
        // Send data bytes
        for (i = 0; i < data.size(); i++) begin
            send_byte(data[i], half_ns);
            receive_ack_bit(data_ack, half_ns);
        end
        
        // STOP condition
        stop_condition(half_ns);
        # (cfg.t_buf_ns * 1ns);
        
        log_info($sformatf("[I2C INIT] WR dev=0x%02x reg=0x%0x %0d bytes",
                           dev_addr, reg_addr, data.size()), EVM_HIGH);
    endtask
    
    //==========================================================================
    // read() — read nbytes from device register address
    //==========================================================================
    virtual task read(
        input  bit [6:0]  dev_addr,
        input  bit [15:0] reg_addr,
        input  int        reg_addr_bytes,
        input  int        num_bytes,
        output bit [7:0]  data_out[]
    );
        bit addr_ack;
        bit data_ack;
        int i;
        int half_ns;
        bit [7:0] rb;
        
        half_ns = cfg.scl_period_ns / 2;
        data_out = new[num_bytes];
        
        // START + write address to set register pointer
        start_condition(half_ns);
        send_byte({dev_addr, 1'b0}, half_ns);  // WRITE
        receive_ack_bit(addr_ack, half_ns);
        if (!addr_ack) begin
            stop_condition(half_ns);
            log_warning($sformatf("[I2C INIT] READ (set ptr) addr NACK from 0x%02x", dev_addr));
            return;
        end
        
        for (i = 0; i < reg_addr_bytes; i++) begin
            int shift;
            shift = (reg_addr_bytes - 1 - i) * 8;
            send_byte((reg_addr >> shift) & 8'hFF, half_ns);
            receive_ack_bit(data_ack, half_ns);
        end
        
        // Repeated START + read address
        repeated_start(half_ns);
        send_byte({dev_addr, 1'b1}, half_ns);  // READ
        receive_ack_bit(addr_ack, half_ns);
        if (!addr_ack) begin
            stop_condition(half_ns);
            log_warning($sformatf("[I2C INIT] READ addr NACK from 0x%02x", dev_addr));
            return;
        end
        
        // Receive data bytes
        for (i = 0; i < num_bytes; i++) begin
            receive_byte(rb, half_ns);
            data_out[i] = rb;
            // Send ACK for all but last byte; NACK for last
            if (i < num_bytes - 1)
                send_ack(half_ns);
            else
                send_nack(half_ns);
        end
        
        stop_condition(half_ns);
        # (cfg.t_buf_ns * 1ns);
        
        log_info($sformatf("[I2C INIT] RD dev=0x%02x reg=0x%0x %0d bytes",
                           dev_addr, reg_addr, num_bytes), EVM_HIGH);
    endtask
    
    //==========================================================================
    // Convenience: write single byte
    //==========================================================================
    virtual task write_byte(input bit [6:0] dev_addr, input bit [15:0] reg_addr, input byte data);
        bit [7:0] d[];
        d = new[1];
        d[0] = data;
        write(dev_addr, reg_addr, 1, d);
    endtask
    
    //==========================================================================
    // Convenience: read single byte
    //==========================================================================
    virtual task read_byte(input bit [6:0] dev_addr, input bit [15:0] reg_addr, output bit [7:0] data);
        bit [7:0] out[];
        read(dev_addr, reg_addr, 1, 1, out);
        data = (out.size() > 0) ? out[0] : 8'hFF;
    endtask
    
    //==========================================================================
    // Low-level bus tasks
    //==========================================================================
    
    virtual task idle_bus();
        vif.scl_pull_low   = 0;
        vif.sda_i_pull_low = 0;
    endtask
    
    virtual task start_condition(input int half_ns);
        // Ensure idle: SCL=1, SDA=1
        vif.scl_pull_low   = 0;
        vif.sda_i_pull_low = 0;
        # (half_ns * 1ns);
        // SDA falls while SCL=1 → START
        vif.sda_i_pull_low = 1;
        # (cfg.t_hd_sta_ns * 1ns);
        // SCL falls
        vif.scl_pull_low = 1;
        # (half_ns * 1ns);
    endtask
    
    virtual task repeated_start(input int half_ns);
        // Release SDA, release SCL (SDA=1, SCL=1)
        vif.sda_i_pull_low = 0;
        # (half_ns * 1ns);
        vif.scl_pull_low   = 0;
        # (half_ns * 1ns);
        // SDA falls while SCL=1 → Repeated START
        vif.sda_i_pull_low = 1;
        # (cfg.t_hd_sta_ns * 1ns);
        vif.scl_pull_low   = 1;
        # (half_ns * 1ns);
    endtask
    
    virtual task stop_condition(input int half_ns);
        // SCL=0, SDA=0 → release SCL → SDA rises while SCL=1 → STOP
        vif.sda_i_pull_low = 1;
        # (half_ns * 1ns);
        vif.scl_pull_low   = 0;  // SCL rises
        # (cfg.t_su_sto_ns * 1ns);
        vif.sda_i_pull_low = 0;  // SDA rises while SCL=1 → STOP
        # (half_ns * 1ns);
    endtask
    
    virtual task send_byte(input bit [7:0] data_in, input int half_ns);
        int i;
        for (i = 7; i >= 0; i--) begin
            vif.sda_i_pull_low = !data_in[i];  // open-drain
            # (half_ns * 1ns);
            vif.scl_pull_low = 0;   // SCL rises
            # (half_ns * 1ns);
            vif.scl_pull_low = 1;   // SCL falls
        end
        // Release SDA before ACK
        vif.sda_i_pull_low = 0;
    endtask
    
    virtual task receive_ack_bit(output bit ack, input int half_ns);
        # (half_ns * 1ns);
        vif.scl_pull_low = 0;   // SCL rises
        # (half_ns / 2 * 1ns);
        ack = !vif.sda;          // SDA low = ACK, high = NACK
        # (half_ns / 2 * 1ns);
        vif.scl_pull_low = 1;   // SCL falls
    endtask
    
    virtual task receive_byte(output bit [7:0] data_out, input int half_ns);
        int i;
        data_out = 8'h00;
        vif.sda_i_pull_low = 0;  // release SDA
        for (i = 7; i >= 0; i--) begin
            # (half_ns * 1ns);
            vif.scl_pull_low = 0;    // SCL rises
            # (half_ns / 2 * 1ns);
            data_out[i] = vif.sda;   // sample
            # (half_ns / 2 * 1ns);
            vif.scl_pull_low = 1;    // SCL falls
        end
    endtask
    
    virtual task send_ack(input int half_ns);
        vif.sda_i_pull_low = 1;  // ACK
        # (half_ns * 1ns);
        vif.scl_pull_low   = 0;
        # (half_ns * 1ns);
        vif.scl_pull_low   = 1;
        vif.sda_i_pull_low = 0;  // release
    endtask
    
    virtual task send_nack(input int half_ns);
        vif.sda_i_pull_low = 0;  // NACK (release SDA)
        # (half_ns * 1ns);
        vif.scl_pull_low   = 0;
        # (half_ns * 1ns);
        vif.scl_pull_low   = 1;
    endtask
    
    virtual task on_reset_assert();
        if (vif != null) begin
            vif.scl_pull_low   = 0;
            vif.sda_i_pull_low = 0;
        end
    endtask
    
    virtual function string get_type_name();
        return "evm_i2c_initiator_driver";
    endfunction
    
endclass : evm_i2c_initiator_driver
