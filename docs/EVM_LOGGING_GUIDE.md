# EVM Logging and Reporting Guide

**EVM - Embedded Verification Methodology**  
**Last Updated:** 2026-03-28  
**Version:** 1.0.0

---

## Overview

EVM provides a comprehensive logging and reporting infrastructure inspired by UVM but optimized for embedded verification. The system supports four severity levels with configurable behavior.

---

## Severity Levels

### 1. EVM_INFO
- **Purpose:** Informational messages
- **Behavior:** Filtered by verbosity level
- **Simulation:** Continues
- **Use for:** Progress updates, debug information, status messages

### 2. EVM_WARNING
- **Purpose:** Potentially problematic conditions
- **Behavior:** Always displayed (not filtered)
- **Simulation:** Continues (unless `stop_on_warning=1`)
- **Use for:** Unexpected but non-fatal conditions

### 3. EVM_ERROR
- **Purpose:** Error conditions
- **Behavior:** Always displayed, counted
- **Simulation:** Continues (unless `stop_on_error=1` or `max_quit_count` reached)
- **Use for:** Protocol violations, assertion failures, data mismatches

### 4. EVM_FATAL
- **Purpose:** Fatal errors requiring immediate termination
- **Behavior:** Always displayed, terminates simulation after delay
- **Simulation:** **Terminates after 1μs delay** (configurable)
- **Use for:** Unrecoverable errors, critical failures

**⚠️ CRITICAL:** FATAL errors include a 1μs delay before `$finish` to allow waveform dumping!

---

## Quick Start

### Basic Usage

```systemverilog
import evm_pkg::*;

class my_test extends evm_base_test;
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // INFO - filtered by verbosity
        log_info("Starting test", EVM_LOW);
        log_info("Detailed step 1", EVM_HIGH);
        
        // WARNING - always shown, simulation continues
        log_warning("Unexpected condition detected");
        
        // ERROR - always shown, simulation continues
        log_error("Protocol violation");
        
        // FATAL - always shown, simulation terminates after 1us
        // log_fatal("Unrecoverable error"); // Would end simulation!
        
        drop_objection("test");
    endtask
    
endclass
```

### Using Global Functions

```systemverilog
// Simpler syntax (no class needed)
evm_info("TEST", "Starting simulation", EVM_LOW);
evm_warning("PROTO", "Unexpected response");
evm_error("CHECK", "Data mismatch");
evm_fatal("INIT", "Initialization failed");
```

---

## Verbosity Levels

Control message filtering:

```systemverilog
typedef enum int {
    EVM_NONE   = 0,   // No messages
    EVM_LOW    = 100, // Critical only
    EVM_MEDIUM = 200, // Default level
    EVM_HIGH   = 300, // Detailed
    EVM_FULL   = 400, // Everything
    EVM_DEBUG  = 500  // Extremely detailed
} evm_verbosity_e;
```

### Setting Verbosity

```systemverilog
// Set global verbosity
evm_report_handler::set_verbosity(EVM_HIGH);

// Or using evm_log method
evm_log::set_global_verbosity(EVM_HIGH);

// From command line
// +EVM_VERBOSITY=300
```

### Verbosity Filtering

```systemverilog
// These are filtered based on verbosity setting
log_info("Critical message", EVM_LOW);    // Shown if verbosity >= 100
log_info("Normal message", EVM_MEDIUM);   // Shown if verbosity >= 200
log_info("Detailed message", EVM_HIGH);   // Shown if verbosity >= 300
log_info("Debug message", EVM_DEBUG);     // Shown if verbosity >= 500

// WARNING, ERROR, FATAL are ALWAYS shown (not filtered)
```

---

## Configuration Options

### Stop on Error

```systemverilog
// Make ERRORs stop simulation (default: continue)
evm_report_handler::set_stop_on_error(1);

// Example:
log_error("This will stop simulation");  // Calls $stop
```

### Stop on Warning

```systemverilog
// Make WARNINGs stop simulation (default: continue)
evm_report_handler::set_stop_on_warning(1);

// Example:
log_warning("This will stop simulation");  // Calls $stop
```

### Maximum Error Count

```systemverilog
// Stop simulation after N errors
evm_report_handler::set_max_quit_count(10);

// When error count reaches 10:
// - Waits 1μs for waveform capture
// - Calls $finish(2)
```

### Fatal Delay

```systemverilog
// Configure delay before $finish on FATAL (default: 1000ns = 1μs)
evm_report_handler::set_fatal_delay_ns(2000);  // 2μs delay

// CRITICAL: This delay allows simulator to dump waveforms!
```

---

## Message Format

### Standard Format

