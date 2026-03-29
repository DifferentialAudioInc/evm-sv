# EVM Logging Complete Guide

**Complete reference for EVM logging infrastructure**

---

## 🎯 Overview

EVM provides comprehensive logging with:
- **4 Severity Levels:** INFO, WARNING, ERROR, FATAL
- **6 Verbosity Levels:** NONE, LOW, MEDIUM, HIGH, FULL, DEBUG
- **Console Output:** Always displayed (with verbosity filtering)
- **File Logging:** Optional log file output
- **Automatic Counting:** Track messages by severity
- **UVM-Compatible:** Similar API to UVM reporting

---

## 📊 Severity Levels

| Severity | Value | Behavior | When to Use |
|----------|-------|----------|-------------|
| **INFO** | 0 | Continue, verbosity filtered | Regular information |
| **WARNING** | 1 | Continue, always shown | Unexpected but non-fatal |
| **ERROR** | 2 | Continue, always shown | Test failure condition |
| **FATAL** | 3 | Terminate after delay | Unrecoverable error |

---

## 📈 Verbosity Levels

| Level | Value | Usage |
|-------|-------|-------|
| **EVM_NONE** | 0 | No INFO messages |
| **EVM_LOW** | 100 | Critical milestones only |
| **EVM_MEDIUM** | 200 | Default - important events |
| **EVM_HIGH** | 300 | Detailed transaction info |
| **EVM_FULL** | 400 | Everything |
| **EVM_DEBUG** | 500 | Debug-level detail |

---

## 💡 Basic Usage

### In Classes (Extending evm_log or evm_component)

```systemverilog
class my_driver extends evm_driver;
    
    virtual task main_phase();
        // INFO with verbosity
        log_info("Driver starting", EVM_LOW);
        log_info("Driving transaction", EVM_HIGH);
        log_info("Pin wiggle details", EVM_DEBUG);
        
        // WARNING
        log_warning("Unexpected delay detected");
        
        // ERROR
        log_error("Transaction timeout");
        
        // FATAL (terminates simulation)
        log_fatal("Configuration error - cannot continue");
    endtask
    
endclass
```

### Standalone (Not in EVM Class)

```systemverilog
module tb_top;
    import evm_pkg::*;
    
    initial begin
        // Use global functions
        evm_info("TB_TOP", "Simulation starting", EVM_LOW);
        evm_warning("TB_TOP", "Clock not stable");
        evm_error("TB_TOP", "DUT not responding");
        evm_fatal("TB_TOP", "Critical failure");
    end
endmodule
```

---

## 📝 File Logging

### Enable File Logging

```systemverilog
class my_test extends evm_base_test;
    
    virtual function void build_phase();
        super.build_phase();
        
        // Enable file logging
        evm_report_handler::enable_file_logging("simulation.log");
        
        log_info("File logging enabled", EVM_LOW);
    endfunction
    
    virtual function void final_phase();
        super.final_phase();
        
        // File automatically closed in print_summary()
        // Or manually close:
        // evm_report_handler::disable_file_logging();
    endfunction
endclass
```

### Log File Format

```
================================================================================
EVM Simulation Log
Started: 0
================================================================================
[0] [INFO   ] [test] [BUILD] Build phase starting
[0] [INFO   ] [test.env] [BUILD] Environment built
[100ns] [INFO   ] [test.env.agent.driver] [DRIVE] Driving transaction
[100ns] [WARNING] [test.env.agent.monitor] [CHECK] Parity error detected
[500ns] [ERROR  ] [test.env.scoreboard] [COMPARE] Data mismatch
================================================================================
                        EVM REPORT SUMMARY
================================================================================
[1000ns] INFO messages:    45
[1000ns] WARNINGs:          2
[1000ns] ERRORs:            1
[1000ns] FATALs:            0
================================================================================
[1000ns] *** TEST FAILED with 1 errors ***
================================================================================
```

---

## ⚙️ Configuration

### Set Global Verbosity

```systemverilog
// In test build_phase
function void build_phase();
    super.build_phase();
    
    // Set global verbosity
    evm_report_handler::set_verbosity(EVM_HIGH);
    
    // Or use static method from evm_log
    evm_log::set_global_verbosity(EVM_DEBUG);
endfunction
```

### Stop on Error/Warning

```systemverilog
// Configure error handling
function void build_phase();
    super.build_phase();
    
    // Stop simulation on first error (default: continue)
    evm_report_handler::set_stop_on_error(1);
    
    // Stop on warnings (default: continue)
    evm_report_handler::set_stop_on_warning(1);
    
    // Set max error count before quit
    evm_report_handler::set_max_quit_count(10);
endfunction
```

### Fatal Delay

```systemverilog
// Change delay before $finish (default: 1000ns)
function void build_phase();
    super.build_phase();
    
    // Wait 5us for waveform capture
    evm_report_handler::set_fatal_delay_ns(5000);
endfunction
```

---

## 📊 Statistics

### Get Message Counts

```systemverilog
function void report_phase();
    int infos, warnings, errors, fatals;
    
    infos = evm_report_handler::get_info_count();
    warnings = evm_report_handler::get_warning_count();
    errors = evm_report_handler::get_error_count();
    fatals = evm_report_handler::get_fatal_count();
    
    log_info($sformatf("Messages: I=%0d W=%0d E=%0d F=%0d",
                      infos, warnings, errors, fatals), EVM_LOW);
endfunction
```

### Print Summary

