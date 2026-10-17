/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M8 host: run the epilogue probe on one core; print cycles per 64x48 block and
 * how many outputs differ from the engine's epilogue (variant 0).
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include <stdio.h>

extern unsigned char _binary_kernel_m8_start[];
#define RES 0x9000u

int main() {
    static const char *name[] = {"engine epilogue (GELU)", "two loops, |x| compares", "two loops, GELU x2 unrolled",
                                 "bias + round only",      "restrict, out of place",  "restrict, out of place, x2"};
    printf("=== M8: GEMM epilogue probe ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    if (!dev)
        return 1;
    XAie_LocType tile = XAie_TileLoc((uint8_t)EF_FIRST_COL, (uint8_t)EF_FIRST_ROW);
    __Runtime_set_kernel_elf(_binary_kernel_m8_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, &tile, 1));
    u32 magic = 0, n = 0;
    XTime h0, h1;
    XTime_GetTime(&h0);
    do {
        XAie_DataMemRdWord(dev, tile, RES, &magic);
        XTime_GetTime(&h1);
    } while (magic != 0x4D384F4B && (double)(h1 - h0) / COUNTS_PER_SECOND < 2.0);
    if (magic != 0x4D384F4B) {
        printf("M8 FAIL: core not done\n");
        return 1;
    }
    XAie_DataMemRdWord(dev, tile, RES + 4, &n);
    for (unsigned v = 0; v < n; v++) {
        u32 cyc = 0, d = 0;
        XAie_DataMemRdWord(dev, tile, RES + 4 * (2 + 2 * v), &cyc);
        XAie_DataMemRdWord(dev, tile, RES + 4 * (3 + 2 * v), &d);
        printf("M8 v%u %-30s %7.0f cycles/block  %s %d\n", v, name[v], (double)cyc / 8, v ? "differs:" : "",
               v ? (int)d : 0);
    }
    return 0;
}
