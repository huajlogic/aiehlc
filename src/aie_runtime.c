/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#include "aie_runtime.h"
#include "aie_device_map.h"
#include <stdio.h>

// Global device instances
XAie_DevInst *g_DevInst = NULL;
XAie_RoutingInstance *g_RoutingInst = NULL;

// Reference: aieml_perf.cc lines 111-281 for implementation patterns

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

    // Load ELF for each tile
    for (int i = 0; i < num_tiles; i++) {
        XAie_CoreReset(g_DevInst, tiles[i]);
        XAie_CoreUnreset(g_DevInst, tiles[i]);
        XAie_LoadElfMem(g_DevInst, tiles[i], elf_buffers[i]);
    }

    return kg;
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

    // Start all cores
    XAie_Run(g_RoutingInst, kg.num_tiles);

    return evt;
}

/**
 * Wait for kernel completion
 * Reference: aieml_perf.cc lines 189-202 (XAie_CoreWaitForDone loop)
 */
void __Runtime_wait_event(struct_event event) {
    uint8_t allDone = 0;

    do {
        allDone = 1;
        for (uint32_t i = 0; i < event.num_tiles; i++) {
            AieRC RC = XAie_CoreWaitForDone(g_DevInst, event.tiles[i], 0);
            if (RC != XAIE_OK) {
                allDone = 0;
            }
        }
    } while (!allDone);
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
