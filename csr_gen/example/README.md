# CSR Generator Example

This example demonstrates how to use the CSR Generator tool.

## Files

- **example_csr_definitions.yaml** - Sample YAML register definitions for a DSP project

## Running the Example

From the DAI root directory:

```bash
# Generate CSRs from this example
python evm/csr_gen/gen_csr.py evm/csr_gen/example/example_csr_definitions.yaml output/csr_gen

# Or generate to the project's csr_gen directory
python evm/csr_gen/gen_csr.py evm/csr_gen/example/example_csr_definitions.yaml csr_gen
```

## Example YAML Structure

The `example_csr_definitions.yaml` file defines three modules:

### 1. SYSTEM Module (Base: 0x00000000)
System-level control and status registers including:
- VERSION - Product version identification
- CONTROL - System enable/reset control
- STATUS - System ready/error status
- LED_CONTROL - LED control bits
- SCRATCH registers - For testing
- TIMESTAMP - 64-bit timestamp counter

### 2. ADC Module (Base: 0x00001000)
ADC configuration and status including:
- CONFIG - Channel enables and sample rate
- STATUS - Lock, alignment, overflow status
- SAMPLE_COUNT - Sample counter

### 3. FFT Module (Base: 0x00002000)
FFT processing control including:
- CONFIG - Enable, size, window function, overlap
- STATUS - Busy, done, overflow flags

## Generated Output Structure

After running the generator, you'll see:

```
output/csr_gen/
├── dsp_regs.h              # Master C header
├── csr_paths.svh           # SV path definitions
├── csr_paths.h             # C path definitions
├── register_map.md         # Documentation
├── system/
│   ├── system_csr_pkg.sv
│   ├── system_csr.sv
│   └── system_csr.h
├── adc/
│   ├── adc_csr_pkg.sv
│   ├── adc_csr.sv
│   └── adc_csr.h
└── fft/
    ├── fft_csr_pkg.sv
    ├── fft_csr.sv
    └── fft_csr.h
```

## Using Generated Files

### In SystemVerilog Testbench

```systemverilog
import system_csr_pkg::*;

module tb;
    // CSR interface signals
    logic clk, rst_n;
    logic csr_wr_en, csr_rd_en;
    logic [31:0] csr_addr, csr_wr_data, csr_rd_data;
    logic csr_rd_valid;
    
    // Register connections
    system_reg_t control_o;
    system_reg_t status_i;
    
    // Instantiate CSR module
    system_csr u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .csr_wr_en(csr_wr_en),
        .csr_rd_en(csr_rd_en),
        .csr_addr(csr_addr),
        .csr_wr_data(csr_wr_data),
        .csr_rd_data(csr_rd_data),
        .csr_rd_valid(csr_rd_valid),
        .control_o(control_o),
        .status_i(status_i)
    );
    
    // Test: Write to control register
    initial begin
        csr_addr = SYSTEM_BASE_ADDR + SYSTEM_CONTROL_OFFSET;
        csr_wr_data = 32'h0000_0002; // Set enable bit
        csr_wr_en = 1'b1;
        @(posedge clk);
        csr_wr_en = 1'b0;
    end
endmodule
```

### In C Firmware

```c
#include "dsp_regs.h"

void init_hardware(void) {
    // Enable system
    SYSTEM_REGS->control.fields.enable = 1;
    
    // Configure ADC channels
    ADC_REGS->config.fields.enable_ch0 = 1;
    ADC_REGS->config.fields.enable_ch1 = 1;
    ADC_REGS->config.fields.sample_rate = 5;
    
    // Configure FFT
    FFT_REGS->config.fields.enable = 1;
    FFT_REGS->config.fields.size = 2;  // 4K FFT
    FFT_REGS->config.fields.window = 1; // Hanning
    
    // Wait for system ready
    while (!SYSTEM_REGS->status.fields.ready);
    
    // Turn on LED to indicate ready
    SYSTEM_REGS->led_control.fields.led0 = 1;
}

uint32_t read_version(void) {
    return SYSTEM_REGS->version.raw;
}
```

## Customizing for Your Project

1. Copy `example_csr_definitions.yaml` to your project directory
2. Edit the YAML file to define your registers:
   - Change module names and base addresses
   - Add/remove registers as needed
   - Define register fields and bit positions
3. Run the generator pointing to your YAML file
4. Include generated files in your RTL and firmware builds

## YAML Tips

- Use clear, descriptive names for modules, registers, and fields
- Choose base addresses that don't overlap (4KB boundaries recommended)
- Document each register and field with descriptions
- Use appropriate access types (RW/RO/WO)
- Set meaningful reset values
- Group related functionality into modules