```
[TIME] [SEVERITY] [CONTEXT] [ID] MESSAGE [LOCATION]
```

### Examples

```
[0] [INFO   ] [TEST] Starting simulation
[1000] [WARNING] [test.agent.driver] [PROTO] Unexpected response
[2500] [ERROR  ] [test.scoreboard] [CHECK] Data mismatch expected=0x42 actual=0x43
[5000] [FATAL  ] [test] [INIT] Critical initialization failed
```

### With File Location

```systemverilog
evm_report_handler::evm_report_error(
    "CHECK",
    "Data mismatch",
    `__FILE__,  // Filename
    `__LINE__,  // Line number
    get_full_name()  // Component path
);

// Output:
// [1000] [ERROR  ] [test.scoreboard] [CHECK] Data mismatch [my_test.sv:42]
```

---

## Statistics and Reporting

### Get Counts

```systemverilog
int info_cnt = evm_report_handler::get_info_count();
int warn_cnt = evm_report_handler::get_warning_count();
int err_cnt  = evm_report_handler::get_error_count();
int fatal_cnt = evm_report_handler::get_fatal_count();
```

### Print Summary

```systemverilog
// In test's final_phase or report_phase
virtual function void final_phase();
    super.final_phase();
    evm_report_handler::print_summary();
endfunction
```

**Output:**
```
==============================================================================
                        EVM REPORT SUMMARY
==============================================================================
[100000] INFO messages:    45
[100000] WARNINGs:          2
[100000] ERRORs:            0
[100000] FATALs:            0
==============================================================================
[100000] *** TEST PASSED with 2 warnings ***
==============================================================================
```

### Reset Counts

```systemverilog
// Reset all counters
evm_report_handler::reset_counts();
```

---

## Advanced Usage

### With Component Hierarchy

```systemverilog
class my_driver extends evm_driver;
    
    virtual task main_phase();
        super.main_phase();
        
        // Context automatically includes component path
        log_info("Starting driver", EVM_LOW);
        // Output: [100] [INFO   ] [test.agent.driver] [INFO] Starting driver
        
        if (error_condition) begin
            log_error("Protocol violation detected");
            // Output: [200] [ERROR  ] [test.agent.driver] [ERROR] Protocol violation detected
        end
    endtask
    
endclass
```

### Custom Message IDs

```systemverilog
// Use meaningful IDs for categorization
evm_info("SIM_START", "Simulation beginning", EVM_LOW);
evm_warning("BUS_TIMEOUT", $sformatf("Timeout after %0d cycles", cycles));
evm_error("CRC_ERR", $sformatf("CRC mismatch: calc=0x%h exp=0x%h", calc, exp));
```

### Conditional Logging

```systemverilog
// Only log at high verbosity
if (evm_report_handler::get_verbosity() >= EVM_HIGH) begin
    string details = generate_detailed_report();  // Expensive operation
    log_info(details, EVM_HIGH);
end
```

---

## Migration from Old Logging

### Backward Compatibility

Old code continues to work:

```systemverilog
// Old style (still works)
log_info("Message", EVM_MED);
log_warning("Warning");
log_error("Error");

// Automatically uses evm_report_handler behind the scenes
```

### New log_fatal Method

```systemverilog
// NEW: Fatal logging with automatic termination
log_fatal("Critical failure");
// - Displays message
// - Waits 1μs (configurable)
// - Calls $finish(2)
```

---

## Best Practices

### 1. Use Appropriate Severity

```systemverilog
// ✅ GOOD
log_info("Transaction sent", EVM_HIGH);         // Progress info
log_warning("Queue size exceeds threshold");     // Unexpected but ok
log_error("Response timeout");                   // Error condition
log_fatal("Cannot open essential file");         // Unrecoverable

// ❌ BAD
log_error("Transaction sent");  // Too severe
log_info("Response timeout");   // Too lenient
```

### 2. Use Meaningful IDs

```systemverilog
// ✅ GOOD
evm_error("AXI_TIMEOUT", "No response after 1000 cycles");
evm_warning("FIFO_FULL", "Output FIFO reached capacity");

// ❌ BAD
evm_error("ERROR", "Something went wrong");
log_error("Bad thing happened");
```

### 3. Include Context

```systemverilog
// ✅ GOOD
log_error($sformatf("Expected 0x%h, got 0x%h", expected, actual));
log_warning($sformatf("Retry %0d/%0d failed", retry, max_retries));

// ❌ BAD
log_error("Mismatch");
log_warning("Retry failed");
```

### 4. Use Verbosity Appropriately

```systemverilog
log_info("Test starting", EVM_LOW);              // Always want to see
log_info("Phase transition", EVM_MEDIUM);        // Normal operation
log_info("Transaction details", EVM_HIGH);       // Detailed tracking
log_info("Internal state dump", EVM_DEBUG);      // Debug only
```

