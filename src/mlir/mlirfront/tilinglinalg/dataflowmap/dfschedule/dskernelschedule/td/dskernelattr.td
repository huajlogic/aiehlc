//===- dskernelDialect.td ---------------------------------------*- tablegen -*-===//
include "mlir/IR/OpBase.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/BuiltinAttributes.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/IR/EnumAttr.td"

// Dialect: amd_host
def dskerneldialect : Dialect {
    let name = "dskernel";
    let cppNamespace = "dskernel";
    //let useDefaultAttributePrinterParser = 1;
    let hasOperationAttrVerify = 0;
    let useDefaultAttributePrinterParser = 1;
	let usePropertiesForAttributes = 0;
    let useDefaultTypePrinterParser = 1;  
    dag discardableAttrs = (ins);
}

class dskernelattr<string name> : AttrDef<dskerneldialect, name>{ let mnemonic = name;}
class dskerneltype<string name, list<Trait> traits=[]> : TypeDef<dskerneldialect, name,traits>{}
class dskernelop<string name, list<Trait> traits=[]> : Op<dskerneldialect, name, traits>{}


