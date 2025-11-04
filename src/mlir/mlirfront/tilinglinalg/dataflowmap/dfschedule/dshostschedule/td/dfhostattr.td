//===- DsHostDialect.td ---------------------------------------*- tablegen -*-===//
include "mlir/IR/OpBase.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/BuiltinAttributes.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"

// Dialect: amd_host
def DSHost_Dialect : Dialect {
  let name = "dshost";
  let cppNamespace = "::dshost";
  let summary = "aie data flow Host-side runtime and launch control dialect";
  let description = [{
    Host-side ops for device memory, async copies, kernel launch, events and streams.
  }];
}
//=== DsHost Types/Attrs ===//
def DsHost_EventType : TypeDef<DsHost_Dialect, "Event"> {
  let mnemonic = "event";
  let summary = "Opaque async event type for host runtime";
}

def DsHost_StreamType : TypeDef<DsHost_Dialect, "Stream"> {
  let mnemonic = "stream";
  let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Host-visible stream handle carrying element type";
  let assemblyFormat = "`<` $elemTy `>`";
}

def AMD_TileAttr : AttrDef<DsHost_Dialect, "Tile"> {
  let summary = "Tile location attribute (row, col)";
  let parameters = (ins
    I64Attr:$row,
    I64Attr:$col
  );
  let assemblyFormat = "`<` `row` `=` $row `,` `col` `=` $col `>`";
}

//=== AMDDMA Types/Attrs ===//
def AMDDMA_LockType : TypeDef<AMDDMA_Dialect, "Lock"> {
  let mnemonic = "lock";
  let summary = "Abstract device lock handle";
}

def AMDDMA_DirectionAttr : EnumAttr<AMDDMA_Dialect, "Direction",
  "DMA direction", [
    EnumAttrCase<"MM2S", 0>,
    EnumAttrCase<"S2MM", 1>
  ]> {
  let cppNamespace = "::amd::dma";
}

def AMDDMA_DirectionAttrParam : AttrDef<AMDDMA_Dialect, "DirectionParam"> {
  let summary = "Wrapper to use direction in ops";
}

//=== Flow Types/Attrs ===//
def Flow_StreamType : TypeDef<Flow_Dialect, "Stream"> {
  let mnemonic = "stream";
  let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Logical stream type";
  let assemblyFormat = "`<` $elemTy `>`";
}

def Flow_ShimEndpointAttr : AttrDef<Flow_Dialect, "ShimEndpoint"> {
  let summary = "Physical SHIM endpoint binding";
  let parameters = (ins
    SymbolRefArrayAttr:$hops, // optional route, keep generic
    I64Attr:$row,
    I64Attr:$col,
    StrAttr:$port,           // "MM2S0"/"S2MM0"/etc.
    I64Attr:$channel,
    OptionalAttr<I64Attr>:$packet_id,
    OptionalAttr<I64Attr>:$vc
  );
  let assemblyFormat = [{
    `<` `tile` `=` `#dma_hop` `<` `tile` `{` `col` `=` $col `,` `row` `=` $row `}` `>`
     `,` `port` `=` $port `,` `channel` `=` $channel
     (`,` `packet_id` `=` $packet_id^)?
     (`,` `vc` `=` $vc^)?
    `>`
  }];
}