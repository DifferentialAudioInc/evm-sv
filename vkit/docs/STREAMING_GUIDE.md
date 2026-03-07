# EVM Streaming vs Transaction-Based Architecture Guide

**Copyright (c) 2026 Differential Audio Inc**  
**Version:** 1.0  
**Date:** 2026-03-07

---

## Table of Contents

1. [Overview](#overview)
2. [When to Use Each Model](#when-to-use-each-model)
3. [Transaction-Based Agents](#transaction-based-agents)
4. [Streaming-Based Agents](#streaming-based-agents)
5. [Comparison Table](#comparison-table)
6. [Implementation Examples](#implementation-examples)
7. [Best Practices](#best-practices)

---

## Overview

EVM uniquely supports **two verification models** to match real hardware architectures:

### Transaction-Based (Protocol-Driven)
- **Discrete operations** with handshakes
- **Sequencer-driven** for controlled stimulus
- **Examples:** AXI, APB, SPI, UART, I2C

### Streaming-Based (Clock-Cycle Driven)
- **Continuous data** without handshakes
- **File-driven** with Python integration
- **Examples:** ADC, DAC, PDM, High-speed serial

Both models coexist in the same framework and can be used simultaneously in a single test.

---

## When to Use Each Model

### Use Transaction-Based When:

✅ **Protocol has handshaking**
- Valid/ready signals
- Request/acknowledge
- Enable/busy

✅ **Discrete operations**
- Register reads/writes
- Command/response pairs
- Packet transmission

✅ **Controlled timing needed**
- Specific inter-transaction delays
- Randomized stimulus
- Back-pressure testing

✅ **Examples:**
- AXI/AXI-Lite for CSR access
- APB for peripheral configuration
- SPI for sensor communication
- UART for debugging interfaces

### Use Streaming-Based When:

✅ **Continuous data streams**
- No handshaking
- Clock-synchronous
- Every-cycle valid

✅ **Signal processing**
- ADC data capture
- DAC output generation
- Audio/video streams
- RF I/Q data

✅ **Python integration needed**
- Complex waveform generation (numpy, scipy)
- FFT/spectrum analysis
- SNR/THD measurements
- Eye diagram analysis

✅ **Examples:**
- Multi-channel ADC interfaces
- DAC output for audio
- PDM microphone data
- High-speed serial data (deserializer output)

---

## Transaction-Based Agents

### Architecture

```
Test
  └─> Sequence
       └─> Sequence Items (transactions)
            └─> Sequencer (arbiter/scheduler)
                 └─> Driver (protocol executor)
                      └─> Interface (with handshakes)
```

### Key Classes

**`evm_sequence_item`** - Single transaction
```systemverilog
class axi_lite_item extends evm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        read_write;  // 0=read, 1=write
    
    // Transaction delays, errors, etc.
endclass
```

**`evm_sequence`** - Collection of items
```systemverilog
class config_sequence extends evm_sequence;
    virtual task body();
        // Create and send transactions
        axi_lite_item item = new();
        item.read_write = 1;  // Write
        item.addr = 32'h1000;
        item.data = 32'hDEADBEEF;
        send_item(item);
    endtask
endclass
```

**`evm_sequencer`** - Arbitrates and schedules
```systemverilog
class axi_lite_sequencer extends evm_sequencer;
    mailbox #(axi_lite_item) item_mbx;
    // Handles sequence execution
endclass
```

**`evm_driver`** - Executes protocol
```systemverilog
class axi_lite_driver extends evm_driver;
    task execute_write(axi_lite_item item);
        @(posedge vif.clk);
        vif.awvalid <= 1'b1;
        vif.awaddr <= item.addr;
        wait(vif.awready);
        @(posedge vif.clk);
        vif.awvalid <= 1'b0;
        // ... complete write transaction
    endtask
endclass
```

### Usage Example

```systemverilog
class axi_config_test extends base_test;
    virtual task main_phase();
        axi_lite_sequence cfg_seq = new();
        cfg_seq.add_write(32'h1000, 32'h00000001);  // Enable
        cfg_seq.add_write(32'h1004, 32'h12345678);  // Config
        cfg_seq.add_read(32'h1008);                 // Status
        cfg_seq.execute(axi_agent.sequencer);
    endtask
endclass
```

---

## Streaming-Based Agents

### Architecture

```
Python Generator    →  Streaming Driver  →  DUT
(numpy/scipy)           (reads file)         
   ↓                                          ↓
stimulus.txt                              DUT Output
                                              ↓
                          Streaming Monitor  →  capture.txt
                          (writes file)         ↓
                                           Python Analysis
                                           (FFT, metrics)
```

### Key Classes

**`evm_stream_cfg`** - Configuration
```systemverilog
class evm_stream_cfg extends evm_object;
    string stimulus_file = "stimulus.txt";
    string capture_file = "capture.txt";
    real   sample_rate_hz = 100e6;
    int    bit_width = 16;
    int    num_channels = 1;
    bit    loop_mode = 0;
    string signal_type = "sine";
    real   signal_freq_hz = 10e6;
endclass
```

**`evm_stream_driver`** - File-based stimulus
```systemverilog
class evm_stream_driver extends evm_driver;
    real samples[$][$];  // [channel][sample]
    
    function void load_stimulus();
        // Read samples from file
        file_handle = $fopen(cfg.stimulus_file, "r");
        // Parse and store samples
    endfunction
    
    task stream_samples();
        forever begin
            @(posedge vif.clk);
            // Output sample every clock
            vif.data[ch] <= samples[ch][sample_index];
            vif.valid[ch] <= 1'b1;
            sample_index++;
        end
    endtask
endclass
```

**`evm_stream_monitor`** - File-based capture
```systemverilog
class evm_stream_monitor extends evm_monitor;
    int file_handle;
    
    task capture_samples();
        file_handle = $fopen(cfg.capture_file, "w");
        forever begin
            @(posedge vif.clk);
            if (vif.valid[ch]) begin
                // Write sample to file
                $fwrite(file_handle, "%.9f, %.6f\n", time, sample);
            end
        end
    endtask
endclass
```

**`evm_stream_agent`** - Complete agent
```systemverilog
class evm_stream_agent extends evm_agent;
    evm_stream_cfg cfg;
    
    function void generate_stimulus();
        // Call Python script to generate stimulus
        string cmd = cfg.get_python_gen_cmd();
    endfunction
endclass
```

**`evm_stream_if`** - Generic interface
```systemverilog
interface evm_stream_if #(
    parameter DATA_WIDTH = 16,
    parameter NUM_CHANNELS = 1
);
    logic clk;
    logic [NUM_CHANNELS-1:0][DATA_WIDTH-1:0] data;
    logic [NUM_CHANNELS-1:0] valid;
endinterface
```

### Usage Example

```systemverilog
class adc_sine_test extends base_test;
    virtual function void build_phase();
        super.build_phase();
        
        // Configure streaming agent
        adc_agent.cfg.stimulus_file = "adc_10mhz_sine.txt";
        adc_agent.cfg.sample_rate_hz = 100e6;
        adc_agent.cfg.signal_freq_hz = 10e6;
        adc_agent.cfg.loop_mode = 1;
    endfunction
    
    virtual task main_phase();
        // Stream runs automatically
        #100us;
    endtask
endclass
```

---

## Comparison Table

| Aspect | Transaction-Based | Streaming-Based |
|--------|-------------------|-----------------|
| **Data Flow** | Discrete transactions | Continuous stream |
| **Handshaking** | Required (valid/ready) | Not required |
| **Timing** | Controlled by sequence | Every clock cycle |
| **Stimulus** | Randomized items | File-based waveforms |
| **Driver** | Protocol executor | File reader |
| **Monitor** | Transaction capture | Sample-by-sample capture |
| **Sequencer** | Yes | No (not needed) |
| **Python** | Not typically used | Heavily integrated |
| **Use Cases** | CSR, protocols | ADC/DAC, streaming data |
| **Complexity** | Medium-High | Low-Medium |
| **Performance** | Good for sparse ops | Optimized for continuous |

---

## Implementation Examples

### Example 1: Pure Streaming Test

```systemverilog
//==============================================================================
// ADC Streaming Test - Pure streaming, no transactions
//==============================================================================

class adc_stream_test extends base_test;
    evm_stream_agent adc_agent;
    
    virtual function void build_phase();
        super.build_phase();
        
        // Create streaming agent
        adc_agent = new("adc_agent", this);
        adc_agent.cfg.stimulus_file = "stim/adc_chirp.txt";
        adc_agent.cfg.capture_file = "results/adc_capture.txt";
        adc_agent.cfg.sample_rate_hz = 100e6;
        adc_agent.cfg.num_channels = 4;
        adc_agent.cfg.loop_mode = 0;  // One-shot
        
        // Set virtual interface
        adc_agent.set_vif(adc_vif);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        log_info("Starting ADC streaming test", EVM_LOW);
        
        // Wait for stream to complete
        #200us;
        
        log_info($sformatf("Captured %0d samples", 
                 adc_agent.get_monitor().get_sample_count()), EVM_LOW);
        
        drop_objection("test");
    endtask
    
    virtual function void final_phase();
        super.final_phase();
        // Run Python analysis
        adc_agent.analyze_capture();
    endfunction
endclass
```

### Example 2: Mixed Transaction + Streaming Test

```systemverilog
//==============================================================================
// Mixed Test - Configure DUT via AXI, then stream data
//==============================================================================

class mixed_test extends base_test;
    axi_lite_agent  axi_agent;
    evm_stream_agent adc_agent;
    evm_stream_agent dac_agent;
    
    virtual function void build_phase();
        super.build_phase();
        
        // Transaction-based agent for configuration
        axi_agent = new("axi_agent", this);
        axi_agent.set_vif(axi_vif);
        
        // Streaming agents for data
        adc_agent = new("adc_agent", this);
        adc_agent.cfg.stimulus_file = "stim/adc_data.txt";
        adc_agent.cfg.loop_mode = 1;
        adc_agent.set_vif(adc_vif);
        
        dac_agent = new("dac_agent", this);
        dac_agent.cfg.capture_file = "results/dac_out.txt";
        dac_agent.set_mode(EVM_PASSIVE);  // Monitor only
        dac_agent.set_vif(dac_vif);
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        fork
            // Thread 1: Configure DUT via AXI transactions
            begin
                axi_config_sequence cfg_seq = new();
                cfg_seq.add_write(32'h1000, 32'h0000000F);  // Enable all channels
                cfg_seq.add_write(32'h1004, 32'h00000005);  // Sample rate
                cfg_seq.add_write(32'h2000, 32'h00001000);  // FFT config
                cfg_seq.execute(axi_agent.sequencer);
                
                log_info("DUT configured", EVM_LOW);
            end
            
            // Thread 2: Stream ADC data (automatic)
            // Thread 3: Capture DAC data (automatic)
            
            // Thread 4: Wait for completion
            begin
                #500us;
            end
        join
        
        drop_objection("test");
    endtask
endclass
```

### Example 3: Python Integration

```systemverilog
//==============================================================================
// Test with Python-Generated Stimulus
//==============================================================================

class python_generated_test extends base_test;
    evm_stream_agent adc_agent;
    
    virtual function void build_phase();
        super.build_phase();
        
        adc_agent = new("adc_agent", this);
        
        // Configure Python generation
        adc_agent.cfg.stimulus_file = "gen/adc_multi_tone.txt";
        adc_agent.cfg.python_gen_script = "python/gen_stimulus.py";
        adc_agent.cfg.signal_type = "multi_tone";
        adc_agent.cfg.signal_freq_hz = 10e6;
        adc_agent.cfg.sample_rate_hz = 100e6;
        adc_agent.cfg.duration_sec = 100e-6;
        
        // Configure Python analysis
        adc_agent.cfg.capture_file = "results/dac_capture.txt";
        adc_agent.cfg.python_analyze_script = "python/analyze_spectrum.py";
        
        adc_agent.set_vif(adc_vif);
    endfunction
    
    virtual task pre_main_phase();
        super.pre_main_phase();
        // Generate stimulus before simulation starts
        adc_agent.generate_stimulus();
    endtask
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        #200us;
        drop_objection("test");
    endtask
    
    virtual function void final_phase();
        super.final_phase();
        // Analyze results after simulation
        adc_agent.analyze_capture();
    endfunction
endclass
```

---

## Best Practices

### For Transaction-Based Agents:

1. **Use sequences for reusability**
   - Create a library of common sequences
   - Compose complex scenarios from simple sequences

2. **Randomize intelligently**
   - Constrain for valid scenarios
   - Use coverage to guide randomization

3. **Separate concerns**
   - Sequence: WHAT to do
   - Sequencer: WHEN to do it
   - Driver: HOW to do it

4. **Handle back-pressure**
   - Implement ready/valid handshaking properly
   - Test flow control scenarios

### For Streaming-Based Agents:

1. **Use Python for complex waveforms**
   - Leverage numpy/scipy ecosystem
   - Generate realistic test vectors

2. **Choose appropriate file formats**
   - Text for debugging (human-readable)
   - Binary for performance (large datasets)

3. **Buffer management**
   - Pre-load files for performance
   - Use loop mode for continuous operation

4. **Analysis automation**
   - Run Python analysis in final_phase
   - Generate plots and metrics automatically

### For Mixed Tests:

1. **Separate initialization from streaming**
   - Configure DUT with transactions
   - Then start streaming data

2. **Use fork/join for concurrency**
   - Run configuration and streaming in parallel
   - Coordinate with objections

3. **Monitor both paths**
   - Transaction monitor for CSR accesses
   - Stream monitor for data flow

4. **Realistic scenarios**
   - Mimic real system behavior
   - Configuration changes during streaming

---

## Summary

EVM's dual-model architecture provides the flexibility to match your verification needs:

- **Transaction-based** for control interfaces with protocols
- **Streaming-based** for continuous data with Python integration
- **Both models** can coexist in the same test

Choose the right model for each interface in your design, and use both together for complete system-level verification.

---

**Copyright (c) 2026 Differential Audio Inc**  
Part of the EVM (Embedded Verification Module) Framework  
Repository: https://github.com/DifferentialAudioInc/evm-sv
