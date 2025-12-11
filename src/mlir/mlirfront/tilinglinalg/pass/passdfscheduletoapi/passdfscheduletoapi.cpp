/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "passdfscheduletoapi.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/Transforms/DialectConversion.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"
#include <iostream>
#include <sstream>

using namespace mlir;

namespace mlir {

//===----------------------------------------------------------------------===//
// Helper Functions
//===----------------------------------------------------------------------===//

static std::string getEmitCTypeString(Type elemType) {
    if (elemType.isInteger(8)) return "int8_t";
    if (elemType.isInteger(16)) return "int16_t";
    if (elemType.isInteger(32)) return "int32_t";
    if (elemType.isInteger(64)) return "int64_t";
    if (elemType.isF32()) return "float";
    if (elemType.isF64()) return "double";
    return "uint8_t";
}

static std::string buildArrayDimString(ArrayRef<int64_t> shape) {
    std::string result;
    for (auto dim : shape) {
        result += "[" + std::to_string(dim) + "]";
    }
    return result;
}

static std::string buildInitializerString(DenseElementsAttr denseAttr, Type elemType) {
    std::ostringstream initStream;
    initStream << "{";
    bool first = true;
    
    if (elemType.isInteger(8)) {
        for (auto val : denseAttr.getValues<int8_t>()) {
            if (!first) initStream << ", ";
            first = false;
            initStream << static_cast<int>(val);
        }
    } else if (elemType.isInteger(16)) {
        for (auto val : denseAttr.getValues<int16_t>()) {
            if (!first) initStream << ", ";
            first = false;
            initStream << val;
        }
    } else if (elemType.isInteger(32)) {
        for (auto val : denseAttr.getValues<int32_t>()) {
            if (!first) initStream << ", ";
            first = false;
            initStream << val;
        }
    } else if (elemType.isInteger(64)) {
        for (auto val : denseAttr.getValues<int64_t>()) {
            if (!first) initStream << ", ";
            first = false;
            initStream << val;
        }
    } else if (elemType.isF32()) {
        for (auto val : denseAttr.getValues<APFloat>()) {
            if (!first) initStream << ", ";
            first = false;
            initStream << val.convertToFloat();
        }
    } else if (elemType.isF64()) {
        for (auto val : denseAttr.getValues<APFloat>()) {
            if (!first) initStream << ", ";
            first = false;
            initStream << val.convertToDouble();
        }
    }
    initStream << "}";
    return initStream.str();
}

static int64_t getElemSize(Type elemType) {
    if (elemType.isInteger(8)) return 1;
    if (elemType.isInteger(16)) return 2;
    if (elemType.isInteger(32) || elemType.isF32()) return 4;
    if (elemType.isInteger(64) || elemType.isF64()) return 8;
    return 1;
}

//===----------------------------------------------------------------------===//
// Shared State for Conversion Patterns
//===----------------------------------------------------------------------===//

struct ConversionState {
    DenseMap<Value, std::tuple<Value, int64_t, int64_t>> memAllocMap;
    SmallVector<Value> allocatedMemList;
    DenseMap<Operation*, std::string> arrayNameMap;
    int arrayIndex = 0;
    int partitionIndex = 0;
};

//===----------------------------------------------------------------------===//
// Conversion Patterns using OpConversionPattern
//===----------------------------------------------------------------------===//

/// OpConversionPattern for arith.constant with DenseElementsAttr -> emitc.verbatim
struct DenseConstantToEmitCPattern : public OpConversionPattern<arith::ConstantOp> {
    ConversionState &state;
    
    DenseConstantToEmitCPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<arith::ConstantOp>(typeConverter, ctx, /*benefit=*/10), state(state) {}
    
