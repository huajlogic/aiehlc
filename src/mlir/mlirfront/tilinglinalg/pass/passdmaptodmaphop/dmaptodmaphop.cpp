/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "dmaptodmaphop.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Transforms/DialectConversion.h"
#include <sstream>

using namespace mlir;
using namespace dmap;
using namespace dmaphop;

namespace {

// This pattern converts a dmap::FuncOp into a standard func::FuncOp and
// triggers the conversion of the operations inside.
struct DmapFuncOpLowering : public OpConversionPattern<dmap::FuncOp> {
    using OpConversionPattern<dmap::FuncOp>::OpConversionPattern;

    LogicalResult
    matchAndRewrite(dmap::FuncOp op, OpAdaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        auto funcType = rewriter.getFunctionType({}, {});
        auto funcOp = rewriter.create<func::FuncOp>(op.getLoc(), op.getSymName(), funcType);

        rewriter.inlineRegionBefore(op.getBody(), funcOp.getBody(), funcOp.end());

        // Convert the dmap::YieldOp terminator to a func::ReturnOp
        for (auto &block : funcOp.getBlocks()) {
            if (auto yieldOp = dyn_cast_or_null<dmap::YieldOp>(block.getTerminator())) {
                rewriter.setInsertionPoint(yieldOp);
                rewriter.replaceOpWithNewOp<func::ReturnOp>(yieldOp);
            }
        }
        
        rewriter.eraseOp(op);
        return success();
    }
};


// Enum to distinguish between push and pull dataflow directions.
enum class DataflowDirection { Push, Pull };

// Generic function to lower a data movement operation (push or pull).
static LogicalResult lowerDataMovementOp(Operation *op, ConversionPatternRewriter &rewriter,
                                         RoutingTopology &router, DataflowDirection direction) {
    auto loc = op->getLoc();
    
    // Get topology info - core tile start row
    int core_start_row = (int) router.getRM()->getrsc()->absTileRow(TileType::Core, 0);
    
    // dmap.push %data, %stream -> stream is operand 1
    // dmap.pull %data from %stream -> stream is operand 1
    Value streamValue = op->getOperand(1);
    Operation *streamOp = streamValue.getDefiningOp();

    dmap::define_io_engine shimEngine, memEngine;
    dmap::define_core_group coreGroup;

    // --- 1. Extract tile/engine definitions from the stream ---
    if (auto chainStreamOp = dyn_cast<dmap::createchainstream>(streamOp)) {
        if (chainStreamOp.getStreams().size() != 2) return op->emitError("only supports 2-hop chained streams");
        auto stream1 = chainStreamOp.getStreams()[0].getDefiningOp<dmap::createstream>();
        auto stream2 = chainStreamOp.getStreams()[1].getDefiningOp<dmap::createstream>();

        auto config1_src = stream1.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
        auto config1_dst = stream1.getDestination().getDefiningOp<dmap::create_io_engin_with_config>();
        auto config2_src = stream2.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
        auto config2_dst = stream2.getDestination().getDefiningOp<dmap::create_core_group_with_config>();
        
        shimEngine = config1_src.getIoengine().getDefiningOp<dmap::define_io_engine>();
        memEngine = config1_dst.getIoengine().getDefiningOp<dmap::define_io_engine>();
        coreGroup = config2_dst.getCoregroup().getDefiningOp<dmap::define_core_group>();

    } else if (auto createStreamOp = dyn_cast<dmap::createstream>(streamOp)) {
        dmap::create_io_engin_with_config shimConfig;
        dmap::create_core_group_with_config coreGroupConfig;
        if (direction == DataflowDirection::Push) { // SHIM -> CORES
            shimConfig = createStreamOp.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
            coreGroupConfig = createStreamOp.getDestination().getDefiningOp<dmap::create_core_group_with_config>();
        } else { // CORES -> SHIM
            coreGroupConfig = createStreamOp.getSource().getDefiningOp<dmap::create_core_group_with_config>();
            shimConfig = createStreamOp.getDestination().getDefiningOp<dmap::create_io_engin_with_config>();
        }
        shimEngine = shimConfig.getIoengine().getDefiningOp<dmap::define_io_engine>();
        coreGroup = coreGroupConfig.getCoregroup().getDefiningOp<dmap::define_core_group>();
    } else {
        return op->emitError("unsupported stream type for lowering");
    }

    // --- 2. Create dmaphop::tile and dmaphop::port Ops ---
    auto shimTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("shim"), rewriter.getI64IntegerAttr(shimEngine.getIoId()), rewriter.getI64IntegerAttr(0));
    auto shimPortOut = rewriter.create<dmaphop::port>(loc, shimTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("shimPortOut"), rewriter.getI64IntegerAttr(0));
    auto shimPortIn = rewriter.create<dmaphop::port>(loc, shimTile, rewriter.getStringAttr("In"), rewriter.getStringAttr("shimPortIn"), rewriter.getI64IntegerAttr(0));
    
