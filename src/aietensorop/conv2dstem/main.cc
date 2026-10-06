/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * conv2dstem — driver main() for the ResNet-18 stem convolution.
 *
 * This is an aiehlc ENTRY FILE: it owns main() and #includes the kernel source,
 * so one command produces host.cc (device init, DMA/mesh setup, the launch), the
 * extracted kernel, and a linked ELF:
 *
 *   source script/aiehlc.sh --aie-version 5 \
 *       --runtime-source-file ./src/aietensorop/conv2dstem/main.cc
 *
 * The frontend splices `#include "conv2dstem.cc"` into the text before its
 * rewrites run, so the kernel is annotated, body-guarded and launch-lowered as
 * if it had been written here (src/llvm/aiehlc.cc:inlineSourceIncludes; read
 * aout/newfile.cpp to see the flattened result). Only `.cc`/`.cpp` includes are
 * spliced — the `.h` data headers below are left for Clang, so they cannot
 * disturb kernel extraction. Because main() survives into host.cc,
 * hostcompile.sh classifies this as HOST_ENTRY_KIND=user-main and links an ELF
 * -- in contrast to building conv2dstem.cc directly, which has no main() and is
 * archived into libconv2dstem.a for the TVM BYOC path (skill: hostlibrarymode).
 *
 * ── What this runs on ──────────────────────────────────────────────────────
 *
 * REAL data, not a synthetic pattern: the actual int8-quantized ResNet-18
 * conv1 applied to an actual photograph. Three generated headers carry it,
 * all produced by src/aietensorop/conv2dstem/data/ (see data/README.md):
 *
 *   conv2dstem_image.h    [230,230,4] int8  the fixture image, already
 *                                           ImageNet-preprocessed, quantized,
 *                                           zero-point-padded and HWC4 —
 *                                           byte-for-byte g_ifm_pad's layout
 *   conv2dstem_weights.h  [64,7,7,3] int8   the real conv1 weights, plus the
 *                                           64 folded {bias, zp, mult, shift}
 *   conv2dstem_golden.h   [112,112,64] u8   the CPU ground truth to check against
 *
 * This matters beyond realism. The previous synthetic fixture fed values in
 * [-4,4] x {-1,0,1}, which keeps the accumulator inside int16; with the real
 * weights the peak |accumulator| is 1,023,225, so an int16 accumulator would
 * silently wrap on roughly every output. Only real data exercises that.
 *
 * Because the image header already has the kernel's exact [230,230,4] layout,
 * the host does no scatter at all — stage_ifm_pad4() is a straight memcpy.
 * That is why this file no longer talks about "raw caller-facing shapes": the
 * staging has moved off the board and into the generator.
 ******************************************************************************/
// Brings in the kernel, the staging helpers and the geometry #defines. The
// geometry arrives with it, so parameter.h must NOT also be included here --
// the two spell OUTPUT_H/K differently (same values) and would redefine them.
#include "conv2dstem.cc"

// Generated fixtures. Their element-count macros are all CONV2DSTEM_DATA_*,
// deliberately disjoint from conv2dstem.h's CONV2DSTEM_* names — reusing
// CONV2DSTEM_WTS_ELEMS here would be a macro redefinition with a different
// token sequence. Regenerate with data/*.py, never hand-edit.
#include "conv2dstem_image.h"
#include "conv2dstem_weights.h"

// The golden output is ~800 KB of .rodata and is derived from the two headers
// above, so it is gitignored rather than committed. Build without it and the
// app still runs — it just does not self-check.
#if defined(__has_include)
#if __has_include("conv2dstem_golden.h")
#include "conv2dstem_golden.h"
#define CONV2DSTEM_HAVE_GOLDEN 1
#endif
#endif
#ifndef CONV2DSTEM_HAVE_GOLDEN
#define CONV2DSTEM_HAVE_GOLDEN 0
#endif

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Declared, not included: the runtime header (src/mlir/runtime/aie_runtime.h)
// pulls in the XAie driver headers, which this plain host TU does not need.
// These are C++-mangled in the archive (_Z15__Runtime_Allocm), NOT extern "C",
// so declare them as plain C++ or the link fails with an undefined reference.
void *__Runtime_Alloc(size_t bytes);

// The generated arrays are uint8_t — a hex initializer for int8_t would lean on
// an implementation-defined out-of-range conversion — so they are cast at the
// point of use. These are the only two casts in the file.
static const int8_t *fixture_ifm(void) { return (const int8_t *)conv2dstem_ifm_pad4; }
static const int8_t *fixture_wts(void) { return (const int8_t *)conv2dstem_wts; }