### 5. Fatal Only for Unrecoverable Errors

```systemverilog
// ✅ GOOD uses of FATAL
log_fatal("Cannot open stimulus file");
log_fatal("Memory allocation failed");
log_fatal("Critical register inaccessible");

// ❌ BAD uses of FATAL (use ERROR instead)
log_fatal("Single transaction failed");  // Can continue
log_fatal("Unexpected response");         // Not unrecoverable
```

---

## Common Patterns

### Test Result Checking

```systemverilog
virtual function void check_phase();
    super.check_phase();
    
    if (scoreboard.get_mismatch_count() > 0) begin
        log_error($sformatf("Scoreboard found %0d mismatches",
                           scoreboard.get_mismatch_count()));
    end else begin
        log_info("All transactions matched", EVM_LOW);
    end
endfunction
```

### Timeout Handling

```systemverilog
task wait_for_ready(int timeout_cycles);
    int count = 0;
    
    while (!vif.ready && count < timeout_cycles) begin
        @(posedge vif.clk);
        count++;
    end
    
    if (count >= timeout_cycles) begin
        log_error($sformatf("Timeout waiting for ready after %0d cycles",
                           timeout_cycles));
    end
endtask
```

### Debug Dumping

```systemverilog
task dump_state();
    if (evm_report_handler::get_verbosity() >= EVM_DEBUG) begin
        log_info("=== State Dump ===", EVM_DEBUG);
        log_info($sformatf("  Register A: 0x%h", reg_a), EVM_DEBUG);
        log_info($sformatf("  Register B: 0x%h", reg_b), EVM_DEBUG);
        log_info($sformatf("  Status:     0x%h", status), EVM_DEBUG);
    end
endtask
```

---

## Comparison with UVM

| Feature | UVM | EVM | Notes |
|---------|-----|-----|-------|
| Severity Levels | INFO, WARNING, ERROR, FATAL | Same | Identical |
| Verbosity | UVM_NONE..UVM_DEBUG | EVM_NONE..EVM_DEBUG | Similar values |
| Message IDs | Yes | Yes | Same concept |
| File/Line | `__FILE__`, `__LINE__` | Same | Same usage |
| Report Catcher | Yes | No | Too complex for EVM |
| Report Server | Yes (complex) | No | Simplified singleton |
| Actions | Complex bitmap | Simple | Streamlined |
| Stop on Error | Yes | Yes | Configurable |
| Max Quit Count | Yes | Yes | Same behavior |
| **Fatal Delay** | **No** | **Yes (1μs)** | **EVM adds waveform capture** |

---

## Troubleshooting

### Messages Not Appearing

```systemverilog
// Check verbosity setting
$display("Current verbosity: %0d", evm_report_handler::get_verbosity());

// Ensure message verbosity <= global verbosity
log_info("Test", EVM_LOW);    // Will show if verbosity >= 100
log_info("Test", EVM_DEBUG);  // Only shows if verbosity >= 500
```

### Too Many Messages

```systemverilog
// Reduce verbosity
evm_report_handler::set_verbosity(EVM_LOW);

// Or filter specific components
// (Future enhancement - not implemented yet)
```

### Simulation Not Stopping on Error

```systemverilog
// Enable stop on error
evm_report_handler::set_stop_on_error(1);

// Or set max error count
evm_report_handler::set_max_quit_count(1);
```

### Waveforms Not Captured on Fatal

```systemverilog
// Increase fatal delay if needed
evm_report_handler::set_fatal_delay_ns(5000);  // 5μs

// Ensure simulator waveform dumping is configured
initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_top);
end
```

---

## Summary

**Key Features:**
- ✅ Four severity levels (INFO, WARNING, ERROR, FATAL)
- ✅ Verbosity filtering for INFO messages
- ✅ WARNING/ERROR always shown, simulation continues
- ✅ FATAL terminates with configurable delay for waveform capture
- ✅ Message counting and statistics
- ✅ Configurable behavior (stop on error/warning)
- ✅ Backward compatible with existing code
- ✅ UVM-inspired but lightweight

**Critical Points:**
- 🔴 FATAL errors wait 1μs before $finish (for waveforms)
- 🟡 WARNING/ERROR continue simulation by default
- 🟢 INFO messages filtered by verbosity
- 🔵 All messages counted for summary reporting

---

**For more information, see:**
- `evm_report_handler.sv` - Implementation
- `evm_log.sv` - Backward-compatible wrapper
- `CLAUDE.md` - Coding standards
- `examples/` - Usage examples

---

**End of EVM Logging Guide**
