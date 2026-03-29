# EVM Quick Start Guide

Get started with EVM in 5 minutes!

---

## 📦 What is EVM?

**EVM (Embedded Verification Methodology)** is a lightweight alternative to UVM for embedded systems verification.

- ✅ **100% of UVM critical features**
- ✅ **10% of UVM code complexity**
- ✅ **Compile in seconds, not minutes**
- ✅ **Learn in days, not weeks**

---

## 🚀 Quick Example

```systemverilog
// 1. Import EVM
import evm_pkg::*;

// 2. Create a test
class my_test extends evm_base_test;
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // Your test code here
        #1us;
        
        drop_objection("test");
    endtask
endclass

// 3. Run the test
initial begin
    my_test test = new("my_test");
    evm_root::get().run_test(test);
end
```

---

## 🏗️ Basic Structure

### 1. Transaction
```systemverilog
class my_txn extends evm_sequence_item;
    rand bit [7:0] data;
    
    function new(string name = "my_txn");
        super.new(name);
    endfunction
endclass
```

### 2. Monitor
```systemverilog
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    virtual task main_phase();
        my_txn txn;
        forever begin
            txn = collect_from_interface();
            analysis_port.write(txn);  // Broadcast!
        end
    endtask
endclass
```

### 3. Driver
```systemverilog
class my_driver extends evm_driver#(virtual my_if, my_txn);
    virtual task main_phase();
        my_txn req;
        forever begin
            seq_item_port.get_next_item(req);
            drive_to_interface(req);
            seq_item_port.item_done();
        end
    endtask
endclass
```

### 4. Scoreboard
```systemverilog
class my_scoreboard extends evm_scoreboard#(my_txn);
    function new(string name, evm_component parent);
        super.new(name, parent);
        mode = EVM_SB_FIFO;  // FIFO checking
    endfunction
endclass
```

### 5. Agent
```systemverilog
class my_agent extends evm_component;
    my_driver driver;
    my_monitor monitor;
    my_sequencer#(my_txn) sequencer;
    
    virtual function void build_phase();
        super.build_phase();
        driver = new("driver", this);
        monitor = new("monitor", this);
        sequencer = new("sequencer", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        driver.seq_item_port.connect(
            sequencer.seq_item_export.get_req_fifo(),
            sequencer.seq_item_export.get_rsp_fifo()
        );
    endfunction
endclass
```

### 6. Environment
```systemverilog
class my_env extends evm_component;
    my_agent agent;
    my_scoreboard sb;
    
    virtual function void build_phase();
        super.build_phase();
        agent = new("agent", this);
        sb = new("sb", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        agent.monitor.analysis_port.connect(sb.analysis_imp.get_mailbox());
    endfunction
endclass
```

---

## 🔄 The 12 Phases

```systemverilog
class my_test extends evm_base_test;
    // 1. Build
    virtual function void build_phase();
        super.build_phase();
        env = new("env", this);
    endfunction
    
    // 2. Connect
    virtual function void connect_phase();
        super.connect_phase();
        // Make TLM connections
    endfunction
    
    // 3. End of Elaboration
    virtual function void end_of_elaboration_phase();
        super.end_of_elaboration_phase();
        print_topology();
    endfunction
    
    // 4. Start of Simulation
    virtual function void start_of_simulation_phase();
        super.start_of_simulation_phase();
    endfunction
    
    // 5. Reset
    virtual task reset_phase();
        super.reset_phase();
    endtask
    
    // 6. Configure
    virtual task configure_phase();
        super.configure_phase();
    endtask
    
    // 7. Main (with objections!)
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        // Test code
        drop_objection("test");
    endtask
    
    // 8. Shutdown
    virtual task shutdown_phase();
        super.shutdown_phase();
    endtask
    
    // 9. Extract
    virtual function void extract_phase();
        super.extract_phase();
    endfunction
    
    // 10. Check
    virtual function void check_phase();
        super.check_phase();
    endfunction
    
    // 11. Report
    virtual function void report_phase();
        super.report_phase();
    endfunction
    
    // 12. Final
    virtual function void final_phase();
        super.final_phase();
        evm_report_handler::print_summary();
    endfunction
endclass
```

**ALWAYS call `super.phase()` first!**

---

## 💡 Key Patterns

### Virtual Interface (No Config DB!)
```systemverilog
// In test/env
function void set_vif(virtual my_if vif);
    agent.driver.set_vif(vif);
    agent.monitor.set_vif(vif);
endfunction

// In testbench
test.set_vif(my_vif);
```

### Monitor → Scoreboard
```systemverilog
// In environment connect_phase
monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());

// Monitor automatically broadcasts
// Scoreboard automatically receives and checks
```

### Objections
```systemverilog
virtual task main_phase();
    super.main_phase();
    raise_objection("my_test");
    
    // Test runs here
    
    drop_objection("my_test");
endtask
```

---

## 📚 Complete Examples

1. **examples/minimal_test/** - Simplest possible test
2. **examples/full_phases_test/** - All 12 phases + agents
3. **examples/complete_test/** - Monitor → Scoreboard flow

---

## 📖 Documentation

| Guide | Topic |
|-------|-------|
| **EVM_PHASING_GUIDE.md** | The 12 phases in detail |
| **EVM_VIRTUAL_INTERFACE_GUIDE.md** | VIF usage (no config DB) |
| **EVM_MONITOR_SCOREBOARD_GUIDE.md** | TLM communication |
| **EVM_LOGGING_COMPLETE_GUIDE.md** | Reporting and logging |

---

## 🎯 EVM vs UVM Cheat Sheet

| Feature | UVM | EVM |
|---------|-----|-----|
| **Virtual Interface** | `uvm_config_db#(vif)::set()` | Direct `set_vif(vif)` |
| **Factory** | `uvm_factory::create()` | Direct `new()` |
| **Field Macros** | `` `uvm_field_int()`` | Manual `do_copy()` |
| **Objections** | `uvm_objection` | Same: `raise/drop_objection()` |
| **Phasing** | 13 phases | 12 phases (same concept) |
| **TLM** | TLM 1.0 + 2.0 | TLM 1.0 (sufficient) |
| **Reporting** | `uvm_report_*` | `log_info/error/etc` |
| **Scoreboard** | Build your own | Built-in `evm_scoreboard` |

---

## ⚡ Quick Tips

1. **Always call super first:**
   ```systemverilog
   virtual function void build_phase();
       super.build_phase();  // ← FIRST!
       // Your code
   endfunction
   ```

2. **Use objections in main_phase:**
   ```systemverilog
   raise_objection("name");
   // stuff
   drop_objection("name");
   ```

3. **Print topology to debug:**
   ```systemverilog
   virtual function void end_of_elaboration_phase();
       super.end_of_elaboration_phase();
       print_topology();
   endfunction
   ```

4. **Enable file logging:**
   ```systemverilog
   evm_report_handler::enable_file_logging("test.log");
   evm_report_handler::set_verbosity(EVM_MEDIUM);
   ```

---

## 🎉 You're Ready!

Start with `examples/full_phases_test/` to see everything working together.

**EVM = UVM simplicity for embedded verification!**
