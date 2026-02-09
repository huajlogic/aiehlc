/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#ifndef AIE_RUNTIME_H
#define AIE_RUNTIME_H

#include "xaiengine.h"
// #include <stdint.h>

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

// Type aliases for emitted host code (uses "io", "event", etc. without "struct" prefix)
typedef struct_io io;
typedef struct_ioevent ioevent;
typedef struct_kernel_group kernel_group;
typedef struct_event event;

// Runtime API declarations
// Reference: aieml_perf.cc for XAie API usage patterns

// DMA and data movement
XAie_DmaDesc __Runtime_dma_bd_config(XAie_DevInst *dev, XAie_LocType tile, void *buffer, int32_t bd_id, uint64_t addr,
                                     int32_t len, int32_t next_bd, int32_t enable_packet, int32_t packet_id);

struct_io __Runtime_dma_createio(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id,
                                 XAie_MemInst *mem);
/* 4-arg version for emitted host code (mem = NULL) */
struct_io __Runtime_dma_createio_4(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id);

struct_ioevent __Runtime_startio(struct_io io, int32_t bd_id);

// Kernel management
struct_kernel_group __Runtime_load_kernel_group(XAie_LocType *tiles, int32_t num_tiles, unsigned char **elf_buffers);
/* 4-tile + count version for emitted host code */
struct_kernel_group __Runtime_load_kernel_group_4t(XAie_LocType t0, XAie_LocType t1, XAie_LocType t2, XAie_LocType t3,
                                                   int n);

struct_event __Runtime_launch_kernel_group(struct_kernel_group kg);

// Synchronization
void __Runtime_wait_event(struct_event ev);
void __Runtime_wait_io(struct_ioevent io_ev);
/* C only: single name for emitted host. */
#ifndef __cplusplus
#define __Runtime_wait(x) _Generic((x), struct_event: __Runtime_wait_event, struct_ioevent: __Runtime_wait_io)(x)
#else
/* C++ overloads so emitted host can call __Runtime_wait(event_or_ioevent) */
inline void __Runtime_wait(struct_event ev) { __Runtime_wait_event(ev); }
inline void __Runtime_wait(struct_ioevent ev) { __Runtime_wait_io(ev); }
#endif

// Data movement wrappers (wraps XAie routing APIs)
void __Runtime_move_data_to_tile(XAie_RoutingInstance *routing, XAie_LocType shim_tile, XAie_LocType dest_tile,
                                 XAie_MemInst *mem, uint32_t size, uint32_t tile_offset);

void __Runtime_move_data_from_tile(XAie_RoutingInstance *routing, XAie_LocType src_tile, XAie_LocType shim_tile,
                                   XAie_MemInst *mem, uint32_t tile_offset, uint32_t size);

#endif // AIE_RUNTIME_H
