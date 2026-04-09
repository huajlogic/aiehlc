/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "routingmanager.h"
#include <iostream>

#define GET_TYPEDEF_CLASSES
#define GET_ATTRDEF_CLASSES
#define GET_OP_CLASSES
#define GET_OP_DEFS
//#define GET_OP_LIST
#include "routinginterface.cc.inc"
#include "routingdialect.cc.inc"
#include "routingattr.cc.inc"
#include "routingtype.cc.inc"

#include "routingop.cc.inc"
//#undef GET_OP_LIST
#undef GET_OP_DEFS

#undef GET_OP_CLASSES
#undef GET_ATTRDEF_CLASSES
#undef GET_TYPEDEF_CLASSES

void routingdialect::initialize()  { 
    addOperations<
    #define GET_OP_LIST
    #include "routingop.cc.inc"
        >();
    // 如果有 Attr / Type：addAttributes<...>(); addTypes<...>();
     addAttributes<
    #define GET_ATTRDEF_LIST
    #include "routingattr.cc.inc"
    >();

        // 3. Types
    addTypes<
    #define GET_TYPEDEF_LIST
    #include "routingtype.cc.inc"
    >();
}
// implment interface api
int64_t tilearrayType::getTileBase() const {
    return 100;
}

// implement creattilearrayop result assembly
LogicalResult createtilearrayOp::inferReturnTypes(mlir::MLIRContext* ctx, 
    std::optional<mlir::Location>, 
    mlir::ValueRange, 
    mlir::DictionaryAttr args, 
    mlir::OpaqueProperties, 
    mlir::RegionRange, 
    llvm::SmallVectorImpl<mlir::Type>& infer) {
        //args is arguments
        //auto items = args.get("items").dyn_cast_or_null<TileRangeArrayAttr>();
        //if (!items) return failure();
    TileRangeAttr ta = TileRangeAttr::get(ctx, -1,-1);
    llvm::SmallVector<TileRangeAttr,4> slist;
    slist.push_back(ta);
    infer.push_back(tilearrayType::get(ctx,slist));

    return success();

}

LogicalResult createdataio::inferReturnTypes(mlir::MLIRContext* ctx, 
    std::optional<mlir::Location>, 
    mlir::ValueRange, 
    mlir::DictionaryAttr args, 
    mlir::OpaqueProperties, 
    mlir::RegionRange, 
    llvm::SmallVectorImpl<mlir::Type>& infer) {
        //args is arguments
        auto items = args.get("iotype").dyn_cast_or_null<StringAttr>();
        auto items2 = args.get("direction").dyn_cast_or_null<StringAttr>();
        if (!items||!items) return failure();
        infer.push_back(dataioType::get(ctx,items, items2));

    return success();

}

// In RoutingOps.cpp

// This is the C++ implementation for the printer.
void routing::RoutingCreate::print(OpAsmPrinter &p) {
  // `p` is the printer object. The `<<` operator prints literal strings.
  //p << " on_row ";

  // Use printAttribute to print attributes. Angle brackets are just literals.
  p << "<";
  p << "Memo = \"";
  p << (getMemo());
  p << "\">";

  // Use printOperand for SSA values, and print its type.
  p << " ( scf_idx = ";
  p.printOperand(getScfIdx());
  p << " : ";
  p.printType(getScfIdx().getType());
  p << ")";

  // Use printOptionalAttrDict to print any attributes we haven't
  // explicitly printed. This is good practice for forward compatibility.
  // We need to tell it which attributes we already handled.
  //p.printOptionalAttrDict(this->getAttrs(), /*elidedAttrs=*/{"device_row"});

  // Print the result type.
  p << " -> ";
  p.printType(getResult().getType());
  
  // Use printRegion to print the region.
  p.printRegion(getBody(), /*printEntryBlockArgs=*/true,
                              /*printBlockTerminators=*/true);
}

// In RoutingOps.cpp

