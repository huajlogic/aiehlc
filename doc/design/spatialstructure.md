# Spatial Policy Architecture: From Type-as-Behavior to Policy-as-Configuration

To evolve your DSL toward a professional, SOTA (State-of-the-Art) architecture, we should move away from "Type-as-Behavior" (where the class name dictates the hardware action) and toward "Policy-as-Configuration." The following solution combines Option 4 (Struct-based declaration) for clarity with Option 2 (Builder-style) for local flexibility.

## 1. The Declarative Strategy: Spatial Policy Structs

Instead of creating `row_broadcast_in`, we define a generic `aie::port` that accepts a `constexpr` configuration struct. This allows the compiler to treat spatial layout as metadata rather than a rigid type hierarchy.

### The Configuration Schema

```cpp
namespace aie {
    enum class Pattern { Broadcast, Scatter, Multicast, Gather };
    enum class Layout  { Row, Col, Grid };
    enum class Flow    { LeftToRight, RightToLeft, Default };

    struct SpatialPolicy {
        Pattern pattern      = Pattern::Broadcast;
        Layout  distribution = Layout::Row;
        Flow    merge_order  = Flow::Default;
        int     ping_pong    = 2;
    };
}
```

### Pre-defined Policies

You can define these once in a header file to maintain a clean "Library of Behaviors."

```cpp
// Explicitly defining your specific requirements
constexpr aie::SpatialPolicy RowBC = {
    .pattern = aie::Pattern::Broadcast,
    .distribution = aie::Layout::Row
};

constexpr aie::SpatialPolicy LtoR_Merge = {
    .pattern = aie::Pattern::Gather,
    .distribution = aie::Layout::Row,
    .merge_order = aie::Flow::LeftToRight // Specifically addressing your "Left-to-Right" requirement
};
```

## 2. The Refactored Kernel Signature

The kernel signature now becomes a high-level contract between the algorithm and the hardware scheduler.

```cpp
__global__ void matmul(
    aie::port<input_window_int8*,  RowBC>      window_in_0,
    aie::port<input_window_int8*,  ColBC>      window_in_1,
    aie::port<output_window_int8*, LtoR_Merge> window_out_0
) {
    // The kernel code focuses on the computation.
    // The compiler uses the template parameters to generate
    // the DMA descriptors and synchronization barriers.
}
```

## 3. Inline Flexibility: The Builder Style

Sometimes a static policy isn't enough. You might need to override a specific parameter for a specialized tile. By using a Builder Pattern inside the kernel or at the call site, you provide "escape hatches" for power users.

```cpp
auto custom_view = window_in_0.override()
                              .with_buffer_depth(4)
                              .as_scatter();
```

## 4. Why This Matches SOTA Industrial Solutions

### Separation of Concerns (The Halide/Triton Approach)

Modern compilers like Halide or OpenAI Triton succeed because they separate the **Algorithm** (the math) from the **Schedule** (the data movement). By using `aie::port<T, Policy>`, you allow the user to change the hardware mapping (e.g., switching from Row Broadcast to Column Broadcast) without touching the mathematical logic inside the kernel.

### MLIR Compatibility

If your backend uses MLIR (Multi-Level Intermediate Representation), this struct-based approach maps perfectly to Attributes.

The `SpatialPolicy` struct can be lowered directly into an MLIR Attribute dictionary: `{aie.pattern = #broadcast, aie.flow = #l_to_r}`.

This makes it trivial for a transformation pass to analyze the data-flow and ensure no hardware bank conflicts occur.

### Left-to-Right Flow Optimization

By explicitly naming the `Flow::LeftToRight` property, you enable the compiler to perform **Systolic Array Mapping**. Instead of a global synchronization barrier, the compiler can generate "Chain Synchronizations," where Tile $N$ signals Tile $N+1$ immediately after finishing its row, maximizing hardware utilization.
