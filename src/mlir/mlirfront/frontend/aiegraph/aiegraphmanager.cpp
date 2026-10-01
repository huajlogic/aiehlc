/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#include "aiegraphmanager.h"
#include "mlir/IR/OpImplementation.h"

#define GET_TYPEDEF_CLASSES
#define GET_ATTRDEF_CLASSES
#define GET_OP_CLASSES
#define GET_OP_DEFS
#include "aiegraphdialect.cc.inc"
#include "aiegraphattr.cc.inc"
#include "aiegraphtype.cc.inc"
#include "aiegraphenums.cc.inc"

#include "aiegraphop.cc.inc"
#undef GET_OP_DEFS
#undef GET_OP_CLASSES
#undef GET_ATTRDEF_CLASSES
#undef GET_TYPEDEF_CLASSES

//===----------------------------------------------------------------------===//
// Small helpers for verifiers
//===----------------------------------------------------------------------===//

// Number of i8 elements carried by a ranked int8 tensor value; -1 if unranked
// or non-i8 (the tablegen operand constraint already restricts to TensorOf<[I8]>,
// but the shape may be dynamic).
static int64_t i8Elems(mlir::Value v) {
    auto t = ::llvm::dyn_cast<mlir::RankedTensorType>(v.getType());
    if (!t || !t.hasStaticShape())
        return -1;
    return t.getNumElements();
}

//===----------------------------------------------------------------------===//
// Op verifiers
//===----------------------------------------------------------------------===//

::mlir::LogicalResult aiegraph::ConvBnReluOp::verify() {
    if (getCin() == 0 || getCout() == 0 || getK() == 0)
        return emitOpError("Cin, Cout and K must be non-zero");
    if (getStride() == 0)
        return emitOpError("stride must be non-zero");
    return ::mlir::success();
}

::mlir::LogicalResult aiegraph::ConvBnOp::verify() {
    if (getCin() == 0 || getCout() == 0 || getK() == 0)
        return emitOpError("Cin, Cout and K must be non-zero");
    if (getStride() == 0)
        return emitOpError("stride must be non-zero");
    return ::mlir::success();
}

::mlir::LogicalResult aiegraph::ResidualAddReluOp::verify() {
    int64_t mainN = i8Elems(getMain());
    int64_t skipN = i8Elems(getSkip());
    int64_t outN = i8Elems(getResult());
    if (mainN >= 0 && skipN >= 0 && mainN != skipN)
        return emitOpError("main and skip must carry the same element count (") << mainN << " vs " << skipN << ")";
    if (mainN >= 0 && outN >= 0 && mainN != outN)
        return emitOpError("result element count (") << outN << ") must match operands (" << mainN << ")";
    if (mainN >= 0 && (uint64_t)mainN != getLength())
        return emitOpError("length attr (") << getLength() << ") must match operand element count (" << mainN << ")";
    return ::mlir::success();
}

::mlir::LogicalResult aiegraph::AvgPoolFcOp::verify() {
    if (getChannels() == 0 || getNumClasses() == 0)
        return emitOpError("channels and num_classes must be non-zero");
    int64_t outN = i8Elems(getResult());
    if (outN >= 0 && (uint64_t)outN != getNumClasses())
        return emitOpError("logits element count (") << outN << ") must match num_classes (" << getNumClasses() << ")";
    return ::mlir::success();
}

//===----------------------------------------------------------------------===//
// FuncOp custom assembly (mirrors dmap::FuncOp)
//===----------------------------------------------------------------------===//

void aiegraph::FuncOp::print(OpAsmPrinter &printer) {
    printer << " ";
    printer.printSymbolName(getSymName());
    printer << " ";
    // Print the entry-block arguments (the network input feature map is a block
    // arg referenced by the first op); omitting them makes the IR non-parseable.
    printer.printRegion(getBody(), /*printEntryBlockArgs=*/true,
                        /*printBlockTerminators=*/false);
    printer.printOptionalAttrDictWithKeyword(getOperation()->getAttrs(),
                                             /*elidedAttrs=*/{"sym_name"});
}

