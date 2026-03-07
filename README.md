# EVM - Embedded Verification Module Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A SystemVerilog verification framework with integrated CSR generation tooling.

**Repository:** https://github.com/DifferentialAudioInc/evm-sv  
**Developed by:** [Differential Audio Inc](https://github.com/DifferentialAudioInc)

## Overview

EVM provides a lightweight, reusable verification framework for digital hardware projects. It includes:

- **Base verification classes** for agents, monitors, drivers, sequences
- **CSR (Control/Status Register) generator** from YAML definitions
- **Python utilities** for stimulus generation and analysis
- **Protocol agents** for common interfaces (AXI-Lite, ADC, PCIe, etc.)

## Project Structure

```
evm/
├── csr_gen/                    # CSR Generator Tool
│   ├── gen_csr.py             # Python generator script
│   ├── README.md              # Tool documentation
│   └── example/               # Working examples
│
├── python/                     # Python Utilities
│   ├── gen_stimulus.py        # Stimulus generation
│   └── analyze_spectrum.py   # Spectrum analysis
│
└── vkit/                       # SystemVerilog Framework
    ├── src/                    # Base classes
    │   ├── evm_pkg.sv
    │   ├── evm_object.sv
    │   ├── evm_component.sv
    │   ├── evm_agent.sv
    │   ├── evm_driver.sv
    │   ├── evm_monitor.sv
    │   ├── evm_sequencer.sv
    │   ├── evm_sequence.sv
    │   ├── evm_sequence_item.sv
    │   ├── evm_base_test.sv
    │   └── evm_root.sv
    │
    └── docs/                   # Documentation
        ├── README.md
        ├── EVM_ARCHITECTURE.md
        ├── EVM_RULES.md
        └── evm_vkit/          # Verification kit examples

```

## Features

### CSR Generator

Generate SystemVerilog RTL and C headers from YAML register definitions:

```bash
python evm/csr_gen/gen_csr.py my_regs.yaml output_dir
```

Features:
- Type-safe register structures for RTL and C
- Automatic documentation generation
- File lists for simulation and synthesis tools
- Module-organized output structure

See `csr_gen/README.md` for complete documentation.

### Verification Framework

Base classes for building SystemVerilog testbenches:

- **evm_object** - Base class for all verification objects
- **evm_component** - Structural components (agents, monitors, etc.)
- **evm_agent** - Protocol agent wrapper
- **evm_driver** - Transaction-level drivers
- **evm_monitor** - Protocol monitors
- **evm_sequencer** - Sequence management
- **evm_sequence** - Transaction sequences
- **evm_base_test** - Test infrastructure

### Python Utilities

- **gen_stimulus.py** - Generate test stimulus files
- **analyze_spectrum.py** - FFT and spectrum analysis

## Quick Start

### Using CSR Generator

1. Create a YAML file defining your registers (see `csr_gen/example/`)
2. Run the generator:
   ```bash
   python evm/csr_gen/gen_csr.py my_registers.yaml my_output/
   ```
3. Include generated files in your project:
   ```bash
   # Simulation
   vcs -f my_output/csr_files.f
   
   # Synthesis
   source my_output/csr_files.tcl
   ```

### Using Verification Framework

1. Import the EVM package in your testbench:
   ```systemverilog
   import evm_pkg::*;
   ```

2. Extend base classes for your protocol:
   ```systemverilog
   class my_driver extends evm_driver;
       // Your driver implementation
   endclass
   ```

3. Build your testbench using EVM components

See `evm/docs/` for architecture and usage guidelines.

## Requirements

### CSR Generator
- Python 3.6+
- PyYAML: `pip install pyyaml`

### Verification Framework
- SystemVerilog simulator (VCS, Xcelium, Questa, etc.)

## Documentation

- **CSR Generator:** `csr_gen/README.md`
- **EVM Architecture:** `evm/vkit/docs/EVM_ARCHITECTURE.md`
- **Streaming Guide:** `evm/vkit/docs/STREAMING_GUIDE.md` - Transaction vs Streaming agents
- **Coding Rules:** `evm/vkit/docs/EVM_RULES.md`
- **Examples:** `csr_gen/example/` and `evm/vkit/docs/evm_vkit/`

## About Differential Audio Inc

Differential Audio Inc develops advanced audio and signal processing solutions for professional and embedded applications. This verification framework was developed to support our internal FPGA/ASIC development workflows and is now available as open source.

## License

MIT License - see LICENSE file for details.

Copyright (c) 2026 Differential Audio Inc

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Submit a pull request

See CONTRIBUTING.md for detailed guidelines.

## Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/DifferentialAudioInc/evm-sv/issues)
- For commercial support or consulting, contact Differential Audio Inc

---

**Version:** 1.0.0  
**Status:** Production Ready
