/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "passblueprinttoschedule.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinDialect.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include <sstream>
#include <vector>
#include <unordered_map>
#include <iostream>

using namespace mlir;
using namespace dfscheblueprint;
using namespace dfschedule;

namespace {

// ============================================================================
// Fake Resource Manager for Lock and BD ID allocation
// ============================================================================
class KernelResourceManager {
public:
    KernelResourceManager() : nextBdId(0), nextLockId(0) {}
    
    // Allocate next BD ID (0, 1 for ping-pong)
    int32_t allocateBdId() { return nextBdId++; }
    
    // Allocate next Lock ID
    int64_t allocateLockId() { return nextLockId++; }
    
    // Reset for new kernel
    void reset() {
        nextBdId = 0;
        nextLockId = 0;
    }
    
private:
    int32_t nextBdId;
    int64_t nextLockId;
};

// Generic template function to look up any operation by symbol reference
// This function searches for an operation of type OpTy with a matching symbol name
// The search starts in the same block as rootOp and then searches parent regions
template <typename OpTy>
static OpTy lookupSymbolOp(Operation *rootOp, SymbolRefAttr target) {
    StringRef targetName = target.getRootReference().getValue();
    
    // First, search in the same block as the rootOp
    Block *parentBlock = rootOp->getBlock();
    if (parentBlock) {
        for (Operation &op : *parentBlock) {
            if (auto targetOp = dyn_cast<OpTy>(&op)) {
                if (targetOp.getSymName() == targetName) {
                    return targetOp;
                }
            }
        }
    }
    
    // If not found, try searching in parent regions (for nested structures)
    Operation *parentOp = rootOp->getParentOp();
    while (parentOp) {
        for (Region &region : parentOp->getRegions()) {
            for (Block &block : region) {
                for (Operation &op : block) {
                    if (auto targetOp = dyn_cast<OpTy>(&op)) {
                        if (targetOp.getSymName() == targetName) {
                            return targetOp;
                        }
                    }
                }
            }
        }
        parentOp = parentOp->getParentOp();
    }
    
    return nullptr;
}

// Helper function to look up TileGroupOp by symbol reference (wrapper for backward compatibility)
static dfscheblueprint::TileGroupOp lookupTileGroup(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::TileGroupOp>(rootOp, target);
}

// Unified template pattern to erase dfscheblueprint operations
// FlowConfigOp is just erased since FlowTransferConversion reads its attributes
// and generates all the DMA BD configuration logic
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

// Helper function to check if dskernel_receiver already exists in the module
static bool hasDSKernelReceiver(Operation *rootOp, StringRef kernelName) {
    // Find the module-level operation
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }
    
