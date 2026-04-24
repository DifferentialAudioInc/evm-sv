# CLAUDE.md — EVM Deep Reference
# Project: evm-sv (Embedded Verification Methodology)

**Last Updated:** 2026-04-23  
**Status:** Production Ready ✅  
**License:** MIT — Copyright (c) 2026 Differential Audio Inc.

---

## 🎯 Project Overview

**EVM** is a lightweight UVM alternative for embedded systems verification.  
**Goal:** 100% of UVM's critical features at 10% of UVM's complexity.  
**Target:** Embedded FPGA/microcontroller DUTs — NOT ASIC-scale complexity.

**Key differentiators vs UVM:**
- No config_db — direct VIF passing: `agent.set_vif(vif)`
- Phase methods have NO arguments — `virtual task main_phase();`
- Quiescence Counter (`evm_qc`) for automatic test completion
- 3-phase reset + mid-sim reset events built into all components
- Built-in test registry (`EVM_REGISTER_TEST`) and sequence library (`EVM_REGISTER_SEQUENCE`)

---

## 📁 Folder Hierarchy

```
evm-sv/
├── CLAUDE.md                       # ← This file
├── NEXT_STEPS.md                   # Roadmap of optional enhancements
├── README.md                       # Public overview
├── CONTRIBUTING.md
│
├── vkit/src/                       # ← CORE EVM LIBRARY (evm_pkg)
│   ├── evm_pkg.sv                  # Package (includes all below in order)
│   ├── evm_report_handler.sv       # Singleton reporting — loaded FIRST
│   ├── evm_log.sv                  # Base logging class for all EVM classes
│   ├── evm_object.sv               # Base data object (copy/clone/compare)
│   ├── evm_component.sv            # Base component (12 phases + reset events)
│   ├── evm_tlm.sv                  # TLM: analysis_port, seq_item_port/export, tlm_fifo
│   ├── evm_sequence_item.sv        # Base transaction item
│   ├── evm_sequence.sv             # Base sequence (container of items)
│   ├── evm_virtual_sequence.sv     # Virtual sequence + virtual sequencer
│   ├── evm_sequencer.sv            # Sequencer (item dispatch + reset flush)
│   ├── evm_driver.sv               # Driver base (run_phase reset monitor)
│   ├── evm_monitor.sv              # Monitor base (run_phase + analysis_port)
│   ├── evm_agent.sv                # Agent base (driver + monitor + sequencer)
│   ├── evm_scoreboard.sv           # Scoreboard (3 modes + run_phase continuous)
│   ├── evm_env.sv                  # Environment base (auto topology print)
│   ├── evm_reg_field.sv            # Register field (access policies)
│   ├── evm_reg.sv                  # Register (holds fields, write/read/mirror)
│   ├── evm_reg_block.sv            # Register block (collection of registers)
│   ├── evm_reg_map.sv              # Address map (multi-block address space)
│   ├── evm_reg_predictor.sv        # RAL predictor (auto-update mirror from bus)
│   ├── evm_csr_item.sv             # CSR transaction item
│   ├── evm_csr_sequence.sv         # CSR sequence (write/read via AXI-Lite)
│   ├── evm_qc.sv                   # Quiescence Counter (auto test completion)
│   ├── evm_root.sv                 # Root singleton (phase control + objections)
│   ├── evm_base_test.sv            # Test base (QC + cmdline + objection helpers)
│   ├── evm_test_registry.sv        # Test registry (EVM_REGISTER_TEST macro)
│   ├── evm_sequence_library.sv     # Sequence library (EVM_REGISTER_SEQUENCE)
│   ├── evm_cmdline.sv              # Command-line arg parsing
│   ├── evm_assertions.sv           # Assertion macros
│   ├── evm_coverage.sv             # Coverage base
│   ├── evm_memory_model.sv         # 64-bit sparse memory model
│   ├── evm_stream_agent.sv         # Generic stream agent
│   ├── evm_stream_cfg.sv           # Stream agent config
│   ├── evm_stream_driver.sv        # Stream driver
│   ├── evm_stream_monitor.sv       # Stream monitor
│   └── evm_stream_if.sv            # Stream interface
│
├── vkit/evm_vkit/                  # ← PROTOCOL AGENTS (evm_vkit_pkg)
│   ├── evm_vkit_pkg.sv             # Package (includes all agents)
│   ├── evm_axi_lite_agent/         # AXI4-Lite master agent
│   │   ├── evm_axi_lite_txn.sv     # 7 transaction types (aw/w/b/ar/r + composite)
│   │   ├── evm_axi_lite_monitor.sv # Monitor with 7 analysis ports
│   │   ├── evm_axi_lite_driver.sv  # Driver: write/read/rmw/poll/write_check
│   │   ├── evm_axi_lite_agent.sv   # Agent: direct API + optional sequencer
│   │   ├── evm_axi_lite_cfg.sv     # Configuration struct
│   │   ├── evm_axi_lite_if.sv      # Interface
│   │   └── evm_axi_lite_reg_predictor.sv  # Concrete RAL predictors
│   ├── evm_axi4_full_agent/        # AXI4 Full burst master agent
│   │   ├── evm_axi4_full_txn.sv    # 7 transaction types
│   │   ├── evm_axi4_full_driver.sv # Driver: write/read burst
│   │   ├── evm_axi4_full_monitor.sv # Monitor: 7 analysis ports
│   │   ├── evm_axi4_full_agent.sv  # Agent
│   │   ├── evm_axi4_full_cfg.sv    # Config
│   │   └── evm_axi4_full_if.sv     # Interface
│   ├── evm_clk_agent/              # Clock agent (clk_driver generates clocks)
│   ├── evm_rst_agent/              # Reset agent (rst_driver asserts/deasserts)
│   ├── evm_adc_agent/              # ADC agent (analog sample model)
│   ├── evm_dac_agent/              # DAC agent (analog drive model)
│   ├── evm_gpio_agent/             # GPIO agent (multi-bit GPIO)
│   └── evm_pcie_agent/             # PCIe agent (stub)
│
├── docs/                           # User documentation
│   ├── QUICK_START.md
│   ├── ARCHITECTURE.md             # Phase system, run_phase, mid-sim reset
│   ├── AGENTS.md                   # All protocol agents guide
│   ├── REGISTER_MODEL.md           # RAL + predictor guide
│   ├── TEST_INFRASTRUCTURE.md      # env/registry/library guide
│   ├── EVM_LOGGING_COMPLETE_GUIDE.md
│   ├── EVM_MONITOR_SCOREBOARD_GUIDE.md
│   └── UVM_FEATURES_NOT_IMPLEMENTED.md
│
├── vkit/docs/uml/                  # Mermaid UML diagrams (6 diagrams)
│   ├── 01_core_framework.md
│   ├── 02_register_model.md
│   ├── 03_utilities.md
│   ├── 04_agents_axi_lite.md
│   ├── 05_agents_axi4_full.md
│   └── 06_tlm_sequences.md
│
├── csr_gen/                        # CSR Generator tool
│   ├── gen_csr.py                  # Python: YAML → RTL + RAL model
│   └── README.md
│
└── examples/example1/             # Complete working example
    ├── README.md
    ├── rtl/example1.sv             # DUT: AXI-Lite data transform
    ├── csr/example1.yaml           # CSR YAML spec
    ├── csr/generated/              # Generated RTL + RAL
    ├── dv/tb/tb_top.sv             # Testbench top
    ├── dv/env/                     # Environment classes
    └── dv/tests/                   # Test classes
```

