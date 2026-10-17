/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M12 -- every core of a triggered mesh row emits M12_N output packets of 6 KB
 * (the engine's output block), with its packet id and out-of-order BD id; word i
 * of packet j holds (core << 16) | (j << 8) | (i & 0xFF).
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "aie_kernel_runtime.h"
#include "engine_fabric.h"

#define M12_BLK 6144
#define M12_N 4
alignas(64) int8_t m12_go[64];
alignas(64) int32_t m12_out[M12_BLK / 4];
static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
#define LK_ACQ(id, v) acquire_greater_equal(EF_LOCK_BASE + (id), (v))
#define LK_REL(id, v) release(EF_LOCK_BASE + (id), (v))

// kernel_decl m12
int32_t main() {
    AieKcReg kc[8];
    const int init[4][2] = {{EF_LK_IN_EMPTY, 1}, {EF_LK_IN_FULL, 0}, {EF_LK_OUT_EMPTY, 1}, {EF_LK_OUT_FULL, 0}};
    for (int i = 0; i < 4; i++) {
        aie_kc_encode_lock(kc, init[i][0], init[i][1]);
        core_reg_write(kc[0].off, kc[0].val);
    }
    const unsigned cid = get_coreid();
    const int mc = (int)((cid >> 16) & 0x7F) - EF_PART_START_COL - EF_FIRST_COL;
    const int mr = (int)(cid & 0x1F) - EF_FIRST_ROW;
    core_reg_write_block(kc, aie_kc_encode_bd(kc, EF_BD_IN_PING, (uintptr_t)m12_go, 64, -1, EF_LK_IN_EMPTY, -1,
                                              EF_LK_IN_FULL, 1, 0, 0, 0, -1));
    aie_kc_encode_s2mm_start(kc, 0, EF_BD_IN_PING, 1, 0);
    core_reg_write(kc[0].off, kc[0].val);
    LK_ACQ(EF_LK_IN_FULL, 1);
    LK_REL(EF_LK_IN_EMPTY, 1);
    for (int j = 0; j < M12_N; j++) {
        LK_ACQ(EF_LK_OUT_EMPTY, 1);
        for (int i = 0; i < M12_BLK / 4; i++)
            m12_out[i] = ((mr * 4 + mc) << 16) | (j << 8) | (i & 0xFF);
        chess_memory_fence();
        core_reg_write_block(kc, aie_kc_encode_bd(kc, EF_BD_OUT_PING, (uintptr_t)m12_out, M12_BLK, -1, EF_LK_OUT_FULL,
                                                  -1, EF_LK_OUT_EMPTY, 1, 1, k_pkt[mr][mc], 0, k_ooo[mr][mc]));
        aie_kc_encode_mm2s_start(kc, 0, EF_BD_OUT_PING, 1, 0);
        core_reg_write(kc[0].off, kc[0].val);
        LK_REL(EF_LK_OUT_FULL, 1);
    }
    LK_ACQ(EF_LK_OUT_EMPTY, 1);
    for (;;) {
    }
    return 0;
}
