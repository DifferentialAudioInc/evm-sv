//==============================================================================
// Class: top_reg_model
// Description: Top-level register model containing all modules
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

class top_reg_model extends evm_object;

    //==========================================================================
    // Module Register Models
    //==========================================================================
    system_reg_model system;
    adc_reg_model adc;
    fft_reg_model fft;

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
        system = new("system_reg_model");
        adc = new("adc_reg_model");
        fft = new("fft_reg_model");
        log_info("Top-level register model built successfully", EVM_LOW);
    endfunction

    //==========================================================================
    // Configure - Set agent for all module register models
    //==========================================================================
    virtual function void configure(evm_component agent);
        system.configure(agent);
        adc.configure(agent);
        fft.configure(agent);
        log_info("All module register models configured with agent", EVM_LOW);
    endfunction

    //==========================================================================
    // Reset - Reset all module register models
    //==========================================================================
    virtual function void reset(string kind = "HARD");
        system.reset(kind);
        adc.reset(kind);
        fft.reset(kind);
    endfunction

    //==========================================================================
    // Dump - Print all register values from all modules
    //==========================================================================
    virtual function void dump();
        log_info("=== Top-Level Register Map ===", EVM_NONE);
        log_info("\n--- SYSTEM (System control and status module) ---", EVM_NONE);
        system.dump();
        log_info("\n--- ADC (ADC control and status module) ---", EVM_NONE);
        adc.dump();
        log_info("\n--- FFT (FFT processing module) ---", EVM_NONE);
        fft.dump();
    endfunction

endclass : top_reg_model