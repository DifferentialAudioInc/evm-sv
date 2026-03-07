# EVM Buffered Streaming Guide

**Copyright (c) 2026 Differential Audio Inc**  
**Version:** 1.0  
**Date:** 2026-03-07

---

## Overview

EVM supports **buffered streaming** mode where stimulus is generated dynamically on-demand by calling Python scripts incrementally. This approach offers significant advantages over pre-generating large stimulus files:

✅ **Memory Efficient** - Only small buffers in memory  
✅ **Unlimited Duration** - Stream indefinitely without large files  
✅ **Phase Continuous** - Python maintains signal phase across buffers  
✅ **Flexible** - Can change signal parameters during simulation  

---

## Architecture

### Buffered Streaming Flow

```
Simulation Start
    ↓
Initialize buffer (e.g., 1024 samples)
    ↓
Call Python: generate_buffer(start=0, count=1024)
    ↓
Python generates samples 0-1023 with phase continuity
    ↓
Load buffer into circular queue
    ↓
┌──────────────────────────────────────┐
│  Streaming Loop (every clock cycle)  │
│  ↓                                    │
│  Output sample from buffer            │
│  ↓                                    │
│  Advance read pointer                 │
│  ↓                                    │
│  Check buffer level < threshold?      │
│  ↓ YES                                │
│  Call Python: generate_buffer(        │
│    start=samples_output,              │
│    count=buffer_size)                 │
│  ↓                                    │
│  Python generates next buffer with    │
│  phase continuity from previous       │
│  ↓                                    │
│  Load new samples into circular buffer│
│  ↓                                    │
└──────────────────────────────────────┘
```

### Key Concepts

**Circular Buffer:**
- Fixed size (e.g., 1024 samples)
- Read pointer advances every clock
- Write pointer advances when refilling
- Wraps around circularly

**Refill Threshold:**
- When buffer drops below threshold (e.g., 256 samples)
- Trigger Python to generate more samples
- Python receives `start_sample` index for phase continuity

**Phase Continuity:**
- Python calculates `start_time = start_sample / sample_rate`
- Generates waveform from `start_time` forward
- Signal phase remains continuous across buffers

---

## Configuration

### Enable Buffered Mode

```systemverilog
// Configure stream agent for buffered mode
stream_agent.cfg.buffered_mode = 1;              // Enable buffered streaming
stream_agent.cfg.buffer_size = 1024;             // Samples per buffer
stream_agent.cfg.buffer_refill_threshold = 256;  // Refill trigger point

// Python script configuration
stream_agent.cfg.python_gen_script = "python/gen_stimulus.py";
stream_agent.cfg.temp_buffer_file = "temp_buffer.txt";

// Signal parameters
stream_agent.cfg.signal_type = "sine";
stream_agent.cfg.signal_freq_hz = 10e6;
stream_agent.cfg.sample_rate_hz = 100e6;
stream_agent.cfg.num_channels = 4;
```

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `buffered_mode` | 1 | Enable dynamic buffered streaming |
| `buffer_size` | 1024 | Number of samples in circular buffer |
| `buffer_refill_threshold` | 256 | Refill when buffer < this value |
| `temp_buffer_file` | "temp_buffer.txt" | Temporary file for each buffer |
| `python_gen_script` | "" | Path to Python generation script |

### Buffer Size Selection

**Small buffers (256-512 samples):**
- ✅ Less memory
- ✅ More responsive to parameter changes
- ❌ More frequent Python calls
- ❌ Higher overhead

**Medium buffers (1024-2048 samples):**
- ✅ Good balance
- ✅ ~10us @ 100MHz between refills
- ✅ Recommended for most cases

**Large buffers (4096+ samples):**
- ✅ Fewer Python calls
- ✅ Lower overhead
- ❌ More memory
- ❌ Slower parameter updates

---

## Python Script Interface

### Command Line Arguments

The Python script is called with these arguments:

```bash
python gen_stimulus.py \
  --type sine \
  --freq 10000000 \
  --fs 100000000 \
  --amp 0.8 \
  --start 1024 \          # Start sample index
  --count 1024 \          # Number of samples to generate
  --channels 4 \
  --output temp_buffer.txt
```

### Key Arguments for Buffered Mode

