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
    RewritePatternSet patternsGlobal(&ctx);
    ConversionTarget target(ctx);
    target.addLegalDialect<dmap::dmapdialect>();
    target.addLegalDialect<dmaphop::dmaphopdialect>();
    target.addLegalOp<dmap::YieldOp>();
    LLVMTypeConverter typeconverter(&ctx);
    patternsGlobal.add<indexcastconvert>(&ctx, typeconverter);
    patternsGlobal.add<define_io_engineconvert>(&ctx, typeconverter);
    patternsGlobal.add<define_core_groupconvert>(&ctx, typeconverter);
    patternsGlobal.add<define_port_configureconvert>(&ctx, typeconverter);
    //
    patternsGlobal.add<create_io_engin_with_configconvert>(&ctx, typeconverter);
    patternsGlobal.add<create_core_group_with_configconvert>(&ctx, typeconverter);
    patternsGlobal.add<create_streamconvert>(&ctx, typeconverter);
    patternsGlobal.add<createchainstreamconvert>(&ctx, typeconverter);

    patternsGlobal.add<PushConvert>(&ctx, typeconverter,rtopology_, 0/*op through memtile or not*/);

    if (failed(applyPartialConversion(module, target, std::move(patternsGlobal) ))) {
        llvm::outs() << "routing convert failed 2--- \n";
    }
    return;
}