# EVM Technical Reference

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

Single-page technical reference. For conceptual overview see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Logging

### Severity Levels

| Severity | Behavior | When to Use |
|---|---|---|
| `log_info(msg, verbosity)` | Shown if verbosity setting ≥ level | Normal progress |
| `log_warning(msg)` | Always shown, increments counter | Unexpected but non-fatal |
| `log_error(msg)` | Always shown, increments error counter | Test failure |
| `log_debug(msg)` | Shown at EVM_DEBUG only | Deep debug detail |

### Verbosity Levels (least → most verbose)

```
EVM_NONE(0)  EVM_LOW(100)  EVM_MEDIUM(200)  EVM_HIGH(300)  EVM_DEBUG(500)
```

Default is `EVM_MEDIUM`. Use `EVM_LOW` for critical milestones only.

### Logging API

```systemverilog
// From any evm_component or evm_object:
log_info("message", EVM_LOW);      // shown at LOW+
log_info("detail", EVM_HIGH);      // shown at HIGH+
log_warning("unexpected event");   // always shown
log_error("test failure");         // always shown, counted

// Global configuration:
evm_report_handler::set_verbosity(EVM_MEDIUM);
evm_report_handler::enable_file_logging("sim.log");
evm_report_handler::print_summary();          // at end of test

// Error counts (use in check_phase):
evm_log::error_count     // int, total errors
evm_log::warning_count   // int, total warnings
```

### Plusarg Control

```bash
+verbosity=HIGH        # set verbosity at runtime
+evm_log=sim.log       # enable file logging
+seed=12345            # set random seed
+EVM_TIMEOUT=5000      # timeout in microseconds
+EVM_TESTNAME=my_test  # select test by name
+EVM_LIST_TESTS        # print registered tests and exit
+EVM_SEQ=my_seq        # select sequence by name
```

---

## Phase Quick Reference

**Rule: Always call `super.phase()` FIRST in every override.**

| Phase | Type | Key Actions | Common Mistakes |
|---|---|---|---|
| `build_phase()` | function | Create child components with `new()` | Creating objects in constructors |
| `connect_phase()` | function | Set VIFs; connect TLM ports | Accessing undeclared VIFs |
| `end_of_elaboration_phase()` | function | Validate config; `print_topology()` | — |
| `start_of_simulation_phase()` | function | Init scoreboards; open files | — |
| `reset_phase()` | task | Drive reset signal; wait for stable | No delay after reset deassert |
| `configure_phase()` | task | Write CSRs; set DUT mode | Writing before reset complete |
| `main_phase()` | task | **Raise objection first!** Drive stimulus | Forgetting `raise_objection()` |
| `shutdown_phase()` | task | Drain FIFOs; wait for idle | — |
| `extract_phase()` | function | Read DUT counters; get scoreboard stats | — |
| `check_phase()` | function | Compare expected vs actual | — |
| `report_phase()` | function | Print test pass/fail summary | — |
| `final_phase()` | function | Close files; cleanup | — |

### What NOT to Do in Each Phase

```systemverilog
// build_phase() — no time, no VIF access
function void build_phase();
    super.build_phase();
    vif.data = 0;      // ❌ VIF not set yet
    #100;              // ❌ cannot consume time in a function
    env = new(...);    // ✅
endfunction

// connect_phase() — no stimulus, just wiring
function void connect_phase();
    super.connect_phase();
    agent.set_vif(vif);                         // ✅
    monitor.analysis_port.connect(...mailbox);  // ✅
endfunction

// main_phase() — MUST use objections
task main_phase();
    super.main_phase();
    // ❌ NO objection → phase ends immediately, #100us never runs
    raise_objection("test");  // ✅ do this first
    #100us;
    drop_objection("test");   // ✅ do this last
endtask
```

---

## Virtual Interface Pattern

### Concept

```
Interface (module scope)       →  concrete signals/wires connected to DUT
Virtual Interface (class var)  →  handle pointing to the concrete interface
```

### Complete Minimal Pattern

```systemverilog
// 1. Interface (tb_top.sv module scope)
interface my_if(input logic clk);
    logic [31:0] data;
    logic        valid;
    logic        ready;
    
    // Clocking block prevents race conditions
    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output data, valid;
        input  ready;
    endclocking
    
    clocking mon_cb @(posedge clk);
        default input #1step;
        input data, valid, ready;
    endclocking
    
    // Modports restrict access direction
    modport driver  (clocking drv_cb, input clk);
    modport monitor (clocking mon_cb, input clk);
endinterface

// 2. Module instantiation (tb_top.sv)
module tb_top;
    logic clk;
    always #5ns clk = ~clk;      // 100 MHz
    my_if dut_if(.clk(clk));
    my_dut dut(.clk(clk), .data(dut_if.data), ...);
    
    initial begin
        my_test t = new("t");
        t.env.agent.set_vif(dut_if);  // Direct assignment — no config DB!
        evm_root::get().run_test(t);
    end
endmodule

// 3. Driver (uses virtual interface)
class my_driver extends evm_driver#(virtual my_if);
    virtual task main_phase();
        super.main_phase();
        forever begin
            if (in_reset) begin @(reset_deasserted); continue; end
            seq_item_port.get_next_item(req);
            @(vif.drv_cb);          // sync to clocking block
            vif.drv_cb.data  <= req.data;
            vif.drv_cb.valid <= 1'b1;
            @(vif.drv_cb iff vif.drv_cb.ready);
            vif.drv_cb.valid <= 1'b0;
            seq_item_port.item_done();
        end
    endtask
endclass

// 4. Monitor (use run_phase, not main_phase)
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    virtual task run_phase();
        super.run_phase();   // starts reset monitoring thread
        fork
            forever begin
                if (in_reset) begin @(reset_deasserted); continue; end
                @(vif.mon_cb iff vif.mon_cb.valid && vif.mon_cb.ready);
                my_txn t = new("t");
                t.data = vif.mon_cb.data;
                analysis_port.write(t);  // broadcast to scoreboard etc.
            end
        join_none
    endtask
endclass
```

