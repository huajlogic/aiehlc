/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef __AIEGRAPH_LOWER_DRIVER__
#define __AIEGRAPH_LOWER_DRIVER__

#include "mlir/IR/BuiltinOps.h"
#include <string>
#include <vector>

namespace aiegraph {

/// One int8 window buffer of a launch (feature / params / output).
/// Mirrors the (shape, bits=8, isInput) tuples produced by
/// ``_compiler._tensor_specs`` on the Python side.
struct LaunchTensorSpec {
    std::vector<int64_t> shape; // flat element count(s)
    int elementBitWidth = 8;    // always 8 for aiegraph
    bool isInput = true;
};

/// A single per-op launch recovered from an ``aiegraph.func`` in topological
/// order. This is exactly the information ``_compiler.compile_launch`` needs to
/// pair with a kernel body and hand to ``run_aie_pipeline`` — one launch dir per
/// op. The kernel body itself stays in Python (``kernels.kernel_body_for``); the
/// driver only owns verification + the topological walk + geometry→tensor_specs.
struct AiegraphLaunch {
    int index = 0;        // position in the func body (launch dir prefix)
    std::string op;       // "conv_bn_relu" | "conv_bn" | "residual_add_relu" | "avgpool_fc"
    std::string funcName; // "<op>_<index>"
    std::vector<LaunchTensorSpec> tensorSpecs;
    // Weights table symbol referenced by the op (empty for residual_add_relu).
    std::string weightsSym;
};

/// Walks a verified ``aiegraph.func`` in body order and produces one
/// ``AiegraphLaunch`` per fused/quantized op. No backend is invoked here; the
/// caller (pybind → Python) loops the launches calling ``run_aie_pipeline``.
class AiegraphLowerDriver {
  public:
    /// Parse ``aiegraph`` textual IR, verify it, and return the ordered launches.
    /// On parse/verify failure the returned vector is empty and ``ok`` is false.
    static std::vector<AiegraphLaunch> lowerFromText(mlir::MLIRContext &ctx, const std::string &mlirText, bool &ok);

    /// Same, over an already-built (and verified) module.
    static std::vector<AiegraphLaunch> lower(mlir::ModuleOp module, bool &ok);
};

} // namespace aiegraph

#endif // __AIEGRAPH_LOWER_DRIVER__
