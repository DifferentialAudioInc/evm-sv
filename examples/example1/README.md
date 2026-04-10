# EVM Example: AXI Data Transform

**Author:** Eric Dyer (Differential Audio Inc.)  
**Purpose:** Complete EVM verification environment reference example

---

## What This Example Demonstrates

A complete EVM-based verification environment from scratch, including:
- **CSR generator workflow** — YAML → RTL + EVM RAL in one command
- **DUT with AXI on both sides** — AXI4-Lite slave (config) + AXI4-Lite master (output)
- **GPIO output observation** — dedicated `gpio_if` + check in test
- **Full env hierarchy** — cfg, env, scoreboard, RAL, predictor
- **Test registry** — `EVM_REGISTER_TEST` + `+EVM_TESTNAME` runtime selection
- **3 tests** — smoke, exhaustive, random with scoreboard checking
- **Vivado regression scripts** — `run_sim.tcl` + `run_regression.tcl`

---

## DUT: `axi_data_xform`

```
AXI4-Lite Slave                                   AXI4-Lite Master
(TB drives CSRs) ──────────────────────────────► (DUT drives result)
                     ┌───────────────────┐
  0x00 CTRL    ────► │ Transform Engine  │ ────► gpio_out[7:0]
  0x04 DATA_IN ────► │  4-cycle pipeline  │
  0x08 STATUS  ◄──── │                   │
  0x0C RESULT  ◄──── │  RESULT → AXI     │
  0x10 GPIO_OUT ───► │  master write     │
                     └───────────────────┘
```

**Transform modes (CTRL[2:1]):**
| Mode | Operation |
|---|---|
| `00` | Passthrough: `result = data` |
| `01` | Invert: `result = ~data` |
| `10` | Byte swap: `result = {b0,b1,b2,b3}` |
| `11` | Bit reverse: `result = data[31:0] reversed` |

**Behavior:**
1. Write `CTRL.ENABLE=1`, optionally set `CTRL.XFORM_SEL`
2. Write `DATA_IN` → triggers 4-cycle pipeline
3. `STATUS.DONE` asserts; `RESULT` holds computed value
4. DUT initiates AXI4-Lite master write to `0x0000_2000` with result
5. `GPIO_OUT[7:0]` drives `gpio_out` pins at all times

---

## File Structure

```
example1/
├── csr/
│   ├── example1.yaml                   ← CSR definitions (source of truth)
│   └── generated/                      ← CSR generator output
│       └── axi_data_xform/
│           ├── axi_data_xform_csr_pkg.sv
│           ├── axi_data_xform_csr.sv
│           └── axi_data_xform_reg_model.sv  ← EVM RAL (used by DV)
├── rtl/
│   └── axi_data_xform.sv               ← DUT top module
├── dv/
│   ├── env/                            ← Environment, cfg, scoreboard, pkg
│   │   ├── axi_data_xform_pkg.sv
│   │   ├── axi_data_xform_cfg.sv
│   │   ├── axi_data_xform_scoreboard.sv
│   │   ├── axi_data_xform_env.sv
│   │   └── axi_data_xform_base_test.sv
│   ├── tb/                             ← Testbench top + interfaces
│   │   ├── tb_top.sv
│   │   └── intf/gpio_if.sv
│   └── tests/                          ← Test files
│       ├── basic_write_test.sv
│       ├── multi_xform_test.sv
│       └── random_test.sv
└── sim/
    ├── run_sim.tcl                     ← Vivado setup + single test
    ├── run_regression.tcl              ← Run all tests
    └── filelist.f                      ← VCS/Questa/Xcelium file list
```

---

## Step 1: Generate CSR Files

Run the CSR generator from the project root:

```bash
cd c:/evm/evm-sv
python csr_gen/gen_csr.py examples/example1/csr/example1.yaml \
                          examples/example1/csr/generated
```

This generates:
- `rtl/generated/axi_data_xform/axi_data_xform_csr_pkg.sv` — RTL constants package
- `rtl/generated/axi_data_xform/axi_data_xform_csr.sv` — AXI4-Lite register file RTL
- `rtl/generated/axi_data_xform/axi_data_xform_reg_model.sv` — EVM RAL model (DV side)
- `rtl/generated/register_map.md` — register map documentation

