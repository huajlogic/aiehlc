/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// tutorial/perfoptmize step 5: + #pragma persistent_kernel (loaded and started once; later launches release
// a go lock; BDs written once).
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#pragma persistent_kernel
#define GP_RING 2
#define GP_KEEP true
#define GP_PARTS 1
#include "gemm_plan_body.cc"
