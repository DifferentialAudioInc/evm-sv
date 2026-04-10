# EVM Protocol Agents

**Author:** Eric Dyer (Differential Audio Inc.)  
**Last Updated:** 2026-04-09  

---

## Agent Pattern Overview

Every EVM agent follows the same pattern:

```
evm_component
  └── evm_agent (base wrapper)
        ├── driver    — drives signals onto the interface (ACTIVE only)
        ├── monitor   — observes the interface (always present)
        └── sequencer — dispatches sequences to driver (optional)
```

**Modes:**
- `EVM_ACTIVE` — has driver + monitor. Agent can initiate transactions.
- `EVM_PASSIVE` — monitor only. Agent observes but does not drive.

**VIF assignment (always explicit):**
```systemverilog
agent.set_vif(my_vif);  // propagates to driver and monitor
```

---

## AXI4-Lite Master Agent

**Use for:** CSR register access, doorbell writes, control/status polling.

**File:** `vkit/evm_vkit/evm_axi_lite_agent/`

### Monitor Analysis Ports

The AXI-Lite monitor publishes transactions at **two granularities**:

**Channel-level** (fires on each AXI handshake):
```
ap_aw   → evm_axi_lite_aw_txn    (AW channel: addr, prot, timestamp)
ap_w    → evm_axi_lite_w_txn     (W  channel: data, strb, timestamp)
ap_b    → evm_axi_lite_b_txn     (B  channel: resp, timestamp)
ap_ar   → evm_axi_lite_ar_txn    (AR channel: addr, prot, timestamp)
ap_r    → evm_axi_lite_r_txn     (R  channel: data, resp, timestamp)
```

**Composite** (fires on complete transaction):
```
ap_write → evm_axi_lite_write_txn   (AW+W+B combined, + write latency)
ap_read  → evm_axi_lite_read_txn    (AR+R combined, + read latency)
```

### Direct API (no sequencer needed)

```systemverilog
evm_axi_lite_master_agent agent = new("agent", this);
agent.set_vif(axi_lite_if);

// Write / read
logic [1:0] resp;
agent.write(32'h1000, 32'hDEAD_BEEF, 4'b1111, resp);
logic [31:0] rdata;
agent.read(32'h1000, rdata, resp);

// Write with automatic error checking
agent.write_check(32'h1004, 32'h0000_0001);

// Read-Modify-Write
agent.rmw(32'h1000, 32'h0000_00FF, 32'h0000_0042);  // mask, value

// Poll until condition (or timeout)
bit success;
agent.poll(32'h1008, 32'h0000_0003, 32'h0000_0000, 5000, success);
```

### Sequencer-Based API (optional)

Enable in config:
```systemverilog
evm_axi_lite_cfg cfg = new();
cfg.use_sequencer = 1;       // default: 0 (backward compatible)
evm_axi_lite_master_agent agent = new("agent", this);
agent.cfg = cfg;
```

Then use `agent.sequencer.execute_sequence(my_csr_seq)` for sequence-driven stimulus.

### Configuration

```systemverilog
evm_axi_lite_cfg cfg;
cfg.mode              = EVM_AXI_ACTIVE_MASTER;  // or ACTIVE_SLAVE, PASSIVE
cfg.use_sequencer     = 0;   // enable sequencer-based stimulus
cfg.master_delay_min  = 0;   // inter-transaction delay (cycles)
cfg.master_delay_max  = 2;
cfg.back_to_back_pct  = 80;  // % chance of back-to-back (no delay)
cfg.awready_delay_min = 0;   // AW ready assertion delay
cfg.awready_delay_max = 1;
// ... similar for ar/w/r/b ready delays
```

### Interface

```systemverilog
// In tb_top:
evm_axi_lite_if axi_lite_if(.aclk(clk), .aresetn(rst_n));
// Connect to DUT...
agent.set_vif(axi_lite_if);
```

### Connection Examples

```systemverilog
// Scoreboard receives complete writes from this agent's monitor:
agent.monitor.ap_write.connect(scoreboard.analysis_imp.get_mailbox());

// RAL predictor auto-updates mirror on observed writes:
agent.monitor.ap_write.connect(predictor.analysis_imp.get_mailbox());

// Protocol checker watches individual channel completions:
agent.monitor.ap_aw.connect(proto_checker.aw_imp.get_mailbox());
agent.monitor.ap_b.connect(proto_checker.b_imp.get_mailbox());

// Bandwidth monitor counts data beats:
agent.monitor.ap_r.connect(bw_monitor.r_imp.get_mailbox());
```

