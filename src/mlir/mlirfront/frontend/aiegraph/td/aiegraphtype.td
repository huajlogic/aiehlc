/******************************************************************************
* Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: Apache-2.0
******************************************************************************/
#ifndef _TYPE_AIEGRAPH_
#define _TYPE_AIEGRAPH_
include "aiegraphattr.td"

// aiegraph expresses dataflow purely through builtin `tensor<...xi8>` SSA values
// (result of one op feeds the next), so it needs no bespoke handle types today.
// A placeholder type is defined to keep the tblgen typedef machinery wired up in
// parity with the other dialects (dmap etc.), and to leave room for a future
// opaque feature-map handle if the graph grows richer semantics.
def aiegraphfeaturetype : aiegraphtype<"aiegraphfeature"> {
    let mnemonic = "feature";
    let summary = "opaque aiegraph feature-map handle (reserved; dataflow uses builtin tensors)";
}

#endif //_TYPE_AIEGRAPH_
