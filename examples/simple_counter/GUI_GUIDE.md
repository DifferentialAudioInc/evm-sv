# Vivado GUI Simulation Guide

## Step 1: Create the Vivado Project (One-Time Setup)

### Option A: Using Vivado GUI

1. **Launch Vivado**
   - Start Vivado application

2. **In Vivado Tcl Console (bottom of window):**
   ```tcl
   cd c:/evm/evm-sv/examples/simple_counter/sim
   source create_vivado_project.tcl
   ```

3. **Wait** for "Project Created Successfully!" message

### Option B: Using Script (if PATH is set)

```powershell
cd c:\evm\evm-sv\examples\simple_counter\sim
vivado -mode tcl -source create_vivado_project.tcl
```

---

## Step 2: Open the Project in Vivado GUI

1. **Double-click** the project file:
   ```
   c:\evm\evm-sv\examples\simple_counter\sim\simple_counter_project\simple_counter_project.xpr
   ```

   OR

2. **In Vivado:**
   - File → Open Project
   - Navigate to: `c:\evm\evm-sv\examples\simple_counter\sim\simple_counter_project`
   - Select: `simple_counter_project.xpr`
   - Click Open

---

## Step 3: View Project Hierarchy

Once project is open, you'll see:

### **Sources** Window (left side):
```
Design Sources
  └─ xil_defaultlib
      └─ simple_counter (rtl/simple_counter.sv)

Simulation Sources
  └─ sim_1
      ├─ tb_top (tb/tb_top.sv) [TOP]
      ├─ Packages
      │   ├─ agents_pkg
      │   ├─ test_pkg
      │   └─ evm_pkg
      ├─ Interfaces
      │   ├─ clk_if
      │   └─ rst_if
      └─ Other Files
          ├─ clk_agent.sv
          ├─ rst_agent.sv
          ├─ simple_test.sv
          └─ evm_*.sv files
```

---

## Step 4: Run Simulation

### Quick Way:
1. **Click:** `Flow → Run Simulation → Run Behavioral Simulation`
2. **Wait** for compilation and simulation
3. **Waveform window** opens automatically

### Manual Way:
1. **Flow Navigator** (left panel)
2. **Simulation** section
3. **Run Simulation** → **Run Behavioral Simulation**

---

## Step 5: View Waveforms

### Auto-Displayed Signals:
Vivado automatically shows all top-level signals:
- `clk` - Clock signal
- `rst_n` - Reset signal  
- `enable` - Counter enable
- `count[7:0]` - Counter value

### Add More Signals:
1. **Scope** window → Expand `tb_top` → `dut`
2. **Right-click** signal → **Add to Wave Window**
3. **Restart** simulation to see from time 0

### Waveform Controls:
- **Zoom In/Out:** Mouse wheel or toolbar buttons
- **Zoom Fit:** Click the "Zoom Fit" button (binoculars icon)
- **Zoom to Range:** Select time range, right-click → Zoom to Range

---

## Step 6: Examine Simulation Results

### Console Output:
**Tcl Console** (bottom) shows test output:
```
[0ns] INFO: >>> Starting BUILD phase
[0ns] INFO: Agents created
...
========================================
Test: simple_test
Errors: 0
Warnings: 0
simple_test PASSED ✓
========================================
```

### Expected Waveforms:
- **Clock:** Toggling every 5ns (10ns period = 100MHz)
- **Reset:** Low for ~100ns, then high
- **Count:** Starts at 0, increments to ~247 over 10us
- **Enable:** Goes high after reset

---

## Step 7: Re-run Simulation

After making code changes:

1. **Relaunch Simulation:**
   - Flow → Run Simulation → Relaunch Simulation
   
2. **Or Start Fresh:**
   - Flow → Run Simulation → Run Behavioral Simulation
   - Click "Yes" to recompile

---

## Common Tasks in GUI

### Change Simulation Time:
1. **Settings** → **Simulation**
2. **Simulation** → **xsim.simulate.runtime**
3. Change from `100us` to desired time

### View File Contents:
- **Sources** window → Double-click any file
- Opens in text editor pane

### View Hierarchy:
- **Simulation** → **Scope** window
- Expand `tb_top` to see:
  - `dut` (simple_counter)
  - `test` (simple_test instance)
  - Agents (clk_agt, rst_agt)

### Save Waveform Configuration:
- **File** → **Simulation Waveform** → **Save Configuration**
- Saves which signals are displayed
- Auto-loads next time

---

## Debugging Tips

### No Waveforms?
- Check **Tcl Console** for errors
- Verify **Simulation** → **Scope** shows `tb_top`
- Re-run: Flow → Run Simulation → Run Behavioral Simulation

### Simulation Doesn't Stop?
- Check test has `raise_objection()` and `drop_objection()`
- Check timeout: 100us max runtime set
- Look for hung loops in code

### Compilation Errors?
- **Messages** window (bottom) shows errors
- Double-click error to jump to file/line
- Fix and re-run simulation

### Can't Find Signals?
- **Scope** window → Expand hierarchy
- **Objects** window shows all signals in selected scope
- Drag signals to **Wave** window

---

## Quick Reference

| Task | Action |
|------|--------|
| Open project | Double-click .xpr file |
| Run simulation | Flow → Run Simulation → Run Behavioral Simulation |
| View waves | Automatically shown |
| Add signal | Scope → Objects → Right-click → Add to Wave |
| Zoom fit | Toolbar binoculars icon |
| Restart sim | Flow → Run Simulation → Relaunch Simulation |
| View hierarchy | Scope window |
| View files | Double-click in Sources window |

---

## What You Should See

### Successful Simulation:
✅ Console shows "simple_test PASSED ✓"  
✅ Waveforms show clock toggling  
✅ Counter increments from 0 to ~247  
✅ No errors in Messages window  

### Simulation Time: ~10us
- Reset: 100ns
- Configure: 50ns  
- Main: 10us
- Total: ~10.15us

---

## Project Structure in GUI

```
Project: simple_counter_project
├─ Design Sources (RTL)
│   └─ simple_counter.sv
├─ Simulation Sources (Testbench)
│   ├─ tb_top.sv [TOP]
│   ├─ simple_test.sv
│   ├─ clk_agent.sv
│   ├─ rst_agent.sv
│   ├─ clk_if.sv
│   ├─ rst_if.sv
│   └─ evm framework files
└─ Simulation Runs
    └─ sim_1 (behavioral)
```

---

**Ready to simulate? Follow Step 1 to create the project, then Step 4 to run!** 🎯
