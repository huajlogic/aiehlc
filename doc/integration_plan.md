# Integration Plan: proposal3.cc → aiehlc → tilinglinalg → worklocal outputs

## Overview

Make `aiehlc proposal3.cc` parse the CUDA-style C++ code and run the full tilinglinalg pipeline to produce `host.cc`, `kernel.cc`, `routing.cc`, `aieml.bcf`, `aieml.prx` in `worklocal/`.

## Current Architecture Gap

**aiehlc binary** links `mlirtestlib` which contains:
- `AieFrontEnd.cc` — Clang AST → AIE MLIR
- `AieDialect.cc` — single-tile AIE ops
- `aiehybrid.cc` — HybridPass → BCF/PRX/wrapper.cc for single-tile
- `routingmanager.cpp` — already included! (builds routing IR)

**BUT** `mlirtestlib` does NOT include:
- The 15 lowering passes (only in `unitest/test` binary)
- The 6 dialect managers (dmap, dmaphop, dfschedule, dfscheblueprint, routinghw)
- `ResourceManager`, `routingtopology`, `routingpath`
- `kernelconfig` (TilingBcf, TilingPrx)

These ~20 source files exist only in `unitest/CMakeLists.txt` SOURCE_FILES.

## Step-by-Step Plan

---

### Step 1: Create `TilingLinalgPipeline` — a reusable pipeline class

**Purpose**: Extract the logic from `test.cpp:routingtodfschedule()` (lines 838-1010) into a reusable class that both `aiehlc` and `unitest/test` can call.

**New files**:
- `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h`
- `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.cpp`

**Content** (extracted from `test.cpp:838-1010` almost verbatim):

```cpp
// tilinglinalg_pipeline.h
#pragma once
#include "mlir/IR/BuiltinOps.h"
#include <string>
#include <vector>

struct TensorParam {
    std::vector<int64_t> shape;  // e.g. {16, 16}
    int elementBitWidth;         // e.g. 32 for int32_t
    bool isInput;                // true = input, false = output
};

class TilingLinalgPipeline {
public:
    /// Register all 6 dialect managers + standard dialects on ctx
    static void registerDialects(mlir::MLIRContext &ctx);

    /// Build initial routing IR (parameterized version of ops_testNew)
    /// meshRows/meshCols -> createhwmesh
    /// tensors -> createscheduletensor + createroutingfuncByDim for each
    static mlir::ModuleOp buildRoutingIR(
        mlir::MLIRContext &ctx,
        int meshRows, int meshCols,
        llvm::ArrayRef<TensorParam> tensors);

    /// Run the full 15-pass pipeline and emit files to outputDir:
    ///   host.cc, kernel.cc, routing.cc, aieml.bcf, aieml.prx
    /// Returns true on success.
    static bool runPipeline(
        mlir::MLIRContext &ctx,
        mlir::ModuleOp module,
        const std::string &outputDir);
};
```

**Implementation** (`tilinglinalg_pipeline.cpp`):

1. **`registerDialects()`** — copy lines 843-862 from `routingtodfschedule()`:
   ```cpp
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
   ctx.getOrLoadDialect<arith::ArithDialect>();
   ctx.getOrLoadDialect<func::FuncDialect>();
   ctx.getOrLoadDialect<memref::MemRefDialect>();
   ctx.getOrLoadDialect<scf::SCFDialect>();
   ctx.getOrLoadDialect<tensor::TensorDialect>();
   ctx.getOrLoadDialect<bufferization::BufferizationDialect>();
   ctx.getOrLoadDialect<emitc::EmitCDialect>();
   ```

2. **`buildRoutingIR()`** — parameterize `ops_testNew()` (lines 294-341 from `routingmanager.cpp`):
   - Replace hardcoded `hwrowused=2, hwcolused=2` -> use `meshRows, meshCols`
   - Replace hardcoded `shapeVec = {16, 16}` -> use `tensors[i].shape`
   - Replace hardcoded `builder.getI8Type()` -> use `builder.getIntegerType(tensors[i].elementBitWidth)`
   - Replace hardcoded `true` (input) -> use `tensors[i].isInput`
   - For each tensor: call `createroutingfuncByDim(builder, ctx, isInput, mesh, tensor, meshRows, "row")`