---

## 🏗️ Core Classes — Every Method & Task

### `evm_log` (virtual class — base of all EVM classes)
**Source:** `vkit/src/evm_log.sv`

```systemverilog
// Logging (route through evm_report_handler singleton)
function void log_info(string msg, int level = EVM_MED);    // filtered by verbosity
function void log_warning(string msg);                       // always shown
function void log_error(string msg);                         // always shown; counted
function void log_fatal(string msg);                         // terminates simulation

// Verbosity control
static function void set_global_verbosity(int verb);  // EVM_NONE/LOW/MED/HIGH/DEBUG
function void        set_verbosity(int verb);          // instance level
function int         get_verbosity();

// Statistics (delegate to evm_report_handler)
static function int  get_error_count();
static function int  get_warning_count();
static function int  get_info_count();
static function int  get_fatal_count();
static function void reset_stats();
static function void print_summary();                  // print TEST PASSED/FAILED

// Name
virtual function string get_name();
virtual function void   set_name(string name);

// Verbosity enum (in evm_log)
EVM_NONE=0, EVM_LOW=100, EVM_MED=200, EVM_HIGH=300, EVM_DEBUG=500
```

---

### `evm_report_handler` (static singleton)
**Source:** `vkit/src/evm_report_handler.sv`

```systemverilog
// Singleton access
static function evm_report_handler get();

// Core reporting
static function void report(evm_severity_e severity, string id, string message,
                             int verbosity=EVM_MEDIUM, string filename="", int line=0,
                             string context_name="");

// Convenience wrappers
static function void evm_report_info(string id, string message, int verbosity=EVM_MEDIUM, ...);
static function void evm_report_warning(string id, string message, ...);
static function void evm_report_error(string id, string message, ...);
static function void evm_report_fatal(string id, string message, ...);

// Global functions (use anywhere without class context)
function void evm_info(string id, string message, int verbosity=EVM_MEDIUM);
function void evm_warning(string id, string message);
function void evm_error(string id, string message);
function void evm_fatal(string id, string message);

// Configuration
static function void set_verbosity(evm_verbosity_e verbosity);
static function evm_verbosity_e get_verbosity();
static function void set_stop_on_error(bit value);      // default: 0
static function void set_stop_on_warning(bit value);    // default: 0
static function void set_max_quit_count(int count);     // 0 = unlimited
static function void set_fatal_delay_ns(int delay_ns);  // default: 1000

// File logging
static function bit  enable_file_logging(string filename="evm.log");
static function void disable_file_logging();
static function bit  is_file_logging_enabled();
static function string get_log_filename();

// Statistics
static function int  get_info_count();
static function int  get_warning_count();
static function int  get_error_count();   // UNEXPECTED errors only (post P0.3)
static function int  get_fatal_count();
static function int  get_severity_count(evm_severity_e severity);
static function void reset_counts();
static function void print_summary();  // prints TEST PASSED / TEST FAILED

// Severity enum
EVM_INFO=0, EVM_WARNING=1, EVM_ERROR=2, EVM_FATAL=3

// Verbosity enum  
EVM_NONE=0, EVM_LOW=100, EVM_MEDIUM=200, EVM_HIGH=300, EVM_FULL=400, EVM_DEBUG=500
```

#### P0.3 — Expected Error / Negative Test Infrastructure
**Added:** 2026-04-23

```systemverilog
// ── Pattern-based expected error registration ────────────────────────────────
// All patterns use case-sensitive substring matching.
// Absorbed (expected) messages still displayed, tagged [EXPECTED].
// get_error_count() returns UNEXPECTED errors only after P0.3.

// Exact count: expect exactly N occurrences (default 1).
// FAIL if seen < count (expected error never happened).
// Errors beyond count pass through as unexpected (also FAIL).
static function void expect_error(string pattern, int count=1);

// Range: expect between min_count and max_count occurrences.
//   min_count=0  → optional (0 occurrences is still PASS)
//   max_count=-1 → unlimited (any count >= min_count is PASS)
static function void expect_error_range(string pattern, int min_count=0, int max_count=1);

// Optional: 0 or 1 occurrence — both OK. For ISR race conditions.
// Equivalent to: expect_error_range(pattern, 0, 1)
static function void expect_error_optional(string pattern);

// Suppress: mute all occurrences permanently, no minimum required.
// For known-noisy 3rd-party IP or startup transients.
// Equivalent to: expect_error_range(pattern, 0, -1)
static function void suppress_error(string pattern);

// Warning equivalents (same semantics):
static function void expect_warning(string pattern, int count=1);
static function void expect_warning_range(string pattern, int min_count=0, int max_count=1);
static function void expect_warning_optional(string pattern);
static function void suppress_warning(string pattern);

// Clear all registered expectations (call between test phases if needed)
static function void clear_expected();

// Query
static function int get_unexpected_error_count();   // = error_count
static function int get_unmet_expectation_count();  // > 0 → TEST FAILS

// Print expectation table (called automatically from print_summary())
static function void print_expectation_report();

// Utility: public substring search (use in evm_error_catcher derived classes)
static function bit str_contains(string haystack, string needle);

// ── evm_error_catcher (complex conditional logic) ───────────────────────────
// Register before stimulus, unregister after. Runs before pattern list.
static function void register_error_catcher(evm_error_catcher catcher);
static function void unregister_error_catcher(evm_error_catcher catcher);
```

**`evm_error_catcher`** (virtual class — defined in `evm_report_handler.sv`):
```systemverilog
// Extend to implement custom error interception logic.
// Use for: ISR races, DMA burst windows, conditional suppression.
virtual class evm_error_catcher;
    function new(string n = "evm_error_catcher");
    
    // Return 1 to absorb/suppress (won't count as failure).
    // Return 0 to let through as a real unexpected error.
    pure virtual function bit catch_error(string id, string message, string context_name);
    
    // Optional: return 1 to absorb warnings. Default: don't catch.
    virtual function bit catch_warning(string id, string message, string context_name);
    
    function string get_name();
endclass
```

**Usage patterns:**
```systemverilog
// Pattern A — Deterministic (exactly 1 expected SLVERR):
evm_report_handler::expect_error("SLVERR on write to RO");
env.agent.write(RO_ADDR, 32'hDEAD, 4'hF, resp);

// Pattern B — Race condition (ISR may clear before 2nd log — 1 or 2 OK):
evm_report_handler::expect_error_range("SLVERR", 1, 2);
trigger_fault_with_isr();

// Pattern C — Optional (might not happen at all):
evm_report_handler::expect_error_optional("startup overflow");
run_startup_sequence();

// Pattern D — Suppress noisy 3rd-party IP always:
evm_report_handler::suppress_error("PHY link warning from vendor IP");

// Pattern E — Complex conditional (catcher class):
class isr_catcher extends evm_error_catcher;
    bit   window_open = 0;
    int   caught = 0;
    virtual function bit catch_error(string id, string msg, string ctx);
        if (!window_open) return 0;
        if (caught < 3 && evm_report_handler::str_contains(msg, "SLVERR")) begin
            caught++; return 1;
        end
        return 0;
    endfunction
endclass
isr_catcher c = new("isr_c");
evm_report_handler::register_error_catcher(c);
c.window_open = 1;  // open window during active DMA
trigger_dma();
wait_dma_done();
c.window_open = 0;
evm_report_handler::unregister_error_catcher(c);
if (c.caught < 1) log_error("Expected at least 1 SLVERR during DMA");
```

