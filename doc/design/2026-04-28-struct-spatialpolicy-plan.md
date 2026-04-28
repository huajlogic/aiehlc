# Struct-based SpatialPolicy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace enum-based SpatialPolicy with constexpr struct NTTP system, enabling user-defined spatial policies.

**Architecture:** The synthetic header injected by aiehlc.cc defines `SpatialPolicy` as a C++20 struct with `Pattern`, `Layout`, `Flow` enum class fields. Clang AST evaluation extracts field values from constexpr initializers. A new `fromPolicyFields()` factory replaces the name-based `fromPolicy()` lookup.

**Tech Stack:** Clang AST (APValue, VarDecl, constexpr evaluation), MLIR, C++17 (compiler), C++20 (user code parsing)

---

### Task 1: Add `-std=c++20` argument adjuster

**Files:**
- Modify: `src/llvm/aiehlc.cc:1655-1659`

**Step 1: Add the C++20 flag adjuster**

After the existing `-I` adjuster block at line 1655-1659, add a `-std=c++20` adjuster:

```cpp
	// Force C++20 for struct NTTP support in aie::port<T, SpatialPolicy>
	Tool.appendArgumentsAdjuster(
			getInsertArgumentAdjuster("-std=c++20", ArgumentInsertPosition::BEGIN));
```

**Step 2: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles without errors.

**Step 3: Commit**

```bash
git add src/llvm/aiehlc.cc
git commit -m "feat: add -std=c++20 adjuster for struct NTTP support"
```

---

### Task 2: Replace enum-based synthetic header with struct-based

**Files:**
- Modify: `src/llvm/aiehlc.cc:1334-1353`

**Step 1: Replace the enum + template block**

Replace lines 1334-1353 (from `// SpatialPolicy enum` through the closing `"}\n"` of the namespace) with:

```cpp
                    // SpatialPolicy struct + port<T, Policy> system (C++20 struct NTTP)
                    ret += "namespace aie {\n";
                    ret += "enum class Pattern  { Broadcast = 0, Scatter = 1, Multicast = 2, Gather = 3 };\n";
                    ret += "enum class Layout   { Row = 0, Col = 1, Grid = 2 };\n";
                    ret += "enum class Flow     { Default = 0, LeftToRight = 1, RightToLeft = 2 };\n";
                    ret += "struct SpatialPolicy {\n";
                    ret += "  Pattern pattern      = Pattern::Broadcast;\n";
                    ret += "  Layout  distribution = Layout::Row;\n";
                    ret += "  Flow    merge_order  = Flow::Default;\n";
                    ret += "  int     ping_pong    = 2;\n";
                    ret += "};\n";
                    ret += "template<typename T, SpatialPolicy P> struct port { using type = T; };\n";
                    // Pre-defined policies
                    ret += "inline constexpr SpatialPolicy RowBC      = {Pattern::Broadcast, Layout::Row,  Flow::Default,     2};\n";
                    ret += "inline constexpr SpatialPolicy ColBC      = {Pattern::Broadcast, Layout::Col,  Flow::Default,     2};\n";
                    ret += "inline constexpr SpatialPolicy LtoR_Merge = {Pattern::Gather,    Layout::Row,  Flow::LeftToRight, 2};\n";
                    ret += "inline constexpr SpatialPolicy RtoL_Merge = {Pattern::Gather,    Layout::Col,  Flow::RightToLeft, 2};\n";
                    ret += "inline constexpr SpatialPolicy RowScatter = {Pattern::Scatter,   Layout::Row,  Flow::Default,     2};\n";
                    ret += "inline constexpr SpatialPolicy ColScatter = {Pattern::Scatter,   Layout::Col,  Flow::Default,     2};\n";
                    // Backward-compatible aliases
                    ret += "template<typename T> using row_broadcast_in = port<T, RowBC>;\n";
                    ret += "template<typename T> using col_broadcast_in = port<T, ColBC>;\n";
                    ret += "template<typename T> using tiled_in         = port<T, RowBC>;\n";
                    ret += "template<typename T> using row_major_out    = port<T, LtoR_Merge>;\n";
                    ret += "template<typename T> using col_major_out    = port<T, RtoL_Merge>;\n";
                    ret += "template<typename T> using row_reduce_out   = port<T, RowScatter>;\n";
                    ret += "}\n";
```

**Step 2: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles without errors.

**Step 3: Commit**

```bash
git add src/llvm/aiehlc.cc
git commit -m "feat: replace enum SpatialPolicy with constexpr struct in synthetic header"
```

---

### Task 3: Add policy fields to ParsedTensorInfo

**Files:**
- Modify: `src/llvm/aiehlc.cc:41-48`

**Step 1: Add the new fields to the struct**

Replace the `ParsedTensorInfo` struct at lines 41-48 with:

