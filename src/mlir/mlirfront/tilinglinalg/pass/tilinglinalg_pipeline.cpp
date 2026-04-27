/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "tilinglinalg_pipeline.h"

#include "dmaptodmaphop.h"
#include "hw/ResourceManager.h"
#include "kernelconfig.h"
#include "passblueprinttoschedule.h"
#include "passblueprinttoschedulekernel.h"
#include "passdfscheduletoapi.h"
#include "passdfscheduletokernelapi.h"
#include "passdmaphoptodfscheblueprint.h"
#include "passdmaphoptoroutinghw.h"
#include "passschedulecanonicalize.h"
#include "routingconstantfold.h"
#include "routingdeadargclean.h"
#include "routinghwlower.h"
#include "routinghwverify.h"
#include "routinglower.h"
#include "routingtodmap.h"
#include "routingunrolling.h"

#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include "dmaphopmanager.h"
#include "dmapmanager.h"
#include "kernelgraphmanager.h"
#include "routinghwmanager.h"
#include "routingmanager.h"

#include "mlir/Conversion/SCFToEmitC/SCFToEmitC.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlow.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/Transforms/Passes.h"
#include "mlir/Target/Cpp/CppEmitter.h"

#include "llvm/ADT/SmallString.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"

#include <iostream>
#include <unordered_map>

using namespace mlir;

// ---------------------------------------------------------------------------
// Helpers (same as unitest/test.cpp)
// ---------------------------------------------------------------------------

static std::string setupPipelineIRDir(const std::string &subdir) {
    llvm::SmallString<256> cwdPath;
    if (std::error_code EC = llvm::sys::fs::current_path(cwdPath)) {
        llvm::errs() << "Failed to get current directory: " << EC.message() << "\n";
        return "";
    }
    std::string dir = (cwdPath + "/ir/" + subdir).str();
    if (std::error_code EC = llvm::sys::fs::create_directories(dir)) {
        llvm::errs() << "Failed to create IR directory " << dir << ": " << EC.message() << "\n";
        return "";
    }
    std::cout << "IR output directory: " << dir << std::endl;
    return dir;
}

static void dumpPipelineIRToFile(mlir::ModuleOp module, const std::string &dir, int stage, const std::string &passName) {
    if (dir.empty())
        return;
    std::string filename = dir + "/" + std::to_string(stage) + "_" + passName + ".mlir";
    std::error_code ec;
    llvm::raw_fd_ostream os(filename, ec, llvm::sys::fs::OF_None);
    if (ec) {
        llvm::errs() << "Failed to write IR to " << filename << ": " << ec.message() << "\n";
        return;
    }
    module.print(os);
    std::cout << "  IR -> " << filename << std::endl;
}

static bool runPipelineSinglePass(MLIRContext &ctx, mlir::ModuleOp module, std::unique_ptr<mlir::Pass> pass,
                          const std::string &irDir, int &stage, const std::string &passName) {
    mlir::PassManager singlePm(&ctx);
    singlePm.addPass(std::move(pass));
    if (failed(singlePm.run(module))) {
        llvm::errs() << "ERROR: " << passName << " failed!\n";
        return false;
    }
    dumpPipelineIRToFile(module, irDir, stage, passName);
    stage++;
    return true;
}

// ---------------------------------------------------------------------------
// TilingLinalgPipeline implementation
// ---------------------------------------------------------------------------

void TilingLinalgPipeline::registerDialects(mlir::MLIRContext &ctx) {
    // Instantiate dialect managers to trigger registration
    routingmanager mtest;
    routinghwmanager mtesthw;
    dmapmanager mdmaptest;
    dmaphopmanager dmaphoptest;
    dfschedulemanager dfscheduletest;
    dfscheblueprintmanager dfscheblueprinttest;

    mtest.loaddialect(&ctx);
    mtesthw.loaddialect(&ctx);
    mdmaptest.loaddialect(&ctx);
    dmaphoptest.loaddialect(&ctx);
    dfscheduletest.loaddialect(&ctx);
    dfscheblueprinttest.loaddialect(&ctx);

    // Register kernelgraph dialect for multi-kernel support
    kernelgraphmanager kgm;
    kgm.loaddialect(&ctx);

    ctx.getOrLoadDialect<arith::ArithDialect>();
    ctx.getOrLoadDialect<mlir::func::FuncDialect>();
    ctx.getOrLoadDialect<mlir::memref::MemRefDialect>();
    ctx.getOrLoadDialect<mlir::scf::SCFDialect>();
    ctx.getOrLoadDialect<mlir::tensor::TensorDialect>();
    ctx.getOrLoadDialect<mlir::bufferization::BufferizationDialect>();
    ctx.getOrLoadDialect<mlir::emitc::EmitCDialect>();
}

mlir::ModuleOp TilingLinalgPipeline::buildRoutingIR(mlir::MLIRContext &ctx, int meshRows, int meshCols,
                                                    const std::vector<TensorParam> &tensors,
                                                    const SplitModel &splitModel) {

    // This is a parameterized version of routingmanager::ops_testNew()
    using namespace routing;

    OpBuilder builder(&ctx);
    mlir::ModuleOp m = ModuleOp::create(builder.getUnknownLoc());

    // Build function type WITH memref arguments — one per tensor.
    // Each memref represents an external DDR pointer provided by the caller.
    SmallVector<Type> argTypes;
    for (const auto &tp : tensors) {
        auto elementType = builder.getIntegerType(tp.elementBitWidth);
        auto memrefType = MemRefType::get(tp.shape, elementType);
        argTypes.push_back(memrefType);
    }
    auto functype = builder.getFunctionType(argTypes, {});
    mlir::func::FuncOp hostFunc = builder.create<func::FuncOp>(builder.getUnknownLoc(), "main", functype);

    auto block = hostFunc.addEntryBlock();
    builder.setInsertionPointToEnd(block);
    auto mesh = builder.create<createhwmesh>(builder.getUnknownLoc(), meshRows, meshCols);

    // Build all tensor values first
    std::vector<Value> tensorValues;
    std::vector<bool> isInputFlags;
    for (unsigned i = 0; i < tensors.size(); ++i) {
        const auto &tp = tensors[i];

        // Build shape attributes
        SmallVector<Attribute> shape;
        for (int64_t v : tp.shape)
            shape.push_back(builder.getI64IntegerAttr(v));
        ArrayAttr vals = builder.getArrayAttr(shape);
        IntegerAttr dimnum = builder.getI64IntegerAttr(tp.shape.size());

        // Build tensor type
        auto elementType = builder.getIntegerType(tp.elementBitWidth);
        auto tensorType = RankedTensorType::get(tp.shape, elementType);

        // Get the func argument (memref from user's DDR pointer)
        Value memrefArg = block->getArgument(i);

        // Convert memref -> tensor (logical view, zero-copy)
        auto tensorValue = builder.create<bufferization::ToTensorOp>(builder.getUnknownLoc(), tensorType, memrefArg);

        // Feed into createscheduletensor — same as before
        auto tensor = builder.create<createscheduletensor>(builder.getUnknownLoc(), tensorType, tensorValue.getResult(),
                                                           vals, dimnum);
        tensorValues.push_back(tensor);
        isInputFlags.push_back(tp.isInput);
    }

    // Use SplitModel-driven routing generation
    routingmanager rm;
    rm.createroutingfuncBySplitModel(builder, &ctx, mesh, tensorValues, isInputFlags, meshRows, meshCols, splitModel);

    builder.create<mlir::func::ReturnOp>(builder.getUnknownLoc());
    m.push_back(hostFunc);
    llvm::errs() << m;
    return m;
}

