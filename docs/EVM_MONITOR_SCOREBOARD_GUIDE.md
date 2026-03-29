# EVM Monitor → Scoreboard Complete Guide

**How transactions flow from Monitor to Scoreboard in EVM**

---

## 🎯 Overview

EVM implements the **same UVM pattern** for monitor → scoreboard communication:

```
Monitor → analysis_port.write() → Scoreboard.insert_actual()
```

**This is ALREADY FULLY IMPLEMENTED in EVM!**

---

## 📊 The Flow

```
┌──────────────────────┐
│   evm_monitor        │
│                      │
│  1. Collect txn      │
│     from interface   │
│                      │
│  2. analysis_port    │
│     .write(txn) ────┼──┐
└──────────────────────┘  │
                          │ Broadcast
                          │ (1-to-many)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Scoreboard   │  │  Coverage    │  │   Checker    │
│              │  │  Collector   │  │              │
│insert_actual │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 💡 Complete Working Example

### Step 1: Define Transaction

```systemverilog
class my_txn extends evm_sequence_item;
    rand bit [7:0] addr;
    rand bit [31:0] data;
    rand bit write;
    
    function new(string name = "my_txn");
        super.new(name);
    endfunction
    
    // For scoreboard comparison
    virtual function bit do_compare(evm_object rhs, output string msg);
        my_txn t;
        $cast(t, rhs);
        
        if (this.addr != t.addr) begin
            msg = $sformatf("addr mismatch: %0h != %0h", this.addr, t.addr);
            return 0;
        end
        if (this.data != t.data) begin
            msg = $sformatf("data mismatch: %0h != %0h", this.data, t.data);
            return 0;
        end
        if (this.write != t.write) begin
            msg = $sformatf("write mismatch: %0b != %0b", this.write, t.write);
            return 0;
        end
        return 1;
    endfunction
    
    virtual function string convert2string();
        return $sformatf("addr=0x%02h data=0x%08h %s",
                        addr, data, write ? "WR" : "RD");
    endfunction
