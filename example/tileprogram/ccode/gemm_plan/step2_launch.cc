/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// tutorial/perfoptmize step 2: the launch is the bottleneck, so take it off the host's MMIO path --
// no partition teardown between launches, the kernel ELF + core launch over the control-packet plane
// (a warm reload resends only reset + data), the cores program their own DMA (KERNELCONFIGOFFLOAD), the
// output as whole tiles (one shim BD walks every round), uncached operands.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#define GEN_VECTOR 1
#define GEN_LAUNCH 1
#include "gemm_generic_body.cc"
