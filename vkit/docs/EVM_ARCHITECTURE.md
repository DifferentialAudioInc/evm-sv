# EVM Architecture - Dual-Model Verification Framework

**Version:** 2.0  
**Date:** 2026-03-06  
**Author:** Engineering Team

---

## 🎯 Executive Summary

**EVM (Embedded Verification Methodology)** differentiates itself from UVM by natively supporting **both transaction-based AND streaming-based** verification models, specifically targeting embedded systems with:

- **Streaming Interfaces**: ADC/DAC continuous data without handshakes
- **Transaction Interfaces**: CSR config over AXI/APB with sequences
- **Python Integration**: Stimulus generation and signal analysis
- **Lightweight**: Suitable for FPGA/ASIC embedded systems

---

## 📐 Dual-Model Architecture

### Model 1: Transaction-Based Agents (Protocol-Driven)

**Use Cases:** AXI, APB, SPI, I2C, UART - anything with handshakes

```
Test
  └─> Sequence
       └─> Sequence Items
            └─> Sequencer
                 └─> Driver
                      └─> Interface (protocol handshakes)
```

**Components:**
- `evm_sequence_item` - Single transaction (read/write)
- `evm_sequence` - Collection of items with timing
- `evm_sequencer` - Arbitrates and sends items to driver
- `evm_driver` - Executes protocol handshakes
- `evm_monitor` - Captures transactions

### Model 2: Streaming-Based Agents (Clock-Cycle Driven)

**Use Cases:** ADC, DAC, high-speed serial data - continuous streams

```
Python Generator          Streaming Driver          DUT
    (numpy/scipy)              (SV)
         ↓                       ↓                    ↓
   stimulus.txt  ──────>  Read every cycle  ──────> ADC data
                          
DUT Output  ──────>  Streaming Monitor  ──────>  capture.txt
                          (SV)                        ↓
                                               Python Analysis
                                               (FFT, SNR, THD)
```

**Components:**
- `evm_stream_driver` - Reads stimulus file, outputs every clock
- `evm_stream_monitor` - Captures output every clock, writes file
- `evm_stream_cfg` - Sample rate, format, mode configuration
- Python toolchain for generation/analysis

---

## 🐍 Python Integration Strategy

### Recommended Approach: **File-Based with Python Ecosystem**

**Why This Approach?**
1. ✅ **Simple**: No DPI complexity, works with all simulators
2. ✅ **Powerful**: Full Python ecosystem (numpy, scipy, matplotlib)
3. ✅ **Fast**: No runtime overhead during simulation
4. ✅ **Debuggable**: Can inspect intermediate files
5. ✅ **Portable**: Platform-independent

### Alternative Approaches (Not Recommended):

**❌ DPI-C Integration:**
- Complex setup, simulator-specific
- Runtime overhead
- Harder to debug
- Limited portability

**❌ Cocotb:**
- Major framework change
- Different paradigm
- Overkill for embedded systems

### Python Workflow:

```
1. PRE-SIMULATION:
   python gen_adc_stimulus.py --freq 10MHz --samples 10000
   → Creates: adc_ch0.txt, adc_ch1.txt, adc_ch2.txt, adc_ch3.txt

2. SIMULATION:
   vivado -mode batch -source run_sim.tcl
   → Reads stimulus files
   → Streams data to DUT
   → Captures output to dac_out.txt

3. POST-SIMULATION:
   python analyze_dac.py dac_out.txt
   → FFT analysis
   → SNR, THD, SFDR calculations
   → Generates plots: spectrum.png, waveform.png
```

---

## 🏗️ Detailed Architecture

### Transaction-Based Agent Structure

```systemverilog
//==============================================================================
// Transaction Model Components
//==============================================================================

// Base sequence item
class evm_sequence_item extends evm_object;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        read_write;  // 0=read, 1=write
    
    // Constraints, methods, etc.
endclass

// Sequence - collection of items with timing
class evm_sequence extends evm_object;
    evm_sequence_item items[$];
    
    virtual task execute(evm_sequencer sequencer);
        foreach (items[i]) begin
            sequencer.send_item(items[i]);
        end
    endtask
endclass

// Sequencer - arbitrates and schedules items
class evm_sequencer extends evm_component;
    mailbox #(evm_sequence_item) item_mbx;
    
    task send_item(evm_sequence_item item);
        item_mbx.put(item);
    endtask
endclass

// Driver - executes protocol
class evm_axi_driver extends evm_driver;
    evm_sequencer sequencer;
    
    virtual task main_phase();
        forever begin
            evm_sequence_item item;
            sequencer.item_mbx.get(item);
            execute_axi_transaction(item);
        end
    endtask
endclass
```

