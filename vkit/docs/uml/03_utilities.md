# EVM Utilities

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Scoreboard

```mermaid
classDiagram
    class evm_scoreboard~T~ {
        +evm_analysis_imp~T~ analysis_imp
        +evm_scoreboard_mode_e mode
        +T expected_queue[$]
        +T actual_queue[$]
        +bit enable_auto_check
        +bit stop_on_mismatch
        +int match_count
        +int mismatch_count
        +int orphan_expected
        +int orphan_actual
        +insert_expected(item)
        +insert_actual(item)
        +check_transaction(actual) bit
        +compare_transactions(expected, actual) bit*
        +find_matching_expected(actual) int*
        +check_all()
        +clear()
        +print_report()
        +run_phase()
        +on_reset_assert()
        +on_reset_deassert()
        +final_phase()
    }

    evm_scoreboard --|> evm_component : extends
```

**Three matching modes:**

```mermaid
graph TD
    SB[Scoreboard Mode]
    SB --> FIFO["EVM_SB_FIFO<br/>Strict order matching<br/>Expected must arrive before actual"]
    SB --> ASSOC["EVM_SB_ASSOCIATIVE<br/>Match by key (out-of-order OK)<br/>Override find_matching_expected()"]
    SB --> UNORD["EVM_SB_UNORDERED<br/>Any expected matches any actual<br/>Exact bitwise match"]
```

**run_phase() operation:**
```mermaid
graph TD
    RP[run_phase started]
    RP --> FORK{fork}
    FORK --> RST[Reset Monitor Thread]
    FORK --> CHK[Check Loop]

    RST --> |"reset_asserted"| RA[on_reset_assert: flush queues]
    RA --> |"reset_deasserted"| RD[on_reset_deassert: ready]
    RD --> RST

    CHK --> |"not in_reset"| GET[analysis_imp.get txn]
    GET --> INS[insert_actual → compare]
    INS --> CHK
    CHK --> |"in_reset"| WAIT[wait reset_deasserted]
    WAIT --> CHK
```

---

## Memory Model

```mermaid
classDiagram
    class evm_memory_model {
        +byte memory[longint]
        +longint memory_size
        +longint base_address
        +string name
        +write_byte(addr, data)
        +write_word(addr, data)
        +write_dword(addr, data)
        +write_burst(addr, data[$])
        +read_byte(addr) byte
        +read_word(addr) bit[31:0]
        +read_dword(addr) bit[63:0]
        +read_burst(addr, len) byte[$]
        +load_from_file(filename)
        +save_to_file(filename)
        +fill(value, start, len)
        +clear()
        +dump(start, len)
    }

    evm_memory_model --|> evm_object : extends
```

**Usage for DMA simulation:**
```mermaid
sequenceDiagram
    participant Test
    participant Memory as "evm_memory_model"
    participant DUT_DMA as "DUT (DMA master)"

    Test->>Memory: fill packet data at address 0xDEAD0000
    Test->>DUT_DMA: doorbell write (addr=0xDEAD0000, size=1024)
    DUT_DMA->>Memory: AXI4 read burst (via AXI4 Full agent slave)
    Memory-->>DUT_DMA: packet data (8 beats × 64-bit)
    Note over DUT_DMA: store and forward...
    DUT_DMA->>Test: streaming output (SOP → data → EOP)
```

---

## Sequence Library

```mermaid
classDiagram
    class evm_sequence_creator {
        <<abstract>>
        +create(name) evm_sequence*
        +get_type_name() string
    }

    class evm_sequence_creator_t~T~ {
        +create(name) evm_sequence
    }

    class evm_sequence_library {
        -evm_sequence_creator m_global_creators[string]$
        -string m_enabled[$]
        -bit m_use_all
        +evm_seq_select_e selection_mode
        +int sequences_run
        +register(name, creator)$
        +create_sequence(name) evm_sequence$
        +list_all()$
        +enable_sequence(name)
        +enable_all()
        +run_sequence(name, sqr)*
        +run_random(sqr)*
        +run_all(sqr)*
        +run_from_plusarg(sqr)*
        +sequence_exists(name) bit
    }

    evm_sequence_creator_t --|> evm_sequence_creator
    evm_sequence_library ..> evm_sequence_creator : "static registry"
```

**Selection modes:**
```mermaid
graph LR
    R[run_random] --> |"SEQ_RANDOM"| RAND[urandom selection]
    R --> |"SEQ_ROUND_ROBIN"| RR[next in cyclic order]
```

---

## Coverage and Assertion Infrastructure

```mermaid
classDiagram
    class evm_coverage {
        +int coverage_threshold
        +bit enable_coverage
        +enable()
        +disable()
        +get_coverage() real
        +report_phase()
    }

    class evm_assertions {
        +int assertion_count
        +int pass_count
        +int fail_count
        +check(condition, msg)
        +check_eq(actual, expected, msg)
        +check_ne(actual, unexpected, msg)
        +print_summary()
    }

    evm_coverage   --|> evm_component : extends
    evm_assertions --|> evm_component : extends
```
