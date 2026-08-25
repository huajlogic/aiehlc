/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#include "AiegraphLowerDriver.h"
#include "aiegraphmanager.h"

#include "mlir/IR/Verifier.h"
#include "mlir/Parser/Parser.h"
#include "llvm/Support/SourceMgr.h"

namespace aiegraph {

// conv params header: {H,W,Cin,Cout,K,stride}
static constexpr int64_t kConvConfigSz = 6;
// fc params header:   {spatial_h,spatial_w,channels,num_classes}
static constexpr int64_t kFcConfigSz = 4;

// Param buffer byte-length for a conv op — matches model.make_conv_params:
//   [config:6][weights:Cin*Cout*K*K][bn_scale:Cout][bn_bias:Cout]
static int64_t convParamSz(int64_t Cin, int64_t Cout, int64_t K) {
    return kConvConfigSz + Cin * Cout * K * K + Cout * 2;
}

// Param buffer byte-length for the fc op — matches model.make_fc_params:
//   [config:4][weights:channels*num_classes][bias:num_classes]
static int64_t fcParamSz(int64_t channels, int64_t num_classes) {
    return kFcConfigSz + channels * num_classes + num_classes;
}

/// Build per-op launch descriptors from one verified aiegraph.func body, in
/// program order. Mirrors _compiler._tensor_specs exactly so the emitted launch
/// dirs are byte-for-byte the same as the direct-Python path.
static void collectLaunches(FuncOp fn, std::vector<AiegraphLaunch> &out) {
    int idx = 0;
    for (Operation &opRef : fn.getBody().front()) {
        Operation *op = &opRef;
        AiegraphLaunch L;
        L.index = idx;

        if (auto c = llvm::dyn_cast<ConvBnReluOp>(op)) {
            L.op = "conv_bn_relu";
            int64_t H = c.getH(), W = c.getW(), Cin = c.getCin(), Cout = c.getCout(), K = c.getK(),
                    stride = c.getStride();
            int64_t out_h = stride ? H / stride : 0, out_w = stride ? W / stride : 0;
            L.tensorSpecs.push_back({{Cin * H * W}, 8, true});
            L.tensorSpecs.push_back({{convParamSz(Cin, Cout, K)}, 8, true});
            L.tensorSpecs.push_back({{Cout * out_h * out_w}, 8, false});
            if (auto w = c.getWeights())
                L.weightsSym = w->str();
        } else if (auto c = llvm::dyn_cast<ConvBnOp>(op)) {
            L.op = "conv_bn";
            int64_t H = c.getH(), W = c.getW(), Cin = c.getCin(), Cout = c.getCout(), K = c.getK(),
                    stride = c.getStride();
            int64_t out_h = stride ? H / stride : 0, out_w = stride ? W / stride : 0;
            L.tensorSpecs.push_back({{Cin * H * W}, 8, true});
            L.tensorSpecs.push_back({{convParamSz(Cin, Cout, K)}, 8, true});
            L.tensorSpecs.push_back({{Cout * out_h * out_w}, 8, false});
            if (auto w = c.getWeights())
                L.weightsSym = w->str();
        } else if (auto r = llvm::dyn_cast<ResidualAddReluOp>(op)) {
            L.op = "residual_add_relu";
            int64_t n = r.getLength();
            L.tensorSpecs.push_back({{n}, 8, true});
            L.tensorSpecs.push_back({{n}, 8, true});
            L.tensorSpecs.push_back({{n}, 8, false});
        } else if (auto a = llvm::dyn_cast<AvgPoolFcOp>(op)) {
            L.op = "avgpool_fc";
            int64_t sh = a.getSpatialH(), sw = a.getSpatialW(), ch = a.getChannels(), nc = a.getNumClasses();
            L.tensorSpecs.push_back({{ch * sh * sw}, 8, true});
            L.tensorSpecs.push_back({{fcParamSz(ch, nc)}, 8, true});
            L.tensorSpecs.push_back({{nc}, 8, false});
            if (auto w = a.getWeights())
                L.weightsSym = w->str();
        } else {
            // YieldOp / anything else: not a launch.
            continue;
        }

        L.funcName = L.op + "_" + std::to_string(idx);
        out.push_back(std::move(L));
        ++idx;
    }
}

std::vector<AiegraphLaunch> AiegraphLowerDriver::lower(mlir::ModuleOp module, bool &ok) {
    std::vector<AiegraphLaunch> launches;
    ok = false;
    if (!module)
        return launches;
    if (mlir::failed(mlir::verify(module)))
        return launches;

    module.walk([&](FuncOp fn) { collectLaunches(fn, launches); });
    ok = true;
    return launches;
}

std::vector<AiegraphLaunch> AiegraphLowerDriver::lowerFromText(mlir::MLIRContext &ctx, const std::string &mlirText,
                                                               bool &ok) {
    ok = false;
    aiegraphmanager::loaddialect(&ctx);

    mlir::OwningOpRef<mlir::ModuleOp> module = mlir::parseSourceString<mlir::ModuleOp>(mlirText, &ctx);
    if (!module)
        return {};

    return lower(module.get(), ok);
}

} // namespace aiegraph
