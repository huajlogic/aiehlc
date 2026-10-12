/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * test_convgemm -- standalone board test of the convgemm basic op.
 *
 * aiehlc ENTRY FILE: owns main() and includes the library source, so one
 * command builds a host ELF (skill aiehlcincludekernel):
 *
 *   mkdir /tmp/cgt && cd /tmp/cgt
 *   source $REPO/script/aiehlc.sh --aie-version 5 \
 *       --runtime-source-file $REPO/src/aietensorop/convgemm/test_convgemm.cc
 *   python3 $REPO/script/test/apppaltest.py -y -nonreboot aout/worklocal/build/host
 *
 * Expect two "[convgemm] ... PASS" lines and "convgemm test done (rc=0)".
 ******************************************************************************/
#include "convgemm.cc"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static uint32_t g_seed = 12345u;
static int8_t rnd8(void) {
    g_seed = g_seed * 1103515245u + 12345u;
    return (int8_t)((g_seed >> 16) & 0xFF);
}

// One GEMM case: AIE (convgemm_i8i32) vs a scalar reference. Returns mismatches.
static long run_case(const char *name, int M, int N, int K) {
    int8_t *A = (int8_t *)malloc((size_t)M * K);
    int8_t *Bt = (int8_t *)malloc((size_t)N * K);
    int32_t *C = (int32_t *)malloc((size_t)M * N * sizeof(int32_t));
    if (!A || !Bt || !C) {
        printf("[convgemm] %s: allocation failed\n", name);
        return -1;
    }
    for (long i = 0; i < (long)M * K; i++)
        A[i] = rnd8();
    for (long i = 0; i < (long)N * K; i++)
        Bt[i] = rnd8();
    const long before = convgemm_launch_count();
    const int rc = convgemm_i8i32(A, Bt, C, M, N, K);
    long bad = 0;
    for (int m = 0; m < M && rc == 0; m++)
        for (int n = 0; n < N; n++) {
            int32_t ref = 0;
            for (int k = 0; k < K; k++)
                ref += (int32_t)A[(long)m * K + k] * (int32_t)Bt[(long)n * K + k];
            if (C[(long)m * N + n] != ref) {
                if (bad < 8)
                    printf("[convgemm] %s: C[%d][%d] = %d, want %d\n", name, m, n, (int)C[(long)m * N + n], (int)ref);
                bad++;
            }
        }
    printf("[convgemm] %s M=%d N=%d K=%d: %s %ld/%ld (rc=%d, %ld launch(es))\n", name, M, N, K,
           (rc == 0 && bad == 0) ? "PASS" : "FAIL", (long)M * N - bad, (long)M * N, rc,
           convgemm_launch_count() - before);
    free(A);
    free(Bt);
    free(C);
    return rc != 0 ? -1 : bad;
}

int main() {
    printf("=== convgemm basic op: int8 GEMM tile on the AIE ===\n");
    long bad = run_case("one tile", 256, 64, 256);
    if (bad == 0)
        bad = run_case("ragged multi-tile", 300, 70, 600);
    const int rc = bad == 0 ? 0 : 1;
    printf("convgemm test done (rc=%d).\n", rc);
    return rc;
}
