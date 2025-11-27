/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "passdmaphoptodfscheblueprint.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinDialect.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include <iostream>
#include <atomic>

using namespace mlir;
using namespace dmaphop;
using namespace dfscheblueprint;
using namespace routing;

namespace mlir {

// Global counter for unique sequential naming (avoids conflict)
static std::atomic<int> g_pullPushCounter{0};

// Helper to process pull (Gather)
void processPull(dmaphop::pull op, OpBuilder &builder, dfscheblueprint::ConfigOp configOp, Value viewHandle) {
    // 1. Get path and extract source/destination from producers/consumers attributes
    auto pathValue = op.getPath();
    auto pathOp = dyn_cast_or_null<dmaphop::create_path>(pathValue.getDefiningOp());
    if (!pathOp) {
        llvm::errs() << "ERROR: processPull - failed to get create_path from pull op\n";
        return;
    }
    
    SmallVector<Attribute> sourceTiles;
    SmallVector<Attribute> destTiles;
    int64_t sourceChannel = -1;
    int64_t destChannel = -1;
    
    // Get producers (sources) from create_path attribute via symbol table lookup
    auto producersAttr = pathOp.getProducers();
    if (auto arrayAttr = dyn_cast<ArrayAttr>(producersAttr)) {
        for (auto innerAttr : arrayAttr) {
            if (auto innerArray = dyn_cast<ArrayAttr>(innerAttr)) {
                for (auto symbolAttr : innerArray) {
                    auto symbolRef = dyn_cast<FlatSymbolRefAttr>(symbolAttr);
                    if (!symbolRef) {
                        llvm::errs() << "ERROR: processPull - producer is not a FlatSymbolRefAttr\n";
                        continue;
                    }
                    auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                    if (!port) {
                        llvm::errs() << "ERROR: processPull - failed to find producer port symbol '" 
                                    << symbolRef.getValue() << "' in symbol table\n";
                        continue;
                    }
                    sourceChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                    auto tileValue = port.getTile();
                    auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp());
                    if (!tileOp) {
                        llvm::errs() << "ERROR: processPull - failed to get tile from producer port '" 
                                    << symbolRef.getValue() << "'\n";
                        continue;
                    }
                    sourceTiles.push_back(builder.getArrayAttr({
                        builder.getI64IntegerAttr(tileOp.getCol()),
                        builder.getI64IntegerAttr(tileOp.getRow())
                    }));
                }
            }
        }
    }
    
    if (sourceTiles.empty()) {
        llvm::errs() << "WARNING: processPull - no source tiles found from producers attribute\n";
    }
    
    // Get unique sequential ID for naming
    int opId = g_pullPushCounter.fetch_add(1);
    
