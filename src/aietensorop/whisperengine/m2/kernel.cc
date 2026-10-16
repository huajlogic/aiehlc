/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M2 -- persistent bf16 GEMM core program fed by memory-tile replay.
 * Per op: a 4 KB header on A (S2MM ch0), then NB*MB blocks of 64x96 outputs:
 * each block = KCN k-chunks (A 64x32 on ch0, B 32x96 on ch1, ping-pong),
 * optional residual block (3 A chunks), epilogue to bf16, one 12 KB packet out.
 * Layouts: A chunk [rg 16][kt 4][4][8], B chunk [kt 4][nt 12][8][8],
 * C/out [rg 16][nt 12][4][8].
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "aie_kernel_runtime.h"
#include "engine_fabric.h"
#include "m2_desc.h"

alignas(64) bfloat16 m2_a[2][M2_A_CHUNK / 2];
alignas(64) bfloat16 m2_b[2][M2_B_CHUNK / 2];
alignas(64) float m2_c[M2_TM * M2_TN];
alignas(64) bfloat16 m2_out[M2_TM * M2_TN];
alignas(64) float m2_bias[4][12][8]; /* [nb][nt][8 cols] */

static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;

#define LK_ACQ(id, v) acquire_greater_equal(EF_LOCK_BASE + (id), (v))
#define LK_REL(id, v) release(EF_LOCK_BASE + (id), (v))

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;

