/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * conv2dstem — ResNet-18 stem convolution (conv1) as an AIE static library.
 *
 *   ifm [224,224,3] (*) wts [64,7,7,3]  stride 2, pad 3  ->  ofm [112,112,64]
 *
 * Derived from example/tileprogram/ccode/simpleconv2d.cc, which already targets
 * exactly this geometry. Two things change:
 *
 *   1. No main(). The host entry is conv2d_stem(ifm, wts, ofm) and the input
 *      data comes from the CALLER. hostcompile.sh classifies the generated
 *      host.cc as HOST_ENTRY_KIND=library and archives libconv2dstem.a instead
 *      of linking an ELF (see skill: hostlibrarymode).
 *   2. The DDR pre-pad / channel-align / filter-transpose that simpleconv2d.cc
 *      did inline while synthesizing test data is now a staging step that
 *      scatters CALLER buffers into AIE-layout buffers.
 *
 * ── Why staging buffers exist ───────────────────────────────────────────────
 * The AIE DMA can only RELOCATE bytes; it cannot synthesize zeros. So every
 * zero the convolution reads must physically exist in DDR. Two independent pads
 * are materialized here:
 *   * spatial: PAD=3 zero pixels on each H/W border -> [230, 230, ...]
 *   * channel: cin 3 -> INPUT_C_ALIGN 4 via a zero channel. The padded channel
 *     contributes 0 to every dot product, so the result is bit-identical to an
 *     unaligned cin=3 run while keeping the K dim a multiple of 4.
 * Real pixel (h,w,c) therefore lands at ((h+PAD)*INPUT_W_PAD + (w+PAD))*4 + c.
 *
 * The staging buffers are cached across calls (allocation + the 9408-element
 * weight transpose are not free per inference). See conv2d_stem_release().
 ******************************************************************************/
// NOTE: conv2dstem.h is deliberately NOT included here — it is included BELOW,
// after the kernel definition. See the "Header include placement" comment above
// the include site. Including it here silently produces a library that builds
// but does nothing.
//
// Also note: the aiehlc source rewriter scans this file as TEXT for the kernel
// annotation keyword and wraps "the next { it finds" in an #ifdef guard. Writing
// that keyword in a comment ABOVE the spatial-space descriptors makes it wrap the
// first descriptor's initializer instead of the kernel body, which silently
// default-constructs the descriptor. Do not spell that keyword in prose here;
// say "the kernel" instead.
#include "unistd.h"
#include "xil_cache.h"
#include "xiltimer.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma aie_debug_level(2 | AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN | AIE_DMA_ISSUE_COUNT)

// ═══════════════════════════════════════════════════════════════════════════
// Geometry
//
// Written as bare literals, NOT as aliases of the CONV2DSTEM_* macros in
// conv2dstem.h, because that header is included only AFTER the kernel (see the
// include site below) and so is not in scope here.
//
// The kernel extractor carries only #defines written DIRECTLY in this .cc into
// the kernel translation unit; the kernel TU does NOT include conv2dstem.h and
// must not — a public header pulling in xil_cache.h/xiltimer.h would not build
// under the AIE chess compiler.
//
// These are cross-checked against the header's CONV2DSTEM_* values by
// static_assert at the include site below, so the duplication cannot drift.
// ═══════════════════════════════════════════════════════════════════════════
#define INPUT_H 224
#define INPUT_W 224
#define INPUT_C 3       // real channels
#define INPUT_C_ALIGN 4 // channel-layout stride (3 + 1 zero pad)
#define KERNEL_H 7
#define KERNEL_W 7
#define NUM_FILTERS 64
#define STRIDE 2
#define PAD 3

#define OUTPUT_H 112 // (224 + 2*3 - 7)/2 + 1
#define OUTPUT_W 112

// Spatially pre-padded DDR extents (what the shim DMA actually walks).
#define INPUT_H_PAD (INPUT_H + 2 * PAD) // 230
#define INPUT_W_PAD (INPUT_W + 2 * PAD) // 230