**`evm_log::log_expected_error(string msg)`** (instance method, added P0.3):
```systemverilog
// Logs as WARNING with [EXPECTED] prefix — never increments error_count.
// Use when a component itself generates an expected error condition.
log_expected_error("FIFO overflow during stress test — expected");
```

**print_summary() output (P0.3):**
```
[EVM] -----------------------------------------------------------------------
[EVM] Expected Message Report:
[EVM]  Type  Pattern                                 Min    Max   Seen  Status
[EVM] -----------------------------------------------------------------------
[EVM]  ERR   SLVERR on write to RO                      1      1      1  PASS
[EVM]  ERR   SLVERR                                      1      2      1  PASS
[EVM]  ERR   startup overflow                            0      1      0  PASS
[EVM] -----------------------------------------------------------------------
[EVM] ERRORs (unexpected):       0
[EVM] ERRORs (absorbed/expected):3
[EVM] Unmet expectations:        0
[EVM] *** TEST PASSED ***
```

---

### `evm_object` (virtual class — extends evm_log)
**Source:** `vkit/src/evm_object.sv`

```systemverilog
// Type identification
virtual function string get_type_name();  // override in every class!

// Copy
virtual function void       copy(evm_object rhs);      // calls do_copy()
virtual function evm_object clone();                    // MUST override — returns null in base
virtual function void       do_copy(evm_object rhs);   // override to copy fields

// Compare
virtual function bit compare(evm_object rhs, output string msg);  // calls do_compare()
virtual function bit do_compare(evm_object rhs, output string msg);  // override for fields

// String / Print
virtual function string convert2string();  // override to describe object
virtual function string sprint();          // returns convert2string()
virtual function void   print();           // $display(convert2string())
```

---

### `evm_component` (virtual class — extends evm_object)
**Source:** `vkit/src/evm_component.sv`

```systemverilog
// Constructor — ALWAYS call super.new(name, parent)
function new(string name="evm_component", evm_component parent=null);

// Hierarchy
virtual function evm_component get_parent();
virtual function string        get_full_name();        // hierarchical: "top.env.agent.driver"
virtual function string        get_type_name();
protected function void        add_child(string name, evm_component child);
virtual function evm_component get_child(string name);
virtual function int           get_num_children();
virtual function int           get_first_child(ref string name);
virtual function int           get_next_child(ref string name);
virtual function evm_component lookup(string name);    // lookup by hierarchical name
virtual function void          print_topology(int indent=0);

// ── 12 PHASES ──────────────────────────────────────────────────────────────
// Build-time (functions):
virtual function void build_phase();                   // create children
virtual function void connect_phase();                 // make TLM connections
virtual function void end_of_elaboration_phase();      // finalize config
virtual function void start_of_simulation_phase();     // pre-sim init

// Runtime (tasks — run sequentially):
virtual task reset_phase();          // calls pre_reset() → reset() → post_reset()
  virtual task pre_reset();          //   prepare for reset (flush, save state)
  virtual task reset();              //   clear queues, reset counters
  virtual task post_reset();         //   reinitialize data structures
virtual task configure_phase();      // configure DUT after reset
virtual task main_phase();           // primary stimulus (use objections!)
virtual task shutdown_phase();       // graceful shutdown

// run_phase — PARALLEL to all runtime phases (monitors, scoreboards use this):
virtual task run_phase();            // continuous execution; fork join_none internally

// Cleanup (functions):
virtual function void extract_phase();
virtual function void check_phase();
virtual function void report_phase();
virtual function void final_phase();

// ── MID-SIMULATION RESET SUPPORT ────────────────────────────────────────────
// Events (declared in base class, triggered by assert/deassert_reset()):
protected event reset_asserted;    // -> fired when reset asserts
protected event reset_deasserted;  // -> fired when reset deasserts
protected bit   in_reset;          // status flag — check before driving

// Reset control (call from test or reset agent):
virtual function void assert_reset();    // sets in_reset=1, triggers event, propagates to children
virtual function void deassert_reset();  // triggers event, clears in_reset, propagates to children

// Reset event handlers (override in derived classes):
virtual task on_reset_assert();    // called from run_phase background thread
virtual task on_reset_deassert();  // called from run_phase background thread

// Utility
virtual function string convert2string();
virtual function void   print();
```

---

### `evm_root` (class — extends evm_component)
**Source:** `vkit/src/evm_root.sv`

```systemverilog
// Singleton
static function evm_root get();             // get or create singleton
static function evm_root init(string name); // initialize with test name

// Objection control
function void raise_objection(string description="");
function void drop_objection(string description="");
function int  get_objection_count();
task          wait_for_objections();        // blocks until count == 0

// Phase execution (called from run_all_phases_with_test)
virtual function void execute_build_phase();
virtual function void execute_connect_phase();
virtual function void execute_end_of_elaboration_phase();
virtual function void execute_start_of_simulation_phase();
virtual task          execute_reset_phase();
virtual task          execute_configure_phase();
virtual task          execute_main_phase();         // includes timeout watchdog
virtual task          execute_shutdown_phase();
virtual function void execute_extract_phase();
virtual function void execute_check_phase();
virtual function void execute_report_phase();
virtual function void execute_final_phase();

// Test runner (call from tb_top initial block)
task run_test(evm_component test);                          // direct object
task run_all_phases_with_test(evm_component test);          // runs all 12 phases
virtual task run_all_phases();                              // legacy

// Configuration
function void set_default_timeout(int timeout);  // microseconds, default=1000
// Plusarg: +EVM_TIMEOUT=<us>

// Misc
virtual function string get_type_name();
int    default_timeout_us;
string test_name;
```

---

### `evm_tlm` — TLM Classes
**Source:** `vkit/src/evm_tlm.sv`

#### `evm_analysis_port #(type T = int)`
```systemverilog
function new(string name="analysis_port", evm_component parent=null);
function void write(T t);                            // broadcasts to ALL subscribers
function void connect(mailbox#(T) subscriber);       // add subscriber mailbox
function int  size();                                // number of subscribers
```

#### `evm_analysis_imp #(type T = int)`
```systemverilog
function new(string name="analysis_imp", int fifo_size=0);  // 0 = unbounded
function mailbox#(T) get_mailbox();   // get mailbox for analysis_port.connect()
task get(output T t);                 // blocking get
function int try_get(output T t);     // non-blocking
function int num();                   // items available
```

**Connection pattern:**
```systemverilog
// In env connect_phase:
monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
```

#### `evm_seq_item_pull_port #(type REQ=int, type RSP=REQ)`
```systemverilog
function new(string name="seq_item_port", evm_component parent=null);
function void connect(mailbox#(REQ) req_fifo, mailbox#(RSP) rsp_fifo);
task     get_next_item(output REQ req);   // BLOCKING get from sequencer
task     try_next_item(output REQ req);   // non-blocking (req=null if empty)
task     item_done(input RSP rsp=RSP'(0)); // signal completion + optional response
task     peek(output REQ req);            // look without removing
function bit is_connected();
```

