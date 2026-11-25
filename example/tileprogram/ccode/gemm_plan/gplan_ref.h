/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* gplan_ref.h -- gemm_plan M3.3.6.2.1.2 reference: one header for the x86 reference (gplan_ref_x86.c) and the
 * aarch64 baremetal board host (gemm_plan, copied byte-identical). Plain C99, no OS calls, no libm, no stdio.
 *
 * Shape: M x N x K (the order of gp_init(A, B, m, n, k)); C[M][N] = A[M][K] . B[N][K]^T.
 *   A  [M][K] row-major, B [N][K] row-major (B stored as N x K, as gp_init / gp_verify).
 *
 * Data (deterministic, storage order, gp_mix32 seeds 1234 / 5678 as gemm_plan/simplegemm_peak.h:44-48):
 *   int8 : A[i] = (int8_t)(mix32(i + 1234) & 0xff), B[i] = (int8_t)(mix32(i + 5678) & 0xff)  == gp_init.
 *   bf16 : v = ((mix32(i + seed) >> 16) % 17) - 8, element = v / 8 (exact bf16 in {-1, -7/8, .., 1}).
 *          Every product is a multiple of 1/64 and |partial sum| <= K, so fp32 accumulation is exact in any
 *          order for K <= 2^18 (K * 64 < 2^24): any correct kernel equals the reference before the final
 *          bf16 rounding of C (as gemm90/gemm_4096_data.h).
 *
 * Sampling: every GPREF_ROW_STEP-th row (7, as gemm_plan_body.cc:229), every GPREF_COL_STEP-th column
 *   (1 = all columns); sample s visits rows i = 0, 7, 14, .. outer, columns j inner.
 *
 * Rules:
 *   int8   "exact"  : want = (int8_t)(int32 sum of A*B)  == gp_verify (simplegemm_peak.h:79-86).
 *   bf16   "bf16cmp": fp32 accumulate, RNE to bf16; got passes iff |got - ref| <= |ref| / 256 + 1e-3 (NaN/Inf
 *                     fail) and cos(got, ref) >= 0.999 over the sampled set  == gemm90/gemm_4096_cmp.h
 *                     (aiehlchj 0f9d0abf).
 *
 * crc32 (IEEE 802.3, reflected, poly 0xEDB88320, init/xorout 0xFFFFFFFF):
 *   in_crc  = crc32 over the bytes of the sampled A rows (row order, K elements each) followed by all of B
 *             (N x K; every column is sampled when GPREF_COL_STEP = 1, else only sampled B rows);
 *             int8 = 1 byte/elem, bf16 = 2 bytes/elem little-endian.
 *   ref_crc = crc32 over the reference values in sample order (int8: 1 byte, bf16: 2 bytes LE of the bits).
 */
#ifndef GPLAN_REF_H
#define GPLAN_REF_H

#include <stddef.h>
#include <stdint.h>

#ifndef GPREF_ROW_STEP
#define GPREF_ROW_STEP 7
#endif
#ifndef GPREF_COL_STEP
#define GPREF_COL_STEP 1
#endif
#define GPREF_SEED_A 1234u
#define GPREF_SEED_B 5678u
#define GPREF_BF16_COS_MIN 0.999
#define GPREF_BF16_ABS 1e-3

enum { GPREF_INT8 = 0, GPREF_BF16 = 1 };

