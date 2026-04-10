# EVM Framework Architecture

**Version:** 2.0  
**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Overview

EVM (Embedded Verification Methodology) is a lightweight SystemVerilog verification framework. It provides the essential UVM patterns at a fraction of the complexity, specifically optimized for embedded FPGA/ASIC IP verification.

**Design goals:**
- 90% of UVM's value at 10% of its complexity
- Direct, explicit code — no hidden magic (no factory, no config DB)
- Continuous monitoring via `run_phase()` — no missed transactions
- Mid-simulation reset support built into every component
- AI-first documentation

---

## Component Hierarchy

All EVM objects descend from two base classes:

```
evm_object                     # Base for all non-component objects
  ├── evm_sequence_item        # Transaction base
  ├── evm_sequence             # Transaction collection
  ├── evm_reg_field            # Register bit field
  ├── evm_reg                  # Individual register
  ├── evm_reg_block            # Register block
  ├── evm_reg_map              # Address map (multiple blocks)
  └── evm_sequence_library     # Named sequence registry

evm_component                  # Base for all phased components
  ├── evm_monitor              # Continuous bus observer (run_phase)
  ├── evm_driver               # Bus stimulus driver (main_phase)
  ├── evm_sequencer            # Sequence dispatcher
  ├── evm_agent                # Agent wrapper (driver+monitor+sequencer)
  ├── evm_env                  # Environment layer (test→agents)
  ├── evm_scoreboard           # Transaction checker (run_phase)
  ├── evm_reg_predictor        # RAL mirror auto-updater (run_phase)
  ├── evm_qc                   # Quiescence counter (activity watchdog)
  ├── evm_root                 # Singleton phase controller
  └── evm_base_test            # Test base class
```

---

## The 12 Phases

EVM uses a 12-phase lifecycle. **Always call `super.method()` first in any override.**

### Build-Time Phases (functions — no time passes)

| Phase | Purpose | Typical Use |
|---|---|---|
| `build_phase()` | Create sub-components | `new()` child components here |
| `connect_phase()` | Wire TLM ports | Connect analysis ports, set VIFs |
| `end_of_elaboration_phase()` | Finalize config | Print topology |
| `start_of_simulation_phase()` | Pre-sim init | Initialize state |

### Run-Time Phases (tasks — time advances)

| Phase | Runs | Purpose |
|---|---|---|
| `run_phase()` | **Parallel** to all below | Monitors, scoreboards, predictors — runs forever |
| `reset_phase()` | Sequential | Apply DUT reset |
| `configure_phase()` | Sequential | Configure DUT registers |
| `main_phase()` | Sequential | Test stimulus — use objections here |
| `shutdown_phase()` | Sequential | Clean shutdown |

### Cleanup Phases (functions)

| Phase | Purpose |
|---|---|
| `extract_phase()` | Collect results from components |
| `check_phase()` | Verify outcomes |
| `report_phase()` | Print results |
| `final_phase()` | Final cleanup |

### Critical: run_phase vs main_phase

```
Timeline:
         reset_phase → configure_phase → main_phase → shutdown_phase
             ↑                                              ↑
             └────────── run_phase (continuous) ───────────┘

Monitors and scoreboards run in run_phase() — they never stop.
Test stimulus runs in main_phase() — controlled by objections.
```

**Why this matters:** If monitors ran in `main_phase()`, they'd stop when the test transitions to `shutdown_phase()`, causing missed tail-end transactions. `run_phase()` solves this.

### Reset Sub-Phases

`reset_phase()` internally calls three virtual tasks you can override:

```systemverilog
reset_phase():
    pre_reset()    // Stop activities, save state
    reset()        // Clear queues, reset counters
    post_reset()   // Reinitialize, prepare for operation
```

---

## Mid-Simulation Reset Support

Every `evm_component` has built-in reset event infrastructure:

