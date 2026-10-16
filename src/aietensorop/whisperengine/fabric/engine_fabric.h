/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * engine_fabric.h -- the fixed AIE fabric the Whisper engine runs on.
 *
 * resnetengine's fabric (conv2dstem's aiehlc routing, partition {2,6}: abs
 * cols 2..6, control spine on col 2, 4x4 mesh on cols 3..6 / rows 3..6) with a
 * MEMORY TILE spliced into every input route, so an operand is fetched from
 * DDR once and replayed to the cores from on-chip memory:
 *
 *   A   shim (k,0) MM2S1 -> MT_A(k-1) = memtile (k,1) S2MM0 ;
 *       MT_A MM2S0 -> broadcast to mesh row k-1          (core S2MM ch0)
 *   B   shim (k,0) MM2S0 -> MT_B(k-1) = memtile (k,2) S2MM0 ;
 *       MT_B MM2S0 -> broadcast to mesh col k-1          (core S2MM ch1)
 *   out core MM2S ch0, packet-switched, merged per mesh row into one shim
 *       S2MM channel in out-of-order mode: rows 3,4 -> shim (4,0) ch0,ch1;
 *       rows 5,6 -> (3,0) ch0,ch1
 *
 * Columns are PARTITION-RELATIVE (rel col 1..4 = absolute 3..6). Memtile DMA
 * addresses: own 512 KB at 0x80000 (0x0 = west neighbour, 0x100000 = east).
 ******************************************************************************/
#ifndef ENGINE_FABRIC_H
#define ENGINE_FABRIC_H

#define EF_PART_START_COL 2
#define EF_PART_NUM_COLS 5
#define EF_MESH_ROWS 4
#define EF_MESH_COLS 4
#define EF_FIRST_ROW 3 /* physical row of mesh row 0 */
#define EF_FIRST_COL 1 /* partition-relative col of mesh col 0 */
#define EF_MT_A_ROW 1  /* memtile row holding A (row-broadcast operand) */
#define EF_MT_B_ROW 2  /* memtile row holding B (column-broadcast operand) */
#define EF_MT_BASE 0x80000u
#define EF_MT_BYTES 0x80000u

/* Core-tile DMA plan (hardware BD ids and lock ids; kernel lock intrinsics use
 * id + EF_LOCK_BASE). */
#define EF_LOCK_BASE 48
#define EF_BD_IN_PING 0 /* S2MM ch0: A */
#define EF_BD_IN_PONG 1
#define EF_LK_IN_EMPTY 0
#define EF_LK_IN_FULL 1
#define EF_BD_W_PING 2 /* S2MM ch1: B */
#define EF_BD_W_PONG 3
#define EF_LK_W_EMPTY 2
#define EF_LK_W_FULL 3
#define EF_BD_OUT_PING 4 /* MM2S ch0: output (packets) */
#define EF_BD_OUT_PONG 5
#define EF_LK_OUT_EMPTY 4
#define EF_LK_OUT_FULL 5

/* Output packet id and out-of-order shim BD per core, [mesh row][mesh col]. */
#define EF_PKT_ID_TABLE                                                                                                \
    {                                                                                                                  \
        {4, 5, 6, 7}, {8, 9, 10, 11}, {12, 13, 14, 15}, { 17, 18, 19, 20 }                                             \
    }
#define EF_OOO_BD_TABLE                                                                                                \
    {                                                                                                                  \
        {2, 3, 4, 5}, {7, 8, 9, 10}, {3, 4, 5, 6}, { 8, 9, 10, 11 }                                                    \
    }
#define EF_OUT_SHIM_COL_TABLE {4, 4, 3, 3}
#define EF_OUT_SHIM_CH_TABLE {0, 1, 0, 1}

#endif
