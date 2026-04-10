# EVM Register Model (RAL)

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Complete RAL Class Hierarchy

```mermaid
classDiagram
    %% ── Object Layer ──────────────────────────────────────────────────────────
    class evm_object {
        <<abstract>>
        +string name
        +log_info/warning/error()
    }

    %% ── Register Field ────────────────────────────────────────────────────────
    class evm_reg_field {
        +string name
        +int lsb_pos
        +int size
        +evm_reg_access_e access
        +bit[63:0] reset_value
        +bit[63:0] mirrored_value
        +get() bit[63:0]
        +set(value)
        +reset(kind)
        +predict(value, is_read)
        +get_mask() bit[63:0]
    }

    %% ── Register ──────────────────────────────────────────────────────────────
    class evm_reg {
        +bit[63:0] address
        +int n_bits
        +evm_reg_field fields[$]
        +evm_component target_agent
        +add_field(field)
        +get_field_by_name(name) evm_reg_field
        +get() bit[63:0]
        +set(value)
        +reset(kind)
        +predict(value, is_read)
        +write(value, status)*
        +read(value, status)*
        +read_check(expected, mask, status)*
        +mirror(status)*
    }

    %% ── Register Block ────────────────────────────────────────────────────────
    class evm_reg_block {
        +bit[63:0] base_address
        +evm_reg registers[$]
        +evm_component default_agent
        +add_reg(reg)
        +get_reg_by_name(name) evm_reg
        +get_reg_by_address(addr) evm_reg
        +get_registers(ref reg_list[$])
        +set_agent(agent)
        +reset(kind)
        +write_reg(name, value, status)*
        +read_reg(name, value, status)*
        +mirror(status)*
        +dump()
    }

    %% ── Register Map (NEW) ────────────────────────────────────────────────────
    class evm_reg_map {
        +bit[63:0] base_address
        +add_reg_block(name, blk, offset)
        +get_reg_by_address(abs_addr) evm_reg
        +get_reg_by_name(reg_name) evm_reg
        +get_block(name) evm_reg_block
        +set_agent(agent)
        +reset(kind)
        +dump()
    }

    %% ── Predictor (NEW) ───────────────────────────────────────────────────────
    class evm_reg_predictor~TXN~ {
        <<abstract>>
        +evm_analysis_imp~TXN~ analysis_imp
        +evm_reg_map reg_map
        +bit check_reads
        +bit verbose
        +int write_predictions
        +int read_mismatches
        +get_addr(txn) bit[63:0]*
        +get_data(txn) bit[63:0]*
        +is_write(txn) bit*
        +process_txn(txn)
        +run_phase()
        +on_reset_assert()
    }

    %% ── Concrete Predictors ───────────────────────────────────────────────────
    class evm_axi_lite_write_predictor {
        +get_addr(txn) bit[63:0]
        +get_data(txn) bit[63:0]
        +is_write(txn) bit
    }

    class evm_axi_lite_read_predictor {
        +check_reads = 1
        +get_addr(txn) bit[63:0]
        +get_data(txn) bit[63:0]
        +is_write(txn) bit
    }

    %% ── CSR Transaction ───────────────────────────────────────────────────────
    class evm_csr_item {
        +evm_csr_op_e op
        +bit[31:0] address
        +bit[31:0] data
        +string reg_name
        +bit status
        +create_write(addr, data, name)$
        +create_read(addr, name)$
        +is_read() bit
        +is_write() bit
    }

    %% ── Inheritance ───────────────────────────────────────────────────────────
    evm_reg_field       --|> evm_object : extends
    evm_reg             --|> evm_object : extends
    evm_reg_block       --|> evm_object : extends
    evm_reg_map         --|> evm_object : extends
    evm_reg_predictor   --|> evm_component : extends
    evm_csr_item        --|> evm_object : extends
    evm_axi_lite_write_predictor --|> evm_reg_predictor : extends
    evm_axi_lite_read_predictor  --|> evm_reg_predictor : extends

    %% ── Composition ───────────────────────────────────────────────────────────
    evm_reg            o-- evm_reg_field : "contains fields[$]"
    evm_reg_block      o-- evm_reg       : "contains registers[$]"
    evm_reg_map        o-- evm_reg_block : "contains blocks[]"
    evm_reg_predictor  o-- evm_reg_map   : "ref reg_map"
    evm_reg            ..> evm_csr_item  : "generates for bus access"
```