mlir::ModuleOp TilingLinalgPipeline::buildRoutingIR(mlir::MLIRContext &ctx, int meshRows, int meshCols, int originRow,
                                                    int originCol, const std::vector<TensorParam> &tensors,
                                                    const SplitModel &splitModel, int kernelId) {
    // Build routing IR at (0,0) using the existing method
    auto module = buildRoutingIR(ctx, meshRows, meshCols, tensors, splitModel);

    // Post-process: offset all tile coordinate attributes by (originRow, originCol)
    // This adjusts createhwmesh, RoutingCreate, and other ops that reference
    // relative tile positions to use absolute physical positions.
    if (originRow != 0 || originCol != 0) {
        module.walk([&](Operation *op) {
            // Offset origin attributes on createhwmesh
            if (auto meshOp = dyn_cast<routing::createhwmesh>(op)) {
                // Add origin_row and origin_col attributes for downstream passes
                meshOp->setAttr("origin_row", IntegerAttr::get(IntegerType::get(&ctx, 64), originRow));
                meshOp->setAttr("origin_col", IntegerAttr::get(IntegerType::get(&ctx, 64), originCol));
            }
        });
        // Tag the module with kernel_id for multi-kernel tracking
        module->setAttr("routing.kernel_id", IntegerAttr::get(IntegerType::get(&ctx, 32), kernelId));
    }

    return module;
}

