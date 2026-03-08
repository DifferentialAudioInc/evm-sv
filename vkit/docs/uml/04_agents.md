# EVM Agents Overview

## Agent Base Architecture

```mermaid
classDiagram
    class evm_component {
        <<abstract>>
        +build_phase()
        +connect_phase()
        +run_phase()
        +final_phase()
    }
    
    class evm_agent {
        <<abstract>>
        +evm_mode_e mode
        +evm_driver driver
        +evm_monitor monitor
        +evm_sequencer sequencer
        +set_mode(mode)
        +create_driver()* evm_driver
        +create_monitor()* evm_monitor
    }
    
    class evm_driver {
        <<abstract>>
        +virtual if vif
        +main_phase()
    }
    
    class evm_monitor {
        <<abstract>>
        +virtual if vif
        +main_phase()
    }
    
    evm_agent --|> evm_component
    evm_driver --|> evm_component
    evm_monitor --|> evm_component
    evm_agent o-- evm_driver : contains
    evm_agent o-- evm_monitor : contains
```

## Agent Modes

```mermaid
graph TD
    AGENT[Agent Mode]
    
    AGENT --> ACTIVE[EVM_ACTIVE<br/>Driver + Monitor]
    AGENT --> PASSIVE[EVM_PASSIVE<br/>Monitor Only]
    
    ACTIVE --> DR[Driver Drives DUT]
    ACTIVE --> MO[Monitor Observes]
    
    PASSIVE --> MO2[Monitor Only<br/>No Driving]
```

## Protocol Agents Summary

```mermaid
graph TD
    subgraph "Register Access"
        AXI[AXI-Lite Agent<br/>3 modes: MASTER/SLAVE/PASSIVE<br/>Randomized delays]
    end
    
    subgraph "Signal Processing"
        ADC[ADC Agent<br/>Active<br/>Python stimulus gen]
        DAC[DAC Agent<br/>Passive<br/>Python analysis]
    end
    
    subgraph "Control"
        GPIO[GPIO Agent<br/>32 pins<br/>LEDs/Buttons/IRQs]
        CLK[Clock Agent<br/>Frequency control]
        RST[Reset Agent<br/>Multiple resets]
    end
    
    subgraph "System"
        PCIE[PCIe Agent<br/>Memory-mapped BFM]
    end
```

## AXI-Lite Agent Modes

```mermaid
graph TD
    AXI[AXI-Lite Agent]
    
    AXI --> MASTER[ACTIVE_MASTER<br/>Drives AXI master]
    AXI --> SLAVE[ACTIVE_SLAVE<br/>Responds as slave]
    AXI --> PASS[PASSIVE<br/>Monitors only]
    
    MASTER --> M1[Write/Read transactions]
    MASTER --> M2[Configurable delays]
    MASTER --> M3[Back-to-back control]
    
    SLAVE --> S1[Ready signal delays]
    SLAVE --> S2[Response generation]
    
    PASS --> P1[Transaction observation]
```

## Streaming Agents (ADC/DAC)

```mermaid
classDiagram
    class evm_stream_agent {
        +evm_stream_cfg cfg
        +generate_stimulus()
        +analyze_capture()
    }
    
    class evm_adc_agent {
        +evm_adc_cfg adc_cfg
        +configure_channel()
        +enable_channel()
        +generate_adc_stimulus()
    }
    
    class evm_dac_agent {
        +evm_dac_cfg dac_cfg
        +analyze_dac_spectrum()
        +analyze_dac_thd()
        +analyze_dac_snr()
    }
    
    evm_adc_agent --|> evm_stream_agent
    evm_dac_agent --|> evm_stream_agent
```

## Python Integration Flow