// im2col -> GEMM dims. K uses the ALIGNED channel count.
#define M (OUTPUT_H * OUTPUT_W)                 // 12544
#define K (KERNEL_H * KERNEL_W * INPUT_C_ALIGN) // 196
#define N NUM_FILTERS                           // 64

// HW mesh
#define HW_ROWS 4
#define HW_COLS 4

// ═══════════════════════════════════════════════════════════════════════════
// Kernel-visible conv geometry (spatial-halo path)
//
// These SP_* literals are what the conv2d_spatial kernel below compiles
// against. They MUST agree with the geometry above; the kernel TU cannot see
// the constexpr descriptors, only these #defines.
// ═══════════════════════════════════════════════════════════════════════════
#define SP_KH 7   // KERNEL_H
#define SP_KW 7   // KERNEL_W
#define SP_C 4    // INPUT_C_ALIGN (layout stride; real cin=3, +1 zero pad)
#define SP_S 2    // STRIDE
#define SP_OW 112 // OUTPUT_W
#define SP_K 196  // KH*KW*INPUT_C_ALIGN

#define PAD_W 3
#define PAD_H 3

// Output tile geometry. 112 / (HW_ROWS*OH_T) = 112/(4*7) = 4 slabs per core —
// a clean integer tiling with no remainder slab.
#define OH_T 7  // output tile height
#define OW_T 28 // output tile width

// Spatial-halo HEIGHT descriptor. Drives both RowBC_spatial.d1 and SP_OHR, so
// the per-tile slab supply == the kernel's per-tile output-row demand.
#define PAD_H_LO 3                              // top pad (first tile only)
#define PAD_H_HI 3                              // bottom pad (last tile only)
#define TILE_H ((OH_T - 1) * SP_S + SP_KH)      // 19 input rows per on-core round
#define TILE_STRIDE_H (TILE_H - (SP_KH - SP_S)) // 14 halo step (overlap = KH-S = 5)
// Output rows produced from a TILE_H-row slab. DDR is PRE-padded, so the slab is
// a window of the already-padded buffer (top pad materialized) — do NOT re-add
// PAD_H_LO here.
#define SP_OHR ((TILE_H - SP_KH) / SP_S + 1) // = 7 (== OH_T)

// Spatial-halo WIDTH descriptor — the width dim is split across mesh COLS the
// same way the height dim splits across mesh ROWS.
#define PAD_W_LO 3
#define PAD_W_HI 3
#define TILE_W ((OW_T - 1) * SP_S + SP_KW)      // 61 per-tile input cols
#define TILE_STRIDE_W (TILE_W - (SP_KW - SP_S)) // 56 (overlap = KW-S = 5)
// Mirrors SP_OHR. Unused by the kernel (it uses ow_dim = OW_T directly), kept
// for symmetry with the height descriptor.
#define SP_OWR ((TILE_W - SP_KW) / SP_S + 1)

constexpr int OC_PER_G = NUM_FILTERS / HW_COLS; // 16 output channels per mesh col

// Full output extents, as kernel-visible literals.
#define OUTPUT_FULL_H 112
#define OUTPUT_FULL_W 112
#define OUTPUT_FULL_C 64

// ═══════════════════════════════════════════════════════════════════════════
// Composition-based spatial spaces
//
// Distribution strategy (same as GEMM):
//   A (input)  : Broadcast per Row — all tiles in a mesh row see the same slab
//   B (filter) : Broadcast per Col — all tiles in a mesh col see the same filter
//   C (output) : Gather per Row    — tile outputs merged left-to-right
// ═══════════════════════════════════════════════════════════════════════════

