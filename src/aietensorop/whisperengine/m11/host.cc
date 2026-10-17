/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M11 host: can a memory tile outside the 4-column mesh feed the mesh's memory
 * tiles? Memory tiles have no east/west stream ports, so the path is memtile ->
 * south -> shim row (east/west) -> north -> memtile. Times 1 and 2 such streams
 * over a 9-column partition (abs cols 2..10).
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include <stdio.h>

extern unsigned char _binary_kernel_m11_start[];
#define MT_BASE 0x80000u
#define LEN (448u * 1024u)
static double us(XTime a, XTime b) { return 1e6 * (double)(b - a) / COUNTS_PER_SECOND; }
static XAie_LocType L(int c, int r) { return XAie_TileLoc((uint8_t)c, (uint8_t)r); }

/* memtile (src,1) MM2S0 -> shim row, lane `lane` -> memtile (dst,1) S2MM0 */
static int route(XAie_DevInst *dev, int src, int dst, int lane) {
    int rc = 0;
    rc |= XAie_StrmConnCctEnable(dev, L(src, 1), DMA, 0, SOUTH, lane);
    rc |= XAie_StrmConnCctEnable(dev, L(src, 0), NORTH, lane, WEST, lane);
    for (int c = src - 1; c > dst; c--)
        rc |= XAie_StrmConnCctEnable(dev, L(c, 0), EAST, lane, WEST, lane);
    rc |= XAie_StrmConnCctEnable(dev, L(dst, 0), EAST, lane, NORTH, 2 + lane);
    rc |= XAie_StrmConnCctEnable(dev, L(dst, 1), SOUTH, 2 + lane, DMA, 0);
    return rc;
}
static void arm(XAie_DevInst *dev, XAie_LocType t, XAie_DmaDirection dir) {
    XAie_DmaDesc d;
    XAie_DmaDescInit(dev, &d, t);
    XAie_DmaSetAddrLen(&d, MT_BASE, LEN);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(dev, &d, t, 0);
    XAie_DmaChannelEnable(dev, t, 0, dir);
    XAie_DmaChannelSetStartQueue(dev, t, 0, dir, 0, 1, XAIE_DISABLE);
}
static int wait_ch(XAie_DevInst *dev, XAie_LocType t, XAie_DmaDirection dir) {
    u8 n = 1;
    for (long i = 0; n; i++) {
        XAie_DmaGetPendingBdCount(dev, t, 0, dir, &n);
        if (i > 20000000)
            return -1;
    }
    return 0;
}

int main() {
    printf("=== M11: memtile -> shim row -> memtile ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, 2, 9);
    if (!dev) {
        printf("M11 FAIL: 9-column partition init\n");
        return 1;
    }
    /* rel cols: mesh memtiles 1..4; far memtiles 6, 7 */
    if (route(dev, 6, 2, 0) || route(dev, 7, 3, 1)) {
        printf("M11 FAIL: route\n");
        return 1;
    }
    for (int pass = 1; pass <= 2; pass++) {
        XTime t0, t1;
        arm(dev, L(2, 1), DMA_S2MM);
        if (pass == 2)
            arm(dev, L(3, 1), DMA_S2MM);
        XTime_GetTime(&t0);
        arm(dev, L(6, 1), DMA_MM2S);
        if (pass == 2)
            arm(dev, L(7, 1), DMA_MM2S);
        int rc = wait_ch(dev, L(2, 1), DMA_S2MM);
        if (pass == 2)
            rc |= wait_ch(dev, L(3, 1), DMA_S2MM);
        XTime_GetTime(&t1);
        if (rc) {
            printf("M11 FAIL: %d stream(s) did not complete\n", pass);
            return 1;
        }
        const double t = us(t0, t1);
        printf("M11 %d stream(s): %u KB each in %.1f us = %.2f GB/s per stream, %.2f GB/s total\n", pass, LEN / 1024, t,
               LEN / t / 1e3, pass * LEN / t / 1e3);
    }
    printf("M11 DONE\n");
    return 0;
}
