//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_sequencer
// Description: Sequencer - manages and dispatches sequence items to driver
//              Uses mailbox for item passing
// Author: Eric Dyer
// Date: 2026-03-06
// Updated: 2026-04-09 - Added run_phase reset monitoring, on_reset_* hooks
//==============================================================================

class evm_sequencer #(type REQ = evm_sequence_item, type RSP = REQ) extends evm_component;
    
    //==========================================================================
    // Sequence Item Export - Provides items to driver
    // Source: UVM pattern - sequencers have seq_item_export
    // Rationale: Sequencer is the "middleman" between sequences and driver:
    //            - Sequences generate stimulus items
    //            - Sequencer queues items in FIFO
    //            - Driver pulls items via seq_item_port
    //            - Export provides the connection point
    // Connection: Auto-connected in agent.connect_phase():
    //            driver.seq_item_port.connect(sequencer.seq_item_export.get_fifos())
    // UVM Equivalent: uvm_seq_item_pull_export#(REQ,RSP) seq_item_export
    //==========================================================================
    evm_seq_item_pull_export#(REQ, RSP) seq_item_export;
    
    //==========================================================================
    // Legacy Mailbox for Item Passing (backward compatibility)
    //==========================================================================
    mailbox #(evm_sequence_item) item_mbx;
    
    //==========================================================================
    // Statistics
    //==========================================================================
    int items_sent;
    int items_completed;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_sequencer", evm_component parent = null);
        super.new(name, parent);
        // Create export
        seq_item_export = new({name, ".seq_item_export"}, this);
        // Legacy mailbox for backward compatibility
        item_mbx = new();
        items_sent = 0;
        items_completed = 0;
    endfunction
    
    //==========================================================================
    // Run Phase - Reset Event Monitor
    // Source: EVM mid-simulation reset support
    // Rationale: Sequencer must flush pending items on reset to prevent stale
    //            transactions from being driven after reset completes
    //==========================================================================
    virtual task run_phase();
        super.run_phase();
        
        log_info("Sequencer run_phase: reset event monitor active", EVM_HIGH);
        
        fork
            begin
                // Background thread: monitor reset events
                forever begin
                    @(reset_asserted);
                    on_reset_assert();
                    @(reset_deasserted);
                    on_reset_deassert();
                end
            end
        join_none
    endtask
    
    //==========================================================================
    // Reset Event Handlers - Flush pending items on reset
    //==========================================================================
    
    // Handle reset assertion - flush all pending sequence items
    // Prevents stale pre-reset transactions from being driven post-reset
    virtual task on_reset_assert();
        super.on_reset_assert();
        log_info("Sequencer: flushing pending items due to reset", EVM_MEDIUM);
        
        // Flush the legacy mailbox
        begin
            int flushed = 0;
            evm_sequence_item item;
            while (item_mbx.try_get(item)) begin
                flushed++;
            end
            if (flushed > 0) begin
                log_info($sformatf("Sequencer: flushed %0d pending items from mailbox", flushed), 
                         EVM_HIGH);
            end
        end
        
        // Drain TLM export FIFOs directly (export has no flush() method)
        if (seq_item_export != null) begin
            REQ req_item;
            RSP rsp_item;
            mailbox#(REQ) req_fifo = seq_item_export.get_req_fifo();
            mailbox#(RSP) rsp_fifo = seq_item_export.get_rsp_fifo();
            if (req_fifo != null) while (req_fifo.try_get(req_item)) begin end
            if (rsp_fifo != null) while (rsp_fifo.try_get(rsp_item)) begin end
            log_info("Sequencer: TLM FIFOs flushed", EVM_HIGH);
        end
    endtask
    
    // Handle reset deassertion - ready for new sequences
    virtual task on_reset_deassert();
        super.on_reset_deassert();
        log_info("Sequencer: ready for new sequences after reset", EVM_MEDIUM);
    endtask
    
    //==========================================================================
    // Item Management
    //==========================================================================
    
    // Send single item to driver
    virtual task send_item(evm_sequence_item item);
        log_info($sformatf("Sending item: %s", item.convert2string()), EVM_DEBUG);
        item.start_time = $realtime;
        item_mbx.put(item);
        items_sent++;
    endtask
    
    // Get item from driver's perspective
    virtual task get_next_item(output evm_sequence_item item);
        item_mbx.get(item);
    endtask
    
    // Item completed callback
    virtual function void item_done(evm_sequence_item item);
        item.end_time = $realtime;
        item.completed = 1;
        items_completed++;
        log_info($sformatf("Item completed: %s (%.1fns)", 
                 item.convert2string(), item.get_duration()), EVM_DEBUG);
    endfunction
    
    //==========================================================================
    // Sequence Execution
    //==========================================================================
    
    // Execute entire sequence
    virtual task execute_sequence(evm_sequence seq);
        log_info($sformatf("Executing sequence: %s (%0d items)", 
                 seq.get_name(), seq.get_item_count()), EVM_MED);
        
        foreach (seq.items[i]) begin
            send_item(seq.items[i]);
        end
        
        log_info($sformatf("Sequence sent: %s", seq.get_name()), EVM_MED);
    endtask
    
    //==========================================================================
    // Report Phase
    //==========================================================================
    virtual function void report_phase();
        super.report_phase();
        log_info($sformatf("Sequencer Statistics:"), EVM_LOW);
        log_info($sformatf("  Items Sent: %0d", items_sent), EVM_LOW);
        log_info($sformatf("  Items Completed: %0d", items_completed), EVM_LOW);
    endfunction
    
endclass : evm_sequencer
