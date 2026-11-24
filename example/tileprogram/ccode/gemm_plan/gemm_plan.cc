// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// int8 GEMM on the 4 x 4 mesh in the 2 x 8 SHARED-OPERAND layout -- 85.5 % of the VEK385 peak from
// this source alone (README.md; doc/design/dmaphop_dataflow_plan.md). The data movement is stated
// where the kernel loads its blocks, and the compiler derives the rest:
//
//   #pragma persistent_kernel                  load the kernel once; later launches release a go lock
//   aie::load_buffer(a, ..., {.share = aie::share::neighbor, .stage = aie::stage::memtile_ring,
//                             .ring = 10})     A: hosted in one neighbour core's memory, staged through
//                                              a MemTile FIFO ring of 10 buffers
//   aie::load_buffer(b, ..., {.share = aie::share::neighbor, .stage = aie::stage::memtile,
//                             .keep = true})   B: hosted likewise, held in a MemTile across launches
//
// Those options become `dataflow` attributes on the routing IR's tensors; the dataflow-plan synthesis
// turns them into dmaphop.plan* ops (host-tile matching, views, locks, MemTile / core / shim BDs,
// routes), and the compiler emits routing.cc / host.cc / kernel.cc and aiehlc_plan.h -- the
// constants the chess kernel below reads. The same build also works one level lower: edit the
// routing IR (AIEHLC_ROUTING_IR_IN) or write the dmaphop plan yourself (gen_plan.py,
// AIEHLC_DMAPHOP_IR_IN); an explicit plan wins over the options.
//
// C[7680 x 512] = A[7680 x 2560] . B[512 x 2560]^T per launch (10.07 G MAC). Logical grid: A in 2
// strips, B in 8 strips; core (pm, pn) computes A strip pm >> 1 x B strip pn + 4 (pm & 1), 60 tiles
// of 64 x 64 x 2560. Each core tile hosts one operand stream that two neighbours read.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#pragma persistent_kernel
#include "gemm_plan_body.cc"
