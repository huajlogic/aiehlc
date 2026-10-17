/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M5 host: run the attention probe on one core, print each variant's cycles per
 * stage and its error against an exact CPU softmax(QK^T)V.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include "we_desc.h"
#include <math.h>
#include <stdio.h>
#include <string.h>

extern unsigned char _binary_kernel_m5_start[];
#define NKC 8
#define OFF(a) ((a) - 0x70000u)

static float rd_f(XAie_DevInst *dev, XAie_LocType t, uint32_t off) {
    u32 w = 0;
    XAie_DataMemRdWord(dev, t, off, &w);
    float f;
    memcpy(&f, &w, 4);
    return f;
}

int main() {
    printf("=== M5: attention inner loop probe ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    if (!dev) {
        printf("M5 FAIL: partition init\n");
        return 1;
    }
    XAie_LocType tile = XAie_TileLoc((uint8_t)EF_FIRST_COL, (uint8_t)EF_FIRST_ROW);
    __Runtime_set_kernel_elf(_binary_kernel_m5_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, &tile, 1));
    u32 magic = 0;
    XTime h0, h1;
    XTime_GetTime(&h0);
    do {
        XAie_DataMemRdWord(dev, tile, OFF(0x7fc00), &magic);
        XTime_GetTime(&h1);
    } while (magic != 0x4D354F4B && (double)(h1 - h0) / COUNTS_PER_SECOND < 2.0);
    if (magic != 0x4D354F4B) {
        printf("M5 FAIL: core not done (magic %08x)\n", (unsigned)magic);
        return 1;
    }
    // exact reference
    static double ref[WE_QB][64];
    const int T = NKC * WE_KCH;
    for (int r = 0; r < WE_QB; r++) {
        double s[NKC * WE_KCH], mx = -1e300, den = 0;
        for (int k = 0; k < T; k++) {
            double a = 0;
            for (int d = 0; d < 64; d++)
                a += (double)((r * 7 + d * 3) % 17 - 8) * ((double)((k * 5 + d * 11) % 19 - 9) / 64.0);
            s[k] = a;
            mx = a > mx ? a : mx;
        }
        for (int d = 0; d < 64; d++)
            ref[r][d] = 0;
        for (int k = 0; k < T; k++) {
            const double p = exp2(s[k] - mx);
            den += p;
            for (int d = 0; d < 64; d++)
                ref[r][d] += p * (double)((k * 3 + d * 7) % 13 - 6);
        }
        for (int d = 0; d < 64; d++)
            ref[r][d] /= den;
    }
    const uint32_t obase[4] = {0x78000, 0x7a000, 0x7dc00, 0x7dc00};
    const int toff[4] = {4, 8, 20, 24};
    for (int v = 0; v < 3; v++) {
        u32 c[4];
        for (int i = 0; i < 4; i++)
            XAie_DataMemRdWord(dev, tile, OFF(0x7fc00) + 4 * (toff[v] + i), &c[i]);
        double maxerr = 0;
        for (int r = 0; r < WE_QB; r++) {
            double L = 0;
            for (int ln = 0; ln < (v == 2 ? 1 : 8); ln++) /* v2: every lane holds the row sum */
                L += rd_f(dev, tile, OFF(0x7cc00) + 4 * (v * 256 + (r / 4) * 32 + (r % 4) * 8 + ln));
            for (int d = 0; d < 64; d++) {
                const float o = rd_f(dev, tile, OFF(obase[v]) + 4 * (((r / 4) * 8 + d / 8) * 32 + (r % 4) * 8 + d % 8));
                const double e = fabs(o / L - ref[r][d]);
                maxerr = e > maxerr ? e : maxerr;
            }
        }
        const double per = (double)(c[0] + c[1] + c[2]) / NKC;
        printf("M5 v%d: per chunk qk %u softmax %u pv %u = %.0f cycles (%.1f%% of 256 MAC/cycle), max |err| %.4f\n", v,
               (unsigned)c[0] / NKC, (unsigned)c[1] / NKC, (unsigned)c[2] / NKC, per,
               100.0 * 2 * WE_QB * 64 * WE_KCH / per / 256, maxerr);
        printf("M5 v%d: first chunk qk %u, later chunks qk %u\n", v, (unsigned)c[3],
               (unsigned)(c[0] - c[3]) / (NKC - 1));
    }
    u32 x[3];
    for (int i = 0; i < 3; i++)
        XAie_DataMemRdWord(dev, tile, OFF(0x7fc00) + 4 * (16 + i), &x[i]);
    printf("M5 v1: %u slow row groups in %d chunks (qk column = fused qk+softmax)\n", (unsigned)x[2], NKC);
    u32 y[5];
    for (int i = 0; i < 5; i++)
        XAie_DataMemRdWord(dev, tile, OFF(0x7fc00) + 4 * (30 + i), &y[i]);
    if (y[2])
        printf("M5 v3 split: qk42 %u, exp %u (separate dst 2x unrolled %u, no max %u) cycles per chunk\n",
               (unsigned)(y[0] / y[2]), (unsigned)(y[1] / y[2]), (unsigned)(y[3] / y[2]), (unsigned)(y[4] / y[2]));
    return 0;
}
