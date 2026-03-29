# Complete Test Example

**Monitor → Scoreboard flow** - Demonstrates TLM communication and automatic checking!

---

## Overview

This example shows a complete verification flow:
- Monitor collects transactions from DUT
- Analysis port broadcasts to scoreboard
- Scoreboard automatically checks expected vs actual
- TLM 1.0 communication pattern

This is a production-ready pattern you can adapt for your projects!

---

## What This Example Shows

### ✅ Key Features

1. **Custom Transaction** - Transaction class with compare
2. **Monitor** - Collects from DUT interface, broadcasts via analysis_port
3. **Scoreboard** - Auto-checks expected vs actual using TLM
4. **Environment** - Connects monitor to scoreboard
5. **Complete Testbench** - DUT, interface, stimulus, test

---

## File Structure

```
complete_test/
├── README.md           ← You are here
└── complete_test.sv    ← Complete example in one file
```

---

## Architecture

```
Test
  └── Environment
      ├── Monitor → Analysis Port ──┐
      │                             │
      └── Scoreboard ←──────────────┘
          └── Analysis Imp (mailbox)
```

**Flow:**
1. Monitor observes DUT interface
2. Monitor creates transaction
3. Monitor writes to analysis_port
4. Analysis port sends to all subscribers
5. Scoreboard receives via analysis_imp mailbox
6. Scoreboard compares expected vs actual
7. Scoreboard reports match/mismatch

---

## Code Highlights

### 1. Transaction with Compare

```systemverilog
class my_txn extends evm_sequence_item;
    rand bit [7:0] addr;
    rand bit [31:0] data;
    rand bit write;
    
    virtual function bit do_compare(evm_object rhs, output string msg);
        my_txn t;
        if (!$cast(t, rhs)) return 0;
        
        if (this.addr != t.addr) begin
            msg = $sformatf("addr: 0x%02h != 0x%02h", this.addr, t.addr);
            return 0;
        end
        // ... check other fields
        return 1;
    endfunction
endclass
```

### 2. Monitor with Analysis Port

```systemverilog
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    
    virtual task main_phase();
        my_txn txn;
        super.main_phase();
        
        forever begin
            // Collect from interface
            txn = collect_transaction();
            
            // Broadcast to all subscribers
            analysis_port.write(txn);
        end
    endtask
endclass
```

### 3. Scoreboard with Auto-Check

```systemverilog
class my_scoreboard extends evm_scoreboard#(my_txn);
    function new(string name, evm_component parent);
        super.new(name, parent);
        
        mode = EVM_SB_FIFO;        // FIFO checking
        enable_auto_check = 1;      // Auto-check on receive
        stop_on_mismatch = 0;       // Continue on error
    endfunction
endclass
```

### 4. Environment Connects Them

```systemverilog
virtual function void connect_phase();
    super.connect_phase();
    
    // TLM connection
    monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
endfunction
```

### 5. Test Inserts Expected

```systemverilog
virtual task main_phase();
    super.main_phase();
    raise_objection("test");
    
    // Generate expected transactions
    repeat(10) begin
        expected = new("expected");
        assert(expected.randomize());
        
        scoreboard.insert_expected(expected);
        #100ns;
    end
    
    drop_objection("test");
endtask
```

---

## Running the Example

### With Questa/ModelSim

```bash
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv complete_test.sv
vsim -c tb_top -do "run -all; quit"
```

### With VCS

```bash
vcs -sverilog +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv complete_test.sv
./simv
```

### With Xcelium

```bash
xrun -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv complete_test.sv
```

---

## Expected Output

```
[0] [INFO   ] Test built
[50ns] [INFO   ] Monitor active after reset
[50ns] [INFO   ] Expected: addr=0x42 data=0xDEADBEEF WR
[150ns] [INFO   ] Monitored: addr=0x42 data=0xDEADBEEF WR
[150ns] [INFO   ] MATCH #1: addr=0x42 data=0xDEADBEEF WR
...
[1500ns] [INFO   ] MATCH #10: addr=0xFF data=0x12345678 RD

==============================================================================
                        EVM REPORT SUMMARY
==============================================================================
[2000ns] INFO messages:    35
[2000ns] WARNINGs:          0
[2000ns] ERRORs:            0
[2000ns] FATALs:            0
==============================================================================
[2000ns] *** TEST PASSED ***
==============================================================================
```

---

## Key Concepts

### 1. TLM Analysis Port

**Purpose:** Broadcast transactions to multiple subscribers

```systemverilog
// In monitor
analysis_port.write(txn);  // Sends to ALL subscribers

// In environment connect_phase
monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
monitor.analysis_port.connect(coverage.mailbox);  // Can have multiple!
```

### 2. Scoreboard Modes

