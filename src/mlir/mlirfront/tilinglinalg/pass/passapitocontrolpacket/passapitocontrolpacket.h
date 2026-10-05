/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

#ifndef __API_TO_CONTROL_PACKET_PASS_H__
#define __API_TO_CONTROL_PACKET_PASS_H__

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include "dfschedulemanager.h"
#include <string>

namespace mlir {

class APIToControlPacketPass : public PassWrapper<APIToControlPacketPass, OperationPass<ModuleOp>> {
  public:
    enum class Phase { Collect, Emit };
    APIToControlPacketPass() = default;
    APIToControlPacketPass(Phase phase, std::string outputDir = "", int partStartCol = 0, int partNumCols = 0,
                           int aieGen = 5)
        : phase(phase), outputDir(std::move(outputDir)), partStartCol(partStartCol), partNumCols(partNumCols),
          aieGen(aieGen) {}

    StringRef getArgument() const final { return "api-to-control-packet"; }
    StringRef getDescription() const final {
        return "Record control-packet runtime API calls for ahead-of-time packet creation";
    }

    void runOnOperation() override;

    void getDependentDialects(DialectRegistry &registry) const override {
        registry.insert<dfschedule::dfscheduledialect, func::FuncDialect>();
    }

  private:
    void runCollect(ModuleOp mod);
    void runEmit(ModuleOp mod);

    Phase phase = Phase::Collect;
    std::string outputDir;
    int partStartCol = 0;
    int partNumCols = 0;
    int aieGen = 5;
};

}

#endif
