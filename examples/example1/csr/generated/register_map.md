# Register Map Documentation
## DSP-4CH-100M

**Generated:** 2026-04-10 00:05:08  
**Source:** c:\evm\evm-sv\examples\axi_data_xform\rtl\axi_data_xform_csr.yaml

## Table of Contents

- [axi_data_xform](#axi_data_xform)

## axi_data_xform

**Description:** AXI Data Transform DUT registers  
**Base Address:** `0`

| Offset | Register | Access | Reset | Description |
|--------|----------|--------|-------|-------------|
| 0 | CTRL | RW | 0 | Control register |
| 4 | DATA_IN | RW | 0 | Input data register. Writing triggers transform when ENABLE=1. |
| 8 | STATUS | RO | 0 | Status register (hardware driven) |
| 12 | RESULT | RO | 0 | Transform result (hardware driven, valid when STATUS.DONE=1) |
| 16 | GPIO_OUT | RW | 0 | GPIO output register. Drives gpio_out[7:0] pins directly. |

### CTRL

**Offset:** 0  
**Access:** RW  
**Reset Value:** 0  
**Description:** Control register

| Bits | Field | Description |
|------|-------|-------------|
| [0] | ENABLE | Enable transform engine (1=enabled) |
| [2:1] | XFORM_SEL | Transform select:
  0 = passthrough  (result = data)
  1 = invert       (result = ~data)
  2 = byte_swap    (result = {d[7:0],d[15:8],d[23:16],d[31:24]})
  3 = bit_reverse  (result = data bit-reversed)
 |

### DATA_IN

**Offset:** 4  
**Access:** RW  
**Reset Value:** 0  
**Description:** Input data register. Writing triggers transform when ENABLE=1.

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | DATA | Input data value |

### STATUS

**Offset:** 8  
**Access:** RO  
**Reset Value:** 0  
**Description:** Status register (hardware driven)

| Bits | Field | Description |
|------|-------|-------------|
| [0] | BUSY | Transform in progress |
| [1] | DONE | Last transform complete |

### RESULT

**Offset:** 12  
**Access:** RO  
**Reset Value:** 0  
**Description:** Transform result (hardware driven, valid when STATUS.DONE=1)

| Bits | Field | Description |
|------|-------|-------------|
| [31:0] | DATA | Transform result value |

### GPIO_OUT

**Offset:** 16  
**Access:** RW  
**Reset Value:** 0  
**Description:** GPIO output register. Drives gpio_out[7:0] pins directly.

| Bits | Field | Description |
|------|-------|-------------|
| [7:0] | GPIO | GPIO output value (8-bit, drives physical pins) |
