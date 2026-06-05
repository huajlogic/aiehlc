/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#ifndef __DMAPHOP_PROVENANCEMAP_PASS_H__
#define __DMAPHOP_PROVENANCEMAP_PASS_H__

#include "dmaphopmanager.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include "routingmanager.h"

#include <string>

namespace mlir {

class DmaphopProvenanceMapPass : public PassWrapper<DmaphopProvenanceMapPass, OperationPass<>> {
  public:
    DmaphopProvenanceMapPass() = default;
    explicit DmaphopProvenanceMapPass(const std::string &outputDir) : outputDir(outputDir) {}

    void runOnOperation() override;

    StringRef getArgument() const override { return "dmaphop-provenance-map"; }
    StringRef getDescription() const override { return "Generate provenance map JSON from dmaphop IR"; }

    void getDependentDialects(DialectRegistry &registry) const override {
        registry.insert<dmaphop::dmaphopdialect>();
        registry.insert<routing::routingdialect>();
        registry.insert<func::FuncDialect>();
        registry.insert<arith::ArithDialect>();
        registry.insert<tensor::TensorDialect>();
    }

  private:
    std::string outputDir;
};

} // namespace mlir

#endif // __DMAPHOP_PROVENANCEMAP_PASS_H__
