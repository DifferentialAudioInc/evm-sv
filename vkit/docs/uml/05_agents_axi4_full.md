# EVM AXI4 Full Agent

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## AXI4 Full Agent Class Hierarchy

```mermaid
classDiagram
    class evm_axi4_full_master_agent {
        +evm_axi4_full_cfg cfg
        +evm_axi4_full_master_driver driver
        +evm_axi4_full_monitor monitor
        +virtual evm_axi4_full_if vif
        +write_single(addr, data, resp)*
        +write_burst(addr, data, resp, len, size, burst)*
        +read_single(addr, data, resp)*
        +read_burst(addr, data, len, resp)*
        +set_vif(vif)
        +build_phase()
        +connect_phase()
    }

    class evm_axi4_full_master_driver {
        +evm_axi4_full_cfg cfg
        +int write_count
        +int read_count
        +int write_beat_count
        +int read_beat_count
        +write_single(addr, data, id, strb, resp)*
        +write_burst(addr, data, strb, len, size, burst, id, resp)*
        +read_single(addr, data, id, resp)*
        +read_burst(addr, data, len, size, burst, id, resp)*
        +run_phase()
        +on_reset_assert()
    }

    class evm_axi4_full_monitor {
        +evm_axi4_full_cfg cfg
        +evm_analysis_port~evm_axi4_aw_txn~ ap_aw
        +evm_analysis_port~evm_axi4_w_txn~ ap_w
        +evm_analysis_port~evm_axi4_b_txn~ ap_b
        +evm_analysis_port~evm_axi4_ar_txn~ ap_ar
        +evm_analysis_port~evm_axi4_r_txn~ ap_r
        +evm_analysis_port~evm_axi4_write_txn~ ap_write
        +evm_analysis_port~evm_axi4_read_txn~ ap_read
        +int writes_observed
        +int reads_observed
        +int write_beats_total
        +int read_beats_total
        +run_phase()
        +on_reset_assert()
    }

    class evm_axi4_full_cfg {
        +int data_width
        +int addr_width
        +int id_width
        +bit is_active
        +logic[1:0] default_burst
        +logic[2:0] default_prot
        +logic[3:0] default_cache
        +int aw_delay_cycles
        +int ar_delay_cycles
        +int w_beat_delay
        +bit always_bready
        +bit always_rready
        +get_default_size() logic[2:0]
    }

    evm_axi4_full_master_agent --|> evm_component : extends
    evm_axi4_full_master_driver --|> evm_driver : extends
    evm_axi4_full_monitor --|> evm_monitor : extends
    evm_axi4_full_master_agent o-- evm_axi4_full_master_driver
    evm_axi4_full_master_agent o-- evm_axi4_full_monitor
    evm_axi4_full_master_agent o-- evm_axi4_full_cfg
```

---

## Transaction Types

### Channel-Level (one per AXI handshake)

```mermaid
classDiagram
    class evm_axi4_aw_txn {
        +logic[7:0]  id
        +logic[31:0] addr
        +logic[7:0]  len
        +logic[2:0]  size
        +logic[1:0]  burst
        +logic[2:0]  prot
        +realtime     time_ns
        +get_num_beats() int
        +burst_type_str() string
    }

    class evm_axi4_w_txn {
        +logic[63:0] data
        +logic[7:0]  strb
        +logic        last
        +int          beat_num
        +realtime     time_ns
    }

    class evm_axi4_b_txn {
        +logic[7:0]  id
        +logic[1:0]  resp
        +realtime     time_ns
        +is_okay() bit
    }

    class evm_axi4_ar_txn {
        +logic[7:0]  id
        +logic[31:0] addr
        +logic[7:0]  len
        +logic[2:0]  size
        +logic[1:0]  burst
        +logic[2:0]  prot
        +realtime     time_ns
        +get_num_beats() int
    }

    class evm_axi4_r_txn {
        +logic[7:0]  id
        +logic[63:0] data
        +logic[1:0]  resp
        +logic        last
        +int          beat_num
        +realtime     time_ns
        +is_okay() bit
    }

    evm_axi4_aw_txn --|> evm_object
    evm_axi4_w_txn  --|> evm_object
    evm_axi4_b_txn  --|> evm_object
    evm_axi4_ar_txn --|> evm_object
    evm_axi4_r_txn  --|> evm_object
```

