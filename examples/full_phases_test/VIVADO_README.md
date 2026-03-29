# Running EVM Full Phases Test in Vivado

**Complete guide for Vivado simulation**

---

## Overview

This example is ready to run in Xilinx Vivado with:
- ✅ **Clock Agent** (`clk_agent.sv`) - Generates 100MHz clock
- ✅ **Reset Agent** (`rst_agent.sv`) - Generates active-low reset
- ✅ **Simple DUT** (`simple_dut.sv`) - Counter with data path
- ✅ **Complete Testbench** (`tb_top.sv`) - Full EVM test with all 12 phases
- ✅ **Vivado Scripts** - Automated project setup

---

## Quick Start

### Method 1: Vivado GUI (Recommended for First Time)

1. **Open Vivado**
   ```bash
   cd c:\evm\evm-sv\examples\full_phases_test
   vivado
   ```

2. **In Vivado TCL Console:**
   ```tcl
   cd c:/evm/evm-sv/examples/full_phases_test
   source vivado_setup.tcl
   ```

3. **Run Simulation:**
   - Click: **Flow → Run Simulation → Run Behavioral Simulation**
   - Or in TCL Console: `launch_simulation`

4. **View Results:**
   - Check TCL Console for test output
   - View waveforms in simulation window
   - Check `full_phases_test.log` for detailed log

---

### Method 2: Command Line (Batch Mode)

```bash
cd c:\evm\evm-sv\examples\full_phases_test

# Create project and run simulation
vivado -mode batch -source vivado_run_sim.tcl
```

---

### Method 3: Manual Setup

If you prefer to create the project manually:

1. **Create New Project:**
   - File → Project → New...
   - Project name: `evm_full_phases_test`
   - Project type: RTL Project
   - Do not specify sources
   - Part: Any 7-series or UltraScale (e.g., xc7a35tcpg236-1)

2. **Add EVM Package Files:**
   ```
   Add Sources → Add or create simulation sources
   Navigate to: c:/evm/evm-sv/vkit/src/
   Add all .sv files
   ```

3. **Add Test Files:**
   ```
   Navigate to: c:/evm/evm-sv/examples/full_phases_test/
   Add:
   - clk_rst_if.sv
   - clk_agent.sv
   - rst_agent.sv
   - base_test.sv
   - simple_dut.sv
   - tb_top.sv (set as top)
   ```

4. **Run Simulation:**
   - Flow → Run Simulation → Run Behavioral Simulation

---

## What the Test Does

### DUT (`simple_dut.sv`)
- 8-bit counter that increments every clock cycle
- Data path that adds counter to input data
- Registered outputs

### Agents
- **Clock Agent:** Generates 100MHz clock
- **Reset Agent:** Generates 10-cycle active-low reset pulse

### Test Flow
1. Build Phase - Creates environment and agents
2. Connect Phase - Connects agents to interfaces
3. Reset Phase - Applies reset via reset agent
4. Main Phase - Runs test stimulus for 1μs
5. Report Phase - Prints results and summary

---

## Expected Output

```
================================================================================
  EVM FULL PHASES EXAMPLE
  Demonstrates all 12 phases with proper super calls
================================================================================

[0] [INFO   ] === TEST build_phase ===
[0] [INFO   ] Test environment created
[0] [INFO   ] === TEST connect_phase ===
[0] [INFO   ] === TEST end_of_elaboration_phase ===
[0] [INFO   ] Component Hierarchy:
[0] [INFO   ]   full_phases_test
[0] [INFO   ]     env
[0] [INFO   ]       clk_agt
[0] [INFO   ]       rst_agt
[0] [INFO   ] === TEST reset_phase ===
[50ns] [INFO   ] Reset asserted
[100ns] [INFO   ] Reset de-asserted
[0] [INFO   ] === TEST configure_phase ===
[0] [INFO   ] === TEST main_phase START ===
[1us] [INFO   ] === TEST main_phase END ===
[0] [INFO   ] === TEST shutdown_phase ===
[0] [INFO   ] === TEST extract_phase ===
[0] [INFO   ] === TEST check_phase ===
[0] [INFO   ] Test PASSED
[0] [INFO   ] === TEST report_phase ===
[0] [INFO   ] === TEST final_phase ===

==============================================================================
                        EVM REPORT SUMMARY
==============================================================================
[1050ns] INFO messages:    25
[1050ns] WARNINGs:          0
[1050ns] ERRORs:            0
[1050ns] FATALs:            0
==============================================================================
[1050ns] *** TEST PASSED ***
==============================================================================

================================================================================
  SIMULATION COMPLETE
================================================================================
```