// This is the C++ implementation for the parser.
// Format (matches printer): <Memo = "str"> ( scf_idx = %val : type) -> type { region }
ParseResult RoutingCreate::parse(OpAsmParser &parser, OperationState &result) {
  // --- 1. Parse <Memo = "string"> ---
  if (parser.parseLess())
    return failure();

  // Parse key-value pairs inside angle brackets
  while (true) {
    // Check for closing >
    if (succeeded(parser.parseOptionalGreater()))
      break;

    StringRef attrName;
    if (parser.parseKeyword(&attrName) || parser.parseEqual())
      return failure();

    if (attrName == "Memo") {
      StringAttr memoAttr;
      if (parser.parseAttribute(memoAttr, "Memo", result.attributes))
        return failure();
    } else {
      // Unknown attribute inside <>, try to parse as generic attribute
      Attribute genericAttr;
      if (parser.parseAttribute(genericAttr, attrName, result.attributes))
        return failure();
    }
    parser.parseOptionalComma();
  }

  // --- 2. Parse ( scf_idx = %operand : type ) ---
  OpAsmParser::UnresolvedOperand inputOperand;
  Type inputType;
  if (parser.parseLParen() ||
      parser.parseKeyword("scf_idx") || parser.parseEqual() ||
      parser.parseOperand(inputOperand) ||
      parser.parseColon() ||
      parser.parseType(inputType) ||
      parser.parseRParen())
    return failure();

  // Parse any optional attributes
  if (parser.parseOptionalAttrDict(result.attributes))
    return failure();

  // --- 3. Parse -> result_type ---
  Type resultType;
  if (parser.parseArrow() || parser.parseType(resultType))
    return failure();

  // --- 4. Parse the region ---
  Region *body = result.addRegion();
  llvm::SmallVector<OpAsmParser::Argument> regionArgs;
  OpAsmParser::Argument arg;
  arg.type = inputType;
  regionArgs.push_back(arg);
  if (parser.parseRegion(*body, regionArgs))
    return failure();

  // --- 5. Populate the OperationState ---
  result.addTypes(resultType);
  if (parser.resolveOperand(inputOperand, inputType, result.operands))
    return failure();

  return success();
}

// partitiontensorOp printer
void routing::partitiontensor::print(OpAsmPrinter &printer) {
    printer << " tensor = " << getTensor() << " : " << getTensor().getType();
    printer << " {";
    printer << "\n          splitnum = " << getSplitnum() << ",";
    printer << "\n          splitdim = " << getSplitdim() << ",";
    printer << "\n          hw_axis_owner = " << getHwAxisOwnerAttr() << ",";
    printer << "\n          replicate_on = " << getReplicateOnAttr() << ",";
    printer << "\n          single_tile_owner = " << getSingleTileOwnerAttr();
    printer << "\n     }";
    printer.printOptionalAttrDict(getOperation()->getAttrs(), 
        /*elidedAttrs=*/{"splitnum", "splitdim", "hw_axis_owner", "replicate_on", "single_tile_owner"});
    printer << " -> " << getOutput().getType();
}

// partitiontensorOp parser
ParseResult routing::partitiontensor::parse(OpAsmParser &parser, OperationState &result) {
    OpAsmParser::UnresolvedOperand tensorOperand;
    Type tensorType;

    if (parser.parseKeyword("tensor") || parser.parseEqual())
        return failure();

    if (parser.parseOperand(tensorOperand) || parser.parseColonType(tensorType))
        return failure();

    // Parse the attributes as a dictionary-style block: { key = val, ... }
    if (parser.parseLBrace())
        return failure();

    while (true) {
        if (succeeded(parser.parseOptionalRBrace()))
            break;

        StringRef attrName;
        if (parser.parseKeyword(&attrName) || parser.parseEqual())
            return failure();

        if (attrName == "splitnum") {
            int64_t val;
            if (parser.parseInteger(val)) return failure();
            result.addAttribute("splitnum",
                parser.getBuilder().getI32IntegerAttr(val));
        } else if (attrName == "splitdim") {
            int64_t val;
            if (parser.parseInteger(val)) return failure();
            result.addAttribute("splitdim",
                parser.getBuilder().getI32IntegerAttr(val));
        } else if (attrName == "hw_axis_owner") {
            StringAttr attr;
            if (parser.parseAttribute(attr, "hw_axis_owner", result.attributes)) return failure();
        } else if (attrName == "replicate_on") {
            StringAttr attr;
            if (parser.parseAttribute(attr, "replicate_on", result.attributes)) return failure();
        } else if (attrName == "single_tile_owner") {
            StringAttr attr;
            if (parser.parseAttribute(attr, "single_tile_owner", result.attributes)) return failure();
        } else {
             return parser.emitError(parser.getCurrentLocation(), "unknown attribute: ") << attrName;
        }

        parser.parseOptionalComma();
    }

    if (parser.parseOptionalAttrDict(result.attributes))
        return failure();

    if (parser.parseArrow())
        return failure();

    Type resultType;
    if (parser.parseType(resultType))
        return failure();

    result.addTypes(resultType);
    if (parser.resolveOperand(tensorOperand, tensorType, result.operands))
        return failure();

    return success();
}

