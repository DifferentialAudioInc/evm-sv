# Simple Counter Example

**Purpose:** Minimal EVM testbench example demonstrating complete phasing with clock and reset agents.

## Project Structure

```
simple_counter/
├── rtl/
│   └── simple_counter.sv          # DUT - 8-bit counter with enable
├── tb/
│   ├── interfaces/
│   │   ├── clk_if.sv              # Clock interface
│   │   └── rst_if.sv              # Reset interface
│   ├── agents/
│   │   ├── clk_agent.sv           # Clock generation agent
│   │   ├── rst_agent.sv           # Reset control agent
│   │   └── pkg/
│   │       └── agents_pkg.sv      # Agent package
│   ├── tests/
│   │   ├── simple_test.sv         # Example test
│   │   └── pkg/
│   │       └── test_pkg.sv        # Test package
│   └── tb_top.sv                  # Testbench top
├── sim/
│   ├── vivado_sim.tcl             # Vivado simulation script
│   ├── run_sim.sh                 # Linux run script
│   └── run_sim.bat                # Windows run script
└── README.md                      # This file
```

## DUT Description

**Module:** `simple_counter`

Simple 8-bit counter with:
- Clock input
- Active-low async reset
- Enable input
- 8-bit counter output

## Running Simulation

### Vivado (Linux/Windows)

```bash
# Linux
cd sim
./run_sim.sh

# Windows
cd sim
run_sim.bat
```

Or manually:
```bash
vivado -mode batch -source vivado_sim.tcl
```

### View Waves

After simulation, waveform file is generated: `sim/simple_counter_tb.wdb`

```bash
vivado sim/simple_counter_tb.wdb
```

## Test Description

**Test:** `simple_test`

Demonstrates EVM phasing:
1. **build_phase:** Creates clock and reset agents
2. **connect_phase:** (stub)
3. **reset_phase:** Applies reset sequence
4. **configure_phase:** Enables counter
5. **main_phase:** Runs for 10us with objections
6. **check_phase:** Verifies counter incremented
7. **report_phase:** Prints pass/fail

## Expected Output

```
[0ns] INFO: >>> Starting BUILD phase
[0ns] INFO: Created clk_agent
[0ns] INFO: Created rst_agent
[0ns] INFO: <<< BUILD phase complete
[0ns] INFO: >>> Starting RESET phase
[100ns] INFO: Reset complete
[0ns] INFO: <<< RESET phase complete
[0ns] INFO: >>> Starting CONFIGURE phase
[200ns] INFO: Counter enabled
[0ns] INFO: <<< CONFIGURE phase complete
[0ns] INFO: >>> Starting MAIN phase
[10100ns] INFO: Main phase complete
[0ns] INFO: <<< MAIN phase complete
[0ns] INFO: >>> Starting CHECK phase
[0ns] INFO: Counter value: 245
[0ns] INFO: TEST PASSED
========================================
Test: simple_test
Errors: 0
Warnings: 0
simple_test PASSED ✓
========================================
```

## Learning Points

1. **EVM Phasing:** All 12 phases demonstrated
2. **Agents:** Clock and reset agents show basic agent structure
3. **Objections:** main_phase uses raise/drop_objection
4. **Hierarchy:** Test → Agents shows parent/child relationship
5. **Interfaces:** SystemVerilog interfaces for clean connections

## Customization

Modify test duration in `simple_test.sv`:
```systemverilog
task main_phase();
    #10us;  // Change duration here
endtask
```

Modify clock period in `tb_top.sv`:
```systemverilog
parameter CLK_PERIOD = 10ns;  // Change clock period
```