3. **`runPipeline()`** — copy lines 866-1010 from `routingtodfschedule()` exactly, but:
   - Remove `mtest.ops_testNew(&ctx, 1)` call (module is passed in)
   - Replace hardcoded `cwdPath + "/../worklocal"` with `outputDir` parameter
   - Keep all pass invocations exactly as-is
   - Keep BCF/PRX generation exactly as-is
   - Also run the routing path (call `routingtoroutinghw()` logic) to emit `routing.cc`

Includes needed (copy from `test.cpp` lines 1-46):
```cpp
#include "passblueprinttoschedule.h"
#include "passblueprinttoschedulekernel.h"
#include "passdfscheduletoapi.h"
#include "passdfscheduletokernelapi.h"
#include "passdmaphoptodfscheblueprint.h"
#include "passdmaphoptoroutinghw.h"
#include "dmaptodmaphop.h"
#include "routingtodmap.h"
#include "passschedulecanonicalize.h"
#include "routinghwlower.h"
#include "routinglower.h"
#include "routingunrolling.h"
#include "routingdeadargclean.h"
#include "routingconstantfold.h"
#include "kernelconfig.h"
#include "hw/ResourceManager.h"
```

---

### Step 2: Add all tilinglinalg sources to `mlirtestlib`

**File**: `src/mlir/mlirfront/CMakeLists.txt` (line 109-116)

**Current** `SOURCE_LIB_FILES`:
```cmake
set(SOURCE_LIB_FILES ./AieFrontEnd.cc)
list(APPEND SOURCE_LIB_FILES ./AieDialect.cc)
list(APPEND SOURCE_LIB_FILES ./AieLinkDialect.cpp)
list(APPEND SOURCE_LIB_FILES ./mlirpass/aiehybrid.cc)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/tilinglinalg.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/tilingpass.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/routing/routingmanager.cpp)
```

**Add** (copy from `unitest/CMakeLists.txt` lines 88-112, adjusted paths):
```cmake
# tilinglinalg pass pipeline sources
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/routinghw/routinghwmanager.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/dataflowmap/dmap/dmapmanager.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/dataflowmap/dmaphop/dmaphopmanager.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/dataflowmap/dfschedule/dfschedulemanager.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/dataflowmap/dfscheblueprint/dfscheblueprintmanager.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routinghwlower.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routinglower.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingunrolling.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingdeadargclean.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingconstantfold.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passroutingtodmap/routingtodmap.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passdmaptodmaphop/dmaptodmaphop.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passdmaphoptoroutinghw/passdmaphoptoroutinghw.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passblueprinttoschedulekernel/passblueprinttoschedulekernel.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passdmaphoptodfscheblueprint/passdmaphoptodfscheblueprint.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passschedulecanonicalize/passschedulecanonicalize.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passdfscheduletoapi/passdfscheduletoapi.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/passdfscheduletokernelapi/passdfscheduletokernelapi.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingimplement/routing/routingpath.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingimplement/hw/hwresource.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingimplement/hw/ResourceManager.cpp)
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/routingimplement/routing/routingtopology.cpp)
# The new pipeline wrapper
list(APPEND SOURCE_LIB_FILES ./tilinglinalg/pass/tilinglinalg_pipeline.cpp)
```

Also add include directories (copy from `unitest/CMakeLists.txt` lines 61-83):
```cmake
include_directories(./tilinglinalg/pass/routingimplement/include/)
include_directories(./tilinglinalg/pass/passroutingtodmap/)
include_directories(./tilinglinalg/pass/passblueprinttoschedule/)
include_directories(./tilinglinalg/pass/passdmaphoptodfscheblueprint/)
include_directories(./tilinglinalg/pass/passschedulecanonicalize/)
include_directories(./tilinglinalg/pass/passdfscheduletoapi/)
include_directories(./tilinglinalg/pass/passdfscheduletokernelapi/)
include_directories(./tilinglinalg/pass/kernelconfig/)
include_directories(./tilinglinalg/dataflowmap/dmap/inc/)
include_directories(./tilinglinalg/dataflowmap/dmap/)
include_directories(./tilinglinalg/dataflowmap/dmaphop/inc/)
include_directories(./tilinglinalg/dataflowmap/dmaphop/)
include_directories(./tilinglinalg/dataflowmap/dfschedule/inc/)
include_directories(./tilinglinalg/dataflowmap/dfschedule/)
include_directories(./tilinglinalg/dataflowmap/dfscheblueprint/inc/)
include_directories(./tilinglinalg/dataflowmap/dfscheblueprint/)
```

