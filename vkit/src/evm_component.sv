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
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_component", evm_component parent = null);
        super.new(name);
        m_parent = parent;
        
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
    virtual task reset_phase();
        // Phase methods are stubs - override in derived classes
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