---

## Field Access Types

```mermaid
graph TD
    subgraph ReadWrite["Read / Write"]
        RW["EVM_REG_RW — Normal read/write"]
        RO["EVM_REG_RO — Read only"]
        WO["EVM_REG_WO — Write only"]
    end
    subgraph ClearOnAccess["Clear on Access"]
        RC["EVM_REG_RC — Read to Clear"]
        WC["EVM_REG_WC — Write to Clear"]
        W1C["EVM_REG_W1C — Write 1 to Clear"]
    end
    subgraph SetOnAccess["Set on Access"]
        RS["EVM_REG_RS — Read to Set"]
        WS["EVM_REG_WS — Write to Set"]
        W1S["EVM_REG_W1S — Write 1 to Set"]
    end
```

---

## Address Map Hierarchy Example

```mermaid
graph TD
    MAP["evm_reg_map<br/>base=0x0000_0000"]

    MAP --> BLK1["doorbell_reg_model<br/>offset=0x0000"]
    MAP --> BLK2["status_reg_model<br/>offset=0x1000"]

    BLK1 --> R1["DOORBELL_ADDR<br/>offset=0x00  WO"]
    BLK1 --> R2["DOORBELL_SIZE<br/>offset=0x04  WO"]
    BLK1 --> R3["CTRL<br/>offset=0x08  RW"]

    BLK2 --> R4["STATUS<br/>offset=0x00  RO"]
    BLK2 --> R5["ERR_FLAGS<br/>offset=0x04  RC"]

    R1 --> F1["ADDR[31:0]"]
    R2 --> F2["SIZE[15:0]"]
    R3 --> F3["ENABLE[0]"]
    R3 --> F4["RESET[1]"]
    R4 --> F5["STATE[1:0]"]
    R5 --> F6["TIMEOUT[0]  RC"]
    R5 --> F7["BUS_ERR[1]  RC"]
```

---

## Register Write Flow with Predictor Auto-Sync

```mermaid
sequenceDiagram
    participant Test
    participant RAL as "evm_reg / evm_reg_block"
    participant Driver as "AXI-Lite Driver"
    participant DUT
    participant Monitor as "AXI-Lite Monitor"
    participant Predictor as "evm_axi_lite_write_predictor"

    Test->>RAL: write_doorbell_addr(0xDEAD0000, status)
    RAL->>Driver: generate AXI-Lite write txn
    Driver->>DUT: AXI Write (AW+W channels)
    DUT-->>Driver: B response (OKAY)
    Driver-->>RAL: status=1
    RAL->>RAL: predict(value, is_read=0)
    Note over RAL: Mirror updated by RAL itself

    Note over Monitor: Independently observing bus...
    Monitor->>Predictor: ap_write → evm_axi_lite_write_txn
    Predictor->>Predictor: get_addr() → 0x0000
    Predictor->>Predictor: reg_map.get_reg_by_address(0x0000)
    Predictor->>RAL: reg.predict(0xDEAD0000, is_read=0)
    Note over RAL: Mirror confirmed (or set if RAL had no agent)
```

---

## CSR Generator Integration

```mermaid
graph LR
    YAML["my_nic.yaml<br/>(source of truth)"]
    GEN["gen_csr.py"]
    RTL["*_csr.sv<br/>(RTL module)"]
    HDR["*_csr.h<br/>(C header)"]
    MODEL["*_reg_model.sv<br/>(evm_reg_block subclass)"]
    DOCS["register_map.md<br/>(documentation)"]

    YAML --> GEN
    GEN --> RTL
    GEN --> HDR
    GEN --> MODEL
    GEN --> DOCS

    MODEL --> MAP["evm_reg_map"]
    MAP --> PRED["evm_reg_predictor"]
    MAP --> TEST["Test reads/writes"]
```
