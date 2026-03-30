# UVM Features NOT Implemented in EVM

**Last Updated:** 2026-03-30  
**Purpose:** Clear documentation of UVM features intentionally excluded from EVM

---

## 🎯 Philosophy: Simplicity Over Completeness

EVM is **intentionally lightweight** - it provides the essential 20% of UVM features that deliver 80% of the value for embedded verification. This document lists UVM features we deliberately **do NOT implement** and explains why.

---

## ❌ Major UVM Features NOT in EVM

### 1. Factory Pattern
**UVM Has:** `uvm_factory`, `uvm_component_registry`, type/instance overrides  
**EVM Has:** Direct instantiation only  

**Why NOT Implemented:**
- ✅ Direct instantiation is clearer and more explicit
- ✅ No runtime type lookup overhead
- ✅ Better compile-time type checking
- ✅ Easier to debug (no hidden object substitution)
- ✅ Sufficient for embedded verification

**EVM Alternative:**
```systemverilog
// Direct, explicit instantiation
my_driver driver = new("driver", this);
```

---

### 2. Configuration Database (uvm_config_db)
**UVM Has:** Hierarchical configuration with wildcards, resource DB  
**EVM Has:** Direct virtual interface assignment  

**Why NOT Implemented:**
- ✅ Direct VIF passing is simpler and more traceable
- ✅ No runtime lookup failures
- ✅ Explicit data flow is easier to understand
- ✅ No wildcard matching complexity
- ✅ Configuration can be done via constructor parameters

**EVM Alternative:**
```systemverilog
// Direct, explicit VIF assignment
agent.set_vif(vif);
```

---

### 3. Field Automation Macros
**UVM Has:** `` `uvm_field_int``, `` `uvm_field_object``, `` `uvm_field_array``, etc.  
**EVM Has:** Explicit manual methods  

**Why NOT Implemented:**
- ✅ Macros obscure what's actually happening
- ✅ Explicit code is more maintainable
- ✅ Better control over copy/compare/print behavior
- ✅ Easier debugging (no macro expansion mysteries)
- ✅ Smaller code footprint

**EVM Alternative:**
```systemverilog
// Write explicit methods when needed
function void do_copy(evm_object rhs);
    my_txn t;
    super.do_copy(rhs);
    $cast(t, rhs);
    this.addr = t.addr;
    this.data = t.data;
endfunction
```

---

### 4. Register Abstraction Layer (RAL/UVM_REG)
**UVM Has:** Full register model with frontdoor/backdoor access, address maps, memories  
**EVM Has:** CSR Generator (YAML → RTL/C headers)  

**Why NOT Implemented:**
- ✅ CSR generator is simpler for embedded systems
- ✅ Direct read/write tasks are clearer
- ✅ No runtime overhead of register model
- ✅ YAML configuration is more portable
- ✅ Generates both RTL and C headers

**EVM Alternative:**
```yaml
# CSR definition in YAML
registers:
  - name: CONTROL
    offset: 0x00
```
```systemverilog
// Direct register access
write_reg(CONTROL_ADDR, data);
```

---

### 5. Callback Infrastructure
**UVM Has:** `uvm_callbacks`, `uvm_callback`, registration, traversal  
**EVM Has:** Virtual methods and direct function calls  

**Why NOT Implemented:**
- ✅ Virtual methods provide same extensibility
- ✅ No registration/deregistration complexity
- ✅ Direct function calls are faster
- ✅ Clearer code flow
- ✅ Simpler debugging

**EVM Alternative:**
```systemverilog
// Override virtual methods
class my_custom_driver extends my_driver;
    virtual task drive_item(my_txn txn);
        // Custom pre-processing
        super.drive_item(txn);
        // Custom post-processing
    endtask
