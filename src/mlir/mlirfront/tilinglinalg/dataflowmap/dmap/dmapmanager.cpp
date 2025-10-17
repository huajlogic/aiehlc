/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "dmapmanager.h"
#include <iostream>

#define GET_TYPEDEF_CLASSES
#define GET_ATTRDEF_CLASSES
#define GET_OP_CLASSES
#define GET_OP_DEFS
//#define GET_OP_LIST
#include "dmapdialect.cc.inc"
#include "dmapattr.cc.inc"
#include "dmaptype.cc.inc"

#include "dmapop.cc.inc"
//#undef GET_OP_LIST
#undef GET_OP_DEFS

#undef GET_OP_CLASSES
#undef GET_ATTRDEF_CLASSES
#undef GET_TYPEDEF_CLASSES

void dmapdialect::initialize()  { 
    addOperations<
    #define GET_OP_LIST
    #include "dmapop.cc.inc"
        >();
    // 如果有 Attr / Type：addAttributes<...>(); addTypes<...>();
     addAttributes<
    #define GET_ATTRDEF_LIST
    #include "dmapattr.cc.inc"
    >();

        // 3. Types
    addTypes<
    #define GET_TYPEDEF_LIST
    #include "dmaptype.cc.inc"
    >();
}



ModuleOp dmapmanager::ops_test(MLIRContext* ctx, int totalN) {
    const int hwrowused= 4, hwcolused=4;
    OpBuilder builder(ctx);
    mlir::ModuleOp m = ModuleOp::create(builder.getUnknownLoc());
    //auto func = createdmapfuncByDim(ctx, true);
    //m.push_back(func);
    auto functype = builder.getFunctionType({},{});
    
    mlir::func::FuncOp main = builder.create<func::FuncOp>(builder.getUnknownLoc(), "main", functype);
    
    auto block = main.addEntryBlock();
    builder.setInsertionPointToEnd(block);
   
    auto retop = builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());
    m.push_back(main);
    llvm::errs() << m;
    return m;
}

void dmapmanager::loaddialect(MLIRContext* ctx) {
    ctx->getOrLoadDialect<mlir::func::FuncDialect>();
    ctx->getOrLoadDialect<dmap::dmapdialect>();
    ctx->getOrLoadDialect<mlir::scf::SCFDialect>();
    ctx->getOrLoadDialect<mlir::arith::ArithDialect>();
}

void dmapmanager::createdmapfuncByDim(OpBuilder& builder, MLIRContext* ctx, bool binput, Value mesh, Value tensor,
                                           uint32_t hwsplitnum, std::string splitAxis) {
        auto location = builder.getUnknownLoc();
        auto tensorhwaxisowner = splitAxis;
        // no region creatation
        //
        auto exec = builder.create<scf::ExecuteRegionOp>(builder.getUnknownLoc(), /*result types*/TypeRange{});
        
       
        return ;//func;
}