    // Search for existing dskernel_receiver with the given name
    for (Region &region : moduleOp->getRegions()) {
        for (Block &block : region) {
            for (Operation &op : block) {
                if (auto receiver = dyn_cast<dfschedule::DSKernelReceiverOp>(&op)) {
                    if (receiver.getSymName() == kernelName) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

// Helper function to get the module-level insertion point
static Operation* getModuleOp(Operation *rootOp) {
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }
    return moduleOp;
}

// Generate dfschedule.dskernel_receiver function
// Parameters:
//   - kernelName: symbol name for the kernel (same as load_kernel_group callee)
//   - tensorType: the tensor type for data
//   - bufferLen: buffer length for DMA BD
//   - basePacketId: base packet ID from FlowTransferOp
//   - coreChannel: DMA channel from core FlowConfig
//   - flowIndex: unique index for this flow, used to access per-flow DMA configs
static void generateDSKernelReceiver(
    ConversionPatternRewriter &rewriter,
    Location loc,
    Operation *insertBeforeOp,
    StringRef kernelName,
    RankedTensorType tensorType,
    int64_t bufferLen,
    uint32_t basePacketId,
    int64_t coreChannel,
    uint32_t flowIndex,
    KernelResourceManager &resourceMgr) {
    
    // Save current insertion point
    OpBuilder::InsertionGuard guard(rewriter);
    
    // Find module and insert at module level (at the end of the first block)
    Operation *moduleOp = getModuleOp(insertBeforeOp);
    Block &moduleBlock = moduleOp->getRegions().front().front();
    
    // Check if block has a terminator, insert before it; otherwise insert at end
    if (!moduleBlock.empty() && moduleBlock.back().hasTrait<OpTrait::IsTerminator>()) {
        rewriter.setInsertionPoint(&moduleBlock.back());
    } else {
        rewriter.setInsertionPointToEnd(&moduleBlock);
    }
    
    // Create the dskernel_receiver operation with new signature
    auto receiverOp = rewriter.create<dfschedule::DSKernelReceiverOp>(
        loc,
        rewriter.getStringAttr(kernelName));
    
    // Create the body block with only ONE argument:
    // %arg0: index (iteration count only)
    Block *body = &receiverOp.getBody().emplaceBlock();
    
    auto indexType = rewriter.getIndexType();
    auto arg0 = body->addArgument(indexType, loc);    // iteration count
    
    // Set insertion point to the body
    rewriter.setInsertionPointToStart(body);
    
    // Reset resource manager for this kernel
    resourceMgr.reset();
    
    // First operation: read config from tile local memory
    // %config = dfschedule.kernel.read_kernelconfig : !dfschedule.tile_config
    auto tileConfigType = dfschedule::TileConfigType::get(rewriter.getContext());
    auto readConfigOp = rewriter.create<dfschedule::KernelReadConfigOp>(
        loc, tileConfigType);
    
    // Extract configuration values for this flow (indexed by flow_index)
    // %packet_id = dfschedule.config.get_packet_id(%config) {flow_index = N} : (!dfschedule.tile_config) -> i32
    auto getPacketIdOp = rewriter.create<dfschedule::ConfigGetPacketIdOp>(
        loc, rewriter.getI32Type(), readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex));
    
    // %dma_channel = dfschedule.config.get_dma_channel(%config) {flow_index = N} : (!dfschedule.tile_config) -> !dfschedule.dma_channel
    auto getDmaChannelOp = rewriter.create<dfschedule::ConfigGetDmaChannelOp>(
        loc, dfschedule::DmaChannelType::get(rewriter.getContext()), readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex));
    
    // Create LOCAL memref type for ping-pong buffers
    auto localMemRefType = MemRefType::get(
        tensorType.getShape(),
        tensorType.getElementType(),
        AffineMap(),
        rewriter.getStringAttr("LOCAL"));
    
    // %ping_buffer = dfschedule.config.get_buffer_addr(%config) {flow_index = N, buffer_index = 0} : (!dfschedule.tile_config) -> memref<...>
    auto getPingBufferOp = rewriter.create<dfschedule::ConfigGetBufferAddrOp>(
        loc, localMemRefType, readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex), rewriter.getI32IntegerAttr(0));
    
    // %pong_buffer = dfschedule.config.get_buffer_addr(%config) {flow_index = N, buffer_index = 1} : (!dfschedule.tile_config) -> memref<...>
    auto getPongBufferOp = rewriter.create<dfschedule::ConfigGetBufferAddrOp>(
        loc, localMemRefType, readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex), rewriter.getI32IntegerAttr(1));
    
