/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#include "aie_runtime.h"
#include "aie_device_map.h"
#include <stdio.h>

// HW generation for device config (reference: aieml_perf.cc lines 14-20)
#if AIE_GEN <= 2
#define HW_GEN XAIE_DEV_GEN_AIEML
#else
#define HW_GEN XAIE_DEV_GEN_AIE2PS
#endif

// Device layout declare: config and instance (reference: aieml_perf.cc lines 292-300)
static XAie_SetupConfig(g_Config, HW_GEN, XAIE_BASE_ADDR, XAIE_COL_SHIFT, XAIE_ROW_SHIFT,
                        XAIE_NUM_COLS, XAIE_NUM_ROWS, XAIE_SHIM_ROW,
                        XAIE_RES_TILE_ROW_START, XAIE_RES_TILE_NUM_ROWS,
                        XAIE_AIE_TILE_ROW_START, XAIE_AIE_TILE_NUM_ROWS);
static XAie_InstDeclare(g_DevInst_storage, &g_Config);

// Global device instances (set by __Runtime_device_init / __Runtime_routing_init)
XAie_DevInst *g_DevInst = NULL;
XAie_RoutingInstance *g_RoutingInst = NULL;

// Reference: aieml_perf.cc lines 111-281 for implementation patterns

/** Return 1 if tile is an AIE core tile (row >= XAIE_AIE_TILE_ROW_START), 0 for shim/res. */
static inline int __Runtime_is_aie_core_tile(XAie_LocType tile) { return tile.Row >= XAIE_AIE_TILE_ROW_START; }

/** Static buffer for kernel group tiles so kg.tiles/event.tiles outlive __Runtime_load_kernel_group_4t. */
static XAie_LocType s_kernel_tiles[4];

/**
 * Initialize device: config, backend, NPI (if gen>=2), partition (reference: aieml_perf.cc lines 316-344)
 */
AieRC __Runtime_device_init(void) {
    printf("[aie_runtime] device_init start\n");
    g_DevInst = &g_DevInst_storage;

    AieRC RC = XAie_CfgInitialize(g_DevInst, &g_Config);
    if (RC != XAIE_OK) {
        printf("[aie_runtime] device_init CfgInitialize failed: %d\n", (int)RC);
        return RC;
    }

    XAie_SetIOBackend(g_DevInst, XAIE_IO_BACKEND_BAREMETAL);

#if AIE_GEN >= 2
    if (g_DevInst->Backend->Type == XAIE_IO_BACKEND_BAREMETAL) {
#if AIE_GEN == 5
        RC = XAie_UpdateNpiAddr(g_DevInst, 0xf6d50000);
#else
        RC = XAie_UpdateNpiAddr(g_DevInst, 0xF6D10000);
#endif
        if (RC != XAIE_OK) {
            return RC;
        }
    }
    RC = XAie_PartitionInitialize(g_DevInst, NULL);
#else
    XAie_PmRequestTiles(g_DevInst, NULL, 0);
    RC = XAIE_OK;
#endif

    if (RC == XAIE_OK)
        printf("[aie_runtime] device_init OK\n");
    else
        printf("[aie_runtime] device_init partition/pm failed: %d\n", (int)RC);
    return RC;
}

/**
 * Initialize routing handler (reference: aieml_perf.cc line 128)
 * Must be called after __Runtime_device_init.
 */
void __Runtime_routing_init(void) {
    printf("[aie_runtime] routing_init start\n");
    g_RoutingInst = XAie_InitRoutingHandler(g_DevInst);
    printf("[aie_runtime] routing_init OK\n");
}

/**
 * Teardown partition (reference: aieml_perf.cc lines 348-352)
 */
AieRC __Runtime_device_teardown(void) {
    printf("[aie_runtime] device_teardown\n");
    AieRC RC = XAie_PartitionTeardown(g_DevInst);
    printf("[aie_runtime] device_teardown done rc=%d\n", (int)RC);
    return RC;
}

/**
 * Configure DMA buffer descriptor
 * Maps to XAie DMA APIs
 */
XAie_DmaDesc __Runtime_dma_bd_config(XAie_DevInst *dev, XAie_LocType tile, void *buffer, int32_t bd_id, uint64_t addr,
                                     int32_t len, int32_t next_bd, int32_t enable_packet, int32_t packet_id) {
    XAie_DmaDesc desc;
    // TODO: Use XAie_DmaDescInit and configure
    // Reference: XAie routing APIs in aieml_perf.cc
    return desc;
}

/**
 * Create I/O channel for DMA
 */
struct_io __Runtime_dma_createio(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id,
                                 XAie_MemInst *mem) {
    struct_io io;
    io.desc = dma_desc;
    io.tile_loc = tile_loc;
    io.channel_id = (uint8_t)channel_id;
    io.bd_id = (uint8_t)bd_id;
    io.mem = mem;
    return io;
}

struct_io __Runtime_dma_createio_4(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id) {
    return __Runtime_dma_createio(tile_loc, dma_desc, channel_id, bd_id, NULL);
}

/**
 * Start I/O operation (triggers DMA)
 * Reference: aieml_perf.cc lines 173-174 (XAie_MoveDataExternal2Aie)
 */
struct_ioevent __Runtime_startio(struct_io io, int32_t bd_id) {
    struct_ioevent evt;
    evt.io = io;
    evt.timeout_us = 10000; // 10ms default

    // DMA operation happens here via XAie routing
    // Actual move is done in __Runtime_move_data_* functions

    return evt;
}

/**
 * Load kernel ELF into tiles
 * Reference: aieml_perf.cc lines 123-125
 */
