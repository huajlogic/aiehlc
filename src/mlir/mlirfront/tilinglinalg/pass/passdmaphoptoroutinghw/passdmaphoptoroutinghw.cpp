/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "passdmaphoptoroutinghw.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/IR/Builders.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "routinghwmanager.h"
#include "routingmanager.h"
#include "routing/routingpath.h"
#include <sstream>
#include <vector>

using namespace mlir;
using namespace dmaphop;
using namespace routinghw;

namespace {

// Helper structure to store tile information
struct TileInfo {
    Operation* tileOp;
    int col;
    int row;
    std::string tileType; // "shim" or "core"
};

// Helper structure to store the routing context
struct RoutingContext {
    //Operation* tileArrayHandle = nullptr;
    DenseMap<Value, TileInfo> tileMap;
    DenseMap<Value, Operation*> portToTileOpMap;
    std::vector<Operation*> orderedTileOps;
    bool isFirstTile = true;
    int pktId = 1;
};

// Pattern to convert dmaphop.tile and dmaphop.port to routinghw operations
struct DmaphopTileConversionPattern : public OpConversionPattern<dmaphop::tile> {
    explicit DmaphopTileConversionPattern(MLIRContext *context, RoutingTopology &router, RoutingContext &ctx)
        : OpConversionPattern<dmaphop::tile>(context), router_(router), routingCtx(ctx) {}

    LogicalResult matchAndRewrite(dmaphop::tile op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        auto output = rewriter.getI32Type();
        
        // Create tile array handle once
        //if (!routingCtx.tileArrayHandle) {
        //    routingCtx.tileArrayHandle = rewriter.create<routinghw::TileArrayHandleCreate>(
        //        loc, output, rewriter.getStringAttr("array handle")
        //    );
        //};

        // Extract tile attributes
        std::string tileType = op.getTiletype().str();
        int64_t col = op.getCol();
        int64_t row = op.getRow();

        Operation* hwTileOp = nullptr;
        
        if (tileType == "shim") {
            // Create IO Shim tile
            hwTileOp = rewriter.create<routinghw::IOShimTileCreate>(
                loc,
                output,
                rewriter.getI32IntegerAttr(row),
                rewriter.getI32IntegerAttr(col),
                rewriter.getI32IntegerAttr(col),  // IOID = col
                rewriter.getStringAttr("shim_dma"),
                rewriter.getI32IntegerAttr(0),  // dmadirection MM2S
                rewriter.getI32IntegerAttr(0)   // channelused
            );
        } else if (tileType == "core") {
            // Create Core tile
            hwTileOp = rewriter.create<routinghw::TileCreate>(
                loc,
                output,
                rewriter.getI32IntegerAttr(row),
                rewriter.getI32IntegerAttr(col),
                rewriter.getStringAttr("core_tile")
            );
        }

        // Store tile info
        TileInfo info;
        info.tileOp = hwTileOp;
        info.col = col;
        info.row = row;
        info.tileType = tileType;
        routingCtx.tileMap[op.getResult()] = info;
        routingCtx.orderedTileOps.push_back(hwTileOp);
        
        // Replace the original tile operation with the hardware tile
        rewriter.replaceOp(op, hwTileOp->getResult(0));
        
        return success();
    }

private:
    RoutingTopology &router_;
    RoutingContext &routingCtx;
};

// Pattern to handle dmaphop.port operations (just track them)
struct DmaphopPortConversionPattern : public OpConversionPattern<dmaphop::port> {
    explicit DmaphopPortConversionPattern(MLIRContext *context, RoutingContext &ctx)
        : OpConversionPattern<dmaphop::port>(context), routingCtx(ctx) {}

    LogicalResult matchAndRewrite(dmaphop::port op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // Store port to tile mapping for later use
        Value tileValue = adaptor.getTile();
        auto it = routingCtx.tileMap.find(tileValue);
        if (it != routingCtx.tileMap.end()) {
            routingCtx.portToTileOpMap[op.getResult()] = it->second.tileOp;
        }
        
        // Ports are implicit in routinghw, so we just erase them
        rewriter.eraseOp(op);
        return success();
    }

private:
    RoutingContext &routingCtx;
};

// Pattern to handle dmaphop.create_path - this is where we create stream switch connections
struct DmaphopPathConversionPattern : public OpConversionPattern<dmaphop::create_path> {
    explicit DmaphopPathConversionPattern(MLIRContext *context, RoutingTopology &router, RoutingContext &ctx)
        : OpConversionPattern<dmaphop::create_path>(context), router_(router), routingCtx(ctx) {}

