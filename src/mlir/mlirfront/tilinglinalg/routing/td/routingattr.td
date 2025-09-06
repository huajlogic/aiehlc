/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef AIE_ATTRS
#define AIE_ATTRS

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

include "mlir/IR/OpBase.td" // This line is crucial
include "mlir/IR/BuiltinTypes.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/LoopLikeInterface.td"
include "mlir/IR/AttrTypeBase.td"

def routingdialect : Dialect {
	let name = "routing";
	let cppNamespace = "routing";
	dag discardableAttrs = (ins);
	let hasOperationAttrVerify = 0;
	let useDefaultTypePrinterParser = 1;
	let useDefaultAttributePrinterParser = 1;
	let usePropertiesForAttributes = 0;
}

class routingop<string mnemonic, list<Trait> traits = []> : Op<routingdialect, mnemonic, traits>;
//class routingop<string name, list<Trait>  traits=[]> : Op<routingdialect, name, traits> {}
class routingtype<string name, list<Trait> traits=[]> : TypeDef<routingdialect, name, traits> {}
class routingattr<string name> : AttrDef<routingdialect, name> {}

def TileRangeAttr : routingattr<"TileRange"> {
  let mnemonic = "tilerangeattr";
  let cppNamespace = "routing";
  let parameters = (ins
    "int64_t":$rowNum,
    "int64_t":$colNum
  );

  let assemblyFormat = "`{` $rowNum `,` $colNum `}`";
}

def TileRangeArrayAttr : routingattr<"TileRangeArray"> {
  let mnemonic = "TileRangeArrayAttr";
  let summary = "a tile array";
  let cppNamespace = "routing";
  let parameters = (ins
    OptionalArrayRefParameter<"TileRangeAttr">:$items
  );
  let assemblyFormat = "`{` $items `}`";
}
#endif
