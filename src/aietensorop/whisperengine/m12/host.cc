/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M12 host: the two paths an on-chip FC1 -> FC2 hand-off needs, on an 11-column
 * partition (engine fabric on rel cols 1..4, storage memtiles beyond):
 *  1. mesh row 0's output packets (4 cores, out-of-order BD ids) are rerouted at
 *     their shim (rel 4) east along the shim row into storage memtile (5,1),
 *     whose S2MM runs in out-of-order mode;
 *  2. that memtile streams the data back west along the shim row into mesh
 *     memtile MT_A(1) = (1,1) S2MM0.
 * Both copies are checked word by word.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>

extern unsigned char _binary_kernel_m12_start[];
#define BLK 6144
#define N 4
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
static XAie_LocType L(int c, int r) { return XAie_TileLoc((uint8_t)c, (uint8_t)r); }
static double us(XTime a, XTime b) { return 1e6 * (double)(b - a) / COUNTS_PER_SECOND; }
static int wait_ch(XAie_DevInst *dev, XAie_LocType t, int ch, XAie_DmaDirection dir) {
    u8 n = 1;
    for (long i = 0; n; i++) {
        XAie_DmaGetPendingBdCount(dev, t, (u8)ch, dir, &n);
        if (i > 20000000)
            return -1;
    }
    return 0;
}
static void mt_bd(XAie_DevInst *dev, XAie_LocType t, int bd, u32 addr, u32 len, u32 it_step, u8 it_wrap) {
    XAie_DmaDesc d;
    XAie_DmaDescInit(dev, &d, t);
    XAie_DmaSetAddrLen(&d, addr, len);
    if (it_wrap > 1)
        XAie_DmaSetBdIteration(&d, it_step, it_wrap, 0);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(dev, &d, t, (u8)bd);
}
static long check(XAie_DevInst *dev, XAie_LocType t, u32 off, const char *what) {
    long bad = 0;
    for (int c = 0; c < 4; c++)
        for (int j = 0; j < N; j++)
            for (int i = 0; i < BLK / 4; i++) {
                u32 w = 0;
                XAie_DataMemRdWord(dev, t, off + (u32)((c * N + j) * BLK + i * 4), &w);
                const u32 want = ((u32)c << 16) | ((u32)j << 8) | (u32)(i & 0xFF);
                if (w != want && bad++ < 4)
                    printf("M12 %s core %d pkt %d word %d: got %08x want %08x\n", what, c, j, i, (unsigned)w,
                           (unsigned)want);
            }
    return bad;
}

