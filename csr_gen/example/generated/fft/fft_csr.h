/*============================================================================*/
/* File: fft_csr.h
 * Description: CSR definitions for FFT processing module
 * Generated: 2026-03-07 16:48:06
 * Source: evm/csr_gen/example/example_csr_definitions.yaml
 */
/*============================================================================*/

#ifndef __FFT_CSR_H__
#define __FFT_CSR_H__

#include <stdint.h>

/* Module base address */
#define FFT_BASE_ADDR    8192

/* Register offsets */
#define FFT_CONFIG_OFFSET    0
#define FFT_STATUS_OFFSET    4

/* Absolute register addresses */
#define FFT_CONFIG_ADDR      0x00002000U
#define FFT_STATUS_ADDR      0x00002004U

/* FFT configuration register */
typedef union {
    struct {
        uint32_t enable               :  1;  /* FFT enable */
        uint32_t size                 :  4;  /* FFT size (0=1K, 1=2K, 2=4K, 3=8K) */
        uint32_t window               :  3;  /* Window function (0=Rect, 1=Hanning, 2=Hamming, 3=Blackman) */
        uint32_t overlap              :  2;  /* Overlap (0=0%, 1=25%, 2=50%, 3=75%) */
        uint32_t reserved             : 22;  /* Reserved */
    } fields;
    uint32_t raw;
} fft_config_t;

#define FFT_CONFIG_ENABLE_POS    0
#define FFT_CONFIG_ENABLE_MASK   0x00000001U
#define FFT_CONFIG_SIZE_POS    1
#define FFT_CONFIG_SIZE_MASK   0x0000000FU
#define FFT_CONFIG_WINDOW_POS    5
#define FFT_CONFIG_WINDOW_MASK   0x00000007U
#define FFT_CONFIG_OVERLAP_POS    8
#define FFT_CONFIG_OVERLAP_MASK   0x00000003U
#define FFT_CONFIG_RESERVED_POS    10
#define FFT_CONFIG_RESERVED_MASK   0x003FFFFFU
/* FFT status register */
typedef union {
    struct {
        uint32_t busy                 :  1;  /* FFT processing active */
        uint32_t done                 :  1;  /* FFT processing complete */
        uint32_t overflow             :  1;  /* Output overflow detected */
        uint32_t reserved             : 29;  /* Reserved */
    } fields;
    uint32_t raw;
} fft_status_t;

#define FFT_STATUS_BUSY_POS    0
#define FFT_STATUS_BUSY_MASK   0x00000001U
#define FFT_STATUS_DONE_POS    1
#define FFT_STATUS_DONE_MASK   0x00000001U
#define FFT_STATUS_OVERFLOW_POS    2
#define FFT_STATUS_OVERFLOW_MASK   0x00000001U
#define FFT_STATUS_RESERVED_POS    3
#define FFT_STATUS_RESERVED_MASK   0x1FFFFFFFU

/* Complete FFT register block */
typedef struct {
    fft_config_t config              ; /* FFT configuration register */
    fft_status_t status              ; /* FFT status register */
} fft_regs_t;

/* Pointer to register block in memory */
#define FFT_REGS    ((volatile fft_regs_t *)FFT_BASE_ADDR)

#endif /* __FFT_CSR_H__ */