// A-input: spatial-halo model. RowBC_spatial is a lean GemmSpace whose d1 carries
// the HEIGHT halo split AND the conv kernel window (win) + stride (win_stride);
// the compiler derives the conv tiling from d1/d2 — no Conv2dSpace needed.
//   d1 = HEIGHT halo across mesh ROWS: 61-row outer slices stepping 56 over the
//        padded height 230 -> 4 mesh rows. Each slab is chunked on-core into 4
//        L2 rounds of TILE_H=19 stepping TILE_STRIDE_H=14. Coverage:
//        (4-1)*14 + 19 = 61. Derived oh_per_row = (19-7)/2+1 = 7 == OH_T.
//   d2 = WIDTH K-accum split across mesh COLS: 61-col chunks stepping 56 over
//        the padded width 230; with the d3 channel stride this gives the routing
//        slice 244 / step 224 and a padded row pitch of 230*4 = 920.
//   d3 = CHANNEL: real cin=3 padded to 4. fullsize is the layout stride;
//        padsize records the single zero channel the host materializes.
constexpr aie::GemmSpace RowBC_spatial = {
    .policy = {.map = {.act = aie::Pattern::Broadcast, .layout = aie::Layout::Row},
               .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::Dma},
               .sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}},
    .d1 = {.fullsize = INPUT_H + PAD_H_LO + PAD_H_HI, // 230 padded H
           .tile_round = 4,
           .tile_size = 61,                          // outer height slice (rows per mesh row)
           .stride = 56,                             // outer height step
           .slice_tiling = {.tile_size = TILE_H,     // 19 rows per on-core round
                            .stride = TILE_STRIDE_H, // 14 row step between rounds
                            .rounds = 4}},
    .d2 = {.fullsize = INPUT_W + PAD_W_LO + PAD_W_HI, // 230 padded W
           .tile_round = 4,
           .tile_size = TILE_W,       // 61 per-chunk input cols
           .stride = TILE_STRIDE_W},  // 56 width halo step
    .d3 = {.fullsize = INPUT_C_ALIGN, // 4 (layout stride; not split)
           .tile_size = INPUT_C_ALIGN,
           .padsize = INPUT_C_ALIGN - INPUT_C}}; // 1 zero pad channel (3 -> 4)

// Filter (B), described per-port as B^T[N, K] decomposed over its K factors:
//   d1 = N-tile (output channels per mesh col), d2/d3 = KW/KH, d4 = channel.
constexpr aie::GemmSpace ColBC = {
    .policy = {.map = {.wgt = aie::Pattern::Broadcast, .layout = aie::Layout::Col},
               .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::Dma},
               .sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}},
    .d1 = {.fullsize = OC_PER_G * HW_COLS, .tile_round = HW_COLS, .tile_size = OC_PER_G, .stride = OC_PER_G},
    .d2 = {.fullsize = SP_KW, .tile_size = SP_KH, .stride = SP_KW},
    .d3 = {.fullsize = SP_KH, .tile_size = SP_KH, .stride = SP_KH},
    .d4 = {.fullsize = INPUT_C_ALIGN,
           .tile_size = INPUT_C_ALIGN,
           .stride = INPUT_C_ALIGN,
           .padsize = INPUT_C_ALIGN - INPUT_C}};

// Output (C): gathered left-to-right. Must be described with the FULL output
// tile size, not the per-tile sub-split — the compiler needs total coverage.
constexpr aie::GemmSpace LtoR_Merge = {
    .policy = {.map = {.layout = aie::Layout::Row,
                       .merge_order = aie::Flow::LeftToRight,
                       .mesh_tiling_group1_dim = 1 /* d1 = H, split across mesh rows */,
                       .mesh_tiling_group2_dim = 3 /* d3 = channel, split across mesh cols */},
               .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None},
               .sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}},
    .d1 = {.fullsize = OUTPUT_FULL_H,
           .tile_round = 4,
           .tile_size = 28,
           .stride = 28,
           .slice_tiling = {.tile_size = 7, .stride = 7, .rounds = 4}},
    .d2 = {.fullsize = OUTPUT_FULL_W, .tile_round = 4, .tile_size = 28, .stride = 28},
    .d3 = {.fullsize = OUTPUT_FULL_C, .tile_round = 4, .tile_size = OC_PER_G},
};

