# EVM Register Model (Lightweight RAL)

**A lightweight register abstraction layer similar to UVM RAL**

---

## Overview

The EVM Register Model provides a lightweight abstraction for register access, similar to UVM's Register Abstraction Layer (RAL) but designed to be simpler and easier to use. It supports field-level access, automatic mirroring, and generates `evm_csr_item` transactions for register operations.

### Key Features

- ✅ **Field-level access** with configurable access policies (RW, RO, WO, W1C, etc.)
- ✅ **Automatic mirroring** of register values
- ✅ **Reset functionality** with configurable reset values
- ✅ **Transaction generation** via `evm_csr_item`
- ✅ **Agent integration** for automatic execution
- ✅ **Lightweight** - minimal overhead compared to UVM RAL
- ✅ **Type-safe** field access

---

## Architecture

The register model consists of three main classes:

```
evm_reg_block          (Register Block)
    ├── evm_reg        (Individual Register)
    │   └── evm_reg_field   (Register Field)
    └── evm_component  (Associated Agent)
```

### Class Hierarchy

1. **`evm_reg_field`** - Represents a field within a register
   - Configurable width, position, and access policy
   - Tracks reset and current values
   - Handles read/write side effects

2. **`evm_reg`** - Represents a complete register
   - Contains multiple fields
   - Generates `evm_csr_item` transactions
   - Provides read/write/mirror methods

3. **`evm_reg_block`** - Contains multiple registers
   - Manages a collection of registers
   - Provides block-level operations
   - Associates an agent for transaction execution

---

## Field Access Types

The register model supports common hardware access policies:

| Type | Description | Read Effect | Write Effect |
|------|-------------|-------------|--------------|
| `EVM_REG_RW` | Read-Write | Returns value | Updates value |
| `EVM_REG_RO` | Read-Only | Returns value | Ignored |
| `EVM_REG_WO` | Write-Only | Returns 0 | Updates value |
| `EVM_REG_RC` | Read-Clears | Clears field | No effect |
| `EVM_REG_RS` | Read-Sets | Sets field | No effect |
| `EVM_REG_WC` | Write-Clears | No effect | Clears field |
| `EVM_REG_WS` | Write-Sets | No effect | Sets field |
| `EVM_REG_W1C` | Write-1-to-Clear | Returns value | Clears bits where 1 is written |
| `EVM_REG_W1S` | Write-1-to-Set | Returns value | Sets bits where 1 is written |

---

## Basic Usage Example

### 1. Create Register Model

```systemverilog
class my_reg_model extends evm_object;
    evm_reg_block   ctrl_block;
    evm_reg         ctrl_reg;
    evm_reg         status_reg;
    
    function new(string name = "my_reg_model");
        super.new(name);
        
        // Create register block
        ctrl_block = new("ctrl_block", 32'h1000);
        
        // Create control register
        ctrl_reg = new("CTRL", 32'h1000, 32);
        build_ctrl_reg();
        ctrl_block.add_reg(ctrl_reg);
        
        // Create status register
        status_reg = new("STATUS", 32'h1004, 32);
        build_status_reg();
        ctrl_block.add_reg(status_reg);
    endfunction
    
    function void build_ctrl_reg();
        evm_reg_field enable_field;
        evm_reg_field mode_field;
        
        // ENABLE field [0] - RW, reset=0
        enable_field = new("ENABLE", 0, 1, EVM_REG_RW, 0);
        ctrl_reg.add_field(enable_field);
        
        // MODE field [2:1] - RW, reset=0
        mode_field = new("MODE", 1, 2, EVM_REG_RW, 0);
        ctrl_reg.add_field(mode_field);
    endfunction
    
    function void build_status_reg();
        evm_reg_field ready_field;
        evm_reg_field error_field;
        
        // READY field [0] - RO
        ready_field = new("READY", 0, 1, EVM_REG_RO, 0);
        status_reg.add_field(ready_field);
        
        // ERROR field [1] - W1C (write 1 to clear)
        error_field = new("ERROR", 1, 1, EVM_REG_W1C, 0);
        status_reg.add_field(error_field);
    endfunction
    
    // Connect to agent that will execute transactions
    function void set_agent(evm_component agent);
        ctrl_block.set_agent(agent);
    endfunction
endclass
```

