/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "passblueprinttoschedule.h"
#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include "hw/ResourceManager.h"
#include "hw/hwresource.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Transforms/DialectConversion.h"
#include "routingmanager.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include <iostream>
#include <sstream>
#include <unordered_map>
#include <vector>

using namespace mlir;
using namespace dfscheblueprint;
using namespace dfschedule;

namespace {

// Trace a Value back through the SSA chain to find the originating function
// argument index.  This walks through bufferization.to_tensor,
// routing.routingcreatescheduletensor, routing.partitiontensor,
// routing.routingextract_data, dfscheblueprint.declare_data, and
// scf.execute_region captures until it reaches a BlockArgument of a func::FuncOp.
// Returns the argument index (0-based), or -1 if the chain cannot be resolved.
static int traceToFuncArgIndex(Value v) {
    // Walk up the def chain, max 20 hops to avoid infinite loops
    for (int depth = 0; depth < 20; ++depth) {
        // If v is a block argument of a func op, we found it
        if (auto blockArg = dyn_cast<BlockArgument>(v)) {
            if (auto funcOp = dyn_cast<func::FuncOp>(blockArg.getOwner()->getParentOp()))
                return static_cast<int>(blockArg.getArgNumber());
            break; // can't follow further through a block argument
        }
        Operation *defOp = v.getDefiningOp();
        if (!defOp)
            break;

        // routing ops that forward data through operand 0
        if (defOp->getName().getStringRef() == "routing.routingextract_data" ||
            defOp->getName().getStringRef() == "routing.routingcreatescheduletensor" ||
            defOp->getName().getStringRef() == "routing.partitiontensor") {
            v = defOp->getOperand(0);
            continue;
        }
        // bufferization.to_tensor %memref -> follow %memref (operand 0)
        if (defOp->getName().getStringRef() == "bufferization.to_tensor") {
            v = defOp->getOperand(0);
            continue;
        }
        // dfscheblueprint.declare_data -> follow init_tensor (operand 0)
        if (defOp->getName().getStringRef() == "dfscheblueprint.declare_data") {
            v = defOp->getOperand(0);
            continue;
        }
        // tensor.extract_slice -> follow source tensor (operand 0)
        if (defOp->getName().getStringRef() == "tensor.extract_slice") {
            v = defOp->getOperand(0);
            continue;
        }
        // Generic single-result ops that just forward operand 0
        if (defOp->getNumOperands() > 0) {
            v = defOp->getOperand(0);
            continue;
        }
        break;
    }
    return -1; // unable to resolve
}

// Trace from a FlowConfigOp's view value back through the SSA chain to find
// the originating function argument index.
static int traceFlowConfigToFuncArgIndex(dfscheblueprint::FlowConfigOp flowConfig) {
    Value viewValue = flowConfig.getView();
    if (!viewValue)
        return -1;
    return traceToFuncArgIndex(viewValue);
}

// Generic template function to look up any operation by symbol reference
// This function searches for an operation of type OpTy with a matching symbol name
// The search starts in the same block as rootOp and then searches parent regions
template <typename OpTy>
static OpTy lookupSymbolOp(Operation *rootOp, SymbolRefAttr target) {
    StringRef targetName = target.getRootReference().getValue();
    
    // First, search in the same block as the rootOp
    Block *parentBlock = rootOp->getBlock();
    if (parentBlock) {
        for (Operation &op : *parentBlock) {
            if (auto targetOp = dyn_cast<OpTy>(&op)) {
                if (targetOp.getSymName() == targetName) {
                    return targetOp;
                }
            }
        }
    }
    
    // If not found, try searching in parent regions (for nested structures)
    Operation *parentOp = rootOp->getParentOp();
    while (parentOp) {
        for (Region &region : parentOp->getRegions()) {
            for (Block &block : region) {
                for (Operation &op : block) {
                    if (auto targetOp = dyn_cast<OpTy>(&op)) {
                        if (targetOp.getSymName() == targetName) {
                            return targetOp;
                        }
                    }
                }
            }
        }
        parentOp = parentOp->getParentOp();
    }
    
    return nullptr;
}

// Helper function to look up TileGroupOp by symbol reference (wrapper for backward compatibility)
static dfscheblueprint::TileGroupOp lookupTileGroup(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::TileGroupOp>(rootOp, target);
}

// Unified template pattern to erase dfscheblueprint operations
// FlowConfigOp is just erased since FlowTransferConversion reads its attributes
// and generates all the DMA BD configuration logic
template <typename OpTy>
struct EraseOpPattern : public OpConversionPattern<OpTy> {
    using OpConversionPattern<OpTy>::OpConversionPattern;

    LogicalResult
    matchAndRewrite(OpTy op, typename OpTy::Adaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        rewriter.eraseOp(op);
        return success();
    }
};

// Helper function to check if dskernel_receiver already exists in the module
static bool hasDSKernelReceiver(Operation *rootOp, StringRef kernelName) {
    // Find the module-level operation
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }
    
