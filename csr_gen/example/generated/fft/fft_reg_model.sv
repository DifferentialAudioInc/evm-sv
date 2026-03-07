//==============================================================================
// Class: fft_reg_model
// Description: EVM register model for FFT processing module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

class fft_reg_model extends evm_object;

    //==========================================================================
    // Register Block and Registers
    //==========================================================================
    evm_reg_block reg_block;

    evm_reg config;
    evm_reg status;

    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "fft_reg_model");
        super.new(name);
        build();
    endfunction

    //==========================================================================
    // Build - Create register block and registers
    //==========================================================================
    virtual function void build();
        evm_reg_field field;

        // Create register block
        reg_block = new("fft", 64'h00002000);

        // Build CONFIG register
        config = new("CONFIG", 64'h00002000 + 32'h00000000, 32);

        field = new("ENABLE", 0, 1, EVM_REG_RW, 1'h0);
        config.add_field(field);
        field = new("SIZE", 1, 4, EVM_REG_RW, 4'h0);
        config.add_field(field);
        field = new("WINDOW", 5, 3, EVM_REG_RW, 3'h0);
        config.add_field(field);
        field = new("OVERLAP", 8, 2, EVM_REG_RW, 2'h0);
        config.add_field(field);
        field = new("RESERVED", 10, 22, EVM_REG_RW, 22'h4);
        config.add_field(field);
        reg_block.add_reg(config);

        // Build STATUS register
        status = new("STATUS", 64'h00002000 + 32'h00000004, 32);

        field = new("BUSY", 0, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("DONE", 1, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("OVERFLOW", 2, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("RESERVED", 3, 29, EVM_REG_RO, 29'h0);
        status.add_field(field);
        reg_block.add_reg(status);

        log_info("Register model 'fft' built successfully", EVM_LOW);
    endfunction

    //==========================================================================
    // Configure - Set agent for transaction execution
    //==========================================================================
    virtual function void configure(evm_component agent);
        reg_block.set_agent(agent);
        log_info("Register model configured with agent", EVM_LOW);
    endfunction

    //==========================================================================
    // Reset - Reset all registers to their reset values
    //==========================================================================
    virtual function void reset(string kind = "HARD");
        reg_block.reset(kind);
    endfunction

    //==========================================================================
    // Convenience Methods
    //==========================================================================

    // Write to CONFIG
    task write_config(bit [31:0] value, output bit status);
        config.write(value, status);
    endtask

    // Read from CONFIG
    task read_config(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        config.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from STATUS
    task read_status(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        status.read(val64, status);
        value = val64[31:0];
    endtask

    //==========================================================================
    // Dump - Print all register values
    //==========================================================================
    virtual function void dump();
        reg_block.dump();
    endfunction

endclass : fft_reg_model