> The generated files are already in the repo. Re-run only if you modify the YAML.

---

## Step 2: Run Simulation (Vivado)

### Single Test

Open Vivado, then in the Tcl console:

```tcl
cd c:/evm/evm-sv/examples/example1/sim
source run_sim.tcl
run_test basic_write_test
```

### All Tests (Regression)

```tcl
cd c:/evm/evm-sv/examples/example1/sim
source run_regression.tcl
```

Expected output:
```
============================================================
  REGRESSION SUMMARY
============================================================
  [PASS] basic_write_test
  [PASS] multi_xform_test
  [PASS] random_test

  Passed: 3 / 3

  ALL TESTS PASSED
============================================================
```

---

## Step 2 (Alternative): Run with VCS / Questa / Xcelium

```bash
cd c:/evm/evm-sv/examples/example1/sim

# VCS
vcs -sverilog -f filelist.f +EVM_TESTNAME=basic_write_test -o simv && ./simv

# Xcelium
xrun -f filelist.f +EVM_TESTNAME=basic_write_test

# Questa
vlib work
vlog -sv -f filelist.f
vsim tb_top +EVM_TESTNAME=basic_write_test -c -do "run -all; quit"
```

---

## Test Selection

Tests use `EVM_REGISTER_TEST` macro and `+EVM_TESTNAME` plusarg:

| Plusarg | Test | What it does |
|---|---|---|
| `+EVM_TESTNAME=basic_write_test` | Basic smoke | 1 passthrough, 0xDEAD_BEEF |
| `+EVM_TESTNAME=multi_xform_test` | All modes | Tests all 4 xform modes |
| `+EVM_TESTNAME=random_test` | Random | 20 random data + mode combos |
| `+EVM_LIST_TESTS` | List | Print all registered tests, exit |

---

## DV Environment Architecture

```
tb_top
├── slave_if        → DUT AXI4-Lite slave port (TB drives)
├── master_if       → DUT AXI4-Lite master port (DUT drives, TB observes)
├── gpio_port       → DUT gpio_out[7:0] observation
└── initial begin
      t.slave_vif  = slave_if
      t.master_vif = master_if
      t.gpio_vif   = gpio_port
      run_test(t)

axi_data_xform_base_test
  └── axi_data_xform_env (evm_env)
        ├── csr_agent           ← evm_axi_lite_master_agent (ACTIVE, drives DUT CSRs)
        ├── master_mon          ← evm_axi_lite_master_agent (PASSIVE, observes DUT output)
        ├── scoreboard          ← axi_data_xform_scoreboard (checks master writes)
        ├── ral                 ← axi_data_xform_reg_model (from CSR generator)
        ├── reg_map             ← evm_reg_map (maps RAL to bus addresses)
        └── predictor           ← evm_axi_lite_write_predictor (auto-mirrors CSR writes)
```

---

## Key EVM Patterns Demonstrated

### 1. CSR Generator → RAL → Predictor
```systemverilog
// RAL model from generator:
ral = new("ral");
reg_map.add_reg_block("xform", ral.reg_block, 0);
// Auto-update mirror on every observed write:
csr_agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());
```

### 2. Passive Monitor → Scoreboard
```systemverilog
// DUT master interface observed passively:
master_mon.monitor.ap_write.connect(scoreboard.analysis_imp.get_mailbox());
// Test inserts expected BEFORE driving DATA_IN:
scoreboard.insert_expected(make_expected(result));
csr_agent.write(DATA_IN_ADDR, data, ...);
```

### 3. Test Registry
```systemverilog
// At end of each test file:
`EVM_REGISTER_TEST(basic_write_test)
// In tb_top:
evm_test_registry::create_test(testname);
// Simulation:
+EVM_TESTNAME=basic_write_test
```

### 4. GPIO Interface Observation
```systemverilog
// Interface instantiation (tb_top):
gpio_if gpio_port();
assign gpio_port.gpio = dut.gpio_out;
// Test check:
check_gpio(8'hA5);   // verifies gpio_vif.gpio === 8'hA5
```