### Streaming-Based Agent Structure

```systemverilog
//==============================================================================
// Streaming Model Components
//==============================================================================

// Stream configuration
class evm_stream_cfg extends evm_object;
    string  stimulus_file;     // Input file path
    string  capture_file;      // Output file path
    int     sample_rate_hz;    // Sampling rate
    int     bit_width;         // Data width
    bit     complex_data;      // Real or complex samples
    bit     loop_mode;         // Loop or one-shot
    real    interpolation;     // Interpolation factor
endclass

// Stream driver (ADC model)
class evm_stream_driver extends evm_driver#(virtual evm_stream_if);
    evm_stream_cfg cfg;
    int file_handle;
    real samples[$];           // Sample buffer
    int sample_index;
    
    function void load_stimulus();
        file_handle = $fopen(cfg.stimulus_file, "r");
        // Read all samples into buffer
        while (!$feof(file_handle)) begin
            real sample;
            $fscanf(file_handle, "%f\n", sample);
            samples.push_back(sample);
        end
        $fclose(file_handle);
    endfunction
    
    virtual task main_phase();
        load_stimulus();
        sample_index = 0;
        
        forever begin
            @(posedge vif.clk);
            
            // Output current sample
            vif.data <= samples[sample_index];
            vif.valid <= 1'b1;
            
            // Advance index
            sample_index++;
            if (sample_index >= samples.size()) begin
                if (cfg.loop_mode) begin
                    sample_index = 0;  // Loop
                end else begin
                    break;  // Done
                end
            end
        end
    endtask
endclass

// Stream monitor (DAC capture)
class evm_stream_monitor extends evm_monitor#(virtual evm_stream_if);
    evm_stream_cfg cfg;
    int file_handle;
    
    virtual task main_phase();
        file_handle = $fopen(cfg.capture_file, "w");
        
        forever begin
            @(posedge vif.clk);
            
            if (vif.valid) begin
                // Capture sample
                $fwrite(file_handle, "%f\n", real'(vif.data));
            end
        end
    endtask
    
    function void final_phase();
        $fclose(file_handle);
    endfunction
endclass
```

---

## 🔧 Implementation Plan

### Phase 1: Core Infrastructure (Week 1)

**1.1 Transaction Components**
- [ ] `evm_sequence_item.sv` - Base transaction class
- [ ] `evm_sequence.sv` - Sequence container
- [ ] `evm_sequencer.sv` - Item scheduler
- [ ] Update `evm_driver` to support sequencer
- [ ] Update `evm_agent` to create sequencer

**1.2 Streaming Components**
- [ ] `evm_stream_cfg.sv` - Stream configuration
- [ ] `evm_stream_driver.sv` - File-based stimulus driver
- [ ] `evm_stream_monitor.sv` - File-based capture monitor
- [ ] `evm_stream_agent.sv` - Stream agent
- [ ] `evm_stream_if.sv` - Generic streaming interface

### Phase 2: Python Toolchain (Week 2)

**2.1 Stimulus Generation**
- [ ] `gen_stimulus.py` - CLI tool for waveform generation
  - Sine wave, chirp, noise, complex modulation
  - Multiple channels
  - Configurable sample rate, amplitude, frequency
  - Output formats: txt, bin, hex

**2.2 Analysis Tools**
- [ ] `analyze_spectrum.py` - FFT and spectrum analysis
  - FFT with windowing
  - SNR, THD, SFDR, ENOB calculation
  - Plots: time domain, frequency domain
- [ ] `analyze_eye.py` - Eye diagram generation
- [ ] `analyze_iq.py` - IQ constellation plots

**2.3 Integration Scripts**
- [ ] `run_with_python.tcl` - TCL script that calls Python
- [ ] Update `run_sim.tcl` to support Python workflows

### Phase 3: Reference Agents (Week 3)

**3.1 Streaming Agents**
- [ ] `evm_adc_stream_agent` - Multi-channel ADC
- [ ] `evm_dac_stream_agent` - Multi-channel DAC
- [ ] `evm_serdes_stream_agent` - High-speed serial

**3.2 Transaction Agents with Sequences**
- [ ] Update `evm_axi_lite_agent` with sequencer support
- [ ] `axi_lite_sequence_item.sv`
- [ ] `axi_lite_sequence.sv` - Pre-built sequences (burst read/write)

### Phase 4: Documentation and Examples (Week 4)

**4.1 Documentation**
- [ ] Update `EVM_RULES.md` with streaming guidelines
- [ ] Create `STREAMING_GUIDE.md`
- [ ] Create `PYTHON_INTEGRATION.md`
- [ ] Create `SEQUENCE_GUIDE.md`