// ═══════════════════════════════════════════════════════════════════════════
// KERNEL: conv2d_spatial
//
// Receives a RAW input slab in win_a as [TILE_H, TILE_W*C] (the overlapping
// block owned by this tile), the filter [K, tile_N] in win_b, and produces
// [oh_per_row * OW_T, tile_N] output rows.
//
// The spatial-halo DMA (raw overlapping blocks) is DERIVED by the compiler from
// RowBC_spatial: each tile owns OH_T output rows, needing (OH_T-1)*S + KH input
// rows, advancing by the halo step per tile. The shim BD stays flat; overlap is
// realized via per-tile DDR base offsets.
//
// Identical to the simpleconv2d.cc kernel — the geometry is the same, so this
// is a straight port.
// ═══════════════════════════════════════════════════════════════════════════
constexpr aie::GlobalPolicy conv_policy = {.fullconnect_auto = 0};
__global__(conv_policy) void conv2d_spatial(
    aie::port<input_window_int8 *, RowBC_spatial> win_a, // raw slab [TILE_H, TILE_W*C]
    aie::port<input_window_int8 *, ColBC> win_b,         // filter [K, tile_N]
    aie::port<output_window_int8 *, LtoR_Merge> win_c    // output [oh_per_row*OW_T, tile_N]
) {
    const int kh_dim = SP_KH;
    const int kw_dim = SP_KW;
    const int c_dim = SP_C;
    const int stride = SP_S;
    // 2D WIDTH-SPLIT: the conv width is chunked into on-core rounds. Each round
    // delivers a NARROW slab [TILE_H, TILE_W*C] cut from the PRE-PADDED DDR
    // buffer and produces a per-chunk output tile of OW_T cols. The host streams
    // H_chunks*W_chunks slabs and the 2D shim BDs handle the (hc,wc) base-offset
    // stepping, so every round is uniform here — the left/top pad is already
    // baked into the pre-padded buffer.
    const int ow_dim = OW_T;       // per-chunk output cols (28)
    const int oh_per_row = SP_OHR; // 7
    const int k_dim = SP_K;        // KH*KW*C

    const int out_c_num = aie::get_arg_per_round_size_in_dim(2, win_c);

    const int num_a_rounds = aie::get_num_rounds(win_a);
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int num_c_rounds = aie::get_num_rounds(win_c);
    const int buf_sz_a = aie::get_buffer_size(win_a);
    const int buf_sz_b = aie::get_buffer_size(win_b);
    const int buf_sz_c = aie::get_buffer_size(win_c);

    // Number of spatial M sub-tiles (slabs) this core processes. Each slab is a
    // contiguous overlapping halo block yielding one output tile. The host
    // streams m_rounds slabs and expects m_rounds output tiles back, so the whole
    // receive -> compute -> emit sequence repeats once per slab.
    const int m_rounds = aie::get_spatial_multiple_rounds(win_a);

    // Per-chunk input row width. With the 2D width-split each round's slab is the
    // NARROW block [TILE_H, TILE_W*C] = [19, 244], delivered by a 2D shim BD
    // (contiguous run 244, row pitch = padded INPUT_W_PAD*C). The im2col indexing
    // below stays within this narrow slab.
    const int raw_wc = TILE_W * SP_C;

    int8_t slab[buf_sz_a]; // raw input slab [TILE_H, raw_wc]
    int8_t local_out[oh_per_row * ow_dim * out_c_num];

    // ===== Receive B (filter) ONCE, before the slab loop =====
    // The filter is streamed a single time (win_b num_rounds == 1). Acquiring it
    // inside the mr loop would over-acquire the lock (m_rounds times) against a
    // producer that releases it once -> DMA/lock stall. Copy it into a persistent
    // local buffer so every slab reuses the same filter without re-acquiring.
    int8_t B_local[num_b_rounds * buf_sz_b];
    for (int rb = 0; rb < num_b_rounds; rb++) {
        int8_t *B_ptr = (int8_t *)acquire_input_window(win_b);
        for (int i = 0; i < buf_sz_b; i++)
            B_local[rb * buf_sz_b + i] = B_ptr[i];
        release_input_window(win_b);
    }

    // ===== M sub-tile loop: one slab -> one output tile per iteration =====
    for (int mr = 0; mr < m_rounds; mr++) {
        // ===== Phase 1: receive the raw input slab =====
        for (int ra = 0; ra < num_a_rounds; ra++) {
            int8_t *A_ptr = (int8_t *)acquire_input_window(win_a);
            for (int i = 0; i < buf_sz_a; i++)
                slab[ra * buf_sz_a + i] = A_ptr[i];
            release_input_window(win_a);
        }

        // ===== Phase 2: on-chip windowing (im2col) + matmul (reads B_local) =====
        for (int oh = 0; oh < oh_per_row; oh++) {
            for (int ow = 0; ow < ow_dim; ow++) {
                for (int j = 0; j < out_c_num; j++) {
                    int16_t sum = 0;
                    // local im2col: gather the KH*KW*C patch from the slab
                    int kk = 0;
                    for (int kh = 0; kh < kh_dim; kh++) {
                        for (int kw = 0; kw < kw_dim; kw++) {
                            for (int c = 0; c < c_dim; c++) {
                                int ih = oh * stride + kh;
                                int iw = ow * stride + kw;
                                int8_t iv = slab[ih * raw_wc + iw * c_dim + c];
                                int8_t fv = B_local[j * k_dim + kk];
                                sum += (int16_t)iv * (int16_t)fv;
                                kk++;
                            }
                        }
                    }
                    if (sum > 127)
                        sum = 127;
                    else if (sum < -128)
                        sum = -128;
                    // HWC slab [oh,ow,c]: channel j innermost/contiguous, so the
                    // MM2S stream order is (h,w,c), matching the declared output
                    // dim order.
                    local_out[(oh * ow_dim + ow) * out_c_num + j] = (int8_t)sum;
                }
            }
        }

        // ===== Phase 3: output =====
        for (int rc = 0; rc < num_c_rounds; rc++) {
            int8_t *out = (int8_t *)acquire_output_window(win_c);
            for (int i = 0; i < buf_sz_c; i++)
                out[i] = local_out[rc * buf_sz_c + i];
            release_output_window(win_c);
        }
    } // end m_rounds
}