```systemverilog
// In evm_component:
event reset_asserted;     // Fired when reset starts
event reset_deasserted;   // Fired when reset ends
bit   in_reset;           // Status flag

virtual function void assert_reset();    // Call from test/reset agent
virtual function void deassert_reset();  // Call from test/reset agent
virtual task on_reset_assert();          // Override to handle reset
virtual task on_reset_deassert();        // Override to handle reset release
```

**Usage:**
```systemverilog
// From test or reset agent:
env.assert_reset();     // Propagates to all children
#(10 * CLOCK_PERIOD);
env.deassert_reset();

// In a monitor (example):
virtual task on_reset_assert();
    super.on_reset_assert();
    // Flush any partial transaction being collected
    current_txn = null;
endtask
```

**What each component does automatically on reset:**
- **Monitor**: logs "paused", stops collecting (checks `in_reset` flag)
- **Scoreboard**: flushes expected + actual queues  
- **Driver**: idles the bus (deasserts all outputs)
- **Sequencer**: drains mailbox and TLM FIFOs
- **RAL Predictor**: resets register map mirror to power-on values

---

## Virtual Interface Pattern

EVM uses direct VIF assignment — no config database.

```systemverilog
// In tb_top (before simulation):
my_env env = new("env", null);
env.agent.set_vif(my_if);           // Direct assignment

// In agent:
function void set_vif(virtual my_if vif_handle);
    this.vif = vif_handle;
    if (driver  != null) driver.set_vif(vif_handle);
    if (monitor != null) monitor.set_vif(vif_handle);
endfunction
```

**Connect in build/connect order:**
1. Create agent in `build_phase()`
2. Call `set_vif()` before `connect_phase()` completes
3. Agent propagates VIF to driver and monitor in `connect_phase()`

---

## TLM 1.0 Infrastructure

### Analysis Ports (broadcast — one publisher, many subscribers)

```
Monitor                        Scoreboard
   analysis_port ──────────→  analysis_imp  (checks transactions)
                 └──────────→  predictor.analysis_imp  (updates RAL)
                 └──────────→  coverage_collector.analysis_imp
```

**Connection:**
```systemverilog
// In env connect_phase():
monitor.ap_write.connect(scoreboard.analysis_imp.get_mailbox());
monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
```

### Sequence Item Ports (driver ↔ sequencer)

```
Sequencer ←───── seq_item_export ←──── req_fifo ←── sequences
                                 └──── rsp_fifo ──→ sequences
Driver ──────→   seq_item_port ─────→ (pulls from req_fifo)
```

**Connection:**
```systemverilog
// In agent connect_phase():
driver.seq_item_port.connect(
    sequencer.seq_item_export.get_req_fifo(),
    sequencer.seq_item_export.get_rsp_fifo()
);
```

---

## Objection Mechanism

Objections control when `main_phase()` ends. The test runs until all objections are dropped.

```systemverilog
virtual task main_phase();
    super.main_phase();
    raise_objection("test running");
    
    // Run test stimulus here
    run_sequences();
    #(100 * CLOCK_PERIOD);
    
    drop_objection("test complete");
    // main_phase ends; run_phase continues until fork unblocks
endtask
```

**Quiescence Counter (QC) — automatic alternative:**
```systemverilog
// In test constructor:
function new(string name = "my_test");
    super.new(name);
    enable_quiescence_counter(200); // End after 200 idle cycles
endfunction

// In drivers/monitors — signal activity:
qc.tick();  // Reset the idle counter
// Test ends automatically after 200 cycles of no tick() calls
```

---

## Test Execution Flow

```
tb_top
  │
  ├── initial begin
  │     evm_root::get().run_test_by_name();  // +EVM_TESTNAME=my_test
  │   end
  │
  └── evm_root.run_all_phases_with_test(test)
        │
        ├── build_phase()         ← construct env/agents/monitors
        ├── connect_phase()       ← wire TLM ports, set VIFs
        ├── end_of_elaboration()  ← print topology
        ├── start_of_simulation() ← pre-sim init
        │
        ├── fork
        │     run_phase()          ← monitors, scoreboards, predictors (forever)
        │     reset_phase()        ─┐
        │     configure_phase()     ├── sequential phases
        │     main_phase()          │  (objection controls end)
        │     shutdown_phase()     ─┘
        │   join
        │
        ├── extract_phase()
        ├── check_phase()
        ├── report_phase()
        └── final_phase()
```