#### `evm_seq_item_pull_export #(type REQ=int, type RSP=REQ)`
```systemverilog
function new(string name="seq_item_export", evm_component parent=null, int fifo_size=0);
function mailbox#(REQ) get_req_fifo();    // for port.connect()
function mailbox#(RSP) get_rsp_fifo();   // for port.connect()
task     put(REQ req);                    // sequences call this to send items
function bit try_put(REQ req);            // non-blocking put
task     get_response(output RSP rsp);    // get driver response
function bit try_get_response(output RSP rsp);
function int num_pending();               // items in request FIFO
```

#### `evm_tlm_fifo #(type T = int)`
```systemverilog
function new(string name="tlm_fifo", int size=0);  // 0 = unbounded
task     put(T t);           function bit try_put(T t);
task     get(output T t);    function bit try_get(output T t);
task     peek(output T t);   function bit try_peek(output T t);
function int  num();
function bit  is_empty();
function bit  is_full();
function int  size();
function void flush();        // clear all items
```

---

### `evm_sequence_item` (virtual class — extends evm_object)
**Source:** `vkit/src/evm_sequence_item.sv`

```systemverilog
// Metadata (auto-populated by sequencer/driver)
time start_time;
time end_time;
bit  completed;
int  transaction_id;

function new(string name="evm_sequence_item");

// Timing
virtual function real get_duration();    // end - start in ns
virtual function void mark_started();
virtual function void mark_completed();

// CRV Helper [P0.1] — call randomize() with error handling + debug logging
// Returns 1 on success, 0 on failure (also logs EVM_ERROR → test FAILS)
// Usage: if (!txn.randomize_item()) return;
// For inline constraint: if (!txn.randomize() with { addr < 32'h100; }) ...
virtual function bit randomize_item();

// Must implement in derived classes:
pure virtual function string convert2string();
```

---

### `evm_sequence` (virtual class — extends evm_object)
**Source:** `vkit/src/evm_sequence.sv`

```systemverilog
evm_sequence_item items[$];
int item_count;

function new(string name="evm_sequence");
virtual function void add_item(evm_sequence_item item);
virtual function void clear_items();
virtual function int  get_item_count();
virtual task          execute();           // override in derived class
virtual function string convert2string();
```

---

### `evm_rand_sequence` (virtual class — extends evm_sequence) [P0.1]
**Source:** `vkit/src/evm_rand_sequence.sv`  
**Added:** 2026-04-24 — Constrained Random Verification base class

```systemverilog
function new(string name="evm_rand_sequence");

// execute(): logs seed, then calls body(). ALWAYS call super.execute() if overriding.
virtual task execute();

// body(): override this in derived classes — put stimulus here
// Preferred override point (execute() calls body() for you)
virtual task body();

// log_crv_seed(): logs active seed at EVM_LOW — call manually if you override execute()
// Output: [CRV] Sequence 'my_seq' running — to replay: +evm_seed=12345
virtual function void log_crv_seed();

virtual function string get_type_name();
```

**CRV sequence pattern (preferred — override body()):**
```systemverilog
class my_rand_write_seq extends evm_rand_sequence;
    virtual task body();
        my_axi_txn txn;
        repeat (50) begin
            txn = new("txn");
            if (!txn.randomize_item()) return;   // auto-error + FAIL on bad constraints
            add_item(txn);
        end
    endtask
endclass
```

**CRV transaction pattern (declare rand fields + constraints):**
```systemverilog
class my_axi_txn extends evm_sequence_item;
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic [3:0]  strb;
    
    constraint c_aligned { addr[1:0] == 2'b00; }          // 32-bit aligned
    constraint c_strb    { strb inside {4'hF, 4'h3, 4'hC, 4'h1}; }
    constraint c_nonzero { data != 0; }
    
    virtual function string convert2string();
        return $sformatf("addr=0x%08x data=0x%08x strb=0x%x", addr, data, strb);
    endfunction
endclass
```

**Seed management:**
- Call `evm_cmdline::set_random_seed()` from `build_phase` or `tb_top` initial block once
- `+evm_seed=<N>` sets a deterministic seed; if absent, a random seed is auto-generated
- The seed is **cached** after first resolution — consistent across all `get_seed()` calls
- Every `evm_rand_sequence::execute()` logs the seed for replay

**CRV replay workflow:**
```
# Failed run log shows:
# [EVM CRV] Random seed: 847329  (replay: +evm_seed=847329)
# [CRV] Sequence 'my_rand_seq' running — to replay: +evm_seed=847329

# Replay the exact failure:
+evm_seed=847329
```

---

### `evm_virtual_sequence` (virtual) + `evm_virtual_sequencer`
**Source:** `vkit/src/evm_virtual_sequence.sv`

```systemverilog
// evm_virtual_sequencer (holds references to sub-sequencers)
class evm_virtual_sequencer extends evm_component;
    // Add your sub-sequencer handles as public fields:
    // my_sequencer axi_seqr;
    // my_sequencer apb_seqr;

// evm_virtual_sequence (coordinates multiple sequencers)
class evm_virtual_sequence extends evm_sequence;
    evm_virtual_sequencer v_sequencer;
    
    virtual task start(evm_virtual_sequencer sequencer);
    // Raises objection, calls body(), drops objection
    
    virtual task body();  // OVERRIDE THIS — implement stimulus coordination
    // Example pattern:
    // fork
    //   begin seqA = new(); seqA.execute(); end
    //   begin seqB = new(); seqB.execute(); end
    // join
```

---

### `evm_sequencer #(REQ, RSP=REQ)` (extends evm_component)
**Source:** `vkit/src/evm_sequencer.sv`

```systemverilog
evm_seq_item_pull_export#(REQ, RSP) seq_item_export;  // driver connects here
mailbox#(evm_sequence_item) item_mbx;                  // legacy mailbox

int items_sent;
int items_completed;

function new(string name="evm_sequencer", evm_component parent=null);

// run_phase: monitors reset events; flushes FIFOs on reset_asserted
virtual task run_phase();
virtual task on_reset_assert();    // flush req/rsp FIFOs + legacy mailbox
virtual task on_reset_deassert();  // ready for new sequences

// Item management (legacy API)
virtual task send_item(evm_sequence_item item);          // put item in mailbox
virtual task get_next_item(output evm_sequence_item item); // get from mailbox
virtual function void item_done(evm_sequence_item item); // mark completed

// Sequence execution
virtual task execute_sequence(evm_sequence seq);  // iterates seq.items[], calls send_item()

virtual function void report_phase();  // prints stats
```

---

### `evm_driver #(VIF, REQ=int, RSP=REQ)` (virtual — extends evm_component)
**Source:** `vkit/src/evm_driver.sv`

```systemverilog
VIF vif;
evm_seq_item_pull_port#(REQ, RSP) seq_item_port;

function new(string name="evm_driver", evm_component parent=null);
function void set_vif(VIF vif_handle);

// run_phase: launches background thread monitoring reset_asserted/reset_deasserted
virtual task run_phase();

// main_phase: override to drive stimulus
// Pattern:
//   forever begin
//     if (!in_reset) begin
//       seq_item_port.get_next_item(req);
//       drive_transaction(req);
//       seq_item_port.item_done();
//     end else @(reset_deasserted);
//   end
virtual task main_phase();

// Reset handlers (override in derived drivers)
virtual task on_reset_assert();    // deassert outputs, idle bus
virtual task on_reset_deassert();  // reinitialize bus, prepare to drive

virtual function string get_type_name();
```

