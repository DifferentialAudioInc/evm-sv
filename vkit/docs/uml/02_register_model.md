# EVM Register Abstraction Layer (RAL)

## Register Model Class Hierarchy

```mermaid
classDiagram
    class evm_object {
        <<abstract>>
        +string name
    }
    
    class evm_reg_field {
        +string name
        +int lsb
        +int width
        +evm_reg_access_e access
        +bit[63:0] reset_value
        +bit[63:0] mirrored_value
        +read(output value, status)
        +write(value, status)
        +get_mirrored_value()
        +set_mirrored_value()
    }
    
    class evm_reg {
        +string name
        +bit[63:0] address
        +int size
        +evm_reg_field fields[$]
        +add_field(field)
        +get_field(name)
        +read(output value, status)
        +write(value, status)
        +mirror(value)
        +check(expected)
        +reset()
    }
    
    class evm_reg_block {
        +string name
        +bit[63:0] base_address
        +evm_reg registers[$]
        +evm_component agent
        +add_reg(reg)
        +get_reg(name)
        +set_agent(agent)
        +reset(kind)
        +dump()
    }
    
    class evm_csr_item {
        +evm_csr_op_e op
        +bit[63:0] address
        +bit[63:0] data
        +bit status
        +convert2string()
    }
    
    %% Inheritance
    evm_reg_field --|> evm_object
    evm_reg --|> evm_object
    evm_reg_block --|> evm_object
    evm_csr_item --|> evm_object
    
    %% Composition
    evm_reg o-- evm_reg_field : contains
    evm_reg_block o-- evm_reg : contains
    evm_reg_block ..> evm_csr_item : generates
```

## Field Access Types

```mermaid
graph TD
    subgraph "Read/Write"
        RW[EVM_REG_RW<br/>Read/Write]
        RO[EVM_REG_RO<br/>Read Only]
        WO[EVM_REG_WO<br/>Write Only]
    end
    
    subgraph "Clear on Access"
        RC[EVM_REG_RC<br/>Read to Clear]
        WC[EVM_REG_WC<br/>Write to Clear]
        W1C[EVM_REG_W1C<br/>Write 1 to Clear]
    end
    
    subgraph "Set on Access"
        RS[EVM_REG_RS<br/>Read to Set]
        WS[EVM_REG_WS<br/>Write to Set]
        W1S[EVM_REG_W1S<br/>Write 1 to Set]
    end
```

## Register Model Hierarchy Example

```mermaid
graph TD
    TOP[top_reg_model]
    
    TOP --> SYS[system_reg_model]
    TOP --> ADC[adc_reg_model]
    TOP --> FFT[fft_reg_model]
    
    SYS --> SYS_BLK[system_reg_block<br/>base: 0x00000000]
    ADC --> ADC_BLK[adc_reg_block<br/>base: 0x00010000]
    FFT --> FFT_BLK[fft_reg_block<br/>base: 0x00020000]
    
    SYS_BLK --> VER[version_reg<br/>offset: 0x00]
    SYS_BLK --> CTRL[control_reg<br/>offset: 0x04]
    SYS_BLK --> STAT[status_reg<br/>offset: 0x08]
    
    VER --> MAJOR[major: [31:24] RO]
    VER --> MINOR[minor: [23:16] RO]
    VER --> PATCH[patch: [15:8] RO]
    
    CTRL --> EN[enable: [0] RW]
    CTRL --> RST[reset: [1] RW]
    CTRL --> DBG[debug: [2] RW]
    
    STAT --> RDY[ready: [0] RO]
    STAT --> ERR[error: [1] RC]
    STAT --> LOCK[locked: [2] RO]
```

## Register Access Flow

```mermaid
sequenceDiagram
    participant Test
    participant RegModel
    participant RegBlock
    participant Register
    participant Agent
    participant DUT
    
    Test->>RegModel: system.control.write(value)
    RegModel->>RegBlock: write(addr, value)
    RegBlock->>Register: write(value)
    Register->>Agent: generate CSR transaction
    Agent->>DUT: AXI-Lite write
    DUT-->>Agent: response
    Agent-->>Register: status
    Register->>Register: update mirror
    Register-->>Test: done
```

## Key Features

### evm_reg_field
- Represents individual bit field
- 9 access types (RW, RO, WO, RC, RS, WC, WS, W1C, W1S)
- Reset and mirrored values
- Automatic field extraction

### evm_reg
- Contains multiple fields
- Address offset within block
- Read/write/mirror/check methods
- Field-level access

### evm_reg_block
- Collection of registers
- Base address management
- Agent association
- Block-level operations

### Auto-Generated Models
- CSR generator creates RAL from YAML
- Per-module register models
- Top-level aggregation model
- Type-safe access methods

## Usage Example

```systemverilog
// Create and configure
top_reg_model ral = new();
ral.configure(axi_agent);

// Write register
ral.system.control.write(32'h0003, status);

// Read register
ral.system.status.read(value, status);

// Field-level access
ral.system.control.enable.write(1, status);

// Mirror check
ral.system.status.mirror(actual_value);
if (ral.system.status.check(expected)) begin
    $display("Match!");
end
```
