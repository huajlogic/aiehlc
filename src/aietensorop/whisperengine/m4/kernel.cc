/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M4 -- DDR write probe: every core emits M4_R packets of M4_BLK bytes on its
 * output channel, once per host "go" (a 64 B block on S2MM ch0), forever.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "aie_kernel_runtime.h"
#include "engine_fabric.h"

#define M4_BLK 8192
#define M4_R 64
alignas(64) int8_t m4_go[64];
alignas(64) int8_t m4_out[M4_BLK];
static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
#define LK_ACQ(id, v) acquire_greater_equal(EF_LOCK_BASE + (id), (v))
#define LK_REL(id, v) release(EF_LOCK_BASE + (id), (v))

// kernel_decl m4
int32_t main() {
    AieKcReg kc[8];
    const int init[4][2] = {{EF_LK_IN_EMPTY, 1}, {EF_LK_IN_FULL, 0}, {EF_LK_OUT_EMPTY, 1}, {EF_LK_OUT_FULL, 0}};
    for (int i = 0; i < 4; i++) {
        aie_kc_encode_lock(kc, init[i][0], init[i][1]);
        core_reg_write(kc[0].off, kc[0].val);
    }
    const unsigned cid = get_coreid();
    const int mc = ((int)(cid >> 16) - EF_PART_START_COL - EF_FIRST_COL) % EF_PART_NUM_COLS;
    const int mr = (int)(cid & 0x1F) - EF_FIRST_ROW;
    for (;;) {
        core_reg_write_block(kc, aie_kc_encode_bd(kc, EF_BD_IN_PING, (uintptr_t)m4_go, 64, -1, EF_LK_IN_EMPTY, -1,
                                                  EF_LK_IN_FULL, 1, 0, 0, 0, -1));
        aie_kc_encode_s2mm_start(kc, 0, EF_BD_IN_PING, 1, 0);
        core_reg_write(kc[0].off, kc[0].val);
        LK_ACQ(EF_LK_IN_FULL, 1);
        LK_REL(EF_LK_IN_EMPTY, 1);
        // one BD, the same buffer, M4_R times (no lock: pure stream rate)
        core_reg_write_block(kc, aie_kc_encode_bd(kc, EF_BD_OUT_PING, (uintptr_t)m4_out, M4_BLK, -1, -1, 0, -1, 0, 1,
                                                  k_pkt[mr][mc], 0, k_ooo[mr][mc]));
        aie_kc_encode_mm2s_start(kc, 0, EF_BD_OUT_PING, M4_R, 0);
        core_reg_write(kc[0].off, kc[0].val);
    }
    return 0;
}