// conv2dstem_qp is a flat int32 block of 64 x {bias, zero_point, multiplier,
// shift}; conv2dstem_qparam is exactly that struct. The reinterpretation is
// only sound if the struct has no padding, which this asserts at compile time.
static_assert(sizeof(conv2dstem_qparam) == 4 * sizeof(int32_t),
              "conv2dstem_qparam is padded; conv2dstem_qp cannot be reinterpreted");
static const conv2dstem_qparam *fixture_qp(void) { return (const conv2dstem_qparam *)conv2dstem_qp; }

/*
 * Compare the AIE output against the CPU ground truth, element for element.
 *
 * Prints at most CONV2DSTEM_MAX_REPORTED_MISMATCHES coordinate lines, then one
 * verdict line. The cap is not cosmetic: apppaltest.py gives the run a 300 s
 * no-output / 600 s total watchdog, and 802,816 lines over a UART would blow
 * through both. data/groundtruth.py --applog parses the verdict line back off
 * the console log, which is the only channel a baremetal board under xsdb has.
 *
 * Returns the mismatch count (0 == bit-exact).
 */
#if CONV2DSTEM_HAVE_GOLDEN
static int check_against_golden(const uint8_t *ofm) {
    int mismatches = 0;
    for (int i = 0; i < OFM_ELEMS; i++) {
        if (ofm[i] != conv2dstem_golden_ofm[i]) {
            if (mismatches < CONV2DSTEM_MAX_REPORTED_MISMATCHES) {
                const int oh = i / (OUTPUT_W * NUM_FILTERS);
                const int ow = (i / NUM_FILTERS) % OUTPUT_W;
                const int f = i % NUM_FILTERS;
                printf("[conv2dstem] MISMATCH ofm[oh=%d,ow=%d,f=%d] (flat %d): got %d, want %d\n", oh, ow, f, i, ofm[i],
                       conv2dstem_golden_ofm[i]);
            }
            mismatches++;
        }
    }
    // One machine-readable line, matched by groundtruth.py's
    // r"GOLDEN (PASS|FAIL)\s+(\d+)\s*/\s*(\d+)".
    printf("[conv2dstem] GOLDEN %s %d/%d\n", mismatches == 0 ? "PASS" : "FAIL", OFM_ELEMS - mismatches, OFM_ELEMS);
    return mismatches;
}
#endif

int main() {
    printf("=== ResNet-18 stem conv2d on AIE ===\n");
    printf("    Input:  [%d, %d, %d] padded to [%d, %d, %d]\n", CONV2DSTEM_INPUT_H, CONV2DSTEM_INPUT_W,
           CONV2DSTEM_INPUT_C, INPUT_H_PAD, INPUT_W_PAD, INPUT_C_ALIGN);
    printf("    Filter: [%d, %d, %d, %d]\n", CONV2DSTEM_NUM_FILTERS, CONV2DSTEM_KERNEL_H, CONV2DSTEM_KERNEL_W,
           CONV2DSTEM_INPUT_C);
    printf("    Output: [%d, %d, %d]  (stride %d, pad %d)\n", CONV2DSTEM_OUTPUT_H, CONV2DSTEM_OUTPUT_W,
           CONV2DSTEM_NUM_FILTERS, CONV2DSTEM_STRIDE, CONV2DSTEM_PAD);
    printf("    Data:   real int8 ResNet-18 conv1 on the fixture image\n");

    // The fixture is const .rodata and needs no DMA alignment: the weights and
    // qparams are only ever read on the host (stage_weights packs them into the
    // aligned g_wts_bt), and the image is memcpy'd into the aligned g_ifm_pad.
    // Only the output buffer is allocated.
    uint8_t *ofm = (uint8_t *)__Runtime_Alloc(CONV2DSTEM_OFM_ELEMS * sizeof(uint8_t));
    if (!ofm) {
        printf("ERROR: host buffer allocation failed.\n");
        return 1;
    }

    int rc = ensure_staging();
    if (rc != CONV2DSTEM_OK) {
        printf("ERROR: staging allocation failed (rc=%d).\n", rc);
        free(ofm);
        return 1;
    }

    // The image header is already in g_ifm_pad's exact layout, so this is a
    // copy rather than the scatter conv2d_stem()/conv2d_stem_prepadded() do.
    stage_ifm_pad4(fixture_ifm());
    rc = stem_run(fixture_wts(), fixture_qp(), ofm);

#if CONV2DSTEM_HAVE_GOLDEN
    if (rc == CONV2DSTEM_OK)
        rc = check_against_golden(ofm);
#else
    printf("[conv2dstem] conv2dstem_golden.h absent -- no self-check. "
           "Generate it with data/groundtruth.py.\n");
#endif

    free(ofm);
    printf("conv2dstem done (rc=%d).\n", rc);
    return rc;
}