struct_kernel_group __Runtime_load_kernel_group(XAie_LocType *tiles, int32_t num_tiles, unsigned char **elf_buffers) {
    struct_kernel_group kg;
    kg.tiles = tiles;
    kg.num_tiles = num_tiles;
    kg.elf_buffers = elf_buffers;

    if (elf_buffers) {
        for (int i = 0; i < num_tiles; i++) {
            if (!__Runtime_is_aie_core_tile(tiles[i]))
                continue;
            XAie_CoreReset(g_DevInst, tiles[i]);
            XAie_CoreUnreset(g_DevInst, tiles[i]);
            XAie_LoadElfMem(g_DevInst, tiles[i], elf_buffers[i]);
        }
    }

    return kg;
}

struct_kernel_group __Runtime_load_kernel_group_4t(XAie_LocType t0, XAie_LocType t1, XAie_LocType t2, XAie_LocType t3,
                                                   int n) {
    printf("[aie_runtime] load_kernel_group n=%d tiles=(%u,%u)(%u,%u)(%u,%u)(%u,%u)\n", n, (unsigned)t0.Row,
           (unsigned)t0.Col, (unsigned)t1.Row, (unsigned)t1.Col, (unsigned)t2.Row, (unsigned)t2.Col, (unsigned)t3.Row,
           (unsigned)t3.Col);
    s_kernel_tiles[0] = t0;
    s_kernel_tiles[1] = t1;
    s_kernel_tiles[2] = t2;
    s_kernel_tiles[3] = t3;
    return __Runtime_load_kernel_group(s_kernel_tiles, n, NULL);
}

/**
 * Launch kernel group (start cores)
 * Reference: aieml_perf.cc line 185 (XAie_Run)
 */
struct_event __Runtime_launch_kernel_group(struct_kernel_group kg) {
    struct_event evt;
    evt.tiles = kg.tiles;
    evt.num_tiles = kg.num_tiles;
    evt.timeout_us = 100000; // 100ms default

    // Start only AIE core tiles (skip shim/res to avoid invalid tile use)
    uint32_t core_count = 0;
    for (uint32_t i = 0; i < kg.num_tiles; i++) {
        if (__Runtime_is_aie_core_tile(kg.tiles[i]))
            core_count++;
    }
    printf("[aie_runtime] launch_kernel_group num_tiles=%u core_count=%u\n", (unsigned)kg.num_tiles,
           (unsigned)core_count);
    if (core_count > 0)
        XAie_Run(g_RoutingInst, core_count);

    return evt;
}

/**
 * Wait for kernel completion
 * Reference: aieml_perf.cc lines 189-202 (XAie_CoreWaitForDone loop)
 */
void __Runtime_wait_event(struct_event event) {
    uint8_t allDone = 0;

    printf("[aie_runtime] wait_event num_tiles=%u tiles=(%u,%u)(%u,%u)(%u,%u)(%u,%u)\n", (unsigned)event.num_tiles,
           (unsigned)event.tiles[0].Row, (unsigned)event.tiles[0].Col, (unsigned)event.tiles[1].Row,
           (unsigned)event.tiles[1].Col, (unsigned)event.tiles[2].Row, (unsigned)event.tiles[2].Col,
           (unsigned)event.tiles[3].Row, (unsigned)event.tiles[3].Col);
    do {
        allDone = 1;
        for (uint32_t i = 0; i < event.num_tiles; i++) {
            /// printf("[aie_runtime] wait_event tile=%u\n", (unsigned)event.tiles[i].Row,
            /// (unsigned)event.tiles[i].Col);
            if (!__Runtime_is_aie_core_tile(event.tiles[i])) {
                printf("[aie_runtime] wait_event tile=(row %u, col %u) is not a core tile\n",
                       (unsigned)event.tiles[i].Row, (unsigned)event.tiles[i].Col);
                continue;
            }
            AieRC RC = XAie_CoreWaitForDone(g_DevInst, event.tiles[i], 0);
            printf("[aie_runtime] wait_event tile=%u rc=%d\n", (unsigned)event.tiles[i].Row,
                   (unsigned)event.tiles[i].Col, (int)RC);
            if (RC != XAIE_OK) {
                allDone = 0;
            }
        }
    } while (!allDone);
    printf("[aie_runtime] wait_event done\n");
}

/**
 * Wait for I/O completion (DMA wait)
 * Reference: aieml_perf.cc line 181 (XAie_RouteDmaWait)
 */
void __Runtime_wait_io(struct_ioevent io_event) {
    // Optional: XAie_RouteDmaWait can be used here
    // For now, synchronous operation assumed
}

/**
 * Move data from DDR to AIE tile
 * Reference: aieml_perf.cc lines 173-174
 */
void __Runtime_move_data_to_tile(XAie_RoutingInstance *routing, XAie_LocType shim_tile, XAie_LocType dest_tile,
                                 XAie_MemInst *mem, uint32_t size, uint32_t tile_offset) {
    // Sync memory for device access
    XAie_MemSyncForDev(mem);

    // Move data using routing API
    XAie_MoveDataExternal2Aie(routing, shim_tile, mem, size, tile_offset, dest_tile);
}

/**
 * Move data from AIE tile to DDR
 * Reference: aieml_perf.cc lines 206-208
 */
void __Runtime_move_data_from_tile(XAie_RoutingInstance *routing, XAie_LocType src_tile, XAie_LocType shim_tile,
                                   XAie_MemInst *mem, uint32_t tile_offset, uint32_t size) {
    // Sync memory for CPU access
    XAie_MemSyncForCPU(mem);

    // Move data using routing API
    XAie_MoveDataAie2External(routing, src_tile, tile_offset, size, mem, shim_tile);
}
