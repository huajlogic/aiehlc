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

using namespace mlir;
using namespace dmaphop;
using namespace dfscheblueprint;
using namespace routing;

namespace mlir {

// Helper to process pull (Gather)
void processPull(dmaphop::pull op, OpBuilder &builder, dfscheblueprint::ConfigOp configOp, Value viewHandle) {
    // 1. Identify Sources
    auto inputPorts = op.getOutputPorts();
    SmallVector<Attribute> sourceTiles;
    int64_t sourceChannel = -1;
    
    for (auto portValue : inputPorts) {
        if (auto port = dyn_cast_or_null<dmaphop::port>(portValue.getDefiningOp())) {
            sourceChannel = static_cast<int64_t>(port.getDirectionChannel().value());
            auto tileValue = port.getTile();
            if (auto tileOp = dyn_cast_or_null<dmaphop::tile>(tileValue.getDefiningOp())) {
                sourceTiles.push_back(builder.getArrayAttr({
                    builder.getI64IntegerAttr(tileOp.getCol()),
                    builder.getI64IntegerAttr(tileOp.getRow())
                }));
            }
        }
    }
    
    std::string srcGroupName = "group_src_" + std::to_string((uintptr_t)op.getOperation());
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        srcGroupName,
        builder.getArrayAttr(sourceTiles)
    );
    
    // 2. Identify Destination
    auto pathValue = op.getPath();
    int64_t destChannel = -1;
    SmallVector<Attribute> destTiles;
    
    if (auto pathOp = dyn_cast_or_null<dmaphop::create_path>(pathValue.getDefiningOp())) {
        auto consumersAttr = pathOp.getConsumers();
        if (auto arrayAttr = dyn_cast<ArrayAttr>(consumersAttr)) {
            if (arrayAttr.size() > 0) {
                if (auto innerArray = dyn_cast<ArrayAttr>(arrayAttr[0])) {
                    if (innerArray.size() > 0) {
                        auto symbolRef = dyn_cast<FlatSymbolRefAttr>(innerArray[0]);
                        if (symbolRef) {
                            auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                            if (port) {
                                destChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                                auto tileOp = dyn_cast<dmaphop::tile>(port.getTile().getDefiningOp());
                                destTiles.push_back(builder.getArrayAttr({
                                    builder.getI64IntegerAttr(tileOp.getCol()),
                                    builder.getI64IntegerAttr(tileOp.getRow())
                                }));
                            }
                        }
                    }
                }
            }
        }
    }
    
