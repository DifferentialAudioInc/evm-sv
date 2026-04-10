//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// File: evm_axi_lite_txn.sv
// Description: AXI4-Lite transaction types for EVM monitor analysis ports
//
//              Provides channel-level and composite transaction classes for the
//              AXI4-Lite monitor. Each monitor publishes transactions at two
//              levels of granularity:
//
//              Channel-level (one per handshake):
//                ap_aw  → evm_axi_lite_aw_txn  (AW channel handshake)
//                ap_w   → evm_axi_lite_w_txn   (W  channel handshake)
//                ap_b   → evm_axi_lite_b_txn   (B  channel handshake)
//                ap_ar  → evm_axi_lite_ar_txn  (AR channel handshake)
//                ap_r   → evm_axi_lite_r_txn   (R  channel handshake)
//
//              Composite (one per complete transaction):
//                ap_write → evm_axi_lite_write_txn  (AW + W + B combined)
//                ap_read  → evm_axi_lite_read_txn   (AR + R combined)
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

//------------------------------------------------------------------------------
// AW Channel Transaction - Write Address handshake
//------------------------------------------------------------------------------
class evm_axi_lite_aw_txn extends evm_object;
    logic [31:0] addr;      // Write address
    logic [2:0]  prot;      // Protection type
    realtime     time_ns;   // Timestamp of handshake
    
    function new(string name = "aw_txn");
        super.new(name);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("AW: addr=0x%08h prot=%0b @%.1fns", addr, prot, time_ns);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_aw_txn";
    endfunction
endclass : evm_axi_lite_aw_txn

//------------------------------------------------------------------------------
// W Channel Transaction - Write Data handshake
//------------------------------------------------------------------------------
class evm_axi_lite_w_txn extends evm_object;
    logic [31:0] data;      // Write data
    logic [3:0]  strb;      // Byte strobes
    realtime     time_ns;   // Timestamp of handshake
    
    function new(string name = "w_txn");
        super.new(name);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("W:  data=0x%08h strb=0x%h @%.1fns", data, strb, time_ns);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_w_txn";
    endfunction
endclass : evm_axi_lite_w_txn

//------------------------------------------------------------------------------
// B Channel Transaction - Write Response handshake
//------------------------------------------------------------------------------
class evm_axi_lite_b_txn extends evm_object;
    logic [1:0]  resp;      // Write response (OKAY/EXOKAY/SLVERR/DECERR)
    realtime     time_ns;   // Timestamp of handshake
    
    function new(string name = "b_txn");
        super.new(name);
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("B:  resp=%s @%.1fns", resp_str(), time_ns);
    endfunction
    
    local function string resp_str();
        case (resp)
            2'b00: return "OKAY";
            2'b01: return "EXOKAY";
            2'b10: return "SLVERR";
            2'b11: return "DECERR";
            default: return "???";
        endcase
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_b_txn";
    endfunction
endclass : evm_axi_lite_b_txn

//------------------------------------------------------------------------------
// AR Channel Transaction - Read Address handshake
//------------------------------------------------------------------------------
class evm_axi_lite_ar_txn extends evm_object;
    logic [31:0] addr;      // Read address
    logic [2:0]  prot;      // Protection type
    realtime     time_ns;   // Timestamp of handshake
    
    function new(string name = "ar_txn");
        super.new(name);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("AR: addr=0x%08h prot=%0b @%.1fns", addr, prot, time_ns);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_ar_txn";
    endfunction
endclass : evm_axi_lite_ar_txn

//------------------------------------------------------------------------------
// R Channel Transaction - Read Data handshake
//------------------------------------------------------------------------------
class evm_axi_lite_r_txn extends evm_object;
    logic [31:0] data;      // Read data
    logic [1:0]  resp;      // Read response
    realtime     time_ns;   // Timestamp of handshake
    
    function new(string name = "r_txn");
        super.new(name);
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("R:  data=0x%08h resp=%0b @%.1fns", data, resp, time_ns);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_r_txn";
    endfunction
endclass : evm_axi_lite_r_txn

//------------------------------------------------------------------------------
// Composite Write Transaction - Complete AW + W + B sequence
// Published on ap_write when AW, W, and B channels all complete
// Use this for:
//   - Scoreboard checking
//   - RAL predictor (connect to predictor.analysis_imp)
//   - Coverage collection
//   - Protocol compliance checking
//------------------------------------------------------------------------------
class evm_axi_lite_write_txn extends evm_object;
    logic [31:0] addr;          // Write address (from AW)
    logic [31:0] data;          // Write data (from W)
    logic [3:0]  strb;          // Byte strobes (from W)
    logic [2:0]  prot;          // Protection (from AW)
    logic [1:0]  resp;          // Response (from B)
    
    realtime     aw_time_ns;    // AW handshake timestamp
    realtime     w_time_ns;     // W  handshake timestamp
    realtime     b_time_ns;     // B  handshake timestamp
    
    function new(string name = "write_txn");
        super.new(name);
    endfunction
    
    // Latency from AW handshake to B response
    function realtime get_write_latency();
        return b_time_ns - aw_time_ns;
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("WRITE: addr=0x%08h data=0x%08h strb=0x%h resp=%s lat=%.1fns",
                        addr, data, strb, resp_str(), get_write_latency());
    endfunction
    
    local function string resp_str();
        case (resp)
            2'b00: return "OKAY";
            2'b01: return "EXOKAY";
            2'b10: return "SLVERR";
            2'b11: return "DECERR";
            default: return "???";
        endcase
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_write_txn";
    endfunction
endclass : evm_axi_lite_write_txn

//------------------------------------------------------------------------------
// Composite Read Transaction - Complete AR + R sequence
// Published on ap_read when AR and R channels both complete
//------------------------------------------------------------------------------
class evm_axi_lite_read_txn extends evm_object;
    logic [31:0] addr;          // Read address (from AR)
    logic [31:0] data;          // Read data (from R)
    logic [2:0]  prot;          // Protection (from AR)
    logic [1:0]  resp;          // Response (from R)
    
    realtime     ar_time_ns;    // AR handshake timestamp
    realtime     r_time_ns;     // R  handshake timestamp
    
    function new(string name = "read_txn");
        super.new(name);
    endfunction
    
    // Latency from AR handshake to R data
    function realtime get_read_latency();
        return r_time_ns - ar_time_ns;
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("READ:  addr=0x%08h data=0x%08h resp=%s lat=%.1fns",
                        addr, data, resp_str(), get_read_latency());
    endfunction
    
    local function string resp_str();
        case (resp)
            2'b00: return "OKAY";
            2'b01: return "EXOKAY";
            2'b10: return "SLVERR";
            2'b11: return "DECERR";
            default: return "???";
        endcase
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_read_txn";
    endfunction
endclass : evm_axi_lite_read_txn
