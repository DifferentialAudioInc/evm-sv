//==============================================================================
// Class: multi_xform_test
// Description: Test all 4 transform modes with known data
//   Runs each of the 4 transforms on 0x1234_5678 and verifies result:
//     0=passthrough: 0x12345678
//     1=invert:      0xEDCBA987
//     2=byte_swap:   0x78563412
//     3=bit_reverse: 0x1E6A2C48
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

class multi_xform_test extends example1_base_test;
    
    function new(string name = "multi_xform_test");
        super.new(name);
        cfg.fixed_xform_sel    = 2'b00;
        cfg.num_transactions   = 4;
        cfg.gpio_test_val      = 8'hF0;
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("multi_xform_test");
        
        begin
            logic [31:0] data_in = 32'h1234_5678;
            logic [31:0] expected;
            logic [31:0] result_rb;
            logic  [1:0] resp;
            bit           done;
            string        xform_names[4] = '{"passthrough", "invert", "byte_swap", "bit_reverse"};
            
            for (int i = 0; i < 4; i++) begin
                log_info($sformatf("--- Transform mode %0d: %s ---", i, xform_names[i]),
                         EVM_LOW);
                
                do_transform(data_in, logic'(i[1:0]), expected);
                poll_done(done);
                
                // Read RESULT back
                env.csr_agent.read(32'h0000_000C, result_rb, resp);
                if (result_rb !== expected) begin
                    log_error($sformatf(
                        "Mode %0d RESULT mismatch: got 0x%08h expected 0x%08h",
                        i, result_rb, expected));
                end else begin
                    log_info($sformatf("Mode %0d: 0x%08h → 0x%08h  OK",
                                       i, data_in, result_rb), EVM_LOW);
                end
                
                // Small gap between transforms
                repeat(10) @(posedge slave_vif.aclk);
            end
            
            // Drain scoreboard (GPIO checked in check_phase after settle)
            repeat(30) @(posedge slave_vif.aclk);
        end
        
        drop_objection("multi_xform_test");
    endtask
    
    virtual function string get_type_name();
        return "multi_xform_test";
    endfunction
    
endclass : multi_xform_test
// Note: registration done in tb_top.sv (initial block not allowed in package context)
