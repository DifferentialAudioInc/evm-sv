# EVM Utilities

## Memory Model

```mermaid
classDiagram
    class evm_object {
        <<abstract>>
        +string name
    }
    
    class evm_memory_model {
        +byte memory[longint]
        +longint memory_size
        +int read_latency_cycles
        +int write_latency_cycles
        +longint read_count
        +longint write_count
        +write_byte(addr, data)
        +write_word(addr, data)
        +write_burst(addr, data[], size)
        +read_byte(addr) byte
        +read_word(addr) bit[31:0]
        +read_burst(addr, output data[], size)
        +clear()
        +init_pattern(addr, size, pattern)
        +load_from_file(filename, addr)
        +save_to_file(filename, addr, size)
        +print_statistics()
    }
    
    evm_memory_model --|> evm_object
```

## Scoreboard

```mermaid
classDiagram
    class evm_component {
        <<abstract>>
    }
    
    class evm_scoreboard~T~ {
        <<parameterized>>
        +evm_scoreboard_mode_e mode
        +T expected_queue[$]
        +T actual_queue[$]
        +int match_count
        +int mismatch_count
        +bit enable_auto_check
        +bit stop_on_mismatch
        +insert_expected(item)
        +insert_actual(item)
        +check_transaction(actual) bit
        +compare_transactions(exp, act)* bit
        +find_matching_expected(act)* int
        +check_all()
        +print_report()
        +clear()
    }
    
    evm_scoreboard --|> evm_component
```

## Scoreboard Matching Modes

```mermaid
graph TD
    SB[Scoreboard]
    
    SB --> FIFO[EVM_SB_FIFO<br/>Strict FIFO Order]
    SB --> ASSOC[EVM_SB_ASSOCIATIVE<br/>Match by Key]
    SB --> UNORD[EVM_SB_UNORDERED<br/>Any Match]
    
    FIFO --> F1[Expected[0] must match Actual[0]]
    FIFO --> F2[Expected[1] must match Actual[1]]
    
    ASSOC --> A1[Find by key/ID]
    ASSOC --> A2[Out-of-order OK]
    
    UNORD --> U1[Match any expected<br/>with any actual]
```

## Memory Model Usage Flow

```mermaid
sequenceDiagram
    participant Test
    participant MemModel
    participant File
    
    Test->>MemModel: new(size_mb)
    
    Test->>File: Load stimulus
    File-->>MemModel: load_from_file()
    
    Test->>MemModel: write_word(addr, data)
    Note over MemModel: Store in sparse array
    
    Test->>MemModel: read_word(addr)
    MemModel-->>Test: data
    
    Test->>MemModel: save_to_file()
    MemModel->>File: Write results
    
    Test->>MemModel: print_statistics()
    Note over MemModel: Show R/W counts
```

## Scoreboard Usage Flow

```mermaid
sequenceDiagram
    participant Test
    participant Scoreboard
    participant Monitor
    
    Test->>Scoreboard: new(mode)
    Test->>Scoreboard: set mode = FIFO
    
    Test->>Scoreboard: insert_expected(item1)
    Test->>Scoreboard: insert_expected(item2)
    
    Monitor->>Scoreboard: insert_actual(actual1)
    Scoreboard->>Scoreboard: auto_check()
    Note over Scoreboard: Compare with expected[0]
    
    Monitor->>Scoreboard: insert_actual(actual2)
    Scoreboard->>Scoreboard: auto_check()
    Note over Scoreboard: Compare with expected[1]
    
    Test->>Scoreboard: print_report()
    Scoreboard-->>Test: Matches: 2<br/>Mismatches: 0
```

## Memory Model Features

### Sparse Array
- Only stores written locations
- Efficient for large address spaces
- 64MB default size

### File I/O
- Load stimulus from files
- Save results for analysis
- Hex format support

### Statistics
- Read/write counters
- Byte tracking
- Performance metrics

### Latency Modeling
- Configurable read/write latency
- Realistic memory timing
- Burst support

## Scoreboard Features

### Multiple Matching Modes
- **FIFO**: Strict order matching
- **Associative**: Match by key/ID
- **Unordered**: Any-to-any matching

### Auto-Check
- Automatic comparison on insert_actual()
- Immediate feedback
- Optional deferred checking

### Statistics & Reporting
- Match/mismatch counters
- Orphan detection (expected or actual with no match)
- Pass rate calculation
- Detailed reporting

### Customization
- Virtual compare_transactions() method
- Override for custom comparison logic
- Virtual find_matching_expected() for key-based matching

## Usage Examples

### Memory Model
```systemverilog
// Create 64MB memory
evm_memory_model mem = new("ddr_model", 64*1024*1024);

// Load stimulus
mem.load_from_file("stimulus.hex", 32'h00000000);

// Write/read
mem.write_word(32'h00001000, 32'hDEADBEEF);
data = mem.read_word(32'h00001000);

// Save results
mem.save_to_file("results.hex", 32'h00002000, 1024);
mem.print_statistics();
```

### Scoreboard
```systemverilog
// Create parameterized scoreboard
evm_scoreboard#(my_transaction) sb = new("sb");
sb.mode = EVM_SB_FIFO;
sb.enable_auto_check = 1;

// Insert expected
sb.insert_expected(exp_trans1);
sb.insert_expected(exp_trans2);

// Monitor inserts actual (auto-checked)
sb.insert_actual(act_trans1);  // Compared immediately
sb.insert_actual(act_trans2);

// Final report
sb.print_report();  // Shows matches/mismatches
```
