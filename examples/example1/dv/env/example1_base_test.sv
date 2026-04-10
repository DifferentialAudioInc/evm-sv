//==============================================================================
// Class: example1_base_test
// Description: Base test for example1 (AXI Data Transform)
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

virtual class example1_base_test extends evm_base_test;
    
    example1_env env;
    example1_cfg cfg;
    
    virtual evm_axi_lite_if slave_vif;
    virtual evm_axi_lite_if master_vif;
    virtual gpio_if          gpio_vif;
    
    function new(string name = "example1_base_test");
        super.new(name);
        cfg = new("cfg");
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        evm_report_handler::set_verbosity(EVM_MEDIUM);
        env = new("env", this);
        env.cfg = cfg;
        env.slave_vif  = slave_vif;
        env.master_vif = master_vif;
        log_info($sformatf("Test: %s", test_name), EVM_LOW);
        log_info(cfg.convert2string(), EVM_MEDIUM);
    endfunction
    
    virtual task reset_phase();
        super.reset_phase();
        log_info("Waiting for reset release...", EVM_LOW);
        @(posedge slave_vif.aclk iff slave_vif.aresetn === 1'b1);
        repeat(5) @(posedge slave_vif.aclk);
        log_info("Reset released, DUT ready", EVM_LOW);
    endtask
    
    virtual task configure_phase();
        super.configure_phase();
        logic [1:0] resp;
        log_info("Configure: CTRL.ENABLE=1", EVM_LOW);
        env.csr_agent.write(
            32'h0000_0000,
            {29'b0, cfg.fixed_xform_sel, 1'b1},
            4'b1111, resp
        );
        env.csr_agent.write(32'h0000_0010, {24'b0, cfg.gpio_test_val}, 4'b1111, resp);
        log_info($sformatf("GPIO_OUT = 0x%02h", cfg.gpio_test_val), EVM_LOW);
    endtask
    
    // Reference transform function
    static function logic [31:0] apply_xform(logic [31:0] data, logic [1:0] sel);
        logic [31:0] r;
        case (sel)
            2'b00: r = data;
            2'b01: r = ~data;
            2'b10: r = {data[7:0], data[15:8], data[23:16], data[31:24]};
            2'b11: begin for (int k = 0; k < 32; k++) r[k] = data[31-k]; end
        endcase
        return r;
    endfunction
    
    // Drive transform + insert scoreboard expected entry
    task do_transform(
        input  logic [31:0] data_in,
        input  logic  [1:0] xform_sel,
        output logic [31:0] expected_result
    );
        logic [1:0] resp;
        evm_axi_lite_write_txn exp;
        
        expected_result = apply_xform(data_in, xform_sel);
        env.csr_agent.write(32'h0000_0000, {29'b0, xform_sel, 1'b1}, 4'b1111, resp);
        exp = example1_scoreboard::make_expected(expected_result);
        env.scoreboard.insert_expected(exp);
        env.csr_agent.write(32'h0000_0004, data_in, 4'b1111, resp);
        log_info($sformatf(
            "Transform: data_in=0x%08h  xform=%0b  expected=0x%08h",
            data_in, xform_sel, expected_result), EVM_MEDIUM);
    endtask
    
    // Poll STATUS.DONE with timeout
    task poll_done(output bit success);
        bit poll_ok;
        env.csr_agent.poll(32'h0000_0008, 32'h0000_0002, 32'h0000_0002,
                          cfg.timeout_cycles, poll_ok);
        success = poll_ok;
        if (!poll_ok) log_error("Timeout waiting for STATUS.DONE");
    endtask
    
    // Check GPIO output pins (function — no time consumption, safe in check_phase)
    function void check_gpio(logic [7:0] expected);
        if (gpio_vif != null) begin
            if (gpio_vif.gpio !== expected)
                log_error($sformatf("GPIO MISMATCH: expected=0x%02h  actual=0x%02h",
                                   expected, gpio_vif.gpio));
            else
                log_info($sformatf("GPIO OK: 0x%02h", gpio_vif.gpio), EVM_LOW);
        end
    endfunction
    
    //==========================================================================
    // Check Phase — runs after shutdown_phase, all transactions settled
    // GPIO output is stable here: AXI write completed long ago
    //==========================================================================
    virtual function void check_phase();
        super.check_phase();
        // Check GPIO output pins — stable after all AXI writes complete
        check_gpio(cfg.gpio_test_val);
        log_info($sformatf("Check phase: GPIO_OUT verified = 0x%02h", cfg.gpio_test_val), 
                 EVM_LOW);
    endfunction
    
    virtual function void report_phase();
        super.report_phase();
        log_info("=========================================", EVM_LOW);
        log_info($sformatf("Test: %s", test_name), EVM_LOW);
        env.scoreboard.print_report();
        if (evm_log::error_count == 0)
            log_info($sformatf("%s  PASSED", test_name), EVM_LOW);
        else
            log_error($sformatf("%s  FAILED  (%0d errors)", test_name, evm_log::error_count));
        log_info("=========================================", EVM_LOW);
    endfunction
    
    virtual function string get_type_name();
        return "example1_base_test";
    endfunction
    
endclass : example1_base_test
