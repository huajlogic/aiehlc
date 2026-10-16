/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M3 host: time shim MM2S -> core S2MM streaming on the engine fabric
 * (row broadcast on ch1, column broadcast on ch0), per channel and combined.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>
#include <string.h>

extern unsigned char _binary_kernel_m3_start[];
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_out_col[EF_MESH_ROWS] = EF_OUT_SHIM_COL_TABLE;
static const int k_out_ch[EF_MESH_ROWS] = EF_OUT_SHIM_CH_TABLE;
#define M3_NT 4
static const int k_tests[M3_NT][4] = {{8192, 64, 1, 0}, {8192, 64, 0, 1}, {8192, 64, 1, 1}, {12288, 42, 1, 1}};
static XAie_LocType shim(int c) { return XAie_TileLoc((uint8_t)c, 0); }

static void arm_mm2s(XAie_DevInst *dev, int col, int ch, int8_t *src, int len) {
    XAie_DmaDesc d = __Runtime_dma_bd_config_multidim_ooo(dev, shim(col), src, ch, len, -1, 0, 0, 0, 0, 0, 0, -1, 3, 4,
                                                          64, 256, 512, 256 * 512, 0, 0, 0);
    __Runtime_startio(dev, __Runtime_dma_createio_4(shim(col), d, ch, ch, DMA_MM2S), ch, 1);
}

int main() {
    printf("=== M3: shim -> core stream bandwidth on the engine fabric ===\n");
    XAie_DevInst *devs[2];
    for (int p = 0; p < 1; p++)
        devs[p] = __Runtime_init_mesh_partition(p, EF_PART_START_COL + p * EF_PART_NUM_COLS, EF_PART_NUM_COLS);
    XAie_LocType tiles[16];
    for (int r = 0; r < EF_MESH_ROWS; r++)
        for (int c = 0; c < EF_MESH_COLS; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_m3_start);
    for (int p = 0; p < 1; p++)
        __Runtime_launch_kernel_group(devs[p], __Runtime_load_kernel_group_nt(devs[p], tiles, 16));
    XAie_DevInst *dev = devs[0];
    const int big = 64 * 8192;
    int8_t *src[16];
    for (int i = 0; i < 16; i++) {
        src[i] = (int8_t *)__Runtime_Alloc(big);
        memset(src[i], i, big);
        __Runtime_sync_for_dev(dev, src[i], big);
    }
    int8_t *out = (int8_t *)__Runtime_Alloc(16 * 64);
    for (int k = 1; k <= 4; k++) {
        XAie_DmaChannelEnable(dev, XAie_TileLoc((uint8_t)k, EF_MT_A_ROW), 0, DMA_MM2S);
        XAie_DmaChannelEnable(dev, XAie_TileLoc((uint8_t)k, EF_MT_B_ROW), 0, DMA_MM2S);
    }
    for (int np = 1; np <= 1; np++)
        for (int rep = 0; rep < 2; rep++)
            for (int t = 0; t < M3_NT; t++) {
                const int blk = k_tests[t][0], R = k_tests[t][1], u0 = k_tests[t][2], u1 = k_tests[t][3];
                XTime t0, t1, t2;
                XTime_GetTime(&t0);
                struct_ioevent ev[2][EF_MESH_ROWS];
                for (int p = 0; p < np; p++) {
                    dev = devs[p];
                    for (int r = 0; r < EF_MESH_ROWS; r++) {
                        XAie_LocType s = shim(k_out_col[r]);
                        XAie_DmaDesc d = {};
                        for (int c = 0; c < EF_MESH_COLS; c++)
                            d = __Runtime_dma_bd_config_multidim_ooo(dev, s, out + (r * 4 + c) * 64, k_ooo[r][c], 64,
                                                                     -1, 0, k_pkt[r][c], -1, 0, -1, 0, -1, 0, 0, 0, 0,
                                                                     0, 0, 0, 0, 0);
                        __Runtime_dma_channel_enable_ooo(dev, s, k_out_ch[r], DMA_S2MM);
                        ev[p][r] =
                            __Runtime_startio(dev, __Runtime_dma_createio_4(s, d, k_out_ch[r], k_ooo[r][0], DMA_S2MM),
                                              k_ooo[r][0], EF_MESH_COLS);
                    }
                    for (int k = 0; k < 4; k++) {
                        // memtile replay: MODE 0 = one 1-D BD of blk bytes repeated R times,
                        // MODE 1 = one BD covering everything (len blk*R, d0 wrap 256 words)
                        for (int which = 0; which < 2; which++) {
                            if (which == 0 ? !u1 : !u0)
                                continue;
                            XAie_LocType t =
                                XAie_TileLoc((uint8_t)(EF_FIRST_COL + k), which == 0 ? EF_MT_B_ROW : EF_MT_A_ROW);
                            XAie_DmaDesc d;
                            XAie_DmaDescInit(dev, &d, t);
                            XAie_DmaSetAddrLen(&d, EF_MT_BASE, (u32)blk);
                            XAie_DmaEnableBd(&d);
                            XAie_DmaWriteBd(dev, &d, t, 5);
                            XAie_DmaChannelSetStartQueue(dev, t, 0, DMA_MM2S, 5, (u32)R, XAIE_DISABLE);
                        }
                    }
                }
                XTime_GetTime(&t1);
                for (int p = 0; p < np; p++)
                    for (int r = 0; r < EF_MESH_ROWS; r++)
                        __Runtime_wait_io(devs[p], ev[p][r]);
                XTime_GetTime(&t2);
                const double us = 1e6 * (double)(t2 - t0) / COUNTS_PER_SECOND;
                const double arm = 1e6 * (double)(t1 - t0) / COUNTS_PER_SECOND;
                const double per_ch = (double)blk * R / (us - arm) / 1e3; /* GB/s per channel, after arming */
                const int nch = 4 * (u0 + u1) * np;
                printf("M3 parts %d rep %d test %d: blk %d x %d, ch0(B,col)=%d ch1(A,row)=%d: %.1f us (arm %.1f)  "
                       "%.2f GB/s per channel, %.2f GB/s total over %d shim channels\n",
                       np, rep, t, blk, R, u1, u0, us, arm, per_ch, per_ch * nch, nch);
            }
    printf("M3 DONE\n");
    return 0;
}