```cpp
struct ParsedTensorInfo {
    std::string varName;
    std::vector<int64_t> shape;
    int elementBitWidth;
    bool isInput;
    std::string spatialTag;  // "row_broadcast_in", "col_broadcast_in", etc. or "" for default
    std::string policyName;  // variable name for diagnostics (from aie::port<T, Policy>)
    // Resolved SpatialPolicy struct fields (from Clang AST constexpr evaluation)
    int pattern = 0;       // 0=Broadcast, 1=Scatter, 2=Multicast, 3=Gather
    int distribution = 0;  // 0=Row, 1=Col, 2=Grid
    int mergeOrder = 0;    // 0=Default, 1=LeftToRight, 2=RightToLeft
    int pingPong = 2;
    bool policyResolved = false; // true once AST extraction succeeds
};
```

**Step 2: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles without errors (new fields have defaults, existing code still works).

**Step 3: Commit**

```bash
git add src/llvm/aiehlc.cc
git commit -m "feat: add resolved policy fields to ParsedTensorInfo"
```

---

### Task 4: Implement Clang AST constexpr extraction

**Files:**
- Modify: `src/llvm/aiehlc.cc` — after line 830 (`pti.policyName = policyName;`)

This is the core task. After the policy name is stored, resolve the constexpr VarDecl and extract struct field values.

**Step 1: Add AST resolution code**

After `pti.policyName = policyName;` (line 830), add the constexpr evaluation block. The approach:
- We already have `kp` (the `ParmVarDecl`). The policy is the second template argument of `aie::port<T, P>`.
- Get the `TemplateSpecializationType` from the parameter type.
- Extract the second template argument as a `NonTypeTemplateParm`.
- Evaluate the `APValue` which is a struct with 4 fields.

```cpp
                                // --- AST-based SpatialPolicy struct extraction ---
                                if (!policyName.empty()) {
                                    // Get the template specialization type for port<T, P>
                                    const clang::Type *rawType = ptype.getTypePtr();
                                    // Unwrap elaborated types
                                    if (const auto *elab = dyn_cast<clang::ElaboratedType>(rawType))
                                        rawType = elab->getNamedType().getTypePtr();
                                    if (const auto *tst = dyn_cast<clang::TemplateSpecializationType>(rawType)) {
                                        if (tst->template_arguments().size() >= 2) {
                                            const auto &policyArg = tst->template_arguments()[1];
                                            // The NTTP argument is an expression referencing the constexpr var
                                            if (policyArg.getKind() == clang::TemplateArgument::StructuralValue) {
                                                // C++20 structural NTTP: value is directly available
                                                const APValue &val = policyArg.getAsStructuralValue();
                                                if (val.isStruct() && val.getStructNumFields() >= 4) {
                                                    pti.pattern      = (int)val.getStructField(0).getInt().getExtValue();
                                                    pti.distribution = (int)val.getStructField(1).getInt().getExtValue();
                                                    pti.mergeOrder   = (int)val.getStructField(2).getInt().getExtValue();
                                                    pti.pingPong     = (int)val.getStructField(3).getInt().getExtValue();
                                                    pti.policyResolved = true;
                                                    llvm::outs() << "[TilingLinalg] Policy resolved: pattern="
                                                                 << pti.pattern << " distribution=" << pti.distribution
                                                                 << " mergeOrder=" << pti.mergeOrder
                                                                 << " pingPong=" << pti.pingPong << "\n";
                                                }
                                            }
                                        }
                                    }
                                    if (!pti.policyResolved) {
                                        llvm::errs() << "[TilingLinalg] ERROR: Failed to resolve constexpr SpatialPolicy '"
                                                     << policyName << "' from AST\n";
                                    }
                                }
```

**Important Clang API notes:**
- C++20 struct NTTPs use `TemplateArgument::StructuralValue` kind (Clang 16+).
- `getAsStructuralValue()` returns an `APValue` of kind `Struct`.
- Fields are indexed in declaration order: 0=pattern, 1=distribution, 2=merge_order, 3=ping_pong.
- The enum class values are stored as integers in `APValue::getInt()`.
- If your Clang version doesn't have `StructuralValue`, check for `Declaration` kind and evaluate the `VarDecl` — see alternative approach in doc/design/2026-04-28-struct-spatialpolicy-design.md.

**Step 2: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles. The new code is additive — old paths still work.

**Step 3: Smoke test with simplematmul.cc**

Run: `cd build && ./aiehlc ../example/tileprogram/ccode/simplematmul.cc -- 2>&1 | grep "Policy resolved"`
Expected: Three lines showing resolved policy fields for RowBC, ColBC, LtoR_Merge.

**Step 4: Commit**

```bash
git add src/llvm/aiehlc.cc
git commit -m "feat: extract SpatialPolicy struct fields from Clang AST constexpr evaluation"
```

