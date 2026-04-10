# EVM Documentation

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Start Here

| Document | Purpose | Audience |
|---|---|---|
| [QUICK_START.md](QUICK_START.md) | Full testbench build-up: transaction → monitor → driver → agent → env → test → tb_top | New users |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 12 phases + run_phase, mid-sim reset, TLM, VIF pattern, objections, test execution flow | All |

---

## Feature Reference

| Document | Purpose |
|---|---|
| [AGENTS.md](AGENTS.md) | AXI-Lite (7 analysis ports), AXI4 Full (burst), ADC, DAC, GPIO, Clock, Reset, PCIe, custom agent template |
| [REGISTER_MODEL.md](REGISTER_MODEL.md) | `evm_reg_field` → `evm_reg` → `evm_reg_block` → `evm_reg_map` → `evm_reg_predictor` + CSR generator |
| [TEST_INFRASTRUCTURE.md](TEST_INFRASTRUCTURE.md) | `evm_env`, `+EVM_TESTNAME` test registry, sequence library, complete test template |
| [REFERENCE.md](REFERENCE.md) | Logging API + verbosity table, per-phase DO/DON'T, VIF + clocking blocks, monitor→scoreboard pattern |
| [UVM_FEATURES_NOT_IMPLEMENTED.md](UVM_FEATURES_NOT_IMPLEMENTED.md) | 20 UVM features intentionally excluded and why |

---

## UML Diagrams (Mermaid)

All class diagrams render in GitHub/VS Code. Located in `vkit/docs/uml/`:

| File | Contents |
|---|---|
| [01_core_framework.md](../vkit/docs/uml/01_core_framework.md) | `evm_object`, `evm_component`, 12 phases + `run_phase`, mid-sim reset, `evm_env`, test registry, QC |
| [02_register_model.md](../vkit/docs/uml/02_register_model.md) | `evm_reg_field → reg → reg_block → reg_map → reg_predictor`, CSR generator flow |
| [03_utilities.md](../vkit/docs/uml/03_utilities.md) | `evm_scoreboard` (3 modes), `evm_memory_model`, `evm_sequence_library` |
| [04_agents_axi_lite.md](../vkit/docs/uml/04_agents_axi_lite.md) | AXI-Lite agent, 7 analysis ports, all transaction types, predictor integration |
| [05_agents_axi4_full.md](../vkit/docs/uml/05_agents_axi4_full.md) | AXI4 Full burst agent, write/read burst flow, interface parameters |
| [06_tlm_sequences.md](../vkit/docs/uml/06_tlm_sequences.md) | TLM ports, analysis port broadcast, driver↔sequencer wiring, virtual sequences |

---

## For AI Assistants

**Recommended reading order for context:**

1. `../CLAUDE.md` — complete status + file map (start here)
2. `ARCHITECTURE.md` — how phases, run_phase, and reset work
3. `AGENTS.md` — what protocol agents are available
4. `REGISTER_MODEL.md` — RAL and predictor
5. `TEST_INFRASTRUCTURE.md` — env, test registry, sequence library
6. `REFERENCE.md` — API details, logging, scoreboard patterns

---

## Archive

Historical documents (superseded, kept for reference):  
[`archive/`](archive/) — older guides, session notes, gap analyses