    std::string srcGroupName = "group_src_" + std::to_string(opId);
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        srcGroupName,
        builder.getArrayAttr(sourceTiles)
    );
    
    // Get consumers (destinations) from create_path attribute via symbol table lookup
    auto consumersAttr = pathOp.getConsumers();
    if (auto arrayAttr = dyn_cast<ArrayAttr>(consumersAttr)) {
        for (auto innerAttr : arrayAttr) {
            if (auto innerArray = dyn_cast<ArrayAttr>(innerAttr)) {
                for (auto symbolAttr : innerArray) {
                    auto symbolRef = dyn_cast<FlatSymbolRefAttr>(symbolAttr);
                    if (!symbolRef) {
                        llvm::errs() << "ERROR: processPull - consumer is not a FlatSymbolRefAttr\n";
                        continue;
                    }
                    auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                    if (!port) {
                        llvm::errs() << "ERROR: processPull - failed to find consumer port symbol '" 
                                    << symbolRef.getValue() << "' in symbol table\n";
                        continue;
                    }
                    destChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                    auto tileValue = port.getTile();
                    auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp());
                    if (!tileOp) {
                        llvm::errs() << "ERROR: processPull - failed to get tile from consumer port '" 
                                    << symbolRef.getValue() << "'\n";
                        continue;
                    }
                    destTiles.push_back(builder.getArrayAttr({
                        builder.getI64IntegerAttr(tileOp.getCol()),
                        builder.getI64IntegerAttr(tileOp.getRow())
                    }));
                }
            }
        }
    }
    
    if (destTiles.empty()) {
        llvm::errs() << "WARNING: processPull - no destination tiles found from consumers attribute\n";
    }
    
    std::string dstGroupName = "group_dst_" + std::to_string(opId);
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        dstGroupName,
        builder.getArrayAttr(destTiles)
    );
    
    // 3. Create Binds
    std::string srcBindName = "bind_src_" + std::to_string(opId);
    builder.create<dfscheblueprint::BindGroupOp>(
        op.getLoc(),
        srcBindName,
        FlatSymbolRefAttr::get(builder.getContext(), srcGroupName),
        viewHandle,
        builder.getStringAttr("linear"),
        dfscheblueprint::DMAAttr::get(builder.getContext(), ArrayRef<int64_t>({sourceChannel}), dfscheblueprint::bp_direction::MM2S),
        builder.getArrayAttr({}) 
    );
    
    std::string dstBindName = "bind_dst_" + std::to_string(opId);
    builder.create<dfscheblueprint::BindOp>(
        op.getLoc(),
        dstBindName,
        FlatSymbolRefAttr::get(builder.getContext(), dstGroupName),
        viewHandle,
        builder.getStringAttr("root"),
        dfscheblueprint::DMAAttr::get(builder.getContext(), ArrayRef<int64_t>({destChannel}), dfscheblueprint::bp_direction::S2MM),
        nullptr // slice_symbol
    );
    
    // 4. Collective Transfer
    builder.create<dfscheblueprint::CollectiveTransferOp>(
        op.getLoc(),
        "transfer_" + std::to_string(opId),
        "many_to_one",
        FlatSymbolRefAttr::get(builder.getContext(), srcBindName),
        FlatSymbolRefAttr::get(builder.getContext(), dstBindName),
        builder.getStringAttr("sequential"),
        0
    );
}