Add tablegen dependencies for the additional dialects (routinghw, dmap, dmaphop, dfschedule, dfscheblueprint).

---

### Step 3: Handle `<<<mesh>>>` syntax in preprocessor

**File**: `src/llvm/aiehlc.cc` — `GetKeyReplaceAndAddInclude()` (line 569)

The `<<<>>>` syntax is not valid C++. Transform it during preprocessing (same pattern as `__global__` -> `__attribute__((annotate("__global__")))` on line 527).

**Add to `replace_map`** or as a custom regex step in `GetKeyReplaceAndAddInclude()`:

```
Before Clang sees it:
  matmul<<<mesh>>>(A, B, C, M, N, K);
After preprocessing:
  __aie_launch(matmul, mesh, A, B, C, M, N, K);
```

**Implementation** — add after the existing keyword replacement loop (line 668):

```cpp
// Transform <<<mesh>>> kernel launch syntax
// Pattern: funcname<<<varname>>>(args) -> __aie_launch(funcname, varname, args)
size_t launchPos = 0;
while ((launchPos = SourceCodeString.find("<<<", launchPos)) != std::string::npos) {
    // Find the function name before <<<
    size_t funcEnd = launchPos;
    while (funcEnd > 0 && (std::isalnum(SourceCodeString[funcEnd-1]) || SourceCodeString[funcEnd-1] == '_'))
        funcEnd--;
    std::string funcName = SourceCodeString.substr(funcEnd, launchPos - funcEnd);

    // Find mesh variable name between <<< and >>>
    size_t meshStart = launchPos + 3;
    size_t meshEnd = SourceCodeString.find(">>>", meshStart);
    if (meshEnd == std::string::npos) break;
    std::string meshVar = SourceCodeString.substr(meshStart, meshEnd - meshStart);

    // Find args between ( and )
    size_t argsStart = meshEnd + 3; // skip >>>
    size_t argsOpenParen = SourceCodeString.find("(", argsStart);
    int depth = 1;
    size_t argsEnd = argsOpenParen + 1;
    while (depth > 0 && argsEnd < SourceCodeString.size()) {
        if (SourceCodeString[argsEnd] == '(') depth++;
        if (SourceCodeString[argsEnd] == ')') depth--;
        if (depth > 0) argsEnd++;
    }
    std::string args = SourceCodeString.substr(argsOpenParen + 1, argsEnd - argsOpenParen - 1);

    // Build replacement: __aie_launch("funcName", meshVar, args)
    std::string replacement = "__aie_launch(\"" + funcName + "\", " + meshVar + ", " + args + ")";

    // Replace from funcEnd to argsEnd+1 (include closing paren)
    SourceCodeString.replace(funcEnd, argsEnd + 1 - funcEnd, replacement);
    launchPos = funcEnd + replacement.size();

    // Track that we're in tiling mode
    isTilingLinalgMode = true;
}
```

Also handle:
- `aieSetDevice(...)` -> `__aie_set_device(...)` (or leave as-is and match in visitor)
- `aieDeviceSynchronize()` -> `__aie_synchronize()` (or leave as-is)
- `aieDim` -> needs to be a stub type in the injected header

---

### Step 4: Add stub types for Clang parsing

**File**: `src/llvm/aiehlc.cc` — in the stub declarations section (line 672-684)

Add after existing stubs:

```cpp
// CUDA-style AIE API stubs for Clang parsing
ret += "struct aieDim {\n";
ret += "    int rows, cols;\n";
ret += "    aieDim(int r, int c) : rows(r), cols(c) {}\n";
ret += "};\n";
ret += "inline void aieSetDevice(int) {}\n";
ret += "inline void aieDeviceSynchronize() {}\n";
ret += "inline void __aie_launch(const char* kernel, aieDim mesh, ...) {}\n";
```

---

