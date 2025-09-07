/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "routingmanager.h"
#include <iostream>

#define GET_TYPEDEF_CLASSES
#define GET_ATTRDEF_CLASSES
#define GET_OP_CLASSES
#include "routinginterface.cc.inc"
#include "routingdialect.cc.inc"
#include "routingattr.cc.inc"
#include "routingtype.cc.inc"

#include "routingop.cc.inc"
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
    Value cnum = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(), 1);
    Value rnum = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(), 8);
    //Value total = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(),16);
    auto callop = builder.create<mlir::func::CallOp>(builder.getUnknownLoc(), func, ValueRange({cnum, rnum}));
    auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());
    m.push_back(main);
    llvm::errs() << m;
    return m;
}

ModuleOp routingmanager::ops_testNew(MLIRContext* ctx, int totalN) {
    OpBuilder builder(ctx);
    mlir::ModuleOp m = ModuleOp::create(builder.getUnknownLoc());
    auto func = createroutingfuncNew(ctx, totalN);
    m.push_back(func);
    auto functype = builder.getFunctionType({},{});
    mlir::func::FuncOp main = builder.create<func::FuncOp>(builder.getUnknownLoc(), "main", functype);
    auto block = main.addEntryBlock();
    builder.setInsertionPointToEnd(block);
    //Value cnum   = builder.create<arith::ConstantIndexOp>(location, 1);
    Value cnum = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(), 1);
    Value rnum = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(), 8);
    //Value total = builder.create<arith::ConstantIndexOp>(builder.getUnknownLoc(),16);
    auto callop = builder.create<mlir::func::CallOp>(builder.getUnknownLoc(), func, ValueRange({cnum, rnum}));
    auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());
    m.push_back(main);
    llvm::errs() << m;
    return m;
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
            auto tensor = builder.create<createtensor>(builder.getUnknownLoc(),  subview, vals, dimnum);
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
            auto io = builder.create<createdataio>(builder.getUnknownLoc(), "mem", "input");
            auto tilearray = builder.create<createtilearrayOp>(builder.getUnknownLoc(), rnum_i32, cnum_i32);
            
          
            auto output = builder.getI32Type();
            auto op3 = builder.create<creatbroadcast>(builder.getUnknownLoc(), io.getResult(), tilearray.getResult());
            auto result = tilearray.getResult().getType().dyn_cast<tilearrayType>();

            llvm::outs() << "result count is "<< result.getItems().size() <<" \n";
           
        }
         
         //without return the print will go into generic as some verify failed.
         auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());

       
        return func;
}

mlir::func::FuncOp routingmanager::createroutingfuncNew(MLIRContext* ctx, int totalN, bool purefunc) {
        OpBuilder builder(ctx);
        auto location = builder.getUnknownLoc();
        //ModuleOp module= ModuleOp::create(builder.getUnknownLoc());
        IndexType itype= builder.getIndexType();
        mlir::FunctionType ftype = builder.getFunctionType({itype,itype},{});
        func::FuncOp func = builder.create<func::FuncOp>(builder.getUnknownLoc(), "createroute", ftype);
        Block* eb = func.addEntryBlock();
        builder.setInsertionPointToStart(eb);

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

            ///*
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
            auto tensor = builder.create<createtensor>(builder.getUnknownLoc(),  subview, vals, dimnum);
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
            //*/
            //
            auto io = builder.create<createdataio>(builder.getUnknownLoc(), "mem", "input");
            auto tilearray = builder.create<createtilearrayOp>(builder.getUnknownLoc(), rnum_i32, cnum_i32);
            
          
            auto output = builder.getI32Type();
            auto op3 = builder.create<creatbroadcast>(builder.getUnknownLoc(), io.getResult(), tilearray.getResult());
            auto result = tilearray.getResult().getType().dyn_cast<tilearrayType>();

            llvm::outs() << "result count is "<< result.getItems().size() <<" \n";
           
        }
         
         //without return the print will go into generic as some verify failed.
         auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());

       
        return func;
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