//==============================================================================
// Class: system_reg_model
// Description: EVM register model for System control and status module
// Generated: 2026-03-07 16:48:06
// Source: evm/csr_gen/example/example_csr_definitions.yaml
//==============================================================================

class system_reg_model extends evm_object;

    //==========================================================================
    // Register Block and Registers
    //==========================================================================
    evm_reg_block reg_block;

    evm_reg version;
    evm_reg control;
    evm_reg status;
    evm_reg led_control;
    evm_reg scratch0;
    evm_reg scratch1;
    evm_reg timestamp_lo;
    evm_reg timestamp_hi;
    evm_reg test_reg;

    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "system_reg_model");
        super.new(name);
        build();
    endfunction

    //==========================================================================
    // Build - Create register block and registers
    //==========================================================================
    virtual function void build();
        evm_reg_field field;

        // Create register block
        reg_block = new("system", 64'h00000000);

        // Build VERSION register
        version = new("VERSION", 64'h00000000 + 32'h00000000, 32);

        field = new("MAJOR", 24, 8, EVM_REG_RO, 8'h1);
        version.add_field(field);
        field = new("MINOR", 16, 8, EVM_REG_RO, 8'h0);
        version.add_field(field);
        field = new("PATCH", 8, 8, EVM_REG_RO, 8'h0);
        version.add_field(field);
        field = new("BUILD", 0, 8, EVM_REG_RO, 8'h0);
        version.add_field(field);
        reg_block.add_reg(version);

        // Build CONTROL register
        control = new("CONTROL", 64'h00000000 + 32'h00000004, 32);

        field = new("RESET", 0, 1, EVM_REG_RW, 1'h0);
        control.add_field(field);
        field = new("ENABLE", 1, 1, EVM_REG_RW, 1'h0);
        control.add_field(field);
        field = new("DEBUG_MODE", 2, 1, EVM_REG_RW, 1'h0);
        control.add_field(field);
        field = new("RESERVED", 3, 29, EVM_REG_RW, 29'h0);
        control.add_field(field);
        reg_block.add_reg(control);

        // Build STATUS register
        status = new("STATUS", 64'h00000000 + 32'h00000008, 32);

        field = new("READY", 0, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("ERROR", 1, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("LOCKED", 2, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("RESERVED", 3, 29, EVM_REG_RO, 29'h0);
        status.add_field(field);
        reg_block.add_reg(status);

        // Build LED_CONTROL register
        led_control = new("LED_CONTROL", 64'h00000000 + 32'h0000000C, 32);

        field = new("LED0", 0, 1, EVM_REG_RW, 1'h0);
        led_control.add_field(field);
        field = new("LED1", 1, 1, EVM_REG_RW, 1'h0);
        led_control.add_field(field);
        field = new("LED2", 2, 1, EVM_REG_RW, 1'h0);
        led_control.add_field(field);
        field = new("LED3", 3, 1, EVM_REG_RW, 1'h0);
        led_control.add_field(field);
        field = new("RESERVED", 4, 28, EVM_REG_RW, 28'h0);
        led_control.add_field(field);
        reg_block.add_reg(led_control);

        // Build SCRATCH0 register
        scratch0 = new("SCRATCH0", 64'h00000000 + 32'h00000010, 32);

        field = new("DATA", 0, 32, EVM_REG_RW, 32'h0);
        scratch0.add_field(field);
        reg_block.add_reg(scratch0);

        // Build SCRATCH1 register
        scratch1 = new("SCRATCH1", 64'h00000000 + 32'h00000014, 32);

        field = new("DATA", 0, 32, EVM_REG_RW, 32'hDEADBEEF);
        scratch1.add_field(field);
        reg_block.add_reg(scratch1);

        // Build TIMESTAMP_LO register
        timestamp_lo = new("TIMESTAMP_LO", 64'h00000000 + 32'h00000018, 32);

        field = new("COUNT", 0, 32, EVM_REG_RO, 32'h0);
        timestamp_lo.add_field(field);
        reg_block.add_reg(timestamp_lo);

        // Build TIMESTAMP_HI register
        timestamp_hi = new("TIMESTAMP_HI", 64'h00000000 + 32'h0000001C, 32);

        field = new("COUNT", 0, 32, EVM_REG_RO, 32'h0);
        timestamp_hi.add_field(field);
        reg_block.add_reg(timestamp_hi);

        // Build TEST_REG register
        test_reg = new("TEST_REG", 64'h00000000 + 32'h00000020, 32);

        field = new("VAL", 0, 32, EVM_REG_RO, 32'h12345678);
        test_reg.add_field(field);
        reg_block.add_reg(test_reg);

        log_info("Register model 'system' built successfully", EVM_LOW);
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

    // Read from VERSION
    task read_version(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        version.read(val64, status);
        value = val64[31:0];
    endtask

    // Write to CONTROL
    task write_control(bit [31:0] value, output bit status);
        control.write(value, status);
    endtask

    // Read from CONTROL
    task read_control(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        control.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from STATUS
    task read_status(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        status.read(val64, status);
        value = val64[31:0];
    endtask

    // Write to LED_CONTROL
    task write_led_control(bit [31:0] value, output bit status);
        led_control.write(value, status);
    endtask

    // Read from LED_CONTROL
    task read_led_control(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        led_control.read(val64, status);
        value = val64[31:0];
    endtask

    // Write to SCRATCH0
    task write_scratch0(bit [31:0] value, output bit status);
        scratch0.write(value, status);
    endtask

    // Read from SCRATCH0
    task read_scratch0(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        scratch0.read(val64, status);
        value = val64[31:0];
    endtask

    // Write to SCRATCH1
    task write_scratch1(bit [31:0] value, output bit status);
        scratch1.write(value, status);
    endtask

    // Read from SCRATCH1
    task read_scratch1(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        scratch1.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from TIMESTAMP_LO
    task read_timestamp_lo(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        timestamp_lo.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from TIMESTAMP_HI
    task read_timestamp_hi(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        timestamp_hi.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from TEST_REG
    task read_test_reg(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        test_reg.read(val64, status);
        value = val64[31:0];
    endtask

    //==========================================================================
    // Dump - Print all register values
    //==========================================================================
    virtual function void dump();
        reg_block.dump();
    endfunction

endclass : system_reg_model