---

### `evm_monitor #(VIF, T=int)` (virtual — extends evm_component)
**Source:** `vkit/src/evm_monitor.sv`

```systemverilog
VIF vif;
evm_analysis_port#(T) analysis_port;  // broadcast collected transactions

function new(string name="evm_monitor", evm_component parent=null);
function void set_vif(VIF vif_handle);

// run_phase: forks reset event monitor + continuous collection loop
// Override to add collection logic inside the fork
virtual task run_phase();

// Reset handlers (override in derived monitors)
virtual task on_reset_assert();    // pause collection, flush partial transactions
virtual task on_reset_deassert();  // resume collection

virtual function string get_type_name();
```

---

### `evm_agent #(VIF, T=int)` (virtual — extends evm_component)
**Source:** `vkit/src/evm_agent.sv`

```systemverilog
typedef enum { EVM_PASSIVE, EVM_ACTIVE } evm_agent_mode_e;

evm_agent_mode_e           mode;       // EVM_ACTIVE (default) or EVM_PASSIVE
evm_monitor#(VIF, T)       monitor;    // always created
evm_driver#(VIF, T, T)     driver;     // only in ACTIVE mode
evm_sequencer#(T, T)       sequencer;  // only in ACTIVE mode
VIF                        vif;

function new(string name="evm_agent", evm_component parent=null);

// Set VIF — propagates to driver + monitor
function void set_vif(VIF vif_handle);

// build_phase: creates monitor (always) + driver+sequencer (if ACTIVE)
// Calls create_monitor() and create_driver() — OVERRIDE THESE
virtual function void build_phase();

// connect_phase: connects driver.seq_item_port → sequencer.seq_item_export
virtual function void connect_phase();

// run_phase: validates VIF is set (fatal if null)
virtual task run_phase();

// Factory methods — MUST override in derived agents:
virtual function evm_monitor#(VIF, T)   create_monitor(string name);  // return your monitor
virtual function evm_driver#(VIF, T, T) create_driver(string name);   // return your driver
virtual function evm_sequencer#(T, T)   create_sequencer(string name); // default OK

// Mode control
function void             set_mode(evm_agent_mode_e new_mode);
function evm_agent_mode_e get_mode();
function bit              is_active();   // returns 1 if EVM_ACTIVE
```

---

### `evm_scoreboard #(type T=int)` (extends evm_component)
**Source:** `vkit/src/evm_scoreboard.sv`

```systemverilog
typedef enum { EVM_SB_FIFO, EVM_SB_ASSOCIATIVE, EVM_SB_UNORDERED } evm_scoreboard_mode_e;

evm_analysis_imp#(T) analysis_imp;   // connect to monitor.analysis_port

// Configuration
evm_scoreboard_mode_e mode = EVM_SB_FIFO;
bit enable_auto_check = 1;            // auto-compare when actual arrives
bit stop_on_mismatch = 0;            // $stop on first mismatch
int max_expected_queue_size = 1000;

// Statistics
int match_count, mismatch_count, expected_count, actual_count;
int orphan_expected, orphan_actual;

function new(string name="evm_scoreboard", evm_component parent=null);

// Queue management
function void insert_expected(T item);
function void insert_actual(T item);   // auto-check if enable_auto_check=1

// Check
function bit check_transaction(T actual);
virtual function bit compare_transactions(T expected, T actual);   // override for custom compare
virtual function int find_matching_expected(T actual);             // override for ASSOCIATIVE mode
function int find_exact_match(T actual);
function void check_all();    // check all deferred actuals

// run_phase: continuously reads analysis_imp + monitors reset events
virtual task run_phase();

// Reset handlers
virtual task on_reset_assert();    // flush expected + actual queues
virtual task on_reset_deassert();

// Reset phase handlers
virtual task pre_reset();
virtual task reset();              // clear queues + reset all statistics
virtual task post_reset();

// final_phase: prints report, calls log_error if failures
virtual function void final_phase();
function void print_report();

// Utility
function void clear();
function int  get_expected_size();
function int  get_actual_size();
```

---

### `evm_env` (virtual class — extends evm_component)
**Source:** `vkit/src/evm_env.sv`

```systemverilog
function new(string name="evm_env", evm_component parent=null);

// end_of_elaboration_phase: automatically prints component topology
// Override and call super first to preserve this behavior
virtual function void end_of_elaboration_phase();

virtual function string get_type_name();
```

---

### `evm_base_test` (virtual class — extends evm_component)
**Source:** `vkit/src/evm_base_test.sv`

```systemverilog
string test_name;
evm_qc qc;             // quiescence counter (if enabled)
bit    enable_qc = 0;
int    qc_threshold = 100;

function new(string name="evm_base_test");

// build_phase: processes cmdline args + creates qc if enable_qc=1
virtual function void build_phase();
virtual function void process_cmdline_args();  // verbosity, log file, seed

// Objection convenience (delegates to evm_root::get())
function void raise_objection(string description="");
function void drop_objection(string description="");

// Quiescence counter control (call in constructor or before build_phase)
function void enable_quiescence_counter(int threshold=100);
function void disable_quiescence_counter();
function evm_qc get_qc();
function bit is_qc_enabled();

// main_phase: default raises objection, waits 50us, drops objection
// OVERRIDE in your test
virtual task main_phase();

// report_phase: prints test name + error/warning count + PASSED/FAILED
virtual function void report_phase();

function bit    get_test_result();  // 1=pass, 0=fail
virtual function string get_type_name();

// Plusargs processed in process_cmdline_args:
// +evm_verbosity=<NONE|LOW|MEDIUM|HIGH|FULL|DEBUG>
// +evm_log=<filename>  or  +log=<filename>
// +evm_seed=<int>
// +evm_debug  (prints all cmdline args)
```

---

### `evm_qc` — Quiescence Counter (extends evm_component)
**Source:** `vkit/src/evm_qc.sv`  
**Unique EVM feature — no UVM equivalent**

```systemverilog
int quiescent_cycles = 100;   // cycles of inactivity before test ends
string objection_name = "qc";

// Statistics
int total_ticks;
int max_counter_value;

function new(string name="qc", evm_component parent=null);

// Called by drivers/monitors on each transaction — resets inactivity counter
// Automatically raises objection on first tick
function void tick();

// Configuration
function void set_threshold(int cycles);
function int  get_threshold();
function void enable();
function void set_disabled();  // 'disable' is SV keyword
function bit  is_enabled();
function bit  is_active();     // 1 if objection is raised
function int  get_counter();   // current inactivity count

// reset(): drops objection, resets counters
virtual task reset();

// main_phase: counts inactive cycles; drops objection after threshold
// Uses #1ns per cycle — TODO: configurable clock edge
virtual task main_phase();

virtual function void report_phase();  // prints QC statistics
```

**Usage pattern:**
```systemverilog
// In test constructor:
enable_quiescence_counter(200);  // 200 cycle inactivity threshold

// In connect_phase:
env.agent.driver.set_qc(qc);
env.agent.monitor.set_qc(qc);

// In driver/monitor — signal activity:
if (qc != null) qc.tick();
// Test ends automatically when system goes quiet for 200 cycles
```

---

### `evm_test_registry` — Test Registry
**Source:** `vkit/src/evm_test_registry.sv`

