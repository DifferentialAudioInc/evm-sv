//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_tlm.sv
// Description: TLM (Transaction Level Modeling) Infrastructure for EVM
//              Provides ports, exports, and FIFOs for component communication
//              Simplified version of UVM TLM 1.0
// Author: EVM Contributors
// Date: 2026-03-28
//==============================================================================

//==============================================================================
// Class: evm_analysis_port
// Source: Inspired by UVM TLM 1.0 uvm_analysis_port
// Description: Analysis port for broadcasting transactions to multiple subscribers
//              Used by monitors to broadcast collected transactions
//              1-to-many connection pattern
// Rationale: CRITICAL for verification - monitors must broadcast to:
//            - Scoreboard (for checking)
//            - Coverage collector (for functional coverage)
//            - Protocol checker (for protocol violations)
//            - Transaction logger (for debugging)
//            Without this, monitors can only connect to ONE component!
// UVM Equivalent: uvm_analysis_port#(T)::write(T t)
// Implementation: Uses mailbox array for subscribers, write() broadcasts to all
//==============================================================================
class evm_analysis_port #(type T = int);
    
    typedef evm_analysis_port#(T) this_type;
    
    // Subscribers (implementations that receive broadcasts)
    local mailbox#(T) m_subscribers[$];
    local string m_name;
    local evm_component m_parent;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "analysis_port", evm_component parent = null);
        m_name = name;
        m_parent = parent;
    endfunction
    
    //==========================================================================
    // Write - Broadcast to all subscribers
    //==========================================================================
    function void write(T t);
        if (m_subscribers.size() == 0) begin
            if (m_parent != null) begin
                m_parent.log_warning($sformatf("Analysis port '%s' has no subscribers", m_name));
            end
        end
        
        // Broadcast to all subscribers
        foreach (m_subscribers[i]) begin
            m_subscribers[i].try_put(t);  // Non-blocking put
        end
    endfunction
    
    //==========================================================================
    // Connect - Connect to subscriber mailbox
    //==========================================================================
    function void connect(mailbox#(T) subscriber);
        if (subscriber == null) begin
            if (m_parent != null) begin
                m_parent.log_error("Attempting to connect null subscriber");
            end
            return;
        end
        m_subscribers.push_back(subscriber);
        if (m_parent != null) begin
            m_parent.log_info($sformatf("Connected subscriber to analysis port '%s'", m_name), EVM_HIGH);
        end
    endfunction
    
    //==========================================================================
    // Get subscriber count
    //==========================================================================
    function int size();
        return m_subscribers.size();
    endfunction
    
endclass : evm_analysis_port

//==============================================================================
// Class: evm_analysis_imp
// Description: Analysis implementation - receives broadcasts via mailbox
//              Used by scoreboards, coverage collectors, etc.
//==============================================================================
class evm_analysis_imp #(type T = int);
    
    local mailbox#(T) m_fifo;
    local string m_name;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "analysis_imp", int fifo_size = 0);
        m_name = name;
        if (fifo_size > 0) begin
            m_fifo = new(fifo_size);
        end else begin
            m_fifo = new();  // Unbounded
        end
    endfunction
    
    //==========================================================================
    // Get mailbox for connection
    //==========================================================================
    function mailbox#(T) get_mailbox();
        return m_fifo;
    endfunction
    
    //==========================================================================
    // Get - Blocking get from FIFO
    //==========================================================================
    task get(output T t);
        m_fifo.get(t);
    endtask
    
    //==========================================================================
    // Try get - Non-blocking get
    //==========================================================================
    function int try_get(output T t);
        return m_fifo.try_get(t);
    endfunction
    
    //==========================================================================
    // Check if data available
    //==========================================================================
    function int num();
        return m_fifo.num();
    endfunction
    
endclass : evm_analysis_imp