    // Read lock IDs from config for this flow (indexed by flow_index)
    // %ping_acquire_lock_id = dfschedule.config.get_ping_acquire_lock_id(%config) {flow_index = N} : (!dfschedule.tile_config) -> i32
    auto getPingAcquireLockIdOp = rewriter.create<dfschedule::ConfigGetPingAcquireLockIdOp>(
        loc, rewriter.getI32Type(), readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex));
    
    // %pong_acquire_lock_id = dfschedule.config.get_pong_acquire_lock_id(%config) {flow_index = N} : (!dfschedule.tile_config) -> i32
    auto getPongAcquireLockIdOp = rewriter.create<dfschedule::ConfigGetPongAcquireLockIdOp>(
        loc, rewriter.getI32Type(), readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex));
    
    // %ping_release_lock_id = dfschedule.config.get_ping_release_lock_id(%config) {flow_index = N} : (!dfschedule.tile_config) -> i32
    auto getPingReleaseLockIdOp = rewriter.create<dfschedule::ConfigGetPingReleaseLockIdOp>(
        loc, rewriter.getI32Type(), readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex));
    
    // %pong_release_lock_id = dfschedule.config.get_pong_release_lock_id(%config) {flow_index = N} : (!dfschedule.tile_config) -> i32
    auto getPongReleaseLockIdOp = rewriter.create<dfschedule::ConfigGetPongReleaseLockIdOp>(
        loc, rewriter.getI32Type(), readConfigOp.getConfig(),
        rewriter.getI32IntegerAttr(flowIndex));
    
    // Now use these values in the kernel body...
    // Create bd_id constants for ping (0) and pong (1)
    int32_t pingBdId = resourceMgr.allocateBdId();  // 0
    int32_t pongBdId = resourceMgr.allocateBdId();  // 1
    
    auto pingBdIdConst = rewriter.create<arith::ConstantOp>(
        loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(pingBdId));
    auto pongBdIdConst = rewriter.create<arith::ConstantOp>(
        loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(pongBdId));
    
    // %5 = dfschedule.config.dma_bd for ping buffer
    // bd_id=0, next_bd=1, packet_id will be read from config at runtime
    // Note: We'll need to update ConfigDmaBdOp to work with runtime packet_id
    // For now, we create a placeholder tile value (this needs architectural decision)
    // TODO: Refactor DMA BD config to work with runtime config
    auto dummyTile = rewriter.create<dfschedule::DeclareTileOp>(
        loc, dfschedule::TileType::get(rewriter.getContext()), 
        rewriter.getI32IntegerAttr(0), rewriter.getI32IntegerAttr(0));
    
    auto pingDmaBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
        loc,
        dfschedule::BdHandleType::get(rewriter.getContext()),
        getPingBufferOp.getBuffer(),                  // buffer from config
        dummyTile.getTile(),                          // tile (placeholder)
        pingBdIdConst.getResult(),                    // bd_id
        rewriter.getI32IntegerAttr(0),                // offset
        rewriter.getI32IntegerAttr(bufferLen),        // len
        rewriter.getBoolAttr(true),                   // enable_packet
        rewriter.getI32IntegerAttr(basePacketId),     // packet_id (TODO: should be from config at runtime)
        rewriter.getI32IntegerAttr(pongBdId),         // next_bd -> points to pong
        getPingAcquireLockIdOp.getLockId(),           // acquire_lock_id from config
        getPingReleaseLockIdOp.getLockId());          // release_lock_id from config
    
    // %6 = dfschedule.config.dma_bd for pong buffer
    // bd_id=1, next_bd=0, packet_id from config
    auto pongDmaBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
        loc,
        dfschedule::BdHandleType::get(rewriter.getContext()),
        getPongBufferOp.getBuffer(),                  // buffer from config
        dummyTile.getTile(),                          // tile (placeholder)
        pongBdIdConst.getResult(),                    // bd_id
        rewriter.getI32IntegerAttr(0),                // offset
        rewriter.getI32IntegerAttr(bufferLen),        // len
        rewriter.getBoolAttr(true),                   // enable_packet
        rewriter.getI32IntegerAttr(basePacketId),     // packet_id (TODO: should be from config at runtime)
        rewriter.getI32IntegerAttr(pingBdId),         // next_bd -> points back to ping
        getPongAcquireLockIdOp.getLockId(),           // acquire_lock_id from config
        getPongReleaseLockIdOp.getLockId());          // release_lock_id from config
    
    // Initialize locks for ping-pong synchronization using lock IDs from config
    // Lock values: acquire locks start at 0, release locks: ping=1, pong=0
    
    // %7 = dfschedule.dskernel.lock_init(%ping_acquire_lock_id, 0, "ping_acquire_lock")
    auto pingAcqLock = rewriter.create<dfschedule::DSKernelLockInitOp>(
        loc,
        dfschedule::LockType::get(rewriter.getContext()),
        getPingAcquireLockIdOp.getLockId(),
        rewriter.getI64IntegerAttr(0),
        rewriter.getStringAttr("ping_acquire_lock"));
    
    // %8 = dfschedule.dskernel.lock_init(%pong_acquire_lock_id, 0, "pong_acquire_lock")
    auto pongAcqLock = rewriter.create<dfschedule::DSKernelLockInitOp>(
        loc,
        dfschedule::LockType::get(rewriter.getContext()),
        getPongAcquireLockIdOp.getLockId(),
        rewriter.getI64IntegerAttr(0),
        rewriter.getStringAttr("pong_acquire_lock"));
    
    // %9 = dfschedule.dskernel.lock_init(%ping_release_lock_id, 1, "ping_release_lock")
    auto pingRelLock = rewriter.create<dfschedule::DSKernelLockInitOp>(
        loc,
        dfschedule::LockType::get(rewriter.getContext()),
        getPingReleaseLockIdOp.getLockId(),
        rewriter.getI64IntegerAttr(1),
        rewriter.getStringAttr("ping_release_lock"));
    
    // %10 = dfschedule.dskernel.lock_init(%pong_release_lock_id, 0, "pong_release_lock")
    auto pongRelLock = rewriter.create<dfschedule::DSKernelLockInitOp>(
        loc,
        dfschedule::LockType::get(rewriter.getContext()),
        getPongReleaseLockIdOp.getLockId(),
        rewriter.getI64IntegerAttr(0),
        rewriter.getStringAttr("pong_release_lock"));
    
    // dfschedule.dskernel.launch_dma_s2m_loop
    rewriter.create<dfschedule::DSKernelLaunchDmaLoopOp>(
        loc,
        getPingBufferOp.getBuffer(),
        getPongBufferOp.getBuffer(),
        pingAcqLock.getLock(),
        pingRelLock.getLock(),
        pongAcqLock.getLock(),
        pongRelLock.getLock(),
        getDmaChannelOp.getChannel());
    
    // Create constants for loop
    auto c0 = rewriter.create<arith::ConstantIndexOp>(loc, 0);
    auto c1 = rewriter.create<arith::ConstantIndexOp>(loc, 1);
    auto c2 = rewriter.create<arith::ConstantIndexOp>(loc, 2);
    
    // scf.for %arg1 = %c0 to %arg0 step %c1 (arg0 is the iteration count parameter)
    auto forOp = rewriter.create<scf::ForOp>(
        loc, c0.getResult(), arg0, c1.getResult());
    
    // Build the loop body
    rewriter.setInsertionPointToStart(forOp.getBody());
    Value iv = forOp.getInductionVar();
    
    // %11 = arith.remui %arg1, %c2 : index
    auto remOp = rewriter.create<arith::RemUIOp>(loc, iv, c2.getResult());
    
    // %12 = arith.cmpi eq, %11, %c0 : index
    auto cmpOp = rewriter.create<arith::CmpIOp>(
        loc, arith::CmpIPredicate::eq, remOp.getResult(), c0.getResult());
    
    // %13 = scf.if %12 -> (memref<...>) { yield ping } else { yield pong }
    auto selectBufferOp = rewriter.create<scf::IfOp>(
        loc, TypeRange{localMemRefType}, cmpOp.getResult(), /*withElseRegion=*/true);
    
    // Then block: yield ping
    rewriter.setInsertionPointToStart(&selectBufferOp.getThenRegion().front());
    rewriter.create<scf::YieldOp>(loc, ValueRange{getPingBufferOp.getBuffer()});
    
    // Else block: yield pong
    rewriter.setInsertionPointToStart(&selectBufferOp.getElseRegion().front());
    rewriter.create<scf::YieldOp>(loc, ValueRange{getPongBufferOp.getBuffer()});
    
    // Continue after if
    rewriter.setInsertionPointAfter(selectBufferOp);
    Value selectedBuffer = selectBufferOp.getResult(0);
    
    // %14 = scf.if %12 -> (!dfschedule.lock) { yield ping_acq } else { yield pong_acq }
    auto lockType = dfschedule::LockType::get(rewriter.getContext());
    auto selectAcqLockOp = rewriter.create<scf::IfOp>(
        loc, TypeRange{lockType}, cmpOp.getResult(), /*withElseRegion=*/true);
    
    rewriter.setInsertionPointToStart(&selectAcqLockOp.getThenRegion().front());
    rewriter.create<scf::YieldOp>(loc, ValueRange{pingAcqLock.getLock()});
    
    rewriter.setInsertionPointToStart(&selectAcqLockOp.getElseRegion().front());
    rewriter.create<scf::YieldOp>(loc, ValueRange{pongAcqLock.getLock()});
    
    rewriter.setInsertionPointAfter(selectAcqLockOp);
    Value selectedAcqLock = selectAcqLockOp.getResult(0);
    
    // %15 = scf.if %12 -> (!dfschedule.lock) { yield ping_rel } else { yield pong_rel }
    auto selectRelLockOp = rewriter.create<scf::IfOp>(
        loc, TypeRange{lockType}, cmpOp.getResult(), /*withElseRegion=*/true);
    
    rewriter.setInsertionPointToStart(&selectRelLockOp.getThenRegion().front());
    rewriter.create<scf::YieldOp>(loc, ValueRange{pingRelLock.getLock()});
    
    rewriter.setInsertionPointToStart(&selectRelLockOp.getElseRegion().front());
    rewriter.create<scf::YieldOp>(loc, ValueRange{pongRelLock.getLock()});
    
    rewriter.setInsertionPointAfter(selectRelLockOp);
    Value selectedRelLock = selectRelLockOp.getResult(0);
    
    // dfschedule.dskernel.acquire_lock(%14, 1)
    rewriter.create<dfschedule::DSKernelAcquireLockOp>(
        loc, selectedAcqLock, rewriter.getI32IntegerAttr(1));
    
    // TODO: Insert actual compute logic here
    // The compute logic should be provided through the config or as a separate parameter
    // For now, we just acquire and release locks without actual compute
    
    // dfschedule.dskernel.release_lock(%15, 1)
    rewriter.create<dfschedule::DSKernelReleaseLockOp>(
        loc, selectedRelLock, rewriter.getI32IntegerAttr(1));
}