    LogicalResult matchAndRewrite(arith::ConstantOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto denseAttr = dyn_cast<DenseElementsAttr>(op.getValue());
        if (!denseAttr) return failure();
        
        auto tensorType = dyn_cast<RankedTensorType>(denseAttr.getType());
        if (!tensorType) return failure();
        
        if (state.arrayNameMap.count(op.getOperation())) return failure();
        
        std::string arrayName = "g_data_array_" + std::to_string(state.arrayIndex++);
        Type elemType = tensorType.getElementType();
        std::string cTypeStr = getEmitCTypeString(elemType);
        std::string initStr = buildInitializerString(denseAttr, elemType);
        
        std::string verbatimCode = "static const " + cTypeStr + " " + arrayName +
            buildArrayDimString(tensorType.getShape()) + " = " + initStr + ";";
        
        auto moduleOp = op->getParentOfType<ModuleOp>();
        if (!moduleOp) return failure();
        
        OpBuilder::InsertionGuard guard(rewriter);
        rewriter.setInsertionPointToStart(moduleOp.getBody());
        rewriter.create<emitc::VerbatimOp>(op.getLoc(), rewriter.getStringAttr(verbatimCode));
        
        state.arrayNameMap[op.getOperation()] = arrayName;
        llvm::errs() << "[Pattern] Created global array: " << arrayName << "\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// OpConversionPattern for tensor.extract_slice -> EmitC slice extraction
struct ExtractSliceToEmitCPattern : public OpConversionPattern<tensor::ExtractSliceOp> {
    ConversionState &state;
    
    ExtractSliceToEmitCPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<tensor::ExtractSliceOp>(typeConverter, ctx), state(state) {}
    
    LogicalResult matchAndRewrite(tensor::ExtractSliceOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        auto ctx = rewriter.getContext();
        
        auto resultType = dyn_cast<RankedTensorType>(op.getResult().getType());
        auto srcType = dyn_cast<RankedTensorType>(op.getSource().getType());
        if (!resultType || !srcType) return failure();
        
        Value srcTensor = op.getSource();
        
        if (!state.memAllocMap.count(srcTensor)) return failure();
        
        Value srcDataPtr = std::get<0>(state.memAllocMap[srcTensor]);
        
        auto offsets = op.getStaticOffsets();
        auto sizes = op.getStaticSizes();
        auto srcShape = srcType.getShape();
        
        Type elemType = resultType.getElementType();
        int64_t elemSize = getElemSize(elemType);
        
        int64_t sliceElements = 1;
        for (auto s : sizes) sliceElements *= s;
        int64_t sliceByteSize = sliceElements * elemSize;
        
        int64_t byteOffset = 0;
        int64_t stride = elemSize;
        for (int64_t i = srcShape.size() - 1; i >= 0; --i) {
            byteOffset += offsets[i] * stride;
            stride *= srcShape[i];
        }
        
        auto voidPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
        auto i32Type = rewriter.getI32Type();
        
        Value slicePtr;
        if (byteOffset == 0) {
            slicePtr = srcDataPtr;
        } else {
            auto offsetConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
                rewriter.getI32IntegerAttr(byteOffset));
            auto sliceSizeConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
                rewriter.getI32IntegerAttr(sliceByteSize));
            
            auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(loc,
                voidPtrType, "__emitc_extract_slice_contiguous",
                nullptr, nullptr,
                ValueRange{srcDataPtr, offsetConst.getResult(), sliceSizeConst.getResult()});
            slicePtr = sliceOp.getResult(0);
        }
        
        state.memAllocMap[op.getResult()] = std::make_tuple(slicePtr, sliceByteSize, sliceElements);
        llvm::errs() << "[Pattern] Created slice (offset=" << byteOffset << " bytes)\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// ConversionPattern for dfscheblueprint.declare_data (generic by op name)
struct DeclareDataPattern : public ConversionPattern {
    ConversionState &state;
    
    DeclareDataPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : ConversionPattern(typeConverter, "dfscheblueprint.declare_data", /*benefit=*/1, ctx), state(state) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        if (op->getNumResults() == 0) return failure();
        
        auto resultType = dyn_cast<RankedTensorType>(op->getResult(0).getType());
        if (!resultType) return failure();
        
        auto loc = op->getLoc();
        auto ctx = rewriter.getContext();
        
        std::string arrayName = "g_data_array_0";
        if (op->getNumOperands() > 0) {
            Value initTensor = op->getOperand(0);
            if (Operation *initOp = initTensor.getDefiningOp()) {
                if (state.arrayNameMap.count(initOp)) {
                    arrayName = state.arrayNameMap[initOp];
                }
            }
        }
        
        int64_t totalElements = 1;
        for (auto dim : resultType.getShape()) {
            totalElements *= dim;
        }
        
        Type elemType = resultType.getElementType();
        int64_t elemSize = getElemSize(elemType);
        int64_t byteSize = totalElements * elemSize;
        
        auto i32Type = rewriter.getI32Type();
        auto voidPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
        auto memInstPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "XAie_MemInst"));
        auto devInstType = emitc::OpaqueType::get(ctx, "XAie_DevInst");
        
