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
#include "llvm/Support/Format.h"
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
    
    // Counter for generating unique array names
    int arrayIndex = 0;
    int partitionIndex = 0;
    
    // Statistics for ExtractSliceInnerPattern
    int extractSliceCallCount = 0;
    int extractSliceFailCount = 0;
    int extractSliceSuccessCount = 0;
    
    // Resource manager for channel and BD IDs
    // Map from tile (col, row) to next available channel/BD ID
    DenseMap<std::pair<int32_t, int32_t>, int32_t> nextChannelId;
    DenseMap<std::pair<int32_t, int32_t>, int32_t> nextBdId;
    
    // Map from io_handle Value to (channel_id, bd_id) for __Runtime_dma_createio
    DenseMap<Value, std::pair<int32_t, int32_t>> ioHandleToResourceMap;
    
    // Cached values for inner patterns (set before applying inner patterns)
    Value devInstRef;
    Value cacheableConst;
    Type voidPtrType;
    Type memInstPtrType;
    Type i32Type;
    Type partitionType;
    Type devInstType;
    MLIRContext *ctx = nullptr;
    
    // Helper to allocate a channel ID for a tile
    int32_t allocateChannelId(int32_t col, int32_t row) {
        auto key = std::make_pair(col, row);
        int32_t &nextId = nextChannelId[key];
        return nextId++;
    }
    
    // Helper to allocate a BD ID for a tile
    int32_t allocateBdId(int32_t col, int32_t row) {
        auto key = std::make_pair(col, row);
        int32_t &nextId = nextBdId[key];
        return nextId++;
    }
};


//===----------------------------------------------------------------------===//
// Module-Level Patterns (Global conversions)
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Helper: EraseOpLowering - Reusable pattern to erase ops by name
//===----------------------------------------------------------------------===//

template <typename Op_T>
struct EraseOpLowering : public OpConversionPattern<Op_T> {
    using OpConversionPattern<Op_T>::OpConversionPattern;
    LogicalResult matchAndRewrite(Op_T op, typename Op_T::Adaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

//===----------------------------------------------------------------------===//
// Inner Patterns (Applied inside host op region via walk)
//===----------------------------------------------------------------------===//

/// Inner pattern for arith.constant -> emitc.constant (handles ALL constant types)
struct ArithConstantInnerPattern : public OpConversionPattern<arith::ConstantOp> {
    ConversionState &state;
    
    ArithConstantInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<arith::ConstantOp>(typeConverter, ctx, /*benefit=*/1), state(state) {}
    
    LogicalResult matchAndRewrite(arith::ConstantOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        auto resultType = op.getType();
        auto value = op.getValue();
        
        // Handle dense constants (tensors) - these were converted to global arrays in Phase 2
        if (auto denseAttr = dyn_cast<DenseElementsAttr>(value)) {
            // Check if this op has the "emitc.global_array_name" attribute (set in Phase 2)
            if (auto arrayNameAttr = op->getAttrOfType<StringAttr>("emitc.global_array_name")) {
                std::string arrayName = arrayNameAttr.getValue().str();
                
                // Create emitc.constant that references the global array
                // The type should be a pointer to the array's element type
                auto emitcConst = rewriter.create<emitc::ConstantOp>(
                    loc, state.voidPtrType,
                    emitc::OpaqueAttr::get(state.ctx, "(void*)" + arrayName));
                
                rewriter.replaceOp(op, emitcConst.getResult());
                llvm::errs() << "[Pattern] Converted arith.constant dense -> emitc.constant reference to " 
                             << arrayName << "\n";
                return success();
            }
            // If not marked with global array name, this shouldn't happen
            llvm::errs() << "[Pattern] Dense constant without global array name attribute, erasing\n";
            rewriter.eraseOp(op);
            return success();
        }
        
        // Handle integer constants (including index type)
        if (auto intAttr = dyn_cast<IntegerAttr>(value)) {
            auto emitcConst = rewriter.create<emitc::ConstantOp>(
                loc, resultType, intAttr);
            rewriter.replaceOp(op, emitcConst.getResult());
            llvm::errs() << "[Pattern] Converted arith.constant (int) to emitc.constant\n";
            return success();
        }
        
        // Handle float constants
        if (auto floatAttr = dyn_cast<FloatAttr>(value)) {
            auto emitcConst = rewriter.create<emitc::ConstantOp>(
                loc, resultType, floatAttr);
            rewriter.replaceOp(op, emitcConst.getResult());
            llvm::errs() << "[Pattern] Converted arith.constant (float) to emitc.constant\n";
            return success();
        }
        
        // Handle bool constants
        if (auto boolAttr = dyn_cast<BoolAttr>(value)) {
            auto emitcConst = rewriter.create<emitc::ConstantOp>(
                loc, resultType, boolAttr);
            rewriter.replaceOp(op, emitcConst.getResult());
            llvm::errs() << "[Pattern] Converted arith.constant (bool) to emitc.constant\n";
            return success();
        }
        
        // For any other constant types, try to convert to emitc.constant
        auto emitcConst = rewriter.create<emitc::ConstantOp>(
            loc, resultType, value);
        rewriter.replaceOp(op, emitcConst.getResult());
        llvm::errs() << "[Pattern] Converted arith.constant (other) to emitc.constant\n";
        return success();
    }
};

/// Inner pattern for dfscheblueprint.declare_data -> XAie_MemAllocate + memcpy
struct DeclareDataInnerPattern : public OpConversionPattern<dfscheblueprint::DeclareDataOp> {
    
    DeclareDataInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx)
        : OpConversionPattern<dfscheblueprint::DeclareDataOp>(typeConverter, ctx, /*benefit=*/100) {}
    
    // OpConversionPattern provides OpAdaptor automatically
    LogicalResult matchAndRewrite(dfscheblueprint::DeclareDataOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        llvm::errs() << "[Pattern] DeclareDataInnerPattern::matchAndRewrite called\n";
        
        auto resultType = dyn_cast<RankedTensorType>(op.getResult().getType());
        if (!resultType) {
            llvm::errs() << "[Pattern] DeclareData: Result is not RankedTensorType\n";
            return failure();
        }
        
        auto loc = op.getLoc();
        auto ctx = rewriter.getContext();
        
        // Get converted source pointer from adaptor (auto-generated by OpConversionPattern)
        Value srcPtr = adaptor.getOperands()[0];
        
        llvm::errs() << "[Pattern] DeclareData: OpAdaptor srcPtr = ";
        srcPtr.print(llvm::errs());
        llvm::errs() << "\n[Pattern] DeclareData: OpAdaptor srcPtr type = ";
        srcPtr.getType().print(llvm::errs());
        llvm::errs() << "\n";
        
        if (!srcPtr) {
            llvm::errs() << "[Pattern] DeclareData: No converted input from adaptor\n";
            return failure();
        }
        
        // Calculate sizes from the result type
        auto shape = resultType.getShape();
        int64_t totalElements = 1;
        for (auto dim : shape) totalElements *= dim;
        
        Type elemType = resultType.getElementType();
        int64_t elemSize = getElemSize(elemType);
        int64_t byteSize = totalElements * elemSize;
        
        // Create types locally
        Type i32Type = IntegerType::get(ctx, 32);
        Type voidPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
        Type memInstPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "XAie_MemInst"));
        Type devInstType = emitc::OpaqueType::get(ctx, "XAie_DevInst");
        Type devInstPtrType = emitc::PointerType::get(devInstType);
        
        // Create &DevInst reference
        auto devInstRef = rewriter.create<emitc::ConstantOp>(
            loc, devInstPtrType,
            emitc::OpaqueAttr::get(ctx, "&DevInst"));
        
        // Create XAIE_MEM_CACHEABLE constant
        auto cacheableConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type,
            emitc::OpaqueAttr::get(ctx, "XAIE_MEM_CACHEABLE"));
        
        // Create size constant
        auto sizeConst = rewriter.create<emitc::ConstantOp>(loc, i32Type,
            rewriter.getI32IntegerAttr(byteSize));
        
        // Call XAie_MemAllocate
        auto memInst = rewriter.create<emitc::CallOpaqueOp>(loc,
            memInstPtrType, "XAie_MemAllocate", nullptr, nullptr,
            ValueRange{devInstRef.getResult(), sizeConst.getResult(), cacheableConst.getResult()});
        
        // Call XAie_MemGetVAddr to get void* address
        auto vaddr = rewriter.create<emitc::CallOpaqueOp>(loc,
            voidPtrType, "XAie_MemGetVAddr", nullptr, nullptr,
            ValueRange{memInst.getResult(0)});
        
        // Call memcpy to copy data from source array to allocated memory
        rewriter.create<emitc::CallOpaqueOp>(loc, voidPtrType, "memcpy",
            nullptr, nullptr,
            ValueRange{vaddr.getResult(0), srcPtr, sizeConst.getResult()});
        
        llvm::errs() << "[Pattern] DeclareData: XAie_MemAllocate and memcpy completed\n";
        
        // Replace the op with the vaddr result to maintain SSA chain
        rewriter.replaceOp(op, vaddr.getResult(0));
        return success();
    }
};

/// Inner pattern for routing.partitiontensor -> __Runtime_init_PartitionTensor
struct PartitionTensorInnerPattern : public OpConversionPattern<routing::partitiontensor> {
    ConversionState &state;
    
    PartitionTensorInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<routing::partitiontensor>(typeConverter, ctx, /*benefit=*/50), state(state) {}
    
    LogicalResult matchAndRewrite(routing::partitiontensor op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        llvm::errs() << "[Pattern] PartitionTensorInnerPattern::matchAndRewrite called\n";
        // routing::partitiontensor has OneOperand and OneResult traits
        auto resultType = dyn_cast<RankedTensorType>(op.getResult().getType());
        auto inputType = dyn_cast<RankedTensorType>(op.getOperand().getType());
        if (!resultType || !inputType) return failure();
       
        auto loc = op.getLoc();
        
        // Use adaptor to get converted operand (this is the void* from DeclareData)
        // OpAdaptor for OneOperand ops exposes getOperands() which returns ValueRange
        Value dataVoidPtr = adaptor.getOperands()[0];
        Type want = getTypeConverter()->convertType(op.getOperand().getType());

        if (0) {//!dataVoidPtr || dataVoidPtr.getType() != want) {
            // Debug: Print what we got from adaptor
            llvm::errs() << "[PartitionTensor] adaptor.getOperands()[0] = ";
            if (dataVoidPtr) {
                dataVoidPtr.print(llvm::errs());
                llvm::errs() << "\n[PartitionTensor] Type: ";
                dataVoidPtr.getType().print(llvm::errs());
                llvm::errs() << "\nwant: ";
                want.print(llvm::errs());
                llvm::errs() << "\n";
                if (auto defOp = dataVoidPtr.getDefiningOp()) {
                    llvm::errs() << "[PartitionTensor] Defining op: " << defOp->getName() << "\n";
                }
            } else {
                llvm::errs() << "NULL!\n";
            }
           return failure();
        }   
        
        if (!dataVoidPtr) {
            dataVoidPtr = rewriter.create<emitc::ConstantOp>(loc, state.voidPtrType,
                emitc::OpaqueAttr::get(state.ctx, "NULL")).getResult();
        }
        
        // Get partition attributes
        int splitnum = 1, splitdim = 0;
        if (auto attr = op->getAttrOfType<IntegerAttr>("splitnum")) splitnum = attr.getInt();
        if (auto attr = op->getAttrOfType<IntegerAttr>("splitdim")) splitdim = attr.getInt();
        
        // Get hw_axis_owner and replicate_on (convert string to int)
        int hwAxisOwner = 0; // 0=row, 1=col
        int replicateOn = -1; // -1=none, 0=row, 1=col
        if (auto attr = op->getAttrOfType<StringAttr>("hw_axis_owner")) {
            hwAxisOwner = (attr.getValue() == "col") ? 1 : 0;
        }
        if (auto attr = op->getAttrOfType<StringAttr>("replicate_on")) {
            if (attr.getValue() == "col") replicateOn = 1;
            else if (attr.getValue() == "row") replicateOn = 0;
        }
        
        // Get original shape from input type
        auto originalShape = inputType.getShape();
        int ndim = originalShape.size();
        
        // Compute partition shape: divide by splitnum along splitdim
        SmallVector<int64_t, 4> partitionShape;
        for (int i = 0; i < ndim; i++) {
            if (i == splitdim) {
                partitionShape.push_back(originalShape[i] / splitnum);
            } else {
                partitionShape.push_back(originalShape[i]);
            }
        }
        
        int64_t totalElements = 1;
        for (auto dim : partitionShape) totalElements *= dim;
        
        int64_t elemSize = getElemSize(resultType.getElementType());
        int64_t partitionByteSize = totalElements * elemSize;
        ///*
        // Build original_shape array literal
        std::string origShapeStr = "(int64_t[]){";
        for (size_t i = 0; i < originalShape.size(); i++) {
            if (i > 0) origShapeStr += ", ";
            origShapeStr += std::to_string(originalShape[i]);
        }
        origShapeStr += "}";
        
        // Build partition_shape array literal (divided by splitnum along splitdim)
        std::string partShapeStr = "(int64_t[]){";
        for (size_t i = 0; i < partitionShape.size(); i++) {
            if (i > 0) partShapeStr += ", ";
            partShapeStr += std::to_string(partitionShape[i]);
        }
        partShapeStr += "}";
        ///*
        auto i64PtrType = emitc::PointerType::get(rewriter.getI64Type());
        
        auto elemSizeConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(elemSize));
        auto ndimConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(ndim));
        auto origShapeConst = rewriter.create<emitc::ConstantOp>(loc, i64PtrType,
            emitc::OpaqueAttr::get(state.ctx, origShapeStr));
        auto partShapeConst = rewriter.create<emitc::ConstantOp>(loc, i64PtrType,
            emitc::OpaqueAttr::get(state.ctx, partShapeStr));
        auto splitdimConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(splitdim));
        auto splitnumConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(splitnum));
        auto hwAxisConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(hwAxisOwner));
        auto replicateConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(replicateOn));
        ///*
        auto ptOp = rewriter.create<emitc::CallOpaqueOp>(loc, state.partitionType,
            "__Runtime_init_PartitionTensor", nullptr, nullptr,
            ValueRange{dataVoidPtr, elemSizeConst.getResult(), ndimConst.getResult(),
                       origShapeConst.getResult(), partShapeConst.getResult(),
                       splitdimConst.getResult(), splitnumConst.getResult(),
                       hwAxisConst.getResult(), replicateConst.getResult()});
        ///*
        state.memAllocMap[op.getResult()] = std::make_tuple(ptOp.getResult(0), partitionByteSize, totalElements);
        state.dataPtrMap[op.getResult()] = dataVoidPtr;
        llvm::errs() << "[Pattern] PartitionTensor: created (ndim=" << ndim 
                     << ", splitdim=" << splitdim << ", splitnum=" << splitnum << ")\n";
        //*/
        rewriter.replaceOp(op, ptOp.getResult(0));
        //rewriter.eraseOp(op);
        return success();
    }
};

