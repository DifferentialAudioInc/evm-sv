//==============================================================================
// Interface: gpio_if
// Description: Simple GPIO output observation interface
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================
interface gpio_if;
    logic [7:0] gpio;  // observed from DUT gpio_out[7:0] pins
endinterface : gpio_if