    // Search for existing dskernel_receiver with the given name
    for (Region &region : moduleOp->getRegions()) {
        for (Block &block : region) {
            for (Operation &op : block) {
                if (auto receiver = dyn_cast<dfschedule::DSKernelReceiverOp>(&op)) {
                    if (receiver.getSymName() == kernelName) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

// Helper function to check if kernel module already exists in the module
static bool hasKernelModule(Operation *rootOp, StringRef moduleName) {
    // Find the module-level operation
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }

    // Search for existing kernel module with the given name
    for (Region &region : moduleOp->getRegions()) {
        for (Block &block : region) {
            for (Operation &op : block) {
                if (auto kernelModule = dyn_cast<dfschedule::KernelModuleOp>(&op)) {
                    if (kernelModule.getSymName() == moduleName) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

// Helper function to get the module-level insertion point
static Operation* getModuleOp(Operation *rootOp) {
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }
    return moduleOp;
}

// Forward declarations for functions used in generateDSKernelReceiver
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target);

// Generate a kernel symbol declaration only (dfschedule.dskernel_receiver with empty body).
// Details (kernel module, buffers, locks, etc.) are filled in by a separate pass.
// Parameters:
//   - kernelName: symbol name for the kernel (same as load_kernel_group callee)
//   - insertBeforeOp: used to find module and insertion point
static void generateDSKernelReceiver(ConversionPatternRewriter &rewriter, Location loc, Operation *insertBeforeOp,
                                     StringRef kernelName, RankedTensorType tensorType, int64_t bufferLen,
                                     uint32_t basePacketId, int64_t coreChannel, uint32_t flowIndex) {
    (void)tensorType;
    (void)bufferLen;
    (void)basePacketId;
    (void)coreChannel;
    (void)flowIndex;

    Operation *rootModuleOp = getModuleOp(insertBeforeOp);
    Block &moduleBlock = rootModuleOp->getRegions().front().front();
    if (!moduleBlock.empty() && moduleBlock.back().hasTrait<OpTrait::IsTerminator>())
        rewriter.setInsertionPoint(&moduleBlock.back());
    else
        rewriter.setInsertionPointToEnd(&moduleBlock);

    auto receiverOp = rewriter.create<dfschedule::DSKernelReceiverOp>(loc, kernelName);
    receiverOp.getBody().emplaceBlock();
}

// Helper function to look up FlowConfigOp by symbol reference (wrapper for backward compatibility)
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::FlowConfigOp>(rootOp, target);
}

static dfscheblueprint::DataSliceOp lookupDataSlice(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::DataSliceOp>(rootOp, target);
}

// Shared state between pre-processing, FlowTransferConversion, and post-processing.
struct BlueprintPassState {
    Value rootMemref;
    MemRefType rootMemrefType;
    SmallVector<int64_t> rootShape;
    Type elementType;
    // Map from each arith.constant result to its allocated memref.
    // When multiple data tensors exist (e.g. input A, input B, output C),
    // each has its own backing memref.
    llvm::DenseMap<Value, Value> constantToMemref;
    // Routing module attributes, cached before conversion (module attrs may be
    // stripped during applyPartialConversion).
    int64_t tileM = 0;
    int64_t tileRows = 0;
    int64_t tileN = 0;
    int64_t tileCols = 0;
    int64_t effectiveK = 0;
    int64_t fullK = 0;
    int64_t kRounds = 0;
};

static SmallVector<OpFoldResult> toOpFoldResult(ArrayRef<int64_t> values, OpBuilder &b) {
    SmallVector<OpFoldResult> result;
    for (int64_t v : values)
        result.push_back(b.getI64IntegerAttr(v));
    return result;
}

// Pre-processing: lower arith.constant dense tensors to memrefs via
// bufferization.to_memref, keeping everything inside @main with no module-level
// memref.global.  Processes ALL DeclareDataOps so each data tensor (input A,
// input B, output C, etc.) gets its own backing memref.
static LogicalResult preprocessConstantToMemref(Operation *topLevel, std::shared_ptr<BlueprintPassState> state) {
    func::FuncOp mainFunc = nullptr;
    topLevel->walk([&](func::FuncOp f) {
        if (f.getName() == "main" || f.getName() == "host_canonicalized")
            mainFunc = f;
    });
    if (!mainFunc)
        return success();

    // Collect ALL DeclareDataOps
    SmallVector<dfscheblueprint::DeclareDataOp> declareDataOps;
    mainFunc.walk([&](dfscheblueprint::DeclareDataOp op) { declareDataOps.push_back(op); });
    if (declareDataOps.empty())
        return success();

    // Track which constants have already been lowered to avoid duplicates
    // (multiple DeclareDataOps may reference the same constant)
    llvm::DenseSet<Operation *> processedConstants;
    SmallVector<Value> allocatedMemrefs;

    for (auto declareDataOp : declareDataOps) {
        Value initTensor = declareDataOp.getInitTensor();

        // Case 1: arith.constant (original path — hardcoded data)
        if (auto constantOp = initTensor.getDefiningOp<arith::ConstantOp>()) {
            // Skip if this constant was already lowered
            if (processedConstants.count(constantOp.getOperation()))
                continue;
            processedConstants.insert(constantOp.getOperation());

            auto tensorType = dyn_cast<RankedTensorType>(constantOp.getType());
            if (!tensorType)
                continue;

            // Use the first constant's shape/type for the legacy rootShape/elementType fields
            if (!state->elementType) {
                state->rootShape.assign(tensorType.getShape().begin(), tensorType.getShape().end());
                state->elementType = tensorType.getElementType();
            }

            MemRefType memrefType = MemRefType::get(tensorType.getShape(), tensorType.getElementType());

            // Lower the dense constant: get a read-only memref view via bufferization.to_memref,
            // then alloc a writable buffer and copy into it.
            OpBuilder builder(constantOp.getOperation());
            builder.setInsertionPointAfter(constantOp.getOperation());
            auto loc = constantOp.getLoc();
            auto toMemref = builder.create<bufferization::ToMemrefOp>(loc, memrefType, constantOp.getResult());
            auto allocOp = builder.create<memref::AllocOp>(loc, memrefType);
            builder.create<memref::CopyOp>(loc, toMemref.getResult(), allocOp.getResult());

            // Register this constant's memref in the map
            state->constantToMemref[constantOp.getResult()] = allocOp.getResult();
            allocatedMemrefs.push_back(allocOp.getResult());

            // Keep legacy rootMemref/rootMemrefType pointing to the first allocation
            if (!state->rootMemref) {
                state->rootMemref = allocOp.getResult();
                state->rootMemrefType = memrefType;
            }
        }
        // Case 2: bufferization.to_tensor of func arg (external DDR pointer)
        // The user's pointer IS the DDR buffer — no alloc, no copy needed.
        else if (auto toTensorOp = initTensor.getDefiningOp<bufferization::ToTensorOp>()) {
            Value srcMemref = toTensorOp.getMemref();

            auto tensorType = dyn_cast<RankedTensorType>(toTensorOp.getType());
            if (!tensorType)
                continue;

            // Skip if already processed
            if (processedConstants.count(toTensorOp.getOperation()))
                continue;
            processedConstants.insert(toTensorOp.getOperation());

            if (!state->elementType) {
                state->rootShape.assign(tensorType.getShape().begin(), tensorType.getShape().end());
                state->elementType = tensorType.getElementType();
            }

            MemRefType memrefType = cast<MemRefType>(srcMemref.getType());

            // Use the func arg memref DIRECTLY — no alloc, no copy needed.
            state->constantToMemref[initTensor] = srcMemref;

            if (!state->rootMemref) {
                state->rootMemref = srcMemref;
                state->rootMemrefType = memrefType;
            }
        }
    }

    // Insert memref.dealloc for ALL allocated memrefs before the return op.
    if (!allocatedMemrefs.empty()) {
        Block &mainBlock = mainFunc.getBody().front();
        for (auto &op : mainBlock) {
            if (isa<func::ReturnOp>(op)) {
                OpBuilder builder(&op);
                for (auto memref : allocatedMemrefs) {
                    builder.create<memref::DeallocOp>(op.getLoc(), memref);
                }
                break;
            }
        }
    }

    return success();
}

// Post-processing: restructure scf.execute_region / routing ops into per-partition
// scf.execute_region blocks, erase old routing/tensor ops, and add memref.dealloc.
static LogicalResult postprocessRestructure(Operation *topLevel, std::shared_ptr<BlueprintPassState> state) {
    func::FuncOp mainFunc = nullptr;
    topLevel->walk([&](func::FuncOp f) {
        if (f.getName() == "main" || f.getName() == "host_canonicalized")
            mainFunc = f;
    });
    if (!mainFunc || !state->rootMemref)
        return success();

    // Find the old scf.execute_region with routing_memo attribute
    scf::ExecuteRegionOp oldExecuteRegion = nullptr;
    mainFunc.walk([&](scf::ExecuteRegionOp op) {
        if (op->hasAttr("routing_memo"))
            oldExecuteRegion = op;
    });
    if (!oldExecuteRegion)
        return success();

    SmallVector<routing::RoutingCreate> routingCreateOps;
    oldExecuteRegion.walk([&](routing::RoutingCreate op) { routingCreateOps.push_back(op); });

    OpBuilder builder(topLevel->getContext());
    builder.setInsertionPoint(oldExecuteRegion);

    for (auto routingCreate : routingCreateOps) {
        auto loc = routingCreate.getLoc();
        auto newRegionOp = builder.create<scf::ExecuteRegionOp>(loc, TypeRange{});
        Block *newBlock = new Block();
        newRegionOp.getRegion().push_back(newBlock);

        // Collect non-tensor, non-routing ops from the RoutingCreate body
        SmallVector<Operation *> opsToMove;
        Block &rcBody = routingCreate.getBody().front();
        for (auto &op : rcBody) {
            if (isa<tensor::ExtractSliceOp>(op))
                continue;
            if (op.hasTrait<OpTrait::IsTerminator>())
                continue;
            opsToMove.push_back(&op);
        }

        // Add yield terminator first, then move ops before it
        OpBuilder::InsertionGuard guard(builder);
        builder.setInsertionPointToEnd(newBlock);
        auto yieldOp = builder.create<scf::YieldOp>(loc);

        for (auto *op : opsToMove)
            op->moveBefore(yieldOp);
    }

    // Erase tensor.extract_slice ops inside RoutingCreate bodies (now dead)
    for (auto routingCreate : routingCreateOps) {
        Block &rcBody = routingCreate.getBody().front();
        SmallVector<Operation *> toErase;
        for (auto &op : rcBody) {
            if (isa<tensor::ExtractSliceOp>(op))
                toErase.push_back(&op);
        }
        for (auto *op : llvm::reverse(toErase)) {
            if (op->use_empty())
                op->erase();
        }
    }

    // Erase old scf.execute_region (contains partitiontensor, RoutingCreate shells, etc.)
    oldExecuteRegion->erase();

    // Erase dead arith.constant (tensor type), bufferization.to_tensor, and declare_data
    Block &mainBlock = mainFunc.getBody().front();
    SmallVector<Operation *> deadOps;
    for (auto &op : mainBlock) {
        if (auto constOp = dyn_cast<arith::ConstantOp>(op)) {
            if (isa<RankedTensorType>(constOp.getType()) && constOp.use_empty())
                deadOps.push_back(&op);
        }
        if (isa<bufferization::ToTensorOp>(op) && op.use_empty())
            deadOps.push_back(&op);
        if (isa<dfscheblueprint::DeclareDataOp>(op) && op.use_empty())
            deadOps.push_back(&op);
    }
    for (auto *op : llvm::reverse(deadOps))
        op->erase();

    // No dealloc needed: rootMemref comes from bufferization.to_memref which
    // is a read-only view over a constant — the caller does not own the buffer.

    return success();
}

// Trace a view value back through tensor.extract_slice → routing.partitiontensor
// → dfscheblueprint.declare_data → arith.constant to find the originating constant,
// then look up its memref in the constantToMemref map.
static Value resolveMemrefForView(Value viewValue, const BlueprintPassState &state) {
    // Walk backwards through extract_slice chain
    Value current = viewValue;
    while (auto extractSlice = current.getDefiningOp<tensor::ExtractSliceOp>()) {
        current = extractSlice.getSource();
    }
    // Now current should be the partition tensor result.
    // Walk through routing.partitiontensor to find its source tensor.
    if (auto partitionOp = current.getDefiningOp<routing::partitiontensor>()) {
        current = partitionOp.getTensor();
    }
    // Walk through dfscheblueprint.declare_data to find the init_tensor.
    if (auto declareOp = current.getDefiningOp<dfscheblueprint::DeclareDataOp>()) {
        current = declareOp.getInitTensor();
    }
    // Now current should be the arith.constant result or bufferization.to_tensor
    // result — look it up in the map.
    auto it = state.constantToMemref.find(current);
    if (it != state.constantToMemref.end())
        return it->second;
    return Value();
}

// === Tiling Classification ===
// Determines whether the M/N-dimension tiling requires host-side SCF loops.
enum class TilingMode { Match, Multiple, Invalid };

struct TilingClassification {
    TilingMode mMode;
    int64_t mRounds; // 1 for Match, tileRows/tileM for Multiple
    TilingMode nMode;
    int64_t nRounds; // 1 for Match, tileCols/tileN for Multiple
};

TilingClassification classifyTiling(ModuleOp moduleOp) {
    TilingClassification result;
    result.mMode = TilingMode::Match;
    result.mRounds = 1;
    result.nMode = TilingMode::Match;
    result.nRounds = 1;

    if (!moduleOp)
        return result;

    // M-dimension classification
    auto tileMAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
    auto tileRowsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");

    int64_t m = tileMAttr ? tileMAttr.getInt() : 0;
    int64_t rows = tileRowsAttr ? tileRowsAttr.getInt() : 0;

    if (m == 0 || m == rows) {
        result.mMode = TilingMode::Match;
        result.mRounds = 1;
    } else if (m < rows && rows % m == 0) {
        result.mMode = TilingMode::Multiple;
        result.mRounds = rows / m;
    } else {
        result.mMode = TilingMode::Invalid;
        result.mRounds = 0;
    }

    // N-dimension classification
    auto tileNAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
    auto tileColsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");

    int64_t n = tileNAttr ? tileNAttr.getInt() : 0;
    int64_t cols = tileColsAttr ? tileColsAttr.getInt() : 0;

    if (n == 0 || n == cols) {
        result.nMode = TilingMode::Match;
        result.nRounds = 1;
    } else if (n < cols && cols % n == 0) {
        result.nMode = TilingMode::Multiple;
        result.nRounds = cols / n;
    } else {
        result.nMode = TilingMode::Invalid;
        result.nRounds = 0;
    }

    return result;
}

// Returns true if policy is "n_outer_m_inner" (N is outer loop, M is inner/iter)
bool isNOuterPolicy(ModuleOp moduleOp) {
    if (!moduleOp)
        return false;
    auto attr = moduleOp->getAttrOfType<StringAttr>("routing.iter_policy");
    if (attr && attr.getValue() == "n_outer_m_inner")
        return true;
    return false; // default: m_outer_n_inner
}

// Pattern to convert dfscheblueprint::FlowTransferOp to dfschedule operations
// Logic:
// 1. Find shim tile from the "from" and "to" FlowConfigOps by checking type="shim"
// 2. Get DMA configuration from the shim FlowConfig's DMA attribute
// 3. Only do DMA config (declaretensor, declaretile, config.dma_bd, config.create_io) for shim tile
// 4. Create packet ops for core tiles, load_kernel_group, launch, schedule ops
// 5. Generate dskernel_receiver function with kernel DMA BD config
struct FlowTransferConversion : public OpConversionPattern<dfscheblueprint::FlowTransferOp> {
    std::shared_ptr<ResourceMgr> resourceMgr;
    std::shared_ptr<BlueprintPassState> passState;
    double bufferRatio;
    int64_t maxPingPongBytes;
    // Buffer index mapping keyed by data_id.
    // All tiles share the same kernel ELF (one BCF), so all row partitions
    // of the same input tensor must use the same buffer addresses (e.g.
    // buf_in_ping_0).  We map each unique data_id to a direction-specific
    // index so that row partitions reuse the same buffer name/address.
    mutable std::unordered_map<int32_t, int> dataIdToInputIdx;
    mutable std::unordered_map<int32_t, int> dataIdToOutputIdx;
    mutable int nextInputIdx = 0;
    mutable int nextOutputIdx = 0;

    FlowTransferConversion(MLIRContext *ctx, std::shared_ptr<ResourceMgr> mgr,
                           std::shared_ptr<BlueprintPassState> state, double ratio, int64_t maxPPBytes)
        : OpConversionPattern<dfscheblueprint::FlowTransferOp>(ctx), resourceMgr(std::move(mgr)),
          passState(std::move(state)), bufferRatio(ratio), maxPingPongBytes(maxPPBytes) {}

    LogicalResult
    matchAndRewrite(dfscheblueprint::FlowTransferOp op, OpAdaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();
        
        // Look up "from" FlowConfigOp
        SymbolRefAttr fromRef = op.getFrom();
        auto fromFlowConfig = lookupFlowConfig(op.getOperation(), fromRef);
        if (!fromFlowConfig) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Look up "to" FlowConfigOp
        SymbolRefAttr toRef = op.getTo();
        auto toFlowConfig = lookupFlowConfig(op.getOperation(), toRef);
        if (!toFlowConfig) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Step 1: Find the shim tile by checking type field
        // Determine which FlowConfig is shim and which is core
        dfscheblueprint::FlowConfigOp shimFlowConfig = nullptr;
        dfscheblueprint::FlowConfigOp coreFlowConfig = nullptr;
        bool shimIsSender = false;  // true if shim is "from" (MM2S), false if shim is "to" (S2MM)
        
        auto fromType = fromFlowConfig.getType();
        auto toType = toFlowConfig.getType();
        
        if (fromType && *fromType == "shim") {
            shimFlowConfig = fromFlowConfig;
            coreFlowConfig = toFlowConfig;
            shimIsSender = true;
        } else if (toType && *toType == "shim") {
            shimFlowConfig = toFlowConfig;
            coreFlowConfig = fromFlowConfig;
            shimIsSender = false;
        } else {
            // No shim tile found, just erase
            rewriter.eraseOp(op);
            return success();
        }
        
        // Get tile groups
        auto shimTileGroup = lookupTileGroup(shimFlowConfig.getOperation(), shimFlowConfig.getTarget());
        auto coreTileGroup = lookupTileGroup(coreFlowConfig.getOperation(), coreFlowConfig.getTarget());
        if (!shimTileGroup || !coreTileGroup) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Get base packet id for packet operations
        uint32_t basePacketId = op.getBasePacketId();
        
        // Get flow_index for per-flow DMA configurations
        uint32_t flowIndex = op.getFlowIndex();
        
        // Get the view operand from the shim FlowConfig (shim holds the data buffer)
        Value viewValue = shimFlowConfig.getView();
        Type viewType = viewValue.getType();

        // Trace back to tensor.extract_slice to get partition offsets/sizes
        auto partExtractSlice = viewValue.getDefiningOp<tensor::ExtractSliceOp>();
        RankedTensorType shimTensorType = dyn_cast<RankedTensorType>(viewType);

        // Resolve which backing memref this flow's data belongs to.
        // When multiple data tensors exist (A, B, C), each has its own memref.
        Value flowRootMemref;
        if (passState && !passState->constantToMemref.empty()) {
            flowRootMemref = resolveMemrefForView(viewValue, *passState);
        }
        // Fall back to legacy single rootMemref if per-constant lookup didn't find it
        if (!flowRootMemref && passState)
            flowRootMemref = passState->rootMemref;

        // Create partition subview from the pre-allocated root memref
        Value partitionSubview;
        MemRefType memrefType;
        Value ddrBuffer;
        if (flowRootMemref && partExtractSlice && shimTensorType) {
            // Path 1: view is a tensor.extract_slice — use partition offsets
            auto partOffsets = partExtractSlice.getStaticOffsets();
            auto partSizes = partExtractSlice.getStaticSizes();
            auto partStrides = partExtractSlice.getStaticStrides();

            auto partSubviewOp = rewriter.create<memref::SubViewOp>(
                loc, flowRootMemref, toOpFoldResult(partOffsets, rewriter), toOpFoldResult(partSizes, rewriter),
                toOpFoldResult(partStrides, rewriter));
            partitionSubview = partSubviewOp.getResult();

            ddrBuffer = partitionSubview;
            memrefType = cast<MemRefType>(ddrBuffer.getType());
        } else if (flowRootMemref && shimTensorType) {
            // Path 2: view is the full partition tensor (e.g. from routing.partitiontensor)
            // Use the entire root memref as the DDR buffer
            ddrBuffer = flowRootMemref;
            memrefType = cast<MemRefType>(flowRootMemref.getType());
            partitionSubview = flowRootMemref;
        } else if (auto mrType = dyn_cast<MemRefType>(viewType)) {
            memrefType = mrType;
        } else {
            rewriter.eraseOp(op);
            return success();
        }

        // --- Step 2 & 3: DMA CONFIG FOR SHIM TILE ONLY ---
        ArrayAttr shimTilesAttr = shimTileGroup.getTiles();
        if (shimTilesAttr.empty()) {
            rewriter.eraseOp(op);
            return success();
        }
        
        // Get first shim tile coordinates
        auto firstShimTile = dyn_cast<ArrayAttr>(shimTilesAttr[0]);
        if (!firstShimTile || firstShimTile.size() < 2) {
            rewriter.eraseOp(op);
            return success();
        }
        int64_t shimCol = cast<IntegerAttr>(firstShimTile[0]).getInt();
        int64_t shimRow = cast<IntegerAttr>(firstShimTile[1]).getInt();
        
        // Create dfschedule.declaretile for shim
        auto shimTileOp = rewriter.create<dfschedule::DeclareTileOp>(
            loc,
            dfschedule::TileType::get(rewriter.getContext()),
            rewriter.getI32IntegerAttr(shimCol),
            rewriter.getI32IntegerAttr(shimRow));
        
        // Step 2: Get DMA configuration from shim FlowConfig's DMA attribute
        auto shimDmaAttr = shimFlowConfig.getDma();
        auto shimDmaChannels = shimDmaAttr.getChannels();
        int64_t shimChannel = shimDmaChannels.empty() ? 0 : shimDmaChannels[0];
        
        // Determine DMA direction based on whether shim is sender or receiver
        StringRef dmaDirection = shimIsSender ? "MM2S" : "S2MM";
        StringRef ioOperation = shimIsSender ? "SEND" : "RECV";

        // Calculate buffer size (logical partition view)
        int64_t bufferLen = 1;
        for (int64_t dim : memrefType.getShape()) {
            bufferLen *= dim;
        }

        // Shim BD len in bytes: runtime passes len directly to
        // XAie_DmaSetAddrLen, so compute the total byte count here.
        int64_t elementSizeBytesShim = 1;
        if (memrefType.getElementType().isIntOrFloat())
            elementSizeBytesShim = memrefType.getElementTypeBitWidth() / 8;
        if (elementSizeBytesShim == 0)
            elementSizeBytesShim = 1;
        StringRef transferType = op.getType();
        int64_t shimBdLen = bufferLen * elementSizeBytesShim;
        // Read data_id from shimFlowConfig (set by DmaphopTodfscheblueprintPass).
        // Propagate it to the ConfigDmaBdOp so ScheduleCanonicalizePass can group
        // all shim BDs for the same root tensor and merge them into one.
        auto dataIdOpt = shimFlowConfig.getDataId();
        int32_t dataId = dataIdOpt.has_value() ? static_cast<int32_t>(*dataIdOpt) : -1;

        // --- Step 3: Single shim BD with NO packet mode ---
        // Circuit-switched routing does not support packet-mode filtering at
        // core S2MM (no TLAST demarcation).  Use a single non-packet shim BD
        // that sends the per-tile data portion.  With broadcast routing all
        // core tiles on the same circuit-switched path receive the same data.
        ArrayAttr coreTilesAttrForShim = coreTileGroup.getTiles();
        int64_t numCoreTiles = coreTilesAttrForShim.size();
        if (numCoreTiles <= 0)
            numCoreTiles = 1;

        // Shim BD len = partition size for BOTH one_to_many and many_to_one.
        // one_to_many: shim sends full partition, each core receives full copy.
        // many_to_one: K cores each send N/K bytes, shim receives N bytes total.
        // No separate alloc needed — partition subview is the correct size.
        int64_t perTileShimLen = shimBdLen;

        // K-round iteration: when iter_wrap > 1, BD len must be the per-iteration
        // transfer size, NOT the full partition size. The DMA repeats the BD
        // iter_wrap times via channel repeat count, advancing the base address
        // by iter_step_size between iterations.
        // Ref: xaie_dmabd_iter.c — XAie_DmaSetAddrLen uses per-iteration len.
        //
        // When tile_m < tileRows (M sub-tiling), the per-iteration transfer is
        // tile_m * effectiveK (one sub-tile), NOT shimBdLen / kRounds.
        // When tile_m == tileRows, the per-iteration transfer is
        // shimBdLen / kRounds (one K-chunk across all rows).
        {
            auto moduleOp = op->getParentOfType<ModuleOp>();
            if (moduleOp) {
                auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds");
                auto tileMAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
                auto effectiveKAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.effective_k");
                auto tileRowsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");

                if (kRoundsAttr && kRoundsAttr.getInt() > 1 && shimIsSender) {
                    int64_t tileM = tileMAttr ? tileMAttr.getInt() : 0;
                    int64_t tileRows = tileRowsAttr ? tileRowsAttr.getInt() : 0;

                    if (dataId == 0) {
                        // Input B (Col-distributed, dataId=0): use tile_n dimension
                        auto tileNAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
                        auto tileColsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");
                        int64_t tileN = tileNAttr ? tileNAttr.getInt() : 0;
                        int64_t tileCols = tileColsAttr ? tileColsAttr.getInt() : 0;
                        if (tileN > 0 && tileN < tileCols) {
                            int64_t effectiveK = effectiveKAttr ? effectiveKAttr.getInt() : 0;
                            int64_t kRounds = kRoundsAttr.getInt();
                            perTileShimLen = tileN * effectiveK * kRounds;
                        } else {
                            perTileShimLen = shimBdLen / kRoundsAttr.getInt();
                        }
                    } else if (tileM > 0 && tileM < tileRows) {
                        // Input A (Row-distributed): len covers D0×D1×D2 total
                        // = tile_m * effectiveK * kRounds
                        // (iter handles mRounds separately)
                        int64_t effectiveK = effectiveKAttr ? effectiveKAttr.getInt() : 0;
                        int64_t kRounds = kRoundsAttr.getInt();
                        perTileShimLen = tileM * effectiveK * kRounds;
                    } else {
                        // tile_m == partRows (or unset): len = shimBdLen / kRounds
                        perTileShimLen = shimBdLen / kRoundsAttr.getInt();
                    }
                }
            }
        }

        // Single shim BD: sends/receives full data from DDR
        // Allocate BD ID from ResourceMgr to avoid conflicts when a SHIM tile
        // is used by both MM2S and S2MM (e.g. input + output on same SHIM).
        // SHIM tiles share a single BD pool across all channels/directions,
        // so channel number alone is NOT a valid BD ID.
        int32_t shimBdIdVal = -1;
        if (resourceMgr) {
            auto bdOpt = resourceMgr->allocateTileBd(shimRow, shimCol, /*ownerId=*/flowIndex);
            if (bdOpt)
                shimBdIdVal = *bdOpt;
        }
        if (shimBdIdVal < 0)
            shimBdIdVal = static_cast<int32_t>(shimChannel); // fallback

        auto shimBdIdConst =
            rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(shimBdIdVal));

        // Read multi-dim addressing from FlowConfigOp (computed during
        // dmaphop→dfscheblueprint lowering for shim output assembly).
        auto shimDimStrides = shimFlowConfig.getShimDimStridesAttr();
        auto shimDimWraps = shimFlowConfig.getShimDimWrapsAttr();

        // === Output gather (many_to_one) handling ===
        // OOO path — per-tile shim BDs with packet headers preserved
        // (routing uses DONOT_DROP_HEADER), shim S2MM channel enables OOO
        // mode for non-deterministic tile arrival order.
        bool isManyToOne = (transferType == "many_to_one");
        bool useOOO = isManyToOne;

        // Collect shim BD IDs allocated for each tile (used by core MM2S BDs
        // to set out_of_order_bd_id pointing to the correct shim BD).
        SmallVector<int32_t> shimPerTileBdIds;

        Value lastShimBdHandle; // The BD handle consumed by ConfigCreateIoOp
        SmallVector<Value> shimBdHandles; // OOO per-tile BD handles (for loop erasure)

        // --- Compute per-round parameters for OOO iteration ---
        // These values are identical for all tiles in this flow.
        int64_t ooElementSizeBytes = 1;
        if (memrefType.getElementType().isIntOrFloat())
            ooElementSizeBytes = memrefType.getElementTypeBitWidth() / 8;
        if (ooElementSizeBytes == 0)
            ooElementSizeBytes = 1;

        int64_t ooFullPartitionElements = shimBdLen / ooElementSizeBytes;
        int64_t ooPerCoreElements = ooFullPartitionElements;
        if (isManyToOne)
            ooPerCoreElements = ooFullPartitionElements / numCoreTiles;

        // pp_depth controls physical ping-pong buffer count, NOT data splitting.
        // OOO shim buffer size = full per-core data, clamped only by maxPingPongBytes.
        int64_t ooPingPongSize = ooPerCoreElements;
        if (ooPingPongSize <= 0)
            ooPingPongSize = 1;
        if (maxPingPongBytes > 0 && ooElementSizeBytes > 0) {
            int64_t maxElements = maxPingPongBytes / ooElementSizeBytes;
            if (maxElements > 0 && ooPingPongSize > maxElements)
                ooPingPongSize = maxElements;
        }
        // perCoreElements must be evenly divisible by ooPingPongSize
        if (ooPerCoreElements % ooPingPongSize != 0) {
            op.emitError("OOO iteration: perCoreElements (")
                << ooPerCoreElements << ") not divisible by pingPongSize (" << ooPingPongSize << ")";
            return failure();
        }
        int64_t ooNumIterations = ooPerCoreElements / ooPingPongSize;
        int64_t perRoundBytes = ooPingPongSize * ooElementSizeBytes;

        // Shim BD iteration settings for K-round stepping.
        // Declared here (outside OOO/non-OOO branch) so they are visible
        // in the Multiple-mode scf.for loop below.
        int32_t shimIterStepSize = 0;
        int32_t shimIterWrap = 0;

        // OOO m_rounds loop variables — declared here so they are visible
        // in the schedule emission section below.
        bool usedMRounds3D = false;
        int64_t oooMRounds = 1;
        int64_t oooMSubTileStride = 0;
        int32_t oooIterStepSize = 0;
        int32_t oooIterWrap = 0;
        int64_t perTileStrideFromDims = 0;
        ArrayAttr perTileDimStrides = nullptr;
        ArrayAttr perTileDimWraps = nullptr;

        if (useOOO && numCoreTiles > 1) {
            // --- OOO path: N per-tile shim BDs ---
            // Each shim BD receives data from one core tile at the correct DDR
            // column offset. The shim S2MM channel has OOO mode enabled, so
            // incoming packets can arrive in any order — the out_of_order_bd_id
            // in each packet header tells the DMA engine which BD to use.

            // Compute per-tile DDR byte size for offset calculation
            int64_t perTileDdrBytes = shimBdLen / numCoreTiles;

            // Extract per-tile DDR offset stride from shimDimStrides.
            // The 3D shimDimStrides encode: D0=intra-tile-row, D1=DDR-row, D2=tile-column.
            // D2.stride gives the byte distance between adjacent tile columns in DDR.
            // For per-tile BDs, each BD starts at tile_index * D2.stride.
            // The BD uses 2D addressing (D0, D1) within its tile column.
            perTileStrideFromDims = perTileDdrBytes; // fallback: flat linear
            if (shimDimStrides && shimDimStrides.size() >= 3) {
                // D2 (outermost, tile-column) stride gives per-tile DDR offset
                perTileStrideFromDims = cast<IntegerAttr>(shimDimStrides[2]).getInt();
            }

            // OOO iteration parameters:
            // iter_step_size = rows_per_round * DDR_row_stride — the DDR byte
            //   distance from the start of round N to round N+1 for the same tile.
            // iter_wrap = ooNumIterations (number of ping/pong rounds per tile).
            int64_t ddrRowStride = 0;
            int64_t perTileD1Rows = 0;
            if (shimDimStrides && shimDimStrides.size() >= 2) {
                ddrRowStride = cast<IntegerAttr>(shimDimStrides[1]).getInt();
            }
            if (shimDimWraps && shimDimWraps.size() >= 2) {
                // D1 wrap = full partition rows. Tiles split along D2 (columns),
                // NOT D1 (rows) — each tile writes the same number of rows as
                // the full partition.
                perTileD1Rows = cast<IntegerAttr>(shimDimWraps[1]).getInt();
            }
            int64_t rowsPerRound = (ooNumIterations > 1) ? perTileD1Rows / ooNumIterations : perTileD1Rows;

            // When iter_wrap <= 1 (no repetition), set iter_step_size to 0
            // since the step is meaningless with a single pass.
            oooIterWrap = (int32_t)ooNumIterations;
            oooIterStepSize = (oooIterWrap > 1) ? (int32_t)(rowsPerRound * ddrRowStride) : 0;

            // Build per-tile addressing from shimDimStrides.
            // When tile_m < tileRows (M sub-tiling on output), use 3D strides
            // with D2 encoding a diagonal shift for m_rounds iteration:
            //   D0: stride=wordBytes, wrap=tileN_words (words per tile row)
            //   D1: stride=outW_words*wordBytes, wrap=tileM (rows per sub-tile)
            //   D2: stride=tileM*outW_words*wordBytes + tileN_words*wordBytes, wrap=mRounds
            // D2 advances both tile_m rows AND tile_n columns in DDR per m_round.
            // Otherwise, use 2D strides (D0, D1) with D1 wrap adjusted to rows_per_round.
            {
                int64_t tileM = passState->tileM;
                int64_t tileRowsVal = passState->tileRows;

                if (tileM > 0 && tileM < tileRowsVal && !shimIsSender) {
                    // 2D addressing + iter for OOO output with m/n sub-tiling:
                    //   D0: stride=wordBytes, wrap=tileN_sub_w (words per tile row)
                    //   D1: stride=outW_w*wordBytes, wrap=tileM (rows per sub-tile)
                    //
                    // Policy determines which dimension uses iter vs scf.for:
                    //   m_outer_n_inner (default): iter over nRounds, scf.for over mRounds
                    //   n_outer_m_inner:           iter over mRounds, scf.for over nRounds
                    int64_t mRounds = tileRowsVal / tileM;
                    unsigned bitWidth = memrefType.getElementTypeBitWidth();
                    int64_t elemsPerWord = 32 / bitWidth;
                    constexpr int64_t wordBytes = 4;
                    int64_t outW = memrefType.getDimSize(1); // full output row width (elements)
                    int64_t tileN_full = outW / numCoreTiles; // per-tile column width (elements)
                    int64_t outW_w = outW / elemsPerWord;

                    // Compute nRounds from tile_n attribute
                    int64_t tileNVal = passState->tileN;
                    int64_t tileColsVal = passState->tileCols;
                    int64_t nRounds = 1;
                    int64_t tileN_sub = tileN_full; // default: full per-tile width
                    if (tileNVal > 0 && tileNVal < tileColsVal) {
                        nRounds = tileColsVal / tileNVal;
                        tileN_sub = tileNVal; // use sub-tile width for iter stepping
                    }
                    int64_t tileN_sub_w = tileN_sub / elemsPerWord;

                    // 2D strides only (D0 + D1)
                    SmallVector<Attribute> strides2d, wraps2d;
                    // D0: contiguous word step
                    strides2d.push_back(rewriter.getI32IntegerAttr(1 * wordBytes));
                    wraps2d.push_back(rewriter.getI32IntegerAttr(tileN_sub_w));
                    // D1: DDR row stride, tile_m rows per sub-tile
                    strides2d.push_back(rewriter.getI32IntegerAttr(outW_w * wordBytes));
                    wraps2d.push_back(rewriter.getI32IntegerAttr(tileM));

                    perTileDimStrides = rewriter.getArrayAttr(strides2d);
                    perTileDimWraps = rewriter.getArrayAttr(wraps2d);
                    usedMRounds3D = true;

                    // Policy-aware iter/scf.for assignment for OOO output (C matrix)
                    auto moduleOp = op->getParentOfType<ModuleOp>();
                    bool nOuterPolicy = moduleOp ? isNOuterPolicy(moduleOp) : false;

                    if (nOuterPolicy) {
                        // n_outer_m_inner: scf.for over nRounds, iter over mRounds
                        oooIterStepSize = static_cast<int32_t>(tileM * outW_w * wordBytes); // m-row advance via iter
                        oooIterWrap = static_cast<int32_t>(mRounds);
                        oooMRounds = nRounds;                        // outer loop = nRounds
                        oooMSubTileStride = tileN_sub_w * wordBytes; // n-column advance per outer round
                    } else {
                        // m_outer_n_inner (default): scf.for over mRounds, iter over nRounds
                        oooIterStepSize = static_cast<int32_t>(tileN_sub_w * wordBytes); // n-column advance via iter
                        oooIterWrap = static_cast<int32_t>(nRounds);
                        oooMRounds = mRounds;                           // outer loop = mRounds
                        oooMSubTileStride = tileM * outW_w * wordBytes; // m-row advance per outer round
                    }

                    llvm::errs() << "[OOO ShimBD 2D+iter] tileM=" << tileM << " tileRows=" << tileRowsVal
                                 << " mRounds=" << mRounds << " nRounds=" << nRounds << " tileN_sub=" << tileN_sub
                                 << " policy=" << (nOuterPolicy ? "n_outer" : "m_outer") << " outW=" << outW << " D0=["
                                 << (1 * wordBytes) << "," << tileN_sub_w << "]"
                                 << " D1=[" << (outW_w * wordBytes) << "," << tileM << "]"
                                 << " iter_step=" << oooIterStepSize << " iter_wrap=" << oooIterWrap
                                 << " outerRounds=" << oooMRounds << " outerStride=" << oooMSubTileStride << "\n";
                } else if (shimDimStrides && shimDimWraps && shimDimStrides.size() >= 2) {
                    // 2D strides (original path)
                    SmallVector<Attribute> strides2d, wraps2d;
                    // D0: intra-tile-row addressing (unchanged)
                    strides2d.push_back(shimDimStrides[0]);
                    wraps2d.push_back(shimDimWraps[0]);
                    // D1: DDR-row addressing — use rows_per_round, NOT full partition rows
                    strides2d.push_back(shimDimStrides[1]);
                    wraps2d.push_back(rewriter.getI32IntegerAttr(rowsPerRound));
                    perTileDimStrides = rewriter.getArrayAttr(strides2d);
                    perTileDimWraps = rewriter.getArrayAttr(wraps2d);
                }
            }

            // When 2D strides + iter handle n_rounds, and scf.for handles m_rounds,
            // each BD activation writes one d0×d1 block = tileM × tileN_sub bytes.
            // BD len = tileM * tileN_sub * ooElementSizeBytes (per single OOO packet).
            // iter_step/iter_wrap are already set above for n_rounds stepping.
            if (usedMRounds3D) {
                int64_t tileM = passState->tileM;
                int64_t tileNVal_pr = passState->tileN;
                int64_t tileColsVal_pr = passState->tileCols;
                if (tileM > 0) {
                    int64_t outW = memrefType.getDimSize(1);
                    int64_t tileN_full = outW / numCoreTiles;
                    int64_t tileN_sub = tileN_full;
                    if (tileNVal_pr > 0 && tileNVal_pr < tileColsVal_pr) {
                        tileN_sub = tileNVal_pr;
                    }
                    // One d0×d1 block per BD activation (single OOO packet)
                    perRoundBytes = tileM * tileN_sub * ooElementSizeBytes;
                    llvm::errs() << "[OOO ShimBD 2D+iter] perRoundBytes=" << perRoundBytes << " tileM=" << tileM
                                 << " tileN_sub=" << tileN_sub << " oooIterStepSize=" << oooIterStepSize
                                 << " oooIterWrap=" << oooIterWrap << " oooMRounds=" << oooMRounds << "\n";
                }
            }

            // Allocate N shim BD IDs
            SmallVector<int32_t> shimBdIds;
            for (int64_t t = 0; t < numCoreTiles; t++) {
                int32_t bid = -1;
                if (resourceMgr) {
                    auto bdOpt = resourceMgr->allocateTileBd(shimRow, shimCol, /*ownerId=*/flowIndex);
                    if (bdOpt)
                        bid = *bdOpt;
                }
                if (bid < 0)
                    bid = shimBdIdVal + (int32_t)t; // fallback
                shimBdIds.push_back(bid);
            }
            shimPerTileBdIds = shimBdIds;

            // Create N shim BDs in reverse order (last first, so each can reference previous via SSA).
            // In OOO mode each BD is independently dispatched by the packet switch based on
            // packet_id matching. next_bd = -1 (disabled) — iteration handles re-execution
            // across ping-pong rounds; self-chaining would restart from the beginning.
            shimBdHandles.resize(numCoreTiles);
            for (int64_t t = numCoreTiles - 1; t >= 0; t--) {
                int32_t nextBdId = -1; // no chaining — iteration handles re-execution
                int32_t thisBdId = shimBdIds[t];
                // Per-tile DDR offset: use D2 stride from shimDimStrides for correct
                // GEMM output tile column placement in DDR.
                int64_t ddrOffset = t * perTileStrideFromDims;

                // linked_bd chain for SSA: BD[i] links to BD[i+1] (or none for last)
                Value linkedBd = (t < numCoreTiles - 1) ? shimBdHandles[t + 1] : Value();

                auto shimBdIdC = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                    rewriter.getI32IntegerAttr(thisBdId));

                // Per-tile shim BD: enable_packet=false for OOO S2MM receiving.
                // OOO dispatch uses ooo_bd_id from the packet header to select BDs;
                // the S2MM BD itself must NOT have PktEn set, otherwise the DMA
                // engine would try to strip a second header from the data payload,
                // causing data corruption and stalls.  (Reference:
                // xaie_conv2d_2core_dataflow_test.c — shim S2MM BD has no XAie_DmaSetPkt.)
                auto ddrOffsetConst = rewriter.create<arith::ConstantOp>(
                    loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(static_cast<int32_t>(ddrOffset)));
                auto shimBd = rewriter.create<dfschedule::ConfigDmaBdOp>(
                    loc, dfschedule::BdHandleType::get(rewriter.getContext()),
                    ddrBuffer,                                 // DDR buffer
                    shimTileOp.getTile(),                      // tile
                    shimBdIdC.getResult(),                     // bd_id
                    ddrOffsetConst.getResult(),                // offset (per-tile DDR position using D2 stride)
                    rewriter.getI32IntegerAttr(perRoundBytes), // len (per-round, matches src BD)
                    rewriter.getBoolAttr(false),               // enable_packet = false (OOO dispatch handles packets)
                    rewriter.getI32IntegerAttr(
                        basePacketId + (int32_t)t), // packet_id (kept for debug/comments, ignored when PktEn=false)
                    rewriter.getI32IntegerAttr(nextBdId), // next_bd = -1 (disabled — iteration handles rounds)
                    rewriter.getI32IntegerAttr(-1), // acquire_lock_id = -1 → no lock (OOO flow control via packets)
                    rewriter.getI32IntegerAttr(0),  // acquire_lock_val (ignored)
                    rewriter.getI32IntegerAttr(-1), // release_lock_id = -1 → no lock
                    rewriter.getI32IntegerAttr(0),  // release_lock_val (ignored)
                    rewriter.getI32IntegerAttr(dataId), // data_id
                    linkedBd,                           // linked_bd
                    rewriter.getI32IntegerAttr(-1),     // out_of_order_bd_id (N/A for shim)
                    /*dim_strides=*/perTileDimStrides, /*dim_wraps=*/perTileDimWraps,
                    rewriter.getI32IntegerAttr(oooIterStepSize), // iter_step_size
                    rewriter.getI32IntegerAttr(oooIterWrap));    // iter_wrap

                shimBdHandles[t] = shimBd.getBdHandle();

                llvm::errs() << "[OOO ShimBD] tile " << t << " bd_id=" << thisBdId << " pkt_id=" << (basePacketId + t)
                             << " ddr_offset=" << ddrOffset << " len=" << perRoundBytes << " next_bd=" << nextBdId
                             << " iter_step=" << oooIterStepSize << " iter_wrap=" << oooIterWrap
                             << " d1_wrap=" << rowsPerRound << "\n";
            }
            // Last BD in SSA chain (BD[0]) is consumed by create_io
            lastShimBdHandle = shimBdHandles[0];
        } else {
            // --- Non-OOO path: single shim BD (original behavior) ---
            // K-round iteration: when effectiveK < fullK, use iter_step_size and
            // iter_wrap so the BD repeats, advancing the DDR read address.
            //
            // When tile_m == tileRows (no M sub-tiling):
            //   iter_step = effectiveK bytes (next K-chunk column)
            //   iter_wrap = kRounds
            //
            // When tile_m < tileRows (M sub-tiling):
            //   D2 handles kRounds (K-chunk stepping), so iter handles mRounds:
            //   iter_step = tile_m * fullK bytes (next m-sub-tile block in DDR)
            //   iter_wrap = mRounds (= tileRows / tileM)
            if (shimIsSender) {
                auto moduleOp = op->getParentOfType<ModuleOp>();
                if (moduleOp) {
                    auto effectiveKAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.effective_k");
                    auto fullKAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.full_k");
                    auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds");
                    if (effectiveKAttr && fullKAttr && kRoundsAttr) {
                        int64_t effectiveK = effectiveKAttr.getInt();
                        int64_t fullK = fullKAttr.getInt();
                        int64_t kRounds = kRoundsAttr.getInt();
                        if (effectiveK > 0 && effectiveK < fullK && kRounds > 1) {
                            // Compute element size from the memref type
                            int64_t elemBytes = 1;
                            if (memrefType.getElementType().isIntOrFloat())
                                elemBytes = memrefType.getElementTypeBitWidth() / 8;
                            if (elemBytes == 0)
                                elemBytes = 1;

                            bool nOuterPolicy = isNOuterPolicy(moduleOp);

                            if (dataId == 0) {
                                // Input B (Col-distributed, dataId=0)
                                auto tileNAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
                                auto tileColsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");
                                int64_t tileN = tileNAttr ? tileNAttr.getInt() : 0;
                                int64_t tileCols = tileColsAttr ? tileColsAttr.getInt() : 0;

                                if (tileN > 0 && tileN < tileCols) {
                                    if (nOuterPolicy) {
                                        // n_outer: B repeats same data; scf.for handles n-sub-tile advancement
                                        int64_t mRoundsIter = 1;
                                        auto tileMAttrB = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
                                        auto tileRowsAttrB = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");
                                        if (tileMAttrB && tileRowsAttrB) {
                                            int64_t tM = tileMAttrB.getInt();
                                            int64_t tR = tileRowsAttrB.getInt();
                                            if (tM > 0 && tM < tR)
                                                mRoundsIter = tR / tM;
                                        }
                                        shimIterStepSize = 0;
                                        shimIterWrap = 0; // step=0 → disable iteration entirely
                                        llvm::errs() << "[BlueprintToSchedule] Input B iter (n_outer, mRounds repeat): "
                                                     << "iter_step_size=" << shimIterStepSize
                                                     << " iter_wrap=" << shimIterWrap << " tileN=" << tileN
                                                     << " tileCols=" << tileCols << " mRounds=" << mRoundsIter << "\n";
                                    } else {
                                        // m_outer (default): B advances through n-sub-tiles via iter
                                        int64_t nRounds = tileCols / tileN;
                                        shimIterStepSize = static_cast<int32_t>(tileN * fullK * elemBytes);
                                        shimIterWrap = static_cast<int32_t>(nRounds);
                                        llvm::errs() << "[BlueprintToSchedule] Input B iter (m_outer, nRounds): "
                                                     << "iter_step_size=" << shimIterStepSize
                                                     << " iter_wrap=" << shimIterWrap << " tileN=" << tileN
                                                     << " tileCols=" << tileCols << " nRounds=" << nRounds << "\n";
                                    }
                                } else {
                                    // No N sub-tiling: fall through to kRounds
                                    shimIterStepSize = static_cast<int32_t>(effectiveK * elemBytes);
                                    shimIterWrap = static_cast<int32_t>(kRounds);
                                    llvm::errs() << "[BlueprintToSchedule] Input B iter (no N sub-tiling, kRounds): "
                                                 << "iter_step_size=" << shimIterStepSize
                                                 << " iter_wrap=" << shimIterWrap << "\n";
                                }
                            } else {
                                // Input A (Row-distributed)
                                int64_t tileM = 0, tileRows = 0;
                                if (auto a = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m"))
                                    tileM = a.getInt();
                                if (auto a = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows"))
                                    tileRows = a.getInt();

                                if (tileM > 0 && tileM < tileRows) {
                                    if (nOuterPolicy) {
                                        // n_outer: A advances through m-sub-tiles via iter
                                        int64_t mRoundsA = tileRows / tileM;
                                        shimIterStepSize = static_cast<int32_t>(tileM * fullK * elemBytes);
                                        shimIterWrap = static_cast<int32_t>(mRoundsA);
                                        llvm::errs()
                                            << "[BlueprintToSchedule] Input A iter (n_outer, mRounds advance): "
                                            << "iter_step_size=" << shimIterStepSize << " iter_wrap=" << shimIterWrap
                                            << " tileM=" << tileM << " tileRows=" << tileRows << " mRounds=" << mRoundsA
                                            << "\n";
                                    } else {
                                        // m_outer (default): A repeats same data; scf.for handles m advancement
                                        int64_t nRounds2 = 1;
                                        auto tileNAttr2 = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
                                        auto tileColsAttr2 = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");
                                        if (tileNAttr2 && tileColsAttr2) {
                                            int64_t tN = tileNAttr2.getInt();
                                            int64_t tC = tileColsAttr2.getInt();
                                            if (tN > 0 && tN < tC)
                                                nRounds2 = tC / tN;
                                        }
                                        shimIterStepSize = 0; // no advance — repeat same A data
                                        shimIterWrap = 0;     // step=0 → disable iteration entirely
                                        llvm::errs() << "[BlueprintToSchedule] Input A iter (m_outer, nRounds repeat): "
                                                     << "iter_step_size=" << shimIterStepSize
                                                     << " iter_wrap=" << shimIterWrap << " tileM=" << tileM
                                                     << " tileRows=" << tileRows << " nRounds=" << nRounds2 << "\n";
                                    }
                                } else {
                                    // D1 covers all rows; iter handles kRounds
                                    shimIterStepSize = static_cast<int32_t>(effectiveK * elemBytes);
                                    shimIterWrap = static_cast<int32_t>(kRounds);
                                    llvm::errs() << "[BlueprintToSchedule] Input A iter (2D, kRounds): "
                                                 << "iter_step_size=" << shimIterStepSize
                                                 << " iter_wrap=" << shimIterWrap << "\n";
                                }
                            }
                        }
                    }
                }
            }

            auto shimOffsetConst =
                rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(0));
            auto shimBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
                loc, dfschedule::BdHandleType::get(rewriter.getContext()),
                ddrBuffer,                                  // DDR receive buffer
                shimTileOp.getTile(),                       // tile
                shimBdIdConst.getResult(),                  // bd_id
                shimOffsetConst.getResult(),                // offset
                rewriter.getI32IntegerAttr(perTileShimLen), // len (per-tile portion)
                rewriter.getBoolAttr(false),                // enable_packet = false
                rewriter.getI32IntegerAttr(0),              // packet_id (unused)
                rewriter.getI32IntegerAttr(4294967295),     // next_bd = none
                rewriter.getI32IntegerAttr(0),              // acquire_lock_id
                rewriter.getI32IntegerAttr(0),              // acquire_lock_val
                rewriter.getI32IntegerAttr(0),              // release_lock_id
                rewriter.getI32IntegerAttr(0),              // release_lock_val
                rewriter.getI32IntegerAttr(dataId),         // data_id
                Value(),                                    // linked_bd = none
                rewriter.getI32IntegerAttr(-1),             // out_of_order_bd_id
                /*dim_strides=*/shimDimStrides, /*dim_wraps=*/shimDimWraps,
                rewriter.getI32IntegerAttr(shimIterStepSize), // iter_step_size (K-round advance)
                rewriter.getI32IntegerAttr(shimIterWrap));    // iter_wrap (kRounds repetitions)

            lastShimBdHandle = shimBdOp.getBdHandle();
            // For single-BD path with OOO (single tile many_to_one), still record
            if (isManyToOne) {
                shimPerTileBdIds.push_back(shimBdIdVal);
            }
        }

        auto createIoOp = rewriter.create<dfschedule::ConfigCreateIoOp>(
            loc, dfschedule::IoHandleType::get(rewriter.getContext()),
            lastShimBdHandle,                        // BD handle (first BD in chain or single)
            shimTileOp.getTile(),                    // tile
            rewriter.getI32IntegerAttr(shimChannel), // channel
            rewriter.getStringAttr(dmaDirection),    // direction (MM2S or S2MM)
            rewriter.getStringAttr(ioOperation),     // io_operation (SEND or RECV)
            rewriter.getBoolAttr(useOOO));           // enable_out_of_order

        // --- CORE TILES: declaretile, kernel_config, and ping-pong DMA config ---
        ArrayAttr coreTilesAttr = coreTileGroup.getTiles();
        SmallVector<Value> coreTiles;

        // Get DMA channel and direction from core FlowConfig
        auto coreDmaAttr = coreFlowConfig.getDma();
        auto coreDmaChannels = coreDmaAttr.getChannels();
        int64_t coreChannel = coreDmaChannels.empty() ? 0 : coreDmaChannels[0];
        auto coreDmaDir = coreDmaAttr.getDirection();
        StringRef coreDmaDirection = (coreDmaDir == dfscheblueprint::bp_direction::MM2S) ? "MM2S" : "S2MM";
        StringRef coreIoOperation = (coreDmaDir == dfscheblueprint::bp_direction::MM2S) ? "SEND" : "RECV";

        // Get per-tile data slices from core FlowConfig's slice_symbols
        auto sliceSymbolsOpt = coreFlowConfig.getSliceSymbols();

        // Pre-allocate buffer addresses once for this flow (shared kernel binary)
        // All tiles use the same buffer placement.
        int64_t flowPingL1Offset = 0;
        int64_t flowPongL1Offset = 0;
        bool flowAddrsValid = false;

        // Compute dirIdx (funcArgIndex-based) before the tile loop so it's
        // available for both lock allocation and buffer naming.
        // This ensures the host lock IDs match the kernel's window ordering.
        bool isInput = shimIsSender;
        int funcArgIdx = traceFlowConfigToFuncArgIndex(shimFlowConfig);
        int dirIdx;
        if (isInput) {
            auto it = dataIdToInputIdx.find(dataId);
            if (it != dataIdToInputIdx.end()) {
                dirIdx = it->second;
            } else {
                dirIdx = (funcArgIdx >= 0) ? funcArgIdx : nextInputIdx;
                dataIdToInputIdx[dataId] = dirIdx;
                nextInputIdx = std::max(nextInputIdx, dirIdx + 1);
            }
        } else {
            auto it = dataIdToOutputIdx.find(dataId);
            if (it != dataIdToOutputIdx.end()) {
                dirIdx = it->second;
            } else {
                dirIdx = nextOutputIdx++;
                dataIdToOutputIdx[dataId] = dirIdx;
            }
        }

        // Collect tile config dictionaries for kernel_config
        SmallVector<Attribute> tileConfigDicts;
        // Deferred core StartIoOp data: collect IO handles and BD IDs inside the
        // per-tile loop, then emit StartIoOp AFTER LoadKernelGroup/LaunchKernelGroup
        // so that ELF BSS initialization does not overwrite DMA data.
        struct DeferredCoreStartIo {
            Value ioHandle;
            Value bdId;
            uint32_t flowIdx;
            int32_t repeatCount;
        };
        SmallVector<DeferredCoreStartIo> deferredCoreStartIos;
        int tileIndex = 0;
        
        for (auto tileAttr : coreTilesAttr) {
            auto tileArray = dyn_cast<ArrayAttr>(tileAttr);
            if (!tileArray || tileArray.size() < 2) {
                continue;
            }
            
            int64_t col = cast<IntegerAttr>(tileArray[0]).getInt();
            int64_t row = cast<IntegerAttr>(tileArray[1]).getInt();
            
            // Create dfschedule.declaretile for each core tile
            auto coreTileOp = rewriter.create<dfschedule::DeclareTileOp>(
                loc,
                dfschedule::TileType::get(rewriter.getContext()),
                rewriter.getI32IntegerAttr(col),
                rewriter.getI32IntegerAttr(row));
            coreTiles.push_back(coreTileOp.getTile());

            // Calculate buffer size from the DDR memref type
            int64_t bufferSize = bufferLen;
            int64_t elementSizeBytes = 1;
            if (memrefType.getElementType().isIntOrFloat())
                elementSizeBytes = memrefType.getElementTypeBitWidth() / 8;
            if (elementSizeBytes == 0)
                elementSizeBytes = 1;
            bufferSize *= elementSizeBytes;

            // With circuit-switched broadcast every core tile receives the FULL
            // partition data from the shim stream.  The kernel selects its own
            // portion via buffer_offset.  DMA iterations must cover the full
            // partition so the stream is fully consumed.
            int64_t perTileSize = bufferSize / coreTilesAttr.size();
            int64_t bufferOffset = tileIndex * perTileSize;

            // Per-core data depends on transfer type:
            // many_to_one (gather/output): each core produces partition / numCoreTiles.
            // one_to_many (broadcast/input): each core receives the full partition.
            int64_t fullPartitionElements = bufferSize / elementSizeBytes;
            int64_t perCoreElements = fullPartitionElements;
            if (transferType == "many_to_one")
                perCoreElements = fullPartitionElements / numCoreTiles;
            // K-round adjustment: for input flows with kRounds > 1, the kernel
            // operates on per-k-round data (tile_rows * effectiveK), not the
            // full partition (tile_rows * fullK). We must divide perCoreElements
            // by kRounds so that pingPongBufferSize matches the kernel's
            // buf_sz_a/b (= rowsPerRound * effectiveK). The numIterations
            // multiplication by kRounds (below) then correctly recovers the
            // total number of DMA rounds across all k-rounds.
            int64_t perCorePerKRound = perCoreElements;
            if (isInput) {
                auto moduleOp = op->getParentOfType<ModuleOp>();
                if (moduleOp) {
                    if (auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds")) {
                        int64_t kRounds = kRoundsAttr.getInt();
                        if (kRounds > 1) {
                            perCorePerKRound = perCoreElements / kRounds;
                            // When tile_m < tileRows, each k-round only needs
                            // tile_m rows (not partRows). Divide by mRounds
                            // so pingPongBufferSize = tile_m * effectiveK.
                            auto tileMAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
                            auto tileRowsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");
                            int64_t tileM = tileMAttr ? tileMAttr.getInt() : 0;
                            int64_t tileRows = tileRowsAttr ? tileRowsAttr.getInt() : 0;
                            if (tileM > 0 && tileM < tileRows) {
                                int64_t mRounds = tileRows / tileM;
                                perCorePerKRound = perCorePerKRound / mRounds;
                            }
                        }
                    }
                }
            } else {
                // Output: the kernel produces one sub-tile (tile_m × tile_n_sub)
                // per release_output_window call. Divide perCoreElements by
                // mRounds * nRounds so BD len matches one kernel output window.
                auto moduleOp = op->getParentOfType<ModuleOp>();
                if (moduleOp) {
                    auto tileMAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
                    auto tileRowsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");
                    auto tileNAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
                    auto tileColsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");
                    int64_t tileM = tileMAttr ? tileMAttr.getInt() : 0;
                    int64_t tileRows = tileRowsAttr ? tileRowsAttr.getInt() : 0;
                    int64_t tileN = tileNAttr ? tileNAttr.getInt() : 0;
                    int64_t tileCols = tileColsAttr ? tileColsAttr.getInt() : 0;
                    int64_t mRounds = (tileM > 0 && tileM < tileRows) ? (tileRows / tileM) : 1;
                    int64_t nRounds = (tileN > 0 && tileN < tileCols) ? (tileCols / tileN) : 1;
                    if (mRounds * nRounds > 1) {
                        perCorePerKRound = perCoreElements / (mRounds * nRounds);
                    }
                }
            }

            // Read pp_depth from FlowConfigOp attribute (set by dmaphop→blueprint pass).
            // pp_depth controls physical ping-pong buffer count (for DMA/compute
            // overlap), NOT data splitting.  Buffer size = full per-k-round data,
            // clamped only by maxPingPongBytes when the data exceeds tile memory.
            int ppDepth = static_cast<int>(1.0 / bufferRatio + 0.5); // e.g. bufferRatio=0.5 → ppDepth=2
            if (coreFlowConfig.getPpDepth())
                ppDepth = static_cast<int>(*coreFlowConfig.getPpDepth());
            if (ppDepth <= 0)
                ppDepth = 2;

            int64_t pingPongBufferSize = perCorePerKRound;
            if (pingPongBufferSize <= 0)
                pingPongBufferSize = 1;
            // Clamp to maxPingPongBytes to prevent exceeding core tile memory
            if (maxPingPongBytes > 0 && elementSizeBytes > 0) {
                int64_t maxElements = maxPingPongBytes / elementSizeBytes;
                if (maxElements > 0 && pingPongBufferSize > maxElements)
                    pingPongBufferSize = maxElements;
            }
            // numIterations: use perCorePerKRound (per-k-round data) so that
            // base iterations count one k-round. The kRounds multiplier below
            // then scales to the total across all k-rounds.
            int64_t numIterations = (perCorePerKRound + pingPongBufferSize - 1) / pingPongBufferSize;

            // Validate: pp_depth=1 requires numIterations==1.
            // With single-buffer mode (no BD chaining, no next_bd cycling),
            // the DMA fires exactly once. If the kernel needs multiple
            // rounds (numIterations > 1), the DMA cannot re-arm and the
            // kernel will deadlock on the second acquire_window call.
            if (ppDepth == 1 && numIterations > 1) {
                op.emitError("pp_depth=1 (single buffer) incompatible with "
                             "numIterations=")
                    << numIterations << " (buffer_size=" << pingPongBufferSize
                    << " < perCorePerKRound=" << perCorePerKRound
                    << "). Single-buffer DMA cannot re-arm for multiple rounds. "
                       "Set pp_depth>=2 to enable ping-pong BD chaining, or "
                       "increase max_buffer_bytes to fit the full per-k-round data.";
                return failure();
            }

            // K-round multiplication: when effectiveK < K, the kernel runs
            // kRounds iterations, each consuming numIterations DMA rounds.
            // The host must send numIterations * kRounds total BD iterations
            // for input flows to match the kernel's acquire/release pattern.
            if (isInput) {
                auto moduleOp = op->getParentOfType<ModuleOp>();
                if (moduleOp) {
                    if (auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds")) {
                        int64_t kRounds = kRoundsAttr.getInt();
                        if (kRounds > 1) {
                            llvm::errs() << "[BlueprintToSchedule] K-round: input numIterations " << numIterations
                                         << " * kRounds " << kRounds << " = " << numIterations * kRounds << "\n";
                            numIterations *= kRounds;
                        }
                    }
                }
            }

            // Compute lock IDs from dirIdx to match the kernel's window ordering.
            // The kernel allocates locks sequentially per sorted window:
            //   input0 → lock 0/1, input1 → lock 2/3, output0 → lock 4/5, ...
            // (kernel adds LOCK_BASE=48 offset internally).
            // For outputs, offset by numInputs * 2 (we use nextInputIdx as
            // an estimate of numInputs since inputs are processed first).
            int acquireLockId, releaseLockId;
            if (isInput) {
                acquireLockId = dirIdx * 2;
                releaseLockId = dirIdx * 2 + 1;
            } else {
                // Output locks start after all input locks.
                // nextInputIdx tracks the highest input dirIdx+1 seen so far.
                int outputLockBase = nextInputIdx * 2;
                acquireLockId = outputLockBase + dirIdx * 2;
                releaseLockId = outputLockBase + dirIdx * 2 + 1;
            }

            // Build config dictionary for this tile
            // buffer_mode: 0 = single buffer (pp_depth=1), 1 = ping-pong (pp_depth>=2)
            int bufferMode = (ppDepth == 1) ? 0 : 1;
            int numBuffers = (ppDepth == 1) ? 1 : 2;

            NamedAttrList configAttrs;
            configAttrs.append("tile_index", rewriter.getI32IntegerAttr(tileIndex));
            configAttrs.append("flow_index", rewriter.getI32IntegerAttr(flowIndex));
            configAttrs.append("packet_id", rewriter.getI32IntegerAttr(basePacketId + tileIndex));
            configAttrs.append("dma_channel", rewriter.getI32IntegerAttr(coreChannel));
            configAttrs.append("buffer_mode", rewriter.getI32IntegerAttr(bufferMode));
            configAttrs.append("num_buffers", rewriter.getI32IntegerAttr(numBuffers));
            configAttrs.append("buffer_size", rewriter.getI32IntegerAttr(pingPongBufferSize));
            configAttrs.append("num_iterations", rewriter.getI32IntegerAttr(numIterations));
            configAttrs.append("buffer_offset", rewriter.getI32IntegerAttr(bufferOffset));
            configAttrs.append("element_size", rewriter.getI32IntegerAttr(elementSizeBytes));
            configAttrs.append("acquire_lock_id", rewriter.getI32IntegerAttr(acquireLockId));
            configAttrs.append("release_lock_id", rewriter.getI32IntegerAttr(releaseLockId));

            tileConfigDicts.push_back(rewriter.getDictionaryAttr(configAttrs));

            // --- Core tile ping-pong DMA BD configuration ---
            // Look up per-tile data slice from slice_symbols (maps 1:1 to tiles)
            if (sliceSymbolsOpt && tileIndex < (int)sliceSymbolsOpt->size()) {
                auto sliceSymRef = cast<SymbolRefAttr>((*sliceSymbolsOpt)[tileIndex]);
                auto dataSliceOp = lookupDataSlice(op.getOperation(), sliceSymRef);
                if (dataSliceOp) {
                    Value perTileTensor = dataSliceOp.getTensorSlice();
                    Type perTileType = perTileTensor.getType();

                    // Trace back to tensor.extract_slice to get per-tile offsets/sizes
                    auto tileExtractSlice = perTileTensor.getDefiningOp<tensor::ExtractSliceOp>();

                    int64_t perTileTotalSize = perTileSize / elementSizeBytes;
                    MemRefType shapedPerTileType;

                    if (flowRootMemref && tileExtractSlice) {
                        // Get slice info from tileExtractSlice
                        auto sliceOffsets = tileExtractSlice.getStaticOffsets();
                        auto sliceSizes = tileExtractSlice.getStaticSizes();
                        auto sliceStrides = tileExtractSlice.getStaticStrides();

                        Value partSubview;
                        SmallVector<int64_t> perTileSizes;
                        SmallVector<int64_t> perTileOffsets;
                        SmallVector<int64_t> perTileStrides(sliceSizes.size(), 1);

                        if (partExtractSlice) {
                            // Original path: tileExtractSlice gives per-tile offsets relative
                            // to partition subview (output flow has distinct extract_slices per tile)
                            perTileSizes.assign(sliceSizes.begin(), sliceSizes.end());
                            perTileOffsets.assign(sliceOffsets.begin(), sliceOffsets.end());
                            partSubview = partitionSubview;
                        } else {
                            // Path 2: tileExtractSlice gives partition-level offsets from root.
                            // Create partition subview first, then compute per-tile split.
                            auto partSubviewOp = rewriter.create<memref::SubViewOp>(
                                loc, flowRootMemref, toOpFoldResult(sliceOffsets, rewriter),
                                toOpFoldResult(sliceSizes, rewriter), toOpFoldResult(sliceStrides, rewriter));
                            partSubview = partSubviewOp.getResult();

                            // Split first dimension evenly among core tiles
                            int64_t numCoreTiles = coreTilesAttr.size();
                            perTileSizes.assign(sliceSizes.begin(), sliceSizes.end());
                            perTileSizes[0] = sliceSizes[0] / numCoreTiles;
                            perTileOffsets.assign(sliceSizes.size(), 0);
                            perTileOffsets[0] = tileIndex * perTileSizes[0];
                        }

                        // Create per-tile subview
                        auto tileSubviewOp = rewriter.create<memref::SubViewOp>(
                            loc, partSubview, toOpFoldResult(perTileOffsets, rewriter),
                            toOpFoldResult(perTileSizes, rewriter), toOpFoldResult(perTileStrides, rewriter));

                        // memref_mapping: strip strides, produce clean shaped type
                        shapedPerTileType = MemRefType::get(perTileSizes, passState->elementType);
                        perTileTotalSize = 1;
                        for (int64_t d : perTileSizes)
                            perTileTotalSize *= d;

                        auto coreMappingOp = rewriter.create<dfschedule::MemRefMappingOp>(loc, shapedPerTileType,
                                                                                          tileSubviewOp.getResult());
                        Value perTileToken = coreMappingOp.getMapped();

                        // bind_core_buffer with shaped memref type
                        // Use pre-allocated buffer addresses from CoreMemAllocator
                        // (allocated once for first tile, reused for all tiles in this flow)
                        int64_t pingL1Offset = 0;
                        // Pong offset must be int32-aligned for DMA transfers
                        int64_t pingBufBytes = pingPongBufferSize * elementSizeBytes;
                        int64_t pongL1Offset = (pingBufBytes + 3) & ~3;
                        if (!flowAddrsValid) {
                            // First tile: allocate addresses for this flow.
                            // dirIdx, isInput, and funcArgIdx are computed before
                            // the tile loop to ensure consistent ordering.
                            llvm::errs() << "[HostParamMapping] data_id=" << dataId << " funcArgIdx=" << funcArgIdx
                                         << " isInput=" << isInput << " dirIdx=" << dirIdx << "\n";
                            std::string pingName, pongName;
                            if (isInput) {
                                pingName = "buf_in_ping_" + std::to_string(dirIdx);
                                pongName = "buf_in_pong_" + std::to_string(dirIdx);
                            } else {
                                pingName = "buf_out_ping_" + std::to_string(dirIdx);
                                pongName = "buf_out_pong_" + std::to_string(dirIdx);
                            }
                            // Ensure buffer size is int32-aligned for DMA.
                            // Use perCorePerKRound (per-k-round data for one core) as the
                            // allocation size.  The kernel uses a single global BUF_SZ for
                            // ALL windows, determined by the largest flow (input one_to_many).
                            // Output buffers (many_to_one) need the same allocation size
                            // even though they transfer fewer elements per core.
                            int64_t kernelBufElements = perCorePerKRound;
                            // Clamp kernelBufElements to maxPingPongBytes (same as pingPongBufferSize clamping)
                            if (maxPingPongBytes > 0 && elementSizeBytes > 0) {
                                int64_t maxElements = maxPingPongBytes / elementSizeBytes;
                                if (maxElements > 0 && kernelBufElements > maxElements)
                                    kernelBufElements = maxElements;
                            }
                            if (kernelBufElements < pingPongBufferSize)
                                kernelBufElements = pingPongBufferSize;
                            uint32_t bufSizeBytes = ((kernelBufElements * elementSizeBytes) + 3) & ~3;
                            try {
                                auto &allocator = ResourceMgr::instance()->coreMemAllocator();
                                auto pingAddr = allocator.allocate(pingName, bufSizeBytes, /*alignment=*/32);
                                if (ppDepth == 1) {
                                    // Single buffer mode: only allocate ping buffer, no pong
                                    if (pingAddr) {
                                        flowPingL1Offset = static_cast<int64_t>(*pingAddr) - 0x70000;
                                        flowPongL1Offset = flowPingL1Offset; // unused but set for safety
                                        flowAddrsValid = true;
                                    }
                                } else {
                                    auto pongAddr = allocator.allocate(pongName, bufSizeBytes, /*alignment=*/32);
                                    if (pingAddr && pongAddr) {
                                        // Convert core processor view (0x78000+) to DMA view (0x08000+)
                                        // Core DMA engine sees memory starting at 0x00000, not 0x70000
                                        flowPingL1Offset = static_cast<int64_t>(*pingAddr) - 0x70000;
                                        flowPongL1Offset = static_cast<int64_t>(*pongAddr) - 0x70000;
                                        flowAddrsValid = true;
                                    }
                                }
                            } catch (...) {
                                // ResourceMgr singleton not initialized; fall back to relative offsets
                            }
                        }
                        if (flowAddrsValid) {
                            pingL1Offset = flowPingL1Offset;
                            pongL1Offset = flowPongL1Offset;
                        }
                        // Core BD len in bytes: runtime passes len directly to
                        // XAie_DmaSetAddrLen, so compute the total byte count here.
                        int64_t coreBdLen = pingPongBufferSize * elementSizeBytes;
                        if (coreBdLen <= 0)
                            coreBdLen = 1;

                        // For output (MM2S on core), swap lock IDs in BD config:
                        // Input (S2MM):  DMA acquires lock 0 (buffer free), releases lock 1 (data ready)
                        // Output (MM2S): DMA acquires lock 1 (data produced by kernel), releases lock 0 (buffer free)
                        bool isOutputFlow = (coreDmaDir == dfscheblueprint::bp_direction::MM2S);
                        int bdAcquireLockId = isOutputFlow ? releaseLockId : acquireLockId;
                        int bdReleaseLockId = isOutputFlow ? acquireLockId : releaseLockId;

                        // Output (MM2S) uses packet-switched routing: core DMA must emit
                        // packet headers so the packet switch can route data to the shim.
                        // Input (S2MM) uses circuit-switched routing: no packet headers needed.
                        bool coreBdEnablePacket = isOutputFlow;
                        int32_t coreBdPacketId = isOutputFlow ? (int32_t)(basePacketId + tileIndex) : 0;

                        // Compute out_of_order_bd_id for output (MM2S) core BDs.
                        // This tells the shim S2MM DMA which BD to use for this tile's data.
                        int32_t coreOooBdId = -1;
                        if (isOutputFlow && !shimPerTileBdIds.empty()) {
                            size_t idx = static_cast<size_t>(tileIndex);
                            if (idx < shimPerTileBdIds.size())
                                coreOooBdId = shimPerTileBdIds[idx];
                        }

                        Value firstCoreBdHandle; // The BD handle consumed by ConfigCreateIoOp

                        if (ppDepth == 1) {
                            // === Single buffer mode (pp_depth=1) ===
                            // One buffer, one BD, no next_bd chaining, no pong.
                            auto singleL1 = rewriter.create<dfschedule::BindCoreBufferOp>(
                                loc, shapedPerTileType, perTileToken, coreTileOp.getTile(),
                                rewriter.getI64IntegerAttr(pingL1Offset));

                            int32_t singleBdId = -1;
                            if (resourceMgr) {
                                auto bd0 = resourceMgr->allocateTileBd(row, col, /*ownerId=*/flowIndex);
                                if (bd0)
                                    singleBdId = *bd0;
                            }
                            if (singleBdId < 0)
                                singleBdId = 0;

                            auto singleBdIdConst = rewriter.create<arith::ConstantOp>(
                                loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(singleBdId));
                            auto singleOffsetConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                                        rewriter.getI32IntegerAttr(0));
                            auto singleBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
                                loc, dfschedule::BdHandleType::get(rewriter.getContext()), singleL1.getBuffer(),
                                coreTileOp.getTile(), singleBdIdConst.getResult(),
                                singleOffsetConst.getResult(),               // offset
                                rewriter.getI32IntegerAttr(coreBdLen),       // len (bytes)
                                rewriter.getBoolAttr(coreBdEnablePacket),    // enable_packet
                                rewriter.getI32IntegerAttr(coreBdPacketId),  // packet_id
                                rewriter.getI32IntegerAttr(-1),              // next_bd = -1 (no chaining)
                                rewriter.getI32IntegerAttr(bdAcquireLockId), // acquire_lock_id
                                rewriter.getI32IntegerAttr(-1),              // acquire_lock_val
                                rewriter.getI32IntegerAttr(bdReleaseLockId), // release_lock_id
                                rewriter.getI32IntegerAttr(1),               // release_lock_val
                                rewriter.getI32IntegerAttr(-1),              // data_id
                                Value(),                                     // linked_bd = none
                                rewriter.getI32IntegerAttr(coreOooBdId),     // out_of_order_bd_id
                                /*dim_strides=*/nullptr, /*dim_wraps=*/nullptr,
                                rewriter.getI32IntegerAttr(0),  // iter_step_size (no iteration)
                                rewriter.getI32IntegerAttr(0)); // iter_wrap (no iteration)

                            firstCoreBdHandle = singleBdOp.getBdHandle();
                        } else {
                            // === Ping-pong mode (pp_depth>=2, existing behavior) ===
                            auto pingL1 = rewriter.create<dfschedule::BindCoreBufferOp>(
                                loc, shapedPerTileType, perTileToken, coreTileOp.getTile(),
                                rewriter.getI64IntegerAttr(pingL1Offset));
                            auto pongL1 = rewriter.create<dfschedule::BindCoreBufferOp>(
                                loc, shapedPerTileType, perTileToken, coreTileOp.getTile(),
                                rewriter.getI64IntegerAttr(pongL1Offset));

                            // Allocate BD IDs from ResourceMgr per-tile pool
                            int32_t pingBdId = -1, pongBdId = -1;
                            if (resourceMgr) {
                                auto bd0 = resourceMgr->allocateTileBd(row, col, /*ownerId=*/flowIndex);
                                auto bd1 = resourceMgr->allocateTileBd(row, col, /*ownerId=*/flowIndex);
                                if (bd0 && bd1) {
                                    pingBdId = *bd0;
                                    pongBdId = *bd1;
                                }
                            }
                            if (pingBdId < 0 || pongBdId < 0) {
                                llvm::errs() << "WARNING: BD allocation failed for tile (" << col << "," << row
                                             << "), falling back to 0/1\n";
                                pingBdId = 0;
                                pongBdId = 1;
                            }

                            // Pong BD first (no linked_bd): next_bd -> ping
                            auto pongBdIdConst = rewriter.create<arith::ConstantOp>(
                                loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(pongBdId));
                            auto pongOffsetConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                                      rewriter.getI32IntegerAttr(0));
                            auto pongBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
                                loc, dfschedule::BdHandleType::get(rewriter.getContext()), pongL1.getBuffer(),
                                coreTileOp.getTile(), pongBdIdConst.getResult(),
                                pongOffsetConst.getResult(),                 // offset
                                rewriter.getI32IntegerAttr(coreBdLen),       // len (bytes)
                                rewriter.getBoolAttr(coreBdEnablePacket),    // enable_packet
                                rewriter.getI32IntegerAttr(coreBdPacketId),  // packet_id
                                rewriter.getI32IntegerAttr(pingBdId),        // next_bd -> ping
                                rewriter.getI32IntegerAttr(bdAcquireLockId), // acquire_lock_id
                                rewriter.getI32IntegerAttr(-1),              // acquire_lock_val
                                rewriter.getI32IntegerAttr(bdReleaseLockId), // release_lock_id
                                rewriter.getI32IntegerAttr(1),               // release_lock_val
                                rewriter.getI32IntegerAttr(-1),              // data_id
                                Value(),                                     // linked_bd = none
                                rewriter.getI32IntegerAttr(coreOooBdId),     // out_of_order_bd_id
                                /*dim_strides=*/nullptr, /*dim_wraps=*/nullptr,
                                rewriter.getI32IntegerAttr(0),  // iter_step_size (no iteration)
                                rewriter.getI32IntegerAttr(0)); // iter_wrap (no iteration)

                            // Ping BD second (linked_bd = pong handle): next_bd -> pong
                            auto pingBdIdConst = rewriter.create<arith::ConstantOp>(
                                loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(pingBdId));
                            auto pingOffsetConst = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(),
                                                                                      rewriter.getI32IntegerAttr(0));
                            auto pingBdOp = rewriter.create<dfschedule::ConfigDmaBdOp>(
                                loc, dfschedule::BdHandleType::get(rewriter.getContext()), pingL1.getBuffer(),
                                coreTileOp.getTile(), pingBdIdConst.getResult(),
                                pingOffsetConst.getResult(),                 // offset
                                rewriter.getI32IntegerAttr(coreBdLen),       // len (bytes)
                                rewriter.getBoolAttr(coreBdEnablePacket),    // enable_packet
                                rewriter.getI32IntegerAttr(coreBdPacketId),  // packet_id
                                rewriter.getI32IntegerAttr(pongBdId),        // next_bd -> pong
                                rewriter.getI32IntegerAttr(bdAcquireLockId), // acquire_lock_id
                                rewriter.getI32IntegerAttr(-1),              // acquire_lock_val
                                rewriter.getI32IntegerAttr(bdReleaseLockId), // release_lock_id
                                rewriter.getI32IntegerAttr(1),               // release_lock_val
                                rewriter.getI32IntegerAttr(-1),              // data_id
                                pongBdOp.getBdHandle(),                      // linked_bd = pong BD
                                rewriter.getI32IntegerAttr(coreOooBdId),     // out_of_order_bd_id
                                /*dim_strides=*/nullptr, /*dim_wraps=*/nullptr,
                                rewriter.getI32IntegerAttr(0),  // iter_step_size (no iteration)
                                rewriter.getI32IntegerAttr(0)); // iter_wrap (no iteration)

                            firstCoreBdHandle = pingBdOp.getBdHandle();
                        }

                        // Create IO handle for core tile
                        auto coreCreateIoOp = rewriter.create<dfschedule::ConfigCreateIoOp>(
                            loc, dfschedule::IoHandleType::get(rewriter.getContext()), firstCoreBdHandle,
                            coreTileOp.getTile(), rewriter.getI32IntegerAttr(coreChannel),
                            rewriter.getStringAttr(coreDmaDirection), rewriter.getStringAttr(coreIoOperation),
                            rewriter.getBoolAttr(false)); // enable_out_of_order=false for core tiles
                        auto coreBdIdOp =
                            rewriter.create<dfschedule::GetBdIdOp>(loc, rewriter.getI32Type(), coreTileOp.getTile());
                        // Defer core StartIoOp until after ELF is loaded (LoadKernelGroup)
                        // to prevent BSS initialization from overwriting DMA data.
                        // Core tiles use ping-pong BD chaining (next_bd links ping↔pong),
                        // so the DMA hardware automatically re-arms via the chain.
                        // repeat=1 is sufficient; the BD chain does the work.
                        int32_t coreRepeat = 1;
                        deferredCoreStartIos.push_back(
                            {coreCreateIoOp.getIoHandle(), coreBdIdOp.getBdId(), flowIndex, coreRepeat});
                    } // end if (passState && ...)
                }
            }

            tileIndex++;
        }
        
