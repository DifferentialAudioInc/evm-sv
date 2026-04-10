//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Interface: evm_axi4_full_if
// Description: AXI4 Full interface with burst support
//              Parameterized for data width, address width, and ID width.
//
//              Default parameters match typical ASIC DMA / NIC use case:
//                DATA_WIDTH = 64   (64-bit data bus)
//                ADDR_WIDTH = 32   (32-bit address)
//                ID_WIDTH   = 8    (8-bit transaction IDs)
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

interface evm_axi4_full_if #(
    parameter int DATA_WIDTH = 64,
    parameter int ADDR_WIDTH = 32,
    parameter int ID_WIDTH   = 8
)(
    input logic aclk,
    input logic aresetn
);

    // Derived parameters
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    //==========================================================================
    // Write Address Channel (AW)
    //==========================================================================
    logic [ID_WIDTH-1:0]   awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [7:0]            awlen;      // Burst length (0=1 beat, 255=256 beats)
    logic [2:0]            awsize;     // Burst size (2^n bytes per beat)
    logic [1:0]            awburst;    // Burst type: 00=FIXED 01=INCR 10=WRAP
    logic                  awlock;     // Lock type
    logic [3:0]            awcache;    // Memory attributes
    logic [2:0]            awprot;     // Protection type
    logic [3:0]            awqos;      // Quality of service
    logic                  awvalid;
    logic                  awready;
    
    //==========================================================================
    // Write Data Channel (W)
    //==========================================================================
    logic [DATA_WIDTH-1:0] wdata;
    logic [STRB_WIDTH-1:0] wstrb;
    logic                  wlast;      // Last beat in burst
    logic                  wvalid;
    logic                  wready;
    
    //==========================================================================
    // Write Response Channel (B)
    //==========================================================================
    logic [ID_WIDTH-1:0]   bid;
    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;
    
    //==========================================================================
    // Read Address Channel (AR)
    //==========================================================================
    logic [ID_WIDTH-1:0]   arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0]            arlen;
    logic [2:0]            arsize;
    logic [1:0]            arburst;
    logic                  arlock;
    logic [3:0]            arcache;
    logic [2:0]            arprot;
    logic [3:0]            arqos;
    logic                  arvalid;
    logic                  arready;
    
    //==========================================================================
    // Read Data Channel (R)
    //==========================================================================
    logic [ID_WIDTH-1:0]   rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rlast;      // Last beat in burst
    logic                  rvalid;
    logic                  rready;
    
    //==========================================================================
    // Modports
    //==========================================================================
    
    // Master modport (for driver - initiates transactions)
    modport master (
        input  aclk, aresetn,
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid,
        input  awready,
        output wdata, wstrb, wlast, wvalid,
        input  wready,
        input  bid, bresp, bvalid,
        output bready,
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid,
        input  arready,
        input  rid, rdata, rresp, rlast, rvalid,
        output rready
    );
    
    // Slave modport (for slave/responder)
    modport slave (
        input  aclk, aresetn,
        input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awvalid,
        output awready,
        input  wdata, wstrb, wlast, wvalid,
        output wready,
        output bid, bresp, bvalid,
        input  bready,
        input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arvalid,
        output arready,
        output rid, rdata, rresp, rlast, rvalid,
        input  rready
    );
    
    // Monitor modport (for passive monitoring - all inputs)
    modport monitor (
        input aclk, aresetn,
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos,
        input awvalid, awready,
        input wdata, wstrb, wlast, wvalid, wready,
        input bid, bresp, bvalid, bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos,
        input arvalid, arready,
        input rid, rdata, rresp, rlast, rvalid, rready
    );
    
    //==========================================================================
    // Initial Values (Master drives these to idle)
    //==========================================================================
    initial begin
        awid     = '0;
        awaddr   = '0;
        awlen    = '0;
        awsize   = '0;
        awburst  = 2'b01;  // INCR
        awlock   = 1'b0;
        awcache  = 4'b0000;
        awprot   = 3'b000;
        awqos    = 4'b0000;
        awvalid  = 1'b0;
        wdata    = '0;
        wstrb    = '0;
        wlast    = 1'b0;
        wvalid   = 1'b0;
        bready   = 1'b1;   // Always ready for write response
        arid     = '0;
        araddr   = '0;
        arlen    = '0;
        arsize   = '0;
        arburst  = 2'b01;  // INCR
        arlock   = 1'b0;
        arcache  = 4'b0000;
        arprot   = 3'b000;
        arqos    = 4'b0000;
        arvalid  = 1'b0;
        rready   = 1'b1;   // Always ready for read data
    end
    
    //==========================================================================
    // Protocol Assertions
    //==========================================================================
    
    // AWVALID must remain stable until AWREADY
    property p_awvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        awvalid && !awready |=> awvalid;
    endproperty
    assert property (p_awvalid_stable) else
        $error("[AXI4_IF] AWVALID deasserted before AWREADY");
    
    // WVALID must remain stable until WREADY
    property p_wvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        wvalid && !wready |=> wvalid;
    endproperty
    assert property (p_wvalid_stable) else
        $error("[AXI4_IF] WVALID deasserted before WREADY");
    
    // ARVALID must remain stable until ARREADY
    property p_arvalid_stable;
        @(posedge aclk) disable iff (!aresetn)
        arvalid && !arready |=> arvalid;
    endproperty
    assert property (p_arvalid_stable) else
        $error("[AXI4_IF] ARVALID deasserted before ARREADY");
    
    // WLAST must assert on the last beat of a write burst
    // (Checked by monitor - complex to do as a simple property)
    
endinterface : evm_axi4_full_if
