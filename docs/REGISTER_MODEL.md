# EVM Register Model (RAL)

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Overview

EVM's register model (RAL — Register Abstraction Layer) provides a lightweight, type-safe way to access control/status registers in your DUT. It integrates with the CSR generator to auto-produce both RTL and verification models from a single YAML source.

**Stack:**
```
YAML (source of truth)
  ↓ gen_csr.py
evm_reg_block (per module)
  → organized in evm_reg_map (multiple blocks per bus)
  → access via evm_axi_lite_master_agent  
  → mirror auto-updated by evm_reg_predictor
```

---

## Class Overview

### `evm_reg_field` — Individual bit field

```systemverilog
class evm_reg_field extends evm_object;
    string name;
    int    lsb_pos;        // LSB position within register
    int    size;           // Width in bits
    // Access types: RW, RO, WO, RC, RS, WC, WS, W1C, W1S
    evm_reg_access_e access;
    bit [63:0] reset_value;
    bit [63:0] mirrored_value;
    
    function bit [63:0] get();          // Get current mirrored value
    function void set(bit [63:0] val);  // Set mirrored value
    function void reset(string kind);   // Restore reset value
    function void predict(bit [63:0] value, bit is_read);
endclass
```

**Access types:**
| Type | Description |
|---|---|
| `RW` | Normal read/write |
| `RO` | Read only (writes ignored) |
| `WO` | Write only (reads return 0) |
| `RC` | Read to clear |
| `RS` | Read to set |
| `WC` | Write to clear |
| `WS` | Write to set |
| `W1C` | Write 1 to clear bits |
| `W1S` | Write 1 to set bits |

---

### `evm_reg` — Single register

```systemverilog
class evm_reg extends evm_object;
    bit [63:0] address;
    int        n_bits;     // Width: 8, 16, 32, or 64
    evm_reg_field fields[$];
    evm_component target_agent;  // Agent that executes bus transactions
    
    // Field access
    function evm_reg_field get_field_by_name(string name);
    
    // Value assembly/disassembly (all fields combined)
    function bit [63:0] get();          // Assemble all fields → 64-bit value
    function void set(bit [63:0] val);  // Distribute value across fields
    
    // Bus operations (require target_agent to be set)
    task write(bit [63:0] value, output bit status);
    task read(output bit [63:0] value, output bit status);
    task read_check(bit [63:0] expected, bit [63:0] mask, output bit status);
    task mirror(output bit status);     // Read + compare with model
    
    // Mirror (no bus access)
    function void predict(bit [63:0] value, bit is_read);
    function void reset(string kind = "HARD");
endclass
```

---

### `evm_reg_block` — Collection of registers at a base address

```systemverilog
class evm_reg_block extends evm_object;
    bit [63:0] base_address;
    evm_reg    registers[$];
    evm_component default_agent;
    
    function void add_reg(evm_reg reg);
    function evm_reg get_reg_by_name(string name);
    function evm_reg get_reg_by_address(bit [63:0] addr);  // relative address
    
    function void set_agent(evm_component agent);  // Propagates to all regs
    function void reset(string kind = "HARD");
    
    task write_reg(string name, bit [63:0] value, output bit status);
    task read_reg(string name, output bit [63:0] value, output bit status);
    task mirror(output bit status);     // Mirror entire block
    
    function void dump();  // Print all register values
endclass
```

---

### `evm_reg_map` — Address map for multiple register blocks

Maps multiple `evm_reg_block` instances to bus address offsets. Provides unified register lookup by absolute bus address (used by the predictor).

```systemverilog
class evm_reg_map extends evm_object;
    // Add a block at a given bus offset
    function void add_reg_block(string name, evm_reg_block blk, 
                                bit [63:0] offset = 0);
    
    // Lookup by absolute bus address (map.base + block.offset + reg.offset)
    function evm_reg get_reg_by_address(bit [63:0] abs_addr);
    
    // Lookup by register name (searches all blocks)
    function evm_reg get_reg_by_name(string reg_name);
    
    // Get a specific block by name
    function evm_reg_block get_block(string name);
    
    // Propagate agent to all blocks
    function void set_agent(evm_component agent);
    
    // Reset all blocks (called by predictor on DUT reset)
    function void reset(string kind = "HARD");
    
    function void dump();
endclass
```

**Address calculation:**
```
Absolute bus address = map.base_addr + block.offset + block.base_address + reg.offset
```

---

### `evm_reg_predictor` — Auto-update mirror from observed transactions

Abstract parameterized class. Subscribes to a monitor's analysis port and automatically updates the register mirror whenever a bus transaction is observed.

```systemverilog
virtual class evm_reg_predictor #(type TXN = evm_sequence_item) 
    extends evm_component;

    evm_analysis_imp#(TXN) analysis_imp;  // Connect monitor → here
    evm_reg_map reg_map;                  // Set before simulation
    
    bit check_reads = 0;  // Validate reads against mirror
    bit verbose     = 0;  // Per-transaction logging
    
    // Implement these 3 methods for your transaction type:
    pure virtual function bit [63:0] get_addr(TXN txn);
    pure virtual function bit [63:0] get_data(TXN txn);
    pure virtual function bit        is_write(TXN txn);
    
    // On reset: mirror reset to power-on values automatically
endclass
```

