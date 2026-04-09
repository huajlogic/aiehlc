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

class TilingLinalgPipeline {
public:
    /// Register all 6 dialect managers + standard dialects on ctx
    static void registerDialects(mlir::MLIRContext &ctx);

    /// Build initial routing IR (parameterized version of ops_testNew)
    /// meshRows/meshCols -> createhwmesh dimensions
    /// tensors -> createscheduletensor + createroutingfuncByDim for each
    static mlir::ModuleOp buildRoutingIR(
        mlir::MLIRContext &ctx,
        int meshRows, int meshCols,
        const std::vector<TensorParam> &tensors);

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
                            const std::vector<TensorParam> &tensors = {});
};