### 2. Use in Test

```systemverilog
class my_test extends evm_base_test;
    my_reg_model    reg_model;
    my_axi_agent    axi_agent;
    
    function void build_phase();
        super.build_phase();
        
        // Create register model
        reg_model = new("reg_model");
        
        // Create AXI agent
        axi_agent = new("axi_agent", this);
        
        // Connect register model to agent
        reg_model.set_agent(axi_agent);
    endfunction
    
    virtual task main_phase();
        bit status;
        bit [63:0] value;
        
        super.main_phase();
        raise_objection("test");
        
        // Reset register model
        reg_model.ctrl_block.reset("HARD");
        
        // Write to control register
        reg_model.ctrl_reg.write(32'h0000_0003, status);  // ENABLE=1, MODE=1
        
        // Read status register
        reg_model.status_reg.read(value, status);
        
        // Check status register value
        reg_model.status_reg.read_check(32'h0000_0001, 32'hFFFF_FFFF, status);
        
        // Access individual fields
        evm_reg_field enable_field = reg_model.ctrl_reg.get_field_by_name("ENABLE");
        enable_field.set(1);
        
        // Write register using current field values
        reg_model.ctrl_reg.write(reg_model.ctrl_reg.get(), status);
        
        // Dump all registers
        reg_model.ctrl_block.dump();
        
        drop_objection("test");
    endtask
endclass
```

---

## Advanced Features

### Field-Level Access

```systemverilog
// Get field by name
evm_reg_field enable = ctrl_reg.get_field_by_name("ENABLE");

// Read field value (from mirror)
bit [63:0] val = enable.get();

// Set field value (mirror only)
enable.set(1);

// Write entire register with updated field values
ctrl_reg.write(ctrl_reg.get(), status);
```

### Block-Level Operations

```systemverilog
// Write all registers in block
reg_model.ctrl_block.write_all(status);

// Read all registers in block
reg_model.ctrl_block.read_all(status);

// Mirror check - read and compare all registers
reg_model.ctrl_block.mirror(status);

// Reset all registers
reg_model.ctrl_block.reset("HARD");

// Access registers by name
reg_model.ctrl_block.write_reg("CTRL", 32'h0003, status);
reg_model.ctrl_block.read_reg("STATUS", value, status);
```

### Custom Register Class

For complex register access patterns, extend `evm_reg`:

```systemverilog
class my_special_reg extends evm_reg;
    
    // Override execute_item to handle custom agent interface
    protected virtual task execute_item(evm_csr_item item, output bit status);
        // Custom implementation for your agent
        my_axi_agent agent;
        
        $cast(agent, target_agent);
        
        if (item.is_write()) begin
            agent.write(item.addr, item.data, status);
        end else begin
            agent.read(item.addr, item.data, status);
        end
    endtask
    
    // Add custom methods
    task set_mode(int mode, output bit status);
        evm_reg_field mode_field = get_field_by_name("MODE");
        mode_field.set(mode);
        write(get(), status);
    endtask
endclass
```

---

## Integration with Agents

### Method 1: Override execute_item

```systemverilog
class my_reg extends evm_reg;
    protected virtual task execute_item(evm_csr_item item, output bit status);
        my_agent agent;
        $cast(agent, target_agent);
        
        if (item.is_write()) begin
            agent.write_task(item.addr, item.data);
        end else begin
            agent.read_task(item.addr, item.data);
        end
        status = 1;
    endtask
endclass
```

### Method 2: Agent with CSR Execution Method