static dfscheblueprint::DataSliceOp lookupDataSlice(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::DataSliceOp>(rootOp, target);
}

// Helper function to look up FlowConfigOp by symbol reference (wrapper for backward compatibility)
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::FlowConfigOp>(rootOp, target);
}

bool checktheopusedtensor(Operation *flowtransferOp) {
    auto op = dyn_cast<dfscheblueprint::FlowTransferOp>(flowtransferOp);
    if (!op) {
        return false;
    }
    
    SymbolRefAttr fromRef = op.getFrom();
    auto fromFlowConfig = lookupFlowConfig(op.getOperation(), fromRef);
    if (!fromFlowConfig) {
        return false;
    }

    auto toRef = op.getTo();
    auto toFlowConfig = lookupFlowConfig(op.getOperation(), toRef);
    if (!toFlowConfig) {
        return false;
    }
    auto sliceSymbolsOpt = fromFlowConfig.getSliceSymbols();
    if (sliceSymbolsOpt && !sliceSymbolsOpt->empty()) {
        for (auto sliceSymbol : *sliceSymbolsOpt) {
            auto sliceOp = lookupDataSlice(op.getOperation(), cast<SymbolRefAttr>(sliceSymbol));
            // TODO: Add logic to check the slice operation
        }
    }
  
    return true;
}

