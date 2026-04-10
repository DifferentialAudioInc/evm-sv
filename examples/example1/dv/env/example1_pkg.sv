//==============================================================================
// Package: example1_pkg
// Description: Testbench package for example1 (AXI Data Transform)
//   Located at: dv/env/example1_pkg.sv
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

package example1_pkg;
    
    import evm_pkg::*;
    import evm_vkit_pkg::*;
    
    // Generated RAL model (from CSR generator)
    `include "../../csr/generated/axi_data_xform/axi_data_xform_reg_model.sv"
    
    // DV classes — all in dv/env/ (same directory)
    `include "example1_cfg.sv"
    `include "example1_scoreboard.sv"
    `include "example1_env.sv"
    `include "example1_base_test.sv"
    
    // Tests — in dv/tests/
    `include "../tests/basic_write_test.sv"
    `include "../tests/multi_xform_test.sv"
    `include "../tests/random_test.sv"
    
endpackage : example1_pkg