**`--start N`**  
- Starting sample index (0, 1024, 2048, ...)
- Used to calculate `start_time = N / sample_rate`
- Ensures phase continuity

**`--count N`**  
- Number of samples in this buffer
- Overrides `--duration`

### Phase Continuity Implementation

The Python script maintains phase by:

1. Calculate `start_time = start_sample / sample_rate`
2. Generate time array: `t = arange(count) / sample_rate + start_time`
3. Apply signal function: `signal = amp * sin(2*pi*freq*t + phase)`

**Example:**
```python
# Buffer 1: samples 0-1023
start_time = 0 / 100e6 = 0.0
t = [0.00us, 0.01us, ..., 10.23us]

# Buffer 2: samples 1024-2047  
start_time = 1024 / 100e6 = 10.24us
t = [10.24us, 10.25us, ..., 20.47us]  # Continuous!
```

---

## Usage Example

### Complete Test

```systemverilog
class buffered_streaming_test extends base_test;
    evm_stream_agent stream_agent;
    
    virtual function void build_phase();
        super.build_phase();
        
        stream_agent = new("stream_agent", this);
        
        // Configure buffered streaming
        stream_agent.cfg.buffered_mode = 1;
        stream_agent.cfg.buffer_size = 1024;
        stream_agent.cfg.buffer_refill_threshold = 256;
        stream_agent.cfg.python_gen_script = "python/gen_stimulus.py";
        stream_agent.cfg.temp_buffer_file = "temp_buffer.txt";
        
        // Signal configuration
        stream_agent.cfg.signal_type = "sine";
        stream_agent.cfg.signal_freq_hz = 10e6;
        stream_agent.cfg.sample_rate_hz = 100e6;
        stream_agent.cfg.signal_amplitude = 0.8;
        stream_agent.cfg.num_channels = 4;
        
        stream_agent.set_vif(stream_vif);
    endfunction
    
    virtual task main_phase();
        raise_objection("test");
        
        // Stream will automatically refill buffer as needed
        #100us;  // Stream for 100us (10,000 samples, ~10 refills)
        
        // Check buffer statistics
        int samples = stream_agent.get_driver().get_total_samples();
        log_info($sformatf("Streamed %0d samples", samples), EVM_LOW);
        
        drop_objection("test");
    endtask
endclass
```

---

## Monitoring and Statistics

### Runtime Monitoring

Query buffer status during simulation:

```systemverilog
// Get current buffer level
int level = stream_agent.get_driver().get_buffer_level();
log_info($sformatf("Buffer: %0d samples", level), EVM_DEBUG);

// Get total samples output
int total = stream_agent.get_driver().get_total_samples();
log_info($sformatf("Output: %0d samples", total), EVM_MED);
```

### Automatic Statistics

At end of simulation, driver reports:

```
=== Streaming Statistics ===
  Total samples output: 13024
  Buffer refills: 12
  Max buffer usage: 1024/1024
```

### Detecting Issues

**Buffer Underrun:**
```
ERROR: Buffer underrun!
```
- Python generation too slow
- Increase `buffer_size` or `buffer_refill_threshold`

**No Refills:**
```
Buffer refills: 0
```
- Simulation too short to trigger refill
- Or streaming stopped early

---

## Comparison: Buffered vs File Mode

| Aspect | File Mode | Buffered Mode |
|--------|-----------|---------------|
| **Memory** | Entire file in memory | Only buffer in memory |
| **Duration** | Limited by file size | Unlimited |
| **Generation** | Pre-generate before sim | On-demand during sim |
| **Flexibility** | Static | Can change parameters |
| **Overhead** | Load once | Python calls per buffer |
| **Phase** | File-defined | Calculated per buffer |
| **Best For** | Fixed, finite stimulus | Long or infinite streams |

### When to Use Each

**Use File Mode When:**
- Known, finite stimulus
- Pre-generated complex waveforms
- Minimize Python dependencies
- Faster startup (no Python calls)

**Use Buffered Mode When:**
- Long-duration streaming (>100us)
- Continuous/infinite streaming
- Memory constrained
- Need to change parameters during test

---

## Advanced Features

### Dynamic Parameter Changes

Change signal parameters during streaming:

```systemverilog
// Change frequency after 50us
#50us;
stream_agent.cfg.signal_freq_hz = 20e6;  // Changes will apply to next buffer
```

