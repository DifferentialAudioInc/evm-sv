//==============================================================================
// Class: basic_write_test
// Description: Basic smoke test — one passthrough transform + GPIO check
//   1. CTRL.ENABLE=1, XFORM_SEL=0 (passthrough)
//   2. Write DATA_IN=0xDEAD_BEEF
//   3. Wait for STATUS.DONE
//   4. Read RESULT — verify = 0xDEAD_BEEF
//   5. Scoreboard checks DUT master write = 0xDEAD_BEEF
//   6. Check GPIO pins = cfg.gpio_test_val
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

class basic_write_test extends example1_base_test;
    
    function new(string name = "basic_write_test");
        super.new(name);
        cfg.fixed_xform_sel    = 2'b00;   // passthrough
        cfg.num_transactions   = 1;
        cfg.gpio_test_val      = 8'hA5;
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("basic_write_test");
        
        begin
            logic [31:0] data_in = 32'hDEAD_BEEF;
            logic [31:0] expected;
            logic [31:0] result_readback;
            logic [1:0]  resp;
            bit           done;
            
            log_info($sformatf("Writing DATA_IN = 0x%08h", data_in), EVM_LOW);
            
            // Trigger transform (inserts expected into scoreboard)
            do_transform(data_in, 2'b00, expected);
            
            // Poll STATUS.DONE
            poll_done(done);
            
            // Read back RESULT register directly
            env.csr_agent.read(32'h0000_000C, result_readback, resp);
            log_info($sformatf("RESULT readback = 0x%08h  (expected 0x%08h)",
                              result_readback, expected), EVM_LOW);
            
            if (result_readback !== expected)
                log_error($sformatf(
                    "RESULT register mismatch: got 0x%08h expected 0x%08h",
                    result_readback, expected));
            
            // Small drain time for scoreboard to receive DUT master write
            // (GPIO is checked in check_phase() after simulation settles)
            repeat(20) @(posedge slave_vif.aclk);
        end
        
        drop_objection("basic_write_test");
    endtask
    
    virtual function string get_type_name();
        return "basic_write_test";
    endfunction
    
endclass : basic_write_test
// Note: registration done in tb_top.sv (initial block not allowed in package context)
