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
    // Spatial policy fields
    std::string pattern; // "broadcast" | "scatter" | "multicast" | "gather"
    std::string flow;    // "ltor" | "rtol" | "default"
    int pingPong = 2;    // ping-pong buffer depth (2, 4, 8)
    int maxBufferBytes = 4096; // max per-buffer size (PP_MAX_BYTES equivalent)
};

/// Operation-level split model: one TensorSplitDesc per tensor.
struct SplitModel {
    std::vector<TensorSplitDesc> tensorSplits;

    /// Factory: default GEMM
    /// A: tensor split dim=0, mesh partition by row, broadcast along cols
    /// B: tensor split dim=0, mesh partition by col, broadcast along rows
    /// C: tensor split dim=0, mesh partition by row, gather along cols
    static SplitModel gemm() {
        return {{{0, "row", "col", "broadcast", "default", 2, 4096},
                 {0, "col", "row", "broadcast", "default", 2, 4096},
                 {0, "row", "col", "gather", "ltor", 2, 4096}}};
    }

    /// Construct a TensorSplitDesc from a spatial type tag string.
    /// tag: "row_broadcast_in", "col_broadcast_in", etc.
    /// isInput: used for default when tag is empty.
    static TensorSplitDesc fromSpatialTag(const std::string &tag, bool isInput);

    /// Construct a TensorSplitDesc from resolved SpatialPolicy struct fields.
    /// pattern: 0=Broadcast, 1=Scatter, 2=Multicast, 3=Gather
    /// distribution: 0=Row, 1=Col, 2=Grid
    /// mergeOrder: 0=Default, 1=LeftToRight, 2=RightToLeft
    static TensorSplitDesc fromPolicyFields(int pattern, int distribution, int mergeOrder, int pingPong, bool isInput,
                                            int maxBufferBytes = 4096);
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
                                         const SplitModel &splitModel = SplitModel::gemm(),
                                         const std::string &aieGen = "Gen2");

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
                            const std::vector<TensorParam> &tensors = {}, int64_t maxPingPongBytes = 4096,
                            const std::string &aieGen = "Gen2");
};
