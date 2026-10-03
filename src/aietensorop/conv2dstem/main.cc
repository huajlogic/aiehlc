/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * conv2dstem — driver main() for the ResNet-18 stem convolution library.
 *
 * This is the CALLER side of libconv2dstem.a: it owns the input/output buffers,
 * fills the input, calls conv2d_stem(), and frees. It is a PLAIN host translation
 * unit — it includes only conv2dstem.h, contains no AIE kernel and no <<<mesh>>>
 * launch, and is NOT built by aiehlc.sh. Build it with the host cross-compiler
 * and link it against the archive (recipe at the bottom of this comment).
 *
 * Buffer convention follows the normal aiehlc host code (see
 * example/tileprogram/ccode/simpleconv2d.cc): allocate with __Runtime_Alloc()
 * (64-byte-aligned, DMA-capable) and release with plain free().
 *
 * Note the buffers here are the RAW caller-facing shapes — [224,224,3] input and
 * [64,7,7,3] filter, NOT the AIE's padded [230,230,4] / B^T[64,196] layouts. The
 * library stages between the two internally, so this file carries no knowledge of
 * the AIE data layout.
 *
 * Build:
 *   source script/aiehlc.sh --aie-version 5 \
 *       --runtime-source-file ./src/aietensorop/conv2dstem/conv2dstem.cc
 *   # then, in the SAME shell (aiehlc.sh wipes thirdparty/alib/lib on each run):
 *   aarch64-none-elf-g++ -Os -I src/aietensorop/conv2dstem \
 *       -c -o main.o src/aietensorop/conv2dstem/main.cc
 *   aarch64-none-elf-g++ -Os -o app main.o aout/libconv2dstem.a \
 *       --specs=nosys.specs -Wl,--defsym,end=__bss_end__ \
 *       -Wl,-T -Wl,thirdparty/arch/cortexa78_0/lscript.ld \
 *       -L thirdparty/alib/lib -L <bsp>/lib \
 *       -L <bsp>/lib/../libsrc/build_configs/gen_bsp/libsrc/aienginev2/src \
 *       -Wl,--start-group,-lm,-lxaienginea78,-lxil,-lgcc,-lc,-lstdc++,\
 * -lxiltimer,-lxilstandalone,-lxilpm_ng,--end-group
 *
 * The full recipe with absolute paths is printed by hostcompile.sh at the end of
 * a library build.
 ******************************************************************************/
#include "conv2dstem.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Declared, not included: the runtime header (src/mlir/runtime/aie_runtime.h)
// pulls in the XAie driver headers, which this plain host TU does not need.
// These are C++-mangled in the archive (_Z15__Runtime_Allocm), NOT extern "C",
// so declare them as plain C++ or the link fails with an undefined reference.
void *__Runtime_Alloc(size_t bytes);

// Run the CPU reference cross-check instead of a bare compute call. The reference
// is ~157M scalar int8 MACs on the APU and takes seconds — keep it off unless
// bringing up / debugging the data path.
#ifndef CONV2DSTEM_VERIFY
#define CONV2DSTEM_VERIFY 0
#endif

// Deterministic, zero-mean sample values. Small magnitudes keep the 49-tap x
// 3-channel accumulator inside int8 so the output is distributed rather than
// saturated at +/-127 — the same reasoning as the simpleconv2d.cc generator.
static void fill_inputs(int8_t *ifm, int8_t *wts) {
    for (int i = 0; i < CONV2DSTEM_IFM_ELEMS; i++)
        ifm[i] = (int8_t)((i % 9) - 4); // [-4, 4]
    for (int i = 0; i < CONV2DSTEM_WTS_ELEMS; i++)
        wts[i] = (int8_t)((i % 3) - 1); // {-1, 0, 1}
}