        auto devInstRef = rewriter.create<emitc::GetGlobalOp>(loc, devInstType, "DevInst");
        auto sizeConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            rewriter.getI32IntegerAttr(byteSize));
        auto cacheableConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            emitc::OpaqueAttr::get(ctx, "XAIE_MEM_CACHEABLE"));
        
        auto memInst = rewriter.create<emitc::CallOpaqueOp>(loc,
            memInstPtrType, "XAie_MemAllocate",
            nullptr, nullptr,
            ValueRange{devInstRef.getResult(), sizeConst.getResult(), cacheableConst.getResult()});
        
        auto vaddr = rewriter.create<emitc::CallOpaqueOp>(loc,
            voidPtrType, "XAie_MemGetVAddr",
            nullptr, nullptr, ValueRange{memInst.getResult(0)});
        
        auto srcPtr = rewriter.create<emitc::ConstantOp>(loc, voidPtrType,
            emitc::OpaqueAttr::get(ctx, "(void*)" + arrayName));
        
        rewriter.create<emitc::CallOpaqueOp>(loc,
            voidPtrType, "memcpy",
            nullptr, nullptr,
            ValueRange{vaddr.getResult(0), srcPtr.getResult(), sizeConst.getResult()});
        
        state.memAllocMap[op->getResult(0)] = std::make_tuple(vaddr.getResult(0), byteSize, totalElements);
        llvm::errs() << "[Pattern] Generated XAie_MemAllocate for " << arrayName << "\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// ConversionPattern for routing.partitiontensor
struct PartitionTensorPattern : public ConversionPattern {
    ConversionState &state;
    
    PartitionTensorPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : ConversionPattern(typeConverter, "routing.partitiontensor", /*benefit=*/1, ctx), state(state) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        if (op->getNumResults() == 0 || op->getNumOperands() == 0) return failure();
        
        auto resultType = dyn_cast<RankedTensorType>(op->getResult(0).getType());
        if (!resultType) return failure();
        
        auto loc = op->getLoc();
        auto ctx = rewriter.getContext();
        
        Value inputTensor = op->getOperand(0);
        
        int splitnum = 1, splitdim = 0;
        if (auto attr = op->getAttrOfType<IntegerAttr>("splitnum")) {
            splitnum = attr.getInt();
        }
        if (auto attr = op->getAttrOfType<IntegerAttr>("splitdim")) {
            splitdim = attr.getInt();
        }
        
        int64_t totalElements = 1;
        for (auto dim : resultType.getShape()) {
            totalElements *= dim;
        }
        
        Type elemType = resultType.getElementType();
        int64_t elemSize = getElemSize(elemType);
        int64_t partitionByteSize = totalElements * elemSize;
        
        Value srcDataPtr;
        if (state.memAllocMap.count(inputTensor)) {
            srcDataPtr = std::get<0>(state.memAllocMap[inputTensor]);
        }
        
        auto i32Type = rewriter.getI32Type();
        auto voidPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
        
        Value dataVoidPtr = srcDataPtr ? srcDataPtr :
            rewriter.create<emitc::ConstantOp>(loc, voidPtrType,
                emitc::OpaqueAttr::get(ctx, "NULL")).getResult();
        
        auto sizeConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            rewriter.getI32IntegerAttr(partitionByteSize));
        auto numElemsConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            rewriter.getI32IntegerAttr(totalElements));
        auto splitnumConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            rewriter.getI32IntegerAttr(splitnum));
        auto splitdimConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            rewriter.getI32IntegerAttr(splitdim));
        
        auto partitionType = emitc::OpaqueType::get(ctx, "PartitionTensor");
        rewriter.create<emitc::CallOpaqueOp>(loc,
            partitionType, "__emitc_init_PartitionTensor",
            nullptr, nullptr,
            ValueRange{dataVoidPtr, sizeConst.getResult(), numElemsConst.getResult(),
                       splitnumConst.getResult(), splitdimConst.getResult()});
        
        if (srcDataPtr) {
            state.memAllocMap[op->getResult(0)] = std::make_tuple(srcDataPtr, partitionByteSize, totalElements);
        }
        
        llvm::errs() << "[Pattern] Created PartitionTensor: partition_" << state.partitionIndex++ << "\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// ConversionPattern for dfschedule.host -> emitc.func