**4.2 Example Tests**
- [ ] `adc_sine_wave_test.sv` - Basic ADC streaming
- [ ] `dac_fft_test.sv` - DAC capture with FFT analysis
- [ ] `axi_config_sequence_test.sv` - CSR programming
- [ ] `mixed_test.sv` - Streaming + transactions together

---

## 📊 File Formats

### Stimulus File Format (text-based, human-readable)

```
# ADC Stimulus File
# Sample Rate: 100 MHz
# Channels: 4
# Samples per channel: 1000
#
# Format: time, ch0, ch1, ch2, ch3
0.000000, 0.0, 0.0, 0.0, 0.0
0.000010, 0.309, 0.588, 0.809, 0.951
0.000020, 0.588, 0.951, 0.951, 0.588
...
```

### Capture File Format

```
# DAC Capture File
# Sample Rate: 100 MHz
# Start Time: 1.234us
#
# Format: time, data
0.000000, 2047
0.000010, 2048
0.000020, 2049
...
```

---

## 🎨 Usage Examples

### Example 1: Streaming ADC Test

```systemverilog
class adc_sine_test extends base_test;
    
    function void connect_interfaces(...);
        super.connect_interfaces(...);
        
        // Configure streaming agent
        adc_stream_agent.cfg.stimulus_file = "stimulus/adc_10mhz_sine.txt";
        adc_stream_agent.cfg.sample_rate_hz = 100_000_000;
        adc_stream_agent.cfg.loop_mode = 1;
    endfunction
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // Stream runs automatically
        #10us;
        
        drop_objection("test");
    endtask
endclass
```

### Example 2: AXI Sequence Test

```systemverilog
class axi_config_test extends base_test;
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        // Create configuration sequence
        axi_lite_sequence cfg_seq = new("cfg_seq");
        
        // Add register writes
        cfg_seq.add_write(32'h1000, 32'h00000001);  // Enable
        cfg_seq.add_write(32'h1004, 32'h12345678);  // Data
        cfg_seq.add_read (32'h1008);                 // Status
        
        // Execute sequence
        cfg_seq.execute(axi_agent_h.sequencer);
        
        #1us;
        drop_objection("test");
    endtask
endclass
```

### Example 3: Mixed Test (Streaming + Transactions)

```systemverilog
class mixed_test extends base_test;
    
    virtual task main_phase();
        super.main_phase();
        raise_objection("test");
        
        fork
            // Thread 1: Configure DUT via AXI
            begin
                axi_config_sequence.execute(axi_agent_h.sequencer);
            end
            
            // Thread 2: Stream ADC data
            begin
                // Streaming happens automatically via agent
            end
            
            // Thread 3: Monitor DAC output
            begin
                // Monitor captures automatically
            end
        join
        
        #100us;
        drop_objection("test");
    endtask
endclass
```

---

## 🐍 Python Tool Examples

### Stimulus Generation

```python
#!/usr/bin/env python3
"""Generate ADC stimulus waveforms"""

import numpy as np
import argparse

def generate_sine(freq_hz, sample_rate_hz, duration_sec, amplitude=1.0):
    """Generate sine wave"""
    t = np.arange(0, duration_sec, 1/sample_rate_hz)
    return amplitude * np.sin(2 * np.pi * freq_hz * t)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--freq', type=float, default=10e6, help='Frequency in Hz')
    parser.add_argument('--fs', type=float, default=100e6, help='Sample rate in Hz')
    parser.add_argument('--duration', type=float, default=100e-6, help='Duration in seconds')
    parser.add_argument('--output', default='adc_stimulus.txt', help='Output file')
    args = parser.parse_args()
    
    # Generate waveform
    samples = generate_sine(args.freq, args.fs, args.duration)
    
    # Write to file
    with open(args.output, 'w') as f:
        f.write(f"# Frequency: {args.freq/1e6:.2f} MHz\n")
        f.write(f"# Sample Rate: {args.fs/1e6:.2f} MHz\n")
        f.write(f"# Samples: {len(samples)}\n")
        for i, sample in enumerate(samples):
            time = i / args.fs
            f.write(f"{time:.9f}, {sample:.6f}\n")
    
    print(f"Generated {len(samples)} samples to {args.output}")

if __name__ == '__main__':
    main()
```

### FFT Analysis

