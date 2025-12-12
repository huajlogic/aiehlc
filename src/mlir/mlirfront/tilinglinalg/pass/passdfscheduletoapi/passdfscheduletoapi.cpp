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

//===----------------------------------------------------------------------===//
// Helper: EraseOpLowering - Reusable pattern to erase ops by name
//===----------------------------------------------------------------------===//

/// EraseOpLowering: A reusable ConversionPattern that erases an op by its string name.
/// Usage in pattern registration:
///   patterns.add<EraseOpLowering>(typeConverter, ctx, "dfschedule.schedule.wait");
///   patterns.add<EraseOpLowering>(typeConverter, ctx, "dfschedule.start_io");
struct EraseOpLowering : public ConversionPattern {
    std::string targetOpName;
    
    EraseOpLowering(TypeConverter &typeConverter, MLIRContext *ctx, StringRef opName)
        : ConversionPattern(typeConverter, opName, /*benefit=*/1, ctx), targetOpName(opName.str()) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        llvm::errs() << "[EraseOpLowering] Erasing: " << targetOpName << "\n";
        rewriter.eraseOp(op);
        return success();
    }
};

/// Helper function to add multiple EraseOpLowering patterns at once
inline void addEraseOpPatterns(RewritePatternSet &patterns, TypeConverter &typeConverter, 
                               MLIRContext *ctx, ArrayRef<StringRef> opNames) {
    for (StringRef opName : opNames) {
        patterns.add<EraseOpLowering>(typeConverter, ctx, opName);
    }
}

//===----------------------------------------------------------------------===//
// Inner Patterns (Applied inside host op region via walk)
//===----------------------------------------------------------------------===//

/// Inner pattern for arith.constant -> erase (already converted to global array)
struct ArithConstantInnerPattern : public OpConversionPattern<arith::ConstantOp> {
    ConversionState &state;
    
    ArithConstantInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : OpConversionPattern<arith::ConstantOp>(typeConverter, ctx, /*benefit=*/1), state(state) {}
    
