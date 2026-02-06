/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#include "passblueprinttoschedulekernel.h"
#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinDialect.h"
#include "mlir/Transforms/DialectConversion.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include <iostream>
#include <sstream>
#include <unordered_map>
#include <vector>

using namespace mlir;
using namespace dfscheblueprint;
using namespace dfschedule;

namespace {

// ============================================================================
// Fake Resource Manager for Lock and BD ID allocation
// ============================================================================
class KernelResourceManager {
  public:
    KernelResourceManager()
        : nextBdId(0), nextLockId(0), nextInputAcqLock(48), nextInputRelLock(49), nextOutputAcqLock(51),
          nextOutputRelLock(50) {}

    // Allocate next BD ID (0, 1 for ping-pong)
    int32_t allocateBdId() { return nextBdId++; }

    // Allocate next Lock ID
    int64_t allocateLockId() { return nextLockId++; }

    // Allocate lock IDs for input windows (acquire for read, release after read)
    int32_t allocateInputAcquireLock() { return nextInputAcqLock++; }
    int32_t allocateInputReleaseLock() { return nextInputRelLock++; }

    // Allocate lock IDs for output windows (acquire for write, release after write)
    int32_t allocateOutputAcquireLock() { return nextOutputAcqLock++; }
    int32_t allocateOutputReleaseLock() { return nextOutputRelLock++; }

    // Reset for new kernel
    void reset() {
        nextBdId = 0;
        nextLockId = 0;
        nextInputAcqLock = 48;
        nextInputRelLock = 49;
        nextOutputAcqLock = 51;
        nextOutputRelLock = 50;
    }

