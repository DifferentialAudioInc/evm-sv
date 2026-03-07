# Register Map Documentation
## DSP-4CH-100M

**Generated:** 2026-03-07 16:48:06  
**Source:** evm/csr_gen/example/example_csr_definitions.yaml

## Table of Contents

- [SYSTEM](#system)
- [ADC](#adc)
- [FFT](#fft)

## SYSTEM

**Description:** System control and status module  
**Base Address:** `0`

| Offset | Register | Access | Reset | Description |
|--------|----------|--------|-------|-------------|
| 0 | VERSION | RO | 16777216 | Version and identification register |
| 4 | CONTROL | RW | 0 | System control register |
| 8 | STATUS | RO | 0 | System status register |
| 12 | LED_CONTROL | RW | 0 | LED control register |
| 16 | SCRATCH0 | RW | 0 | Scratch register 0 for testing |
| 20 | SCRATCH1 | RW | 3735928559 | Scratch register 1 for testing |
| 24 | TIMESTAMP_LO | RO | 0 | Timestamp counter lower 32 bits |
| 28 | TIMESTAMP_HI | RO | 0 | Timestamp counter upper 32 bits |
| 32 | TEST_REG | RO | 305419896 | Read only test register |

### VERSION

**Offset:** 0  
**Access:** RO  
**Reset Value:** 16777216  
**Description:** Version and identification register

| Bits | Field | Description |
|------|-------|-------------|
| [31:24] | MAJOR | Major version number |
| [23:16] | MINOR | Minor version number |
| [15:8] | PATCH | Patch version number |
| [7:0] | BUILD | Build number |

### CONTROL

**Offset:** 4  
**Access:** RW  
**Reset Value:** 0  
**Description:** System control register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | RESET | Software reset (write 1 to reset) |
| [1] | ENABLE | System enable (1=enabled, 0=disabled) |
| [2] | DEBUG_MODE | Debug mode enable |
| [31:3] | RESERVED | Reserved for future use |

### STATUS

**Offset:** 8  
**Access:** RO  
**Reset Value:** 0  
**Description:** System status register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | READY | System ready flag |
| [1] | ERROR | Error flag |
| [2] | LOCKED | Clock locked status |
| [31:3] | RESERVED | Reserved |

### LED_CONTROL

**Offset:** 12  
**Access:** RW  
**Reset Value:** 0  
**Description:** LED control register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | LED0 | LED0 control (1=on, 0=off) |
| [1] | LED1 | LED1 control (1=on, 0=off) |
| [2] | LED2 | LED2 control (1=on, 0=off) |
| [3] | LED3 | LED3 control (1=on, 0=off) |
| [31:4] | RESERVED | Reserved |

### SCRATCH0

**Offset:** 16  
**Access:** RW  
**Reset Value:** 0  
**Description:** Scratch register 0 for testing

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | DATA | Scratch data |

### SCRATCH1

**Offset:** 20  
**Access:** RW  
**Reset Value:** 3735928559  
**Description:** Scratch register 1 for testing

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | DATA | Scratch data |

### TIMESTAMP_LO

**Offset:** 24  
**Access:** RO  
**Reset Value:** 0  
**Description:** Timestamp counter lower 32 bits

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | COUNT | Lower 32 bits of timestamp |

### TIMESTAMP_HI

**Offset:** 28  
**Access:** RO  
**Reset Value:** 0  
**Description:** Timestamp counter upper 32 bits

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | COUNT | Upper 32 bits of timestamp |

### TEST_REG

**Offset:** 32  
**Access:** RO  
**Reset Value:** 305419896  
**Description:** Read only test register

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | VAL | Read only test register |

## ADC

**Description:** ADC control and status module  
**Base Address:** `4096`

| Offset | Register | Access | Reset | Description |
|--------|----------|--------|-------|-------------|
| 0 | CONFIG | RW | 0 | ADC configuration register |
| 4 | STATUS | RO | 0 | ADC status register |
| 8 | SAMPLE_COUNT | RO | 0 | Sample counter |

### CONFIG

**Offset:** 0  
**Access:** RW  
**Reset Value:** 0  
**Description:** ADC configuration register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | ENABLE_CH0 | Enable channel 0 |
| [1] | ENABLE_CH1 | Enable channel 1 |
| [2] | ENABLE_CH2 | Enable channel 2 |
| [3] | ENABLE_CH3 | Enable channel 3 |
| [11:8] | SAMPLE_RATE | Sample rate divider |
| [31:12] | RESERVED | Reserved |

### STATUS

**Offset:** 4  
**Access:** RO  
**Reset Value:** 0  
**Description:** ADC status register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | LOCKED | ADC clock locked |
| [1] | ALIGNED | Channels aligned |
| [2] | OVERFLOW | Data overflow detected |
| [31:3] | RESERVED | Reserved |

### SAMPLE_COUNT

**Offset:** 8  
**Access:** RO  
**Reset Value:** 0  
**Description:** Sample counter

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | COUNT | Number of samples captured |

## FFT

**Description:** FFT processing module  
**Base Address:** `8192`

| Offset | Register | Access | Reset | Description |
|--------|----------|--------|-------|-------------|
| 0 | CONFIG | RW | 4096 | FFT configuration register |
| 4 | STATUS | RO | 0 | FFT status register |

### CONFIG

**Offset:** 0  
**Access:** RW  
**Reset Value:** 4096  
**Description:** FFT configuration register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | ENABLE | FFT enable |
| [4:1] | SIZE | FFT size (0=1K, 1=2K, 2=4K, 3=8K) |
| [7:5] | WINDOW | Window function (0=Rect, 1=Hanning, 2=Hamming, 3=Blackman) |
| [9:8] | OVERLAP | Overlap (0=0%, 1=25%, 2=50%, 3=75%) |
| [31:10] | RESERVED | Reserved |

### STATUS

**Offset:** 4  
**Access:** RO  
**Reset Value:** 0  
**Description:** FFT status register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | BUSY | FFT processing active |
| [1] | DONE | FFT processing complete |
| [2] | OVERFLOW | Output overflow detected |
| [31:3] | RESERVED | Reserved |
