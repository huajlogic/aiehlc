#ifndef _ATTR_DMAMAP_
#define _ATTR_DMAMAP_

include "mlir/IR/OpBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/IR/EnumAttr.td"

def dmamapdialect : Dialect {
    let name = "dmamap";
    let cppNamespace = "dmamap";
    let useDefaultAttributePrinterParser = 1;
    let hasOperationAttrVerify = 0;
    let useDefaultAttributePrinterParser = 1;
	let usePropertiesForAttributes = 0;
    dag discardableAttrs = (ins);
}

class dmapattr<string name> : AttrDef<dmamapdialect, name>{}
class dmaptype<string name, list<Trait> traits=[]> : TypeDef<dmamapdialect, name,traits>{}
class dmapop<string name, list<Trait> traits=[]> : Op<dmamapdialect, name, traits>{}

def DMAP_SEND : I32EnumAttrCase<"DMAP_SEND", 0, "DMAP_SEND">;
def DMAP_RECEIVE : I32EnumAttrCase<"DMAP_RECEIVE", 0, "DMAP_RECEIVE">;
def dmapdirection_enum
    : I32EnumAttr<"dmapdirection", "dmap direction", [
      DMAP_SEND,
      DMAP_RECEIVE]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "dmap";
}

def DMAP_SHIMIO : I32EnumAttrCase<"DMAP_SHIMIO", 0, "DMAP_SHIMIO">;
def DMAP_MEMTILEIO : I32EnumAttrCase<"DMAP_MEMTILEIO", 0, "DMAP_MEMTILEIO">;
def DMAP_CORETILEIO : I32EnumAttrCase<"DMAP_CORETILEIO", 0, "DMAP_CORETILEIO">;
def dmapio_enum
    : I32EnumAttr<"dmapio", "dmap direction", [
      DMAP_SHIMIO,
      DMAP_MEMTILEIO,
      DMAP_CORETILEIO]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "dmapio";
}

def dmapdirectionAttr : EnumAttr<dmamapdialect, dmapdirection_enum, "direction"> {
  let assemblyFormat = "`<` $value `>`";
}

def dmapioAttr : EnumAttr<dmamapdialect, dmapio_enum, "direction"> {
  let assemblyFormat = "`<` $value `>`";
}

def dataaccesspattern : dmapattr<"dataaccesspattern"> {
    let mnemonic = "datadirectionattr";
    let cppNamespace = "dmap";
    let parameters = ( ins
        "dmapdirectionAttr":$direction,
        "int64_t":$sizepertran,
        "int64_t":$pingpongbuffer,
        "int64_t":$slidingaccess
    );
    let assemblyFormat = "`{` $direction `,` $sizepertran  `,` $pingpongbuffer `,` $slidingaccess `}`";

}

#endif//_ATTR_DMAMAP_