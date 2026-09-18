# Pass: BlueprintToSchedulePass

## Overview
This pass converts `dfscheblueprint` dialect operations into `dfschedule` dialect operations for AIE dataflow scheduling.

## Location
- Header: `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.h`
- Implementation: `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp`

## Purpose
Transforms high-level schedule blueprint operations into concrete runtime scheduling operations that implement ping-pong buffering, DMA transfers, and synchronization for efficient data streaming on AIE tiles.

## Input IR Structure (dfscheblueprint dialect)
```mlir
schedule.config @my_blueprint {
  // Physical resource definitions
  schedule.resource_group @shim_gateway { tiles = [[0, 2]] }
  schedule.resource_group @compute_row { tiles = [[2, 0], [2, 1], [2, 2], [2, 3]] }
  
  // Data declarations
  %root_data = schedule.declare_data tensor<1024x1024xf32> -> tensor<1024x1024xf32>
  
  // Data slicing
  %view_strip = tensor.extract_slice %root_data[0, 0] [256, 1024] [1, 1] 
                : tensor<1024x1024xf32> to tensor<256x1024xf32>
  %slice_0 = schedule.data_slice @out_slice_0 wrap %view_strip : tensor<256x1024xf32>
  
  // Binding resources to data
  schedule.bind @bind_shim_tx { 
    target = @shim_gateway, 
    view = %view_strip,
    slice = "root",
    dma = #schedule.DMA<channels = [0], direction = MM2S>
  }
  
  schedule.bind_group @bind_cores_in {
    target_group = @compute_row,
    view = %view_strip,
    distribution = "linear",
    dma = #schedule.DMA<channels = [0], direction = S2MM>
  }
  
  // Transfer definitions
  schedule.collective_transfer @input_scatter {
    type = "one_to_many",
    from = @bind_shim_tx,
    to = @bind_cores_in,
    base_packet_id = 10
  }
}
```

## Output IR Structure (dfschedule dialect)
```mlir
module {
  // Host orchestration function
  func.func @schedule_host() {
    // Get tile handles
    %tile_0_2 = dfschedule.get_tile_handle {col = 0, row = 2} -> !dfschedule.tile_handle
    %tile_2_0 = dfschedule.get_tile_handle {col = 2, row = 0} -> !dfschedule.tile_handle
    ...
    
    // Allocate device memory
    %dev_mem = dfschedule.alloc_device_mem : memref<1024x1024xf32>
    
    // Get stream handles
    %stream = dfschedule.get_stream_handle @bind_shim_tx -> !dfschedule.stream
    
    return
  }
  
  // Kernel function for compute tiles
  func.func private @kernel_compute_row(%arg0: i32) {
    // Ping-pong buffers
    %ping = memref.alloca() {buffer_type = "ping"} : memref<256xf32>
    %pong = memref.alloca() {buffer_type = "pong"} : memref<256xf32>
    
    // Lock initialization
    %ping_acquire = dfschedule.lock_init(0) -> !dfschedule.lock
    %pong_acquire = dfschedule.lock_init(0) -> !dfschedule.lock
    %ping_release = dfschedule.lock_init(1) -> !dfschedule.lock
    %pong_release = dfschedule.lock_init(0) -> !dfschedule.lock
    
    // DMA thread (runs in parallel)
    dfschedule.launch_dma_s2m_loop %ping, %pong, %arg0, 
                                   %ping_acquire, %pong_acquire, 
                                   %ping_release, %pong_release { }
    
    // Compute thread with ping-pong logic
    scf.for %i = %c0 to %c4 step %c1 {
      %is_even = arith.cmpi eq, arith.remui(%i, %c2), %c0
      %buffer = scf.if %is_even -> (memref<256xf32>) { ... }
      %acquire_lock = scf.if %is_even -> (!dfschedule.lock) { ... }
      %release_lock = scf.if %is_even -> (!dfschedule.lock) { ... }
      
      dfschedule.acquire_lock %acquire_lock, %lock_val
      dfschedule.compute %buffer : memref<256xf32>
      dfschedule.release_lock %release_lock, %lock_val
    }
    return
  }
}
```

## Key Transformations

### 1. ConfigOp Conversion
- Creates a module containing host and kernel functions
- Processes resource groups to get tile handles
- Allocates device memory for declared data
- Sets up collective transfers

### 2. ResourceGroupOp Processing
- Extracts tile coordinates from resource groups
- Creates `dfschedule.get_tile_handle` for each tile

### 3. DeclareDataOp Conversion
- Converts logical tensor declarations to device memory allocations
- Uses `dfschedule.alloc_device_mem`

### 4. DataSliceOp Handling
- Passes through tensor slices for use in scheduling

### 5. Bind/BindGroup Processing
- Links resources to data views
- Configures DMA channels and directions

### 6. CollectiveTransferOp Conversion
- Converts to stream handles and copy operations
- Supports one_to_many (broadcast) and many_to_one (gather)

### 7. Kernel Generation
- Creates kernel functions for compute tiles
- Implements ping-pong buffering pattern
- Sets up lock synchronization

## Pass Registration
```cpp
StringRef getArgument() const final { return "lower-blueprint-to-schedule"; }
StringRef getDescription() const final { return "Lower dfscheblueprint dialect to dfschedule dialect"; }
```

## Dependencies
- `dfscheblueprint` dialect (input)
- `dfschedule` dialect (output)
- Standard dialects: `func`, `memref`, `arith`, `scf`, `tensor`

## Usage Example
```bash
# Apply pass during compilation pipeline
mlir-opt --lower-blueprint-to-schedule input.mlir -o output.mlir
```

## Notes
- Lock values increment with loop iterations (1, 2, 3, 4 for iterations 0, 1, 2, 3)
- Ping-pong selection based on even/odd iteration parity
- DMA and compute threads run in parallel using separate lock synchronization
- Shim tiles are excluded from kernel generation (handled by host)
- Buffer size defaults to 256xf32 (configurable if needed)
