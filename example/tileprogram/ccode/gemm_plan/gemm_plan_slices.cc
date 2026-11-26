// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// N-slices host driver for gemm_plan (m3362124221 P2): the entry sets GP_M / GP_N (one slice) / GP_K, GP_N_SLICES
// and `#pragma dataflow_slices(GP_N_SLICES, 1, 2)`. The kernel, its launch and the DMA program are gemm_plan.cc's;
// the compiler rebases B's / C's shim BDs per call (the host function's call i serves slice i % GP_N_SLICES) and
// writes C row-major with ldc = GP_N x GP_N_SLICES (the kernel writes its output tile row-major, gemm_plan_tile.h
// K4_OUT). This file only replaces the host main: B and C are GP_N_SLICES slices wide, one launch = GP_N_SLICES
// calls, GOLDEN over the whole M x (N x slices) x K product (gplan_ref.h). gemm_plan_body.cc's own main is kept
// as gp_plan_main_one_slice (unused) so the 1-slice sources (nb101 ...) and their host.cc stay byte-identical.
#if !defined(GP_N_SLICES) || GP_N_SLICES < 2
#error "gemm_plan_slices.cc: the entry sets GP_N_SLICES >= 2 (and #pragma dataflow_slices(GP_N_SLICES, 1, 2))"
#endif
#if defined(GP_DTYPE) && GP_DTYPE != 1
#error "gemm_plan_slices.cc: int8 only (the row-major output tile is the int8 K4_OUT)"
#endif
// (host compile only: the x86 kernel trace and the core's kernel TU collect the #defines and have their own main)
#if !defined(AIEHLC_EMU_HEADER) && !defined(__chess__) && !defined(__AIENGINE__)
#define main gp_plan_main_one_slice
#endif
#include "gemm_plan.cc"
#undef main

uint64_t __Runtime_shim_bd_rebase_count(void);
void __Runtime_shim_bd_rebase_count_reset(void);

// golden: C row-major, ldc = N (all slices)
static int32_t gp_got_rm(void *vctx, long i, long j) {
    gp_got_ctx *x = (gp_got_ctx *)vctx;
    const uint8_t g = (uint8_t)x->Ct[i * (long)(GP_N * GP_N_SLICES) + j];
    x->crc = gpref_crc32_upd(x->crc, &g, 1);
    return (int32_t)(int8_t)g;
}

