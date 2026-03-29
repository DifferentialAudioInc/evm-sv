//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_component
// Description: Base component class for Embedded Verification Methodology (EVM)
//              Extends evm_object with hierarchy and logging support
//              Lightweight alternative to uvm_component
// Author: Engineering Team
// Date: 2026-03-05
//==============================================================================

virtual class evm_component extends evm_object;
    
    //==========================================================================
    // Properties
    //==========================================================================
    protected evm_component m_parent;
    protected string        m_full_name;
    protected evm_component m_children[$];
    protected string        m_child_names[$];
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_component", evm_component parent = null);
        super.new(name);
        m_parent = parent;
        
        // Register with parent
        if (parent != null) begin
            parent.add_child(name, this);
        end
        
        // Build hierarchical full name
        if (parent == null) begin
            m_full_name = name;
        end else begin
            m_full_name = {parent.get_full_name(), ".", name};
        end
        
        // Update name to hierarchical name for logging
        m_name = m_full_name;
        
        // Log creation at HIGH verbosity
        log_info($sformatf("Created %s", get_type_name()), EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Hierarchy Methods
    //==========================================================================
    
    // Get parent component
    virtual function evm_component get_parent();
        return m_parent;
    endfunction
    
    // Get full hierarchical name
    virtual function string get_full_name();
        return m_full_name;
    endfunction
    
    // Get type name
    virtual function string get_type_name();
        return "evm_component";
    endfunction
    
    //==========================================================================
    // Child Management Methods
    // Source: Inspired by uvm_component child tracking and hierarchy methods
    // Rationale: Essential for debugging and introspection:
    //            - Cannot debug testbench without seeing component tree
    //            - Need to query hierarchy for configuration
    //            - print_topology() is invaluable for understanding structure
    // UVM Equivalent: uvm_component::get_child(), get_num_children(), etc.
    // Implementation: Uses dynamic arrays m_children[] and m_child_names[]
    //                 Children auto-register with parent in constructor
    //==========================================================================
    
    // Add child (called from child constructor)
    protected function void add_child(string name, evm_component child);
        m_child_names.push_back(name);
        m_children.push_back(child);
    endfunction
    
    // Get child by name
    virtual function evm_component get_child(string name);
        foreach (m_child_names[i]) begin
            if (m_child_names[i] == name) begin
                return m_children[i];
            end
        end
        log_warning($sformatf("Child '%s' not found in %s", name, get_full_name()));
        return null;
    endfunction
    
    // Get number of children
    virtual function int get_num_children();
        return m_children.size();
    endfunction
    
    // Get first child (iterator support)
    virtual function int get_first_child(ref string name);
        if (m_children.size() > 0) begin
            name = m_child_names[0];
            return 1;
        end
        return 0;
    endfunction
    
    // Get next child (iterator support)  
    virtual function int get_next_child(ref string name);
        int found_current = 0;
        foreach (m_child_names[i]) begin
            if (found_current) begin
                name = m_child_names[i];
                return 1;
            end
            if (m_child_names[i] == name) begin
                found_current = 1;
            end
        end
        return 0;
    endfunction
    
    // Lookup by hierarchical name
    virtual function evm_component lookup(string name);
        string names[$];
        string token;
        int start, dot_pos;
        evm_component current = this;
        
        // Parse hierarchical name by splitting on '.'
        start = 0;
        while (start < name.len()) begin
            dot_pos = start;
            while (dot_pos < name.len() && name[dot_pos] != ".") begin
                dot_pos++;
            end
            
            token = name.substr(start, dot_pos-1);
            if (token.len() > 0) begin
                names.push_back(token);
            end
            
            start = dot_pos + 1;
        end
        
        // Traverse hierarchy
        foreach (names[i]) begin
            current = current.get_child(names[i]);
            if (current == null) begin
                return null;
            end
        end
        
        return current;
    endfunction
    
    // Print topology
    virtual function void print_topology(int indent = 0);
        string spaces = "";
        
        // Create indentation
        for (int i = 0; i < indent; i++) begin
            spaces = {spaces, "  "};
        end
        
        // Print this component
        $display("%s%s (%s)", spaces, get_name(), get_type_name());
        
        // Print children recursively
        foreach (m_children[i]) begin
            m_children[i].print_topology(indent + 1);
        end
    endfunction
    
    //==========================================================================
    // Phase Methods (to be overridden by derived classes)
    //==========================================================================
    
    // Build phase - construct and configure
    virtual function void build_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // Connect phase - make connections
    virtual function void connect_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // End of elaboration - finalize configuration
    virtual function void end_of_elaboration_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // Start of simulation - initialization at time 0
    virtual function void start_of_simulation_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // Reset phase - apply and wait for reset
    // Calls pre_reset, reset, post_reset in sequence
    virtual task reset_phase();
        // Execute reset sequence
        pre_reset();
        reset();
        post_reset();
    endtask
    
    //==========================================================================
    // Reset Sub-Phases (Virtual - Override in Derived Classes)
    // Source: EVM-specific enhancement (not in UVM)
    // Rationale: Embedded systems require robust reset handling:
    //            - DUTs undergo multiple resets during testing
    //            - Must clear queues/scoreboards on reset
    //            - Three phases provide clean separation of concerns
    // Design: pre_reset()  -> Prepare (stop activities, save state)
    //         reset()      -> Clear (delete queues, reset counters)
    //         post_reset() -> Reinitialize (prepare for operation)
    // UVM Note: UVM only has single reset_phase(), EVM splits into 3 for clarity
    //==========================================================================
    
    // Pre-reset: Prepare for reset
    // - Stop ongoing activities
    // - Save state if needed
    // - Prepare queues/FIFOs for clearing
    virtual task pre_reset();
        // Default: no action
        // Override in derived classes to add pre-reset functionality
    endtask
    
    // Reset: Perform actual reset operations
    // - Clear all queues
    // - Delete pending transactions
    // - Reset scoreboards/predictors
    // - Clear all internal state
    virtual task reset();
        // Default: no action
        // Override in derived classes to clear state
    endtask
    
    // Post-reset: Cleanup after reset
    // - Reinitialize data structures
    // - Reset counters/statistics
    // - Prepare for normal operation
    virtual task post_reset();
        // Default: no action
        // Override in derived classes to reinitialize
    endtask
    
    // Configure phase - configure DUT after reset
    virtual task configure_phase();
        // Phase methods are stubs - override in derived classes
    endtask
    
    // Main phase - primary test activity (renamed from run_phase)
    virtual task main_phase();
        // Phase methods are stubs - override in derived classes
    endtask
    
    // Shutdown phase - graceful shutdown
    virtual task shutdown_phase();
        // Phase methods are stubs - override in derived classes
    endtask
    
    // Extract phase - collect results
    virtual function void extract_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // Check phase - verify results
    virtual function void check_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // Report phase - print results
    virtual function void report_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    // Final phase - cleanup
    virtual function void final_phase();
        // Phase methods are stubs - override in derived classes
    endfunction
    
    //==========================================================================
    // Objection Convenience Methods
    // Note: These are stubs - actual objection control is in evm_root
    // Tests should call evm_root::get().raise_objection() directly
    //==========================================================================
    
    //==========================================================================
    // Utility Methods
    //==========================================================================
    
    // Convert to string
    virtual function string convert2string();
        return $sformatf("%s [%s]", m_full_name, get_type_name());
    endfunction
    
    // Print component information
    virtual function void print();
        $display("%s", convert2string());
    endfunction
    
endclass : evm_component
