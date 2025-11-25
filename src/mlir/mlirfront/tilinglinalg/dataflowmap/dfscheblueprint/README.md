# dfscheblueprint Dialect - Schedule Blueprint IR

## Overview

The `dfscheblueprint` dialect provides a schedule blueprint IR for defining data movement patterns, tiling configurations, and routing information for AIE architectures. It serves as schedule metadata that can be used to guide compilation and runtime scheduling.

## Dialect Structure

### Operations

#### `schedule.config` - Top-level Container
The main container operation for schedule blueprints.

**Syntax:**
```mlir
schedule.config @blueprint_name {
  // transfer manifest operations
}
```

**Traits:** `IsolatedFromAbove`, `SymbolTable`, `Symbol`, `SingleBlock`

#### `schedule.transfer_manifest` - Data Transfer Specification
Defines individual data transfers with tiling and routing information.

**Syntax:**
```mlir
schedule.transfer_manifest @transfer_name {
  payload_slice = #schedule.slice<...>,
  packet_id = <id> : i32,
  source = #schedule.endpoint<...>,
  destinations = [#schedule.endpoint<...>, ...]
}
```

**Attributes:**
- `payload_slice`: Data slice definition (what data to transfer)
- `packet_id`: Packet identifier for routing
- `source`: Single source endpoint
- `destinations`: Array of destination endpoints (for broadcast)

### Attributes

#### `#schedule.slice` - Data Slice Attribute
Defines data tiling/slicing information.

**Parameters:**
- `data_type`: MemRef type (e.g., `memref<1024x1024xf32>`)
- `offset`: Starting offset `[row, col]`
- `size`: Size of the slice `[rows, cols]`
- `stride`: Stride values `[row_stride, col_stride]`

**Example:**
```mlir
#schedule.slice<
  data_type = memref<1024x1024xf32>,
  offset = [0, 0],
  size = [512, 1024],
  stride = [1024, 1]
>
```

#### `#schedule.endpoint` - Tile Endpoint Attribute
Defines physical tile location and DMA configuration.

**Parameters:**
- `tile`: Tile location `[row, col]`
- `direction`: DMA direction (`"MM2S"` or `"S2MM"`)
- `channel`: DMA channel number

**Example:**
```mlir
#schedule.endpoint<tile=[2,0], direction="MM2S", channel=0>
```

## Complete Example

```mlir
schedule.config @tiling_and_broadcast_blueprint {
  
  // Transfer 1: Broadcast upper half
  schedule.transfer_manifest @broadcast_upper_half {
    payload_slice = #schedule.slice<
      data_type = memref<1024x1024xf32>,
      offset = [0, 0],
      size = [512, 1024],
      stride = [1024, 1]
    >,
    packet_id = 10 : i32,
    source = #schedule.endpoint<tile=[0,2], direction="MM2S", channel=0>,
    destinations = [
      #schedule.endpoint<tile=[2,2], direction="S2MM", channel=0>,
      #schedule.endpoint<tile=[3,2], direction="S2MM", channel=0>
    ]
  }
  
  // Transfer 2: Broadcast lower half
  schedule.transfer_manifest @broadcast_lower_half {
    payload_slice = #schedule.slice<
      data_type = memref<1024x1024xf32>,
      offset = [512, 0],
      size = [512, 1024],
      stride = [1024, 1]
    >,
    packet_id = 11 : i32,
    source = #schedule.endpoint<tile=[0,2], direction="MM2S", channel=0>,
    destinations = [
      #schedule.endpoint<tile=[4,2], direction="S2MM", channel=0>,
      #schedule.endpoint<tile=[5,2], direction="S2MM", channel=0>
    ]
  }
}
```

## File Structure

```
dfscheblueprint/
├── td/                              # TableGen definitions
│   ├── dfscheblueprintattr.td       # Dialect and attribute definitions
│   ├── dfscheblueprinttype.td       # Type definitions
│   └── dfscheblueprintop.td         # Operation definitions
├── inc/                             # Generated .inc files
│   ├── dfscheblueprintdialect.*.inc
│   ├── dfscheblueprintattr.*.inc
│   ├── dfscheblueprinttype.*.inc
│   ├── dfscheblueprintop.*.inc
│   └── dfscheblueprintenums.*.inc
├── unitest/                         # Unit tests
│   ├── test.cpp                     # Test application
│   ├── CMakeLists.txt              # Build configuration
│   └── build/                       # Build directory
├── dfscheblueprintmanager.h         # Dialect manager header
├── dfscheblueprintmanager.cpp       # Dialect manager implementation
├── gen.sh                           # TableGen generation script
└── CMakeLists.txt                   # Library build configuration
```

## Building

### Build the unittest:
```bash
cd dfscheblueprint/unitest/build
cmake ..
make
```

### Run the test:
```bash
./test
```

## Integration with Main Project

The dialect is integrated into the main project's unittest CMakeLists.txt:

1. Include directories added
2. Manager source file added to build
3. gen.sh script added to custom target for tablegen generation

## Usage in Compiler Pipeline

The dfscheblueprint dialect can be used to:

1. **Define Schedule Templates**: Create reusable schedule patterns for common data movement scenarios
2. **Guide Routing**: Provide hints to the routing pass about optimal data paths
3. **Tiling Information**: Specify how data should be partitioned across tiles
4. **Packet Configuration**: Define packet IDs and routing parameters
5. **Metadata for Runtime**: Generate configuration data for runtime scheduling

## Future Extensions

Potential extensions to the dialect:

- Add timing constraints (latency, throughput)
- Support for conditional routing
- Multi-level tiling specifications
- Performance annotations
- Resource usage hints

