# EVM Test Infrastructure

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

This document covers the test infrastructure components:
- **`evm_env`** — the environment base class
- **`evm_test_registry`** — named test selection via `+EVM_TESTNAME`
- **`evm_sequence_library`** — named sequence registry and runner

---

## evm_env — Environment Base Class

`evm_env` is the layer between your test and your agents. It automatically prints the component topology at `end_of_elaboration_phase()`, saving you a `print_topology()` call.

### Why use evm_env?

```
Without env:  test → agents (flat)
With env:     test → env → agents (properly layered, easier to reuse)
```

A properly layered environment can be reused across multiple tests without modification.

### Usage

```systemverilog
// my_env.sv
class my_env extends evm_env;
    evm_axi_lite_master_agent   csr_agent;
    evm_axi4_full_master_agent  dma_agent;
    evm_scoreboard#(my_dma_txn) scoreboard;
    doorbell_reg_model          ral;
    evm_reg_map                 reg_map;
    evm_axi_lite_write_predictor predictor;
    
    function new(string name = "my_env", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();  // prints topology automatically
        csr_agent  = new("csr_agent",  this);
        dma_agent  = new("dma_agent",  this);
        scoreboard = new("scoreboard", this);
        ral        = new("ral");
        reg_map    = new("reg_map", 32'h0);
        predictor  = new("predictor",  this);
        reg_map.add_reg_block("doorbell", ral, 0);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        reg_map.set_agent(csr_agent);
        predictor.reg_map = reg_map;
        csr_agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
        dma_agent.monitor.ap_write.connect(scoreboard.analysis_imp.get_mailbox());
    endfunction
endclass

// In test:
class my_test extends evm_base_test;
    my_env env;
    
    virtual function void build_phase();
        super.build_phase();
        env = new("env", this);
        env.csr_agent.set_vif(csr_vif);
        env.dma_agent.set_vif(dma_vif);
    endfunction
endclass
```

### What evm_env provides

- `end_of_elaboration_phase()` — calls `print_topology()` automatically
- `get_type_name()` returns `"evm_env"` for topology display
- Inherits all `evm_component` phases and reset infrastructure

---

## evm_test_registry — Named Test Selection

Allows running any registered test by name without recompiling, controlled by the `+EVM_TESTNAME` plusarg.

### Registration (once per test, at module/package scope)

```systemverilog
// my_tests.sv (after your test class definitions)

class basic_test extends evm_base_test;
    // ...
endclass
`EVM_REGISTER_TEST(basic_test)       // ← registers by name "basic_test"

class stress_test extends evm_base_test;
    // ...
endclass
`EVM_REGISTER_TEST(stress_test)

class reset_test extends evm_base_test;
    // ...
endclass
`EVM_REGISTER_TEST(reset_test)
```

The macro creates a zero-overhead initial block that registers the test at time 0.

### tb_top usage

```systemverilog
// tb_top.sv
initial begin
    // Set up interfaces...
    evm_root::get().run_test_by_name();   // reads +EVM_TESTNAME
end
```

### Running tests

```bash
# Run a specific test
./sim +EVM_TESTNAME=basic_test

# Run stress test
./sim +EVM_TESTNAME=stress_test

# List all registered tests (prints and exits — no simulation)
./sim +EVM_LIST_TESTS

# Run with other plusargs
./sim +EVM_TESTNAME=basic_test +EVM_TIMEOUT=5000 +verbosity=HIGH
```

### Programmatic access

```systemverilog
// Check if test exists
if (evm_test_registry::test_exists("my_test")) begin
    evm_base_test t = evm_test_registry::create_test("my_test");
    evm_root::get().run_test(t);
end

// Print all registered tests
evm_test_registry::list_tests();

// Count
int n = evm_test_registry::get_test_count();
```

### How it works

The `EVM_REGISTER_TEST` macro expands to:
```systemverilog
evm_test_creator_t#(TNAME) TNAME_evm_reg_creator;
initial begin
    TNAME_evm_reg_creator = new();
    evm_test_registry::register("TNAME", TNAME_evm_reg_creator);
end
```

`evm_test_creator_t#(T)` is a generic factory that calls `new(name)` on type T and returns it as `evm_base_test`. No DPI, no string-to-type tricks.

---

## evm_sequence_library — Named Sequence Registry

Analogous to the test registry but for sequences. Lets you name sequences, run them by name, run all, or run randomly.

### Registration (once per sequence)

```systemverilog
// my_sequences.sv

class doorbell_write_seq extends evm_sequence;
    // ...
endclass
`EVM_REGISTER_SEQUENCE(doorbell_write_seq)

class backpressure_seq extends evm_sequence;
    // ...
