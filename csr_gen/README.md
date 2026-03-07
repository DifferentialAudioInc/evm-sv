# CSR Generator Tool

Part of the EVM (Embedded Verification Module) package.

## Overview

The CSR (Control/Status Register) Generator is a Python tool that generates:
- **SystemVerilog RTL** - Synthesizable register modules with packages
- **C Header Files** - Hardware register definitions for firmware
- **Documentation** - Complete register map in Markdown format
- **Path Definitions** - Include paths for build systems

## Features

- Single YAML source file defines all registers
- Generates type-safe structures for both RTL and C
- Module-specific subdirectories for clean organization
- Automatic documentation generation
- Path definition files for easy integration

## Usage

```bash
python gen_csr.py <yaml_file> <output_directory>
```

### Arguments

- **yaml_file** - Path to your YAML CSR definition file
- **output_directory** - Directory where generated files will be created

### Example

```bash
python evm/csr_gen/gen_csr.py my_project/registers.yaml my_project/csr_gen
```

## YAML Format

See `example/example_csr_definitions.yaml` for a complete example.

### Basic Structure

```yaml
modules:
  - name: MODULE_NAME
    base_address: 0x00000000
    description: Module description
    registers:
      - name: REGISTER_NAME
        offset: 0x0000
        access: RW  # RW, RO, or WO
        reset: 0x00000000
        description: Register description
        fields:
          - name: FIELD_NAME
            bits: [31, 24]  # or single bit: [0]
            description: Field description
```

### Register Access Types

- **RW** - Read/Write
- **RO** - Read Only
- **WO** - Write Only

## Generated Files

### Root Level

- **dsp_regs.h** - Master C header including all modules
- **csr_paths.svh** - SystemVerilog path definitions
- **csr_paths.h** - C path definitions
- **csr_files.f** - Filelist for simulation tools (VCS, Xcelium)
- **csr_files.tcl** - TCL script for synthesis tools (Vivado, Quartus)
- **register_map.md** - Complete documentation

### Per-Module Subdirectories

For each module defined in your YAML file:

```
<module_name>/
├── <module>_csr_pkg.sv    # SystemVerilog package
├── <module>_csr.sv        # SystemVerilog module
└── <module>_csr.h         # C header
```

## Integration

### SystemVerilog

```systemverilog
// Include path definitions
`include "csr_paths.svh"

// Import packages
import system_csr_pkg::*;

// Instantiate CSR module
system_csr u_system_csr (
    .clk(clk),
    .rst_n(rst_n),
    // ... ports
);
```

### C/C++

```c
// Include master header
#include "dsp_regs.h"

// Access registers
SYSTEM_REGS->control.fields.enable = 1;
uint32_t version = SYSTEM_REGS->version.raw;
```

## Requirements

- Python 3.6+
- PyYAML library

Install dependencies:
```bash
pip install pyyaml
```

## Using File Lists

The generator creates two types of file lists for easy integration:

### csr_files.f - For Simulation Tools

Use with VCS, Xcelium, or other simulators that support file lists:

```bash
# VCS
vcs -f csr_gen/csr_files.f

# Xcelium
xrun -f csr_gen/csr_files.f

# In your own filelist
-f csr_gen/csr_files.f
```

### csr_files.tcl - For Synthesis Tools

Use with Vivado, Quartus, or other tools that support TCL:

```tcl
# In Vivado TCL console or script
source csr_gen/csr_files.tcl

# In Quartus
source csr_gen/csr_files.tcl
```

The TCL script automatically determines its directory and loads all CSR files with proper relative paths.

## Git Workflow

The output directory includes a `.gitignore` file that excludes all generated files. This is intentional:

**What's committed to git:**
- `csr_definitions.yaml` - Your register definitions (source of truth)
- `README.md` - Documentation
- `.gitignore` - Ensures generated files aren't committed

**What's NOT committed (auto-generated):**
- All `.sv` and `.svh` files
- All `.h` files  
- `csr_files.f` and `csr_files.tcl`
- `register_map.md`
- Module subdirectories

**Workflow:**
1. Edit `csr_definitions.yaml` in your project
2. Commit the YAML file to git
3. Run the generator to create output files
4. Generated files are ignored by git (not committed)
5. CI/CD or developers run generator to recreate files as needed

This approach keeps your repository clean while ensuring everyone can regenerate the exact same files from the YAML source.

## Example

See the `example/` directory for a complete working example with documentation.

## License

Part of the EVM verification framework.