static inline uint32_t gpref_mix32(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

/* ---- data ---- */
static inline void gpref_init_i8(int8_t *A, int8_t *B, long m, long n, long k) {
    for (long i = 0; i < m * k; i++)
        A[i] = (int8_t)(gpref_mix32((uint32_t)i + GPREF_SEED_A) & 0xff);
    for (long i = 0; i < n * k; i++)
        B[i] = (int8_t)(gpref_mix32((uint32_t)i + GPREF_SEED_B) & 0xff);
}

static inline uint16_t gpref_f2bf_exact(float f) { /* f already a bf16 value */
    union {
        float f;
        uint32_t u;
    } c;
    c.f = f;
    return (uint16_t)(c.u >> 16);
}

static inline uint16_t gpref_f2bf_rne(float f) {
    union {
        float f;
        uint32_t u;
    } c;
    c.f = f;
    if ((c.u & 0x7f800000u) == 0x7f800000u) /* Inf / NaN: keep (NaN quiet) */
        return (uint16_t)((c.u >> 16) | ((c.u & 0x007fffffu) ? 0x40u : 0u));
    return (uint16_t)((c.u + 0x7fffu + ((c.u >> 16) & 1u)) >> 16);
}

static inline float gpref_bf2f(uint16_t h) {
    union {
        float f;
        uint32_t u;
    } c;
    c.u = (uint32_t)h << 16;
    return c.f;
}

static inline uint16_t gpref_bf16_elem(uint32_t idx, uint32_t seed) {
    const int v = (int)((gpref_mix32(idx + seed) >> 16) % 17u) - 8;
    return gpref_f2bf_exact((float)v * 0.125f);
}

static inline void gpref_init_bf16(uint16_t *A, uint16_t *B, long m, long n, long k) {
    for (long i = 0; i < m * k; i++)
        A[i] = gpref_bf16_elem((uint32_t)i, GPREF_SEED_A);
    for (long i = 0; i < n * k; i++)
        B[i] = gpref_bf16_elem((uint32_t)i, GPREF_SEED_B);
}

/* ---- crc32 ---- */
static inline uint32_t gpref_crc32_upd(uint32_t crc, const void *p, size_t n) { /* crc: running, pre-inverted */
    const uint8_t *b = (const uint8_t *)p;
    for (size_t i = 0; i < n; i++) {
        crc ^= b[i];
        for (int j = 0; j < 8; j++)
            crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
    }
    return crc;
}
static inline uint32_t gpref_crc32_u16le(uint32_t crc, uint16_t v) {
    uint8_t b[2] = {(uint8_t)(v & 0xff), (uint8_t)(v >> 8)};
    return gpref_crc32_upd(crc, b, 2);
}

/* in_crc: sampled A rows + B (all rows when every column is sampled, else the sampled B rows) */
static inline uint32_t gpref_in_crc(int dtype, const void *A, const void *B, long m, long n, long k) {
    uint32_t c = 0xFFFFFFFFu;
    const long es = dtype == GPREF_BF16 ? 2 : 1;
    for (long i = 0; i < m; i += GPREF_ROW_STEP) {
        if (dtype == GPREF_BF16)
            for (long q = 0; q < k; q++)
                c = gpref_crc32_u16le(c, ((const uint16_t *)A)[i * k + q]);
        else
            c = gpref_crc32_upd(c, (const uint8_t *)A + i * k * es, (size_t)(k * es));
    }
    for (long j = 0; j < n; j += GPREF_COL_STEP) {
        if (dtype == GPREF_BF16)
            for (long q = 0; q < k; q++)
                c = gpref_crc32_u16le(c, ((const uint16_t *)B)[j * k + q]);
        else
            c = gpref_crc32_upd(c, (const uint8_t *)B + j * k * es, (size_t)(k * es));
    }
    return c ^ 0xFFFFFFFFu;
}

/* ---- reference values ---- */
static inline int8_t gpref_ref_i8(const int8_t *A, const int8_t *B, long k, long i, long j) {
    int32_t acc = 0;
    const int8_t *a = A + i * k, *b = B + j * k;
    for (long q = 0; q < k; q++)
        acc += (int32_t)a[q] * (int32_t)b[q];
    return (int8_t)acc;
}

static inline uint16_t gpref_ref_bf16(const uint16_t *A, const uint16_t *B, long k, long i, long j) {
    float acc = 0.0f;
    const uint16_t *a = A + i * k, *b = B + j * k;
    for (long q = 0; q < k; q++)
        acc += gpref_bf2f(a[q]) * gpref_bf2f(b[q]);
    return gpref_f2bf_rne(acc);
}

static inline long gpref_nsampled(long m, long n) {
    return ((m + GPREF_ROW_STEP - 1) / GPREF_ROW_STEP) * ((n + GPREF_COL_STEP - 1) / GPREF_COL_STEP);
}

/* bf16 per-element rule (gemm_4096_cmp.h): |got - ref| <= |ref| / 256 + 1e-3; NaN fails */
static inline int gpref_bf16_ok(uint16_t got, uint16_t ref) {
    const double x = gpref_bf2f(got), y = gpref_bf2f(ref);
    const double e = x > y ? x - y : y - x, ay = y < 0 ? -y : y;
    return e <= ay / 256.0 + GPREF_BF16_ABS; /* NaN / Inf compare false */
}

/* ---- check ----
 * got(ctx, i, j): the board's C[i][j] raw bits (int8 sign-extended, or the bf16 bits); NULL = reference only.
 * Visits the samples in order, computes the reference, crc's it, compares. pass = bad == 0 (and cos >= 0.999
 * for bf16). With got == NULL, pass = 1 and bad = 0.                                                       */
typedef int32_t (*gpref_got_fn)(void *ctx, long i, long j);
typedef struct {
    long checked, bad, first_bad_i, first_bad_j;
    int32_t first_got, first_want;
    uint32_t ref_crc;
    int pass;
    double cr, cc, rr; /* bf16 cosine sums */
} gpref_res_t;

static inline gpref_res_t gpref_check(int dtype, const void *A, const void *B, long m, long n, long k, gpref_got_fn got,
                                      void *ctx) {
    gpref_res_t r = {0, 0, -1, -1, 0, 0, 0, 0, 0.0, 0.0, 0.0};
    uint32_t c = 0xFFFFFFFFu;
    for (long i = 0; i < m; i += GPREF_ROW_STEP)
        for (long j = 0; j < n; j += GPREF_COL_STEP) {
            int ok = 1;
            int32_t want, g = 0;
            if (dtype == GPREF_BF16) {
                const uint16_t ref = gpref_ref_bf16((const uint16_t *)A, (const uint16_t *)B, k, i, j);
                want = ref;
                c = gpref_crc32_u16le(c, ref);
                if (got) {
                    g = got(ctx, i, j) & 0xffff;
                    const double x = gpref_bf2f((uint16_t)g), y = gpref_bf2f(ref);
                    r.cr += x * y;
                    r.cc += x * x;
                    r.rr += y * y;
                    ok = gpref_bf16_ok((uint16_t)g, ref);
                }
            } else {
                const int8_t ref = gpref_ref_i8((const int8_t *)A, (const int8_t *)B, k, i, j);
                const uint8_t rb = (uint8_t)ref;
                want = ref;
                c = gpref_crc32_upd(c, &rb, 1);
                if (got) {
                    g = got(ctx, i, j);
                    ok = (int8_t)g == ref;
                }
            }
            if (!ok && r.bad++ == 0) {
                r.first_bad_i = i;
                r.first_bad_j = j;
                r.first_got = g;
                r.first_want = want;
            }
            r.checked++;
        }
    r.ref_crc = c ^ 0xFFFFFFFFu;
    r.pass = r.bad == 0;
    if (got && dtype == GPREF_BF16) /* cos >= 0.999 without sqrt: cr > 0 and cr^2 >= 0.999^2 cc rr */
        r.pass = r.pass && r.cr > 0.0 && r.cr * r.cr >= GPREF_BF16_COS_MIN * GPREF_BF16_COS_MIN * r.cc * r.rr;
    return r;
}

static inline const char *gpref_rule(int dtype) { return dtype == GPREF_BF16 ? "bf16cmp" : "exact"; }
static inline const char *gpref_dtype(int dtype) { return dtype == GPREF_BF16 ? "bf16" : "int8"; }

#endif /* GPLAN_REF_H */