// Pattern to convert dfscheblueprint::FlowTransferOp to dfschedule operations
// Logic:
// 1. Find shim tile from the "from" and "to" FlowConfigOps by checking type="shim"
// 2. Get DMA configuration from the shim FlowConfig's DMA attribute
// 3. Only do DMA config (declaretensor, declaretile, config.dma_bd, config.create_io) for shim tile
// 4. Create packet ops for core tiles, load_kernel_group, launch, schedule ops
// 5. Generate dskernel_receiver function with kernel DMA BD config
struct FlowTransferConversion : public OpConversionPattern<dfscheblueprint::FlowTransferOp> {
    using OpConversionPattern<dfscheblueprint::FlowTransferOp>::OpConversionPattern;
    
    // Mutable resource manager for kernel resource allocation
    mutable KernelResourceManager resourceMgr;

    LogicalResult
    matchAndRewrite(dfscheblueprint::FlowTransferOp op, OpAdaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        // Look up "from" FlowConfigOp
        SymbolRefAttr fromRef = op.getFrom();
        auto fromFlowConfig = lookupFlowConfig(op.getOperation(), fromRef);
        if (!fromFlowConfig) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Look up "to" FlowConfigOp
        SymbolRefAttr toRef = op.getTo();
        auto toFlowConfig = lookupFlowConfig(op.getOperation(), toRef);
        if (!toFlowConfig) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Step 1: Find the shim tile by checking type field
        // Determine which FlowConfig is shim and which is core
        dfscheblueprint::FlowConfigOp shimFlowConfig = nullptr;
        dfscheblueprint::FlowConfigOp coreFlowConfig = nullptr;
        bool shimIsSender = false;  // true if shim is "from" (MM2S), false if shim is "to" (S2MM)
        
        auto fromType = fromFlowConfig.getType();
        auto toType = toFlowConfig.getType();
        
        if (fromType && *fromType == "shim") {
            shimFlowConfig = fromFlowConfig;
            coreFlowConfig = toFlowConfig;
            shimIsSender = true;
        } else if (toType && *toType == "shim") {
            shimFlowConfig = toFlowConfig;
            coreFlowConfig = fromFlowConfig;
            shimIsSender = false;
        } else {
            // No shim tile found, just erase
            rewriter.eraseOp(op);
            return success();
        }
        
        // Get tile groups
        auto shimTileGroup = lookupTileGroup(shimFlowConfig.getOperation(), shimFlowConfig.getTarget());
        auto coreTileGroup = lookupTileGroup(coreFlowConfig.getOperation(), coreFlowConfig.getTarget());
        if (!shimTileGroup || !coreTileGroup) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Get base packet id for packet operations
        uint32_t basePacketId = op.getBasePacketId();
        
        // Get flow_index for per-flow DMA configurations
        uint32_t flowIndex = op.getFlowIndex();
        
        // Get the view operand from the shim FlowConfig (shim holds the data buffer)
        Value viewValue = shimFlowConfig.getView();
        Type viewType = viewValue.getType();
        
        // Convert tensor type to memref type if needed
        MemRefType memrefType;
        Value memrefValue;
        if (auto tensorType = dyn_cast<RankedTensorType>(viewType)) {
            // Create 1D memref type with total size
            int64_t totalSize = 1;
            for (int64_t dim : tensorType.getShape()) {
                totalSize *= dim;
            }
            memrefType = MemRefType::get({totalSize}, tensorType.getElementType());
            
            // Create dfschedule.declaretensor
            memrefValue = rewriter.create<dfschedule::DeclareTensorOp>(
                loc, memrefType, viewValue);
        } else if (auto mrType = dyn_cast<MemRefType>(viewType)) {
            memrefType = mrType;
            memrefValue = viewValue;
        } else {
            rewriter.eraseOp(op);
            return success();
        }
        
        // --- Step 2 & 3: DMA CONFIG FOR SHIM TILE ONLY ---
        ArrayAttr shimTilesAttr = shimTileGroup.getTiles();
        if (shimTilesAttr.empty()) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Get first shim tile coordinates
        auto firstShimTile = dyn_cast<ArrayAttr>(shimTilesAttr[0]);
        if (!firstShimTile || firstShimTile.size() < 2) {
            rewriter.eraseOp(op);
            return success();
        }
        int64_t shimCol = cast<IntegerAttr>(firstShimTile[0]).getInt();
        int64_t shimRow = cast<IntegerAttr>(firstShimTile[1]).getInt();
        
        // Create dfschedule.declaretile for shim
        auto shimTileOp = rewriter.create<dfschedule::DeclareTileOp>(
            loc,
            dfschedule::TileType::get(rewriter.getContext()),
            rewriter.getI32IntegerAttr(shimCol),
            rewriter.getI32IntegerAttr(shimRow));
        
        // Step 2: Get DMA configuration from shim FlowConfig's DMA attribute
        auto shimDmaAttr = shimFlowConfig.getDma();
        auto shimDmaChannels = shimDmaAttr.getChannels();
        int64_t shimChannel = shimDmaChannels.empty() ? 0 : shimDmaChannels[0];
        
        // Determine DMA direction based on whether shim is sender or receiver
        StringRef dmaDirection = shimIsSender ? "MM2S" : "S2MM";
        StringRef ioOperation = shimIsSender ? "SEND" : "RECV";
        
        // Calculate buffer size
        int64_t bufferLen = 1;
        for (int64_t dim : memrefType.getShape()) {
            bufferLen *= dim;
        }
        
        // Create bd_id constant for config
        auto bdIdConst = rewriter.create<arith::ConstantOp>(
            loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(0));
        
        // Step 3: Create dfschedule.config.dma_bd for shim tile only
        auto minusOne = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(-1));
        auto configDmaBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
            loc,
            dfschedule::BdHandleType::get(rewriter.getContext()),
            memrefValue,                                      // buffer
            shimTileOp.getTile(),                             // tile
            bdIdConst.getResult(),                            // bd_id
            rewriter.getI32IntegerAttr(0),                    // offset
            rewriter.getI32IntegerAttr(bufferLen),            // len
            rewriter.getBoolAttr(true),                       // enable_packet
            rewriter.getI32IntegerAttr(basePacketId),         // packet_id
            rewriter.getI32IntegerAttr(4294967295),           // next_bd (-1 as unsigned)
            minusOne.getResult(),                             // acquire_lock_id = -1 (host-side, no lock)
            minusOne.getResult());                            // release_lock_id = -1 (host-side, no lock)
        
        // Create dfschedule.config.create_io for shim tile
        auto createIoOp = rewriter.create<dfschedule::ConfigCreateIoOp>(
            loc,
            dfschedule::IoHandleType::get(rewriter.getContext()),
            configDmaBdOp.getBdHandle(),                      // bd_config
            shimTileOp.getTile(),                             // tile
            rewriter.getI32IntegerAttr(shimChannel),          // channel
            rewriter.getStringAttr(dmaDirection),             // direction (MM2S or S2MM)
            rewriter.getStringAttr(ioOperation));             // io_operation (SEND or RECV)
        
        // --- CORE TILES (no DMA config, just declaretile and kernel_config) ---
        ArrayAttr coreTilesAttr = coreTileGroup.getTiles();
        SmallVector<Value> coreTiles;
        
        // Get DMA channel from core FlowConfig for packet ops
        auto coreDmaAttr = coreFlowConfig.getDma();
        auto coreDmaChannels = coreDmaAttr.getChannels();
        int64_t coreChannel = coreDmaChannels.empty() ? 0 : coreDmaChannels[0];
        
        // Collect tile config dictionaries for kernel_config
        SmallVector<Attribute> tileConfigDicts;
        int tileIndex = 0;
        
        for (auto tileAttr : coreTilesAttr) {
            auto tileArray = dyn_cast<ArrayAttr>(tileAttr);
            if (!tileArray || tileArray.size() < 2) {
                continue;
            }
            
            int64_t col = cast<IntegerAttr>(tileArray[0]).getInt();
            int64_t row = cast<IntegerAttr>(tileArray[1]).getInt();
            
            // Create dfschedule.declaretile for each core tile
            auto coreTileOp = rewriter.create<dfschedule::DeclareTileOp>(
                loc,
                dfschedule::TileType::get(rewriter.getContext()),
                rewriter.getI32IntegerAttr(col),
                rewriter.getI32IntegerAttr(row));
            coreTiles.push_back(coreTileOp.getTile());
            
            // Calculate buffer size from memrefType
            int64_t bufferSize = 1;
            int64_t elementSizeBytes = 1;
            if (auto memrefType = memrefValue.getType().dyn_cast<MemRefType>()) {
                for (auto dim : memrefType.getShape()) {
                    if (dim > 0) {  // Skip dynamic dimensions
                        bufferSize *= dim;
                    }
                }
                // Multiply by element size in bytes
                elementSizeBytes = memrefType.getElementTypeBitWidth() / 8;
                bufferSize *= elementSizeBytes;
            }
            
            // Calculate buffer offset for this tile (assuming data is partitioned evenly)
            // For ping-pong mode, we need 2x the per-tile buffer size
            int64_t perTileSize = bufferSize / coreTilesAttr.size();
            int64_t bufferOffset = tileIndex * perTileSize;
            
            // Build config dictionary for this tile with per-flow configuration
            // The config is structured to support multiple flows, indexed by flow_index
            NamedAttrList configAttrs;
            configAttrs.append("tile_index", rewriter.getI32IntegerAttr(tileIndex));
            configAttrs.append("flow_index", rewriter.getI32IntegerAttr(flowIndex)); // Flow index for this configuration
            configAttrs.append("packet_id", rewriter.getI32IntegerAttr(basePacketId + tileIndex)); // Packet ID based on base + tile
            configAttrs.append("dma_channel", rewriter.getI32IntegerAttr(coreChannel));
            configAttrs.append("buffer_mode", rewriter.getI32IntegerAttr(1)); // 1 = ping-pong
            configAttrs.append("num_buffers", rewriter.getI32IntegerAttr(2)); // 2 buffers
            configAttrs.append("buffer_size", rewriter.getI32IntegerAttr(perTileSize)); // Per-tile buffer size in bytes
            configAttrs.append("buffer_offset", rewriter.getI32IntegerAttr(bufferOffset)); // Offset within shared buffer
            configAttrs.append("element_size", rewriter.getI32IntegerAttr(elementSizeBytes)); // Element size in bytes
            
            // Lock IDs for ping-pong synchronization
            // Each flow+tile combination gets unique lock IDs
            // Lock ID = (flowIndex * maxTilesPerFlow * 4) + (tileIndex * 4) + lockType
            int64_t lockBase = flowIndex * 16 + tileIndex * 4; // Assuming max 4 tiles per flow
            configAttrs.append("ping_acquire_lock_id", rewriter.getI32IntegerAttr(lockBase + 0));
            configAttrs.append("pong_acquire_lock_id", rewriter.getI32IntegerAttr(lockBase + 1));
            configAttrs.append("ping_release_lock_id", rewriter.getI32IntegerAttr(lockBase + 2));
            configAttrs.append("pong_release_lock_id", rewriter.getI32IntegerAttr(lockBase + 3));
            
            // Note: Actual buffer base address will be determined at runtime by __Runtime_load_kernel_group
            // The runtime will use: tile_buffer_addr = base_addr + buffer_offset
            
            tileConfigDicts.push_back(rewriter.getDictionaryAttr(configAttrs));
            tileIndex++;
        }
        
        if (coreTiles.empty()) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Create individual kernel_config ops for each tile (e.g., @kernelconfig0, @kernelconfig1)
        SmallVector<Attribute> kernelConfigSymbols;
        for (size_t i = 0; i < tileConfigDicts.size(); ++i) {
            std::string configName = "kernelconfig" + std::to_string(i);
            
            // Create a kernel_config op with a single tile's config
            SmallVector<Attribute> singleTileConfig;
            singleTileConfig.push_back(tileConfigDicts[i]);
            
            auto kernelConfigOp = rewriter.create<dfschedule::DeclareKernelConfigOp>(
                loc,
                dfschedule::KernelConfigType::get(rewriter.getContext()),
                rewriter.getStringAttr(configName),
                rewriter.getArrayAttr(singleTileConfig));
            
            // Store symbol reference
            kernelConfigSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), configName));
        }
        
        // Create callee symbol refs (dskernel_receiver for all)
        SmallVector<Attribute> calleeAttrs;
        calleeAttrs.push_back(SymbolRefAttr::get(rewriter.getContext(), "dskernel_receiver"));
        
        // Create distributed_compute_kernel_args (compute0 for all)
        SmallVector<Attribute> computeKernelAttrs;
        for (size_t i = 0; i < coreTiles.size(); ++i) {
            computeKernelAttrs.push_back(SymbolRefAttr::get(rewriter.getContext(), "compute0"));
            }
            
        // Create dfschedule.config.load_kernel_group with distributed_args pointing to kernel configs
        auto loadKernelGroupOp = rewriter.create<dfschedule::LoadKernelGroupOp>(
                loc,
            dfschedule::KernelGroupType::get(rewriter.getContext()),
            coreTiles,
            rewriter.getArrayAttr(calleeAttrs),
            rewriter.getArrayAttr(computeKernelAttrs),
            nullptr,  // kernel_config = nullptr (not used)
            rewriter.getArrayAttr(kernelConfigSymbols));  // distributed_args = [@kernelconfig0, @kernelconfig1, ...]
            
        // Create dfschedule.schedule.launch_kernel_group
        auto launchKernelGroupOp = rewriter.create<dfschedule::LaunchKernelGroupOp>(
            loc,
            dfschedule::EventType::get(rewriter.getContext()),
            loadKernelGroupOp.getKernelGroup());
        
        // Create dfschedule.schedule.getbdid for shim tile
        auto getBdIdOp = rewriter.create<dfschedule::GetBdIdOp>(
            loc,
            rewriter.getI32Type(),
            shimTileOp.getTile());
        
        // Create dfschedule.schedule.start_io for shim
        auto startIoOp = rewriter.create<dfschedule::StartIoOp>(
            loc,
            dfschedule::EventType::get(rewriter.getContext()),
            createIoOp.getIoHandle(),
            getBdIdOp.getBdId(),
            rewriter.getI32IntegerAttr(flowIndex));
        
        // Create dfschedule.schedule.wait with both events
        SmallVector<Value> events;
        events.push_back(startIoOp.getEvent());
        events.push_back(launchKernelGroupOp.getEvent());
        rewriter.create<dfschedule::ScheduleWaitOp>(loc, events);
        
        // --- Step 5: Generate dskernel_receiver function ---
        // Use the same symbol name as load_kernel_group callee
        StringRef kernelName = "dskernel_receiver";
        
        // Only generate if it doesn't already exist
        if (!hasDSKernelReceiver(op.getOperation(), kernelName)) {
            // Get the tensor type from view for kernel generation
            RankedTensorType kernelTensorType;
            if (auto tensorType = dyn_cast<RankedTensorType>(viewType)) {
                kernelTensorType = tensorType;
            } else if (auto mrType = dyn_cast<MemRefType>(viewType)) {
                kernelTensorType = RankedTensorType::get(mrType.getShape(), mrType.getElementType());
            }
            
            if (kernelTensorType) {
                generateDSKernelReceiver(
                    rewriter,
                    loc,
                    op.getOperation(),
                    kernelName,
                    kernelTensorType,
                    bufferLen,
                    basePacketId,
                    coreChannel,
                    flowIndex,
                    resourceMgr);
            }
        }
        
        // Erase the original FlowTransferOp
        rewriter.eraseOp(op);
        
        return success();
    }
};