ParseResult aiegraph::FuncOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();

    Region *body = result.addRegion();
    if (parser.parseRegion(*body, {}, {}))
        return failure();

    if (body->empty())
        body->emplaceBlock();

    // The printer emits the non-elided attributes (including funcType) as a
    // trailing `attributes { ... }` dict; consume it here so the op round-trips.
    if (parser.parseOptionalAttrDictWithKeyword(result.attributes))
        return failure();

    // Provide a default funcType when the parsed dict did not carry one.
    if (!result.attributes.get("funcType")) {
        auto builder = parser.getBuilder();
        auto funcType = builder.getFunctionType({}, {});
        result.addAttribute("funcType", TypeAttr::get(funcType));
    }

    return success();
}

//===----------------------------------------------------------------------===//
// Dialect initialize + load
//===----------------------------------------------------------------------===//

void aiegraphdialect::initialize() {
    addOperations<
#define GET_OP_LIST
#include "aiegraphop.cc.inc"
        >();
    addAttributes<
#define GET_ATTRDEF_LIST
#include "aiegraphattr.cc.inc"
        >();
    addTypes<
#define GET_TYPEDEF_LIST
#include "aiegraphtype.cc.inc"
        >();
}

void aiegraphmanager::loaddialect(MLIRContext *ctx) {
    ctx->getOrLoadDialect<mlir::func::FuncDialect>();
    ctx->getOrLoadDialect<mlir::tensor::TensorDialect>();
    ctx->getOrLoadDialect<mlir::arith::ArithDialect>();
    ctx->getOrLoadDialect<aiegraph::aiegraphdialect>();
}

//===----------------------------------------------------------------------===//
// Round-trip test builder: a tiny 2-op graph.
//===----------------------------------------------------------------------===//

ModuleOp aiegraphmanager::ops_test(MLIRContext *ctx) {
    OpBuilder builder(ctx);
    ModuleOp m = ModuleOp::create(builder.getUnknownLoc());

    auto functype = builder.getFunctionType({}, {});
    aiegraph::FuncOp fn = builder.create<aiegraph::FuncOp>(builder.getUnknownLoc(), builder.getStringAttr("resnet"),
                                                           TypeAttr::get(functype));
    m.push_back(fn);
    auto &block = fn.getBody().emplaceBlock();
    builder.setInsertionPointToEnd(&block);

    auto i8 = builder.getIntegerType(8);
    // in: 8x8x3 int8 feature map -> conv_bn_relu -> 8x8x4 -> avgpool_fc -> 10.
    auto inTy = RankedTensorType::get({8 * 8 * 3}, i8);
    auto midTy = RankedTensorType::get({8 * 8 * 4}, i8);
    auto logitsTy = RankedTensorType::get({10}, i8);

    // Block argument stands in for the network input feature map.
    auto inVal = block.addArgument(inTy, builder.getUnknownLoc());

    auto quant = aiegraph::quantparamAttr::get(ctx, /*in_scale=*/builder.getF64FloatAttr(0.5), /*in_zp=*/0,
                                               /*out_scale=*/builder.getF64FloatAttr(0.25), /*out_zp=*/0,
                                               /*bn_scale=*/128, /*bn_bias=*/0);
    auto conv = builder.create<aiegraph::ConvBnReluOp>(builder.getUnknownLoc(), midTy, inVal,
                                                       /*H=*/(uint64_t)8, /*W=*/(uint64_t)8, /*Cin=*/(uint64_t)3,
                                                       /*Cout=*/(uint64_t)4, /*K=*/(uint64_t)3, /*stride=*/(uint64_t)1,
                                                       quant, mlir::FlatSymbolRefAttr::get(ctx, "w0"));

    builder.create<aiegraph::AvgPoolFcOp>(builder.getUnknownLoc(), logitsTy, conv.getResult(),
                                          /*spatial_h=*/(uint64_t)8, /*spatial_w=*/(uint64_t)8,
                                          /*channels=*/(uint64_t)4, /*num_classes=*/(uint64_t)10,
                                          mlir::FlatSymbolRefAttr::get(ctx, "fc"));

    builder.create<aiegraph::YieldOp>(builder.getUnknownLoc());

    return m;
}
