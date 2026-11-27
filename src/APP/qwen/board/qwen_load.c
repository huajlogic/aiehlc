/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* Weight loader (baremetal A78, run through netboot): its ELF carries one chunk of the qwen weight blob as a
 * loadable segment in DDR_LOW0 (netboot places segments there only); main copies it to its home in DDR_LOW1,
 * flushes the data cache and prints a checksum the host compares (qwen_board.py).
 * QW_DST: the chunk's destination, QW_BYTES: its size (both from the build). */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "xil_cache.h"

extern const uint8_t _binary_payload_bin_start[], _binary_payload_bin_end[];

/* position-dependent 64-bit sum: sum over words w[i] ^ i (mod 2^64); qwen_board.py computes the same */
static uint64_t qw_sum(const uint64_t *w, uint64_t n) {
    uint64_t s = 0;
    for (uint64_t i = 0; i < n; i++)
        s += w[i] ^ i;
    return s;
}

int main(void) {
    const uint8_t *src = _binary_payload_bin_start;
    const uint64_t n = (uint64_t)(_binary_payload_bin_end - _binary_payload_bin_start);
    uint8_t *dst = (uint8_t *)(uintptr_t)QW_DST;
    if (n != (uint64_t)QW_BYTES) {
        printf("QWLOAD ERROR payload %llu B, expected %llu\r\n", (unsigned long long)n, (unsigned long long)QW_BYTES);
        return 1;
    }
    memcpy(dst, src, n);
    Xil_DCacheFlushRange((INTPTR)dst, (INTPTR)n);
    printf("QWLOAD dst=0x%llx bytes=%llu sum=0x%016llx\r\n", (unsigned long long)QW_DST, (unsigned long long)n,
           (unsigned long long)qw_sum((const uint64_t *)dst, n / 8));
    return 0;
}
