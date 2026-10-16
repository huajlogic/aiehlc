/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M0 host: load the GEMM probe on the 16 cores of the engine mesh, let it run,
 * read every core's cycle count and check one core's C against the CPU.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>
#include <string.h>

extern unsigned char _binary_kernel_m0_start[];
#define RES_OFF 0xFF00u /* m0_res (core view 0x7ff00) in tile data memory */

int main() {
    printf("=== M0: per-core bf16 mmul<4,8,8> throughput ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    if (!dev) {
        printf("M0 FAIL: partition init\n");
        return 1;
    }
    XAie_LocType tiles[16];
    for (int r = 0; r < EF_MESH_ROWS; r++)
        for (int c = 0; c < EF_MESH_COLS; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_m0_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, tiles, 16));
    XTime h0, h1;
    XTime_GetTime(&h0);
    do
        XTime_GetTime(&h1);
    while ((double)(h1 - h0) / COUNTS_PER_SECOND < 0.2);
    double best = 0, sum = 0;
    int ok = 0;
    for (int t = 0; t < 16; t++) {
        u32 w[6];
        for (int i = 0; i < 6; i++)
            XAie_DataMemRdWord(dev, tiles[t], RES_OFF + 4 * i, &w[i]);
        if (w[0] != 0x4D304F4B) {
            printf("M0 tile %d: not done (magic %08x)\n", t, (unsigned)w[0]);
            continue;
        }
        const double macs = (double)w[2] * w[3] * w[4] * w[5];
        const double eff = macs / w[1] / 256.0;
        printf("M0 tile %2d: M=%u N=%u K=%u reps=%u  %u cycles  %.1f MAC/cycle  %.1f%% of 256\n", t, (unsigned)w[2],
               (unsigned)w[3], (unsigned)w[4], (unsigned)w[5], (unsigned)w[1], macs / w[1], 100 * eff);
        best = eff > best ? eff : best;
        sum += eff;
        ok++;
    }
    printf("M0 SUMMARY tiles=%d mean %.1f%% best %.1f%% of peak\n", ok, ok ? 100 * sum / ok : 0, 100 * best);
    return ok == 16 ? 0 : 1;
}
