/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

#ifndef __DFSCHEDULE_TO_KERNEL_API_PASS_H__
#define __DFSCHEDULE_TO_KERNEL_API_PASS_H__

#include "dfschedulemanager.h"
#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"

namespace mlir {

/// Converts dfschedule.module (kernel logic) into emitc line-by-line:
/// each dfschedule op inside the module is converted to corresponding emitc ops.
class DfscheduleToKernelApiPass : public PassWrapper<DfscheduleToKernelApiPass, OperationPass<ModuleOp>> {
  public:
    DfscheduleToKernelApiPass() = default;
    // Absolute column of the partition origin. Plan columns are partition-relative,
    // but get_coreid() reports the absolute hardware column.
    explicit DfscheduleToKernelApiPass(int partStartCol) : partStartCol(partStartCol < 0 ? 0 : partStartCol) {}

    StringRef getArgument() const final { return "dfschedule-to-kernel-api"; }
    StringRef getDescription() const final { return "Convert dfschedule.module kernel logic to emitc (line-by-line)"; }

    void runOnOperation() override;

    void getDependentDialects(DialectRegistry &registry) const override {
        registry.insert<dfschedule::dfscheduledialect, emitc::EmitCDialect, func::FuncDialect, arith::ArithDialect,
                        memref::MemRefDialect>();
    }

  private:
    int partStartCol = 0;
};

} // namespace mlir

#endif // __DFSCHEDULE_TO_KERNEL_API_PASS_H__
