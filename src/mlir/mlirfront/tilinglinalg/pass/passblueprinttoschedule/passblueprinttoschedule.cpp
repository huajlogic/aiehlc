/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

#include "passblueprinttoschedule.h"
#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include "helper/flowtransfer_internal.h"
#include "hw/ResourceManager.h"
#include "hw/hwresource.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Transforms/DialectConversion.h"
#include "routingmanager.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include <iostream>
#include <sstream>
#include <unordered_map>
#include <vector>

using namespace mlir;
using namespace dfscheblueprint;
using namespace dfschedule;

namespace {

template <typename OpTy>
struct EraseOpPattern : public OpConversionPattern<OpTy> {
    using OpConversionPattern<OpTy>::OpConversionPattern;

    LogicalResult
    matchAndRewrite(OpTy op, typename OpTy::Adaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

// Special pattern for DataSliceOp - replaces with input tensor instead of erasing
struct DataSliceOpConversion : public OpConversionPattern<dfscheblueprint::DataSliceOp> {
    using OpConversionPattern<dfscheblueprint::DataSliceOp>::OpConversionPattern;

    LogicalResult matchAndRewrite(dfscheblueprint::DataSliceOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // DataSliceOp is used for symbol references, replace with the input tensor
        rewriter.replaceOp(op, adaptor.getTensorSlice());
        return success();
    }
};

// Pattern for DeclareDataOp - pass through the init_tensor operand to all users
struct DeclareDataOpConversion : public OpConversionPattern<dfscheblueprint::DeclareDataOp> {
    using OpConversionPattern<dfscheblueprint::DeclareDataOp>::OpConversionPattern;

    LogicalResult matchAndRewrite(dfscheblueprint::DeclareDataOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // DeclareDataOp is a logical wrapper around init_tensor; pass through the input
        rewriter.replaceOp(op, adaptor.getInitTensor());
        return success();
    }
};

// Part D (NCHW conv output): reinterpret the rank-3 conv-output DDR root memref
// with an NCHW strided layout so the per-mesh-row memref.subview yields an
// NCHW base offset (R*OUTPUT_W per H-slab) instead of the NHWC row-major offset.
//
// The logical shape stays [H, W, C] (row order preserved), only the strides
// change from row-major NHWC [W*C, C, 1] to NCHW [W, 1, H*W]. A subview
// [R*ohSlab, 0, 0] then legally carries offset R*ohSlab*W (elements).
//
// Returns the reinterpret_cast result, or the original `root` if the tiling
// attr is absent/malformed (safe fallback to NHWC).
static mlir::Value reinterpretRootAsNchw(ConversionPatternRewriter &rewriter, Location loc, mlir::Value root,
                                         mlir::Attribute tilingAttr) {
    auto rootType = dyn_cast<MemRefType>(root.getType());
    if (!rootType || rootType.getRank() != 3)
        return root;
    auto tiling = tilingAttr ? dyn_cast_or_null<routing::TilingAttr>(tilingAttr) : routing::TilingAttr();
    if (!tiling || tiling.getDims().size() < 3)
        return root;
    routing::LevelAttr d0Outer = tiling.getDims()[0].getOuter(); // H
    routing::LevelAttr d1Outer = tiling.getDims()[1].getOuter(); // W
    if (!d0Outer || !d1Outer)
        return root;
    int64_t OUTPUT_H = d0Outer.getBase();
    int64_t OUTPUT_W = d1Outer.getBase();
    ArrayRef<int64_t> shape = rootType.getShape(); // [H, W, C]
    if (OUTPUT_H <= 0 || OUTPUT_W <= 0 || shape.size() != 3)
        return root;
    // NCHW strides over the logical [H, W, C] shape.
    SmallVector<int64_t> nchwStrides = {OUTPUT_W, 1, OUTPUT_H * OUTPUT_W};
    auto layout = StridedLayoutAttr::get(rewriter.getContext(), /*offset=*/0, nchwStrides);
    auto nchwType = MemRefType::get(shape, rootType.getElementType(), layout, rootType.getMemorySpace());
    SmallVector<int64_t> sizes(shape.begin(), shape.end());
    auto reOp = rewriter.create<memref::ReinterpretCastOp>(loc, nchwType, root, /*offset=*/0, sizes, nchwStrides);
    return reOp.getResult();
}

} // namespace

namespace blueprint_sched {

LogicalResult FlowTransferConversion::matchAndRewrite(dfscheblueprint::FlowTransferOp op, OpAdaptor adaptor,
                                                      ConversionPatternRewriter &rewriter) const {
    auto loc = op.getLoc();

    // --- Prologue: resolve "from"/"to" FlowConfig roles + backing memref ---
    SymbolRefAttr fromRef = op.getFrom();
    auto fromFlowConfig = lookupFlowConfig(op.getOperation(), fromRef);
    if (!fromFlowConfig) {
        rewriter.eraseOp(op);
        return success();
    }

    SymbolRefAttr toRef = op.getTo();
    auto toFlowConfig = lookupFlowConfig(op.getOperation(), toRef);
    if (!toFlowConfig) {
        rewriter.eraseOp(op);
        return success();
    }

    // Step 1: determine which FlowConfig is shim and which is core.
    FlowLoweringCtx c(rewriter, loc, op);
    auto fromType = fromFlowConfig.getType();
    auto toType = toFlowConfig.getType();

    if (fromType && *fromType == "shim") {
        c.shimFlowConfig = fromFlowConfig;
        c.coreFlowConfig = toFlowConfig;
        c.shimIsSender = true;
    } else if (toType && *toType == "shim") {
        c.shimFlowConfig = toFlowConfig;
        c.coreFlowConfig = fromFlowConfig;
        c.shimIsSender = false;
    } else {
        rewriter.eraseOp(op);
        return success();
    }

    // Get tile groups
    c.shimTileGroup = lookupTileGroup(c.shimFlowConfig.getOperation(), c.shimFlowConfig.getTarget());
    c.coreTileGroup = lookupTileGroup(c.coreFlowConfig.getOperation(), c.coreFlowConfig.getTarget());
    if (!c.shimTileGroup || !c.coreTileGroup) {
        rewriter.eraseOp(op);
        return success();
    }

    c.basePacketId = op.getBasePacketId();
    c.flowIndex = op.getFlowIndex();

    // Get the view operand from the shim FlowConfig (shim holds the data buffer)
    c.viewValue = c.shimFlowConfig.getView();
    c.viewType = c.viewValue.getType();

    // Trace back to tensor.extract_slice to get partition offsets/sizes
    c.partExtractSlice = c.viewValue.getDefiningOp<tensor::ExtractSliceOp>();
    c.shimTensorType = dyn_cast<RankedTensorType>(c.viewType);

    // Resolve which backing memref this flow's data belongs to.
    if (passState && !passState->constantToMemref.empty()) {
        c.flowRootMemref = resolveMemrefForView(c.viewValue, *passState);
    }
    if (!c.flowRootMemref && passState)
        c.flowRootMemref = passState->rootMemref;

    // Create partition subview from the pre-allocated root memref
    if (c.flowRootMemref && c.partExtractSlice && c.shimTensorType) {
        auto partOffsets = c.partExtractSlice.getStaticOffsets();
        auto partSizes = c.partExtractSlice.getStaticSizes();
        auto partStrides = c.partExtractSlice.getStaticStrides();

        // Part D: for the rank-3 conv OUTPUT flow (cores -> shim, S2MM receiver),
        // reinterpret the DDR root with an NCHW strided layout so the per-mesh-row
        // subview base offset becomes NCHW (R*OUTPUT_W) rather than NHWC row-major.
        // Guarded by a tiling attr on the partition extract_slice; falls back to the
        // NHWC root when absent (matmul / input halo paths are untouched).
        mlir::Value subviewRoot = c.flowRootMemref;
        if (!c.shimIsSender) {
            mlir::Attribute tilingAttr = c.partExtractSlice->getAttr("tiling");
            subviewRoot = reinterpretRootAsNchw(rewriter, loc, c.flowRootMemref, tilingAttr);
        }

        auto partSubviewOp = rewriter.create<memref::SubViewOp>(loc, subviewRoot, toOpFoldResult(partOffsets, rewriter),
                                                                toOpFoldResult(partSizes, rewriter),
                                                                toOpFoldResult(partStrides, rewriter));
        c.partitionSubview = partSubviewOp.getResult();
        c.ddrBuffer = c.partitionSubview;
        c.memrefType = cast<MemRefType>(c.ddrBuffer.getType());
    } else if (c.flowRootMemref && c.shimTensorType) {
        c.ddrBuffer = c.flowRootMemref;
        c.memrefType = cast<MemRefType>(c.flowRootMemref.getType());
        c.partitionSubview = c.flowRootMemref;
    } else if (auto mrType = dyn_cast<MemRefType>(c.viewType)) {
        c.memrefType = mrType;
    } else {
        rewriter.eraseOp(op);
        return success();
    }

    // --- Step 2 & 3: shim tile guards (must precede DeclareTileOp) ---
    ArrayAttr shimTilesAttr = c.shimTileGroup.getTiles();
    if (shimTilesAttr.empty()) {
        rewriter.eraseOp(op);
        return success();
    }
    auto firstShimTile = dyn_cast<ArrayAttr>(shimTilesAttr[0]);
    if (!firstShimTile || firstShimTile.size() < 2) {
        rewriter.eraseOp(op);
        return success();
    }

    // --- HOST: shim tile + DMA params + shim BD ---
    emitShimTileAndParams(c);
    if (failed(computeShimBdParams(c)))
        return failure();

    if (c.useOOO && c.numCoreTiles > 1) {
        emitShimBdOoo(c);
    } else {
        emitShimBdNonOoo(c);
    }

    // Shim create_io (consumes last shim BD in SSA chain). Shared across
    // OOO / non-OOO paths so it lives in the orchestrator.
    c.createIoOp = rewriter.create<dfschedule::ConfigCreateIoOp>(
        loc, dfschedule::IoHandleType::get(rewriter.getContext()),
        c.lastShimBdHandle,                        // BD handle (first BD in chain or single)
        c.shimTileOp.getTile(),                    // tile
        rewriter.getI32IntegerAttr(c.shimChannel), // channel
        rewriter.getStringAttr(c.dmaDirection),    // direction (MM2S or S2MM)
        rewriter.getStringAttr(c.ioOperation),     // io_operation (SEND or RECV)
        rewriter.getBoolAttr(c.useOOO));           // enable_out_of_order

    // --- KERNEL: core-tile configs (declaretile + kernel_config + core DMA) ---
    if (failed(emitCoreTileConfigs(c)))
        return failure();

    if (c.coreTiles.empty()) {
        rewriter.eraseOp(op);
        return success();
    }

    finalizeKernelConfig(c);

    // --- HOST: schedule classify + emit ---
    classifyScheduleMode(c);

    if (c.needsOuterLoop && c.shimIsSender) {
        if (failed(emitScheduleMultipleInput(c)))
            return failure();
    } else if (c.useOOO && c.usedMRounds3D && c.oooMRounds > 1) {
        emitScheduleOooOutput(c);
    } else {
        emitScheduleStraightLine(c);
    }

    // Stage 6: free DDR allocation after all transfers complete
    if (c.ddrBuffer) {
        rewriter.create<dfschedule::FreeDeviceMemOp>(loc, c.ddrBuffer);
    }

    // --- Step 5: Generate dskernel_receiver function ---
    StringRef kernelName = "dskernel_receiver";
    if (!hasDSKernelReceiver(op.getOperation(), kernelName)) {
        RankedTensorType kernelTensorType;
        if (auto tensorType = dyn_cast<RankedTensorType>(c.viewType)) {
            kernelTensorType = tensorType;
        } else if (auto mrType = dyn_cast<MemRefType>(c.viewType)) {
            kernelTensorType = RankedTensorType::get(mrType.getShape(), mrType.getElementType());
        }
        if (kernelTensorType) {
            generateDSKernelReceiver(rewriter, loc, op.getOperation(), kernelName, kernelTensorType, c.bufferLen,
                                     c.basePacketId, c.coreChannel, c.flowIndex);
        }
    }

    // Erase the original FlowTransferOp
    rewriter.eraseOp(op);

    return success();
}

} // namespace blueprint_sched

namespace mlir {

void BlueprintToSchedulePass::runOnOperation() {
    MLIRContext *context = &getContext();

    // --- Phase 1: Pre-processing ---
    auto passState = std::make_shared<blueprint_sched::BlueprintPassState>();
    if (failed(blueprint_sched::preprocessConstantToMemref(getOperation(), passState))) {
        signalPassFailure();
        return;
    }

    // Cache routing module attributes before conversion (they may be stripped
    // during applyPartialConversion).
    {
        auto moduleOp = dyn_cast<ModuleOp>(getOperation());
        if (moduleOp) {
            auto getI64 = [&](StringRef name) -> int64_t {
                auto attr = moduleOp->getAttrOfType<IntegerAttr>(name);
                return attr ? attr.getInt() : 0;
            };
            // Flat module attrs are the fallback source.
            passState->tileM = getI64("routing.tile_m");
            passState->tileRows = getI64("routing.tile_rows");
            passState->tileN = getI64("routing.tile_n");
            passState->tileCols = getI64("routing.tile_cols");
            passState->effectiveK = getI64("routing.effective_k");
            passState->fullK = getI64("routing.full_k");
            passState->kRounds = getI64("routing.k_rounds");

            // TilingAttr-primary: for fullconnect_auto=1 source the tiling scalars
            // directly from the routing.partitiontensor #routing.tiling op (still live
            // in this Phase-1 pre-processing step, before conversion erases it). The
            // flat attrs above remain the fallback when no TilingAttr is present.
            routing::GemmTilingScalars ir = routing::readGemmTilingScalars(moduleOp);
            passState->tilingScalars = ir; // raw reader output (empty for conv)
            if (ir.found) {
                passState->tileM = ir.tileM;
                passState->tileRows = ir.tileRows;
                passState->tileN = ir.tileN;
                passState->tileCols = ir.tileCols;
                passState->effectiveK = ir.effectiveK;
                passState->fullK = ir.fullK;
                passState->kRounds = ir.kRounds;
            }
        }
    }

    // --- Phase 2: Dialect conversion ---
    ConversionTarget target(*context);
    target.addLegalDialect<dfschedule::dfscheduledialect, routing::routingdialect, func::FuncDialect,
                           memref::MemRefDialect, arith::ArithDialect, scf::SCFDialect, tensor::TensorDialect,
                           bufferization::BufferizationDialect, BuiltinDialect, emitc::EmitCDialect>();

    target.addIllegalOp<dfscheblueprint::FlowConfigOp>();
    target.addIllegalOp<dfscheblueprint::TileGroupOp>();
    target.addIllegalOp<dfscheblueprint::DeclareDataOp>();
    target.addIllegalOp<dfscheblueprint::FlowTransferOp>();

    auto hwRes = makeResource(aieGen_);
    auto resourceMgr = std::make_shared<ResourceMgr>(std::move(hwRes));

    RewritePatternSet patterns(context);
    patterns.add<blueprint_sched::FlowTransferConversion>(context, resourceMgr, passState, bufferRatio_,
                                                          maxPingPongBytes_);
    patterns.add<DataSliceOpConversion>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::FlowConfigOp>>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::TileGroupOp>>(context);
    patterns.add<DeclareDataOpConversion>(context);

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
        return;
    }

    // --- Phase 3: Erase dead tensor/routing ops ---
    // tensor.extract_slice chains can be nested (partition → producer), so
    // iterate until no more dead ops are found.
    SmallVector<Operation *, 8> deadOps;
    bool changed = true;
    while (changed) {
        changed = false;
        deadOps.clear();
        getOperation()->walk([&](Operation *op) {
            if (!op->use_empty())
                return;
            if (isa<tensor::ExtractSliceOp>(op) || isa<routing::partitiontensor>(op) ||
                isa<bufferization::ToTensorOp>(op) ||
                (isa<arith::ConstantOp>(op) && isa<RankedTensorType>(op->getResult(0).getType())))
                deadOps.push_back(op);
        });
        for (auto *op : deadOps) {
            op->erase();
            changed = true;
        }
    }

    // Region restructuring is deferred to ScheduleCanonicalizePass.
    // The dfschedule ops remain inside routing.RoutingCreate bodies, which is
    // valid because RoutingCreate has the SymbolTable trait needed by
    // DeclareKernelConfigOp.  ScheduleCanonicalizePass will extract them into
    // per-partition scf.execute_region blocks and erase the routing ops.
}

} // namespace mlir
