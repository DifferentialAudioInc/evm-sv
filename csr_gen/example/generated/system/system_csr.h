/*============================================================================*/
/* File: system_csr.h
 * Description: CSR definitions for System control and status module
 * Generated: 2026-03-07 16:48:06
 * Source: evm/csr_gen/example/example_csr_definitions.yaml
 */
/*============================================================================*/

#ifndef __SYSTEM_CSR_H__
#define __SYSTEM_CSR_H__

#include <stdint.h>

/* Module base address */
#define SYSTEM_BASE_ADDR    0

/* Register offsets */
#define SYSTEM_VERSION_OFFSET    0
#define SYSTEM_CONTROL_OFFSET    4
#define SYSTEM_STATUS_OFFSET    8
#define SYSTEM_LED_CONTROL_OFFSET    12
#define SYSTEM_SCRATCH0_OFFSET    16
#define SYSTEM_SCRATCH1_OFFSET    20
#define SYSTEM_TIMESTAMP_LO_OFFSET    24
#define SYSTEM_TIMESTAMP_HI_OFFSET    28
#define SYSTEM_TEST_REG_OFFSET    32

/* Absolute register addresses */
#define SYSTEM_VERSION_ADDR      0x00000000U
#define SYSTEM_CONTROL_ADDR      0x00000004U
#define SYSTEM_STATUS_ADDR      0x00000008U
#define SYSTEM_LED_CONTROL_ADDR      0x0000000CU
#define SYSTEM_SCRATCH0_ADDR      0x00000010U
#define SYSTEM_SCRATCH1_ADDR      0x00000014U
#define SYSTEM_TIMESTAMP_LO_ADDR      0x00000018U
#define SYSTEM_TIMESTAMP_HI_ADDR      0x0000001CU
#define SYSTEM_TEST_REG_ADDR      0x00000020U

/* Version and identification register */
typedef union {
    struct {
        uint32_t build                :  8;  /* Build number */
        uint32_t patch                :  8;  /* Patch version number */
        uint32_t minor                :  8;  /* Minor version number */
        uint32_t major                :  8;  /* Major version number */
    } fields;
    uint32_t raw;
} system_version_t;

#define SYSTEM_VERSION_MAJOR_POS    24
#define SYSTEM_VERSION_MAJOR_MASK   0x000000FFU
#define SYSTEM_VERSION_MINOR_POS    16
#define SYSTEM_VERSION_MINOR_MASK   0x000000FFU
#define SYSTEM_VERSION_PATCH_POS    8
#define SYSTEM_VERSION_PATCH_MASK   0x000000FFU
#define SYSTEM_VERSION_BUILD_POS    0
#define SYSTEM_VERSION_BUILD_MASK   0x000000FFU
/* System control register */
typedef union {
    struct {
        uint32_t reset                :  1;  /* Software reset (write 1 to reset) */
        uint32_t enable               :  1;  /* System enable (1=enabled, 0=disabled) */
        uint32_t debug_mode           :  1;  /* Debug mode enable */
        uint32_t reserved             : 29;  /* Reserved for future use */
    } fields;
    uint32_t raw;
} system_control_t;

#define SYSTEM_CONTROL_RESET_POS    0
#define SYSTEM_CONTROL_RESET_MASK   0x00000001U
#define SYSTEM_CONTROL_ENABLE_POS    1
#define SYSTEM_CONTROL_ENABLE_MASK   0x00000001U
#define SYSTEM_CONTROL_DEBUG_MODE_POS    2
#define SYSTEM_CONTROL_DEBUG_MODE_MASK   0x00000001U
#define SYSTEM_CONTROL_RESERVED_POS    3
#define SYSTEM_CONTROL_RESERVED_MASK   0x1FFFFFFFU
/* System status register */
typedef union {
    struct {
        uint32_t ready                :  1;  /* System ready flag */
        uint32_t error                :  1;  /* Error flag */
        uint32_t locked               :  1;  /* Clock locked status */
        uint32_t reserved             : 29;  /* Reserved */
    } fields;
    uint32_t raw;
} system_status_t;

