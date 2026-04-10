# EVM Next Steps & Roadmap

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  
---

## ✅ What's Complete

### Core Framework

- [x] `evm_object` — base object with logging
- [x] `evm_component` — 12-phase lifecycle + **run_phase** + mid-simulation reset events
- [x] `evm_root` — singleton phase controller + `run_test_by_name()` (via `+EVM_TESTNAME`)
- [x] `evm_base_test` — test base with optional quiescence counter (QC)
- [x] `evm_env` — environment base class (auto topology print)
- [x] `evm_test_registry` + `EVM_REGISTER_TEST` macro — test selection without recompile
- [x] TLM 1.0 — `evm_analysis_port`, `evm_analysis_imp`, `evm_seq_item_pull_port/export`
- [x] `evm_monitor` — `run_phase()` based, reset-aware
- [x] `evm_driver` — `run_phase()` reset monitor, `main_phase()` for stimulus
- [x] `evm_sequencer` — with reset flush (mailbox + TLM FIFOs)
- [x] `evm_agent` — configurable active/passive
- [x] `evm_scoreboard` — `run_phase()` based, 3 matching modes, reset-aware
- [x] `evm_qc` — quiescence counter (unique EVM feature)

### Register Model (RAL)

- [x] `evm_reg_field` — 9 access types
- [x] `evm_reg` — read/write/mirror/predict
- [x] `evm_reg_block` — with agent association
- [x] `evm_reg_map` — address map for multiple blocks
- [x] `evm_reg_predictor` — parameterized base + AXI-Lite concrete classes
- [x] CSR Generator (`gen_csr.py`) — YAML → RTL + C headers + RAL model

### Sequences & Libraries

- [x] `evm_sequence_item`, `evm_sequence`, `evm_csr_item`, `evm_csr_sequence`
- [x] `evm_virtual_sequence` — multi-sequencer coordination
- [x] `evm_sequence_library` + `EVM_REGISTER_SEQUENCE` macro

### Protocol Agents (VKit)

- [x] `evm_clk_agent` — clock generation
- [x] `evm_rst_agent` — reset sequencing
- [x] **`evm_axi_lite_master_agent`** — 7 analysis ports + optional sequencer
- [x] **`evm_axi4_full_master_agent`** — AXI4 Full burst agent (write/read burst API)
- [x] `evm_adc_agent` — streaming ADC stimulus
- [x] `evm_dac_agent` — streaming DAC capture + Python analysis
- [x] `evm_gpio_agent` — digital I/O
- [x] `evm_pcie_agent` — PCIe BFM

### Infrastructure

- [x] `evm_memory_model` — 64-bit sparse memory + file I/O
- [x] `evm_coverage` — coverage wrapper
- [x] `evm_assertions` — assertion checker
- [x] Command-line plusargs: `+EVM_TESTNAME`, `+EVM_SEQ`, `+verbosity`, `+seed`, `+EVM_TIMEOUT`
- [x] Multi-simulator support (VCS, Questa, Xcelium, Vivado)

### Documentation

- [x] `docs/ARCHITECTURE.md` — complete framework architecture
- [x] `docs/AGENTS.md` — all agent documentation
- [x] `docs/REGISTER_MODEL.md` — complete RAL reference
- [x] `docs/TEST_INFRASTRUCTURE.md` — env, test registry, sequence library
- [x] 6 updated UML files (Mermaid) — all new classes included
- [x] `CLAUDE.md` — AI development guide

---

## 🎯 Next Priority: NIC Example Project

**Goal:** Build a complete TX NIC DUT and verification environment using EVM.

This is the main next task. See `next.txt` for the full specification.

### NIC DUT Architecture
```
AXI-Lite Slave (doorbell CSRs)
  → doorbell: address + size
  → AXI4 Full Master engine
      → fetch packet from host memory
      → store in internal FIFO (store-and-forward)
      → transmit on streaming output (SOP/DATA/EOP + backpressure)
```

### NIC Verification Plan
- [ ] Design CSRs → YAML → `gen_csr.py` → RTL + RAL
- [ ] Implement DUT in RTL (SV)
- [ ] Create `tb_top.sv` with interfaces + clock/reset
- [ ] Create `nic_env.sv` with AXI-Lite + AXI4 Full + stream agents
- [ ] Create `nic_base_test.sv`
- [ ] Create test suite: single_pkt, backpressure, stress
- [ ] Register all tests with `EVM_REGISTER_TEST`

---

## 🟢 Optional Enhancements (Community / Future)

### Protocol Agents

These agents are listed in NEXT_STEPS but are not yet implemented. 
Add when needed by a specific project.

- [ ] **AXI4-Stream Agent** — TVALID/TREADY/TDATA/TKEEP/TLAST
  - Ideal for the NIC streaming output side
  - SOP/EOP framing can be built on top
- [ ] **SPI Agent** — CPOL/CPHA modes
- [ ] **I2C Agent** — master/slave, START/STOP/ACK
- [ ] **UART Agent** — configurable baud rate, parity

### Verification Infrastructure

- [ ] **AXI4 Full Slave agent** — needed to model host memory for DMA
  - Currently: use `evm_memory_model` with manual response
  - Better: a proper AXI4 slave BFM that auto-responds
- [ ] **Better test template generator** — Python script that scaffolds a new project
- [ ] **CI/CD** — GitHub Actions workflow for compile + lint
- [ ] **Regression framework** — run all `EVM_REGISTER_TEST` tests, collect pass/fail

### RAL Enhancements

- [ ] **Backdoor access** — `$deposit()` / force/release for zero-time register inspection
- [ ] **Register test sequences** — hw_reset_seq, bit_bash_seq, access_seq (standard IP qualification)
- [ ] **Address map validation** — overlap detection, coverage of all addresses

---

## ❌ Intentionally NOT Implemented

These UVM features are deliberately excluded. See `docs/UVM_FEATURES_NOT_IMPLEMENTED.md` for full rationale.

| UVM Feature | EVM Alternative |
|---|---|
| Factory pattern | Direct instantiation |
| Config DB | Direct VIF assignment |
| Field macros | Explicit code |
| Full RAL (uvm_reg) | CSR generator + evm_reg_map |
| Callbacks | Virtual method overrides |
| TLM 2.0 | TLM 1.0 is sufficient |
| Multiple phase domains | Single 12-phase domain |
| Heartbeat | Quiescence counter |
| Report catcher | Verbosity levels |
| Phase jumping | Linear phase execution |

---

## 📊 Metrics

| Metric | Target | Actual |
|---|---|---|
| Framework LOC | < 10K | ~8K |
| Compilation time | < 10s | < 5s |
| Learning curve | < 1 week | ~1 day |
| Examples | 4+ | 4 working |
| Simulators | 4 | VCS/Questa/Xcelium/Vivado |
| Protocol agents | - | AXI-Lite + AXI4 Full + 5 others |
| Documentation files | - | 10 guides + 6 UML |

---

*EVM: Everything you need, nothing you don't.* 🚀
