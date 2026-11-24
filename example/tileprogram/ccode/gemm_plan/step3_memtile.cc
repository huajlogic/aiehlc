/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// tutorial/perfoptmize step 3: the dataflow plan -- 2 x 8 shared operands (each A / B chunk stream hosted
// in one core, read by two neighbours) staged through the MemTiles: A a FIFO ring of 2 buffers, B loaded
// every launch; the kernel reloaded every launch; chunks in one memory bank.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#define GP_RING 2
#define GP_KEEP false
#define GP_PARTS 1
#include "gemm_plan_body.cc"
