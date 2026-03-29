# Minimal Test Example

**The simplest possible EVM test** - Start here to learn EVM basics!

---

## Overview

This example demonstrates the absolute minimum code needed for an EVM test. It shows:
- Basic test structure
- Quiescence counter for automatic test completion
- Manual objections (optional)
- Phase execution
- Result reporting

---

## What This Example Shows

### ✅ Essential EVM Features

1. **Test Class** - Extends `evm_base_test`
2. **Quiescence Counter** - Automatic objection management
3. **Phase Methods** - build_phase, main_phase, final_phase
4. **Objections** - Both manual and automatic (via QC)
5. **Logging** - Using `evm_report_handler`

---

## File Structure

```
minimal_test/
├── README.md           ← You are here
└── minimal_test.sv     ← Complete test in one file
```

---

## Code Walkthrough

### 1. Test Class

```systemverilog
class minimal_test extends evm_base_test;
    evm_qc qc;  // Quiescence counter
```

### 2. Build Phase

```systemverilog
virtual function void build_phase();
    super.build_phase();  // ALWAYS first!
    
    qc = new("qc", this);
    qc.set_threshold(50);  // Auto-drop after 50 idle cycles
endfunction
```

### 3. Main Phase

```systemverilog
virtual task main_phase();
    super.main_phase();  // ALWAYS first!
    
    raise_objection("test");
    
    // Simulate activity
    repeat(10) begin
        qc.tick();  // Signal activity
        #10ns;
    end
    
    drop_objection("test");
    // QC will auto-drop after 50 cycles of inactivity
endtask
```

### 4. Final Phase

```systemverilog
virtual function void final_phase();
    super.final_phase();
    evm_report_handler::print_summary();
endfunction
```

---

## Running the Example

### With Questa/ModelSim

```bash
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv minimal_test.sv
vsim -c minimal_test_top -do "run -all; quit"
```

### With VCS

```bash
vcs -sverilog +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv minimal_test.sv
./simv
```

### With Xcelium

```bash
xrun -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv minimal_test.sv
```

---

## Expected Output

```
[0] [INFO   ] Minimal test built
[0] [INFO   ] ========================================
[0] [INFO   ]    MINIMAL TEST STARTING
[0] [INFO   ] ========================================
[10ns] [INFO   ] Test activity...
[20ns] [INFO   ] Test activity...
...
[100ns] [INFO   ] Test stimulus complete - waiting for quiescence...
[150ns] [INFO   ] Quiescence detected after 50 inactive cycles
[150ns] [INFO   ] ========================================
[150ns] [INFO   ]    MINIMAL TEST COMPLETE
[150ns] [INFO   ] ========================================

==============================================================================
                        EVM REPORT SUMMARY
==============================================================================
[150ns] INFO messages:    15
[150ns] WARNINGs:          0
[150ns] ERRORs:            0
[150ns] FATALs:            0
==============================================================================
[150ns] *** TEST PASSED ***
==============================================================================
```

---

## Key Concepts Demonstrated

### 1. Quiescence Counter (QC)

**Problem:** Manually managing objections is error-prone  
**Solution:** QC automatically raises/drops objections based on activity

```systemverilog
qc.tick();  // Call this on each activity
// QC raises objection on first tick()
// QC drops objection after threshold cycles of no tick()
```

### 2. Always Call Super First

```systemverilog
virtual function void build_phase();
    super.build_phase();  // ← CRITICAL!
    // Your code
endfunction
```

### 3. Objection Pattern

```systemverilog
raise_objection("name");  // Prevents phase from ending
// Do work
drop_objection("name");   // Allows phase to end
```

---

## What's Next?

After understanding this minimal example:

1. **Next:** Try `examples/qc_test/` - More detailed QC usage
2. **Then:** Try `examples/complete_test/` - Monitor → Scoreboard
3. **Finally:** Try `examples/full_phases_test/` - All 12 phases

---

## Modification Ideas

Try these modifications to learn more:

### 1. Change QC Threshold

```systemverilog
qc.set_threshold(100);  // Longer wait
qc.set_threshold(10);   // Shorter wait
```

### 2. Add More Activity

```systemverilog
repeat(100) begin  // More iterations
    qc.tick();
    #10ns;
end
```

### 3. Add File Logging

```systemverilog
virtual function void build_phase();
    super.build_phase();
    evm_report_handler::enable_file_logging("minimal_test.log");
    evm_report_handler::set_verbosity(EVM_HIGH);
    // ...
endfunction
```

### 4. Try Manual Objections Only

```systemverilog
// Don't create QC
virtual task main_phase();
    super.main_phase();
    raise_objection("test");
    
    #1us;  // Fixed duration
    
    drop_objection("test");
endtask
```

---

## Common Mistakes

### ❌ Forgetting to Drop Objection

```systemverilog
raise_objection("test");
// Do work
// FORGOT to drop_objection()!
// Test will hang!
```

**Fix:** Always pair raise with drop, or use QC!

### ❌ Not Calling Super

```systemverilog
virtual function void build_phase();
    // MISSING: super.build_phase();
    qc = new("qc", this);
endfunction
```

**Fix:** Always call super.phase() first!

---

## Summary

**This is the simplest EVM test possible:**
- ✅ 50 lines of code
- ✅ Automatic test completion via QC
- ✅ Proper phase structure
- ✅ Complete result reporting

**Perfect starting point for learning EVM!**
