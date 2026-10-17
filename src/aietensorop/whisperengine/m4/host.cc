/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M4 host: DDR read alone (shim -> memtiles), DDR write alone (16 cores ->
 * shims), and both at once, to see whether reads and writes share bandwidth.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>
#include <string.h>

extern unsigned char _binary_kernel_m4_start[];
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_out_col[EF_MESH_ROWS] = EF_OUT_SHIM_COL_TABLE;
static const int k_out_ch[EF_MESH_ROWS] = EF_OUT_SHIM_CH_TABLE;
#define BLK 8192
#define R 64
static XAie_LocType shim(int c) { return XAie_TileLoc((uint8_t)c, 0); }
static XAie_LocType mt(int c, int r) { return XAie_TileLoc((uint8_t)c, (uint8_t)r); }
static double us(XTime a, XTime b) { return 1e6 * (double)(b - a) / COUNTS_PER_SECOND; }
static void wait_ch(XAie_DevInst *dev, XAie_LocType t, int ch, XAie_DmaDirection dir) {
    u8 n = 1;
    while (n)
        XAie_DmaGetPendingBdCount(dev, t, (uint8_t)ch, dir, &n);
}

int main() {
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_m4_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, tiles, 16));
    const int rd = 448 * 1024; /* per memtile */
    int8_t *src = (int8_t *)__Runtime_Alloc((size_t)8 * rd);
    int8_t *dst = (int8_t *)__Runtime_Alloc((size_t)16 * R * BLK);
    int8_t *go = (int8_t *)__Runtime_Alloc(64);
    memset(src, 1, (size_t)8 * rd);
    __Runtime_sync_for_dev(dev, src, (size_t)8 * rd);
    for (int k = 1; k <= 4; k++) {
        XAie_DmaChannelEnable(dev, mt(k, 1), 1, DMA_S2MM); /* MT_A fills: S2MM1 */
        XAie_DmaChannelEnable(dev, mt(k, 2), 0, DMA_S2MM);
    }
    for (int rep = 0; rep < 2; rep++)
        for (int mode = 1; mode <= 3; mode++) { /* 1 read, 2 write, 3 both */
            struct_ioevent ev[4];
            if (mode & 2) {
                for (int r = 0; r < 4; r++) {
                    XAie_LocType s = shim(k_out_col[r]);
                    XAie_DmaDesc d = {};
                    for (int c = 0; c < 4; c++)
                        d = __Runtime_dma_bd_config_multidim_ooo(
                            dev, s, dst + (size_t)(r * 4 + c) * R * BLK, k_ooo[r][c], BLK, -1, 0, k_pkt[r][c], -1, 0,
                            -1, 0, k_ooo[r][c], 2, 4, 256, 1024, BLK / 1024, 0, 0, BLK, R);
                    __Runtime_dma_channel_enable_ooo(dev, s, k_out_ch[r], DMA_S2MM);
                    ev[r] = __Runtime_startio(dev, __Runtime_dma_createio_4(s, d, k_out_ch[r], k_ooo[r][0], DMA_S2MM),
                                              k_ooo[r][0], 4 * R);
                }
            }
            XTime t0, t1;
            XTime_GetTime(&t0);
            if (mode & 1)
                for (int k = 1; k <= 4; k++)
                    for (int row = 1; row <= 2; row++) {
                        XAie_DmaDesc d;
                        XAie_DmaDescInit(dev, &d, mt(k, row));
                        XAie_DmaSetAddrLen(&d, EF_MT_BASE, (u32)rd);
                        XAie_DmaEnableBd(&d);
                        const int mbd = row == 1 ? 24 : 0; /* odd channels own BDs 24..47 */
                        XAie_DmaWriteBd(dev, &d, mt(k, row), mbd);
                        XAie_DmaChannelSetStartQueue(dev, mt(k, row), row == 1, DMA_S2MM, mbd, 1, XAIE_DISABLE);
                        const int ch = row == 1 ? 1 : 0;
                        XAie_DmaDesc s = __Runtime_dma_bd_config_multidim_ooo(
                            dev, shim(k), src + (size_t)((k - 1) * 2 + row - 1) * rd, 12 + ch, rd, -1, 0, 0, 0, 0, 0, 0,
                            -1, 3, 4, 64, 256, 512, 256 * 512, 0, 0, 0);
                        __Runtime_startio(dev, __Runtime_dma_createio_4(shim(k), s, ch, 12 + ch, DMA_MM2S), 12 + ch, 1);
                    }
            if (mode & 2)
                for (int k = 1; k <= 4; k++) { /* "go": 64 B to each mesh row via MT_A */
                    XAie_DmaDesc d;
                    XAie_DmaDescInit(dev, &d, mt(k, 1));
                    XAie_DmaSetAddrLen(&d, EF_MT_BASE + 0x7FF00, 64);
                    XAie_DmaEnableBd(&d);
                    XAie_DmaWriteBd(dev, &d, mt(k, 1), 7);
                    XAie_DmaChannelEnable(dev, mt(k, 1), 0, DMA_MM2S);
                    XAie_DmaChannelSetStartQueue(dev, mt(k, 1), 0, DMA_MM2S, 7, 1, XAIE_DISABLE);
                }
            if (mode & 1)
                for (int k = 1; k <= 4; k++) {
                    wait_ch(dev, mt(k, 1), 1, DMA_S2MM);
                    wait_ch(dev, mt(k, 2), 0, DMA_S2MM);
                }
            XTime tr;
            XTime_GetTime(&tr);
            if (mode & 2)
                for (int r = 0; r < 4; r++)
                    __Runtime_wait_io(dev, ev[r]);
            XTime_GetTime(&t1);
            const double rb = (mode & 1) ? 8.0 * rd : 0, wb = (mode & 2) ? 16.0 * R * BLK : 0;
            printf("M4 rep %d mode %s: read %.0f KB done at %.1f us (%.2f GB/s), write %.0f KB, all done %.1f us "
                   "(write %.2f GB/s, combined %.2f GB/s)\n",
                   rep,
                   mode == 1   ? "read "
                   : mode == 2 ? "write"
                               : "both ",
                   rb / 1024, us(t0, tr), rb / us(t0, tr) / 1e3, wb / 1024, us(t0, t1), wb / us(t0, t1) / 1e3,
                   (rb + wb) / us(t0, t1) / 1e3);
        }
    printf("M4 DONE\n");
    return 0;
}
