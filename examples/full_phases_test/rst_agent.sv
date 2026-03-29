//==============================================================================
// EVM Full Phases Example - Reset Agent
//==============================================================================

//==============================================================================
// Reset Configuration
//==============================================================================
class rst_cfg extends evm_object;
    int reset_cycles = 10;   // Reset assertion duration in cycles
    bit active_low = 1;      // Active low reset
    
    function new(string name = "rst_cfg");
        super.new(name);
    endfunction
endclass

//==============================================================================
// Reset Driver
//==============================================================================
class rst_driver extends evm_driver#(virtual rst_if, int, int);
    
    rst_cfg cfg;
    
    function new(string name = "rst_driver", evm_component parent = null);
        super.new(name, parent);
        cfg = new("cfg");
    endfunction
    
    virtual task reset_phase();
        super.reset_phase();
        
        log_info("Applying reset", EVM_LOW);
        
        // Assert reset
        vif.drv_cb.reset_n <= (cfg.active_low ? 0 : 1);
        
        // Hold for configured cycles
        repeat(cfg.reset_cycles) @(vif.drv_cb);
        
        // Deassert reset
        vif.drv_cb.reset_n <= (cfg.active_low ? 1 : 0);
        
        log_info("Reset released", EVM_LOW);
        
        // Wait one more cycle
        @(vif.drv_cb);
    endtask
    
    virtual function string get_type_name();
        return "rst_driver";
    endfunction
endclass

//==============================================================================
// Reset Monitor
//==============================================================================
class rst_monitor extends evm_monitor#(virtual rst_if, int);
    
    rst_cfg cfg;
    bit reset_active = 0;
    
    function new(string name = "rst_monitor", evm_component parent = null);
        super.new(name, parent);
        cfg = new("cfg");
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        
        forever begin
            @(vif.mon_cb);
            
            if (cfg.active_low) begin
                if (vif.reset_n == 0 && !reset_active) begin
                    reset_active = 1;
                    log_info("Reset asserted", EVM_MEDIUM);
                end else if (vif.reset_n == 1 && reset_active) begin
                    reset_active = 0;
                    log_info("Reset deasserted", EVM_MEDIUM);
                end
            end else begin
                if (vif.reset_n == 1 && !reset_active) begin
                    reset_active = 1;
                    log_info("Reset asserted", EVM_MEDIUM);
                end else if (vif.reset_n == 0 && reset_active) begin
                    reset_active = 0;
                    log_info("Reset deasserted", EVM_MEDIUM);
                end
            end
        end
    endtask
    
    virtual function string get_type_name();
        return "rst_monitor";
    endfunction
endclass

//==============================================================================
// Reset Agent
//==============================================================================
class rst_agent extends evm_component;
    
    rst_cfg cfg;
    rst_driver driver;
    rst_monitor monitor;
    virtual rst_if vif;
    bit is_active = 1;
    
    function new(string name = "rst_agent", evm_component parent = null);
        super.new(name, parent);
        cfg = new("cfg");
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        if (is_active) begin
            driver = new("driver", this);
            driver.cfg = cfg;
        end
        
        monitor = new("monitor", this);
        monitor.cfg = cfg;
        
        log_info("Reset agent built", EVM_MEDIUM);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        
        if (vif != null) begin
            if (driver != null) driver.set_vif(vif);
            if (monitor != null) monitor.set_vif(vif);
            log_info("Reset agent connected to VIF", EVM_MEDIUM);
        end
    endfunction
    
    function void set_vif(virtual rst_if vif_handle);
        this.vif = vif_handle;
        if (driver != null) driver.set_vif(vif_handle);
        if (monitor != null) monitor.set_vif(vif_handle);
    endfunction
    
    virtual function string get_type_name();
        return "rst_agent";
    endfunction
endclass
