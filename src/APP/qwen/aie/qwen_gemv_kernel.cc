/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// qwen_gemv_kernel.cc -- included by qwen_gemv.cc (self test ELF) and qwen_gemv_lib.cc (library for the engine).
// qwen small-M int4 GEMM on the 4 x 4 mesh: one launch is y[4096 rows][M] = W[4096 x 4096] . x[M x 4096]
// with W in the qwen blob's Q4G64 layout (src/APP/qwen/engine/qwen_blob.h): per row block of 16 rows,
// 4 chunks of 16 K-groups (64 K each), a chunk = 16 x 512 B int4 tiles then 16 x 32 B bf16 row scales.
// Core c (mesh row-major) owns row blocks c * QG_U .. c * QG_U + QG_U - 1: its weights are one contiguous
// range, streamed once. x (M tokens, int8 per 64 with a float scale) is held by every core, in two halves of
// 32 K groups each: int8 tiles [32 groups][4][M][16] (8192 B), then the scales [32 groups][M] fp32 (512 B).
// y per row block: [M][16] fp32. The math is qw_matmul_cpu's: per group int32 sum, times w_scale x x_scale.
// Written as the data is laid out -- w = the launch's chunks [row block][k chunk][8704 B], x whole, y = row
// blocks -- and the compiler derives the DMA: w's dim 0 follows the linear core index 4 pm + pn (routed as a
// 2-D view), w is fed one stream per core through a MemTile ring, rings and BD dims are picked by the plan
// (skill naturalkernelplan). The DDR order of w is the plan's: qwen_convert.py applies the generated
// aiehlc_plan_arrange to every launch; y lands row-block order as declared (no output_tile_major).
#include "qwen_gemv_host.h"
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#ifdef QG_PERSISTENT
#pragma persistent_kernel
#endif

#define QG_K 4096
#define QG_M 4
#define QG_U 16
#define QG_CH 4
#define QG_CB 8704
#define QG_XB 17408
#define QG_YB 256
#define QG_NCH 1024 /* chunks per launch: 256 row blocks x QG_CH */
#define QG_NRB 256  /* row blocks per launch */

// w: one stream per core through a MemTile FIFO; x: the same block for every core, multicast, held once
#define QG_OPTS_W {.depth = 2, .stage = aie::stage::memtile_ring, .align = 64}
#define QG_OPTS_X {.depth = 1, .share = aie::share::broadcast, .stage = aie::stage::memtile_ring, .align = 64}

#if defined(__chess__)
// one 64-K group: 4 x mmul<4,16,16> int8 x int4, then acc += float(c) * (x_scale[m] * w_scale[n])
#define QG_GROUP(acc, wt, ws, xt, xs)                                                                                  \
    do {                                                                                                               \
        aie::mmul<4, 16, 16, int8_t, int4> mm_;                                                                        \
        mm_.mul(aie::load_v<64>(xt), aie::load_v<128>(wt).cast_to<int4>());                                            \
        mm_.mac(aie::load_v<64>((xt) + 64), aie::load_v<128>((wt) + 128).cast_to<int4>());                             \
        mm_.mac(aie::load_v<64>((xt) + 128), aie::load_v<128>((wt) + 256).cast_to<int4>());                            \
        mm_.mac(aie::load_v<64>((xt) + 192), aie::load_v<128>((wt) + 384).cast_to<int4>());                            \
        const aie::vector<float, 64> cf_ = aie::to_float(mm_.to_vector<int32_t>(), 0);                                 \
        const aie::accum<accfloat, 16> wsa_(aie::load_v<16>((const bfloat16 *)(ws)));                                  \
        const aie::vector<float, 16> wsf_ = wsa_.to_vector<float>();                                                   \
        const aie::vector<float, 64> sv_ =                                                                             \
            aie::concat(aie::mul(wsf_, (xs)[0]).to_vector<float>(), aie::mul(wsf_, (xs)[1]).to_vector<float>(),        \
                        aie::mul(wsf_, (xs)[2]).to_vector<float>(), aie::mul(wsf_, (xs)[3]).to_vector<float>());       \
        acc = aie::mac(acc, cf_, sv_);                                                                                 \
    } while (0)
