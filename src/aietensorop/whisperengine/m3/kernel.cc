/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M3 -- stream bandwidth probe. Per test, every core drains R blocks of BLK
 * bytes on S2MM ch0 (row broadcast) and R blocks on S2MM ch1 (column
 * broadcast), touching nothing, then emits one 64-byte packet so the host can
 * time the whole transfer. Tests: {blk, rounds, use ch0, use ch1}.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "aie_kernel_runtime.h"
#include "engine_fabric.h"

#define M1_BLK 12288
alignas(64) int8_t m1_in[2 * M1_BLK];
alignas(64) int8_t m1_w[2 * M1_BLK];
alignas(64) int8_t m1_out[64];

static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
#define M1_NT 4
static const int k_tests[M1_NT][4] = {{8192, 64, 1, 0}, {8192, 64, 0, 1}, {8192, 64, 1, 1}, {12288, 42, 1, 1}};

#define LK_ACQ(id, v) acquire_greater_equal(EF_LOCK_BASE + (id), (v))
#define LK_REL(id, v) release(EF_LOCK_BASE + (id), (v))

static void cfg_s2mm(int ch, int bd0, int bd1, int8_t *b0, int8_t *b1, unsigned len, int lk_e, int lk_f,
                     unsigned rounds) {
    AieKcReg kc[8];
    core_reg_write_block(kc, aie_kc_encode_bd(kc, bd1, (uintptr_t)b1, len, -1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
    core_reg_write_block(kc, aie_kc_encode_bd(kc, bd0, (uintptr_t)b0, len, bd1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
    aie_kc_encode_s2mm_start(kc, ch, bd0, rounds / 2, 0);
    core_reg_write(kc[0].off, kc[0].val);
}

// kernel_decl m3
int32_t main() {
    AieKcReg kc[2];
    const int init[6][2] = {{EF_LK_IN_EMPTY, 2}, {EF_LK_IN_FULL, 0},   {EF_LK_W_EMPTY, 2},
                            {EF_LK_W_FULL, 0},   {EF_LK_OUT_EMPTY, 1}, {EF_LK_OUT_FULL, 0}};
    for (int i = 0; i < 6; i++) {
        aie_kc_encode_lock(kc, init[i][0], init[i][1]);
        core_reg_write(kc[0].off, kc[0].val);
    }
    const unsigned cid = get_coreid();
    const int mc =
        ((int)(cid >> 16) - EF_PART_START_COL - EF_FIRST_COL) % EF_PART_NUM_COLS; /* any copy of the fabric */
    const int mr = (int)(cid & 0x1F) - EF_FIRST_ROW;
    for (;;) {
        for (int t = 0; t < M1_NT; t++) {
            const unsigned blk = k_tests[t][0], R = k_tests[t][1];
            const int u0 = k_tests[t][2], u1 = k_tests[t][3];
            if (u0)
                cfg_s2mm(0, EF_BD_IN_PING, EF_BD_IN_PONG, m1_in, m1_in + M1_BLK, blk, EF_LK_IN_EMPTY, EF_LK_IN_FULL, R);
            if (u1)
                cfg_s2mm(1, EF_BD_W_PING, EF_BD_W_PONG, m1_w, m1_w + M1_BLK, blk, EF_LK_W_EMPTY, EF_LK_W_FULL, R);
            {
                AieKcReg o[8];
                core_reg_write_block(o, aie_kc_encode_bd(o, EF_BD_OUT_PING, (uintptr_t)m1_out, 64, -1, EF_LK_OUT_FULL,
                                                         -1, EF_LK_OUT_EMPTY, 1, 1, k_pkt[mr][mc], 0, k_ooo[mr][mc]));
                aie_kc_encode_mm2s_start(o, 0, EF_BD_OUT_PING, 1, 0);
                core_reg_write(o[0].off, o[0].val);
            }
            for (unsigned r = 0; r < R; r++) {
                if (u0) {
                    LK_ACQ(EF_LK_IN_FULL, 1);
                    LK_REL(EF_LK_IN_EMPTY, 1);
                }
                if (u1) {
                    LK_ACQ(EF_LK_W_FULL, 1);
                    LK_REL(EF_LK_W_EMPTY, 1);
                }
            }
            LK_ACQ(EF_LK_OUT_EMPTY, 1);
            m1_out[0] = (int8_t)t;
            chess_memory_fence();
            LK_REL(EF_LK_OUT_FULL, 1);
            LK_ACQ(EF_LK_OUT_EMPTY, 1); // drained
            LK_REL(EF_LK_OUT_EMPTY, 1);
        }
    }
    return 0;
}
