# EVM TLM Infrastructure & Sequences

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## TLM 1.0 Class Overview

```mermaid
classDiagram
    %% ── Analysis Ports (broadcast) ────────────────────────────────────────────
    class evm_analysis_port~T~ {
        -mailbox~T~ m_subscribers[$]
        +connect(mailbox~T~ subscriber)
        +write(T t)
        +get_subscriber_count() int
    }

    class evm_analysis_imp~T~ {
        -mailbox~T~ m_mailbox
        +get(T t)*
        +try_get(T t) bit
        +get_mailbox() mailbox~T~
        +num_pending() int
    }

    %% ── Sequence Item Ports ───────────────────────────────────────────────────
    class evm_seq_item_pull_port~REQ,RSP~ {
        -mailbox~REQ~ m_req_fifo
        -mailbox~RSP~ m_rsp_fifo
        +connect(req_fifo, rsp_fifo)
        +get_next_item(REQ req)*
        +try_next_item(REQ req)*
        +item_done(RSP rsp)
        +peek(REQ req)*
        +is_connected() bit
    }

    class evm_seq_item_pull_export~REQ,RSP~ {
        -mailbox~REQ~ m_req_fifo
        -mailbox~RSP~ m_rsp_fifo
        +get_req_fifo() mailbox~REQ~
        +get_rsp_fifo() mailbox~RSP~
        +put(REQ req)*
        +try_put(REQ req) bit
        +get_response(RSP rsp)*
        +num_pending() int
    }

    evm_analysis_port  ..> evm_analysis_imp : "broadcasts to mailbox"
    evm_seq_item_pull_port ..> evm_seq_item_pull_export : "connects to FIFOs"
```

---

## Sequence Infrastructure

```mermaid
classDiagram
    class evm_sequence_item {
        +string name
        +int item_id
        +realtime start_time
        +realtime end_time
        +bit completed
        +get_duration() realtime
        +convert2string() string
    }

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

    class evm_sequence {
        +string name
        +evm_sequence_item items[$]
        +add_item(item)
        +get_item_count() int
        +get_name() string
    }

    class evm_csr_sequence {
        +add_write(addr, data, name)
        +add_read(addr, name)
        +add_read_check(addr, expected, mask, name)
        +execute_all(agent)
    }

    class evm_sequencer~REQ,RSP~ {
        +evm_seq_item_pull_export~REQ,RSP~ seq_item_export
        +mailbox~evm_sequence_item~ item_mbx
        +int items_sent
        +int items_completed
        +send_item(item)*
        +get_next_item(item)*
        +item_done(item)
        +execute_sequence(seq)*
        +run_phase()
        +on_reset_assert()
    }

    class evm_virtual_sequence {
        +evm_sequencer sequencers[$]
        +add_sequencer(sqr)
        +get_sequencer(name) evm_sequencer
        +start()*
        +body()*
    }

    evm_csr_item --|> evm_sequence_item : extends
    evm_csr_sequence --|> evm_sequence : extends
    evm_virtual_sequence --|> evm_sequence : extends
    evm_sequence o-- evm_sequence_item : "contains items[$]"
    evm_sequencer ..> evm_sequence_item : "dispatches"
```

---

## Driver ↔ Sequencer Connection

```mermaid
graph TD
    SEQ["evm_sequence\nItems generated here"]

    SEQ --> |"send_item()"| SQR["evm_sequencer\nitem_mbx / req_fifo"]

    SQR --> |"seq_item_export\nget_req_fifo()"| PORT["Connection point"]
    PORT --> |"seq_item_port\nget_next_item()"| DRV["evm_driver\nDrives signals"]

    DRV --> |"item_done()"| PORT
    PORT --> |"rsp_fifo"| SQR

    DRV --> BUS["Interface → DUT"]
```

**Connection code:**
```systemverilog
// In agent connect_phase():
driver.seq_item_port.connect(
    sequencer.seq_item_export.get_req_fifo(),
    sequencer.seq_item_export.get_rsp_fifo()
);
```

---

## Monitor → Multiple Subscribers

```mermaid
graph TD
    MON["Monitor\nanalysis_port"]
    MB1["mailbox 1"]
    MB2["mailbox 2"]
    MB3["mailbox 3"]

    MON --> |"connect()"| MB1
    MON --> |"connect()"| MB2
    MON --> |"connect()"| MB3

    MB1 --> SB["Scoreboard\nanalysis_imp.get()"]
    MB2 --> PRED["RAL Predictor\nanalysis_imp.get()"]
    MB3 --> COV["Coverage Collector\nanalysis_imp.get()"]

    style MON fill:#4CAF50,color:#fff
    style SB fill:#2196F3,color:#fff
    style PRED fill:#2196F3,color:#fff
    style COV fill:#2196F3,color:#fff
```

---

## Sequence Execution Flow

```mermaid
sequenceDiagram
    participant Test
    participant Library as "evm_sequence_library"
    participant Seq as "my_sequence"
    participant Sqr as "evm_sequencer"
    participant Driver as "evm_driver"
    participant DUT

    Test->>Library: run_sequence("doorbell_seq", sqr)
    Library->>Library: create_sequence("doorbell_seq")
    Library->>Seq: new("doorbell_seq")
    Library->>Sqr: execute_sequence(seq)
    loop for each item in seq
        Sqr->>Sqr: send_item(item) → req_fifo
        Driver->>Sqr: get_next_item(req)
        Driver->>DUT: drive transaction
        DUT-->>Driver: acknowledge
        Driver->>Sqr: item_done(req)
    end
    Library-->>Test: sequence complete
```

---

## Virtual Sequence Pattern

```mermaid
graph TD
    VSEQ["evm_virtual_sequence\n(coordinates multiple agents)"]

    VSEQ --> |"sequencers[0]"| SQR0["CSR Sequencer\n(AXI-Lite)"]
    VSEQ --> |"sequencers[1]"| SQR1["DMA Sequencer\n(AXI4 Full)"]
    VSEQ --> |"sequencers[2]"| SQR2["Stream Sequencer"]

    SQR0 --> DRV0["AXI-Lite Driver\n→ CSR writes"]
    SQR1 --> DRV1["AXI4 Full Driver\n→ DMA bursts"]
    SQR2 --> DRV2["Stream Driver\n→ packet data"]
```