//routing class
void routingmanager::type_interface_test(MLIRContext* ctx) {
        //ctx->getOrLoadDialect<routing::routingdialect>();
        TileRangeAttr tarrayattr = TileRangeAttr::get(ctx, 1, 1);
        llvm::SmallVector<TileRangeAttr,4> slist;
        slist.push_back(tarrayattr);
        tilearrayType ttype = tilearrayType::get(ctx, slist);
        if (auto tt = dyn_cast<TileInterface>(ttype)) {
            llvm::outs() << tt.getTileBase() << "\n";
        }
        auto len = ttype.getItems().size();
        llvm::outs() << len << " is the length\n"; 
    }
ModuleOp routingmanager::ops_test(MLIRContext* ctx, int totalN) {
    OpBuilder builder(ctx);
    mlir::ModuleOp m = ModuleOp::create(builder.getUnknownLoc());
    auto func = createroutingfunc(ctx, totalN);
    m.push_back(func);
    auto functype = builder.getFunctionType({},{});
    mlir::func::FuncOp main = builder.create<func::FuncOp>(builder.getUnknownLoc(), "main", functype);
    auto block = main.addEntryBlock();
    builder.setInsertionPointToEnd(block);
    //Value cnum   = builder.create<arith::ConstantIndexOp>(location, 1);
    // cnum and rnum is not the ARRAY/hw shape, it means reserve how many row , how many col used to do broadcast
    Value cnum = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(), 1);
    Value rnum = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(), 8);
    //Value total = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(),16);
    auto callop = builder.create<mlir::func::CallOp>(builder.getUnknownLoc(), func, ValueRange({cnum, rnum}));
    auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());
    m.push_back(main);
    llvm::errs() << m;
    return m;
}

ModuleOp routingmanager::ops_testNew(MLIRContext *ctx, int totalN, std::string routingname) {
    const int hwrowused = 2, hwcolused = 2;
    OpBuilder builder(ctx);
    mlir::ModuleOp m = ModuleOp::create(builder.getUnknownLoc());
    auto functype = builder.getFunctionType({},{});

    if (routingname.empty()) {
        routingname = "main";
    }

    mlir::func::FuncOp main = builder.create<func::FuncOp>(builder.getUnknownLoc(), routingname, functype);

    auto block = main.addEntryBlock();
    builder.setInsertionPointToEnd(block);
    auto mesh = builder.create<createhwmesh>(builder.getUnknownLoc(),  hwrowused, hwcolused);

    // Helper to create a schedule tensor with dense init data
    auto createTensor = [&](SmallVector<int64_t> shapeVec, int64_t startVal) -> Value {
        SmallVector<Attribute> shape;
        for (int64_t v : shapeVec)
            shape.push_back(builder.getI64IntegerAttr(v));
        ArrayAttr vals = builder.getArrayAttr(shape);
        IntegerAttr dimnum = builder.getI64IntegerAttr(shapeVec.size());
        auto tensorType = RankedTensorType::get(shapeVec, builder.getI8Type());

        SmallVector<llvm::APInt> initValues;
        int64_t totalElements = 1;
        for (auto dim : shapeVec)
            totalElements *= dim;
        for (int64_t i = 0; i < totalElements; ++i)
            initValues.push_back(llvm::APInt(8, startVal + i));

        auto denseAttr = DenseElementsAttr::get(tensorType, initValues);
        auto initConstant = builder.create<arith::ConstantOp>(builder.getUnknownLoc(), tensorType, denseAttr);
        auto tensor = builder.create<createscheduletensor>(builder.getUnknownLoc(), tensorType,
                                                           initConstant.getResult(), vals, dimnum);
        return tensor;
    };

    // GEMM: C[16x16] = A[16x16] * B[16x16]
    // A (input)  — start from 1
    // B (input)  — start from 2 (must differ from A to prevent constant folding/merge)
    // C (output) — zeroed out (result buffer)
    Value tensorA = createTensor({16, 16}, 1);
    Value tensorB = createTensor({16, 16}, 2);
    Value tensorC = createTensor({16, 16}, 0);

    createroutingfuncGEMM(builder, ctx, mesh, tensorA, tensorB, tensorC, hwrowused, "row");

    auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());
    m.push_back(main);
    llvm::errs() << m;
    return m;
}

