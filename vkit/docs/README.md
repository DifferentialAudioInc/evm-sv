# EVM - Embedded Verification Methodology

**A lightweight, dual-model verification framework for embedded systems**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Issues](https://img.shields.io/github/issues/username/evm)](https://github.com/username/evm/issues)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## Overview

EVM (Embedded Verification Methodology) is an open-source verification framework designed specifically for embedded systems, FPGAs, and ASICs. Unlike traditional verification methodologies (UVM), EVM natively supports **both transaction-based and streaming-based** verification models, making it ideal for modern embedded systems with mixed interfaces.

### Key Features

- ✅ **Dual-Model Architecture**: Native support for both streaming (ADC/DAC) and transaction (AXI, APB) interfaces
- ✅ **Python Integration**: Modern toolchain with numpy/scipy for signal generation and analysis
- ✅ **Lightweight**: Simple, understandable codebase without excessive automation
- ✅ **File-Based Streaming**: Fast, debuggable, simulator-independent
- ✅ **Embedded-Focused**: Designed for FPGA/ASIC embedded systems
- ✅ **Open Source**: MIT license, community-driven development

---

## Quick Start

### Prerequisites

- SystemVerilog simulator (Vivado, ModelSim, VCS, etc.)
- Python 3.7+ with numpy, scipy, matplotlib (for streaming features)

### Basic Example

```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

class my_test extends evm_base_test;
    function void connect_interfaces(virtual my_if vif);
        my_agent = new("agent", this);
        my_agent.set_vif(vif);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // Your test code
        #100us;
        
        drop_objection("test");
    endtask
endclass
```

### CSR Configuration Example

```systemverilog
// Create CSR sequence
evm_csr_sequence cfg_seq = new("device_config");
cfg_seq.add_write(32'h1000, 32'h00000001, "ENABLE");
cfg_seq.add_write(32'h1004, 32'h12345678, "CONFIG");
cfg_seq.add_read_check(32'h1008, 32'hDEADBEEF, 32'hFFFFFFFF, "STATUS");

// Execute via sequencer
axi_agent.sequencer.execute_sequence(cfg_seq);
```

### Streaming Example

```bash
# Generate stimulus
python python/gen_stimulus.py --type sine --freq 10e6 --fs 100e6 --output stimulus.txt

# Run simulation
cd run && vivado -mode batch -source run_sim.tcl

# Analyze results
python python/analyze_spectrum.py capture.txt --fs 100e6 --freq 10e6
```

---

## Architecture

### Dual-Model Design

EVM uniquely supports two verification paradigms:

**1. Transaction Model** (for protocol-based interfaces)
```
Test → Sequence → Sequencer → Driver → Interface → DUT
```

**2. Streaming Model** (for continuous data interfaces)
```
Python → Stimulus File → Driver → Interface → DUT → Monitor → Capture File → Python Analysis
```

### Components

- **Core Framework** (`src/`): Base classes, logging, phases
- **VKit Agents** (`docs/evm_vkit/`): Reusable verification components
- **Python Tools** (`../python/`): Signal generation and analysis
- **Tests** (`tests/`): Example tests and base classes

---

## Documentation

- [**EVM Architecture**](EVM_ARCHITECTURE.md) - Framework design and philosophy
- [**EVM Rules**](EVM_RULES.md) - Design guidelines and best practices
- [**Streaming Guide**](STREAMING_IMPLEMENTATION_STATUS.md) - Streaming model usage
- [**API Reference**](docs/API.md) - Class and method reference (coming soon)

---

## VKit Agents

Pre-built verification components:

- **evm_clk_agent**: Configurable clock generation
- **evm_rst_agent**: Reset sequencing
- **evm_stream_agent**: File-based streaming (ADC/DAC models)
- **evm_axi_lite_agent**: AXI-Lite master with CSR sequences
- **evm_adc_agent**: Multi-channel ADC with streaming support
- **evm_pcie_agent**: PCIe endpoint model

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📝 Improve documentation
- 🔧 Submit bug fixes
- ✨ Add new agents or features
- 📊 Share your test examples

---

## Credits

### Creator

**EVM** was created by **[Differential Audio Inc.](https://differentialaudio.com)** to address the unique verification challenges of embedded DSP and RF systems.

### Engineering Team

- Differential Audio Inc. Engineering Team - Initial design and implementation

### Contributors

See [CONTRIBUTORS.md](CONTRIBUTORS.md) for the full list of contributors.

---

## License

EVM is released under the **MIT License**. See [LICENSE](LICENSE) for details.

```
Copyright (c) 2026 Differential Audio Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## Support

### Community Support (Free)

- **Issues**: [GitHub Issues](https://github.com/username/evm/issues)
- **Discussions**: [GitHub Discussions](https://github/username/evm/discussions)
- **Documentation**: [Wiki](https://github.com/username/evm/wiki)

### Commercial Support

**Differential Audio Inc.** offers professional services for enterprises:

- 📞 **Support Contracts** - Priority bug fixes, features, and direct access
- 🎓 **Training & Certification** - Master EVM methodology in 3 days
- 🛠️ **Custom Development** - Protocol agents, IP blocks, and integrations
- ☁️ **Hosted Solutions** - Cloud-based verification and analysis
- 🤝 **Consulting** - Architecture review and implementation support

**Contact:** eric@differentialaudioinc.com  
**Website:** [differentialaudio.com](https://differentialaudio.com)

---

## Comparison with UVM

| Feature | EVM | UVM |
|---------|-----|-----|
| **Streaming Support** | ✅ Native | ❌ Requires workarounds |
| **Python Integration** | ✅ Built-in | ❌ Complex DPI |
| **Learning Curve** | Low | High |
| **Code Size** | Lightweight | Large |
| **Embedded Focus** | ✅ Yes | ❌ General purpose |
| **File-Based Stimulus** | ✅ Native | ❌ Limited |
| **Signal Analysis** | ✅ Built-in Python tools | ❌ External |

---

## Roadmap

- [ ] Complete VKit agent library
- [ ] Add more protocol support (SPI, I2C, UART)
- [ ] Scoreboard framework
- [ ] Coverage collection utilities
- [ ] Example projects repository
- [ ] Video tutorials
- [ ] Online documentation site

---

## Acknowledgments

Special thanks to:
- The SystemVerilog verification community
- Contributors to numpy, scipy, and matplotlib
- All early adopters and testers

---

**⭐ If you find EVM useful, please star the repository!**
