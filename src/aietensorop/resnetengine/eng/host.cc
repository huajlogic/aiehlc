/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Persistent conv engine host driver: every conv of int8 ResNet-18 after the
 * stem (16 engine layers = 19 TVM convs) on the AIE, kernel loaded once.
 * Per layer it only re-arms shim BDs: weights (+header) per mesh column,
 * input rows per mesh row, output packets per core. Each layer's output is
 * checked byte-for-byte against TVM (gen_engine.py's golden, itself proven
 * equal to the TRACE=1 dumps).
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include "eng_desc.h"
#include "eng_net.h"
#include <stdio.h>
#include <arm_neon.h>
#include <math.h>
#include <string.h>

extern unsigned char _binary_kernel_eng_start[];

#define INCBIN(sym, path)                                                                                              \
    __asm__(".section .rodata\n.balign 64\n.global " #sym "\n" #sym ":\n.incbin \"" path "\"\n.previous\n")
INCBIN(eng_blob_src, ENG_BLOB_PATH);
INCBIN(eng_gold_src, ENG_GOLD_PATH);
INCBIN(eng_img_src, ENG_IMG_PATH);
INCBIN(eng_image_src, ENG_IMAGE_PATH);
INCBIN(eng_logits_src, ENG_LOGITS_PATH);
INCBIN(eng_dense_src, ENG_DENSE_PATH);
extern const int8_t eng_blob_src[], eng_gold_src[], eng_img_src[], eng_dense_src[];
extern const float eng_image_src[], eng_logits_src[];

static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_out_col[EF_MESH_ROWS] = EF_OUT_SHIM_COL_TABLE;
static const int k_out_ch[EF_MESH_ROWS] = EF_OUT_SHIM_CH_TABLE;

static XAie_LocType shim(int rel_col) { return XAie_TileLoc((uint8_t)rel_col, 0); }

static long l8_bytes(int h, int c, int wst) { return (long)(h + 2) * (c / 8) * wst * 8; }

// Output: one OOO BD per core; packet = [p][nb][Wo][8] of one output row.
static void arm_output(XAie_DevInst *dev, const eng_layer_t *L, int8_t *out, struct_ioevent *ev) {
    const long row_bytes = (long)(L->Cout / 8) * L->wst_out * 8;
    int r0 = 0;
    for (int r = 0; r < EF_MESH_ROWS; r++) {
        XAie_LocType t = shim(k_out_col[r]);
        XAie_DmaDesc d = {};
        for (int c = 0; c < EF_MESH_COLS; c++) {
            int8_t *dst = out + (r0 + 1) * row_bytes + (long)(2 * c) * L->wst_out * 8 + 8;
            d = __Runtime_dma_bd_config_multidim_ooo(dev, t, dst, k_ooo[r][c], L->P * 2 * L->Wo * 8, -1, 0, k_pkt[r][c],
                                                     -1, 0, -1, 0, -1, 3, 4, L->Wo * 2, L->wst_out * 8, 2,
                                                     8 * L->wst_out * 8, L->P, (int)row_bytes, L->rows[r]);
        }
        __Runtime_dma_channel_enable_ooo(dev, t, k_out_ch[r], DMA_S2MM);
        ev[r] = __Runtime_startio(dev, __Runtime_dma_createio_4(t, d, k_out_ch[r], k_ooo[r][0], DMA_S2MM), k_ooo[r][0],
                                  EF_MESH_COLS * L->rows[r]);
        r0 += L->rows[r];
    }
}

// Weights: header + P*Q chunks, one contiguous run per mesh column.
static void arm_weights(XAie_DevInst *dev, const eng_layer_t *L, const int8_t *blob) {
    for (int c = 0; c < EF_MESH_COLS; c++) {
        XAie_LocType t = shim(EF_FIRST_COL + c);
        // Contiguous, but expressed as 3 dims: a plain BD this long (> 1023
        // words) takes the runtime's fallback path, which leaves the AXI burst
        // at its default and streams ~3x slower than burst 16.
        XAie_DmaDesc d =
            __Runtime_dma_bd_config_multidim_ooo(dev, t, (void *)(blob + L->blob_off[c]), 0, (int)L->blob_len, -1, 0, 0,
                                                 0, 0, 0, 0, -1, 3, 4, 64, 256, 512, 256 * 512, 0, 0, 0);
        __Runtime_startio(dev, __Runtime_dma_createio_4(t, d, 0, 0, DMA_MM2S), 0, 1);
    }
}

// Stem input: per mesh row, image rows 56r-2 .. (mesh row 0 has no halo row
// above it, so it starts at row 0 with two rows fewer).
static void arm_input_stem(XAie_DevInst *dev, const int8_t *img) {
    for (int r = 0; r < EF_MESH_ROWS; r++) {
        const int r0 = r == 0 ? 0 : 56 * r - 2, rows_in = r == 0 ? 61 : 63;
        XAie_LocType t = shim(EF_FIRST_COL + r);
        XAie_DmaDesc d = __Runtime_dma_bd_config_multidim_ooo(
            dev, t, (void *)(img + (long)r0 * ENG_STEM_IN_ROW), 1, rows_in * ENG_STEM_IN_ROW, -1, 0, 0, 0, 0, 0, 0, -1,
            2, 4, ENG_STEM_IN_ROW / 4, ENG_STEM_IN_ROW, rows_in, 0, 0, 0, 0);
        __Runtime_startio(dev, __Runtime_dma_createio_4(t, d, 1, 1, DMA_MM2S), 1, 1);
    }
}

// Input: per mesh row, its rows of one 64-channel chunk; iteration walks the
// Q chunks, P*Q repeats re-stream them once per pass.
static void arm_input(XAie_DevInst *dev, const eng_layer_t *L, const int8_t *in) {
    const long row_bytes = (long)(L->Cin / 8) * L->wst_in * 8;
    const int chunk = ENG_CHUNK_BLK * L->wst_in * 8;
    int r0 = 0;
    for (int r = 0; r < EF_MESH_ROWS; r++) {
        const int rows_in = (L->rows[r] - 1) * L->S + 3;
        XAie_LocType t = shim(EF_FIRST_COL + r);
        // (the _ooo variant is the one with an iteration dimension; ooo = -1)
        XAie_DmaDesc d = __Runtime_dma_bd_config_multidim_ooo(
            dev, t, (void *)(in + (long)r0 * L->S * row_bytes), 1, chunk * rows_in, -1, 0, 0, 0, 0, 0, 0, -1, 3, 4,
            L->wst_in * 2, L->wst_in * 8, ENG_CHUNK_BLK, (int)row_bytes, rows_in, chunk, L->Q);
        // resident input: each chunk once; otherwise once per pass
        __Runtime_startio(dev, __Runtime_dma_createio_4(t, d, 1, 1, DMA_MM2S), 1, L->resident ? L->Q : L->P * L->Q);
        r0 += L->rows[r];
    }
}

void __Runtime_ctrl_high_throughput_enable(int on);
void __Runtime_ctrl_pmap_enable(int on);

static double us_since(XTime t0) {
    XTime t1;
    XTime_GetTime(&t1);
    return 1e6 * (double)(t1 - t0) / COUNTS_PER_SECOND;
}

typedef struct {
    XAie_DevInst *dev;
    __Runtime_CtrlRowFabric *fab;
    int8_t *blob;
    int8_t *act[ENG_NLAYERS + 1];
    long act_bytes[ENG_NLAYERS + 1];
} Engine;

// Partition, control-packet fabric, kernel loaded + started ONCE, weights and
// every activation buffer allocated once (borders written once, never again).
static void engine_init(Engine *e) {
    // Shim BDs go over the control-packet plane (~3 ns/word) instead of MMIO
    // (~372 ns/word, doc/performance/register_write_cost.md). AIE2PS needs high
    // throughput mode for that, and it must be set before device init.
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    e->dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    // Control spine on partition col 0 (abs 2), dedicated: the data plane is cols 1..4.
    static __Runtime_CtrlRowFabric fab;
    static const __Runtime_CtrlRowChain fab_rows[] = {{3, 1, 4}, {4, 1, 4}, {5, 1, 4}, {6, 1, 4}};
    __Runtime_ctrl_plan_init(&fab, e->dev, 0, 0, 1, fab_rows, 4);
    __Runtime_ctrl_plan_set_exclusive(&fab, 1);
    e->fab = &fab;
    XAie_LocType tiles[16];
    for (int r = 0; r < EF_MESH_ROWS; r++)
        for (int c = 0; c < EF_MESH_COLS; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_eng_start);
    __Runtime_launch_kernel_group(e->dev, __Runtime_load_kernel_group_nt(e->dev, tiles, 16));

    e->blob = (int8_t *)__Runtime_Alloc(ENG_BLOB_BYTES);
    memcpy(e->blob, eng_blob_src, ENG_BLOB_BYTES);
    __Runtime_sync_for_dev(e->dev, e->blob, ENG_BLOB_BYTES);
    for (int i = 0; i <= ENG_NLAYERS; i++) {
        const eng_layer_t *L = &eng_layers[i == ENG_NLAYERS ? i - 1 : i];
        e->act_bytes[i] = i == 0            ? (long)ENG_IMG_BYTES
                          : i < ENG_NLAYERS ? l8_bytes(L->Hin, L->Cin, L->wst_in)
                                            : l8_bytes(L->Ho, L->Cout, L->wst_out);
        // the image is the only buffer the CPU writes per run: non-cacheable,
        // so a run needs no cache clean (falls back to cached where it cannot)
        e->act[i] = (int8_t *)(i == 0 ? __Runtime_alloc_uncached(e->act_bytes[i] + 256)
                                      : __Runtime_Alloc(e->act_bytes[i] + 256));
        memset(e->act[i], i == 0 ? ENG_Q_PAD : -128, e->act_bytes[i] + 256);
        __Runtime_sync_for_dev(e->dev, e->act[i], e->act_bytes[i] + 256);
    }
}

// One engine layer: arm shim BDs (control packets), wait for the output.
static double engine_layer(Engine *e, int l) {
    const eng_layer_t *L = &eng_layers[l];
    struct_ioevent ev[EF_MESH_ROWS];
    XTime t0;
    XTime_GetTime(&t0);
    __Runtime_ctrl_shim_bd_begin(e->fab);
    arm_output(e->dev, L, e->act[l + 1], ev);
    arm_weights(e->dev, L, e->blob);
    if (L->stem)
        arm_input_stem(e->dev, e->act[l]);
    else
        arm_input(e->dev, L, e->act[l]);
    __Runtime_ctrl_shim_bd_commit();
    for (int r = 0; r < EF_MESH_ROWS; r++)
        __Runtime_wait_io(e->dev, ev[r]);
    return us_since(t0);
}

static int check_layer(Engine *e, int l) {
    const eng_layer_t *L = &eng_layers[l];
    __Runtime_sync_for_cpu(e->dev, e->act[l + 1], e->act_bytes[l + 1]);
    const int8_t *gold = eng_gold_src + L->gold_off;
    int bad = 0;
    for (long k = 0; k < L->gold_len; k++)
        if (e->act[l + 1][k] != gold[k] && bad++ < 4)
            printf("  MISMATCH call %d byte %ld: got %d want %d\n", L->call, k, e->act[l + 1][k], gold[k]);
    return bad;
}

// Verification: pass 0 isolated (each layer fed TVM's golden input, so a bad
// layer cannot hide the ones after it), pass 1 chained; every output checked.
static int verify_layers(Engine *e) {
    int total = 0;
    for (int pass = 0; pass < 2; pass++) {
        memcpy(e->act[0], eng_img_src, ENG_IMG_BYTES);
        for (int l = 0; l < ENG_NLAYERS; l++) {
            if (pass == 0 && l > 0) {
                memcpy(e->act[l], eng_gold_src + eng_layers[l - 1].gold_off, eng_layers[l - 1].gold_len);
                __Runtime_sync_for_dev(e->dev, e->act[l], e->act_bytes[l]);
            }
            const double us = engine_layer(e, l);
            const int bad = check_layer(e, l);
            printf("ENG %s call %2d: %s (%d bad)  %.1f us\n", pass ? "chained " : "isolated", eng_layers[l].call,
                   bad ? "FAIL" : "PASS", bad, us);
            total += bad;
        }
    }
    return total;
}

// ---- CPU ends ---------------------------------------------------------------

// TVM call 00: float NCHW [3][224][224] -> int8 (round(x*s) + zp, clamp, -128),
// zero-point border (written once at init); emitted straight into the stem's
// [230][232][4] layout. vrndaq = round half away from zero = roundf, and the
// multiply/add are the same IEEE single ops TVM's C does, so it is bit-exact.
__attribute__((optimize("O3"))) static void quantize_image(const float *x, int8_t *img) {
    const float32x4_t s = vdupq_n_f32(ENG_Q_SCALE), zp = vdupq_n_f32(ENG_Q_ZP);
    const float32x4_t hi = vdupq_n_f32(255.0f), lo = vdupq_n_f32(0.0f);
    const int32x4_t off = vdupq_n_s32(128);
    for (int h = 0; h < 224; h++) {
        int8_t *dst = img + ((h + 3) * 232 + 3) * 4;
        for (int w = 0; w < 224; w += 16) {
            int8x16x4_t o;
            o.val[3] = vdupq_n_s8(0);
            for (int c = 0; c < 3; c++) {
                const float *src = x + (c * 224 + h) * 224 + w;
                int16x8_t n[2];
                for (int k = 0; k < 2; k++) {
                    int32x4_t q[2];
                    for (int j = 0; j < 2; j++) {
                        float32x4_t v = vaddq_f32(vrndaq_f32(vmulq_f32(vld1q_f32(src + k * 8 + j * 4), s)), zp);
                        v = vmaxq_f32(vminq_f32(v, hi), lo);
                        q[j] = vsubq_s32(vcvtq_s32_f32(v), off);
                    }
                    n[k] = vcombine_s16(vmovn_s32(q[0]), vmovn_s32(q[1]));
                }
                o.val[c] = vcombine_s8(vmovn_s16(n[0]), vmovn_s16(n[1]));
            }
            vst4q_s8(dst + w * 4, o);
        }
    }
}

// dense weights repacked once from TVM's [N/8][K][8] to [N][K] for SDOT
static int8_t g_dense_nk[ENG_NCLASS * ENG_FEAT] __attribute__((aligned(64)));
static void dense_repack(void) {
    for (int o = 0; o < ENG_NCLASS; o++)
        for (int k = 0; k < ENG_FEAT; k++)
            g_dense_nk[o * ENG_FEAT + k] = eng_dense_src[((long)(o / 8) * ENG_FEAT + k) * 8 + o % 8];
}

// TVM calls 38..40: Q(v << 2) per element (a 256-entry table), 7x7 average,
// clamp to u8, - 128, dense 512 -> 1000 + requant, then to float.
__attribute__((optimize("O3"))) static void cpu_tail(const int8_t *fin, const eng_layer_t *L, float *logits) {
    static int32_t sum[ENG_FEAT];
    static int8_t feat[ENG_FEAT] __attribute__((aligned(16)));
    memset(sum, 0, sizeof(sum));
    for (int h = 0; h < L->Ho; h++)
        for (int b = 0; b < ENG_FEAT / 8; b++) {
            const int8_t *row = fin + (((h + 1) * (ENG_FEAT / 8) + b) * L->wst_out + 1) * 8;
            for (int w = 0; w < L->Wo; w++)
                for (int i = 0; i < 8; i++)
                    sum[b * 8 + i] += eng_final_lut[(uint8_t)(row[w * 8 + i] ^ 0x80)];
        }
    for (int c = 0; c < ENG_FEAT; c++) {
        int32_t v = sum[c] / (L->Ho * L->Wo);
        v = v < 255 ? v : 255;
        feat[c] = (int8_t)((v > 0 ? v : 0) - 128);
    }
    for (int o = 0; o < ENG_NCLASS; o++) {
        const int8_t *w = g_dense_nk + o * ENG_FEAT;
        int32x4_t a = vdupq_n_s32(0);
        for (int k = 0; k < ENG_FEAT; k += 16)
            a = vdotq_s32(a, vld1q_s8(feat + k), vld1q_s8(w + k));
        const int32_t acc = vaddvq_s32(a);
        const int64_t sh = (int64_t)eng_dense_shift[o] + 31;
        int32_t v =
            (int32_t)((((int64_t)(acc + eng_dense_bz[o])) * (int64_t)eng_dense_mult[o] + ((int64_t)1 << (sh - 1))) >>
                      sh) +
            ENG_DENSE_C0;
        v = v < 255 ? v : 255;
        logits[o] = (float)((v > 0 ? v : 0) - ENG_DENSE_ZP) * ENG_DENSE_SCALE;
    }
}

static void top5(const float *lg, int *idx) {
    for (int k = 0; k < 5; k++) {
        int best = -1;
        for (int i = 0; i < ENG_NCLASS; i++) {
            int used = 0;
            for (int j = 0; j < k; j++)
                used |= idx[j] == i;
            if (!used && (best < 0 || lg[i] > lg[best]))
                best = i;
        }
        idx[k] = best;
    }
}

// One image end to end: float image -> logits, all timed.
static int run_image(Engine *e, float *logits, double *t) {
    XTime t0;
    XTime_GetTime(&t0);
    quantize_image(eng_image_src, e->act[0]);
    t[0] = us_since(t0);
    double eng = 0;
    for (int l = 0; l < ENG_NLAYERS; l++)
        eng += engine_layer(e, l);
    t[1] = eng;
    XTime t2;
    XTime_GetTime(&t2);
    const eng_layer_t *L = &eng_layers[ENG_NLAYERS - 1];
    __Runtime_sync_for_cpu(e->dev, e->act[ENG_NLAYERS], e->act_bytes[ENG_NLAYERS]);
    cpu_tail(e->act[ENG_NLAYERS], L, logits);
    t[2] = us_since(t2);
    t[3] = us_since(t0);
    return memcmp(logits, eng_logits_src, ENG_NCLASS * sizeof(float)) != 0;
}

int main() {
    printf("=== resnet engine: int8 ResNet-18, every conv on the AIE, kernel loaded once ===\n");
    static Engine e;
    engine_init(&e);
    dense_repack();
    const int bad = verify_layers(&e);
    printf("ENG layers %s (%d bad bytes)\n", bad ? "FAIL" : "PASS", bad);
    static float logits[ENG_NCLASS];
    int fails = 0;
    double best = 1e30;
    for (int it = 0; it < 10; it++) {
        double t[4];
        const int diff = run_image(&e, logits, t);
        fails += diff;
        best = t[3] < best ? t[3] : best;
        int k5[5];
        top5(logits, k5);
        printf("ENG image %d: logits %s TVM  top5 %d %d %d %d %d  | quantize %.1f  aie %.1f  tail %.1f  "
               "total %.1f us\n",
               it, diff ? "DIFFER from" : "== (bit-exact)", k5[0], k5[1], k5[2], k5[3], k5[4], t[0], t[1], t[2], t[3]);
    }
    printf("PERF SUMMARY best %.3f ms per image (float image -> logits)\n", best / 1000.0);
    { // AIE clock: core-module timer vs the A78's XTime over ~2 ms
        u64 a0, a1;
        XTime h0, h1;
        XAie_LocType t = XAie_TileLoc(EF_FIRST_COL, EF_FIRST_ROW);
        XTime_GetTime(&h0);
        XAie_ReadTimer(e.dev, t, XAIE_CORE_MOD, &a0);
        do
            XTime_GetTime(&h1);
        while ((double)(h1 - h0) / COUNTS_PER_SECOND < 2e-3);
        XAie_ReadTimer(e.dev, t, XAIE_CORE_MOD, &a1);
        XTime_GetTime(&h1);
        printf("ENG AIE clock %.1f MHz\n", (double)(a1 - a0) / ((double)(h1 - h0) / COUNTS_PER_SECOND) / 1e6);
    }
    const int ok = !bad && !fails;
    printf("ENG %s\n", ok ? "PASS" : "FAIL");
    return ok ? 0 : 1;
}
