//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================

//==============================================================================
// Class: evm_axi_lite_cfg
// Description: Configuration class for AXI4-Lite agent
//              Supports master, slave, and passive modes with timing control
// Author: Eric Dyer
// Date: 2026-03-07
//==============================================================================

typedef enum {
    EVM_AXI_ACTIVE_MASTER,   // Agent drives as AXI master
    EVM_AXI_ACTIVE_SLAVE,    // Agent drives as AXI slave
    EVM_AXI_PASSIVE          // Agent monitors only
} evm_axi_mode_e;

typedef enum {
    EVM_AXI_RESP_OKAY   = 2'b00,
    EVM_AXI_RESP_EXOKAY = 2'b01,
    EVM_AXI_RESP_SLVERR = 2'b10,
    EVM_AXI_RESP_DECERR = 2'b11
} evm_axi_resp_e;

class evm_axi_lite_cfg extends evm_object;
    
    //==========================================================================
    // Configuration Parameters
    //==========================================================================
    
    // Operating mode
    evm_axi_mode_e mode = EVM_AXI_ACTIVE_MASTER;
    
    // Enable sequencer for sequence-based stimulus (default: off for backward compat)
    bit use_sequencer = 0;
    
    //==========================================================================
    // Master Configuration (when mode = ACTIVE_MASTER)
    //==========================================================================
    
    // Delay between transactions (cycles)
    rand int master_delay_min = 0;
    rand int master_delay_max = 2;
    
    // Back-to-back transaction probability (0-100)
    rand int back_to_back_pct = 80;
    
    // Per-channel delay cycles (used by driver)
    int aw_delay_cycles = 0;   // AW channel delay
    int w_delay_cycles  = 0;   // W  channel delay
    int ar_delay_cycles = 0;   // AR channel delay
    bit enable_delays   = 0;   // Master: enable channel delays
    
    // Ready delay ranges (slave ready signals when in master mode)
    rand int awready_delay_min = 0;
    rand int awready_delay_max = 1;
    rand int arready_delay_min = 0;
    rand int arready_delay_max = 1;
    rand int wready_delay_min = 0;
    rand int wready_delay_max = 1;
    
    // Valid delay ranges (slave valid signals when in master mode)
    rand int rvalid_delay_min = 1;
    rand int rvalid_delay_max = 3;
    rand int bvalid_delay_min = 1;
    rand int bvalid_delay_max = 3;
    
    //==========================================================================
    // Slave Configuration (when mode = ACTIVE_SLAVE)
    //==========================================================================
    
    // Ready signal assertion delays for slave
    rand int slave_awready_delay_min = 0;
    rand int slave_awready_delay_max = 2;
    rand int slave_arready_delay_min = 0;
    rand int slave_arready_delay_max = 2;
    rand int slave_wready_delay_min = 0;
    rand int slave_wready_delay_max = 2;
    
    // Response delays for slave
    rand int slave_rvalid_delay_min = 1;
    rand int slave_rvalid_delay_max = 5;
    rand int slave_bvalid_delay_min = 1;
    rand int slave_bvalid_delay_max = 5;
    
    // Default slave response
    evm_axi_resp_e default_resp = EVM_AXI_RESP_OKAY;
    
    //==========================================================================
    // Constraints
    //==========================================================================
    constraint reasonable_delays {
        master_delay_min >= 0;
        master_delay_max >= master_delay_min;
        master_delay_max <= 10;
        
        awready_delay_min >= 0;
        awready_delay_max >= awready_delay_min;
        awready_delay_max <= 5;
        
        arready_delay_min >= 0;
        arready_delay_max >= arready_delay_min;
        arready_delay_max <= 5;
        
        wready_delay_min >= 0;
        wready_delay_max >= wready_delay_min;
        wready_delay_max <= 5;
        
        rvalid_delay_min >= 1;
        rvalid_delay_max >= rvalid_delay_min;
        rvalid_delay_max <= 10;
        
        bvalid_delay_min >= 1;
        bvalid_delay_max >= bvalid_delay_min;
        bvalid_delay_max <= 10;
        
        back_to_back_pct >= 0;
        back_to_back_pct <= 100;
        
        slave_awready_delay_min >= 0;
        slave_awready_delay_max >= slave_awready_delay_min;
        slave_awready_delay_max <= 5;
        
        slave_arready_delay_min >= 0;
        slave_arready_delay_max >= slave_arready_delay_min;
        slave_arready_delay_max <= 5;
        
        slave_wready_delay_min >= 0;
        slave_wready_delay_max >= slave_wready_delay_min;
        slave_wready_delay_max <= 5;
        
        slave_rvalid_delay_min >= 1;
        slave_rvalid_delay_max >= slave_rvalid_delay_min;
        slave_rvalid_delay_max <= 10;
        
        slave_bvalid_delay_min >= 1;
        slave_bvalid_delay_max >= slave_bvalid_delay_min;
        slave_bvalid_delay_max <= 10;
    }
    
    //==========================================================================
    // Constructor
    //==========================================================================
    function new(string name = "evm_axi_lite_cfg");
        super.new(name);
    endfunction
    
    //==========================================================================
    // Helper Methods
    //==========================================================================
    
    // Check if operating as master
    function bit is_master();
        return (mode == EVM_AXI_ACTIVE_MASTER);
    endfunction
    
    // Check if operating as slave
    function bit is_slave();
        return (mode == EVM_AXI_ACTIVE_SLAVE);
    endfunction
    
    // Check if passive (monitor only)
    function bit is_passive();
        return (mode == EVM_AXI_PASSIVE);
    endfunction
    
    // Get random delay between transactions
    function int get_inter_transaction_delay();
        if ($urandom_range(100) < back_to_back_pct) begin
            return 0;  // Back-to-back
        end else begin
            return $urandom_range(master_delay_max, master_delay_min);
        end
    endfunction
    
    // Get random ready delays
    function int get_awready_delay();
        return $urandom_range(awready_delay_max, awready_delay_min);
    endfunction
    
    function int get_arready_delay();
        return $urandom_range(arready_delay_max, arready_delay_min);
    endfunction
    
    function int get_wready_delay();
        return $urandom_range(wready_delay_max, wready_delay_min);
    endfunction
    
    function int get_rvalid_delay();
        return $urandom_range(rvalid_delay_max, rvalid_delay_min);
    endfunction
    
    function int get_bvalid_delay();
        return $urandom_range(bvalid_delay_max, bvalid_delay_min);
    endfunction
    
    // Get random slave delays
    function int get_slave_awready_delay();
        return $urandom_range(slave_awready_delay_max, slave_awready_delay_min);
    endfunction
    
    function int get_slave_arready_delay();
        return $urandom_range(slave_arready_delay_max, slave_arready_delay_min);
    endfunction
    
    function int get_slave_wready_delay();
        return $urandom_range(slave_wready_delay_max, slave_wready_delay_min);
    endfunction
    
    function int get_slave_rvalid_delay();
        return $urandom_range(slave_rvalid_delay_max, slave_rvalid_delay_min);
    endfunction
    
    function int get_slave_bvalid_delay();
        return $urandom_range(slave_bvalid_delay_max, slave_bvalid_delay_min);
    endfunction
    
    //==========================================================================
    // String Conversion
    //==========================================================================
    virtual function string convert2string();
        string s;
        s = $sformatf("AXI-Lite Config: mode=%s", mode.name());
        if (is_master()) begin
            s = {s, $sformatf(", delay=[%0d:%0d], b2b=%0d%%", 
                             master_delay_min, master_delay_max, back_to_back_pct)};
        end else if (is_slave()) begin
            s = {s, $sformatf(", resp=%s", default_resp.name())};
        end
        return s;
    endfunction
    
    virtual function string get_type_name();
        return "evm_axi_lite_cfg";
    endfunction
    
endclass : evm_axi_lite_cfg
