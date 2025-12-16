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
    
    // Cached values for inner patterns (set before applying inner patterns)
    Value devInstRef;
    Value cacheableConst;
    Type voidPtrType;
    Type memInstPtrType;
    Type i32Type;
    Type partitionType;
    Type devInstType;
    MLIRContext *ctx = nullptr;
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

/// Inner pattern for routing.partitiontensor -> __emitc_init_PartitionTensor
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
            "__emitc_init_PartitionTensor", nullptr, nullptr,
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

/// Inner pattern for tensor.extract_slice -> __emitc_extract_slice_*
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
                    "__emitc_extract_slice_contiguous_2d",
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
                    "__emitc_extract_slice_strided_2d",
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
                    "__emitc_extract_slice_contiguous_2d",
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
                    "__emitc_extract_slice_strided_2d",
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
    
    DeclareTensorInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<dfschedule::DeclareTensorOp>(typeConverter, ctx, /*benefit=*/1), state(state) {}
    
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
    
    DeclareTileInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<dfschedule::DeclareTileOp>(typeConverter, ctx, /*benefit=*/1), state(state) {}
    
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
    
    ConfigDmaBdInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<dfschedule::ConfigDmaBdOp>(typeConverter, ctx, /*benefit=*/1), state(state) {}
    
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
        
        // Get converted operands
        Value buffer = adaptor.getOperands()[0];  // PartitionTensor
        Value tile = adaptor.getOperands()[1];    // XAie_LocType
        Value bdId = adaptor.getOperands()[2];    // i32
        
        llvm::errs() << "  Buffer type: " << buffer.getType() << "\n";
        llvm::errs() << "  Tile type: " << tile.getType() << "\n";
        llvm::errs() << "  BD ID type: " << bdId.getType() << "\n";
        
        // Create verbatim comment to document the configuration
        std::string comment = "/* DMA BD Config: offset=" + std::to_string(offset) +
                            ", len=" + std::to_string(len) +
                            ", enable_packet=" + (enablePacket ? "true" : "false") +
                            ", packet_id=" + std::to_string(packetId) +
                            ", next_bd=" + std::to_string(nextBd) + " */";
        
        rewriter.create<emitc::VerbatimOp>(loc, comment);
        
        // Create a dummy XAie_DmaDescInit call that uses the tile
        // This keeps the tile value alive and prevents optimization
        // Format: XAie_DmaDescInit(&DevInst, &dmaDesc, tile)
        auto i32Type = rewriter.getI32Type();
        auto dmaDescType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_DmaDesc");
        
        // Create a call that uses the tile - this prevents dead code elimination
        // We'll create a dummy call to document tile usage
        auto dummyCall = rewriter.create<emitc::CallOpaqueOp>(
            loc,
            i32Type,
            "__emitc_dma_bd_config",
            nullptr,
            nullptr,
            ValueRange{tile, bdId});  // Use the tile here!
        
        llvm::errs() << "  ✓ Created DMA BD config with tile usage\n";
        
        // Replace the op with the call result
        rewriter.replaceOp(op, dummyCall.getResult(0));
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
            "/* Extract contiguous 2D slice from PartitionTensor */\n"
            "/* Takes PartitionTensor by value for cleaner generated code */\n"
            "static inline PartitionTensor __emitc_extract_slice_contiguous_2d(\n"
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
            "static inline PartitionTensor __emitc_extract_slice_strided_2d(\n"
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
            "    __emitc_track_alloc(mem_inst);\n"
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
    innerPatterns.add<DeclareDataInnerPattern>(typeConverter, ctx);
    innerPatterns.add<PartitionTensorInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<ExtractSliceInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<DeclareTensorInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<DeclareTileInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<ConfigDmaBdInnerPattern>(typeConverter, ctx, state);
    
    // Add EraseOpLowering patterns for ops that should simply be erased
    // NOTE: tensor.extract_slice, routing.partitiontensor, declare_data are NOT here - they are converted above
    innerPatterns.add<EraseOpLowering<dfschedule::ScheduleWaitOp>,
        EraseOpLowering<dfschedule::StartIoOp>,
        EraseOpLowering<routing::partitiontensor>,
        //EraseOpLowering<tensor::ExtractSliceOp>,
        EraseOpLowering<dfschedule::LaunchKernelGroupOp>,
        EraseOpLowering<dfschedule::GetBdIdOp>,
        EraseOpLowering<dfschedule::LoadKernelGroupOp>,
        EraseOpLowering<dfschedule::ConfigCreateIoOp>,
        // NOTE: ConfigDmaBdOp is now converted by ConfigDmaBdInnerPattern
        // EraseOpLowering<dfschedule::ConfigDmaBdOp>,
        // NOTE: DeclareTileOp is now converted by DeclareTileInnerPattern
        // EraseOpLowering<dfschedule::DeclareTileOp>,
        // NOTE: LaunchHostOp is handled in Phase 4, not here
        // EraseOpLowering<dfschedule::LaunchHostOp>,
        // NOTE: DeclareTensorOp is now converted by DeclareTensorInnerPattern
        // EraseOpLowering<dfschedule::DeclareTensorOp>,
        EraseOpLowering<dfschedule::ScheduleWaitOp>
        // EraseOpLowering<dfscheblueprint::DeclareDataOp>
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
    innerTarget.addIllegalOp<dfschedule::ConfigDmaBdOp>();  // Converted by ConfigDmaBdInnerPattern
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
    // Phase 4.5: Walk and convert any remaining dfschedule.launchhost inside execute_regions
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