    dmaphop::tile memTile;
    dmaphop::port memPortIn, memPortOut;
    if (memEngine) {
        memTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("mem"), rewriter.getI64IntegerAttr(memEngine.getIoId()), rewriter.getI64IntegerAttr(0));
        memPortIn = rewriter.create<dmaphop::port>(loc, memTile, rewriter.getStringAttr("In"), rewriter.getStringAttr("memPortIn"), rewriter.getI64IntegerAttr(0));
        memPortOut = rewriter.create<dmaphop::port>(loc, memTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("memPortOut"), rewriter.getI64IntegerAttr(0));
    }

    SmallVector<dmaphop::tile, 4> coreTiles;
    SmallVector<Value, 4> corePortsInValues;
    SmallVector<dmaphop::port, 4> corePortsOutOps;
    SmallVector<Attribute, 4> consumerPortSymbols;
    for (int i = 0; i < coreGroup.getCoreCount(); ++i) {
        // Use core_start_row as the base for core tile row calculation
        int row = (coreGroup.getGroupAxis() == "col") ? (i + core_start_row) : (coreGroup.getGroupIdx() + core_start_row);
        int col = (coreGroup.getGroupAxis() == "row") ? i : coreGroup.getGroupIdx();
        auto coreTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("core"), rewriter.getI64IntegerAttr(col), rewriter.getI64IntegerAttr(row));
        coreTiles.push_back(coreTile);

        std::string inPortName = "corePortIn" + std::to_string(i);
        auto portInOp = rewriter.create<dmaphop::port>(loc, coreTile, rewriter.getStringAttr("In"), rewriter.getStringAttr(inPortName), rewriter.getI64IntegerAttr(0));
        corePortsInValues.push_back(portInOp.getResult());
        consumerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), inPortName));

        std::string outPortName = "corePortOut" + std::to_string(i);
        corePortsOutOps.push_back(rewriter.create<dmaphop::port>(loc, coreTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr(outPortName), rewriter.getI64IntegerAttr(0)));
    }

    // --- 3. Create dmaphop::create_hop Ops based on direction ---
    SmallVector<Value, 4> hops;
    SmallVector<Attribute, 4> producerPortSymbols;
    if (direction == DataflowDirection::Push) {
        if (memTile) { // SHIM -> MEM -> CORES
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, shimPortOut, memPortIn).getResult());
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, memPortOut, corePortsInValues[0]).getResult());
            producerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), "memPortIn"));
        } else { // SHIM -> CORES
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, shimPortOut, corePortsInValues[0]).getResult());
        }
        for (size_t i = 0; i < corePortsOutOps.size() - 1; ++i) {
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, corePortsOutOps[i], corePortsInValues[i+1]).getResult());
        }
    } else { // Pull
        if (memTile) { // CORES -> MEM -> SHIM
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, memPortOut, shimPortIn).getResult());
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, corePortsOutOps.back(), memPortIn).getResult());
            producerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), "shimPortIn"));
            producerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), "memPortIn"));
        } else { // CORES -> SHIM
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, corePortsOutOps.back(), shimPortIn).getResult());
            producerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), "shimPortIn"));
        }
        for (int i = corePortsOutOps.size() - 2; i >= 0; --i) {
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, corePortsOutOps[i], corePortsInValues[i]).getResult());
        }
    }

    // --- 4. Create path, buffers, and final data movement op ---
    auto path = (direction == DataflowDirection::Push)
        ? rewriter.create<dmaphop::create_path>(loc, hops, rewriter.getArrayAttr(consumerPortSymbols), rewriter.getArrayAttr(producerPortSymbols))
        : rewriter.create<dmaphop::create_path>(loc, hops, rewriter.getArrayAttr(producerPortSymbols), rewriter.getArrayAttr({}));

    auto memrefType = MemRefType::get(ArrayRef<int64_t>{1024}, rewriter.getF32Type());
    Value ddrBuffer = rewriter.create<memref::AllocOp>(loc, memrefType);
    Value coreBufferTemplate = rewriter.create<memref::AllocOp>(loc, memrefType);
    SmallVector<Value, 4> coreBuffers;
    for (auto coreTile : coreTiles) {
        coreBuffers.push_back(rewriter.create<dmaphop::alloc_buffer>(loc, memrefType, coreTile.getResult(), coreBufferTemplate).getResult());
    }

    if (direction == DataflowDirection::Push) {
        rewriter.create<dmaphop::push>(loc, ddrBuffer, path, coreBuffers, corePortsInValues);
    } else {
        rewriter.create<dmaphop::pull>(loc, ddrBuffer, path, coreBuffers, corePortsInValues);
    }
    rewriter.create<dmaphop::sync>(loc, path);

    // --- 5. Deallocate buffers and erase original op ---
    for (auto buffer : coreBuffers) {
        rewriter.create<dmaphop::dealloc_buffer>(loc, buffer);
    }
    rewriter.create<memref::DeallocOp>(loc, ddrBuffer);
    rewriter.create<memref::DeallocOp>(loc, coreBufferTemplate);
    rewriter.eraseOp(op);
    return success();
}