endclass
```

### Step 2: Create Monitor

```systemverilog
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    
    function new(string name = "my_monitor", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task main_phase();
        my_txn txn;
        
        // Wait for reset
        @(posedge vif.reset_n);
        
        forever begin
            // Collect transaction from interface
            txn = collect_transaction();
            
            // *** CRITICAL: Broadcast via analysis port ***
            analysis_port.write(txn);
            
            log_info($sformatf("Monitored: %s", txn.convert2string()), EVM_HIGH);
        end
    endtask
    
    // Collect transaction from interface
    virtual function my_txn collect_transaction();
        my_txn txn = new("monitored_txn");
        
        // Wait for valid
        @(vif.mon_cb);
        wait(vif.mon_cb.valid && vif.mon_cb.ready);
        
        // Capture signals
        txn.addr = vif.mon_cb.addr;
        txn.data = vif.mon_cb.data;
        txn.write = vif.mon_cb.write;
        
        return txn;
    endfunction
    
    virtual function string get_type_name();
        return "my_monitor";
    endfunction
    
endclass
```

### Step 3: Create Scoreboard

```systemverilog
class my_scoreboard extends evm_scoreboard#(my_txn);
    
    function new(string name = "my_scoreboard", evm_component parent = null);
        super.new(name, parent);
        
        // Configure scoreboard
        mode = EVM_SB_FIFO;              // FIFO order checking
        enable_auto_check = 1;           // Auto-check on insert
        stop_on_mismatch = 0;            // Continue on mismatch
        
        // analysis_imp created automatically by base class
    endfunction
    
    // Override compare for custom comparison logic
    virtual function bit compare_transactions(my_txn expected, my_txn actual);
        string msg;
        bit match;
        
        // Use transaction's do_compare method
        match = expected.compare(actual, msg);
        
        if (match) begin
            match_count++;
            log_info($sformatf("MATCH #%0d: %s", 
                              match_count, actual.convert2string()), EVM_MEDIUM);
        end else begin
            mismatch_count++;
            log_error($sformatf("MISMATCH #%0d: %s",
                               mismatch_count, msg));
            log_error($sformatf("  Expected: %s", expected.convert2string()));
            log_error($sformatf("  Actual:   %s", actual.convert2string()));
        end
        
        return match;
    endfunction
    
    // main_phase inherited from evm_scoreboard - automatically receives!
    
endclass
```

### Step 4: Create Environment

```systemverilog
class my_env extends evm_component;
    
    my_monitor monitor;
    my_scoreboard scoreboard;
    
    function new(string name = "my_env", evm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        // Create components
        monitor = new("monitor", this);
        scoreboard = new("scoreboard", this);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        
        // *** CRITICAL CONNECTION ***
        // Connect monitor's analysis port to scoreboard's analysis_imp
        monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
        
        log_info("Monitor → Scoreboard connection established", EVM_MEDIUM);
    endfunction
    
    function void set_vif(virtual my_if vif);
        monitor.set_vif(vif);
    endfunction
    
endclass
```

### Step 5: Create Test

```systemverilog
class my_test extends evm_base_test;
    
    my_env env;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        env = new("env", this);
    endfunction
    
    virtual task main_phase();
        my_txn expected_txn;
        
        super.main_phase();
        raise_objection("test");
        
        log_info("Generating expected transactions", EVM_LOW);
        
        // Generate expected transactions
        repeat(10) begin
            expected_txn = new("expected");
            expected_txn.randomize();
            
            // Insert expected into scoreboard
            env.scoreboard.insert_expected(expected_txn);
            
            log_info($sformatf("Expected: %s", expected_txn.convert2string()), EVM_HIGH);
            
            #100ns;
        end
        
        // Wait for all transactions to complete
        #1us;
        
        drop_objection("test");
    endtask
    
endclass
```

### Step 6: Testbench Top

```systemverilog
module tb_top;
    import evm_pkg::*;
    
    logic clk = 0;
    always #5 clk = ~clk;
    
    my_if dut_if(clk);
    my_dut dut(...);
    
    initial begin
        my_test test;
        
        test = new("test");
        test.env.set_vif(dut_if);
        
        evm_root::get().run_test(test);
    end
    
endmodule
```

---

## 🔑 Key Points

### 1. **Monitor Has analysis_port**

```systemverilog
class evm_monitor #(type VIF, type T) extends evm_component;
    evm_analysis_port#(T) analysis_port;  // ← Built-in!
    
    virtual task main_phase();
        T txn = collect_transaction();
        analysis_port.write(txn);  // ← Broadcast!
    endtask
endclass
```

### 2. **Scoreboard Receives via analysis_imp**

```systemverilog
class my_scoreboard extends evm_scoreboard#(my_txn);
    // analysis_imp created automatically!
    
    // main_phase inherited - automatically receives and checks!
    // Just configure and add expected transactions
endclass
```

### 3. **Connect in Environment**

```systemverilog
virtual function void connect_phase();
    // Connect analysis port to mailbox
    monitor.analysis_port.connect(scoreboard.monitor_mailbox);
endfunction
```

---

## 🎨 Advanced: Multiple Subscribers

```systemverilog
class my_env extends evm_component;
    
    my_monitor monitor;
    my_scoreboard scoreboard;
    my_coverage_collector coverage;
    my_protocol_checker checker;
    
    virtual function void connect_phase();
        super.connect_phase();
        
        // Monitor broadcasts to MULTIPLE components!
        monitor.analysis_port.connect(scoreboard.monitor_mailbox);
        monitor.analysis_port.connect(coverage.txn_mailbox);
        monitor.analysis_port.connect(checker.txn_mailbox);
        
        log_info("Monitor connected to 3 subscribers", EVM_MEDIUM);
    endfunction
    
endclass
```

**Each component receives the SAME transaction!**

---

## 📊 Scoreboard Modes

### FIFO Mode (Default)

```systemverilog
scoreboard.mode = EVM_SB_FIFO;
// Strict order: First expected matches first actual
```

### Associative Mode

```systemverilog
scoreboard.mode = EVM_SB_ASSOCIATIVE;
// Match by key (override find_matching_expected())
```

### Unordered Mode

```systemverilog
scoreboard.mode = EVM_SB_UNORDERED;
// Any expected can match any actual
```

---

## 🔧 Scoreboard Configuration

```systemverilog
function void build_phase();
    super.build_phase();
    
    scoreboard = new("scoreboard", this);
    
    // Configure
    scoreboard.mode = EVM_SB_FIFO;
    scoreboard.enable_auto_check = 1;      // Check on insert
    scoreboard.stop_on_mismatch = 0;       // Continue on error
    scoreboard.max_expected_queue_size = 1000;
endfunction
```

---

## 📈 Scoreboard Statistics

```systemverilog
function void report_phase();
    super.report_phase();
    
    $display("Scoreboard Stats:");
    $display("  Matches:    %0d", scoreboard.match_count);
    $display("  Mismatches: %0d", scoreboard.mismatch_count);
    $display("  Expected:   %0d", scoreboard.expected_count);
    $display("  Actual:     %0d", scoreboard.actual_count);
endfunction
```

---

## 🚨 Common Mistakes

### ❌ Mistake 1: Forgetting to Connect

```systemverilog
// BAD - No connection!
function void connect_phase();
    super.connect_phase();
    // Missing: monitor.analysis_port.connect(...)
endfunction
```

### ❌ Mistake 2: Not Running main_phase in Scoreboard

```systemverilog
// BAD - Scoreboard never receives
class my_scoreboard extends evm_scoreboard;
    // Missing main_phase to get from mailbox!
endclass
```

### ❌ Mistake 3: Not Inserting Expected

```systemverilog
// BAD - No expected transactions
task main_phase();
    // Monitor sends actual, but no expected to compare!
endtask
```

---

## ✅ Complete Checklist

- [x] **Monitor** has `analysis_port` (built-in to evm_monitor)
- [x] **Monitor** calls `analysis_port.write(txn)` after collecting
- [x] **Scoreboard** has mailbox for receiving
- [x] **Scoreboard** has `main_phase()` to get from mailbox
- [x] **Scoreboard** calls `insert_actual()` on receive
- [x] **Environment** connects in `connect_phase()`
- [x] **Test** inserts expected transactions
- [x] **Test** raises/drops objections

---

## 🎯 Summary

### Monitor Side

```systemverilog
virtual task main_phase();
    txn = collect_transaction();
    analysis_port.write(txn);  // ← Broadcast!
endtask
```

### Scoreboard Side

```systemverilog
mailbox#(T) monitor_mailbox = new();

virtual task main_phase();
    forever begin
        monitor_mailbox.get(txn);  // ← Receive
        insert_actual(txn);        // ← Check
    end
endtask
```

### Environment Connection

```systemverilog
virtual function void connect_phase();
    monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
endfunction
```

---

## 🚀 This is ALREADY Working in EVM!

**All infrastructure is in place:**
- ✅ evm_monitor has analysis_port
- ✅ evm_analysis_port broadcasts to multiple subscribers
- ✅ evm_scoreboard has insert_actual() with auto-check
- ✅ evm_scoreboard has compare_transactions() override
- ✅ Connection via mailbox

**Same as UVM, simpler implementation!** 🎉
