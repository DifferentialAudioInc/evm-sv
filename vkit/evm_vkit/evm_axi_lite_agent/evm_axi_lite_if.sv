//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_axi_lite_if
// Description: AXI4-Lite Master Interface (32-bit)
//              For driving CSR register accesses
// Author: Eric Dyer
// Date: 2026-03-05
//==============================================================================

interface evm_axi_lite_if(input logic aclk, input logic aresetn);
    
    //==========================================================================
    // AXI4-Lite Master Signals (32-bit)
    //==========================================================================
    
    // Write Address Channel
    logic [31:0] awaddr;
    logic [2:0]  awprot;    // Protection type (typically 3'b000)
    logic        awvalid;
    logic        awready;
    
    // Write Data Channel
    logic [31:0] wdata;
    logic [3:0]  wstrb;     // Byte lane strobes
    logic        wvalid;
    logic        wready;
    
    // Write Response Channel
    logic [1:0]  bresp;     // 00=OKAY, 01=EXOKAY, 10=SLVERR, 11=DECERR
    logic        bvalid;
    logic        bready;
    
    // Read Address Channel
    logic [31:0] araddr;
    logic [2:0]  arprot;    // Protection type
    logic        arvalid;
    logic        arready;
    
    // Read Data Channel
    logic [31:0] rdata;
    logic [1:0]  rresp;     // Response
    logic        rvalid;
    logic        rready;
    
    //==========================================================================
    // Modports
    //==========================================================================
    
    // Master modport (for driver)
    modport master (
        input  aclk, aresetn,
        output awaddr, awprot, awvalid,
        input  awready,
        output wdata, wstrb, wvalid,
        input  wready,
        input  bresp, bvalid,
        output bready,
        output araddr, arprot, arvalid,
        input  arready,
        input  rdata, rresp, rvalid,
        output rready
    );
    
    // Slave modport (for monitor/slave)
    modport slave (
        input  aclk, aresetn,
        input  awaddr, awprot, awvalid,
        output awready,
        input  wdata, wstrb, wvalid,
        output wready,
        output bresp, bvalid,
        input  bready,
        input  araddr, arprot, arvalid,
        output arready,
        output rdata, rresp, rvalid,
        input  rready
    );
    
    // Monitor modport (for observation)
    modport monitor (
        input aclk, aresetn,
        input awaddr, awprot, awvalid, awready,
        input wdata, wstrb, wvalid, wready,
        input bresp, bvalid, bready,
        input araddr, arprot, arvalid, arready,
        input rdata, rresp, rvalid, rready
    );
    
    //==========================================================================
    // Initial Values (Master drives)
    //==========================================================================
    initial begin
        awaddr  = '0;
        awprot  = 3'b000;
        awvalid = 1'b0;
        wdata   = '0;
        wstrb   = 4'b0000;
        wvalid  = 1'b0;
        bready  = 1'b1;     // Always ready for write response
        araddr  = '0;
        arprot  = 3'b000;
        arvalid = 1'b0;
        rready  = 1'b1;     // Always ready for read data
    end
    
    //==========================================================================
    // Protocol Checkers (Assertions for debug)
    //==========================================================================
    
    // Check for stable AWVALID until AWREADY
    property p_awvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        awvalid && !awready |=> awvalid;
    endproperty
    assert property (p_awvalid_stable) else 
        $error("[AXI_LITE_IF] AWVALID deasserted before AWREADY");
    
    // Check for stable WVALID until WREADY
    property p_wvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        wvalid && !wready |=> wvalid;
    endproperty
    assert property (p_wvalid_stable) else 
        $error("[AXI_LITE_IF] WVALID deasserted before WREADY");
    
    // Check for stable ARVALID until ARREADY
    property p_arvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        arvalid && !arready |=> arvalid;
    endproperty
    assert property (p_arvalid_stable) else 
        $error("[AXI_LITE_IF] ARVALID deasserted before ARREADY");
    
    // Check for aligned addresses (word-aligned)
    property p_awaddr_aligned;
        @(posedge aclk) disable iff (!aresetn)
        awvalid |-> (awaddr[1:0] == 2'b00);
    endproperty
    assert property (p_awaddr_aligned) else 
        $error("[AXI_LITE_IF] AWADDR not word-aligned: 0x%08h", awaddr);
    
    property p_araddr_aligned;
        @(posedge aclk) disable iff (!aresetn)
        arvalid |-> (araddr[1:0] == 2'b00);
    endproperty
    assert property (p_araddr_aligned) else 
        $error("[AXI_LITE_IF] ARADDR not word-aligned: 0x%08h", araddr);
    
endinterface : evm_axi_lite_if