```python
#!/usr/bin/env python3
"""Analyze captured DAC data"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import argparse

def compute_fft(samples, sample_rate, window='blackmanharris'):
    """Compute FFT with windowing"""
    N = len(samples)
    
    # Apply window
    if window:
        w = signal.get_window(window, N)
        samples_windowed = samples * w
    else:
        samples_windowed = samples
    
    # Compute FFT
    fft = np.fft.fft(samples_windowed)
    freq = np.fft.fftfreq(N, 1/sample_rate)
    
    # Power spectrum (dBFS)
    power = 20 * np.log10(np.abs(fft) / N)
    
    return freq[:N//2], power[:N//2]

def compute_metrics(freq, power, signal_freq, num_harmonics=5):
    """Compute SNR, THD, SFDR"""
    # Find signal bin
    signal_bin = np.argmin(np.abs(freq - signal_freq))
    signal_power = power[signal_bin]
    
    # Find harmonics
    harmonics = []
    for n in range(2, num_harmonics+1):
        harm_freq = signal_freq * n
        if harm_freq < freq[-1]:
            harm_bin = np.argmin(np.abs(freq - harm_freq))
            harmonics.append(power[harm_bin])
    
    # SFDR (Spurious-Free Dynamic Range)
    spurious = np.copy(power)
    spurious[signal_bin-5:signal_bin+5] = -200  # Mask signal
    sfdr = signal_power - np.max(spurious)
    
    # THD (Total Harmonic Distortion)
    thd_power = 10 ** (np.array(harmonics) / 10)
    thd = 10 * np.log10(np.sum(thd_power))
    
    # SNR (Signal-to-Noise Ratio)
    noise_power = 10 ** (power / 10)
    noise_power[signal_bin-5:signal_bin+5] = 0  # Mask signal
    snr = signal_power - 10 * np.log10(np.sum(noise_power))
    
    return {
        'snr': snr,
        'thd': thd,
        'sfdr': sfdr,
        'signal_power': signal_power
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input', help='Captured data file')
    parser.add_argument('--fs', type=float, default=100e6, help='Sample rate')
    parser.add_argument('--freq', type=float, default=10e6, help='Signal frequency')
    args = parser.parse_args()
    
    # Read captured data
    data = []
    with open(args.input, 'r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            parts = line.strip().split(',')
            if len(parts) >= 2:
                data.append(float(parts[1]))
    
    samples = np.array(data)
    
    # Compute FFT
    freq, power = compute_fft(samples, args.fs)
    
    # Compute metrics
    metrics = compute_metrics(freq, power, args.freq)
    
    # Print results
    print(f"\n=== Analysis Results ===")
    print(f"Signal Power: {metrics['signal_power']:.2f} dBFS")
    print(f"SNR:  {metrics['snr']:.2f} dB")
    print(f"THD:  {metrics['thd']:.2f} dBc")
    print(f"SFDR: {metrics['sfdr']:.2f} dBc")
    
    # Plot
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
    
    # Time domain
    time = np.arange(len(samples)) / args.fs * 1e6  # us
    ax1.plot(time, samples)
    ax1.set_xlabel('Time (µs)')
    ax1.set_ylabel('Amplitude')
    ax1.set_title('Time Domain')
    ax1.grid(True)
    
    # Frequency domain
    ax2.plot(freq/1e6, power)
    ax2.set_xlabel('Frequency (MHz)')
    ax2.set_ylabel('Power (dBFS)')
    ax2.set_title(f'Frequency Domain (SNR={metrics["snr"]:.1f}dB, SFDR={metrics["sfdr"]:.1f}dB)')
    ax2.set_xlim([0, args.fs/2e6])
    ax2.grid(True)
    
    plt.tight_layout()
    plt.savefig('analysis.png')
    print(f"\nPlot saved to analysis.png")

if __name__ == '__main__':
    main()
```

---

## 🎯 Key Differentiators of EVM

### vs UVM:

1. **Dual Model Support**: Both transaction AND streaming natively
2. **Lightweight**: No excessive automation, suitable for embedded
3. **Python Integration**: Modern toolchain for DSP/RF analysis
4. **File-Based Streaming**: Simple, fast, debuggable
5. **Embedded Focus**: Designed for FPGA/ASIC embedded systems

### Benefits:

- ✅ **Fast**: File I/O is faster than DPI
- ✅ **Simple**: No complex infrastructure
- ✅ **Powerful**: Full Python ecosystem
- ✅ **Debuggable**: Inspect intermediate files
- ✅ **Portable**: Works with any simulator
- ✅ **Scalable**: Handle millions of samples

---

## 📚 Next Steps

1. Review this architecture document
2. Approve Python integration strategy
3. Begin Phase 1 implementation
4. Iterate based on first use cases

**This architecture positions EVM as the premier verification methodology for embedded systems!**
