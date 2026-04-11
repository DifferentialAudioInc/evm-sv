//==============================================================================
// EVM - Embedded Verification Methodology
// Virtual Sequences
// Coordinates multiple sequencers for complex test scenarios
//==============================================================================

//==============================================================================
// Class: evm_virtual_sequencer
// Description: Virtual sequencer - doesn't drive anything directly
//              Contains references to multiple sub-sequencers
//              Used by virtual sequences to coordinate traffic
// Usage: Create in environment, add references to real sequencers
//==============================================================================
class evm_virtual_sequencer extends evm_component;
    
    // Virtual sequencers don't have seq_item_export
    // They just hold references to sub-sequencers
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "virtual_sequencer", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_virtual_sequencer";
    endfunction
    
endclass

//==============================================================================
// Class: evm_virtual_sequence
// Description: Virtual sequence - coordinates multiple sequencers
//              Override body() to implement test scenario
// Usage: 
//   class my_vseq extends evm_virtual_sequence;
//       my_sequencer_a seqr_a;
//       my_sequencer_b seqr_b;
//       
//       virtual task body();
//           fork
//               start_sequence_a();
//               start_sequence_b();
//           join
//       endtask
//   endclass
//==============================================================================
virtual class evm_virtual_sequence extends evm_sequence;
    
    // Reference to virtual sequencer
    evm_virtual_sequencer v_sequencer;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "virtual_sequence");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Start sequence on virtual sequencer
    //==========================================================================
    virtual task start(evm_virtual_sequencer sequencer);
        if (sequencer == null) begin
            evm_report_handler::report(EVM_ERROR, "evm_virtual_sequence", 
                "Virtual sequencer is null");
            return;
        end
        
        v_sequencer = sequencer;
        
        // Raise objection via evm_root (v_sequencer doesn't have raise_objection)
        evm_root::get().raise_objection({get_name(), "_running"});
        
        // Execute body
        body();
        
        // Drop objection
        evm_root::get().drop_objection({get_name(), "_running"});
    endtask
    
    //==========================================================================
    // Body - Override in derived class
    //==========================================================================
    virtual task body();
        // Override in derived class
        evm_report_handler::report(EVM_WARNING, "evm_virtual_sequence", 
            "Virtual sequence body() not implemented - override in derived class");
    endtask
    
endclass

//==============================================================================
// Example: Multi-interface virtual sequence
//==============================================================================
// class soc_virtual_sequencer extends evm_virtual_sequencer;
//     axi_sequencer    axi_seqr;
//     apb_sequencer    apb_seqr;
//     uart_sequencer   uart_seqr;
//     
//     function new(string name, evm_component parent);
//         super.new(name, parent);
//     endfunction
// endclass
//
// class soc_base_vseq extends evm_virtual_sequence;
//     soc_virtual_sequencer v_seqr;
//     
//     virtual task start(evm_virtual_sequencer sequencer);
//         if (!$cast(v_seqr, sequencer)) begin
//             `EVM_ASSERT_FATAL(0, "Wrong sequencer type")
//         end
//         super.start(sequencer);
//     endtask
//     
//     virtual task body();
//         axi_write_seq  axi_wr_seq;
//         apb_config_seq apb_cfg_seq;
//         
//         fork
//             // Parallel AXI and APB traffic
//             begin
//                 axi_wr_seq = new("axi_write");
//                 axi_wr_seq.start(v_seqr.axi_seqr);
//             end
//             begin
//                 apb_cfg_seq = new("apb_config");
//                 apb_cfg_seq.start(v_seqr.apb_seqr);
//             end
//         join
//     endtask
// endclass
//==============================================================================

// NOTE: Sequence coordination utility tasks removed pending API review.
// evm_sequence does not expose a run-time execution method at the evm_sequence level.
// These tasks will be re-enabled once the correct execution API is confirmed.
// See NEXT_STEPS.md for details.
