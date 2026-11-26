/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef __STARTIO_INTERLEAVE_PASS__
#define __STARTIO_INTERLEAVE_PASS__

#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"

using namespace mlir;

struct StartioInterleavePass : public PassWrapper<StartioInterleavePass, OperationPass<ModuleOp>> {
    MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(StartioInterleavePass)
    StringRef getArgument() const final { return "startio-interleave"; }
    StringRef getDescription() const final { return "Issue each DMA channel right after its BD chain"; }
    void runOnOperation() override;
};

// #pragma dataflow_slices (dfschedule.plan_slices): issue B -> C -> A and pre-queue call i+1's shim MM2S inputs on
// an alt BD before call i's waits (sliceprequeue_plan.h). A no-op on a module without plan_slices.
struct SlicePrequeuePass : public PassWrapper<SlicePrequeuePass, OperationPass<ModuleOp>> {
    MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(SlicePrequeuePass)
    StringRef getArgument() const final { return "slice-prequeue"; }
    StringRef getDescription() const final { return "Pre-queue the next slice's shim inputs (dataflow_slices)"; }
    void runOnOperation() override;
};

#endif