// ═══════════════════════════════════════════════════════════════════════════
// Header include placement — DO NOT move this to the top of the file.
//
// conv2dstem.h declares conv2d_stem(), which contains the <<<mesh>>> launch.
// The aiehlc Clang frontend's VisitFunctionDecl registers an annotated kernel
// into globalKernelFuncs when it visits the kernel DEFINITION, and resolves the
// launch's tensor parameters by looking the kernel up in that map.
//
// Clang's FunctionDecl::hasBody()/getBody() resolve across the whole
// redeclaration chain: visiting a mere PROTOTYPE of conv2d_stem yields the real
// body, so the visitor traverses the launch at the prototype's source position.
// With the header included at the top, that position is ABOVE the kernel
// definition — the launch is then processed while globalKernelFuncs is still
// empty, no tensor params are parsed, and the pipeline emits an empty module.
//
// The failure is SILENT in the worst way: every MLIR pass still "succeeds" and
// host.cc/kernel.cc are still written, but with zero routing connections. The
// only surface symptom is a downstream "Couldn't open aie2ps.prx" from xchessmk,
// because BCF/PRX emission is skipped when the allocator has no allocations.
//
// Including the header AFTER the kernel definition keeps the first-seen
// declaration of conv2d_stem below the kernel, so the kernel registers first.
// Verified by bisection: adding a single forward declaration above the kernel
// to an otherwise-working source reproduces the empty-module build exactly.
// ═══════════════════════════════════════════════════════════════════════════
#include "conv2dstem.h"

