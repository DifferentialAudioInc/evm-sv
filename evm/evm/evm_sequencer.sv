//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_sequencer
// Description: Sequencer - manages and dispatches sequence items to driver
//              Uses mailbox for item passing
// Author: Engineering Team
// Date: 2026-03-06
//==============================================================================

class evm_sequencer extends evm_component;
    
    //==========================================================================
    // Mailbox for Item Passing
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
        item_mbx = new();
        items_sent = 0;
        items_completed = 0;
    endfunction
    
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
