//===- DSHostDialect.td ---------------------------------------*- tablegen -*-===//
include "mlir/IR/OpBase.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/BuiltinAttributes.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/IR/EnumAttr.td"

// Dialect: amd_host
def dshosdialect : Dialect {
  let name = "dshost";
  let cppNamespace = "::dshost";
  let summary = "aie data flow Host-side runtime and launch control dialect";
  let description = [{
    Host-side ops for device memory, async copies, kernel launch, events and streams.
  }];
}

class dshosattr<string name> : AttrDef<dshosdialect, name>{ let mnemonic = name;}
class dshostype<string name, list<Trait> traits=[]> : TypeDef<dshosdialect, name,traits>{}
class dshosop<string name, list<Trait> traits=[]> : Op<dshosdialect, name, traits>{}


def DSHost_TileAttr : dshosattr<"Tile"> {
  let summary = "Tile location attribute (row, col)";
  let parameters = (ins
    I64Attr:$row,
    I64Attr:$col
  );
  let assemblyFormat = "`<` `row` `=` $row `,` `col` `=` $col `>`";
}


def DMAP_MM2S : I32EnumAttrCase<"DMAP_MM2S", 0, "DMAP_MM2S">;
def DMAP_S2MM : I32EnumAttrCase<"DMAP_S2MM", 1, "DMAP_S2MM">;
def dsdirection_enum : I32EnumAttr<"dsdirection", "dsdirection direction", [
      DMAP_MM2S,
      DMAP_S2MM]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "dsdirection";
}

def dsdirectionAttr : EnumAttr<dshosdialect, dsdirection_enum, "io"> {
  let assemblyFormat = "`<` $value `>`";
}

def Flow_ShimEndpointAttr : dshosattr<"ShimEndpoint"> {
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