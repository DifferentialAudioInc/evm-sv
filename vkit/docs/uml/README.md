# EVM Framework UML Documentation

Complete architecture diagrams for the Embedded Verification Methodology (EVM) framework.

## Quick Navigation

| Document | Description |
|----------|-------------|
| [01. Base Components](01_base_components.md) | Core classes: evm_object, evm_component, evm_log, evm_test |
| [02. Register Model](02_register_model.md) | RAL architecture: fields, registers, blocks |
| [03. Utilities](03_utilities.md) | Memory model and scoreboard |
| [04. Agents](04_agents.md) | Protocol agents overview and usage |

## Document Overview

### 01. Base Components
Core infrastructure and base classes that form the foundation of EVM:
- **evm_object** - Base class with logging
- **evm_component** - Phased execution model
- **evm_log** - Centralized logging system
- **evm_root** - Simulation controller
- **evm_base_test** - Test base class with objection mechanism

**Key Diagrams:**
- Class hierarchy
- Phase execution flow
- Verbosity levels

### 02. Register Model
Complete Register Abstraction Layer (RAL) documentation:
- **evm_reg_field** - Bit fields with 9 access types
- **evm_reg** - Register with field collection
- **evm_reg_block** - Register block with base address
- **Auto-generation** - YAML to RAL conversion

**Key Diagrams:**
- RAL class hierarchy
- Field access types
- Register model hierarchy example
- Register access flow

### 03. Utilities
Support components for verification:
- **evm_memory_model** - 64MB sparse memory with file I/O
- **evm_scoreboard** - Transaction checking with 3 matching modes

**Key Diagrams:**
- Memory model class
- Scoreboard class (parameterized)
- Matching modes (FIFO, Associative, Unordered)
- Usage flows

### 04. Agents
Protocol-specific verification components:
- **AXI-Lite** - 3 modes (MASTER/SLAVE/PASSIVE)
- **ADC** - Active with Python stimulus generation
- **DAC** - Passive with Python analysis
- **GPIO** - 32-pin control
- **Clock/Reset** - Infrastructure agents
- **PCIe** - Memory-mapped BFM

**Key Diagrams:**
- Agent base architecture
- Protocol agents summary
- Python integration flow
- Test environment structure

## How to Use This Documentation

### For New Users
1. Start with **Base Components** to understand the foundation
2. Read **Agents** to see available protocol support
3. Check **Register Model** if using CSR/register access
4. Review **Utilities** for memory and checking support

### For Implementation
1. Choose relevant **Agents** for your DUT
2. Configure **Register Model** if needed (via CSR generator)
3. Add **Memory Model** for DMA/buffer simulation
4. Use **Scoreboard** for output checking

### For Viewing Diagrams
- **GitHub**: Diagrams render automatically in markdown preview
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
  - Press `Ctrl+Shift+V` (Windows) or `Cmd+Shift+V` (Mac)
- **Online**: Use [Mermaid Live Editor](https://mermaid.live)

## Framework Architecture Summary

```
EVM Framework
├── Base (01)
│   ├── evm_object (logging, identification)
│   ├── evm_component (phases, hierarchy)
│   ├── evm_log (centralized logging)
│   ├── evm_root (simulation control)
│   └── evm_base_test (test base class)
│
├── Register Model (02)
│   ├── evm_reg_field (9 access types)
│   ├── evm_reg (field collection)
│   ├── evm_reg_block (address management)
│   └── Auto-generation (YAML → RAL)
│
├── Utilities (03)
│   ├── evm_memory_model (64MB sparse memory)
│   └── evm_scoreboard (3 matching modes)
│
└── Agents (04)
    ├── AXI-Lite (register access)
    ├── ADC (signal generation + Python)
    ├── DAC (capture + Python)
    ├── GPIO (control signals)
    ├── Clock/Reset (infrastructure)
    └── PCIe (memory-mapped BFM)
```

## Key Features

### Phased Execution
All components follow a phased execution model:
1. **build_phase()** - Create sub-components
2. **connect_phase()** - Connect interfaces
3. **run_phase()** - Main execution (spawns main_phase())
4. **final_phase()** - Cleanup and reporting

### Python Integration
- **ADC Agent**: Stimulus generation via `gen_stimulus.py`
- **DAC Agent**: Analysis via `analyze_spectrum.py`
- FFT, THD, SNR analysis support
- File-based data exchange

### Register Model
- Lightweight RAL alternative
- 9 field access types (RW, RO, WO, RC, RS, WC, WS, W1C, W1S)
- Auto-generated from YAML
- Top-level model aggregation

### Verification Support
- Memory model for DMA/buffer simulation
- Scoreboard with multiple matching modes
- Comprehensive logging system
- Statistics and reporting

## Related Documentation

- [REGISTER_MODEL.md](../REGISTER_MODEL.md) - Detailed RAL documentation
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [CSR Generator README](../../../csr_gen/README.md) - CSR generator usage

## Version Information

- **Created**: 2026-03-07
- **EVM Version**: 1.0
- **Diagram Format**: Mermaid
- **License**: MIT

---

*For questions or issues, please refer to the main EVM documentation or file an issue on GitHub.*