---

## Environment Layering

Recommended hierarchy for IP verification:

```
evm_base_test          (your_test.sv)
  └── evm_env          (your_env.sv)
        ├── agent_a    (AXI-Lite, AXI4 Full, etc.)
        ├── agent_b
        ├── evm_scoreboard
        ├── evm_reg_predictor
        └── your_reg_map  (evm_reg_map with CSR-gen blocks)
```

```systemverilog
class my_env extends evm_env;
    evm_axi_lite_master_agent  csr_agent;
    evm_axi4_full_master_agent dma_agent;
    evm_scoreboard#(my_txn)    scoreboard;
    evm_axi_lite_write_predictor predictor;
    my_reg_map                 reg_map;
    
    virtual function void build_phase();
        super.build_phase();       // auto-prints topology
        csr_agent  = new("csr_agent",  this);
        dma_agent  = new("dma_agent",  this);
        scoreboard = new("scoreboard", this);
        predictor  = new("predictor",  this);
        reg_map    = new("reg_map");
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        // Connect monitor → scoreboard
        dma_agent.monitor.ap_write.connect(scoreboard.analysis_imp.get_mailbox());
        // Connect CSR monitor → RAL predictor
        predictor.reg_map = reg_map;
        csr_agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
    endfunction
endclass
```

---

## Logging

```systemverilog
// Verbosity levels (from least to most verbose):
// EVM_NONE  EVM_LOW  EVM_MEDIUM  EVM_HIGH  EVM_DEBUG

// From any evm_component or evm_object:
log_info("message", EVM_LOW);     // Always shown at EVM_LOW+
log_warning("message");           // Always shown, increments counter
log_error("message");             // Always shown, increments error counter

// Global settings:
evm_report_handler::set_verbosity(EVM_MEDIUM);
evm_report_handler::enable_file_logging("sim.log");

// Plusarg control:
// +verbosity=HIGH    → sets verbosity
// +evm_log=sim.log   → enables file logging
// +seed=12345        → sets random seed
// +EVM_TIMEOUT=1000  → timeout in microseconds
```

---

## Coding Standards

```systemverilog
// 1. ALWAYS call super first in every phase override
virtual function void build_phase();
    super.build_phase();   // ← critical
    // your code
endfunction

// 2. Raise objection BEFORE any test activity
virtual task main_phase();
    super.main_phase();
    raise_objection("test");    // ← first line
    // test code
    drop_objection("test");     // ← last line
endtask

// 3. Check in_reset before driving in run_phase
virtual task run_phase();
    super.run_phase();
    fork
        forever begin
            if (!in_reset) begin
                // do work
            end else begin
                @(reset_deasserted);
            end
        end
    join_none
endtask

// 4. Components should NOT reference parent directly
//    Use constructor injection or set_vif() pattern
```

---

## See Also

- [`QUICK_START.md`](QUICK_START.md) — Get running in 15 minutes
- [`AGENTS.md`](AGENTS.md) — Protocol agent documentation
- [`REGISTER_MODEL.md`](REGISTER_MODEL.md) — RAL and CSR generator
- [`TEST_INFRASTRUCTURE.md`](TEST_INFRASTRUCTURE.md) — Test registry, env, sequence library
- [`EVM_LOGGING_COMPLETE_GUIDE.md`](EVM_LOGGING_COMPLETE_GUIDE.md) — Logging reference
- [`EVM_MONITOR_SCOREBOARD_GUIDE.md`](EVM_MONITOR_SCOREBOARD_GUIDE.md) — Monitor/scoreboard patterns
- [`../CLAUDE.md`](../CLAUDE.md) — AI development guide (primary reference)
