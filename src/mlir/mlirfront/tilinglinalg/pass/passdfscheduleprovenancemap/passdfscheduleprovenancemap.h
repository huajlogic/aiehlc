/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

#ifndef __DFSCHEDULE_PROVENANCEMAP_PASS_H__
#define __DFSCHEDULE_PROVENANCEMAP_PASS_H__

#include "dfschedulemanager.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"

#include <string>

namespace mlir {

class DfscheduleProvenanceMapPass : public PassWrapper<DfscheduleProvenanceMapPass, OperationPass<>> {
  public:
    DfscheduleProvenanceMapPass() = default;
    explicit DfscheduleProvenanceMapPass(const std::string &outputDir) : outputDir(outputDir) {}
    DfscheduleProvenanceMapPass(const std::string &outputDir, int startCol)
        : outputDir(outputDir), startCol(startCol) {}
    DfscheduleProvenanceMapPass(const std::string &outputDir, int startCol, const std::string &aieGen)
        : outputDir(outputDir), startCol(startCol), aieGen(aieGen) {}
    // K-triple threaded in from the pipeline: on the dfschedule/host module the routing
    // dialect is not registered, so the #routing.tiling op is gone. The pipeline reads it
    // once (on the pre-conversion module) and passes the derived K-triple here. A zero value
    // means "not threaded" → fall back to the flat module attr (fullconnect_auto=0 path).
    DfscheduleProvenanceMapPass(const std::string &outputDir, int startCol, const std::string &aieGen,
                                int64_t effectiveK, int64_t fullK, int64_t kRounds, int64_t tileM = 0,
                                int64_t tileN = 0, int64_t mRounds = 0, int64_t nRounds = 0)
        : outputDir(outputDir), startCol(startCol), aieGen(aieGen), ctorEffectiveK(effectiveK), ctorFullK(fullK),
          ctorKRounds(kRounds), ctorTileM(tileM), ctorTileN(tileN), ctorMRounds(mRounds), ctorNRounds(nRounds) {}

    void runOnOperation() override;

    StringRef getArgument() const override { return "dfschedule-provenance-map"; }
    StringRef getDescription() const override { return "Generate low-level provenance map JSON from dfschedule IR"; }

    void getDependentDialects(DialectRegistry &registry) const override {
        registry.insert<dfschedule::dfscheduledialect>();
        registry.insert<func::FuncDialect>();
        registry.insert<memref::MemRefDialect>();
        registry.insert<arith::ArithDialect>();
        registry.insert<scf::SCFDialect>();
    }

  private:
    std::string outputDir;
    int startCol = -1;
    std::string aieGen;
    int64_t ctorEffectiveK = 0;
    int64_t ctorFullK = 0;
    int64_t ctorKRounds = 0;
    int64_t ctorTileM = 0;
    int64_t ctorTileN = 0;
    int64_t ctorMRounds = 0;
    int64_t ctorNRounds = 0;
};

} // namespace mlir

#endif // __DFSCHEDULE_PROVENANCEMAP_PASS_H__
