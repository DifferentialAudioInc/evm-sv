//==============================================================================
// Class: random_test
// Description: Random data + random transform mode test
//   Runs cfg.num_transactions (default 20) iterations with:
//     - Random 32-bit DATA_IN
//     - Random XFORM_SEL (0-3)
//   Scoreboard verifies each result.
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

class random_test extends example1_base_test;
    
    function new(string name = "random_test");
        super.new(name);
        cfg.num_transactions   = 20;
        cfg.enable_random_data  = 1;
        cfg.enable_random_xform = 1;
        cfg.gpio_test_val      = 8'h5A;
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("random_test");
        
        begin
            logic [31:0] data_in;
            logic  [1:0] xform_sel;
            logic [31:0] expected;
            bit           done;
            
            for (int i = 0; i < cfg.num_transactions; i++) begin
                // Randomize inputs
                data_in   = $urandom();
                xform_sel = $urandom_range(0, 3);
                
                log_info($sformatf("[%0d/%0d] data=0x%08h  xform=%0b",
                                   i+1, cfg.num_transactions, data_in, xform_sel),
                         EVM_MEDIUM);
                
                do_transform(data_in, xform_sel, expected);
                poll_done(done);
                
                // Small gap between iterations (allow DUT master write to complete)
                repeat(15) @(posedge slave_vif.aclk);
            end
            
            // Extra drain time for scoreboard (GPIO checked in check_phase)
            repeat(50) @(posedge slave_vif.aclk);
        end
        
        drop_objection("random_test");
    endtask
    
    virtual function string get_type_name();
        return "random_test";
    endfunction
    
endclass : random_test
`EVM_REGISTER_TEST(random_test)