```systemverilog
function void final_phase();
    super.final_phase();
    
    // Print summary (automatically includes file logging)
    evm_report_handler::print_summary();
endfunction
```

---

## 🎨 Message Formatting

### Message Format

```
[TIME] [SEVERITY] [CONTEXT] [ID] MESSAGE [LOCATION]
```

**Example:**
```
[1250ns] [ERROR  ] [test.env.scoreboard] [COMPARE] Expected: 0x1234, Got: 0x5678 [scoreboard.sv:45]
```

### With Source Location

```systemverilog
// Include file and line number
evm_report_handler::evm_report_error(
    "DATA_MISMATCH",           // ID
    "Values don't match",      // Message
    "my_scoreboard.sv",        // Filename
    123,                       // Line number
    "test.env.scoreboard"      // Context
);
```

**Output:**
```
[500ns] [ERROR  ] [test.env.scoreboard] [DATA_MISMATCH] Values don't match [my_scoreboard.sv:123]
```

---

## 🔧 Advanced Usage

### Custom Verbosity Per Component

```systemverilog
class my_monitor extends evm_monitor;
    
    function new(string name, evm_component parent);
        super.new(name, parent);
        
        // Override component verbosity
        set_verbosity(EVM_DEBUG);  // This component always DEBUG
    endfunction
    
endclass
```

### Conditional Logging

```systemverilog
task drive_transaction(my_txn tr);
    if (get_verbosity() >= EVM_HIGH) begin
        log_info($sformatf("Driving: %s", tr.convert2string()), EVM_HIGH);
    end
    
    // Drive transaction...
endtask
```

---

## 📋 Best Practices

### 1. **Use Appropriate Severity**

```systemverilog
// ✅ GOOD
log_info("Transaction sent", EVM_HIGH);        // Normal event
log_warning("Unexpected ready signal");        // Unusual but OK
log_error("Timeout waiting for response");     // Test failure
log_fatal("Null pointer detected");            // Fatal error

// ❌ BAD
log_error("Transaction sent");                 // Too severe
log_info("DUT not responding");                // Too lenient
```

### 2. **Use Appropriate Verbosity**

```systemverilog
// ✅ GOOD
log_info("Test starting", EVM_LOW);            // Major milestone
log_info("Configuring agent", EVM_MEDIUM);     // Configuration
log_info("Sending transaction", EVM_HIGH);     // Each transaction
log_info("Pin state: data=0xFF", EVM_DEBUG);   // Pin-level detail

// ❌ BAD
log_info("Pin wiggle", EVM_LOW);               // Too detailed for LOW
log_info("Test complete", EVM_DEBUG);          // Too important for DEBUG
```

### 3. **Include Context**

```systemverilog
// ✅ GOOD
log_info($sformatf("Received data: 0x%08h", data), EVM_HIGH);
log_error($sformatf("Expected: 0x%08h, Got: 0x%08h", exp, got));

// ❌ BAD
log_info("Got data");                          // What data?
log_error("Mismatch");                         // What values?
```

### 4. **Enable File Logging for Regression**

```systemverilog
// In regression environment
initial begin
    evm_report_handler::enable_file_logging("regression.log");
end
```

---

## 🎯 Quick Reference

### Logging Functions

| Function | Severity | Verbosity Filtered | Use |
|----------|----------|-------------------|-----|
| `log_info(msg, verb)` | INFO | Yes | Normal messages |
| `log_warning(msg)` | WARNING | No | Warnings |
| `log_error(msg)` | ERROR | No | Errors |
| `log_fatal(msg)` | FATAL | No | Fatal errors |

### Configuration Functions

| Function | Purpose |
|----------|---------|
| `set_verbosity(level)` | Set global verbosity |
| `enable_file_logging(filename)` | Enable file logging |
| `disable_file_logging()` | Close log file |
| `set_stop_on_error(1)` | Stop on first error |
| `set_max_quit_count(N)` | Quit after N errors |

### Statistics Functions

| Function | Returns |
|----------|---------|
| `get_info_count()` | INFO message count |
| `get_warning_count()` | WARNING count |
| `get_error_count()` | ERROR count |
| `get_fatal_count()` | FATAL count |
| `print_summary()` | Print final report |

---

## 💻 Complete Example

```systemverilog
class my_test extends evm_base_test;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        // Configure logging
        evm_report_handler::set_verbosity(EVM_HIGH);
        evm_report_handler::enable_file_logging("my_test.log");
        evm_report_handler::set_max_quit_count(5);
        
        log_info("Test configured", EVM_LOW);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        log_info("Test starting", EVM_LOW);
        
        // Run test
        repeat(10) begin
            log_info("Running iteration", EVM_MEDIUM);
            #100ns;
        end
        
        log_info("Test complete", EVM_LOW);
        drop_objection("test");
    endtask
    
    virtual function void final_phase();
        super.final_phase();
        
        // Print summary (auto-closes log file)
        evm_report_handler::print_summary();
    endfunction
endclass
```

---

## 🚀 Summary

**EVM Logging Provides:**
- ✅ 4 severity levels (INFO/WARNING/ERROR/FATAL)
- ✅ 6 verbosity levels (NONE to DEBUG)
- ✅ Console output (always)
- ✅ File logging (optional)
- ✅ Automatic counting
- ✅ Configurable behavior
- ✅ UVM-compatible API

**Simple to use:**
```systemverilog
log_info("Message", EVM_MEDIUM);
log_warning("Warning message");
log_error("Error message");
log_fatal("Fatal error");
```

**Full featured for production verification!** 🎉