---

## AXI4 Full Master Agent

**Use for:** DMA data transfers, burst memory reads/writes, AXI4-compliant IP.

**File:** `vkit/evm_vkit/evm_axi4_full_agent/`

**Interface parameters** (must match DUT):
```systemverilog
evm_axi4_full_if #(
    .DATA_WIDTH(64),   // data bus width in bits
    .ADDR_WIDTH(32),   // address width
    .ID_WIDTH(8)       // transaction ID width
) axi4_full_if(.aclk(clk), .aresetn(rst_n));
```

### Monitor Analysis Ports

Same 7-port pattern as AXI-Lite, but with burst fields:

**Channel-level** (one per AXI handshake):
```
ap_aw   → evm_axi4_aw_txn    (id, addr, len, size, burst, lock, cache, prot, qos)
ap_w    → evm_axi4_w_txn     (data, strb, last, beat_num)  — one per beat
ap_b    → evm_axi4_b_txn     (id, resp)
ap_ar   → evm_axi4_ar_txn    (id, addr, len, size, burst, ...)
ap_r    → evm_axi4_r_txn     (id, data, resp, last, beat_num)  — one per beat
```

**Composite** (fires on complete burst):
```
ap_write → evm_axi4_write_txn   (AW + all W beats + B; data[$], strb[$])
ap_read  → evm_axi4_read_txn    (AR + all R beats; data[$], resp[$])
```

**Composite transaction helpers:**
```systemverilog
write_txn.get_num_beats()      // int'(len) + 1
write_txn.get_byte_count()     // beats × (2^size)
write_txn.get_write_latency()  // b_time_ns - aw_time_ns
read_txn.get_read_latency()    // last_r_time_ns - ar_time_ns
```

### Direct API

```systemverilog
evm_axi4_full_master_agent agent = new("agent", this, cfg);
agent.set_vif(axi4_full_if);

// Single-beat operations (convenience wrappers)
logic [1:0]  resp;
logic [63:0] rdata;
agent.write_single(32'h2000, 64'hDEAD_BEEF_CAFE_1234, resp);
agent.read_single(32'h2000, rdata, resp);

// Burst operations
logic [63:0] wdata[8];
logic [1:0]  wresps;
foreach (wdata[i]) wdata[i] = 64'h0 + i;
agent.write_burst(
    32'h3000,      // addr
    wdata,         // data[]
    resp,          // response
    8'h07,         // len (7 = 8 beats)
    3'b011,        // size (8 bytes per beat = 64-bit)
    2'b01          // burst type INCR
);

logic [63:0] rdata_burst[];
logic [1:0]  rresps[];
agent.read_burst(32'h3000, rdata_burst, 8'h07, rresps);
```

### Configuration

```systemverilog
evm_axi4_full_cfg cfg = new();
cfg.is_active          = 1;        // 1=active (driver), 0=passive (monitor only)
cfg.default_burst      = 2'b01;    // INCR (01), FIXED (00), WRAP (10)
cfg.default_prot       = 3'b000;   // non-secure, unprivileged, data
cfg.default_cache      = 4'b0010;  // normal non-cacheable
cfg.aw_delay_cycles    = 0;        // AW channel assertion delay
cfg.ar_delay_cycles    = 0;        // AR channel assertion delay
cfg.w_beat_delay       = 0;        // delay between W beats
cfg.always_bready      = 1;        // keep bready asserted (no backpressure)
cfg.always_rready      = 1;        // keep rready asserted
```

---

## Clock Agent

**Use for:** Generating the DUT clock signal.

```systemverilog
evm_clk_agent clk_agent = new("clk_agent", this);
clk_agent.set_vif(clk_if);
clk_agent.cfg.freq_mhz = 100;     // 100 MHz
clk_agent.cfg.duty_cycle = 50;    // 50%
```

---

## Reset Agent

**Use for:** Driving DUT reset sequences.

```systemverilog
evm_rst_agent rst_agent = new("rst_agent", this);
rst_agent.set_vif(rst_if);
rst_agent.cfg.rst_duration_cycles = 10;    // hold reset for 10 cycles
rst_agent.cfg.active_low = 1;              // aresetn style
```

