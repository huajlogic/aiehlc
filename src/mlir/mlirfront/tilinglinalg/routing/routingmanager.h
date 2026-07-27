/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef __ROUTING_MANAGER__
#define __ROUTING_MANAGER__
#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/IR/TypeSupport.h"
#include "mlir/IR/Types.h"
#include "llvm/ADT/TypeSwitch.h"

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/OperationSupport.h"
#include "mlir/IR/Value.h"
#include "mlir/Interfaces/FunctionImplementation.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/LogicalResult.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"

#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Arith/IR/Arith.h"

struct TensorSplitDesc;
struct SplitModel;

//fieldparser
#include "mlir/IR/DialectImplementation.h"

#include "routinginterface.h.inc"

#include "routingdialect.h.inc"

using namespace mlir;
using namespace routing;

#define GET_ATTRDEF_CLASSES
#include "routingattr.h.inc"
#undef GET_ATTRDEF_CLASSES

#define GET_TYPEDEF_CLASSES
#include "routingtype.h.inc"
#undef GET_TYPEDEF_CLASSES

#define GET_OP_CLASSES
#define GET_OP_DECLS
#include "routingop.h.inc"
#undef GET_OP_DECLS
#undef GET_OP_CLASSEST

namespace routing {
// GEMM per-dim tiling scalars sourced from routing.partitiontensor TilingAttr.
// These mirror the flat module attrs (routing.tile_m / tile_rows / tile_n /
// tile_cols / effective_k / full_k / k_rounds) but come from the IR op, making
// the TilingAttr the single source of truth for the fullconnect_auto=1 schedule.
struct GemmTilingScalars {
    int64_t tileM = 0;
    int64_t tileRows = 0;
    int64_t mRounds = 0;
    int64_t tileN = 0;
    int64_t tileCols = 0;
    int64_t nRounds = 0;
    int64_t effectiveK = 0;
    int64_t fullK = 0;
    int64_t kRounds = 0;
    bool found = false; // true when at least one usable TilingAttr was read
};

// Walk the module's routing.partitiontensor ops and extract GEMM tiling scalars
// from their #routing.tiling TilingAttr. Role is resolved by PartitionAttr's
// hwAxisOwner ("row" -> M, "col" -> N); the K dimension is the un-meshed non-split
// dim (outer.rounds==1) carrying a nested on-core slice_tiling. Only active when
// routing.fullconnect_auto==1; otherwise returns {found=false} so callers fall
// back to the flat module attrs.
GemmTilingScalars readGemmTilingScalars(mlir::ModuleOp moduleOp);
} // namespace routing

class routingmanager{
public:
    routingmanager(){};
    void type_interface_test(MLIRContext* ctx) ;
    ModuleOp ops_test(MLIRContext* ctx,int totalN=2) ;
    ModuleOp ops_testNew(MLIRContext *ctx, int totalN = 2, std::string routingname = "");
    mlir::func::FuncOp createroutingfunc(MLIRContext* ctx, int totalN = 16,bool purefunc=false) ;
    void createroutingfuncByDim(OpBuilder& builder, MLIRContext* ctx,  bool binput,Value mesh, Value tensor, uint32_t hwsplitnum, std::string splitAxis);
    void createroutingfuncGEMM(OpBuilder &builder, MLIRContext *ctx, Value mesh, Value tensorA, Value tensorB,
                               Value tensorC, uint32_t hwsplitnum, std::string splitAxis);
    /// Generalized routing function driven by SplitModel instead of hardcoded logic.
    /// Creates partitiontensor, extract_data, IO, and movedata ops for each tensor
    /// according to its TensorSplitDesc.
    void createroutingfuncBySplitModel(OpBuilder &builder, MLIRContext *ctx, Value mesh,
                                       const std::vector<Value> &tensors, const std::vector<bool> &isInputFlags,
                                       int meshRows, int meshCols, const struct SplitModel &splitModel);
    //void createroutingfuncByDimDmap(OpBuilder& builder, MLIRContext* ctx,  bool binput,Value mesh, Value tensor, uint32_t hwsplitnum, std::string splitAxis);
    static void loaddialect(MLIRContext* ctx);
};
#endif//__ROUTING_MANAGER__