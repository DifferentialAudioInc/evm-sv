# EVM AXI4-Lite Agent

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## AXI4-Lite Agent Class Hierarchy

```mermaid
classDiagram
    class evm_agent {
        <<abstract>>
        +evm_mode_e mode
        +evm_driver driver
        +evm_monitor monitor
        +set_mode(mode)
        +create_driver()* evm_driver
        +create_monitor()* evm_monitor
        +set_vif(vif)
    }

    class evm_axi_lite_master_agent {
        +evm_axi_lite_cfg cfg
        +evm_sequencer~evm_csr_item~ sequencer
        +write(addr, data, strb, resp)*
        +read(addr, data, resp)*
        +write_check(addr, data)*
        +read_check(addr, data)*
        +rmw(addr, mask, value)*
        +poll(addr, mask, expected, timeout, success)*
        +get_driver() evm_axi_lite_master_driver
        +get_monitor() evm_axi_lite_monitor
    }

    class evm_axi_lite_master_driver {
        +evm_axi_lite_cfg cfg
        +int write_count
        +int read_count
        +write(addr, data, strb, resp)*
        +read(addr, data, resp)*
        +write_check(addr, data)*
        +read_check(addr, data)*
        +rmw(addr, mask, value)*
        +poll(addr, mask, expected, timeout, success)*
        +main_phase()
        +on_reset_assert()
        +on_reset_deassert()
    }

    class evm_axi_lite_monitor {
        +evm_axi_lite_cfg cfg
        +evm_analysis_port~evm_axi_lite_aw_txn~ ap_aw
        +evm_analysis_port~evm_axi_lite_w_txn~ ap_w
        +evm_analysis_port~evm_axi_lite_b_txn~ ap_b
        +evm_analysis_port~evm_axi_lite_ar_txn~ ap_ar
        +evm_analysis_port~evm_axi_lite_r_txn~ ap_r
        +evm_analysis_port~evm_axi_lite_write_txn~ ap_write
        +evm_analysis_port~evm_axi_lite_read_txn~ ap_read
        +int write_observed
        +int read_observed
        +run_phase()
        +on_reset_assert()
    }

    class evm_axi_lite_cfg {
        +evm_axi_mode_e mode
        +bit use_sequencer
        +int master_delay_min
        +int master_delay_max
        +int back_to_back_pct
        +int awready_delay_min
        +int awready_delay_max
        +int arready_delay_min
        +int arready_delay_max
    }

    evm_axi_lite_master_agent --|> evm_agent : extends
    evm_axi_lite_master_driver --|> evm_driver : extends
    evm_axi_lite_monitor --|> evm_monitor : extends
    evm_axi_lite_master_agent o-- evm_axi_lite_master_driver : driver
    evm_axi_lite_master_agent o-- evm_axi_lite_monitor : monitor
    evm_axi_lite_master_agent o-- evm_axi_lite_cfg : cfg
```

---

## Transaction Types

```mermaid
classDiagram
    class evm_axi_lite_aw_txn {
        +logic[31:0] addr
        +logic[2:0] prot
        +realtime time_ns
        +convert2string() string
    }

    class evm_axi_lite_w_txn {
        +logic[31:0] data
        +logic[3:0] strb
        +realtime time_ns
        +convert2string() string
    }

    class evm_axi_lite_b_txn {
        +logic[1:0] resp
        +realtime time_ns
        +is_okay() bit
        +convert2string() string
    }

    class evm_axi_lite_ar_txn {
        +logic[31:0] addr
        +logic[2:0] prot
        +realtime time_ns
        +convert2string() string
    }

    class evm_axi_lite_r_txn {
        +logic[31:0] data
        +logic[1:0] resp
        +realtime time_ns
        +is_okay() bit
        +convert2string() string
    }

    class evm_axi_lite_write_txn {
        +logic[31:0] addr
        +logic[31:0] data
        +logic[3:0] strb
        +logic[2:0] prot
        +logic[1:0] resp
        +realtime aw_time_ns
        +realtime w_time_ns
        +realtime b_time_ns
        +get_write_latency() realtime
        +is_okay() bit
        +convert2string() string
    }

    class evm_axi_lite_read_txn {
        +logic[31:0] addr
        +logic[31:0] data
        +logic[2:0] prot
        +logic[1:0] resp
        +realtime ar_time_ns
        +realtime r_time_ns
        +get_read_latency() realtime
        +is_okay() bit
        +convert2string() string
    }

    evm_axi_lite_aw_txn --|> evm_object
    evm_axi_lite_w_txn  --|> evm_object
    evm_axi_lite_b_txn  --|> evm_object
    evm_axi_lite_ar_txn --|> evm_object
    evm_axi_lite_r_txn  --|> evm_object
    evm_axi_lite_write_txn --|> evm_object
    evm_axi_lite_read_txn  --|> evm_object
```

