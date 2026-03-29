# EVM Phasing Guide

**EVM - Embedded Verification Methodology**  
**Document:** Complete Phasing System Guide  
**Date:** 2026-03-28  
**Version:** 1.0  

---

## Table of Contents

1. [Overview](#1-overview)
2. [Phase Execution Flow](#2-phase-execution-flow)
3. [Phase Reference](#3-phase-reference)
4. [Objection Mechanism](#4-objection-mechanism)
5. [Usage Examples](#5-usage-examples)
6. [Best Practices](#6-best-practices)
7. [Advanced Topics](#7-advanced-topics)

---

## 1. Overview

### 1.1 What is Phasing?

EVM uses a **phase-based execution model** where testbench construction, execution, and cleanup are organized into distinct, ordered phases. Each phase has a specific purpose and executes at a defined time.

**Benefits of Phasing:**
- ✅ **Organized code structure** - Clear separation of build, run, and check
- ✅ **Predictable execution order** - Phases run in defined sequence
- ✅ **Automatic management** - No manual orchestration needed
- ✅ **Synchronization** - All components execute phases together
- ✅ **Test control** - Objections control when phases complete

### 1.2 Phase Categories

EVM has **12 phases** organized into three categories:

```
┌─────────────────────────────────────────────────────────┐
│  FUNCTION PHASES (Pre-Simulation)                       │
│  build, connect, end_of_elaboration, start_of_simulation│
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  TASK PHASES (Runtime)                                   │
│  reset, configure, main, shutdown                        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  FUNCTION PHASES (Post-Simulation)                       │
│  extract, check, report, final                           │
└─────────────────────────────────────────────────────────┘
```

### 1.3 Quick Start

**Minimal Test:**
```systemverilog
class my_test extends evm_base_test;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    // Build components
    function void build_phase();
        super.build_phase();
        // Create environment, agents, etc.
    endfunction
    
    // Run test stimulus
    task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // Your test code here
        #100us;
        
        drop_objection("test");
    endtask
    
endclass
```

**Running the Test:**
```systemverilog
initial begin
    my_test test = new("test");
    test.connect_interfaces(my_if);
    evm_root::get().run_test(test);
    $finish;
end
```

---

## 2. Phase Execution Flow

### 2.1 Complete Phase Sequence

```
Time 0
  │
  ├─► build_phase()                    [Function]
  │    Purpose: Construct testbench hierarchy
  │    Actions: Create components, configure
  │
  ├─► connect_phase()                  [Function]
  │    Purpose: Make connections
  │    Actions: Connect ports, set interfaces
  │
  ├─► end_of_elaboration_phase()       [Function]
  │    Purpose: Final pre-simulation checks
  │    Actions: Validate configuration, print topology
  │
  ├─► start_of_simulation_phase()      [Function]
  │    Purpose: Pre-run initialization
  │    Actions: Initialize scoreboards, open files
  │
  ├─► reset_phase()                    [Task]
  │    Purpose: Reset DUT
  │    Actions: Apply reset, wait for reset completion
  │
  ├─► configure_phase()                [Task]
  │    Purpose: Configure DUT after reset
  │    Actions: Program registers, set modes
  │
  ├─► main_phase()                     [Task] ⭐
  │    Purpose: Primary test activity
  │    Actions: Generate stimulus, run sequences
  │    Control: Use raise/drop_objection()
  │
  ├─► shutdown_phase()                 [Task]
  │    Purpose: Graceful shutdown
  │    Actions: Drain FIFOs, wait for completion
  │
  ├─► extract_phase()                  [Function]
  │    Purpose: Extract results from DUT/scoreboards
  │    Actions: Read counters, collect coverage
  │
  ├─► check_phase()                    [Function]
  │    Purpose: Verify test results
  │    Actions: Compare expected vs actual
  │
  ├─► report_phase()                   [Function]
  │    Purpose: Print test summary
  │    Actions: Report pass/fail, statistics
  │
  └─► final_phase()                    [Function]
       Purpose: Final cleanup
       Actions: Close files, free resources
       
$finish
```

### 2.2 Phase Types

#### Function Phases
- **Type:** `function void phase_name()`
- **Blocking:** Yes - must complete before next phase
- **Time:** Cannot consume time
- **Usage:** Construction, configuration, checking

#### Task Phases
- **Type:** `task phase_name()`
- **Blocking:** Yes - but can consume time
- **Time:** Can consume simulation time
- **Usage:** Runtime activities (stimulus, reset, etc.)

### 2.3 Automatic Phase Management

The `evm_root` singleton automatically manages phase execution:

```systemverilog
// From evm_root.sv
task run_test(evm_component test);
    // Function phases (pre-simulation)
    test.build_phase();
    test.connect_phase();
    test.end_of_elaboration_phase();
    test.start_of_simulation_phase();
    
    // Task phases (runtime) - run in parallel with root
    fork
        test.reset_phase();
    join_none
    execute_reset_phase();
    wait fork;
    
    fork
        test.configure_phase();
    join_none
    execute_configure_phase();
    wait fork;
    
    fork
        test.main_phase();
    join_none
    execute_main_phase();  // Includes objection wait + timeout
    wait fork;
    
    fork
        test.shutdown_phase();
    join_none
    execute_shutdown_phase();
    wait fork;
    
    // Function phases (post-simulation)
    test.extract_phase();
    test.check_phase();
    test.report_phase();
    test.final_phase();
endtask
```

**You never call phases directly - evm_root does it for you!**

---

## 3. Phase Reference

### 3.1 build_phase()

**Type:** Function  
**Purpose:** Construct the testbench hierarchy  
**Timing:** Executes first, at time 0  

**What to do:**
- ✅ Create child components (env, agents, etc.)
- ✅ Set configuration parameters
- ✅ Allocate resources

**What NOT to do:**
- ❌ Access virtual interfaces (not set yet)
- ❌ Consume time
- ❌ Start threads

**Example:**
```systemverilog
function void build_phase();
    super.build_phase();
    
    // Create environment
    env = new("env", this);
    
    // Configure
    env.cfg.num_agents = 2;
    env.cfg.data_width = 32;
    
    log_info("Build phase complete", EVM_HIGH);
endfunction
```

### 3.2 connect_phase()

**Type:** Function  
**Purpose:** Make connections between components  
**Timing:** After build_phase  

**What to do:**
- ✅ Set virtual interfaces
- ✅ Connect ports (if using TLM)
- ✅ Establish communication paths

**Example:**
```systemverilog
function void connect_phase();
    super.connect_phase();
    
    // Connect driver to sequencer (if using TLM)
    env.agent.driver.seq_item_port.connect(
        env.agent.sequencer.seq_item_export);
    
    // Connect monitor to scoreboard
    env.agent.monitor.analysis_port.connect(
        env.scoreboard.analysis_export);
    
    log_info("Connect phase complete", EVM_HIGH);
endfunction
```

**Note:** In EVM, virtual interfaces are typically set via `connect_interfaces()` before `run_test()`:

```systemverilog
initial begin
    my_test test = new("test");
    test.connect_interfaces(my_if);  // Set interfaces
    evm_root::get().run_test(test);  // Run all phases
end
```

### 3.3 end_of_elaboration_phase()

**Type:** Function  
**Purpose:** Final checks before simulation starts  
**Timing:** After connect_phase  

**What to do:**
- ✅ Validate configuration
- ✅ Print topology (if debugging)
- ✅ Final sanity checks

**Example:**
```systemverilog
function void end_of_elaboration_phase();
    super.end_of_elaboration_phase();
    
    // Validate configuration
    if (env.agent.driver.vif == null) begin
        log_error("Driver interface not set!");
    end
    
    // Print hierarchy (debugging)
    if (get_verbosity() >= EVM_HIGH) begin
        print_topology();
    end
    
    log_info("End of elaboration phase complete", EVM_HIGH);
endfunction
```

### 3.4 start_of_simulation_phase()

**Type:** Function  
**Purpose:** Initialize before runtime  
**Timing:** After end_of_elaboration_phase, still at time 0  

**What to do:**
- ✅ Initialize scoreboards
- ✅ Open files
- ✅ Reset counters
- ✅ Print "Test Starting" messages

**Example:**
```systemverilog
function void start_of_simulation_phase();
    super.start_of_simulation_phase();
    
    // Initialize scoreboard
    env.scoreboard.reset();
    
    // Open log file
    log_file = $fopen("test.log", "w");
    
    log_info("=== TEST STARTING ===", EVM_LOW);
    log_info($sformatf("Test: %s", get_name()), EVM_LOW);
endfunction
```

### 3.5 reset_phase()

**Type:** Task  
**Purpose:** Apply and wait for reset  
**Timing:** First runtime phase  

**What to do:**
- ✅ Assert reset
- ✅ Wait specified duration
- ✅ Deassert reset
- ✅ Wait for reset to complete

**Example:**
```systemverilog
task reset_phase();
    super.reset_phase();
    
    log_info("Applying reset...", EVM_LOW);
    
    // Assert reset
    env.rst_agent.assert_reset();
    
    // Hold for 10 clock cycles
    repeat(10) @(posedge env.clk_agent.vif.clk);
    
    // Deassert reset
    env.rst_agent.deassert_reset();
    
    // Wait for reset completion
    wait(env.dut_if.ready == 1);
    
    log_info("Reset complete", EVM_LOW);
endtask
```

### 3.6 configure_phase()

**Type:** Task  
**Purpose:** Configure DUT after reset  
**Timing:** After reset_phase  

**What to do:**
- ✅ Program registers
- ✅ Set operating modes
- ✅ Initialize DUT state

**Example:**
```systemverilog
task configure_phase();
    super.configure_phase();
    
    log_info("Configuring DUT...", EVM_LOW);
    
    // Program control register
    env.axi_agent.write(CTRL_REG, 32'h0000_0001);
    
    // Set mode
    env.axi_agent.write(MODE_REG, 32'h0000_0003);
    
    // Enable interrupts
    env.axi_agent.write(INT_EN_REG, 32'hFFFF_FFFF);
    
    log_info("Configuration complete", EVM_LOW);
endtask
```

### 3.7 main_phase() ⭐

**Type:** Task  
**Purpose:** Primary test activity - THIS IS WHERE YOUR TEST RUNS  
**Timing:** After configure_phase  

**Critical:** Use objections to control when this phase ends!

**What to do:**
- ✅ Raise objection at start
- ✅ Generate stimulus
- ✅ Run sequences
- ✅ Check for errors
- ✅ Drop objection when done

**Example:**
```systemverilog
task main_phase();
    super.main_phase();
    
    // Raise objection to prevent phase from ending
    raise_objection("test_stimulus");
    
    log_info("=== MAIN PHASE STARTING ===", EVM_LOW);
    
    // Run sequences
    for (int i = 0; i < 100; i++) begin
        my_sequence seq = new();
        seq.randomize();
        seq.execute(env.agent.sequencer);
    end
    
    // Wait for all transactions to complete
    env.agent.driver.wait_for_idle();
    
    // Additional delay
    #10us;
    
    log_info("=== MAIN PHASE COMPLETE ===", EVM_LOW);
    
    // Drop objection to allow phase to end
    drop_objection("test_stimulus");
endtask
```

**Without objections, main_phase would end immediately!**

### 3.8 shutdown_phase()

**Type:** Task  
**Purpose:** Graceful shutdown  
**Timing:** After main_phase  

**What to do:**
- ✅ Drain FIFOs
- ✅ Wait for pending transactions
- ✅ Disable DUT

**Example:**
```systemverilog
task shutdown_phase();
    super.shutdown_phase();
    
    log_info("Shutting down...", EVM_LOW);
    
    // Wait for FIFOs to drain
    env.agent.monitor.wait_for_idle();
    
    // Disable DUT
    env.axi_agent.write(CTRL_REG, 32'h0000_0000);
    
    log_info("Shutdown complete", EVM_LOW);
endtask
```

### 3.9 extract_phase()

**Type:** Function  
**Purpose:** Extract results from DUT/testbench  
**Timing:** After shutdown_phase  

**What to do:**
- ✅ Read DUT counters
- ✅ Get scoreboard statistics
- ✅ Collect coverage

**Example:**
```systemverilog
function void extract_phase();
    super.extract_phase();
    
    // Read DUT statistics
    int tx_count, rx_count;
    env.axi_agent.read(TX_COUNT_REG, tx_count);
    env.axi_agent.read(RX_COUNT_REG, rx_count);
    
    log_info($sformatf("DUT: TX=%0d, RX=%0d", tx_count, rx_count), EVM_LOW);
    
    // Get scoreboard stats
    sb_matches = env.scoreboard.get_match_count();
    sb_errors = env.scoreboard.get_error_count();
    
    log_info($sformatf("Scoreboard: Matches=%0d, Errors=%0d", 
             sb_matches, sb_errors), EVM_LOW);
endfunction
```

### 3.10 check_phase()

**Type:** Function  
**Purpose:** Verify test results  
**Timing:** After extract_phase  

**What to do:**
- ✅ Compare expected vs actual
- ✅ Check for errors
- ✅ Validate coverage goals

**Example:**
```systemverilog
function void check_phase();
    super.check_phase();
    
    // Check scoreboard
    if (env.scoreboard.get_error_count() > 0) begin
        log_error($sformatf("Scoreboard errors: %0d", 
                  env.scoreboard.get_error_count()));
    end
    
    // Check expected transaction count
    if (env.scoreboard.get_match_count() != expected_count) begin
        log_error($sformatf("Transaction count mismatch: got %0d, expected %0d",
                  env.scoreboard.get_match_count(), expected_count));
    end
    
    // Check coverage (if enabled)
    if (get_coverage() < 80.0) begin
        log_warning($sformatf("Coverage below target: %.1f%%", get_coverage()));
    end
endfunction
```

### 3.11 report_phase()

**Type:** Function  
**Purpose:** Print test summary and results  
**Timing:** After check_phase  

**What to do:**
- ✅ Print test name
- ✅ Print pass/fail status
- ✅ Print statistics
- ✅ Print error/warning counts

**Example:**
```systemverilog
function void report_phase();
    super.report_phase();
    
    log_info("========================================", EVM_LOW);
    log_info($sformatf("Test: %s", test_name), EVM_LOW);
    log_info($sformatf("Transactions: %0d", transaction_count), EVM_LOW);
    log_info($sformatf("Errors: %0d", evm_log::error_count), EVM_LOW);
    log_info($sformatf("Warnings: %0d", evm_log::warning_count), EVM_LOW);
    
    if (evm_log::error_count == 0) begin
        log_info($sformatf("%s PASSED ✓", test_name), EVM_LOW);
    end else begin
        log_error($sformatf("%s FAILED ✗ with %0d errors", 
                  test_name, evm_log::error_count));
    end
    
    log_info("========================================", EVM_LOW);
endfunction
```

### 3.12 final_phase()

**Type:** Function  
**Purpose:** Final cleanup  
**Timing:** Last phase before $finish  

**What to do:**
- ✅ Close files
- ✅ Free resources
- ✅ Final logging

**Example:**
```systemverilog
function void final_phase();
    super.final_phase();
    
    // Close log file
    if (log_file != 0) begin
        $fclose(log_file);
    end
    
    // Free dynamic memory (if needed)
    // cleanup_resources();
    
    log_info("Final phase complete", EVM_HIGH);
endfunction
```

---

## 4. Objection Mechanism

### 4.1 What Are Objections?

Objections control when **task phases** (reset, configure, main, shutdown) complete.

**Without objections:**
```systemverilog
task main_phase();
    super.main_phase();
    #100us;  // Phase ends immediately - this never executes!
endtask
```

**With objections:**
```systemverilog
task main_phase();
    super.main_phase();
    raise_objection("activity");
    #100us;  // Now this executes!
    drop_objection("activity");
endtask
```

### 4.2 Objection Rules

1. **Each raise must have a matching drop**
   ```systemverilog
   raise_objection("test1");  // count = 1
   raise_objection("test2");  // count = 2
   drop_objection("test1");   // count = 1
   drop_objection("test2");   // count = 0 → phase ends
   ```

2. **Phase waits for count to reach 0**
   - All objections must be dropped
   - Event-based notification
   - Timeout protection

3. **Use descriptive names**
   ```systemverilog
   raise_objection("stimulus_generation");
   raise_objection("waiting_for_response");
   ```

### 4.3 Objection API

```systemverilog
// In test or component
class my_test extends evm_base_test;
    
    task main_phase();
        // Raise objection
        raise_objection("test_activity");
        
        // Do work
        run_stimulus();
        
        // Drop objection
        drop_objection("test_activity");
    endtask
    
endclass
```

**Behind the scenes:**
```systemverilog
// evm_base_test convenience methods call evm_root
function void raise_objection(string description = "");
    evm_root::get().raise_objection(description);
endfunction

function void drop_objection(string description = "");
    evm_root::get().drop_objection(description);
endfunction
```

### 4.4 Timeout Protection

EVM automatically protects against infinite waits:

```systemverilog
// Set timeout (default: 1ms)
initial begin
    evm_root::get().set_default_timeout(5000); // 5ms
    // Or via plusarg: +EVM_TIMEOUT=5000
end
```

**What happens on timeout:**
```
ERROR: EVM_TIMEOUT: Main phase timeout after 5000us with 2 objections still raised
```

### 4.5 Multiple Objections

Components can raise objections independently:

```systemverilog
// Test raises objection
task main_phase();
    raise_objection("test_main");
    start_background_thread();
    // ... test code ...
    drop_objection("test_main");
endtask

// Background thread raises its own objection
task background_thread();
    raise_objection("background_activity");
    forever begin
        @(posedge clk);
        if (done) break;
    end
    drop_objection("background_activity");
endtask
```

**Phase waits for BOTH objections to drop!**

---

## 5. Usage Examples

### 5.1 Simple Test

```systemverilog
class simple_test extends evm_base_test;
    
    my_env env;
    
    function new(string name = "simple_test");
        super.new(name);
    endfunction
    
    function void build_phase();
        super.build_phase();
        env = new("env", this);
    endfunction
    
    task main_phase();
        super.main_phase();
        raise_objection("stimulus");
        
        for (int i = 0; i < 10; i++) begin
            env.agent.driver.send_transaction(i);
        end
        
        #1us;
        drop_objection("stimulus");
    endtask
    
endclass
```

### 5.2 Complex Test with Multiple Phases

```systemverilog
class complex_test extends evm_base_test;
    
    my_env env;
    int expected_transactions;
    
    function new(string name = "complex_test");
        super.new(name);
        expected_transactions = 100;
    endfunction
    
    // Build
    function void build_phase();
        super.build_phase();
        env = new("env", this);
        env.cfg.num_agents = 2;
        env.cfg.data_width = 32;
        log_info("Environment created", EVM_HIGH);
    endfunction
    
    // Validate after build
    function void end_of_elaboration_phase();
        super.end_of_elaboration_phase();
        if (env.agent[0].vif == null) begin
            log_error("Agent 0 interface not connected");
        end
    endfunction
    
    // Initialize
    function void start_of_simulation_phase();
        super.start_of_simulation_phase();
        log_info("=== COMPLEX TEST STARTING ===", EVM_LOW);
        log_info($sformatf("Expected transactions: %0d", expected_transactions), EVM_LOW);
    endfunction
    
    // Reset
    task reset_phase();
        super.reset_phase();
        log_info("Applying reset", EVM_LOW);
        env.rst_agent.assert_reset();
        repeat(10) @(posedge env.clk_agent.vif.clk);
        env.rst_agent.deassert_reset();
        log_info("Reset complete", EVM_LOW);
    endtask
    
    // Configure
    task configure_phase();
        super.configure_phase();
        log_info("Configuring DUT", EVM_LOW);
        env.axi_agent.write('h00, 'h0001); // Enable
        env.axi_agent.write('h04, 'h00FF); // Set mask
        log_info("Configuration complete", EVM_LOW);
    endtask
    
    // Main test
    task main_phase();
        super.main_phase();
        raise_objection("main_stimulus");
        
        log_info("Generating stimulus", EVM_LOW);
        
        fork
            // Stream 1
            begin
                for (int i = 0; i < expected_transactions/2; i++) begin
                    env.agent[0].driver.send_random_transaction();
                end
            end
            
            // Stream 2
            begin
                for (int i = 0; i < expected_transactions/2; i++) begin
                    env.agent[1].driver.send_random_transaction();
                end
            end
        join
        
        // Wait for all transactions to complete
        #10us;
        
        log_info("Stimulus complete", EVM_LOW);
        drop_objection("main_stimulus");
    endtask
    
    // Shutdown
    task shutdown_phase();
        super.shutdown_phase();
        log_info("Draining pipeline", EVM_LOW);
        env.wait_for_idle();
    endtask
    
    // Extract results
    function void extract_phase();
        super.extract_phase();
        log_info($sformatf("Scoreboard matches: %0d", 
                 env.scoreboard.match_count), EVM_LOW);
        log_info($sformatf("Scoreboard errors: %0d", 
                 env.scoreboard.error_count), EVM_LOW);
    endfunction
    
    // Check results
    function void check_phase();
        super.check_phase();
        if (env.scoreboard.match_count != expected_transactions) begin
            log_error($sformatf("Transaction count mismatch: %0d != %0d",
                      env.scoreboard.match_count, expected_transactions));
        end
    endfunction
    
    // Report
    function void report_phase();
        super.report_phase();
        // Base class prints pass/fail
    endfunction
    
endclass
```

### 5.3 Streaming Test with Python Integration

```systemverilog
class streaming_test extends evm_base_test;
    
    my_env env;
    
    function new(string name = "streaming_test");
        super.new(name);
    endfunction
    
    function void build_phase();
        super.build_phase();
        env = new("env", this);
        
        // Configure streaming agent
        env.stream_agent.cfg.stimulus_file = "input_stimulus.txt";
        env.stream_agent.cfg.capture_file = "output_capture.txt";
    endfunction
    
    // Generate stimulus before simulation
    function void start_of_simulation_phase();
        super.start_of_simulation_phase();
        
        // Call Python to generate stimulus
        $system("python gen_stimulus.py --freq 1000 --fs 48000 -o input_stimulus.txt");
        
        log_info("Stimulus file generated", EVM_LOW);
    endfunction
    
    task main_phase();
        super.main_phase();
        raise_objection("streaming");
        
        // Stream agent loads file and streams data
        env.stream_agent.driver.stream_from_file();
        
        // Monitor captures to file
        env.stream_agent.monitor.capture_to_file();
        
        drop_objection("streaming");
    endtask
    
    // Analyze results after simulation
    function void final_phase();
        super.final_phase();
        
        // Call Python to analyze captured data
        $system("python analyze_spectrum.py output_capture.txt --fs 48000");
    endfunction
    
endclass
```

---

## 6. Best Practices

### 6.1 Always Call super

**✅ DO THIS:**
```systemverilog
function void build_phase();
    super.build_phase();  // Always call super first!
    // Your code here
endfunction
```

**❌ NOT THIS:**
```systemverilog
function void build_phase();
    // Missing super.build_phase()!
    // Your code here
endfunction
```

### 6.2 Use Objections in main_phase

**✅ DO THIS:**
```systemverilog
task main_phase();
    super.main_phase();
    raise_objection("test");
    // Test code
    drop_objection("test");
endtask
```

**❌ NOT THIS:**
```systemverilog
task main_phase();
    super.main_phase();
    // Missing objections - phase ends immediately!
    #100us;  // Never executes
endtask
```

### 6.3 Balance raise/drop

**✅ DO THIS:**
```systemverilog
raise_objection("test1");
// work
drop_objection("test1");

raise_objection("test2");
// more work
drop_objection("test2");
```

**❌ NOT THIS:**
```systemverilog
raise_objection("test1");
raise_objection("test2");
drop_objection("test1");
// Missing drop for test2 - timeout!
```

### 6.4 Use Descriptive Phase Code

**✅ DO THIS:**
```systemverilog
function void build_phase();
    super.build_phase();
    
    // Create components
    env = new("env", this);
    
    // Configure
    env.cfg.mode = FULL_DUPLEX;
    
    log_info("Build complete", EVM_HIGH);
endfunction
```

**❌ NOT THIS:**
```systemverilog
function void build_phase();
    super.build_phase();
    env = new("env", this);
    env.cfg.mode = FULL_DUPLEX;
endfunction
```

### 6.5 Check for Errors in check_phase

```systemverilog
function void check_phase();
    super.check_phase();
    
    // Check all error sources
    if (env.scoreboard.error_count > 0) begin
        log_error("Scoreboard errors detected");
    end
    
    if (env.monitor.protocol_errors > 0) begin
        log_error("Protocol violations detected");
    end
    
    if (transaction_count != expected_count) begin
        log_error("Transaction count mismatch");
    end
endfunction
```

---

## 7. Advanced Topics

### 7.1 Hierarchical Phasing

All components in the hierarchy execute phases:

```
test
  └─ env
      ├─ agent1
      │   ├─ driver
      │   ├─ monitor
      │   └─ sequencer
      └─ agent2
          ├─ driver
          ├─ monitor
          └─ sequencer
```

**Phase execution:**
```
test.build_phase()
    ├─> env.build_phase()
        ├─> agent1.build_phase()
        │   ├─> driver.build_phase()
        │   ├─> monitor.build_phase()
        │   └─> sequencer.build_phase()
        └─> agent2.build_phase()
            ├─> driver.build_phase()
            ├─> monitor.build_phase()
            └─> sequencer.build_phase()
```

**Each component can override phases:**
```systemverilog
class my_driver extends evm_driver;
    
    function void build_phase();
        super.build_phase();
        // Driver-specific build
    endfunction
    
    task main_phase();
        super.main_phase();
        // Driver-specific main activity
    endtask
    
endclass
```

### 7.2 Custom Timeout

**Set globally:**
```systemverilog
initial begin
    evm_root::get().set_default_timeout(10000); // 10ms
    // Run test
end
```

**Set via plusarg:**
```bash
vsim +EVM_TIMEOUT=5000 ...
```

### 7.3 Phase Logging

Enable phase transition logging:

```systemverilog
// Set verbosity to HIGH or DEBUG
evm_log::set_verbosity(EVM_HIGH);
```

**Output:**
```
[0ns] INFO: >>> Starting BUILD phase
[0ns] INFO: <<< BUILD phase complete
[0ns] INFO: >>> Starting CONNECT phase
[0ns] INFO: <<< CONNECT phase complete
...
```

### 7.4 Debugging Stuck Tests

If your test hangs:

1. **Check objection balance:**
   ```systemverilog
   // Add to main_phase
   log_info($sformatf("Objections at end: %0d", 
            evm_root::get().get_objection_count()), EVM_LOW);
   ```

2. **Lower timeout for faster failure:**
   ```bash
   +EVM_TIMEOUT=1000
   ```

3. **Add debug logging:**
   ```systemverilog
   raise_objection("test");
   log_info("Objection raised", EVM_DEBUG);
   
   // ... work ...
   
   log_info("About to drop objection", EVM_DEBUG);
   drop_objection("test");
   ```

---

## 8. Phase Quick Reference

| Phase | Type | Purpose | Common Use |
|-------|------|---------|------------|
| build | function | Create hierarchy | new(), configure |
| connect | function | Make connections | connect ports, set VIFs |
| end_of_elaboration | function | Final checks | validate config |
| start_of_simulation | function | Initialize | reset scoreboards, open files |
| reset | task | Reset DUT | assert/deassert reset |
| configure | task | Configure DUT | program registers |
| **main** | **task** | **Test stimulus** | **generate traffic** ⭐ |
| shutdown | task | Graceful stop | drain FIFOs |
| extract | function | Get results | read counters |
| check | function | Verify | compare expected vs actual |
| report | function | Print summary | pass/fail, statistics |
| final | function | Cleanup | close files |

---

## Summary

**EVM Phasing provides:**
- ✅ 12 well-defined phases
- ✅ Automatic execution via `run_test()`
- ✅ Objection mechanism for test control
- ✅ Timeout protection
- ✅ Hierarchical phase propagation
- ✅ Clean code organization

**Key takeaways:**
1. Always call `super.phase_name()` first
2. Use objections in `main_phase()`
3. One raise = one drop
4. Let `evm_root` manage phase execution
5. Use phases for their intended purpose

---

**End of Phasing Guide**

**Last Updated:** 2026-03-28  
**Version:** 1.0.0  
**Status:** Complete and Production-Ready ⭐