static void cfg_s2mm(int ch, int bd0, int bd1, void *b0, void *b1, unsigned len, int lk_e, int lk_f, unsigned rounds) {
    AieKcReg kc[8];
    if (rounds == 1) {
        core_reg_write_block(kc, aie_kc_encode_bd(kc, bd0, (uintptr_t)b0, len, -1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
        aie_kc_encode_s2mm_start(kc, ch, bd0, 1, 0);
    } else {
        core_reg_write_block(kc, aie_kc_encode_bd(kc, bd1, (uintptr_t)b1, len, -1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
        core_reg_write_block(kc, aie_kc_encode_bd(kc, bd0, (uintptr_t)b0, len, bd1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
        aie_kc_encode_s2mm_start(kc, ch, bd0, rounds / 2, 0);
    }
    core_reg_write(kc[0].off, kc[0].val);
}

static void cfg_out(unsigned rounds, int pkt, int ooo) {
    AieKcReg kc[8];
    core_reg_write_block(kc, aie_kc_encode_bd(kc, EF_BD_OUT_PING, (uintptr_t)m2_out, M2_OUT_BLK, -1, EF_LK_OUT_FULL, -1,
                                              EF_LK_OUT_EMPTY, 1, 1, pkt, 0, ooo));
    aie_kc_encode_mm2s_start(kc, 0, EF_BD_OUT_PING, rounds, 0);
    core_reg_write(kc[0].off, kc[0].val);
}

// C[64x96] += A chunk (64x32) * B chunk (32x96); 2x2 register blocking.
__attribute__((noinline)) static void mac_chunk(const bfloat16 *__restrict A, const bfloat16 *__restrict B,
                                                float *__restrict C) {
    for (unsigned z = 0; z < 16; z += 2)
        chess_loop_range(8, 8) for (unsigned j = 0; j < 12; j += 2) chess_loop_range(6, 6)
            chess_prepare_for_pipelining {
            float *c00 = C + (z * 12 + j) * 32;
            float *c10 = c00 + 12 * 32;
            MM C00(aie::load_v<32>(c00)), C01(aie::load_v<32>(c00 + 32));
            MM C10(aie::load_v<32>(c10)), C11(aie::load_v<32>(c10 + 32));
            const bfloat16 *pa0 = A + z * 4 * 32;
            const bfloat16 *pa1 = pa0 + 4 * 32;
            const bfloat16 *pb = B + j * 64;
            for (unsigned k = 0; k < 4; k++)
                chess_unroll_loop() {
                    const aie::vector<bfloat16, 32> a0 = aie::load_v<32>(pa0 + k * 32);
                    const aie::vector<bfloat16, 32> a1 = aie::load_v<32>(pa1 + k * 32);
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 12 * 64);
                    const aie::vector<bfloat16, 64> b1 = aie::load_v<64>(pb + k * 12 * 64 + 64);
                    C00.mac(a0, b0);
                    C01.mac(a0, b1);
                    C10.mac(a1, b0);
                    C11.mac(a1, b1);
                }
            aie::store_v(c00, C00.template to_vector<float>());
            aie::store_v(c00 + 32, C01.template to_vector<float>());
            aie::store_v(c10, C10.template to_vector<float>());
            aie::store_v(c10 + 32, C11.template to_vector<float>());
        }
}

__attribute__((noinline)) static void zero_c(float *C) {
    const aie::vector<float, 32> z = aie::zeros<float, 32>();
    for (unsigned i = 0; i < M2_TM * M2_TN / 32; i++)
        chess_prepare_for_pipelining aie::store_v(C + i * 32, z);
}

// out = bf16(C + bias [+ res]) in the same [rg][nt][4][8] order.
__attribute__((noinline)) static void epilogue(const float *C, const float *bias, bfloat16 *out, int use_bias) {
    for (unsigned rg = 0; rg < 16; rg++)
        for (unsigned nt = 0; nt < 12; nt++)
            chess_prepare_for_pipelining {
                aie::vector<float, 32> v = aie::load_v<32>(C + (rg * 12 + nt) * 32);
                if (use_bias) {
                    const aie::vector<float, 8> b8 = aie::load_v<8>(bias + nt * 8);
                    v = aie::add(v, aie::concat(b8, b8, b8, b8));
                }
                aie::accum<accfloat, 32> acc;
                acc.from_vector(v, 0);
                aie::store_v(out + (rg * 12 + nt) * 32, acc.template to_vector<bfloat16>());
            }
}

// kernel_decl m2
int32_t main() {
    AieKcReg kc[2];
    const int init[6][2] = {{EF_LK_IN_EMPTY, 2}, {EF_LK_IN_FULL, 0},   {EF_LK_W_EMPTY, 2},
                            {EF_LK_W_FULL, 0},   {EF_LK_OUT_EMPTY, 1}, {EF_LK_OUT_FULL, 0}};
    for (int i = 0; i < 6; i++) {
        aie_kc_encode_lock(kc, init[i][0], init[i][1]);
        core_reg_write(kc[0].off, kc[0].val);
    }
    aie::set_rounding(aie::rounding_mode::conv_even);
    const unsigned cid = get_coreid();
    const int mc = ((int)(cid >> 16) - EF_PART_START_COL - EF_FIRST_COL) % EF_PART_NUM_COLS;
    const int mr = (int)(cid & 0x1F) - EF_FIRST_ROW;
    const int pkt = k_pkt[mr][mc], ooo = k_ooo[mr][mc];
    for (;;) {
        // header: one A chunk into ping
        cfg_s2mm(0, EF_BD_IN_PING, EF_BD_IN_PONG, m2_a[0], m2_a[1], M2_HDR_BYTES, EF_LK_IN_EMPTY, EF_LK_IN_FULL, 1);
        LK_ACQ(EF_LK_IN_FULL, 1);
        const int32_t *h = (const int32_t *)m2_a[0];
        const int MB = h[MH_MB], NB = h[MH_NB], KCN = h[MH_KCN], flags = h[MH_FLAGS];
        const int use_bias = flags & M2_F_BIAS;
        if (use_bias) {
            const bfloat16 *bsrc = (const bfloat16 *)((const int8_t *)m2_a[0] + M2_BIAS_OFF);
            for (int nb = 0; nb < NB; nb++)
                for (int nt = 0; nt < 12; nt++)
                    for (int i = 0; i < 8; i++)
                        m2_bias[nb][nt][i] = (float)bsrc[(mc * NB + nb) * M2_TN + nt * 8 + i];
        }
        chess_memory_fence();
        LK_REL(EF_LK_IN_EMPTY, 1);

        const unsigned blocks = (unsigned)(NB * MB);
        cfg_s2mm(0, EF_BD_IN_PING, EF_BD_IN_PONG, m2_a[0], m2_a[1], M2_A_CHUNK, EF_LK_IN_EMPTY, EF_LK_IN_FULL,
                 blocks * KCN);
        cfg_s2mm(1, EF_BD_W_PING, EF_BD_W_PONG, m2_b[0], m2_b[1], M2_B_CHUNK, EF_LK_W_EMPTY, EF_LK_W_FULL,
                 blocks * KCN);
        cfg_out(blocks, pkt, ooo);
        unsigned ia = 0, ib = 0;
        for (int nb = 0; nb < NB; nb++)
            for (int mb = 0; mb < MB; mb++) {
                zero_c(m2_c);
                for (int k = 0; k < KCN; k++) {
                    LK_ACQ(EF_LK_IN_FULL, 1);
                    LK_ACQ(EF_LK_W_FULL, 1);
#ifndef M2_NO_MAC
                    mac_chunk(m2_a[ia], m2_b[ib], m2_c);
#endif
                    LK_REL(EF_LK_IN_EMPTY, 1);
                    LK_REL(EF_LK_W_EMPTY, 1);
                    ia ^= 1;
                    ib ^= 1;
                }
                LK_ACQ(EF_LK_OUT_EMPTY, 1);
                epilogue(m2_c, &m2_bias[nb][0][0], m2_out, use_bias);
                chess_memory_fence();
                LK_REL(EF_LK_OUT_FULL, 1);
            }
        LK_ACQ(EF_LK_OUT_EMPTY, 1); // last packet drained: BDs may be rewritten
        LK_REL(EF_LK_OUT_EMPTY, 1);
    }
    return 0;
}