### Step 5: Extract mesh/tensor parameters in AST Visitor

**File**: `src/llvm/aiehlc.cc` — `GlobalFunctionVisitor` class (line 37)

Add member variables to collect parsed parameters:

```cpp
// Tiling mode state
bool isTilingLinalgMode = false;
int meshRows = 0, meshCols = 0;
std::string launchKernelName;
struct ParsedTensor {
    std::string varName;
    std::vector<int64_t> shape;
    int elementBitWidth;
    bool isInput;
};
std::vector<ParsedTensor> parsedTensors;
```

Add visitor methods:

**`VisitVarDecl`** — detect `aieDim mesh(2, 2)`:
```cpp
bool VisitVarDecl(VarDecl *VD) {
    if (VD->getType().getAsString() == "aieDim") {
        if (auto *CE = dyn_cast<CXXConstructExpr>(VD->getInit())) {
            if (CE->getNumArgs() >= 2) {
                meshRows = evaluateIntExpr(CE->getArg(0));
                meshCols = evaluateIntExpr(CE->getArg(1));
                isTilingLinalgMode = true;
            }
        }
    }
    return true;
}
```

**`VisitCallExpr`** — detect `__aie_launch(...)`:
```cpp
// In VisitCallExpr:
if (name == "__aie_launch") {
    // Arg 0: kernel name (string literal)
    // Arg 1: mesh variable (aieDim)
    // Arg 2..N-4: tensor pointers (A, B, C)
    // Arg N-3..N-1: dimension values (M, N, K)
    isTilingLinalgMode = true;
}
```

**Detect `malloc` calls** to infer tensor shapes from `malloc(M * N * sizeof(int32_t))`:
```cpp
// In VisitCallExpr:
if (name == "malloc") {
    // The variable being assigned tells us the tensor name
    // The size expression tells us the total bytes
    // sizeof(int32_t) tells us element type
    // Combined with launch args M, N, K we know the shapes
}
```

---

### Step 6: Wire the pipeline in `EndSourceFileAction`

**File**: `src/llvm/aiehlc.cc` — `EndSourceFileAction()` (line 754-787)

Add branch after existing logic:

```cpp
void EndSourceFileAction() override {
    // ... existing host.cc writing (lines 756-771) ...
    // ... existing aie.mlir dump (lines 778-784) ...

    if (isTilingLinalgMode) {
        // ---- NEW PATH: tilinglinalg pipeline ----
        MLIRContext ctx;
        TilingLinalgPipeline::registerDialects(ctx);

        // Build tensor params from parsed data
        std::vector<TensorParam> tensors;
        for (auto &pt : parsedTensors) {
            tensors.push_back({pt.shape, pt.elementBitWidth, pt.isInput});
        }

        // Build routing IR
        auto module = TilingLinalgPipeline::buildRoutingIR(
            ctx, meshRows, meshCols, tensors);

        // Run pipeline -> writes host.cc, kernel.cc, routing.cc, BCF, PRX
        std::string outputDir = std::string(AOUT) + "worklocal/";
        TilingLinalgPipeline::runPipeline(ctx, module, outputDir);
    } else {
        // ---- EXISTING PATH: single-tile HybridPass ----
        aiefrontend.RunPass(fname);
    }
}
```

---

### Step 7: Refactor `unitest/test.cpp` to use `TilingLinalgPipeline`

**File**: `src/mlir/mlirfront/tilinglinalg/pass/unitest/test.cpp`

Replace `routingtodfschedule()` body with:

```cpp
void routingtodfschedule() {
    MLIRContext ctx;
    TilingLinalgPipeline::registerDialects(ctx);

    std::vector<TensorParam> tensors = {
        {{16, 16}, 8, true},  // input tensor 16x16 i8
    };
    auto module = TilingLinalgPipeline::buildRoutingIR(ctx, 2, 2, tensors);

    llvm::SmallString<256> cwdPath;
    llvm::sys::fs::current_path(cwdPath);
    std::string outputDir = (cwdPath + "/../worklocal").str();

    TilingLinalgPipeline::runPipeline(ctx, module, outputDir);
}
```

This keeps `test.cpp` working identically but uses the shared implementation.

---

### Step 8: Update CMake for aiehlc to add missing MLIR link targets