```systemverilog
// Registration (call via macro at module/package scope)
static function void register(string name, evm_test_creator creator);

// Creation
static function evm_base_test create_test(string name);  // null if not found
static function bit            test_exists(string name);
static function int            get_test_count();
static function void           list_tests();              // logs all registered

// Macro (place after test class definition, at module/package scope):
`EVM_REGISTER_TEST(my_test_class_name)

// Plusargs:
// +EVM_TESTNAME=<registered_name>   — select test from command line
// +EVM_LIST_TESTS                   — print all registered tests

// In tb_top:
initial begin
    string testname;
    evm_base_test test;
    if ($value$plusargs("EVM_TESTNAME=%s", testname)) begin
        test = evm_test_registry::create_test(testname);
        evm_root::get().run_test(test);
    end
end
```

---

### `evm_sequence_library` — Sequence Library
**Source:** `vkit/src/evm_sequence_library.sv`

```systemverilog
typedef enum { SEQ_RANDOM, SEQ_ROUND_ROBIN } evm_seq_select_e;

int sequences_run;
evm_seq_select_e selection_mode = SEQ_RANDOM;

function new(string name="evm_sequence_library");

// Static global registry
static function void         register(string name, evm_sequence_creator creator);
static function evm_sequence create_sequence(string name);  // null if not found
static function void         list_all();                     // log all registered

// Instance control
function void enable_sequence(string name);  // use subset of global registry
function void enable_all();                  // use all registered (default)
function bit  sequence_exists(string name);

// Running
task run_sequence(string name, evm_sequencer sqr);
task run_random(evm_sequencer sqr);           // random or round-robin
task run_all(evm_sequencer sqr);              // run all enabled
task run_from_plusarg(evm_sequencer sqr);     // uses +EVM_SEQ=<name>

// Macro (place after sequence class definition, at module/package scope):
`EVM_REGISTER_SEQUENCE(my_sequence_class_name)

// Plusargs:
// +EVM_SEQ=<registered_name>  — run specific sequence via run_from_plusarg()
```

---

### `evm_coverage` + `evm_coverage_db` — Functional Coverage [P0.2]
**Source:** `vkit/src/evm_coverage.sv`  
**Added:** 2026-04-24

```systemverilog
// ── evm_coverage — virtual base class ───────────────────────────────────────
// Extend this, declare covergroups in the constructor, override sample() and
// get_coverage(). Register with evm_coverage_db::register(this) in build_phase.

virtual class evm_coverage extends evm_component;
    real coverage_target;      // minimum % for PASS (0 = no check, default)
    
    function new(string name, evm_component parent);
    
    virtual function void set_coverage_enable(bit enable);
    function void         set_target(real pct);   // e.g. 90.0 = require 90%
    function real         get_target();
    
    // Override these two in derived class:
    virtual function void sample();         // call your_cg.sample() inside
    virtual function real get_coverage();   // return your_cg.get_inst_coverage()
    
    // report_phase: prints coverage% + PASS/FAIL vs target;
    //               logs EVM_ERROR if below target (→ test FAILS)
    virtual function void report_phase();
endclass

// ── evm_coverage_collector#(T) — TLM-connected collector ────────────────────
// Receives transactions via analysis_imp, calls write() for each.
// Connection: monitor.analysis_port.connect(cov.analysis_imp.get_mailbox());

virtual class evm_coverage_collector#(type T = evm_sequence_item) extends evm_coverage;
    evm_analysis_imp#(T) analysis_imp;  // connect to monitor
    
    function new(string name, evm_component parent);
    virtual task          main_phase();      // background: calls write() on each txn
    virtual function void write(T txn);      // override: update cg inputs, call sample()
endclass

// ── evm_coverage_db — global registry ───────────────────────────────────────
// Static singleton. Register all models; evm_base_test auto-calls print_summary().

class evm_coverage_db;
    static function void register(evm_coverage cov);     // call in build_phase
    static function real get_total_coverage();            // average across all models
    static function bit  check_all_targets();             // 0 = any model below target
    static function void print_summary();                 // table with targets + PASS/FAIL
    // [P0.2] write per-run CSV for evm_cov_merge.py
    static function void write_log(string testname, string filename);
endclass
```

**Full usage pattern:**
```systemverilog
// 1. Define coverage model:
class my_axi_cov extends evm_coverage;
    evm_axi_lite_write_txn last_txn;  // set by monitor before calling sample()
    
    covergroup axi_write_cg;
        addr_cp: coverpoint last_txn.addr[15:12] {
            bins low  = {[0:3]};
            bins mid  = {[4:11]};
            bins high = {[12:15]};
        }
        strb_cp: coverpoint last_txn.strb {
            bins full    = {4'hF};
            bins partial = {4'h1, 4'h3, 4'hC};
        }
        cross addr_cp, strb_cp;
    endgroup
    
    function new(string name, evm_component parent);
        super.new(name, parent);
        axi_write_cg = new();
        set_target(90.0);   // require 90% for PASS
    endfunction
    
    virtual function void sample();
        if (!coverage_enabled) return;
        sample_count++;
        axi_write_cg.sample();
    endfunction
    
    virtual function real get_coverage();
        return axi_write_cg.get_inst_coverage();
    endfunction
endclass

// 2. In env build_phase:
cov = new("axi_cov", this);
evm_coverage_db::register(cov);   // ← required

// 3. In monitor run_phase (or directly in env connect_phase with collector):
cov.last_txn = collected_txn;
cov.sample();

// 4. evm_base_test.report_phase() auto-calls evm_coverage_db::print_summary()
//    and check_all_targets() — no additional test code needed.
```

**Regression workflow (two-layer):**
```
# Layer 1 — per-run EVM reporting (happens automatically):
# [COV] env.monitor.axi_cov   87.5%  BELOW TARGET (90.0%)

# Layer 2a — EVM text merge (fast CI/CD gate):
# Each run: +evm_cov_log=basic_write.evm_cov
python evm-sv/python/evm_cov_merge.py *.evm_cov --threshold 90.0
# Exit 0 = PASS, Exit 1 = FAIL (any model below target)

# Layer 2b — Simulator-native bin-level merge (signoff):
# Questa: vcover merge merged.ucdb *.ucdb
# VCS:    urg -dir *.vdb -report merged_cov
```

**Plusargs:**
- `+evm_cov_log=<file>` — write per-run CSV (handled by `evm_base_test.report_phase()`)
- If no filename given: defaults to `<testname>.evm_cov`

---

## 📊 Register Model (RAL)

### `evm_reg_field` (extends evm_object)
**Source:** `vkit/src/evm_reg_field.sv`

```systemverilog
// Access types
typedef enum { EVM_REG_RW, EVM_REG_RO, EVM_REG_WO, EVM_REG_RC, EVM_REG_RS,
               EVM_REG_WC, EVM_REG_WS, EVM_REG_W1C, EVM_REG_W1S } evm_reg_access_e;

function new(string name, int lsb, int size, evm_reg_access_e access=EVM_REG_RW,
             bit [63:0] reset=0, bit is_volatile=0);

// Value
virtual function bit [63:0] get();                          // mirrored value
virtual function void       set(bit [63:0] value);          // set mirror (no bus access)
virtual function void       reset(string kind="HARD");       // restore reset value
virtual function void       predict(bit [63:0] write_value, bit is_read);  // update mirror

// Properties
function int             get_lsb_pos();
function int             get_msb_pos();
function int             get_size();
function bit [63:0]      get_mask();                         // mask for this field in register
function evm_reg_access_e get_access();
function bit             is_volatile();
function bit             is_readable();    // false if WO
function bit             is_writable();    // false if RO
```

