//==============================================================================
// Class: example1_env
// Description: Verification environment for example1 (AXI Data Transform)
// Author: Eric Dyer (Differential Audio Inc.)
//==============================================================================

class example1_env extends evm_env;
    
    evm_axi_lite_master_agent       csr_agent;
    evm_axi_lite_master_agent       master_mon;
    example1_scoreboard             scoreboard;
    axi_data_xform_reg_model        ral;
    evm_reg_map                     reg_map;
    evm_axi_lite_write_predictor    predictor;
    
    example1_cfg  cfg;
    
    virtual evm_axi_lite_if slave_vif;
    virtual evm_axi_lite_if master_vif;
    
    function new(string name = "example1_env", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        begin
            evm_axi_lite_cfg axi_cfg = new("csr_cfg");
            axi_cfg.mode = EVM_AXI_ACTIVE_MASTER;
            csr_agent = new("csr_agent", this);
            csr_agent.cfg = axi_cfg;
        end
        
        begin
            evm_axi_lite_cfg axi_cfg = new("master_cfg");
            axi_cfg.mode = EVM_AXI_PASSIVE;
            master_mon = new("master_mon", this);
            master_mon.cfg = axi_cfg;
        end
        
        scoreboard = new("scoreboard", this);
        ral        = new("ral");
        reg_map    = new("reg_map", 64'h0000_0000);
        predictor  = new("predictor", this);
        
        reg_map.add_reg_block("xform", ral.reg_block, 64'h0000_0000);
        
        log_info($sformatf("Environment built: %s", cfg.convert2string()), EVM_LOW);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        
        if (slave_vif  != null) csr_agent.set_vif(slave_vif);
        if (master_vif != null) master_mon.set_vif(master_vif);
        
        reg_map.set_agent(csr_agent);
        ral.reg_block.reset();
        
        predictor.reg_map = reg_map;
        csr_agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
        master_mon.monitor.ap_write.connect(scoreboard.analysis_imp.get_mailbox());
        
        log_info("Environment connected", EVM_LOW);
    endfunction
    
    task write_csr(string reg_name, logic [31:0] value);
        bit status;
        ral.reg_block.write_reg(reg_name, value, status);
        if (!status) log_error($sformatf("Failed to write CSR '%s'", reg_name));
    endtask
    
    task read_csr(string reg_name, output logic [31:0] value);
        bit status;
        ral.reg_block.read_reg(reg_name, value, status);
        if (!status) log_error($sformatf("Failed to read CSR '%s'", reg_name));
    endtask
    
    virtual function string get_type_name();
        return "example1_env";
    endfunction
    
endclass : example1_env