If your agent has a method to execute CSR items directly:

```systemverilog
class my_agent extends evm_agent;
    task execute_csr(evm_csr_item item);
        // Execute the CSR transaction
        driver.execute_item(item);
    endtask
endclass

// In your register class:
protected virtual task execute_item(evm_csr_item item, output bit status);
    my_agent agent;
    $cast(agent, target_agent);
    agent.execute_csr(item);
    status = 1;
endtask
```

---

## Best Practices

### 1. Create Register Model in Build Phase

```systemverilog
function void build_phase();
    reg_model = new("reg_model");
    reg_model.set_agent(csr_agent);
    reg_model.ctrl_block.reset("HARD");
endfunction
```

### 2. Use Descriptive Names

```systemverilog
// Good
enable_field = new("ENABLE", 0, 1, EVM_REG_RW, 0);

// Better - matches hardware spec
enable_field = new("CTRL_ENABLE", 0, 1, EVM_REG_RW, 1'b0);
```

### 3. Match Hardware Reset Values

```systemverilog
// Set reset value to match hardware
mode_field = new("MODE", 1, 2, EVM_REG_RW, 2'b01);
```

### 4. Use Field Access for Clarity

```systemverilog
// Less clear
ctrl_reg.write(32'h0000_0007, status);

// More clear
enable_field.set(1);
mode_field.set(2);
start_field.set(1);
ctrl_reg.write(ctrl_reg.get(), status);
```

### 5. Check Status Returns

```systemverilog
bit status;
reg_model.ctrl_reg.write(32'h0003, status);
if (!status) begin
    log_error("Register write failed!");
end
```

---

## Comparison with UVM RAL

| Feature | EVM Register Model | UVM RAL |
|---------|-------------------|---------|
| **Complexity** | Simple, ~600 lines | Complex, 10,000+ lines |
| **Learning Curve** | Low | High |
| **Field Access** | ✅ Full support | ✅ Full support |
| **Mirroring** | ✅ Built-in | ✅ Built-in |
| **Callbacks** | ❌ Not supported | ✅ Full support |
| **Coverage** | ❌ Not built-in | ✅ Built-in |
| **Backdoor Access** | ❌ Not supported | ✅ Supported |
| **Memory Maps** | ❌ Single map | ✅ Multiple maps |
| **Auto-prediction** | ✅ Built-in | ✅ Built-in |
| **Setup Time** | Minutes | Hours |

---

## Limitations

The EVM register model is intentionally lightweight. It does not support:

- Callbacks/hooks for pre/post access
- Built-in coverage collection
- Backdoor (hierarchical) access
- Multiple address maps
- Memory modeling (only registers)
- HDL path tracking

For these advanced features, use UVM RAL or implement custom extensions.

---

## Example: Complete Register Model

See `evm/vkit/docs/examples/register_model_example.sv` for a complete working example.

---

## Troubleshooting

### Register Writes Not Happening

**Problem:** Calling `write()` but no transaction occurs.

**Solution:** Ensure agent is configured:
```systemverilog
reg_model.set_agent(my_agent);
```

### Mirror Mismatches

**Problem:** Mirror shows different value than hardware.

**Solution:** Call `mirror()` to sync:
```systemverilog
reg_model.ctrl_block.mirror(status);
```

### Field Not Found

**Problem:** `get_field_by_name()` returns null.

**Solution:** Check field name spelling and ensure field was added:
```systemverilog
evm_reg_field field = ctrl_reg.get_field_by_name("ENABLE");
if (field == null) begin
    $error("Field not found!");
end
```

---

## Future Enhancements

Planned features for future releases:

- [ ] Pre/post access callbacks
- [ ] Built-in coverage collection
- [ ] Backdoor access support
- [ ] Memory modeling
- [ ] Auto-generation from IP-XACT/SystemRDL
- [ ] Python-based register model generation

---

*Last Updated: 2026-03-07*
