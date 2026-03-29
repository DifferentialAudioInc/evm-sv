# Quick Start - Running the Simulation

## Step-by-Step Instructions

### Windows (Easiest)

1. **Open Command Prompt or PowerShell**

2. **Navigate to the sim directory:**
   ```cmd
   cd c:\evm\evm-sv\examples\simple_counter\sim
   ```

3. **Run the simulation:**
   ```cmd
   run_sim.bat
   ```

That's it! The script will:
- Check for Vivado
- Create a Vivado project
- Compile all files
- Run the simulation
- Generate waveforms

### Linux

1. **Open terminal**

2. **Navigate to sim directory:**
   ```bash
   cd /path/to/evm-sv/examples/simple_counter/sim
   ```

3. **Make script executable (first time only):**
   ```bash
   chmod +x run_sim.sh
   ```

4. **Run simulation:**
   ```bash
   ./run_sim.sh
   ```

### Manual Vivado Invocation

If the batch scripts don't work, run Vivado directly:

**From Windows Command Prompt:**
```cmd
cd c:\evm\evm-sv\examples\simple_counter\sim
vivado -mode batch -source vivado_sim.tcl
```

**From Vivado Tcl Shell (use forward slashes!):**
```tcl
cd c:/evm/evm-sv/examples/simple_counter/sim
vivado -mode batch -source vivado_sim.tcl
```

---

## Troubleshooting

### Error: "Vivado not found in PATH"

**Solution:** Add Vivado to your PATH or source the settings:

**Windows:**
```cmd
C:\Xilinx\Vivado\2023.2\settings64.bat
cd c:\evm\evm-sv\examples\simple_counter\sim
run_sim.bat
```

**Linux:**
```bash
source /tools/Xilinx/Vivado/2023.2/settings64.sh
cd /path/to/evm-sv/examples/simple_counter/sim
./run_sim.sh
```

### Error: "File not found"

Make sure you're in the correct directory:
```cmd
cd c:\evm\evm-sv\examples\simple_counter\sim
dir
```

You should see:
- run_sim.bat
- run_sim.sh
- vivado_sim.tcl

---

## Viewing Results

### Console Output

Look for this at the end of simulation:
```
========================================
Test: simple_test
Errors: 0
Warnings: 0
simple_test PASSED ✓
========================================

=== SIMULATION COMPLETE ===
```

### Waveforms

After simulation completes, the waveform database is at:
```
simple_counter_sim/simple_counter_sim.sim/sim_1/behav/xsim/tb_top_behav.wdb
```

**To view waveforms:**

1. **Open Vivado GUI:**
   ```cmd
   cd c:\evm\evm-sv\examples\simple_counter\sim
   vivado simple_counter_sim\simple_counter_sim.xpr
   ```

2. **In Vivado:**
   - Click: **Flow → Run Simulation → Run Behavioral Simulation**
   - Or: **Flow → Open Static Simulation**

3. **View signals:**
   - Waveform window shows all DUT signals
   - Clock toggling at 100MHz
   - Reset sequence
   - Counter incrementing

---

## What Gets Created

After running simulation, you'll have:

```
sim/
├── simple_counter_sim/          # Vivado project
│   ├── simple_counter_sim.xpr   # Project file
│   └── simple_counter_sim.sim/  # Simulation results
│       └── sim_1/behav/xsim/
│           └── tb_top_behav.wdb # Waveform database
├── vivado*.log                   # Log files
└── vivado*.jou                   # Journal files
```

---

## Quick Commands Reference

| Task | Windows | Linux |
|------|---------|-------|
| Run sim | `run_sim.bat` | `./run_sim.sh` |
| Run Vivado manually | `vivado -mode batch -source vivado_sim.tcl` | Same |
| Open project | `vivado simple_counter_sim\simple_counter_sim.xpr` | `vivado simple_counter_sim/simple_counter_sim.xpr` |
| View waves | Open project, then Flow → Run Simulation | Same |

---

## Expected Simulation Time

- Compilation: ~30 seconds
- Simulation: ~5 seconds
- Total: **~35-40 seconds**

---

## Success Indicators

✅ **Simulation passed if you see:**
```
simple_test PASSED ✓
Errors: 0
```

✅ **Waveforms show:**
- Clock toggling
- Reset assertion/deassertion
- Counter incrementing from 0 to ~247

❌ **Failed if you see:**
```
ERROR: ...
simple_test FAILED ✗
```

---

## Next Steps After Successful Run

1. ✅ View waveforms in Vivado
2. ✅ Modify test duration in `simple_test.sv`
3. ✅ Change clock frequency in `clk_agent.sv`
4. ✅ Add debug logging
5. ✅ Create your own test

---

**Ready to run? Execute:**
```cmd
cd c:\evm\evm-sv\examples\simple_counter\sim
run_sim.bat
```