// The geometry literals above are duplicated from the header (the header is not
// in scope where they are defined). Pin them together so a change to one side
// breaks the build instead of silently miscompiling the data path.
static_assert(INPUT_H == CONV2DSTEM_INPUT_H, "INPUT_H out of sync with conv2dstem.h");
static_assert(INPUT_W == CONV2DSTEM_INPUT_W, "INPUT_W out of sync with conv2dstem.h");
static_assert(INPUT_C == CONV2DSTEM_INPUT_C, "INPUT_C out of sync with conv2dstem.h");
static_assert(KERNEL_H == CONV2DSTEM_KERNEL_H, "KERNEL_H out of sync with conv2dstem.h");
static_assert(KERNEL_W == CONV2DSTEM_KERNEL_W, "KERNEL_W out of sync with conv2dstem.h");
static_assert(NUM_FILTERS == CONV2DSTEM_NUM_FILTERS, "NUM_FILTERS out of sync with conv2dstem.h");
static_assert(STRIDE == CONV2DSTEM_STRIDE, "STRIDE out of sync with conv2dstem.h");
static_assert(PAD == CONV2DSTEM_PAD, "PAD out of sync with conv2dstem.h");
static_assert(OUTPUT_H == CONV2DSTEM_OUTPUT_H, "OUTPUT_H out of sync with conv2dstem.h");
static_assert(OUTPUT_W == CONV2DSTEM_OUTPUT_W, "OUTPUT_W out of sync with conv2dstem.h");
// The SP_* kernel-visible literals must agree with the host geometry too — the
// kernel TU sees only those, so a mismatch here is a silent wrong-result bug.
static_assert(SP_KH == KERNEL_H && SP_KW == KERNEL_W, "SP_K* out of sync with KERNEL_*");
static_assert(SP_C == INPUT_C_ALIGN, "SP_C out of sync with INPUT_C_ALIGN");
static_assert(SP_S == STRIDE, "SP_S out of sync with STRIDE");
static_assert(SP_K == KERNEL_H * KERNEL_W * INPUT_C_ALIGN, "SP_K out of sync with KH*KW*C");
static_assert(SP_OHR == OH_T, "per-tile slab supply != kernel output-row demand");
static_assert(OH_T * HW_ROWS * 4 == OUTPUT_H, "height tiling does not cover OUTPUT_H");
static_assert(OW_T * HW_COLS == OUTPUT_W, "width tiling does not cover OUTPUT_W");

// ═══════════════════════════════════════════════════════════════════════════
// HOST — staging buffer cache
//
// The mesh itself CANNOT be hoisted into a static: the aiehlc Clang frontend
// extracts the mesh dims by pattern-matching a function-local VarDecl
// initialized via device.partition(...) in the SAME function as the launch
// (src/llvm/aiehlc.cc). So aieArray/aieMesh are re-declared per call; only the
// DDR buffers are cached. That is where the real cost is anyway —
// __Runtime_Alloc is a plain 64-byte-aligned aligned_alloc with no device
// handle, so the buffers are independent of any mesh lifetime.
// ═══════════════════════════════════════════════════════════════════════════
#define IFM_PAD_ELEMS (INPUT_H_PAD * INPUT_W_PAD * INPUT_C_ALIGN) // 230*230*4 = 211600
#define WTS_BT_ELEMS (NUM_FILTERS * K)                            // 64*196    = 12544
#define OFM_ELEMS (OUTPUT_H * OUTPUT_W * NUM_FILTERS)             // 112*112*64 = 802816

static int8_t *g_ifm_pad = nullptr;       // [230,230,4] spatially + channel padded
static int8_t *g_wts_bt = nullptr;        // B^T [64,196]
static int8_t *g_ofm = nullptr;           // [112,112,64] AIE destination
static const int8_t *g_wts_src = nullptr; // provenance of the packed weights

// Allocate the staging buffers on first use. The zero-pad regions are written
// once here and never touched again: stage_ifm() only ever overwrites the
// interior real-pixel positions, so the borders stay zero for the process
// lifetime. Same for the padding channel in the weights.
static int ensure_staging(void) {
    if (g_ifm_pad && g_wts_bt && g_ofm)
        return CONV2DSTEM_OK;

    if (!g_ifm_pad)
        g_ifm_pad = (int8_t *)__Runtime_Alloc(IFM_PAD_ELEMS * sizeof(int8_t));
    if (!g_wts_bt)
        g_wts_bt = (int8_t *)__Runtime_Alloc(WTS_BT_ELEMS * sizeof(int8_t));
    if (!g_ofm)
        g_ofm = (int8_t *)__Runtime_Alloc(OFM_ELEMS * sizeof(int8_t));

    if (!g_ifm_pad || !g_wts_bt || !g_ofm) {
        conv2d_stem_release();
        return CONV2DSTEM_ERR_ALLOC;
    }

    // Materialize both pads once. memset covers the spatial border, the padding
    // channel, and the filter's padding channel in one go.
    memset(g_ifm_pad, 0, IFM_PAD_ELEMS * sizeof(int8_t));
    memset(g_wts_bt, 0, WTS_BT_ELEMS * sizeof(int8_t));
    return CONV2DSTEM_OK;
}