```mermaid
sequenceDiagram
    participant Test
    participant ADC_Agent
    participant Python_Gen
    participant DUT
    participant DAC_Agent
    participant Python_Analyze
    
    Test->>ADC_Agent: generate_adc_stimulus()
    ADC_Agent->>Python_Gen: gen_stimulus.py
    Python_Gen-->>ADC_Agent: stimulus files
    
    ADC_Agent->>DUT: Drive signals
    DUT->>DAC_Agent: Output signals
    DAC_Agent->>DAC_Agent: Capture to file
    
    Test->>DAC_Agent: analyze_dac_spectrum()
    DAC_Agent->>Python_Analyze: analyze_spectrum.py
    Python_Analyze-->>Test: Results & plots
```

## Agent Usage Examples

### AXI-Lite Master Mode
```systemverilog
// Create and configure
evm_axi_lite_agent axi_agent = new();
axi_agent.cfg.mode = EVM_AXI_ACTIVE_MASTER;
axi_agent.cfg.master_delay_min = 0;
axi_agent.cfg.master_delay_max = 2;
axi_agent.cfg.back_to_back_pct = 80;

// Connect interface
axi_agent.set_interface(axi_if);
axi_agent.build();

// Use with register model
ral.configure(axi_agent);
ral.system.control.write(32'h0003, status);
```

### ADC Agent (Active)
```systemverilog
// Create and configure
evm_adc_agent adc_agent = new();
adc_agent.set_sample_rate(100e6);
adc_agent.enable_auto_generate(1);

// Configure channels
adc_agent.configure_channel(0, 1.0e6, 2047.0);  // 1 MHz sine
adc_agent.configure_channel(1, 2.0e6, 1024.0);  // 2 MHz sine
adc_agent.enable_all_channels();

// Stimulus auto-generated before sim
// Driver streams data to DUT
```

### DAC Agent (Passive)
```systemverilog
// Create and configure
evm_dac_agent dac_agent = new();
dac_agent.set_sample_rate(100e6);
dac_agent.set_capture_samples(16384);
dac_agent.enable_auto_analyze(1);
dac_agent.enable_fft_analysis(1);
dac_agent.enable_thd_analysis(1);

// Monitor captures output
// Analysis auto-runs after sim
```

### GPIO Agent
```systemverilog
// Create and configure
evm_gpio_agent gpio_agent = new();

// Set individual pins
gpio_agent.set_pin(0, 1);  // LED on
gpio_agent.set_pin(1, 0);  // LED off

// Set multiple pins
gpio_agent.set_pins(32'h0000_000F);  // Lower 4 bits

// Toggle pin
gpio_agent.toggle_pin(2);
```

## Test Environment Structure

```mermaid
graph TD
    TEST[Test]
    ENV[Environment]
    
    TEST --> ENV
    
    ENV --> AXI[AXI-Lite Agent]
    ENV --> ADC[ADC Agent]
    ENV --> DAC[DAC Agent]
    ENV --> GPIO[GPIO Agent]
    ENV --> CLK[Clock Agent]
    ENV --> RST[Reset Agent]
    ENV --> PCIE[PCIe Agent]
    
    ENV --> RAL[Register Model]
    ENV --> MEM[Memory Model]
    ENV --> SB[Scoreboard]
    
    AXI -.-> DUT[DUT]
    ADC -.-> DUT
    DAC -.-> DUT
    GPIO -.-> DUT
    CLK -.-> DUT
    RST -.-> DUT
    PCIE -.-> DUT
    
    RAL --> AXI
    SB --> DAC
    MEM --> PCIE
```

## Key Agent Features

### AXI-Lite
- 3 operating modes
- Randomized timing
- Protocol checking
- Register model integration

### ADC
- Python stimulus generation
- Multi-channel support
- Configurable sample rate
- Signal generation (sine, etc.)

### DAC
- Passive capture only
- Python analysis (FFT, THD, SNR)
- Multi-channel monitoring
- File output

### GPIO
- 32-pin control
- LED/button support
- Interrupt monitoring
- Toggle tracking

### Clock/Reset
- Frequency control
- Multiple reset types
- Synchronization support

### PCIe
- Memory-mapped BFM
- Simple read/write
- Link training
- Configuration space