---

### Task 5: Add `fromPolicyFields()` factory method

**Files:**
- Modify: `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h:48-51`
- Modify: `src/mlir/mlirfront/tilinglinalg/routing/routingmanager.cpp:660-673`

**Step 1: Add declaration in header**

Replace lines 48-51 (the `fromPolicy` declaration) with:

```cpp
    /// Construct a TensorSplitDesc from resolved SpatialPolicy struct fields.
    /// pattern: 0=Broadcast, 1=Scatter, 2=Multicast, 3=Gather
    /// distribution: 0=Row, 1=Col, 2=Grid
    /// mergeOrder: 0=Default, 1=LeftToRight, 2=RightToLeft
    static TensorSplitDesc fromPolicyFields(int pattern, int distribution,
                                             int mergeOrder, int pingPong, bool isInput);
```

**Step 2: Replace `fromPolicy()` implementation with `fromPolicyFields()`**

In `routingmanager.cpp`, replace lines 660-673 (the `fromPolicy` function) with:

```cpp
// ---------------------------------------------------------------------------
// SplitModel::fromPolicyFields — struct field-based lookup
// ---------------------------------------------------------------------------

TensorSplitDesc SplitModel::fromPolicyFields(int pattern, int distribution,
                                              int mergeOrder, int pingPong, bool isInput) {
    // Map enum values to strings
    static const char *patternStr[]  = {"broadcast", "scatter", "multicast", "gather"};
    static const char *flowStr[]     = {"default", "ltor", "rtol"};

    std::string pat = (pattern >= 0 && pattern <= 3) ? patternStr[pattern] : "broadcast";
    std::string flw = (mergeOrder >= 0 && mergeOrder <= 2) ? flowStr[mergeOrder] : "default";

    // Determine hwAxisOwner and replicateOn from distribution + pattern
    std::string hwAxis, replOn;
    if (distribution == 0) { // Row
        hwAxis = "row";
        replOn = (pattern == 1) ? "" : "col"; // Scatter has no replicateOn
    } else if (distribution == 1) { // Col
        hwAxis = "col";
        replOn = (pattern == 1) ? "" : "row";
    } else { // Grid
        hwAxis = "row";
        replOn = "";
    }

    return {0, hwAxis, replOn, pat, flw, pingPong};
}
```

**Step 3: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles without errors.

**Step 4: Commit**

```bash
git add src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h \
        src/mlir/mlirfront/tilinglinalg/routing/routingmanager.cpp
git commit -m "feat: add fromPolicyFields() factory, remove fromPolicy()"
```

---

### Task 6: Update SplitModel construction to use resolved fields

**Files:**
- Modify: `src/llvm/aiehlc.cc:1484-1502`

**Step 1: Replace the SplitModel construction block**

Replace lines 1484-1502 with:

```cpp
                // Build SplitModel from resolved policy fields
                SplitModel splitModel;
                if (!parsedTensors.empty()) {
                    for (auto &pt : parsedTensors) {
                        if (pt.policyResolved) {
                            // Use resolved struct fields from AST
                            splitModel.tensorSplits.push_back(
                                SplitModel::fromPolicyFields(pt.pattern, pt.distribution,
                                                              pt.mergeOrder, pt.pingPong, pt.isInput));
                        } else if (!pt.spatialTag.empty()) {
                            // Legacy spatial tag syntax (e.g. row_broadcast_in<T>)
                            splitModel.tensorSplits.push_back(
                                SplitModel::fromSpatialTag(pt.spatialTag, pt.isInput));
                        } else {
                            llvm::errs() << "[TilingLinalg] ERROR: tensor '" << pt.varName
                                         << "' has no resolved policy and no spatial tag\n";
                            // Default fallback
                            splitModel.tensorSplits.push_back(
                                SplitModel::fromPolicyFields(
                                    pt.isInput ? 0 : 3,  // Broadcast for input, Gather for output
                                    0, pt.isInput ? 0 : 1, 2, pt.isInput));
                        }
                    }
                } else {
                    splitModel = SplitModel::gemm();
                }
```

**Step 2: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles without errors.

**Step 3: Commit**

```bash
git add src/llvm/aiehlc.cc
git commit -m "feat: use resolved policy fields for SplitModel construction"
```

---

### Task 7: Update input/output and shape determination

**Files:**
- Modify: `src/llvm/aiehlc.cc:781-826`

**Step 1: Simplify isInput determination**

Replace lines 781-795 (the isInput block) with:

```cpp
                                // Determine input/output: always prefer inner type info
                                bool isInput;
                                if (isWindowParam) {
                                    isInput = isInputWindow;
                                } else if (!spatialTag.empty()) {
                                    isInput = (spatialTag.find("_in") != std::string::npos);
                                } else if (ptype->isPointerType()) {
                                    isInput = ptype->getPointeeType().isConstQualified();
                                } else {
                                    isInput = true; // conservative default
                                }
```

