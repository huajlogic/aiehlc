/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M7: host -> AIE register write cost under three memory types for the AIE
 * aperture (Device-nGnRnE as the BSP maps it, Device-nGnRE, Normal non-cacheable),
 * each checked by read-back.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include "xil_mmu.h"
#include <stdio.h>

extern unsigned char _binary_kernel_m7_start[];

static double now_us(void) {
    XTime t;
    XTime_GetTime(&t);
    return 1e6 * (double)t / COUNTS_PER_SECOND;
}
static uint64_t par_of(uint64_t va) {
    uint64_t par;
    __asm__ volatile("at s1e3r, %1\n isb\n mrs %0, par_el1" : "=r"(par) : "r"(va) : "memory");
    return par;
}

int main() {
    printf("=== M7: AIE register write cost by memory type ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    if (!dev)
        return 1;
    const u64 bd = XAie_GetTileAddr(dev, 1, 1) + 0xA0000 + 47 * 0x20; /* memtile (1,1) BD 47 */
    const u64 va = 0x20000000000ULL + bd;
    static const struct {
        const char *name;
        u64 attr;
    } m[3] = {{"Device-nGnRnE (BSP)", 0}, {"Device-nGnRE", DEVICE_MEMORY}, {"Normal non-cacheable", NORM_NONCACHE}};
    for (int k = 0; k < 3; k++) {
        if (m[k].attr)
            Xil_SetTlbAttributes((UINTPTR)0x20000000000ULL, m[k].attr);
        const uint64_t par = par_of(va);
        double t0 = now_us();
        for (int i = 0; i < 1000; i++)
            XAie_Write32(dev, bd + 4 * (i & 7), (u32)i);
        __asm__ volatile("dsb sy" ::: "memory");
        double t1 = now_us();
        u32 rb[8];
        for (int i = 0; i < 8; i++)
            XAie_Read32(dev, bd + 4 * i, &rb[i]);
        int ok = 1;
        for (int i = 0; i < 8; i++)
            ok &= rb[i] == (u32)(992 + i);
        printf("M7 %-22s PAR 0x%016llx attr[11:4]=0x%02llx: %.1f ns per write, read-back %s\n", m[k].name,
               (unsigned long long)par, (unsigned long long)((par >> 56) & 0xFF), (t1 - t0) * 1e3 / 1000,
               ok ? "OK" : "WRONG");
    }
    return 0;
}