/// Inner pattern for tensor.extract_slice -> __Runtime_extract_slice_*
struct ExtractSliceInnerPattern : public OpConversionPattern<tensor::ExtractSliceOp> {
    ConversionState &state;
    
    ExtractSliceInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<tensor::ExtractSliceOp>(typeConverter, ctx, /*benefit=*/1), state(state) {}
    
    LogicalResult matchAndRewrite(tensor::ExtractSliceOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        state.extractSliceCallCount++;
        llvm::errs() << "[Pattern] ExtractSliceInnerPattern::matchAndRewrite called (#" 
                     << state.extractSliceCallCount << ")\n";
        auto loc = op.getLoc();
        
        auto resultType = dyn_cast<RankedTensorType>(op.getResult().getType());
        auto srcType = dyn_cast<RankedTensorType>(op.getSource().getType());
        if (!resultType || !srcType) {
            state.extractSliceFailCount++;
            llvm::errs() << "[Pattern] ExtractSlice: CONVERT FAIL - Not a ranked tensor type\n";
            llvm::errs() << "[Pattern] ExtractSlice: FAILURE #" << state.extractSliceFailCount 
                         << " (total calls: " << state.extractSliceCallCount << ")\n";
            return failure();
        }
        
        Value srcTensor = op.getSource();
        
        // Use adaptor to get the converted source
        Value srcPartitionTensor = adaptor.getSource();
        
        // Check if the input source is already a PartitionTensor or needs conversion
        Operation* srcOp = srcTensor.getDefiningOp();
        bool isFromPartitionTensor = false;
        bool isFromExtractSlice = false;
        
        if (!srcOp) {
            state.extractSliceFailCount++;
            llvm::errs() << "[Pattern] ExtractSlice: CONVERT FAIL - Source is BlockArgument\n";
            llvm::errs() << "[Pattern] ExtractSlice: FAILURE #" << state.extractSliceFailCount 
                         << " (total calls: " << state.extractSliceCallCount << ")\n";
            return failure();
        }
        
        // Check the defining operation type
        if (isa<routing::partitiontensor>(srcOp)) {
            isFromPartitionTensor = true;
            llvm::errs() << "[Pattern] ExtractSlice: Input from routing.partitiontensor\n";
        } else if (isa<tensor::ExtractSliceOp>(srcOp)) {
            isFromPartitionTensor = true;
            isFromExtractSlice = true;
            llvm::errs() << "[Pattern] ExtractSlice: Input from tensor.extract_slice (NESTED SLICE)\n";
        } else {
            llvm::errs() << "[Pattern] ExtractSlice: Input from other op: " << srcOp->getName() << "\n";
        }
        
        // Verify the converted source type
        if (auto opaqueType = dyn_cast<emitc::OpaqueType>(srcPartitionTensor.getType())) {
            if (opaqueType.getValue() == "PartitionTensor") {
                llvm::errs() << "[Pattern] ExtractSlice: Converted source is PartitionTensor ✓\n";
            } else {
                llvm::errs() << "[Pattern] ExtractSlice: Converted source type = " << opaqueType.getValue() << "\n";
            }
        } else {
            llvm::errs() << "[Pattern] ExtractSlice: Converted source NOT yet PartitionTensor, type = " 
                         << srcPartitionTensor.getType() << " (conversion in progress)\n";
        }
        
        auto offsets = op.getStaticOffsets();
        auto sizes = op.getStaticSizes();
        auto srcShape = srcType.getShape();
        
        int64_t ndim = srcShape.size();
        if (ndim != 2) {
            state.extractSliceFailCount++;
            llvm::errs() << "[Pattern] ExtractSlice: CONVERT FAIL - Only 2D slices supported, got " 
                         << ndim << "D\n";
            llvm::errs() << "[Pattern] ExtractSlice: FAILURE #" << state.extractSliceFailCount 
                         << " (total calls: " << state.extractSliceCallCount << ")\n";
            return failure();
        }
        
        int64_t elemSize = getElemSize(resultType.getElementType());
        int64_t sliceElements = sizes[0] * sizes[1];
        int64_t sliceByteSize = sliceElements * elemSize;
        
        // Check if slice is contiguous:
        // For 2D: contiguous if offset[1]==0 && size[1]==srcShape[1], or size[0]==1
        bool isContiguous = (offsets[1] == 0 && sizes[1] == srcShape[1]) || (sizes[0] == 1);
        
        Value resultPt;
        
        // Branch based on source operation type
        if (isFromExtractSlice) {
            // NESTED SLICE: slicing a previous slice result
            llvm::errs() << "[Pattern] ExtractSlice: *** NESTED SLICE MODE ***\n";
            llvm::errs() << "[Pattern]   Parent slice shape: " << srcShape[0] << "x" << srcShape[1] << "\n";
            llvm::errs() << "[Pattern]   This slice: offset=[" << offsets[0] << ", " << offsets[1] 
                         << "] size=[" << sizes[0] << ", " << sizes[1] << "]\n";
            
            if (isContiguous) {
                auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(loc, state.partitionType,
                    "__Runtime_extract_slice_contiguous_2d",
                    rewriter.getArrayAttr({
                        rewriter.getIndexAttr(0),
                        rewriter.getI32IntegerAttr(offsets[0]),
                        rewriter.getI32IntegerAttr(offsets[1]),
                        rewriter.getI32IntegerAttr(sizes[0]),
                        rewriter.getI32IntegerAttr(sizes[1])
                    }),
                    nullptr,
                    ValueRange{srcPartitionTensor});
                resultPt = sliceOp.getResult(0);
                llvm::errs() << "[Pattern]   => Contiguous nested slice (no allocation)\n";
            } else {
                auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(loc, state.partitionType,
                    "__Runtime_extract_slice_strided_2d",
                    rewriter.getArrayAttr({
                        rewriter.getIndexAttr(0),
                        rewriter.getIndexAttr(1),
                        rewriter.getI32IntegerAttr(offsets[0]),
                        rewriter.getI32IntegerAttr(offsets[1]),
                        rewriter.getI32IntegerAttr(sizes[0]),
                        rewriter.getI32IntegerAttr(sizes[1])
                    }),
                    nullptr,
                    ValueRange{state.devInstRef, srcPartitionTensor});
                resultPt = sliceOp.getResult(0);
                state.allocatedMemList.push_back(resultPt);
                llvm::errs() << "[Pattern]   => Strided nested slice (allocated " << sliceByteSize << " bytes)\n";
            }
        } else if (isFromPartitionTensor) {
            // PARTITION SLICE: slicing a partitioned tensor
            llvm::errs() << "[Pattern] ExtractSlice: *** PARTITION SLICE MODE ***\n";
            llvm::errs() << "[Pattern]   Partition shape: " << srcShape[0] << "x" << srcShape[1] << "\n";
            llvm::errs() << "[Pattern]   Slice: offset=[" << offsets[0] << ", " << offsets[1] 
                         << "] size=[" << sizes[0] << ", " << sizes[1] << "]\n";
            
            if (isContiguous) {
                auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(loc, state.partitionType,
                    "__Runtime_extract_slice_contiguous_2d",
                    rewriter.getArrayAttr({
                        rewriter.getIndexAttr(0),
                        rewriter.getI32IntegerAttr(offsets[0]),
                        rewriter.getI32IntegerAttr(offsets[1]),
                        rewriter.getI32IntegerAttr(sizes[0]),
                        rewriter.getI32IntegerAttr(sizes[1])
                    }),
                    nullptr,
                    ValueRange{srcPartitionTensor});
                resultPt = sliceOp.getResult(0);
                llvm::errs() << "[Pattern]   => Contiguous partition slice (no allocation)\n";
            } else {
                auto sliceOp = rewriter.create<emitc::CallOpaqueOp>(loc, state.partitionType,
                    "__Runtime_extract_slice_strided_2d",
                    rewriter.getArrayAttr({
                        rewriter.getIndexAttr(0),
                        rewriter.getIndexAttr(1),
                        rewriter.getI32IntegerAttr(offsets[0]),
                        rewriter.getI32IntegerAttr(offsets[1]),
                        rewriter.getI32IntegerAttr(sizes[0]),
                        rewriter.getI32IntegerAttr(sizes[1])
                    }),
                    nullptr,
                    ValueRange{state.devInstRef, srcPartitionTensor});
                resultPt = sliceOp.getResult(0);
                state.allocatedMemList.push_back(resultPt);
                llvm::errs() << "[Pattern]   => Strided partition slice (allocated " << sliceByteSize << " bytes)\n";
            }
        } else {
            // Unknown source - this shouldn't happen
            state.extractSliceFailCount++;
            llvm::errs() << "[Pattern] ExtractSlice: *** CONVERT FAIL - UNKNOWN SOURCE ***\n";
            llvm::errs() << "[Pattern]   Source operation is not routing.partitiontensor or tensor.extract_slice\n";
            llvm::errs() << "[Pattern] ExtractSlice: FAILURE #" << state.extractSliceFailCount 
                         << " (total calls: " << state.extractSliceCallCount << ")\n";
            return failure();
        }
        
        //state.memAllocMap[op.getResult()] = std::make_tuple(resultPt, sliceByteSize, sliceElements);
        //*/
        //rewriter.eraseOp(op);
        rewriter.replaceOp(op, resultPt);
        
        // Success!
        state.extractSliceSuccessCount++;
        llvm::errs() << "[Pattern] ExtractSlice: ✓ CONVERT SUCCESS #" << state.extractSliceSuccessCount 
                     << " (total: " << state.extractSliceCallCount 
                     << ", failures: " << state.extractSliceFailCount << ")\n";
        return success();
    }
};

/// OpConversionPattern for dfschedule.declaretensor -> pass through partition pointer
/// This takes a tensor (from extract_slice or partition) and just returns the partition structure pointer
/// NOTE: Lower benefit than ExtractSliceInnerPattern to ensure extract_slice is converted first
struct DeclareTensorInnerPattern : public OpConversionPattern<dfschedule::DeclareTensorOp> {
    ConversionState &state;
    
    DeclareTensorInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 100)
        : OpConversionPattern<dfschedule::DeclareTensorOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::DeclareTensorOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        llvm::errs() << "[Pattern] DeclareTensor called\n";
        llvm::errs() << "  Input tensor: " << op.getTensor() << "\n";
        llvm::errs() << "  Result type: " << op.getType() << "\n";
        
        // Get the input tensor value
        Value inputTensor = op.getTensor();
        
        // Try to get the converted value through the adaptor
        Value convertedInput = adaptor.getOperands()[0];
        llvm::errs() << "  Converted input type: " << convertedInput.getType() << "\n";
        
        // The input should already be a PartitionTensor from ExtractSliceInnerPattern or PartitionTensorInnerPattern
        // We just pass it through - the PartitionTensor struct contains the data pointer
        
        // Check if input is PartitionTensor type
        if (auto opaqueType = convertedInput.getType().dyn_cast<emitc::OpaqueType>()) {
            if (opaqueType.getValue() == "PartitionTensor") {
                llvm::errs() << "  ✓ Input is PartitionTensor, passing through\n";
                
                // Just replace with the input - the PartitionTensor contains the data pointer
                rewriter.replaceOp(op, convertedInput);
                return success();
            }
        }
        
        // If input is a pointer type (void*), also pass through
        if (convertedInput.getType().isa<emitc::PointerType>()) {
            llvm::errs() << "  ✓ Input is pointer type, passing through\n";
            rewriter.replaceOp(op, convertedInput);
            return success();
        }
        
        // If the input is still a tensor type, it means the extract_slice hasn't been converted yet
        // In this case, we need to defer conversion or handle it specially
        if (convertedInput.getType().isa<RankedTensorType>()) {
            llvm::errs() << "  ⚠ Input is still tensor type (conversion in progress)\n";
            llvm::errs() << "  → Passing through tensor value (will be resolved in later pass)\n";
            
            // Just pass through - the value will be updated when extract_slice is converted
            rewriter.replaceOp(op, convertedInput);
            return success();
        }
        
        llvm::errs() << "  ✗ WARNING: Unexpected input type for DeclareTensor\n";
        
        // Fallback: just pass through the converted input
        rewriter.replaceOp(op, convertedInput);
        return success();
    }
};

/// OpConversionPattern for dfschedule.declaretile -> XAie_TileLoc call
/// Converts tile declaration to: XAie_LocType tile = XAie_TileLoc(col, row);
struct DeclareTileInnerPattern : public OpConversionPattern<dfschedule::DeclareTileOp> {
    ConversionState &state;
    
    DeclareTileInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 100)
        : OpConversionPattern<dfschedule::DeclareTileOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::DeclareTileOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        // Get tile coordinates from attributes
        int32_t col = op.getCol();
        int32_t row = op.getRow();
        
        llvm::errs() << "[Pattern] DeclareTile called for tile (col=" << col << ", row=" << row << ")\n";
        
        // Create XAie_LocType type
        auto xaieLocType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_LocType");
        
        // Create constants for column and row
        auto i8Type = rewriter.getI8Type();
        auto colConst = rewriter.create<emitc::ConstantOp>(
            loc, i8Type, rewriter.getI8IntegerAttr(col));
        auto rowConst = rewriter.create<emitc::ConstantOp>(
            loc, i8Type, rewriter.getI8IntegerAttr(row));
        
        // Create XAie_TileLoc(col, row) call
        // This generates: XAie_LocType tile_<col>_<row> = XAie_TileLoc(col, row);
        auto tileLocOp = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            xaieLocType,
            "XAie_TileLoc",
            nullptr,
            nullptr,
            ValueRange{colConst.getResult(), rowConst.getResult()});
        
        llvm::errs() << "  ✓ Created XAie_TileLoc(" << col << ", " << row << ") -> XAie_LocType\n";
        
        // Replace the declaretile op with the XAie_TileLoc call result
        // The result is of type XAie_LocType and can be used by DMA BD operations
        rewriter.replaceOp(op, tileLocOp.getResult(0));
        return success();
    }
};

/// OpConversionPattern for dfschedule.config.dma_bd
/// Converts DMA BD configuration to AIE API calls
/// For now, creates a placeholder that uses the tile to keep it alive
struct ConfigDmaBdInnerPattern : public OpConversionPattern<dfschedule::ConfigDmaBdOp> {
    ConversionState &state;
    
    ConfigDmaBdInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::ConfigDmaBdOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::ConfigDmaBdOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        // Get attributes
        int32_t offset = op.getOffset();
        int32_t len = op.getLen();
        bool enablePacket = op.getEnablePacket();
        int32_t packetId = op.getPacketId();
        uint32_t nextBd = op.getNextBd();
        
        llvm::errs() << "[Pattern] ConfigDmaBd called (offset=" << offset 
                     << ", len=" << len << ", enable_packet=" << enablePacket 
                     << ", packet_id=" << packetId << ")\n";
        
        // Get operands
        Value buffer = adaptor.getBuffer();
        Value tile = adaptor.getTile();
        Value bdId = adaptor.getBdId();
        
        llvm::errs() << "  Buffer type: " << buffer.getType() << "\n";
        llvm::errs() << "  Tile type: " << tile.getType() << "\n";
        llvm::errs() << "  BD ID type: " << bdId.getType() << "\n";
        
        // If tile is not yet converted, check if it's a DeclareTileOp and convert it inline
        /*
        if (!tile.getType().isa<emitc::OpaqueType>() || 
            tile.getType().cast<emitc::OpaqueType>().getValue() != "XAie_LocType") {
            // Check if the tile comes from a DeclareTileOp
            if (auto declareTileOp = tile.getDefiningOp<dfschedule::DeclareTileOp>()) {
                llvm::errs() << "  ℹ Tile from DeclareTileOp, converting inline...\n";
                
                // Get tile coordinates
                int32_t col = declareTileOp.getCol();
                int32_t row = declareTileOp.getRow();
                
                // Create XAie_TileLoc call inline
                auto xaieLocType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_LocType");
                auto colConst = rewriter.create<emitc::ConstantOp>(
                    loc, rewriter.getI32Type(),
                    rewriter.getI32IntegerAttr(col));
                auto rowConst = rewriter.create<emitc::ConstantOp>(
                    loc, rewriter.getI32Type(),
                    rewriter.getI32IntegerAttr(row));
                
                tile = rewriter.create<emitc::CallOpaqueOp>(
                    loc, xaieLocType, "XAie_TileLoc",
                    nullptr, nullptr,
                    ValueRange{colConst.getResult(), rowConst.getResult()}).getResult(0);
                
                llvm::errs() << "  ✓ Created inline XAie_TileLoc(" << col << ", " << row << ")\n";
            } else if (tile.isa<BlockArgument>()) {
                // Tile is a function argument (e.g., in dskernel_receiver)
                // This is OK - we'll just use it as-is and it will be handled by the kernel conversion
                llvm::errs() << "  ℹ Tile is a function argument, using as-is\n";
                // For now, just erase this op since kernel-side DMA config is handled differently
                rewriter.eraseOp(op);
                return success();
            } else {
                llvm::errs() << "  ⚠ Tile not from DeclareTileOp or BlockArgument, deferring...\n";
                return failure();
            }
        }
        
        llvm::errs() << "  ✓ Tile is XAie_LocType\n";
        */
        
        // Generate AIE DMA BD configuration following the pattern:
        // XAie_DmaDesc DmaInst;
        // XAie_DmaDescInit(&DevInst, &DmaInst, tile);
        // XAie_DmaSetAddrLen(&DmaInst, offset, len);
        // XAie_DmaSetNextBd(&DmaInst, next_bd, XAIE_ENABLE/XAIE_DISABLE);
        // XAie_DmaSetPkt(&DmaInst, {.PktId=packet_id, .PktType=0});
        // XAie_DmaEnableBd(&DmaInst);
        // XAie_DmaWriteBd(&DevInst, &DmaInst, tile, bd_id);
        
        auto i32Type = rewriter.getI32Type();
        auto dmaDescType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_DmaDesc");
        
        // Create comment
        std::string comment =
            "/* DMA BD Config: bd_id=" +
            std::to_string(
                op.getBdId().getDefiningOp<arith::ConstantOp>()
                    ? mlir::cast<IntegerAttr>(op.getBdId().getDefiningOp<arith::ConstantOp>().getValue()).getInt()
                    : -1) +
            ", offset=" + std::to_string(offset) + ", len=" + std::to_string(len) +
            ", enable_packet=" + (enablePacket ? "true" : "false") + ", packet_id=" + std::to_string(packetId) +
            ", next_bd=" + std::to_string(nextBd) + " */";
        rewriter.create<emitc::VerbatimOp>(loc, comment);
        
        // Create constants for parameters
        auto offsetConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(offset));
        auto lenConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(len));
        auto nextBdConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(nextBd));
        auto packetIdConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(packetId));
        
        // Get buffer address - need to convert memref/PartitionTensor to void* address
        // For now, we'll pass the buffer directly and let the helper function extract the address
        Value bufferAddr = buffer;
        
        // If buffer is a PartitionTensor, we need to extract its data pointer
        // If it's a memref, we need to get its base address
        // For simplicity, we'll cast it to void* and let the runtime handle it
        
        // Call the helper function that wraps all the AIE API calls
        // XAie_DmaDesc __Runtime_dma_bd_config(XAie_DevInst* dev, XAie_LocType tile, 
        //                                      void* buffer, int32_t bd_id,
        //                                      uint64_t addr, int32_t len, int32_t next_bd,
        //                                      int32_t enable_packet, int32_t packet_id)
        auto u64Type = rewriter.getIntegerType(64);
        auto addrConst = rewriter.create<emitc::ConstantOp>(
            loc, u64Type, rewriter.getIntegerAttr(u64Type, offset));
        
        auto configCall = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            dmaDescType,
            "__Runtime_dma_bd_config",
            nullptr,
            nullptr,
            ValueRange{
                state.devInstRef,          // &DevInst
                tile,                      // XAie_LocType tile
                bufferAddr,                // void* buffer (for address extraction)
                bdId,                      // bd_id
                addrConst.getResult(),     // addr (offset within buffer)
                lenConst.getResult(),      // len
                nextBdConst.getResult(),   // next_bd
                rewriter.create<emitc::ConstantOp>(loc, i32Type, 
                    rewriter.getI32IntegerAttr(enablePacket ? 1 : 0)).getResult(),  // enable_packet
                packetIdConst.getResult()  // packet_id
            });
        
        llvm::errs() << "  ✓ Created DMA BD config with full AIE API parameters\n";
        
        // Replace the op with the call result (status code)
        rewriter.replaceOp(op, configCall.getResult(0));
        return success();
    }
};

/// OpConversionPattern for dfschedule.schedule.getbdid
/// Converts GetBdId to allocate a BD ID from the resource manager
/// Returns the allocated BD ID as an i32 constant
struct GetBdIdInnerPattern : public OpConversionPattern<dfschedule::GetBdIdOp> {
    ConversionState &state;
    
    GetBdIdInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::GetBdIdOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::GetBdIdOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        llvm::errs() << "[Pattern] GetBdId called\n";
        
        // Get the tile operand
        Value tile = adaptor.getTile();
        
        llvm::errs() << "  Tile type: " << tile.getType() << "\n";
        
        // Extract tile coordinates directly from the original DeclareTileOp
        int32_t tileCol = -1, tileRow = -1;
        Value originalTile = op.getTile();  // Get original tile value before conversion
        
        if (auto declareTileOp = originalTile.getDefiningOp<dfschedule::DeclareTileOp>()) {
            tileCol = declareTileOp.getCol();
            tileRow = declareTileOp.getRow();
            llvm::errs() << "  ✓ Extracted tile coordinates from DeclareTileOp: (" 
                         << tileCol << ", " << tileRow << ")\n";
        } else {
            llvm::errs() << "  ⚠ Could not find DeclareTileOp for tile\n";
            return failure();
        }
        
        if (tileCol < 0 || tileRow < 0) {
            llvm::errs() << "  ⚠ Invalid tile coordinates\n";
            return failure();
        }
        
        // Allocate BD ID from resource manager
        int32_t allocatedBdId = state.allocateBdId(tileCol, tileRow);
        
        llvm::errs() << "  ✓ Allocated BD ID: " << allocatedBdId 
                     << " for tile (" << tileCol << ", " << tileRow << ")\n";
        
        // Create comment
        std::string comment = "/* Allocated BD ID " + std::to_string(allocatedBdId) +
                            " for tile (" + std::to_string(tileCol) + "," + std::to_string(tileRow) + ") */";
        rewriter.create<emitc::VerbatimOp>(loc, comment);
        
        // Create constant for BD ID
        auto i32Type = rewriter.getI32Type();
        auto bdIdConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(allocatedBdId));
        
        // Replace the op with the BD ID constant
        rewriter.replaceOp(op, bdIdConst.getResult());
        return success();
    }
};

/// OpConversionPattern for dfschedule.config.create_io
/// Converts IO creation to __Runtime_dma_createio call that returns an io struct
/// struct io = __Runtime_dma_createio(dma_desc, channel_id, bd_id);
/// The channel_id and bd_id are allocated from the resource manager
struct ConfigCreateIoInnerPattern : public OpConversionPattern<dfschedule::ConfigCreateIoOp> {
    ConversionState &state;
    
    ConfigCreateIoInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::ConfigCreateIoOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::ConfigCreateIoOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        // Get attributes
        int32_t channel = op.getChannel();
        std::string direction = op.getDirection().str();  // "MM2S" or "S2MM"
        std::string ioOperation = op.getIoOperation().str();
        
        llvm::errs() << "[Pattern] ConfigCreateIo called (channel=" << channel 
                     << ", direction=" << direction << ", io_operation=" << ioOperation << ")\n";
        
        // Get operands
        Value bdConfig = adaptor.getBdConfig();  // This should be the XAie_DmaDesc from config.dma_bd
        Value tile = adaptor.getTile();
        
        // IMPORTANT: In partial conversion, adaptor gives us converted operands if they exist
        // But we need to explicitly check if they've been remapped
        llvm::errs() << "  Original BD Config: " << op.getBdConfig() << "\n";
        llvm::errs() << "  Adapted BD Config: " << bdConfig << "\n";
        llvm::errs() << "  BD Config type: " << bdConfig.getType() << "\n";
        llvm::errs() << "  Tile type: " << tile.getType() << "\n";
        
     
        //rewriter.eraseOp(op);
        //return success();
        
        // Extract tile coordinates directly from the original DeclareTileOp
        int32_t tileCol = -1, tileRow = -1;
        Value originalTile = op.getTile();  // Get original tile value before conversion
        
        if (auto declareTileOp = originalTile.getDefiningOp<dfschedule::DeclareTileOp>()) {
            tileCol = declareTileOp.getCol();
            tileRow = declareTileOp.getRow();
            llvm::errs() << "  ✓ Extracted tile coordinates from DeclareTileOp: (" 
                         << tileCol << ", " << tileRow << ")\n";
        } else {
            llvm::errs() << "  ⚠ Could not find DeclareTileOp for tile\n";
            return failure();
        }
        
        if (tileCol < 0 || tileRow < 0) {
            llvm::errs() << "  ⚠ Invalid tile coordinates\n";
            return failure();
        }
        
        auto i32Type = rewriter.getI32Type();
        
        // Allocate channel ID and BD ID from resource manager
        int32_t allocatedChannelId = state.allocateChannelId(tileCol, tileRow);
        int32_t allocatedBdId = state.allocateBdId(tileCol, tileRow);
        
        llvm::errs() << "  ✓ Allocated resources: channel_id=" << allocatedChannelId 
                     << ", bd_id=" << allocatedBdId << "\n";
        
        // Create constants for channel and BD IDs
        auto channelIdConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(allocatedChannelId));
        
        auto bdIdConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(allocatedBdId));
        // Create comment
        std::string comment = "/* Create IO: channel_id=" + std::to_string(allocatedChannelId) +
                            ", bd_id=" + std::to_string(allocatedBdId) +
                            ", tile=(" + std::to_string(tileCol) + "," + std::to_string(tileRow) + ")" +
                            ", direction=" + direction + " */";
        rewriter.create<emitc::VerbatimOp>(loc, comment);
        
        // Define the IO struct type
        auto ioStructType = emitc::OpaqueType::get(rewriter.getContext(), "struct io");
        
        // Create __Runtime_dma_createio call:
        // struct io = __Runtime_dma_createio(tile_loc, dma_desc, channel_id, bd_id);
        auto createIoCall = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            ioStructType,
            "__Runtime_dma_createio",
            nullptr,
            nullptr,
            ValueRange{
                tile,                       // XAie_LocType tile_loc
                bdConfig,                   // XAie_DmaDesc dma_desc
                channelIdConst.getResult(), // channel_id (from resource manager)
                bdIdConst.getResult()       // bd_id (from resource manager)
            });
        
        llvm::errs() << "  ✓ Created __Runtime_dma_createio call\n";
        
        // Store the resource mapping for use by StartIoOp
        //state.ioHandleToResourceMap[op.getResult()] = std::make_pair(allocatedChannelId, allocatedBdId);
        
        // Replace the op with the IO struct
        rewriter.replaceOp(op, createIoCall.getResult(0));
        return success();
    }
};

