/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#ifndef __BLUEPRINT_TOSCHEDULE_KERNEL_PASS_H__
#define __BLUEPRINT_TOSCHEDULE_KERNEL_PASS_H__

#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"

namespace mlir {

class BlueprintToScheduleKernelPass : public PassWrapper<BlueprintToScheduleKernelPass, OperationPass<>> {
  public:
    BlueprintToScheduleKernelPass() = default;
    BlueprintToScheduleKernelPass(double ratio) : bufferRatio_(ratio) {}
    // MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(BlueprintToScheduleKernelPass)

    StringRef getArgument() const final { return "lower-blueprint-to-schedule"; }
    StringRef getDescription() const final { return "Lower dfscheblueprint dialect to dfschedule dialect"; }

    double getBufferRatio() const { return bufferRatio_; }

    void runOnOperation() override;

    void getDependentDialects(DialectRegistry &registry) const override {
        registry.insert<dfscheblueprint::dfscheblueprintdialect, dfschedule::dfscheduledialect, func::FuncDialect,
                        memref::MemRefDialect, arith::ArithDialect, scf::SCFDialect, tensor::TensorDialect>();
    }

  private:
    double bufferRatio_ = 0.5;
};

} // namespace mlir

#endif // __BLUEPRINT_TOSCHEDULE_KERNEL_PASS_H__
