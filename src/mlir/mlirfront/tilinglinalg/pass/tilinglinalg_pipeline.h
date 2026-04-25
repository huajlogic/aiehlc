/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#pragma once

#include "mlir/IR/BuiltinOps.h"
#include <string>
#include <vector>

struct TensorParam {
    std::vector<int64_t> shape;  // e.g. {16, 16}
    int elementBitWidth;         // e.g. 32 for int32_t, 8 for int8_t
    bool isInput;                // true = input, false = output
};

/// Per-tensor split descriptor — maps to partitiontensor op attributes.
/// Spatial tags control mesh partitioning (hwAxisOwner, replicateOn), not tensor splitting.
struct TensorSplitDesc {
    int splitDim;            // tensor dimension to split (default: 0). Irrelevant when splitnum=1.
    std::string hwAxisOwner; // "row" | "col" | "" — which mesh axis owns this tensor's partition
    std::string replicateOn; // "row" | "col" | "" — which mesh axis to replicate/broadcast on
};

/// Operation-level split model: one TensorSplitDesc per tensor.
struct SplitModel {
    std::vector<TensorSplitDesc> tensorSplits;

    /// Factory: default GEMM
    /// A: tensor split dim=0, mesh partition by row, broadcast along cols
    /// B: tensor split dim=0, mesh partition by col, broadcast along rows
    /// C: tensor split dim=0, mesh partition by row, gather along cols
    static SplitModel gemm() { return {{{0, "row", "col"}, {0, "col", "row"}, {0, "row", "col"}}}; }

    /// Construct a TensorSplitDesc from a spatial type tag string.
    /// tag: "row_broadcast_in", "col_broadcast_in", etc.
    /// isInput: used for default when tag is empty.
    static TensorSplitDesc fromSpatialTag(const std::string &tag, bool isInput);
};

class TilingLinalgPipeline {
public:
    /// Register all 6 dialect managers + standard dialects on ctx
    static void registerDialects(mlir::MLIRContext &ctx);

    /// Build initial routing IR (parameterized version of ops_testNew)
    /// meshRows/meshCols -> createhwmesh dimensions
    /// tensors -> createscheduletensor + createroutingfuncBySplitModel
    /// splitModel -> per-tensor data distribution strategy
    static mlir::ModuleOp buildRoutingIR(mlir::MLIRContext &ctx, int meshRows, int meshCols,
                                         const std::vector<TensorParam> &tensors,
                                         const SplitModel &splitModel = SplitModel::gemm());

    /// Run the full pipeline and emit files to outputDir:
    ///   host.cc, kernel.cc, routing.cc, aieml.bcf, aieml.prx
    /// If userKernelBody is non-empty, it is written as computekernel.cc
    /// instead of auto-generating the compute kernel. The function name
    /// in userKernelBody (userKernelFuncName) is renamed to match the
    /// pipeline's expected compute kernel name.
    /// Returns true on success.
    static bool runPipeline(mlir::MLIRContext &ctx, mlir::ModuleOp module, const std::string &outputDir,
                            const std::string &userKernelBody = "", const std::string &userKernelFuncName = "",
                            int runtimeDebugLevel = -1, const std::string &userRewrittenSource = "",
                            const std::vector<TensorParam> &tensors = {}, int64_t maxPingPongBytes = 4096);
};
