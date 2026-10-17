/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M9 host: run the LayerNorm-apply probe on one core; print cycles per 64x48
 * block and how many fp32 outputs differ (bitwise) from the engine's ln_apply.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>

extern unsigned char _binary_kernel_m9_start[];
#define RES 0x9000u

int main() {
    static const char *name[] = {"engine ln_apply", "nt unrolled", "flat, per-rg operands staged", "flat x2"};
    printf("=== M9: LayerNorm apply probe ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    if (!dev)
        return 1;
    XAie_LocType tile = XAie_TileLoc((uint8_t)EF_FIRST_COL, (uint8_t)EF_FIRST_ROW);
    __Runtime_set_kernel_elf(_binary_kernel_m9_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, &tile, 1));
    u32 magic = 0, n = 0;
    XTime h0, h1;
    XTime_GetTime(&h0);
    do {
        XAie_DataMemRdWord(dev, tile, RES, &magic);
        XTime_GetTime(&h1);
    } while (magic != 0x4D394F4B && (double)(h1 - h0) / COUNTS_PER_SECOND < 2.0);
    if (magic != 0x4D394F4B) {
        printf("M9 FAIL: core not done\n");
        return 1;
    }
    XAie_DataMemRdWord(dev, tile, RES + 4, &n);
    for (unsigned v = 0; v < n; v++) {
        u32 cyc = 0, d = 0;
        XAie_DataMemRdWord(dev, tile, RES + 4 * (2 + 2 * v), &cyc);
        XAie_DataMemRdWord(dev, tile, RES + 4 * (3 + 2 * v), &d);
        printf("M9 v%u %-32s %7.0f cycles/block  differs: %d\n", v, name[v], (double)cyc / 8, (int)d);
    }
    return 0;
}