// Helper to process PushOp (Scatter)
void processPush(dmaphop::push op, OpBuilder &builder, dfscheblueprint::ConfigOp configOp, Value viewHandle) {
    // 1. Identify Source (One)
    // Push %data to %path
    // Source is implicit or we need to find where %data comes from?
    // Usually Push is from Shim/Host.
    // Let's look at the path producers.
    
    auto pathValue = op.getPath();
    int64_t srcChannel = -1;
    SmallVector<Attribute> srcTiles;
    SmallVector<Attribute> dstTiles;
    int64_t dstChannel = -1;
    
    auto pathOp = dyn_cast_or_null<dmaphop::create_path>(pathValue.getDefiningOp());
    if (!pathOp) {
        llvm::errs() << "ERROR: processPush - failed to get create_path from push op\n";
        return;
    }
    
    // Producers (sources) via symbol table lookup
    auto producersAttr = pathOp.getProducers();
    if (auto arrayAttr = dyn_cast<ArrayAttr>(producersAttr)) {
        for (auto innerAttr : arrayAttr) {
            if (auto innerArray = dyn_cast<ArrayAttr>(innerAttr)) {
                for (auto symbolAttr : innerArray) {
                    auto symbolRef = dyn_cast<FlatSymbolRefAttr>(symbolAttr);
                    if (!symbolRef) {
                        llvm::errs() << "ERROR: processPush - producer is not a FlatSymbolRefAttr\n";
                        continue;
                    }
                    auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                    if (!port) {
                        llvm::errs() << "ERROR: processPush - failed to find producer port symbol '" 
                                    << symbolRef.getValue() << "' in symbol table\n";
                        continue;
                    }
                    srcChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                    auto tileValue = port.getTile();
                    auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp());
                    if (!tileOp) {
                        llvm::errs() << "ERROR: processPush - failed to get tile from producer port '" 
                                    << symbolRef.getValue() << "'\n";
                        continue;
                    }
                    srcTiles.push_back(builder.getArrayAttr({
                        builder.getI64IntegerAttr(tileOp.getCol()),
                        builder.getI64IntegerAttr(tileOp.getRow())
                    }));
                }
            }
        }
    }
    
    if (srcTiles.empty()) {
        llvm::errs() << "WARNING: processPush - no source tiles found from producers attribute\n";
    }
    
    // Consumers (destinations) via symbol table lookup
    auto consumersAttr = pathOp.getConsumers();
    if (auto arrayAttr = dyn_cast<ArrayAttr>(consumersAttr)) {
        for (auto innerAttr : arrayAttr) {
            if (auto innerArray = dyn_cast<ArrayAttr>(innerAttr)) {
                for (auto symbolAttr : innerArray) {
                    auto symbolRef = dyn_cast<FlatSymbolRefAttr>(symbolAttr);
                    if (!symbolRef) {
                        llvm::errs() << "ERROR: processPush - consumer is not a FlatSymbolRefAttr\n";
                        continue;
                    }
                    auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                    if (!port) {
                        llvm::errs() << "ERROR: processPush - failed to find consumer port symbol '" 
                                    << symbolRef.getValue() << "' in symbol table\n";
                        continue;
                    }
                    dstChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                    auto tileValue = port.getTile();
                    auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp());
                    if (!tileOp) {
                        llvm::errs() << "ERROR: processPush - failed to get tile from consumer port '" 
                                    << symbolRef.getValue() << "'\n";
                        continue;
                    }
                    dstTiles.push_back(builder.getArrayAttr({
                        builder.getI64IntegerAttr(tileOp.getCol()),
                        builder.getI64IntegerAttr(tileOp.getRow())
                    }));
                }
            }
        }
    }
    
    if (dstTiles.empty()) {
        llvm::errs() << "WARNING: processPush - no destination tiles found from consumers attribute\n";
    }
    
    // Get unique sequential ID for naming
    int opId = g_pullPushCounter.fetch_add(1);
    
    std::string srcGroupName = "group_src_" + std::to_string(opId);
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        srcGroupName,
        builder.getArrayAttr(srcTiles)
    );
    
    std::string dstGroupName = "group_dst_" + std::to_string(opId);
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        dstGroupName,
        builder.getArrayAttr(dstTiles)
    );
    
    // Binds
    std::string srcBindName = "bind_src_" + std::to_string(opId);
    builder.create<dfscheblueprint::BindOp>(
        op.getLoc(),
        srcBindName,
        FlatSymbolRefAttr::get(builder.getContext(), srcGroupName),
        viewHandle,
        builder.getStringAttr("root"),
        dfscheblueprint::DMAAttr::get(builder.getContext(), ArrayRef<int64_t>({srcChannel}), dfscheblueprint::bp_direction::MM2S),
        nullptr // slice_symbol
    );
    
    std::string dstBindName = "bind_dst_" + std::to_string(opId);
    builder.create<dfscheblueprint::BindGroupOp>(
        op.getLoc(),
        dstBindName,
        FlatSymbolRefAttr::get(builder.getContext(), dstGroupName),
        viewHandle,
        builder.getStringAttr("linear"),
        dfscheblueprint::DMAAttr::get(builder.getContext(), ArrayRef<int64_t>({dstChannel}), dfscheblueprint:: bp_direction::S2MM),
        builder.getArrayAttr({})
    );
    
    builder.create<dfscheblueprint::CollectiveTransferOp>(
        op.getLoc(),
        "transfer_" + std::to_string(opId),
        "one_to_many",
        FlatSymbolRefAttr::get(builder.getContext(), srcBindName),
        FlatSymbolRefAttr::get(builder.getContext(), dstBindName),
        builder.getStringAttr(""),
        0
    );
}

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

struct CreateDummyTensorConversion : public OpConversionPattern<routing::createdummytensor> {
    using OpConversionPattern<routing::createdummytensor>::OpConversionPattern;
    LogicalResult matchAndRewrite(routing::createdummytensor op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto shapeAttr = op.getShape();
        SmallVector<int64_t> shape;
        for (auto dim : shapeAttr) {
            shape.push_back(cast<IntegerAttr>(dim).getInt());
        }
        auto memRefType = MemRefType::get(shape, rewriter.getF32Type());
        auto alloc = rewriter.create<memref::AllocOp>(op.getLoc(), memRefType);
        rewriter.replaceOp(op, alloc.getResult());
        return success();
    }
};

struct PartitionTensorConversion : public OpConversionPattern<routing::partitiontensor> {
    using OpConversionPattern<routing::partitiontensor>::OpConversionPattern;
    LogicalResult matchAndRewrite(routing::partitiontensor op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.replaceOp(op, adaptor.getTensor());
        return success();
    }
};

