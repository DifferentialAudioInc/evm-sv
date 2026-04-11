/*============================================================================*/
/* File: axi_data_xform_csr.h
 * Description: CSR definitions for AXI Data Transform DUT registers
 * Generated: 2026-04-10 15:26:15
 * Source: c:\evm\evm-sv\examples\example1\csr\example1.yaml
 */
/*============================================================================*/

#ifndef __AXI_DATA_XFORM_CSR_H__
#define __AXI_DATA_XFORM_CSR_H__

#include <stdint.h>

/* Module base address */
#define AXI_DATA_XFORM_BASE_ADDR    0

/* Register offsets */
#define AXI_DATA_XFORM_CTRL_OFFSET    0
#define AXI_DATA_XFORM_DATA_IN_OFFSET    4
#define AXI_DATA_XFORM_STATUS_OFFSET    8
#define AXI_DATA_XFORM_RESULT_OFFSET    12
#define AXI_DATA_XFORM_GPIO_OUT_OFFSET    16

/* Absolute register addresses */
#define AXI_DATA_XFORM_CTRL_ADDR      0x00000000U
#define AXI_DATA_XFORM_DATA_IN_ADDR      0x00000004U
#define AXI_DATA_XFORM_STATUS_ADDR      0x00000008U
#define AXI_DATA_XFORM_RESULT_ADDR      0x0000000CU
#define AXI_DATA_XFORM_GPIO_OUT_ADDR      0x00000010U

/* Control register */
typedef union {
    struct {
        uint32_t enable               :  1;  /* Enable transform engine (1=enabled) */
        uint32_t xform_sel            :  2;  /* Transform select: 0=passthrough 1=invert 2=byte_swap 3=bit_reverse */
    } fields;
    uint32_t raw;
} axi_data_xform_ctrl_t;

#define AXI_DATA_XFORM_CTRL_ENABLE_POS    0
#define AXI_DATA_XFORM_CTRL_ENABLE_MASK   0x00000001U
#define AXI_DATA_XFORM_CTRL_XFORM_SEL_POS    1
#define AXI_DATA_XFORM_CTRL_XFORM_SEL_MASK   0x00000003U
/* Input data register. Writing triggers transform when ENABLE=1. */
typedef union {
    struct {
        uint32_t data                 : 32;  /* Input data value */
    } fields;
    uint32_t raw;
} axi_data_xform_data_in_t;

#define AXI_DATA_XFORM_DATA_IN_DATA_POS    0
#define AXI_DATA_XFORM_DATA_IN_DATA_MASK   0xFFFFFFFFU
/* Status register (hardware driven) */
typedef union {
    struct {
        uint32_t busy                 :  1;  /* Transform in progress */
        uint32_t done                 :  1;  /* Last transform complete */
    } fields;
    uint32_t raw;
} axi_data_xform_status_t;

#define AXI_DATA_XFORM_STATUS_BUSY_POS    0
#define AXI_DATA_XFORM_STATUS_BUSY_MASK   0x00000001U
#define AXI_DATA_XFORM_STATUS_DONE_POS    1
#define AXI_DATA_XFORM_STATUS_DONE_MASK   0x00000001U
/* Transform result (hardware driven, valid when STATUS.DONE=1) */
typedef union {
    struct {
        uint32_t data                 : 32;  /* Transform result value */
    } fields;
    uint32_t raw;
} axi_data_xform_result_t;

#define AXI_DATA_XFORM_RESULT_DATA_POS    0
#define AXI_DATA_XFORM_RESULT_DATA_MASK   0xFFFFFFFFU
/* GPIO output register. Drives gpio_out[7:0] pins directly. */
typedef union {
    struct {
        uint32_t gpio                 :  8;  /* GPIO output value (8-bit, drives physical pins) */
    } fields;
    uint32_t raw;
} axi_data_xform_gpio_out_t;

#define AXI_DATA_XFORM_GPIO_OUT_GPIO_POS    0
#define AXI_DATA_XFORM_GPIO_OUT_GPIO_MASK   0x000000FFU

/* Complete AXI_DATA_XFORM register block */
typedef struct {
    axi_data_xform_ctrl_t ctrl                ; /* Control register */
    axi_data_xform_data_in_t data_in             ; /* Input data register. Writing triggers transform when ENABLE=1. */
    axi_data_xform_status_t status              ; /* Status register (hardware driven) */
    axi_data_xform_result_t result              ; /* Transform result (hardware driven, valid when STATUS.DONE=1) */
    axi_data_xform_gpio_out_t gpio_out            ; /* GPIO output register. Drives gpio_out[7:0] pins directly. */
} axi_data_xform_regs_t;

/* Pointer to register block in memory */
#define AXI_DATA_XFORM_REGS    ((volatile axi_data_xform_regs_t *)AXI_DATA_XFORM_BASE_ADDR)

#endif /* __AXI_DATA_XFORM_CSR_H__ */