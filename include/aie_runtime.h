/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#ifndef AIE_RUNTIME_H
#define AIE_RUNTIME_H

#include "xaiengine.h"
#include <stdint.h>

// Runtime structures wrapping XAie types
typedef struct {
    XAie_DmaDesc desc;
    XAie_LocType tile_loc;
    uint8_t channel_id;
    uint8_t bd_id;
    XAie_MemInst *mem;
} struct_io;

typedef struct {
    struct_io io;
    uint32_t timeout_us;
} struct_ioevent;

typedef struct {
    XAie_LocType *tiles;
    uint32_t num_tiles;
    unsigned char **elf_buffers;
} struct_kernel_group;

typedef struct {
    XAie_LocType *tiles;
    uint32_t num_tiles;
    uint32_t timeout_us;
} struct_event;

// Global device instance (to be initialized by host)
extern XAie_DevInst *g_DevInst;
extern XAie_RoutingInstance *g_RoutingInst;

// Runtime API declarations
// Reference: aieml_perf.cc for XAie API usage patterns

// DMA and data movement
XAie_DmaDesc __Runtime_dma_bd_config(XAie_DevInst *dev, XAie_LocType tile, void *buffer, int32_t bd_id, uint64_t addr,
                                     int32_t len, int32_t next_bd, int32_t enable_packet, int32_t packet_id);

struct_io __Runtime_dma_createio(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id,
                                 XAie_MemInst *mem);

struct_ioevent __Runtime_startio(struct_io io, int32_t bd_id);

// Kernel management
struct_kernel_group __Runtime_load_kernel_group(XAie_LocType *tiles, int32_t num_tiles, unsigned char **elf_buffers);

struct_event __Runtime_launch_kernel_group(struct_kernel_group kg);

// Synchronization
void __Runtime_wait_event(struct_event event);
void __Runtime_wait_io(struct_ioevent io_event);

// Data movement wrappers (wraps XAie routing APIs)
void __Runtime_move_data_to_tile(XAie_RoutingInstance *routing, XAie_LocType shim_tile, XAie_LocType dest_tile,
                                 XAie_MemInst *mem, uint32_t size, uint32_t tile_offset);

void __Runtime_move_data_from_tile(XAie_RoutingInstance *routing, XAie_LocType src_tile, XAie_LocType shim_tile,
                                   XAie_MemInst *mem, uint32_t tile_offset, uint32_t size);

#endif // AIE_RUNTIME_H