struct ExtractDataConversion : public OpConversionPattern<routing::extract_data> {
    using OpConversionPattern<routing::extract_data>::OpConversionPattern;
    LogicalResult matchAndRewrite(routing::extract_data op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto partitionOp = dyn_cast_or_null<routing::partitiontensor>(op.getTensor().getDefiningOp());
        if (!partitionOp) return failure();

        int64_t splitNum = partitionOp.getSplitnum();
        int64_t splitDim = partitionOp.getSplitdim();

        Value inputMemRef = adaptor.getTensor();
        auto memRefType = dyn_cast<MemRefType>(inputMemRef.getType());
        if (!memRefType) return failure();
        auto shape = memRefType.getShape();

        SmallVector<OpFoldResult> offsets;
        SmallVector<OpFoldResult> sizes;
        SmallVector<OpFoldResult> strides;

        Value indexVal = adaptor.getIdx();
        if (!indexVal.getType().isIndex()) {
            indexVal = rewriter.create<arith::IndexCastOp>(op.getLoc(), rewriter.getIndexType(), indexVal);
        }

        for (size_t i = 0; i < shape.size(); ++i) {
            if (i == (size_t)splitDim) {
                Value dimSizeVal;
                if (shape[i] == ShapedType::kDynamic) {
                    dimSizeVal = rewriter.create<memref::DimOp>(op.getLoc(), inputMemRef, i);
                } else {
                    dimSizeVal = rewriter.create<arith::ConstantIndexOp>(op.getLoc(), shape[i]);
                }
                
                Value splitNumVal = rewriter.create<arith::ConstantIndexOp>(op.getLoc(), splitNum);
                Value splitSize = rewriter.create<arith::DivUIOp>(op.getLoc(), dimSizeVal, splitNumVal);
                Value offset = rewriter.create<arith::MulIOp>(op.getLoc(), indexVal, splitSize);
                
                offsets.push_back(offset);
                sizes.push_back(splitSize);
            } else {
                offsets.push_back(rewriter.getIndexAttr(0));
                if (shape[i] == ShapedType::kDynamic) {
                     Value dimSizeVal = rewriter.create<memref::DimOp>(op.getLoc(), inputMemRef, i);
                     sizes.push_back(dimSizeVal);
                } else {
                    sizes.push_back(rewriter.getIndexAttr(shape[i]));
                }
            }
            strides.push_back(rewriter.getIndexAttr(1));
        }

        auto subView = rewriter.create<memref::SubViewOp>(
            op.getLoc(),
            inputMemRef,
            offsets,
            sizes,
            strides
        );
        
        rewriter.replaceOp(op, subView.getResult());
        return success();
    }
};

struct PushOpConversion : public OpConversionPattern<dmaphop::push> {
    PushOpConversion(MLIRContext *context) 
        : OpConversionPattern<dmaphop::push>(context) {}

