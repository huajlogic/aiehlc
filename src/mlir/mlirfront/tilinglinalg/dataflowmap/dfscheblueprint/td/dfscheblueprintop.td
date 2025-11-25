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
//-- no SymbolTable will cause the generic print when block have Symbol
//-- no NoTerminator will cause the generic print when block is empty or there is no terminate op like yeld
//-- let hasCustomAssemblyFormat = 1; will fix the generic print issue after the said fix in
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

// schedule.resource_group
def dfscheblueprint_ResourceGroupOp : dfscheblueprintop<"resource_group", [
    Symbol,
    HasParent<"ConfigOp">
  ]> {
  let summary = "Defines a group of physical tiles";
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    ArrayAttr:$tiles // Array of arrays/tuples e.g. [(0,2)]
  );
  let assemblyFormat = "$sym_name `{` `tiles` `=` $tiles `}` attr-dict";
}

// schedule.declare_data
def dfscheblueprint_DeclareDataOp : dfscheblueprintop<"declare_data", [
    HasParent<"ConfigOp">
  ]> {
  let summary = "Declares a data matrix";
  let arguments = (ins
    TypeAttr:$type
  );
  let results = (outs dfscheblueprint_DataHandleType:$result);
  let assemblyFormat = "$type attr-dict";
}

// schedule.partition
def dfscheblueprint_PartitionOp : dfscheblueprintop<"partition", [
    HasParent<"ConfigOp">
  ]> {
  let summary = "Partitions data into views";
  let arguments = (ins
    dfscheblueprint_DataHandleType:$data,
    ArrayAttr:$tile_shape
  );
  let results = (outs dfscheblueprint_ViewHandleType:$result);
  let assemblyFormat = "$data `{` `tile_shape` `=` $tile_shape `}` attr-dict";
}

// schedule.extract
def dfscheblueprint_ExtractOp : dfscheblueprintop<"extract", [
    HasParent<"ConfigOp">
  ]> {
  let summary = "Extracts a specific partition from a partitioned view";
  let arguments = (ins
    AnyType:$view,
    I32Attr:$index
  );
  let results = (outs dfscheblueprint_ViewHandleType:$result);
  let assemblyFormat = "$view `:` type($view) `{` `index` `=` $index `}` attr-dict";
}

// schedule.data_slice
def dfscheblueprint_DataSliceOp : dfscheblueprintop<"data_slice", [
    Symbol,
    HasParent<"ConfigOp">
  ]> {
  let summary = "Defines a named slice of a data view";
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    AnyType:$view,
    dfscheblueprint_SliceAttr:$slice_params
  );
  let assemblyFormat = [{
    $sym_name `{`
      `view` `=` $view `:` type($view) `,`
      `slice` `=` $slice_params
    `}` attr-dict
  }];
}

// schedule.bind
def dfscheblueprint_BindOp : dfscheblueprintop<"bind", [
    Symbol,
    HasParent<"ConfigOp">
  ]> {
  let summary = "Binds a resource to a data view";
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    SymbolRefAttr:$target,
    AnyType:$view,
    StrAttr:$slice,
    dfscheblueprint_DMAAttr:$dma,
    OptionalAttr<SymbolRefAttr>:$slice_symbol
  );
  let assemblyFormat = [{
    $sym_name `{`
      `target` `=` $target `,`
      `view` `=` $view `:` type($view) `,`
      `slice` `=` $slice `,`
      `dma` `=` $dma
      (`,` `slice_symbol` `=` $slice_symbol^)?
    `}` attr-dict
  }];
}

// schedule.bind_group
def dfscheblueprint_BindGroupOp : dfscheblueprintop<"bind_group", [
    Symbol,
    HasParent<"ConfigOp">
  ]> {
  let summary = "Binds a resource group to a data view";
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    SymbolRefAttr:$target_group,
    AnyType:$view,
    StrAttr:$distribution,
    dfscheblueprint_DMAAttr:$dma,
    OptionalAttr<ArrayAttr>:$slice_symbols
  );
  let assemblyFormat = [{
    $sym_name `{`
      `target_group` `=` $target_group `,`
      `view` `=` $view `:` type($view) `,`
      `distribution` `=` $distribution `,`
      `dma` `=` $dma
      (`,` `slice_symbols` `=` $slice_symbols^)?
    `}` attr-dict
  }];
}

// schedule.collective_transfer
def dfscheblueprint_CollectiveTransferOp : dfscheblueprintop<"collective_transfer", [
    Symbol,
    HasParent<"ConfigOp">
  ]> {
  let summary = "Defines a collective transfer between bindings";
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    StrAttr:$type,
    SymbolRefAttr:$from,
    SymbolRefAttr:$to,
    OptionalAttr<StrAttr>:$ordering,
    I32Attr:$base_packet_id
  );
  let assemblyFormat = [{
    $sym_name `{`
      `type` `=` $type `,`
      `from` `=` $from `,`
      `to` `=` $to
      (`,` `ordering` `=` $ordering^)? `,`
      `base_packet_id` `=` $base_packet_id
    `}` attr-dict
  }];
}

#endif // dfscheblueprint_OPS

