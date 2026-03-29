# CLAUDE.md - EVM Project Development Rules and Guidelines

**EVM - Embedded Verification Methodology Framework**  
**Version:** 1.0.0  
**Date:** 2026-03-28  
**Purpose:** Comprehensive development rules and guidelines for AI assistants and developers

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Copyright and Licensing](#2-copyright-and-licensing)
3. [Project Architecture](#3-project-architecture)
4. [Development Philosophy](#4-development-philosophy)
5. [File Organization Rules](#5-file-organization-rules)
6. [SystemVerilog Coding Standards](#6-systemverilog-coding-standards)
7. [Python Coding Standards](#7-python-coding-standards)
8. [Documentation Requirements](#8-documentation-requirements)
9. [Testing and Verification](#9-testing-and-verification)
10. [Phase-Based Development](#10-phase-based-development)
11. [Common Patterns](#11-common-patterns)
12. [Anti-Patterns to Avoid](#12-anti-patterns-to-avoid)
13. [Tool-Specific Guidelines](#13-tool-specific-guidelines)
14. [Contribution Workflow](#14-contribution-workflow)
15. [Quick Reference](#15-quick-reference)

---

## 1. Project Overview

### 1.1 What is EVM?

EVM (Embedded Verification Methodology) is a lightweight SystemVerilog verification framework with integrated tools for FPGA/ASIC verification. It provides:

- **Dual-model architecture**: Transaction-based AND streaming-based verification
- **CSR Generator**: YAML to SystemVerilog/C register generation
- **Python integration**: DSP/RF stimulus generation and analysis
- **Protocol agents**: Reusable agents for AXI-Lite, ADC, PCIe, etc.
- **Base classes**: Clean hierarchy for verification components

### 1.2 Repository Structure

```
evm-sv/
├── csr_gen/                    # CSR Generator Tool
│   ├── gen_csr.py             # Python generator script
│   ├── README.md              # Tool documentation
│   └── example/               # Working examples
│
├── python/                     # Python Utilities
│   ├── gen_stimulus.py        # Stimulus generation
│   └── analyze_spectrum.py   # Spectrum analysis
│
├── vkit/                       # SystemVerilog Framework
│   ├── src/                   # Base classes (evm_pkg)
│   │   ├── evm_pkg.sv         # Main package file
│   │   ├── evm_object.sv      # Base object
│   │   ├── evm_component.sv   # Component hierarchy
│   │   ├── evm_agent.sv       # Generic agent
│   │   ├── evm_driver.sv      # Base driver
│   │   ├── evm_monitor.sv     # Base monitor
│   │   ├── evm_sequencer.sv   # Transaction sequencer
│   │   ├── evm_sequence.sv    # Sequence base
│   │   ├── evm_stream_*.sv    # Streaming components
│   │   └── evm_root.sv        # Singleton phase manager
│   │
│   └── docs/                  # Documentation + Examples
│       ├── README.md
│       ├── EVM_ARCHITECTURE.md
│       ├── EVM_RULES.md
│       └── evm_vkit/          # Protocol agents
│
├── README.md                  # Main documentation
├── CONTRIBUTING.md            # Contribution guidelines
├── EVM_ASSESSMENT.md          # Framework assessment
├── NEXT_STEPS.md              # Development roadmap
├── LICENSE                    # MIT License
└── CLAUDE.md                  # This file
```

### 1.3 Key Design Principles

1. **Lightweight over feature-rich**: Simpler than UVM, easier to learn
2. **Dual verification models**: Both transaction and streaming supported natively
3. **Python integration**: File-based interface for DSP/RF workflows
4. **Practical over theoretical**: Built for real FPGA/ASIC projects
5. **Reusable components**: Generic agents, not hardcoded specific ones

---

## 2. Copyright and Licensing

### 2.1 License

EVM is licensed under the **MIT License**. See `LICENSE` file for full terms.

**Key points:**
- Open source and freely usable
- Commercial use allowed
- No warranty provided (AS IS)
- Attribution required
- Minimal restrictions

### 2.2 Copyright Header Rules

**RULE 2.2.1**: Every source file MUST include a copyright header.

#### SystemVerilog Files (.sv)

```systemverilog
//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: filename.sv
// Description: Brief description of file purpose
// Author: Differential Audio Inc., EVM Contributors
// Date: YYYY-MM-DD
//==============================================================================

// Code starts here
```

#### Python Files (.py)

```python
#!/usr/bin/env python3
"""
EVM - Embedded Verification Methodology
Copyright (c) 2026 Differential Audio Inc.
Licensed under MIT License - see LICENSE file for full terms

File: filename.py
Description: Brief description of file purpose
Author: Author name or "EVM Contributors"
Date: YYYY-MM-DD
"""

# Code starts here
```

#### TCL Files (.tcl)

```tcl
#===============================================================================
# EVM - Embedded Verification Methodology
# Copyright (c) 2026 Differential Audio Inc.
# Licensed under MIT License - see LICENSE file for full terms
#===============================================================================
# File: filename.tcl
# Description: Brief description of file purpose
# Author: Author name or "EVM Contributors"
# Date: YYYY-MM-DD
#===============================================================================

# Code starts here
```

#### Markdown Files (.md)

```markdown
# Title

**EVM - Embedded Verification Methodology**  
**Copyright:** (c) 2026 Differential Audio Inc.  
**License:** MIT - see LICENSE file

Content starts here...
```

### 2.3 Attribution Requirements

- Copyright notice must remain intact in all files
- Differential Audio Inc. must be credited as original creator
- Contributors may add their names to appropriate files
- Modifications should note contributor name in file header

---

## 3. Project Architecture

### 3.1 EVM Design Philosophy vs UVM

**CRITICAL CONTEXT:** EVM is intentionally a **lightweight subset** of UVM, not a full replacement.

#### 3.1.1 UVM vs EVM Strategy

**UVM Approach:**
- Comprehensive, enterprise-grade framework
- ~50,000 lines of code, ~150 files
- Steep learning curve (weeks)
- Full feature set for all verification needs
- Complex infrastructure (factory, config DB, TLM 2.0, RAL, callbacks)

**EVM Approach:**
- Essential subset for embedded FPGA/ASIC
- ~5,000 lines of code, ~25 files  
- Gentle learning curve (days)
- 80% of practical utility with 20% of complexity
- Unique features: Streaming model + Python integration

#### 3.1.2 Feature Implementation Priority

**✅ Priority 1: MUST HAVE (Implement)**
These features are critical for reusable verification:

1. **Factory Pattern**
   - Type and instance overrides
   - Dynamic component creation
   - Enables reusable test libraries
   - **Status:** ❌ Not implemented yet
   - **Effort:** 3-4 days

2. **Configuration Database**
   - Type-safe configuration
   - Hierarchical scope
   - Wildcard matching
   - **Status:** ❌ Not implemented yet
   - **Effort:** 4-5 days

3. **TLM Seq Item Port**
   - Driver-sequencer connection
   - Pull-mode transaction flow
   - `get_next_item()`, `item_done()`
   - **Status:** ❌ Not implemented yet
   - **Effort:** 3-4 days

**⚠️ Priority 2: NICE TO HAVE (Consider)**
These enhance usability but aren't critical:

1. **Printing Infrastructure** - Configurable object printing
2. **Comparison Infrastructure** - Deep object comparison
3. **Packing/Unpacking** - Serialization support
4. **Complete Hierarchy Navigation** - `get_children()`, `lookup()`
5. **Transaction Recording** - Waveform database integration

**❌ Priority 3: SKIP (Keep Lightweight)**
These add complexity without proportional value for embedded:

1. **Full Register Abstraction Layer (RAL)** - Use CSR generator instead
2. **Virtual Sequences** - Not needed for embedded scope
3. **Callbacks Infrastructure** - Adds complexity
4. **TLM 2.0** - Overkill for embedded
5. **Field Macros** - Syntactic sugar, not essential
6. **Phases Beyond 12** - Current set is sufficient

#### 3.1.3 UVM to EVM Mapping

| UVM Class | EVM Equivalent | Status | Notes |
|-----------|----------------|--------|-------|
| `uvm_object` | `evm_object` | ✅ Partial | Missing: print, copy, compare, pack |
| `uvm_component` | `evm_component` | ✅ Good | Has phases, hierarchy; Missing: factory methods |
| `uvm_agent` | `evm_agent` | ✅ Good | Missing: is_active configuration |
| `uvm_driver` | `evm_driver` | ⚠️ Basic | Missing: seq_item_port |
| `uvm_monitor` | `evm_monitor` | ✅ Good | Functional |
| `uvm_sequencer` | `evm_sequencer` | ⚠️ Basic | Missing: seq_item_export |
| `uvm_sequence` | `evm_sequence` | ✅ Good | Functional |
| `uvm_sequence_item` | `evm_sequence_item` | ✅ Good | Functional |
| `uvm_test` | `evm_base_test` | ✅ Good | Functional |
| `uvm_env` | N/A | ❌ Skip | Not needed - keep flat |
| `uvm_scoreboard` | `evm_scoreboard` | ✅ Good | Functional |
| `uvm_factory` | N/A | ❌ Missing | **Priority 1** - implement |
| `uvm_config_db` | N/A | ❌ Missing | **Priority 1** - implement |
| TLM ports | N/A | ❌ Missing | **Priority 1** - implement seq_item_port only |
| `uvm_reg_*` | CSR Generator | ✅ Alternative | Simpler tool-based approach |
| N/A | `evm_stream_*` | ✅ Unique | **EVM-only** streaming model |

#### 3.1.4 Refactoring Strategy

**Phase 1: Foundation (Weeks 1-2)**
- Implement `evm_factory` singleton
- Add factory methods to `evm_object` and `evm_component`
- Add type/instance override support
- Update examples to use factory

**Phase 2: Configuration (Weeks 3-4)**
- Implement `evm_config_db#(T)` template
- Add resource pool infrastructure
- Integrate with `apply_config_settings()`
- Update examples to use config_db

**Phase 3: Connectivity (Week 5)**
- Implement TLM port base classes
- Add `seq_item_port` to `evm_driver`
- Add `seq_item_export` to `evm_sequencer`
- Update driver/sequencer examples

**Phase 4: Polish (Week 6)**
- Add missing hierarchy methods
- Implement basic printing
- Update all documentation
- Comprehensive testing

**DO NOT ADD:**
- Multiple phase domains
- Virtual sequences
- Full TLM 2.0
- Callbacks infrastructure
- Field macros
- Full RAL

### 3.2 Class Hierarchy

```
evm_object (base for all EVM objects)
  │
  ├─ evm_component (structural components with hierarchy)
  │   ├─ evm_agent (protocol agent wrapper)
  │   ├─ evm_driver (transaction/streaming drivers)
  │   ├─ evm_monitor (protocol monitors)
  │   ├─ evm_sequencer (sequence management)
  │   ├─ evm_base_test (test infrastructure)
  │   └─ evm_scoreboard (result checking)
  │
  ├─ evm_sequence_item (transaction-based items)
  │   └─ evm_csr_item (CSR transactions)
  │
  ├─ evm_sequence (sequence containers)
  │   └─ evm_csr_sequence (CSR sequences)
  │
  └─ evm_*_cfg (configuration objects)
      ├─ evm_stream_cfg
      └─ (protocol-specific configs)
```

### 3.2 Package Architecture

**RULE 3.2.1**: Use two-tier package structure.

```systemverilog
// Tier 1: Core framework (evm_pkg.sv)
package evm_pkg;
    `include "evm_log.sv"
    `include "evm_object.sv"
    `include "evm_component.sv"
    `include "evm_agent.sv"
    `include "evm_driver.sv"
    `include "evm_monitor.sv"
    `include "evm_sequencer.sv"
    `include "evm_sequence.sv"
    `include "evm_sequence_item.sv"
    `include "evm_stream_agent.sv"
    `include "evm_stream_driver.sv"
    `include "evm_stream_monitor.sv"
    `include "evm_stream_cfg.sv"
    `include "evm_csr_item.sv"
    `include "evm_csr_sequence.sv"
    `include "evm_base_test.sv"
    `include "evm_root.sv"
endpackage

// Tier 2: Protocol agents (evm_vkit_pkg.sv)
package evm_vkit_pkg;
    import evm_pkg::*;
    
    `include "evm_clk_agent/evm_clk_if.sv"
    `include "evm_clk_agent/evm_clk_cfg.sv"
    `include "evm_clk_agent/evm_clk_agent.sv"
    `include "evm_rst_agent/evm_rst_if.sv"
    // ... etc
endpackage
```

**RULE 3.2.2**: Import both packages in test files.

```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

class my_test extends evm_base_test;
    // ...
endclass
```

### 3.3 Dual Verification Models

EVM uniquely supports BOTH verification models:

#### Transaction-Based Model
- For control interfaces (AXI-Lite, APB, CSR access)
- Uses sequences and sequencers
- Protocol-specific transactions
- Driver converts transactions to pin wiggles

#### Streaming-Based Model
- For data interfaces (ADC, DAC, streaming data)
- File-based stimulus and capture
- Python integration for DSP/RF
- Continuous data flow

**RULE 3.3.1**: Choose the right model for your interface:
- **Control/Status** → Transaction model
- **Data streams** → Streaming model
- **Mixed designs** → Use both models simultaneously

---

## 4. Development Philosophy

### 4.1 Core Values

1. **Simplicity**: Prefer simple solutions over complex ones
2. **Reusability**: Write generic, configurable components
3. **Readability**: Code should be self-documenting
4. **Practicality**: Solve real problems, not theoretical ones
5. **Minimalism**: Keep constructors and base classes minimal

### 4.2 Coding Principles

**RULE 4.2.1**: Follow Single Responsibility Principle
- Each class has one clear purpose
- Agents wrap driver + monitor for a protocol
- Drivers handle stimulus generation
- Monitors observe and check protocol

**RULE 4.2.2**: Favor Composition Over Inheritance
- Use configuration objects, not deep class hierarchies
- Parameterize behavior through config, not subclassing

**RULE 4.2.3**: Make It Work, Then Make It Clean
1. First: Get functionality working
2. Second: Refactor for clarity
3. Third: Optimize if needed (rarely)

**RULE 4.2.4**: Document Intent, Not Implementation
- Explain WHY, not just WHAT
- Add comments for non-obvious decisions
- Keep documentation up-to-date

---

## 5. File Organization Rules

### 5.1 Directory Structure

**RULE 5.1.1**: Maintain consistent directory structure:

```
evm-sv/
├── csr_gen/              # Standalone tools
│   ├── gen_csr.py
│   ├── README.md
│   └── example/
│
├── python/               # Shared utilities
│   ├── gen_stimulus.py
│   └── analyze_spectrum.py
│
└── vkit/                 # Verification framework
    ├── src/              # Core framework sources
    │   └── *.sv
    └── docs/             # Documentation + examples
        ├── *.md
        └── evm_vkit/     # Protocol agents
```

### 5.2 File Naming Conventions

**RULE 5.2.1**: Use consistent naming:

- **Classes**: `evm_<component_name>.sv` (e.g., `evm_driver.sv`)
- **Interfaces**: `evm_<protocol>_if.sv` (e.g., `evm_axi_lite_if.sv`)
- **Configs**: `evm_<protocol>_cfg.sv` (e.g., `evm_clk_cfg.sv`)
- **Packages**: `evm_pkg.sv`, `evm_vkit_pkg.sv`
- **Python**: Snake_case (e.g., `gen_stimulus.py`)
- **Docs**: UPPERCASE.md for top-level (e.g., `README.md`)

### 5.3 Agent Organization

**RULE 5.3.1**: Each agent gets its own directory:

```
evm_vkit/
├── evm_clk_agent/
│   ├── evm_clk_if.sv       # Interface
│   ├── evm_clk_cfg.sv      # Configuration
│   └── evm_clk_agent.sv    # Agent (includes driver/monitor)
│
└── evm_axi_lite_agent/
    ├── evm_axi_lite_if.sv
    ├── evm_axi_lite_cfg.sv
    ├── evm_axi_lite_driver.sv
    ├── evm_axi_lite_monitor.sv
    └── evm_axi_lite_agent.sv
```

---

## 6. SystemVerilog Coding Standards

### 6.1 General Rules

**RULE 6.1.1**: Use 4-space indentation (no tabs)

**RULE 6.1.2**: Maximum line length: 100 characters (soft limit)

**RULE 6.1.3**: Use meaningful variable names:
```systemverilog
// ✅ GOOD
int transaction_count;
real frequency_mhz;

// ❌ BAD
int tc;
real f;
```

### 6.2 Class Structure

**RULE 6.2.1**: Standard class structure:

```systemverilog
class evm_example extends evm_component;
    
    //--------------------------------------------------------------------------
    // Properties
    //--------------------------------------------------------------------------
    local int my_local_var;          // Private
    protected int my_protected_var;  // Derived classes
    int my_public_var;               // Public (default)
    
    //--------------------------------------------------------------------------
    // Configuration
    //--------------------------------------------------------------------------
    evm_example_cfg cfg;
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name, evm_component parent);
        super.new(name, parent);
    endfunction
    
    //--------------------------------------------------------------------------
    // Phase Methods
    //--------------------------------------------------------------------------
    virtual function void build_phase();
        super.build_phase();
        // Build logic
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        // Main logic
    endtask
    
    //--------------------------------------------------------------------------
    // Public Methods
    //--------------------------------------------------------------------------
    virtual function void my_method();
        // Implementation
    endfunction
    
    //--------------------------------------------------------------------------
    // Local Methods
    //--------------------------------------------------------------------------
    local function void helper_method();
        // Helper implementation
    endfunction
    
endclass
```

### 6.3 Constructor Rules

**RULE 6.3.1**: Keep constructors MINIMAL
```systemverilog
// ✅ CORRECT
function new(string name = "my_class");
    super.new(name);
    // Only simple initialization here
endfunction

// ❌ WRONG
function new(string name = "my_class");
    super.new(name);
    my_agent = new("agent", this);  // Don't create objects
    configure();                     // Don't call methods
endfunction
```

**RULE 6.3.2**: Always call `super.new()` first

**RULE 6.3.3**: Don't use `new()` in ternary operators
```systemverilog
// ❌ WRONG - Syntax error
this.cfg = (cfg != null) ? cfg : new();

// ✅ CORRECT - Use if-else
if (cfg != null) begin
    this.cfg = cfg;
end else begin
    this.cfg = new("cfg");
end
```

### 6.4 Task/Function Rules

**RULE 6.4.1**: No default parameters in tasks
```systemverilog
// ❌ WRONG - Not supported
virtual task my_task(int param = 10);

// ✅ CORRECT - No defaults
virtual task my_task(int param);

// ✅ ALTERNATIVE - Overloading
virtual task my_task_default();
    my_task(10);
endtask

virtual task my_task(int param);
    // Implementation
endtask
```

**RULE 6.4.2**: Always use `virtual` for overrideable methods

**RULE 6.4.3**: Always call `super.method()` first in overrides
```systemverilog
virtual function void build_phase();
    super.build_phase();  // ✅ Always call super first
    // Your code here
endfunction
```

### 6.5 Logging Rules

**RULE 6.5.1**: Use EVM logging functions, not `$display`
```systemverilog
// ✅ CORRECT
log_info("Starting test", EVM_MED);
log_warning("Unexpected value");
log_error("Critical failure");

// ❌ WRONG
$display("Starting test");
```

**RULE 6.5.2**: Appropriate verbosity levels:
- `EVM_NONE`: No logging
- `EVM_LOW`: Test start/end, major milestones
- `EVM_MED`: Phase transitions, configurations
- `EVM_HIGH`: Transactions, state changes
- `EVM_DEBUG`: Every detail

**RULE 6.5.3**: In modules, use package prefix for enums:
```systemverilog
// In classes (after import)
log_info("Message", EVM_LOW);  // ✅ OK

// In modules (even after import)
test.log_info("Message", evm_log::EVM_LOW);  // ✅ Required
```

### 6.6 Interface Connection

**RULE 6.6.1**: Use `virtual` keyword for interface handles
```systemverilog
class my_driver extends evm_driver;
    virtual my_if vif;  // ✅ Virtual interface handle
    
    function void set_vif(virtual my_if vif);
        this.vif = vif;
    endfunction
endclass
```

**RULE 6.6.2**: Set VIF before `build_phase()`
```systemverilog
// In test class
function void connect_interfaces(virtual my_if vif);
    my_agent = new("agent", this);
    my_agent.set_vif(vif);  // ✅ Set before build_phase
endfunction
```

### 6.7 Agent Creation

**RULE 6.7.1**: Create agents in `connect_interfaces()`, not in constructor
```systemverilog
// ✅ CORRECT - In base_test
function void connect_interfaces(
    virtual clk_if clk_vif,
    virtual rst_if rst_vif
);
    clk_agent = new("clk_agent", this);
    clk_agent.cfg.freq_mhz = 100.0;
    clk_agent.set_vif(clk_vif);
    
    rst_agent = new("rst_agent", this);
    rst_agent.set_vif(rst_vif);
endfunction

// ❌ WRONG - In constructor
function new(string name = "base_test");
    super.new(name);
    clk_agent = new("clk_agent", this);  // Too early!
endfunction
```

**RULE 6.7.2**: Create generic agents, not specific ones
```systemverilog
// ✅ GOOD - Generic, reusable
evm_clk_agent adc_clk;
evm_clk_agent pcie_clk;
evm_clk_agent sys_clk;

// ❌ BAD - Hardcoded specific agents
evm_adc_clk_agent adc_clk;
evm_pcie_clk_agent pcie_clk;
```

---

## 7. Python Coding Standards

### 7.1 General Python Rules

**RULE 7.1.1**: Follow PEP 8 style guide

**RULE 7.1.2**: Use 4-space indentation

**RULE 7.1.3**: Maximum line length: 100 characters

**RULE 7.1.4**: Use type hints where beneficial
```python
def generate_sine(freq: float, duration: float, fs: float) -> np.ndarray:
    """Generate sine wave."""
    return np.sin(2 * np.pi * freq * np.arange(0, duration, 1/fs))
```

### 7.2 Docstring Format

**RULE 7.2.1**: Use docstrings for all public functions/classes
```python
def analyze_spectrum(data, fs, window='hann'):
    """
    Analyze spectrum of input data using FFT.
    
    Args:
        data (np.ndarray): Input time-domain samples
        fs (float): Sampling frequency in Hz
        window (str): Window function ('hann', 'blackman', etc.)
    
    Returns:
        dict: Analysis results containing:
            - freq: Frequency bins
            - magnitude: Magnitude spectrum
            - snr: Signal-to-noise ratio in dB
            - thd: Total harmonic distortion in %
    
    Example:
        >>> results = analyze_spectrum(data, 48000)
        >>> print(f"SNR: {results['snr']:.2f} dB")
    """
    # Implementation
```

### 7.3 File I/O Format

**RULE 7.3.1**: Use consistent text format for stimulus files
```python
# Generate stimulus file
with open("stimulus.txt", "w") as f:
    f.write("# Time, Channel0, Channel1\n")  # Header
    for i, (ch0, ch1) in enumerate(zip(data0, data1)):
        f.write(f"{i}, {ch0:.6f}, {ch1:.6f}\n")
```

**RULE 7.3.2**: Use consistent format for capture files
```python
# Parse capture file
time = []
data = []
with open("capture.txt", "r") as f:
    for line in f:
        if line.startswith("#"):  # Skip comments
            continue
        t, d = line.strip().split(",")
        time.append(float(t))
        data.append(float(d))
```

### 7.4 Error Handling

**RULE 7.4.1**: Validate inputs
```python
def generate_stimulus(freq, duration, fs, filename):
    """Generate stimulus file."""
    if freq <= 0:
        raise ValueError(f"Frequency must be positive, got {freq}")
    if duration <= 0:
        raise ValueError(f"Duration must be positive, got {duration}")
    if fs <= 0:
        raise ValueError(f"Sample rate must be positive, got {fs}")
    
    # Generate and write
```

**RULE 7.4.2**: Handle file errors gracefully
```python
try:
    with open(filename, "w") as f:
        # Write data
except IOError as e:
    print(f"Error writing file {filename}: {e}")
    return False
return True
```

---

## 8. Documentation Requirements

### 8.1 Code Documentation

**RULE 8.1.1**: Every class must have a description
```systemverilog
//------------------------------------------------------------------------------
// Class: evm_driver
// Description: Base class for all protocol drivers. Converts high-level
//              transactions into pin-level activity on the DUT interface.
//------------------------------------------------------------------------------
virtual class evm_driver extends evm_component;
```

**RULE 8.1.2**: Document non-obvious logic
```systemverilog
// Wait for 3 clock cycles to allow pipeline to flush
// before starting next transaction
repeat(3) @(posedge vif.clk);
```

**RULE 8.1.3**: Document function parameters
```systemverilog
//--------------------------------------------------------------------------
// Function: write
// Description: Write data to specified address
//
// Parameters:
//   addr  - Target address
//   data  - Data value to write
//   delay - Additional delay in clock cycles (default: 0)
//--------------------------------------------------------------------------
virtual task write(int addr, int data, int delay = 0);
```

### 8.2 README Files

**RULE 8.2.1**: Every major directory must have a README.md

**RULE 8.2.2**: README structure:
1. Title and brief description
2. Features/capabilities
3. Usage examples
4. File structure
5. Requirements
6. License reference

### 8.3 Change Documentation

**RULE 8.3.1**: Update NEXT_STEPS.md when adding features

**RULE 8.3.2**: Document breaking changes clearly

**RULE 8.3.3**: Keep examples up-to-date with code changes

---

## 9. Testing and Verification

### 9.1 Test Structure

**RULE 9.1.1**: Standard test template:
```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

class my_test extends evm_base_test;
    
    // Agents
    evm_clk_agent clk_agent;
    evm_rst_agent rst_agent;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    function void connect_interfaces(
        virtual evm_clk_if clk_vif,
        virtual evm_rst_if rst_vif
    );
        clk_agent = new("clk_agent", this);
        clk_agent.cfg.freq_mhz = 100.0;
        clk_agent.set_vif(clk_vif);
        
        rst_agent = new("rst_agent", this);
        rst_agent.set_vif(rst_vif);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        log_info("Build phase complete", EVM_HIGH);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test_activity");
        
        // Test stimulus here
        #100us;
        
        drop_objection("test_activity");
    endtask
    
    virtual function void check_phase();
        super.check_phase();
        // Check results
    endfunction
    
endclass
```

### 9.2 Testbench Structure

**RULE 9.2.1**: Standard tb_top template:
```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

module tb_top;
    
    // Interface instances
    evm_clk_if clk_if();
    evm_rst_if rst_if();
    
    // DUT instance
    my_dut dut(
        .clk(clk_if.clk),
        .rst(rst_if.rst)
    );
    
    // Test execution
    initial begin
        my_test test;
        
        // Create test
        test = new();
        
        // Connect interfaces
        test.connect_interfaces(clk_if, rst_if);
        
        // Run test
        evm_root::get().run_test(test);
        
        $finish;
    end
    
endmodule
```

### 9.3 Test Naming

**RULE 9.3.1**: Descriptive test names:
```systemverilog
// ✅ GOOD
sine_wave_test
axi_burst_test
streaming_capture_test
mixed_transaction_stream_test

// ❌ BAD
test1
my_test
debug_test
```

---

## 10. Phase-Based Development

### 10.1 Phase Execution Order

**RULE 10.1.1**: Standard phase sequence:
1. `build_phase()` - Create components
2. `connect_phase()` - Connect components
3. `end_of_elaboration()` - Final setup
4. `start_of_simulation()` - Pre-run initialization
5. `reset_phase()` - Apply resets
6. `configure_phase()` - Configure DUT
7. `main_phase()` - Test stimulus (with objections)
8. `shutdown_phase()` - Cleanup activities
9. `extract_phase()` - Extract results
10. `check_phase()` - Check results
11. `report_phase()` - Report results
12. `final_phase()` - Final cleanup

### 10.2 Phase Rules

**RULE 10.2.1**: Let `evm_root` manage phases, don't call manually
```systemverilog
// ✅ CORRECT
evm_root::get().run_test(test);  // Runs ALL phases

// ❌ WRONG
test.build_phase();
test.main_phase();
```

**RULE 10.2.2**: Use objections in `main_phase()`
```systemverilog
virtual task main_phase();
    super.main_phase();
    
    raise_objection("test_activity");  // ✅ Prevent phase from ending
    
    // Do test activities
    #100us;
    
    drop_objection("test_activity");  // ✅ Allow phase to end
endtask
```

**RULE 10.2.3**: Always call `super.phase()` first

---

## 11. Common Patterns

### 11.1 Agent Pattern

```systemverilog
class evm_my_agent extends evm_agent#(virtual my_if);
    
    my_cfg cfg;
    my_driver driver;
    my_monitor monitor;
    
    function new(string name, evm_component parent);
        super.new(name, parent);
        cfg = new("cfg");
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        
        if (cfg.is_active) begin
            driver = my_driver::type_id::create("driver", this);
            driver.set_vif(vif);
            driver.cfg = cfg;
        end
        
        monitor = my_monitor::type_id::create("monitor", this);
        monitor.set_vif(vif);
        monitor.cfg = cfg;
    endfunction
    
endclass
```

### 11.2 Configuration Pattern

```systemverilog
class my_cfg extends evm_object;
    
    // Configuration knobs
    bit is_active = 1;
    real freq_mhz = 100.0;
    int data_width = 32;
    
    function new(string name = "my_cfg");
        super.new(name);
    endfunction
    
endclass
```

### 11.3 Streaming Pattern

```systemverilog
// In stream driver
virtual task main_phase();
    super.main_phase();
    
    if (cfg.stimulus_file != "") begin
        load_stimulus(cfg.stimulus_file);
        stream_data();
    end
endtask

local task load_stimulus(string filename);
    int fd;
    string line;
    real time_val, data_val;
    
    fd = $fopen(filename, "r");
    if (fd == 0) begin
        log_error($sformatf("Cannot open file: %s", filename));
        return;
    end
    
    while (!$feof(fd)) begin
        $fgets(line, fd);
        if (line[0] == "#") continue;  // Skip comments
        $sscanf(line, "%f, %f", time_val, data_val);
        // Store data
    end
    
    $fclose(fd);
endtask
```

### 11.4 Sequence Pattern

```systemverilog
class my_sequence extends evm_sequence;
    
    function new(string name = "my_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        my_item item;
        
        repeat(10) begin
            item = new("item");
            item.randomize();
            send_item(item);
        end
    endtask
    
endclass
```

---

## 12. Anti-Patterns to Avoid

### 12.1 Common Mistakes

**ANTI-PATTERN 12.1.1**: Creating agents in constructor
```systemverilog
// ❌ WRONG
function new(string name = "test");
    super.new(name);
    my_agent = new("agent", this);  // VIF not set yet!
endfunction

// ✅ CORRECT
function void connect_interfaces(virtual my_if vif);
    my_agent = new("agent", this);
    my_agent.set_vif(vif);
endfunction
```

**ANTI-PATTERN 12.1.2**: Forgetting `super.method()`
```systemverilog
// ❌ WRONG
virtual function void build_phase();
    my_agent.build();  // Missing super call!
endfunction

// ✅ CORRECT
virtual function void build_phase();
    super.build_phase();  // Always call super first
    my_agent.build();
endfunction
```

**ANTI-PATTERN 12.1.3**: Module enum references without package prefix
```systemverilog
// In module tb_top
// ❌ WRONG
test.log_info("Message", EVM_LOW);

// ✅ CORRECT
test.log_info("Message", evm_log::EVM_LOW);
```

**ANTI-PATTERN 12.1.4**: Using `$display` instead of EVM logging
```systemverilog
// ❌ WRONG
$display("Test starting");

// ✅ CORRECT
log_info("Test starting", EVM_LOW);
```

**ANTI-PATTERN 12.1.5**: No objections in `main_phase()`
```systemverilog
// ❌ WRONG - Test ends immediately
virtual task main_phase();
    super.main_phase();
    #100us;  // Nothing prevents phase from ending before this
endtask

// ✅ CORRECT
virtual task main_phase();
    super.main_phase();
    raise_objection("activity");
    #100us;
    drop_objection("activity");
endtask
```

### 12.2 Design Anti-Patterns

**ANTI-PATTERN 12.2.1**: Hardcoded specific agents instead of generic
```systemverilog
// ❌ BAD - Not reusable
class evm_100mhz_clk_agent extends evm_agent;
class evm_125mhz_pcie_clk_agent extends evm_agent;

// ✅ GOOD - Generic and configurable
class evm_clk_agent extends evm_agent;
    evm_clk_cfg cfg;  // Configure frequency
endclass
```

**ANTI-PATTERN 12.2.2**: Deep inheritance hierarchies
```systemverilog
// ❌ BAD
class base_driver extends evm_driver;
class protocol_driver extends base_driver;
class version1_driver extends protocol_driver;
class custom_driver extends version1_driver;

// ✅ GOOD - Use composition
class my_driver extends evm_driver;
    my_cfg cfg;  // Configure behavior
endclass
```

---

## 13. Tool-Specific Guidelines

### 13.1 CSR Generator

**RULE 13.1.1**: YAML format for register definitions
```yaml
module_name: my_module
base_address: 0x1000

registers:
  - name: CONTROL
    offset: 0x00
    description: Control register
    fields:
      - name: ENABLE
        bits: [0]
        access: RW
        reset: 0
      - name: MODE
        bits: [2:1]
        access: RW
        reset: 0
```

**RULE 13.1.2**: Run CSR generator:
```bash
python evm-sv/csr_gen/gen_csr.py input.yaml output_dir/
```

### 13.2 Python Stimulus Generation

**RULE 13.2.1**: Use `gen_stimulus.py` for waveform generation
```bash
python gen_stimulus.py --type sine --freq 1000 --duration 1.0 --fs 48000 -o stimulus.txt
```

**RULE 13.2.2**: Supported waveform types:
- `sine`: Single frequency
- `multitone`: Multiple frequencies
- `chirp`: Frequency sweep
- `noise`: White/pink noise
- `pulse`: Pulse train

### 13.3 Python Spectrum Analysis

**RULE 13.3.1**: Use `analyze_spectrum.py` for FFT analysis
```bash
python analyze_spectrum.py capture.txt --fs 48000 --plot
```

**RULE 13.3.2**: Analysis outputs:
- SNR (Signal-to-Noise Ratio)
- THD (Total Harmonic Distortion)
- SFDR (Spurious-Free Dynamic Range)
- ENOB (Effective Number of Bits)

---

## 14. Contribution Workflow

### 14.1 Development Process

**RULE 14.1.1**: Standard workflow:
1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes with clear commits
4. Update documentation
5. Test changes locally
6. Submit pull request

### 14.2 Commit Messages

**RULE 14.2.1**: Use clear, descriptive commit messages:
```
✅ GOOD:
"Add file I/O support to streaming driver"
"Fix objection handling in base test"
"Update README with quick-start guide"

❌ BAD:
"fixes"
"update"
"wip"
```

### 14.3 Pull Request Guidelines

**RULE 14.3.1**: PR description should include:
- What: What changes were made
- Why: Why the changes were needed
- How: How to test the changes
- Impact: What areas are affected

**RULE 14.3.2**: Keep PRs focused on single feature/fix

**RULE 14.3.3**: Update documentation in same PR as code changes

---

## 15. Quick Reference

### 15.1 Essential Imports

```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;
```

### 15.2 Class Template

```systemverilog
class my_class extends evm_component;
    
    function new(string name, evm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
    endfunction
    
endclass
```

### 15.3 Test Template

```systemverilog
class my_test extends evm_base_test;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    function void connect_interfaces(/* interface args */);
        // Create and configure agents
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("activity");
        // Test code
        drop_objection("activity");
    endtask
    
endclass
```

### 15.4 Testbench Template

```systemverilog
module tb_top;
    // Interfaces
    // DUT
    
    initial begin
        my_test test = new();
        test.connect_interfaces(/* args */);
        evm_root::get().run_test(test);
        $finish;
    end
endmodule
```

### 15.5 Common Commands

```bash
# CSR Generation
python evm-sv/csr_gen/gen_csr.py regs.yaml output/

# Stimulus Generation
python evm-sv/python/gen_stimulus.py --type sine --freq 1000 -o stim.txt

# Spectrum Analysis
python evm-sv/python/analyze_spectrum.py capture.txt --fs 48000
```

---

## 16. Key Takeaways for AI Assistants

### 16.1 Critical Understanding

**EVM is NOT a full UVM replacement** - it's a lightweight subset with unique features.

**Design Goals:**
- ✅ 80% of UVM's practical utility
- ✅ 20% of UVM's complexity  
- ✅ Unique streaming model + Python integration
- ✅ Learning curve < 1 week (vs weeks for UVM)
- ✅ Code size < 10K LOC (vs 50K for UVM)

### 16.2 When Working with EVM

**ALWAYS Remember:**

1. **Keep it lightweight** - Don't over-engineer like UVM
2. **Prioritize simplicity** - If it's complex, there's a simpler way
3. **Add copyright headers** to all new files
4. **Use two-tier packages** (evm_pkg + evm_vkit_pkg)
5. **Keep constructors minimal** - create objects in `connect_interfaces()`
6. **Always call `super.method()`** first in overrides
7. **Use EVM logging**, not `$display`
8. **Raise/drop objections** in `main_phase()`
9. **Let `evm_root` manage phases** - don't call manually
10. **Choose correct model**: Transaction vs Streaming
11. **Make agents generic** and configurable, not hardcoded
12. **Document WHY**, not just WHAT

### 16.3 UVM Feature Decisions

**✅ IMPLEMENT (Priority 1):**
- Factory pattern - enables reusability
- Config database - enables parameterization
- TLM seq_item_port - standard driver-sequencer interface

**⚠️ CONSIDER (Priority 2):**
- Printing infrastructure - if users request
- Comparison infrastructure - if users request
- Complete hierarchy - if needed for debugging

**❌ NEVER ADD (Keep Lightweight):**
- Full RAL - we have CSR generator
- Virtual sequences - not needed for embedded
- Callbacks - adds complexity
- TLM 2.0 - overkill
- Additional phase domains - 12 phases sufficient
- Field macros - syntactic sugar

### 16.4 Refactoring Guidelines

**When refactoring EVM:**

1. **Check UVM comparison** in `docs/UVM_vs_EVM_ANALYSIS.md`
2. **Identify feature gap** - is it Priority 1, 2, or 3?
3. **If Priority 1** - implement minimal subset
4. **If Priority 2** - wait for user request
5. **If Priority 3** - don't implement
6. **Keep it simple** - less code is better
7. **Test with examples** - ensure backward compatibility
8. **Update docs** - CLAUDE.md, UVM_vs_EVM_ANALYSIS.md

### 16.5 Implementation Template

When adding UVM features to EVM:

```systemverilog
// ✅ GOOD - Minimal, focused implementation
class evm_factory;
    static function evm_object create(string type_name);
        // Simple factory lookup
    endfunction
    
    static function void set_type_override(type base, type derived);
        // Simple override registration
    endfunction
endclass

// ❌ BAD - Over-engineered like UVM
class evm_factory;
    // Complex nested classes
    // Multiple override mechanisms
    // Extensive callback system
    // 500+ lines of code
endclass
```

**Guideline:** If UVM needs 500 lines, EVM should need 100 lines.

### When Adding New Features

1. Check NEXT_STEPS.md for priorities
2. Follow existing patterns in similar components
3. Add copyright header
4. Update documentation
5. Add usage example
6. Test with existing examples

### When Fixing Bugs

1. Understand the root cause
2. Check for similar issues elsewhere
3. Add comments explaining the fix
4. Update NEXT_STEPS.md if needed

### When Reviewing Code

1. Check for copyright headers
2. Verify `super.method()` calls
3. Check logging usage
4. Verify phase objections
5. Check documentation updates

---

## Appendix A: Current Status (March 2026)

### Completed (✅ ~75%)
- ✅ Core framework (evm_pkg) - Base classes functional
- ✅ Transaction model - Sequences, items working
- ✅ Streaming model - File I/O support (EVM unique)
- ✅ Protocol agents - Clock, reset, AXI-Lite, ADC, PCIe
- ✅ CSR generator - YAML to SystemVerilog/C
- ✅ Python tools - Stimulus generation, spectrum analysis
- ✅ Documentation - Architecture, UVM comparison, guides
- ✅ Phase methodology - All 12 phases implemented
- ✅ Simple counter example - Complete working example

### Critical Gaps (❌ ~25%)

**Priority 1: Essential for Reusability**
- ❌ Factory pattern (`evm_factory`) - **10-13 days**
- ❌ Configuration database (`evm_config_db`) - **4-5 days**
- ❌ TLM seq_item_port - **3-4 days**
- **Total:** ~3-4 weeks for production-ready EVM

**Priority 2: Nice to Have**
- ⚠️ Printing infrastructure - 2-3 days
- ⚠️ Comparison infrastructure - 2 days
- ⚠️ Complete hierarchy navigation - 1-2 days
- ⚠️ Packing/unpacking - 2-3 days

**Priority 3: Intentionally Skipped**
- ❌ Full RAL (use CSR generator instead)
- ❌ Virtual sequences (not needed)
- ❌ Callback infrastructure (too complex)
- ❌ TLM 2.0 (overkill for embedded)
- ❌ Additional phase domains (12 phases sufficient)

### Implementation Roadmap

**2026-Q2: Core Infrastructure**
1. Week 1-2: Factory pattern implementation
2. Week 3-4: Configuration database implementation
3. Week 5: TLM ports for driver-sequencer connection
4. Week 6: Testing, examples, documentation

**2026-Q3: Enhanced Features**
1. Printing and comparison infrastructure
2. Additional examples and tutorials
3. Performance optimization
4. Tool integration (Vivado, Questa, VCS)

**2026-Q4: Ecosystem**
1. Additional protocol agents
2. Advanced examples
3. Python workflow automation
4. Community engagement

### Success Metrics

EVM will be successful when:
- ✅ Learning curve < 1 week (vs weeks for UVM)
- ✅ Code size < 10K LOC (vs 50K for UVM)
- ✅ Compilation time < 5 seconds (vs minutes for UVM)
- ✅ Factory enables reusable components
- ✅ Config DB enables parameterized testbenches
- ✅ Streaming model differentiates from UVM
- ✅ Python integration remains simple

See **`docs/UVM_vs_EVM_ANALYSIS.md`** for detailed comparison and **NEXT_STEPS.md** for detailed roadmap.

---

**End of CLAUDE.md**

*This document is a living document and will be updated as the EVM framework evolves.*

**Last Updated:** 2026-03-28  
**Version:** 1.0.0  
**Maintainer:** Differential Audio Inc., EVM Contributors