  private:
    int32_t nextBdId;
    int64_t nextLockId;
    int32_t nextInputAcqLock;
    int32_t nextInputRelLock;
    int32_t nextOutputAcqLock;
    int32_t nextOutputRelLock;
};

// Generic template function to look up any operation by symbol reference
// This function searches for an operation of type OpTy with a matching symbol name
// The search starts in the same block as rootOp and then searches parent regions
template <typename OpTy> static OpTy lookupSymbolOp(Operation *rootOp, SymbolRefAttr target) {
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
template <typename OpTy> struct EraseOpPattern : public OpConversionPattern<OpTy> {
    using OpConversionPattern<OpTy>::OpConversionPattern;

    LogicalResult matchAndRewrite(OpTy op, typename OpTy::Adaptor adaptor,
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
static Operation *getModuleOp(Operation *rootOp) {
    Operation *moduleOp = rootOp;
    while (moduleOp->getParentOp()) {
        moduleOp = moduleOp->getParentOp();
    }
    return moduleOp;
}

// =============================================================================
// Kernel Module IR Generation
// =============================================================================
// Generates a general-purpose kernel module IR that can be lowered by different
// passes to produce either:
//   - LegacyKernelPass  -> adfkernellegacy.cc style (loop inside kernel)
//   - AdfKernelPass     -> adfkernel.cc style (loop in wrapper)
//
// The generated IR uses abstract operations:
//   - dfschedule.module           : top-level kernel module
//   - dfschedule.kernel_config    : kernel metadata
//   - dfschedule.lock_def         : named lock definitions
//   - dfschedule.buffer           : named buffer declarations
//   - dfschedule.window           : abstract window (ping/pong + locks)
//   - dfschedule.kernel_decl      : kernel signature with iteration_style
//   - dfschedule.main             : entry point with kernel_invoke
// =============================================================================

// Structure to hold individual kernel parameter info (input/output window)
struct KernelParamInfo {
    std::string windowName;     // e.g., "window_in_0", "window_out_0"
    std::string bufferPingName; // e.g., "buf_in_ping_0"
    std::string bufferPongName; // e.g., "buf_in_pong_0"
    bool isInput;               // true = input parameter, false = output parameter
    int32_t acquireLockId;      // Lock ID for acquire operation
    int32_t releaseLockId;      // Lock ID for release operation
    Type elementType;           // Element type of the buffer
    int64_t bufferSize;         // Size of the buffer
    int32_t vectorWidth;        // Vector width (e.g., 4 for v4int32)
};

// Structure to hold kernel generation parameters
struct KernelGenParams {
    StringRef kernelName;        // Wrapper function name, e.g., "dskernel_receiver"
    StringRef computeKernelName; // Actual compute kernel name, e.g., "perf"
    StringRef kernelFile;        // e.g., "perf.cc"
    int64_t bufferSize;          // e.g., 256
    Type elementType;            // e.g., i32
    int32_t vectorWidth;         // e.g., 4
    StringRef iterationStyle;    // "internal" or "external"

    // Lock IDs (base values, will be offset for ping/pong) - used when params is empty
    int32_t inputAcquireLockId;  // e.g., 48
    int32_t inputReleaseLockId;  // e.g., 49
    int32_t outputAcquireLockId; // e.g., 51
    int32_t outputReleaseLockId; // e.g., 50

    // Dynamic parameter list - when non-empty, overrides the hardcoded lock IDs
    SmallVector<KernelParamInfo> kernelParams;
};

// Generate dfschedule.module with kernel_config, locks, buffers, windows, kernel_decl, and main
// This is the general-purpose kernel module that can be lowered by different passes
static void generateKernelModule(ConversionPatternRewriter &rewriter, Location loc, Operation *insertBeforeOp,
                                 const KernelGenParams &params, RankedTensorType tensorType) {

    // Create module name from kernel name
    std::string moduleName = "kernel_driver_" + params.kernelName.str();

    // Check if kernel module already exists - skip if duplicate
    if (hasKernelModule(insertBeforeOp, moduleName)) {
        return;
    }

    // Save current insertion point
    OpBuilder::InsertionGuard guard(rewriter);

    // Find module and insert at module level
    Operation *rootModuleOp = getModuleOp(insertBeforeOp);
    Block &moduleBlock = rootModuleOp->getRegions().front().front();

    // Check if block has a terminator, insert before it; otherwise insert at end
    if (!moduleBlock.empty() && moduleBlock.back().hasTrait<OpTrait::IsTerminator>()) {
        rewriter.setInsertionPoint(&moduleBlock.back());
    } else {
        rewriter.setInsertionPointToEnd(&moduleBlock);
    }

    // Create the dfschedule.module operation
    auto kernelModuleOp = rewriter.create<dfschedule::KernelModuleOp>(loc, rewriter.getStringAttr(moduleName));

    // Create the body block for the module
    Block *body = &kernelModuleOp.getBody().emplaceBlock();
    rewriter.setInsertionPointToStart(body);

    // =========================================================================
    // 1. Kernel Config (metadata)
    // =========================================================================
    NamedAttrList configAttrs;
    configAttrs.append("kernel_name", rewriter.getStringAttr(params.computeKernelName));
    configAttrs.append("kernel_file", rewriter.getStringAttr(params.kernelFile));
    configAttrs.append("buffer_size", rewriter.getI32IntegerAttr(params.bufferSize));
    configAttrs.append("element_type", TypeAttr::get(params.elementType));
    configAttrs.append("vector_width", rewriter.getI32IntegerAttr(params.vectorWidth));

    rewriter.create<dfschedule::KernelConfigDefOp>(loc, rewriter.getStringAttr("config"),
                                                   rewriter.getDictionaryAttr(configAttrs));

    // =========================================================================
    // 2-5. Generate Locks, Buffers, Windows, and Kernel Declaration
    // =========================================================================
    // Use dynamic parameters if provided, otherwise fall back to hardcoded values

    SmallVector<Attribute> inputWindowRefs;
    SmallVector<Attribute> outputWindowRefs;
    SmallVector<std::string> allWindowNames; // Track window names for main block

    if (!params.kernelParams.empty()) {
        // === DYNAMIC PARAMETER MODE ===
        // Generate locks, buffers, and windows for each kernel parameter

        for (const auto &paramInfo : params.kernelParams) {
            // Lock definitions for this parameter
            std::string acqLockName = "LOCK_" + paramInfo.windowName + "_ACQ";
            std::string relLockName = "LOCK_" + paramInfo.windowName + "_REL";

            rewriter.create<dfschedule::LockDefOp>(loc, rewriter.getStringAttr(acqLockName),
                                                   rewriter.getI32IntegerAttr(paramInfo.acquireLockId));
            rewriter.create<dfschedule::LockDefOp>(loc, rewriter.getStringAttr(relLockName),
                                                   rewriter.getI32IntegerAttr(paramInfo.releaseLockId));

            // Buffer definitions (ping/pong pair)
            Type elemType = paramInfo.elementType ? paramInfo.elementType : params.elementType;
            auto vectorType = VectorType::get({paramInfo.vectorWidth}, elemType);
            auto localMemRefType =
                MemRefType::get({paramInfo.bufferSize}, vectorType, AffineMap(), rewriter.getStringAttr("LOCAL"));

            rewriter.create<dfschedule::BufferDefOp>(loc, rewriter.getStringAttr(paramInfo.bufferPingName),
                                                     TypeAttr::get(localMemRefType));
            rewriter.create<dfschedule::BufferDefOp>(loc, rewriter.getStringAttr(paramInfo.bufferPongName),
                                                     TypeAttr::get(localMemRefType));

            // Window definition
            NamedAttrList winAttrs;
            winAttrs.append("direction", rewriter.getStringAttr(paramInfo.isInput ? "in" : "out"));
            winAttrs.append("ping_buffer", SymbolRefAttr::get(rewriter.getContext(), paramInfo.bufferPingName));
            winAttrs.append("pong_buffer", SymbolRefAttr::get(rewriter.getContext(), paramInfo.bufferPongName));
            winAttrs.append("acquire_lock", SymbolRefAttr::get(rewriter.getContext(), acqLockName));
            winAttrs.append("release_lock", SymbolRefAttr::get(rewriter.getContext(), relLockName));
            winAttrs.append("buffer_size", rewriter.getI32IntegerAttr(paramInfo.bufferSize));
            winAttrs.append("async", rewriter.getBoolAttr(true));

            rewriter.create<dfschedule::WindowDefOp>(loc, rewriter.getStringAttr(paramInfo.windowName),
                                                     rewriter.getDictionaryAttr(winAttrs));

            // Track for kernel declaration
            if (paramInfo.isInput) {
                inputWindowRefs.push_back(SymbolRefAttr::get(rewriter.getContext(), paramInfo.windowName));
            } else {
                outputWindowRefs.push_back(SymbolRefAttr::get(rewriter.getContext(), paramInfo.windowName));
            }
            allWindowNames.push_back(paramInfo.windowName);
        }
    } else {
        // === HARDCODED MODE (backward compatibility) ===
        // Generate fixed input/output locks, buffers, and windows

        // Lock definitions
        rewriter.create<dfschedule::LockDefOp>(loc, rewriter.getStringAttr("LOCK_win_ping_ACQ"),
                                               rewriter.getI32IntegerAttr(params.inputAcquireLockId));
        rewriter.create<dfschedule::LockDefOp>(loc, rewriter.getStringAttr("LOCK_win_pong_REL"),
                                               rewriter.getI32IntegerAttr(params.inputReleaseLockId));
        rewriter.create<dfschedule::LockDefOp>(loc, rewriter.getStringAttr("LOCK_out_ping_ACQ"),
                                               rewriter.getI32IntegerAttr(params.outputAcquireLockId));
        rewriter.create<dfschedule::LockDefOp>(loc, rewriter.getStringAttr("LOCK_out_pong_REL"),
                                               rewriter.getI32IntegerAttr(params.outputReleaseLockId));

        // Buffer definitions
        auto vectorType = VectorType::get({params.vectorWidth}, params.elementType);
        auto localMemRefType =
            MemRefType::get({params.bufferSize}, vectorType, AffineMap(), rewriter.getStringAttr("LOCAL"));

        rewriter.create<dfschedule::BufferDefOp>(loc, rewriter.getStringAttr("win_ping"),
                                                 TypeAttr::get(localMemRefType));
        rewriter.create<dfschedule::BufferDefOp>(loc, rewriter.getStringAttr("win_pong"),
                                                 TypeAttr::get(localMemRefType));
        rewriter.create<dfschedule::BufferDefOp>(loc, rewriter.getStringAttr("out_ping"),
                                                 TypeAttr::get(localMemRefType));
        rewriter.create<dfschedule::BufferDefOp>(loc, rewriter.getStringAttr("out_pong"),
                                                 TypeAttr::get(localMemRefType));

        // Window definitions
        NamedAttrList winInAttrs;
        winInAttrs.append("direction", rewriter.getStringAttr("in"));
        winInAttrs.append("ping_buffer", SymbolRefAttr::get(rewriter.getContext(), "win_ping"));
        winInAttrs.append("pong_buffer", SymbolRefAttr::get(rewriter.getContext(), "win_pong"));
        winInAttrs.append("acquire_lock", SymbolRefAttr::get(rewriter.getContext(), "LOCK_win_ping_ACQ"));
        winInAttrs.append("release_lock", SymbolRefAttr::get(rewriter.getContext(), "LOCK_win_pong_REL"));
        winInAttrs.append("buffer_size", rewriter.getI32IntegerAttr(params.bufferSize));
        winInAttrs.append("async", rewriter.getBoolAttr(true));
        rewriter.create<dfschedule::WindowDefOp>(loc, rewriter.getStringAttr("window_in"),
                                                 rewriter.getDictionaryAttr(winInAttrs));

        NamedAttrList winOutAttrs;
        winOutAttrs.append("direction", rewriter.getStringAttr("out"));
        winOutAttrs.append("ping_buffer", SymbolRefAttr::get(rewriter.getContext(), "out_ping"));
        winOutAttrs.append("pong_buffer", SymbolRefAttr::get(rewriter.getContext(), "out_pong"));
        winOutAttrs.append("acquire_lock", SymbolRefAttr::get(rewriter.getContext(), "LOCK_out_ping_ACQ"));
        winOutAttrs.append("release_lock", SymbolRefAttr::get(rewriter.getContext(), "LOCK_out_pong_REL"));
        winOutAttrs.append("buffer_size", rewriter.getI32IntegerAttr(params.bufferSize));
        winOutAttrs.append("async", rewriter.getBoolAttr(true));
        rewriter.create<dfschedule::WindowDefOp>(loc, rewriter.getStringAttr("window_out"),
                                                 rewriter.getDictionaryAttr(winOutAttrs));

        inputWindowRefs.push_back(SymbolRefAttr::get(rewriter.getContext(), "window_in"));
        outputWindowRefs.push_back(SymbolRefAttr::get(rewriter.getContext(), "window_out"));
        allWindowNames.push_back("window_in");
        allWindowNames.push_back("window_out");
    }

    // =========================================================================
    // 5. Kernel Declaration
    // =========================================================================
    NamedAttrList kernelDeclAttrs;
    kernelDeclAttrs.append("inputs", rewriter.getArrayAttr(inputWindowRefs));
    kernelDeclAttrs.append("outputs", rewriter.getArrayAttr(outputWindowRefs));
    kernelDeclAttrs.append("iteration_style", rewriter.getStringAttr(params.iterationStyle));

    rewriter.create<dfschedule::KernelDeclOp>(loc, rewriter.getStringAttr(params.computeKernelName),
                                              rewriter.getDictionaryAttr(kernelDeclAttrs));

    // =========================================================================
    // 6. Main Entry Point
    // =========================================================================
    auto mainOp = rewriter.create<dfschedule::KernelMainOp>(loc, rewriter.getStringAttr("main"));

    // Create the body block for main
    Block *mainBody = &mainOp.getBody().emplaceBlock();
    rewriter.setInsertionPointToStart(mainBody);

    // --- Sync buffer ---
    auto syncBufferType = dfschedule::SyncBufferType::get(rewriter.getContext());
    auto syncBufferOp =
        rewriter.create<dfschedule::AllocSyncBufferOp>(loc, syncBufferType, rewriter.getI32IntegerAttr(8));

    // Reset end signal: sync_buffer[0] = 0
    auto c0_i32 = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(0));
    rewriter.create<dfschedule::SyncBufferWriteOp>(loc, syncBufferOp.getResult(), c0_i32.getResult(),
                                                   rewriter.getI32IntegerAttr(0));

    // --- Debug logging ---
    auto c1_i32 = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(1));
    rewriter.create<dfschedule::LogOp>(loc, c1_i32.getResult());

    // --- Window initialization and kernel args ---
    SmallVector<Value> kernelArgs;

    if (!params.kernelParams.empty()) {
        // Dynamic: Initialize each window based on kernelParams
        for (const auto &paramInfo : params.kernelParams) {
            Type elemType = paramInfo.elementType ? paramInfo.elementType : params.elementType;
            if (paramInfo.isInput) {
                auto inputWindowType = dfschedule::InputWindowType::get(rewriter.getContext(), elemType);
                auto winPtrOp = rewriter.create<dfschedule::WindowInitOp>(
                    loc, inputWindowType, SymbolRefAttr::get(rewriter.getContext(), paramInfo.windowName));
                kernelArgs.push_back(winPtrOp.getResult());
            } else {
                auto outputWindowType = dfschedule::OutputWindowType::get(rewriter.getContext(), elemType);
                auto outPtrOp = rewriter.create<dfschedule::WindowInitOp>(
                    loc, outputWindowType, SymbolRefAttr::get(rewriter.getContext(), paramInfo.windowName));
                kernelArgs.push_back(outPtrOp.getResult());
            }
        }
    } else {
        // Hardcoded: Initialize fixed input/output windows
        auto inputWindowType = dfschedule::InputWindowType::get(rewriter.getContext(), params.elementType);
        auto winPtrOp = rewriter.create<dfschedule::WindowInitOp>(
            loc, inputWindowType, SymbolRefAttr::get(rewriter.getContext(), "window_in"));

        auto outputWindowType = dfschedule::OutputWindowType::get(rewriter.getContext(), params.elementType);
        auto outPtrOp = rewriter.create<dfschedule::WindowInitOp>(
            loc, outputWindowType, SymbolRefAttr::get(rewriter.getContext(), "window_out"));

        kernelArgs.push_back(winPtrOp.getResult());
        kernelArgs.push_back(outPtrOp.getResult());
    }

    // --- Kernel invocation ---
    rewriter.create<dfschedule::KernelInvokeOp>(
        loc, SymbolRefAttr::get(rewriter.getContext(), params.computeKernelName), kernelArgs);

    // --- Signal completion ---
    rewriter.create<dfschedule::DoneOp>(loc);

    // --- Return ---
    rewriter.create<dfschedule::KernelReturnOp>(loc);
}

// Forward declarations for functions used in generateDSKernelReceiver
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target);
static SmallVector<KernelParamInfo> analyzeKernelParams(Operation *rootOp, KernelResourceManager &resourceMgr,
                                                        Type defaultElementType, int64_t defaultBufferSize,
                                                        int32_t defaultVectorWidth);

// Generate dfschedule.dskernel_receiver function (legacy style)
// This is kept for backward compatibility and will call generateKernelModule internally
// Parameters:
//   - kernelName: symbol name for the kernel (same as load_kernel_group callee)
//   - tensorType: the tensor type for data
//   - bufferLen: buffer length for DMA BD
//   - basePacketId: base packet ID from FlowTransferOp
//   - coreChannel: DMA channel from core FlowConfig
//   - flowIndex: unique index for this flow, used to access per-flow DMA configs
static void generateDSKernelReceiver(ConversionPatternRewriter &rewriter, Location loc, Operation *insertBeforeOp,
                                     StringRef kernelName, RankedTensorType tensorType, int64_t bufferLen,
                                     uint32_t basePacketId, int64_t coreChannel, uint32_t flowIndex,
                                     KernelResourceManager &resourceMgr) {

    // Build kernel generation parameters
    KernelGenParams params;
    params.kernelName = kernelName;              // Wrapper function name (e.g., "dskernel_receiver")
    params.computeKernelName = "compute_kernel"; // Actual compute kernel name
    params.kernelFile = "compute_kernel.cc";     // Kernel source file
    params.bufferSize = 256;                     // Default buffer size (BUF_SZ)
    params.elementType = rewriter.getI32Type();
    params.vectorWidth = 4;
    params.iterationStyle = "internal"; // Legacy style: loop inside kernel

    // Lock IDs (fallback - used when kernelParams is empty)
    params.inputAcquireLockId = 48;  // LOCK_win_ping_ACQ
    params.inputReleaseLockId = 49;  // LOCK_win_pong_REL
    params.outputAcquireLockId = 51; // LOCK_out_ping_ACQ
    params.outputReleaseLockId = 50; // LOCK_out_pong_REL

    // Dynamically analyze flow_transfer operations to determine kernel parameters
    // Walk from the module root to collect all shim<->core data flows
    Operation *rootOp = getModuleOp(insertBeforeOp);
    params.kernelParams =
        analyzeKernelParams(rootOp, resourceMgr, params.elementType, params.bufferSize, params.vectorWidth);

    // Generate the kernel module IR
    generateKernelModule(rewriter, loc, insertBeforeOp, params, tensorType);
}

static dfscheblueprint::DataSliceOp lookupDataSlice(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::DataSliceOp>(rootOp, target);
}

// Helper function to look up FlowConfigOp by symbol reference (wrapper for backward compatibility)
static dfscheblueprint::FlowConfigOp lookupFlowConfig(Operation *rootOp, SymbolRefAttr target) {
    return lookupSymbolOp<dfscheblueprint::FlowConfigOp>(rootOp, target);
}

// Helper function to trace a value through the IR to find FlowConfigOp that uses it
// This follows the value chain from declare_data result to FlowConfig.view
static dfscheblueprint::FlowConfigOp traceToFlowConfig(Value dataValue, Operation *rootOp) {
    // Track visited values to avoid infinite loops
    SmallPtrSet<Value, 16> visited;
    SmallVector<Value, 16> worklist;
    worklist.push_back(dataValue);

    while (!worklist.empty()) {
        Value currentValue = worklist.pop_back_val();
        if (visited.contains(currentValue))
            continue;
        visited.insert(currentValue);

        // Check all users of this value
        for (Operation *user : currentValue.getUsers()) {
            // Check if user is a FlowConfigOp and this value is its view operand
            if (auto flowConfig = dyn_cast<dfscheblueprint::FlowConfigOp>(user)) {
                if (flowConfig.getView() == currentValue) {
                    return flowConfig;
                }
            }

            // For other ops, add their results to the worklist to continue tracing
            for (Value result : user->getResults()) {
                if (!visited.contains(result)) {
                    worklist.push_back(result);
                }
            }
        }
    }

    return nullptr; // No FlowConfigOp found using this data
}

// Helper function to find FlowTransferOp that references a given FlowConfigOp
// Searches for flow_transfer ops where 'from' or 'to' matches the FlowConfig's symbol
static dfscheblueprint::FlowTransferOp
findFlowTransferFor(dfscheblueprint::FlowConfigOp flowConfig, Operation *rootOp,
                    bool &isFromConfig) { // Output: true if flowConfig is the 'from', false if 'to'

    // Get the symbol name of the FlowConfigOp
    StringRef configSymbol = flowConfig.getSymName();
    if (configSymbol.empty())
        return nullptr;

    dfscheblueprint::FlowTransferOp result = nullptr;
    isFromConfig = false;

    // Walk all flow_transfer operations to find one that references this FlowConfig
    rootOp->walk([&](dfscheblueprint::FlowTransferOp transferOp) {
        if (result)
            return; // Already found

        // Check if 'from' matches
        SymbolRefAttr fromRef = transferOp.getFrom();
        if (fromRef && fromRef.getRootReference().getValue() == configSymbol) {
            result = transferOp;
            isFromConfig = true;
            return;
        }

        // Check if 'to' matches
        SymbolRefAttr toRef = transferOp.getTo();
        if (toRef && toRef.getRootReference().getValue() == configSymbol) {
            result = transferOp;
            isFromConfig = false;
            return;
        }
    });

    return result;
}

// Analyze all declare_data operations to determine kernel parameters dynamically
// Returns a list of KernelParamInfo based on actual data flows:
// - For each declare_data, trace value chain to find FlowConfigOp
// - Find flow_transfer referencing that FlowConfig
// - shim -> core: Input parameter
// - core -> shim: Output parameter
// - No flow_transfer or core -> core: Skip (not a kernel parameter)
static SmallVector<KernelParamInfo> analyzeKernelParams(Operation *rootOp, KernelResourceManager &resourceMgr,
                                                        Type defaultElementType, int64_t defaultBufferSize,
                                                        int32_t defaultVectorWidth) {

    SmallVector<KernelParamInfo> params;
    int inputCount = 0;
    int outputCount = 0;

    // Walk all declare_data operations in the module
    rootOp->walk([&](dfscheblueprint::DeclareDataOp declareDataOp) {
        // Get the result value of declare_data
        Value dataValue = declareDataOp.getResult();

        // Trace the value chain to find FlowConfigOp that uses this data
        auto flowConfig = traceToFlowConfig(dataValue, rootOp);
        if (!flowConfig) {
            return; // No FlowConfig found - not a kernel parameter
        }

        // Find flow_transfer that references this FlowConfig
        bool isFromConfig = false;
        auto flowTransfer = findFlowTransferFor(flowConfig, rootOp, isFromConfig);
        if (!flowTransfer) {
            return; // No flow_transfer found - not a kernel parameter
        }

        // Get the 'from' and 'to' FlowConfigOps from the flow_transfer
        SymbolRefAttr fromRef = flowTransfer.getFrom();
        auto fromFlowConfig = lookupFlowConfig(flowTransfer.getOperation(), fromRef);
        if (!fromFlowConfig) {
            return;
        }

        SymbolRefAttr toRef = flowTransfer.getTo();
        auto toFlowConfig = lookupFlowConfig(flowTransfer.getOperation(), toRef);
        if (!toFlowConfig) {
            return;
        }

        // Determine direction based on shim/core types
        auto fromType = fromFlowConfig.getType();
        auto toType = toFlowConfig.getType();

        bool isInput = false;
        bool isValidParam = false;

        if (fromType && *fromType == "shim" && toType && *toType == "core") {
            // shim -> core: Input parameter (MM2S - data flows into kernel)
            isInput = true;
            isValidParam = true;
        } else if (fromType && *fromType == "core" && toType && *toType == "shim") {
            // core -> shim: Output parameter (S2MM - data flows out of kernel)
            isInput = false;
            isValidParam = true;
        }
        // Note: core -> core is skipped (inter-tile transfer)

        if (isValidParam) {
            KernelParamInfo paramInfo;

            if (isInput) {
                paramInfo.windowName = "window_in_" + std::to_string(inputCount);
                paramInfo.bufferPingName = "buf_in_ping_" + std::to_string(inputCount);
                paramInfo.bufferPongName = "buf_in_pong_" + std::to_string(inputCount);
                paramInfo.isInput = true;
                // Allocate lock IDs for input (acquire for read, release after read)
                paramInfo.acquireLockId = resourceMgr.allocateInputAcquireLock();
                paramInfo.releaseLockId = resourceMgr.allocateInputReleaseLock();
                inputCount++;
            } else {
                paramInfo.windowName = "window_out_" + std::to_string(outputCount);
                paramInfo.bufferPingName = "buf_out_ping_" + std::to_string(outputCount);
                paramInfo.bufferPongName = "buf_out_pong_" + std::to_string(outputCount);
                paramInfo.isInput = false;
                // Allocate lock IDs for output (acquire for write, release after write)
                paramInfo.acquireLockId = resourceMgr.allocateOutputAcquireLock();
                paramInfo.releaseLockId = resourceMgr.allocateOutputReleaseLock();
                outputCount++;
            }

            // Get element type from the declare_data operand
            Value srcValue = declareDataOp.getOperand();
            if (srcValue) {
                Type srcType = srcValue.getType();
                if (auto tensorType = dyn_cast<RankedTensorType>(srcType)) {
                    paramInfo.elementType = tensorType.getElementType();
                    // Calculate buffer size from tensor shape
                    int64_t totalSize = 1;
                    for (int64_t dim : tensorType.getShape()) {
                        totalSize *= dim;
                    }
                    paramInfo.bufferSize = totalSize;
                } else {
                    paramInfo.elementType = defaultElementType;
                    paramInfo.bufferSize = defaultBufferSize;
                }
            } else {
                paramInfo.elementType = defaultElementType;
                paramInfo.bufferSize = defaultBufferSize;
            }

            paramInfo.vectorWidth = defaultVectorWidth;
            params.push_back(paramInfo);
        }
    });

    return params;
}

// Pattern to convert dfscheblueprint::FlowTransferOp to dfschedule operations.
// Kernel-only: generates only dfschedule.module (kernel driver) via generateDSKernelReceiver.
// No host IR (DeclareTensor, DeclareTile, ConfigDmaBd, ConfigCreateIo, LoadKernelGroup, etc.).
struct FlowTransferConversion : public OpConversionPattern<dfscheblueprint::FlowTransferOp> {
    using OpConversionPattern<dfscheblueprint::FlowTransferOp>::OpConversionPattern;