### Composite (one per complete burst transaction)

```mermaid
classDiagram
    class evm_axi4_write_txn {
        +logic[7:0]  id
        +logic[31:0] addr
        +logic[7:0]  len
        +logic[2:0]  size
        +logic[1:0]  burst
        +logic[63:0] data[$]
        +logic[7:0]  strb[$]
        +logic[1:0]  resp
        +realtime     aw_time_ns
        +realtime     last_w_time_ns
        +realtime     b_time_ns
        +get_num_beats() int
        +get_byte_count() int
        +get_write_latency() realtime
        +is_okay() bit
    }

    class evm_axi4_read_txn {
        +logic[7:0]  id
        +logic[31:0] addr
        +logic[7:0]  len
        +logic[2:0]  size
        +logic[1:0]  burst
        +logic[63:0] data[$]
        +logic[1:0]  resp[$]
        +realtime     ar_time_ns
        +realtime     last_r_time_ns
        +get_num_beats() int
        +get_byte_count() int
        +get_read_latency() realtime
        +all_okay() bit
    }

    evm_axi4_write_txn --|> evm_object
    evm_axi4_read_txn  --|> evm_object
```

---

## Write Burst Sequence Diagram

```mermaid
sequenceDiagram
    participant Test
    participant Driver as "evm_axi4_full_master_driver"
    participant DUT
    participant Monitor as "evm_axi4_full_monitor"

    Test->>Driver: write_burst(addr, data[8], len=7)
    Note over Driver: fork AW + W channels

    Driver->>DUT: AW handshake (id, addr, len=7, size=3, burst=INCR)
    Monitor->>Monitor: capture → ap_aw (evm_axi4_aw_txn)

    loop 8 beats
        Driver->>DUT: W beat N (data, strb, wlast on beat 7)
        Monitor->>Monitor: capture → ap_w (evm_axi4_w_txn, beat_num=N)
    end
    Note over Driver: join

    DUT->>Driver: B handshake (id, resp=OKAY)
    Monitor->>Monitor: capture → ap_b (evm_axi4_b_txn)
    Note over Monitor: Compose write_txn (all 8 beats)
    Monitor->>Monitor: ap_write.write(evm_axi4_write_txn)
```

---

## Interface Parameters

```mermaid
graph TD
    IF["evm_axi4_full_if #(DATA_WIDTH, ADDR_WIDTH, ID_WIDTH)"]

    IF --> AW["Write Address Channel (AW)<br/>awid, awaddr, awlen, awsize, awburst<br/>awlock, awcache, awprot, awqos<br/>awvalid, awready"]
    IF --> W["Write Data Channel (W)<br/>wdata[DATA_WIDTH], wstrb[DATA_WIDTH/8]<br/>wlast, wvalid, wready"]
    IF --> B["Write Response Channel (B)<br/>bid[ID_WIDTH], bresp<br/>bvalid, bready"]
    IF --> AR["Read Address Channel (AR)<br/>arid, araddr, arlen, arsize, arburst<br/>arlock, arcache, arprot, arqos<br/>arvalid, arready"]
    IF --> R["Read Data Channel (R)<br/>rid[ID_WIDTH], rdata[DATA_WIDTH]<br/>rresp, rlast, rvalid, rready"]

    IF --> MODS["Modports:<br/>master (driver)<br/>slave (responder)<br/>monitor (passive)"]
    IF --> ASSERTS["Protocol Assertions:<br/>AWVALID stable until AWREADY<br/>WVALID stable until WREADY<br/>ARVALID stable until ARREADY"]
```

---

## Burst Type Reference

```mermaid
graph LR
    BT[AXI Burst Types]
    BT --> FIXED["FIXED (2'b00)<br/>All beats same address<br/>e.g., FIFO access"]
    BT --> INCR["INCR (2'b01)<br/>Address increments per beat<br/>Normal DMA / memory"]
    BT --> WRAP["WRAP (2'b10)<br/>Address wraps at boundary<br/>Cache line fills"]
```

**AWSIZE / ARSIZE encoding:**
| Value | Bytes per beat |
|---|---|
| 3'b000 | 1 byte |
| 3'b001 | 2 bytes |
| 3'b010 | 4 bytes |
| 3'b011 | 8 bytes (64-bit default) |
| 3'b100 | 16 bytes |