/// This pattern has low benefit so inner patterns are applied first
struct HostOpPattern : public ConversionPattern {
    ConversionState &state;
    
    HostOpPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : ConversionPattern(typeConverter, "dfschedule.host", /*benefit=*/0, ctx), state(state) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op->getLoc();
        auto ctx = rewriter.getContext();
        
        std::string funcName = "hostruntime";
        if (auto symNameAttr = op->getAttrOfType<StringAttr>("sym_name")) {
            funcName = symNameAttr.getValue().str();
        }
        
        auto funcType = rewriter.getFunctionType({}, {});
        auto emitcFunc = rewriter.create<emitc::FuncOp>(loc, funcName, funcType);
        Block *entryBlock = emitcFunc.addEntryBlock();
        
        OpBuilder::InsertionGuard guard(rewriter);
        rewriter.setInsertionPointToStart(entryBlock);
        
        // Process nested operations and convert them inline
        auto i32Type = rewriter.getI32Type();
        auto voidPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
        auto memInstPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "XAie_MemInst"));
        auto devInstType = emitc::OpaqueType::get(ctx, "XAie_DevInst");
        
        auto devInstRef = rewriter.create<emitc::GetGlobalOp>(loc, devInstType, "DevInst");
        auto cacheableConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            emitc::OpaqueAttr::get(ctx, "XAIE_MEM_CACHEABLE"));
        
        if (op->getNumRegions() > 0 && !op->getRegion(0).empty()) {
            Block &srcBlock = op->getRegion(0).front();
            
            for (Operation &nestedOp : srcBlock.getOperations()) {
                StringRef nestedOpName = nestedOp.getName().getStringRef();
                auto nestedLoc = nestedOp.getLoc();
                
                // Convert dfscheblueprint.declare_data inline
                if (nestedOpName == "dfscheblueprint.declare_data") {
                    if (nestedOp.getNumResults() == 0) continue;
                    
                    auto resultType = dyn_cast<RankedTensorType>(nestedOp.getResult(0).getType());
                    if (!resultType) continue;
                    
                    std::string arrayName = "g_data_array_0";
                    if (nestedOp.getNumOperands() > 0) {
                        if (Operation *initOp = nestedOp.getOperand(0).getDefiningOp()) {
                            if (state.arrayNameMap.count(initOp)) {
                                arrayName = state.arrayNameMap[initOp];
                            }
                        }
                    }
                    
                    int64_t totalElements = 1;
                    for (auto dim : resultType.getShape()) totalElements *= dim;
                    
                    Type elemType = resultType.getElementType();
                    int64_t byteSize = totalElements * getElemSize(elemType);
                    
                    auto sizeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(byteSize));
                    
                    auto memInst = rewriter.create<emitc::CallOpaqueOp>(nestedLoc,
                        memInstPtrType, "XAie_MemAllocate", nullptr, nullptr,
                        ValueRange{devInstRef.getResult(), sizeConst.getResult(), cacheableConst.getResult()});
                    
                    auto vaddr = rewriter.create<emitc::CallOpaqueOp>(nestedLoc,
                        voidPtrType, "XAie_MemGetVAddr", nullptr, nullptr,
                        ValueRange{memInst.getResult(0)});
                    
                    auto srcPtr = rewriter.create<emitc::ConstantOp>(nestedLoc, voidPtrType,
                        emitc::OpaqueAttr::get(ctx, "(void*)" + arrayName));
                    
                    rewriter.create<emitc::CallOpaqueOp>(nestedLoc, voidPtrType, "memcpy",
                        nullptr, nullptr,
                        ValueRange{vaddr.getResult(0), srcPtr.getResult(), sizeConst.getResult()});
                    
                    state.memAllocMap[nestedOp.getResult(0)] = std::make_tuple(vaddr.getResult(0), byteSize, totalElements);
                    llvm::errs() << "[Pattern] Host: XAie_MemAllocate for " << arrayName << "\n";
                }
                
                // Convert routing.partitiontensor inline
                if (nestedOpName == "routing.partitiontensor") {
                    if (nestedOp.getNumResults() == 0 || nestedOp.getNumOperands() == 0) continue;
                    
                    auto resultType = dyn_cast<RankedTensorType>(nestedOp.getResult(0).getType());
                    if (!resultType) continue;
                    
                    Value inputTensor = nestedOp.getOperand(0);
                    
                    int splitnum = 1, splitdim = 0;
                    if (auto attr = nestedOp.getAttrOfType<IntegerAttr>("splitnum")) splitnum = attr.getInt();
                    if (auto attr = nestedOp.getAttrOfType<IntegerAttr>("splitdim")) splitdim = attr.getInt();
                    
                    int64_t totalElements = 1;
                    for (auto dim : resultType.getShape()) totalElements *= dim;
                    
                    int64_t partitionByteSize = totalElements * getElemSize(resultType.getElementType());
                    
                    Value srcDataPtr;
                    if (state.memAllocMap.count(inputTensor)) {
                        srcDataPtr = std::get<0>(state.memAllocMap[inputTensor]);
                    }
                    
                    Value dataVoidPtr = srcDataPtr ? srcDataPtr :
                        rewriter.create<emitc::ConstantOp>(nestedLoc, voidPtrType,
                            emitc::OpaqueAttr::get(ctx, "NULL")).getResult();
                    
                    auto sizeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(partitionByteSize));
                    auto numElemsConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(totalElements));
                    auto splitnumConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(splitnum));
                    auto splitdimConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(splitdim));
                    
                    auto partitionType = emitc::OpaqueType::get(ctx, "PartitionTensor");
                    rewriter.create<emitc::CallOpaqueOp>(nestedLoc, partitionType,
                        "__emitc_init_PartitionTensor", nullptr, nullptr,
                        ValueRange{dataVoidPtr, sizeConst.getResult(), numElemsConst.getResult(),
                                   splitnumConst.getResult(), splitdimConst.getResult()});
                    
                    if (srcDataPtr) {
                        state.memAllocMap[nestedOp.getResult(0)] = std::make_tuple(srcDataPtr, partitionByteSize, totalElements);
                    }
                    llvm::errs() << "[Pattern] Host: PartitionTensor created\n";
                }
                
                // Convert tensor.extract_slice inline
                if (nestedOpName == "tensor.extract_slice") {
                    if (nestedOp.getNumResults() == 0 || nestedOp.getNumOperands() == 0) continue;
                    
                    auto resultType = dyn_cast<RankedTensorType>(nestedOp.getResult(0).getType());
                    auto srcType = dyn_cast<RankedTensorType>(nestedOp.getOperand(0).getType());
                    if (!resultType || !srcType) continue;
                    
                    Value srcTensor = nestedOp.getOperand(0);
                    if (!state.memAllocMap.count(srcTensor)) continue;
                    
                    Value srcDataPtr = std::get<0>(state.memAllocMap[srcTensor]);
                    
                    auto staticOffsetsAttr = nestedOp.getAttrOfType<DenseI64ArrayAttr>("static_offsets");
                    auto staticSizesAttr = nestedOp.getAttrOfType<DenseI64ArrayAttr>("static_sizes");
                    if (!staticOffsetsAttr || !staticSizesAttr) continue;
                    
                    auto offsets = staticOffsetsAttr.asArrayRef();
                    auto sizes = staticSizesAttr.asArrayRef();
                    auto srcShape = srcType.getShape();
                    
                    int64_t elemSize = getElemSize(resultType.getElementType());
                    int64_t sliceElements = 1;
                    for (auto s : sizes) sliceElements *= s;
                    int64_t sliceByteSize = sliceElements * elemSize;
                    
                    int64_t byteOffset = 0;
                    int64_t stride = elemSize;
                    for (int64_t i = srcShape.size() - 1; i >= 0; --i) {
                        byteOffset += offsets[i] * stride;
                        stride *= srcShape[i];
                    }
                    
                    Value slicePtr;
                    if (byteOffset == 0) {
                        slicePtr = srcDataPtr;
                    } else {
                        auto offsetConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                            rewriter.getI32IntegerAttr(byteOffset));
                        auto sliceSizeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                            rewriter.getI32IntegerAttr(sliceByteSize));
                        
                        auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(nestedLoc, voidPtrType,
                            "__emitc_extract_slice_contiguous", nullptr, nullptr,
                            ValueRange{srcDataPtr, offsetConst.getResult(), sliceSizeConst.getResult()});
                        slicePtr = sliceOp.getResult(0);
                    }
                    
                    state.memAllocMap[nestedOp.getResult(0)] = std::make_tuple(slicePtr, sliceByteSize, sliceElements);
                    llvm::errs() << "[Pattern] Host: slice (offset=" << byteOffset << ")\n";
                }
            }
        }
        
        rewriter.setInsertionPointToEnd(entryBlock);
        rewriter.create<emitc::ReturnOp>(loc, Value{});
        
        llvm::errs() << "[Pattern] Created emitc.func: " << funcName << "\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// ConversionPattern for dfschedule.launchhost -> emitc.call_opaque
