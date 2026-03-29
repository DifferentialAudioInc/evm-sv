# Quiescence Counter Example

This example demonstrates the **automatic test completion** feature using EVM's built-in Quiescence Counter (QC).

## Overview

The Quiescence Counter is a key EVM component that automatically manages test objections based on activity detection. Instead of manually raising and dropping objections, components simply call `qc.tick()` whenever activity occurs, and the QC handles the rest.

## Key Concepts

### Traditional Approach (Manual Objections)
```systemverilog
virtual task main_phase();
    super.main_phase();
    raise_objection("test");  // Manual
    
    // Test activity
    run_sequences();
    
    drop_objection("test");    // Manual - easy to forget!
endtask
```

### QC Approach (Automatic)
```systemverilog
function new(string name = "my_test");
    super.new(name);
    enable_quiescence_counter(200);  // Enable with 200 cycle threshold
endfunction

virtual task main_phase();
    super.main_phase();
    
    // NO manual objections needed!
    run_sequences();
    
    // QC auto-drops objection after 200 cycles of inactivity
endtask

// In driver/monitor:
task drive_transaction();
    // Drive signals...
    qc.tick();  // Signal activity
endtask
```

## How It Works

1. **Enable QC in test constructor:**
   ```systemverilog
   enable_quiescence_counter(threshold_cycles);
   ```

2. **QC is created automatically in build_phase:**
   - `evm_base_test.build_phase()` creates the QC component
   - QC becomes a child component in the hierarchy

3. **Pass QC reference to active components:**
   ```systemverilog
   driver.set_qc(qc);
   monitor.set_qc(qc);
   ```

4. **Components signal activity:**
   ```systemverilog
   qc.tick();  // Called on each transaction
   ```

5. **QC auto-manages objections:**
   - Raises objection on first `tick()`
   - Resets inactivity counter on each `tick()`
   - Drops objection after `threshold_cycles` of inactivity
   - Test ends gracefully!

## Benefits

✅ **No manual objection management** - Eliminates common bug source  
✅ **Automatic test completion** - Detects when system goes idle  
✅ **Prevents early termination** - Watchdog for ongoing activity  
✅ **Configurable threshold** - Tune for your system timing  
✅ **Statistics reporting** - Visibility into activity patterns  

## Files

- `qc_test.sv` - Complete example with QC-enabled and manual tests
  - `qc_example_test` - Uses built-in QC (recommended)
  - `manual_test` - Traditional manual objections (for comparison)

## Running the Example

```bash
# With your simulator (example using Questa/ModelSim):
vlog -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv qc_test.sv
vsim -c qc_test -do "run -all; quit"

# Or with VCS:
vcs -sverilog +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv qc_test.sv
./simv

# Or with Xcelium:
xrun -sv +incdir+../../vkit/src ../../vkit/src/evm_pkg.sv qc_test.sv
```

## Expected Output

The test will:
1. Start 10 transactions
2. Driver calls `qc.tick()` on each transaction
3. QC raises objection on first tick
4. After last transaction, 200 cycles of inactivity pass
5. QC drops objection automatically
6. Test completes gracefully
7. QC statistics are printed

## Configuration

### QC Threshold Guidelines

Choose threshold based on your transaction timing:

```systemverilog
// Fast transactions (~100ns)
enable_quiescence_counter(200);  // 200ns wait

// Medium transactions (~1us)
enable_quiescence_counter(2000);  // 2us wait

// Slow transactions (~10us)
enable_quiescence_counter(20000);  // 20us wait
```

**Rule of thumb:** Set threshold to 2-3x your longest transaction time.

### Advanced Options

```systemverilog
// Enable with custom threshold
enable_quiescence_counter(500);

// Get QC handle for direct control
evm_qc my_qc = get_qc();
my_qc.set_threshold(1000);
my_qc.disable();  // Temporarily disable
my_qc.enable();   // Re-enable

// Check status
if (is_qc_enabled()) begin
    $display("QC is active");
end
```

## When to Use QC

### ✅ Use QC when:
- Transaction completion time is unpredictable
- Multiple agents are active
- Activity may occur at random times
- You want automatic test completion

### ❌ Don't use QC when:
- Exact test duration is known
- No ongoing background activity
- Simple sequential tests
- You need precise control over test end time

## Common Patterns

### Pattern 1: Single Agent
```systemverilog
class my_test extends evm_base_test;
    my_agent agent;
    
    function new(string name);
        super.new(name);
        enable_quiescence_counter(200);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        agent.driver.set_qc(qc);
    endfunction
endclass
```

### Pattern 2: Multiple Agents
```systemverilog
class my_env extends evm_env;
    my_agent agent1, agent2;
    evm_qc qc;  // Shared QC
    
    function void set_qc(evm_qc qc_handle);
        this.qc = qc_handle;
        agent1.driver.set_qc(qc);
        agent2.driver.set_qc(qc);
        agent1.monitor.set_qc(qc);
        agent2.monitor.set_qc(qc);
    endfunction
endclass
```

### Pattern 3: Standalone QC (not in base_test)
```systemverilog
class my_test extends evm_base_test;
    evm_qc custom_qc;
    
    virtual function void build_phase();
        super.build_phase();
        // Create custom QC with different settings
        custom_qc = new("custom_qc", this);
        custom_qc.set_threshold(5000);
    endfunction
endclass
```

## See Also

- `evm_qc.sv` - QC implementation
- `evm_base_test.sv` - Base test with built-in QC support
- `evm_root.sv` - Objection mechanism
- `docs/EVM_PHASING_GUIDE.md` - Phase and objection details
