/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include <iostream>
#include "routinghwmanager.h"
#include "routinghwlower.h"
#include "routingmanager.h"
#include "routinglower.h"
#include "../passroutingtodmap/routingtodmap.h"
#include "routingunrolling.h"
#include "mlir/Conversion/SCFToEmitC/SCFToEmitC.h"
//#include "llvm/IR/IRPrintingPasses.h"
#include "llvm/IRPrinter/IRPrintingPasses.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlow.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"


#include "routingdeadargclean.h"

#include "routingconstantfold.h"
void routingtoroutinghw() {
     MLIRContext ctx;
    
    routingmanager mtest;
    routinghwmanager mtesthw;
    mtesthw.loaddialect(&ctx);
    mtest.loaddialect(&ctx);

    ctx.getOrLoadDialect<arith::ArithDialect>();
    
    //auto module1 = mtest.createroutingfunc(&ctx,1);
    auto module1 = mtest.ops_testNew(&ctx,1);
    module1.dump();
    //auto module2 = mtesthw.ops_test(&ctx);
    std::cout << "main" <<std::endl;
    
    mlir::PrintIRPassOptions options;

    mlir::PassManager pm(&ctx);;
    RoutingTopology rtopology("Gen2");
    
    options.label = "Before RoutingUnrollingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingUnrollingLowerPass>());
    options.label = "After RoutingUnrollingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingLowerPass>(rtopology));
    options.label = "After RoutingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    options.label = "After RoutingHWLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //remove dead arg
    pm.addPass(std::make_unique<RoutingDeadArgPass>());
    options.label = "After RoutingDeadArgPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //The constanfold change emitc.call into emic.call_opaque to convert 
    /*
    XAie_LocType v251 = XAie_TileLoc(v1, v10);
    XAie_DevInst* v252 = getOrCreateDeviceInstance();
    int32_t v253 = XAie_StrmConnCctEnable(v252, v251, v6, v13, v5, v12);
    */
    //into
    /*
    int32_t v80 = XAie_StrmConnCctEnable(getOrCreateDeviceInstance(), XAie_TileLoc(6,3), WEST, 0, EAST, 0); 
    */
    pm.addPass(std::make_unique<RoutingConstantFoldPass>());

    options.label = "After RoutingConstantFoldPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //remove the dead code
    pm.addPass(mlir::createCanonicalizerPass());

    options.label = "After createCanonicalizerPasse:";
    pm.addPass(mlir::createPrintIRPass(options));

    //remove dead arg
    //pm.addPass(mlir::createConvertSCFToEmitCPass());
    (void)pm.run(module1);

    llvm::outs() << "----------module1.dump---------\n";
    module1.dump();
/*
    mlir::PassManager pm2(&ctx);;
    pm2.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    (void)pm2.run(module1);
    module1.dump();
  */
//conver emitc into c code  
    mlir::LogicalResult result = mlir::emitc::translateToCpp(module1, llvm::outs());
    return;
}
void routingtodmap() {
     MLIRContext ctx;
    
    routingmanager mtest;
    routinghwmanager mtesthw;
    mtesthw.loaddialect(&ctx);
    mtest.loaddialect(&ctx);

    ctx.getOrLoadDialect<arith::ArithDialect>();
    
    //auto module1 = mtest.createroutingfunc(&ctx,1);
    auto module1 = mtest.ops_testNew_dmap(&ctx,1);
    module1.dump();
    //auto module2 = mtesthw.ops_test(&ctx);
    std::cout << "main" <<std::endl;
    
    mlir::PrintIRPassOptions options;

    mlir::PassManager pm(&ctx);;
    RoutingTopology rtopology("Gen2");
    
    options.label = "Before RoutingUnrollingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingUnrollingLowerPass>());
    options.label = "After RoutingUnrollingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingToDmapPass>(rtopology));
    
    //into
    /*
    int32_t v80 = XAie_StrmConnCctEnable(getOrCreateDeviceInstance(), XAie_TileLoc(6,3), WEST, 0, EAST, 0); 
    */
    pm.addPass(std::make_unique<RoutingConstantFoldPass>());

    options.label = "After RoutingConstantFoldPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //remove the dead code
    pm.addPass(mlir::createCanonicalizerPass());

    options.label = "After createCanonicalizerPasse:";
    pm.addPass(mlir::createPrintIRPass(options));

    //remove dead arg
    //pm.addPass(mlir::createConvertSCFToEmitCPass());
    (void)pm.run(module1);

    llvm::outs() << "----------module1.dump---------\n";
    module1.dump();
/*
    mlir::PassManager pm2(&ctx);;
    pm2.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    (void)pm2.run(module1);
    module1.dump();
  */
//conver emitc into c code  
    //mlir::LogicalResult result = mlir::emitc::translateToCpp(module1, llvm::outs());
    return;
}
int main(int argc, char* argv[]) {
    //routingtoroutinghw();
    routingtodmap();
    return 0;
}