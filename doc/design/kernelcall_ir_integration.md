# Kernel Call IR Integration: From User C++ to AIE Execution

## Overview

This document describes how user-written kernel code travels from a C++ source file through the aiehlc compiler and MLIR pipeline to become executable code running on AIE cores. The process has four key phases:

1. **aiehlc parses `__global__` and captures kernel code** -- Clang AST extracts the kernel body
2. **IR auto-generates kernel load/launch ops from data-move patterns** -- `BlueprintToSchedulePass` creates `load_kernel_group` + `launch_kernel_group`
3. **aiehlc's `__aie_launch` glue sets kernel ELF** -- the generated glue function binds the compiled kernel binary to the runtime
4. **dfscheblueprint auto-generates kernel config from data flow** -- `BlueprintToSchedulePass` + `BlueprintToScheduleKernelPass` derive kernel parameters from DMA flow structure

## Architecture Diagram

```
User Source (.cc)
  |
  |  Phase 1: Clang AST
  |  aiehlc.cc
  v
+------------------+     +-----------------------+
| __global__ body  |---->| computekernel.cc      | --> xchesscc --> kernel ELF
| (captured text)  |     | (verbatim user code)  |
+------------------+     +-----------------------+
  |
  |  <<<mesh>>> rewriting
  v
+------------------+     +-------------------------+
| __aie_launch()   |---->| Phase 3: Glue function  |
| call in user src |     | in host.cc tail         |
+------------------+     | sets _binary_kernel_*   |
                         +-------------------------+
  |
  |  Phase 2 & 4: MLIR Pipeline
  v
+------------------+     +-------------------------+
| routing/dmap/    |---->| BlueprintToSchedulePass |
| dmaphop/         |     | creates load_kernel_    |
| dfscheblueprint  |     | group + launch_kernel_  |
| IR               |     | group ops               |
+------------------+     +--------+----------------+
                                  |
                         +--------v----------------+
                         | DfscheduleToApiPass     |
                         | emits __Runtime_load_   |
                         | kernel_group_Nt()       |
                         | + __Runtime_launch_     |
                         | kernel_group()          |
                         +--------+----------------+
                                  |
                                  v
                         +-------------------------+
                         | host.cc (pipeline part) |
                         | DMA BD + kernel load +  |
                         | launch + wait           |
                         +-------------------------+
```

## Phase 1: Parsing `__global__` and Capturing Kernel Code

**Source:** `src/llvm/aiehlc.cc:167-298, 366-398`

### Detection

The `GlobalFunctionVisitor` AST consumer scans every function declaration for `__global__` or `__kernel__` annotations:

```cpp
// aiehlc.cc:366-368
for (auto attr : f->attrs()) {
    if (auto anno = clang::dyn_cast<clang::AnnotateAttr>(attr)) {
        if (anno->getAnnotation() == "__global__" || anno->getAnnotation() == "__kernel__") {
```

When found, three things happen:

### 1. Kernel body extraction (`ExportFunction`)

`aiehlc.cc:167-298` -- The function body is extracted as raw C++ text via `GetFuncText()`. The text undergoes cleanup:

- **`__attribute__` stripping** (lines 187-207): All `__attribute__((...))` annotations are removed since the kernel compiler doesn't need them.
- **`#ifdef KERNEL_COMPILE` guard removal** (lines 213-234): Preprocessor guards added during source inclusion are stripped.
- **Spatial type wrapper unwrapping** (lines 236-258): Wrappers like `aie::row_broadcast_in<input_window_int8 *>` are reduced to `input_window_int8 *` since the kernel compiler only sees raw window types.
- **`aie::port<T, Policy>` stripping** (lines 260-292): Port wrappers are reduced to their inner type `T`.

The cleaned body is stored in two places:

```cpp
// aiehlc.cc:295-297
userKernelFuncName = kname;
userKernelBody = str;
globalKernelBodies[kname] = str;  // per-kernel map for multi-kernel support
```

### 2. Source removal and extern declaration

The original function body is removed from the user source (`Rewrite->RemoveText()`), and an `extern` declaration for the embedded kernel binary is inserted:

```cpp
// aiehlc.cc:390-395
"extern unsigned char _binary_kernel_" + kernelName + "_start[];\n"
"extern unsigned char _binary_kernel_" + kernelName + "_end[];\n"
"extern unsigned int _binary_kernel_" + kernelName + "_size;\n"
```