// Special pattern for DataSliceOp - replaces with input tensor instead of erasing
struct DataSliceOpConversion : public OpConversionPattern<dfscheblueprint::DataSliceOp> {
    using OpConversionPattern<dfscheblueprint::DataSliceOp>::OpConversionPattern;

    LogicalResult
    matchAndRewrite(dfscheblueprint::DataSliceOp op, OpAdaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        // DataSliceOp is used for symbol references, replace with the input tensor
        rewriter.replaceOp(op, adaptor.getTensorSlice());
        return success();
    }
};

} // namespace

namespace mlir {

void BlueprintToSchedulePass::runOnOperation() {
    MLIRContext *context = &getContext();
    ConversionTarget target(*context);
    
    // Mark target dialects as legal
    target.addLegalDialect<dfschedule::dfscheduledialect, 
                          func::FuncDialect,
                          memref::MemRefDialect,
                          arith::ArithDialect,
                          scf::SCFDialect,
                          tensor::TensorDialect,
                          bufferization::BufferizationDialect,
                          BuiltinDialect>();
    
    // Mark all dfscheblueprint operations as illegal to trigger conversion/erasure
    target.addIllegalOp<dfscheblueprint::FlowConfigOp>();
    target.addIllegalOp<dfscheblueprint::TileGroupOp>();
    //target.addIllegalOp<dfscheblueprint::DeclareDataOp>();
    //target.addIllegalOp<dfscheblueprint::DataSliceOp>();
    target.addIllegalOp<dfscheblueprint::FlowTransferOp>();
    target.addIllegalOp<dfscheblueprint::TransferManifestOp>();
    
    // Type converter
    TypeConverter typeConverter;
    typeConverter.addConversion([](Type type) { return type; });
    
    // Convert tensor types to memref types where needed
    typeConverter.addConversion([](RankedTensorType tensorType) -> Type {
        return MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    });
    
    RewritePatternSet patterns(context);
    // FlowTransferConversion converts flow_transfer to dfschedule operations
    // It reads from FlowConfigOps to get DMA configuration
    patterns.add<FlowTransferConversion>(context);
    // DataSliceOp replaces with input tensor
    patterns.add<DataSliceOpConversion>(context);
    // Use unified erase pattern for ops that just need to be removed
    // FlowConfigOp is erased since FlowTransferConversion reads its attributes directly
    patterns.add<EraseOpPattern<dfscheblueprint::FlowConfigOp>>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::TileGroupOp>>(context);
    //patterns.add<EraseOpPattern<dfscheblueprint::DeclareDataOp>>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::TransferManifestOp>>(context);
    
    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
    }
}

} // namespace mlir
