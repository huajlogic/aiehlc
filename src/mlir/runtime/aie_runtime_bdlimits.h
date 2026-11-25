/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* Hardware BD-length limits and DMA channel-status Cur_BD decode, standalone
 * (no aie-rt include) so the self-test and the offline tools can use it.
 *
 * aie-rt writes a BD's Buffer_Length field masked to the field width: a MemTile
 * BD of 0x20000 words lands as length 0 and the channel moves nothing (or hangs
 * on its lock) with no error. __Runtime_bd_len_ok() is the check the runtime
 * runs before programming a BD (BDLEN_OVF on failure, BD not written).
 *
 *   tile kind        AIE2 / AIE2PS (AIE_GEN 2, 5)  Buffer_Length field
 *   MemTile          0x1FFFF words                 17 bits
 *   core (AIE) tile  0x3FFF  words                 14 bits
 *   shim NoC / PL    0xFFFFFFFF words              32 bits (no practical limit)
 *
 * Cur_BD in DMA_{S2MM,MM2S}_Status: AIE2 bits[27:24]; AIE2PS bits[28:25]
 * (HG raw 0x1C080012 -> 14; the AIE2 mask reads 12). */
#ifndef AIE_RUNTIME_BDLIMITS_H
#define AIE_RUNTIME_BDLIMITS_H

#include <stdint.h>

#ifndef AIE_GEN
#define AIE_GEN 5
#endif

/* tile kinds: same numbering as aie-rt XAIEGBL_TILE_TYPE_* */
#define RT_BD_TILE_CORE 0
#define RT_BD_TILE_SHIMNOC 1
#define RT_BD_TILE_SHIMPL 2
#define RT_BD_TILE_MEMTILE 3

#if AIE_GEN >= 2
#define RT_BD_LEN_MAX_MEMTILE_WORDS 0x1FFFFu
#define RT_BD_LEN_MAX_CORE_WORDS 0x3FFFu
#else
#define RT_BD_LEN_MAX_MEMTILE_WORDS 0u /* no MemTile on AIE1 */
#define RT_BD_LEN_MAX_CORE_WORDS 0x1FFFu
#endif
#define RT_BD_LEN_MAX_SHIM_WORDS 0xFFFFFFFFu

static inline uint32_t __Runtime_bd_len_max_words(int tile_kind) {
    switch (tile_kind) {
    case RT_BD_TILE_MEMTILE:
        return RT_BD_LEN_MAX_MEMTILE_WORDS;
    case RT_BD_TILE_CORE:
        return RT_BD_LEN_MAX_CORE_WORDS;
    default:
        return RT_BD_LEN_MAX_SHIM_WORDS;
    }
}

/* 1 when a BD of len_bytes fits the tile's Buffer_Length field, else 0. */
static inline int __Runtime_bd_len_ok(int tile_kind, int64_t len_bytes) {
    if (len_bytes < 0)
        return 0;
    const uint64_t words = ((uint64_t)len_bytes + 3u) / 4u;
    return words <= (uint64_t)__Runtime_bd_len_max_words(tile_kind);
}

static inline uint32_t __Runtime_bd_len_words(int64_t len_bytes) {
    return len_bytes < 0 ? 0u : (uint32_t)(((uint64_t)len_bytes + 3u) / 4u);
}

/* Cur_BD field of a DMA channel status word */
static inline uint32_t __Runtime_dma_cur_bd(uint32_t raw) {
#if AIE_GEN == 5
    return (raw & 0x1E000000u) >> 25;
#else
    return (raw & 0x0F000000u) >> 24;
#endif
}

#endif /* AIE_RUNTIME_BDLIMITS_H */
