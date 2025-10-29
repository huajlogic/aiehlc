#ifndef _ATTR_DMAMAP_
#define _ATTR_DMAMAP_

include "mlir/IR/OpBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/IR/EnumAttr.td"

def dmaphopdialect : Dialect {
    let name = "dmaphop";
    let cppNamespace = "dmaphop";
    //let useDefaultAttributePrinterParser = 1;
    let hasOperationAttrVerify = 0;
    let useDefaultAttributePrinterParser = 1;
	  let usePropertiesForAttributes = 0;
    let useDefaultTypePrinterParser = 1;  
    dag discardableAttrs = (ins);
}


class dmapattr<string name> : AttrDef<dmaphopdialect, name>{}
class dmaptype<string name, list<Trait> traits=[]> : TypeDef<dmaphopdialect, name,traits>{}
class dmapop<string name, list<Trait> traits=[]> : Op<dmaphopdialect, name, traits>{}

def portaccesspattern : dmapattr<"portaccesspattern"> {
    let mnemonic = "portaccesspattern";
    let cppNamespace = "dmap";
    let parameters = ( ins
        "StringAttr":$direction,
        "int64_t":$transsize,
        "int64_t":$totalsize,
        "int64_t":$pingpongbuffer,
        "int64_t":$slidingaccess
    );
    let assemblyFormat = "`{` $direction  `,` $sizepertran  `,` $pingpongbuffer `,` $slidingaccess `}`";

}

#endif//_ATTR_DMAMAP_