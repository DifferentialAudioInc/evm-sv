//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// File: evm_axi4_full_txn.sv
// Description: AXI4 Full transaction types for EVM monitor analysis ports
//
//              Channel-level (fire on each AXI handshake):
//                ap_aw  → evm_axi4_aw_txn  (AW channel handshake)
//                ap_w   → evm_axi4_w_txn   (W  beat handshake; one per beat)
//                ap_b   → evm_axi4_b_txn   (B  channel handshake)
//                ap_ar  → evm_axi4_ar_txn  (AR channel handshake)
//                ap_r   → evm_axi4_r_txn   (R  beat handshake; one per beat)
//
//              Composite (fire on complete transaction):
//                ap_write → evm_axi4_write_txn (AW + all W beats + B)
//                ap_read  → evm_axi4_read_txn  (AR + all R beats)
//
//              Note: Data width fixed at 64 bits (matching interface default).
//                    Extend these classes for different bus widths.
//
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

//------------------------------------------------------------------------------
// AW Channel Transaction - Write Address handshake
//------------------------------------------------------------------------------
class evm_axi4_aw_txn extends evm_object;
    logic [7:0]  id;        // Transaction ID (AWID)
    logic [31:0] addr;      // Write address
    logic [7:0]  len;       // Burst length (0 = 1 beat)
    logic [2:0]  size;      // Burst size (bytes per beat = 2^size)
    logic [1:0]  burst;     // Burst type: 00=FIXED 01=INCR 10=WRAP
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    realtime     time_ns;
    
    function new(string name = "aw4_txn");
        super.new(name);
    endfunction
    
    function int get_num_beats();
        return int'(len) + 1;
    endfunction
    
    function string burst_type_str();
        case (burst)
            2'b00: return "FIXED";
            2'b01: return "INCR";
            2'b10: return "WRAP";
            default: return "RSVD";
        endcase
    endfunction
    
    virtual function string convert2string();
        return $sformatf("AW4: id=%0d addr=0x%08h len=%0d(%0d beats) size=%0d burst=%s",
                        id, addr, len, get_num_beats(), size, burst_type_str());
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_aw_txn";
    endfunction
endclass : evm_axi4_aw_txn

//------------------------------------------------------------------------------
// W Channel Transaction - Write Data beat (one per burst beat)
//------------------------------------------------------------------------------
class evm_axi4_w_txn extends evm_object;
    logic [63:0] data;      // Write data (64-bit)
    logic [7:0]  strb;      // Byte strobes (8 bytes for 64-bit)
    logic        last;      // This is the last beat
    int          beat_num;  // Beat number within burst (0-based)
    realtime     time_ns;
    
    function new(string name = "w4_txn");
        super.new(name);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("W4:  beat=%0d data=0x%016h strb=0x%02h last=%0b",
                        beat_num, data, strb, last);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_w_txn";
    endfunction
endclass : evm_axi4_w_txn

//------------------------------------------------------------------------------
// B Channel Transaction - Write Response
//------------------------------------------------------------------------------
class evm_axi4_b_txn extends evm_object;
    logic [7:0]  id;        // Response ID (BID - must match AWID)
    logic [1:0]  resp;      // Response: OKAY/EXOKAY/SLVERR/DECERR
    realtime     time_ns;
    
    function new(string name = "b4_txn");
        super.new(name);
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("B4:  id=%0d resp=%s", id, resp_str());
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
        return "evm_axi4_b_txn";
    endfunction
endclass : evm_axi4_b_txn

//------------------------------------------------------------------------------
// AR Channel Transaction - Read Address handshake
//------------------------------------------------------------------------------
class evm_axi4_ar_txn extends evm_object;
    logic [7:0]  id;
    logic [31:0] addr;
    logic [7:0]  len;
    logic [2:0]  size;
    logic [1:0]  burst;
    logic        lock;
    logic [3:0]  cache;
    logic [2:0]  prot;
    logic [3:0]  qos;
    realtime     time_ns;
    
    function new(string name = "ar4_txn");
        super.new(name);
    endfunction
    
    function int get_num_beats();
        return int'(len) + 1;
    endfunction
    
    function string burst_type_str();
        case (burst)
            2'b00: return "FIXED";
            2'b01: return "INCR";
            2'b10: return "WRAP";
            default: return "RSVD";
        endcase
    endfunction
    
    virtual function string convert2string();
        return $sformatf("AR4: id=%0d addr=0x%08h len=%0d(%0d beats) size=%0d burst=%s",
                        id, addr, len, get_num_beats(), size, burst_type_str());
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_ar_txn";
    endfunction