### Why `#1step` in clocking blocks?

`#1step` samples in the NBA (non-blocking assignment) region — after all flip-flop outputs are stable but before the next clock edge. This is the correct sampling point and avoids race conditions with the DUT's own flip-flop outputs.

### Why `default output #1ns`?

Adds 1ns setup margin — signals are driven slightly after clock edge, giving the DUT a proper setup window.

---

## Monitor → Scoreboard TLM Pattern

### Complete Working Example

```systemverilog
// 1. Transaction class (must support comparison)
class my_txn extends evm_sequence_item;
    bit [31:0] addr;
    bit [31:0] data;
    
    function new(string name = "my_txn");
        super.new(name);
    endfunction
    
    // Required for EVM_SB_FIFO mode (==  operator)
    function bit is_equal(my_txn other);
        return (this.addr == other.addr && this.data == other.data);
    endfunction
endclass

// 2. Monitor — publishes to analysis_port in run_phase
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    virtual task run_phase();
        super.run_phase();
        fork
            forever begin
                my_txn t = new("t");
                collect(t);
                analysis_port.write(t);  // ← broadcasts to ALL subscribers
            end
        join_none
    endtask
endclass

// 3. Scoreboard — receives via analysis_imp
class my_scoreboard extends evm_scoreboard#(my_txn);
    function new(string name, evm_component parent);
        super.new(name, parent);
        mode = EVM_SB_FIFO;  // strict FIFO order (default)
    endfunction
    
    // Optional: override for custom comparison
    virtual function bit compare_transactions(my_txn exp, my_txn act);
        if (!exp.is_equal(act)) begin
            log_error($sformatf("MISMATCH: exp addr=%0h, act addr=%0h",
                               exp.addr, act.addr));
            return 0;
        end
        return 1;
    endfunction
endclass

// 4. Connect in env connect_phase
virtual function void connect_phase();
    super.connect_phase();
    monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
    // Can connect multiple subscribers:
    monitor.analysis_port.connect(predictor.analysis_imp.get_mailbox());
endfunction

// 5. Inject expected from test (before or alongside stimulus)
virtual task main_phase();
    super.main_phase();
    raise_objection("test");
    
    // Predict expected output (reference model)
    my_txn expected = new("exp");
    expected.addr = 32'h1000;
    expected.data = 32'hDEAD_BEEF;
    env.scoreboard.insert_expected(expected);
    
    // Drive stimulus
    env.agent.write(32'h1000, 32'hDEAD_BEEF);
    
    #100ns;
    drop_objection("test");
endtask
```

### Scoreboard Modes

| Mode | Use When | Notes |
|---|---|---|
| `EVM_SB_FIFO` | DUT is in-order, strict sequencing | Default; expected must arrive before actual |
| `EVM_SB_ASSOCIATIVE` | Match by key (OOO responses ok) | Override `find_matching_expected(actual)` |
| `EVM_SB_UNORDERED` | Any expected matches any actual | Exact bitwise match only |

### Orphan Detection

At `final_phase()`, scoreboard automatically logs:
- `orphan_expected` — transactions expected but never received
- `orphan_actual` — transactions received but never expected

Both are errors. `print_report()` summarizes matches, mismatches, and orphans.

---

## CSR Register Access Pattern

```systemverilog
// Direct via AXI-Lite agent:
logic [1:0] resp;
axi_agent.write(32'h1000, 32'h0000_0001, 4'b1111, resp);  // write
logic [31:0] rdata;
axi_agent.read(32'h1000, rdata, resp);                     // read
axi_agent.write_check(32'h1000, 32'h0000_0001);            // write + verify
axi_agent.rmw(32'h1000, 32'hFF, 32'h42);                  // read-mod-write
bit success;
axi_agent.poll(32'h1008, 32'h3, 32'h0, 5000, success);    // poll until idle

// Via RAL (after CSR generator):
bit status;
ral.write_doorbell_addr(32'hDEAD_0000, status);
ral.read_status(rdata, status);
ral.mirror(status);  // read DUT and compare with model
```

---

## Common Compilation Issues

| Symptom | Cause | Fix |
|---|---|---|
| Test never ends | Forgot `drop_objection()` | Add at end of `main_phase()` |
| Test ends instantly | Forgot `raise_objection()` | Add at start of `main_phase()` |
| `null VIF` error | VIF not set before `run_test()` | Call `agent.set_vif()` before `evm_root::get().run_test()` |
| Scoreboard never checks | Monitor not connected | `monitor.analysis_port.connect(sb.analysis_imp.get_mailbox())` |
| Monitor data = X | Sampling wrong region | Use clocking block with `#1step` input |
| Driver races DUT | Driving without clocking block | Use `@(vif.drv_cb)` before driving |
| Components not created | Missing `super.build_phase()` | Always call super first |

---

## See Also

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — Full framework overview with diagrams
- [`AGENTS.md`](AGENTS.md) — Protocol agent documentation
- [`REGISTER_MODEL.md`](REGISTER_MODEL.md) — RAL and predictor
- [`TEST_INFRASTRUCTURE.md`](TEST_INFRASTRUCTURE.md) — Test registry, env, sequence library
- [`UVM_FEATURES_NOT_IMPLEMENTED.md`](UVM_FEATURES_NOT_IMPLEMENTED.md) — What EVM intentionally omits
- [`../vkit/docs/uml/`](../vkit/docs/uml/) — Mermaid UML class diagrams
