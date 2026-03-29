//==============================================================================
// EVM Full Phases Example - Clock and Reset Interfaces
//==============================================================================

//==============================================================================
// Clock Interface
//==============================================================================
interface clk_if;
    logic clk;
    
    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
    endclocking
    
    modport monitor (clocking mon_cb, input clk);
    
endinterface

//==============================================================================
// Reset Interface  
//==============================================================================
interface rst_if(input logic clk);
    logic reset_n;
    
    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        output reset_n;
    endclocking
    
    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        input reset_n;
    endclocking
    
    modport driver  (clocking drv_cb);
    modport monitor (clocking mon_cb, input reset_n);
    
endinterface

//==============================================================================
// DUT Interface
//==============================================================================
interface dut_if(input logic clk);
    logic reset_n;
    logic [7:0] data_in;
    logic data_valid;
    logic [7:0] data_out;
    logic data_ready;
    
    // Clocking blocks
    clocking drv_cb @(posedge clk);
        input reset_n;
        output data_in, data_valid;
        input data_ready;
    endclocking
    
    clocking mon_cb @(posedge clk);
        input reset_n, data_in, data_valid, data_out, data_ready;
    endclocking
    
    modport driver  (clocking drv_cb);
    modport monitor (clocking mon_cb);
    
endinterface