    std::string dstGroupName = "group_dst_" + std::to_string((uintptr_t)op.getOperation());
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        dstGroupName,
        builder.getArrayAttr(destTiles)
    );
    
    // 3. Create Binds
    std::string srcBindName = "bind_src_" + std::to_string((uintptr_t)op.getOperation());
    builder.create<dfscheblueprint::BindGroupOp>(
        op.getLoc(),
        srcBindName,
        FlatSymbolRefAttr::get(builder.getContext(), srcGroupName),
        viewHandle,
        builder.getStringAttr("linear"),
        dfscheblueprint::DMAAttr::get(builder.getContext(), ArrayRef<int64_t>({sourceChannel}), dfscheblueprint::bp_direction::MM2S),
        builder.getArrayAttr({}) 
    );
    
    std::string dstBindName = "bind_dst_" + std::to_string((uintptr_t)op.getOperation());
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
        "transfer_" + std::to_string((uintptr_t)op.getOperation()),
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
    
    if (auto pathOp = dyn_cast_or_null<dmaphop::create_path>(pathValue.getDefiningOp())) {
        // Producers
        auto producersAttr = pathOp.getProducers();
        if (auto arrayAttr = dyn_cast<ArrayAttr>(producersAttr)) {
             if (arrayAttr.size() > 0) {
                if (auto innerArray = dyn_cast<ArrayAttr>(arrayAttr[0])) {
                    if (innerArray.size() > 0) {
                        auto symbolRef = dyn_cast<FlatSymbolRefAttr>(innerArray[0]);
                        if (symbolRef) {
                            auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                            if (port) {
                                srcChannel = static_cast<int64_t>(port.getDirectionChannel().value());
                                auto tileOp = dyn_cast<dmaphop::tile>(port.getTile().getDefiningOp());
                                srcTiles.push_back(builder.getArrayAttr({
                                    builder.getI64IntegerAttr(tileOp.getCol()),
                                    builder.getI64IntegerAttr(tileOp.getRow())
                                }));
                            }
                        }
                    }
                }
            }
        }
        
        // Consumers (Many)
        // For scatter, consumers are many.
        // But create_path consumers attribute might list them.
        // Or we can look at the hops.
        // Let's assume consumers attribute lists all destination ports.
        auto consumersAttr = pathOp.getConsumers();
        if (auto arrayAttr = dyn_cast<ArrayAttr>(consumersAttr)) {
             if (arrayAttr.size() > 0) {
                if (auto innerArray = dyn_cast<ArrayAttr>(arrayAttr[0])) {
                    for (auto attr : innerArray) {
                        auto symbolRef = dyn_cast<FlatSymbolRefAttr>(attr);
                        if (symbolRef) {
                            auto port = SymbolTable::lookupNearestSymbolFrom<dmaphop::port>(op, symbolRef);
                            if (port) {
                                dstChannel = static_cast<int64_t>(port.getDirectionChannel().value()); // Assuming same channel
                                auto tileOp = dyn_cast<dmaphop::tile>(port.getTile().getDefiningOp());
                                dstTiles.push_back(builder.getArrayAttr({
                                    builder.getI64IntegerAttr(tileOp.getCol()),
                                    builder.getI64IntegerAttr(tileOp.getRow())
                                }));
                            }
                        }
                    }
                }
            }
        }
    }
    
    std::string srcGroupName = "group_src_" + std::to_string((uintptr_t)op.getOperation());
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        srcGroupName,
        builder.getArrayAttr(srcTiles)
    );
    
    std::string dstGroupName = "group_dst_" + std::to_string((uintptr_t)op.getOperation());
    builder.create<dfscheblueprint::ResourceGroupOp>(
        op.getLoc(),
        dstGroupName,
        builder.getArrayAttr(dstTiles)
    );
    
    // Binds
    std::string srcBindName = "bind_src_" + std::to_string((uintptr_t)op.getOperation());
    builder.create<dfscheblueprint::BindOp>(
        op.getLoc(),
        srcBindName,
        FlatSymbolRefAttr::get(builder.getContext(), srcGroupName),
        viewHandle,
        builder.getStringAttr("root"),
        dfscheblueprint::DMAAttr::get(builder.getContext(), ArrayRef<int64_t>({srcChannel}), dfscheblueprint::bp_direction::MM2S),
        nullptr // slice_symbol
    );
    
    std::string dstBindName = "bind_dst_" + std::to_string((uintptr_t)op.getOperation());
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
        "transfer_" + std::to_string((uintptr_t)op.getOperation()),
        "one_to_many",
        FlatSymbolRefAttr::get(builder.getContext(), srcBindName),
        FlatSymbolRefAttr::get(builder.getContext(), dstBindName),
        builder.getStringAttr(""),
        0
    );
}