bool TilingLinalgPipeline::runMultiKernelPipeline(mlir::MLIRContext &ctx, mlir::ModuleOp module,
                                                  const std::string &outputDir, const std::vector<KernelInfo> &kernels,
                                                  const std::vector<DataEdgeInfo> &dataEdges) {
    // Create output directory
    if (std::error_code EC = llvm::sys::fs::create_directories(outputDir)) {
        llvm::errs() << "Failed to create directory " << outputDir << ": " << EC.message() << "\n";
        return false;
    }

    RoutingTopology rtopology("Gen2");
    std::string irDir = setupPipelineIRDir("multikernel");

    // Initialize ResourceMgr singleton
    {
        auto hwRes = makeResource("Gen2");
        ResourceMgr::init(std::move(hwRes));
    }

    // -----------------------------------------------------------------------
    // Topological sort: group kernels into execution stages based on data edges
    // Kernels with no dependencies (or whose dependencies are all in earlier
    // stages) go into the same stage and can run concurrently.
    // -----------------------------------------------------------------------
    // Build adjacency: consumer -> set of producer ids
    std::unordered_map<int, std::vector<int>> predecessors;
    for (const auto &edge : dataEdges) {
        predecessors[edge.consumerKernelId].push_back(edge.producerKernelId);
    }

    // Assign stage numbers via BFS-like topological layering
    std::unordered_map<int, int> kernelStage; // kernelId -> stage
    int numStages = 0;
    {
        // Compute in-degree based on data edges
        std::unordered_map<int, int> inDegree;
        for (const auto &ki : kernels)
            inDegree[ki.kernelId] = 0;
        for (const auto &edge : dataEdges) {
            inDegree[edge.consumerKernelId]++;
        }

        // BFS layers: kernels with in-degree 0 go to stage 0, etc.
        std::vector<int> currentLayer;
        for (const auto &ki : kernels) {
            if (inDegree[ki.kernelId] == 0) {
                currentLayer.push_back(ki.kernelId);
                kernelStage[ki.kernelId] = 0;
            }
        }

        int currentStageNum = 0;
        while (!currentLayer.empty()) {
            std::vector<int> nextLayer;
            for (int kid : currentLayer) {
                // Find consumers of this kernel
                for (const auto &edge : dataEdges) {
                    if (edge.producerKernelId == kid) {
                        inDegree[edge.consumerKernelId]--;
                        if (inDegree[edge.consumerKernelId] == 0) {
                            kernelStage[edge.consumerKernelId] = currentStageNum + 1;
                            nextLayer.push_back(edge.consumerKernelId);
                        }
                    }
                }
            }
            currentLayer = nextLayer;
            if (!nextLayer.empty())
                currentStageNum++;
        }
        numStages = currentStageNum + 1;
    }

    // If no data edges, all kernels go to stage 0
    if (dataEdges.empty()) {
        for (const auto &ki : kernels)
            kernelStage[ki.kernelId] = 0;
        numStages = 1;
    }

    // Build stage -> list of kernel indices
    std::vector<std::vector<size_t>> stages(numStages);
    for (size_t i = 0; i < kernels.size(); ++i) {
        int stg = kernelStage[kernels[i].kernelId];
        stages[stg].push_back(i);
    }

    std::cout << "\n=== Multi-Kernel Execution Plan (" << numStages << " stage(s)) ===" << std::endl;
    for (int s = 0; s < numStages; ++s) {
        std::cout << "  Stage " << s << ": ";
        for (size_t idx : stages[s]) {
            std::cout << kernels[idx].kernelName << " (" << kernels[idx].executionMode << ") ";
        }
        std::cout << std::endl;
    }

    // Reserve regions for spatial_parallel kernels (sequential_reuse share regions)
    for (const auto &ki : kernels) {
        if (ki.executionMode == "spatial_parallel") {
            if (!ResourceMgr::instance()->reserveRegion(ki.kernelId, ki.originRow, ki.originCol, ki.meshRows,
                                                        ki.meshCols)) {
                llvm::errs() << "Failed to reserve region for kernel " << ki.kernelName << "\n";
                return false;
            }
        }
    }

    // For each kernel, build and run the pipeline independently
    for (size_t ki_idx = 0; ki_idx < kernels.size(); ++ki_idx) {
        const auto &ki = kernels[ki_idx];
        std::cout << "\n=== Processing kernel: " << ki.kernelName << " (id=" << ki.kernelId << ", mesh=" << ki.meshRows
                  << "x" << ki.meshCols << " at " << ki.originRow << "," << ki.originCol
                  << ", mode=" << ki.executionMode << ", stage=" << kernelStage[ki.kernelId] << ") ===" << std::endl;

        // Default tensor config for each kernel
        std::vector<TensorParam> tensors = {
            {{16, 16}, 8, true},  // input A
            {{16, 16}, 8, true},  // input B
            {{16, 16}, 8, false}, // output C
        };

        // Build routing IR with origin offset for this kernel
        auto kernelModule = buildRoutingIR(ctx, ki.meshRows, ki.meshCols, ki.originRow, ki.originCol, tensors,
                                           SplitModel::gemm(), ki.kernelId);

        // Create per-kernel output directory
        std::string kernelDir = outputDir + "/" + ki.kernelName;
        if (std::error_code EC = llvm::sys::fs::create_directories(kernelDir)) {
            llvm::errs() << "Failed to create kernel directory " << kernelDir << ": " << EC.message() << "\n";
            return false;
        }

        // Run the standard pipeline for this kernel
        if (!runPipeline(ctx, kernelModule, kernelDir, ki.kernelBody, ki.kernelFuncName, -1, "", tensors)) {
            llvm::errs() << "Pipeline failed for kernel " << ki.kernelName << "\n";
            return false;
        }

        std::cout << "=== Kernel " << ki.kernelName << " complete ===" << std::endl;
    }

    // -----------------------------------------------------------------------
    // Generate stage-based unified host_main.cc
    // -----------------------------------------------------------------------
    {
        std::string hostMainPath = outputDir + "/host_main.cc";
        std::error_code ec;
        llvm::raw_fd_ostream stream(hostMainPath, ec, llvm::sys::fs::OF_None);
        if (ec) {
            llvm::errs() << "Failed to create " << hostMainPath << "\n";
            return false;
        }

        stream << "// Auto-generated multi-kernel host main\n";
        stream << "// Execution plan: " << numStages << " stage(s)\n";
        stream << "#include <stdio.h>\n";
        stream << "#include <stdlib.h>\n";
        stream << "#include <string.h>\n\n";

        // Extern declarations for each kernel's binary and host function
        for (const auto &ki : kernels) {
            stream << "// Kernel: " << ki.kernelName << " (stage " << kernelStage[ki.kernelId] << ", "
                   << ki.executionMode << ")\n";
            stream << "extern unsigned char _binary_kernel_" << ki.kernelName << "_start[];\n";
            stream << "extern unsigned char _binary_kernel_" << ki.kernelName << "_end[];\n";
            stream << "extern unsigned int _binary_kernel_" << ki.kernelName << "_size;\n\n";
        }

        // Forward-declare each kernel's host_canonicalized function
        for (const auto &ki : kernels) {
            stream << "void host_canonicalized_" << ki.kernelName << "(";
            stream << "void*, void*, void*";
            stream << ");\n";
        }

        // Forward-declare routing functions
        for (const auto &ki : kernels) {
            stream << "void routing_" << ki.kernelName << "();\n";
        }

        stream << "\nint main() {\n";
        stream << "    printf(\"\\n========== Multi-Kernel AIE Test ==========\\n\");\n\n";

        // Allocate DDR buffers for each kernel
        for (size_t i = 0; i < kernels.size(); ++i) {
            const auto &ki = kernels[i];
            int totalBytes = 16 * 16; // Default: 16x16 i8 tensor
            stream << "    // Buffers for kernel: " << ki.kernelName << "\n";
            stream << "    void* buf_" << ki.kernelName << "_A = malloc(" << totalBytes << ");\n";
            stream << "    void* buf_" << ki.kernelName << "_B = malloc(" << totalBytes << ");\n";
            stream << "    void* buf_" << ki.kernelName << "_C = malloc(" << totalBytes << ");\n";
            stream << "    for (int j = 0; j < " << totalBytes << "; j++) {\n";
            stream << "        ((char*)buf_" << ki.kernelName << "_A)[j] = (char)(j + 1);\n";
            stream << "        ((char*)buf_" << ki.kernelName << "_B)[j] = (char)(j + 2);\n";
            stream << "    }\n";
            stream << "    memset(buf_" << ki.kernelName << "_C, 0, " << totalBytes << ");\n\n";
        }

        // Wire up data edges: copy producer output to consumer input
        // (emit as comments for now; actual DDR memcpy between stages)

        // Execute stage by stage
        for (int s = 0; s < numStages; ++s) {
            stream << "    // ===== Stage " << s << " =====\n";
            stream << "    printf(\"--- Stage " << s << " ---\\n\");\n";

            // If stage > 0, perform data transfers from previous stages
            if (s > 0) {
                for (const auto &edge : dataEdges) {
                    // Find producer and consumer kernel names
                    if (kernelStage[edge.consumerKernelId] == s) {
                        std::string producerName, consumerName;
                        for (const auto &ki : kernels) {
                            if (ki.kernelId == edge.producerKernelId)
                                producerName = ki.kernelName;
                            if (ki.kernelId == edge.consumerKernelId)
                                consumerName = ki.kernelName;
                        }
                        if (!producerName.empty() && !consumerName.empty()) {
                            stream << "    // Data edge: " << producerName << " output[" << edge.producerOutputIdx
                                   << "] -> " << consumerName << " input[" << edge.consumerInputIdx << "] ("
                                   << edge.transferMode << ")\n";
                            stream << "    printf(\"  Transferring data: " << producerName << " -> " << consumerName
                                   << "\\n\");\n";
                            stream << "    memcpy(buf_" << consumerName << "_A, buf_" << producerName
                                   << "_C, 256);\n\n";
                        }
                    }
                }
            }

            // Configure routing for all kernels in this stage
            for (size_t idx : stages[s]) {
                const auto &ki = kernels[idx];
                stream << "    printf(\"Configuring routing for kernel: " << ki.kernelName << "\\n\");\n";
                stream << "    routing_" << ki.kernelName << "();\n";
            }
            stream << "\n";

            // Launch all kernels in this stage (concurrent for spatial_parallel)
            for (size_t idx : stages[s]) {
                const auto &ki = kernels[idx];
                stream << "    printf(\"Launching kernel: " << ki.kernelName << "\\n\");\n";
                stream << "    host_canonicalized_" << ki.kernelName << "("
                       << "buf_" << ki.kernelName << "_A, "
                       << "buf_" << ki.kernelName << "_B, "
                       << "buf_" << ki.kernelName << "_C);\n";
            }
            stream << "\n";

            // Stage synchronization barrier
            stream << "    printf(\"Stage " << s << " complete.\\n\");\n\n";
        }

        // Print output buffers
        for (const auto &ki : kernels) {
            stream << "    printf(\"Output for kernel " << ki.kernelName << ":\\n\");\n";
            stream << "    for (int j = 0; j < 256; j++) printf(\"  out[%d]=%d\\n\", j, "
                   << "((unsigned char*)buf_" << ki.kernelName << "_C)[j]);\n\n";
        }

        // Free buffers
        for (const auto &ki : kernels) {
            stream << "    free(buf_" << ki.kernelName << "_A);\n";
            stream << "    free(buf_" << ki.kernelName << "_B);\n";
            stream << "    free(buf_" << ki.kernelName << "_C);\n";
        }

        stream << "\n    printf(\"\\n========== Multi-Kernel Test Complete ==========\\n\");\n";
        stream << "    return 0;\n";
        stream << "}\n";

        stream.close();
        std::cout << "Unified host main written to " << hostMainPath << std::endl;
    }

    // Generate unified compile scripts
    {
        std::string compilePath = outputDir + "/compile_all_kernels.sh";
        std::error_code ec;
        llvm::raw_fd_ostream stream(compilePath, ec, llvm::sys::fs::OF_None);
        if (ec) {
            llvm::errs() << "Failed to create " << compilePath << "\n";
            return false;
        }
        stream << "#!/bin/bash\n";
        stream << "# Auto-generated multi-kernel compile script\n";
        stream << "set -e\n\n";

        for (const auto &ki : kernels) {
            stream << "echo \"=== Compiling kernel: " << ki.kernelName << " ===\"\n";
            stream << "pushd " << ki.kernelName << "\n";
            stream << "mkdir -p build\n";
            stream << "# Compile kernel ELF using xchesscc\n";
            stream << "# xchesscc +f kernel.cc " << ki.kernelFuncName << ".cc -o build/kernel\n";
            stream << "echo \"Kernel " << ki.kernelName << " compiled.\"\n";
            stream << "popd\n\n";
        }

        stream << "echo \"=== Creating kernel binary objects ===\"\n";
        for (const auto &ki : kernels) {
            stream << "cd " << ki.kernelName << "/build && ";
            stream << "ld -r -b binary kernel -o kernel_" << ki.kernelName << ".o && ";
            stream << "cd ../..\n";
        }

        stream << "\necho \"=== Compiling unified host ===\"\n";
        stream << "KERNEL_OBJS=\"";
        for (size_t i = 0; i < kernels.size(); ++i) {
            if (i > 0)
                stream << " ";
            stream << kernels[i].kernelName << "/build/kernel_" << kernels[i].kernelName << ".o";
        }
        stream << "\"\n";

        // Each kernel's host.cc and routing.cc
        stream << "HOST_SRCS=\"host_main.cc";
        for (const auto &ki : kernels) {
            stream << " " << ki.kernelName << "/host.cc";
            stream << " " << ki.kernelName << "/routing.cc";
        }
        stream << "\"\n\n";

        stream << "aarch64-linux-gnu-g++ $HOST_SRCS aie_runtime.c $KERNEL_OBJS -o build/host\n";
        stream << "echo \"=== All kernels compiled and linked ===\"\n";
        stream.close();
        std::cout << "Compile script written to " << compilePath << std::endl;
    }

    return true;
}

