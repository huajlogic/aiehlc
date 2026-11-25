/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#include "simpleconv2d_new_load.h"
// simpleconv2dkernel_port.cc through the dataflow plan (doc/design/dmaphop_dataflow_plan.md, "Per-core
// copies"): the input blocks follow the mesh row only and the weights the mesh column only, so both are
// {.share = aie::share::broadcast} -- the input one multicast stream per mesh row through a MemTile FIFO ring
// (its halo blocks repeated in DDR by aiehlc_plan_arrange), the weights one per mesh column held in a
// MemTile across launches; each core keeps its own copy of both, on its own S2MM channels.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#define OPTS_IN {.depth = 2, .share = aie::share::broadcast, .stage = aie::stage::memtile_ring, .ring = 2}
#define OPTS_W {.depth = 2, .share = aie::share::broadcast, .stage = aie::stage::memtile, .keep = true}
__global__ void conv2d_spatial(aie::port<input_window_int8 *, aie::IFM, aie::shape<230, 230, 4>> win_a,
                               aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<64, 7, 7, 4>> win_b,
                               aie::port<output_window_int8 *, aie::OFM, aie::shape<112, 112, 64>> win_c) {
    // The operator and the tiling live in the kernel.
    const int KH = 7, KW = 7, S = 2, C = 4;         // 7x7 stride-2 conv, 4 (aligned) channels
    const int oh_t = 7, ow_t = 28, oc_t = 16;       // output block computed per round
    const int ih_t = (oh_t - 1) * S + KH;           // 19: input footprint of one output block
    const int iw_t = (ow_t - 1) * S + KW;           // 61
    const int oh_core = 112 / aie::num_programs(0); // 28 output rows per mesh row
    const int TAPS = KH * KW * C;                   // 196
    const int ROW = iw_t * C;                       // 244 bytes per slab row
    const int pid_h = aie::program_id(0);           // mesh row: which OH band
    const int pid_c = aie::program_id(1);           // mesh col: which OC group
    using MM = aie::mmul<8, 8, 8, int8_t, int8_t>;
    aie::set_saturation(aie::saturation_mode::saturate); // int8 results clamp like the scalar reference
    const int8_t *w = aie::load_buffer(win_b, {pid_c * oc_t, 0, 0, 0}, {oc_t, KH, KW, C}, OPTS_W);
    alignas(64) int8_t Bp[7 * 4 * 2 * 64];
    for (int kh = 0; kh < KH; kh++)
        for (int kb = 0; kb < 4; kb++)
            for (int nb = 0; nb < 2; nb++)
                for (int k = 0; k < 8; k++)
                    for (int n = 0; n < 8; n++) {
                        const int byte = kb < 3 ? kb * 8 + k : 20 + k; // tap byte within kernel row kh
                        const bool live = kb < 3 || k >= 4;
                        Bp[(((kh * 4 + kb) * 2 + nb) * 8 + k) * 8 + n] =
                            live ? w[(nb * 8 + n) * TAPS + kh * KW * C + byte] : (int8_t)0;
                    }
    aie::release(win_b);
    const aie::accum<acc32, 64> zero = aie::zeros<acc32, 64>();

    for (int i = 0; i < oh_core / oh_t; i++) {          // 4 row blocks
        for (int j = 0; j < 112 / ow_t; j++) {          // 4 column blocks
            const int oh0 = pid_h * oh_core + i * oh_t; // output block origin
            const int ow0 = j * ow_t;
            // Its input footprint (the halo overlaps the neighbouring blocks).
            const int8_t *x = aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C}, OPTS_IN);
            int8_t *y = aie::store_buffer(win_c, {oh0, ow0, pid_c * oc_t}, {oh_t, ow_t, oc_t});

            for (int oh = 0; oh < oh_t; oh++) {
                for (int pass = 0; pass < 2; pass++) {
                    const int owA = pass * 16, owB = pass * 16 + (pass ? 4 : 8); // M-block first columns
                    MM cA0(zero), cA1(zero), cB0(zero), cB1(zero);
                    for (int kh = 0; kh < KH; kh++)
                        chess_prepare_for_pipelining chess_loop_range(7, 7) {
                            const int8_t *r = x + (oh * S + kh) * ROW;
                            const int8_t *bk = Bp + kh * 4 * 2 * 64;
                            for (int kb = 0; kb < 4; kb++)
                                chess_unroll_loop() {
                                    const int off = kb < 3 ? kb * 8 : 20;
                                    const aie::vector<int8_t, 64> aA = aie::load_unaligned_v<64>(r + owA * 8 + off, 4);
                                    const aie::vector<int8_t, 64> aB = aie::load_unaligned_v<64>(r + owB * 8 + off, 4);
                                    const aie::vector<int8_t, 64> b0 = aie::load_v<64>(bk + (kb * 2 + 0) * 64);
                                    const aie::vector<int8_t, 64> b1 = aie::load_v<64>(bk + (kb * 2 + 1) * 64);
                                    cA0.mac(aA, b0);
                                    cA1.mac(aA, b1);
                                    cB0.mac(aB, b0);
                                    cB1.mac(aB, b1);
                                }
                        }
                    // 8 columns x 16 channels = 128 contiguous output bytes:
                    // interleave the two N-blocks 8 channels at a time.
                    const int owc[2] = {owA, owB};
                    const MM *acc[2][2] = {{&cA0, &cA1}, {&cB0, &cB1}};
                    for (int m = 0; m < 2; m++) {
                        const auto z =
                            aie::interleave_zip(acc[m][0]->to_vector<int8_t>(0), acc[m][1]->to_vector<int8_t>(0), 8);
                        int8_t *o = y + (oh * ow_t + owc[m]) * oc_t; // 32-byte aligned (window base is)
                        aie::store_v(o, z.first.extract<32>(0));
                        aie::store_v(o + 32, z.first.extract<32>(1));
                        aie::store_v(o + 64, z.second.extract<32>(0));
                        aie::store_v(o + 96, z.second.extract<32>(1));
                    }
                }
            }
            aie::release(win_a);
            aie::commit(win_c);
        }
    }
}
// ═══════════════════════════════════════════════════════════════════════════
// HOST
// ═══════════════════════════════════════════════════════════════════════════
void __Runtime_ctrl_high_throughput_enable(int on);
void __Runtime_ctrl_pmap_enable(int on);
void *__Runtime_alloc_uncached(size_t bytes);
#if __has_include("aiehlc_plan.h")
#include "aiehlc_plan.h"
#else
void aiehlc_plan_arrange(int arg, const void *src, void *dst);
#endif

