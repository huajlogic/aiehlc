/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#ifndef KERNEL_LOG_H
#define KERNEL_LOG_H

#include <stdint.h>

/*
 * Kernel Data Memory Log for AIE Debug
 *
 * Writes log entries (4-char tag + int32 value) to the last 2KB of AIE core
 * tile data memory. No stdlib, no printf — volatile memory writes only.
 *
 * Memory layout (512 int32 slots at offset 0xF800 of data memory):
 *   slot[0]   = write_index (number of int32s written, NOT entries)
 *   slot[1,2] = first entry: [tag_packed, value]
 *   slot[3,4] = second entry: [tag_packed, value]
 *   ...up to 255 entries (511 slots / 2 per entry)
 *
 * AIE core tile data memory: 64KB, base address 0x70000.
 * Log region: offset 0xF800 => absolute address 0x7F800.
 * Host reads via XAie_DataMemBlockRead(dev, tile, 0xF800, buf, 2048).
 */

/* Absolute address for kernel-side access (base 0x70000 + offset 0xF800) */
#define KLOG_BASE 0x7F800

/* Maximum number of int32 slots (slot 0 = write_index, slots 1..511 = data) */
#define KLOG_MAX_SLOTS 511

/* Magic marker written by klog_init: "KLOG" in ASCII big-endian */
#define KLOG_MAGIC 0x4B4C4F47

/* Pack 4 ASCII characters into one int32 (big-endian byte order) */
#define KLOG_TAG(a, b, c, d)                                                                                           \
    ((int32_t)(((uint8_t)(a) << 24) | ((uint8_t)(b) << 16) | ((uint8_t)(c) << 8) | ((uint8_t)(d))))

/* Pointer to the log region in data memory */
#define KLOG_PTR ((volatile int32_t *)KLOG_BASE)

/*
 * Pack the first 4 characters of a string into an int32.
 * Shorter strings are padded with null bytes.
 */
static inline int32_t klog_pack_tag(const char *tag) {
    uint8_t c0 = tag[0];
    uint8_t c1 = c0 ? (uint8_t)tag[1] : 0;
    uint8_t c2 = c1 ? (uint8_t)tag[2] : 0;
    uint8_t c3 = c2 ? (uint8_t)tag[3] : 0;
    return (int32_t)((c0 << 24) | (c1 << 16) | (c2 << 8) | c3);
}

/*
 * Write a log entry: 4-char tag + int32 value.
 * Each entry occupies 2 int32 slots.
 */
static inline void klog(const char *tag, int32_t val) {
    volatile int32_t *base = KLOG_PTR;
    int32_t wi = base[0]; /* current write_index */
    if (wi + 2 > KLOG_MAX_SLOTS)
        return; /* log full */
    base[wi + 1] = klog_pack_tag(tag);
    base[wi + 2] = val;
    base[0] = wi + 2;
}

/*
 * Initialize the kernel log: clear write_index, write magic marker.
 * Call once at the start of kernel main().
 */
static inline void klog_init(void) {
    volatile int32_t *base = KLOG_PTR;
    base[0] = 0; /* write_index = 0 */
    klog("KLOG", KLOG_MAGIC);
}

#endif /* KERNEL_LOG_H */