endclass
```

---

### 6. TLM 2.0
**UVM Has:** TLM 2.0 sockets, generic payload, blocking/non-blocking transport  
**EVM Has:** TLM 1.0 (analysis ports, seq_item ports)  

**Why NOT Implemented:**
- ✅ TLM 1.0 is sufficient for embedded verification
- ✅ TLM 2.0 adds significant complexity
- ✅ Generic payload overhead not needed
- ✅ Simpler ports easier to understand
- ✅ Embedded systems rarely need TLM 2.0 features

**EVM Has:**
- ✅ `analysis_port` / `analysis_imp` (broadcast)
- ✅ `seq_item_pull_port` / `seq_item_pull_export` (driver ↔ sequencer)

---

### 7. Heartbeat Mechanism
**UVM Has:** `uvm_heartbeat`, component monitoring  
**EVM Has:** Quiescence Counter (better alternative!)  

**Why NOT Implemented:**
- ✅ Quiescence Counter is simpler and more flexible
- ✅ QC automatically manages objections
- ✅ Less configuration needed
- ✅ More intuitive for embedded workflows

**EVM Alternative:**
```systemverilog
// Quiescence counter - simpler & automatic
enable_quiescence_counter(200);
```

---

### 8. Report Catcher
**UVM Has:** `uvm_report_catcher`, message interception, filtering  
**EVM Has:** Verbosity levels and direct message control  

**Why NOT Implemented:**
- ✅ Verbosity levels handle most use cases
- ✅ Direct message filtering is simpler
- ✅ Less runtime overhead
- ✅ Easier to understand message flow

---

### 9. Packing/Unpacking Infrastructure
**UVM Has:** `uvm_packer`, bitstream packing, automatic pack/unpack  
**EVM Has:** Manual serialization when needed  

**Why NOT Implemented:**
- ✅ Rarely needed in embedded verification
- ✅ Manual packing is more explicit
- ✅ Better control over bit ordering
- ✅ SystemVerilog streaming operators available when needed

**EVM Alternative:**
```systemverilog
// Use SystemVerilog streaming when needed
bit [127:0] packed = {addr, data, ctrl};
```

---

### 10. Barrier/Event Pools
**UVM Has:** `uvm_barrier`, `uvm_event`, `uvm_event_pool`  
**EVM Has:** SystemVerilog events and semaphores  

**Why NOT Implemented:**
- ✅ Native SystemVerilog constructs sufficient
- ✅ Less abstraction = clearer code
- ✅ Better performance
- ✅ Standard language features

**EVM Alternative:**
```systemverilog
// Use SystemVerilog events directly
event start_test;
-> start_test;
@(start_test);
```

---

### 11. Additional Phase Domains
**UVM Has:** Multiple phase domains (clock, power, etc.)  
**EVM Has:** Single domain with 12 phases  

**Why NOT Implemented:**
- ✅ 12 phases sufficient for embedded systems
- ✅ Multiple domains add significant complexity
- ✅ Synchronization between domains is error-prone
- ✅ Embedded projects rarely need this

---

### 12. Object Pool/Resource Pool
**UVM Has:** `uvm_pool`, `uvm_object_string_pool`  
**EVM Has:** SystemVerilog associative arrays  

**Why NOT Implemented:**
- ✅ Associative arrays simpler and native
- ✅ No abstraction overhead
- ✅ Better performance
- ✅ More familiar to most users

**EVM Alternative:**
```systemverilog
// Use associative arrays directly
bit [31:0] config_table[string];
config_table["timeout"] = 1000;
```

---

### 13. Command Line Processor (Complex)
**UVM Has:** Full `uvm_cmdline_processor` with complex parsing  
**EVM Has:** Simple plusarg processing  

**Why NOT Implemented:**
- ✅ Simple plusargs cover 95% of use cases
- ✅ Less overhead
- ✅ Faster processing
- ✅ Easier to understand

**EVM Has:**
```systemverilog
// Simple, effective plusargs
// +verbosity=HIGH
// +seed=12345
// +evm_log=test.log
```

---

### 14. Objection Timeout
**UVM Has:** Automatic timeout for hanging objections  
**EVM Has:** Manual timeout with `+evm_timeout=`  

**Why NOT Implemented:**
- ✅ Simpler to let users set explicit timeout
- ✅ Plusarg provides flexibility
- ✅ No complex timeout mechanism needed

---

### 15. Multi-language Support (DPI-C Wrapper Classes)
**UVM Has:** Extensive DPI-C support classes  
**EVM Has:** Direct DPI-C when needed  

**Why NOT Implemented:**
- ✅ Direct DPI-C is simpler
- ✅ No wrapper overhead
- ✅ Standard SystemVerilog feature

---

### 16. Sequence Arbitration (Complex)
**UVM Has:** Multiple arbitration schemes (priority, FIFO, weighted, etc.)  
**EVM Has:** Simple FIFO sequencer  

**Why NOT Implemented:**
- ✅ FIFO sufficient for most embedded cases
- ✅ Complex arbitration rarely needed
- ✅ Simpler code and debug
- ✅ Can implement custom arbitration if needed

---

### 17. Root Timeout (Separate from Objection)
**UVM Has:** `uvm_root.set_timeout()`  
**EVM Has:** Combined with plusarg timeout  

**Why NOT Implemented:**
- ✅ Single timeout mechanism is simpler
- ✅ Less configuration needed

---

### 18. Comprehensive Reporting Infrastructure
**UVM Has:** ID, verbosity, file, line, action, severity customization per message  
**EVM Has:** Simple verbosity levels and file logging  

**Why NOT Implemented:**
- ✅ Simple system covers 90% of needs
- ✅ Less configuration overhead
- ✅ Faster runtime
- ✅ Easier to use

---

### 19. Phase Jumping
**UVM Has:** `phase.jump()` to skip/revisit phases  
**EVM Has:** Linear phase execution only  

**Why NOT Implemented:**
- ✅ Phase jumping creates confusing control flow
- ✅ Linear execution easier to understand
- ✅ Rarely needed in practice
- ✅ Simpler implementation

---

### 20. Set/Get Config String/Int Wrappers
**UVM Has:** `uvm_config_db#(string)`, `uvm_config_db#(int)`  
**EVM Has:** Direct parameter passing  