    LogicalResult matchAndRewrite(dmaphop::push op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

struct PullOpConversion : public OpConversionPattern<dmaphop::pull> {
    PullOpConversion(MLIRContext *context) 
        : OpConversionPattern<dmaphop::pull>(context) {}

    LogicalResult matchAndRewrite(dmaphop::pull op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto producerBuffers = op.getProducerBuffers();
        if (producerBuffers.empty()) return failure();

        Value viewSplit = adaptor.getData();
        
        // 1. Create data slices for producer buffers and collect slice symbol names
        SmallVector<Attribute> sliceSymbols;
        int64_t cumulativeOffset = 0;
        for (size_t i = 0; i < producerBuffers.size(); ++i) {
            auto buffer = producerBuffers[i];
            auto memrefType = dyn_cast<MemRefType>(buffer.getType());
            if (!memrefType) continue;

            auto sliceShape = memrefType.getShape();
            SmallVector<int64_t> sizeVec;
            SmallVector<int64_t> strideVec;
            
            for (int64_t dim : sliceShape) {
                sizeVec.push_back(dim);
            }

            int64_t currentStride = 1;
            for (int j = sliceShape.size() - 1; j >= 0; --j) {
                strideVec.insert(strideVec.begin(), currentStride);
                int64_t dimSize = (sliceShape[j] == ShapedType::kDynamic ? 1024 : sliceShape[j]);
                currentStride *= dimSize;
            }

            SmallVector<int64_t> offsetVec;
            offsetVec.push_back(cumulativeOffset);
            for (size_t j = 1; j < sliceShape.size(); ++j) {
                offsetVec.push_back(0);
            }

            auto sliceAttr = dfscheblueprint::SliceAttr::get(
                getContext(),
                TypeAttr::get(memrefType),
                rewriter.getI64ArrayAttr(offsetVec),
                rewriter.getI64ArrayAttr(sizeVec),
                rewriter.getI64ArrayAttr(strideVec)
            );

            std::string sliceName = "producer_slice_" + std::to_string(i);
            rewriter.create<dfscheblueprint::DataSliceOp>(
                op.getLoc(),
                rewriter.getStringAttr(sliceName),
                viewSplit,
                sliceAttr
            );
            
            // Collect slice symbol reference for bind_group
            sliceSymbols.push_back(FlatSymbolRefAttr::get(getContext(), sliceName));

            cumulativeOffset += sliceShape[0]; 
        }

        // 2. Get path and extract source/destination from producers/consumers attributes
        // Path structure: create_path[hop1, hop2, ...] with producers/consumers attributes
        // producers/consumers are symbol references to port ops
        auto pathValue = op.getPath();
        auto pathOp = dyn_cast_or_null<dmaphop::create_path>(pathValue.getDefiningOp());
        if (!pathOp) {
            llvm::errs() << "ERROR: PullOpConversion - failed to get create_path from pull op\n";
            return failure();
        }
        
        SmallVector<Attribute> sourceTiles;
        SmallVector<Attribute> destTiles;
        int64_t sourceChannel = -1;
        int64_t destChannel = -1;
        
        // Get producers (sources) from create_path attribute via symbol table lookup
        auto producersAttr = pathOp.getProducers();
        if (auto arrayAttr = dyn_cast<ArrayAttr>(producersAttr)) {
            for (auto innerAttr : arrayAttr) {
                //if (auto innerArray = dyn_cast<ArrayAttr>(innerAttr)) {
                    //for (auto symbolAttr : innerArray) {
                        auto symbolRef = dyn_cast<FlatSymbolRefAttr>(innerAttr);
                        if (!symbolRef) {
                            llvm::errs() << "ERROR: PullOpConversion - producer is not a FlatSymbolRefAttr\n";
                            continue;
                        }
                        auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                        if (!port) {
                            llvm::errs() << "ERROR: PullOpConversion - failed to find producer port symbol '" 
                                        << symbolRef.getValue() << "' in symbol table\n";
                            continue;
                        }
                        sourceChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                        auto tileValue = port.getTile();
                        auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp());
                        if (!tileOp) {
                            llvm::errs() << "ERROR: PullOpConversion - failed to get tile from producer port '" 
                                        << symbolRef.getValue() << "'\n";
                            continue;
                        }
                        sourceTiles.push_back(rewriter.getArrayAttr({
                            rewriter.getI64IntegerAttr(tileOp.getCol()),
                            rewriter.getI64IntegerAttr(tileOp.getRow())
                        }));
                    //}
                //}
            }
        }
        
        if (sourceTiles.empty()) {
            llvm::errs() << "WARNING: PullOpConversion - no source tiles found from producers attribute\n";
        }
        
        // Get consumers (destinations) from create_path attribute via symbol table lookup
        auto consumersAttr = pathOp.getConsumers();
        if (auto arrayAttr = dyn_cast<ArrayAttr>(consumersAttr)) {
            for (auto innerAttr : arrayAttr) {
                //if (auto innerArray = dyn_cast<ArrayAttr>(innerAttr)) {
                    //for (auto symbolAttr : innerArray) {
                        auto symbolRef = dyn_cast<FlatSymbolRefAttr>(innerAttr);
                        if (!symbolRef) {
                            llvm::errs() << "ERROR: PullOpConversion - consumer is not a FlatSymbolRefAttr\n";
                            continue;
                        }
                        auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                        if (!port) {
                            llvm::errs() << "ERROR: PullOpConversion - failed to find consumer port symbol '" 
                                        << symbolRef.getValue() << "' in symbol table\n";
                            continue;
                        }
                        destChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                        auto tileValue = port.getTile();
                        auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp());
                        if (!tileOp) {
                            llvm::errs() << "ERROR: PullOpConversion - failed to get tile from consumer port '" 
                                        << symbolRef.getValue() << "'\n";
                            continue;
                        }
                        destTiles.push_back(rewriter.getArrayAttr({
                            rewriter.getI64IntegerAttr(tileOp.getCol()),
                            rewriter.getI64IntegerAttr(tileOp.getRow())
                        }));
                    //}
                //}
            }
        }
        
        if (destTiles.empty()) {
            llvm::errs() << "WARNING: PullOpConversion - no destination tiles found from consumers attribute\n";
        }
        
        // Get unique sequential ID for naming
        int opId = g_pullPushCounter.fetch_add(1);
        
        std::string srcGroupName = "group_src_" + std::to_string(opId);
        std::string dstGroupName = "group_dst_" + std::to_string(opId);
        
        // 3. Create resource_group ops at the beginning of RoutingCreate block
        if (auto routingCreateOp = op->getParentOfType<routing::RoutingCreate>()) {
            Block &routingBlock = routingCreateOp.getRegion().front();
            OpBuilder::InsertionGuard guard(rewriter);
            rewriter.setInsertionPointToStart(&routingBlock);
            
            // Source resource group (producers)
            rewriter.create<dfscheblueprint::ResourceGroupOp>(
                op.getLoc(),
                rewriter.getStringAttr(srcGroupName),
                rewriter.getArrayAttr(sourceTiles)
            );
            
            // Destination resource group (consumers)
            rewriter.create<dfscheblueprint::ResourceGroupOp>(
                op.getLoc(),
                rewriter.getStringAttr(dstGroupName),
                rewriter.getArrayAttr(destTiles)
            );
        } else {
            // Fallback: insert at current position if not inside RoutingCreate
            rewriter.create<dfscheblueprint::ResourceGroupOp>(
                op.getLoc(),
                rewriter.getStringAttr(srcGroupName),
                rewriter.getArrayAttr(sourceTiles)
            );
            
            rewriter.create<dfscheblueprint::ResourceGroupOp>(
                op.getLoc(),
                rewriter.getStringAttr(dstGroupName),
                rewriter.getArrayAttr(destTiles)
            );
        }
        
        // 4. Create Binds
        std::string srcBindName = "bind_src_" + std::to_string(opId);
        rewriter.create<dfscheblueprint::BindGroupOp>(
            op.getLoc(),
            rewriter.getStringAttr(srcBindName),
            FlatSymbolRefAttr::get(getContext(), srcGroupName),
            viewSplit,
            rewriter.getStringAttr("linear"),
            dfscheblueprint::DMAAttr::get(getContext(), ArrayRef<int64_t>({sourceChannel}), dfscheblueprint::bp_direction::MM2S),
            rewriter.getArrayAttr(sliceSymbols)  // Associate with @producer_slice_0 to @producer_slice_N
        );
        
        std::string dstBindName = "bind_dst_" + std::to_string(opId);
        rewriter.create<dfscheblueprint::BindOp>(
            op.getLoc(),
            rewriter.getStringAttr(dstBindName),
            FlatSymbolRefAttr::get(getContext(), dstGroupName),
            viewSplit,
            rewriter.getStringAttr("root"),
            dfscheblueprint::DMAAttr::get(getContext(), ArrayRef<int64_t>({destChannel}), dfscheblueprint::bp_direction::S2MM),
            nullptr // slice_symbol
        );
        
        // 5. Create Collective Transfer
        rewriter.create<dfscheblueprint::CollectiveTransferOp>(
            op.getLoc(),
            rewriter.getStringAttr("transfer_" + std::to_string(opId)),
            rewriter.getStringAttr("many_to_one"),
            FlatSymbolRefAttr::get(getContext(), srcBindName),
            FlatSymbolRefAttr::get(getContext(), dstBindName),
            rewriter.getStringAttr("sequential"),
            0
        );
        
        rewriter.eraseOp(op);
        return success();
    }
};