/// OpConversionPattern for dfschedule.schedule.start_io
/// Converts StartIo to __Runtime_startio call that returns an ioevent
/// struct ioevent = __Runtime_startio(io, timer_value);
struct StartIoInnerPattern : public OpConversionPattern<dfschedule::StartIoOp> {
    ConversionState &state;
    
    StartIoInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::StartIoOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::StartIoOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        llvm::errs() << "[Pattern] StartIo called\n";
        
        // Get operands
        Value ioHandle = adaptor.getIoHandle();  // This should be the "struct io" from config.create_io
        Value bdId = adaptor.getBdId();          // BD ID (though not used in __Runtime_startio signature shown)
        // Note: flow_index is available via op.getFlowIndex() but unused in __Runtime_startio currently
        
        llvm::errs() << "  IO Handle type: " << ioHandle.getType() << "\n";
        llvm::errs() << "  BD ID type: " << bdId.getType() << "\n";
      
        
        // Define the ioevent struct type
        auto ioEventType = emitc::OpaqueType::get(rewriter.getContext(), "struct ioevent");
        
        //rewriter.eraseOp(op);
        //return success();
        // Create __Runtime_startio call:
        // struct ioevent = __Runtime_startio(io, timer_or_data_value);
        // According to the example: __Runtime_startio(io, v4)
        // The second parameter seems to be some value (maybe from partition or timer)
        auto startIoCall = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            ioEventType,
            "__Runtime_startio",
            nullptr,
            nullptr,
            ValueRange{
                ioHandle,  // struct io
                bdId       // Using bdId as the second parameter (v4 in example)
            });
        
        llvm::errs() << "  ✓ Created __Runtime_startio call\n";
        
        // Replace the op with the ioevent
        rewriter.replaceOp(op, startIoCall.getResult(0));
        return success();
    }
};

/// OpConversionPattern for dfschedule.schedule.wait
/// Converts ScheduleWait to __Runtime_wait call that waits for multiple events
/// __Runtime_wait(event1, event2, ...);
struct ScheduleWaitInnerPattern : public OpConversionPattern<dfschedule::ScheduleWaitOp> {
    ConversionState &state;
    
    ScheduleWaitInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::ScheduleWaitOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::ScheduleWaitOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        llvm::errs() << "[Pattern] ScheduleWait called with " << op.getEvents().size() << " events\n";
        
        // Get all event operands
        auto events = adaptor.getEvents();
        
        if (events.empty()) {
            llvm::errs() << "  ⚠ No events to wait for, erasing op\n";
            rewriter.eraseOp(op);
            return success();
        }
        
        // Log event types for debugging
        for (size_t i = 0; i < events.size(); ++i) {
            llvm::errs() << "  Event[" << i << "] type: " << events[i].getType() << "\n";
        }
        
        // Create comment showing what we're waiting for
        std::string comment = "/* Wait for " + std::to_string(events.size()) + " event(s) */";
        rewriter.create<emitc::VerbatimOp>(loc, comment);
        
        // Create __Runtime_wait call for each event
        // (We could also create a single call that takes an array, but for simplicity,
        //  we'll create individual calls for now)
        for (auto event : events) {
            rewriter.create<emitc::CallOpaqueOp>(
                loc,
                TypeRange{},  // void return type
                "__Runtime_wait",
                nullptr,
                nullptr,
                ValueRange{event});
        }
        
        llvm::errs() << "  ✓ Created __Runtime_wait calls for " << events.size() << " event(s)\n";
        
        // Erase the original wait op (it has no results)
        rewriter.eraseOp(op);
        return success();
    }
};

/// OpConversionPattern for dfschedule.declare_kernel_config
/// This is metadata-only, so just erase it
struct DeclareKernelConfigInnerPattern : public OpConversionPattern<dfschedule::DeclareKernelConfigOp> {
    using OpConversionPattern<dfschedule::DeclareKernelConfigOp>::OpConversionPattern;
    
    LogicalResult matchAndRewrite(dfschedule::DeclareKernelConfigOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        llvm::errs() << "[Pattern] DeclareKernelConfig - erasing (metadata only)\n";
        // This operation is pure metadata, it doesn't generate any runtime code
        rewriter.eraseOp(op);
        return success();
    }
};

/// OpConversionPattern for dfschedule.config.load_kernel_group
/// Converts LoadKernelGroup to __Runtime_load_kernel_group call
/// struct kernel_group = __Runtime_load_kernel_group(tiles, callee_symbols, compute_args, kernel_config);
struct LoadKernelGroupInnerPattern : public OpConversionPattern<dfschedule::LoadKernelGroupOp> {
    ConversionState &state;
    
    LoadKernelGroupInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::LoadKernelGroupOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::LoadKernelGroupOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        llvm::errs() << "[Pattern] LoadKernelGroup called\n";
        
        // Get tiles operands (variadic)
        auto tiles = adaptor.getTiles();
        llvm::errs() << "  Number of tiles: " << tiles.size() << "\n";
        
        // Get attributes
        auto calleeAttr = op.getCalleeAttr();
        auto computeKernelArgsAttr = op.getDistributedComputeKernelArgsAttr();
        auto distributedArgsAttr = op.getDistributedArgsAttr();
        
        llvm::errs() << "  Callee array: " << calleeAttr << "\n";
        llvm::errs() << "  Compute kernel args array: " << computeKernelArgsAttr << "\n";
        
        if (distributedArgsAttr) {
            llvm::errs() << "  Using distributed_args (kernel config symbols): " << distributedArgsAttr << "\n";
            
            auto moduleOp = op->getParentOfType<ModuleOp>();
            
            // Iterate through distributed_args to extract config for each tile
            for (size_t i = 0; i < distributedArgsAttr.size(); ++i) {
                auto symRef = mlir::cast<SymbolRefAttr>(distributedArgsAttr[i]);
                llvm::errs() << "  Tile[" << i << "] config symbol: " << symRef << "\n";
                
                // Look up the kernel_config op
                auto configOp = moduleOp.lookupSymbol<dfschedule::DeclareKernelConfigOp>(
                    symRef.getRootReference());
                
                if (!configOp) {
                    llvm::errs() << "    ERROR: Could not find kernel_config symbol\n";
                    continue;
                }
                
                // Extract tile_configs array (should have exactly one entry per config op)
                auto tileConfigsAttr = configOp.getTileConfigs();
                if (tileConfigsAttr.size() == 0) {
                    llvm::errs() << "    ERROR: Empty tile_configs in kernel_config\n";
                    continue;
                }
                
                auto configDict = mlir::cast<DictionaryAttr>(tileConfigsAttr[0]);
                
                // Extract and log all config fields
                uint32_t tileIndex = mlir::cast<IntegerAttr>(configDict.get("tile_index")).getInt();
                uint8_t packetId = mlir::cast<IntegerAttr>(configDict.get("packet_id")).getInt();
                uint32_t dmaChannel = mlir::cast<IntegerAttr>(configDict.get("dma_channel")).getInt();
                uint8_t bufferMode = mlir::cast<IntegerAttr>(configDict.get("buffer_mode")).getInt();
                uint8_t numBuffers = mlir::cast<IntegerAttr>(configDict.get("num_buffers")).getInt();
                uint32_t bufferSize = mlir::cast<IntegerAttr>(configDict.get("buffer_size")).getInt();
                uint64_t bufferOffset = mlir::cast<IntegerAttr>(configDict.get("buffer_offset")).getInt();
                uint8_t elementSize = mlir::cast<IntegerAttr>(configDict.get("element_size")).getInt();
                uint32_t pingAcquireLockId = mlir::cast<IntegerAttr>(configDict.get("ping_acquire_lock_id")).getInt();
                uint32_t pongAcquireLockId = mlir::cast<IntegerAttr>(configDict.get("pong_acquire_lock_id")).getInt();
                uint32_t pingReleaseLockId = mlir::cast<IntegerAttr>(configDict.get("ping_release_lock_id")).getInt();
                uint32_t pongReleaseLockId = mlir::cast<IntegerAttr>(configDict.get("pong_release_lock_id")).getInt();

                llvm::errs() << "    Config: "
                             << "tile_index=" << tileIndex
                             << ", packet_id=" << (int)packetId
                             << ", dma_channel=" << dmaChannel
                             << ", buffer_mode=" << (int)bufferMode
                             << ", num_buffers=" << (int)numBuffers
                             << ", buffer_size=" << bufferSize
                             << ", buffer_offset=" << bufferOffset
                             << ", element_size=" << (int)elementSize
                             << ", ping_acq_lock=" << pingAcquireLockId
                             << ", pong_acq_lock=" << pongAcquireLockId
                             << ", ping_rel_lock=" << pingReleaseLockId
                             << ", pong_rel_lock=" << pongReleaseLockId << "\n";
            }
            
            // NOTE: In the future, this would generate arrays of config values
            // and pass them to __Runtime_load_kernel_group(tiles, num_tiles, configs[])
            // For now, the simple call below is a placeholder
            
        } else {
            llvm::errs() << "  ERROR: No distributed_args provided\n";
            return failure();
        }
        
        // Create comment showing configuration
        std::string comment = "/* Load Kernel Group: " + std::to_string(tiles.size()) + " tile(s) */";
        rewriter.create<emitc::VerbatimOp>(loc, comment);
        
        // Define the kernel_group struct type
        auto kernelGroupType = emitc::OpaqueType::get(rewriter.getContext(), "struct kernel_group");
        
        // For now, create a simple call that encapsulates the configuration
        // In a full implementation, this would parse the arrays and pass them appropriately
        // struct kernel_group = __Runtime_load_kernel_group(...);
        
        // We'll pass tiles as an array and the number of tiles
        auto i32Type = rewriter.getI32Type();
        auto numTilesConst = rewriter.create<emitc::ConstantOp>(
            loc, i32Type, rewriter.getI32IntegerAttr(tiles.size()));
        
        // Create the call with tiles and count
        // A full implementation would also pass the symbol references and arguments
        SmallVector<Value> callOperands;
        callOperands.append(tiles.begin(), tiles.end());
        callOperands.push_back(numTilesConst.getResult());
        
        auto loadCall = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            kernelGroupType,
            "__Runtime_load_kernel_group",
            nullptr,
            nullptr,
            callOperands);
        
        llvm::errs() << "  ✓ Created __Runtime_load_kernel_group call\n";
        
        // Replace the op with the kernel_group
        rewriter.replaceOp(op, loadCall.getResult(0));
        return success();
    }
};

/// OpConversionPattern for dfschedule.schedule.launch_kernel_group
/// Converts LaunchKernelGroup to __Runtime_launch_kernel_group call
/// struct event = __Runtime_launch_kernel_group(kernel_group);
struct LaunchKernelGroupInnerPattern : public OpConversionPattern<dfschedule::LaunchKernelGroupOp> {
    ConversionState &state;
    
    LaunchKernelGroupInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state, PatternBenefit benefit = 1)
        : OpConversionPattern<dfschedule::LaunchKernelGroupOp>(typeConverter, ctx, benefit), state(state) {}
    
    LogicalResult matchAndRewrite(dfschedule::LaunchKernelGroupOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        llvm::errs() << "[Pattern] LaunchKernelGroup called\n";
        
        // Get the kernel group operand
        Value kernelGroup = adaptor.getKernelGroup();
        
        llvm::errs() << "  Kernel Group type: " << kernelGroup.getType() << "\n";
        //rewriter.eraseOp(op);
        //return success();
        // Create comment
        rewriter.create<emitc::VerbatimOp>(loc, "/* Launch Kernel Group */");
        
        // Define the event struct type (same as returned by StartIoOp)
        auto eventType = emitc::OpaqueType::get(rewriter.getContext(), "struct event");
        
        // Create __Runtime_launch_kernel_group call:
        // struct event = __Runtime_launch_kernel_group(kernel_group);
        auto launchCall = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            eventType,
            "__Runtime_launch_kernel_group",
            nullptr,
            nullptr,
            ValueRange{kernelGroup});
        
        llvm::errs() << "  ✓ Created __Runtime_launch_kernel_group call\n";
        
        // Replace the op with the event
        rewriter.replaceOp(op, launchCall.getResult(0));
        return success();
    }
};

//===----------------------------------------------------------------------===//
// Outer Patterns (Convert host op structure)
//===----------------------------------------------------------------------===//

/// Outer pattern for dfschedule.host -> emitc.func (simple shell only)
/// The inner ops are already converted by the host inner pattern phase
struct HostOpOuterPattern : public ConversionPattern {
    HostOpOuterPattern(TypeConverter &typeConverter, MLIRContext *ctx)
        : ConversionPattern(typeConverter, "dfschedule.host", /*benefit=*/1, ctx) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op->getLoc();
        
        std::string funcName = "hostruntime";
        if (auto symNameAttr = op->getAttrOfType<StringAttr>("sym_name")) {
            funcName = symNameAttr.getValue().str();
        }
        
        // Create emitc.func
        auto funcType = rewriter.getFunctionType({}, {});
        auto emitcFunc = rewriter.create<emitc::FuncOp>(loc, funcName, funcType);
        Block *entryBlock = emitcFunc.addEntryBlock();
        
        // Move converted operations from host region to new func
        if (op->getNumRegions() > 0 && !op->getRegion(0).empty()) {
            Block &srcBlock = op->getRegion(0).front();
            
            // Move all operations except terminator to the new func
            OpBuilder::InsertionGuard guard(rewriter);
            rewriter.setInsertionPointToStart(entryBlock);
            
            for (Operation &nestedOp : llvm::make_early_inc_range(srcBlock.getOperations())) {
                if (!nestedOp.hasTrait<OpTrait::IsTerminator>()) {
                    nestedOp.moveBefore(entryBlock, entryBlock->end());
                }
            }
        }
        
