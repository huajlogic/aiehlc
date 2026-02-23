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

// Helper function to check if kernel module already exists in the module
static bool hasKernelModule(Operation *rootOp, StringRef moduleName) {
    // Find the module-level operation
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }

    // Search for existing kernel module with the given name
    for (Region &region : moduleOp->getRegions()) {
        for (Block &block : region) {
            for (Operation &op : block) {
                if (auto kernelModule = dyn_cast<dfschedule::KernelModuleOp>(&op)) {
                    if (kernelModule.getSymName() == moduleName) {
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

// Forward declarations for functions used in generateDSKernelReceiver
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target);

// Generate a kernel symbol declaration only (dfschedule.dskernel_receiver with empty body).
// Details (kernel module, buffers, locks, etc.) are filled in by a separate pass.
// Parameters:
//   - kernelName: symbol name for the kernel (same as load_kernel_group callee)
//   - insertBeforeOp: used to find module and insertion point
static void generateDSKernelReceiver(ConversionPatternRewriter &rewriter, Location loc, Operation *insertBeforeOp,
                                     StringRef kernelName, RankedTensorType tensorType, int64_t bufferLen,
                                     uint32_t basePacketId, int64_t coreChannel, uint32_t flowIndex) {
    (void)tensorType;
    (void)bufferLen;
    (void)basePacketId;
    (void)coreChannel;
    (void)flowIndex;

    Operation *rootModuleOp = getModuleOp(insertBeforeOp);
    Block &moduleBlock = rootModuleOp->getRegions().front().front();
    if (!moduleBlock.empty() && moduleBlock.back().hasTrait<OpTrait::IsTerminator>())
        rewriter.setInsertionPoint(&moduleBlock.back());
    else
        rewriter.setInsertionPointToEnd(&moduleBlock);

    auto receiverOp = rewriter.create<dfschedule::DSKernelReceiverOp>(loc, kernelName);
    receiverOp.getBody().emplaceBlock();
}

// Helper function to look up FlowConfigOp by symbol reference (wrapper for backward compatibility)
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::FlowConfigOp>(rootOp, target);
}

static dfscheblueprint::DataSliceOp lookupDataSlice(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::DataSliceOp>(rootOp, target);
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

        // --- CORE TILES: declaretile, kernel_config, and ping-pong DMA config ---
        ArrayAttr coreTilesAttr = coreTileGroup.getTiles();
        SmallVector<Value> coreTiles;

        // Get DMA channel and direction from core FlowConfig
        auto coreDmaAttr = coreFlowConfig.getDma();
        auto coreDmaChannels = coreDmaAttr.getChannels();
        int64_t coreChannel = coreDmaChannels.empty() ? 0 : coreDmaChannels[0];
        auto coreDmaDir = coreDmaAttr.getDirection();
        StringRef coreDmaDirection = (coreDmaDir == dfscheblueprint::bp_direction::MM2S) ? "MM2S" : "S2MM";
        StringRef coreIoOperation = (coreDmaDir == dfscheblueprint::bp_direction::MM2S) ? "SEND" : "RECV";

        // Get per-tile data slices from core FlowConfig's slice_symbols
        auto sliceSymbolsOpt = coreFlowConfig.getSliceSymbols();

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
                    if (dim > 0) {
                        bufferSize *= dim;
                    }
                }
                elementSizeBytes = memrefType.getElementTypeBitWidth() / 8;
                bufferSize *= elementSizeBytes;
            }

            int64_t perTileSize = bufferSize / coreTilesAttr.size();
            int64_t bufferOffset = tileIndex * perTileSize;

            // Lock IDs: both ping and pong BDs share the same acquire/release pair
            int64_t lockBase = flowIndex * 8 + tileIndex * 2;
            int32_t acquireLockId = lockBase + 0;
            int32_t releaseLockId = lockBase + 1;

            // Build config dictionary for this tile
            NamedAttrList configAttrs;
            configAttrs.append("tile_index", rewriter.getI32IntegerAttr(tileIndex));
            configAttrs.append("flow_index", rewriter.getI32IntegerAttr(flowIndex));
            configAttrs.append("packet_id", rewriter.getI32IntegerAttr(basePacketId + tileIndex));
            configAttrs.append("dma_channel", rewriter.getI32IntegerAttr(coreChannel));
            configAttrs.append("buffer_mode", rewriter.getI32IntegerAttr(1)); // 1 = ping-pong
            configAttrs.append("num_buffers", rewriter.getI32IntegerAttr(2));
            configAttrs.append("buffer_size", rewriter.getI32IntegerAttr(perTileSize));
            configAttrs.append("buffer_offset", rewriter.getI32IntegerAttr(bufferOffset));
            configAttrs.append("element_size", rewriter.getI32IntegerAttr(elementSizeBytes));
            configAttrs.append("acquire_lock_id", rewriter.getI32IntegerAttr(acquireLockId));
            configAttrs.append("release_lock_id", rewriter.getI32IntegerAttr(releaseLockId));

            tileConfigDicts.push_back(rewriter.getDictionaryAttr(configAttrs));

            // --- Core tile ping-pong DMA BD configuration ---
            // Look up per-tile data slice from slice_symbols (maps 1:1 to tiles)
            if (sliceSymbolsOpt && tileIndex < (int)sliceSymbolsOpt->size()) {
                auto sliceSymRef = cast<SymbolRefAttr>((*sliceSymbolsOpt)[tileIndex]);
                auto dataSliceOp = lookupDataSlice(op.getOperation(), sliceSymRef);
                if (dataSliceOp) {
                    Value perTileTensor = dataSliceOp.getTensorSlice();
                    Type perTileType = perTileTensor.getType();

                    // Create per-tile declaretensor -> memref
                    int64_t perTileTotalSize = perTileSize / elementSizeBytes;
                    MemRefType perTileMemrefType;
                    if (auto tt = dyn_cast<RankedTensorType>(perTileType)) {
                        int64_t totalElems = 1;
                        for (int64_t d : tt.getShape())
                            totalElems *= d;
                        perTileMemrefType = MemRefType::get({totalElems}, tt.getElementType());
                        perTileTotalSize = totalElems;
                    } else {
                        perTileMemrefType = MemRefType::get({perTileTotalSize}, memrefType.getElementType());
                    }

                    Value perTileMemref =
                        rewriter.create<dfschedule::DeclareTensorOp>(loc, perTileMemrefType, perTileTensor);

                    // Lock ID constants (shared by both ping and pong BDs)
                    auto acqLockConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                           rewriter.getI32IntegerAttr(acquireLockId));
                    auto relLockConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                           rewriter.getI32IntegerAttr(releaseLockId));

                    // BD IDs are per-tile local (each tile's DMA has its own BD space)
                    int32_t pingBdId = 0;
                    int32_t pongBdId = 1;

                    // Ping BD: next_bd -> pong
                    auto pingBdIdConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                            rewriter.getI32IntegerAttr(pingBdId));
                    auto pingBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
                        loc, dfschedule::BdHandleType::get(rewriter.getContext()), perTileMemref, coreTileOp.getTile(),
                        pingBdIdConst.getResult(),
                        rewriter.getI32IntegerAttr(0),                // offset
                        rewriter.getI32IntegerAttr(perTileTotalSize), // len
                        rewriter.getBoolAttr(true),                   // enable_packet
                        rewriter.getI32IntegerAttr(basePacketId + tileIndex),
                        rewriter.getI32IntegerAttr(pongBdId), // next_bd -> pong
                        acqLockConst.getResult(), relLockConst.getResult());

                    // Pong BD: next_bd -> ping
                    auto pongBdIdConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                            rewriter.getI32IntegerAttr(pongBdId));
                    rewriter.create<dfschedule::ConfigDmaBdOp>(
                        loc, dfschedule::BdHandleType::get(rewriter.getContext()), perTileMemref, coreTileOp.getTile(),
                        pongBdIdConst.getResult(),
                        rewriter.getI32IntegerAttr(0),                // offset
                        rewriter.getI32IntegerAttr(perTileTotalSize), // len
                        rewriter.getBoolAttr(true),                   // enable_packet
                        rewriter.getI32IntegerAttr(basePacketId + tileIndex),
                        rewriter.getI32IntegerAttr(pingBdId), // next_bd -> ping
                        acqLockConst.getResult(), relLockConst.getResult());

                    // Create IO handle for core tile (references ping BD; DMA chains automatically)
                    rewriter.create<dfschedule::ConfigCreateIoOp>(
                        loc, dfschedule::IoHandleType::get(rewriter.getContext()), pingBdOp.getBdHandle(),
                        coreTileOp.getTile(), rewriter.getI32IntegerAttr(coreChannel),
                        rewriter.getStringAttr(coreDmaDirection), rewriter.getStringAttr(coreIoOperation));
                }
            }

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
                generateDSKernelReceiver(rewriter, loc, op.getOperation(), kernelName, kernelTensorType, bufferLen,
                                         basePacketId, coreChannel, flowIndex);
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
    // target.addIllegalOp<dfscheblueprint::TransferManifestOp>();

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
    // patterns.add<EraseOpPattern<dfscheblueprint::DeclareDataOp>>(context);
    // patterns.add<EraseOpPattern<dfscheblueprint::TransferManifestOp>>(context);

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
    }
}

} // namespace mlir