// Scatter the caller's raw [224,224,3] IFM into the padded, channel-aligned
// staging buffer. Real pixel (h,w,c) -> ((h+PAD)*INPUT_W_PAD + (w+PAD))*4 + c.
// Channel 3 and the spatial border are left at the zero written by
// ensure_staging() — do NOT memset here, it would re-zero 211600 bytes every
// call to rewrite regions that are already zero.
static void stage_ifm(const int8_t *ifm) {
    for (int h = 0; h < INPUT_H; h++) {
        for (int w = 0; w < INPUT_W; w++) {
            const int src = (h * INPUT_W + w) * INPUT_C;
            const int dst = ((h + PAD) * INPUT_W_PAD + (w + PAD)) * INPUT_C_ALIGN;
            for (int c = 0; c < INPUT_C; c++)
                g_ifm_pad[dst + c] = ifm[src + c];
        }
    }
}

// Pack the caller's raw [64,7,7,3] filter into the B^T[N,K] layout the kernel
// indexes as B_ptr[f*K + (kh*KW + kw)*INPUT_C_ALIGN + c]. The padding channel
// c == 3 stays at the zero from ensure_staging().
static void stage_weights(const int8_t *wts) {
    for (int f = 0; f < NUM_FILTERS; f++) {
        for (int kh = 0; kh < KERNEL_H; kh++) {
            for (int kw = 0; kw < KERNEL_W; kw++) {
                const int src = ((f * KERNEL_H + kh) * KERNEL_W + kw) * INPUT_C;
                const int dst = f * K + (kh * KERNEL_W + kw) * INPUT_C_ALIGN;
                for (int c = 0; c < INPUT_C; c++)
                    g_wts_bt[dst + c] = wts[src + c];
            }
        }
    }
}

void conv2d_stem_invalidate_weights(void) { g_wts_src = nullptr; }

void conv2d_stem_release(void) {
    if (g_ifm_pad) {
        free(g_ifm_pad);
        g_ifm_pad = nullptr;
    }
    if (g_wts_bt) {
        free(g_wts_bt);
        g_wts_bt = nullptr;
    }
    if (g_ofm) {
        free(g_ofm);
        g_ofm = nullptr;
    }
    g_wts_src = nullptr;
}

// ═══════════════════════════════════════════════════════════════════════════
// HOST — library entry
// ═══════════════════════════════════════════════════════════════════════════
int conv2d_stem(const int8_t *ifm, const int8_t *wts, int8_t *ofm) {
    if (!ifm || !wts || !ofm)
        return CONV2DSTEM_ERR_NULL_ARG;

    const int rc = ensure_staging();
    if (rc != CONV2DSTEM_OK)
        return rc;

    stage_ifm(ifm);
    // Re-pack only when the weight buffer changed identity. Callers mutating
    // weights in place must call conv2d_stem_invalidate_weights().
    if (g_wts_src != wts) {
        stage_weights(wts);
        g_wts_src = wts;
    }

    // --- Device + mesh ---
    // Must stay function-local and constant-foldable: the Clang frontend
    // pattern-matches this VarDecl to recover the mesh dims and partition.
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({3, 6, 0, 6}, HW_ROWS, HW_COLS);

    conv2d_spatial<<<mesh>>>(g_ifm_pad, g_wts_bt, g_ofm, M, N, K);

    // Copy the AIE result out to the caller's buffer. The AIE destination is a
    // cached staging buffer rather than `ofm` directly because the caller's
    // pointer carries no alignment guarantee, while the shim S2MM gather needs
    // the 64-byte-aligned DMA-capable allocation from __Runtime_Alloc.
    memcpy(ofm, g_ofm, OFM_ELEMS * sizeof(int8_t));
    return CONV2DSTEM_OK;
}

