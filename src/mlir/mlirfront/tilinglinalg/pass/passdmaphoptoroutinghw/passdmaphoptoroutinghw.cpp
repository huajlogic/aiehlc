/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "passdmaphoptoroutinghw.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
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
    int channel;
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
        info.channel = 0;
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
        
        // Get producers attribute to determine which tiles should send to DMA (S2MM)
        // Producers are core tiles that send data FROM core TO shim/memory (Pull direction)
        llvm::DenseSet<Value> producerPorts;
        if (auto producersAttr = op->getAttrOfType<ArrayAttr>("producers")) {
            for (auto symRef : producersAttr) {
                if (auto symRefAttr = dyn_cast<FlatSymbolRefAttr>(symRef)) {
                    // Find the port with this symbol name in the parent function
                    auto parentFunc = op->getParentOfType<func::FuncOp>();
                    if (parentFunc) {
                        parentFunc.walk([&](dmaphop::port portOp) {
                            auto symName = portOp.getSymName();
                            if (!symName.empty() && symName == symRefAttr.getValue()) {
                                producerPorts.insert(portOp.getResult());
                            }
                        });
                    }
                }
            }
        }
        
        // Get consumers attribute to determine which tiles should receive from DMA (MM2S)
        // Consumers are core tiles that receive data FROM shim/memory TO core (Push direction)
        llvm::DenseSet<Value> consumerPorts;
        if (auto consumersAttr = op->getAttrOfType<ArrayAttr>("consumers")) {
            for (auto symRef : consumersAttr) {
                if (auto symRefAttr = dyn_cast<FlatSymbolRefAttr>(symRef)) {
                    // Find the port with this symbol name in the parent function
                    auto parentFunc = op->getParentOfType<func::FuncOp>();
                    if (parentFunc) {
                        parentFunc.walk([&](dmaphop::port portOp) {
                            auto symName = portOp.getSymName();
                            if (!symName.empty() && symName == symRefAttr.getValue()) {
                                consumerPorts.insert(portOp.getResult());
                            }
                        });
                    }
                }
            }
        }
        
        // Extract tiles and track which tiles have producer/consumer ports
        std::vector<Value> tilesInPath;
        llvm::DenseSet<Value> seenTiles;
        llvm::DenseMap<Value, bool> tileHasProducer;  // Map tile -> has producer port (sends to DMA)
        llvm::DenseMap<Value, bool> tileHasConsumer;  // Map tile -> has consumer port (receives from DMA)
        
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
                    // Mark this tile as having a producer if source port is a producer
                    if (producerPorts.contains(srcPort)) {
                        tileHasProducer[srcTile] = true;
                    }
                }
                
                if (dstPortOp) {
                    Value dstTile = dstPortOp.getTile();
                    if (!seenTiles.contains(dstTile)) {
                        tilesInPath.push_back(dstTile);
                        seenTiles.insert(dstTile);
                    }
                    // Mark this tile as having a consumer if destination port is a consumer
                    if (consumerPorts.contains(dstPort)) {
                        tileHasConsumer[dstTile] = true;
                    }
                }
            }
        }
        
        if (tilesInPath.empty()) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Create routinghw tile operations for tiles in this path
        std::vector<Operation*> hwTileOps;
        
        for (auto tileValue : tilesInPath) {
            auto tileInfoIt = routingCtx.tileMap.find(tileValue);
            if (tileInfoIt == routingCtx.tileMap.end()) continue;
            
            const TileInfo& info = tileInfoIt->second;
            if (info.tileOp) {
                hwTileOps.push_back(info.tileOp);
            }
        }
        
        // Create stream switch connections for tiles in this path
        for (size_t i = 0; i < hwTileOps.size(); ++i) {
            auto tileOp = hwTileOps[i];
            Value tileValue = tilesInPath[i];
            
            auto tileInfoIt = routingCtx.tileMap.find(tileValue);
            if (tileInfoIt == routingCtx.tileMap.end()) continue;
            
            // Skip shim tiles for stream switch connections
            if (tileInfoIt->second.tileType != "core") continue;
            
            // Determine if this tile is a producer (sends to DMA) or consumer (receives from DMA)
            bool isProducer = tileHasProducer.count(tileValue) && tileHasProducer[tileValue];
            bool isConsumer = tileHasConsumer.count(tileValue) && tileHasConsumer[tileValue];
            
            // Determine port directions for routing (always create routing connection)
            std::string slaveDirection;
            std::string masterDirection;
            
            if (i == 0) {
                // First tile: no slave input, forward to next tile
                slaveDirection = "NONE";
                masterDirection = (i < hwTileOps.size() - 1) ? "EAST" : "NONE";
            } else if (i == hwTileOps.size() - 1) {
                // Last tile: receive from previous, no forward
                slaveDirection = "WEST";
                masterDirection = "NONE";
            } else {
                // Middle tiles: receive from WEST, forward to EAST
                slaveDirection = "WEST";
                masterDirection = "EAST";
            }
            
            // Create routing stream switch connection
            if (masterDirection != "NONE" || slaveDirection != "NONE") {
                rewriter.create<routinghw::ConnectStreamSingleSwitchPort>(
                    loc, output,
                    tileOp->getResult(0),
                    rewriter.getStringAttr(slaveDirection),
                    rewriter.getI32IntegerAttr(0),  // slaveportidx
                    rewriter.getStringAttr(masterDirection),
                    rewriter.getI32IntegerAttr(0)   // masterportidx
                );
            }
            
            // If this tile is a consumer, create DMA receive connection (MM2S: DMA -> core)
            if (isConsumer) {
                // Determine the slave direction for DMA connection (where data comes from)
                std::string dmaSlaveDirection;
                if (i == 0) {
                    dmaSlaveDirection = "SOUTH";  // First tile gets from shim
                } else {
                    dmaSlaveDirection = "WEST";  // Others get from previous tile
                }
                
                rewriter.create<routinghw::ConnectStreamSingleSwitchPort>(
                    loc, output,
                    tileOp->getResult(0),
                    rewriter.getStringAttr(dmaSlaveDirection),
                    rewriter.getI32IntegerAttr(0),  // slaveportidx
                    rewriter.getStringAttr("DMA"),
                    rewriter.getI32IntegerAttr(2)   // masterportidx (DMA channel 2)
                );
            }
            
            // If this tile is a producer, create DMA send connection (S2MM: core -> DMA)
            if (isProducer) {
                // Determine the master direction for DMA send (where data goes to)
                std::string dmaMasterDirection;
                if (i == hwTileOps.size() - 1) {
                    dmaMasterDirection = "SOUTH";  // Last tile sends to shim
                } else {
                    dmaMasterDirection = "EAST";  // Others send to next tile
                }
                
                rewriter.create<routinghw::ConnectStreamSingleSwitchPort>(
                    loc, output,
                    tileOp->getResult(0),
                    rewriter.getStringAttr("DMA"),
                    rewriter.getI32IntegerAttr(2),  // slaveportidx (DMA channel 2)
                    rewriter.getStringAttr(dmaMasterDirection),
                    rewriter.getI32IntegerAttr(0)   // masterportidx
                );
            }
        }
        
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
    target.addLegalDialect<routinghw::RoutingHWDialect, func::FuncDialect, memref::MemRefDialect, 
                           routing::routingdialect, scf::SCFDialect, arith::ArithDialect>();
    
    // Mark routing::extract_data as illegal so it gets erased
    target.addIllegalOp<routing::extract_data>();
    target.addIllegalOp<routing::createdummytensor>();
    target.addIllegalOp<routing::partitiontensor>();
    
    // Explicitly mark all other routing and SCF operations as legal to preserve them
    target.addDynamicallyLegalDialect<routing::routingdialect>(
        [](Operation *op) { return !isa<routing::extract_data>(op); }
    );
    
    // Explicitly preserve scf.execute_region and other SCF operations
    target.addLegalOp<scf::ExecuteRegionOp>();
    target.addLegalOp<scf::YieldOp>();
    
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
    patterns.add<EraseOpPattern<routing::extract_data>>(&ctx);  // Erase routing::extract_data
    patterns.add<EraseOpPattern<routing::createdummytensor>>(&ctx);
    patterns.add<EraseOpPattern<routing::partitiontensor>>(&ctx);  // Erase routing::partitiontensor
    
    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
    }
}

DmaphopToRoutinghwPass::DmaphopToRoutinghwPass(RoutingTopology& rtopology):rtopology_(rtopology) {
}

