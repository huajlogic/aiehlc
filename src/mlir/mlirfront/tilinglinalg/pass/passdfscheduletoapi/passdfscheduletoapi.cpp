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
    // Maps MLIR Value to (PartitionTensor SSA Value, byte size, num elements)
    DenseMap<Value, std::tuple<Value, int64_t, int64_t>> memAllocMap;
    // Also track the raw data pointer for cases where we need it
    DenseMap<Value, Value> dataPtrMap;
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
                    
                    auto shape = resultType.getShape();
                    int64_t totalElements = 1;
                    for (auto dim : shape) totalElements *= dim;
                    
                    Type elemType = resultType.getElementType();
                    int64_t elemSize = getElemSize(elemType);
                    int64_t byteSize = totalElements * elemSize;
                    int ndim = shape.size();
                    
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
                    
                    // Build shape array literal
                    std::string shapeStr = "(int64_t[]){";
                    for (size_t i = 0; i < shape.size(); i++) {
                        if (i > 0) shapeStr += ", ";
                        shapeStr += std::to_string(shape[i]);
                    }
                    shapeStr += "}";
                    
                    auto i64PtrType = emitc::PointerType::get(rewriter.getI64Type());
                    auto elemSizeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(elemSize));
                    auto ndimConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(ndim));
                    auto shapeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i64PtrType,
                        emitc::OpaqueAttr::get(ctx, shapeStr));
                    auto partDimConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(-1)); // not partitioned
                    auto numPartConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(1));
                    auto hwAxisConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(0));
                    auto replicateConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(-1));
                    
                    auto partitionType = emitc::OpaqueType::get(ctx, "PartitionTensor");
                    auto initPtOp = rewriter.create<emitc::CallOpaqueOp>(nestedLoc, partitionType,
                        "__emitc_init_PartitionTensor", nullptr, nullptr,
                        ValueRange{vaddr.getResult(0), elemSizeConst.getResult(), ndimConst.getResult(),
                                   shapeConst.getResult(), shapeConst.getResult(),
                                   partDimConst.getResult(), numPartConst.getResult(),
                                   hwAxisConst.getResult(), replicateConst.getResult()});
                    
                    state.memAllocMap[nestedOp.getResult(0)] = std::make_tuple(initPtOp.getResult(0), byteSize, totalElements);
                    state.dataPtrMap[nestedOp.getResult(0)] = vaddr.getResult(0);
                    llvm::errs() << "[Pattern] Host: XAie_MemAllocate for " << arrayName << " -> PartitionTensor\n";
                }
                
                // Convert routing.partitiontensor inline
                if (nestedOpName == "routing.partitiontensor") {
                    if (nestedOp.getNumResults() == 0 || nestedOp.getNumOperands() == 0) continue;
                    
                    auto resultType = dyn_cast<RankedTensorType>(nestedOp.getResult(0).getType());
                    auto inputType = dyn_cast<RankedTensorType>(nestedOp.getOperand(0).getType());
                    if (!resultType || !inputType) continue;
                    
                    Value inputTensor = nestedOp.getOperand(0);
                    
                    // Get partition attributes
                    int splitnum = 1, splitdim = 0;
                    if (auto attr = nestedOp.getAttrOfType<IntegerAttr>("splitnum")) splitnum = attr.getInt();
                    if (auto attr = nestedOp.getAttrOfType<IntegerAttr>("splitdim")) splitdim = attr.getInt();
                    
                    // Get hw_axis_owner and replicate_on (convert string to int)
                    int hwAxisOwner = 0; // 0=row, 1=col
                    int replicateOn = -1; // -1=none, 0=row, 1=col
                    if (auto attr = nestedOp.getAttrOfType<StringAttr>("hw_axis_owner")) {
                        hwAxisOwner = (attr.getValue() == "col") ? 1 : 0;
                    }
                    if (auto attr = nestedOp.getAttrOfType<StringAttr>("replicate_on")) {
                        if (attr.getValue() == "col") replicateOn = 1;
                        else if (attr.getValue() == "row") replicateOn = 0;
                    }
                    
                    // Get original and partition shapes
                    auto originalShape = inputType.getShape();
                    auto partitionShape = resultType.getShape();
                    int ndim = originalShape.size();
                    
                    int64_t totalElements = 1;
                    for (auto dim : partitionShape) totalElements *= dim;
                    
                    int64_t elemSize = getElemSize(resultType.getElementType());
                    int64_t partitionByteSize = totalElements * elemSize;
                    
                    // Get data pointer from source (dataPtrMap stores the raw void*)
                    Value dataVoidPtr;
                    if (state.dataPtrMap.count(inputTensor)) {
                        dataVoidPtr = state.dataPtrMap[inputTensor];
                    } else {
                        dataVoidPtr = rewriter.create<emitc::ConstantOp>(nestedLoc, voidPtrType,
                            emitc::OpaqueAttr::get(ctx, "NULL")).getResult();
                    }
                    
                    // Build original_shape array literal
                    std::string origShapeStr = "(int64_t[]){";
                    for (size_t i = 0; i < originalShape.size(); i++) {
                        if (i > 0) origShapeStr += ", ";
                        origShapeStr += std::to_string(originalShape[i]);
                    }
                    origShapeStr += "}";
                    
                    // Build partition_shape array literal
                    std::string partShapeStr = "(int64_t[]){";
                    for (size_t i = 0; i < partitionShape.size(); i++) {
                        if (i > 0) partShapeStr += ", ";
                        partShapeStr += std::to_string(partitionShape[i]);
                    }
                    partShapeStr += "}";
                    
                    auto i64PtrType = emitc::PointerType::get(rewriter.getI64Type());
                    
                    auto elemSizeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(elemSize));
                    auto ndimConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(ndim));
                    auto origShapeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i64PtrType,
                        emitc::OpaqueAttr::get(ctx, origShapeStr));
                    auto partShapeConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i64PtrType,
                        emitc::OpaqueAttr::get(ctx, partShapeStr));
                    auto splitdimConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(splitdim));
                    auto splitnumConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(splitnum));
                    auto hwAxisConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(hwAxisOwner));
                    auto replicateConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i32Type,
                        rewriter.getI32IntegerAttr(replicateOn));
                    
                    auto partitionType = emitc::OpaqueType::get(ctx, "PartitionTensor");
                    auto ptOp = rewriter.create<emitc::CallOpaqueOp>(nestedLoc, partitionType,
                        "__emitc_init_PartitionTensor", nullptr, nullptr,
                        ValueRange{dataVoidPtr, elemSizeConst.getResult(), ndimConst.getResult(),
                                   origShapeConst.getResult(), partShapeConst.getResult(),
                                   splitdimConst.getResult(), splitnumConst.getResult(),
                                   hwAxisConst.getResult(), replicateConst.getResult()});
                    
                    state.memAllocMap[nestedOp.getResult(0)] = std::make_tuple(ptOp.getResult(0), partitionByteSize, totalElements);
                    state.dataPtrMap[nestedOp.getResult(0)] = dataVoidPtr;
                    llvm::errs() << "[Pattern] Host: PartitionTensor created (ndim=" << ndim 
                                 << ", splitdim=" << splitdim << ", splitnum=" << splitnum << ")\n";
                }
                
                // Convert tensor.extract_slice inline
                if (nestedOpName == "tensor.extract_slice") {
                    if (nestedOp.getNumResults() == 0 || nestedOp.getNumOperands() == 0) continue;
                    
                    auto resultType = dyn_cast<RankedTensorType>(nestedOp.getResult(0).getType());
                    auto srcType = dyn_cast<RankedTensorType>(nestedOp.getOperand(0).getType());
                    if (!resultType || !srcType) continue;
                    
                    Value srcTensor = nestedOp.getOperand(0);
                    if (!state.memAllocMap.count(srcTensor)) continue;
                    
                    Value srcPartitionTensor = std::get<0>(state.memAllocMap[srcTensor]);
                    
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
                    
                    // Check if slice is contiguous:
                    // A slice is contiguous if inner dimensions are fully covered
                    // (i.e., for 2D: if offset[1]==0 && size[1]==srcShape[1], or size[0]==1)
                    bool isContiguous = true;
                    int64_t ndim = srcShape.size();
                    for (int64_t i = ndim - 1; i > 0; --i) {
                        if (offsets[i] != 0 || sizes[i] != srcShape[i]) {
                            bool outerSizeOne = true;
                            for (int64_t j = 0; j < i; ++j) {
                                if (sizes[j] != 1) {
                                    outerSizeOne = false;
                                    break;
                                }
                            }
                            if (!outerSizeOne) {
                                isContiguous = false;
                                break;
                            }
                        }
                    }
                    
                    auto i64PtrType = emitc::PointerType::get(rewriter.getI64Type());
                    auto partitionType = emitc::OpaqueType::get(ctx, "PartitionTensor");
                    auto partitionPtrType = emitc::PointerType::get(partitionType);
                    
                    // Build offsets array literal
                    std::string offsetsStr = "(int64_t[]){";
                    for (size_t i = 0; i < offsets.size(); i++) {
                        if (i > 0) offsetsStr += ", ";
                        offsetsStr += std::to_string(offsets[i]);
                    }
                    offsetsStr += "}";
                    
                    // Build sizes array literal
                    std::string sizesStr = "(int64_t[]){";
                    for (size_t i = 0; i < sizes.size(); i++) {
                        if (i > 0) sizesStr += ", ";
                        sizesStr += std::to_string(sizes[i]);
                    }
                    sizesStr += "}";
                    
                    auto offsetsConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i64PtrType,
                        emitc::OpaqueAttr::get(ctx, offsetsStr));
                    auto sizesConst = rewriter.create<emitc::ConstantOp>(nestedLoc, i64PtrType,
                        emitc::OpaqueAttr::get(ctx, sizesStr));
                    
                    // Get pointer to source PartitionTensor
                    auto srcPtAddr = rewriter.create<emitc::ApplyOp>(nestedLoc, partitionPtrType,
                        rewriter.getStringAttr("&"), srcPartitionTensor);
                    
                    Value resultPt;
                    
                    if (isContiguous) {
                        // Contiguous slice: call __emitc_extract_slice_contiguous
                        auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(nestedLoc, partitionType,
                            "__emitc_extract_slice_contiguous", nullptr, nullptr,
                            ValueRange{srcPtAddr.getResult(), offsetsConst.getResult(), sizesConst.getResult()});
                        resultPt = sliceOp.getResult(0);
                        llvm::errs() << "[Pattern] Host: contiguous slice (PartitionTensor)\n";
                    } else {
                        // Non-contiguous 2D slice: call __emitc_extract_slice_2d
                        if (ndim != 2) {
                            llvm::errs() << "[Pattern] Warning: non-contiguous slice only supported for 2D\n";
                            continue;
                        }
                        
                        auto devInstPtrType = emitc::PointerType::get(devInstType);
                        auto devInstAddr = rewriter.create<emitc::ApplyOp>(nestedLoc, devInstPtrType,
                            rewriter.getStringAttr("&"), devInstRef.getResult());
                        
                        auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(nestedLoc, partitionType,
                            "__emitc_extract_slice_2d", nullptr, nullptr,
                            ValueRange{devInstAddr.getResult(), srcPtAddr.getResult(),
                                       offsetsConst.getResult(), sizesConst.getResult()});
                        resultPt = sliceOp.getResult(0);
                        
                        state.allocatedMemList.push_back(resultPt);
                        llvm::errs() << "[Pattern] Host: non-contiguous 2D slice (PartitionTensor, allocated)\n";
                    }
                    
                    state.memAllocMap[nestedOp.getResult(0)] = std::make_tuple(resultPt, sliceByteSize, sliceElements);
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
            "#define PARTITION_MAX_DIMS 8\n"
            "#define ALLOC_LIST_MAX_SIZE 256\n\n"
            "/* Global list to track allocated memory for cleanup */\n"
            "static XAie_MemInst* g_alloc_mem_list[ALLOC_LIST_MAX_SIZE];\n"
            "static int g_alloc_mem_count = 0;\n\n"
            "/* Add memory instance to tracking list */\n"
            "static inline void __emitc_track_alloc(XAie_MemInst* mem) {\n"
            "    if (g_alloc_mem_count < ALLOC_LIST_MAX_SIZE) {\n"
            "        g_alloc_mem_list[g_alloc_mem_count++] = mem;\n"
            "    }\n"
            "}\n\n"
            "/* Free all tracked memory allocations */\n"
            "static inline void __emitc_free_all_allocs() {\n"
            "    for (int i = 0; i < g_alloc_mem_count; i++) {\n"
            "        if (g_alloc_mem_list[i]) {\n"
            "            XAie_MemFree(g_alloc_mem_list[i]);\n"
            "            g_alloc_mem_list[i] = NULL;\n"
            "        }\n"
            "    }\n"
            "    g_alloc_mem_count = 0;\n"
            "}\n\n"
            "/* PartitionTensor structure for memory management and partitioning info */\n"
            "typedef struct {\n"
            "    void* data;                              /* Pointer to data */\n"
            "    size_t elem_size;                        /* Size of each element in bytes */\n"
            "    int ndim;                                /* Number of dimensions */\n"
            "    int64_t original_shape[PARTITION_MAX_DIMS];  /* Original tensor shape */\n"
            "    int64_t partition_shape[PARTITION_MAX_DIMS]; /* Shape of each partition slice */\n"
            "    int partition_dim;                       /* Dimension being partitioned */\n"
            "    int num_partitions;                      /* Number of partitions */\n"
            "    /* Routing metadata */\n"
            "    int hw_axis_owner;                       /* 0=row, 1=col */\n"
            "    int replicate_on;                        /* 0=row, 1=col, -1=none */\n"
            "} PartitionTensor;\n\n"
            "/* Helper function for PartitionTensor initialization */\n"
            "static inline PartitionTensor __emitc_init_PartitionTensor(\n"
            "    void* data, size_t elem_size, int ndim,\n"
            "    const int64_t* original_shape, const int64_t* partition_shape,\n"
            "    int partition_dim, int num_partitions,\n"
            "    int hw_axis_owner, int replicate_on) {\n"
            "    PartitionTensor pt;\n"
            "    pt.data = data;\n"
            "    pt.elem_size = elem_size;\n"
            "    pt.ndim = ndim;\n"
            "    for (int i = 0; i < ndim && i < PARTITION_MAX_DIMS; i++) {\n"
            "        pt.original_shape[i] = original_shape[i];\n"
            "        pt.partition_shape[i] = partition_shape[i];\n"
            "    }\n"
            "    pt.partition_dim = partition_dim;\n"
            "    pt.num_partitions = num_partitions;\n"
            "    pt.hw_axis_owner = hw_axis_owner;\n"
            "    pt.replicate_on = replicate_on;\n"
            "    return pt;\n"
            "}\n\n"
            "/* Get pointer to a specific partition slice */\n"
            "static inline void* __emitc_get_partition_slice(\n"
            "    PartitionTensor* pt, int partition_idx) {\n"
            "    if (partition_idx < 0 || partition_idx >= pt->num_partitions) return NULL;\n"
            "    /* Calculate slice offset based on partition dimension */\n"
            "    size_t slice_size = pt->elem_size;\n"
            "    for (int i = 0; i < pt->ndim; i++) {\n"
            "        slice_size *= pt->partition_shape[i];\n"
            "    }\n"
            "    return (void*)((char*)pt->data + partition_idx * slice_size);\n"
            "}\n\n"
            "/* Extract contiguous slice from PartitionTensor (returns new PartitionTensor with offset pointer) */\n"
            "/* offsets and sizes are arrays of length ndim */\n"
            "static inline PartitionTensor __emitc_extract_slice_contiguous(\n"
            "    PartitionTensor* src, const int64_t* offsets, const int64_t* sizes) {\n"
            "    PartitionTensor result;\n"
            "    result.elem_size = src->elem_size;\n"
            "    result.ndim = src->ndim;\n"
            "    result.partition_dim = -1;  /* Not partitioned */\n"
            "    result.num_partitions = 1;\n"
            "    result.hw_axis_owner = src->hw_axis_owner;\n"
            "    result.replicate_on = src->replicate_on;\n"
            "    \n"
            "    /* Copy shapes */\n"
            "    for (int i = 0; i < src->ndim && i < PARTITION_MAX_DIMS; i++) {\n"
            "        result.original_shape[i] = sizes[i];\n"
            "        result.partition_shape[i] = sizes[i];\n"
            "    }\n"
            "    \n"
            "    /* Calculate byte offset using row-major layout */\n"
            "    size_t byte_offset = 0;\n"
            "    size_t stride = src->elem_size;\n"
            "    for (int i = src->ndim - 1; i >= 0; i--) {\n"
            "        byte_offset += offsets[i] * stride;\n"
            "        stride *= src->original_shape[i];\n"
            "    }\n"
            "    \n"
            "    result.data = (void*)((char*)src->data + byte_offset);\n"
            "    return result;\n"
            "}\n\n"
            "/* Extract 2D non-contiguous slice from PartitionTensor */\n"
            "/* Allocates new memory via XAie_MemAllocate, copies strided data, tracks allocation */\n"
            "static inline PartitionTensor __emitc_extract_slice_2d(\n"
            "    XAie_DevInst* dev_inst, PartitionTensor* src,\n"
            "    const int64_t* offsets, const int64_t* sizes) {\n"
            "    PartitionTensor result;\n"
            "    result.elem_size = src->elem_size;\n"
            "    result.ndim = src->ndim;\n"
            "    result.partition_dim = -1;  /* Not partitioned */\n"
            "    result.num_partitions = 1;\n"
            "    result.hw_axis_owner = src->hw_axis_owner;\n"
            "    result.replicate_on = src->replicate_on;\n"
            "    \n"
            "    /* Copy new shape (slice sizes become the shape) */\n"
            "    for (int i = 0; i < src->ndim && i < PARTITION_MAX_DIMS; i++) {\n"
            "        result.original_shape[i] = sizes[i];\n"
            "        result.partition_shape[i] = sizes[i];\n"
            "    }\n"
            "    \n"
            "    /* Calculate destination size for 2D slice */\n"
            "    size_t dst_size = (size_t)sizes[0] * sizes[1] * src->elem_size;\n"
            "    \n"
            "    /* Allocate memory for the slice */\n"
            "    XAie_MemInst* mem_inst = XAie_MemAllocate(*dev_inst, dst_size, XAIE_MEM_CACHEABLE);\n"
            "    if (!mem_inst) {\n"
            "        result.data = NULL;\n"
            "        return result;\n"
            "    }\n"
            "    \n"
            "    /* Track the allocation for cleanup */\n"
            "    __emitc_track_alloc(mem_inst);\n"
            "    \n"
            "    /* Get virtual address */\n"
            "    void* dst = XAie_MemGetVAddr(mem_inst);\n"
            "    result.data = dst;\n"
            "    if (!dst) return result;\n"
            "    \n"
            "    /* Copy strided data from source to contiguous destination */\n"
            "    char* d = (char*)dst;\n"
            "    char* s = (char*)src->data;\n"
            "    int elem_size = src->elem_size;\n"
            "    int src_dim1 = src->original_shape[1];\n"
            "    int off0 = offsets[0];\n"
            "    int off1 = offsets[1];\n"
            "    int size0 = sizes[0];\n"
            "    int size1 = sizes[1];\n"
            "    \n"
            "    for (int i = 0; i < size0; i++) {\n"
            "        int src_idx = ((off0 + i) * src_dim1 + off1) * elem_size;\n"
            "        int dst_idx = (i * size1) * elem_size;\n"
            "        memcpy(d + dst_idx, s + src_idx, size1 * elem_size);\n"
            "    }\n"
            "    \n"
            "    return result;\n"
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