    LogicalResult matchAndRewrite(dmaphop::create_path op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        auto output = rewriter.getI32Type();
        
        // Extract tiles from the hops in this specific path
        std::vector<Value> tilesInPath;
        llvm::DenseSet<Value> seenTiles;
        
        for (auto hopValue : adaptor.getHops()) {
            if (auto hopOp = hopValue.getDefiningOp<dmaphop::create_hop>()) {
                // Get source and destination ports
                Value srcPort = hopOp.getSource();
                Value dstPort = hopOp.getDestination();
                
                // Get the tiles for these ports
                auto srcPortOp = srcPort.getDefiningOp<dmaphop::port>();
                auto dstPortOp = dstPort.getDefiningOp<dmaphop::port>();
                
                if (srcPortOp) {
                    Value srcTile = srcPortOp.getTile();
                    if (!seenTiles.contains(srcTile)) {
                        tilesInPath.push_back(srcTile);
                        seenTiles.insert(srcTile);
                    }
                }
                
                if (dstPortOp) {
                    Value dstTile = dstPortOp.getTile();
                    if (!seenTiles.contains(dstTile)) {
                        tilesInPath.push_back(dstTile);
                        seenTiles.insert(dstTile);
                    }
                }
            }
        }
        
        if (tilesInPath.empty()) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Create tile array handle for this specific path
        //auto tileArrayHandle = rewriter.create<routinghw::TileArrayHandleCreate>(
        //    loc, output, rewriter.getStringAttr("array handle")
        //);
        
        // Create routinghw tile operations for tiles in this path
        std::vector<Operation*> hwTileOps;
        
        for (auto tileValue : tilesInPath) {
            auto tileInfoIt = routingCtx.tileMap.find(tileValue);
            if (tileInfoIt == routingCtx.tileMap.end()) continue;
            
            const TileInfo& info = tileInfoIt->second;
            Operation* hwTileOp = nullptr;
            
            if (info.tileType == "shim") {
                hwTileOp = rewriter.create<routinghw::IOShimTileCreate>(
                    loc, output,
                    rewriter.getI32IntegerAttr(info.row),
                    rewriter.getI32IntegerAttr(info.col),
                    rewriter.getI32IntegerAttr(info.col),
                    rewriter.getStringAttr("shim_dma"),
                    rewriter.getI32IntegerAttr(0),
                    rewriter.getI32IntegerAttr(0)
                );
            } else if (info.tileType == "core") {
                hwTileOp = rewriter.create<routinghw::TileCreate>(
                    loc, output,
                    rewriter.getI32IntegerAttr(info.row),
                    rewriter.getI32IntegerAttr(info.col),
                    rewriter.getStringAttr("core_tile")
                );
            }
            
            if (hwTileOp) {
                hwTileOps.push_back(hwTileOp);
            }
        }
        
        // Create packet stream switch connections for core tiles in this path
        for (size_t i = 0; i < hwTileOps.size(); ++i) {
            auto tileOp = hwTileOps[i];
            Value tileValue = tilesInPath[i];
            
            auto tileInfoIt = routingCtx.tileMap.find(tileValue);
            if (tileInfoIt == routingCtx.tileMap.end()) continue;
            
            // Skip shim tiles for packet routing
            if (tileInfoIt->second.tileType != "core") continue;
            
            // Determine port directions based on position in chain
            std::string slaveDirection = (i == 0) ? "NONE" : "WEST";
            std::string masterDirection = (i == hwTileOps.size() - 1) ? "NONE" : "EAST";
            
            rewriter.create<routinghw::ConnectStreamPktSwitchPort>(
                loc, output,
                tileOp->getResult(0),
                rewriter.getStringAttr(slaveDirection),
                rewriter.getI32IntegerAttr(0),  // receiveslaveportidx
                rewriter.getI32IntegerAttr(0),  // receiveslavepktid (0 = forward all)
                rewriter.getI32IntegerAttr(0),  // receiveslavepkttype
                rewriter.getStringAttr("DMA"),  // localdmadirection
                rewriter.getI32IntegerAttr(0),  // localdmaportidx
                rewriter.getI32IntegerAttr(routingCtx.pktId++),  // localdmapktid
                rewriter.getI32IntegerAttr(0),  // localdmapkttype
                rewriter.getStringAttr(masterDirection),  // forwardmasterdirection
                rewriter.getI32IntegerAttr(0)   // forwardmasterportidx
            );
        }
        //routingCtx.tileArrayHandle = nullptr;
        // Erase the path operation
        rewriter.eraseOp(op);
        return success();
    }

private:
    RoutingTopology &router_;
    RoutingContext &routingCtx;
};

// Pattern to erase dmaphop operations that don't need conversion
template <typename OpType>
struct EraseOpPattern : public OpConversionPattern<OpType> {
    using OpConversionPattern<OpType>::OpConversionPattern;
    
    LogicalResult matchAndRewrite(OpType op, typename OpType::Adaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

} // namespace

void DmaphopToRoutinghwPass::runOnOperation() {
    auto& ctx = getContext();
    ConversionTarget target(ctx);
    RewritePatternSet patterns(&ctx);
    
    // Create routing context
    RoutingContext routingCtx;

    // Define conversion target
    //target.addIllegalDialect<dmaphop::dmaphopdialect>();
    target.addLegalDialect<routinghw::RoutingHWDialect, func::FuncDialect, memref::MemRefDialect>();
    
    // Add conversion patterns
    patterns.add<DmaphopTileConversionPattern>(&ctx, rtopology_, routingCtx);
    patterns.add<DmaphopPortConversionPattern>(&ctx, routingCtx);
    patterns.add<DmaphopPathConversionPattern>(&ctx, rtopology_, routingCtx);
    
    // Add patterns to erase operations that don't need direct conversion
    patterns.add<EraseOpPattern<dmaphop::create_hop>>(&ctx);
    patterns.add<EraseOpPattern<dmaphop::alloc_buffer>>(&ctx);
    patterns.add<EraseOpPattern<dmaphop::dealloc_buffer>>(&ctx);
    patterns.add<EraseOpPattern<dmaphop::push>>(&ctx);
    patterns.add<EraseOpPattern<dmaphop::pull>>(&ctx);
    patterns.add<EraseOpPattern<dmaphop::sync>>(&ctx);
    
    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
    }
}

DmaphopToRoutinghwPass::DmaphopToRoutinghwPass(RoutingTopology& rtopology):rtopology_(rtopology) {
}

