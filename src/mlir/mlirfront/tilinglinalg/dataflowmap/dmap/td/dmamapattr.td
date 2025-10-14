#ifndef  _ATTR_DMAMAP_
#define _ATTR_DMAMAP_

include "mlir/IR/OpBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"

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

#endif//_ATTR_DMAMAP_