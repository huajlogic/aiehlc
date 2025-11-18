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


// Lowering for dmap::push. This is the main conversion driver.
struct PushOpLowering : public OpConversionPattern<dmap::push> {
    using OpConversionPattern<dmap::push>::OpConversionPattern;

    LogicalResult matchAndRewrite(dmap::push op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        auto streamValue = op.getStream();

        // Handle a chained stream
        auto chainStreamOp = streamValue.getDefiningOp<dmap::createchainstream>();
        if (!chainStreamOp) {
            return op.emitError("lowering only supports dmap.create_chain_stream");
        }

        // We expect a SHIM -> MEM -> CORES chain
        if (chainStreamOp.getStreams().size() != 2) return failure();

        auto stream1 = chainStreamOp.getStreams()[0].getDefiningOp<dmap::createstream>();
        auto stream2 = chainStreamOp.getStreams()[1].getDefiningOp<dmap::createstream>();

        // Extract Ops from the first stream (SHIM -> MEM)
        auto shimConfig = stream1.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
        auto memInConfig = stream1.getDestination().getDefiningOp<dmap::create_io_engin_with_config>();
        auto shimEngine = shimConfig.getPeioengine().getDefiningOp<dmap::define_io_engine>();
        auto memEngine = memInConfig.getPeioengine().getDefiningOp<dmap::define_io_engine>();

        // Extract Ops from the second stream (MEM -> CORES)
        auto memOutConfig = stream2.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
        auto coreGroupConfig = stream2.getDestination().getDefiningOp<dmap::create_core_group_with_config>();
        auto coreGroup = coreGroupConfig.getCoregroup().getDefiningOp<dmap::define_core_group>();

        // 1. Create dmaphop::tile Ops
        auto shimTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("shim"), rewriter.getI64IntegerAttr(shimEngine.getIoId()), rewriter.getI64IntegerAttr(0));
        auto memTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("mem"), rewriter.getI64IntegerAttr(memEngine.getIoId()), rewriter.getI64IntegerAttr(0));
        
        SmallVector<dmaphop::tile, 4> coreTiles;
        for (int i = 0; i < coreGroup.getCoreCount(); ++i) {
            int row = (coreGroup.getGroupAxis() == "col") ? i + 1 : coreGroup.getGroupIdx() + 1; // Assuming core tiles start at row 1
            int col = (coreGroup.getGroupAxis() == "row") ? i : coreGroup.getGroupIdx();
            coreTiles.push_back(rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("core"), rewriter.getI64IntegerAttr(col), rewriter.getI64IntegerAttr(row)));
        }

        // 2. Create dmaphop::port Ops
        auto shimPortOut = rewriter.create<dmaphop::port>(loc, shimTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("shimPortOut"), rewriter.getI64IntegerAttr(0));
        auto memPortIn = rewriter.create<dmaphop::port>(loc, memTile, rewriter.getStringAttr("In"), rewriter.getStringAttr("memPortIn"), rewriter.getI64IntegerAttr(0));
        auto memPortOut = rewriter.create<dmaphop::port>(loc, memTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("memPortOut"), rewriter.getI64IntegerAttr(0));

        SmallVector<dmaphop::port, 4> corePortsInOps;
        SmallVector<Value, 4> corePortsInValues;
        SmallVector<Attribute, 4> consumerPortSymbols;
        for (const auto &it : llvm::enumerate(coreTiles)) {
            std::string portName = "corePortIn" + std::to_string(it.index());
            auto portOp = rewriter.create<dmaphop::port>(loc, it.value(), rewriter.getStringAttr("In"), rewriter.getStringAttr(portName), rewriter.getI64IntegerAttr(0));
            corePortsInOps.push_back(portOp);
            corePortsInValues.push_back(portOp.getResult());
            consumerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), portName));
        }

        // 3. Create dmaphop::create_hop Ops
        auto hop1 = rewriter.create<dmaphop::create_hop>(loc, shimPortOut, memPortIn);
        
        SmallVector<Value, 4> hops;
        hops.push_back(hop1);
        for(auto corePort : corePortsInOps) {
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, memPortOut, corePort).getResult());
        }

        // 4. Create dmaphop::create_path Op
        auto path = rewriter.create<dmaphop::create_path>(loc, hops, rewriter.getArrayAttr(consumerPortSymbols), rewriter.getArrayAttr({SymbolRefAttr::get(rewriter.getContext(), "memPortIn")}));

        // 5. Allocate buffers
        auto dataOp = op.getData().getDefiningOp<dmap::create_data>();
        auto memrefType = MemRefType::get(ArrayRef<int64_t>{1024}, rewriter.getF32Type());
        Value ddrBuffer = rewriter.create<memref::AllocOp>(loc, memrefType);

        SmallVector<Value, 4> coreBuffers;
        for (auto coreTile : coreTiles) {
            coreBuffers.push_back(rewriter.create<dmaphop::alloc_buffer>(loc, memrefType, coreTile.getResult()).getResult());
        }

        // 6. Create dmaphop::push and sync
        rewriter.create<dmaphop::push>(loc, ddrBuffer, path, coreBuffers, corePortsInValues);
        rewriter.create<dmaphop::sync>(loc, path);

        // 7. Deallocate
        for (auto buffer : coreBuffers) {
            rewriter.create<dmaphop::dealloc_buffer>(loc, buffer);
        }
        rewriter.create<memref::DeallocOp>(loc, ddrBuffer);

        rewriter.eraseOp(op);
        return success();
    }
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
    patterns.add<PushOpLowering>(&ctx);
    
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