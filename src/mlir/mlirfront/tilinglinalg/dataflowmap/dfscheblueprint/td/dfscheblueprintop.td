/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef dfscheblueprint_OPS
#define dfscheblueprint_OPS

include "mlir/Dialect/Arith/IR/ArithBase.td"
include "mlir/Dialect/MemRef/IR/MemRefBase.td"
include "mlir/Interfaces/CastInterfaces.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"

include "mlir/IR/BuiltinTypes.td"
include "dfscheblueprinttype.td"
// no SymbolTable will cause the generic print when block have Symbol
// no NoTerminator will cause the generic print when block is empty or there is no terminate op like yeld
// schedule.config - Top-level container for schedule blueprint
def dfscheblueprint_ConfigOp : dfscheblueprintop<"config", [
    IsolatedFromAbove,  
    SymbolTable,
    Symbol,
    SingleBlock,
    NoTerminator
  ]> {
  let summary = "Schedule configuration blueprint container";
  let description = [{
    Top-level operation that contains transfer manifests defining
    the complete data movement schedule blueprint.
    
    Example:
    ```mlir
    schedule.config @my_blueprint {
      schedule.transfer_manifest @transfer1 { ... }
      schedule.transfer_manifest @transfer2 { ... }
    }
    ```
  }];
  
  let arguments = (ins 
    SymbolNameAttr:$sym_name
  );
  
  let regions = (region SizedRegion<1>:$body);
  
  let hasCustomAssemblyFormat = 1;
}
// Symbol will cause generic print once the partent have no Symboltalbe
// schedule.transfer_manifest - Individual data transfer specification
def dfscheblueprint_TransferManifestOp : dfscheblueprintop<"transfer_manifest", [
    Symbol,
    HasParent<"ConfigOp">
  ]> {
  let summary = "Data transfer manifest with tiling and routing information";
  let description = [{
    Defines a single data transfer including:
    - payload_slice: What data to transfer (tiling definition)
    - packet_id: Packet identifier for routing
    - source: Single source endpoint (tile, direction, channel)
    - destinations: List of destination endpoints (for broadcast)
    
    Example:
    ```mlir
    schedule.transfer_manifest @broadcast_upper {
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
    ```
  }];
  
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    dfscheblueprint_SliceAttr:$payload_slice,
    I32Attr:$packet_id,
    dfscheblueprint_EndpointAttr:$source,
    ArrayAttr:$destinations  // Array of dfscheblueprint_EndpointAttr
  );
  
  let hasCustomAssemblyFormat = 1;
  
  let extraClassDeclaration = [{
    // Helper to access destination endpoints
    ArrayAttr getDestinationEndpoints() { return getDestinations(); }
  }];
}

#endif // dfscheblueprint_OPS