**Note:** Changes take effect at next buffer refill, not immediately.

### Multiple Agents

Run multiple buffered streams concurrently:

```systemverilog
// ADC stimulus
adc_stream.cfg.buffered_mode = 1;
adc_stream.cfg.buffer_size = 1024;
adc_stream.cfg.signal_freq_hz = 10e6;

// Reference signal
ref_stream.cfg.buffered_mode = 1;
ref_stream.cfg.buffer_size = 512;
ref_stream.cfg.signal_freq_hz = 1e6;

// Both stream concurrently with independent buffering
```

### Custom Buffer Sizes per Channel

For multi-channel with different rates:

```systemverilog
// High-rate channel needs larger buffer
high_rate_stream.cfg.buffer_size = 4096;
high_rate_stream.cfg.sample_rate_hz = 1e9;  // 1 GHz

// Low-rate channel can use smaller buffer
low_rate_stream.cfg.buffer_size = 256;
low_rate_stream.cfg.sample_rate_hz = 10e6;  // 10 MHz
```

---

## Troubleshooting

### Issue: Buffer Underruns

**Symptoms:**
- "ERROR: Buffer underrun!" messages
- Gaps in output data

**Causes:**
- Python script too slow
- Buffer too small for refill rate
- System under heavy load

**Solutions:**
1. Increase `buffer_size` (e.g., 2048 or 4096)
2. Increase `buffer_refill_threshold` (e.g., 512)
3. Optimize Python script
4. Use faster storage for temp files (RAM disk)

### Issue: Phase Discontinuities

**Symptoms:**
- Spectral artifacts
- Visible glitches in waveform

**Causes:**
- Python not using `--start` parameter correctly
- Time calculation error

**Solutions:**
1. Verify Python uses `start_time = start_sample / sample_rate`
2. Check time array: `t = arange(count) / fs + start_time`
3. Ensure no rounding errors in time calculation

### Issue: Python Call Failures

**Symptoms:**
- "Python generation failed: status=X" 
- Empty buffers

**Causes:**
- Python script path incorrect
- Script has errors
- Missing dependencies (numpy, scipy)

**Solutions:**
1. Test script manually: `python gen_stimulus.py --help`
2. Check script path in configuration
3. Verify Python environment has required packages
4. Check system() return code for details

### Issue: Performance

**Symptoms:**
- Simulation very slow
- Frequent refills

**Causes:**
- Buffer too small
- Threshold too high (refilling too early)

**Solutions:**
1. Increase buffer size (less frequent calls)
2. Lower threshold (refill less often)
3. Profile: check `Buffer refills` statistic
4. Goal: ~10-20 refills per 100us @ 100MHz

---

## Best Practices

### Buffer Sizing Guidelines

**Rule of Thumb:** Buffer should last ~10-20us at your sample rate

```
buffer_size = sample_rate_hz * desired_buffer_duration
            = 100e6 * 10e-6 = 1000 samples
```

**Refill Threshold:** ~25% of buffer size

```
buffer_refill_threshold = buffer_size / 4
```

### Python Script Optimization

**Fast:**
```python
# Direct numpy operations
t = np.arange(count) / fs + start_time
samples = amp * np.sin(2 * np.pi * freq * t)
```

**Slow:**
```python
# Avoid loops
for i in range(count):
    t = (start + i) / fs
    samples[i] = amp * math.sin(2 * math.pi * freq * t)  # Slow!
```

### Error Handling

Always check return values:

```systemverilog
int samples_generated = generate_buffer(start, count);
if (samples_generated == 0) begin
    log_error("Buffer generation failed!");
    // Handle error (stop streaming, use zeros, etc.)
end
```

---

## Summary

Buffered streaming provides an elegant solution for long-duration, continuous data streaming in verification:

- ✅ Memory efficient (only buffer in memory)
- ✅ Unlimited duration (no large files)
- ✅ Phase continuous (Python tracks sample index)
- ✅ Flexible (can change parameters)
- ✅ Production-ready (with proper buffer sizing)

**Key takeaway:** Python receives `start_sample` index with each call, calculates `start_time`, and generates waveform from that point forward, ensuring perfect phase continuity across buffer boundaries.

---

*End of Guide*
