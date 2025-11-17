/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "dmaptodmaphop.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include <sstream>
int dmaphopioIdx = 0;
struct indexcastconvert : public ConversionPattern {
    explicit indexcastconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(arith::IndexCastOp::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
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

struct define_io_engineconvert : public ConversionPattern {
    explicit define_io_engineconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::define_io_engine::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {   
        // Replace all uses of this op's result with its operand.
        // This allows the user of this op to be processed correctly.
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

//createdummytensor
struct define_core_groupconvert : public ConversionPattern {
    explicit define_core_groupconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::define_core_group::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

struct define_port_configureconvert : public ConversionPattern {
    explicit define_port_configureconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::define_port_configure::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};
//createdummytensor
struct create_io_engin_with_configconvert : public ConversionPattern {
    explicit create_io_engin_with_configconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::create_io_engin_with_config::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

//createdummytensor
struct create_core_group_with_configconvert : public ConversionPattern {
    explicit create_core_group_with_configconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::create_core_group_with_config::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

//createdummytensor
struct create_streamconvert : public ConversionPattern {
    explicit create_streamconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::createstream::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

struct createchainstreamconvert : public ConversionPattern {
    explicit createchainstreamconvert(MLIRContext * ctx, LLVMTypeConverter &converter):
        ConversionPattern(dmap::createchainstream::getOperationName(),1, ctx), typeconverter(converter) {

        }
    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
};

//RoutingCreate
struct PushConvert : public ConversionPattern {
    explicit PushConvert(MLIRContext * ctx, LLVMTypeConverter &converter, RoutingTopology & router, uint32_t oplevel):
        ConversionPattern(dmap::push::getOperationName(),1, ctx), typeconverter(converter), router_(router) {
            //setHasBoundedRewriteRecursion(true);
            //MLIRContext * context = ctx;
            moplevel = oplevel;
        }

    LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter ) const override {    
        rewriter.eraseOp(op);
        return success();
    }
private:
    LLVMTypeConverter& typeconverter;
    RoutingTopology & router_;
    uint32_t moplevel;
    //MLIRContext * context;
};

void DmapToDmaphopPass::getDependentDialects(DialectRegistry &registry) const {
        registry.insert<LLVM::LLVMDialect>();
}
DmapToDmaphopPass::DmapToDmaphopPass(RoutingTopology& rtopology):rtopology_(rtopology) {
}
void DmapToDmaphopPass::runOnOperation() {
    auto& ctx = getContext();
    auto module = getOperation();
    RewritePatternSet patterns(&ctx),patternsGlobal(&ctx);
    ConversionTarget target(ctx);
    target.addIllegalDialect<dmap::dmapdialect>();
    target.addLegalOp<routing::RoutingCreate>();
    target.addLegalOp<routing::YieldOp>();
    target.addLegalDialect<dmaphop::dmaphopdialect>();

    target.addLegalOp<dmap::YieldOp>();
    LLVMTypeConverter typeconverter(&ctx);
    patternsGlobal.add<indexcastconvert>(&ctx, typeconverter);

    patterns.add<define_io_engineconvert>(&ctx, typeconverter);
    patterns.add<define_core_groupconvert>(&ctx, typeconverter);
    patterns.add<define_port_configureconvert>(&ctx, typeconverter);
    //
    patterns.add<create_io_engin_with_configconvert>(&ctx, typeconverter);
    patterns.add<create_core_group_with_configconvert>(&ctx, typeconverter);
    patterns.add<create_streamconvert>(&ctx, typeconverter);
    patterns.add<createchainstreamconvert>(&ctx, typeconverter);

    patterns.add<PushConvert>(&ctx, typeconverter,rtopology_, 0/*op through memtile or not*/);
    llvm::outs() << "dmaphop--pass--\n";
    /*
      There are two patterns are used for different purpose
      first, the ops what we plan to convert is inside the executeregionop, hence we should use walk to
      go inside this op for the parttern convert, the patterns variable is used for such purpose.
      patternsglobal is the second pattern used to convert the ops outside of the executeregionop
      for example arith.constant routingrectedummytensor etc if need.
    */
    FrozenRewritePatternSet frozenPatterns(std::move(patterns));
    module->walk([&](scf::ExecuteRegionOp exec) {
        //only deal with the routing_memo executeregionop
        if (!exec->getAttrOfType<StringAttr>("routing_memo")) {
            llvm::outs() << "dmaphop convert failed--not routing memo \n";
            return;
        }
        llvm::errs() << exec;
        if (failed(applyPartialConversion(exec, target, frozenPatterns ))) {
            llvm::outs() << "dmaphop convert failed \n";
        }
    });//*/

    if (failed(applyPartialConversion(module, target, std::move(patternsGlobal) ))) {
        llvm::outs() << "dmaphop convert failed in global--- \n";
    }
    return;
}