// Quant params that make the epilogue an exact identity, so this smoke test
// stays a pure convolution check and any difference points at the data path.
//
// With multiplier = 2^30 and shift = -1 the epilogue reduces to
//   (acc * 2^30 + 2^29) >> 30  ==  acc
// (verified exhaustively over acc in [-200, 200]). Only the final clamp to
// [0, 255] then applies, so negative taps read back as 0.
//
// The REAL numerical validation is NOT here -- it is
// src/aietensorop/conv2dstem/ref/verify_pack.c, which checks this library's
// packing and epilogue against output produced from the actual ResNet-18
// weights and cross-checked against TVM.
static void fill_qparams(conv2dstem_qparam *qp) {
    for (int f = 0; f < CONV2DSTEM_NUM_FILTERS; f++) {
        qp[f].bias = 0;
        qp[f].zero_point = 0;
        qp[f].multiplier = 1 << 30; /* Q31 1.0 */
        qp[f].shift = -1;           /* net shift of 30 cancels the Q31 scale */
    }
}

int main() {
    printf("=== ResNet-18 stem conv2d on AIE ===\n");
    printf("    Input:  [%d, %d, %d]\n", CONV2DSTEM_INPUT_H, CONV2DSTEM_INPUT_W, CONV2DSTEM_INPUT_C);
    printf("    Filter: [%d, %d, %d, %d]\n", CONV2DSTEM_NUM_FILTERS, CONV2DSTEM_KERNEL_H, CONV2DSTEM_KERNEL_W,
           CONV2DSTEM_INPUT_C);
    printf("    Output: [%d, %d, %d]  (stride %d, pad %d)\n", CONV2DSTEM_OUTPUT_H, CONV2DSTEM_OUTPUT_W,
           CONV2DSTEM_NUM_FILTERS, CONV2DSTEM_STRIDE, CONV2DSTEM_PAD);

    // --- Allocate DMA-capable host memory ---
    int8_t *ifm = (int8_t *)__Runtime_Alloc(CONV2DSTEM_IFM_ELEMS * sizeof(int8_t));
    int8_t *wts = (int8_t *)__Runtime_Alloc(CONV2DSTEM_WTS_ELEMS * sizeof(int8_t));
    uint8_t *ofm = (uint8_t *)__Runtime_Alloc(CONV2DSTEM_OFM_ELEMS * sizeof(uint8_t));
    conv2dstem_qparam *qp = (conv2dstem_qparam *)__Runtime_Alloc(CONV2DSTEM_NUM_FILTERS * sizeof(conv2dstem_qparam));
    if (!ifm || !wts || !ofm || !qp) {
        printf("ERROR: host buffer allocation failed.\n");
        // free(NULL) is a no-op, so an partial allocation still cleans up safely.
        free(ifm);
        free(wts);
        free(ofm);
        free(qp);
        return 1;
    }

    fill_inputs(ifm, wts);
    fill_qparams(qp);

    // --- Run on the AIE mesh ---
    // The library pads/repacks into its own staging buffers, programs the mesh,
    // and copies the result back into ofm.
#if CONV2DSTEM_VERIFY
    printf("\n--- Running conv2d_stem (with CPU cross-check) ---\n");
    int rc = conv2d_stem_verify(ifm, wts, qp, ofm);
    if (rc > 0)
        printf("FAIL: %d mismatches against the CPU reference.\n", rc);
#else
    printf("\n--- Running conv2d_stem ---\n");
    int rc = conv2d_stem(ifm, wts, qp, ofm);
#endif

    if (rc < 0) {
        printf("ERROR: conv2d_stem failed (rc=%d).\n", rc);
    } else {
        // Spot-print one output row of the f=0 plane so a run shows real data.
        printf("Output f=0, oh=0 (first 16 cols):\n  [");
        for (int ow = 0; ow < 16; ow++)
            printf("%4u%s", ofm[(0 * CONV2DSTEM_OUTPUT_W + ow) * CONV2DSTEM_NUM_FILTERS + 0], ow < 15 ? "," : "");
        printf("]\n");
    }

    // --- Cleanup ---
    // Release the library's cached staging buffers first, then our own. Buffers
    // from __Runtime_Alloc are plain aligned_alloc allocations, freed with free().
    conv2d_stem_release();
    free(ifm);
    free(wts);
    free(ofm);
    free(qp);

    printf("conv2dstem done (rc=%d).\n", rc);
    return rc;
}
