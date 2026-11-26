/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: Apache-2.0
******************************************************************************/

#ifndef _ATTR_DMAMAP_
#define _ATTR_DMAMAP_

include "mlir/IR/OpBase.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/IR/EnumAttr.td"

// Direction enum for ports
def Direction_IN  : I32EnumAttrCase<"In", 0, "in">;
def Direction_OUT : I32EnumAttrCase<"Out", 1, "out">;

def DirectionAttr : I32EnumAttr<"Direction", "Port direction attribute",
                               [Direction_IN, Direction_OUT]> {
  //let genSpecializedAttr = 0;
  let cppNamespace = "dmaphop";
}

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

class dmaphopattr<string name> : AttrDef<dmaphopdialect, name>{}
class dmaphoptype<string name, list<Trait> traits=[]> : TypeDef<dmaphopdialect, name,traits>{}
class dmaphopop<string name, list<Trait> traits=[]> : Op<dmaphopdialect, name, traits>{}

def dmaphop_portaccesspattern : dmaphopattr<"portaccesspattern"> {
    let mnemonic = "portaccesspattern";
    let cppNamespace = "dmaphop";
    let parameters = (ins
        "StringAttr":$direction,
        "int64_t":$transize,
        "int64_t":$totalsize,
        "int64_t":$pingpongbuffer,
        "int64_t":$slidingaccess
    );
    let assemblyFormat = [{
        `{` $direction `,` 
            $transize `,` 
            $totalsize `,`
            $pingpongbuffer `,` 
            $slidingaccess 
        `}`
    }];
}

// The dataflow plan's stream of one shared tensor (doc/design/dmaphop_dataflow_plan.md), on the tensor's
// dmaphop.create_path(s): staging (MemTile ring / resident), chunk geometry, the hosted-stream protocol
// (channels / slots / readers / parts), where the blocks sit in the tensor and the logical grid. The
// plan's routes are the path's create_hop ops. Every field is printed and arrays are DenseI64ArrayAttr so
// the dump parses back (skill mlirattrarrayroundtrip). Fields mirror dfplan::PlanStream.
def dmaphop_StreamAttr : dmaphopattr<"Stream"> {
    let mnemonic = "stream";
    let cppNamespace = "dmaphop";
    let parameters = (ins
        "int64_t":$arg,
        StringRefParameter<"label">:$role,
        StringRefParameter<"neighbor | broadcast | none">:$share,
        "int64_t":$channel,
        StringRefParameter<"memtile_ring | memtile | empty">:$stage,
        "int64_t":$ring,
        "bool":$resident,
        "int64_t":$chunk_rows,
        "int64_t":$chunk_cols,
        "int64_t":$tensor_rows,
        "int64_t":$tensor_cols,
        "int64_t":$chunks,
        "int64_t":$rounds,
        "::mlir::DenseI64ArrayAttr":$host_rows,
        "::mlir::DenseI64ArrayAttr":$first_rows,
        "int64_t":$channels,
        "int64_t":$slots,
        "int64_t":$readers,
        "int64_t":$parts,
        "int64_t":$elem_bytes,
        "int64_t":$row_step,
        "int64_t":$col_step,
        "int64_t":$strip_step,
        "int64_t":$row_step_j,
        "int64_t":$col_step_i,
        "::mlir::DenseI64ArrayAttr":$strip_row_base,
        "::mlir::DenseI64ArrayAttr":$strip_col_base,
        "::mlir::DenseI64ArrayAttr":$row_groups,
        "::mlir::DenseI64ArrayAttr":$strips
    );
    let assemblyFormat = [{
        `<` `arg` `=` $arg `,` `role` `=` $role `,` `share` `=` $share `,` `channel` `=` $channel `,`
        `stage` `=` $stage `,` `ring` `=` $ring `,` `resident` `=` $resident `,`
        `chunk` `=` `[` $chunk_rows `,` $chunk_cols `]` `,` `tensor` `=` `[` $tensor_rows `,` $tensor_cols `]` `,`
        `chunks` `=` $chunks `,` `rounds` `=` $rounds `,` `host_rows` `=` $host_rows `,` `first_rows` `=` $first_rows `,`
        `channels` `=` $channels `,` `slots` `=` $slots `,` `readers` `=` $readers `,` `parts` `=` $parts `,`
        `elem_bytes` `=` $elem_bytes `,` `row_step` `=` $row_step `,` `col_step` `=` $col_step `,`
        `strip_step` `=` $strip_step `,` `row_step_j` `=` $row_step_j `,` `col_step_i` `=` $col_step_i `,`
        `strip_row_base` `=` $strip_row_base `,` `strip_col_base` `=` $strip_col_base `,`
        `row_groups` `=` $row_groups `,` `strips` `=` $strips `>`
    }];
}

// One route of the dataflow plan as an attribute (the dfscheblueprint level carries the plan's routes on the
// module, dmaphop carries them as create_hop ops): the stream (arg), the source MM2S channel on a shim
// (src_shim) or a MemTile / core DMA, and the destinations as [col, row, s2mm channel] triples, flattened.
def dmaphop_RouteAttr : dmaphopattr<"Route"> {
    let mnemonic = "route";
    let cppNamespace = "dmaphop";
    let parameters = (ins
        "int64_t":$arg,
        "int64_t":$src_col,
        "int64_t":$src_row,
        "int64_t":$src_ch,
        "bool":$src_shim,
        "::mlir::DenseI64ArrayAttr":$dsts
    );
    let assemblyFormat = [{
        `<` `arg` `=` $arg `,` `src` `=` `[` $src_col `,` $src_row `,` $src_ch `]` `,` `src_shim` `=` $src_shim `,`
        `dsts` `=` $dsts `>`
    }];
}

#endif//_ATTR_DMAMAP_