        // Add return at the end
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
        llvm::errs() << "[Pattern] LaunchHostPattern::matchAndRewrite called for: " << *op << "\n";
        
        // Get the host function name from the attribute
        StringRef hostFuncName = "host_canonicalized";
        if (auto symAttr = op->getAttrOfType<FlatSymbolRefAttr>("callee")) {
            hostFuncName = symAttr.getValue();
        }
        
        llvm::errs() << "[Pattern] Calling host function: " << hostFuncName << "\n";
        
        // Create emitc.call_opaque to call the host function
        rewriter.create<emitc::CallOpaqueOp>(op->getLoc(),
            TypeRange{}, hostFuncName.str(), nullptr, nullptr, ValueRange{});
        
        llvm::errs() << "[Pattern] Created call to " << hostFuncName << "()\n";
        
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
        
        // NEW signature: void dskernel(index iterations)
        auto indexType = rewriter.getIndexType();
        auto funcType = rewriter.getFunctionType({indexType}, {});
        auto emitcFunc = rewriter.create<emitc::FuncOp>(loc, kernelName, funcType);
        emitcFunc->setAttr("specifiers", rewriter.getStrArrayAttr({"__global__"}));
        
        Block *entryBlock = emitcFunc.addEntryBlock();
        OpBuilder::InsertionGuard guard(rewriter);
        rewriter.setInsertionPointToStart(entryBlock);
        
        // Get the iterations parameter
        Value iterationsParam = entryBlock->getArgument(0);
        
        // Generate kernel body that reads config from tile-local memory
        // The kernel will read from TILE_CONFIG_ADDR at runtime
        rewriter.create<emitc::VerbatimOp>(loc, rewriter.getStringAttr(
            "// Read tile-specific config from local memory at TILE_CONFIG_ADDR\n"
            "  TileConfig *config = (TileConfig *)TILE_CONFIG_ADDR;\n"
            "  uint8_t packet_id = config->packet_id;\n"
            "  uint32_t dma_channel = config->dma_channel;\n"
            "  uint8_t buffer_mode = config->buffer_mode;\n"
            "  uint8_t num_buffers = config->num_buffers;\n"
            "  uint32_t buffer_size = config->buffer_size;\n"
            "  void *buffer_addr = (void *)config->buffer_addr;\n"
            "  uint8_t element_size = config->element_size;\n"
            "  // TODO: Implement kernel logic using above config"
        ));
        
        rewriter.create<emitc::ReturnOp>(loc, Value{});
        
        llvm::errs() << "[Pattern] Created __global__ func: " << kernelName 
                     << " with signature (index iterations)\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

//===----------------------------------------------------------------------===//
// Kernel Module Conversion Pattern
//===----------------------------------------------------------------------===//

/// Structure to hold buffer definition info
struct BufferDefInfo {
    std::string name;
    int64_t size = 256;
    int32_t vectorWidth = 4;
    std::string elementType = "int32";
};

/// Structure to hold window parameter information
struct WindowParamInfo {
    std::string windowSymbol;    // e.g., "window_out_0"
    bool isInput;                // true = input, false = output
    std::string elementTypeName; // e.g., "int32", "int8"
    std::string bufferPingName;  // e.g., "buf_out_ping_0" or "out_ping"
    std::string bufferPongName;  // e.g., "buf_out_pong_0" or "out_pong"
    int32_t acquireLockId;       // Lock ID for acquire
    int32_t releaseLockId;       // Lock ID for release
};

/// Structure to hold extracted kernel module information
struct KernelModuleInfo {
    std::string moduleName;
    std::string kernelName;
    std::string kernelFile;
    int32_t bufferSize = 256;
    std::string elementType = "int32_t";
    int32_t vectorWidth = 4;
    std::string iterationStyle = "internal"; // "internal" or "external"

    // Lock IDs
    int32_t inputAcquireLockId = 48;
    int32_t inputReleaseLockId = 49;
    int32_t outputAcquireLockId = 51;
    int32_t outputReleaseLockId = 50;

    // Window names
    std::string inputWindowName = "win";
    std::string outputWindowName = "out";

    // Buffer definitions extracted from dfschedule.buffer_def ops
    SmallVector<BufferDefInfo> bufferDefs;

