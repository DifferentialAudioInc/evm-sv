//==============================================================================
// Class: example1_cfg
// Description: Test configuration for example1 (AXI Data Transform)
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

class example1_cfg extends evm_object;
    
    //==========================================================================
    // Test parameters
    //==========================================================================
    int unsigned  num_transactions   = 10;     // number of transform operations
    bit           enable_random_data  = 0;     // 1 = randomize DATA_IN
    bit           enable_random_xform = 0;     // 1 = randomize XFORM_SEL
    logic  [1:0]  fixed_xform_sel    = 2'b00; // used when enable_random_xform=0
    int unsigned  timeout_cycles     = 1000;  // poll timeout for STATUS.DONE
    
    // GPIO test value (written to GPIO_OUT register)
    logic  [7:0]  gpio_test_val      = 8'hA5;
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "example1_cfg");
        super.new(name);
    endfunction
    
    virtual function string get_type_name();
        return "example1_cfg";
    endfunction
    
    virtual function string convert2string();
        return $sformatf(
            "cfg: txns=%0d rand_data=%0b rand_xform=%0b xform_sel=%0b gpio=0x%02h",
            num_transactions, enable_random_data, enable_random_xform,
            fixed_xform_sel, gpio_test_val);
    endfunction
    
endclass : example1_cfg