---

## Monitor Analysis Port Connections

```mermaid
graph TD
    MON["evm_axi_lite_monitor"]

    MON --> |"ap_aw (per AW handshake)"| AW["Subscribers:<br/>protocol checker<br/>latency monitor"]
    MON --> |"ap_w  (per W  handshake)"| W["Subscribers:<br/>bandwidth monitor"]
    MON --> |"ap_b  (per B  handshake)"| B["Subscribers:<br/>response checker<br/>latency monitor"]
    MON --> |"ap_ar (per AR handshake)"| AR["Subscribers:<br/>protocol checker"]
    MON --> |"ap_r  (per R  handshake)"| R["Subscribers:<br/>bandwidth monitor"]
    MON --> |"ap_write (per complete write)"| WR["Subscribers:<br/>scoreboard<br/>RAL predictor<br/>functional coverage"]
    MON --> |"ap_read  (per complete read)"| RD["Subscribers:<br/>scoreboard<br/>RAL read predictor"]
```

---

## Write Transaction Monitoring Flow

```mermaid
sequenceDiagram
    participant DUT
    participant Monitor as "evm_axi_lite_monitor"
    participant Scoreboard
    participant Predictor as "evm_axi_lite_write_predictor"

    DUT->>Monitor: AW handshake (awvalid+awready)
    Note over Monitor: Capture AW channel
    Monitor->>Monitor: create aw_txn (addr, prot)
    Monitor->>Monitor: ap_aw.write(aw_txn)

    Note over Monitor: Fork: wait for W channel (may arrive before/after AW)
    DUT->>Monitor: W handshake (wvalid+wready)
    Monitor->>Monitor: create w_txn (data, strb)
    Monitor->>Monitor: ap_w.write(w_txn)

    DUT->>Monitor: B handshake (bvalid+bready)
    Monitor->>Monitor: create b_txn (resp)
    Monitor->>Monitor: ap_b.write(b_txn)

    Note over Monitor: Compose write_txn from AW+W+B
    Monitor->>Scoreboard: ap_write.write(write_txn)
    Monitor->>Predictor: ap_write.write(write_txn)
```

---

## Agent Modes

```mermaid
graph TD
    AGENT[evm_axi_lite_master_agent]

    AGENT --> M[EVM_AXI_ACTIVE_MASTER<br/>Driver + Monitor<br/>Initiates AXI transactions]
    AGENT --> S[EVM_AXI_ACTIVE_SLAVE<br/>Slave driver + Monitor<br/>Responds to AXI transactions]
    AGENT --> P[EVM_AXI_PASSIVE<br/>Monitor only<br/>Observes bus silently]

    M --> |"use_sequencer=0"| DC[Direct call API<br/>write/read/rmw/poll]
    M --> |"use_sequencer=1"| SQ[Sequence-based<br/>execute_sequence]
```

---

## RAL Predictor Integration

```mermaid
graph LR
    DRV["AXI-Lite Driver"]
    DUT["DUT"]
    MON["AXI-Lite Monitor"]
    WPred["evm_axi_lite_write_predictor"]
    RPred["evm_axi_lite_read_predictor"]
    MAP["evm_reg_map"]
    RAL["evm_reg_block (RAL)"]

    DRV -->|"AXI write"| DUT
    DUT -->|"AXI bus"| MON
    MON -->|"ap_write"| WPred
    MON -->|"ap_read"| RPred
    WPred -->|"get_reg_by_address"| MAP
    RPred -->|"get_reg_by_address"| MAP
    MAP --> RAL
    WPred -->|"reg.predict(data, 0)"| RAL
    RPred -->|"check vs mirror"| RAL
```
