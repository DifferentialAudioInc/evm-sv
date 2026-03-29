# EVM - Embedded Verification Methodology

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AI-First Development](https://img.shields.io/badge/Development-AI--First-blue)](CLAUDE.md)

**A lightweight SystemVerilog verification framework designed for embedded FPGA/ASIC projects**

🤖 **AI-First Development:** This project is designed to be developed primarily with Claude and other agentic AI assistants. See [AI_DEVELOPMENT.md](AI_DEVELOPMENT.md) for details.

**Developed by:** [Differential Audio Inc](https://github.com/DifferentialAudioInc)  
**License:** MIT

---

## 🎯 What is EVM?

EVM (Embedded Verification Methodology) is a **lightweight alternative to UVM** providing:

✅ **80% of UVM's utility with 20% of its complexity**  
✅ **Dual verification models** - Transaction-based AND Streaming-based  
✅ **Python integration** for DSP/RF workflows  
✅ **CSR Generator** - YAML to SystemVerilog/C  
✅ **Learning curve < 1 week** (vs weeks for UVM)  
✅ **~5,000 LOC** (vs ~50,000 for UVM)

### Why EVM Instead of UVM?

| Feature | UVM | EVM | Winner |
|---------|-----|-----|--------|
| **Learning Curve** | Weeks | Days | EVM ✅ |
| **Code Size** | ~50K LOC | ~5K LOC | EVM ✅ |
| **Compilation** | Minutes | Seconds | EVM ✅ |
| **Streaming Model** | ❌ | ✅ | EVM ✅ |
| **Python Integration** | Complex (DPI) | Simple (files) | EVM ✅ |
| **Enterprise Features** | ✅ Full | ⚠️ Essential | UVM |
| **Best For** | Large teams, ASIC | Small teams, FPGA/ASIC | Depends |

**See [docs/UVM_vs_EVM_ANALYSIS.md](docs/UVM_vs_EVM_ANALYSIS.md) for detailed comparison**

---

## 🚀 Quick Start

### For New Users

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DifferentialAudioInc/evm-sv.git
   cd evm-sv
   ```

2. **Try the example:**
   ```bash
   cd examples/simple_counter/sim
   
   # Launch Vivado and run in Tcl console:
   cd c:/evm/evm-sv/examples/simple_counter/sim
   source create_vivado_project.tcl
   ```

3. **Read the documentation:**
   - 📖 [CLAUDE.md](CLAUDE.md) - **Development rules and guidelines**
   - 📖 [AI_DEVELOPMENT.md](AI_DEVELOPMENT.md) - **How to develop with AI**
   - 📖 [examples/simple_counter/README.md](examples/simple_counter/README.md) - **Complete example**

### For AI Assistants

**🤖 Primary Reference:** [CLAUDE.md](CLAUDE.md) contains all development rules, coding standards, and architectural decisions.

**Key Context:**
- EVM is a **lightweight subset** of UVM (not a full replacement)
- Uses **12-phase methodology** for test execution
- Supports **dual models**: Transaction-based AND Streaming-based verification
- **Priority 1 features** to implement: Factory, Config DB, TLM ports
- **Keep it lightweight** - simplicity over complexity

---

## 📁 Project Structure

```
evm-sv/
├── CLAUDE.md                   # 🤖 AI Development Rules (PRIMARY REFERENCE)
├── AI_DEVELOPMENT.md           # Guide for AI-assisted development
├── README.md                   # This file
├── CONTRIBUTING.md             # Contribution guidelines
│
├── csr_gen/                    # CSR Generator Tool
│   ├── gen_csr.py             # YAML → SystemVerilog/C
│   ├── README.md              # Tool documentation
│   └── example/               # Working examples
│
├── python/                     # Python Utilities
│   ├── gen_stimulus.py        # Stimulus generation
│   └── analyze_spectrum.py   # Spectrum analysis
│
├── vkit/                       # SystemVerilog Framework
│   ├── src/                   # Base classes (evm_pkg)
│   │   ├── evm_pkg.sv
│   │   ├── evm_object.sv
│   │   ├── evm_component.sv
│   │   ├── evm_agent.sv
│   │   ├── evm_driver.sv
│   │   └── ... (see CLAUDE.md for full list)
│   │
│   └── docs/                  # Documentation
│       ├── UVM_vs_EVM_ANALYSIS.md      # Detailed UVM comparison
│       ├── EVM_PHASING_GUIDE.md        # 12-phase methodology
│       └── EVM_CRITICAL_FEATURES_ANALYSIS.md
│
├── examples/                   # Working Examples
│   └── simple_counter/        # Complete testbench example
│       ├── README.md          # Example documentation
│       ├── QUICKSTART.md      # How to run
│       ├── GUI_GUIDE.md       # Vivado GUI guide
│       ├── rtl/               # DUT
│       ├── tb/                # Testbench
│       └── sim/               # Simulation scripts
│
└── docs/                       # Additional Documentation
    ├── UVM_vs_EVM_ANALYSIS.md
    ├── EVM_PHASING_GUIDE.md
    └── EVM_CRITICAL_FEATURES_ANALYSIS.md
```

---

## ✨ Key Features

### 1. Dual Verification Models

**Transaction-Based (like UVM):**
```systemverilog
class my_sequence extends evm_sequence;
    task body();
        my_item item = new("item");
        item.randomize();
        send_item(item);
    endtask
endclass
```

**Streaming-Based (unique to EVM):**
```systemverilog
class stream_driver extends evm_stream_driver;
    task main_phase();
        load_stimulus("stimulus.txt");  // Python-generated
        stream_data();
    endtask
endclass
```

### 2. CSR Generator

Generate RTL and C headers from YAML:

```yaml
# my_regs.yaml
registers:
  - name: CONTROL
    offset: 0x00
    fields:
      - name: ENABLE
        bits: [0]
        reset: 0
```

```bash
python csr_gen/gen_csr.py my_regs.yaml output/
```

### 3. Python Integration

```python
# Generate stimulus
python gen_stimulus.py --type sine --freq 1000 --fs 48000 -o stim.txt

# Analyze results
python analyze_spectrum.py capture.txt --fs 48000 --plot
```

### 4. Phase-Based Testbench

```systemverilog
class my_test extends evm_base_test;
    function void build_phase();
        // Create agents
    endfunction
    
    task reset_phase();
        // Apply reset
    endtask
    
    task main_phase();
        raise_objection("test");
        // Run test
        drop_objection("test");
    endtask
    
    function void check_phase();
        // Verify results
    endfunction
endclass
```

---

## 🤖 AI-First Development

### Why AI-First?

This project is designed from the ground up to be developed with AI assistants:

✅ **Comprehensive documentation** optimized for AI context  
✅ **[CLAUDE.md](CLAUDE.md)** - Single source of truth for development rules  
✅ **Clear coding standards** and anti-patterns  
✅ **UVM comparison** for informed feature decisions  
✅ **Examples** demonstrating best practices  

### How to Develop with AI

1. **Read [CLAUDE.md](CLAUDE.md)** - All rules and guidelines in one place
2. **Use [AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)** - Workflow and prompts
3. **Reference examples** - `examples/simple_counter/`
4. **Check UVM comparison** - `docs/UVM_vs_EVM_ANALYSIS.md`

### Prompts for Common Tasks

**Adding a new feature:**
```
I want to add [feature] to EVM. 
Please check CLAUDE.md section 3.1.2 for feature priorities.
Is this Priority 1, 2, or 3? Then implement accordingly.
```

**Refactoring code:**
```
Please refactor [file] following CLAUDE.md section 6 coding standards.
Keep it lightweight per section 3.1.1 - EVM should be simpler than UVM.
```

**Creating new agent:**
```
Create a new agent for [protocol] following the agent pattern 
in CLAUDE.md section 11.1. Make it generic and configurable.
```

---

## 📖 Documentation

### Primary References

| Document | Purpose | Audience |
|----------|---------|----------|
| **[CLAUDE.md](CLAUDE.md)** | Development rules, coding standards | AI Assistants, Developers |
| **[AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)** | AI collaboration workflow | Users working with AI |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Contribution guidelines | Contributors |

### Technical Documentation

| Document | Purpose |
|----------|---------|
| [docs/UVM_vs_EVM_ANALYSIS.md](docs/UVM_vs_EVM_ANALYSIS.md) | Detailed UVM comparison, feature gaps |
| [docs/EVM_PHASING_GUIDE.md](docs/EVM_PHASING_GUIDE.md) | 12-phase methodology |
| [docs/EVM_CRITICAL_FEATURES_ANALYSIS.md](docs/EVM_CRITICAL_FEATURES_ANALYSIS.md) | Feature roadmap |

### Examples

| Example | Description |
|---------|-------------|
| [examples/simple_counter/](examples/simple_counter/) | Complete testbench with all phases |
| [examples/simple_counter/QUICKSTART.md](examples/simple_counter/QUICKSTART.md) | How to run simulation |
| [examples/simple_counter/GUI_GUIDE.md](examples/simple_counter/GUI_GUIDE.md) | Vivado GUI workflow |

---

## 🏗️ Current Status (March 2026)

### ✅ Implemented (~75%)

- ✅ Core framework (evm_pkg) - All base classes
- ✅ 12-phase methodology
- ✅ Transaction model (sequences, items, sequencer)
- ✅ Streaming model (file I/O, Python integration)
- ✅ Protocol agents (clock, reset, examples)
- ✅ CSR generator (YAML → SV/C)
- ✅ Python tools (stimulus gen, spectrum analysis)
- ✅ Complete working example (simple_counter)
- ✅ Comprehensive documentation

### ❌ Priority 1 Gaps (~25%)

**Essential for production use:**

1. **Factory Pattern** (~10-13 days)
   - Type and instance overrides
   - Dynamic component creation
   
2. **Configuration Database** (~4-5 days)
   - Type-safe hierarchical configuration
   - Wildcard matching
   
3. **TLM Seq Item Port** (~3-4 days)
   - Driver-sequencer connection
   - Pull-mode transaction flow

**Total: 3-4 weeks to production-ready**

### ⚠️ Priority 2: Nice to Have

- Printing infrastructure
- Comparison infrastructure
- Complete hierarchy navigation
- Packing/unpacking

### ❌ Priority 3: Intentionally Skipped

- Full RAL (use CSR generator instead)
- Virtual sequences (not needed)
- Callback infrastructure (too complex)
- TLM 2.0 (overkill)
- Additional phase domains (12 is enough)

**See [docs/UVM_vs_EVM_ANALYSIS.md](docs/UVM_vs_EVM_ANALYSIS.md) for roadmap**

---

## 💡 Getting Help

### For Users

1. **Check documentation:**
   - Start with [examples/simple_counter/README.md](examples/simple_counter/README.md)
   - Read [docs/EVM_PHASING_GUIDE.md](docs/EVM_PHASING_GUIDE.md)
   
2. **Ask AI assistant:**
   - Claude, ChatGPT, etc. can read [CLAUDE.md](CLAUDE.md)
   - Example: "Explain how EVM phases work using CLAUDE.md"

3. **Open an issue:**
   - GitHub Issues for bugs or questions

### For AI Assistants

**You have access to comprehensive documentation:**

1. **[CLAUDE.md](CLAUDE.md)** - Start here, contains everything
2. **[docs/UVM_vs_EVM_ANALYSIS.md](docs/UVM_vs_EVM_ANALYSIS.md)** - For UVM feature questions
3. **[examples/](examples/)** - For implementation patterns

**Remember:**
- EVM is **lightweight** - don't over-engineer
- Check **Priority levels** before adding features
- Follow **coding standards** in CLAUDE.md Section 6
- Keep **constructors minimal**
- Always **call super.method()** first

---

## 🤝 Contributing

We welcome contributions! This project uses an **AI-first development approach**.

### Contribution Workflow

1. **Read [CLAUDE.md](CLAUDE.md)** to understand the project
2. **Read [AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)** for workflow
3. **Fork and create a branch**
4. **Use AI assistant** to help implement changes
5. **Ensure documentation is updated**
6. **Submit pull request**

### Guidelines

- ✅ **DO** use AI assistants (Claude, ChatGPT, etc.)
- ✅ **DO** follow [CLAUDE.md](CLAUDE.md) coding standards
- ✅ **DO** check Priority levels before adding features
- ✅ **DO** update documentation with code changes
- ❌ **DON'T** add complex UVM features (keep it lightweight)
- ❌ **DON'T** break existing examples
- ❌ **DON'T** add features without updating CLAUDE.md

**See [CONTRIBUTING.md](CONTRIBUTING.md) for details**

---

## 📊 Success Metrics

EVM is successful because:

✅ **Learning curve < 1 week** (vs weeks for UVM)  
✅ **Code size < 10K LOC** (vs 50K for UVM)  
✅ **Compilation < 5 seconds** (vs minutes for UVM)  
✅ **Streaming model** (not in UVM)  
✅ **Python integration** (simpler than UVM)  
✅ **AI-friendly documentation**  

---

## 📜 License

**MIT License** - See [LICENSE](LICENSE) file

Copyright (c) 2026 Differential Audio Inc

---

## 🏢 About Differential Audio Inc

Differential Audio Inc develops advanced audio and signal processing solutions for professional and embedded applications. This verification framework was developed to support our internal FPGA/ASIC workflows and is now available as open source.

**This project demonstrates our AI-first development philosophy.**

---

## 🔗 Quick Links

- 📖 **[CLAUDE.md](CLAUDE.md)** - AI Development Rules
- 🤖 **[AI_DEVELOPMENT.md](AI_DEVELOPMENT.md)** - AI Workflow Guide
- 📝 **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution Guidelines
- 📚 **[docs/](docs/)** - Technical Documentation
- 💡 **[examples/](examples/)** - Working Examples
- 🐛 **[Issues](https://github.com/DifferentialAudioInc/evm-sv/issues)** - Bug Reports

---

**Version:** 1.0.0  
**Status:** Beta (75% Complete)  
**Development Model:** AI-First 🤖  
**Last Updated:** 2026-03-28