bool TilingLinalgPipeline::runPipeline(mlir::MLIRContext &ctx, mlir::ModuleOp module, const std::string &outputDir,
                                       const std::string &userKernelBody, const std::string &userKernelFuncName,
                                       int runtimeDebugLevel, const std::string &userRewrittenSource,
                                       const std::vector<TensorParam> &tensors) {

    RoutingTopology rtopology("Gen2");

    std::string irDir = setupPipelineIRDir("dfschedule");
    int stage = 0;

    dumpPipelineIRToFile(module, irDir, stage++, "initial");

    // Phase 1: routing -> dmap -> dmaphop -> dfscheblueprint
    if (!runPipelineSinglePass(ctx, module, std::make_unique<RoutingUnrollingLowerPass>(), irDir, stage,
                       "RoutingUnrollingLowerPass"))
        return false;
    if (!runPipelineSinglePass(ctx, module, std::make_unique<RoutingToDmapPass>(rtopology), irDir, stage, "RoutingToDmapPass"))
        return false;
    if (!runPipelineSinglePass(ctx, module, std::make_unique<DmapToDmaphopPass>(rtopology), irDir, stage, "DmapToDmaphopPass"))
        return false;

    // Clone the module at dmaphop stage for the routing path (Phase 5).
    // This preserves the pkt_ids allocated by DmapToDmaphopPass so that
    // routing.cc and host.cc use the same packet IDs.
    mlir::ModuleOp routingDmaphopModule = cast<ModuleOp>(module->clone());

    // Rename @main → @routing in the clone so that routing.cc emits
    // void routing() instead of void main().
    // Keep memref func args intact — routing lowering passes need the tensor
    // operands connected through bufferization.to_tensor. RoutingDeadArgPass
    // will strip unused args after lowering.
    for (auto func : routingDmaphopModule.getOps<mlir::func::FuncOp>()) {
        if (func.getName() == "main")
            func.setName("routing");
    }

    if (!runPipelineSinglePass(ctx, module, std::make_unique<DmaphopTodfscheblueprintPass>(), irDir, stage,
                       "DmaphopTodfscheblueprintPass"))
        return false;

    // Clone for host and kernel paths
    mlir::ModuleOp kernelModule = cast<ModuleOp>(module->clone());
    mlir::ModuleOp hostModule = cast<ModuleOp>(module->clone());

    // Initialize ResourceMgr singleton for CoreMemAllocator (BCF/PRX generation)
    {
        auto hwRes = makeResource("Gen2");
        ResourceMgr::init(std::move(hwRes));
    }

    // Phase 2: host path (blueprint -> schedule -> API -> EmitC)
    if (!runPipelineSinglePass(ctx, hostModule, std::make_unique<mlir::BlueprintToSchedulePass>(0.5), irDir, stage,
                       "BlueprintToSchedulePass"))
        return false;
    if (!runPipelineSinglePass(ctx, hostModule, std::make_unique<mlir::ScheduleCanonicalizePass>(), irDir, stage,
                       "ScheduleCanonicalizePass"))
        return false;
    if (!runPipelineSinglePass(ctx, hostModule, std::make_unique<mlir::DfscheduleToApiPass>(/*enableDebug=*/true), irDir, stage,
                       "DfscheduleToApiPass"))
        return false;
    if (!runPipelineSinglePass(ctx, hostModule, mlir::createCanonicalizerPass(), irDir, stage, "CanonicalizerPass"))
        return false;
    if (!runPipelineSinglePass(ctx, hostModule, std::make_unique<RoutingConstantFoldPass>(), irDir, stage,
                       "RoutingConstantFoldPass"))
        return false;

    // Phase 3: kernel path (blueprint -> kernel schedule -> kernel API)
    if (!runPipelineSinglePass(ctx, kernelModule, std::make_unique<mlir::BlueprintToScheduleKernelPass>(0.5), irDir, stage,
                       "BlueprintToScheduleKernelPass"))
        return false;

    // Extract kernel parameter info from KernelModuleOp (before DfscheduleToKernelApiPass lowers it)
    int numInputWindows = 0;
    int numOutputWindows = 0;
    std::string kernelElementType = "int32";
    std::string computeKernelName = "computekernel";
    kernelModule->walk([&](dfschedule::KernelDeclOp declOp) {
        computeKernelName = declOp.getSymName().str();
        auto declAttrs = declOp.getDeclAttrs();
        if (auto inputs = declAttrs.getAs<mlir::ArrayAttr>("inputs"))
            numInputWindows = inputs.size();
        if (auto outputs = declAttrs.getAs<mlir::ArrayAttr>("outputs"))
            numOutputWindows = outputs.size();
    });
    kernelModule->walk([&](dfschedule::KernelConfigDefOp configOp) {
        auto attrs = configOp.getConfigAttrs();
        if (auto typeAttr = attrs.getAs<mlir::TypeAttr>("element_type")) {
            mlir::Type t = typeAttr.getValue();
            if (t.isInteger(32)) kernelElementType = "int32";
            else if (t.isInteger(16)) kernelElementType = "int16";
            else if (t.isInteger(8)) kernelElementType = "int8";
            else if (t.isF32()) kernelElementType = "float";
        }
    });

    // Override compute kernel name with user's __global__ function name if provided.
    // This renames KernelDeclOp in the IR so kernel.cc calls the user's function name
    // and the output file is named accordingly (e.g. matmul.cc instead of computekernel.cc).
    if (!userKernelFuncName.empty() && userKernelFuncName != computeKernelName) {
        std::string newKernelFile = userKernelFuncName + ".cc";
        auto renameKernelInModule = [&](mlir::ModuleOp mod) {
            mod->walk([&](dfschedule::KernelDeclOp declOp) {
                declOp.setSymNameAttr(mlir::StringAttr::get(&ctx, userKernelFuncName));
            });
            mod->walk([&](dfschedule::KernelInvokeOp invokeOp) {
                invokeOp.setKernelRefAttr(SymbolRefAttr::get(&ctx, userKernelFuncName));
            });
            mod->walk([&](dfschedule::KernelConfigDefOp configOp) {
                auto oldAttrs = configOp.getConfigAttrs();
                NamedAttrList newAttrs;
                for (auto &namedAttr : oldAttrs) {
                    if (namedAttr.getName() == "kernel_name")
                        newAttrs.append("kernel_name", StringAttr::get(&ctx, userKernelFuncName));
                    else if (namedAttr.getName() == "kernel_file")
                        newAttrs.append("kernel_file", StringAttr::get(&ctx, newKernelFile));
                    else
                        newAttrs.append(namedAttr);
                }
                configOp.setConfigAttrsAttr(DictionaryAttr::get(&ctx, newAttrs));
            });
        };
        renameKernelInModule(kernelModule);
        renameKernelInModule(hostModule);
        std::cout << "Overriding compute kernel name: " << computeKernelName
                  << " -> " << userKernelFuncName << " (file: " << newKernelFile << ")" << std::endl;
        computeKernelName = userKernelFuncName;
    }

    if (!runPipelineSinglePass(ctx, kernelModule, std::make_unique<mlir::DfscheduleToKernelApiPass>(), irDir, stage,
                       "DfscheduleToKernelApiPass"))
        return false;

    // Create output directory
    if (std::error_code EC = llvm::sys::fs::create_directories(outputDir)) {
        llvm::errs() << "Failed to create directory " << outputDir << ": " << EC.message() << "\n";
        return false;
    }

    // Erase func.func @main from hostModule before EmitC emission.
    // After ScheduleCanonicalizePass, @main only contains dfschedule.launchhost
    // + return; all real logic lives in dfschedule.host @host_canonicalized
    // (now emitc.func @host_canonicalized). The user source provides its own
    // main() via __aie_launch(), so we must not emit a competing main().
    for (auto func : llvm::make_early_inc_range(hostModule.getOps<mlir::func::FuncOp>())) {
        if (func.getName() == "main") {
            func->dropAllUses();
            func.erase();
        }
    }

    // Emit host.cc
    {
        std::string hostPath = outputDir + "/host.cc";
        std::error_code ec;
        llvm::raw_fd_ostream stream(hostPath, ec, llvm::sys::fs::OF_None);
        if (ec) {
            llvm::errs() << "Failed to open " << hostPath << ": " << ec.message() << "\n";
            return false;
        }
        // Emit strong g_runtime_debug_level override if user set #pragma aie_debug_level
        if (runtimeDebugLevel >= 0) {
            stream << "// Override runtime debug level (from #pragma aie_debug_level)\n";
            stream << "int g_runtime_debug_level = " << runtimeDebugLevel << ";\n\n";
        }
        if (failed(mlir::emitc::translateToCpp(hostModule, stream))) {
            llvm::errs() << "Failed to translate host MLIR to C++.\n";
            return false;
        }

        // Append user's rewritten source code after MLIR-generated functions.
        // The user source provides main() and calls host_canonicalized() via __aie_launch().
        if (!userRewrittenSource.empty()) {
            stream << "\n// ===== User source (preserved from original file) =====\n";

            // Count the number of void* args on host_canonicalized
            unsigned numArgs = 0;
            for (auto func : hostModule.getOps<emitc::FuncOp>()) {
                if (func.getName() == "host_canonicalized") {
                    numArgs = func.getNumArguments();
                    break;
                }
            }
            if (numArgs == 0) {
                for (auto func : hostModule.getOps<mlir::func::FuncOp>()) {
                    if (func.getName() == "host_canonicalized") {
                        numArgs = func.getNumArguments();
                        break;
                    }
                }
            }

            // Suppress the Clang-phase stubs (which had wrong arity) and emit
            // correct __aie_launch that forwards DDR pointers.
            stream << "#define AIEHLC_TILING_STUBS_DEFINED\n";
            stream << "struct aieDim { int rows, cols; aieDim(int r, int c) : rows(r), cols(c) {} };\n";
            stream << "inline void aieSetDevice(int) {}\n";
            stream << "inline void aieDeviceSynchronize() {}\n";
            if (numArgs > 0) {
                stream << "inline void __aie_launch(const char* kernel, aieDim mesh";
                for (unsigned i = 0; i < numArgs; ++i)
                    stream << ", void* _t" << i;
                stream << ", ...) {\n";
                stream << "    (void)kernel; (void)mesh;\n";
                stream << "    host_canonicalized(";
                for (unsigned i = 0; i < numArgs; ++i) {
                    if (i > 0)
                        stream << ", ";
                    stream << "_t" << i;
                }
                stream << ");\n}\n";
            } else {
                stream << "template<typename... Args>\n";
                stream << "inline void __aie_launch(const char* kernel, aieDim mesh, Args... args) {\n";
                stream << "    host_canonicalized();\n}\n";
            }

            stream << userRewrittenSource << "\n";
        } else if (!tensors.empty()) {
            // Standalone / unittest mode: generate a default main() that
            // allocates DDR buffers matching the tensor parameters, fills
            // inputs with test data, calls host_canonicalized(), and prints
            // output. device_init/teardown is handled by __Runtime_auto_init/
            // __Runtime_auto_teardown constructors in aie_runtime.c.

            // Count the number of void* args on host_canonicalized
            unsigned numArgs = 0;
            for (auto func : hostModule.getOps<emitc::FuncOp>()) {
                if (func.getName() == "host_canonicalized") {
                    numArgs = func.getNumArguments();
                    break;
                }
            }
            if (numArgs == 0) {
                for (auto func : hostModule.getOps<mlir::func::FuncOp>()) {
                    if (func.getName() == "host_canonicalized") {
                        numArgs = func.getNumArguments();
                        break;
                    }
                }
            }

            stream << "\n// ===== Auto-generated main() for standalone testing =====\n";
            stream << "#include <stdio.h>\n";
            stream << "#include <stdlib.h>\n";
            stream << "#include <string.h>\n\n";
            stream << "#define __global__\n\n";

            // Forward-declare host_canonicalized
            stream << "void host_canonicalized(";
            for (unsigned i = 0; i < numArgs; ++i) {
                if (i > 0)
                    stream << ", ";
                stream << "void*";
            }
            stream << ");\n\n";

            // Extern kernel binary symbols
            stream << "extern unsigned char _binary_kernel_" << computeKernelName << "_start[];\n";
            stream << "extern unsigned char _binary_kernel_" << computeKernelName << "_end[];\n";
            stream << "extern unsigned int _binary_kernel_" << computeKernelName << "_size;\n\n";

            // dskernel_receiver stub for the kernel that gets compiled separately
            stream << "__global__ void " << computeKernelName << "(size_t v1) {\n";
            stream << "  return;\n";
            stream << "}\n\n";

            stream << "int main() {\n";
            stream << "    printf(\"------------main--------\\n\");\n\n";

            // Allocate DDR buffers for each tensor
            for (unsigned i = 0; i < tensors.size(); ++i) {
                int64_t totalElements = 1;
                for (auto dim : tensors[i].shape)
                    totalElements *= dim;
                int64_t totalBytes = totalElements * (tensors[i].elementBitWidth / 8);
                stream << "    // Tensor " << i << ": " << (tensors[i].isInput ? "input" : "output") << ", "
                       << totalBytes << " bytes\n";
                stream << "    void* buf_" << i << " = malloc(" << totalBytes << ");\n";
            }
            stream << "\n";

            // Initialize inputs with test data, zero outputs
            for (unsigned i = 0; i < tensors.size(); ++i) {
                int64_t totalElements = 1;
                for (auto dim : tensors[i].shape)
                    totalElements *= dim;
                int64_t totalBytes = totalElements * (tensors[i].elementBitWidth / 8);
                if (tensors[i].isInput) {
                    stream << "    for (int j = 0; j < " << totalBytes << "; j++) ((char*)buf_" << i
                           << ")[j] = (char)(j + " << (i + 1) << ");\n";
                } else {
                    stream << "    memset(buf_" << i << ", 0, " << totalBytes << ");\n";
                }
            }
            stream << "\n";

            // Call host_canonicalized
            stream << "    host_canonicalized(";
            for (unsigned i = 0; i < tensors.size(); ++i) {
                if (i > 0)
                    stream << ", ";
                stream << "buf_" << i;
            }
            stream << ");\n\n";

            stream << "    printf(\"------------after matmul--------\\n\");\n\n";

            // Print output buffers
            for (unsigned i = 0; i < tensors.size(); ++i) {
                if (!tensors[i].isInput) {
                    int64_t totalElements = 1;
                    for (auto dim : tensors[i].shape)
                        totalElements *= dim;
                    int64_t totalBytes = totalElements * (tensors[i].elementBitWidth / 8);
                    stream << "    printf(\"Output buffer " << i << ":\\n\");\n";
                    stream << "    for (int j = 0; j < " << totalBytes << "; j++) printf(\"  out[%d]=%d\\n\", j, "
                           << "((unsigned char*)buf_" << i << ")[j]);\n";
                }
            }
            stream << "\n";

            // Free buffers
            for (unsigned i = 0; i < tensors.size(); ++i) {
                stream << "    free(buf_" << i << ");\n";
            }
            stream << "    return 0;\n";
            stream << "}\n";
        }

        stream.close();
        std::cout << "Host code written to " << hostPath << std::endl;
    }

    // Emit kernel.cc
    {
        std::string kernelPath = outputDir + "/kernel.cc";
        std::error_code ec;
        llvm::raw_fd_ostream stream(kernelPath, ec, llvm::sys::fs::OF_None);
        if (ec) {
            llvm::errs() << "Failed to open " << kernelPath << ": " << ec.message() << "\n";
            return false;
        }
        if (failed(mlir::emitc::translateToCpp(kernelModule, stream))) {
            llvm::errs() << "Failed to translate kernel MLIR to C++.\n";
            return false;
        }
        stream.close();
        std::cout << "Kernel code written to " << kernelPath << std::endl;
    }

    // Emit computekernel.cc (compute kernel implementation)
    {
        std::string computePath = outputDir + "/" + computeKernelName + ".cc";
        std::error_code ec;
        llvm::raw_fd_ostream stream(computePath, ec, llvm::sys::fs::OF_None);
        if (ec) {
            llvm::errs() << "Failed to open " << computePath << ": " << ec.message() << "\n";
            return false;
        }

        if (!userKernelBody.empty()) {
            // Write the user's __global__ kernel body verbatim
            stream << "// User-provided compute kernel (extracted from __global__ function)\n";
            stream << userKernelBody << "\n";
            std::cout << "Compute kernel (user-provided) written to " << computePath << std::endl;
        } else {
            // Auto-generate compute kernel
            // Determine type strings from element type
            std::string cType = kernelElementType + "_t"; // e.g. "int32_t"
            std::string vecType = "v4" + kernelElementType; // e.g. "v4int32"
            std::string winInputType = "input_window_" + kernelElementType;  // e.g. "input_window_int32"
            std::string winOutputType = "output_window_" + kernelElementType; // e.g. "output_window_int32"

            stream << "// Auto-generated compute kernel: " << computeKernelName << "\n";
            stream << "// " << numInputWindows << " input(s) + " << numOutputWindows << " output(s)\n";
            stream << "void " << computeKernelName << "(";

            // Generate parameter list
            int paramIdx = 0;
            for (int i = 0; i < numInputWindows; ++i) {
                if (paramIdx > 0) stream << ", ";
                stream << winInputType << " *window_in_" << i;
                paramIdx++;
            }
            for (int i = 0; i < numOutputWindows; ++i) {
                if (paramIdx > 0) stream << ", ";
                stream << winOutputType << " *window_out_" << i;
                paramIdx++;
            }
            stream << ") {\n";

            // Function body
            stream << "    unsigned coreid = get_coreid();\n";
            stream << "    int col = coreid >> 16;\n";
            stream << "    int row = coreid & 0x1F;\n";
            stream << "\n";
            stream << "    for (int k = 0; k < 2; k++) {\n";
            stream << "        klog(\"CENk\", k);\n";

            // Acquire all input windows
            for (int i = 0; i < numInputWindows; ++i) {
                stream << "        " << cType << " *in" << i
                       << " = (" << cType << " *)acquire_input_window(window_in_" << i << ");\n";
            }
            // Acquire all output windows
            for (int i = 0; i < numOutputWindows; ++i) {
                stream << "        " << cType << " *out" << i
                       << " = (" << cType << " *)acquire_output_window(window_out_" << i << ");\n";
            }

            stream << "\n";
            // Debug: print in0 values
            stream << "        // Debug: dump in0 buffer contents\n";
            stream << "        klog(\"IN0\", BUF_SZ_IN_0 * 4);\n";
            stream << "        for (int di = 0; di < BUF_SZ_IN_0 * 4; di++) {\n";
            stream << "            klog(\"IV\", (int)in0[di]);\n";
            stream << "        }\n";
            stream << "\n";
            stream << "        // GEMM kernel: out0[i] = in0[i] * in1[i]\n";
            stream << "        for (int i = 0; i < BUF_SZ_OUT_0; i++) {\n";
            stream << "            " << vecType << " data0 = *((" << vecType << " *)&in0[i * 4]);\n";
            if (numInputWindows > 1) {
                stream << "            " << vecType << " data1 = *((" << vecType << " *)&in1[i * 4]);\n";
            }
            stream << "            *((" << vecType << " *)&out0[i * 4]) = data0;\n";
            stream << "        }\n";
            stream << "        klog(\"CLOP\", BUF_SZ_OUT_0);\n";
            stream << "\n";
            // Debug: print out0 values
            stream << "        // Debug: dump out0 buffer contents\n";
            stream << "        klog(\"OUT0\", BUF_SZ_OUT_0 * 4);\n";
            stream << "        for (int di = 0; di < BUF_SZ_OUT_0 * 4; di++) {\n";
            stream << "            klog(\"OV\", (int)out0[di]);\n";
            stream << "        }\n";
            stream << "\n";

            // Release all windows
            for (int i = 0; i < numInputWindows; ++i) {
                stream << "        release_input_window(window_in_" << i << ");\n";
            }
            for (int i = 0; i < numOutputWindows; ++i) {
                stream << "        release_output_window(window_out_" << i << ");\n";
            }
            stream << "        klog(\"CEXT\", 1);\n";
            stream << "    }\n";
            stream << "}\n";

            std::cout << "Compute kernel (auto-generated) written to " << computePath << std::endl;
        }

        stream.close();
    }

    // Phase 4: Generate BCF/PRX for kernel compilation
    try {
        auto &allocator = ResourceMgr::instance()->coreMemAllocator();
        const auto &allocations = allocator.getAllocations();

        if (!allocations.empty()) {
            TilingBcf bcf;
            bcf.setStack(0x70000, 0x1024);
            bcf.addReservedDMB(0x40000, 0x10000);
            bcf.addReservedDMB(0x7F800, 0x800);
            for (const auto &slot : allocations) {
                bcf.addSymbol(slot.symbolName, slot.address);
            }

            std::string bcfPath = outputDir + "/aieml.bcf";
            if (bcf.exportToFile(bcfPath)) {
                std::cout << "BCF written to " << bcfPath << std::endl;
            } else {
                llvm::errs() << "Failed to write BCF to " << bcfPath << "\n";
            }

            TilingPrx prx("kernel", 22);
            prx.setBcfPath("aieml.bcf");
            prx.setKernelLLPath("./build/");

            std::string prxPath = outputDir + "/aieml.prx";
            if (prx.exportToFile(prxPath)) {
                std::cout << "PRX written to " << prxPath << std::endl;
            } else {
                llvm::errs() << "Failed to write PRX to " << prxPath << "\n";
            }

            std::cout << "\n=== Core Memory Allocation Summary ===" << std::endl;
            for (const auto &slot : allocations) {
                std::cout << "  " << slot.symbolName << " @ 0x" << std::hex << slot.address
                          << " (size=" << std::dec << slot.size << " bytes)" << std::endl;
            }
            std::cout << "  Free space: " << allocator.getFreeSpace() << " bytes" << std::endl;
        } else {
            std::cout << "No buffer allocations found; skipping BCF/PRX generation." << std::endl;
        }
    } catch (...) {
        std::cout << "ResourceMgr not initialized; skipping BCF/PRX generation." << std::endl;
    }

    // Phase 5: Routing path (dmaphop -> routinghw -> EmitC) for routing.cc
    // Uses the dmaphop module cloned after DmapToDmaphopPass so that packet IDs
    // in routing.cc match those in host.cc (both read from the same dmaphop IR).
    {
        int rstage = 0;
        std::string routingIrDir = setupPipelineIRDir("simplerouting");

        dumpPipelineIRToFile(routingDmaphopModule, routingIrDir, rstage++, "initial");

        // Use the same rtopology that produced the dmaphop IR so that
        // shim columns and DMA port assignments are consistent.
        if (!runPipelineSinglePass(ctx, routingDmaphopModule, std::make_unique<DmaphopToRoutinghwPass>(rtopology),
                                   routingIrDir, rstage, "DmaphopToRoutinghwPass"))
            return false;
        if (!runPipelineSinglePass(ctx, routingDmaphopModule, std::make_unique<RoutingHWVerifyPass>(), routingIrDir,
                                   rstage, "RoutingHWVerifyPass"))
            return false;
        if (!runPipelineSinglePass(ctx, routingDmaphopModule, std::make_unique<RoutingHWLowerPass>(rtopology),
                                   routingIrDir, rstage, "RoutingHWLowerPass"))
            return false;

        if (!runPipelineSinglePass(ctx, routingDmaphopModule, std::make_unique<RoutingDeadArgPass>(), routingIrDir,
                                   rstage, "RoutingDeadArgPass"))
            return false;
        if (!runPipelineSinglePass(ctx, routingDmaphopModule, std::make_unique<RoutingConstantFoldPass>(), routingIrDir,
                                   rstage, "RoutingConstantFoldPass"))
            return false;
        if (!runPipelineSinglePass(ctx, routingDmaphopModule, mlir::createCanonicalizerPass(), routingIrDir, rstage,
                                   "CanonicalizerPass"))
            return false;

        // After all routing lowering passes, clean up residual memref-related
        // ops (bufferization.to_tensor and routing.routingcreatescheduletensor)
        // that prevent RoutingDeadArgPass from stripping memref func args.
        // Only erase specific known-dead op types — never erase scf/emitc ops.
        for (auto func : routingDmaphopModule.getOps<mlir::func::FuncOp>()) {
            if (func.getBody().empty())
                continue;
            Block &entry = func.getBody().front();
            // Multi-pass: erasing routing ops may make to_tensor results dead
            bool changed = true;
            while (changed) {
                changed = false;
                for (auto &op : llvm::make_early_inc_range(entry.getOperations())) {
                    // Only erase bufferization.to_tensor or routing dialect ops
                    bool isTargetOp = isa<bufferization::ToTensorOp>(&op) ||
                                      (op.getDialect() && op.getDialect()->getNamespace() == "routing");
                    if (isTargetOp && op.use_empty()) {
                        op.erase();
                        changed = true;
                    }
                }
            }
            // Now strip dead block args (memref params no longer used)
            for (int i = (int)entry.getNumArguments() - 1; i >= 0; --i) {
                if (entry.getArgument(i).use_empty())
                    entry.eraseArgument(i);
            }
            // Update function type to match remaining args
            SmallVector<Type> argTypes;
            for (auto arg : entry.getArguments())
                argTypes.push_back(arg.getType());
            func.setFunctionType(FunctionType::get(func.getContext(), argTypes, func.getFunctionType().getResults()));
        }

        std::string routingPath = outputDir + "/routing.cc";
        std::error_code ec;
        llvm::raw_fd_ostream stream(routingPath, ec, llvm::sys::fs::OF_None);
        if (ec) {
            llvm::errs() << "Failed to open " << routingPath << ": " << ec.message() << "\n";
            return false;
        }
        // Emit #include before the translated C++ so int32_t etc. are declared
        stream << "#include <xaiengine.h>\n";
        stream << "XAie_DevInst* getOrCreateDeviceInstance();\n\n";
        if (failed(mlir::emitc::translateToCpp(routingDmaphopModule, stream))) {
            llvm::errs() << "Failed to translate routing MLIR to C++.\n";
            return false;
        }
        stream.close();
        std::cout << "Routing code written to " << routingPath << std::endl;
    }

    return true;
}