    // Dynamic window parameters extracted from dfschedule.main
    SmallVector<WindowParamInfo> windowParams;
};

/// Extract kernel module information from dfschedule.module operation
static KernelModuleInfo extractKernelModuleInfo(dfschedule::KernelModuleOp moduleOp) {
    KernelModuleInfo info;
    info.moduleName = moduleOp.getSymName().str();

    // Walk through the module body to extract definitions
    moduleOp.getBody().walk([&](Operation *op) {
        // Extract kernel config
        if (auto configOp = dyn_cast<dfschedule::KernelConfigDefOp>(op)) {
            DictionaryAttr configDict = configOp.getConfigAttrs();
            if (auto kernelNameAttr = configDict.getAs<StringAttr>("kernel_name")) {
                info.kernelName = kernelNameAttr.getValue().str();
            }
            if (auto kernelFileAttr = configDict.getAs<StringAttr>("kernel_file")) {
                info.kernelFile = kernelFileAttr.getValue().str();
            }
            if (auto bufSizeAttr = configDict.getAs<IntegerAttr>("buffer_size")) {
                info.bufferSize = bufSizeAttr.getInt();
            }
            if (auto vecWidthAttr = configDict.getAs<IntegerAttr>("vector_width")) {
                info.vectorWidth = vecWidthAttr.getInt();
            }
            if (auto elemTypeAttr = configDict.getAs<TypeAttr>("element_type")) {
                Type elemType = elemTypeAttr.getValue();
                if (elemType.isInteger(32))
                    info.elementType = "int32_t";
                else if (elemType.isInteger(16))
                    info.elementType = "int16_t";
                else if (elemType.isInteger(8))
                    info.elementType = "int8_t";
                else if (elemType.isF32())
                    info.elementType = "float";
            }
        }

        // Extract lock definitions
        if (auto lockOp = dyn_cast<dfschedule::LockDefOp>(op)) {
            std::string lockName = lockOp.getSymName().str();
            int32_t lockId = lockOp.getId();

            if (lockName.find("win") != std::string::npos && lockName.find("ACQ") != std::string::npos) {
                info.inputAcquireLockId = lockId;
            } else if (lockName.find("win") != std::string::npos && lockName.find("REL") != std::string::npos) {
                info.inputReleaseLockId = lockId;
            } else if (lockName.find("out") != std::string::npos && lockName.find("ACQ") != std::string::npos) {
                info.outputAcquireLockId = lockId;
            } else if (lockName.find("out") != std::string::npos && lockName.find("REL") != std::string::npos) {
                info.outputReleaseLockId = lockId;
            }
        }

        // Extract kernel declaration to get iteration style
        if (auto kernelDeclOp = dyn_cast<dfschedule::KernelDeclOp>(op)) {
            info.kernelName = kernelDeclOp.getSymName().str();
            DictionaryAttr declAttrs = kernelDeclOp.getDeclAttrs();
            if (auto iterStyleAttr = declAttrs.getAs<StringAttr>("iteration_style")) {
                info.iterationStyle = iterStyleAttr.getValue().str();
            }
        }

        // Extract window definitions
        if (auto windowOp = dyn_cast<dfschedule::WindowDefOp>(op)) {
            std::string windowName = windowOp.getSymName().str();
            DictionaryAttr windowAttrs = windowOp.getWindowAttrs();
            if (auto directionAttr = windowAttrs.getAs<StringAttr>("direction")) {
                if (directionAttr.getValue() == "in") {
                    info.inputWindowName = windowName;
                } else if (directionAttr.getValue() == "out") {
                    info.outputWindowName = windowName;
                }
            }
        }

        // Extract buffer definitions
        if (auto bufferOp = dyn_cast<dfschedule::BufferDefOp>(op)) {
            BufferDefInfo bufInfo;
            bufInfo.name = bufferOp.getSymName().str();

            // Parse buffer type: memref<256xvector<4xi32>, "LOCAL">
            TypeAttr bufferTypeAttr = bufferOp.getBufferTypeAttr();
            if (auto memrefType = dyn_cast<MemRefType>(bufferTypeAttr.getValue())) {
                // Get shape (e.g., 256)
                if (!memrefType.getShape().empty()) {
                    bufInfo.size = memrefType.getShape()[0];
                }

                // Get element type (could be vector<4xi32>)
                Type elemType = memrefType.getElementType();
                if (auto vecType = dyn_cast<VectorType>(elemType)) {
                    // Vector type: extract width and element type
                    if (!vecType.getShape().empty()) {
                        bufInfo.vectorWidth = vecType.getShape()[0];
                    }
                    Type scalarType = vecType.getElementType();
                    if (scalarType.isInteger(32))
                        bufInfo.elementType = "int32";
                    else if (scalarType.isInteger(16))
                        bufInfo.elementType = "int16";
                    else if (scalarType.isInteger(8))
                        bufInfo.elementType = "int8";
                    else if (scalarType.isF32())
                        bufInfo.elementType = "float";
                } else {
                    // Scalar type
                    bufInfo.vectorWidth = 1;
                    if (elemType.isInteger(32))
                        bufInfo.elementType = "int32";
                    else if (elemType.isInteger(16))
                        bufInfo.elementType = "int16";
                    else if (elemType.isInteger(8))
                        bufInfo.elementType = "int8";
                    else if (elemType.isF32())
                        bufInfo.elementType = "float";
                }
            }

            info.bufferDefs.push_back(bufInfo);
        }

        // Extract dfschedule.main to get dynamic window parameters
        if (auto mainOp = dyn_cast<dfschedule::KernelMainOp>(op)) {
            llvm::errs() << "[extractKernelModuleInfo] Found dfschedule.main\n";

            // Build a map: window symbol -> window definition attributes
            llvm::StringMap<DictionaryAttr> windowDefMap;
            moduleOp.getBody().walk([&](dfschedule::WindowDefOp winDefOp) {
                windowDefMap[winDefOp.getSymName()] = winDefOp.getWindowAttrs();
                llvm::errs() << "[extractKernelModuleInfo]   Found window def: " << winDefOp.getSymName() << "\n";
            });

            // Walk the main body to find window_init operations
            llvm::errs() << "[extractKernelModuleInfo] Walking main body for window_init ops\n";
            mainOp.getBody().walk([&](dfschedule::WindowInitOp winInitOp) {
                llvm::errs() << "[extractKernelModuleInfo]   Found window_init op\n";
                WindowParamInfo paramInfo;

                // Get window symbol reference from the operation's attribute
                SymbolRefAttr windowRef = winInitOp.getWindowRefAttr();
                paramInfo.windowSymbol = windowRef.getRootReference().getValue().str();

                // Determine if input or output from result type
                Type resultType = winInitOp.getResult().getType();
                if (auto inputWinType = dyn_cast<dfschedule::InputWindowType>(resultType)) {
                    paramInfo.isInput = true;
                    Type elemType = inputWinType.getElementType();
                    if (elemType.isInteger(32))
                        paramInfo.elementTypeName = "int32";
                    else if (elemType.isInteger(16))
                        paramInfo.elementTypeName = "int16";
                    else if (elemType.isInteger(8))
                        paramInfo.elementTypeName = "int8";
                    else if (elemType.isF32())
                        paramInfo.elementTypeName = "float";
                } else if (auto outputWinType = dyn_cast<dfschedule::OutputWindowType>(resultType)) {
                    paramInfo.isInput = false;
                    Type elemType = outputWinType.getElementType();
                    if (elemType.isInteger(32))
                        paramInfo.elementTypeName = "int32";
                    else if (elemType.isInteger(16))
                        paramInfo.elementTypeName = "int16";
                    else if (elemType.isInteger(8))
                        paramInfo.elementTypeName = "int8";
                    else if (elemType.isF32())
                        paramInfo.elementTypeName = "float";
                }

                // Lookup window definition to get buffer names and lock IDs
                auto it = windowDefMap.find(paramInfo.windowSymbol);
                if (it != windowDefMap.end()) {
                    DictionaryAttr windowAttrs = it->second;

                    // Get ping/pong buffer names
                    if (auto pingBufAttr = windowAttrs.getAs<SymbolRefAttr>("ping_buffer")) {
                        paramInfo.bufferPingName = pingBufAttr.getRootReference().getValue().str();
                    }
                    if (auto pongBufAttr = windowAttrs.getAs<SymbolRefAttr>("pong_buffer")) {
                        paramInfo.bufferPongName = pongBufAttr.getRootReference().getValue().str();
                    }

                    // Get acquire/release lock symbols and lookup their IDs
                    if (auto acqLockAttr = windowAttrs.getAs<SymbolRefAttr>("acquire_lock")) {
                        std::string acqLockName = acqLockAttr.getRootReference().getValue().str();
                        // Find the lock definition to get the actual ID
                        moduleOp.getBody().walk([&](dfschedule::LockDefOp lockOp) {
                            if (lockOp.getSymName().str() == acqLockName) {
                                paramInfo.acquireLockId = lockOp.getId();
                            }
                        });
                    }
                    if (auto relLockAttr = windowAttrs.getAs<SymbolRefAttr>("release_lock")) {
                        std::string relLockName = relLockAttr.getRootReference().getValue().str();
                        // Find the lock definition to get the actual ID
                        moduleOp.getBody().walk([&](dfschedule::LockDefOp lockOp) {
                            if (lockOp.getSymName().str() == relLockName) {
                                paramInfo.releaseLockId = lockOp.getId();
                            }
                        });
                    }
                }

                llvm::errs() << "[extractKernelModuleInfo]   Window param: " << paramInfo.windowSymbol
                             << ", isInput=" << paramInfo.isInput << ", elemType=" << paramInfo.elementTypeName
                             << ", ping=" << paramInfo.bufferPingName << ", pong=" << paramInfo.bufferPongName
                             << ", acqLock=" << paramInfo.acquireLockId << ", relLock=" << paramInfo.releaseLockId
                             << "\n";

                info.windowParams.push_back(paramInfo);
            });

            llvm::errs() << "[extractKernelModuleInfo] Extracted " << info.windowParams.size()
                         << " window parameters\n";
        }
    });

    return info;
}

/// Generate C++ kernel driver code from KernelModuleInfo
static std::string generateKernelDriverCode(const KernelModuleInfo &info) {
    std::ostringstream code;

    llvm::errs() << "[generateKernelDriverCode] Called with " << info.windowParams.size() << " window parameters\n";

    // Vector type name (e.g., "v4int32")
    std::string vecTypeName = "v" + std::to_string(info.vectorWidth) + info.elementType;
    // Simplify type name for vector (int32_t -> int32)
    std::string vecTypeSimple = info.elementType;
    if (vecTypeSimple == "int32_t")
        vecTypeSimple = "int32";
    else if (vecTypeSimple == "int16_t")
        vecTypeSimple = "int16";
    else if (vecTypeSimple == "int8_t")
        vecTypeSimple = "int8";
    vecTypeName = "v" + std::to_string(info.vectorWidth) + vecTypeSimple;

    // Generate includes and defines
    code << "/* ========== Kernel Driver: " << info.moduleName << " ========== */\n";
    code << "#include <adf.h>\n";
    code << "#include <aie_api/aie.hpp>\n";
    code << "#include <aie_api/aie_adf.hpp>\n";
    code << "#define FOR_READ  1\n";
    code << "#define FOR_WRITE 0\n";
    code << "#define BUF_SZ " << info.bufferSize << "\n\n";

    code << "volatile static int sync_buffer[8] = {0, -1};\n\n";
    code << "#include <adf/sync/mesync.h>\n\n";

    // Generate debug logging helpers
    code << "// =============================================================================\n";
    code << "// Debug logging at fixed address 0x73000\n";
    code << "// =============================================================================\n";
    code << "#define LOG_BASE_ADDR 0x73000\n";
    code << "static volatile int* log_ptr = (volatile int*)LOG_BASE_ADDR;\n";
    code << "static int log_index = 0;\n\n";
    code << "inline void log(int value) { log_ptr[log_index++] = value; }\n";
    code << "inline void log_at(int index, int value) { log_ptr[index] = value; }\n";
    code << "inline void log_reset() { log_index = 0; }\n\n";

    // Generate lock defines
    code << "#define LOCK_win_ping_ACQ " << info.inputAcquireLockId << "\n";
    code << "#define LOCK_win_pong_REL " << info.inputReleaseLockId << "\n";
    code << "#define LOCK_out_ping_ACQ " << info.outputAcquireLockId << "\n";
    code << "#define LOCK_out_pong_REL " << info.outputReleaseLockId << "\n\n";

    // Generate buffer declarations from extracted buffer definitions
    if (!info.bufferDefs.empty()) {
        for (const auto &buf : info.bufferDefs) {
            std::string bufVecType = "v" + std::to_string(buf.vectorWidth) + buf.elementType;
            code << bufVecType << " " << buf.name << "[BUF_SZ];\n";
        }
        code << "\n";
    } else {
        // Fallback to default buffer names if no buffer defs extracted
        code << vecTypeName << " win_ping[BUF_SZ];\n";
        code << vecTypeName << " win_pong[BUF_SZ];\n";
        code << vecTypeName << " out_ping[BUF_SZ];\n";
        code << vecTypeName << " out_pong[BUF_SZ];\n\n";
    }

    // Include the kernel file
    if (!info.kernelFile.empty()) {
        code << "#include \"" << info.kernelFile << "\"\n\n";
    }

    // Generate main function (kernel driver entry point)
    code << "int main(void) {\n";
    code << "    log(1);  // Log: entering main\n";
    code << "    sync_buffer[0] = 0; // reset end signal\n\n";

    // Generate kernel invocation based on iteration style
    if (info.iterationStyle == "internal") {
        // Legacy style: window_init once, call kernel once
        code << "    // Legacy style: kernel handles iterations internally\n";

        // Use dynamic window parameters if available
        if (!info.windowParams.empty()) {
            // Dynamic mode: generate window initialization for each parameter
            SmallVector<std::string> windowPtrVars;

            for (size_t i = 0; i < info.windowParams.size(); ++i) {
                const auto &param = info.windowParams[i];
                std::string windowVarName = "window_" + param.windowSymbol;
                std::string ptrVarName = param.windowSymbol + "_ptr";
                std::string lockAcqName = "LOCK_" + param.windowSymbol + "_ACQ";
                std::string lockRelName = "LOCK_" + param.windowSymbol + "_REL";

                // Generate window_internal declaration
                code << "    window_internal " << windowVarName << "[1];\n";

                // Generate window_init call with actual buffer and lock names
                code << "    window_init(" << windowVarName << ", 1, " << param.bufferPingName << ", "
                     << param.acquireLockId << ", " << param.bufferPongName << ", " << param.releaseLockId
                     << ", BUF_SZ, BUF_SZ);\n";

                // Generate get_input/output_async_window call
                if (param.isInput) {
                    code << "    input_window_" << param.elementTypeName << "* " << ptrVarName
                         << " = get_input_async_window_" << param.elementTypeName << "(" << windowVarName << ");\n\n";
                } else {
                    code << "    output_window_" << param.elementTypeName << "* " << ptrVarName
                         << " = get_output_async_window_" << param.elementTypeName << "(" << windowVarName << ");\n\n";
                }

                windowPtrVars.push_back(ptrVarName);
            }

            // Generate kernel call with dynamic arguments
            code << "    // Call kernel\n";
            code << "    " << info.kernelName << "(";
            for (size_t i = 0; i < windowPtrVars.size(); ++i) {
                if (i > 0)
                    code << ", ";
                code << windowPtrVars[i];
            }
            code << ");\n";
        } else {
            // Fallback: hardcoded mode (backward compatibility)
            code << "    window_internal window_win_ping[1];\n";
            code << "    window_init(window_win_ping, 1, win_ping, LOCK_win_ping_ACQ, win_pong, LOCK_win_pong_REL, "
                    "BUF_SZ, "
                    "BUF_SZ);\n";
            code << "    input_window_int32* win_ping_ptr = get_input_async_window_int32(window_win_ping);\n\n";
            code << "    window_internal window_out_ping[1];\n";
            code << "    window_init(window_out_ping, 1, out_ping, LOCK_out_ping_ACQ, out_pong, LOCK_out_pong_REL, "
                    "BUF_SZ, "
                    "BUF_SZ);\n";
            code << "    output_window_int32* out_ping_ptr = get_output_async_window_int32(window_out_ping);\n\n";
            code << "    // Call kernel\n";
            code << "    " << info.kernelName << "(win_ping_ptr, out_ping_ptr);\n";
        }
    } else {
        // ADF style: loop with acquire/release
        code << "    // ADF style: wrapper handles iterations with acquire/release\n";

        // Use dynamic window parameters if available
        if (!info.windowParams.empty()) {
            // Dynamic mode: generate window initialization for each parameter
            SmallVector<std::string> windowVarNames;

            for (size_t i = 0; i < info.windowParams.size(); ++i) {
                const auto &param = info.windowParams[i];
                std::string windowVarName = "window_" + param.windowSymbol;

                // Generate window_internal declaration
                code << "    window_internal " << windowVarName << "[1];\n";

                // Generate window_init call
                code << "    window_init(" << windowVarName << ", 1, " << param.bufferPingName << ", "
                     << param.acquireLockId << ", " << param.bufferPongName << ", " << param.releaseLockId
                     << ", BUF_SZ, BUF_SZ);\n\n";

                windowVarNames.push_back(windowVarName);
            }

            code << "    for(int i = 0; i < iterations; i++) {\n";

            // Generate window_acquire calls for each parameter
            SmallVector<std::string> ptrVars;
            for (size_t i = 0; i < info.windowParams.size(); ++i) {
                const auto &param = info.windowParams[i];
                std::string ptrVar = param.windowSymbol + "_ptr";

                if (param.isInput) {
                    code << "        input_window_" << param.elementTypeName << "* " << ptrVar
                         << " = window_acquire_in(" << windowVarNames[i] << ");\n";
                } else {
                    code << "        output_window_" << param.elementTypeName << "* " << ptrVar
                         << " = window_acquire_out(" << windowVarNames[i] << ");\n";
                }
                ptrVars.push_back(ptrVar);
            }

            // Generate kernel call with dynamic arguments
            code << "        " << info.kernelName << "(";
            for (size_t i = 0; i < ptrVars.size(); ++i) {
                if (i > 0)
                    code << ", ";
                code << ptrVars[i];
            }
            code << ");\n";

            // Generate window_release calls for each parameter
            for (const auto &windowVar : windowVarNames) {
                code << "        window_release(" << windowVar << ");\n";
            }

            code << "    }\n";
        } else {
            // Fallback: hardcoded mode (backward compatibility)
            code << "    window_internal window_win_ping[1];\n";
            code << "    window_init(window_win_ping, 1, win_ping, LOCK_win_ping_ACQ, win_pong, LOCK_win_pong_REL, "
                    "BUF_SZ, "
                    "BUF_SZ);\n\n";
            code << "    window_internal window_out_ping[1];\n";
            code << "    window_init(window_out_ping, 1, out_ping, LOCK_out_ping_ACQ, out_pong, LOCK_out_pong_REL, "
                    "BUF_SZ, "
                    "BUF_SZ);\n\n";
            code << "    for(int i = 0; i < iterations; i++) {\n";
            code << "        input_window_int32* win_ptr = window_acquire_in(window_win_ping);\n";
            code << "        output_window_int32* out_ptr = window_acquire_out(window_out_ping);\n";
            code << "        " << info.kernelName << "(win_ptr, out_ptr);\n";
            code << "        window_release(window_win_ping);\n";
            code << "        window_release(window_out_ping);\n";
            code << "    }\n";
        }
    }

    code << "\n    done();\n";
    code << "    return 0;\n";
    code << "}\n";
    code << "/* ========== End Kernel Driver ========== */\n";

    return code.str();
}

/// ConversionPattern for dfschedule.module -> EmitC verbatim kernel code
struct KernelModuleConversionPattern : public ConversionPattern {
    KernelModuleConversionPattern(TypeConverter &typeConverter, MLIRContext *ctx)
        : ConversionPattern(typeConverter, "dfschedule.module", /*benefit=*/1, ctx) {}

    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        auto moduleOp = cast<dfschedule::KernelModuleOp>(op);
        auto loc = op->getLoc();

        llvm::errs() << "[Pattern] KernelModuleConversionPattern for: " << moduleOp.getSymName() << "\n";

        // Extract module information
        KernelModuleInfo info = extractKernelModuleInfo(moduleOp);

        llvm::errs() << "  Kernel name: " << info.kernelName << "\n";
        llvm::errs() << "  Iteration style: " << info.iterationStyle << "\n";
        llvm::errs() << "  Buffer size: " << info.bufferSize << "\n";
        llvm::errs() << "  Vector width: " << info.vectorWidth << "\n";

        // Generate the kernel driver C++ code
        std::string kernelCode = generateKernelDriverCode(info);

        // Create verbatim op with the generated code
        rewriter.create<emitc::VerbatimOp>(loc, rewriter.getStringAttr(kernelCode));

        llvm::errs() << "  ✓ Generated kernel driver code\n";

        // Erase the original module op
        rewriter.eraseOp(op);
        return success();
    }
};

/// Erase pattern for kernel module nested operations
template <typename OpT> struct EraseKernelModuleNestedOp : public OpConversionPattern<OpT> {
    using OpConversionPattern<OpT>::OpConversionPattern;

    LogicalResult matchAndRewrite(OpT op, typename OpT::Adaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // These ops are handled as part of the parent KernelModuleOp conversion
        rewriter.eraseOp(op);
        return success();
    }
};

//===----------------------------------------------------------------------===//
// Helper Functions
//===----------------------------------------------------------------------===//

/// Generate C array literal from DenseElementsAttr
static std::string generateCArrayLiteral(DenseElementsAttr denseAttr) {
    std::string result = "{";
    bool first = true;
    
    if (auto floatAttr = dyn_cast<DenseFPElementsAttr>(denseAttr)) {
        for (auto val : floatAttr.getValues<APFloat>()) {
            if (!first) result += ", ";
            first = false;
            SmallString<16> strVal;
            val.toString(strVal);
            result += strVal.str().str();
        }
    } else if (auto intAttr = dyn_cast<DenseIntElementsAttr>(denseAttr)) {
        for (auto val : intAttr.getValues<APInt>()) {
            if (!first) result += ", ";
            first = false;
            result += std::to_string(val.getSExtValue());
        }
    } else {
        // Fallback for other types
        result += "0";
    }
    
    result += "}";
    return result;
}

static Type buildVoidPtrType(MLIRContext *ctx) {
    // void*  (emitc.ptr<emitc.opaque<"void">>)
    return emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
}
  
static void setupTypeConverter(TypeConverter &typeConverter, MLIRContext *ctx) {
    Type voidPtrTy = buildVoidPtrType(ctx);
    
    // DO NOT convert tensor types globally - this causes unwanted materializations
    // for operations we're not converting yet (like tensor.extract_slice)
    // Instead, handle type changes explicitly in each pattern's replaceOp() call
    
    // Identity conversion for all types
    typeConverter.addConversion([voidPtrTy](Type t) -> Type { 
        // Just return the type as-is
        return t; 
    });
  
    // Materialization callbacks to handle value conversions
    auto castIfNeeded =
        [](OpBuilder &builder, Type resultType, ValueRange inputs, Location loc)
        -> std::optional<Value> {
          if (inputs.size() != 1) {
              llvm::errs() << "[Materialization] ERROR: Wrong number of inputs: " << inputs.size() << "\n";
              return std::nullopt;
          }
          
          // Check if input is null
          if (!inputs[0]) {
              llvm::errs() << "[Materialization] ERROR: Input value is NULL!\n";
              llvm::errs() << "[Materialization] ERROR: Requested result type: " << resultType << "\n";
              return std::nullopt;
          }
          
          if (inputs[0].getType() == resultType) {
              llvm::errs() << "[Materialization] Types match, returning input directly\n";
              return inputs[0];
          }
          
          llvm::errs() << "[Materialization] Creating cast from " << inputs[0].getType() << " to " << resultType << "\n";
          // Create unrealized cast for type mismatches
          return builder.create<UnrealizedConversionCastOp>(loc, resultType, inputs[0])
              .getResult(0);
        };
  
    typeConverter.addSourceMaterialization(castIfNeeded);
    typeConverter.addTargetMaterialization(castIfNeeded);
    typeConverter.addArgumentMaterialization(castIfNeeded);
}
//===----------------------------------------------------------------------===//
// Pass Implementation - Two-Phase Conversion with Walk + Patterns
//===----------------------------------------------------------------------===//