Mid-simulation reset (use EVM's built-in reset events instead for component coordination):
```systemverilog
// In test reset_phase or main_phase:
env.assert_reset();       // notifies all monitors/scoreboards/drivers
rst_agent.apply_reset();  // actually drives the reset signal
env.deassert_reset();     // notifies all components reset is over
```

---

## ADC Agent

**Use for:** Streaming ADC stimulus data from Python-generated files.

```systemverilog
evm_adc_agent adc_agent = new("adc_agent", this);
adc_agent.cfg.stimulus_file = "stimulus/sine_1mhz.txt";
adc_agent.cfg.sample_rate_hz = 100_000_000;
adc_agent.cfg.loop_mode = 1;  // loop forever
adc_agent.cfg.num_channels = 4;
```

Generate stimulus with Python:
```bash
python python/gen_stimulus.py --type sine --freq 1e6 --fs 100e6 --output stimulus/sine_1mhz.txt
```

---

## DAC Agent

**Use for:** Capturing streaming DAC output for Python analysis.

```systemverilog
evm_dac_agent dac_agent = new("dac_agent", this);
dac_agent.cfg.capture_file = "capture/dac_out.txt";
dac_agent.cfg.max_capture_samples = 16384;
```

Analyze output with Python:
```bash
python python/analyze_spectrum.py capture/dac_out.txt --fs 100e6 --freq 1e6 --plot
```

---

## GPIO Agent

**Use for:** Controlling digital I/O signals (LEDs, buttons, interrupts).

```systemverilog
evm_gpio_agent gpio = new("gpio", this);
gpio.set_pin(0, 1);           // pin 0 high
gpio.set_pins(32'h0000_000F); // lower 4 bits high
gpio.toggle_pin(2);           // toggle pin 2
```

---

## PCIe Agent

**Use for:** Simple memory-mapped BFM for PCIe endpoint testing.

```systemverilog
evm_pcie_agent pcie = new("pcie", this);
pcie.mem_write(64'h0000_0000_0000_1000, 32'hDEAD_BEEF);
pcie.mem_read(64'h0000_0000_0000_1000, data);
```

---

## Building a Custom Agent

Template for a new agent:

```systemverilog
// my_agent.sv
class my_agent extends evm_component;
    my_driver     driver;
    my_monitor    monitor;
    my_cfg        cfg;
    virtual my_if vif;
    bit           is_active = 1;
    
    function new(string name, evm_component parent, my_cfg cfg = null);
        super.new(name, parent);
        this.cfg = (cfg != null) ? cfg : new("cfg");
    endfunction
    
    virtual function void build_phase();
        super.build_phase();
        monitor = new("monitor", this, cfg);
        if (is_active) driver = new("driver", this, cfg);
    endfunction
    
    virtual function void connect_phase();
        super.connect_phase();
        if (vif == null) begin
            log_error("VIF not set");
            return;
        end
        monitor.set_vif(vif);
        if (driver != null) driver.set_vif(vif);
    endfunction
    
    function void set_vif(virtual my_if vif_h);
        this.vif = vif_h;
        if (monitor != null) monitor.set_vif(vif_h);
        if (driver  != null) driver.set_vif(vif_h);
    endfunction
endclass

// my_monitor.sv — extends evm_monitor, uses run_phase
class my_monitor extends evm_monitor#(virtual my_if, my_txn);
    virtual task run_phase();
        super.run_phase();  // starts reset monitoring thread
        if (vif == null) return;
        fork
            forever begin
                if (in_reset) begin @(reset_deasserted); continue; end
                @(posedge vif.clk);
                if (vif.valid && vif.ready) begin
                    my_txn txn = new("txn");
                    txn.data = vif.data;
                    analysis_port.write(txn);   // broadcast to scoreboard etc.
                end
            end
        join_none
    endtask
endclass

// my_driver.sv — extends evm_driver, uses main_phase
class my_driver extends evm_driver#(virtual my_if);
    virtual task main_phase();
        super.main_phase();
        forever begin
            if (in_reset) begin @(reset_deasserted); continue; end
            // drive signals...
            @(posedge vif.clk);
        end
    endtask
    
    virtual task on_reset_assert();
        super.on_reset_assert();
        vif.valid <= 0;  // idle bus during reset
    endtask
endclass
```

---

## See Also

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — Framework architecture, TLM, phases
- [`REGISTER_MODEL.md`](REGISTER_MODEL.md) — RAL predictor connection to AXI-Lite monitor
- [`../vkit/docs/uml/04_agents_axi_lite.md`](../vkit/docs/uml/04_agents_axi_lite.md) — UML diagrams
- [`../vkit/docs/uml/05_agents_axi4_full.md`](../vkit/docs/uml/05_agents_axi4_full.md) — AXI4 Full UML
