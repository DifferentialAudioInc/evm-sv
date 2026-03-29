//==============================================================================
// EVM Full Phases Example - Clock Agent
//==============================================================================

//==============================================================================
// Clock Configuration
//==============================================================================
class clk_cfg extends evm_object;
    real freq_mhz = 100.0;  // Default 100MHz
    bit auto_start = 1;     // Start clock automatically
    
    function new(string name = "clk_cfg");
        super.new(name);
    endfunction
endclass

//==============================================================================
// Clock Monitor
//==============================================================================
class clk_monitor extends evm_monitor#(virtual clk_if, int);
    
    clk_cfg cfg;
    real measured_freq_mhz;
    real measured_period_ns;
    
    function new(string name = "clk_monitor", evm_component parent = null);
        super.new(name, parent);
        cfg = new("cfg");
    endfunction
    
    virtual task main_phase();
        time last_edge, current_edge;
        real period_ns;
        
        super.main_phase();
        
        // Wait for first edge
        @(posedge vif.clk);
        last_edge = $time;
        
        // Measure clock frequency
        forever begin
            @(posedge vif.clk);
            current_edge = $time;
            
            period_ns = (current_edge - last_edge) / 1ns;
            measured_period_ns = period_ns;
            measured_freq_mhz = 1000.0 / period_ns;
            
            log_info($sformatf("Clock period: %.2f ns (%.1f MHz)", 
                              period_ns, measured_freq_mhz), EVM_DEBUG);
            
            last_edge = current_edge;
        end
    endtask
    
    virtual function string get_type_name();
        return "clk_monitor";
    endfunction
endclass

//==============================================================================
// Clock Agent
//==============================================================================
class clk_agent extends evm_component;
    
    clk_cfg cfg;
    clk_monitor monitor;
    virtual clk_if vif;
    
    function new(string name = "clk_agent", evm_component parent = null);
        super.new(name, parent);
        cfg = new("cfg");
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        monitor = new("monitor", this);
        monitor.cfg = cfg;
        
        log_info("Clock agent built", EVM_MEDIUM);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        
        if (vif != null) begin
            monitor.set_vif(vif);
            log_info("Clock monitor connected to VIF", EVM_MEDIUM);
        end
    endfunction
    
    function void set_vif(virtual clk_if vif_handle);
        this.vif = vif_handle;
        if (monitor != null) begin
            monitor.set_vif(vif_handle);
        end
    endfunction
    
    virtual function string get_type_name();
        return "clk_agent";
    endfunction
endclass
