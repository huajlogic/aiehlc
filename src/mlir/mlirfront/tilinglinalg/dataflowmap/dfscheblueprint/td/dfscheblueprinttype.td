/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef _TYPE_dfscheblueprint_
#define _TYPE_dfscheblueprint_
include "dfscheblueprintattr.td"

//=== dfscheblueprint Types ===//

// Blueprint type - represents a schedule blueprint handle
def dfscheblueprint_BlueprintType : dfscheblueprinttype<"Blueprint"> {
  let mnemonic = "blueprint";
  let summary = "Schedule blueprint handle";
}

// Config type - represents a schedule configuration
def dfscheblueprint_ConfigType : dfscheblueprinttype<"Config"> {
  let mnemonic = "config";
  let summary = "Schedule configuration handle";
}

// Manifest type - represents a transfer manifest
def dfscheblueprint_ManifestType : dfscheblueprinttype<"Manifest"> {
  let mnemonic = "manifest";
  let summary = "Transfer manifest handle";
}

#endif //_TYPE_dfscheblueprint_