void DfscheduleToApiPass::runOnOperation() {
    llvm::errs() << "=== DfscheduleToApiPass START ===\n";
    
    ModuleOp moduleOp = getOperation();
    MLIRContext *ctx = moduleOp.getContext();
    
    // Shared conversion state
    ConversionState state;
    
    // Type converter
    TypeConverter typeConverter;
    setupTypeConverter(typeConverter, ctx);  
    
    llvm::errs() << "convert tensor -> "
             << typeConverter.convertType(
                    RankedTensorType::get({16,16},
                      IntegerType::get(ctx, 8)))
             << "\n";
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
            "static inline void __Runtime_track_alloc(XAie_MemInst* mem) {\n"
            "    if (g_alloc_mem_count < ALLOC_LIST_MAX_SIZE) {\n"
            "        g_alloc_mem_list[g_alloc_mem_count++] = mem;\n"
            "    }\n"
            "}\n\n"
            "/* Free all tracked memory allocations */\n"
            "static inline void __Runtime_free_all_allocs() {\n"
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
            "static inline PartitionTensor __Runtime_init_PartitionTensor(\n"
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
            "static inline void* __Runtime_get_partition_slice(\n"
            "    PartitionTensor* pt, int partition_idx) {\n"
            "    if (partition_idx < 0 || partition_idx >= pt->num_partitions) return NULL;\n"
            "    /* Calculate slice offset based on partition dimension */\n"
            "    size_t slice_size = pt->elem_size;\n"
            "    for (int i = 0; i < pt->ndim; i++) {\n"
            "        slice_size *= pt->partition_shape[i];\n"
            "    }\n"
            "    return (void*)((char*)pt->data + partition_idx * slice_size);\n"
            "}\n\n"
            "/* Extract contiguous 2D slice from PartitionTensor */\n"
            "/* Takes PartitionTensor by value for cleaner generated code */\n"
            "static inline PartitionTensor __Runtime_extract_slice_contiguous_2d(\n"
            "    PartitionTensor src, int off0, int off1, int size0, int size1) {\n"
            "    PartitionTensor result;\n"
            "    result.elem_size = src.elem_size;\n"
            "    result.ndim = 2;\n"
            "    result.partition_dim = -1;\n"
            "    result.num_partitions = 1;\n"
            "    result.hw_axis_owner = src.hw_axis_owner;\n"
            "    result.replicate_on = src.replicate_on;\n"
            "    result.original_shape[0] = size0;\n"
            "    result.original_shape[1] = size1;\n"
            "    result.partition_shape[0] = size0;\n"
            "    result.partition_shape[1] = size1;\n"
            "    \n"
            "    /* Calculate byte offset: off0 * dim1 * elem_size + off1 * elem_size */\n"
            "    size_t byte_offset = (off0 * src.original_shape[1] + off1) * src.elem_size;\n"
            "    result.data = (void*)((char*)src.data + byte_offset);\n"
            "    return result;\n"
            "}\n\n"
            "/* Extract 2D non-contiguous slice from PartitionTensor */\n"
            "/* Allocates new memory via XAie_MemAllocate, copies strided data */\n"
            "static inline PartitionTensor __Runtime_extract_slice_strided_2d(\n"
            "    XAie_DevInst* dev_inst, PartitionTensor src,\n"
            "    int off0, int off1, int size0, int size1) {\n"
            "    PartitionTensor result;\n"
            "    result.elem_size = src.elem_size;\n"
            "    result.ndim = 2;\n"
            "    result.partition_dim = -1;\n"
            "    result.num_partitions = 1;\n"
            "    result.hw_axis_owner = src.hw_axis_owner;\n"
            "    result.replicate_on = src.replicate_on;\n"
            "    result.original_shape[0] = size0;\n"
            "    result.original_shape[1] = size1;\n"
            "    result.partition_shape[0] = size0;\n"
            "    result.partition_shape[1] = size1;\n"
            "    \n"
            "    /* Calculate destination size */\n"
            "    size_t dst_size = (size_t)size0 * size1 * src.elem_size;\n"
            "    \n"
            "    /* Allocate memory for the slice */\n"
            "    XAie_MemInst* mem_inst = XAie_MemAllocate(*dev_inst, dst_size, XAIE_MEM_CACHEABLE);\n"
            "    if (!mem_inst) {\n"
            "        result.data = NULL;\n"
            "        return result;\n"
            "    }\n"
            "    __Runtime_track_alloc(mem_inst);\n"
            "    \n"
            "    void* dst = XAie_MemGetVAddr(mem_inst);\n"
            "    result.data = dst;\n"
            "    if (!dst) return result;\n"
            "    \n"
            "    /* Copy strided data to contiguous destination */\n"
            "    char* d = (char*)dst;\n"
            "    char* s = (char*)src.data;\n"
            "    int elem_size = src.elem_size;\n"
            "    int src_dim1 = src.original_shape[1];\n"
            "    for (int i = 0; i < size0; i++) {\n"
            "        int src_idx = ((off0 + i) * src_dim1 + off1) * elem_size;\n"
            "        int dst_idx = (i * size1) * elem_size;\n"
            "        memcpy(d + dst_idx, s + src_idx, size1 * elem_size);\n"
            "    }\n"
            "    return result;\n"
            "}"
        ));
        
        auto devInstType = emitc::OpaqueType::get(ctx, "XAie_DevInst");
        builder.create<emitc::GlobalOp>(moduleOp.getLoc(),
            "DevInst", devInstType, Attribute{}, true, false, false);
    }
    
    llvm::errs() << "[Pass] Phase 1: Helper definitions generated\n";
    
    //==========================================================================
    // Phase 2: Convert dense constants at module level
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 2: Converting dense constants\n";
    
    // Walk and manually convert dense constants to global arrays
    moduleOp.walk([&](arith::ConstantOp constOp) {
        auto denseAttr = dyn_cast<DenseElementsAttr>(constOp.getValue());
        if (!denseAttr) return;
        
        // Create global array name
        std::string arrayName = "g_data_array_" + std::to_string(state.arrayIndex++);
        
        // Store the array name as an attribute on the operation for later retrieval
        constOp->setAttr("emitc.global_array_name", 
                         StringAttr::get(moduleOp.getContext(), arrayName));
        
        // Generate C array literal
        std::string cArrayInit = generateCArrayLiteral(denseAttr);
        
        // Get element type
        Type elemType = denseAttr.getElementType();
        std::string cType;
        if (elemType.isF32()) {
            cType = "float";
        } else if (elemType.isInteger(32)) {
            cType = "int32_t";
        } else if (elemType.isInteger(64)) {
            cType = "int64_t";
        } else {
            cType = "int";
        }
        
        // Get shape
        auto tensorType = dyn_cast<RankedTensorType>(constOp.getType());
        if (!tensorType) return;
        
        auto shape = tensorType.getShape();
        std::string shapeStr;
        for (auto dim : shape) {
            shapeStr += "[" + std::to_string(dim) + "]";
        }
        
        // Create verbatim array declaration at the same location as the original constant
        OpBuilder builder(moduleOp.getContext());
        builder.setInsertionPoint(constOp);
        
        std::string arrayDecl = "static " + cType + " " + arrayName + shapeStr + " = " + cArrayInit + ";";
        builder.create<emitc::VerbatimOp>(constOp.getLoc(), arrayDecl);
        
        llvm::errs() << "[Pattern] Created array: " << arrayName << " at original location\n";
    });
    
    //==========================================================================
    // Phase 3: Walk dfschedule.host ops and apply inner patterns
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 3: Converting inner ops in dfschedule.host regions\n";
    
    // Setup common types for inner patterns
    state.ctx = ctx;
    state.i32Type = IntegerType::get(ctx, 32);
    state.voidPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "void"));
    state.memInstPtrType = emitc::PointerType::get(emitc::OpaqueType::get(ctx, "XAie_MemInst"));
    state.devInstType = emitc::OpaqueType::get(ctx, "XAie_DevInst");
    state.partitionType = emitc::OpaqueType::get(ctx, "PartitionTensor");
    
    // Create inner patterns (arith.constant, declare_data, partitiontensor, extract_slice, erase ops)
    RewritePatternSet innerPatterns(ctx);
    
    // Add arith.constant -> emitc.constant conversion (for scalar constants)
    innerPatterns.add<ArithConstantInnerPattern>(typeConverter, ctx, state);
    
    // Add actual conversion patterns for inner ops
    // Higher benefits = run first. We need DeclareTile and DeclareTensor to run before ConfigDmaBd
    innerPatterns.add<DeclareDataInnerPattern>(typeConverter, ctx);
    innerPatterns.add<PartitionTensorInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<ExtractSliceInnerPattern>(typeConverter, ctx, state);
    
    // These must run BEFORE ConfigDmaBdOp and ConfigCreateIoOp (higher benefit = 100)
    innerPatterns.add<DeclareTensorInnerPattern>(typeConverter, ctx, state, /*benefit=*/100);
    innerPatterns.add<DeclareTileInnerPattern>(typeConverter, ctx, state, /*benefit=*/100);
    
    // ConfigDmaBdOp must run before ConfigCreateIoOp (benefit = 50)
    innerPatterns.add<ConfigDmaBdInnerPattern>(typeConverter, ctx, state, /*benefit=*/50);
    
    // GetBdIdOp allocates BD IDs and should run with medium priority (benefit = 30)
    innerPatterns.add<GetBdIdInnerPattern>(typeConverter, ctx, state, /*benefit=*/30);
    
    // ConfigCreateIoOp must run before StartIoOp (benefit = 10)
    innerPatterns.add<ConfigCreateIoInnerPattern>(typeConverter, ctx, state, /*benefit=*/10);
    
    // StartIoOp depends on ConfigCreateIoOp (benefit = 1)
    innerPatterns.add<StartIoInnerPattern>(typeConverter, ctx, state, /*benefit=*/1);
    
    // ScheduleWaitOp depends on StartIoOp (benefit = 1)
    innerPatterns.add<ScheduleWaitInnerPattern>(typeConverter, ctx, state, /*benefit=*/1);
    
    // LoadKernelGroupOp loads and configures kernel groups (benefit = 2)
    innerPatterns.add<LoadKernelGroupInnerPattern>(typeConverter, ctx, state, /*benefit=*/2);
    
    // DeclareKernelConfigOp is just metadata (benefit = 5, run early)
    innerPatterns.add<DeclareKernelConfigInnerPattern>(typeConverter, ctx, /*benefit=*/5);
    
    // LaunchKernelGroupOp depends on LoadKernelGroupOp (benefit = 1)
    innerPatterns.add<LaunchKernelGroupInnerPattern>(typeConverter, ctx, state, /*benefit=*/1);
    
    // Add EraseOpLowering patterns for ops that should simply be erased
    // NOTE: tensor.extract_slice, routing.partitiontensor, declare_data are NOT here - they are converted above
    // NOTE: ScheduleWaitOp, StartIoOp, GetBdIdOp, ConfigCreateIoOp, ConfigDmaBdOp, DeclareTileOp, DeclareTensorOp,
    //       LoadKernelGroupOp, LaunchKernelGroupOp are now converted by their respective Inner patterns
    // NOTE: LaunchHostOp is handled in Phase 4, not here
    innerPatterns.add<
        EraseOpLowering<routing::partitiontensor>
    >(typeConverter, ctx);

    FrozenRewritePatternSet frozenInnerPatterns(std::move(innerPatterns));
    ConversionTarget innerTarget(*ctx);
    innerTarget.addLegalDialect<emitc::EmitCDialect>();
    innerTarget.addLegalDialect<scf::SCFDialect>();
    
    // Mark arith dialect as legal, but with exceptions for arith.constant
    innerTarget.addLegalDialect<arith::ArithDialect>();
    
    // Use dynamic legality for arith.constant:
    // ALL arith.constant ops should be converted to emitc.constant
    innerTarget.addDynamicallyLegalOp<arith::ConstantOp>([&](arith::ConstantOp op) {
        // All constants are illegal - need conversion to emitc.constant
        return false;
    });
    
    // Mark typed ops as illegal (need conversion)
    innerTarget.addIllegalOp<tensor::ExtractSliceOp>();
    innerTarget.addIllegalOp<routing::partitiontensor>();
    innerTarget.addIllegalOp<dfschedule::ScheduleWaitOp>();
    innerTarget.addIllegalOp<dfschedule::StartIoOp>();
    innerTarget.addIllegalOp<dfschedule::LaunchKernelGroupOp>();
    innerTarget.addIllegalOp<dfschedule::GetBdIdOp>();
    innerTarget.addIllegalOp<dfschedule::LoadKernelGroupOp>();
    innerTarget.addIllegalOp<dfschedule::ConfigCreateIoOp>();
    innerTarget.addIllegalOp<dfschedule::ConfigDmaBdOp>();  // Converted in Phase 3 with proper benefits
    innerTarget.addIllegalOp<dfschedule::DeclareTileOp>();
    // NOTE: LaunchHostOp is handled in Phase 4, not here
    // innerTarget.addIllegalOp<dfschedule::LaunchHostOp>();
    innerTarget.addIllegalOp<dfschedule::DeclareTensorOp>();
    innerTarget.addIllegalOp<dfscheblueprint::DeclareDataOp>();
    
    // Use dynamic legality for string-named ops without C++ types
    
    // Create &DevInst and XAIE_MEM_CACHEABLE constants in each host block BEFORE conversion
    moduleOp->walk([&](dfschedule::HostBlockOp hostOp) {
        llvm::errs() << "[Pass] Pre-creating constants in host block\n";
        
        OpBuilder builder(ctx);
        builder.setInsertionPointToStart(&hostOp.getRegion().front());
        
        // Create &DevInst reference directly as a constant
        state.devInstRef = builder.create<emitc::ConstantOp>(
            hostOp.getLoc(), 
            emitc::PointerType::get(state.devInstType),
            emitc::OpaqueAttr::get(ctx, "&DevInst")).getResult();
        
        // Create XAIE_MEM_CACHEABLE constant
        state.cacheableConst = builder.create<emitc::ConstantOp>(
            hostOp.getLoc(), state.i32Type,
            emitc::OpaqueAttr::get(ctx, "XAIE_MEM_CACHEABLE")).getResult();
    });
    
    // Now apply conversion patterns to the ENTIRE MODULE (not per hostOp)
    llvm::errs() << "[Pass] Applying inner conversion patterns to entire module\n";
    
    // Debug: Count declare_data operations before conversion
    int declareDataCount = 0;
    moduleOp->walk([&](dfscheblueprint::DeclareDataOp op) {
        declareDataCount++;
        llvm::errs() << "[Pass] Found declare_data #" << declareDataCount << " at " << op->getLoc() << "\n";
    });
    llvm::errs() << "[Pass] Total declare_data ops: " << declareDataCount << "\n";
    
    if (failed(applyPartialConversion(moduleOp, innerTarget, frozenInnerPatterns))) {
        llvm::errs() << "[Pass] Warning: Some inner ops not converted\n";
    }
    
    // Debug: Count declare_data operations after conversion
    int remainingDeclareDataCount = 0;
    moduleOp->walk([&](dfscheblueprint::DeclareDataOp op) {
        remainingDeclareDataCount++;
        llvm::errs() << "[Pass] Remaining declare_data #" << remainingDeclareDataCount << " at " << op->getLoc() << "\n";
    });
    llvm::errs() << "[Pass] Remaining declare_data ops: " << remainingDeclareDataCount << "\n";
    
    // Debug: Check for unrealized_conversion_cast operations
    int castCount = 0;
    moduleOp->walk([&](UnrealizedConversionCastOp castOp) {
        castCount++;
        llvm::errs() << "[Pass] Found UnrealizedConversionCastOp #" << castCount << "\n";
        llvm::errs() << "[Pass]   Inputs: " << castOp.getInputs().size() << "\n";
        for (auto input : castOp.getInputs()) {
            if (input) {
                llvm::errs() << "[Pass]   Input type: " << input.getType() << "\n";
            } else {
                llvm::errs() << "[Pass]   Input is NULL!\n";
            }
        }
        llvm::errs() << "[Pass]   Outputs: " << castOp.getOutputs().size() << "\n";
        for (auto output : castOp.getOutputs()) {
            llvm::errs() << "[Pass]   Output type: " << output.getType() << "\n";
        }
    });
    llvm::errs() << "[Pass] Total UnrealizedConversionCastOps: " << castCount << "\n";
    
    // Phase 3.6: Remove unrealized conversion casts
    // These are leftover from operations we didn't convert (like tensor.extract_slice)
    llvm::errs() << "[Pass] Phase 3.6: Removing unrealized conversion casts\n";
    moduleOp->walk([&](UnrealizedConversionCastOp castOp) {
        // Replace the cast with its input (passthrough)
        if (castOp.getInputs().size() == 1 && castOp.getOutputs().size() == 1) {
            Value input = castOp.getInputs()[0];
            Value output = castOp.getOutputs()[0];
            
            if (input && input.getType() != output.getType()) {
                llvm::errs() << "[Pass] Removing cast from " << input.getType() << " to " << output.getType() << "\n";
                // Replace all uses of the cast output with the input
                output.replaceAllUsesWith(input);
                castOp.erase();
            }
        }
    });
    
    // Phase 3.5 is no longer needed - arith.constant dense ops are replaced directly in ArithConstantInnerPattern
    
    //==========================================================================
    // Phase 4: Convert dfschedule ops (host -> emitc.func, launchhost, dskernel_receiver)
    //==========================================================================
    llvm::errs() << "[Pass] Phase 4: Converting dfschedule operations\n";
    
    {
        ConversionTarget target(*ctx);
        target.addLegalDialect<emitc::EmitCDialect>();
        target.addLegalDialect<arith::ArithDialect>();
        target.addLegalDialect<scf::SCFDialect>();
        target.addLegalDialect<func::FuncDialect>();  // func.func, func.return are legal
        
        target.addIllegalOp<dfschedule::HostBlockOp>();
        target.addIllegalOp<dfschedule::LaunchHostOp>();
        
        target.markUnknownOpDynamicallyLegal([](Operation *op) {
            StringRef opName = op->getName().getStringRef();
            if (opName == "dfschedule.dskernel_receiver") {
                return false; // illegal
            }
            // Mark kernel module operations as illegal - they will be converted
            if (opName == "dfschedule.module") {
                return false; // illegal - convert to EmitC
            }
            // Nested kernel module ops will be erased when parent module is converted
            if (opName == "dfschedule.kernel_config_def" || opName == "dfschedule.lock_def" ||
                opName == "dfschedule.buffer_def" || opName == "dfschedule.window_def" ||
                opName == "dfschedule.kernel_decl" || opName == "dfschedule.main" ||
                opName == "dfschedule.alloc_sync_buffer" || opName == "dfschedule.sync_buffer_write" ||
                opName == "dfschedule.log" || opName == "dfschedule.window_init" ||
                opName == "dfschedule.kernel_invoke" || opName == "dfschedule.done" ||
                opName == "dfschedule.kernel_return") {
                return true; // legal - handled by parent module pattern
            }
            return true;
        });
        
        llvm::errs() << "[Pass] Phase 4: Checking for launchhost ops before conversion\n";
        moduleOp.walk([&](Operation *op) {
            if (op->getName().getStringRef() == "dfschedule.launchhost") {
                llvm::errs() << "  Found launchhost op: " << *op << "\n";
            }
        });
        
        RewritePatternSet patterns(ctx);
        patterns.add<HostOpOuterPattern>(typeConverter, ctx);
        patterns.add<LaunchHostPattern>(typeConverter, ctx);
        patterns.add<DsKernelReceiverPattern>(typeConverter, ctx);
        patterns.add<KernelModuleConversionPattern>(typeConverter, ctx);

        if (failed(applyPartialConversion(moduleOp, target, std::move(patterns)))) {
            llvm::errs() << "[Pass] Warning: Partial conversion had failures\n";
        }
        
        llvm::errs() << "[Pass] Phase 4: Checking for launchhost ops after conversion\n";
        moduleOp.walk([&](Operation *op) {
            if (op->getName().getStringRef() == "dfschedule.launchhost") {
                llvm::errs() << "  Still found launchhost op: " << *op << "\n";
            }
        });
    }
    
    //==========================================================================
    // Phase 4.5: Convert remaining arith.constant to emitc.constant
    //==========================================================================
    llvm::errs() << "[Pass] Phase 4.5: Converting remaining arith.constant to emitc.constant\n";
    
    {
        RewritePatternSet remainingConstPatterns(ctx);
        remainingConstPatterns.add<ArithConstantInnerPattern>(typeConverter, ctx, state);
        
        ConversionTarget remainingConstTarget(*ctx);
        remainingConstTarget.addLegalDialect<emitc::EmitCDialect>();
        remainingConstTarget.addLegalDialect<scf::SCFDialect>();
        remainingConstTarget.addLegalDialect<func::FuncDialect>();
        remainingConstTarget.addLegalDialect<arith::ArithDialect>();
        
        // Mark all arith.constant as illegal
        remainingConstTarget.addDynamicallyLegalOp<arith::ConstantOp>([&](arith::ConstantOp op) {
            return false;  // All constants need conversion
        });
        
        if (failed(applyPartialConversion(moduleOp, remainingConstTarget, std::move(remainingConstPatterns)))) {
            llvm::errs() << "[Pass] Warning: Some arith.constant ops could not be converted in phase 4.5\n";
        }
    }
    
    //==========================================================================
    // Phase 4.6: Remove remaining unconverted ops and orphaned unrealized casts
    //==========================================================================
    llvm::errs() << "[Pass] Phase 4.6: Removing remaining unconverted ops\n";
    
    // Collect operations that will be removed
    SmallVector<Operation*> opsToRemove;
    
    // Collect declare_data ops that weren't converted
    moduleOp.walk([&](dfscheblueprint::DeclareDataOp op) {
        llvm::errs() << "  Will remove unconverted declare_data\n";
        opsToRemove.push_back(op);
    });
    
    // Collect partitiontensor ops that weren't converted  
    moduleOp.walk([&](routing::partitiontensor op) {
        llvm::errs() << "  Will remove unconverted partitiontensor\n";
        opsToRemove.push_back(op);
    });
    
    // Now collect unrealized casts that only have uses in operations we're removing
    SmallVector<UnrealizedConversionCastOp> castsToRemove;
    moduleOp.walk([&](UnrealizedConversionCastOp castOp) {
        if (castOp.getOutputs().size() == 1) {
            Value output = castOp.getOutputs()[0];
            bool allUsersWillBeRemoved = true;
            
            for (Operation *user : output.getUsers()) {
                // Check if this user is in our removal list
                if (std::find(opsToRemove.begin(), opsToRemove.end(), user) == opsToRemove.end()) {
                    allUsersWillBeRemoved = false;
                    break;
                }
            }
            
            if (output.use_empty() || allUsersWillBeRemoved) {
                llvm::errs() << "  Will remove orphaned unrealized_conversion_cast\n";
                castsToRemove.push_back(castOp);
            }
        }
    });
    
    // Now actually remove everything
    for (auto op : opsToRemove) {
        if (auto declareData = dyn_cast<dfscheblueprint::DeclareDataOp>(op)) {
            declareData.replaceAllUsesWith(declareData.getInitTensor());
        } else if (auto partition = dyn_cast<routing::partitiontensor>(op)) {
            partition.replaceAllUsesWith(partition.getOperand());
        }
        op->erase();
    }
    
    for (auto castOp : castsToRemove) {
        if (castOp.getInputs().size() == 1 && castOp.getOutputs().size() == 1) {
            Value input = castOp.getInputs()[0];
            Value output = castOp.getOutputs()[0];
            
            llvm::errs() << "    Removing cast from " << input.getType() 
                         << " to " << output.getType() << "\n";
            
            // Replace all uses of the output with the input
            output.replaceAllUsesWith(input);
        }
        castOp.erase();
    }
    
    //==========================================================================
    // Phase 4.7: Walk and convert any remaining dfschedule.launchhost inside execute_regions
    //==========================================================================
    /*
    llvm::errs() << "[Pass] Phase 4.5: Converting nested launchhost ops\n";
    
    {
        SmallVector<Operation*> launchhostOps;
        moduleOp.walk([&](Operation *op) {
            if (op->getName().getStringRef() == "dfschedule.launchhost") {
                launchhostOps.push_back(op);
            }
        });
        
        for (Operation *op : launchhostOps) {
            OpBuilder builder(op);
            builder.create<emitc::CallOpaqueOp>(op->getLoc(),
                TypeRange{}, "hostruntime", nullptr, nullptr, ValueRange{});
            llvm::errs() << "[Pass] Converted nested launchhost\n";
            op->erase();
        }
    }
    */
    //==========================================================================
    // Phase 5: Apply canonicalization to optimize EmitC
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 5: Applying canonicalization patterns\n";
    /*
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
    */
    llvm::errs() << "=== DfscheduleToApiPass COMPLETE ===\n";
    
    // Print ExtractSlice conversion statistics
    llvm::errs() << "\n=== ExtractSlice Conversion Statistics ===\n";
    llvm::errs() << "  Total calls:    " << state.extractSliceCallCount << "\n";
    llvm::errs() << "  Successes:      " << state.extractSliceSuccessCount << "\n";
    llvm::errs() << "  Failures:       " << state.extractSliceFailCount << "\n";
    if (state.extractSliceCallCount > 0) {
        double successRate = (100.0 * state.extractSliceSuccessCount) / state.extractSliceCallCount;
        llvm::errs() << "  Success rate:   " << llvm::format("%.1f", successRate) << "%\n";
    }
    llvm::errs() << "==========================================\n\n";
    
    bool foundNullOperand = false;
    moduleOp.walk([&](Operation *op) {
        for (unsigned i = 0; i < op->getNumOperands(); ++i) {
            if (!op->getOperand(i)) {
                llvm::errs() << "[Pass] ERROR: Found null operand at index " << i 
                             << " in operation: " << op->getName() << "\n";
                
                // If it's a CallOpaqueOp, print the callee name
                if (auto callOp = dyn_cast<emitc::CallOpaqueOp>(op)) {
                    llvm::errs() << "  -> CallOpaqueOp callee: " << callOp.getCallee() << "\n";
                    llvm::errs() << "  -> Location: ";
                    op->getLoc().print(llvm::errs());
                    llvm::errs() << "\n";
                    llvm::errs() << "  -> Total operands: " << op->getNumOperands() << "\n";
                    for (unsigned j = 0; j < op->getNumOperands(); ++j) {
                        llvm::errs() << "     Operand[" << j << "]: " 
                                     << (op->getOperand(j) ? "valid" : "NULL") << "\n";
                    }
                }
                
                foundNullOperand = true;
            }
        }
    });
    
    if (foundNullOperand) {
        llvm::errs() << "[Pass] ERROR: Null operands detected, failing pass\n";
        //signalPassFailure();
    }
}

} // namespace mlir
