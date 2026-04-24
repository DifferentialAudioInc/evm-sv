//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_i2c_target_driver.sv
// Description: I2C target driver — EVM emulates one or more I2C peripheral devices.
//              DUT is the I2C initiator (master); this driver responds.
//              PRIMARY use case for embedded FPGA verification.
//
//              Supports multiple devices at different addresses via cfg.devices[].
//              Each device has a register-map backed by evm_memory_model.
//              When addressed by the DUT, automatically ACKs and responds.
//
// API — Public Interface:
//   [evm_i2c_target_driver extends evm_driver#(virtual evm_i2c_if, evm_i2c_txn)]
//   cfg       — must be set before run_phase
//==============================================================================

class evm_i2c_target_driver extends evm_driver#(virtual evm_i2c_if, evm_i2c_txn);
    
    evm_i2c_cfg cfg;
    
    function new(string name = "evm_i2c_target_driver", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase();
        super.run_phase();
        if (vif == null) begin
            log_fatal("evm_i2c_target_driver: VIF not set");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_i2c_target_driver: cfg not set");
            return;
        end
        // Initialize: release SDA (high)
        vif.sda_t_pull_low = 0;
        vif.scl_t_pull_low = 0;
        fork
            target_loop();
        join_none
    endtask
    
    virtual task main_phase();
        // Target runs continuously in run_phase
    endtask
    
    //==========================================================================
    // target_loop — respond to I2C transactions from DUT
    //==========================================================================
    virtual task target_loop();
        bit [7:0]             addr_byte;
        bit [6:0]             dev_addr;
        bit                   is_read;
        evm_i2c_device_model  device;
        int                   reg_addr_val;
        int                   i;
        bit [7:0]             rb;
        
        forever begin
            // Wait for START condition (SDA falls while SCL=1)
            wait_for_start();
            
            if (in_reset) begin
                release_sda();
                @(reset_deasserted);
                continue;
            end
            
            // Receive address byte (7-bit addr + R/W)
            receive_byte_as_target(addr_byte);
            dev_addr = addr_byte[7:1];
            is_read  = addr_byte[0];  // 1=read from target, 0=write to target
            
            // Find device with matching address
            device = cfg.get_device(dev_addr);
            
            if (device == null) begin
                // No device at this address — NACK (release SDA)
                release_sda();  // NACK
                log_info($sformatf("[I2C TGT] Unmatched addr 0x%02x — NACK", dev_addr), EVM_DEBUG);
                wait_for_stop();
                continue;
            end
            
            device.txn_count++;
            
            // ACK the address
            drive_ack();
            log_info($sformatf("[I2C TGT] Matched device 0x%02x, %s",
                               dev_addr, is_read ? "READ" : "WRITE"), EVM_DEBUG);
            
            if (!is_read) begin
                // WRITE: receive register address bytes, then data
                reg_addr_val = 0;
                for (i = 0; i < device.reg_addr_bytes; i++) begin
                    receive_byte_as_target(rb);
                    reg_addr_val = (reg_addr_val << 8) | int'(rb);
                    drive_ack();
                end
                device.set_reg_ptr(reg_addr_val);
                
                // Receive data bytes until STOP or rSTART
                while (1) begin
                    if (detect_stop_or_rstart()) break;
                    receive_byte_as_target(rb);
                    device.write_reg(device.get_reg_ptr(), rb);
                    drive_ack();
                end
                
            end else begin
                // READ: send register data bytes, check ACK from initiator
                bit got_nack;
                got_nack = 0;
                while (!got_nack) begin
                    rb = device.read_reg();  // reads from reg_ptr and advances
                    send_byte_as_target(rb);
                    // 9th bit: receive ACK from initiator
                    begin
                        bit mack;
                        receive_ack_from_initiator(mack);
                        got_nack = !mack;  // NACK = done
                    end
                end
                release_sda();
                // Wait for STOP
                wait_for_stop();
            end
        end
    endtask
    
    //==========================================================================
    // wait_for_start — block until START (SDA falls while SCL=1)
    //==========================================================================
    virtual task wait_for_start();
        forever begin
            @(negedge vif.sda);
            if (vif.scl == 1'b1) return;
        end
    endtask
    
    //==========================================================================
    // wait_for_stop — block until STOP (SDA rises while SCL=1)
    //==========================================================================
    virtual task wait_for_stop();
        forever begin
            @(posedge vif.sda);
            if (vif.scl == 1'b1) return;
        end
    endtask
    
    //==========================================================================
    // detect_stop_or_rstart — non-blocking check during byte boundary
    //==========================================================================
    virtual task detect_stop_or_rstart(output bit detected);
        detected = 0;
        // Check if SCL is high (SDA change while SCL=1 = STOP or rSTART)
        if (vif.scl == 1'b1) begin
            detected = 1;
        end
    endtask
    
    //==========================================================================
    // receive_byte_as_target — clock in 8 bits from SDA (data)
    //==========================================================================
    virtual task receive_byte_as_target(output bit [7:0] data_out);
        int i;
        data_out = 8'h00;
        for (i = 7; i >= 0; i--) begin
            @(posedge vif.scl);
            data_out[i] = vif.sda;
        end
    endtask
    
    //==========================================================================
    // drive_ack — target pulls SDA low during 9th clock
    //==========================================================================
    virtual task drive_ack();
        // Wait for SCL low (after 8th bit was sampled)
        @(negedge vif.scl);
        vif.sda_t_pull_low = 1;  // pull SDA low = ACK
        @(posedge vif.scl);      // initiator reads ACK
        @(negedge vif.scl);
        vif.sda_t_pull_low = 0;  // release SDA
    endtask
    
    //==========================================================================
    // release_sda — stop driving SDA (NACK / end of drive)
    //==========================================================================
    virtual task release_sda();
        vif.sda_t_pull_low = 0;
    endtask
    
    //==========================================================================
    // send_byte_as_target — drive SDA for 8 bits (READ response)
    //==========================================================================
    virtual task send_byte_as_target(input bit [7:0] data_in);
        int i;
        for (i = 7; i >= 0; i--) begin
            @(negedge vif.scl);
            // Drive bit on SDA (open-drain: pull low for 0, release for 1)
            vif.sda_t_pull_low = !data_in[i];
            @(posedge vif.scl);  // initiator samples
        end
        @(negedge vif.scl);
        vif.sda_t_pull_low = 0;  // release SDA before ACK bit
    endtask
    
    //==========================================================================
    // receive_ack_from_initiator — read the ACK bit after sending a byte
    //==========================================================================
    virtual task receive_ack_from_initiator(output bit ack);
        // SDA is released, initiator drives ACK (low) or NACK (high)
        @(posedge vif.scl);
        ack = !vif.sda;  // SDA low = ACK, high = NACK
        @(negedge vif.scl);
    endtask
    
    //==========================================================================
    // Reset handlers
    //==========================================================================
    virtual task on_reset_assert();
        if (vif != null) begin
            vif.sda_t_pull_low = 0;
            vif.scl_t_pull_low = 0;
        end
    endtask
    
    virtual function string get_type_name();
        return "evm_i2c_target_driver";
    endfunction
    
endclass : evm_i2c_target_driver