**File**: `CMakeLists.txt` (top-level, line 128-166)

Add missing MLIR libraries that tilinglinalg passes need (from `unitest/CMakeLists.txt` line 182-191):

```cmake
target_link_libraries(aiehlc PRIVATE
    # ... existing libs ...
    MLIRFuncDialect
    MLIRFuncTransforms
    MLIRLinalgDialect
    MLIRLinalgTransforms
    MLIRMemRefDialect
    MLIRTransformDialect
    MLIRTransformUtils
    MLIRLinalgTransformOps
    MLIRTransformDialectTransforms
)
```

---

## Data Flow Summary

```
proposal3.cc
  |
  +-- Preprocessor (Step 3):
  |     matmul<<<mesh>>>(A,B,C,M,N,K)
  |       -> __aie_launch("matmul", mesh, A,B,C,M,N,K)
  |     aieDim mesh(2,2) -> kept as-is (stub parsed by Clang)
  |
  +-- Clang AST Visitor (Steps 4-5):
  |     Extracts: meshRows=2, meshCols=2
  |               kernel="matmul" with body -> exported as matmul.cc
  |               A: int32_t[16*16], input
  |               B: int32_t[16*16], input
  |               C: int32_t[16*16], output
  |               M=16, N=16, K=16
  |
  +-- buildRoutingIR (Step 1):
  |     createhwmesh(2, 2)
  |     createscheduletensor({16,16}, i32, data_A) + createroutingfuncByDim(input)
  |     createscheduletensor({16,16}, i32, data_B) + createroutingfuncByDim(input)
  |     createscheduletensor({16,16}, i32, data_C) + createroutingfuncByDim(output)
  |
  +-- runPipeline (Step 1, copied from test.cpp):
  |     RoutingUnrollingLowerPass
  |     RoutingToDmapPass
  |     DmapToDmaphopPass
  |     DmaphopTodfscheblueprintPass
  |     -- clone module --
  |     Host: BlueprintToSchedule -> ScheduleCanonicalize -> DfscheduleToApi -> EmitC
  |     Kernel: BlueprintToScheduleKernel -> DfscheduleToKernelApi -> EmitC
  |     BCF/PRX from ResourceMgr allocations
  |     Routing: RoutingLower -> RoutingHWLower -> DeadArg -> ConstFold -> Canonicalize -> EmitC
  |
  +-- Output:
        worklocal/
        +-- host.cc          (XAie_* calls: DMA BD, locks, core load, data movement)
        +-- kernel.cc        (window acquire/release, compute, done)
        +-- routing.cc       (stream switch config, packet routing)
        +-- aieml.bcf        (buffer symbols, stack, reserved DM)
        +-- aieml.prx        (xchesscc project file)
```

## Files Changed

| File | Action | Description |
|---|---|---|
| `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h` | **NEW** | ~40 lines — pipeline class header |
| `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.cpp` | **NEW** | ~250 lines — extracted from test.cpp |
| `src/mlir/mlirfront/CMakeLists.txt` | **MODIFY** | +25 source files, +16 include dirs |
| `src/llvm/aiehlc.cc` | **MODIFY** | +stub types, +<<<>>> rewrite, +AST visitors, +EndSourceFileAction branch |
| `CMakeLists.txt` | **MODIFY** | +8 MLIR link targets |
| `src/mlir/mlirfront/tilinglinalg/pass/unitest/test.cpp` | **MODIFY** | Replace routingtodfschedule() body |

## Verification

1. **Regression**: `cd unitest/build && cmake .. && make -j4 && ./test dfschedule` — must produce same outputs as before
2. **Integration**: `cd build && cmake .. && make -j$(nproc)` — aiehlc must compile with all new sources
3. **End-to-end**: `./aiehlc example/tileprogram/design/proposal3.cc` — must produce `worklocal/{host,kernel,routing}.cc` + `aieml.{bcf,prx}`
4. **Diff test**: Compare `worklocal/host.cc` from step 3 with `worklocal/host.cc` from step 1 — should match for same mesh(2,2) + tensor(16x16, i32)
5. **HW test**: `cd worklocal && source compile_kernel.sh && source hostcompile.sh && python3 script/test/apppaltest.py build/host`
