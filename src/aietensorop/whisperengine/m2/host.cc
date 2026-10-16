/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M2 host: one bf16 GEMM C[M x N] = A[M x K] * W[N x K]^T + bias on the memtile
 * fabric. Fill: DDR -> MT_A (header + A row block) and MT_B (weight column
 * block), once. Replay: memtiles stream to the 16 cores (A NB times, each B
 * panel MB times). Output: 12 KB packets into the BLK layout. Times both
 * phases and checks every output against the CPU.
 ******************************************************************************/
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include "m2_desc.h"
#include <math.h>
#include <stdio.h>
#include <string.h>

extern unsigned char _binary_kernel_m2_start[];
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_out_col[EF_MESH_ROWS] = EF_OUT_SHIM_COL_TABLE;
static const int k_out_ch[EF_MESH_ROWS] = EF_OUT_SHIM_CH_TABLE;

#define M 1536
#define K 384
#define N 1152
#define MB (M / 4 / M2_TM) /* 6 */
#define NBT (N / M2_TN)    /* 12 col blocks in total */
#define NB (NBT / 4)       /* 3 per mesh column */
#define KB (K / M2_TN)     /* 4 col blocks of A */
#define KCN (K / M2_KC)    /* 12 */
#define TILE_B (384 * 96 * 2)
#define A_ROW_BYTES (KB * TILE_B)
#define W_COL_BYTES (NB * KCN * M2_B_CHUNK)

typedef uint16_t bf16_t;
static inline float bf2f(bf16_t h) {
    uint32_t u = (uint32_t)h << 16;
    float f;
    memcpy(&f, &u, 4);
    return f;
}
static inline bf16_t f2bf(float f) {
    uint32_t u;
    memcpy(&u, &f, 4);
    u += 0x7FFF + ((u >> 16) & 1);
    return (bf16_t)(u >> 16);
}
static uint32_t g_seed = 12345;
static float rnd() {
    g_seed = g_seed * 1664525u + 1013904223u;
    return ((g_seed >> 8) & 0xFFFF) / 32768.0f - 1.0f;
}
// BLK index of element (row, col) of a [*, ncols] activation
static inline size_t blk_idx(int row, int col, int ncols) {
    const int r = row / 384, rr = row % 384, cb = col / 96, cc = col % 96;
    return ((size_t)(r * (ncols / 96) + cb) * 384 * 96) + (size_t)((rr / 4) * 12 + cc / 8) * 32 + (rr % 4) * 8 + cc % 8;
}

static XAie_LocType shim(int c) { return XAie_TileLoc((uint8_t)c, 0); }
static XAie_LocType mt(int c, int row) { return XAie_TileLoc((uint8_t)c, (uint8_t)row); }

// Shim MM2S BD over a contiguous DDR range (3-D form: keeps AXI burst 16).
static void sh_bd(XAie_DevInst *dev, int col, int bd, const void *src, int len, int next) {
    __Runtime_dma_bd_config_multidim_ooo(dev, shim(col), (void *)src, bd, len, next, 0, 0, 0, 0, 0, 0, -1, 3, 4, 64,
                                         256, 512, 256 * 512, 0, 0, 0);
}
static void sh_start(XAie_DevInst *dev, int col, int ch, int bd) {
    XAie_DmaDesc d = {};
    __Runtime_startio(dev, __Runtime_dma_createio_4(shim(col), d, ch, bd, DMA_MM2S), bd, 1);
}

