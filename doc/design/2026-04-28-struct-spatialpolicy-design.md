# Design: Struct-based SpatialPolicy with Clang AST Evaluation

**Date:** 2026-04-28
**Status:** Approved

## Goal

Replace the enum-based `SpatialPolicy` system with a `constexpr` struct-based system,
enabling users to define custom spatial policies for kernel parameter transfer logic.

## Current State

- `SpatialPolicy` is an `enum { RowBC=0, ColBC=1, LtoR_Merge=2, ... }` injected as a synthetic header
- `aie::port<T, Policy>` uses the enum as a non-type template parameter
- Policy name is extracted as a string from template argument text
- `SplitModel::fromPolicy(name)` maps the string to a `TensorSplitDesc` via hardcoded lookup
- Users cannot define custom policies

## Design

### 1. Synthetic Header (aiehlc.cc) — Types Only

The synthetic header defines only the type system (enums, struct, port template).
Pre-defined policy constants are NOT in the synthetic header — they belong in the
user's source file, giving users full control over policy definitions.

```cpp
namespace aie {
  enum class Pattern  { Broadcast = 0, Scatter = 1, Multicast = 2, Gather = 3 };
  enum class Layout   { Row = 0, Col = 1, Grid = 2 };
  enum class Flow     { Default = 0, LeftToRight = 1, RightToLeft = 2 };

  struct SpatialPolicy {
    Pattern pattern      = Pattern::Broadcast;
    Layout  distribution = Layout::Row;
    Flow    merge_order  = Flow::Default;
    int     ping_pong    = 2;
  };

  template<typename T, SpatialPolicy P> struct port { using type = T; };
}
```

### 1b. User Source File (e.g. simplematmul.cc) — Policy Constants

Users define their own policy constants at file scope:

```cpp
constexpr aie::SpatialPolicy RowBC = {
    .pattern = aie::Pattern::Broadcast,
    .distribution = aie::Layout::Row
};

constexpr aie::SpatialPolicy ColBC = {
    .pattern = aie::Pattern::Broadcast,
    .distribution = aie::Layout::Col
};

constexpr aie::SpatialPolicy LtoR_Merge = {
    .pattern = aie::Pattern::Gather,
    .distribution = aie::Layout::Row,
    .merge_order = aie::Flow::LeftToRight
};
```

Backward-compatible aliases (`row_broadcast_in`, etc.) are removed.

### 2. C++20 Requirement

Add `-std=c++20` as an argument adjuster in `aiehlc.cc` because:
- Designated initializers (`.field = value`) require C++20
- Struct NTTP (`template<typename T, SpatialPolicy P>`) requires C++20

### 3. Clang AST Extraction

When `aie::port<T, UserPolicy>` is encountered:

1. Extract the policy variable name from template argument text (existing logic)
2. Resolve the `VarDecl` for the policy name via Clang AST
3. Get `APValue` from constexpr evaluator (`VarDecl::getEvaluatedValue()`)
4. Extract struct fields by index from `APValue::getStructField(i)`
5. Store resolved fields in `ParsedTensorInfo`

No fallback to name-based lookup. AST resolution failure is an error.

### 4. ParsedTensorInfo Changes

```cpp
struct ParsedTensorInfo {
    std::string varName;
    std::vector<int64_t> shape;
    int elementBitWidth;
    bool isInput;
    std::string spatialTag;   // legacy tag (to be removed)
    std::string policyName;   // variable name (diagnostics only)
    // Resolved struct fields
    int pattern = 0;       // 0=Broadcast, 1=Scatter, 2=Multicast, 3=Gather
    int distribution = 0;  // 0=Row, 1=Col, 2=Grid
    int mergeOrder = 0;    // 0=Default, 1=LeftToRight, 2=RightToLeft
    int pingPong = 2;
    bool policyResolved = false;
};
```

### 5. TensorSplitDesc Construction

New factory method replaces `fromPolicy()`:

```cpp
static TensorSplitDesc fromPolicyFields(int pattern, int distribution,
                                         int mergeOrder, int pingPong, bool isInput);
```

Mapping:
- `pattern`: 0->"broadcast", 1->"scatter", 2->"multicast", 3->"gather"
- `distribution + pattern` -> `hwAxisOwner`/`replicateOn`:
  - Row+Broadcast -> {"row", "col"}
  - Col+Broadcast -> {"col", "row"}
  - Row+Gather    -> {"row", "col"}
  - Col+Gather    -> {"col", "row"}
  - Row+Scatter   -> {"row", ""}
  - Col+Scatter   -> {"col", ""}
- `mergeOrder`: 0->"default", 1->"ltor", 2->"rtol"
- `pingPong` -> passed through

### 6. Input/Output Determination

Derive `isInput` from the inner type, not the policy name:
- `input_window_*` -> input
- `output_window_*` -> output
- Bare pointer -> `const` qualification

### 7. Shape Assignment

Derive GEMM shape from `pattern + distribution` fields:
- Broadcast + Row -> A matrix -> [M, K]
- Broadcast + Col -> B matrix -> [K, N]
- Gather/Scatter + Row/Col -> C matrix -> [M, N]

### 8. Removals

- `enum SpatialPolicy { RowBC=0, ... }` (replaced by struct)
- `SplitModel::fromPolicy(const std::string&, bool)` (replaced by `fromPolicyFields`)
- Policy-name-based `isInput` heuristic in aiehlc.cc:786-787
- Policy-name-to-effectiveTag mapping in aiehlc.cc:806-813

## Files Changed

| File | Change |
|------|--------|
| `src/llvm/aiehlc.cc` | Synthetic header (types only), AST extraction, `-std=c++20`, remove enum/name paths |
| `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h` | Add `fromPolicyFields()`, remove `fromPolicy()` |
| `src/mlir/mlirfront/tilinglinalg/routing/routingmanager.cpp` | Implement `fromPolicyFields()`, remove `fromPolicy()` |
| `example/tileprogram/ccode/simplematmul.cc` | Add `constexpr SpatialPolicy` definitions for RowBC, ColBC, LtoR_Merge |

## User-Facing Example

```cpp
// Policy constants defined at file scope (user source)
constexpr aie::SpatialPolicy RowBC = {
    .pattern = aie::Pattern::Broadcast,
    .distribution = aie::Layout::Row
};
constexpr aie::SpatialPolicy ColBC = {
    .pattern = aie::Pattern::Broadcast,
    .distribution = aie::Layout::Col
};
constexpr aie::SpatialPolicy LtoR_Merge = {
    .pattern = aie::Pattern::Gather,
    .distribution = aie::Layout::Row,
    .merge_order = aie::Flow::LeftToRight
};

__global__ void matmul(aie::port<input_window_int8*, RowBC>      a,
                       aie::port<input_window_int8*, ColBC>      b,
                       aie::port<output_window_int8*, LtoR_Merge> c) { ... }

// Custom policy — user-defined
constexpr aie::SpatialPolicy MyGather = {
    .pattern = aie::Pattern::Gather,
    .distribution = aie::Layout::Col,
    .merge_order = aie::Flow::RightToLeft,
    .ping_pong = 4
};
__global__ void mykernel(aie::port<output_window_int8*, MyGather> out) { ... }
```
