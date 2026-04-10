//==============================================================================
// Class: axi_data_xform_reg_model
// Description: EVM register model for AXI Data Transform DUT registers
// Generated: 2026-04-10 00:05:08
// Source: c:\evm\evm-sv\examples\axi_data_xform\rtl\axi_data_xform_csr.yaml
//==============================================================================

class axi_data_xform_reg_model extends evm_object;

    //==========================================================================
    // Register Block and Registers
    //==========================================================================
    evm_reg_block reg_block;

    evm_reg ctrl;
    evm_reg data_in;
    evm_reg status;
    evm_reg result;
    evm_reg gpio_out;

    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "axi_data_xform_reg_model");
        super.new(name);
        build();
    endfunction

    //==========================================================================
    // Build - Create register block and registers
    //==========================================================================
    virtual function void build();
        evm_reg_field field;

        // Create register block
        reg_block = new("axi_data_xform", 64'h00000000);

        // Build CTRL register
        ctrl = new("CTRL", 64'h00000000 + 32'h00000000, 32);

        field = new("ENABLE", 0, 1, EVM_REG_RW, 1'h0);
        ctrl.add_field(field);
        field = new("XFORM_SEL", 1, 2, EVM_REG_RW, 2'h0);
        ctrl.add_field(field);
        reg_block.add_reg(ctrl);

        // Build DATA_IN register
        data_in = new("DATA_IN", 64'h00000000 + 32'h00000004, 32);

        field = new("DATA", 0, 32, EVM_REG_RW, 32'h0);
        data_in.add_field(field);
        reg_block.add_reg(data_in);

        // Build STATUS register
        status = new("STATUS", 64'h00000000 + 32'h00000008, 32);

        field = new("BUSY", 0, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        field = new("DONE", 1, 1, EVM_REG_RO, 1'h0);
        status.add_field(field);
        reg_block.add_reg(status);

        // Build RESULT register
        result = new("RESULT", 64'h00000000 + 32'h0000000C, 32);

        field = new("DATA", 0, 32, EVM_REG_RO, 32'h0);
        result.add_field(field);
        reg_block.add_reg(result);

        // Build GPIO_OUT register
        gpio_out = new("GPIO_OUT", 64'h00000000 + 32'h00000010, 32);

        field = new("GPIO", 0, 8, EVM_REG_RW, 8'h0);
        gpio_out.add_field(field);
        reg_block.add_reg(gpio_out);

        log_info("Register model 'axi_data_xform' built successfully", EVM_LOW);
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

    // Write to CTRL
    task write_ctrl(bit [31:0] value, output bit status);
        ctrl.write(value, status);
    endtask

    // Read from CTRL
    task read_ctrl(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        ctrl.read(val64, status);
        value = val64[31:0];
    endtask

    // Write to DATA_IN
    task write_data_in(bit [31:0] value, output bit status);
        data_in.write(value, status);
    endtask

    // Read from DATA_IN
    task read_data_in(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        data_in.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from STATUS
    task read_status(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        status.read(val64, status);
        value = val64[31:0];
    endtask

    // Read from RESULT
    task read_result(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        result.read(val64, status);
        value = val64[31:0];
    endtask

    // Write to GPIO_OUT
    task write_gpio_out(bit [31:0] value, output bit status);
        gpio_out.write(value, status);
    endtask

    // Read from GPIO_OUT
    task read_gpio_out(output bit [31:0] value, output bit status);
        bit [63:0] val64;
        gpio_out.read(val64, status);
        value = val64[31:0];
    endtask

    //==========================================================================
    // Dump - Print all register values
    //==========================================================================
    virtual function void dump();
        reg_block.dump();
    endfunction

endclass : axi_data_xform_reg_model