/*============================================================================*/
/* File: adc_csr.h
 * Description: CSR definitions for ADC control and status module
 * Generated: 2026-03-07 16:48:06
 * Source: evm/csr_gen/example/example_csr_definitions.yaml
 */
/*============================================================================*/

#ifndef __ADC_CSR_H__
#define __ADC_CSR_H__

#include <stdint.h>

/* Module base address */
#define ADC_BASE_ADDR    4096

/* Register offsets */
#define ADC_CONFIG_OFFSET    0
#define ADC_STATUS_OFFSET    4
#define ADC_SAMPLE_COUNT_OFFSET    8

/* Absolute register addresses */
#define ADC_CONFIG_ADDR      0x00001000U
#define ADC_STATUS_ADDR      0x00001004U
#define ADC_SAMPLE_COUNT_ADDR      0x00001008U

/* ADC configuration register */
typedef union {
    struct {
        uint32_t enable_ch0           :  1;  /* Enable channel 0 */
        uint32_t enable_ch1           :  1;  /* Enable channel 1 */
        uint32_t enable_ch2           :  1;  /* Enable channel 2 */
        uint32_t enable_ch3           :  1;  /* Enable channel 3 */
        uint32_t sample_rate          :  4;  /* Sample rate divider */
        uint32_t reserved             : 20;  /* Reserved */
    } fields;
    uint32_t raw;
} adc_config_t;

#define ADC_CONFIG_ENABLE_CH0_POS    0
#define ADC_CONFIG_ENABLE_CH0_MASK   0x00000001U
#define ADC_CONFIG_ENABLE_CH1_POS    1
#define ADC_CONFIG_ENABLE_CH1_MASK   0x00000001U
#define ADC_CONFIG_ENABLE_CH2_POS    2
#define ADC_CONFIG_ENABLE_CH2_MASK   0x00000001U
#define ADC_CONFIG_ENABLE_CH3_POS    3
#define ADC_CONFIG_ENABLE_CH3_MASK   0x00000001U
#define ADC_CONFIG_SAMPLE_RATE_POS    8
#define ADC_CONFIG_SAMPLE_RATE_MASK   0x0000000FU
#define ADC_CONFIG_RESERVED_POS    12
#define ADC_CONFIG_RESERVED_MASK   0x000FFFFFU
/* ADC status register */
typedef union {
    struct {
        uint32_t locked               :  1;  /* ADC clock locked */
        uint32_t aligned              :  1;  /* Channels aligned */
        uint32_t overflow             :  1;  /* Data overflow detected */
        uint32_t reserved             : 29;  /* Reserved */
    } fields;
    uint32_t raw;
} adc_status_t;

#define ADC_STATUS_LOCKED_POS    0
#define ADC_STATUS_LOCKED_MASK   0x00000001U
#define ADC_STATUS_ALIGNED_POS    1
#define ADC_STATUS_ALIGNED_MASK   0x00000001U
#define ADC_STATUS_OVERFLOW_POS    2
#define ADC_STATUS_OVERFLOW_MASK   0x00000001U
#define ADC_STATUS_RESERVED_POS    3
#define ADC_STATUS_RESERVED_MASK   0x1FFFFFFFU
/* Sample counter */
typedef union {
    struct {
        uint32_t count                : 32;  /* Number of samples captured */
    } fields;
    uint32_t raw;
} adc_sample_count_t;

#define ADC_SAMPLE_COUNT_COUNT_POS    0
#define ADC_SAMPLE_COUNT_COUNT_MASK   0xFFFFFFFFU

/* Complete ADC register block */
typedef struct {
    adc_config_t config              ; /* ADC configuration register */
    adc_status_t status              ; /* ADC status register */
    adc_sample_count_t sample_count        ; /* Sample counter */
} adc_regs_t;

/* Pointer to register block in memory */
#define ADC_REGS    ((volatile adc_regs_t *)ADC_BASE_ADDR)

#endif /* __ADC_CSR_H__ */