static void conv_run(int8_t *in, int8_t *w, int8_t *out) {
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({2, 2 + HW_COLS, 0, 6}, HW_ROWS, HW_COLS); // + the control-packet column
    conv2d_spatial<<<mesh>>>(in, w, out, M, N, K);
}

int main() {
    printf("=== Conv2d (kernel-only) through the dataflow plan on AIE %dx%d Mesh ===\n", HW_ROWS, HW_COLS);
    const long in_b = (long)INPUT_H_PAD * INPUT_W_PAD * INPUT_C_ALIGN,
               w_b = (long)KERNEL_H * KERNEL_W * INPUT_C_ALIGN * NUM_FILTERS,
               out_b = (long)OUTPUT_H * OUTPUT_W * NUM_FILTERS;
    int8_t *input = (int8_t *)malloc(in_b), *filter = (int8_t *)malloc(w_b), *output = (int8_t *)malloc(out_b);
    int8_t *in2 = (int8_t *)__Runtime_alloc_uncached(in_b * 2); // halo blocks repeated: up to 2x
    int8_t *w2 = (int8_t *)__Runtime_alloc_uncached(w_b);
    int8_t *ot = (int8_t *)__Runtime_alloc_uncached(out_b); // tile-major: [row][col][round][7][28][16]
    memset(input, 0, in_b);
    for (int h = 0; h < INPUT_H; h++)
        for (int w = 0; w < INPUT_W; w++)
            for (int c = 0; c < INPUT_C; c++) {
                int real_idx = (h * INPUT_W + w) * INPUT_C + c;
                int val = (int)(mix32((uint32_t)real_idx + INPUT_SEED) % 9u) - 4; // [-4, 4]
                input[((h + PAD) * INPUT_W_PAD + (w + PAD)) * INPUT_C_ALIGN + c] = (int8_t)val;
            }
    memset(filter, 0, w_b);
    for (int f = 0; f < NUM_FILTERS; f++)
        for (int kh = 0; kh < KERNEL_H; kh++)
            for (int kw = 0; kw < KERNEL_W; kw++)
                for (int c = 0; c < INPUT_C; c++) {
                    int kk = (kh * KERNEL_W + kw) * INPUT_C_ALIGN + c;
                    int filt_key = ((f * KERNEL_H + kh) * KERNEL_W + kw) * INPUT_C + c;
                    int val = (int)(mix32((uint32_t)filt_key + FILTER_SEED) % 3u) - 1; // {-1,0,1}
                    filter[f * K + kk] = (int8_t)val;
                }
    aiehlc_plan_arrange(0, input, in2);
    aiehlc_plan_arrange(1, filter, w2);
    memset(ot, 0, out_b);
    const int launches = 6;
    double first = 0, best = 1e9, sum = 0;
    for (int it = 0; it < launches; it++) {
        XTime t0, t1;
        XTime_GetTime(&t0);
        conv_run(in2, w2, ot);
        XTime_GetTime(&t1);
        const double ms = 1.0 * (t1 - t0) / COUNTS_PER_SECOND * 1000.0;
        printf("[conv_plan] launch %d: %.3f ms\n", it, ms);
        if (it == 0)
            first = ms;
        else
            sum += ms, best = ms < best ? ms : best;
    }
    printf("PERF SUMMARY conv_plan first %.3f ms, steady %.3f ms mean, best %.3f ms\n", first, sum / (launches - 1),
           best);
    const int oh_core = OUTPUT_H / HW_ROWS, oh_t = 7, ow_t = 28, oc_t = 16; // the kernel's tiling
    for (int pm = 0; pm < HW_ROWS; pm++)                                    // tile-major -> HWC
        for (int pn = 0; pn < HW_COLS; pn++)
            for (int i = 0; i < oh_core / oh_t; i++)
                for (int j = 0; j < OUTPUT_W / ow_t; j++) {
                    const int8_t *blk =
                        ot + (((long)(pm * HW_COLS + pn) * (oh_core / oh_t) + i) * (OUTPUT_W / ow_t) + j) *
                                 (oh_t * ow_t * oc_t);
                    for (int r = 0; r < oh_t; r++)
                        for (int c = 0; c < ow_t; c++)
                            memcpy(output +
                                       ((long)(pm * oh_core + i * oh_t + r) * OUTPUT_W + j * ow_t + c) * NUM_FILTERS +
                                       pn * oc_t,
                                   blk + (r * ow_t + c) * oc_t, oc_t);
                }
    int8_t *ref = (int8_t *)malloc(out_b); // the header's scalar reference, compared without the debug dumps
    scalar_conv2d(input, filter, ref);
    int bad = 0;
    for (long e = 0; e < out_b; e++)
        if (output[e] != ref[e] && ++bad <= 8)
            printf("MISMATCH out[oh=%ld,ow=%ld,f=%ld]: got %d want %d\n", e / (OUTPUT_W * NUM_FILTERS),
                   (e / NUM_FILTERS) % OUTPUT_W, e % NUM_FILTERS, output[e], ref[e]);
    printf("GOLDEN %s: conv_plan %d mismatches of %ld\n", bad ? "FAIL" : "PASS", bad, out_b);
    return bad ? 1 : 0;
}