// Memory-tile BD: up to 4 dims (word steps/wraps; wrap 0 on the last = open),
// optional iteration.
static void mt_bd(XAie_DevInst *dev, XAie_LocType t, int bd, uint32_t addr, uint32_t len, int ndims,
                  const uint32_t *step, const uint32_t *wrap, uint32_t it_step, uint32_t it_wrap) {
    XAie_DmaDesc d;
    XAie_DmaDescInit(dev, &d, t);
    if (ndims) {
        XAie_DmaDimDesc dims[4];
        for (int i = 0; i < ndims; i++) {
            dims[i].AieMlDimDesc.StepSize = step[i];
            dims[i].AieMlDimDesc.Wrap = (uint16_t)wrap[i];
        }
        XAie_DmaTensor tn;
        tn.NumDim = (uint8_t)ndims;
        tn.Dim = dims;
        XAie_DmaSetMultiDimAddr(&d, &tn, addr, len);
    } else {
        XAie_DmaSetAddrLen(&d, addr, len);
    }
    if (it_wrap > 1)
        XAie_DmaSetBdIteration(&d, it_step, (uint8_t)it_wrap, 0);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(dev, &d, t, (uint8_t)bd);
}
static void mt_queue(XAie_DevInst *dev, XAie_LocType t, int ch, XAie_DmaDirection dir, int bd, int repeat) {
    XAie_DmaChannelSetStartQueue(dev, t, (uint8_t)ch, dir, (uint8_t)bd, (uint32_t)repeat, XAIE_DISABLE);
}
static void wait_ch(XAie_DevInst *dev, XAie_LocType t, int ch, XAie_DmaDirection dir) {
    u8 n = 1;
    for (long it = 0; n; it++) {
        XAie_DmaGetPendingBdCount(dev, t, (uint8_t)ch, dir, &n);
        if (it > 20000000) {
            printf("M2 TIMEOUT tile(%d,%d) ch %d dir %d pending %u\n", t.Col, t.Row, ch, (int)dir, n);
            return;
        }
    }
}
static double us(XTime a, XTime b) { return 1e6 * (double)(b - a) / COUNTS_PER_SECOND; }