    mutable KernelResourceManager resourceMgr;

    LogicalResult matchAndRewrite(dfscheblueprint::FlowTransferOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        auto loc = op.getLoc();

        SymbolRefAttr fromRef = op.getFrom();
        auto fromFlowConfig = lookupFlowConfig(op.getOperation(), fromRef);
        if (!fromFlowConfig) {
            rewriter.eraseOp(op);
            return success();
        }

        SymbolRefAttr toRef = op.getTo();
        auto toFlowConfig = lookupFlowConfig(op.getOperation(), toRef);
        if (!toFlowConfig) {
            rewriter.eraseOp(op);
            return success();
        }

        dfscheblueprint::FlowConfigOp shimFlowConfig = nullptr;
        dfscheblueprint::FlowConfigOp coreFlowConfig = nullptr;

        auto fromType = fromFlowConfig.getType();
        auto toType = toFlowConfig.getType();

        if (fromType && *fromType == "shim") {
            shimFlowConfig = fromFlowConfig;
            coreFlowConfig = toFlowConfig;
        } else if (toType && *toType == "shim") {
            shimFlowConfig = toFlowConfig;
            coreFlowConfig = fromFlowConfig;
        } else {
            rewriter.eraseOp(op);
            return success();
        }

        auto shimTileGroup = lookupTileGroup(shimFlowConfig.getOperation(), shimFlowConfig.getTarget());
        auto coreTileGroup = lookupTileGroup(coreFlowConfig.getOperation(), coreFlowConfig.getTarget());
        if (!shimTileGroup || !coreTileGroup) {
            rewriter.eraseOp(op);
            return success();
        }

        uint32_t basePacketId = op.getBasePacketId();
        uint32_t flowIndex = op.getFlowIndex();

        Value viewValue = shimFlowConfig.getView();
        Type viewType = viewValue.getType();

        // Compute bufferLen and kernelTensorType from view (no host IR)
        int64_t bufferLen = 1;
        RankedTensorType kernelTensorType;
        if (auto tensorType = dyn_cast<RankedTensorType>(viewType)) {
            kernelTensorType = tensorType;
            for (int64_t dim : tensorType.getShape()) {
                bufferLen *= dim;
            }
        } else if (auto mrType = dyn_cast<MemRefType>(viewType)) {
            kernelTensorType = RankedTensorType::get(mrType.getShape(), mrType.getElementType());
            for (int64_t dim : mrType.getShape()) {
                bufferLen *= dim;
            }
        } else {
            rewriter.eraseOp(op);
            return success();
        }

        auto coreDmaAttr = coreFlowConfig.getDma();
        auto coreDmaChannels = coreDmaAttr.getChannels();
        int64_t coreChannel = coreDmaChannels.empty() ? 0 : coreDmaChannels[0];

        StringRef kernelName = "dskernel_receiver";
        if (!hasDSKernelReceiver(op.getOperation(), kernelName)) {
            generateDSKernelReceiver(rewriter, loc, op.getOperation(), kernelName, kernelTensorType, bufferLen,
                                     basePacketId, coreChannel, flowIndex, resourceMgr);
        }

        rewriter.eraseOp(op);
        return success();
    }
};

// Special pattern for DataSliceOp - replaces with input tensor instead of erasing
struct DataSliceOpConversion : public OpConversionPattern<dfscheblueprint::DataSliceOp> {
    using OpConversionPattern<dfscheblueprint::DataSliceOp>::OpConversionPattern;