**Concrete predictors (ready to use):**

```systemverilog
// For AXI-Lite writes — updates mirror when write observed on bus
class evm_axi_lite_write_predictor 
    extends evm_reg_predictor#(evm_axi_lite_write_txn);
    // get_addr() → txn.addr
    // get_data() → txn.data
    // is_write() → 1 (always write)
endclass

// For AXI-Lite reads — validates read data against mirror
class evm_axi_lite_read_predictor
    extends evm_reg_predictor#(evm_axi_lite_read_txn);
    // check_reads = 1 by default
    // is_write() → 0
endclass
```

---

## CSR Generator Integration

The CSR generator (`csr_gen/gen_csr.py`) creates:
- SystemVerilog RTL (synthesizable register module)
- C header (for firmware)
- `evm_reg_block` subclass (ready to instantiate)
- Documentation

**YAML definition (source of truth):**
```yaml
modules:
  - name: doorbell
    base_address: 0x0000_0000
    registers:
      - name: DOORBELL_ADDR
        offset: 0x00
        access: WO
        reset: 0x0000_0000
        description: Host buffer address for packet fetch
        fields:
          - name: ADDR
            bits: [31, 0]
            description: 32-bit host DMA address

      - name: DOORBELL_SIZE
        offset: 0x04
        access: WO
        reset: 0x0000
        fields:
          - name: SIZE
            bits: [15, 0]
            description: Packet size in bytes

      - name: STATUS
        offset: 0x08
        access: RO
        reset: 0x0000_0000
        fields:
          - name: STATE
            bits: [1, 0]
            description: 00=IDLE 01=FETCHING 10=TRANSMITTING
```

**Generate:**
```bash
python csr_gen/gen_csr.py my_nic.yaml output/
```

**Generated `doorbell_reg_model.sv` (usable immediately):**
```systemverilog
class doorbell_reg_model extends evm_reg_block;
    // Auto-generated per-register read/write methods:
    task write_doorbell_addr(bit [31:0] value, output bit status);
    task write_doorbell_size(bit [15:0] value, output bit status);
    task read_status(output bit [31:0] value, output bit status);
    
    // Reset to power-on values
    function void reset(string kind = "HARD");
endclass
```

---

## Complete Usage Pattern

### 1. Setup in env build_phase

```systemverilog
class my_env extends evm_env;
    evm_axi_lite_master_agent     csr_agent;
    doorbell_reg_model            ral;         // from CSR generator
    evm_reg_map                   reg_map;
    evm_axi_lite_write_predictor  predictor;
    
    virtual function void build_phase();
        super.build_phase();
        csr_agent = new("csr_agent", this);
        ral       = new("ral");
        reg_map   = new("reg_map", 32'h0000_0000); // bus base address
        predictor = new("predictor", this);
        
        // Add RAL block to map at offset 0
        reg_map.add_reg_block("doorbell", ral, 32'h0000_0000);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        // Connect agent to RAL
        reg_map.set_agent(csr_agent);
        ral.reset();
        
        // Auto-update mirror when writes observed on bus
        predictor.reg_map = reg_map;
        csr_agent.monitor.ap_write.connect(
            predictor.analysis_imp.get_mailbox());
    endfunction
endclass
```

### 2. Use in test main_phase

```systemverilog
virtual task main_phase();
    super.main_phase();
    raise_objection("test");
    bit status;
    
    // Write doorbell (DUT will start fetching)
    env.ral.write_doorbell_addr(32'hDEAD_0000, status);
    env.ral.write_doorbell_size(16'd1024,       status);
    
    // Poll status until IDLE
    begin
        bit [31:0] val;
        bit success;
        env.csr_agent.poll(
            32'h0000_0008,     // STATUS register address
            32'h0000_0003,     // mask (bits [1:0])
            32'h0000_0000,     // expected IDLE
            5000,              // timeout cycles
            success
        );
    end
    
    // Mirror check - reads DUT and compares with model
    env.ral.mirror(status);
    
    drop_objection("test");
endtask
```

### 3. Mirror is auto-updated by predictor

Whenever the CSR agent drives a write, the monitor's `ap_write` port fires, the predictor receives the `evm_axi_lite_write_txn`, looks up the register by address in the map, and calls `reg.predict(data, 0)` to update the mirror. No manual mirror calls needed for writes you drive.

---

## Register Sequences

For systematic register testing (common in IP sign-off):

```systemverilog
class reg_hw_reset_seq extends evm_sequence;
    evm_reg_block blk;
    
    task body();
        evm_reg regs[$];
        bit status;
        blk.get_registers(regs);
        foreach (regs[i]) begin
            bit [63:0] expected = regs[i].get(); // mirror has reset values
            regs[i].read_check(expected, '1, status);
        end
    endtask
endclass
```

---

## See Also

- [`../csr_gen/README.md`](../csr_gen/README.md) — CSR generator documentation
- [`AGENTS.md`](AGENTS.md) — AXI-Lite agent that drives RAL transactions
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — How the predictor integrates into the framework