endclass : evm_axi4_ar_txn

//------------------------------------------------------------------------------
// R Channel Transaction - Read Data beat (one per burst beat)
//------------------------------------------------------------------------------
class evm_axi4_r_txn extends evm_object;
    logic [7:0]  id;        // Read ID (must match ARID)
    logic [63:0] data;      // Read data (64-bit)
    logic [1:0]  resp;      // Response per beat
    logic        last;      // Last beat in burst
    int          beat_num;  // Beat number (0-based)
    realtime     time_ns;
    
    function new(string name = "r4_txn");
        super.new(name);
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    virtual function string convert2string();
        return $sformatf("R4:  id=%0d beat=%0d data=0x%016h resp=%0b last=%0b",
                        id, beat_num, data, resp, last);
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_r_txn";
    endfunction
endclass : evm_axi4_r_txn

//------------------------------------------------------------------------------
// Composite Write Transaction - Complete AW + all W beats + B
// Published on ap_write when the complete burst is captured.
//------------------------------------------------------------------------------
class evm_axi4_write_txn extends evm_object;
    // AW fields
    logic [7:0]  id;
    logic [31:0] addr;
    logic [7:0]  len;        // Number of beats - 1
    logic [2:0]  size;
    logic [1:0]  burst;
    logic [2:0]  prot;
    
    // W fields - one entry per beat
    logic [63:0] data[$];    // Data for each beat
    logic [7:0]  strb[$];    // Strobe for each beat
    
    // B fields
    logic [1:0]  resp;       // Final write response
    
    // Timestamps
    realtime     aw_time_ns;
    realtime     last_w_time_ns;
    realtime     b_time_ns;
    
    function new(string name = "write4_txn");
        super.new(name);
    endfunction
    
    function int get_num_beats();
        return int'(len) + 1;
    endfunction
    
    function bit is_okay();
        return (resp == 2'b00);
    endfunction
    
    // Latency from AW to B
    function realtime get_write_latency();
        return b_time_ns - aw_time_ns;
    endfunction
    
    // Total data transferred in bytes
    function int get_byte_count();
        return get_num_beats() * (1 << int'(size));
    endfunction
    
    virtual function string convert2string();
        return $sformatf(
            "WRITE4: id=%0d addr=0x%08h len=%0d(%0d beats) size=%0d resp=%0b bytes=%0d lat=%.1fns",
            id, addr, len, get_num_beats(), size, resp, get_byte_count(), get_write_latency());
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_write_txn";
    endfunction
endclass : evm_axi4_write_txn

//------------------------------------------------------------------------------
// Composite Read Transaction - Complete AR + all R beats
// Published on ap_read when RLAST is seen.
//------------------------------------------------------------------------------
class evm_axi4_read_txn extends evm_object;
    // AR fields
    logic [7:0]  id;
    logic [31:0] addr;
    logic [7:0]  len;        // Number of beats - 1
    logic [2:0]  size;
    logic [1:0]  burst;
    logic [2:0]  prot;
    
    // R fields - one entry per beat
    logic [63:0] data[$];    // Data for each beat
    logic [1:0]  resp[$];    // Response for each beat
    
    // Timestamps
    realtime     ar_time_ns;
    realtime     last_r_time_ns;
    
    function new(string name = "read4_txn");
        super.new(name);
    endfunction
    
    function int get_num_beats();
        return int'(len) + 1;
    endfunction
    
    function bit all_okay();
        foreach (resp[i]) begin
            if (resp[i] != 2'b00) return 0;
        end
        return 1;
    endfunction
    
    // Latency from AR to last R
    function realtime get_read_latency();
        return last_r_time_ns - ar_time_ns;
    endfunction
    
    // Total data transferred in bytes
    function int get_byte_count();
        return get_num_beats() * (1 << int'(size));
    endfunction
    
    virtual function string convert2string();
        return $sformatf(
            "READ4:  id=%0d addr=0x%08h len=%0d(%0d beats) size=%0d ok=%0b bytes=%0d lat=%.1fns",
            id, addr, len, get_num_beats(), size, all_okay(), get_byte_count(), get_read_latency());
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi4_read_txn";
    endfunction
endclass : evm_axi4_read_txn