void routingmanager::createroutingfuncGEMM(OpBuilder &builder, MLIRContext *ctx, Value mesh, Value tensorA,
                                           Value tensorB, Value tensorC, uint32_t hwsplitnum, std::string splitAxis) {
    auto location = builder.getUnknownLoc();
    auto exec = builder.create<scf::ExecuteRegionOp>(location, /*result types*/ TypeRange{});
    exec->setAttr("routing_memo", builder.getStringAttr(splitAxis));
    {
        OpBuilder::InsertionGuard guard(builder);
        builder.setInsertionPointToStart(&exec.getRegion().emplaceBlock());

        // One partitionmesh for the entire GEMM
        auto partmesh = builder.create<partitionmesh>(location, mesh, hwsplitnum, splitAxis);

        int splitdimn = splitAxis == "row" ? 0 : 1;

        // Get tensor types
        auto tensorTypeA = tensorA.getType().cast<RankedTensorType>();
        auto tensorTypeB = tensorB.getType().cast<RankedTensorType>();
        auto tensorTypeC = tensorC.getType().cast<RankedTensorType>();

        // Partition tensor A (input): split by row, each tile group gets its rows
        auto partTensorA = builder.create<partitiontensor>(location, tensorTypeA, tensorA, hwsplitnum, splitdimn,
                                                           splitAxis, "col", "");

        // Partition tensor B (input): replicated to all tile groups (broadcast)
        // splitnum=1 means no split — full tensor goes to each group
        // hw_axis_owner="" means not owned by any axis, replicate_on=splitAxis means broadcast along split axis
        auto partTensorB =
            builder.create<partitiontensor>(location, tensorTypeB, tensorB, 1, splitdimn, "", splitAxis, "");

        // Partition tensor C (output): split by row, each tile group produces its rows
        auto partTensorC = builder.create<partitiontensor>(location, tensorTypeC, tensorC, hwsplitnum, splitdimn,
                                                           splitAxis, "col", "");

        // Calculate split tensor shapes
        SmallVector<int64_t> splitShapeA(tensorTypeA.getShape());
        SmallVector<int64_t> splitShapeC(tensorTypeC.getShape());
        if (splitdimn == 0) {
            if (splitShapeA[0] != ShapedType::kDynamic)
                splitShapeA[0] /= hwsplitnum;
            if (splitShapeC[0] != ShapedType::kDynamic)
                splitShapeC[0] /= hwsplitnum;
        } else {
            if (splitShapeA[1] != ShapedType::kDynamic)
                splitShapeA[1] /= hwsplitnum;
            if (splitShapeC[1] != ShapedType::kDynamic)
                splitShapeC[1] /= hwsplitnum;
        }
        auto splitTensorTypeA = RankedTensorType::get(splitShapeA, tensorTypeA.getElementType());
        // B is not split (splitnum=1), extract returns full tensor
        auto splitTensorTypeB = tensorTypeB;
        auto splitTensorTypeC = RankedTensorType::get(splitShapeC, tensorTypeC.getElementType());

        Value lb = builder.create<arith::ConstantIndexOp>(location, 0);
        Value ub = builder.create<arith::ConstantIndexOp>(location, hwsplitnum);
        Value step = builder.create<arith::ConstantIndexOp>(location, 1);

        auto scf = builder.create<mlir::scf::ForOp>(location, lb, ub, step);
        {
            OpBuilder::InsertionGuard guard(builder);
            builder.setInsertionPointToStart(scf.getBody());
            auto memo = builder.getStringAttr(splitAxis);
            mlir::Value scf_idx = scf.getInductionVar();
            Value idx = builder.create<arith::IndexCastOp>(location, builder.getI32Type(), scf_idx);

            auto routingcreateOp = builder.create<routing::RoutingCreate>(
                location, idx, memo, [&](OpBuilder &b, Location bodyLoc, Value sidx) {
                    auto tilelist = b.create<extract_tiles>(location, partmesh, sidx);

                    // --- Input A: split slice per tile group ---
                    auto sliceA = b.create<extract_data>(location, splitTensorTypeA, partTensorA, sidx);
                    auto hwioA = b.create<createhwiowithtarget>(location, tilelist, "input", "mem2");
                    b.create<movedatabyio>(location, sliceA, hwioA);

                    // --- Input B: broadcast full tensor to each tile group ---
                    auto sliceB = b.create<extract_data>(location, splitTensorTypeB, partTensorB, sidx);
                    auto hwioB = b.create<createhwiowithtarget>(location, tilelist, "input", "mem2");
                    b.create<movedatabyio>(location, sliceB, hwioB);

                    // --- Output C: gather from tile group ---
                    auto sliceC = b.create<extract_data>(location, splitTensorTypeC, partTensorC, sidx);
                    auto gatherC = b.create<routinggatherout>(location, sliceC.getType(), tilelist, sliceC);
                    auto hwioC = b.create<createhwiowithtarget>(location, tilelist, "output", "mem2");
                    b.create<movedatabyio>(location, gatherC, hwioC);

                    b.create<routing::YieldOp>(location);
                });
        }

        builder.create<scf::YieldOp>(location);
    };
}

