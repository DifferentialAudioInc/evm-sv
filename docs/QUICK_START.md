# EVM Quick Start

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

Get a testbench running in 15 minutes.

---

## 1. Import EVM

```systemverilog
import evm_pkg::*;        // Core framework
import evm_vkit_pkg::*;   // Protocol agents (AXI-Lite, AXI4 Full, etc.)
```

---

## 2. Minimal Test (no agents)

```systemverilog
class my_test extends evm_base_test;
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");   // ← required or phase ends immediately
        
        #1us;                      // your test code here
        
        drop_objection("test");
    endtask
endclass

// tb_top.sv
initial begin
    my_test t = new("my_test");
    evm_root::get().run_test(t);
    $finish;
end
```

---

## 3. Typical IP Verification Structure

```
evm_base_test
  └── evm_env
        ├── evm_axi_lite_master_agent   (CSR writes/reads)
        ├── evm_axi4_full_master_agent  (DMA burst access)
        ├── evm_scoreboard              (check output)
        └── evm_reg_map + predictor     (RAL + auto-mirror)
```

---

## 4. Define a Transaction

```systemverilog
class my_txn extends evm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    
    function new(string name = "my_txn");
        super.new(name);
    endfunction
endclass
```

---

## 5. Define a Monitor (use run_phase — not main_phase!)

```systemverilog
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    virtual task run_phase();
        super.run_phase();   // starts reset monitoring thread
        if (vif == null) return;
        fork
            forever begin
                if (in_reset) begin @(reset_deasserted); continue; end
                // Wait for a transaction on the interface
                @(posedge vif.clk iff (vif.valid && vif.ready));
                my_txn t = new("t");
                t.data = vif.data;
                analysis_port.write(t);  // broadcast to scoreboard/predictor
            end
        join_none
    endtask
endclass
```

**Why `run_phase()`?** Monitors must run continuously — even during `reset_phase`, `configure_phase`, and `shutdown_phase`. Using `main_phase()` would miss transactions at phase boundaries.

---

## 6. Define a Driver

```systemverilog
class my_driver extends evm_driver#(virtual my_if);
    virtual task main_phase();
        super.main_phase();
        forever begin
            if (in_reset) begin @(reset_deasserted); continue; end
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);
            vif.data  <= req.data;
            vif.valid <= 1'b1;
            @(posedge vif.clk iff vif.ready);
            vif.valid <= 1'b0;
            seq_item_port.item_done();
        end
    endtask
    
    virtual task on_reset_assert();
        super.on_reset_assert();
        vif.valid <= 0;   // idle bus during reset
    endtask
endclass
```

---

## 7. Define an Agent

```systemverilog
class my_agent extends evm_component;
    my_driver                   driver;
    my_monitor                  monitor;
    evm_sequencer#(my_txn)      sequencer;
    virtual my_if               vif;
    
    function new(string name, evm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        monitor   = new("monitor",   this);
        driver    = new("driver",    this);
        sequencer = new("sequencer", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        driver.seq_item_port.connect(
            sequencer.seq_item_export.get_req_fifo(),
            sequencer.seq_item_export.get_rsp_fifo()
        );
        if (vif != null) begin
            driver.set_vif(vif);
            monitor.set_vif(vif);
        end
    endfunction
    
    function void set_vif(virtual my_if vif_handle);
        this.vif = vif_handle;
        if (driver  != null) driver.set_vif(vif_handle);
        if (monitor != null) monitor.set_vif(vif_handle);
    endfunction
endclass
```

---

## 8. Define an Environment

```systemverilog
class my_env extends evm_env;
    my_agent           agent;
    evm_scoreboard#(my_txn) scoreboard;
    
    virtual function void build_phase();
        super.build_phase();   // auto-prints topology
        agent      = new("agent",      this);
        scoreboard = new("scoreboard", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        agent.monitor.analysis_port.connect(
            scoreboard.analysis_imp.get_mailbox()
        );
    endfunction
endclass
```

---

## 9. Define a Test

```systemverilog
class my_test extends evm_base_test;
    my_env env;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        evm_report_handler::set_verbosity(EVM_MEDIUM);
        env = new("env", this);
    endfunction
    
    virtual task reset_phase();
        super.reset_phase();
        env.agent.set_vif(/* pass in VIF here */);
        // drive reset...
    endtask
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // Insert expected result into scoreboard
        my_txn exp = new("exp");
        exp.data = 32'hDEAD_BEEF;
        env.scoreboard.insert_expected(exp);
        
        // Drive stimulus via sequencer
        my_txn req = new("req");
        req.data = 32'hDEAD_BEEF;
        env.agent.sequencer.send_item(req);
        
        #1us;
        drop_objection("test");
    endtask
    
    virtual function void report_phase();
        super.report_phase();          // prints PASS/FAIL automatically
    endfunction
endclass
```

---

## 10. tb_top.sv Template

```systemverilog
module tb_top;
    import evm_pkg::*;
    import my_pkg::*;
    
    // Clock and reset
    logic clk = 0;
    logic rst_n = 0;
    always #5ns clk = ~clk;
    initial begin #20ns rst_n = 1; end
    
    // Interface
    my_if dut_if(.clk(clk));
    
    // DUT
    my_dut dut(
        .clk(clk),
        .rst_n(rst_n),
        .data(dut_if.data),
        .valid(dut_if.valid),
        .ready(dut_if.ready)
    );
    
    // Test execution
    initial begin
        my_test t = new("my_test");
        t.env.agent.set_vif(dut_if);   // direct assignment — no config DB
        evm_root::get().run_test(t);
        $finish;
    end
    
    // Or use +EVM_TESTNAME=my_test (after registering with EVM_REGISTER_TEST)
    // initial begin
    //     t.env.agent.set_vif(dut_if);
    //     evm_root::get().run_test_by_name();
    // end
endmodule
```

---

## 11. Key Rules

| Rule | Why |
|---|---|
| Always call `super.phase()` first | Chains phase execution to base class |
| `raise_objection()` at start of `main_phase()` | Phase ends immediately without it |
| Monitors use `run_phase()` not `main_phase()` | Continuous monitoring across all phases |
| Set VIF before calling `run_test()` | VIF must be valid when build/connect run |
| Check `in_reset` flag before driving | Prevents protocol violations during reset |

---

## Quick Reference Links

| What you need | Document |
|---|---|
| Framework concepts | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Protocol agents | [`AGENTS.md`](AGENTS.md) |
| Register model / RAL | [`REGISTER_MODEL.md`](REGISTER_MODEL.md) |
| Test registry, env, sequences | [`TEST_INFRASTRUCTURE.md`](TEST_INFRASTRUCTURE.md) |
| Logging API, phase tips, VIF details, scoreboard | [`REFERENCE.md`](REFERENCE.md) |
| UML class diagrams | [`../vkit/docs/uml/`](../vkit/docs/uml/) |
| AI development guide | [`../CLAUDE.md`](../CLAUDE.md) |