**Why NOT Implemented:**
- ✅ Direct passing is explicit and clear
- ✅ No runtime lookup
- ✅ Compile-time type checking

---

## ✅ What EVM DOES Have

### Core Infrastructure
- ✅ `evm_object` - Base class with hierarchy
- ✅ `evm_component` - Component with phasing
- ✅ `evm_root` - Singleton root with objections
- ✅ 12-phase methodology
- ✅ Objection mechanism

### TLM 1.0
- ✅ `analysis_port` / `analysis_imp`
- ✅ `seq_item_pull_port` / `seq_item_pull_export`
- ✅ Mailbox-based communication

### Components
- ✅ `evm_monitor`
- ✅ `evm_driver`
- ✅ `evm_sequencer`
- ✅ `evm_agent`
- ✅ `evm_scoreboard` (3 comparison modes)

### Sequences
- ✅ `evm_sequence`
- ✅ `evm_sequence_item`
- ✅ `evm_virtual_sequence`

### Reporting
- ✅ `evm_report_handler`
- ✅ File logging
- ✅ Verbosity levels (NONE/LOW/MEDIUM/HIGH/DEBUG)
- ✅ Message counting

### Unique EVM Features
- ✅ **Quiescence Counter** - Automatic test completion
- ✅ **Direct VIF** - No config DB needed
- ✅ **Simple Plusargs** - Command-line control
- ✅ **CSR Generator** - YAML → RTL/C

### Advanced Features
- ✅ `evm_coverage` - Coverage wrapper
- ✅ `evm_assertions` - Assertion infrastructure
- ✅ Command-line plusargs
- ✅ Multi-simulator support

---

## 📊 Feature Comparison Summary

| Feature Category | UVM | EVM | Reason for EVM Choice |
|-----------------|-----|-----|----------------------|
| **Component Creation** | Factory | Direct | Simpler, explicit |
| **Configuration** | Config DB | Direct VIF | Traceable, no lookup |
| **Automation** | Field Macros | Explicit | Clear, maintainable |
| **Registers** | Full RAL | CSR Gen | Lightweight, portable |
| **Extensibility** | Callbacks | Virtual Methods | Native, clear |
| **TLM** | TLM 2.0 | TLM 1.0 | Sufficient, simpler |
| **Monitoring** | Heartbeat | QC | Better, automatic |
| **Messages** | Report Catcher | Verbosity | Adequate, simple |
| **Serialization** | Packer | Manual | Explicit control |
| **Synchronization** | Barrier/Pool | SV Events | Native, familiar |
| **Phases** | Multi-domain | Single | Adequate, simpler |
| **Collections** | Object Pool | Assoc Array | Native, faster |
| **Command Line** | Full Processor | Plusargs | Covers use cases |
| **Test Control** | Quiescence Counter | ❌ (UVM doesn't have) | EVM unique! |

---

## 🎯 The EVM Philosophy

**"Everything you need, nothing you don't"**

We deliberately exclude features that:
1. ❌ Add complexity without proportional value
2. ❌ Obscure what's happening (macros, factories)
3. ❌ Have simpler native alternatives (events, arrays)
4. ❌ Are rarely needed in embedded verification
5. ❌ Slow down compilation or simulation

We include features that:
1. ✅ Are essential for verification
2. ✅ Provide clear value
3. ✅ Are simple to understand and use
4. ✅ Have no good SystemVerilog alternative
5. ✅ Are commonly needed in embedded systems

---

## 💡 When to Use UVM vs EVM

### Choose UVM if you need:
- Large team (10+ engineers) with established UVM infrastructure
- Enterprise-level features (factories, complex config)
- ASIC-scale verification
- Compliance with established UVM coding standards
- Very complex register models

### Choose EVM if you need:
- Small to medium team (1-5 engineers)
- Fast learning curve and onboarding
- Simple, understandable codebase
- Fast compilation and simulation
- Embedded/FPGA verification
- Python integration for DSP/RF

---

## 📚 References

- **UVM 1.2 Class Reference:** Full list of UVM features
- **CLAUDE.md:** EVM development guide
- **NEXT_STEPS.md:** Optional future enhancements
- **README.md:** Project overview and philosophy

---

**Remember:** EVM's power comes from what we DON'T include, not just what we do. Every excluded feature is a conscious choice for simplicity, clarity, and maintainability.

**Version:** 1.0.0  
**Last Updated:** 2026-03-30