void routingmanager::loaddialect(MLIRContext* ctx) {
    ctx->getOrLoadDialect<mlir::func::FuncDialect>();
    ctx->getOrLoadDialect<routing::routingdialect>();
    ctx->getOrLoadDialect<mlir::scf::SCFDialect>();
    ctx->getOrLoadDialect<mlir::arith::ArithDialect>();
}
mlir::func::FuncOp routingmanager::createroutingfunc(MLIRContext* ctx, int totalN, bool purefunc) {
        OpBuilder builder(ctx);
        auto location = builder.getUnknownLoc();
        //ModuleOp module= ModuleOp::create(builder.getUnknownLoc());
        IndexType itype= builder.getIndexType();
        mlir::FunctionType ftype = builder.getFunctionType({itype,itype},{});
        func::FuncOp func = builder.create<func::FuncOp>(builder.getUnknownLoc(), "createroute", ftype);
        Block* eb = func.addEntryBlock();
        builder.setInsertionPointToStart(eb);

        auto getconstant = [&](Value value) -> int {
            if (auto definingOp = value.getDefiningOp()) {
                if (auto constantOp = dyn_cast<arith::ConstantIntOp>(definingOp)) {
                    if (auto intAttr = constantOp.getValue().dyn_cast<mlir::IntegerAttr>()) {
                        return intAttr.getInt();
                    }
                }
            }
            return 0;
        };

        Value row = eb->getArgument(0);
        Value col = eb->getArgument(1);
        //Value total_col = eb->getArgument(2);

        Value lb = builder.create<arith::ConstantIndexOp>(location, 0);
        Value ub = builder.create<arith::ConstantIndexOp>(location, totalN);
        Value step = builder.create<arith::ConstantIndexOp>(location,1);
  // ──────────────────────────────
  // 2. 创建 scf.forall
  //    OpBuilder 会回调一个 lambda，让你往 region 里塞指令
  // ──────────────────────────────
        auto scf = builder.create<mlir::scf::ForOp>(location, lb, ub, step);
        {
            //use such format to fix the generic format print issue 
            OpBuilder::InsertionGuard guard(builder);
            builder.setInsertionPointToStart(scf.getBody());
            Value cnum_i32, rnum_i32;
            //TileRangeArrayAttr tlist = TileRangeArrayAttr::get(ctx, slist);
            if (purefunc) {
                col   = builder.create<arith::ConstantIndexOp>(location, 1);
                row   = builder.create<arith::ConstantIndexOp>(location, 8);
            }
            cnum_i32 = builder.create<arith::IndexCastOp>(location,builder.getI32Type(), col);
            rnum_i32 = builder.create<arith::IndexCastOp>(location, builder.getI32Type(), row);

            /*
            //create mesh
            auto mesh = builder.create<createhwmesh>(builder.getUnknownLoc(),  rnum_i32, cnum_i32);
            
            auto patitionmesh = builder.create<partitionmesh>(builder.getUnknownLoc(),  mesh, cnum_i32, "row");
            //------------
            //fixme should use real subview 
            Value subview = builder.create<arith::ConstantIntOp>(builder.getUnknownLoc(), 1, 32);
            SmallVector<Attribute> shape;
            for (int64_t v : {10, 20})
            shape.push_back(builder.getI64IntegerAttr(v));
            ArrayAttr vals = builder.getArrayAttr(shape);  // satisfies I64ArrayAttr
            // 3) I64Attr ($dim).
            IntegerAttr dimnum = builder.getI64IntegerAttr(2);
            auto tensor = builder.create<createscheduletensor>(builder.getUnknownLoc(),  subview, vals, dimnum);
            //
            auto hw_row_number = rnum_i32;
            IntegerAttr splitdim = builder.getI64IntegerAttr(0);//dim 0 is 

            mlir::StringAttr hw_axis_owner=builder.getStringAttr("row");
		    mlir::StringAttr replicate_on=builder.getStringAttr("col");
		    mlir::StringAttr single_tile_owner=builder.getStringAttr("");
            auto rowtensor = builder.create<partitiontensor>(builder.getUnknownLoc(),  
                    tensor, hw_row_number, splitdim,hw_axis_owner,replicate_on, single_tile_owner);
            //extract data
            auto edata = builder.create<extract_data>(builder.getUnknownLoc(), rowtensor, cnum_i32);
            auto emeshtile = builder.create<extract_tiles>(builder.getUnknownLoc(), patitionmesh, cnum_i32);
            //extract tile
            */
            //
            
            auto tilearray = builder.create<createtilearrayOp>(builder.getUnknownLoc(), rnum_i32, cnum_i32);
            auto io = builder.create<createdataio>(builder.getUnknownLoc(), "mem", "input");
            
          
            auto output = builder.getI32Type();
            auto op3 = builder.create<creatbroadcast>(builder.getUnknownLoc(), io.getResult(), tilearray.getResult());
            auto result = tilearray.getResult().getType().dyn_cast<tilearrayType>();

            llvm::outs() << "result count is "<< result.getItems().size() <<" \n";
           
        }
         
         //without return the print will go into generic as some verify failed.
         auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());

       
        return func;
}

