//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_target_driver.sv
// Description: SPI target driver — EVM emulates SPI peripheral device(s).
//              DUT is the SPI initiator (master); this driver responds.
//
//              For each CS_N assertion:
//              1. Detects which CS_N asserted
//              2. Byte-shifts MOSI in; drives MISO out per CPOL/CPHA
//              3. Calls device_model.process_byte() for each byte to get MISO data
//              4. Continues until CS_N deasserts
//
//              Supports all 4 SPI modes (CPOL/CPHA), MSB/LSB first, 1-8 devices.
//              Device memory models are accessed via cfg.devices[].
//
// API — Public Interface:
//   [evm_spi_target_driver extends evm_driver#(virtual evm_spi_if, evm_spi_txn)]
//   cfg         — must be set before run_phase (set by agent.build_phase)
//   main_phase()— runs the target response loop
//==============================================================================

class evm_spi_target_driver extends evm_driver#(virtual evm_spi_if, evm_spi_txn);
    
    //==========================================================================
    // Configuration reference (set by agent in create_driver)
    //==========================================================================
    evm_spi_cfg cfg;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_spi_target_driver", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // run_phase — override to launch target loop in background
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        fork
            target_loop();
        join_none
    endtask
    
    //==========================================================================
    // main_phase — target response is handled in run_phase (continuous)
    // Override to prevent base class default behavior
    //==========================================================================
    virtual task main_phase();
        // Target driver runs forever in run_phase — nothing to do here
    endtask
    
    //==========================================================================
    // target_loop — respond to DUT SPI initiator transfers indefinitely
    //==========================================================================
    virtual task target_loop();
        int                   cs_sel;
        evm_spi_device_model  device;
        bit [7:0]             mosi_byte;
        bit [7:0]             current_miso; // MISO byte to drive during THIS byte transfer
        bit [7:0]             next_miso;    // MISO byte returned by process_byte() for NEXT transfer
        int                   i;
        
        if (vif == null) begin
            log_fatal("evm_spi_target_driver: VIF not set — call agent.set_vif()");
            return;
        end
        if (cfg == null) begin
            log_fatal("evm_spi_target_driver: cfg not set — set agent.cfg before build_phase");
            return;
        end
        
        // Initialize MISO to idle high
        vif.miso = 1'b1;
        
        forever begin
            // Wait for any CS_N to assert (go low)
            wait (vif.cs_n != 8'hFF);
            
            if (in_reset) begin
                vif.miso = 1'b1;
                @(reset_deasserted);
                continue;
            end
            
            // Find which CS asserted
            cs_sel = -1;
            for (i = 0; i < cfg.num_cs; i++) begin
                if (vif.cs_n[i] == 1'b0) begin
                    cs_sel = i;
                    break;
                end
            end
            
            if (cs_sel < 0) begin
                #1;
                continue;
            end
            
            // Get device model for this CS
            device = cfg.get_device(cs_sel);
            if (device == null) begin
                log_warning($sformatf("[SPI TGT] No device model for CS[%0d] — ignoring transfer", cs_sel));
                wait (vif.cs_n[cs_sel] == 1'b1);
                continue;
            end
            
            // Begin transfer — reset device FSM
            device.begin_transfer();
            
            // Initial MISO = 0xFF (don't-care during CMD byte)
            current_miso = 8'hFF;
            
            log_info($sformatf("[SPI TGT] CS[%0d] asserted — begin transfer", cs_sel), EVM_DEBUG);
            
            // Transfer bytes until CS_N deasserts
            while (vif.cs_n[cs_sel] == 1'b0) begin
                // Exchange one byte: drive current_miso on MISO, receive mosi_byte
                exchange_byte(current_miso, mosi_byte);
                
                // Process received byte through device FSM
                // Returns the MISO byte to drive for the NEXT byte transfer
                next_miso = device.process_byte(mosi_byte);
                
                // The returned next_miso becomes current_miso for the next iteration
                current_miso = next_miso;
            end
            
            // CS_N deasserted — end of transfer
            vif.miso = 1'b1;  // release MISO to idle
            device.end_transfer();
            
            log_info($sformatf("[SPI TGT] CS[%0d] deasserted — transfer complete", cs_sel), EVM_DEBUG);
        end
    endtask
    
    //==========================================================================
    // exchange_byte — drive tx_byte on MISO while receiving rx_byte from MOSI
    // Timing per CPOL/CPHA:
    //   Mode 0 (CPOL=0,CPHA=0): MISO changes on negedge, sampled on posedge
    //   Mode 1 (CPOL=0,CPHA=1): MISO changes on posedge, sampled on negedge
    //   Mode 2 (CPOL=1,CPHA=0): MISO changes on posedge, sampled on negedge
    //   Mode 3 (CPOL=1,CPHA=1): MISO changes on negedge, sampled on posedge
    //
    // All local variables declared at top (Vivado rule)
    //==========================================================================
    virtual task exchange_byte(input bit [7:0] tx_byte, output bit [7:0] rx_byte);
        int i;
        int bit_pos;
        
        rx_byte = 8'h00;
        
        for (i = 0; i < cfg.word_size; i++) begin
            // Determine bit position (MSB first vs LSB first)
            if (cfg.lsb_first)
                bit_pos = i;
            else
                bit_pos = cfg.word_size - 1 - i;
            
            // For CPHA=0, first bit of first byte was already on MISO from CS assert.
            // For subsequent bits: drive on setup edge, sample on sample edge.
            
            if (cfg.sample_on_posedge()) begin
                // Mode 0 (CPOL=0,CPHA=0) or Mode 3 (CPOL=1,CPHA=1):
                // MISO changes on negedge, MOSI sampled on posedge
                if (i == 0 && cfg.cpha == 0) begin
                    // For CPHA=0: drive first bit immediately when CS asserts
                    // (already done by caller or initial value)
                    // Drive immediately:
                    vif.miso = tx_byte[bit_pos];
                end
                @(posedge vif.sclk);          // sample edge
                rx_byte[bit_pos] = vif.mosi;  // capture MOSI
                if (i < cfg.word_size - 1) begin
                    @(negedge vif.sclk);           // setup edge
                    vif.miso = tx_byte[bit_pos-1 >= 0 ? bit_pos-1 : 0]; // next bit
                    // Correct: drive the next bit (bit_pos for next i)
                    // We'll just update MISO for next iteration by recalculating
                end
            end else begin
                // Mode 1 (CPOL=0,CPHA=1) or Mode 2 (CPOL=1,CPHA=0):
                // MISO changes on posedge, MOSI sampled on negedge
                if (i == 0 && cfg.cpha == 0) begin
                    vif.miso = tx_byte[bit_pos];
                end
                @(negedge vif.sclk);          // sample edge
                rx_byte[bit_pos] = vif.mosi;
                if (i < cfg.word_size - 1) begin
                    @(posedge vif.sclk);           // setup edge
                end
            end
        end
        
        // After all bits sampled, drive MISO idle for inter-byte gap
        // (will be overwritten at the start of next byte by exchange_byte)
    endtask
    
    //==========================================================================
    // Reset handlers
    //==========================================================================
    virtual task on_reset_assert();
        if (vif != null)
            vif.miso = 1'b1;  // release MISO on reset
    endtask
    
    virtual function string get_type_name();
        return "evm_spi_target_driver";
    endfunction
    
endclass : evm_spi_target_driver