These symbols come from the linker's `ld -r -b binary` embedding of the compiled kernel ELF.

### 3. MLIR definition creation

`Aiefrontend->createKernelDefinitionOp()` (line 388) creates an MLIR op representing the kernel signature, which downstream passes use to derive parameter counts and types.

### 4. Kernel body emission

Later, `tilinglinalg_pipeline.cpp:826-840` writes the stored `userKernelBody` to `computekernel.cc` (or `<kernelname>.cc`):

```cpp
// tilinglinalg_pipeline.cpp:836-839
if (!userKernelBody.empty()) {
    stream << "// User-provided compute kernel (extracted from __global__ function)\n";
    stream << userKernelBody << "\n";
}
```

If no `__global__` function exists, an auto-generated compute kernel is emitted (lines 842-879).

## Source Rewriting: `<<<mesh>>>` to `__aie_launch`

**Source:** `src/llvm/aiehlc.cc:1862-1903`

Before the Clang AST visit, aiehlc performs text-level source rewriting to transform CUDA-style kernel launch syntax into a regular function call:

```
matmul<<<mesh>>>(A, B, C, M, N, K)
   -->
__aie_launch("matmul", mesh, A, B, C, M, N, K)
```

The rewriting logic:

```cpp
// aiehlc.cc:1866-1898
while ((launchPos = SourceCodeString.find("<<<", launchPos)) != std::string::npos) {
    // Extract function name before <<<
    std::string funcName = SourceCodeString.substr(funcEnd, launchPos - funcEnd);
    // Extract mesh variable between <<< and >>>
    std::string meshVar = SourceCodeString.substr(meshStart, meshEnd - meshStart);
    // Extract args between ( and )
    std::string args = SourceCodeString.substr(argsOpenParen + 1, argsEnd - argsOpenParen - 1);
    // Build replacement
    std::string replacement = "__aie_launch(\"" + funcName + "\", " + meshVar + ", " + args + ")";
    SourceCodeString.replace(funcEnd, argsEnd + 1 - funcEnd, replacement);
}
```

A stub `__aie_launch` template is injected for initial AST parsing (lines 2012-2020). The real implementation is emitted later (see Phase 3).

### AST extraction from `__aie_launch`

After rewriting, the Clang AST visitor (`VisitCallExpr`) detects `__aie_launch` calls:

```cpp
// aiehlc.cc:513-514
if (Callee && Callee->getNameAsString() == "__aie_launch") {
    isTilingLinalgMode = true;
```

From the call arguments, it extracts:
- **Arg 0**: kernel name (string literal)
- **Arg 1**: mesh dimensions (`aieMesh` or `aieDim` — rows, cols, partition)
- **Args 2+**: tensor parameters matched against the `__global__` function's parameter list (line 656)
- **Extra args beyond kernel params**: dimension scalars (M, N, K) at line 722

## Phase 2: IR Auto-Generates Kernel Load/Launch from Data-Move Patterns

**Source:** `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp:1498-1530`

The `BlueprintToSchedulePass` converts `dfscheblueprint.flow_transfer` ops (which describe data movement between shim, mem, and core tiles) into executable schedule ops. As part of this conversion, it automatically generates kernel management ops derived entirely from the data-flow structure — no explicit kernel reference exists in the blueprint IR.

### Callee symbol creation

```cpp
// passblueprinttoschedule.cpp:1498-1500
SmallVector<Attribute> calleeAttrs;
calleeAttrs.push_back(SymbolRefAttr::get(rewriter.getContext(), "dskernel_receiver"));
```

All core tiles reference the same `@dskernel_receiver` callee symbol. The "compute0" symbol is used as the compute kernel arg:

```cpp
// passblueprinttoschedule.cpp:1502-1506
SmallVector<Attribute> computeKernelAttrs;
for (size_t i = 0; i < coreTiles.size(); ++i) {
    computeKernelAttrs.push_back(SymbolRefAttr::get(rewriter.getContext(), "compute0"));
}
```

### LoadKernelGroupOp