void routingmanager::createroutingfuncByDim(OpBuilder& builder, MLIRContext* ctx, bool binput, Value mesh, Value tensor,
                                           uint32_t hwsplitnum, std::string splitAxis) {
        auto location = builder.getUnknownLoc();
        auto tensorhwaxisowner = splitAxis;
        // no region creatation
        //
        auto exec = builder.create<scf::ExecuteRegionOp>(builder.getUnknownLoc(), /*result types*/TypeRange{});
        exec->setAttr("routing_memo", builder.getStringAttr(splitAxis));
        //Block *body = builder.createBlock(&exec.getRegion());
        {
                    OpBuilder::InsertionGuard guard(builder);
                    //fix the upper scope return go inside this region issue
                    builder.setInsertionPointToStart(&exec.getRegion().emplaceBlock());
                ///*               
                    auto patitionmesh = builder.create<partitionmesh>(builder.getUnknownLoc(),  mesh, hwsplitnum, splitAxis);
                    int splitdimn= splitAxis == "row" ? 0 : 1;
                    IntegerAttr splitdim = builder.getI64IntegerAttr(splitdimn);//dim 0 is 
                    if (splitdimn == 0) {
                        assert(splitAxis == "row" && "splitdim 0 must be row");
                    } else {
                        assert(splitAxis == "col" && "splitdim 1 must be col");
                    }
                    // Get tensor type from input tensor for partitiontensor result
                    auto tensorType = tensor.getType().cast<RankedTensorType>();
                    auto rowtensor = builder.create<partitiontensor>(builder.getUnknownLoc(), tensorType, tensor, hwsplitnum, 0, tensorhwaxisowner,"col","");
                    
                    // Calculate split tensor type
                    SmallVector<int64_t> splitShape(tensorType.getShape());
                    if (splitdimn== 0) {
                        if (splitShape[0] != ShapedType::kDynamic) splitShape[0] /= hwsplitnum;
                    } else {
                        if (splitShape[1] != ShapedType::kDynamic) splitShape[1] /= hwsplitnum;
                    }
                    auto splitTensorType = RankedTensorType::get(splitShape, tensorType.getElementType());

                    Value lb = builder.create<arith::ConstantIndexOp>(location, 0);
                    Value ub = builder.create<arith::ConstantIndexOp>(location, hwsplitnum);
                    Value step = builder.create<arith::ConstantIndexOp>(location,1);
                    // create RoutingCreate region op
                    // inside region
                    ///*
                    auto scf = builder.create<mlir::scf::ForOp>(location, lb, ub, step);
                    { 
                        OpBuilder::InsertionGuard guard(builder);
                        builder.setInsertionPointToStart(scf.getBody());
                        auto memo = builder.getStringAttr(splitAxis);
                        mlir::Value scf_idx = scf.getInductionVar();
                        
                        Value idx = builder.create<arith::IndexCastOp>(builder.getUnknownLoc(),builder.getI32Type(), scf_idx);
                        
                        auto routingcreateOp = builder.create<routing::RoutingCreate>(builder.getUnknownLoc(), idx, memo, [&](OpBuilder &builder1, Location bodyLoc,Value sidx) { 
                            //use such format to fix the generic format print issue 
                            ///*
                            // extract_data returns the split tensor type
                            auto slicetensor = builder1.create<extract_data>(builder1.getUnknownLoc(), splitTensorType, rowtensor, sidx);
                            auto tilelist = builder1.create<extract_tiles>(builder1.getUnknownLoc(), patitionmesh, sidx);
                            
                            if (binput) {
                                auto hwio = builder1.create<createhwiowithtarget>(builder1.getUnknownLoc(), tilelist, "input", "mem2");
                                auto datamov = builder1.create<movedatabyio>(builder1.getUnknownLoc(), slicetensor, hwio);
                            } else {
                                // routinggatherout now takes AnyTensor and returns AnyTensor
                                auto gatherdata = builder1.create<routinggatherout>(builder1.getUnknownLoc(), slicetensor.getType(), tilelist, slicetensor);
                                auto hwio = builder1.create<createhwiowithtarget>(builder1.getUnknownLoc(), tilelist, "output", "mem2");
                                auto datamov = builder1.create<movedatabyio>(builder1.getUnknownLoc(), gatherdata, hwio);
                            }
                            //*/
                            builder1.create<routing::YieldOp>(builder1.getUnknownLoc());
                            
                        });
                        
                        //extract tile
                    }
                    //*/

                    // use routing.yield to return value finish the yield
                 builder.create<scf::YieldOp>(builder.getUnknownLoc());
        };
       
        return ;//func;
}
/*
int main() {
    MLIRContext ctx;
    mlirtest mtest;
    mtest.type_interface_test(&ctx);
    mtest.ops_test(&ctx);
    std::cout << "main" <<std::endl;
    return 0;
}
    */