void DmaphopTodfscheblueprintPass::runOnOperation() {
    auto module = getOperation();
    OpBuilder builder(module->getContext());
    
    module->walk([&](scf::ExecuteRegionOp execOp) {
        bool hasDmapHop = false;
        execOp.walk([&](Operation *op) {
            if (op->getDialect()->getNamespace() == "dmaphop") {
                hasDmapHop = true;
                return WalkResult::interrupt();
            }
            return WalkResult::advance();
        });
        
        if (!hasDmapHop) return;

        builder.setInsertionPoint(execOp);
        auto configOp = builder.create<dfscheblueprint::ConfigOp>(
            execOp.getLoc(), 
            builder.getStringAttr("broadcast_gather_blueprint")
        );
        
        Block *configBody = builder.createBlock(&configOp.getRegion());
        builder.setInsertionPointToStart(configBody);

        // 1. Handle Routing/Tensor setup (to get view handle)
        Value viewHandle;
        routing::partitiontensor partitionOp;
        execOp.walk([&](routing::partitiontensor op) {
            partitionOp = op;
        });

        if (partitionOp) {
            auto tensorDef = partitionOp.getTensor().getDefiningOp();
            if (auto dummyOp = dyn_cast_or_null<routing::createdummytensor>(tensorDef)) {
                auto newDummy = builder.clone(*dummyOp);
                auto newPartition = builder.clone(*partitionOp);
                newPartition->setOperand(0, newDummy->getResult(0));
                
                routing::extract_data extractOp;
                execOp.walk([&](routing::extract_data op) {
                    extractOp = op;
                });
                
                if (extractOp) {
                    auto c0 = builder.create<arith::ConstantOp>(
                        execOp.getLoc(), 
                        builder.getI32IntegerAttr(0)
                    );
                    auto newExtract = builder.create<routing::extract_data>(
                        extractOp.getLoc(),
                        extractOp.getType(),
                        newPartition->getResult(0),
                        c0
                    );
                    auto schedExtract = builder.create<dfscheblueprint::ExtractOp>(
                        extractOp.getLoc(),
                        dfscheblueprint::ViewHandleType::get(builder.getContext()),
                        newExtract.getResult()
                    );
                    schedExtract->setAttr("index", builder.getI64IntegerAttr(0));
                    viewHandle = schedExtract.getResult();
                    
                    // Create Data Slices (simplified)
                    int64_t splitNum = partitionOp.getSplitnum();
                    int64_t sliceRows = 4;
                    int64_t sliceCols = 256;
                    for (int i = 0; i < splitNum; ++i) {
                        std::string name = "out_slice_" + std::to_string(i);
                        auto nameAttr = builder.getStringAttr(name);
                        SmallVector<int64_t> offset = {i * sliceRows, 0};
                        SmallVector<int64_t> size = {sliceRows, sliceCols};
                        SmallVector<int64_t> stride = {sliceCols, 1};
                        auto sliceType = MemRefType::get({sliceRows, sliceCols}, builder.getF32Type());
                        auto sliceAttr = dfscheblueprint::SliceAttr::get(
                            builder.getContext(),
                            TypeAttr::get(sliceType),
                            builder.getI64ArrayAttr(offset),
                            builder.getI64ArrayAttr(size),
                            builder.getI64ArrayAttr(stride)
                        );
                        builder.create<dfscheblueprint::DataSliceOp>(
                            execOp.getLoc(),
                            nameAttr,
                            viewHandle,
                            sliceAttr
                        );
                    }
                }
            }
        }
        
        // 2. Process Push/Pull
        execOp.walk([&](Operation *op) {
            if (auto pull = dyn_cast<dmaphop::pull>(op)) {
                processPull(pull, builder, configOp, viewHandle);
            } else if (auto pushOp = dyn_cast<dmaphop::push>(op)) {
                processPush(pushOp, builder, configOp, viewHandle);
            }
        });
        
        // 3. Erase dmaphop ops
        SmallVector<Operation*> toErase;
        execOp.walk([&](Operation *op) {
            if (op->getDialect()->getNamespace() == "dmaphop") {
                toErase.push_back(op);
            }
        });
        for (auto op : llvm::reverse(toErase)) {
            op->erase();
        }
        
        execOp.erase();
    });
}

std::unique_ptr<Pass> createDmaphopTodfscheblueprintPass() {
    return std::make_unique<DmaphopTodfscheblueprintPass>();
}

} // namespace mlir
