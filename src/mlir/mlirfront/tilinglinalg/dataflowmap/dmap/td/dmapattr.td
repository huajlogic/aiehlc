#ifndef  _ATTR_DMAMAP_
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

class dmamapattr<string name> : AttrDef<dmamapdialect, name>{}
class dmamaptype<string name, list<Trait> traits=[]> : TypeDef<dmamapdialect, name,traits>{}

def DMAP_SEND : I32EnumAttrCase<"DMAP_SEND", 0, "DMAP_SEND">;
def DMAP_RECEIVE : I32EnumAttrCase<"DMAP_RECEIVE", 0, "DMAP_RECEIVE">;
def dmapdirection_enum
    : I32EnumAttr<"dmapdirection", "dmap direction", [
      DMAP_SEND,
      DMAP_RECEIVE]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "dmapdialect";
}

def dmapdirectionAttr : EnumAttr<dmamapdialect, dmapdirection_enum, "direction"> {
  let assemblyFormat = "`<` $value `>`";
}

def dataaccesspattern : dmamapattr<"dataaccesspattern"> {
    let mnemonic = "datadirectionattr";
    let cppNamespace = "dmapdialect";
    let parameters = ( ins
        "dmapdirectionAttr":$direction,
        "int64_t":$sizepertran,
        "int64_t":$pingpongbuffer,
        "int64_t":$slidingaccess
    );
    let assemblyFormat = "`{` $direction `,` $sizepertran  `,` $pingpongbuffer `,` $slidingaccess `}`";

}
#endif//_ATTR_DMAMAP_