#define QG_ACC_LOAD(acc, p) aie::accum<accfloat, 64> acc(aie::load_v<64>(p))
#define QG_ACC_SAVE(p, acc) aie::store_v((p), (acc).to_vector<float>())
#define QG_COPY_OUT(o, p) aie::store_v((float *)(o), aie::load_v<64>(p))
#else
// the same math, scalar (x86 trace / emulation)
#define QG_GROUP(acc, wt, ws, xt, xs)                                                                                  \
    do {                                                                                                               \
        for (int m_ = 0; m_ < QG_M; m_++)                                                                              \
            for (int n_ = 0; n_ < 16; n_++) {                                                                          \
                int32_t d_ = 0;                                                                                        \
                for (int k_ = 0; k_ < 64; k_++) {                                                                      \
                    const int e_ = (k_ % 16) * 16 + n_, b_ = (wt)[(k_ / 16) * 128 + e_ / 2];                           \
                    const int v_ = (e_ & 1) ? ((b_ >> 4) & 15) : (b_ & 15);                                            \
                    d_ += (v_ >= 8 ? v_ - 16 : v_) * (xt)[(k_ / 16) * 64 + m_ * 16 + k_ % 16];                         \
                }                                                                                                      \
                const uint32_t u_ = (uint32_t)((const uint8_t *)(ws))[2 * n_ + 1] << 24 |                              \
                                    (uint32_t)((const uint8_t *)(ws))[2 * n_] << 16;                                   \
                float w_;                                                                                              \
                memcpy(&w_, &u_, 4);                                                                                   \
                acc[m_ * 16 + n_] += (float)d_ * (w_ * (xs)[m_]);                                                      \
            }                                                                                                          \
    } while (0)
#define QG_ACC_LOAD(acc, p) float *acc = (p)
#define QG_ACC_SAVE(p, acc) (void)(acc)
#define QG_COPY_OUT(o, p) memcpy((o), (p), QG_YB)
#endif

// Core c = 4 pm + pn computes row blocks c * QG_U + u, u < QG_U, each over its QG_CH K chunks; the QG_U
// accumulators stay in core memory. x holds the K groups g = 0..63 in two halves of 32 (tiles, then scales).
__global__ void qwen_gemv(aie::port<input_window_int8 *, aie::shape<QG_NCH, QG_CB>> w,
                          aie::port<input_window_int8 *, aie::shape<1, QG_XB>> x,
                          aie::port<output_window_int8 *, aie::shape<QG_NRB, QG_YB>> y) {
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int c = pm * 4 + pn;
    alignas(64) static float accs[QG_U * 64];
    for (int i = 0; i < QG_U * 64; i++)
        accs[i] = 0;
    const int8_t *xb = aie::load_buffer(x, {0, 0}, {1, QG_XB}, QG_OPTS_X);
    for (int u = 0; u < QG_U; u++) {
        QG_ACC_LOAD(acc, accs + u * 64);
        for (int kc = 0; kc < QG_CH; kc++) {
            const int8_t *wb = aie::load_buffer(w, {(c * QG_U + u) * QG_CH + kc, 0}, {1, QG_CB}, QG_OPTS_W);
            for (int gg = 0; gg < 16; gg++) { /* group g = 16 kc + gg of the row block */
                const int g = kc * 16 + gg;
                const int8_t *xh = xb + (g / 32) * (QG_XB / 2);
                QG_GROUP(acc, wb + gg * 512, wb + 8192 + gg * 32, xh + (g % 32) * 256,
                         (const float *)(xh + 8192) + (g % 32) * QG_M);
            }
            aie::release(w);
        }
        QG_ACC_SAVE(accs + u * 64, acc);
    }
    aie::release(x);
    for (int u = 0; u < QG_U; u++) {
        int8_t *o = aie::store_buffer(y, {c * QG_U + u, 0}, {1, QG_YB}, {.depth = 2});
        QG_COPY_OUT(o, accs + u * 64);
        aie::commit(y);
    }
}

/* one launch; the qwen engine calls it through qa_ctx.launch (src/APP/qwen/engine/qwen_aie.h) */
extern "C" void qwen_gemv_launch(int8_t *w, int8_t *x, int8_t *y) {
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({2, 6, 0, 6}, 4, 4); // + the control-packet column
    qwen_gemv<<<mesh>>>(w, x, y);
}