//==============================================================================
// Class: evm_seq_item_pull_port
// Source: Inspired by UVM TLM uvm_seq_item_pull_port
// Description: Port for driver to pull sequence items from sequencer
//              REQ = Request item type
//              RSP = Response item type (optional, defaults to REQ)
// Rationale: CRITICAL for proper sequence-based stimulus:
//            - Provides standard driver-sequencer protocol
//            - get_next_item() blocks until item available
//            - item_done() signals completion (optional response)
//            - try_next_item() allows non-blocking access
//            Without this, no standard way for drivers to get sequences!
// UVM Equivalent: uvm_seq_item_pull_port#(REQ,RSP)
// Protocol: 1. get_next_item(req) - blocking get
//           2. Drive req to DUT
//           3. item_done(rsp) - signal done, optional response
//==============================================================================
class evm_seq_item_pull_port #(type REQ = int, type RSP = REQ);
    
    local mailbox#(REQ) m_req_fifo;
    local mailbox#(RSP) m_rsp_fifo;
    local string m_name;
    local evm_component m_parent;
    local bit m_connected;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "seq_item_port", evm_component parent = null);
        m_name = name;
        m_parent = parent;
        m_connected = 0;
    endfunction
    
    //==========================================================================
    // Connect to sequencer export
    //==========================================================================
    function void connect(mailbox#(REQ) req_fifo, mailbox#(RSP) rsp_fifo);
        if (req_fifo == null) begin
            if (m_parent != null) begin
                m_parent.log_fatal("Cannot connect to null request FIFO");
            end
            return;
        end
        
        m_req_fifo = req_fifo;
        m_rsp_fifo = rsp_fifo;
        m_connected = 1;
        
        if (m_parent != null) begin
            m_parent.log_info($sformatf("Connected seq_item_port '%s'", m_name), EVM_MEDIUM);
        end
    endfunction
    
    //==========================================================================
    // Get next item - Blocking
    //==========================================================================
    task get_next_item(output REQ req);
        if (!m_connected) begin
            if (m_parent != null) begin
                m_parent.log_fatal("seq_item_port not connected");
            end
            return;
        end
        
        m_req_fifo.get(req);
        
        if (m_parent != null) begin
            m_parent.log_info("Got next sequence item", EVM_DEBUG);
        end
    endtask
    
    //==========================================================================
    // Try next item - Non-blocking
    //==========================================================================
    task try_next_item(output REQ req);
        // Initialize to default (Vivado: avoid 'null' directly with parameterized types)
        automatic REQ _no_item = null;
        req = _no_item;
        if (!m_connected) begin
            if (m_parent != null) begin
                m_parent.log_error("seq_item_port not connected");
            end
            return;
        end
        
        void'(m_req_fifo.try_get(req));  // req stays null if nothing available
    endtask
    
    //==========================================================================
    // Item done - Signal completion and optionally send response
    //==========================================================================
    task item_done(input RSP rsp = RSP'(0));  // avoid null default in parameterized context
        if (!m_connected) begin
            if (m_parent != null) begin
                m_parent.log_error("seq_item_port not connected");
            end
            return;
        end
        
        // Send response if provided and response FIFO exists
        if (rsp != null && m_rsp_fifo != null) begin
            m_rsp_fifo.put(rsp);
        end
        
        if (m_parent != null) begin
            m_parent.log_info("Sequence item done", EVM_DEBUG);
        end
    endtask
    
    //==========================================================================
    // Peek - Look at next item without removing
    //==========================================================================
    task peek(output REQ req);
        automatic REQ _no_item = null;
        req = _no_item;  // default initialization
        if (!m_connected) begin
            if (m_parent != null) begin
                m_parent.log_error("seq_item_port not connected");
            end
            return;
        end
        
        m_req_fifo.peek(req);
    endtask
    
    //==========================================================================
    // Check if connected
    //==========================================================================
    function bit is_connected();
        return m_connected;
    endfunction
    
endclass : evm_seq_item_pull_port

//==============================================================================
// Class: evm_seq_item_pull_export
// Source: Inspired by UVM TLM uvm_seq_item_pull_export
// Description: Export for sequencer to provide sequence items to driver
//              Connects to internal FIFOs
// Rationale: Completes the driver-sequencer connection:
//            - Export provides FIFOs that port connects to
//            - Sequences put() items into request FIFO
//            - Driver get_next_item() pulls from request FIFO
//            - Driver item_done(rsp) puts into response FIFO
// UVM Equivalent: uvm_seq_item_pull_export#(REQ,RSP)
// Connection: driver.seq_item_port.connect(sequencer.seq_item_export.get_fifos())
//==============================================================================
class evm_seq_item_pull_export #(type REQ = int, type RSP = REQ);
    
    local mailbox#(REQ) m_req_fifo;
    local mailbox#(RSP) m_rsp_fifo;
    local string m_name;
    local evm_component m_parent;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "seq_item_export", evm_component parent = null, int fifo_size = 0);
        m_name = name;
        m_parent = parent;
        
        // Create FIFOs
        if (fifo_size > 0) begin
            m_req_fifo = new(fifo_size);
            m_rsp_fifo = new(fifo_size);
        end else begin
            m_req_fifo = new();  // Unbounded
            m_rsp_fifo = new();
        end
    endfunction
    
    //==========================================================================
    // Get FIFO handles for connection
    //==========================================================================
    function mailbox#(REQ) get_req_fifo();
        return m_req_fifo;
    endfunction
    
    function mailbox#(RSP) get_rsp_fifo();
        return m_rsp_fifo;
    endfunction
    
    //==========================================================================
    // Put request item (from sequence)
    //==========================================================================
    task put(REQ req);
        m_req_fifo.put(req);
    endtask
    
    //==========================================================================
    // Try put (non-blocking)
    //==========================================================================
    function bit try_put(REQ req);
        return m_req_fifo.try_put(req);
    endfunction
    
    //==========================================================================
    // Get response (if any)
    //==========================================================================
    task get_response(output RSP rsp);
        m_rsp_fifo.get(rsp);
    endtask
    
    //==========================================================================
    // Try get response (non-blocking)
    //==========================================================================
    function bit try_get_response(output RSP rsp);
        return m_rsp_fifo.try_get(rsp);
    endfunction
    
    //==========================================================================
    // Check pending items
    //==========================================================================
    function int num_pending();
        return m_req_fifo.num();
    endfunction
    
endclass : evm_seq_item_pull_export

//==============================================================================
// Class: evm_tlm_fifo
// Description: General purpose FIFO for TLM communication
//              Provides both put and get interfaces
//==============================================================================
class evm_tlm_fifo #(type T = int);
    
    local mailbox#(T) m_fifo;
    local string m_name;
    local int m_size;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "tlm_fifo", int size = 0);
        m_name = name;
        m_size = size;
        
        if (size > 0) begin
            m_fifo = new(size);
        end else begin
            m_fifo = new();  // Unbounded
        end
    endfunction
    
    //==========================================================================
    // Put - Blocking
    //==========================================================================
    task put(T t);
        m_fifo.put(t);
    endtask
    
    //==========================================================================
    // Try put - Non-blocking
    //==========================================================================
    function bit try_put(T t);
        return m_fifo.try_put(t);
    endfunction
    
    //==========================================================================
    // Get - Blocking
    //==========================================================================
    task get(output T t);
        m_fifo.get(t);
    endtask
    
    //==========================================================================
    // Try get - Non-blocking
    //==========================================================================
    function bit try_get(output T t);
        return m_fifo.try_get(t);
    endfunction
    
    //==========================================================================
    // Peek - Look without removing
    //==========================================================================
    task peek(output T t);
        m_fifo.peek(t);
    endtask
    
    //==========================================================================
    // Try peek - Non-blocking peek
    //==========================================================================
    function bit try_peek(output T t);
        return m_fifo.try_peek(t);
    endfunction
    
    //==========================================================================
    // Status methods
    //==========================================================================
    function int num();
        return m_fifo.num();
    endfunction
    
    function bit is_empty();
        return (m_fifo.num() == 0);
    endfunction
    
    function bit is_full();
        if (m_size == 0) return 0;  // Unbounded never full
        return (m_fifo.num() >= m_size);
    endfunction
    
    function int size();
        return m_size;
    endfunction
    
    //==========================================================================
    // Flush - Clear all items
    //==========================================================================
    function void flush();
        T dummy;
        while (m_fifo.try_get(dummy)) begin
            // Keep getting until empty
        end
    endfunction
    
endclass : evm_tlm_fifo