// ═══════════════════════════════════════════════════════════════════════════
// HOST — bring-up verification (opt-in, NOT on the conv2d_stem() fast path)
// ═══════════════════════════════════════════════════════════════════════════

// Scalar reference conv over the SAME padded staging buffer the AIE consumed,
// so a divergence points at the data path and not at a staging mismatch.
// Iterating the padded extents gives true padded conv with no OOB reads.
static void scalar_conv2d_ref(const int8_t *ifm_pad, const int8_t *wts_bt, int8_t *ref) {
    for (int oh = 0; oh < OUTPUT_H; oh++) {
        for (int ow = 0; ow < OUTPUT_W; ow++) {
            for (int f = 0; f < NUM_FILTERS; f++) {
                int16_t acc = 0;
                for (int kh = 0; kh < KERNEL_H; kh++) {
                    for (int kw = 0; kw < KERNEL_W; kw++) {
                        for (int c = 0; c < INPUT_C_ALIGN; c++) {
                            const int ih = oh * STRIDE + kh;
                            const int iw = ow * STRIDE + kw;
                            const int kk = (kh * KERNEL_W + kw) * INPUT_C_ALIGN + c;
                            const int8_t iv = ifm_pad[(ih * INPUT_W_PAD + iw) * INPUT_C_ALIGN + c];
                            const int8_t fv = wts_bt[f * K + kk];
                            acc += (int16_t)iv * (int16_t)fv;
                        }
                    }
                }
                if (acc > 127)
                    acc = 127;
                else if (acc < -128)
                    acc = -128;
                ref[(oh * OUTPUT_W + ow) * NUM_FILTERS + f] = (int8_t)acc;
            }
        }
    }
}

#define CONV2DSTEM_MAX_REPORTED_MISMATCHES 32

int conv2d_stem_verify(const int8_t *ifm, const int8_t *wts, int8_t *ofm) {
    const int rc = conv2d_stem(ifm, wts, ofm);
    if (rc != CONV2DSTEM_OK)
        return rc;

    // 802816 bytes — too large for the stack, so allocate it.
    int8_t *ref = (int8_t *)malloc(OFM_ELEMS * sizeof(int8_t));
    if (!ref)
        return CONV2DSTEM_ERR_ALLOC;

    printf("[conv2dstem] computing CPU reference (157M MACs, this is slow)...\n");
    XTime t_start, t_end;
    XTime_GetTime(&t_start);
    scalar_conv2d_ref(g_ifm_pad, g_wts_bt, ref);
    XTime_GetTime(&t_end);
    printf("[conv2dstem] CPU reference time: %.3f ms\n", 1.0 * (t_end - t_start) / COUNTS_PER_SECOND * 1000.0);

    int mismatches = 0;
    for (int i = 0; i < OFM_ELEMS; i++) {
        if (ofm[i] != ref[i]) {
            if (mismatches < CONV2DSTEM_MAX_REPORTED_MISMATCHES) {
                const int oh = i / (OUTPUT_W * NUM_FILTERS);
                const int ow = (i / NUM_FILTERS) % OUTPUT_W;
                const int f = i % NUM_FILTERS;
                printf("[conv2dstem] MISMATCH ofm[oh=%d,ow=%d,f=%d] (flat %d): got %d, expected %d\n", oh, ow, f, i,
                       ofm[i], ref[i]);
            }
            mismatches++;
        }
    }
    free(ref);

    if (mismatches == 0)
        printf("[conv2dstem] PASS: all %d output elements match.\n", OFM_ELEMS);
    else
        printf("[conv2dstem] FAIL: %d mismatches out of %d.\n", mismatches, OFM_ELEMS);
    return mismatches;
}