    LogicalResult matchAndRewrite(dfscheblueprint::DataSliceOp op, OpAdaptor adaptor,
                                  ConversionPatternRewriter &rewriter) const override {
        // DataSliceOp is used for symbol references, replace with the input tensor
        rewriter.replaceOp(op, adaptor.getTensorSlice());
        return success();
    }
};

} // namespace

namespace mlir {

void BlueprintToScheduleKernelPass::runOnOperation() {
    MLIRContext *context = &getContext();
    ConversionTarget target(*context);

    // Mark target dialects as legal
    target
        .addLegalDialect<dfschedule::dfscheduledialect, func::FuncDialect, memref::MemRefDialect, arith::ArithDialect,
                         scf::SCFDialect, tensor::TensorDialect, bufferization::BufferizationDialect, BuiltinDialect>();

    // Mark all dfscheblueprint operations as illegal to trigger conversion/erasure
    target.addIllegalOp<dfscheblueprint::FlowConfigOp>();
    target.addIllegalOp<dfscheblueprint::TileGroupOp>();
    // target.addIllegalOp<dfscheblueprint::DeclareDataOp>();
    // target.addIllegalOp<dfscheblueprint::DataSliceOp>();
    target.addIllegalOp<dfscheblueprint::FlowTransferOp>();
    target.addIllegalOp<dfscheblueprint::TransferManifestOp>();

    // Type converter
    TypeConverter typeConverter;
    typeConverter.addConversion([](Type type) { return type; });

    // Convert tensor types to memref types where needed
    typeConverter.addConversion([](RankedTensorType tensorType) -> Type {
        return MemRefType::get(tensorType.getShape(), tensorType.getElementType());
    });

    RewritePatternSet patterns(context);
    // FlowTransferConversion converts flow_transfer to dfschedule operations
    // It reads from FlowConfigOps to get DMA configuration
    patterns.add<FlowTransferConversion>(context);
    // DataSliceOp replaces with input tensor
    patterns.add<DataSliceOpConversion>(context);
    // Use unified erase pattern for ops that just need to be removed
    // FlowConfigOp is erased since FlowTransferConversion reads its attributes directly
    patterns.add<EraseOpPattern<dfscheblueprint::FlowConfigOp>>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::TileGroupOp>>(context);
    // patterns.add<EraseOpPattern<dfscheblueprint::DeclareDataOp>>(context);
    patterns.add<EraseOpPattern<dfscheblueprint::TransferManifestOp>>(context);

    if (failed(applyPartialConversion(getOperation(), target, std::move(patterns)))) {
        signalPassFailure();
        return;
    }

    // Kernel-only: remove all top-level ops that are not dfschedule kernel logic.
    // Keep only DSKernelReceiverOp (@kernel_driver_dskernel_receiver) and KernelModuleOp (dfschedule.module).
    // This removes func @main and any declare_data / partitiontensor / RoutingCreate host IR.
    Operation *root = getOperation();
    while (root->getParentOp())
        root = root->getParentOp();
    Block &body = root->getRegion(0).front();
    SmallVector<Operation *> toErase;
    for (Operation &op : body)
        if (!isa<dfschedule::DSKernelReceiverOp>(&op) && !isa<dfschedule::KernelModuleOp>(&op))
            toErase.push_back(&op);
    for (auto it = toErase.rbegin(); it != toErase.rend(); ++it)
        (*it)->erase();
}

} // namespace mlir