endclass
`EVM_REGISTER_SEQUENCE(backpressure_seq)

class burst_read_seq extends evm_sequence;
    // ...
endclass
`EVM_REGISTER_SEQUENCE(burst_read_seq)
```

### Basic usage in test

```systemverilog
virtual task main_phase();
    super.main_phase();
    raise_objection("test");
    
    evm_sequence_library lib = new("lib");
    
    // Run by name
    lib.run_sequence("doorbell_write_seq", env.csr_agent.sequencer);
    
    // Run all registered sequences in order
    lib.run_all(env.csr_agent.sequencer);
    
    // Run random selection
    lib.run_random(env.csr_agent.sequencer);
    
    // Run from plusarg: +EVM_SEQ=doorbell_write_seq
    lib.run_from_plusarg(env.csr_agent.sequencer);
    
    drop_objection("test");
endtask
```

### Advanced usage

```systemverilog
evm_sequence_library lib = new("lib");

// Only use a subset
lib.enable_sequence("doorbell_write_seq");
lib.enable_sequence("burst_read_seq");
// lib.enable_all();  // reset to using all

// Configure selection mode
lib.selection_mode = evm_sequence_library::SEQ_ROUND_ROBIN;  // or SEQ_RANDOM

// Run N random sequences
repeat (10) lib.run_random(env.sqr);

// Check results
$display("Sequences run: %0d", lib.sequences_run);
```

### Static operations (no instance needed)

```systemverilog
// Print all registered sequences
evm_sequence_library::list_all();

// Create a sequence by name
evm_sequence seq = evm_sequence_library::create_sequence("doorbell_write_seq");
env.sqr.execute_sequence(seq);
```

### +EVM_SEQ plusarg

```bash
./sim +EVM_TESTNAME=random_test +EVM_SEQ=doorbell_write_seq
```

In test:
```systemverilog
lib.run_from_plusarg(env.sqr);
// Runs "doorbell_write_seq" if +EVM_SEQ= specified,
// otherwise runs a random sequence from the library
```

---

## Complete Test Template

Here's the complete pattern combining all three:

```systemverilog
//==============================================================================
// File: my_test.sv
// Description: Template for a complete EVM test
//==============================================================================

// 1. Environment
class my_env extends evm_env;
    evm_axi_lite_master_agent csr_agent;
    // ... other agents, scoreboard, predictor
    
    virtual function void build_phase();
        super.build_phase();
        csr_agent = new("csr_agent", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        // ... connections
    endfunction
endclass

// 2. Test base (project-specific)
virtual class proj_base_test extends evm_base_test;
    my_env env;
    
    virtual function void build_phase();
        super.build_phase();
        evm_report_handler::set_verbosity(EVM_MEDIUM);
        env = new("env", this);
    endfunction
endclass

// 3. Concrete tests
class basic_test extends proj_base_test;
    virtual task main_phase();
        super.main_phase();
        raise_objection("basic_test");
        // ... test body
        drop_objection("basic_test");
    endtask
endclass
`EVM_REGISTER_TEST(basic_test)

class stress_test extends proj_base_test;
    evm_sequence_library seq_lib;
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("stress_test");
        
        seq_lib = new("seq_lib");
        seq_lib.selection_mode = evm_sequence_library::SEQ_RANDOM;
        repeat (50) seq_lib.run_random(env.csr_agent.sequencer);
        
        drop_objection("stress_test");
    endtask
endclass
`EVM_REGISTER_TEST(stress_test)

// 4. Sequences
class doorbell_seq extends evm_sequence;
    virtual task body();
        evm_csr_item item = evm_csr_item::create_write(32'h0, 32'hDEAD_0000, "doorbell_addr");
        items.push_back(item);
    endtask
endclass
`EVM_REGISTER_SEQUENCE(doorbell_seq)
```

```systemverilog
// 5. tb_top.sv
module tb_top;
    // ... clk/rst generation
    // ... interface instantiation
    // ... DUT instantiation
    
    initial begin
        // Set VIFs
        evm_root::get().// or use your test registry entry point
        
        // Set interface handles (before simulation)
        // env is created inside the test, so set VIFs globally
        // or use a tb helper
        
        evm_root::get().run_test_by_name();
    end
endmodule
```

---

## Session Start Checklist

When starting a new AI-assisted EVM session, reference:
1. [`../CLAUDE.md`](../CLAUDE.md) — framework rules and class reference
2. [`ARCHITECTURE.md`](ARCHITECTURE.md) — phases, TLM, run_phase
3. [`AGENTS.md`](AGENTS.md) — protocol agents
4. [`REGISTER_MODEL.md`](REGISTER_MODEL.md) — RAL and predictor

---

## See Also

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — phases, objections, VIF pattern
- [`AGENTS.md`](AGENTS.md) — protocol agent documentation
- [`QUICK_START.md`](QUICK_START.md) — first-time setup
- [`../CLAUDE.md`](../CLAUDE.md) — AI development guide
