//==============================================================================
// Class: top_reg_model
// Description: Top-level register model containing all modules
// Generated: 2026-04-10 15:26:15
// Source: c:\evm\evm-sv\examples\example1\csr\example1.yaml
//==============================================================================

class top_reg_model extends evm_object;

    //==========================================================================
    // Module Register Models
    //==========================================================================
    axi_data_xform_reg_model axi_data_xform;

    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "top_reg_model");
        super.new(name);
        build();
    endfunction

    //==========================================================================
    // Build - Create all module register models
    //==========================================================================
    virtual function void build();
        axi_data_xform = new("axi_data_xform_reg_model");
        log_info("Top-level register model built successfully", EVM_LOW);
    endfunction

    //==========================================================================
    // Configure - Set agent for all module register models
    //==========================================================================
    virtual function void configure(evm_component agent);
        axi_data_xform.configure(agent);
        log_info("All module register models configured with agent", EVM_LOW);
    endfunction

    //==========================================================================
    // Reset - Reset all module register models
    //==========================================================================
    virtual function void reset(string kind = "HARD");
        axi_data_xform.reset(kind);
    endfunction

    //==========================================================================
    // Dump - Print all register values from all modules
    //==========================================================================
    virtual function void dump();
        log_info("=== Top-Level Register Map ===", EVM_NONE);
        log_info("\n--- axi_data_xform (AXI Data Transform DUT registers) ---", EVM_NONE);
        axi_data_xform.dump();
    endfunction

endclass : top_reg_model