---

## Viewing Waveforms

After simulation starts:

1. **Add Signals to Waveform:**
   - In Scope window, expand `tb_top`
   - Select `dut` instance
   - Right-click → Add to Wave Window

2. **Useful Signals:**
   ```
   tb_top/sys_clk          - System clock
   tb_top/rst_vif/reset_n  - Reset signal
   tb_top/dut/counter      - DUT counter
   tb_top/dut/data_in      - Input data
   tb_top/dut/data_out     - Output data
   tb_top/dut/data_valid   - Valid signal
   tb_top/dut/data_ready   - Ready signal
   ```

3. **Zoom to Fit:**
   - Click "Zoom Fit" button in waveform toolbar

---

## Troubleshooting

### Issue: "Cannot find include file"

**Fix:**
```tcl
# In vivado_setup.tcl, ensure paths are correct:
../../vkit/src/evm_pkg.sv  # Should resolve to c:/evm/evm-sv/vkit/src/
```

### Issue: "Undefined macro or package"

**Fix:** Check compile order in Vivado:
1. Sources window → Simulation Sources
2. Right-click → Set File Compilation Order
3. Ensure `evm_pkg.sv` is compiled first

### Issue: Simulation hangs

**Fix:** Check objections - the test should automatically end after 1μs.
- If stuck, check TCL Console for `[EVM] Waiting for objections...`
- Force quit and check for missing `drop_objection()` calls

### Issue: No output in TCL Console

**Fix:** Check simulator settings:
- Tools → Settings → Simulation
- Ensure "Enable verbose mode" is checked

---

## Files Generated

After running simulation:

```
full_phases_test/
├── vivado_project/               ← Vivado project directory
│   ├── evm_full_phases_test.xpr  ← Project file
│   └── ...                       ← Other project files
├── full_phases_test.vcd          ← VCD waveform dump
├── full_phases_test.log          ← EVM log file
└── ...
```

---

## Customization

### Change Target Part

Edit `vivado_setup.tcl`:
```tcl
# Change from 7-series to UltraScale:
create_project $project_name $project_dir -part xcvu9p-flga2104-2-i -force
```

### Increase Simulation Time

Edit `vivado_run_sim.tcl`:
```tcl
# Change from 10ms to longer:
run 100ms
```

### Change Clock Frequency

Edit `clk_agent.sv`:
```systemverilog
// In clk_agent_cfg:
freq_mhz = 200.0;  // 200MHz instead of 100MHz
```

### Change Reset Duration

Edit `rst_agent.sv`:
```systemverilog
// In rst_agent_cfg:
reset_cycles = 20;  // 20 cycles instead of 10
```

---

## Advanced: Adding Your Own DUT

1. **Replace `simple_dut.sv` with your DUT**

2. **Update `tb_top.sv` DUT instantiation:**
   ```systemverilog
   your_dut_name dut(
       .clk(sys_clk),
       .reset_n(rst_vif.reset_n),
       // Your ports...
   );
   ```

3. **Update interfaces and agents as needed**

4. **Modify test stimulus in `base_test.sv`**

---

## Next Steps

After successfully running in Vivado:

1. **Modify the DUT** - Add your own design
2. **Add monitors** - Observe DUT outputs
3. **Add scoreboards** - Check results automatically
4. **Add coverage** - Use Vivado coverage tools
5. **Create test library** - Multiple test scenarios

---

## Summary

**Vivado-Ready Features:**
- ✅ Automated project setup (`vivado_setup.tcl`)
- ✅ One-command simulation (`vivado_run_sim.tcl`)
- ✅ Clock and reset agents
- ✅ Simple example DUT
- ✅ Complete EVM test with all 12 phases
- ✅ Waveform dumping enabled
- ✅ File logging enabled

**Just run `source vivado_setup.tcl` and you're ready to simulate!**
