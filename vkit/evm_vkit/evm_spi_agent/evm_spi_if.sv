//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_spi_if.sv
// Description: SPI bus interface.
//              Supports up to 8 devices via cs_n[7:0].
//              Fixed width (not parameterized) for Vivado xvlog compatibility.
//              cfg.num_cs controls how many CS lines are actually active.
//
//   Naming: "initiator" = SPI master (drives SCLK/MOSI/CS_N)
//           "target"    = SPI peripheral (drives MISO; responds to initiator)
//           — "slave" is not used in this agent —
//
// Connections:
//   In tb_top:  evm_spi_if spi_if(sys_clk, sys_rst_n);
//   DUT (initiator): connect DUT.sclk → spi_if.sclk, etc.
//   EVM target agent: agent.set_vif(spi_if) — drives spi_if.miso
//
// Signal ownership:
//   sclk:   driven by SPI initiator (DUT or evm_spi_initiator_driver)
//   mosi:   driven by SPI initiator (DUT or evm_spi_initiator_driver)
//   miso:   driven by SPI target    (evm_spi_target_driver)
//   cs_n:   driven by SPI initiator (DUT or evm_spi_initiator_driver)
//==============================================================================

interface evm_spi_if (
    input logic sys_clk,    // system clock (for synchronous resets only)
    input logic sys_rst_n   // system reset, active low
);
    //--------------------------------------------------------------------------
    // SPI bus signals
    //--------------------------------------------------------------------------
    logic        sclk;      // SPI clock — driven by initiator
    logic        mosi;      // Master Out Target In — initiator → target
    logic        miso;      // Master In Target Out — target → initiator
    logic [7:0]  cs_n;      // Chip selects, active low (bit N = device N)
    
    //--------------------------------------------------------------------------
    // Convenience: return 1 if any CS is asserted
    //--------------------------------------------------------------------------
    function automatic bit any_cs_active();
        return (cs_n != 8'hFF);
    endfunction
    
    //--------------------------------------------------------------------------
    // Return index of first asserted CS_N, or -1 if none active
    //--------------------------------------------------------------------------
    function automatic int active_cs();
        int i;
        for (i = 0; i < 8; i++) begin
            if (cs_n[i] == 1'b0) return i;
        end
        return -1;
    endfunction

endinterface : evm_spi_if