### `evm_reg` (extends evm_object)
**Source:** `vkit/src/evm_reg.sv`

```systemverilog
function new(string name, bit [63:0] addr, int n_bits=32);

// Configuration
function void   set_parent(evm_reg_block parent);
function void   set_agent(evm_component agent);
function bit [63:0] get_address();
function int    get_n_bits();

// Field management
virtual function void       add_field(evm_reg_field field);
virtual function evm_reg_field get_field_by_name(string name);
virtual function void       get_fields(ref evm_reg_field field_list[$]);

// Mirror value assembly
virtual function bit [63:0] get();               // assemble from all fields
virtual function void       set(bit [63:0] value);  // distribute to all fields
virtual function void       reset(string kind="HARD");
virtual function void       predict(bit [63:0] value, bit is_read);  // update mirror

// Bus access (require agent to be set)
virtual task write(bit [63:0] value, output bit status);
virtual task read(output bit [63:0] value, output bit status);
virtual task read_check(bit [63:0] expected, bit [63:0] mask='1, output bit status);
virtual task mirror(output bit status);   // read + compare with mirrored value
```

### `evm_reg_block` (extends evm_object)
**Source:** `vkit/src/evm_reg_block.sv`

```systemverilog
function new(string name, bit [63:0] base_addr=0);

// Configuration
function void   set_agent(evm_component agent);  // applies to all regs
function bit [63:0] get_base_address();

// Register management
virtual function void    add_reg(evm_reg csr);               // 'csr' avoids SV 'reg' keyword
virtual function evm_reg get_reg_by_name(string name);
virtual function evm_reg get_reg_by_address(bit [63:0] addr);
virtual function void    get_registers(ref evm_reg reg_list[$]);

// Operations
virtual function void reset(string kind="HARD");
virtual task write_reg(string reg_name, bit [63:0] value, output bit status);
virtual task read_reg(string reg_name, output bit [63:0] value, output bit status);
virtual task read_check_reg(string reg_name, bit [63:0] expected, bit [63:0] mask='1, output bit status);
virtual task mirror(output bit status);     // mirror all registers
virtual task write_all(output bit status);  // write all regs with current mirror values
virtual task read_all(output bit status);   // read all registers
virtual function void dump();               // log all register values
```

### `evm_reg_map` (extends evm_object)
**Source:** `vkit/src/evm_reg_map.sv`

```systemverilog
function new(string name="evm_reg_map", bit [63:0] base_addr=0);

// Add register blocks
function void add_reg_block(string name, evm_reg_block blk, bit [63:0] offset=0);

// Agent assignment (propagates to all blocks)
function void       set_agent(evm_component agent);
function evm_component get_agent();

// Lookup
function evm_reg_block get_block(string name);
function evm_reg       get_reg_by_address(bit [63:0] abs_addr);  // searches all blocks
function evm_reg       get_reg_by_name(string reg_name);          // searches all blocks
function bit [63:0]    get_base_address();
function int           get_block_count();

// Operations
function void reset(string kind="HARD");
function void dump();
```

### `evm_reg_predictor #(TXN)` (virtual — extends evm_component)
**Source:** `vkit/src/evm_reg_predictor.sv`

```systemverilog
evm_analysis_imp#(TXN) analysis_imp;  // connect monitor.ap_write here
evm_reg_map reg_map;                   // MUST set before simulation
bit check_reads = 0;                   // validate reads against mirror
bit verbose = 0;

// Statistics
int write_predictions, read_checks, read_mismatches, unknown_addr;

function new(string name="evm_reg_predictor", evm_component parent=null);

// MUST implement these three pure virtual methods in derived class:
pure virtual function bit [63:0] get_addr(TXN txn);  // extract address
pure virtual function bit [63:0] get_data(TXN txn);  // extract data
pure virtual function bit        is_write(TXN txn);   // 1=write, 0=read

// run_phase: receives transactions, calls process_txn(), handles reset
virtual task run_phase();
virtual function void process_txn(TXN txn);  // update mirror or check read data

// Reset handlers
virtual task on_reset_assert();    // resets register map mirror to power-on values
virtual task on_reset_deassert();

virtual function void report_phase();
```

**Concrete predictor example:**
```systemverilog
class my_axi_write_predictor extends evm_reg_predictor#(evm_axi_lite_write_txn);
    virtual function bit [63:0] get_addr(evm_axi_lite_write_txn t); return t.addr; endfunction
    virtual function bit [63:0] get_data(evm_axi_lite_write_txn t); return t.data; endfunction
    virtual function bit        is_write(evm_axi_lite_write_txn t); return 1; endfunction
endclass
// Note: evm_axi_lite_reg_predictor in vkit/evm_vkit already provides this!
```

---

## 📡 Protocol Agents (evm_vkit)

### AXI4-Lite Master Agent (`evm_axi_lite_master_agent`)
**Source:** `vkit/evm_vkit/evm_axi_lite_agent/`

```systemverilog
// Transaction types (7)
evm_axi_lite_aw_txn     // AW channel handshake: .addr, .prot, .time_ns
evm_axi_lite_w_txn      // W  channel handshake: .data, .strb, .time_ns
evm_axi_lite_b_txn      // B  channel handshake: .resp, .time_ns, .is_okay()
evm_axi_lite_ar_txn     // AR channel handshake: .addr, .prot, .time_ns
evm_axi_lite_r_txn      // R  channel handshake: .data, .resp, .time_ns, .is_okay()
evm_axi_lite_write_txn  // COMPOSITE: .addr .data .strb .prot .resp, .get_write_latency(), .is_okay()
evm_axi_lite_read_txn   // COMPOSITE: .addr .data .prot .resp, .get_read_latency(), .is_okay()

// Monitor analysis ports (7)
monitor.ap_aw    // evm_analysis_port#(evm_axi_lite_aw_txn)
monitor.ap_w     // evm_analysis_port#(evm_axi_lite_w_txn)
monitor.ap_b     // evm_analysis_port#(evm_axi_lite_b_txn)
monitor.ap_ar    // evm_analysis_port#(evm_axi_lite_ar_txn)
monitor.ap_r     // evm_analysis_port#(evm_axi_lite_r_txn)
monitor.ap_write // evm_analysis_port#(evm_axi_lite_write_txn) ← use for scoreboard/predictor
monitor.ap_read  // evm_analysis_port#(evm_axi_lite_read_txn)  ← use for scoreboard

// Direct API (most common usage):
task write(input logic [31:0] addr, input logic [31:0] data,
           input logic [3:0] strb=4'b1111, output logic [1:0] resp);
task read(input logic [31:0] addr, output logic [31:0] data, output logic [1:0] resp);
task write_check(input logic [31:0] addr, input logic [31:0] data, input logic [3:0] strb=4'b1111);
task read_check(input logic [31:0] addr, output logic [31:0] data);
task rmw(input logic [31:0] addr, input logic [31:0] mask, input logic [31:0] value);
task poll(input logic [31:0] addr, input logic [31:0] mask, input logic [31:0] expected,
          input int timeout_cycles=1000, output bit success);

// Configuration (evm_axi_lite_cfg)
cfg.use_sequencer = 0;  // enable sequencer-based driving
```