        if (coreTiles.empty()) {
            rewriter.eraseOp(op);
            return success();
        }

        // Create individual kernel_config ops for each tile (e.g., @kernelconfig0, @kernelconfig1)
        // Use static counter to ensure unique names across multiple transfer manifests
        static int kernelConfigIdx = 0;
        SmallVector<Attribute> kernelConfigSymbols;
        for (size_t i = 0; i < tileConfigDicts.size(); ++i) {
            std::string configName = "kernelconfig" + std::to_string(kernelConfigIdx++);

            // Create a kernel_config op with a single tile's config
            SmallVector<Attribute> singleTileConfig;
            singleTileConfig.push_back(tileConfigDicts[i]);
            
            auto kernelConfigOp = rewriter.create<dfschedule::DeclareKernelConfigOp>(
                loc,
                dfschedule::KernelConfigType::get(rewriter.getContext()),
                rewriter.getStringAttr(configName),
                rewriter.getArrayAttr(singleTileConfig));
            
            // Store symbol reference
            kernelConfigSymbols.push_back(SymbolRefAttr::get(rewriter.getContext(), configName));
        }
        
        // Create callee symbol refs (dskernel_receiver for all)
        SmallVector<Attribute> calleeAttrs;
        calleeAttrs.push_back(SymbolRefAttr::get(rewriter.getContext(), "dskernel_receiver"));
        