**Step 2: Replace shape assignment to use pattern+distribution**

Replace lines 804-824 (effectiveTag mapping and shape lookup) with:

```cpp
                                // Assign per-tensor GEMM shapes from M/N/K macros.
                                // Derive from resolved policy fields or spatial tag.
                                if (macroDimM > 0 && macroDimN > 0 && macroDimK > 0) {
                                    // Determine from policy fields if available, else spatial tag
                                    bool shapeAssigned = false;
                                    if (!policyName.empty()) {
                                        // pattern 0=Broadcast, distribution 0=Row, 1=Col
                                        // Broadcast+Row -> A[M,K], Broadcast+Col -> B[K,N]
                                        // Gather/Scatter -> C[M,N]
                                        // Note: fields not yet resolved at this point in parsing,
                                        // but we know the policyName. We'll use a deferred approach:
                                        // store defaults now, override after AST resolution in Task 4 code.
                                    }
                                    if (!shapeAssigned && !spatialTag.empty()) {
                                        if (spatialTag == "row_broadcast_in") { pti.shape = {macroDimM, macroDimK}; shapeAssigned = true; }
                                        else if (spatialTag == "col_broadcast_in") { pti.shape = {macroDimK, macroDimN}; shapeAssigned = true; }
                                        else if (spatialTag == "row_major_out" || spatialTag == "col_major_out") { pti.shape = {macroDimM, macroDimN}; shapeAssigned = true; }
                                    }
                                    if (!shapeAssigned)
                                        pti.shape = {defaultDim0, defaultDim1};
                                } else {
                                    pti.shape = {defaultDim0, defaultDim1};
                                }
```

**Step 3: Add shape resolution after AST extraction**

After the AST extraction code added in Task 4 (after `pti.policyResolved = true`), add shape re-assignment:

```cpp
                                    // Re-assign shape from resolved policy fields
                                    if (pti.policyResolved && macroDimM > 0 && macroDimN > 0 && macroDimK > 0) {
                                        if (pti.pattern == 0 && pti.distribution == 0)       // Broadcast+Row -> A
                                            pti.shape = {macroDimM, macroDimK};
                                        else if (pti.pattern == 0 && pti.distribution == 1)  // Broadcast+Col -> B
                                            pti.shape = {macroDimK, macroDimN};
                                        else                                                  // Gather/Scatter -> C
                                            pti.shape = {macroDimM, macroDimN};
                                    }
```

**Step 4: Build and verify**

Run: `cd build && make -j$(nproc) 2>&1 | tail -20`
Expected: Compiles without errors.

**Step 5: Commit**

```bash
git add src/llvm/aiehlc.cc
git commit -m "feat: derive isInput and shape from policy fields instead of name matching"
```

---

### Task 8: End-to-end verification

**Step 1: Smoke test with existing example**

Run: `cd build && ./aiehlc ../example/tileprogram/ccode/simplematmul.cc -- 2>&1 | grep -E "Policy|Tensor"`
Expected: All three tensors show resolved policy fields and correct shapes.

**Step 2: Run unitest pipeline**

Run: `cd src/mlir/mlirfront/tilinglinalg/pass/unitest/build && make -j4 && ./test dfschedule 2>&1 | tail -30`
Expected: Pipeline completes, generates host.cc and kernel.cc without errors.

**Step 3: Run routing path**

Run: `./test hw 2>&1 | tail -20`
Expected: Generates routing.cc without errors.

**Step 4: Create a custom policy test**

Create a test file that uses a user-defined policy to verify the custom policy path works. Add to `simplematmul.cc` or create a separate test file with:

```cpp
constexpr aie::SpatialPolicy MyGather = {
    .pattern = aie::Pattern::Gather,
    .distribution = aie::Layout::Col,
    .merge_order = aie::Flow::RightToLeft,
    .ping_pong = 4
};
```

Run: Parse with aiehlc and verify resolved fields show pattern=3, distribution=1, mergeOrder=2, pingPong=4.

**Step 5: Commit any test fixes**

```bash
git add -A && git commit -m "test: verify struct-based SpatialPolicy end-to-end"
```

---

### Task 9: Clean up removed code

**Files:**
- Modify: `src/mlir/mlirfront/tilinglinalg/routing/routingmanager.cpp` — remove `fromPolicy()` if still present
- Modify: `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h` — remove `fromPolicy()` declaration if still present

**Step 1: Verify no remaining references to old fromPolicy**

Run: `grep -rn "fromPolicy" src/`
Expected: No hits (only `fromPolicyFields` should remain).

**Step 2: Commit if any cleanup done**

```bash
git add -A && git commit -m "chore: remove obsolete fromPolicy() name-based lookup"
```