void DmaphopTodfscheblueprintPass::runOnOperation() {
    auto module = getOperation();
    OpBuilder builder(module->getContext());

    MLIRContext *context = &getContext();
    ConversionTarget target(*context);
    target.addLegalDialect<dfscheblueprint::dfscheblueprintdialect>();
    target.addLegalDialect<routing::routingdialect>();
    target.addLegalDialect<arith::ArithDialect>();
    target.addLegalDialect<memref::MemRefDialect>();
    target.addLegalOp<scf::ExecuteRegionOp>();
    
    //target.addIllegalDialect<dmaphop::dmaphopdialect>();
    //target.addIllegalOp<dmaphop::push>();
    //target.addIllegalOp<dmaphop::pull>();
    //target.addIllegalOp<routing::partitiontensor>();
    
    RewritePatternSet patterns(context);
    patterns.add<EraseOpLowering<dmaphop::tile>,
                 EraseOpLowering<dmaphop::port>,
                 EraseOpLowering<dmaphop::create_hop>,
                 EraseOpLowering<dmaphop::create_path>,
                 EraseOpLowering<dmaphop::alloc_buffer>,
                 EraseOpLowering<dmaphop::sync>,
                 EraseOpLowering<dmaphop::dealloc_buffer>>(context);
    
    patterns.add<CreateDummyTensorConversion>(context);
    patterns.add<PartitionTensorConversion>(context);
    patterns.add<ExtractDataConversion>(context);
    patterns.add<PushOpConversion>(context);
    patterns.add<PullOpConversion>(context);

    target.addIllegalOp<routing::createdummytensor>();
    target.addIllegalOp<routing::partitiontensor>();
    target.addIllegalOp<routing::extract_data>();

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
    }
    
    //SmallVector<scf::ExecuteRegionOp> execOps;
    //module->walk([&](scf::ExecuteRegionOp op) { execOps.push_back(op); });
    /*
    for (auto execOp : execOps) {
        bool hasDmapHop = false;
        execOp.walk([&](Operation *op) {
            if (op->getDialect()->getNamespace() == "dmaphop") {
                hasDmapHop = true;
                return WalkResult::interrupt();
            }
            return WalkResult::advance();
        });
        
        if (!hasDmapHop) continue;

        builder.setInsertionPoint(execOp);
        auto configOp = builder.create<dfscheblueprint::ConfigOp>(
            execOp.getLoc(), 
            builder.getStringAttr("broadcast_gather_blueprint")
        );
        
        Block *configBody = builder.createBlock(&configOp.getRegion());
        // No need to set insertion point here as patterns will set it

        MLIRContext *context = &getContext();
        ConversionTarget target(*context);
        target.addLegalDialect<dfscheblueprint::dfscheblueprintdialect>();
        target.addLegalDialect<routing::routingdialect>();
        target.addLegalDialect<arith::ArithDialect>();
        target.addLegalDialect<memref::MemRefDialect>();
        target.addLegalOp<scf::ExecuteRegionOp>();
        
        target.addIllegalDialect<dmaphop::dmaphopdialect>();
        target.addIllegalOp<dmaphop::push>();
        target.addIllegalOp<dmaphop::pull>();
        //target.addIllegalOp<routing::partitiontensor>();
        
        RewritePatternSet patterns(context);
        patterns.add<EraseOpLowering<dmaphop::tile>,
                     EraseOpLowering<dmaphop::port>,
                     EraseOpLowering<dmaphop::create_hop>,
                     EraseOpLowering<dmaphop::create_path>,
                     EraseOpLowering<dmaphop::alloc_buffer>,
                     EraseOpLowering<dmaphop::sync>,
                     EraseOpLowering<dmaphop::dealloc_buffer>>(context);
        
        patterns.add<PartitionTensorConversion>(context, configOp);
        patterns.add<PushOpConversion>(context, configOp);
        patterns.add<PullOpConversion>(context, configOp);

        if (failed(applyPartialConversion(execOp, target, std::move(patterns)))) {
            signalPassFailure();
        }

        execOp.erase();
    }
    */
}

std::unique_ptr<Pass> createDmaphopTodfscheblueprintPass() {
    return std::make_unique<DmaphopTodfscheblueprintPass>();
}

} // namespace mlir