struct LaunchHostPattern : public ConversionPattern {
    LaunchHostPattern(TypeConverter &typeConverter, MLIRContext *ctx)
        : ConversionPattern(typeConverter, "dfschedule.launchhost", /*benefit=*/1, ctx) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.create<emitc::CallOpaqueOp>(op->getLoc(),
            TypeRange{}, "hostruntime", nullptr, nullptr, ValueRange{});
        
        llvm::errs() << "[Pattern] Created hostruntime() call\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// ConversionPattern for dfschedule.dskernel_receiver -> emitc.func with __global__
struct DsKernelReceiverPattern : public ConversionPattern {
    DsKernelReceiverPattern(TypeConverter &typeConverter, MLIRContext *ctx)
        : ConversionPattern(typeConverter, "dfschedule.dskernel_receiver", /*benefit=*/1, ctx) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op->getLoc();
        
        std::string kernelName = "dskernel";
        if (auto symNameAttr = op->getAttrOfType<StringAttr>("sym_name")) {
            kernelName = symNameAttr.getValue().str();
        }
        
        auto funcType = rewriter.getFunctionType({}, {});
        auto emitcFunc = rewriter.create<emitc::FuncOp>(loc, kernelName, funcType);
        emitcFunc->setAttr("specifiers", rewriter.getStrArrayAttr({"__global__"}));
        
