/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* Self-test of aie_runtime_bdlimits.h (BD Buffer_Length guard + Cur_BD decode).
 *   gcc -O2 -std=gnu11 -DAIE_GEN=5 -Isrc/mlir/runtime -o t src/mlir/runtime/test/bdlimits_selftest.c && ./t
 * Last line: RTSELF mem_ovf=1 mem_ok=1 core_ovf=1 curbd=14 cases=N fail=0 */
#include <stdio.h>

#include "aie_runtime_bdlimits.h"

static int g_cases, g_fail;

static int check(const char *name, long long got, long long want) {
    g_cases++;
    if (got != want) {
        g_fail++;
        printf("FAIL %s: got %lld want %lld\n", name, got, want);
        return 0;
    }
    printf("ok   %s = %lld\n", name, got);
    return 1;
}

int main(void) {
    /* MemTile: 17-bit Buffer_Length (0x1FFFF words) */
    const int mem_ovf = check("memtile 0x20000 words refused", __Runtime_bd_len_ok(RT_BD_TILE_MEMTILE, 0x20000LL * 4), 0);
    const int mem_ok = check("memtile 0x1FFFF words accepted", __Runtime_bd_len_ok(RT_BD_TILE_MEMTILE, 0x1FFFFLL * 4), 1);
    check("memtile 0x7FFFD B rounds to 0x20000 words, refused", __Runtime_bd_len_ok(RT_BD_TILE_MEMTILE, 0x7FFFDLL), 0);
    check("memtile 4096x512 int8 half (0x40000 words) refused", __Runtime_bd_len_ok(RT_BD_TILE_MEMTILE, 4096LL * 256), 0);
    check("memtile max words", (long long)__Runtime_bd_len_max_words(RT_BD_TILE_MEMTILE), 0x1FFFF);
    /* core tile: 14-bit Buffer_Length (0x3FFF words) */
    const int core_ovf = check("core 0x4000 words refused", __Runtime_bd_len_ok(RT_BD_TILE_CORE, 0x4000LL * 4), 0);
    check("core 0x3FFF words accepted", __Runtime_bd_len_ok(RT_BD_TILE_CORE, 0x3FFFLL * 4), 1);
    /* shim: 32-bit field, a 64 MB BD is fine */
    check("shim NoC 64 MB accepted", __Runtime_bd_len_ok(RT_BD_TILE_SHIMNOC, 64LL << 20), 1);
    check("negative length refused", __Runtime_bd_len_ok(RT_BD_TILE_MEMTILE, -4), 0);
    check("words of 0x80000 B", (long long)__Runtime_bd_len_words(0x80000), 0x20000);
    /* Cur_BD: AIE2PS bits[28:25]; HG raw status 0x1C080012 -> 14 (AIE2 mask would give 12) */
    const unsigned curbd = __Runtime_dma_cur_bd(0x1C080012u);
    check("cur_bd(0x1C080012)", curbd, AIE_GEN == 5 ? 14 : 12);
    check("cur_bd(0x1E000000)", __Runtime_dma_cur_bd(0x1E000000u), AIE_GEN == 5 ? 15 : 14);
    check("cur_bd(0x02000000)", __Runtime_dma_cur_bd(0x02000000u), AIE_GEN == 5 ? 1 : 2);
    printf("RTSELF mem_ovf=%d mem_ok=%d core_ovf=%d curbd=%u cases=%d fail=%d\n", mem_ovf, mem_ok, core_ovf, curbd,
           g_cases, g_fail);
    return g_fail ? 1 : 0;
}