#define SYSTEM_STATUS_READY_POS    0
#define SYSTEM_STATUS_READY_MASK   0x00000001U
#define SYSTEM_STATUS_ERROR_POS    1
#define SYSTEM_STATUS_ERROR_MASK   0x00000001U
#define SYSTEM_STATUS_LOCKED_POS    2
#define SYSTEM_STATUS_LOCKED_MASK   0x00000001U
#define SYSTEM_STATUS_RESERVED_POS    3
#define SYSTEM_STATUS_RESERVED_MASK   0x1FFFFFFFU
/* LED control register */
typedef union {
    struct {
        uint32_t led0                 :  1;  /* LED0 control (1=on, 0=off) */
        uint32_t led1                 :  1;  /* LED1 control (1=on, 0=off) */
        uint32_t led2                 :  1;  /* LED2 control (1=on, 0=off) */
        uint32_t led3                 :  1;  /* LED3 control (1=on, 0=off) */
        uint32_t reserved             : 28;  /* Reserved */
    } fields;
    uint32_t raw;
} system_led_control_t;

#define SYSTEM_LED_CONTROL_LED0_POS    0
#define SYSTEM_LED_CONTROL_LED0_MASK   0x00000001U
#define SYSTEM_LED_CONTROL_LED1_POS    1
#define SYSTEM_LED_CONTROL_LED1_MASK   0x00000001U
#define SYSTEM_LED_CONTROL_LED2_POS    2
#define SYSTEM_LED_CONTROL_LED2_MASK   0x00000001U
#define SYSTEM_LED_CONTROL_LED3_POS    3
#define SYSTEM_LED_CONTROL_LED3_MASK   0x00000001U
#define SYSTEM_LED_CONTROL_RESERVED_POS    4
#define SYSTEM_LED_CONTROL_RESERVED_MASK   0x0FFFFFFFU
/* Scratch register 0 for testing */
typedef union {
    struct {
        uint32_t data                 : 32;  /* Scratch data */
    } fields;
    uint32_t raw;
} system_scratch0_t;

#define SYSTEM_SCRATCH0_DATA_POS    0
#define SYSTEM_SCRATCH0_DATA_MASK   0xFFFFFFFFU
/* Scratch register 1 for testing */
typedef union {
    struct {
        uint32_t data                 : 32;  /* Scratch data */
    } fields;
    uint32_t raw;
} system_scratch1_t;

#define SYSTEM_SCRATCH1_DATA_POS    0
#define SYSTEM_SCRATCH1_DATA_MASK   0xFFFFFFFFU
/* Timestamp counter lower 32 bits */
typedef union {
    struct {
        uint32_t count                : 32;  /* Lower 32 bits of timestamp */
    } fields;
    uint32_t raw;
} system_timestamp_lo_t;

#define SYSTEM_TIMESTAMP_LO_COUNT_POS    0
#define SYSTEM_TIMESTAMP_LO_COUNT_MASK   0xFFFFFFFFU
/* Timestamp counter upper 32 bits */
typedef union {
    struct {
        uint32_t count                : 32;  /* Upper 32 bits of timestamp */
    } fields;
    uint32_t raw;
} system_timestamp_hi_t;

#define SYSTEM_TIMESTAMP_HI_COUNT_POS    0
#define SYSTEM_TIMESTAMP_HI_COUNT_MASK   0xFFFFFFFFU
/* Read only test register */
typedef union {
    struct {
        uint32_t val                  : 32;  /* Read only test register */
    } fields;
    uint32_t raw;
} system_test_reg_t;

#define SYSTEM_TEST_REG_VAL_POS    0
#define SYSTEM_TEST_REG_VAL_MASK   0xFFFFFFFFU

/* Complete SYSTEM register block */
typedef struct {
    system_version_t version             ; /* Version and identification register */
    system_control_t control             ; /* System control register */
    system_status_t status              ; /* System status register */
    system_led_control_t led_control         ; /* LED control register */
    system_scratch0_t scratch0            ; /* Scratch register 0 for testing */
    system_scratch1_t scratch1            ; /* Scratch register 1 for testing */
    system_timestamp_lo_t timestamp_lo        ; /* Timestamp counter lower 32 bits */
    system_timestamp_hi_t timestamp_hi        ; /* Timestamp counter upper 32 bits */
    system_test_reg_t test_reg            ; /* Read only test register */
} system_regs_t;

/* Pointer to register block in memory */
#define SYSTEM_REGS    ((volatile system_regs_t *)SYSTEM_BASE_ADDR)

#endif /* __SYSTEM_CSR_H__ */