### AXI4 Full Master Agent (`evm_axi4_full_master_agent`)
**Source:** `vkit/evm_vkit/evm_axi4_full_agent/`

```systemverilog
// Same 7-port pattern as AXI-Lite but with burst support
// Transaction types include ARLEN, ARSIZE, ARBURST, ARADDR for full AXI4
// Driver supports write/read burst transactions
```

### Other Protocol Agents
```
evm_clk_agent    — clock generation; cfg: frequency, duty cycle
evm_rst_agent    — reset assertion/deassertion control
evm_adc_agent    — analog-to-digital: sample model (passive monitor)
evm_dac_agent    — digital-to-analog: drive model (active driver)
evm_gpio_agent   — multi-bit GPIO: drive or monitor pin state
evm_pcie_agent   — PCIe stub (placeholder for future)
```

---

## 🎯 Critical Coding Patterns

### 1. Always Call super First!
```systemverilog
virtual function void build_phase();
    super.build_phase();  // ← FIRST, every time, every phase
    monitor = new("monitor", this);
    driver  = new("driver",  this);
endfunction
```

### 2. Test Pattern (Manual Objections)
```systemverilog
class my_test extends evm_base_test;
    my_env env;
    
    function new(string name);
        super.new(name);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        evm_report_handler::enable_file_logging("test.log");
        evm_report_handler::set_verbosity(EVM_MEDIUM);
        env = new("env", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        env.agent.set_vif(tb_top.axi_vif);  // direct VIF — no config_db!
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("my_test");
        // ... stimulus ...
        drop_objection("my_test");
    endtask
    
    virtual function void final_phase();
        super.final_phase();
        evm_report_handler::print_summary();
    endfunction
endclass
`EVM_REGISTER_TEST(my_test)
```

### 3. Test Pattern (Quiescence Counter — Recommended)
```systemverilog
class my_test extends evm_base_test;
    function new(string name);
        super.new(name);
        enable_quiescence_counter(200);  // 200-cycle inactivity threshold
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        env.agent.set_vif(tb_top.axi_vif);
        env.agent.driver.set_qc(qc);    // give QC handle to driver
        env.agent.monitor.set_qc(qc);   // give QC handle to monitor
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        // NO manual objections! QC manages them automatically
        run_sequences();
    endtask
endclass
```

### 4. Agent Pattern
```systemverilog
class my_agent extends evm_agent#(virtual my_if, my_txn);
    
    virtual function evm_monitor#(virtual my_if, my_txn) create_monitor(string name);
        return new(name, this);  // your typed monitor
    endfunction
    
    virtual function evm_driver#(virtual my_if, my_txn, my_txn) create_driver(string name);
        return new(name, this);  // your typed driver
    endfunction
    
    // set_vif() is inherited — automatically propagates to driver + monitor
endclass
```

### 5. Environment TLM Connection Pattern
```systemverilog
virtual function void connect_phase();
    super.connect_phase();
    // Monitor → Scoreboard
    agent.monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
    
    // Monitor → RAL Predictor
    agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
    predictor.reg_map = reg_map_handle;
endfunction
```

### 6. Run Phase Pattern (Monitors/Scoreboards)
```systemverilog
// Monitors and scoreboards use run_phase — runs PARALLEL to sequential phases
virtual task run_phase();
    super.run_phase();
    fork
        begin
            // Reset event monitoring (EVM pattern)
            forever begin
                @(reset_asserted);
                on_reset_assert();
                @(reset_deasserted);
                on_reset_deassert();
            end
        end
        begin
            // Main work loop
            forever begin
                if (!in_reset) begin
                    collect_transaction();
                end else @(reset_deasserted);
            end
        end
    join_none
endtask
```

### 7. Scoreboard Integration
```systemverilog
// 3 modes:
EVM_SB_FIFO        // strict order — default
EVM_SB_ASSOCIATIVE // match by key — override find_matching_expected()
EVM_SB_UNORDERED   // match any — uses == comparison

// Custom compare:
virtual function bit compare_transactions(T expected, T actual);
    my_txn e, a;
    $cast(e, expected); $cast(a, actual);
    if (e.data !== a.data) begin
        log_error($sformatf("Data mismatch: exp=0x%08x got=0x%08x", e.data, a.data));
        return 0;
    end
    return 1;
endfunction
```

---

## 🔬 CSR Generator

**Tool:** `csr_gen/gen_csr.py`  
**Input:** YAML file (see `examples/example1/csr/example1.yaml`)  
**Output:** Two files per register block:
- `*_rtl.sv` — synthesizable RTL register implementation
- `*_reg_model.sv` — EVM RAL model (extends `evm_reg_block`)

**YAML format:**
```yaml
name: my_block
base_addr: 0x0000_0000
registers:
  - name: CTRL
    offset: 0x00
    fields:
      - name: ENABLE
        bits: "0"
        access: RW
        reset: 0
      - name: MODE
        bits: "2:1"
        access: RW
        reset: 0
```

---

## ⚡ Simulation Plusargs

| Plusarg | Effect |
|---------|--------|
| `+EVM_TESTNAME=<name>` | Select test from registry |
| `+EVM_LIST_TESTS` | Print all registered tests |
| `+EVM_SEQ=<name>` | Select sequence via `run_from_plusarg()` |
| `+EVM_TIMEOUT=<us>` | Override simulation timeout (microseconds) |
| `+evm_verbosity=<level>` | Set verbosity (NONE/LOW/MEDIUM/HIGH/FULL/DEBUG) |
| `+evm_log=<file>` | Enable file logging to specified file |
| `+evm_seed=<int>` | Set random seed |
| `+evm_debug` | Print all command-line args |

---

## ✅ What Is Complete

| Feature | Status | File |
|---------|--------|------|
| Core infrastructure (object/component/root) | ✅ | vkit/src/ |
| 12-phase system + run_phase | ✅ | evm_component.sv, evm_root.sv |
| Mid-simulation reset support | ✅ | evm_component.sv + all agents |
| TLM 1.0 (analysis + seq_item) | ✅ | evm_tlm.sv |
| Agent/Driver/Monitor/Sequencer | ✅ | vkit/src/ |
| Scoreboard (3 modes) | ✅ | evm_scoreboard.sv |
| Register Model (RAL) | ✅ | evm_reg*.sv |
| Register Map | ✅ | evm_reg_map.sv |
| RAL Predictor | ✅ | evm_reg_predictor.sv |
| Quiescence Counter | ✅ | evm_qc.sv |
| Report Handler + File Logging | ✅ | evm_report_handler.sv |
| Test Registry (+EVM_TESTNAME) | ✅ | evm_test_registry.sv |
| Sequence Library (+EVM_SEQ) | ✅ | evm_sequence_library.sv |
| Virtual Sequences | ✅ | evm_virtual_sequence.sv |
| AXI4-Lite Agent (7 ports) | ✅ | evm_axi_lite_agent/ |
| AXI4-Full Burst Agent | ✅ | evm_axi4_full_agent/ |
| CLK/RST/ADC/DAC/GPIO agents | ✅ | evm_vkit/ |
| CSR Generator (YAML→RTL+RAL) | ✅ | csr_gen/gen_csr.py |
| Example 1 (AXI-Lite DUT) | ✅ | examples/example1/ |