    LogicalResult matchAndRewrite(arith::ConstantOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

/// Inner pattern for dfscheblueprint.declare_data -> XAie_MemAllocate + memcpy
struct DeclareDataInnerPattern : public ConversionPattern {
    ConversionState &state;
    
    DeclareDataInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : ConversionPattern(typeConverter, "dfscheblueprint.declare_data", /*benefit=*/1, ctx), state(state) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        if (op->getNumResults() == 0) return failure();
        
        auto resultType = dyn_cast<RankedTensorType>(op->getResult(0).getType());
        if (!resultType) return failure();
        
        auto loc = op->getLoc();
        
        std::string arrayName = "g_data_array_0";
        if (op->getNumOperands() > 0) {
            if (Operation *initOp = op->getOperand(0).getDefiningOp()) {
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
        
        auto sizeConst = rewriter.create<emitc::ConstantOp>(loc, state.i32Type,
            rewriter.getI32IntegerAttr(byteSize));
        
        auto memInst = rewriter.create<emitc::CallOpaqueOp>(loc,
            state.memInstPtrType, "XAie_MemAllocate", nullptr, nullptr,
            ValueRange{state.devInstRef, sizeConst.getResult(), state.cacheableConst});
        
        auto vaddr = rewriter.create<emitc::CallOpaqueOp>(loc,
            state.voidPtrType, "XAie_MemGetVAddr", nullptr, nullptr,
            ValueRange{memInst.getResult(0)});
        
        auto srcPtr = rewriter.create<emitc::ConstantOp>(loc, state.voidPtrType,
            emitc::OpaqueAttr::get(state.ctx, "(void*)" + arrayName));
        
        rewriter.create<emitc::CallOpaqueOp>(loc, state.voidPtrType, "memcpy",
            nullptr, nullptr,
            ValueRange{vaddr.getResult(0), srcPtr.getResult(), sizeConst.getResult()});
        
        // Store the raw data pointer - PartitionTensor will be created by routing.partitiontensor
        state.dataPtrMap[op->getResult(0)] = vaddr.getResult(0);
        llvm::errs() << "[Pattern] DeclareData: XAie_MemAllocate for " << arrayName << "\n";
        
        rewriter.eraseOp(op);
        return success();
    }
};

/// Inner pattern for routing.partitiontensor -> __emitc_init_PartitionTensor
struct PartitionTensorInnerPattern : public ConversionPattern {
    ConversionState &state;
    
    PartitionTensorInnerPattern(TypeConverter &typeConverter, MLIRContext *ctx, ConversionState &state)
        : ConversionPattern(typeConverter, "routing.partitiontensor", /*benefit=*/1, ctx), state(state) {}
    
    LogicalResult matchAndRewrite(Operation *op, ArrayRef<Value> operands,
                                  ConversionPatternRewriter &rewriter) const override {
        if (op->getNumResults() == 0 || op->getNumOperands() == 0) return failure();
        
        auto resultType = dyn_cast<RankedTensorType>(op->getResult(0).getType());
        auto inputType = dyn_cast<RankedTensorType>(op->getOperand(0).getType());
        if (!resultType || !inputType) return failure();
        
        auto loc = op->getLoc();
        Value inputTensor = op->getOperand(0);
        
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
        
        // Get data pointer from source (dataPtrMap stores the raw void*)
        Value dataVoidPtr;
        if (state.dataPtrMap.count(inputTensor)) {
            dataVoidPtr = state.dataPtrMap[inputTensor];
        } else {
            dataVoidPtr = rewriter.create<emitc::ConstantOp>(loc, state.voidPtrType,
                emitc::OpaqueAttr::get(state.ctx, "NULL")).getResult();
        }
        
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
        
        auto ptOp = rewriter.create<emitc::CallOpaqueOp>(loc, state.partitionType,
            "__emitc_init_PartitionTensor", nullptr, nullptr,
            ValueRange{dataVoidPtr, elemSizeConst.getResult(), ndimConst.getResult(),
                       origShapeConst.getResult(), partShapeConst.getResult(),
                       splitdimConst.getResult(), splitnumConst.getResult(),
                       hwAxisConst.getResult(), replicateConst.getResult()});
        
        state.memAllocMap[op->getResult(0)] = std::make_tuple(ptOp.getResult(0), partitionByteSize, totalElements);
        state.dataPtrMap[op->getResult(0)] = dataVoidPtr;
        llvm::errs() << "[Pattern] PartitionTensor: created (ndim=" << ndim 
                     << ", splitdim=" << splitdim << ", splitnum=" << splitnum << ")\n";
        
        rewriter.eraseOp(op);
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
        auto loc = op.getLoc();
        
        auto resultType = dyn_cast<RankedTensorType>(op.getResult().getType());
        auto srcType = dyn_cast<RankedTensorType>(op.getSource().getType());
        if (!resultType || !srcType) return failure();
        
        Value srcTensor = op.getSource();
        if (!state.memAllocMap.count(srcTensor)) {
            llvm::errs() << "[Pattern] ExtractSlice: source not in memAllocMap, skipping\n";
            return failure();
        }
        
        Value srcPartitionTensor = std::get<0>(state.memAllocMap[srcTensor]);
        
        auto offsets = op.getStaticOffsets();
        auto sizes = op.getStaticSizes();
        auto srcShape = srcType.getShape();
        
        int64_t ndim = srcShape.size();
        if (ndim != 2) {
            llvm::errs() << "[Pattern] Warning: extract_slice only supported for 2D\n";
            return failure();
        }
        
        int64_t elemSize = getElemSize(resultType.getElementType());
        int64_t sliceElements = sizes[0] * sizes[1];
        int64_t sliceByteSize = sliceElements * elemSize;
        
        // Check if slice is contiguous:
        // For 2D: contiguous if offset[1]==0 && size[1]==srcShape[1], or size[0]==1
        bool isContiguous = (offsets[1] == 0 && sizes[1] == srcShape[1]) || (sizes[0] == 1);
        
        Value resultPt;
        
        if (isContiguous) {
            // Contiguous slice - pass PartitionTensor by value, use args for inline constants
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
            llvm::errs() << "[Pattern] ExtractSlice: contiguous 2D slice\n";
        } else {
            // Non-contiguous 2D slice with memory allocation
            auto devInstPtrType = emitc::PointerType::get(state.devInstType);
            auto devInstAddr = rewriter.create<emitc::ApplyOp>(loc, devInstPtrType,
                rewriter.getStringAttr("&"), state.devInstRef);
            
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
                ValueRange{devInstAddr.getResult(), srcPartitionTensor});
            resultPt = sliceOp.getResult(0);
            
            state.allocatedMemList.push_back(resultPt);
            llvm::errs() << "[Pattern] ExtractSlice: strided 2D slice (allocated)\n";
        }
        
        state.memAllocMap[op.getResult()] = std::make_tuple(resultPt, sliceByteSize, sliceElements);
        
        rewriter.eraseOp(op);
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
        ///*
        // Move converted operations from host region to new func
        if (op->getNumRegions() > 0 && !op->getRegion(0).empty()) {
            Block &srcBlock = op->getRegion(0).front();
            
            // Clone all operations except terminator to the new func
            OpBuilder::InsertionGuard guard(rewriter);
            rewriter.setInsertionPointToStart(entryBlock);
            
            for (Operation &nestedOp : llvm::make_early_inc_range(srcBlock.getOperations())) {
                if (!nestedOp.hasTrait<OpTrait::IsTerminator>()) {
                    rewriter.clone(nestedOp);
                }
            }
        }
        ///*/
        
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
// Pass Implementation - Two-Phase Conversion with Walk + Patterns
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
    
    {
        ConversionTarget constTarget(*ctx);
        constTarget.addLegalDialect<emitc::EmitCDialect>();
        constTarget.addDynamicallyLegalOp<arith::ConstantOp>([](arith::ConstantOp op) {
            // Only convert constants with DenseElementsAttr
            return !dyn_cast<DenseElementsAttr>(op.getValue());
        });
        
        RewritePatternSet constPatterns(ctx);
        constPatterns.add<DenseConstantToEmitCPattern>(typeConverter, ctx, state);
        
        if (failed(applyPartialConversion(moduleOp, constTarget, std::move(constPatterns)))) {
            llvm::errs() << "[Pass] Warning: Some constants not converted\n";
        }
    }
    
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
    innerPatterns.add<ArithConstantInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<DeclareDataInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<PartitionTensorInnerPattern>(typeConverter, ctx, state);
    innerPatterns.add<ExtractSliceInnerPattern>(typeConverter, ctx, state);
    
    // Add EraseOpLowering patterns for ops that should simply be erased
    addEraseOpPatterns(innerPatterns, typeConverter, ctx, {
        "dfschedule.schedule.wait",
        "dfschedule.start_io",
        "dfschedule.launch_kernel_group",
        "dfschedule.load_kernel_group",
        "dfschedule.create_io",
        "dfschedule.config.dma_bd",
        "dfschedule.declaretile"
    });
    
    FrozenRewritePatternSet frozenInnerPatterns(std::move(innerPatterns));
    ///*
    // Walk each dfschedule.host op and apply inner patterns to its region
    moduleOp.walk([&](Operation *hostOp) {
        if (hostOp->getName().getStringRef() != "dfschedule.host")
            return;
        
        if (hostOp->getNumRegions() == 0 || hostOp->getRegion(0).empty())
            return;

        ConversionTarget innerTarget(*ctx);
        innerTarget.addLegalDialect<emitc::EmitCDialect>();
        innerTarget.addLegalDialect<scf::SCFDialect>();
        innerTarget.addIllegalOp<tensor::ExtractSliceOp>();
        
        // arith.constant with DenseElementsAttr is illegal (needs to be erased after global array created)
        innerTarget.addDynamicallyLegalOp<arith::ConstantOp>([&state](arith::ConstantOp op) {
            auto denseAttr = dyn_cast<DenseElementsAttr>(op.getValue());
            if (!denseAttr) return true; // non-tensor constants are legal
            return !state.arrayNameMap.count(op.getOperation()); // illegal if already in arrayNameMap
        });
        
        innerTarget.markUnknownOpDynamicallyLegal([](Operation *op) {
            StringRef opName = op->getName().getStringRef();
            // Ops that need conversion
            if (opName == "dfscheblueprint.declare_data" ||
                opName == "routing.partitiontensor") {
                return false; // illegal - needs conversion
            }
            // Ops that need to be erased
            if (opName == "dfschedule.schedule.wait" ||
                opName == "dfschedule.start_io" ||
                opName == "dfschedule.launch_kernel_group" ||
                opName == "dfschedule.load_kernel_group" ||
                opName == "dfschedule.create_io" ||
                opName == "dfschedule.config.dma_bd" ||
                opName == "dfschedule.declaretile") {
                return false; // illegal - needs to be erased
            }
            return true;
        });
        
        if (failed(applyPartialConversion(hostOp, innerTarget, std::move(frozenInnerPatterns)))) {
            llvm::errs() << "[Pass] Warning: Some inner ops not converted in host region\n";
        }
    });
    //*/
    //==========================================================================
    // Phase 4: Convert dfschedule ops (host -> emitc.func, launchhost, dskernel_receiver)
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 4: Converting dfschedule operations\n";
    
    {
        ConversionTarget target(*ctx);
        target.addLegalDialect<emitc::EmitCDialect>();
        target.addLegalDialect<arith::ArithDialect>();
        target.addLegalDialect<scf::SCFDialect>();
        
        target.markUnknownOpDynamicallyLegal([](Operation *op) {
            StringRef opName = op->getName().getStringRef();
            if (opName.starts_with("dfschedule.") ||
                opName.starts_with("dfscheblueprint.") ||
                opName.starts_with("routing.")) {
                return false; // illegal
            }
            return true;
        });
        
        RewritePatternSet patterns(ctx);
        patterns.add<HostOpOuterPattern>(typeConverter, ctx);
        patterns.add<LaunchHostPattern>(typeConverter, ctx);
        patterns.add<DsKernelReceiverPattern>(typeConverter, ctx);
        
        if (failed(applyPartialConversion(moduleOp, target, std::move(patterns)))) {
            llvm::errs() << "[Pass] Warning: Partial conversion had failures\n";
        }
    }
    
    //==========================================================================
    // Phase 4.5: Walk and convert any remaining dfschedule.launchhost inside execute_regions
    //==========================================================================
    
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
    
    //==========================================================================
    // Phase 5: Apply canonicalization to optimize EmitC
    //==========================================================================
    
    llvm::errs() << "[Pass] Phase 5: Applying canonicalization patterns\n";
    
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
    
    llvm::errs() << "=== DfscheduleToApiPass COMPLETE ===\n";
}

} // namespace mlir
