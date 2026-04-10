# EVM Framework UML Diagrams

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

All diagrams use [Mermaid](https://mermaid.js.org/) and render automatically in:
- **GitHub** — markdown preview
- **VS Code** — install "Markdown Preview Mermaid Support" extension, then `Ctrl+Shift+V`
- **Browser** — [Mermaid Live Editor](https://mermaid.live)

---

## Document Index

| File | Contents | Key Diagrams |
|---|---|---|
| [01_core_framework.md](01_core_framework.md) | `evm_object`, `evm_component`, `evm_env`, `evm_root`, `evm_base_test`, `evm_test_registry`, `evm_qc` | Class hierarchy, 12-phase + run_phase, mid-sim reset flow |
| [02_register_model.md](02_register_model.md) | `evm_reg_field`, `evm_reg`, `evm_reg_block`, `evm_reg_map`, `evm_reg_predictor`, concrete predictors | RAL hierarchy, address map, predictor auto-sync flow |
| [03_utilities.md](03_utilities.md) | `evm_scoreboard`, `evm_memory_model`, `evm_sequence_library`, `evm_coverage`, `evm_assertions` | Scoreboard modes, memory/DMA usage, sequence library |
| [04_agents_axi_lite.md](04_agents_axi_lite.md) | `evm_axi_lite_master_agent`, monitor with 7 analysis ports, all transaction types | Transaction monitoring flow, predictor integration |
| [05_agents_axi4_full.md](05_agents_axi4_full.md) | `evm_axi4_full_master_agent`, burst driver, monitor with 7 ports, all AXI4 txn types | Write burst sequence, interface parameters |
| [06_tlm_sequences.md](06_tlm_sequences.md) | `evm_analysis_port`, `evm_analysis_imp`, `evm_seq_item_pull_port`, sequences, `evm_virtual_sequence` | Driver↔sequencer connection, multi-subscriber broadcast |

---

## Framework Overview

```
EVM Framework
├── Core (01)
│   ├── evm_object              Base object with logging
│   ├── evm_component           Phased execution + reset events (12 phases + run_phase)
│   ├── evm_env                 Environment layer (test → agents)
│   ├── evm_root                Singleton controller + test runner
│   ├── evm_base_test           Test base class with QC
│   ├── evm_test_registry       +EVM_TESTNAME test selection
│   └── evm_qc                  Quiescence counter (unique to EVM)
│
├── Register Model (02)
│   ├── evm_reg_field           Bit fields (9 access types)
│   ├── evm_reg                 Register with predict/mirror
│   ├── evm_reg_block           Register block (from CSR generator)
│   ├── evm_reg_map             Address map (NEW)
│   └── evm_reg_predictor       Auto-mirror updater (NEW)
│
├── Utilities (03)
│   ├── evm_scoreboard          3 matching modes (FIFO/Assoc/Unordered)
│   ├── evm_memory_model        64-bit sparse memory with file I/O
│   ├── evm_sequence_library    Named sequence registry (NEW)
│   ├── evm_coverage            Coverage wrapper
│   └── evm_assertions          Assertion checker
│
├── AXI4-Lite Agent (04)
│   ├── evm_axi_lite_master_agent    Direct API + optional sequencer
│   ├── evm_axi_lite_master_driver   AXI-Lite protocol driver
│   ├── evm_axi_lite_monitor         7 analysis ports (channel + composite)
│   ├── 7 transaction types          aw/w/b/ar/r/write/read txn
│   └── evm_axi_lite_write_predictor Ready-to-use RAL predictor
│
├── AXI4 Full Agent (05) [NEW]
│   ├── evm_axi4_full_master_agent   Burst API + active/passive modes
│   ├── evm_axi4_full_master_driver  Burst write/read with WLAST/RLAST
│   ├── evm_axi4_full_monitor        7 analysis ports (channel + composite)
│   └── 7 transaction types          aw/w/b/ar/r/write/read with burst data[$]
│
└── TLM & Sequences (06)
    ├── evm_analysis_port       1-to-many broadcast
    ├── evm_analysis_imp        Subscriber mailbox
    ├── evm_seq_item_pull_port  Driver pulls from sequencer
    ├── evm_seq_item_pull_export Sequencer provides items
    ├── evm_sequence_item       Base transaction
    ├── evm_sequence            Transaction collection
    ├── evm_csr_item            CSR-specific transaction
    ├── evm_csr_sequence        CSR sequence builder
    ├── evm_sequencer           Sequence dispatcher
    └── evm_virtual_sequence    Multi-agent coordinator
```

---

## Quick Reference: Which Diagram to Use

**"How do phases work?"** → [01_core_framework.md](01_core_framework.md) — sequence diagram  
**"How does run_test_by_name work?"** → [01_core_framework.md](01_core_framework.md) — test registry  
**"How does mid-sim reset propagate?"** → [01_core_framework.md](01_core_framework.md) — reset event flow  
**"How do I set up the RAL?"** → [02_register_model.md](02_register_model.md)  
**"How does the predictor auto-update the mirror?"** → [02_register_model.md](02_register_model.md) — sequence diagram  
**"What analysis ports does the AXI-Lite monitor have?"** → [04_agents_axi_lite.md](04_agents_axi_lite.md)  
**"How do I connect a scoreboard?"** → [03_utilities.md](03_utilities.md) + [06_tlm_sequences.md](06_tlm_sequences.md)  
**"How does write burst work in AXI4?"** → [05_agents_axi4_full.md](05_agents_axi4_full.md) — sequence diagram  