```systemverilog
EVM_SB_FIFO         // Strict order (default)
EVM_SB_ASSOCIATIVE  // Match by key (set compare_key)
EVM_SB_UNORDERED    // Any order
```

### 3. Auto-Check

```systemverilog
enable_auto_check = 1;  // Scoreboard checks automatically
// No need to call check() manually!
```

### 4. Custom Compare

Override for better error messages:

```systemverilog
virtual function bit compare_transactions(my_txn expected, my_txn actual);
    string msg;
    bit match = expected.compare(actual, msg);
    
    if (!match) begin
        log_error($sformatf("MISMATCH: %s", msg));
        log_error($sformatf("  Expected: %s", expected.convert2string()));
        log_error($sformatf("  Actual:   %s", actual.convert2string()));
    end
    
    return match;
endfunction
```

---

## Adapting for Your Project

### 1. Define Your Transaction

```systemverilog
class my_protocol_txn extends evm_sequence_item;
    // Your protocol fields
    rand bit [31:0] address;
    rand bit [63:0] data;
    rand bit [3:0] cmd;
    
    // Comparison
    virtual function bit do_compare(evm_object rhs, output string msg);
        // Compare fields
    endfunction
    
    // Printing
    virtual function string convert2string();
        // Format for display
    endfunction
endclass
```

### 2. Create Your Monitor

```systemverilog
class my_protocol_monitor extends evm_monitor#(virtual my_if, my_protocol_txn);
    
    virtual task main_phase();
        my_protocol_txn txn;
        super.main_phase();
        
        forever begin
            // Wait for transaction on interface
            @(posedge vif.clk);
            if (vif.valid) begin
                // Create and populate transaction
                txn = new();
                txn.address = vif.addr;
                txn.data = vif.data;
                txn.cmd = vif.cmd;
                
                // Broadcast
                analysis_port.write(txn);
            end
        end
    endtask
endclass
```

### 3. Choose Scoreboard Mode

```systemverilog
// For ordered protocols (AXI, etc.)
scoreboard.mode = EVM_SB_FIFO;

// For unordered protocols (PCIe completions, etc.)
scoreboard.mode = EVM_SB_UNORDERED;

// For keyed protocols (lookups, etc.)
scoreboard.mode = EVM_SB_ASSOCIATIVE;
scoreboard.compare_key = "id";  // Compare by ID field
```

---

## Common Patterns

### Pattern 1: Monitor to Multiple Subscribers

```systemverilog
virtual function void connect_phase();
    super.connect_phase();
    
    // Monitor broadcasts to many
    monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
    monitor.analysis_port.connect(coverage_collector.mailbox);
    monitor.analysis_port.connect(protocol_checker.mailbox);
endfunction
```

### Pattern 2: Multiple Monitors to One Scoreboard

```systemverilog
// Scoreboard with two analysis_imps
class dual_scoreboard extends evm_scoreboard#(my_txn);
    evm_analysis_imp#(my_txn) expected_imp;
    evm_analysis_imp#(my_txn) actual_imp;
    
    function new(string name, evm_component parent);
        super.new(name, parent);
        expected_imp = new("expected_imp", this);
        actual_imp = new("actual_imp", this);
    endfunction
endclass

// Connect
virtual function void connect_phase();
    super.connect_phase();
    
    expected_monitor.analysis_port.connect(scoreboard.expected_imp.get_mailbox());
    actual_monitor.analysis_port.connect(scoreboard.actual_imp.get_mailbox());
endfunction
```

---

## Troubleshooting

### Issue: Scoreboard Not Receiving

```systemverilog
// ❌ BAD
virtual function void connect_phase();
    // FORGOT: super.connect_phase();
    monitor.analysis_port.connect(...);
endfunction
```

**Fix:** Always call super first!

### Issue: Transactions Not Matching

```systemverilog
// Check scoreboard mode
$display("Mode: %s", scoreboard.mode.name());

// Check transaction order
$display("Expected queue size: %0d", scoreboard.expected_queue.size());
$display("Actual queue size: %0d", scoreboard.actual_queue.size());
```

### Issue: Too Many Mismatches

```systemverilog
// Enable debug
evm_report_handler::set_verbosity(EVM_HIGH);

// Check compare function
bit match = expected.compare(actual, msg);
$display("Match: %0b, Msg: %s", match, msg);
```

---

## What's Next?

After understanding this example:

1. **Adapt** the monitor for your protocol
2. **Adapt** the transaction for your data
3. **Adapt** the scoreboard mode for your checking needs
4. **Add** coverage collection
5. **Add** protocol checkers

---

## Summary

**This example demonstrates production-ready patterns:**
- ✅ TLM communication
- ✅ Automatic checking
- ✅ Clean separation (monitor, scoreboard, environment)
- ✅ Reusable components

**Copy and adapt for your projects!**
