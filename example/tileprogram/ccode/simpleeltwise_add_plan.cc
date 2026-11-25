/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#include "simpleops_load.h"
// simpleeltwise_add.cc through the dataflow plan: x and y are {.share = aie::share::broadcast} -- one
// stream per mesh row, staged in a MemTile FIFO ring and multicast to the row's 4 cores, each holding its
// own copy on its own S2MM channel (doc/design/dmaphop_dataflow_plan.md, "Per-core copies").
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#define OPTS_BC {.depth = 2, .share = aie::share::broadcast, .stage = aie::stage::memtile_ring, .ring = 2}
#define OPS_R 256  // rows
#define OPS_C 1024 // columns (bytes)
// Elementwise: z = saturate_int8(x + y), x / y / z int8[256, 1024], on the 4x4 mesh
// by redundant broadcast. x / y blocks depend on the mesh row only, so the 4 cores
// of a mesh row receive the same 16 x 256 blocks (one broadcast stream, DDR read
// once); core (pm, pn) computes and stores only column chunk pn.
// simpleeltwise_add_4x1.cc is the same op with one core per mesh row.
// Walkthrough: tutorial/aieprogram/02_elementwise/elementwise.md
// Walkthrough: tutorial/aieprogram/02_elementwise/elementwise.md
__global__ void eltwise_add(aie::port<input_window_int8 *, aie::shape<OPS_R, OPS_C>> x,
                            aie::port<input_window_int8 *, aie::shape<OPS_R, OPS_C>> y,
                            aie::port<output_window_int8 *, aie::shape<OPS_R, OPS_C>> z) {
    const int tr = 16, tc = 256;                   // block: 16 rows x 256 columns (4 KB)
    const int rows = OPS_R / aie::num_programs(0); // 64 rows per core
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    for (int i = 0; i < rows / tr; i++)        // 4 row strips
        for (int j = 0; j < OPS_C / tc; j++) { // 4 column chunks
            const int8_t *a = aie::load_buffer(x, {pm * rows + i * tr, j * tc}, {tr, tc}, OPTS_BC);
            const int8_t *b = aie::load_buffer(y, {pm * rows + i * tr, j * tc}, {tr, tc}, OPTS_BC);
            if (j == pn) { // this core's column chunk; the other three are only received
                int8_t *o = aie::store_buffer(z, {pm * rows + i * tr, j * tc}, {tr, tc});
                for (int e = 0; e < tr * tc; e++) {
                    const int v = a[e] + b[e];
                    o[e] = (int8_t)(v > 127 ? 127 : v < -128 ? -128 : v);
                }
                aie::commit(z);
            }
            aie::release(x);
            aie::release(y);
        }
}
void __Runtime_ctrl_high_throughput_enable(int on);
void __Runtime_ctrl_pmap_enable(int on);
void *__Runtime_alloc_uncached(size_t bytes);
// x / y laid out in DDR in the order the plan's shim BDs stream them (generated into aiehlc_plan.h)
#if __has_include("aiehlc_plan.h")
#include "aiehlc_plan.h"
#else
void aiehlc_plan_arrange(int arg, const void *src, void *dst);
#endif

static void eltwise_run(int8_t *x, int8_t *y, int8_t *z) {
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({2, 6, 0, 6}, 4, 4); // + the control-packet column
    eltwise_add<<<mesh>>>(x, y, z);
}

int main() {
    const long n = (long)OPS_R * OPS_C, rows = OPS_R / 4, tr = 16, tc = 256;
    int8_t *x = (int8_t *)malloc(n), *y = (int8_t *)malloc(n), *z = (int8_t *)malloc(n), *ref = (int8_t *)malloc(n);
    int8_t *x2 = (int8_t *)__Runtime_alloc_uncached(n), *y2 = (int8_t *)__Runtime_alloc_uncached(n);
    int8_t *zt = (int8_t *)__Runtime_alloc_uncached(n); // tile-major: [mesh row][mesh col][round][16 x 256]
    ops_fill(x, n, 11);
    ops_fill(y, n, 22);
    aiehlc_plan_arrange(0, x, x2);
    aiehlc_plan_arrange(1, y, y2);
    memset(zt, 0, n);
    const int launches = 6;
    double first = 0, best = 1e9, sum = 0;
    for (int it = 0; it < launches; it++) {
        XTime t0, t1;
        XTime_GetTime(&t0);
        eltwise_run(x2, y2, zt);
        XTime_GetTime(&t1);
        const double ms = ops_ms(t0, t1);
        printf("[eltwise_plan] launch %d: %.3f ms\n", it, ms);
        if (it == 0)
            first = ms;
        else
            sum += ms, best = ms < best ? ms : best;
    }
    printf("PERF SUMMARY eltwise_plan first %.3f ms, steady %.3f ms mean, best %.3f ms (%.2f GB/s in+out)\n", first,
           sum / (launches - 1), best, 3.0 * n / (best * 1e6));
    for (long pm = 0; pm < 4; pm++) // tile-major -> row-major
        for (long pn = 0; pn < 4; pn++)
            for (long i = 0; i < rows / tr; i++)
                for (long r = 0; r < tr; r++)
                    memcpy(z + (pm * rows + i * tr + r) * OPS_C + pn * tc,
                           zt + ((pm * 4 + pn) * (rows / tr) + i) * tr * tc + r * tc, tc);
    for (long e = 0; e < n; e++)
        ref[e] = ops_sat8(x[e] + y[e]);
    const int bad = ops_compare("z", z, ref, OPS_R, OPS_C);
    printf("GOLDEN %s: eltwise_plan z = sat(x + y), %ld outputs\n", bad ? "FAIL" : "PASS", n);
    return bad ? 1 : 0;
}