// Lowering for dmap::push. This is now a thin wrapper.
struct PushOpLowering : public OpConversionPattern<dmap::push> {
    explicit PushOpLowering(MLIRContext *context, RoutingTopology &router)
        : OpConversionPattern<dmap::push>(context), router_(router) {}

    LogicalResult matchAndRewrite(dmap::push op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        return lowerDataMovementOp(op, rewriter, router_, DataflowDirection::Push);
    }
private:
    RoutingTopology &router_;
};

// Lowering for dmap::pull. This is now a thin wrapper.
struct PullOpLowering : public OpConversionPattern<dmap::pull> {
    explicit PullOpLowering(MLIRContext *context, RoutingTopology &router)
        : OpConversionPattern<dmap::pull>(context), router_(router) {}

    LogicalResult matchAndRewrite(dmap::pull op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        return lowerDataMovementOp(op, rewriter, router_, DataflowDirection::Pull);
    }
private:
    RoutingTopology &router_;
};

// Generic lowering pattern to erase an op that is no longer needed.
template <typename Op_T>
struct EraseOpLowering : public OpConversionPattern<Op_T> {
    using OpConversionPattern<Op_T>::OpConversionPattern;
    LogicalResult matchAndRewrite(Op_T op, typename Op_T::Adaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

} // namespace

void DmapToDmaphopPass::runOnOperation() {
    auto& ctx = getContext();
    ConversionTarget target(ctx);
    RewritePatternSet patterns(&ctx);

    // The conversion is successful when the dmap dialect is gone.
    target.addIllegalDialect<dmap::dmapdialect>();
    // These dialects are legal to have in the output.
    target.addLegalDialect<dmaphop::dmaphopdialect, func::FuncDialect, memref::MemRefDialect>();

    // Add the primary lowering patterns.
    //patterns.add<DmapFuncOpLowering, PushOpLowering>(&ctx);
    patterns.add<PushOpLowering>(&ctx, rtopology_);
    patterns.add<PullOpLowering>(&ctx, rtopology_);
    
    // Add patterns to erase the old dmap ops that are now handled by the main patterns.
    patterns.add<
        EraseOpLowering<dmap::create_data>,
        EraseOpLowering<dmap::define_io_engine>,
        EraseOpLowering<dmap::define_core_group>,
        EraseOpLowering<dmap::define_port_configure>,
        EraseOpLowering<dmap::create_io_engin_with_config>,
        EraseOpLowering<dmap::create_core_group_with_config>,
        EraseOpLowering<dmap::createstream>,
        EraseOpLowering<dmap::createchainstream>//,
        //EraseOpLowering<dmap::push>
    >(&ctx);

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
    }
}

DmapToDmaphopPass::DmapToDmaphopPass(RoutingTopology& rtopology):rtopology_(rtopology) {
}