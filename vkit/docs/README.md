# EVM VKit Documentation

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Contents

| File | Purpose |
|---|---|
| [`uml/`](uml/README.md) | **Mermaid UML diagrams** — complete framework architecture |
| [`CONTRIBUTORS.md`](CONTRIBUTORS.md) | Contributors and attribution |
| [`COPYRIGHT_HEADER.txt`](COPYRIGHT_HEADER.txt) | Standard header template for new files |
| [`archive/`](archive/) | Historical documents (superseded, kept for reference) |

---

## UML Diagrams (Mermaid)

See [`uml/README.md`](uml/README.md) for the full index and quick-reference guide.

| File | Key Classes |
|---|---|
| [01_core_framework.md](uml/01_core_framework.md) | evm_object, evm_component, evm_env, evm_root, evm_base_test, evm_test_registry, evm_qc |
| [02_register_model.md](uml/02_register_model.md) | evm_reg_field → evm_reg → evm_reg_block → evm_reg_map → evm_reg_predictor |
| [03_utilities.md](uml/03_utilities.md) | evm_scoreboard, evm_memory_model, evm_sequence_library |
| [04_agents_axi_lite.md](uml/04_agents_axi_lite.md) | AXI-Lite agent with 7 analysis ports + all txn types |
| [05_agents_axi4_full.md](uml/05_agents_axi4_full.md) | AXI4 Full burst agent with 7 analysis ports |
| [06_tlm_sequences.md](uml/06_tlm_sequences.md) | TLM ports, sequences, driver↔sequencer wiring |

---

## Main Documentation

User-facing documentation lives in [`../../docs/`](../../docs/):

- `docs/QUICK_START.md` — Get running in 15 minutes
- `docs/ARCHITECTURE.md` — Framework design
- `docs/AGENTS.md` — Protocol agents
- `docs/REGISTER_MODEL.md` — RAL
- `docs/TEST_INFRASTRUCTURE.md` — Test registry, env, sequence library
- `docs/EVM_LOGGING_COMPLETE_GUIDE.md` — Logging
- `docs/EVM_MONITOR_SCOREBOARD_GUIDE.md` — Monitor/scoreboard patterns