        // Create distributed_compute_kernel_args (compute0 for all)
        SmallVector<Attribute> computeKernelAttrs;
        for (size_t i = 0; i < coreTiles.size(); ++i) {
            computeKernelAttrs.push_back(SymbolRefAttr::get(rewriter.getContext(), "compute0"));
            }

            // === Schedule emission: classify tiling mode ===
            auto moduleOp = op->getParentOfType<ModuleOp>();
            auto classification = classifyTiling(moduleOp);

            // Create dfschedule.schedule.getbdid for shim tile
            auto getBdIdOp = rewriter.create<dfschedule::GetBdIdOp>(loc, rewriter.getI32Type(), shimTileOp.getTile());

            bool nOuterPolicy = isNOuterPolicy(moduleOp);
            bool needsOuterLoop = false;
            if (nOuterPolicy) {
                needsOuterLoop = (classification.nMode == TilingMode::Multiple);
            } else {
                needsOuterLoop = (classification.mMode == TilingMode::Multiple);
            }

            if (needsOuterLoop && shimIsSender) {
                // === Multiple mode, input flow: unified scf.for ===
                // Kernel load/launch and core DMAs armed ONCE outside the loop.
                // A single scf.for handles ALL iterations uniformly (no special-casing
                // of iteration 0). Each iteration: config BD → create IO → start IO → wait.
                int64_t outerRounds = nOuterPolicy ? classification.nRounds : classification.mRounds;
                llvm::errs() << "[BlueprintToSchedule] Multiple mode input flow (policy="
                             << (nOuterPolicy ? "n_outer" : "m_outer") << "): "
                             << "outerRounds=" << outerRounds << ", emitting unified SCF loop from 0\n";

                // Erase the initial createIoOp and shimBdOp created above —
                // they are unused in Multiple mode because the loop body
                // creates its own BD and create_io each iteration.
                // In Multiple mode, lastShimBdHandle is only consumed by
                // createIoOp, so both can be erased unconditionally.
                {
                    Operation *shimBdDefOp = lastShimBdHandle ? lastShimBdHandle.getDefiningOp() : nullptr;
                    rewriter.eraseOp(createIoOp);
                    if (shimBdDefOp)
                        rewriter.eraseOp(shimBdDefOp);
                }

                // Compute per-iteration repeat: must match iter_wrap
                // The repeat count equals the number of inner-loop rounds:
                // m_outer: inner = nRounds (iter handles n-sub-tile stepping)
                // n_outer: inner = mRounds (iter handles m-sub-tile stepping)
                int32_t perIterRepeat = 1;
                if (moduleOp) {
                    auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds");
                    if (kRoundsAttr && kRoundsAttr.getInt() > 1) {
                        if (nOuterPolicy) {
                            // n_outer: inner loop = mRounds for both A and B
                            auto tileMAttrR = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
                            auto tileRowsAttrR = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");
                            int64_t tM = tileMAttrR ? tileMAttrR.getInt() : 0;
                            int64_t tR = tileRowsAttrR ? tileRowsAttrR.getInt() : 0;
                            if (tM > 0 && tM < tR) {
                                perIterRepeat = static_cast<int32_t>(tR / tM); // mRounds
                            } else {
                                perIterRepeat = static_cast<int32_t>(kRoundsAttr.getInt()); // fallback
                            }
                        } else {
                            // m_outer: inner loop = nRounds for both A and B
                            auto tileNAttrR = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
                            auto tileColsAttrR = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");
                            int64_t tN = tileNAttrR ? tileNAttrR.getInt() : 0;
                            int64_t tC = tileColsAttrR ? tileColsAttrR.getInt() : 0;
                            if (tN > 0 && tN < tC) {
                                perIterRepeat = static_cast<int32_t>(tC / tN); // nRounds
                            } else {
                                perIterRepeat = static_cast<int32_t>(kRoundsAttr.getInt()); // fallback
                            }
                        }
                    }
                }

                // Compute the byte stride for offset computation (policy+dataId dependent)
                // m_outer + A(dataId=1): stride = tileM * fullK * elemBytes (A advances via scf.for)
                // m_outer + B(dataId=0): stride = 0 (B uses iter, not scf.for)
                // n_outer + B(dataId=0): stride = tileN * fullK * elemBytes (B advances via scf.for)
                // n_outer + A(dataId=1): stride = 0 (A uses iter, not scf.for)
                int64_t elemBytes = 1;
                if (memrefType.getElementType().isIntOrFloat())
                    elemBytes = memrefType.getElementTypeBitWidth() / 8;
                if (elemBytes == 0)
                    elemBytes = 1;
                int64_t tileMVal = 0, tileNVal = 0, fullKVal = 0;
                if (auto a = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m"))
                    tileMVal = a.getInt();
                if (auto a = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n"))
                    tileNVal = a.getInt();
                if (auto a = moduleOp->getAttrOfType<IntegerAttr>("routing.full_k"))
                    fullKVal = a.getInt();
                int64_t subTileStride = 0; // default: no offset advancement
                if (!nOuterPolicy && dataId == 1) {
                    // m_outer, Input A: advance m-sub-tiles
                    subTileStride = tileMVal * fullKVal * elemBytes;
                } else if (nOuterPolicy && dataId == 0) {
                    // n_outer, Input B: advance n-sub-tiles
                    subTileStride = tileNVal * fullKVal * elemBytes;
                }

                // 1. load_kernel_group OUTSIDE the loop
                auto loadKernelGroupOp = rewriter.create<dfschedule::LoadKernelGroupOp>(
                    loc, dfschedule::KernelGroupType::get(rewriter.getContext()), coreTiles,
                    rewriter.getArrayAttr(calleeAttrs), rewriter.getArrayAttr(computeKernelAttrs), nullptr,
                    rewriter.getArrayAttr(kernelConfigSymbols));

                // 2. launch_kernel_group OUTSIDE the loop (kernel runs continuously,
                //    stalls at first DMA read until data arrives)
                auto launchKernelGroupOp = rewriter.create<dfschedule::LaunchKernelGroupOp>(
                    loc, dfschedule::EventType::get(rewriter.getContext()), loadKernelGroupOp.getKernelGroup());

                // 3. Core start_io OUTSIDE the loop (core DMAs armed once with total repeat)
                SmallVector<Value> coreStartIoEvents;
                for (auto &deferred : deferredCoreStartIos) {
                    auto coreStartIo = rewriter.create<dfschedule::StartIoOp>(
                        loc, dfschedule::EventType::get(rewriter.getContext()), deferred.ioHandle, deferred.bdId,
                        rewriter.getI32IntegerAttr(deferred.flowIdx), rewriter.getI32IntegerAttr(deferred.repeatCount));
                    coreStartIoEvents.push_back(coreStartIo.getEvent());
                }

                // 4. Single scf.for from 0 to outerRounds (ALL iterations uniform)
                {
                    auto lb = rewriter.create<arith::ConstantIndexOp>(loc, 0);
                    auto ub = rewriter.create<arith::ConstantIndexOp>(loc, outerRounds);
                    auto step = rewriter.create<arith::ConstantIndexOp>(loc, 1);

                    auto forOp = rewriter.create<scf::ForOp>(loc, lb, ub, step);
                    rewriter.setInsertionPointToStart(forOp.getBody());
                    Value iv = forOp.getInductionVar(); // index type

                    // Cast index → i32 for arithmetic
                    auto ivI32 = rewriter.create<arith::IndexCastOp>(loc, rewriter.getI32Type(), iv);

                    // Compute offset = iv * subTileStride
                    auto strideConst = rewriter.create<arith::ConstantIntOp>(loc, static_cast<int32_t>(subTileStride),
                                                                             rewriter.getI32Type());
                    auto offset = rewriter.create<arith::MulIOp>(loc, ivI32, strideConst);

                    // Config BD with dynamic offset AND correct K-round iter settings
                    auto loopBd = rewriter.create<dfschedule::ConfigDmaBdOp>(
                        loc, dfschedule::BdHandleType::get(rewriter.getContext()),
                        ddrBuffer,                                  // buffer
                        shimTileOp.getTile(),                       // tile
                        shimBdIdConst.getResult(),                  // bd_id
                        offset.getResult(),                         // offset (dynamic)
                        rewriter.getI32IntegerAttr(perTileShimLen), // len
                        rewriter.getBoolAttr(false),                // enable_packet
                        rewriter.getI32IntegerAttr(0),              // packet_id
                        rewriter.getI32IntegerAttr(4294967295),     // next_bd = none
                        rewriter.getI32IntegerAttr(0),              // acquire_lock_id
                        rewriter.getI32IntegerAttr(0),              // acquire_lock_val
                        rewriter.getI32IntegerAttr(0),              // release_lock_id
                        rewriter.getI32IntegerAttr(0),              // release_lock_val
                        rewriter.getI32IntegerAttr(dataId),         // data_id
                        Value(),                                    // linked_bd = none
                        rewriter.getI32IntegerAttr(-1),             // out_of_order_bd_id
                        shimDimStrides, shimDimWraps,
                        rewriter.getI32IntegerAttr(shimIterStepSize), // iter_step_size (K-round)
                        rewriter.getI32IntegerAttr(shimIterWrap));    // iter_wrap (kRounds)

                    // Create IO handle for the BD
                    auto loopCreateIo = rewriter.create<dfschedule::ConfigCreateIoOp>(
                        loc, dfschedule::IoHandleType::get(rewriter.getContext()), loopBd.getBdHandle(),
                        shimTileOp.getTile(), rewriter.getI32IntegerAttr(shimChannel),
                        rewriter.getStringAttr(dmaDirection), rewriter.getStringAttr(ioOperation),
                        rewriter.getBoolAttr(false));

                    // Start IO for this iteration
                    auto loopGetBdId =
                        rewriter.create<dfschedule::GetBdIdOp>(loc, rewriter.getI32Type(), shimTileOp.getTile());
                    auto loopStartIo = rewriter.create<dfschedule::StartIoOp>(
                        loc, dfschedule::EventType::get(rewriter.getContext()), loopCreateIo.getIoHandle(),
                        loopGetBdId.getBdId(), rewriter.getI32IntegerAttr(flowIndex),
                        rewriter.getI32IntegerAttr(perIterRepeat));

                    // Wait for this iteration's DMA to complete before next BD re-arm
                    SmallVector<Value> loopWaitEvents;
                    loopWaitEvents.push_back(loopStartIo.getEvent());
                    rewriter.create<dfschedule::ScheduleWaitOp>(loc, loopWaitEvents);

                    rewriter.setInsertionPointAfter(forOp);
                }

                // 5. After all iterations: wait for kernel launch event
                SmallVector<Value> finalEvents;
                finalEvents.push_back(launchKernelGroupOp.getEvent());
                rewriter.create<dfschedule::ScheduleWaitOp>(loc, finalEvents);

            } else if (useOOO && usedMRounds3D && oooMRounds > 1) {
                // === OOO output flow with outer_rounds > 1: scf.for loop ===
                // Each outer round: re-configure N OOO shim BDs with updated DDR offset,
                // then startio + wait. Inner dimension handled by BD iter_step/iter_wrap.
                // m_outer: scf.for over mRounds, iter over nRounds
                // n_outer: scf.for over nRounds, iter over mRounds
                llvm::errs() << "[BlueprintToSchedule] OOO output outerRounds loop: "
                             << "outerRounds=" << oooMRounds << " outerStride=" << oooMSubTileStride
                             << " numCoreTiles=" << numCoreTiles << " iter_wrap=" << oooIterWrap << "\n";

                // Erase the initial createIoOp and N shim BDs created above —
                // the loop body creates its own BDs and create_io each iteration.
                {
                    // The initial shimBdHandles are consumed only by createIoOp
                    // and each other via linked_bd. Erase createIoOp first, then BDs.
                    rewriter.eraseOp(createIoOp);
                    // Erase each initial shim BD (they are in shimBdHandles order)
                    for (int64_t t = 0; t < numCoreTiles; t++) {
                        if (shimBdHandles[t]) {
                            Operation *bdOp = shimBdHandles[t].getDefiningOp();
                            if (bdOp) {
                                // Also erase the arith.constant ops for bd_id and offset
                                // that feed exclusively into this BD op
                                SmallVector<Operation *, 2> deadConsts;
                                for (Value operand : bdOp->getOperands()) {
                                    if (auto constOp = operand.getDefiningOp<arith::ConstantOp>()) {
                                        if (constOp->hasOneUse())
                                            deadConsts.push_back(constOp);
                                    }
                                }
                                rewriter.eraseOp(bdOp);
                                for (auto *dc : deadConsts)
                                    rewriter.eraseOp(dc);
                            }
                        }
                    }
                }

                // 1. load_kernel_group OUTSIDE the loop
                auto loadKernelGroupOp = rewriter.create<dfschedule::LoadKernelGroupOp>(
                    loc, dfschedule::KernelGroupType::get(rewriter.getContext()), coreTiles,
                    rewriter.getArrayAttr(calleeAttrs), rewriter.getArrayAttr(computeKernelAttrs), nullptr,
                    rewriter.getArrayAttr(kernelConfigSymbols));

                // 2. launch_kernel_group OUTSIDE the loop
                auto launchKernelGroupOp = rewriter.create<dfschedule::LaunchKernelGroupOp>(
                    loc, dfschedule::EventType::get(rewriter.getContext()), loadKernelGroupOp.getKernelGroup());

                // 3. Core start_io OUTSIDE the loop (core DMAs armed once with total repeat)
                SmallVector<Value> coreStartIoEvents;
                for (auto &deferred : deferredCoreStartIos) {
                    auto coreStartIo = rewriter.create<dfschedule::StartIoOp>(
                        loc, dfschedule::EventType::get(rewriter.getContext()), deferred.ioHandle, deferred.bdId,
                        rewriter.getI32IntegerAttr(deferred.flowIdx), rewriter.getI32IntegerAttr(deferred.repeatCount));
                    coreStartIoEvents.push_back(coreStartIo.getEvent());
                }

                // 4. scf.for from 0 to oooMRounds (outerRounds): per-iteration OOO BD re-config + startio + wait
                // Each iteration handles one outer round. Per round, each of
                // numCoreTiles cores produces oooIterWrap inner-dimension outputs.
                // Total = perIterRepeat * oooMRounds = numCoreTiles * iterWrap * outerRounds.
                int32_t perIterRepeat = static_cast<int32_t>(numCoreTiles * oooIterWrap);
                {
                    auto lb = rewriter.create<arith::ConstantIndexOp>(loc, 0);
                    auto ub = rewriter.create<arith::ConstantIndexOp>(loc, oooMRounds);
                    auto step = rewriter.create<arith::ConstantIndexOp>(loc, 1);

                    auto forOp = rewriter.create<scf::ForOp>(loc, lb, ub, step);
                    rewriter.setInsertionPointToStart(forOp.getBody());
                    Value iv = forOp.getInductionVar(); // index type

                    // Cast index → i32 for arithmetic
                    auto ivI32 = rewriter.create<arith::IndexCastOp>(loc, rewriter.getI32Type(), iv);

                    // mBaseOffset = iv * oooMSubTileStride
                    auto mStrideConst = rewriter.create<arith::ConstantIntOp>(
                        loc, static_cast<int32_t>(oooMSubTileStride), rewriter.getI32Type());
                    auto mBaseOffset = rewriter.create<arith::MulIOp>(loc, ivI32, mStrideConst);

                    // Re-configure N OOO shim BDs with updated DDR offset
                    SmallVector<Value> loopBdHandles(numCoreTiles);
                    for (int64_t t = numCoreTiles - 1; t >= 0; t--) {
                        int32_t thisBdId = shimPerTileBdIds[t];
                        int64_t perTileOffset = t * perTileStrideFromDims;

                        auto bdIdConst = rewriter.create<arith::ConstantIntOp>(loc, thisBdId, rewriter.getI32Type());
                        auto perTileOffsetConst = rewriter.create<arith::ConstantIntOp>(
                            loc, static_cast<int32_t>(perTileOffset), rewriter.getI32Type());
                        // totalOffset = mBaseOffset + perTileOffset
                        auto totalOffset = rewriter.create<arith::AddIOp>(loc, mBaseOffset.getResult(),
                                                                          perTileOffsetConst.getResult());

                        // linked_bd chain for SSA: BD[i] links to BD[i+1] (or none for last)
                        Value linkedBd = (t < numCoreTiles - 1) ? loopBdHandles[t + 1] : Value();

                        auto loopBd = rewriter.create<dfschedule::ConfigDmaBdOp>(
                            loc, dfschedule::BdHandleType::get(rewriter.getContext()),
                            ddrBuffer,                                 // DDR buffer
                            shimTileOp.getTile(),                      // tile
                            bdIdConst.getResult(),                     // bd_id (reused)
                            totalOffset.getResult(),                   // offset (dynamic: m*stride + tile*step)
                            rewriter.getI32IntegerAttr(perRoundBytes), // len (one d0×d1 block)
                            rewriter.getBoolAttr(false),               // enable_packet = false
                            rewriter.getI32IntegerAttr(basePacketId + (int32_t)t), // packet_id (debug)
                            rewriter.getI32IntegerAttr(-1),                        // next_bd = -1 (no chaining)
                            rewriter.getI32IntegerAttr(-1),                        // acquire_lock_id = -1
                            rewriter.getI32IntegerAttr(0),                         // acquire_lock_val
                            rewriter.getI32IntegerAttr(-1),                        // release_lock_id = -1
                            rewriter.getI32IntegerAttr(0),                         // release_lock_val
                            rewriter.getI32IntegerAttr(dataId),                    // data_id
                            linkedBd,                                              // linked_bd
                            rewriter.getI32IntegerAttr(-1),                        // out_of_order_bd_id
                            /*dim_strides=*/perTileDimStrides, /*dim_wraps=*/perTileDimWraps,
                            rewriter.getI32IntegerAttr(oooIterStepSize), // iter_step_size
                            rewriter.getI32IntegerAttr(oooIterWrap));    // iter_wrap

                        loopBdHandles[t] = loopBd.getBdHandle();
                    }

                    // Create OOO IO handle (first BD in chain = BD[0])
                    auto loopCreateIo = rewriter.create<dfschedule::ConfigCreateIoOp>(
                        loc, dfschedule::IoHandleType::get(rewriter.getContext()), loopBdHandles[0],
                        shimTileOp.getTile(), rewriter.getI32IntegerAttr(shimChannel),
                        rewriter.getStringAttr(dmaDirection), rewriter.getStringAttr(ioOperation),
                        rewriter.getBoolAttr(true)); // enable_out_of_order = true

                    // Start IO: repeat = numCoreTiles * iterWrap per outer-round iteration
                    auto loopGetBdId =
                        rewriter.create<dfschedule::GetBdIdOp>(loc, rewriter.getI32Type(), shimTileOp.getTile());
                    auto loopStartIo = rewriter.create<dfschedule::StartIoOp>(
                        loc, dfschedule::EventType::get(rewriter.getContext()), loopCreateIo.getIoHandle(),
                        loopGetBdId.getBdId(), rewriter.getI32IntegerAttr(flowIndex),
                        rewriter.getI32IntegerAttr(perIterRepeat));

                    // Wait for this outer round's OOO completion before next BD re-arm
                    SmallVector<Value> loopWaitEvents;
                    loopWaitEvents.push_back(loopStartIo.getEvent());
                    rewriter.create<dfschedule::ScheduleWaitOp>(loc, loopWaitEvents);

                    rewriter.setInsertionPointAfter(forOp);
                }

                // 5. After all iterations: wait for kernel launch event
                SmallVector<Value> finalEvents;
                finalEvents.push_back(launchKernelGroupOp.getEvent());
                rewriter.create<dfschedule::ScheduleWaitOp>(loc, finalEvents);

            } else {
                // === Match mode or output flow: existing straight-line schedule ===

                // Shim start_io is emitted BEFORE load_kernel_group so that shim DMA
                // channels are armed first.  Core start_io remains after kernel launch
                // to avoid BSS-zeroing races.
                int32_t repeatCount = 1;
                if (useOOO) {
                    // OOO without m_rounds loop: repeat = numCoreTiles * ooNumIterations
                    repeatCount = (int32_t)(numCoreTiles * ooNumIterations);
                } else if (shimIsSender) {
                    // Channel repeat must match iter_wrap so the DMA engine
                    // re-executes the BD the correct number of times.
                    // Policy determines which dimension is in the inner loop (iter):
                    // m_outer: iter handles nRounds (B advances, A repeats)
                    // n_outer: iter handles mRounds (A advances, B repeats)
                    if (moduleOp) {
                        auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds");
                        if (kRoundsAttr && kRoundsAttr.getInt() > 1) {
                            if (nOuterPolicy) {
                                // n_outer: repeat = mRounds (matches iter_wrap) for both A and B
                                auto tileMAttrRC = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
                                auto tileRowsAttrRC = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");
                                int64_t tM = tileMAttrRC ? tileMAttrRC.getInt() : 0;
                                int64_t tR = tileRowsAttrRC ? tileRowsAttrRC.getInt() : 0;
                                if (tM > 0 && tM < tR) {
                                    repeatCount = static_cast<int32_t>(tR / tM); // mRounds
                                } else {
                                    repeatCount = static_cast<int32_t>(kRoundsAttr.getInt());
                                }
                            } else {
                                // m_outer: repeat = nRounds (matches iter_wrap) for both A and B
                                auto tileNAttrRC = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n");
                                auto tileColsAttrRC = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols");
                                int64_t tN = tileNAttrRC ? tileNAttrRC.getInt() : 0;
                                int64_t tC = tileColsAttrRC ? tileColsAttrRC.getInt() : 0;
                                if (tN > 0 && tN < tC) {
                                    repeatCount = static_cast<int32_t>(tC / tN); // nRounds
                                } else {
                                    repeatCount = static_cast<int32_t>(kRoundsAttr.getInt());
                                }
                            }
                        }
                    }
                }
                auto startIoOp = rewriter.create<dfschedule::StartIoOp>(
                    loc, dfschedule::EventType::get(rewriter.getContext()), createIoOp.getIoHandle(),
                    getBdIdOp.getBdId(), rewriter.getI32IntegerAttr(flowIndex),
                    rewriter.getI32IntegerAttr(repeatCount));

                // Create dfschedule.config.load_kernel_group
                auto loadKernelGroupOp = rewriter.create<dfschedule::LoadKernelGroupOp>(
                    loc, dfschedule::KernelGroupType::get(rewriter.getContext()), coreTiles,
                    rewriter.getArrayAttr(calleeAttrs), rewriter.getArrayAttr(computeKernelAttrs), nullptr,
                    rewriter.getArrayAttr(kernelConfigSymbols));

                // Create dfschedule.schedule.launch_kernel_group
                auto launchKernelGroupOp = rewriter.create<dfschedule::LaunchKernelGroupOp>(
                    loc, dfschedule::EventType::get(rewriter.getContext()), loadKernelGroupOp.getKernelGroup());

                // Emit deferred core StartIoOp calls AFTER kernel load/launch
                SmallVector<Value> coreStartIoEvents;
                for (auto &deferred : deferredCoreStartIos) {
                    auto coreStartIo = rewriter.create<dfschedule::StartIoOp>(
                        loc, dfschedule::EventType::get(rewriter.getContext()), deferred.ioHandle, deferred.bdId,
                        rewriter.getI32IntegerAttr(deferred.flowIdx), rewriter.getI32IntegerAttr(deferred.repeatCount));
                    coreStartIoEvents.push_back(coreStartIo.getEvent());
                }

                // Determine whether to bypass input sending IO wait.
                // When tile_m == tile_rows (M-dimension Match) for Row-distributed
                // inputs (funcArgIdx=0, input A), or tile_n == tile_cols (N-dimension
                // Match) for Col-distributed inputs (funcArgIdx=1, input B), the shim
                // DMA iteration handles all rounds autonomously via BD repeat — the
                // host does not need to wait for the shim IO to complete before
                // proceeding.
                bool bypassInputIoWait = false;
                if (shimIsSender) {
                    // funcArgIdx 0 = input A (Row-distributed) → M dimension
                    // funcArgIdx 1 = input B (Col-distributed) → N dimension
                    if (funcArgIdx == 0 && classification.mMode == TilingMode::Match) {
                        bypassInputIoWait = true;
                        llvm::errs() << "[BlueprintToSchedule] Bypassing input IO wait for input A "
                                     << "(funcArgIdx=0, M-dimension Match: tile_m == tile_rows)\n";
                    } else if (funcArgIdx == 1 && classification.nMode == TilingMode::Match) {
                        bypassInputIoWait = true;
                        llvm::errs() << "[BlueprintToSchedule] Bypassing input IO wait for input B "
                                     << "(funcArgIdx=1, N-dimension Match: tile_n == tile_cols)\n";
                    }
                }

                // Wait for kernel launch + shim IO events
                SmallVector<Value> events;
                events.push_back(launchKernelGroupOp.getEvent());
                if (!bypassInputIoWait)
                    events.push_back(startIoOp.getEvent());
                rewriter.create<dfschedule::ScheduleWaitOp>(loc, events);
            }

        // Stage 6: free DDR allocation after all transfers complete
        if (ddrBuffer) {
            rewriter.create<dfschedule::FreeDeviceMemOp>(loc, ddrBuffer);
        }

        // --- Step 5: Generate dskernel_receiver function ---
        // Use the same symbol name as load_kernel_group callee
        StringRef kernelName = "dskernel_receiver";
        
        // Only generate if it doesn't already exist
        if (!hasDSKernelReceiver(op.getOperation(), kernelName)) {
            // Get the tensor type from view for kernel generation
            RankedTensorType kernelTensorType;
            if (auto tensorType = dyn_cast<RankedTensorType>(viewType)) {
                kernelTensorType = tensorType;
            } else if (auto mrType = dyn_cast<MemRefType>(viewType)) {
                kernelTensorType = RankedTensorType::get(mrType.getShape(), mrType.getElementType());
            }
            
            if (kernelTensorType) {
                generateDSKernelReceiver(rewriter, loc, op.getOperation(), kernelName, kernelTensorType, bufferLen,
                                         basePacketId, coreChannel, flowIndex);
            }
        }

        // Buffer naming uses DMA channel index (coreChannel) so that all rounds
        // sharing the same kernel ELF get the same physical buffer addresses.
        // Within a single flow, all tiles share the same buffer addresses.

        // Erase the original FlowTransferOp
        rewriter.eraseOp(op);

        return success();
    }
};

// Special pattern for DataSliceOp - replaces with input tensor instead of erasing
struct DataSliceOpConversion : public OpConversionPattern<dfscheblueprint::DataSliceOp> {
    using OpConversionPattern<dfscheblueprint::DataSliceOp>::OpConversionPattern;

