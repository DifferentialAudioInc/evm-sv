//==============================================================================
// Reset Agent
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License
//==============================================================================

//==============================================================================
// Class: rst_agent
// Description: Reset control agent
//              Extends evm_component to get phasing support
//==============================================================================

class rst_agent extends evm_component;
    
    //==========================================================================
    // Properties
    //==========================================================================
    virtual rst_if vif;
    virtual clk_if clk_vif;  // Need clock reference for timing
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "rst_agent", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    //==========================================================================
    // Build Phase
    //==========================================================================
    function void build_phase();
        super.build_phase();
        log_info("Reset agent created", EVM_HIGH);
    endfunction
    
    //==========================================================================
    // Set Interfaces
    //==========================================================================
    function void set_vif(virtual rst_if vif, virtual clk_if clk_vif);
        this.vif = vif;
        this.clk_vif = clk_vif;
    endfunction
    
    //==========================================================================
    // Assert Reset
    //==========================================================================
    task assert_reset();
        if (vif == null) begin
            log_error("Reset interface not set!");
            return;
        end
        
        log_info("Asserting reset", EVM_LOW);
        vif.rst_n = 1'b0;
    endtask
    
    //==========================================================================
    // Deassert Reset
    //==========================================================================
    task deassert_reset();
        log_info("Deasserting reset", EVM_LOW);
        vif.rst_n = 1'b1;
    endtask
    
    //==========================================================================
    // Apply Reset Sequence
    // Assert reset, wait N clocks, deassert
    //==========================================================================
    task apply_reset(int cycles = 10);
        if (vif == null) begin
            log_error("Reset interface not set!");
            return;
        end
        
        log_info($sformatf("Applying reset sequence (%0d cycles)", cycles), EVM_LOW);
        
        // Assert reset
        assert_reset();
        
        // Wait N clock cycles
        if (clk_vif != null) begin
            repeat(cycles) @(posedge clk_vif.clk);
        end else begin
            #(cycles * 10ns);  // Fallback if no clock reference
        end
        
        // Deassert reset
        deassert_reset();
        
        // Wait one more clock for reset to propagate
        if (clk_vif != null) begin
            @(posedge clk_vif.clk);
        end else begin
            #10ns;
        end
        
        log_info("Reset sequence complete", EVM_LOW);
    endtask
    
    //==========================================================================
    // Get type name
    //==========================================================================
    virtual function string get_type_name();
        return "rst_agent";
    endfunction
    
endclass : rst_agent
