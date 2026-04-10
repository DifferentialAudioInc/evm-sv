//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi4_full_cfg
// Description: Configuration object for AXI4 Full agent
// Author: Eric Dyer
// Date: 2026-04-09
//==============================================================================

class evm_axi4_full_cfg extends evm_object;
    
    //==========================================================================
    // Bus Parameters - must match interface parameters
    //==========================================================================
    int data_width  = 64;   // Data bus width in bits
    int addr_width  = 32;   // Address width in bits
    int id_width    = 8;    // ID field width in bits
    
    //==========================================================================
    // Agent Configuration
    //==========================================================================
    bit is_active   = 1;    // 1=active (has driver), 0=passive (monitor only)
    
    //==========================================================================
    // Driver Configuration
    //==========================================================================
    
    // Default burst parameters
    logic [1:0]  default_burst = 2'b01;  // INCR burst type
    logic [2:0]  default_prot  = 3'b000; // Non-secure, unprivileged, data
    logic [3:0]  default_cache = 4'b0010;// Normal non-cacheable
    logic [3:0]  default_qos   = 4'b0000;// Default QoS
    
    // Delays (in cycles)
    int aw_delay_cycles = 0;   // AW channel assertion delay
    int ar_delay_cycles = 0;   // AR channel assertion delay
    int w_beat_delay    = 0;   // Delay between W beats (0=back-to-back)
    
    // Backpressure handling
    int bready_delay    = 0;   // Cycles before asserting bready
    int rready_delay    = 0;   // Cycles before asserting rready
    bit always_bready   = 1;   // Keep bready asserted (no backpressure)
    bit always_rready   = 1;   // Keep rready asserted (no backpressure)
    
    // Outstanding transactions
    int max_outstanding_writes = 4;   // Max in-flight write transactions
    int max_outstanding_reads  = 4;   // Max in-flight read transactions
    
    //==========================================================================
    // Monitor Configuration
    //==========================================================================
    bit check_burst_alignment = 1;  // Check burst alignment protocol rule
    bit track_out_of_order    = 0;  // Track out-of-order completions (TODO)
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi4_full_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Get default AWSIZE / ARSIZE for current data width
    // Returns the AXI size encoding for the full data width
    //==========================================================================
    function logic [2:0] get_default_size();
        case (data_width)
            8:   return 3'b000;  // 1 byte
            16:  return 3'b001;  // 2 bytes
            32:  return 3'b010;  // 4 bytes
            64:  return 3'b011;  // 8 bytes
            128: return 3'b100;  // 16 bytes
            256: return 3'b101;  // 32 bytes
            512: return 3'b110;  // 64 bytes
            default: return 3'b011; // Default: 8 bytes (64-bit)
        endcase
    endfunction
    
    //==========================================================================
    // Type identification
    //==========================================================================
    virtual function string get_type_name();
        return "evm_axi4_full_cfg";
    endfunction
    
endclass : evm_axi4_full_cfg
