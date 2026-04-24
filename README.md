# EVM — Embedded Verification Methodology

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AI-First Development](https://img.shields.io/badge/Development-AI--First-blue)](CLAUDE.md)
[![Version](https://img.shields.io/badge/Version-0.1.0-orange)](CLAUDE.md)
[![Status](https://img.shields.io/badge/Status-Experimental-red)](CLAUDE.md)

> ⚠️ **Experimental — v0.1.0.** APIs and architecture are subject to change without notice.  
> Not recommended for production use without thorough independent validation.

**A lightweight SystemVerilog verification framework for embedded FPGA/ASIC IP verification**

**Author:** Eric Dyer — [Differential Audio Inc.](https://github.com/DifferentialAudioInc)  
**License:** MIT

---

## What is EVM?

EVM (Embedded Verification Methodology) is an experimental (v0.1.0) lightweight alternative to UVM for embedded ASIC/FPGA IP verification. It delivers the verification patterns engineers actually use — without the UVM overhead that slows small-to-medium teams down.

| | UVM | EVM |
|---|---|---|
| **Learning curve** | Weeks | Days |
| **Framework size** | ~50K LOC | ~8K LOC |
| **Compilation** | Minutes | Seconds |
| **Factory / Config DB** | Required | Not needed (direct is better) |
| **AXI4 Full burst agent** | Build yourself | ✅ Included |
| **RAL with auto-predictor** | uvm_reg (complex) | ✅ evm_reg_map + predictor |
| **Test registry (+TESTNAME)** | uvm_factory | ✅ +EVM_TESTNAME |
| **Best for** | Large ASIC teams | Small-medium ASIC/FPGA teams |

---

## Key Features

### Core Framework
- **12-phase execution model** — build → connect → reset → configure → main → shutdown → check
- **Parallel `run_phase()`** — monitors and scoreboards run continuously across all phases (no missed transactions)
- **Mid-simulation reset** — every component has built-in `assert_reset()` / `on_reset_assert()` hooks
- **Quiescence Counter** — unique EVM feature: automatic test completion detection, no manual objection management needed

### Protocol Agents (VKit)
- **AXI4-Lite Master** — write/read/rmw/poll, 7 analysis ports (channel + composite), optional sequencer, RAL predictor ready
- **AXI4 Full Master** — burst write/read (INCR/FIXED/WRAP), WLAST/RLAST tracking, 7 analysis ports, active/passive modes
- **ADC/DAC streaming** — file-based Python integration
- Clock, Reset, GPIO, PCIe agents included

### Register Model (RAL)
- **`evm_reg_field`** → **`evm_reg`** → **`evm_reg_block`** → **`evm_reg_map`** → **`evm_reg_predictor`**
- **CSR Generator** (`csr_gen/gen_csr.py`) — YAML → RTL + C header + EVM RAL model in one command
- Auto-predictor: connect monitor's `ap_write` port → predictor → mirror auto-updates on every observed write

### Test Infrastructure
- **`evm_env`** — environment base class with auto topology print
- **Test registry** — `EVM_REGISTER_TEST(my_test)` + `+EVM_TESTNAME=my_test` = run any test without recompiling
- **Sequence library** — `EVM_REGISTER_SEQUENCE(my_seq)` + `+EVM_SEQ=my_seq` = runtime sequence selection

---

## Quick Start

```systemverilog
// Minimal test
import evm_pkg::*;

class my_test extends evm_base_test;
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");    // ← required or phase ends immediately
        #1us;
        drop_objection("test");
    endtask
endclass

// tb_top.sv
initial begin
    my_test t = new("my_test");
    evm_root::get().run_test(t);
    $finish;
end
```

For a full build-up (transaction → monitor → driver → agent → env → test → tb_top), see **[docs/QUICK_START.md](docs/QUICK_START.md)**.

---

## Documentation

### `evm-sv/docs/` — User Reference

| Document | Contents |
|---|---|
| [QUICK_START.md](docs/QUICK_START.md) | Complete testbench build-up step by step |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | 12 phases, run_phase, mid-sim reset, TLM, VIF |
| [AGENTS.md](docs/AGENTS.md) | All protocol agents: AXI-Lite, AXI4 Full, ADC/DAC/GPIO/CLK/RST |
| [REGISTER_MODEL.md](docs/REGISTER_MODEL.md) | RAL: reg_map, predictor, CSR generator |
| [TEST_INFRASTRUCTURE.md](docs/TEST_INFRASTRUCTURE.md) | evm_env, test registry, sequence library |
| [REFERENCE.md](docs/REFERENCE.md) | Logging API, per-phase DO/DON'T, VIF+clocking blocks, scoreboard |
| [UVM_FEATURES_NOT_IMPLEMENTED.md](docs/UVM_FEATURES_NOT_IMPLEMENTED.md) | Why EVM intentionally omits certain UVM features |

### `evm-sv/vkit/docs/uml/` — Mermaid Class Diagrams

All diagrams render on GitHub and in VS Code (with Mermaid Preview extension).

| Diagram | Contents |
|---|---|
| [01_core_framework.md](vkit/docs/uml/01_core_framework.md) | Object/component hierarchy, phases, reset events, QC, test registry |
| [02_register_model.md](vkit/docs/uml/02_register_model.md) | RAL classes, reg_map, predictor, CSR generator flow |
| [03_utilities.md](vkit/docs/uml/03_utilities.md) | Scoreboard (3 modes), memory model, sequence library |
| [04_agents_axi_lite.md](vkit/docs/uml/04_agents_axi_lite.md) | AXI-Lite agent, 7 analysis ports, transaction types |
| [05_agents_axi4_full.md](vkit/docs/uml/05_agents_axi4_full.md) | AXI4 Full burst agent, burst sequence diagram |
| [06_tlm_sequences.md](vkit/docs/uml/06_tlm_sequences.md) | TLM ports, analysis broadcast, driver↔sequencer |

---

## Project Structure

```
evm-sv/
├── CLAUDE.md                 # AI development guide (start here for AI sessions)
├── NEXT_STEPS.md             # What's complete + NIC example project roadmap
│
├── vkit/src/                 # Core EVM library (evm_pkg)
│   ├── evm_component.sv      # 12-phase + run_phase + reset events
│   ├── evm_monitor.sv        # run_phase continuous monitoring
│   ├── evm_driver.sv         # main_phase stimulus + reset handling
│   ├── evm_sequencer.sv      # sequence dispatch + reset flush
│   ├── evm_scoreboard.sv     # 3 matching modes (FIFO/Assoc/Unordered)
│   ├── evm_reg_map.sv        # address map for multiple reg blocks
│   ├── evm_reg_predictor.sv  # parameterized RAL predictor base
│   ├── evm_env.sv            # environment base (auto topology print)
│   ├── evm_test_registry.sv  # +EVM_TESTNAME test selection
│   ├── evm_sequence_library.sv # named sequence registry
│   └── ... (30+ source files)
│
├── vkit/evm_vkit/            # Protocol agents (evm_vkit_pkg)
│   ├── evm_axi_lite_agent/   # AXI4-Lite: 7 analysis ports, optional sequencer
│   ├── evm_axi4_full_agent/  # AXI4 Full: burst read/write, 7 analysis ports
│   └── (clk, rst, adc, dac, gpio, pcie agents)
│
├── csr_gen/                  # CSR Generator
│   └── gen_csr.py            # YAML → RTL + C header + EVM RAL model
│
└── docs/                     # Documentation (see table above)
```

---

## AI-First Development

EVM is designed for AI-assisted development. The documentation is structured for both human and AI consumption:

- **`CLAUDE.md`** — primary AI session reference: complete class list, file locations, coding standards
- **`docs/`** — human + AI readable reference documents
- **`vkit/docs/uml/`** — Mermaid diagrams for visual architecture understanding

To start an AI session: read `CLAUDE.md` first, then reference the specific docs needed for the task.

---

## What's Next

The NIC example project — a complete TX NIC DUT + full EVM verification environment demonstrating the entire framework in a realistic IP scenario. See [NEXT_STEPS.md](NEXT_STEPS.md).

---

## License

**MIT License** — See [LICENSE](LICENSE)  
Copyright (c) 2026 Eric Dyer / Differential Audio Inc.
