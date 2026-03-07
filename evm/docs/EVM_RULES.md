# EVM Framework - Design Rules and Guidelines

**Version:** 1.0  
**Date:** 2026-03-06  
**Status:** Active

---

## 📋 Table of Contents
0. [Copyright and Licensing](#copyright-and-licensing)
1. [Package Structure](#package-structure)
2. [Class Hierarchy](#class-hierarchy)
3. [Logging Rules](#logging-rules)
4. [Agent Creation](#agent-creation)
5. [Interface Connection](#interface-connection)
6. [Phase Methodology](#phase-methodology)
7. [Constructor Rules](#constructor-rules)
8. [Configuration Objects](#configuration-objects)
9. [Common Mistakes](#common-mistakes)

---

## ©️ Copyright and Licensing

### Rule 0.1: All EVM Files Must Include Copyright Header

**Every EVM source file** (.sv, .py, .tcl, .md) must include the standard copyright header:

```systemverilog
//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// Description: Brief description of file purpose
// Author: Differential Audio Inc., EVM Contributors
// Date: YYYY-MM-DD
//==============================================================================
```

For Python files:
```python
#!/usr/bin/env python3
"""
EVM - Embedded Verification Methodology
Copyright (c) 2026 Differential Audio Inc.
Licensed under MIT License - see LICENSE file for full terms

Description: Brief description of file purpose
Author: Author name or "EVM Contributors"
Date: YYYY-MM-DD
"""
```

For TCL files:
```tcl
#===============================================================================
# EVM - Embedded Verification Methodology
# Copyright (c) 2026 Differential Audio Inc.
# Licensed under MIT License - see LICENSE file for full terms
#===============================================================================
# Description: Brief description of file purpose
# Author: Author name or "EVM Contributors"
# Date: YYYY-MM-DD
#===============================================================================
```

### Rule 0.2: Reference to Full License

**All files must reference the LICENSE file** for complete legal terms. This keeps headers concise while ensuring proper attribution and legal protection.

### Rule 0.3: No Warranty Disclaimer

The MIT License provides NO WARRANTY. Users understand:
- Code is provided "AS IS"
- No liability for failures or damages
- Use at your own risk
- Similar to Linux kernel approach

### Rule 0.4: Attribution Requirements

- Copyright notice must remain intact
- Differential Audio Inc. must be credited as creator
- Contributors may add their names to CONTRIBUTORS.md
- Modifications should note contributor name

### Rule 0.5: Example Full Header

```systemverilog
//==============================================================================
// EVM - Embedded Verification Methodology
// Copyright (c) 2026 Differential Audio Inc.
// Licensed under MIT License - see LICENSE file for full terms
//==============================================================================
// File: evm_sequence_item.sv
// Description: Generic base class for all transaction items
//              Provides timing and status tracking
// Author: Differential Audio Inc., EVM Contributors
// Date: 2026-03-06
//==============================================================================

virtual class evm_sequence_item extends evm_object;
    // Implementation...
endclass
```

---

## 📦 Package Structure

### Rule 1.1: Use Two-Tier Package Architecture
```systemverilog
// Tier 1: EVM Framework (evm_pkg.sv)
package evm_pkg;
    `include "evm_log.sv"
    `include "evm_object.sv"
    `include "evm_component.sv"
    // ... etc
endpackage

// Tier 2: VKit Agents (evm_vkit_pkg.sv)
package evm_vkit_pkg;
    import evm_pkg::*;
    
    `include "evm_clk_agent/evm_clk_if.sv"
    `include "evm_clk_agent/evm_clk_cfg.sv"
    // ... etc
endpackage
```

### Rule 1.2: Import Both Packages in Tests
```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

class my_test extends evm_base_test;
    // ...
endclass
```

### Rule 1.3: Module Enum References Require Package Prefix
```systemverilog
// In classes (after import)
log_info("Message", EVM_LOW);  // ✅ OK

// In modules (even after import)
test.log_info("Message", evm_log::EVM_LOW);  // ✅ Required
```

---

## 🏗️ Class Hierarchy

### Rule 2.1: All EVM Classes Extend from evm_object
```
evm_object
  ├─ evm_component
  │   ├─ evm_agent
  │   ├─ evm_driver
  │   ├─ evm_monitor
  │   └─ evm_base_test
  └─ evm_cfg (configuration classes)
```

### Rule 2.2: Components Have Parent Reference
```systemverilog
class my_agent extends evm_agent#(virtual my_if);
    function new(string name, evm_component parent);
        super.new(name, parent);  // ✅ Always pass parent
    endfunction
endclass
```

---

## 📝 Logging Rules

### Rule 3.1: Use EVM Logging Functions
```systemverilog
// ✅ CORRECT
log_info("Starting test", EVM_MED);
log_warning("Unexpected value");
log_error("Critical failure");

// ❌ WRONG
$display("Starting test");  // Don't use in EVM classes
```

### Rule 3.2: Logging Verbosity Levels
```systemverilog
EVM_NONE  // No logging
EVM_LOW   // Minimal (test start/end, major events)
EVM_MED   // Medium (phase transitions, configurations)
EVM_HIGH  // Detailed (transactions, state changes)
EVM_DEBUG // Debug (every detail)
```

### Rule 3.3: No Method-Style Logging Calls
```systemverilog
// ❌ WRONG - log is not an object
log.info("Message");

// ✅ CORRECT - log_info is a function
log_info("Message", EVM_MED);
```

---

## 🤖 Agent Creation

### Rule 4.1: Create Agents in connect_interfaces()
```systemverilog
// ✅ CORRECT - In base_test
function void connect_interfaces(
    virtual my_if my_vif,
    // ... other interfaces
);
    // Create agent
    my_agent = new("my_agent", this);
    
    // Configure it
    my_agent.cfg.param = value;
    
    // Set interface
    my_agent.set_vif(my_vif);
endfunction
```

### Rule 4.2: Don't Create Agents in Constructor
```systemverilog
// ❌ WRONG
function new(string name = "base_test");
    super.new(name);
    my_agent = new("my_agent", this);  // Too early!
endfunction

// ✅ CORRECT - Keep constructor minimal
function new(string name = "base_test");
    super.new(name);
    // That's it!
endfunction
```

### Rule 4.3: Generic Agents for Reusability
```systemverilog
// ✅ GOOD - Generic clock agent
evm_clk_agent adc_clk;    // 100 MHz
evm_clk_agent pcie_clk;   // 125 MHz
evm_clk_agent sys_clk;    // 100 MHz

// ❌ BAD - Hardcoded specific clocks
evm_adc_clk_agent adc_clk;
evm_pcie_clk_agent pcie_clk;
```

---

## 🔌 Interface Connection

### Rule 5.1: set_vif() Before build_phase()
```systemverilog
// In tb_top
test = new();
test.connect_interfaces(clk_if, rst_if, ...);  // Creates agents + sets vifs
evm_root::get().run_test(test);  // Runs build_phase internally
```

### Rule 5.2: Never Access Agent Before Creation
```systemverilog
// ❌ WRONG - agent is null!
test.my_agent.set_vif(my_if);

// ✅ CORRECT - create first, then access
test.connect_interfaces(my_if);  // Creates agent inside
```

---

## ⏱️ Phase Methodology

### Rule 6.1: Phase Execution Order
```
build_phase()           // Create components
connect_phase()         // Connect components
end_of_elaboration()    // Final setup
start_of_simulation()   // Pre-run initialization
reset_phase()           // Apply resets
configure_phase()       // Configure DUT
main_phase()            // Test stimulus (with objections)
shutdown_phase()        // Cleanup activities
extract_phase()         // Extract results
check_phase()           // Check results
report_phase()          // Report results
final_phase()           // Final cleanup
```

### Rule 6.2: Use Objections in main_phase
```systemverilog
virtual task main_phase();
    super.main_phase();
    
    raise_objection("test_activity");  // Prevent phase from ending
    
    // Test stimulus here
    #100us;
    
    drop_objection("test_activity");  // Allow phase to end
endtask
```

### Rule 6.3: Let evm_root Manage Phases
```systemverilog
// ✅ CORRECT
evm_root::get().run_test(test);  // Runs ALL phases automatically

// ❌ WRONG - Don't call phases manually
test.build_phase();
test.main_phase();
```

---

## 🔧 Constructor Rules

### Rule 7.1: Keep Constructors Minimal
```systemverilog
// ✅ CORRECT
function new(string name = "my_class");
    super.new(name);
    // Only initialization, no object creation
endfunction

// ❌ WRONG
function new(string name = "my_class");
    super.new(name);
    my_agent = new();  // Don't create objects here
    configure();       // Don't configure here
endfunction
```

### Rule 7.2: No new() in Ternary Operators
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

---

## ⚙️ Configuration Objects

### Rule 8.1: Config Classes Extend evm_object
```systemverilog
class my_cfg extends evm_object;
    real freq_mhz = 100.0;
    bit  enabled = 1;
    
    function new(string name = "my_cfg");
        super.new(name);
    endfunction
endclass
```

### Rule 8.2: Pass Config to Driver/Monitor
```systemverilog
class my_agent extends evm_agent#(virtual my_if);
    my_cfg cfg;
    
    virtual function evm_driver create_driver(string name);
        my_driver drv = new(name, this, cfg);  // Pass cfg
        return drv;
    endfunction
endclass
```

### Rule 8.3: Configure Before build_phase
```systemverilog
// ✅ CORRECT
my_agent = new("my_agent", this);
my_agent.cfg.freq = 100.0;  // Configure before build
my_agent.set_vif(my_if);
```

---

## ⚠️ Common Mistakes

### Mistake 1: Task Parameter Defaults
```systemverilog
// ❌ WRONG - Not supported
virtual task my_task(int param = 10);

// ✅ CORRECT - No defaults in tasks
virtual task my_task(int param);
```

### Mistake 2: Calling Phases Manually
```systemverilog
// ❌ WRONG
test.build_phase();
test.main_phase();

// ✅ CORRECT
evm_root::get().run_test(test);
```

### Mistake 3: Creating Agents in build_phase Without VIF
```systemverilog
// ❌ WRONG
virtual function void build_phase();
    my_agent = new("agent", this);  // VIF not set yet!
endfunction

// ✅ CORRECT
function void connect_interfaces(virtual my_if vif);
    my_agent = new("agent", this);
    my_agent.set_vif(vif);  // Set VIF immediately
endfunction
```

### Mistake 4: Forgetting super.method()
```systemverilog
// ❌ WRONG
virtual function void build_phase();
    // Missing super.build_phase()!
    my_agent = new();
endfunction

// ✅ CORRECT
virtual function void build_phase();
    super.build_phase();  // Always call super first
    my_agent = new();
endfunction
```

### Mistake 5: Module Context Enum References
```systemverilog
// In module tb_top
// ❌ WRONG
test.log_info("Message", EVM_LOW);

// ✅ CORRECT
test.log_info("Message", evm_log::EVM_LOW);
```

---

## 📚 Quick Reference Template

### Minimal Test Template
```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

class my_test extends evm_base_test;
    // Agents
    my_agent agent_h;
    
    function new(string name = "my_test");
        super.new(name);
    endfunction
    
    function void connect_interfaces(virtual my_if vif);
        agent_h = new("agent", this);
        agent_h.cfg.param = value;
        agent_h.set_vif(vif);
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        log_info("Build phase complete", EVM_HIGH);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test_activity");
        
        // Test stimulus
        #100us;
        
        drop_objection("test_activity");
    endtask
endclass
```

### Minimal tb_top Template
```systemverilog
import evm_pkg::*;
import evm_vkit_pkg::*;

module tb_top;
    my_if my_if_inst();
    my_test test;
    
    initial begin
        test = new();
        test.connect_interfaces(my_if_inst);
        evm_root::get().run_test(test);
        $finish;
    end
endmodule
```

---

## 🎯 Key Takeaways

1. **Two packages**: `evm_pkg` and `evm_vkit_pkg`
2. **Connect interfaces before run_test()**: Create agents and set VIFs in `connect_interfaces()`
3. **Minimal constructors**: Only call `super.new()`
4. **Use EVM logging**: `log_info()`, not `$display()`
5. **Objections in main_phase**: Control when test ends
6. **Let evm_root manage phases**: Don't call phases manually
7. **Config objects extend evm_object**: Pass to driver/monitor
8. **Module enum references**: Use `evm_log::EVM_LOW` in modules

---

**Remember**: When in doubt, follow the patterns in the framework. Consistency is key to maintainability!
