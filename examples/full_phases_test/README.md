# EVM Full Phases Test Example

Complete example demonstrating **all 12 EVM phases** with proper super calls.

---

## 🎯 What This Example Shows

1. **All 12 Phases** - Every phase properly implemented
2. **Super Calls** - Always call `super.phase()` first!
3. **Clock Agent** - Monitors clock frequency
4. **Reset Agent** - Drives and monitors reset
5. **Base Test** - Reusable test infrastructure
6. **Simple DUT** - Basic counter/passthrough
7. **Full Environment** - Complete setup

---

## 📁 Files

| File | Description |
|------|-------------|
| `clk_rst_if.sv` | Clock, reset, and DUT interfaces |
| `clk_agent.sv` | Clock agent with monitor |
| `rst_agent.sv` | Reset agent with driver and monitor |
| `base_test.sv` | Base test and environment with ALL phases |
| `simple_dut.sv` | Simple DUT (counter + passthrough) |
| `tb_top.sv` | Testbench top module |

---

## 🔄 The 12 Phases

### Build-Time Phases (Functions)
1. **build_phase()** - Create components
2. **connect_phase()** - Make TLM connections
3. **end_of_elaboration_phase()** - Final checks, print topology
4. **start_of_simulation_phase()** - Pre-simulation initialization

### Run-Time Phases (Tasks)
5. **reset_phase()** - Apply reset to DUT
6. **configure_phase()** - Configure DUT
7. **main_phase()** - Main test execution (with objections)
8. **shutdown_phase()** - Graceful shutdown

### Cleanup Phases (Functions)
9. **extract_phase()** - Extract results
10. **check_phase()** - Check results
11. **report_phase()** - Report results
12. **final_phase()** - Final cleanup

---

## 💡 Key Patterns Demonstrated

### 1. Always Call Super First!

```systemverilog
virtual function void build_phase();
    super.build_phase();  // ← ALWAYS first!
    
    // Your code here
endfunction
```

### 2. Create in build_phase

```systemverilog
virtual function void build_phase();
    super.build_phase();
    
    env = new("env", this);
    env.clk_agt = new("clk_agt", env);
endfunction
```

### 3. Connect in connect_phase

```systemverilog
virtual function void connect_phase();
    super.connect_phase();
    
    monitor.analysis_port.connect(scoreboard.analysis_imp.get_mailbox());
endfunction
```

### 4. Print Topology in end_of_elaboration

```systemverilog
virtual function void end_of_elaboration_phase();
    super.end_of_elaboration_phase();
    
    print_topology();  // See component hierarchy
endfunction
```

### 5. Use Objections in main_phase

```systemverilog
virtual task main_phase();
    super.main_phase();
    
    raise_objection("test");
    
    // Test stimulus
    
    drop_objection("test");
endtask
```

---

## 🚀 How to Run

### With VCS
```bash
vcs -sverilog -full64 \
    -f filelist.f \
    +incdir+../../vkit/src \
    -timescale=1ns/1ps

./simv
```

### With Questa
```bash
vlog -sv \
    +incdir+../../vkit/src \
    -f filelist.f \
    -timescale 1ns/1ps

vsim -c tb_top -do "run -all"
```

### With Xcelium
```bash
xrun -sv \
    +incdir+../../vkit/src \
    -f filelist.f \
    -timescale 1ns/1ps
```

---

## 📊 Expected Output

```
================================================================================
  EVM FULL PHASES EXAMPLE
  Demonstrates all 12 phases with proper super calls
================================================================================

[0] [INFO   ] [full_phases_test] [INFO] === TEST build_phase ===
[0] [INFO   ] [full_phases_test.env] [INFO] === build_phase ===
[0] [INFO   ] [full_phases_test.env] [INFO] Environment components created
...
[0] [INFO   ] [full_phases_test] [INFO] === TEST end_of_elaboration_phase ===
[0] [INFO   ] [full_phases_test] [INFO] Component Topology:
[0] [INFO   ] [full_phases_test] [INFO]   full_phases_test
[0] [INFO   ] [full_phases_test] [INFO]     env
[0] [INFO   ] [full_phases_test] [INFO]       clk_agt
[0] [INFO   ] [full_phases_test] [INFO]         monitor
[0] [INFO   ] [full_phases_test] [INFO]       rst_agt
[0] [INFO   ] [full_phases_test] [INFO]         driver
[0] [INFO   ] [full_phases_test] [INFO]         monitor
...
================================================================================
                        EVM REPORT SUMMARY
================================================================================
[1000ns] INFO messages:    XX
[1000ns] WARNINGs:          0
[1000ns] ERRORs:            0
[1000ns] FATALs:            0
================================================================================
[1000ns] *** TEST PASSED ***
================================================================================
```

---

## ✨ What You Learn

1. **Phase Order** - Understand the 12-phase flow
2. **Super Calls** - Why they're critical
3. **Hierarchy** - How components nest
4. **Objections** - How to control test execution
5. **Topology** - How to debug structure
6. **Agents** - How to build reusable components

---

## 🎯 Key Takeaways

- ✅ **Always call `super.phase()` first!**
- ✅ **Build in build_phase, connect in connect_phase**
- ✅ **Use objections in main_phase**
- ✅ **Print topology in end_of_elaboration**
- ✅ **Report in final_phase**

**This is the foundation for all EVM tests!** 🎉