#if defined(GP_SWEEP_POINTS) && GP_SWEEP_POINTS > 0
// m33621242222122 PCP (arthur.gemm): ONE ELF, GP_SWEEP_POINTS x GP_LAUNCHES persistent launches. Point p covers launches
// p*GP_LAUNCHES+1 .. (p+1)*GP_LAUNCHES, which is the runtime's AIEHLC_B_SHIM_DELAY_NS table point (aie_shim_ts.c
// rt_sts_point, 101 launches per point). Per point: `=== SWEEP point d_ns= b_pushes_per_launch=`, its GPLAN line, its
// GP_LAUNCHES call lines, STEADY (median of its launches 2..N) and GOLDEN (sentinel before its last launch), i.e. each
// point is a complete board log of its own. Host-only (EXTRA_DEFS); undefined -> the original main below.
extern "C" uint32_t __Runtime_b_shim_delay_ns(void);
extern "C" uint32_t __Runtime_b_shim_pushes_last_launch(void);
int main() {
    const long M = GP_M, Ns = GP_N, S = GP_N_SLICES, N = Ns * S, K = GP_K;
    const int launches = GP_LAUNCHES;
    const char *dts = gpref_dtype(GP_REF_DTYPE);
    printf("=== gemm_plan N-slices SWEEP points=%d: C[%ld x %ld] = A[%ld x %ld] . B^T, %s, %ld slices of %ld x %ld x %ld "
           "(one launch = %ld calls), %d launches per point ===\n",
           (int)GP_SWEEP_POINTS, M, N, M, K, dts, S, M, Ns, K, S, launches);
    const size_t abytes = (size_t)M * K, bbytes = (size_t)N * K, sbytes = (size_t)Ns * K, cbytes = (size_t)M * N;
    gp_elem_t *A = (gp_elem_t *)malloc(abytes), *B = (gp_elem_t *)malloc(bbytes);
    gp_elem_t *Ap = (gp_elem_t *)malloc(abytes), *Bp = (gp_elem_t *)malloc(bbytes);
    int8_t *A2 = (int8_t *)__Runtime_alloc_uncached(abytes), *B2 = (int8_t *)__Runtime_alloc_uncached(bbytes);
    int8_t *Ct = (int8_t *)__Runtime_alloc_uncached(cbytes);
    if (!Ct)
        Ct = (int8_t *)__Runtime_Alloc(cbytes);
    if (!A || !B || !Ap || !Bp || !A2 || !B2 || !Ct) {
        printf("GPLAN ERROR alloc failed (A %zu B %zu C %zu bytes)\n", abytes, bbytes, cbytes);
        return 2;
    }
    const int unc = gp_uncached(A2, abytes) && gp_uncached(B2, bbytes) && gp_uncached(Ct, cbytes);
    printf("UNCACHED ok=%d A=%d B=%d C=%d (A %zu B %zu C %zu bytes)\n", unc, gp_uncached(A2, abytes),
           gp_uncached(B2, bbytes), gp_uncached(Ct, cbytes), abytes, bbytes, cbytes);
    gpref_init_i8(A, B, M, N, K);
    const uint32_t in_crc = gpref_in_crc(GP_REF_DTYPE, A, B, M, N, K);
    ka_pack(A, Ap, M, K, KA_TM, 0);
    ka_pack(B, Bp, N, K, KA_TN, 1);
    aiehlc_plan_arrange(0, Ap, A2);
    for (long s = 0; s < S; s++)
        aiehlc_plan_arrange(1, Bp + s * sbytes, B2 + s * sbytes);
    free(Ap);
    free(Bp);
    memset(Ct, 0, cbytes);
    __Runtime_buffer_device_written(Ct, cbytes);
    double *lms = (double *)malloc(sizeof(double) * launches);
    double aie_clk = 0;
    int fail = 0;
    for (int pt = 0; pt < (int)GP_SWEEP_POINTS; pt++) {
        uint64_t rb_min = ~0ULL, rb_max = 0;
        uint32_t d_ns = 0, pmin = ~0U, pmax = 0;
        for (int it = 0; it < launches; it++) {
            if (it == launches - 1) { // sentinel: the checked C is written by this point's last launch
                memset(Ct, 0xA5, cbytes);
                __Runtime_buffer_device_written(Ct, cbytes);
            }
            __Runtime_shim_bd_rebase_count_reset();
            if (it == 0)
                d_ns = __Runtime_b_shim_delay_ns(); // the table point of this launch (after the reset counted it)
            XTime t0, t1;
            XTime_GetTime(&t0);
            for (long s = 0; s < S; s++)
                gemm_ka_run(A2, B2, Ct);
            XTime_GetTime(&t1);
            lms[it] = gp_ms(t0, t1);
            const uint64_t rb = __Runtime_shim_bd_rebase_count();
            const uint32_t pu = __Runtime_b_shim_pushes_last_launch();
            pmin = pu < pmin ? pu : pmin;
            pmax = pu > pmax ? pu : pmax;
            rb_min = rb < rb_min ? rb : rb_min;
            rb_max = rb > rb_max ? rb : rb_max;
            if (pt == 0 && it == 0)
                aie_clk = gp_aie_clock();
        }
        printf("=== SWEEP point d_ns=%u b_pushes_per_launch=%u\n", (unsigned)d_ns, (unsigned)pmax);
        printf("SWEEPPT point=%d d_ns=%u b_pushes_min=%u b_pushes_max=%u\n", pt, (unsigned)d_ns, (unsigned)pmin,
               (unsigned)pmax);
        printf("GPLAN where=%s dtype=%s shape=%ldx%ldx%ld slices=%ld aie_mhz=%.1f clk_src=%s\n", "board", dts, M, N, K, S,
               aie_clk, aie_clk > 0 ? "shim_timer/cntpct" : "none");
        printf("REBASE writes_per_launch=%llu min=%llu max=%llu slices=%ld\n", (unsigned long long)rb_max,
               (unsigned long long)rb_min, (unsigned long long)rb_max, S);
        const double theory_ms =
            aie_clk > 0 ? (double)M * N * K / (GP_HW_ROWS * GP_HW_COLS * (double)GP_MAC_PER_CYC * aie_clk * 1e6) * 1e3
                        : 0;
        for (int it = 0; it < launches; it++)
            printf("[gemm_plan] call %d: end to end %.3f ms -> %.2f %% of theory\n", it + 1, lms[it],
                   theory_ms > 0 ? 100.0 * theory_ms / lms[it] : 0.0);
        const int ns = launches - 1;
        double *st = lms + 1;
        for (int a = 1; a < ns; a++)
            for (int b = a; b > 0 && st[b] < st[b - 1]; b--) {
                const double tt = st[b];
                st[b] = st[b - 1];
                st[b - 1] = tt;
            }
        const double med = ns % 2 ? st[ns / 2] : 0.5 * (st[ns / 2 - 1] + st[ns / 2]);
        printf("STEADY mode=persistent launches=%d median_us=%.1f\n", launches, med * 1e3);
        Xil_DCacheInvalidateRange((UINTPTR)Ct, cbytes);
        gp_got_ctx gx = {(const gp_elem_t *)Ct, 0xFFFFFFFFu};
        const gpref_res_t r = gpref_check(GP_REF_DTYPE, A, B, M, N, K, gp_got_rm, &gx);
        const uint32_t out_crc = gx.crc ^ 0xFFFFFFFFu;
        if (r.bad)
            printf("MISMATCH first C[%ld][%ld]: got %d want %d (rule %s)\n", r.first_bad_i, r.first_bad_j,
                   (int)r.first_got, (int)r.first_want, gpref_rule(GP_REF_DTYPE));
        printf("GOLDEN %s shape=%ldx%ldx%ld dtype=%s launch=%d checked=%ld bad=%ld in_crc=%08x ref_crc=%08x out_crc=%08x\n",
               r.pass ? "PASS" : "FAIL", M, N, K, dts, launches, r.checked, r.bad, (unsigned)in_crc,
               (unsigned)r.ref_crc, (unsigned)out_crc);
        fail |= !r.pass;
    }
    return fail;
}
#else
int main() {
    const long M = GP_M, Ns = GP_N, S = GP_N_SLICES, N = Ns * S, K = GP_K;
    const int launches = GP_LAUNCHES;
    const char *dts = gpref_dtype(GP_REF_DTYPE);
    printf("=== gemm_plan N-slices: C[%ld x %ld] = A[%ld x %ld] . B^T, %s, %ld slices of %ld x %ld x %ld (one launch = "
           "%ld calls), %.3f GMAC, %d tiles / core, %d K chunks ===\n",
           M, N, M, K, dts, S, M, Ns, K, S, (double)M * N * K / 1e9, (int)SH_TILES, (int)SH_NK);
    const size_t abytes = (size_t)M * K, bbytes = (size_t)N * K, sbytes = (size_t)Ns * K, cbytes = (size_t)M * N;
    gp_elem_t *A = (gp_elem_t *)malloc(abytes), *B = (gp_elem_t *)malloc(bbytes);
    gp_elem_t *Ap = (gp_elem_t *)malloc(abytes), *Bp = (gp_elem_t *)malloc(bbytes);
    int8_t *A2 = (int8_t *)__Runtime_alloc_uncached(abytes), *B2 = (int8_t *)__Runtime_alloc_uncached(bbytes);
    int8_t *Ct = (int8_t *)__Runtime_alloc_uncached(cbytes);
    if (!Ct)
        Ct = (int8_t *)__Runtime_Alloc(cbytes);
    if (!A || !B || !Ap || !Bp || !A2 || !B2 || !Ct) {
        printf("GPLAN ERROR alloc failed (A %zu B %zu C %zu bytes)\n", abytes, bbytes, cbytes);
        return 2;
    }
    const int unc = gp_uncached(A2, abytes) && gp_uncached(B2, bbytes) && gp_uncached(Ct, cbytes);
    printf("UNCACHED ok=%d A=%d B=%d C=%d (A %zu B %zu C %zu bytes)\n", unc, gp_uncached(A2, abytes),
           gp_uncached(B2, bbytes), gp_uncached(Ct, cbytes), abytes, bbytes, cbytes);
    gpref_init_i8(A, B, M, N, K);
    const uint32_t in_crc = gpref_in_crc(GP_REF_DTYPE, A, B, M, N, K);
    // A / B pre-pack on the host, outside the timed launches; B slice s (rows s x Ns ..) laid out like slice 0,
    // s x sbytes on in B2 (the compiler's rebase stride for arg 1)
    ka_pack(A, Ap, M, K, KA_TM, 0);
    ka_pack(B, Bp, N, K, KA_TN, 1);
    aiehlc_plan_arrange(0, Ap, A2);
    for (long s = 0; s < S; s++)
        aiehlc_plan_arrange(1, Bp + s * sbytes, B2 + s * sbytes);
    free(Ap);
    free(Bp);
    memset(Ct, 0, cbytes);
    __Runtime_buffer_device_written(Ct, cbytes);
    double *lms = (double *)malloc(sizeof(double) * launches);
    double aie_clk = 0;
    uint64_t rb_min = ~0ULL, rb_max = 0;
    for (int it = 0; it < launches; it++) {
        if (it == launches - 1) { // sentinel: the checked C is written by the last launch
            memset(Ct, 0xA5, cbytes);
            __Runtime_buffer_device_written(Ct, cbytes);
        }
        __Runtime_shim_bd_rebase_count_reset();
        XTime t0, t1;
        XTime_GetTime(&t0);
        for (long s = 0; s < S; s++)
            gemm_ka_run(A2, B2, Ct);
        XTime_GetTime(&t1);
        lms[it] = gp_ms(t0, t1);
        const uint64_t rb = __Runtime_shim_bd_rebase_count();
        rb_min = rb < rb_min ? rb : rb_min;
        rb_max = rb > rb_max ? rb : rb_max;
        if (it == 0) {
            aie_clk = gp_aie_clock();
            printf("GPLAN where=%s dtype=%s shape=%ldx%ldx%ld slices=%ld aie_mhz=%.1f clk_src=%s\n", "board", dts, M, N, K,
                   S, aie_clk, aie_clk > 0 ? "shim_timer/cntpct" : "none");
        }
    }
    printf("REBASE writes_per_launch=%llu min=%llu max=%llu slices=%ld\n", (unsigned long long)rb_max,
           (unsigned long long)rb_min, (unsigned long long)rb_max, S);
    const double theory_ms =
        aie_clk > 0 ? (double)M * N * K / (GP_HW_ROWS * GP_HW_COLS * (double)GP_MAC_PER_CYC * aie_clk * 1e6) * 1e3 : 0;
    for (int it = 0; it < launches; it++)
        printf("[gemm_plan] call %d: end to end %.3f ms -> %.2f %% of theory\n", it + 1, lms[it],
               theory_ms > 0 ? 100.0 * theory_ms / lms[it] : 0.0);
    const int ns = launches - 1;
    double *st = lms + 1;
    for (int a = 1; a < ns; a++)
        for (int b = a; b > 0 && st[b] < st[b - 1]; b--) {
            const double tt = st[b];
            st[b] = st[b - 1];
            st[b - 1] = tt;
        }
    const double med = ns % 2 ? st[ns / 2] : 0.5 * (st[ns / 2 - 1] + st[ns / 2]);
    printf("STEADY mode=persistent launches=%d median_us=%.1f\n", launches, med * 1e3);
    printf("[gemm_plan] theory %d x %d MAC/cycle @ %.1f MHz = %.1f us -> steady %.2f %% of theory\n",
           GP_HW_ROWS * GP_HW_COLS, GP_MAC_PER_CYC, aie_clk, theory_ms * 1e3,
           theory_ms > 0 ? 100.0 * theory_ms / med : 0.0);
    Xil_DCacheInvalidateRange((UINTPTR)Ct, cbytes);
    gp_got_ctx gx = {(const gp_elem_t *)Ct, 0xFFFFFFFFu};
    const gpref_res_t r = gpref_check(GP_REF_DTYPE, A, B, M, N, K, gp_got_rm, &gx);
    const uint32_t out_crc = gx.crc ^ 0xFFFFFFFFu;
    if (r.bad)
        printf("MISMATCH first C[%ld][%ld]: got %d want %d (rule %s)\n", r.first_bad_i, r.first_bad_j, (int)r.first_got,
               (int)r.first_want, gpref_rule(GP_REF_DTYPE));
    printf("GOLDEN %s shape=%ldx%ldx%ld dtype=%s launch=%d checked=%ld bad=%ld in_crc=%08x ref_crc=%08x out_crc=%08x\n",
           r.pass ? "PASS" : "FAIL", M, N, K, dts, launches, r.checked, r.bad, (unsigned)in_crc, (unsigned)r.ref_crc,
           (unsigned)out_crc);
    return r.pass ? 0 : 1;
}
#endif
