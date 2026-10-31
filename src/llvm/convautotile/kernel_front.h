/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tensor-form kernels: the block-load programming model with typed tensors.
 *
 *   using Ifm = aie::tensor<int8_t, 224, 224, 3>;
 *   template <int OH_T = 7, int OW_T = 28, int OC_T = 16>
 *   __global__ aie::autotune<OH_T, {7, 14, 28}, OW_T, {14, 28, 56}, OC_T, {16, 32}>
 *   void conv2d(aie::in<Ifm> x_t, aie::in<Wgt> w_t, aie::out<Ofm> y_t) {
 *       auto w = aie::load_buffer(w_t, {...}, {...}, {.reuse = N});
 *       auto x = aie::load_buffer(x_t, {oh0 * S - P, ...}, {...}, {.pad = aie::pad_value::zero});
 *       auto y = aie::store_buffer(y_t, {...}, {...});
 *       ... x(i, j, c) ... y(i, j, k) = aie::saturate<int8_t>(acc);
 *   }   // x released, y committed at the end of their scope
 *   ...
 *   auto in = aie::alloc<Ifm>();  conv2d<<<mesh>>>(in, wt, out);
 *
 * lowerTensorForm rewrites such a source into the kernel-only form
 * (kernel_trace.h) that inferKernelOnly derives and verifies the DMA of:
 *
 *   1. the kernel is traced in its OWN coordinates (pass A, traceLogical):
 *      out-of-tensor blocks without .pad, data used without load / after its
 *      scope, {.reuse} vs the stores made while the block is held, ...;
 *   2. the traced footprint fixes the DDR layout: zero border = how far the
 *      .pad loads reach outside the tensor, channel dim aligned to 4 bytes;
 *   3. the kernel is rewritten into that staged layout (offsets shifted by the
 *      border, channel extent aligned, block views, explicit release / commit)
 *      and checked again by inferKernelOnly (pass B);
 *   4. aie::autotune: every candidate is lowered and checked the same way, and
 *      the legal one the convautotile cost model ranks fastest is kept;
 *   5. host: aie::tensor / aie::alloc, and each launch stages its inputs into
 *      the padded / aligned layout before the DMA reads them.
 *
 * Source lines are preserved, so every diagnostic names the user's line.
 * Design: doc/design/op_mapping_programming_model.md, "Tensor form".
 ******************************************************************************/
#pragma once

#include <string>
#include <vector>

namespace convautotile {

struct TensorFormResult {
    bool found = false; // the source has a tensor-form __global__ kernel
    bool ok = true;
    std::vector<std::string> errors, notes;
    std::string report;
};

// Lower every tensor-form kernel of `src` (in place) into the kernel-only form.
TensorFormResult lowerTensorForm(std::string &src, const std::string &srcDir, const std::string &srcName);

} // namespace convautotile
