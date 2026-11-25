// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// The 4 x 2 dataflow-plan GEMM for an AIE-ML device (--aie-version 2). Only its NoC shim columns have a
// DMA (2, 3, 6, 7, 14, 15, ...), in pairs: the mesh sits on columns 2 and 3, where A and B take the 4 shim
// MM2S channels there are, and there is no third such column for the control-packet plane -- so no
// control-plane pragmas (the kernel loads over the config bus).
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#pragma persistent_kernel
#define GP_HW_COLS 2
#define GP_N 256 // 2 x 8 strips on 2 columns: N = 2 x 2 x 64
#define GP_PART_START 2
#include "gemm_plan_body.cc"