```cpp
// passblueprinttoschedule.cpp:1521-1526
auto loadKernelGroupOp = rewriter.create<dfschedule::LoadKernelGroupOp>(
    loc, dfschedule::KernelGroupType::get(rewriter.getContext()), coreTiles,
    rewriter.getArrayAttr(calleeAttrs),          // callee = @dskernel_receiver
    rewriter.getArrayAttr(computeKernelAttrs),   // compute = @compute0
    nullptr,                                     // kernel_config = nullptr
    rewriter.getArrayAttr(kernelConfigSymbols)); // distributed_args = [@kernelconfig0, ...]
```

This op carries:
- The list of core tiles to load kernels onto
- Callee symbol `@dskernel_receiver` (the kernel wrapper that handles window acquire/release)
- Compute kernel symbol `@compute0` (renamed to the user's `__global__` function name later)
- Per-tile kernel configs (`@kernelconfig0`, `@kernelconfig1`, ...) containing DMA BD parameters

### LaunchKernelGroupOp

```cpp
// passblueprinttoschedule.cpp:1528-1530
auto launchKernelGroupOp = rewriter.create<dfschedule::LaunchKernelGroupOp>(
    loc, dfschedule::EventType::get(rewriter.getContext()),
    loadKernelGroupOp.getKernelGroup());
```

This triggers execution of all loaded kernels and returns an event used for synchronization.

### Ordering: shim before kernel, core after kernel

The pass enforces a specific ordering to avoid BSS-zeroing races:

1. **Shim `start_io`** is emitted BEFORE `load_kernel_group` (line 1509-1519) — shim DMA channels are armed first
2. **`load_kernel_group`** loads the kernel ELF onto cores (line 1521-1526)
3. **`launch_kernel_group`** starts kernel execution (line 1528-1530)
4. **Core `start_io`** is emitted AFTER kernel launch (line 1532-1541) — prevents core DMA from writing to buffers that ELF loading would zero

### Wait synchronization

```cpp
// passblueprinttoschedule.cpp:1547-1550
SmallVector<Value> events;
events.push_back(launchKernelGroupOp.getEvent());  // kernel completion
events.push_back(startIoOp.getEvent());             // shim DMA completion
rewriter.create<dfschedule::ScheduleWaitOp>(loc, events);
```

Core tile IO events are excluded because core DMAs use infinite ping-pong BD chaining (BD0->BD1->BD0->...) and `wait_io` would never return.

### Lowering to C API

`DfscheduleToApiPass` (`passdfscheduletoapi.cpp:1854-2044`) converts these ops to runtime calls:

```
LoadKernelGroupOp  -->  __Runtime_load_kernel_group_4t / _8t / _16t
LaunchKernelGroupOp --> __Runtime_launch_kernel_group
```

The `_4t/_8t/_16t` suffix is selected based on tile count with zero-padding for unused slots (lines 1971-1986).

## Phase 3: `__aie_launch` Glue Sets Kernel ELF

**Source:** `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.cpp:612-658` (single-kernel), `src/llvm/aiehlc.cc:2279-2440` (multi-kernel)

After the MLIR pipeline produces `host.cc` (containing DMA configuration and kernel load/launch), the compiler appends a C++ glue function that bridges the user's `__aie_launch()` call to the pipeline-generated `host_canonicalized()` function.

### Single-kernel path (`tilinglinalg_pipeline.cpp`)

```cpp
// tilinglinalg_pipeline.cpp:632
stream << "    __Runtime_set_kernel_elf(_binary_kernel_" << computeKernelName << "_start);\n";
stream << "    " << hostFuncName << "(dev";
```

The generated glue function:

```cpp
// Generated in host.cc (conceptual):
inline void __aie_launch(const char* kernel, aieMesh mesh, void* _t0, void* _t1, ...) {
    XAie_DevInst* dev;
    if (__Runtime_partition_is_initialized(mesh.meshId)) {
        dev = __Runtime_get_partition_dev(mesh.meshId);
    } else {
        dev = __Runtime_explicit_init_partition(mesh.partition.startCol, ...);
        __Runtime_register_partition(mesh.meshId, dev);
    }
    __Runtime_set_kernel_elf(_binary_kernel_matmul_start);  // <-- binds kernel ELF
    host_canonicalized(dev, _t0, _t1, ...);                 // <-- calls pipeline output
}
```

Key points:
- `__Runtime_set_kernel_elf()` stores the kernel ELF pointer in a global that `__Runtime_load_kernel_group` uses when calling `XAie_LoadElfMem()` on each core tile
- `_binary_kernel_<name>_start` is a linker-generated symbol from `ld -r -b binary kernel.elf`
- The partition init/registry pattern supports multi-mesh programs where each `<<<mesh>>>` call may target a different AIE partition

### Multi-kernel path (`aiehlc.cc`)

For programs with multiple `__global__` kernels, `aiehlc.cc:2365-2438` generates a unified `__aie_launch` with `strcmp` dispatch:

```cpp
// Generated (conceptual):
inline void __aie_launch(const char* kernel, aieMesh mesh, void* _t0, ...) {
    if (strcmp(kernel, "matmul") == 0) {
        XAie_DevInst* dev = __Runtime_explicit_init_partition(...);
        __Runtime_set_kernel_elf(_binary_kernel_matmul_start);
        host_canonicalized_matmul(dev, _t0, ...);
        __Runtime_explicit_teardown(dev);
    } else if (strcmp(kernel, "relu") == 0) {
        // ... dispatch to relu's host_canonicalized
    }
}
```

Each kernel gets its own `host_canonicalized_<name>` function (from its own pipeline run) and its own `_binary_kernel_<name>_start` symbol.

## Phase 4: Auto-Generating Kernel Config from Data Flow

### Host-side: `dskernel_receiver` symbol declaration

**Source:** `passblueprinttoschedule.cpp:1557-1575`

After creating the load/launch ops, the pass generates a `dskernel_receiver` function symbol in the module:

```cpp
// passblueprinttoschedule.cpp:1557-1575
StringRef kernelName = "dskernel_receiver";
if (!hasDSKernelReceiver(op.getOperation(), kernelName)) {
    RankedTensorType kernelTensorType;
    // ... derive tensor type from flow's view type
    if (kernelTensorType) {
        generateDSKernelReceiver(rewriter, loc, op.getOperation(), kernelName,
                                 kernelTensorType, bufferLen,
                                 basePacketId, coreChannel, flowIndex);
    }
}
```

The generated `DSKernelReceiverOp` is a declaration with an empty body (lines 235-237). The actual kernel configuration is filled in by `BlueprintToScheduleKernelPass` running on the kernel module clone.

### Kernel-side: window and buffer configuration

**Source:** `passblueprinttoschedulekernel.cpp:780-879`

`BlueprintToScheduleKernelPass` derives kernel parameters from the same `dfscheblueprint.flow_config` and `dfscheblueprint.flow_transfer` ops:

1. **Element type** from flow config's view tensor type (line 792)
2. **Partition size** from the flow's view shape (lines 794-797)
3. **Per-core data size** depends on transfer type:
   - `one_to_many` (broadcast/input): full partition per core (line 809)
   - `many_to_one` (gather/output): `partitionSize / numCoreTiles` (lines 810-811)
4. **Ping-pong buffer size** from `pp_depth` attribute or derived from `bufferRatio` (lines 813-834)
5. **numRounds** = `perCoreSize / pingPongBufSize` (line 840-841)
6. **K-round multiplication**: for input tensors when `routing.k_rounds > 1`, `numRounds *= kRounds` (lines 849-856)

These parameters flow into `KernelDeclOp`, `KernelWindowOp`, and `KernelConfigDefOp`, which `DfscheduleToKernelApiPass` lowers into kernel-side C code (`kernel.cc`) with `window_init()`, `window_acquire()`, `window_release()`, and compute kernel invocation.

### Kernel name renaming

**Source:** `tilinglinalg_pipeline.cpp:386-404`

After `BlueprintToScheduleKernelPass`, the default compute kernel name (`computekernel` or `compute0`) is overridden with the user's `__global__` function name:

```cpp
// tilinglinalg_pipeline.cpp:389-397
if (!userKernelFuncName.empty() && userKernelFuncName != computeKernelName) {
    mod->walk([&](dfschedule::KernelDeclOp declOp) {
        declOp.setSymNameAttr(mlir::StringAttr::get(&ctx, userKernelFuncName));
    });
    mod->walk([&](dfschedule::KernelInvokeOp invokeOp) {
        invokeOp.setKernelRefAttr(SymbolRefAttr::get(&ctx, userKernelFuncName));
    });
}
```

This ensures `kernel.cc` calls the user's function by name, and the output compute kernel file is named accordingly (e.g., `matmul.cc`).

## Final File Assembly

The complete output consists of three files compiled and linked into the host ELF:

### 1. `host.cc` (pipeline-generated + user source + glue)

```
[Pipeline EmitC output]          -- DMA BD config, kernel load/launch, I/O, wait
[User rewritten source]          -- original main() with <<<mesh>>> replaced by __aie_launch()
[__aie_launch glue function]     -- binds kernel ELF, calls host_canonicalized()
[Type/struct definitions]        -- aieMesh, aieDim, aiePartition, aieSetDevice, etc.
[extern _binary_kernel_* decls]  -- linker symbols for embedded kernel ELFs
```

### 2. `kernel.cc` (pipeline-generated)

```
[Window declarations]            -- input_window/output_window setup
[Acquire/release sequences]      -- window_acquire(), window_release() with lock IDs
[Compute kernel invocation]      -- calls user's __global__ function through dskernel_receiver
[K-round loop]                   -- outer loop when effectiveK < K
```

### 3. `<kernelname>.cc` (user code, extracted verbatim)

```
[User's __global__ function body] -- cleaned of annotations, spatial wrappers, port types
```

### Compilation and linking

```
<kernelname>.cc --> xchesscc --> xchessmk --> kernel.elf
kernel.elf      --> ld -r -b binary        --> kernel.o  (_binary_kernel_<name>_start symbol)
kernel.cc       --> xchesscc               --> kernel driver object
host.cc         --> aarch64-g++            --> host object
routing.cc      --> aarch64-g++            --> routing object
all objects     --> aarch64-g++ link        --> host ELF (final executable)
```

## Data Flow Summary

```
User C++ source
    |
    |-- [__global__ body] ---------> computekernel.cc ----> kernel ELF (xchesscc)
    |                                                           |
    |-- [<<<mesh>>> syntax] -------> __aie_launch() call        |
    |                                    |                      |
    |                                    v                      v
    |                            __aie_launch glue:    _binary_kernel_*_start
    |                            __Runtime_set_kernel_elf()     |
    |                                    |                      |
    v                                    v                      |
MLIR Pipeline                    host_canonicalized()           |
    |                                    |                      |
    |-- BlueprintToSchedulePass          |                      |
    |   creates:                         |                      |
    |   - load_kernel_group -----> __Runtime_load_kernel_group_Nt()
    |   - launch_kernel_group ---> __Runtime_launch_kernel_group()
    |   - dskernel_receiver              |                      |
    |                                    v                      v
    |-- BlueprintToScheduleKernelPass    |    XAie_LoadElfMem(dev, tile, _binary_kernel_*_start)
    |   creates:                         |
    |   - kernel_decl                    |
    |   - kernel_window (from flow)      |
    |   - kernel_config (from BD params) |
    |        |                           |
    |        v                           |
    |   kernel.cc                   host.cc
    |   (window driver)           (DMA + kernel + I/O)
    |                                    |
    +------------------------------------+----> Final host ELF
```

## Key Design Principles

1. **Kernel code is opaque to the IR pipeline.** The MLIR pipeline never inspects or transforms the kernel function body. It only generates the *wrapper* (window management, lock protocol) and *host-side orchestration* (ELF loading, launch, synchronization).

2. **Kernel parameters are derived from data flow, not kernel signatures.** Buffer sizes, ping-pong depths, lock IDs, and iteration counts are all computed from the `dfscheblueprint` flow structure (partition sizes, transfer types, tile counts). The kernel function's parameter types only affect element type selection.

3. **The `__aie_launch` glue bridges two independent outputs.** The MLIR pipeline produces `host_canonicalized()` with all DMA/kernel/IO logic. The `__aie_launch` glue connects this to the user's call site and binds the kernel ELF, without either side knowing about the other's implementation details.

4. **Name binding is late.** The kernel function name flows through several stages: captured as `userKernelFuncName` during AST visit, used to name the output file, and injected into kernel IR ops via `KernelDeclOp` renaming after the kernel pass completes. This allows the pipeline to work with generic names (`computekernel`, `compute0`, `dskernel_receiver`) internally.