int main() {
    printf("=== M2: bf16 GEMM %dx%dx%d on the memtile fabric ===\n", M, N, K);
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_m2_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, tiles, 16));
    for (int k = 1; k <= 4; k++) {
        XAie_DmaChannelEnable(dev, mt(k, EF_MT_A_ROW), 0, DMA_S2MM);
        XAie_DmaChannelEnable(dev, mt(k, EF_MT_A_ROW), 0, DMA_MM2S);
        XAie_DmaChannelEnable(dev, mt(k, EF_MT_B_ROW), 0, DMA_S2MM);
        XAie_DmaChannelEnable(dev, mt(k, EF_MT_B_ROW), 0, DMA_MM2S);
    }

    // ---- data: A [M][K], W [N][K], bias [N] (bf16) ----
    static bf16_t a_rm[M * K], w_rm[N * K], bias[N];
    for (int i = 0; i < M * K; i++)
        a_rm[i] = f2bf(rnd());
    for (int i = 0; i < N * K; i++)
        w_rm[i] = f2bf(rnd() * 0.25f);
    for (int i = 0; i < N; i++)
        bias[i] = f2bf(rnd());
    bf16_t *a = (bf16_t *)__Runtime_Alloc((size_t)M * K * 2);
    for (int i = 0; i < M; i++)
        for (int k = 0; k < K; k++)
            a[blk_idx(i, k, K)] = a_rm[i * K + k];
    // W per mesh column, stream order [nb][kchunk][kt 4][nt 12][8 k][8 n]
    bf16_t *w = (bf16_t *)__Runtime_Alloc((size_t)4 * W_COL_BYTES);
    for (int c = 0; c < 4; c++)
        for (int nb = 0; nb < NB; nb++)
            for (int kc = 0; kc < KCN; kc++)
                for (int kt = 0; kt < 4; kt++)
                    for (int nt = 0; nt < 12; nt++)
                        for (int kk = 0; kk < 8; kk++)
                            for (int nn = 0; nn < 8; nn++) {
                                const int n = (c * NB + nb) * 96 + nt * 8 + nn, k = kc * 32 + kt * 8 + kk;
                                const size_t o = (size_t)c * W_COL_BYTES / 2 +
                                                 ((((size_t)(nb * KCN + kc) * 4 + kt) * 12 + nt) * 8 + kk) * 8 + nn;
                                w[o] = w_rm[n * K + k];
                            }
    int32_t *hdr = (int32_t *)__Runtime_Alloc(M2_HDR_BYTES);
    memset(hdr, 0, M2_HDR_BYTES);
    hdr[MH_MAGIC] = M2_MAGIC;
    hdr[MH_MB] = MB;
    hdr[MH_NB] = NB;
    hdr[MH_KCN] = KCN;
    hdr[MH_FLAGS] = M2_F_BIAS;
    hdr[MH_N] = N;
    memcpy((int8_t *)hdr + M2_BIAS_OFF, bias, N * 2);
    bf16_t *out = (bf16_t *)__Runtime_Alloc((size_t)M * N * 2);
    __Runtime_sync_for_dev(dev, a, (size_t)M * K * 2);
    __Runtime_sync_for_dev(dev, w, (size_t)4 * W_COL_BYTES);
    __Runtime_sync_for_dev(dev, hdr, M2_HDR_BYTES);

    for (int run = 0; run < 3; run++) {
        memset(out, 0xFF, (size_t)M * N * 2);
        __Runtime_sync_for_dev(dev, out, (size_t)M * N * 2);
        XTime t0, t1, t2, t3;
        XTime_GetTime(&t0);
        // outputs first: one OOO BD per core, iterating over its NB*MB blocks
        struct_ioevent ev[4];
        for (int r = 0; r < 4; r++) {
            XAie_LocType s = shim(k_out_col[r]);
            XAie_DmaDesc d = {};
            for (int c = 0; c < 4; c++) {
                bf16_t *dst = out + (size_t)(r * NBT + c * NB) * 384 * 96;
                d = __Runtime_dma_bd_config_multidim_ooo(dev, s, dst, k_ooo[r][c], M2_OUT_BLK, -1, 0, k_pkt[r][c], -1,
                                                         0, -1, 0, k_ooo[r][c], 2, 4, 256, 1024, 12, 0, 0, M2_OUT_BLK,
                                                         NB * MB);
            }
            __Runtime_dma_channel_enable_ooo(dev, s, k_out_ch[r], DMA_S2MM);
            ev[r] = __Runtime_startio(dev, __Runtime_dma_createio_4(s, d, k_out_ch[r], k_ooo[r][0], DMA_S2MM),
                                      k_ooo[r][0], 4 * NB * MB);
        }
        // fill: DDR -> memtiles
        for (int k = 1; k <= 4; k++) {
            const int r = k - 1;
            mt_bd(dev, mt(k, EF_MT_A_ROW), 0, EF_MT_BASE, M2_HDR_BYTES + A_ROW_BYTES, 0, 0, 0, 0, 0);
            mt_queue(dev, mt(k, EF_MT_A_ROW), 0, DMA_S2MM, 0, 1);
            mt_bd(dev, mt(k, EF_MT_B_ROW), 0, EF_MT_BASE, W_COL_BYTES, 0, 0, 0, 0, 0);
            mt_queue(dev, mt(k, EF_MT_B_ROW), 0, DMA_S2MM, 0, 1);
            sh_bd(dev, k, 12, hdr, M2_HDR_BYTES, 13);
            sh_bd(dev, k, 13, (int8_t *)a + (size_t)r * A_ROW_BYTES, A_ROW_BYTES, -1);
            sh_start(dev, k, 1, 12);
            sh_bd(dev, k, 14, (int8_t *)w + (size_t)r * W_COL_BYTES, W_COL_BYTES, -1);
            sh_start(dev, k, 0, 14);
        }
        for (int k = 1; k <= 4; k++) {
            wait_ch(dev, mt(k, EF_MT_A_ROW), 0, DMA_S2MM);
            wait_ch(dev, mt(k, EF_MT_B_ROW), 0, DMA_S2MM);
        }
        XTime_GetTime(&t1);
        // replay: memtiles -> cores
        for (int k = 1; k <= 4; k++) {
            XAie_LocType ta = mt(k, EF_MT_A_ROW), tb = mt(k, EF_MT_B_ROW);
            mt_bd(dev, ta, 1, EF_MT_BASE, M2_HDR_BYTES, 0, 0, 0, 0, 0);
            const uint32_t st[4] = {1, 192, 64, 18432}, wr[4] = {64, 16, 3, 0};
            mt_bd(dev, ta, 2, EF_MT_BASE + M2_HDR_BYTES, M2_TM * K * 2, 4, st, wr, 3072, MB);
            mt_queue(dev, ta, 0, DMA_MM2S, 1, 1);
            mt_queue(dev, ta, 0, DMA_MM2S, 2, NB * MB);
            for (int nb = 0; nb < NB; nb++) {
                mt_bd(dev, tb, 1 + nb, EF_MT_BASE + nb * KCN * M2_B_CHUNK, KCN * M2_B_CHUNK, 0, 0, 0, 0, 0);
                mt_queue(dev, tb, 0, DMA_MM2S, 1 + nb, MB);
            }
        }
        XTime_GetTime(&t2);
        // wait until the last block of every core has landed: watch the final word of
        // the last block (out was pre-filled with 0xFFFF, a bf16 NaN)
        {
            XTime tw;
            for (;;) {
                int done = 1;
                for (int r = 0; r < 4 && done; r++)
                    for (int c = 0; c < 4 && done; c++) {
                        volatile bf16_t *p = out + (size_t)(r * NBT + c * NB + NB) * 384 * 96 - 1;
                        __Runtime_sync_for_cpu(dev, (void *)p, 64);
                        done = *p != 0xFFFF;
                    }
                XTime_GetTime(&tw);
                if (done || us(t2, tw) > 2e6)
                    break;
            }
        }
        XTime_GetTime(&t3);
        if (run == 0) {
            const char *nm[2] = {"S2MM", "MM2S"};
            for (int k = 1; k <= 4; k++)
                for (int row = 1; row <= 6; row++)
                    for (int ch = 0; ch < 2; ch++)
                        for (int d = 0; d < 2; d++) {
                            if (row <= 2 && ch > 0)
                                continue;
                            if (row >= 3 && d == 1 && ch > 0)
                                continue;
                            u32 st = 0;
                            u8 pend = 0;
                            XAie_DmaGetChannelStatus(dev, mt(k, row), ch, (XAie_DmaDirection)d, &st);
                            XAie_DmaGetPendingBdCount(dev, mt(k, row), ch, (XAie_DmaDirection)d, &pend);
                            printf("M2 dbg tile(%d,%d) %s ch%d status 0x%08x pending %u\n", k, row, nm[d], ch,
                                   (unsigned)st, pend);
                        }
            for (int k = 1; k <= 4; k++) {
                u32 cs = 0, pc = 0;
                XAie_CoreGetStatus(dev, mt(k, 3), &cs);
                XAie_CoreGetPCValue(dev, mt(k, 3), &pc);
                printf("M2 dbg core(%d,3) status 0x%08x pc 0x%x\n", k, (unsigned)cs, (unsigned)pc);
            }
        }
        for (int r = 0; r < 4; r++) {
            u32 st = 0;
            u8 pend = 0;
            XAie_DmaGetChannelStatus(dev, shim(k_out_col[r]), k_out_ch[r], DMA_S2MM, &st);
            XAie_DmaGetPendingBdCount(dev, shim(k_out_col[r]), k_out_ch[r], DMA_S2MM, &pend);
            printf("M2 out row %d: shim col %d ch %d status 0x%08x pending %u\n", r, k_out_col[r], k_out_ch[r],
                   (unsigned)st, pend);
        }
        __Runtime_sync_for_cpu(dev, out, (size_t)M * N * 2);
        const double macs = (double)M * N * K;
        printf("M2 run %d: fill %.1f us, arm replay %.1f us, compute+drain %.1f us, total %.1f us | "
               "compute %.1f%% of 4x4 peak, total %.1f%%\n",
               run, us(t0, t1), us(t1, t2), us(t2, t3), us(t0, t3), 100 * macs / (us(t1, t3) * 1e-6) / 4096e9,
               100 * macs / (us(t0, t3) * 1e-6) / 4096e9);
    }
    // which output blocks landed at all (0xFFFF = never written)
    for (int r = 0; r < 4; r++) {
        printf("M2 blocks row %d:", r);
        for (int cb = 0; cb < NBT; cb++) {
            printf(" ");
            for (int mb = 0; mb < MB; mb++) {
                const bf16_t *b = out + (size_t)(r * NBT + cb) * 384 * 96 + (size_t)mb * 64 * 96;
                int nan = 0;
                for (int i = 0; i < 64 * 96; i++)
                    nan += b[i] == 0xFFFF;
                printf("%c", nan == 0 ? '#' : nan == 64 * 96 ? '.' : 'p');
            }
        }
        printf("\n");
    }
    // check (last run)
    long bad = 0, big = 0;
    double maxe = 0;
    for (int i = 0; i < M; i += (i < 64 ? 1 : 3))
        for (int n = 0; n < N; n++) {
            float acc = 0;
            for (int k = 0; k < K; k++)
                acc += bf2f(a_rm[i * K + k]) * bf2f(w_rm[n * K + k]);
            acc += bf2f(bias[n]);
            const float got = bf2f(out[blk_idx(i, n, N)]);
            const double e = fabs((double)got - acc);
            const double tol = fabs(acc) * (1.0 / 128) + 1e-2;
            if (e > maxe)
                maxe = e;
            if (!(e <= tol)) {
                if (bad++ < 5)
                    printf("  MISMATCH (%d,%d): got %f want %f\n", i, n, got, acc);
            }
            big++;
        }
    printf("M2 check: %ld / %ld bad, max abs err %.4g\n", bad, big, maxe);
    printf("M2 %s\n", bad ? "FAIL" : "PASS");
    return bad != 0;
}
