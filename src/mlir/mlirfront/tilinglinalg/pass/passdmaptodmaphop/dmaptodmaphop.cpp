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
    explicit PushOpLowering(MLIRContext *context, RoutingTopology &router)
        : OpConversionPattern<dmap::push>(context), router_(router) {}

    LogicalResult matchAndRewrite(dmap::push op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        //toplogy info
        int core_start_row = (int) router_.getRM()->getrsc()->absTileRow(TileType::Core, 0);
        //lowing dmap::push to dmaphop::create_hop chain
        auto loc = op.getLoc();
        auto streamValue = op.getStream();
        Operation *streamOp = streamValue.getDefiningOp();

        if (auto chainStreamOp = dyn_cast<dmap::createchainstream>(streamOp)) {
            // Handle a chained stream (e.g., SHIM -> MEM -> CORES)
            if (chainStreamOp.getStreams().size() != 2) {
                return op.emitError("lowering only supports a 2-hop chained stream (SHIM->MEM->CORES)");
            }

            auto stream1 = chainStreamOp.getStreams()[0].getDefiningOp<dmap::createstream>();
            auto stream2 = chainStreamOp.getStreams()[1].getDefiningOp<dmap::createstream>();
            if (!stream1 || !stream2) return failure();

            // Extract Ops from the first stream (SHIM -> MEM)
            auto shimConfig = stream1.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
            auto memInConfig = stream1.getDestination().getDefiningOp<dmap::create_io_engin_with_config>();
            auto shimEngine = shimConfig.getIoengine().getDefiningOp<dmap::define_io_engine>();
            auto memEngine = memInConfig.getIoengine().getDefiningOp<dmap::define_io_engine>();

            // Extract Ops from the second stream (MEM -> CORES)
            auto memOutConfig = stream2.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
            auto coreGroupConfig = stream2.getDestination().getDefiningOp<dmap::create_core_group_with_config>();
            auto coreGroup = coreGroupConfig.getCoregroup().getDefiningOp<dmap::define_core_group>();

            // 1. Create dmaphop::tile Ops
            auto shimTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("shim"), rewriter.getI64IntegerAttr(shimEngine.getIoId()), rewriter.getI64IntegerAttr(0));
            auto memTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("mem"), rewriter.getI64IntegerAttr(memEngine.getIoId()), rewriter.getI64IntegerAttr(0));
            
            auto groupIdx = coreGroup.getGroupIdx();
            SmallVector<dmaphop::tile, 4> coreTiles;
            for (int i = 0; i < coreGroup.getCoreCount(); ++i) {
                int row = (coreGroup.getGroupAxis() == "col") ? i + 1 : coreGroup.getGroupIdx() + 1; // Assuming core tiles start at row 1
                int col = (coreGroup.getGroupAxis() == "row") ? i : coreGroup.getGroupIdx();
                coreTiles.push_back(rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("core"), rewriter.getI64IntegerAttr(col), rewriter.getI64IntegerAttr(row)));
            }

            // 2. Create dmaphop::port Ops for the daisy chain
            auto shimPortOut = rewriter.create<dmaphop::port>(loc, shimTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("shimPortOut"), rewriter.getI64IntegerAttr(0));
            auto memPortIn = rewriter.create<dmaphop::port>(loc, memTile, rewriter.getStringAttr("In"), rewriter.getStringAttr("memPortIn"), rewriter.getI64IntegerAttr(0));
            auto memPortOut = rewriter.create<dmaphop::port>(loc, memTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("memPortOut"), rewriter.getI64IntegerAttr(0));

            SmallVector<Value, 4> corePortsInValues;
            SmallVector<Attribute, 4> consumerPortSymbols;
            SmallVector<dmaphop::port, 4> corePortsOutOps;

            for (const auto &it : llvm::enumerate(coreTiles)) {
                std::string inPortName = "corePortIn" + std::to_string(it.index());
                auto portInOp = rewriter.create<dmaphop::port>(loc, it.value(), rewriter.getStringAttr("In"), rewriter.getStringAttr(inPortName), rewriter.getI64IntegerAttr(0));
                corePortsInValues.push_back(portInOp.getResult());
                consumerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), inPortName));

                // Each core except the last one also needs an Out port
                if (it.index() < coreTiles.size() - 1) {
                    std::string outPortName = "corePortOut" + std::to_string(it.index());
                    auto portOutOp = rewriter.create<dmaphop::port>(loc, it.value(), rewriter.getStringAttr("Out"), rewriter.getStringAttr(outPortName), rewriter.getI64IntegerAttr(0));
                    corePortsOutOps.push_back(portOutOp);
                }
            }

            // 3. Create dmaphop::create_hop Ops for the sequential chain
            SmallVector<Value, 4> hops;
            // First hop: SHIM -> MEM
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, shimPortOut, memPortIn).getResult());
            // Second hop: MEM -> Core 0
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, memPortOut, corePortsInValues[0]).getResult());

            // Subsequent hops: Core i -> Core i+1
            for (size_t i = 0; i < corePortsOutOps.size(); ++i) {
                hops.push_back(rewriter.create<dmaphop::create_hop>(loc, corePortsOutOps[i], corePortsInValues[i+1]).getResult());
            }

            // 4. Create dmaphop::create_path Op
            auto path = rewriter.create<dmaphop::create_path>(loc, hops, rewriter.getArrayAttr(consumerPortSymbols), rewriter.getArrayAttr({SymbolRefAttr::get(rewriter.getContext(), "memPortIn")}));

            // 5. Allocate buffers
            auto memrefType = MemRefType::get(ArrayRef<int64_t>{1024}, rewriter.getF32Type());
            Value ddrBuffer = rewriter.create<memref::AllocOp>(loc, memrefType);
            Value coreBuffer = rewriter.create<memref::AllocOp>(loc, memrefType);

            SmallVector<Value, 4> coreBuffers;
            for (auto coreTile : coreTiles) {
                coreBuffers.push_back(rewriter.create<dmaphop::alloc_buffer>(loc, memrefType, coreTile.getResult(), coreBuffer).getResult());
            }

            // 6. Create dmaphop::push and sync
            rewriter.create<dmaphop::push>(loc, ddrBuffer, path, coreBuffers, corePortsInValues);
            rewriter.create<dmaphop::sync>(loc, path);

            // 7. Deallocate
            for (auto buffer : coreBuffers) {
                rewriter.create<dmaphop::dealloc_buffer>(loc, buffer);
            }
            rewriter.create<memref::DeallocOp>(loc, ddrBuffer);

        } else if (auto createStreamOp = dyn_cast<dmap::createstream>(streamOp)) {
            // Handle a single stream (e.g., SHIM -> CORES)
            auto shimConfig = createStreamOp.getSource().getDefiningOp<dmap::create_io_engin_with_config>();
            auto coreGroupConfig = createStreamOp.getDestination().getDefiningOp<dmap::create_core_group_with_config>();
            if (!shimConfig || !coreGroupConfig) return failure();

            auto shimEngine = shimConfig.getIoengine().getDefiningOp<dmap::define_io_engine>();
            auto coreGroup = coreGroupConfig.getCoregroup().getDefiningOp<dmap::define_core_group>();

            // 1. Create dmaphop::tile Ops
            auto shimTile = rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("shim"), rewriter.getI64IntegerAttr(shimEngine.getIoId()), rewriter.getI64IntegerAttr(0));
            
            SmallVector<dmaphop::tile, 4> coreTiles;
            for (int i = 0; i < coreGroup.getCoreCount(); ++i) {
                int row = (coreGroup.getGroupAxis() == "col") ? i + 1 : coreGroup.getGroupIdx() + 1;
                int col = (coreGroup.getGroupAxis() == "row") ? i : coreGroup.getGroupIdx();
                coreTiles.push_back(rewriter.create<dmaphop::tile>(loc, rewriter.getStringAttr("core"), rewriter.getI64IntegerAttr(col), rewriter.getI64IntegerAttr(row)));
            }

            // 2. Create dmaphop::port Ops for the daisy chain
            auto shimPortOut = rewriter.create<dmaphop::port>(loc, shimTile, rewriter.getStringAttr("Out"), rewriter.getStringAttr("shimPortOut"), rewriter.getI64IntegerAttr(0));

            SmallVector<Value, 4> corePortsInValues;
            SmallVector<Attribute, 4> consumerPortSymbols;
            SmallVector<dmaphop::port, 4> corePortsOutOps;

            for (const auto &it : llvm::enumerate(coreTiles)) {
                std::string inPortName = "corePortIn" + std::to_string(it.index());
                auto portInOp = rewriter.create<dmaphop::port>(loc, it.value(), rewriter.getStringAttr("In"), rewriter.getStringAttr(inPortName), rewriter.getI64IntegerAttr(0));
                corePortsInValues.push_back(portInOp.getResult());
                consumerPortSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), inPortName));

                // Each core except the last one also needs an Out port
                if (it.index() < coreTiles.size() - 1) {
                    std::string outPortName = "corePortOut" + std::to_string(it.index());
                    auto portOutOp = rewriter.create<dmaphop::port>(loc, it.value(), rewriter.getStringAttr("Out"), rewriter.getStringAttr(outPortName), rewriter.getI64IntegerAttr(0));
                    corePortsOutOps.push_back(portOutOp);
                }
            }

            // 3. Create dmaphop::create_hop Ops for the sequential chain
            SmallVector<Value, 4> hops;
            // First hop: SHIM -> Core 0
            hops.push_back(rewriter.create<dmaphop::create_hop>(loc, shimPortOut, corePortsInValues[0]).getResult());

            // Subsequent hops: Core i -> Core i+1
            for (size_t i = 0; i < corePortsOutOps.size(); ++i) {
                hops.push_back(rewriter.create<dmaphop::create_hop>(loc, corePortsOutOps[i], corePortsInValues[i+1]).getResult());
            }

            // 4. Create dmaphop::create_path Op
            auto path = rewriter.create<dmaphop::create_path>(loc, hops, rewriter.getArrayAttr(consumerPortSymbols), rewriter.getArrayAttr({}));

            // 5. Allocate buffers
            auto memrefType = MemRefType::get(ArrayRef<int64_t>{1024}, rewriter.getF32Type());
            Value ddrBuffer = rewriter.create<memref::AllocOp>(loc, memrefType);
            mlir::Value inputMemRef = rewriter.create<mlir::memref::AllocOp>(loc, memrefType);

            SmallVector<Value, 4> coreBuffers;
            for (auto coreTile : coreTiles) {
                coreBuffers.push_back(rewriter.create<dmaphop::alloc_buffer>(loc, memrefType, coreTile.getResult(),inputMemRef).getResult());
            }

            // 6. Create dmaphop::push and sync
            rewriter.create<dmaphop::push>(loc, ddrBuffer, path, coreBuffers, corePortsInValues);
            rewriter.create<dmaphop::sync>(loc, path);

            // 7. Deallocate
            for (auto buffer : coreBuffers) {
                rewriter.create<dmaphop::dealloc_buffer>(loc, buffer);
            }
            rewriter.create<memref::DeallocOp>(loc, ddrBuffer);

        } else {
            return op.emitError("unsupported stream type for lowering. Expected dmap.createstream or dmap.createchainstream");
        }

        rewriter.eraseOp(op);
        return success();
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