int main() {
    printf("=== M12: core packets -> shim row -> storage memtile (OOO) -> shim row -> MT_A ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, 11);
    if (!dev) {
        printf("M12 FAIL: partition\n");
        return 1;
    }
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = L(EF_FIRST_COL + c, EF_FIRST_ROW + r);
    __Runtime_set_kernel_elf(_binary_kernel_m12_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, tiles, 16));

    /* 1. mesh row 0 -> shim (4,0) NORTH 1 -> EAST 0 -> (5,0) WEST 0 -> NORTH 2 -> memtile (5,1) S2MM0 */
    int rc = XAie_StrmConnCctDisable(dev, L(4, 0), NORTH, 1, SOUTH, 1);
    rc |= XAie_StrmConnCctEnable(dev, L(4, 0), NORTH, 1, EAST, 0);
    rc |= XAie_StrmConnCctEnable(dev, L(5, 0), WEST, 0, NORTH, 2);
    rc |= XAie_StrmConnCctEnable(dev, L(5, 1), SOUTH, 2, DMA, 0);
    /* 2. memtile (5,1) MM2S0 -> SOUTH 2 -> (5,0) NORTH 2 -> WEST 0 -> ... -> (1,0) NORTH 2 -> (1,1) S2MM0 */
    rc |= XAie_StrmConnCctEnable(dev, L(5, 1), DMA, 0, SOUTH, 2);
    rc |= XAie_StrmConnCctEnable(dev, L(5, 0), NORTH, 2, WEST, 0);
    for (int c = 4; c >= 2; c--)
        rc |= XAie_StrmConnCctEnable(dev, L(c, 0), EAST, 0, WEST, 0);
    rc |= XAie_StrmConnCctEnable(dev, L(1, 0), EAST, 0, NORTH, 2);
    rc |= XAie_StrmConnCctEnable(dev, L(1, 1), SOUTH, 2, DMA, 0);
    if (rc) {
        printf("M12 FAIL: routes rc %d\n", rc);
        return 1;
    }
    /* storage S2MM0, out-of-order: core c's packets land at c * N * BLK on, via BD k_ooo[0][c] */
    XAie_LocType st = L(5, 1);
    for (int c = 0; c < 4; c++)
        mt_bd(dev, st, k_ooo[0][c], 0x80000u + (u32)(c * N * BLK), BLK, BLK / 4, N);
    XAie_DmaChannelDesc cd;
    XAie_DmaChannelDescInit(dev, &cd, st);
    XAie_DmaChannelEnOutofOrder(&cd, XAIE_ENABLE);
    XAie_DmaWriteChannel(dev, &cd, st, 0, DMA_S2MM);
    XAie_DmaChannelEnable(dev, st, 0, DMA_S2MM);
    XAie_DmaChannelSetStartQueue(dev, st, 0, DMA_S2MM, (u8)k_ooo[0][0], 4 * N, XAIE_DISABLE);
    /* go: 64 B to mesh row 0 through MT_A (1,1) MM2S0 (the engine's row broadcast) */
    XTime t0, t1, t2;
    XTime_GetTime(&t0);
    mt_bd(dev, L(1, 1), 7, 0x80000u + 0x7FF00u, 64, 0, 0);
    XAie_DmaChannelEnable(dev, L(1, 1), 0, DMA_MM2S);
    XAie_DmaChannelSetStartQueue(dev, L(1, 1), 0, DMA_MM2S, 7, 1, XAIE_DISABLE);
    if (wait_ch(dev, st, 0, DMA_S2MM)) {
        printf("M12 FAIL: storage memtile did not receive the packets\n");
        return 1;
    }
    XTime_GetTime(&t1);
    const long b1 = check(dev, st, 0, "storage");
    printf("M12 path 1 (cores -> shim row -> storage, OOO): %d KB in %.1f us, %ld bad words\n", 4 * N * BLK / 1024,
           us(t0, t1), b1);
    /* 2. back west into MT_A S2MM0 at 0x40000 */
    mt_bd(dev, L(1, 1), 0, 0x80000u + 0x40000u, 4 * N * BLK, 0, 0);
    XAie_DmaChannelEnable(dev, L(1, 1), 0, DMA_S2MM);
    XAie_DmaChannelSetStartQueue(dev, L(1, 1), 0, DMA_S2MM, 0, 1, XAIE_DISABLE);
    XTime_GetTime(&t1);
    mt_bd(dev, st, 1, 0x80000u, 4 * N * BLK, 0, 0);
    XAie_DmaChannelEnable(dev, st, 0, DMA_MM2S);
    XAie_DmaChannelSetStartQueue(dev, st, 0, DMA_MM2S, 1, 1, XAIE_DISABLE);
    if (wait_ch(dev, L(1, 1), 0, DMA_S2MM)) {
        printf("M12 FAIL: MT_A did not receive the storage data\n");
        return 1;
    }
    XTime_GetTime(&t2);
    const long b2 = check(dev, L(1, 1), 0x40000u, "MT_A");
    printf("M12 path 2 (storage -> shim row -> MT_A S2MM0): %d KB in %.1f us, %ld bad words\n", 4 * N * BLK / 1024,
           us(t1, t2), b2);
    printf("M12 %s\n", b1 || b2 ? "FAIL" : "PASS");
    return 0;
}