    LogicalResult
    matchAndRewrite(dfscheblueprint::DataSliceOp op, OpAdaptor adaptor,
                    ConversionPatternRewriter &rewriter) const override {
        // DataSliceOp is used for symbol references, replace with the input tensor
        rewriter.replaceOp(op, adaptor.getTensorSlice());
        return success();
    }
};

// Pattern for DeclareDataOp - pass through the init_tensor operand to all users
struct DeclareDataOpConversion : public OpConversionPattern<dfscheblueprint::DeclareDataOp> {
    using OpConversionPattern<dfscheblueprint::DeclareDataOp>::OpConversionPattern;

    LogicalResult matchAndRewrite(dfscheblueprint::DeclareDataOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // DeclareDataOp is a logical wrapper around init_tensor; pass through the input
        rewriter.replaceOp(op, adaptor.getInitTensor());
        return success();
    }
};

} // namespace

namespace mlir {

void BlueprintToSchedulePass::runOnOperation() {
    MLIRContext *context = &getContext();

    // --- Phase 1: Pre-processing ---
    auto passState = std::make_shared<BlueprintPassState>();
    if (failed(preprocessConstantToMemref(getOperation(), passState))) {
        signalPassFailure();
        return;
    }

    // Cache routing module attributes before conversion (they may be stripped
    // during applyPartialConversion).
    {
        auto moduleOp = dyn_cast<ModuleOp>(getOperation());
        if (moduleOp) {
            auto getI64 = [&](StringRef name) -> int64_t {
                auto attr = moduleOp->getAttrOfType<IntegerAttr>(name);
                return attr ? attr.getInt() : 0;
            };
            passState->tileM = getI64("routing.tile_m");
            passState->tileRows = getI64("routing.tile_rows");
            passState->tileN = getI64("routing.tile_n");
            passState->tileCols = getI64("routing.tile_cols");
            passState->effectiveK = getI64("routing.effective_k");
            passState->fullK = getI64("routing.full_k");
            passState->kRounds = getI64("routing.k_rounds");
        }
    }

    // --- Phase 2: Dialect conversion ---
    ConversionTarget target(*context);
    target.addLegalDialect<dfschedule::dfscheduledialect, routing::routingdialect, func::FuncDialect,
                           memref::MemRefDialect, arith::ArithDialect, scf::SCFDialect, tensor::TensorDialect,
                           bufferization::BufferizationDialect, BuiltinDialect, emitc::EmitCDialect>();

    target.addIllegalOp<dfscheblueprint::FlowConfigOp>();
    target.addIllegalOp<dfscheblueprint::TileGroupOp>();
    target.addIllegalOp<dfscheblueprint::DeclareDataOp>();
    target.addIllegalOp<dfscheblueprint::FlowTransferOp>();

    auto hwRes = makeResource(aieGen_);
    auto resourceMgr = std::make_shared<ResourceMgr>(std::move(hwRes));

    RewritePatternSet patterns(context);
    patterns.add<FlowTransferConversion>(context, resourceMgr, passState, bufferRatio_, maxPingPongBytes_);
    patterns.add<DataSliceOpConversion>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::FlowConfigOp>>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::TileGroupOp>>(context);
    patterns.add<DeclareDataOpConversion>(context);

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
        return;
    }

    // --- Phase 3: Erase dead tensor/routing ops ---
    // tensor.extract_slice chains can be nested (partition → producer), so
    // iterate until no more dead ops are found.
    SmallVector<Operation *, 8> deadOps;
    bool changed = true;
    while (changed) {
        changed = false;
        deadOps.clear();
        getOperation()->walk([&](Operation *op) {
            if (!op->use_empty())
                return;
            if (isa<tensor::ExtractSliceOp>(op) || isa<routing::partitiontensor>(op) ||
                isa<bufferization::ToTensorOp>(op) ||
                (isa<arith::ConstantOp>(op) && isa<RankedTensorType>(op->getResult(0).getType())))
                deadOps.push_back(op);
        });
        for (auto *op : deadOps) {
            op->erase();
            changed = true;
        }
    }

    // Region restructuring is deferred to ScheduleCanonicalizePass.
    // The dfschedule ops remain inside routing.RoutingCreate bodies, which is
    // valid because RoutingCreate has the SymbolTable trait needed by
    // DeclareKernelConfigOp.  ScheduleCanonicalizePass will extract them into
    // per-partition scf.execute_region blocks and erase the routing ops.
}

} // namespace mlir
