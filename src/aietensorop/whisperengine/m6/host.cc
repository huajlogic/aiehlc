/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M6 host: run the mmul blocking probe on one core and print MAC/cycle per variant.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>

extern unsigned char _binary_kernel_m6_start[];
#define RES 0xFC00u

int main() {
    static const char *name[] = {"mac_chunk 64x48x48 (engine)",
                                 "2x2 64x48x48",
                                 "4x2 64x48x48",
                                 "2x3 64x48x48",
                                 "4x3 64x48x48",
                                 "2x2 32x64x64",
                                 "4x2 32x64x64",
                                 "2x4 32x64x64",
                                 "2x2 64x48x96",
                                 "4x2 64x48x96"};
    printf("=== M6: mmul<4,8,8> bf16 blocking probe ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    if (!dev)
        return 1;
    XAie_LocType tile = XAie_TileLoc((uint8_t)EF_FIRST_COL, (uint8_t)EF_FIRST_ROW);
    __Runtime_set_kernel_elf(_binary_kernel_m6_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, &tile, 1));
    u32 magic = 0, n = 0;
    XTime h0, h1;
    XTime_GetTime(&h0);
    do {
        XAie_DataMemRdWord(dev, tile, RES, &magic);
        XTime_GetTime(&h1);
    } while (magic != 0x4D364F4B && (double)(h1 - h0) / COUNTS_PER_SECOND < 2.0);
    if (magic != 0x4D364F4B) {
        printf("M6 FAIL: core not done\n");
        return 1;
    }
    XAie_DataMemRdWord(dev, tile, RES + 4, &n);
    for (unsigned v = 0; v < n; v++) {
        u32 cyc = 0, macs = 0;
        XAie_DataMemRdWord(dev, tile, RES + 4 * (2 + 2 * v), &cyc);
        XAie_DataMemRdWord(dev, tile, RES + 4 * (3 + 2 * v), &macs);
        const double per = (double)cyc / 8;
        printf("M6 %-28s %7.0f cycles/call  %6.1f MAC/cycle  %5.1f%% of 256\n", name[v], per, macs / per,
               100.0 * macs / per / 256);
    }
    return 0;
}