        Block *entryBlock = emitcFunc.addEntryBlock();
        OpBuilder::InsertionGuard guard(rewriter);
        rewriter.setInsertionPointToStart(entryBlock);
        rewriter.create<emitc::VerbatimOp>(loc, rewriter.getStringAttr("/* AIE kernel implementation */"));
        rewriter.create<emitc::ReturnOp>(loc, Value{});
        
        llvm::errs() << "[Pattern] Created __global__ func: " << kernelName << "\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

//===----------------------------------------------------------------------===//
// Pass Implementation - Using ConversionPattern with applyPartialConversion
//===----------------------------------------------------------------------===//

void DfscheduleToApiPass::runOnOperation() {
    llvm::errs() << "=== DfscheduleToApiPass START ===\n";
    
    ModuleOp moduleOp = getOperation();
    MLIRContext *ctx = moduleOp.getContext();
    
    // Shared conversion state
    ConversionState state;
    
    // Type converter (identity for now, can be extended)
    TypeConverter typeConverter;
    typeConverter.addConversion([](Type type) { return type; });
    
    //==========================================================================
    // Phase 1: Setup - Generate helper definitions at module scope
    //==========================================================================
    
    {
        OpBuilder builder(ctx);
        builder.setInsertionPointToStart(moduleOp.getBody());
        
        builder.create<emitc::VerbatimOp>(moduleOp.getLoc(), builder.getStringAttr(
            "/* PartitionTensor structure for memory management */\n"
            "typedef struct {\n"
            "    void* data;\n"
            "    size_t size;\n"
            "    size_t num_elements;\n"
            "    int splitnum;\n"
            "    int splitdim;\n"
            "} PartitionTensor;\n\n"
            "/* Helper function for PartitionTensor initialization */\n"
            "static inline PartitionTensor __emitc_init_PartitionTensor(\n"
            "    void* data, size_t size, size_t num_elements, int splitnum, int splitdim) {\n"
            "    PartitionTensor pt = {data, size, num_elements, splitnum, splitdim};\n"
            "    return pt;\n"
            "}\n\n"
            "/* Helper function for contiguous slice extraction */\n"
            "static inline void* __emitc_extract_slice_contiguous(\n"
            "    void* src_ptr, int byte_offset, int slice_byte_size) {\n"
            "    return (void*)((char*)src_ptr + byte_offset);\n"
            "}\n\n"
            "/* Helper function for 2D non-contiguous slice extraction */\n"
            "static inline void __emitc_extract_slice_2d(\n"
            "    void* dst, void* src, int elem_size,\n"
            "    int src_dim0, int src_dim1,\n"
            "    int off0, int off1,\n"
            "    int size0, int size1) {\n"
            "    char* d = (char*)dst;\n"
            "    char* s = (char*)src;\n"
            "    for (int i = 0; i < size0; i++) {\n"
            "        int src_idx = ((off0 + i) * src_dim1 + off1) * elem_size;\n"
            "        int dst_idx = (i * size1) * elem_size;\n"
            "        memcpy(d + dst_idx, s + src_idx, size1 * elem_size);\n"
            "    }\n"
            "}"
        ));
        
        auto devInstType = emitc::OpaqueType::get(ctx, "XAie_DevInst");
        builder.create<emitc::GlobalOp>(moduleOp.getLoc(),
            "DevInst", devInstType, Attribute{}, true, false, false);
    }
    
    //==========================================================================
    // Phase 2: Apply conversion patterns using applyPartialConversion
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 2: Applying conversion patterns\n";
    
    // Setup conversion target
    ConversionTarget target(*ctx);
    target.addLegalDialect<emitc::EmitCDialect, func::FuncDialect, scf::SCFDialect>();
    target.addLegalOp<ModuleOp>();
    
    // Mark custom dialect ops as illegal
    target.addDynamicallyLegalOp<arith::ConstantOp>([](arith::ConstantOp op) {
        // Illegal if it has DenseElementsAttr (needs conversion)
        return !isa<DenseElementsAttr>(op.getValue());
    });
    target.addIllegalOp<tensor::ExtractSliceOp>();
    
    // Mark operations by name as illegal
    target.markUnknownOpDynamicallyLegal([](Operation *op) {
        StringRef opName = op->getName().getStringRef();
        if (opName.starts_with("dfschedule.") ||
            opName.starts_with("dfscheblueprint.") ||
            opName.starts_with("routing.")) {
            return false; // illegal
        }
        return true; // legal
    });
    
    // Create patterns - HostOpPattern handles nested ops inline
    RewritePatternSet patterns(ctx);
    patterns.add<DenseConstantToEmitCPattern>(typeConverter, ctx, state);
    patterns.add<HostOpPattern>(typeConverter, ctx, state);
    patterns.add<LaunchHostPattern>(typeConverter, ctx);
    patterns.add<DsKernelReceiverPattern>(typeConverter, ctx);
    
    // Apply partial conversion
    if (failed(applyPartialConversion(moduleOp, target, std::move(patterns)))) {
        llvm::errs() << "[Pass] Warning: Partial conversion had failures\n";
        // Don't signal failure - some ops may remain intentionally
    }
    
    //==========================================================================
    // Phase 3: Apply canonicalization to optimize EmitC
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 3: Applying canonicalization patterns\n";
    
    {
        RewritePatternSet canonPatterns(ctx);
        for (auto *dialect : ctx->getLoadedDialects()) {
            dialect->getCanonicalizationPatterns(canonPatterns);
        }
        for (RegisteredOperationName op : ctx->getRegisteredOperations()) {
            op.getCanonicalizationPatterns(canonPatterns, ctx);
        }
        
        if (failed(applyPatternsAndFoldGreedily(moduleOp, std::move(canonPatterns)))) {
            llvm::errs() << "[Pass] Warning: Canonicalization had issues\n";
        }
    }
    
    llvm::errs() << "=== DfscheduleToApiPass SUCCESS ===\n";
}

} // namespace mlir
