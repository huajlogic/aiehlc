/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "routinghwlower.h"
struct EnableExtToAieShimPortpattern: public ConversionPattern {
    explicit EnableExtToAieShimPortpattern(MLIRContext* ctx, LLVMTypeConverter &converter, RoutingTopology & router) :
        ConversionPattern(routinghw::EnableExtToAieShimPort::getOperationName(), 1, ctx), typeconverter(converter), router_(router) {

    }
    LogicalResult matchAndRewrite(Operation *op , ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override{
        auto shimtileoprand = operands[0];
        auto shimtileop = shimtileoprand.getDefiningOp();
        //get the enable ext to aie port attribute
        int32_t portdirection=-1, portidx = -1;
        if (auto pd = op->getAttrOfType<IntegerAttr>("portdirection")) {
            portdirection = pd.getInt();
        }
        if (auto pi = op->getAttrOfType<IntegerAttr>("portidx")) {
            portidx = pi.getInt();
        }
        // get the tilecreate parameter
        // Access attributes by name
        int32_t rowValue=-1, colValue=-1;
        if (auto colAttr = shimtileop->getAttrOfType<IntegerAttr>("col")) {
            colValue = colAttr.getInt();
        } 
        if (auto rowAttr = shimtileop->getAttrOfType<IntegerAttr>("row")) {
            rowValue = rowAttr.getInt();
        }
        auto colConstOp = rewriter.create<emitc::ConstantOp>(op->getLoc(), rewriter.getI32Type(),rewriter.getI32IntegerAttr(colValue));
        auto rowConstOp = rewriter.create<emitc::ConstantOp>(op->getLoc(),rewriter.getI32Type(), rewriter.getI32IntegerAttr(rowValue));

        auto tileLocType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_LocType");

        auto tileLocOp = rewriter.create<emitc::CallOp>(
            op->getLoc(), "XAie_TileLoc", TypeRange{tileLocType}, 
            ValueRange{rowConstOp, colConstOp});

        //get the device instance
        auto devInstType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_DevInst");
        auto devInstPtrType = emitc::PointerType::get(devInstType);
        auto deviceInstOp = rewriter.create<emitc::CallOp>(
                op->getLoc(), "getOrCreateDeviceInstance", TypeRange{devInstPtrType}, ValueRange{});
        Value deviceInst = deviceInstOp.getResult(0);

        StringRef callee = "XAie_EnableShimDmaToAieStrmPort";
        Value arg0 = rewriter.create<mlir::emitc::ConstantOp>(op->getLoc(), rewriter.getI32Type(),rewriter.getI32IntegerAttr(portidx));
        auto callOp = rewriter.create<mlir::emitc::CallOp>(op->getLoc(), TypeRange{rewriter.getI32Type()}, callee, 
            ValueRange{deviceInst, tileLocOp.getResult(0), arg0});

        rewriter.eraseOp(op);
        return success();
    }

private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
};

struct ConnectStreamSingleSwitchPortpattern: public ConversionPattern {
    explicit ConnectStreamSingleSwitchPortpattern(MLIRContext* ctx, LLVMTypeConverter &converter, RoutingTopology & router) :
        ConversionPattern(routinghw::ConnectStreamSingleSwitchPort::getOperationName(), 1, ctx), typeconverter(converter), router_(router) {

    }
    LogicalResult matchAndRewrite(Operation *op , ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override{
        auto tileoprand = operands[0];
        auto tileop = tileoprand.getDefiningOp();
        
        int32_t rowValue=-1, colValue=-1;
        if (auto colAttr = tileop->getAttrOfType<IntegerAttr>("col")) {
            colValue = colAttr.getInt();
        } 
        if (auto rowAttr = tileop->getAttrOfType<IntegerAttr>("row")) {
            rowValue = rowAttr.getInt();
        }

        int32_t masterportdirection=-1, masterportidx = -1,slaveportdirection=-1, slaveportidx = -1;
        std::string masterportdirectionstr="fixme",slaveportdirectionstr="fixme";
        if (auto pd = op->getAttrOfType<StringAttr>("masterportdirection")) {
            masterportdirectionstr = pd.getValue().str();
        }
        if (auto pi = op->getAttrOfType<IntegerAttr>("masterportidx")) {
            masterportidx = pi.getInt();
        }

        if (auto pd = op->getAttrOfType<StringAttr>("slaveportdirection")) {
            slaveportdirectionstr = pd.getValue().str();
        }
        if (auto pi = op->getAttrOfType<IntegerAttr>("slaveportidx")) {
            slaveportidx = pi.getInt();
        }

        //StringRef callee = "XAie_StrmConnCctEnable";
        //Value arg0 = rewriter.create<mlir::emitc::ConstantOp>(op->getLoc(), rewriter.getI32Type(),rewriter.getI32IntegerAttr(42));
        ///auto callOp = rewriter.create<mlir::emitc::CallOp>(op->getLoc(), TypeRange{rewriter.getI32Type()}, callee, ValueRange{arg0});

        auto colConstOp = rewriter.create<emitc::ConstantOp>(op->getLoc(), rewriter.getI32Type(),rewriter.getI32IntegerAttr(colValue));
        auto rowConstOp = rewriter.create<emitc::ConstantOp>(op->getLoc(),rewriter.getI32Type(), rewriter.getI32IntegerAttr(rowValue));

        auto tileLocType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_LocType");

        auto tileLocOp = rewriter.create<emitc::CallOp>(
            op->getLoc(), "XAie_TileLoc", TypeRange{tileLocType}, 
            ValueRange{rowConstOp, colConstOp});

        auto devInstType = emitc::OpaqueType::get(rewriter.getContext(), "XAie_DevInst");
        auto devInstPtrType = emitc::PointerType::get(devInstType);
        auto deviceInstOp = rewriter.create<emitc::CallOp>(
                op->getLoc(), "getOrCreateDeviceInstance", TypeRange{devInstPtrType}, ValueRange{});
        Value deviceInst = deviceInstOp.getResult(0);

        StringRef callee = "XAie_StrmConnCctEnable";
         //string type
        mlir::Type stringType = mlir::emitc::PointerType::get(rewriter.getI8Type());

        Value masterport = rewriter.create<mlir::emitc::ConstantOp>(op->getLoc(), stringType,
                                        mlir::emitc::OpaqueAttr::get(rewriter.getContext(), masterportdirectionstr));
        Value masteridx = rewriter.create<mlir::emitc::ConstantOp>(op->getLoc(), rewriter.getI32Type(),rewriter.getI32IntegerAttr(masterportidx));
        Value slaveport = rewriter.create<mlir::emitc::ConstantOp>(op->getLoc(), stringType,
                                        mlir::emitc::OpaqueAttr::get(rewriter.getContext(), slaveportdirectionstr));
        Value slaveidx = rewriter.create<mlir::emitc::ConstantOp>(op->getLoc(), rewriter.getI32Type(),rewriter.getI32IntegerAttr(slaveportidx));
        auto callOp = rewriter.create<mlir::emitc::CallOp>(op->getLoc(), TypeRange{rewriter.getI32Type()}, callee, 
            ValueRange{deviceInst, tileLocOp.getResult(0), masterport,masteridx,slaveport,slaveidx});

        rewriter.eraseOp(op);
        return success();
    }

private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
};

struct routingRoutingCreatePattern: public ConversionPattern {
    explicit routingRoutingCreatePattern(MLIRContext* ctx, LLVMTypeConverter &converter, RoutingTopology & router) :
        ConversionPattern(routing::RoutingCreate::getOperationName(), 1, ctx), typeconverter(converter), router_(router) {

    }
    LogicalResult matchAndRewrite(Operation *op , ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override{
         // Preconditions for the simple lowering.
        //rewriter.eraseOp(op);
        //return success();
        if (op->getNumRegions() != 1)
        return rewriter.notifyMatchFailure(op, "expected exactly one region");
        Region &region = op->getRegion(0);
        if (!llvm::hasSingleElement(region))
        return rewriter.notifyMatchFailure(op, "expected single-block region");
        Block &body = region.front();

        // Expect one region argument that mirrors the operand `(scf_idx = %c0_i32 : i32)`.
        if (body.getNumArguments() != 1 || op->getNumOperands() != 1)
        return rewriter.notifyMatchFailure(op, "expected 1 operand and 1 region arg");

        // Make sure we have one result.
        if (op->getNumResults() != 1)
        return rewriter.notifyMatchFailure(op, "expected single result");

        // Replace all uses of the region argument with the op's operand.
        Value idx = op->getOperand(0);
        BlockArgument barg = body.getArgument(0);
        rewriter.replaceAllUsesWith(barg, idx);

        

        Location loc = op->getLoc();
        Block *parent = op->getBlock();

        // Insert "{\n" before the op.
        rewriter.setInsertionPoint(op);
        auto open = rewriter.create<emitc::VerbatimOp>(loc, rewriter.getStringAttr("{\n"));

      
        // Inline the region body right before the original op.
        // After this, the ops from the region are moved into `parent` before `op`.
        Block *after = rewriter.splitBlock(parent, Block::iterator(op));
        rewriter.inlineRegionBefore(region, *parent->getParent(), Region::iterator(after));

        rewriter.eraseOp(op);
        return success();

        // The inlined block should end with your region terminator (e.g., routing::YieldOp).
        // Grab its operand (the region result), erase the terminator.
        Operation *beforeOp = op->getPrevNode(); // last op of inlined body
        if (!beforeOp)
        return rewriter.notifyMatchFailure(op, "empty region body after inlining");

        // Adjust this cast to your actual terminator type.
        auto yield = dyn_cast<routing::YieldOp>(beforeOp);
        if (!yield)
        return rewriter.notifyMatchFailure(op, "expected routing yield terminator");

        // Single result expected; take it.
        if (yield->getNumOperands() != 1)
        return rewriter.notifyMatchFailure(op, "yield must return one value");

        Value regionResult = yield->getOperand(0);
        rewriter.eraseOp(yield);

        // Insert "}\n" at the original op position (now after the inlined body).
        rewriter.setInsertionPoint(op);
        rewriter.create<emitc::VerbatimOp>(loc, rewriter.getStringAttr("}\n"));

        // Replace the original op's result with the value produced in the region.
        rewriter.replaceOp(op, regionResult);

        return success();
    }

private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
};

struct IOShimTileCreatepattern: public ConversionPattern {
    explicit IOShimTileCreatepattern(MLIRContext* ctx, LLVMTypeConverter &converter, RoutingTopology & router) :
        ConversionPattern(routinghw::IOShimTileCreate::getOperationName(), 1, ctx), typeconverter(converter), router_(router) {

    }
    LogicalResult matchAndRewrite(Operation *op , ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override{
        rewriter.eraseOp(op);
        return success();
    }

private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
};

struct TileArrayHandleCreatepattern: public ConversionPattern {
    explicit TileArrayHandleCreatepattern(MLIRContext* ctx, LLVMTypeConverter &converter, RoutingTopology & router) :
        ConversionPattern(routinghw::TileArrayHandleCreate::getOperationName(), 1, ctx), typeconverter(converter), router_(router) {

    }
    LogicalResult matchAndRewrite(Operation *op , ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override{
        rewriter.eraseOp(op);
        return success();
    }

private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
};

struct TileCreatepattern: public ConversionPattern {
    explicit TileCreatepattern(MLIRContext* ctx, LLVMTypeConverter &converter, RoutingTopology & router) :
        ConversionPattern(routinghw::TileCreate::getOperationName(), 1, ctx), typeconverter(converter), router_(router) {

    }
    LogicalResult matchAndRewrite(Operation *op , ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override{
        rewriter.eraseOp(op);
        return success();
    }

private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
};

struct arithconstantconvert : public ConversionPattern {
    explicit arithconstantconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(arith::ConstantOp::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

void declareAieTileFunction(mlir::ModuleOp module) {
  mlir::MLIRContext *context = module.getContext();
  mlir::OpBuilder builder(context);

  builder.setInsertionPointToStart(module.getBody());
  builder.create<mlir::emitc::IncludeOp>(module.getLoc(), "xaiengine.h", true);
  // 1. Define the custom `xaie_loc` type using emitc.opaque.
  mlir::Type xaieLocType = mlir::emitc::OpaqueType::get(context, "XAie_LocType");
  auto devInstType = emitc::OpaqueType::get(context, "XAie_DevInst");
  auto devInstPtrType = emitc::PointerType::get(devInstType);
  mlir::Type i32Type = builder.getI32Type();
  //string type
  mlir::Type stringType = mlir::emitc::PointerType::get(builder.getI8Type());

  llvm::ArrayRef<mlir::Type> argTypes = {i32Type, i32Type};

  //auto funcType = mlir::FunctionType::get(context, argTypes, {xaieLocType});
  mlir::FunctionType funcType = builder.getFunctionType({i32Type, i32Type}, {xaieLocType});
  mlir::FunctionType getdevInstType = builder.getFunctionType({}, {devInstPtrType});
  mlir::FunctionType shimportenableType = builder.getFunctionType({devInstPtrType, xaieLocType, i32Type}, {i32Type});
  mlir::FunctionType tileconnectType = builder.getFunctionType({devInstPtrType, xaieLocType, stringType,i32Type,stringType,i32Type}, {i32Type});

  auto decl1 = builder.create<emitc::FuncOp>(module.getLoc(), "XAie_TileLoc", funcType);
  decl1.setVisibility(SymbolTable::Visibility::Private);

  auto decl2 = builder.create<emitc::FuncOp>(module.getLoc(), "getOrCreateDeviceInstance", getdevInstType);
  decl2.setVisibility(SymbolTable::Visibility::Private);

  auto decl3 = builder.create<emitc::FuncOp>(module.getLoc(), "XAie_EnableShimDmaToAieStrmPort", shimportenableType);
  decl3.setVisibility(SymbolTable::Visibility::Private);

  auto decl4 = builder.create<emitc::FuncOp>(module.getLoc(), "XAie_StrmConnCctEnable", tileconnectType);
  decl4.setVisibility(SymbolTable::Visibility::Private);
}

void RoutingHWLowerPass::runOnOperation() {
    auto module = getOperation();
    auto& ctx = getContext();
    RewritePatternSet patterns(&ctx);
    ConversionTarget target(ctx);
    LLVMTypeConverter typeConverter(&ctx);
    target.addLegalDialect<mlir::LLVM::LLVMDialect>();
    //target.addIllegalOp<arith::ConstantOp>();
    //target.addIllegalOp<routing::RoutingCreate>();
    target.addIllegalOp<routinghw::EnableExtToAieShimPort>();
    target.addIllegalOp<routinghw::ConnectStreamSingleSwitchPort>();
    target.addIllegalOp<routinghw::TileCreate>();
    target.addIllegalOp<routinghw::IOShimTileCreate>();
    target.addIllegalOp<routinghw::TileArrayHandleCreate>();
    target.addLegalDialect<mlir::emitc::EmitCDialect>();

    //add header
    // The headers to add
    
    if (auto mop = dyn_cast<ModuleOp>(*module)) {
        declareAieTileFunction(mop);
    }
 ///*
    //target.addIllegalDialect<routinghw::RoutingHWDialect>();
    llvm::outs() << "RoutingHWLowerPass::runOnOperation\n";
    patterns.add<EnableExtToAieShimPortpattern>(&ctx,typeConverter,rtopology_);
    patterns.add<ConnectStreamSingleSwitchPortpattern>(&ctx,typeConverter,rtopology_);
    patterns.add<TileCreatepattern>(&ctx,typeConverter,rtopology_);
    patterns.add<IOShimTileCreatepattern>(&ctx,typeConverter,rtopology_);
    patterns.add<TileArrayHandleCreatepattern>(&ctx,typeConverter,rtopology_);
    patterns.add<routingRoutingCreatePattern>(&ctx,typeConverter,rtopology_);
    //patterns.add<arithconstantconvert>(&ctx,typeConverter);
    if (failed(applyPartialConversion(module, target, std::move(patterns)))) {
        llvm::outs() << "applyPartialConversion failed\n";
    }

    std::string cppOutput;
    llvm::raw_string_ostream os(cppOutput);

    //remove the dead code
    
    mlir::RewritePatternSet patternscde(&ctx);
    for (auto* dialect : ctx.getLoadedDialects()) {
        dialect->getCanonicalizationPatterns(patternscde);
    }
    for (mlir::RegisteredOperationName op : ctx.getRegisteredOperations()) {
        op.getCanonicalizationPatterns(patternscde, &ctx);
    }
    // Apply the patterns greedily. This will simplify and clean up the IR.
    if (mlir::failed(mlir::applyPatternsAndFoldGreedily(module, std::move(patternscde)))) {
                // Handle error
        signalPassFailure();
    }
    

  // This is the core translation call.
  // It takes the module and an output stream.
    if (mlir::failed(mlir::emitc::translateToCpp(module, os))) {
        llvm::errs() << "Failed to translate MLIR to C++.\n";
        return;
    }



  // 4. Print the resulting C++ code.
    std::cout << "--- Generated C++ Code ---\n" << os.str() << std::endl;
       // */
};