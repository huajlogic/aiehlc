/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#include "aie_runtime.h"
#include "aie_device_map.h"
#include "aie_runtime_stream_debug.h"
#include "sleep.h"
#include "xaiengine/xaie_helper.h"
#include "xil_cache.h"
#include <stdio.h>

// HW generation for device config (reference: aieml_perf.cc lines 14-20)
#if AIE_GEN <= 2
#define HW_GEN XAIE_DEV_GEN_AIEML
#else
#define HW_GEN XAIE_DEV_GEN_AIE2PS
#endif

extern void routing();
// Device layout declare: config and instance (reference: aieml_perf.cc lines 292-300)
static XAie_SetupConfig(g_Config, HW_GEN, XAIE_BASE_ADDR, XAIE_COL_SHIFT, XAIE_ROW_SHIFT,
                        XAIE_NUM_COLS, XAIE_NUM_ROWS, XAIE_SHIM_ROW,
                        XAIE_RES_TILE_ROW_START, XAIE_RES_TILE_NUM_ROWS,
                        XAIE_AIE_TILE_ROW_START, XAIE_AIE_TILE_NUM_ROWS);
static XAie_InstDeclare(g_DevInst_storage, &g_Config);

// Global device instances (set by __Runtime_device_init / __Runtime_routing_init)
XAie_DevInst *g_DevInst = NULL;
XAie_RoutingInstance *g_RoutingInst = NULL;

// Debug verbosity: 0=silent (default), set >0 to enable runtime diagnostics
// 1 NO core DMA address log value write logic
// 2 core DMA address log + write pattern + readback logic
// Weak symbol: user source can override via #pragma aie_debug_level N
__attribute__((weak)) int g_runtime_debug_level = 0;

/* Forward declarations for auto-init */
static void __Runtime_auto_init(void) __attribute__((constructor));
static void __Runtime_auto_teardown(void) __attribute__((destructor));

// Reference: aieml_perf.cc lines 111-281 for implementation patterns

/** Return 1 if tile is an AIE core tile (row >= XAIE_AIE_TILE_ROW_START), 0 for shim/res. */
static inline int __Runtime_is_aie_core_tile(XAie_LocType tile) { return tile.Row >= XAIE_AIE_TILE_ROW_START; }

/** Static buffer for kernel group tiles so kg.tiles/event.tiles outlive __Runtime_load_kernel_group_*. */
#define MAX_KERNEL_TILES 32
static XAie_LocType s_kernel_tiles[MAX_KERNEL_TILES];

/* ---------------------------------------------------------------------------
 * BD tracking: records every dma_bd_config call when debug is enabled.
 * __Runtime_free prints the table and dumps the first 16 int32 values for
 * shim tile entries (those have a valid DDR buffer pointer).
 * ----------------------------------------------------------------------- */
typedef struct {
    uint8_t col;
    uint8_t row;
    uint8_t bd_id;
    uint8_t tile_type; /* XAIEGBL_TILE_TYPE_* value from XAie_GetTileTypefromLoc */
    void *buffer;      /* DDR pointer for shim tiles, NULL for core tiles */
    uint64_t dma_addr; /* physical addr programmed into the BD */
    int32_t len;       /* length in bytes */
    int32_t packet_id;
    int8_t direction;  /* -1=unknown, 0=DMA_S2MM, 1=DMA_MM2S (set by startio) */
    int8_t channel_id; /* -1=unknown (set by startio) */
    int8_t next_bd;    /* next BD in chain (-1 = none) */
} BdTrackEntry;

static const char *__bd_tile_type_str(uint8_t tt) {
    switch (tt) {
    case XAIEGBL_TILE_TYPE_SHIMNOC:
        return "SHIM_NOC";
    case XAIEGBL_TILE_TYPE_SHIMPL:
        return "SHIM_PL";
    case XAIEGBL_TILE_TYPE_AIETILE:
        return "CORE";
    case XAIEGBL_TILE_TYPE_MEMTILE:
        return "MEM";
    default:
        return "UNKNOWN";
    }
}

static int __bd_is_shim(uint8_t tt) { return (tt == XAIEGBL_TILE_TYPE_SHIMNOC || tt == XAIEGBL_TILE_TYPE_SHIMPL); }

#define BD_TRACK_MAX 64
static BdTrackEntry g_bd_track[BD_TRACK_MAX];
static int g_bd_track_count = 0;

/* ---------------------------------------------------------------------------
 * Allocation tracking for PartitionTensor strided-slice allocations
 * __Runtime_extract_slice_strided_2d allocates via XAie_MemAllocate;
 * we track those here so __Runtime_free_all_allocs can release them.
 * ----------------------------------------------------------------------- */
#define ALLOC_LIST_MAX_SIZE 256
static XAie_MemInst *g_alloc_mem_list[ALLOC_LIST_MAX_SIZE];
static int g_alloc_mem_count = 0;
static bool g_dumped_done = false;

void __Runtime_track_alloc(XAie_MemInst *mem) {
    if (g_alloc_mem_count < ALLOC_LIST_MAX_SIZE) {
        g_alloc_mem_list[g_alloc_mem_count++] = mem;
    }
}

void __Runtime_free_all_allocs(void) {
    for (int i = 0; i < g_alloc_mem_count; i++) {
        if (g_alloc_mem_list[i]) {
            XAie_MemFree(g_alloc_mem_list[i]);
            g_alloc_mem_list[i] = NULL;
        }
    }
    g_alloc_mem_count = 0;
}

/* ---------------------------------------------------------------------------
 * Kernel log reader: reads the last 2KB of core tile data memory where
 * kernel_log.h writes [tag, value] pairs via volatile stores.
 * Log region: data memory offset 0xF800, 512 int32 slots.
 *   slot[0]   = write_index (number of int32s written)
 *   slot[1,2] = first entry [tag_packed, value]
 *   slot[3,4] = second entry ...
 * Tag is 4 ASCII chars packed big-endian into int32.
 * ----------------------------------------------------------------------- */
#define KLOG_DM_OFFSET 0xF800
#define KLOG_REGION_BYTES 2048
#define KLOG_MAGIC_VAL 0x4B4C4F47 /* "KLOG" */

void __Runtime_read_kernel_log(XAie_DevInst *dev, XAie_LocType tile) {
    int32_t buf[512];
    memset(buf, 0, sizeof(buf));

    AieRC rc = XAie_DataMemBlockRead(dev, tile, KLOG_DM_OFFSET, (void *)buf, KLOG_REGION_BYTES);
    if (rc != XAIE_OK) {
        printf("[kernel_log] tile(%u,%u): read failed rc=%d\n", (unsigned)tile.Col, (unsigned)tile.Row, (int)rc);
        return;
    }

    int32_t wi = buf[0];
    if (wi <= 0 || wi > 511) {
        printf("[kernel_log] tile(%u,%u): no log (write_index=%d)\n", (unsigned)tile.Col, (unsigned)tile.Row, wi);
        return;
    }

    int num_entries = wi / 2;
    printf("[kernel_log] tile(%u,%u): %d entries\n", (unsigned)tile.Col, (unsigned)tile.Row, num_entries);

    for (int i = 0; i < wi; i += 2) {
        int32_t tag_raw = buf[i + 1];
        int32_t val = buf[i + 2];
        char tag[5];
        tag[0] = (char)((tag_raw >> 24) & 0xFF);
        tag[1] = (char)((tag_raw >> 16) & 0xFF);
        tag[2] = (char)((tag_raw >> 8) & 0xFF);
        tag[3] = (char)(tag_raw & 0xFF);
        tag[4] = '\0';
        printf("  [%d] %s = %d (0x%08x)\n", i / 2, tag, val, (unsigned)val);
    }
}

/* ---------------------------------------------------------------------------
 * Plain heap wrappers for DDR buffers in the host init chain
 * ScheduleCanonicalizePass emits __Runtime_malloc / __Runtime_memcpy /
 * __Runtime_free for the arith.constant → memref.alloc → memref.copy chain
 * that initialises DDR data before DMA operations begin.
 * ----------------------------------------------------------------------- */
#include <stdlib.h>

void *__Runtime_malloc(size_t bytes) {
    void *ptr = malloc(bytes);
    printf("[aie_runtime] malloc(%zu) = %p\n", bytes, ptr);
    return ptr;
}

void __Runtime_free(void *ptr) {
    printf("[aie_runtime] free(%p)\n", ptr);
    /* Dump key regions of buffer: offset 0-63 (round0 out), 256-319 (round1 out) */
    {
        int8_t *p8 = (int8_t *)ptr;
        printf("[aie_runtime] free buf [0..63]: ");
        for (int j = 0; j < 64; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [64..127]: ");
        for (int j = 64; j < 128; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [128..191]: ");
        for (int j = 128; j < 192; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [192..255]: ");
        for (int j = 192; j < 256; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [256..319]: ");
        for (int j = 256; j < 320; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [320..383]: ");
        for (int j = 320; j < 384; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [384..447]: ");
        for (int j = 384; j < 448; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
        printf("[aie_runtime] free buf [448..511]: ");
        for (int j = 448; j < 512; j++)
            printf("%d ", (int)p8[j]);
        printf("\n");
    }
    if (g_runtime_debug_level >= 1 && !g_dumped_done) {
        g_dumped_done = true;
        printf("[aie_runtime] BD tracking dump (%d entries):\n", g_bd_track_count);
        for (int i = 0; i < g_bd_track_count; i++) {
            BdTrackEntry *e = &g_bd_track[i];
            const char *dir_label = (e->direction == 0) ? "S2MM" : (e->direction == 1) ? "MM2S" : "???";
            const char *type_str = __bd_tile_type_str(e->tile_type);
            int is_shim = __bd_is_shim(e->tile_type);
            printf("[aie_runtime]   [%d] tile(%u,%u) [%s] bd=%u dir=%s ch=%d pkt_id=%d addr=0x%lx len=%d\n", i,
                   (unsigned)e->col, (unsigned)e->row, type_str, (unsigned)e->bd_id, dir_label, (int)e->channel_id,
                   e->packet_id, (unsigned long)e->dma_addr, e->len);
            if (is_shim && e->buffer != NULL) {
                int8_t *data = (int8_t *)e->buffer;
                int byte_len = e->len;
                printf("[aie_runtime]     shim_buf tile(%u,%u) [%s] dir=%s ch=%d @%p [0..%d] (int8):", (unsigned)e->col,
                       (unsigned)e->row, type_str, dir_label, (int)e->channel_id, e->buffer, byte_len - 1);
                for (int j = 0; j < byte_len; j++)
                    printf(" %d", (int)data[j]);
                printf("\n");
            }
        }
    }
    free(ptr);
}

void __Runtime_memcpy(void *dst, const void *src, size_t bytes) {
    printf("[aie_runtime] memcpy(dst=%p, src=%p, bytes=%zu)\n", dst, src, bytes);
    memcpy(dst, src, bytes);
    /* Concise int8 summary: print first 64 bytes */
    printf("[aie_runtime] memcpy data (int8): ");
    int8_t *p = (int8_t *)dst;
    int n = (int)bytes < 64 ? (int)bytes : 64;
    for (int i = 0; i < n; i++)
        printf("%d ", (int)p[i]);
    if ((int)bytes > 64)
        printf("...");
    printf("\n");
}

/* Kernel ELF embedded as binary blob by hostcompile.sh (ld -EL -r -b binary + redefine_symbols) */
extern unsigned char _binary_kernel_computekernel_start[];
extern unsigned char _binary_kernel_computekernel_end[];
extern unsigned int _binary_kernel_computekernel_size;

XAie_DevInst *getOrCreateDeviceInstance() {
    if (g_DevInst == NULL) {
        AieRC RC = __Runtime_device_init();
        if (RC != XAIE_OK) {
            printf("[aie_runtime] getOrCreateDeviceInstance failed: %d\n", (int)RC);
            return NULL;
        }
    }
    return g_DevInst;
}

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
 */
void __Runtime_platform_init(void) {
    // FIXME: use cache coherency logic and comments this cache disable logic
    Xil_DCacheDisable();
    Xil_ICacheDisable();
}

/**
 * Initialize routing handler (reference: aieml_perf.cc line 128)
 * Must be called after __Runtime_device_init.
 */
void __Runtime_routing_init(void) {
    printf("[aie_runtime] routing_init start\n");
    g_RoutingInst = XAie_InitRoutingHandler(g_DevInst);
    routing();
    printf("[aie_runtime] 2-routing_init OK----\n");
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
 * Configure DMA buffer descriptor.
 * @param len  Transfer length in bytes.
 */
XAie_DmaDesc __Runtime_dma_bd_config(XAie_DevInst *dev, XAie_LocType tile, void *buffer, int32_t bd_id, uint64_t addr,
                                     int32_t len, int32_t next_bd, int32_t enable_packet, int32_t packet_id,
                                     int32_t acquire_lock_id, int32_t acquire_lock_val, int32_t release_lock_id,
                                     int32_t release_lock_val) {
    XAie_DmaDesc DmaInst;
    XAie_DmaDescInit(dev, &DmaInst, tile);
    uint8_t tile_type = XAie_GetTileTypefromLoc(dev, tile);
    /* Both shim and core tiles: buffer is a byte address.
     * Shim tiles: buffer IS the DDR physical address.
     * Core tiles: buffer is a DMA-view byte address (core_proc_addr - 0x70000),
     *   produced by passblueprinttoschedule after CoreMemAllocator conversion. */
    uint64_t dma_addr = (uint64_t)(uintptr_t)buffer;
    XAie_DmaSetAddrLen(&DmaInst, dma_addr, (uint32_t)len);

    if (acquire_lock_id >= 0 && release_lock_id >= 0) {
        XAie_DmaSetLock(&DmaInst, XAie_LockInit(acquire_lock_id, acquire_lock_val),
                        XAie_LockInit(release_lock_id, release_lock_val));
    }

    if (next_bd >= 0) {
        XAie_DmaSetNextBd(&DmaInst, (uint8_t)next_bd, XAIE_ENABLE);
    }

    if (enable_packet) {
        XAie_DmaSetPkt(&DmaInst, XAie_PacketInit(packet_id, 0));
    }

    XAie_DmaEnableBd(&DmaInst);
    AieRC bd_rc = XAie_DmaWriteBd(dev, &DmaInst, tile, (uint8_t)bd_id);
    printf("[aie_runtime] bd_config tile(%u,%u) bd=%d addr=0x%lx len=%d next=%d lock_acq=%d/%d lock_rel=%d/%d "
           "pkt=%d/%d rc=%d\n",
           (unsigned)tile.Col, (unsigned)tile.Row, bd_id, (unsigned long)dma_addr, len, next_bd, acquire_lock_id,
           acquire_lock_val, release_lock_id, release_lock_val, enable_packet, packet_id, (int)bd_rc);

    /* Track this BD for debug dump in __Runtime_free */
    if (g_runtime_debug_level >= 1 && g_bd_track_count < BD_TRACK_MAX) {
        BdTrackEntry *e = &g_bd_track[g_bd_track_count++];
        e->col = tile.Col;
        e->row = tile.Row;
        e->bd_id = (uint8_t)bd_id;
        e->tile_type = tile_type;
        e->buffer = __bd_is_shim(tile_type) ? buffer : NULL;
        e->dma_addr = dma_addr;
        e->len = len;
        e->packet_id = packet_id;
        e->direction = -1;  /* unknown until startio */
        e->channel_id = -1; /* unknown until startio */
        e->next_bd = (int8_t)next_bd;
    }

    if (g_runtime_debug_level >= 2) {
        if (tile_type == XAIEGBL_TILE_TYPE_AIETILE) {
            printf("[aie_runtime] bd_config core(%u,%u) bd=%d dma_addr=0x%lx len=%d pkt_id=%d\n", (unsigned)tile.Col,
                   (unsigned)tile.Row, bd_id, (unsigned long)dma_addr, len, packet_id);
            /* Write pattern col*100+row*10+bd_id into the BD region at dma_addr.
             * len is in bytes; convert to int32 count for the pattern array.
             * ping BD (buffer=0) writes at byte 0; pong BD (buffer=64) writes at byte 256.
             * Covers the full BD transfer so shim sees consistent values (RC-1 fix). */
            int32_t dbg_pat[64];
            int32_t pat_val = (int32_t)(tile.Col * 100 + tile.Row * 10 + bd_id);
            int32_t write_words = len / (int32_t)sizeof(int32_t);
            if (write_words <= 0)
                write_words = 1;
            if (write_words > 64)
                write_words = 64;
            for (int _i = 0; _i < write_words; _i++)
                dbg_pat[_i] = pat_val;
            XAie_DataMemBlockWrite(dev, tile, (u32)dma_addr, dbg_pat, (u32)(write_words * sizeof(int32_t)));
            /* Read back and print to verify */
            int32_t dbg_read[64];
            XAie_DataMemBlockRead(dev, tile, (u32)dma_addr, dbg_read, (u32)(write_words * sizeof(int32_t)));
            printf("[aie_runtime] core(%u,%u) bd=%d dma_addr=0x%lx pat=%d read:", (unsigned)tile.Col,
                   (unsigned)tile.Row, bd_id, (unsigned long)dma_addr, pat_val);
            for (int _i = 0; _i < write_words; _i++)
                printf(" %d", dbg_read[_i]);
            printf("\n");
        } else {
            printf("[aie_runtime] bd_config shim(%u,%u) bd=%d dma_addr=0x%lx len=%d pkt_id=%d buf=%p\n",
                   (unsigned)tile.Col, (unsigned)tile.Row, bd_id, (unsigned long)dma_addr, len, packet_id, buffer);
        }
    }

    return DmaInst;
}

/**
 * Configure DMA buffer descriptor with multi-dimensional addressing.
 * Uses XAie_DmaSetMultiDimAddr with stride/wrap descriptors to enable
 * DMA hardware transpose/reshape during data transfer.
 * @param len  Transfer length in bytes.
 */
XAie_DmaDesc __Runtime_dma_bd_config_multidim(XAie_DevInst *dev, XAie_LocType tile, void *buffer, int32_t bd_id,
                                              uint64_t addr, int32_t len, int32_t next_bd, int32_t enable_packet,
                                              int32_t packet_id, int32_t acquire_lock_id, int32_t acquire_lock_val,
                                              int32_t release_lock_id, int32_t release_lock_val, int32_t num_dims,
                                              int32_t dim_stride0, int32_t dim_wrap0, int32_t dim_stride1,
                                              int32_t dim_wrap1, int32_t dim_stride2, int32_t dim_wrap2,
                                              int32_t dim_stride3, int32_t dim_wrap3) {

    XAie_DmaDesc DmaInst;
    XAie_DmaDescInit(dev, &DmaInst, tile);
    uint8_t tile_type = XAie_GetTileTypefromLoc(dev, tile);
    uint64_t dma_addr = (uint64_t)(uintptr_t)buffer;

    /* Build dimension descriptors from stride/wrap pairs */
    XAie_DmaDimDesc dimDescs[4];
    int32_t strides[4] = {dim_stride0, dim_stride1, dim_stride2, dim_stride3};
    int32_t wraps[4] = {dim_wrap0, dim_wrap1, dim_wrap2, dim_wrap3};
    if (num_dims > 4)
        num_dims = 4;
    for (int i = 0; i < num_dims; i++) {
        dimDescs[i].AieMlDimDesc.StepSize = (uint32_t)strides[i];
        dimDescs[i].AieMlDimDesc.Wrap = (uint16_t)wraps[i];
    }
    XAie_DmaTensor tensor;
    tensor.NumDim = (uint8_t)num_dims;
    tensor.Dim = dimDescs;
    XAie_DmaSetMultiDimAddr(&DmaInst, &tensor, dma_addr, (uint32_t)len);

    if (acquire_lock_id >= 0 && release_lock_id >= 0) {
        XAie_DmaSetLock(&DmaInst, XAie_LockInit(acquire_lock_id, acquire_lock_val),
                        XAie_LockInit(release_lock_id, release_lock_val));
    }

    if (next_bd >= 0) {
        XAie_DmaSetNextBd(&DmaInst, (uint8_t)next_bd, XAIE_ENABLE);
    }

    if (enable_packet) {
        XAie_DmaSetPkt(&DmaInst, XAie_PacketInit(packet_id, 0));
    }

    XAie_DmaEnableBd(&DmaInst);
    AieRC bd_rc = XAie_DmaWriteBd(dev, &DmaInst, tile, (uint8_t)bd_id);
    printf("[aie_runtime] bd_config_multidim tile(%u,%u) bd=%d addr=0x%lx len=%d next=%d "
           "lock_acq=%d/%d lock_rel=%d/%d pkt=%d/%d num_dims=%d rc=%d\n",
           (unsigned)tile.Col, (unsigned)tile.Row, bd_id, (unsigned long)dma_addr, len, next_bd, acquire_lock_id,
           acquire_lock_val, release_lock_id, release_lock_val, enable_packet, packet_id, num_dims, (int)bd_rc);
    for (int i = 0; i < num_dims; i++) {
        printf("[aie_runtime]   dim[%d] stride=%d wrap=%d\n", i, strides[i], wraps[i]);
    }

    /* Track this BD for debug dump */
    if (g_runtime_debug_level >= 1 && g_bd_track_count < BD_TRACK_MAX) {
        BdTrackEntry *e = &g_bd_track[g_bd_track_count++];
        e->col = tile.Col;
        e->row = tile.Row;
        e->bd_id = (uint8_t)bd_id;
        e->tile_type = tile_type;
        e->buffer = __bd_is_shim(tile_type) ? buffer : NULL;
        e->dma_addr = dma_addr;
        e->len = len;
        e->packet_id = packet_id;
        e->direction = -1;
        e->channel_id = -1;
        e->next_bd = (int8_t)next_bd;
    }

    return DmaInst;
}

/**
 * Create I/O channel for DMA
 */
struct_io __Runtime_dma_createio(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id,
                                 XAie_DmaDirection direction, XAie_MemInst *mem) {
    struct_io io;
    io.desc = dma_desc;
    io.tile_loc = tile_loc;
    io.channel_id = (uint8_t)channel_id;
    io.bd_id = (uint8_t)bd_id;
    io.direction = direction;
    io.mem = mem;
    return io;
}

struct_io __Runtime_dma_createio_4(XAie_LocType tile_loc, XAie_DmaDesc dma_desc, int32_t channel_id, int32_t bd_id,
                                   XAie_DmaDirection direction) {
    return __Runtime_dma_createio(tile_loc, dma_desc, channel_id, bd_id, direction, NULL);
}

/**
 * Start I/O operation (triggers DMA)
 * Reference: aieml_perf.cc lines 173-174 (XAie_MoveDataExternal2Aie)
 */
struct_ioevent __Runtime_startio(struct_io io, int32_t bd_id) {
    struct_ioevent evt;
    evt.io = io;
    evt.timeout_us = 10000;

    const char *dir_str = (io.direction == DMA_MM2S) ? "MM2S" : "S2MM";
    printf("[aie_runtime] startio tile(%u,%u) ch=%u dir=%s bd=%u\n", (unsigned)io.tile_loc.Col,
           (unsigned)io.tile_loc.Row, (unsigned)io.channel_id, dir_str, (unsigned)io.bd_id);

    /* Update BD tracking entries with direction/channel from this startio.
     * Match by tile (col,row) and bd_id, then follow next_bd chains. */
    {
        int8_t target_bd = (int8_t)io.bd_id;
        int visited[BD_TRACK_MAX] = {0};
        while (target_bd >= 0) {
            int found = 0;
            for (int _t = 0; _t < g_bd_track_count; _t++) {
                BdTrackEntry *e = &g_bd_track[_t];
                if (e->col == io.tile_loc.Col && e->row == io.tile_loc.Row && e->bd_id == target_bd) {
                    e->direction = (int8_t)io.direction;
                    e->channel_id = (int8_t)io.channel_id;
                    if (!visited[_t]) {
                        visited[_t] = 1;
                        target_bd = e->next_bd;
                        found = 1;
                    }
                    break;
                }
            }
            if (!found)
                break;
            /* Avoid infinite loop on circular chains (ping-pong) */
        }
    }

    AieRC rc =
        XAie_DmaChannelSetStartQueue(g_DevInst, io.tile_loc, io.channel_id, io.direction, io.bd_id, 1, XAIE_DISABLE);
    if (rc != XAIE_OK) {
        printf("[aie_runtime] startio FAILED rc=%d tile(%u,%u) ch=%u dir=%s bd=%u\n", (int)rc,
               (unsigned)io.tile_loc.Col, (unsigned)io.tile_loc.Row, (unsigned)io.channel_id, dir_str,
               (unsigned)io.bd_id);
    }

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

    /* Load the embedded kernel ELF into each core tile
     * (same pattern as aout/host.cc: CoreReset -> CoreUnreset -> LoadElfMem) */
    for (int i = 0; i < n; i++) {
        if (!__Runtime_is_aie_core_tile(s_kernel_tiles[i]))
            continue;
        printf("[aie_runtime] loading kernel ELF into tile (%u,%u)\n", (unsigned)s_kernel_tiles[i].Col,
               (unsigned)s_kernel_tiles[i].Row);
        XAie_CoreReset(g_DevInst, s_kernel_tiles[i]);
        XAie_CoreUnreset(g_DevInst, s_kernel_tiles[i]);
        XAie_LoadElfMem(g_DevInst, s_kernel_tiles[i], _binary_kernel_computekernel_start);
    }

    struct_kernel_group kg;
    kg.tiles = s_kernel_tiles;
    kg.num_tiles = n;
    kg.elf_buffers = NULL;
    return kg;
}

/** Array-based variant: copies caller-provided tile array into the static buffer
 *  and loads the kernel ELF into each core tile. Supports up to MAX_KERNEL_TILES. */
struct_kernel_group __Runtime_load_kernel_group_nt(XAie_LocType *tiles, int n) {
    printf("[aie_runtime] load_kernel_group_nt n=%d\n", n);
    if (n > MAX_KERNEL_TILES) {
        printf("[aie_runtime] WARNING: tile count %d exceeds MAX_KERNEL_TILES %d, clamping\n", n, MAX_KERNEL_TILES);
        n = MAX_KERNEL_TILES;
    }
    for (int i = 0; i < n; i++) {
        s_kernel_tiles[i] = tiles[i];
        printf("[aie_runtime]   tile[%d] = (%u,%u)\n", i, (unsigned)tiles[i].Col, (unsigned)tiles[i].Row);
    }
    for (int i = 0; i < n; i++) {
        if (!__Runtime_is_aie_core_tile(s_kernel_tiles[i]))
            continue;
        printf("[aie_runtime] loading kernel ELF into tile (%u,%u)\n", (unsigned)s_kernel_tiles[i].Col,
               (unsigned)s_kernel_tiles[i].Row);
        XAie_CoreReset(g_DevInst, s_kernel_tiles[i]);
        XAie_CoreUnreset(g_DevInst, s_kernel_tiles[i]);
        XAie_LoadElfMem(g_DevInst, s_kernel_tiles[i], _binary_kernel_computekernel_start);
    }
    struct_kernel_group kg;
    kg.tiles = s_kernel_tiles;
    kg.num_tiles = n;
    kg.elf_buffers = NULL;
    return kg;
}

struct_kernel_group __Runtime_load_kernel_group_8t(XAie_LocType t0, XAie_LocType t1, XAie_LocType t2, XAie_LocType t3,
                                                   XAie_LocType t4, XAie_LocType t5, XAie_LocType t6, XAie_LocType t7,
                                                   int n) {
    XAie_LocType arr[] = {t0, t1, t2, t3, t4, t5, t6, t7};
    return __Runtime_load_kernel_group_nt(arr, n);
}

struct_kernel_group __Runtime_load_kernel_group_16t(XAie_LocType t0, XAie_LocType t1, XAie_LocType t2, XAie_LocType t3,
                                                    XAie_LocType t4, XAie_LocType t5, XAie_LocType t6, XAie_LocType t7,
                                                    XAie_LocType t8, XAie_LocType t9, XAie_LocType t10,
                                                    XAie_LocType t11, XAie_LocType t12, XAie_LocType t13,
                                                    XAie_LocType t14, XAie_LocType t15, int n) {
    XAie_LocType arr[] = {t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15};
    return __Runtime_load_kernel_group_nt(arr, n);
}

/**
 * Enable AIE cores using transaction batching.
 * Reference: aeg_runtime_api.cpp graph_api::run() lines 176-181
 */
void __Runtime_core_run(XAie_LocType *tiles, uint32_t num_tiles) {
    XAie_StartTransaction(g_DevInst, XAIE_TRANSACTION_ENABLE_AUTO_FLUSH);
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (__Runtime_is_aie_core_tile(tiles[i]))
            XAie_CoreEnable(g_DevInst, tiles[i]);
    }
    XAie_SubmitTransaction(g_DevInst, NULL);
}

/**
 * Launch kernel group (start cores)
 * Reference: aeg_runtime_api.cpp graph_api::run()
 */
struct_event __Runtime_launch_kernel_group(struct_kernel_group kg) {
    struct_event evt;
    evt.tiles = kg.tiles;
    evt.num_tiles = kg.num_tiles;
    evt.timeout_us = 100000;

    printf("[aie_runtime] launch_kernel_group num_tiles=%u\n", (unsigned)kg.num_tiles);
    __Runtime_core_run(kg.tiles, kg.num_tiles);

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
    uint32_t timeout_iters = 100;
    uint32_t iter = 0;
    do {
        allDone = 1;
        for (uint32_t i = 0; i < event.num_tiles; i++) {
            if (!__Runtime_is_aie_core_tile(event.tiles[i])) {
                continue;
            }
            AieRC RC = XAie_CoreWaitForDone(g_DevInst, event.tiles[i], 0);
            if (RC != XAIE_OK) {
                allDone = 0;
            }
        }
        iter++;
    } while (!allDone && iter < timeout_iters);
    if (allDone)
        printf("[aie_runtime] wait_event done\n");
    else
        printf("[aie_runtime] wait_event TIMEOUT after %u iters - continuing to debug snapshot\n", iter);

    /* Read kernel logs immediately after cores are done (or timed out).
     * This must happen here rather than in auto_teardown because the
     * console capture window may expire before teardown runs
     * (wait_io timeouts + debug snapshot can exceed the capture budget). */
    for (uint32_t i = 0; i < event.num_tiles; i++) {
        if (__Runtime_is_aie_core_tile(event.tiles[i]))
            __Runtime_read_kernel_log(g_DevInst, event.tiles[i]);
    }
}

/**
 * Wait for I/O completion (DMA wait)
 * Polls XAie_DmaGetPendingBdCount until the channel has zero pending BDs,
 * meaning both the start queue is empty and no BD is currently executing.
 * Reference: aeg_runtime_api.cpp waitDMAChannelTaskQueue / waitDMAChannelDone
 */
void __Runtime_wait_io(struct_ioevent io_event) {
    XAie_LocType tile = io_event.io.tile_loc;
    uint8_t channel = io_event.io.channel_id;
    XAie_DmaDirection dir = io_event.io.direction;

    if (g_runtime_debug_level >= 1)
        printf("[aie_runtime] wait_io tile(%u,%u) ch=%u dir=%d\n", (unsigned)tile.Col, (unsigned)tile.Row,
               (unsigned)channel, (int)dir);

    /* 5-second timeout (debug only): poll every 100ms, max 50 iterations */
    const uint32_t poll_interval_us = 1000 * 1000;
    const uint32_t max_iters = 5;
    u8 numPendingBDs = 1;
    uint32_t iter = 0;

    printf("aie runtime col = %d, row = %d, channel = %d, dir = %d\n", tile.Col, tile.Row, channel, dir);
    /* Read raw DMA channel status for diagnostic */
    {
        u32 ch_status = 0;
        AieRC src = XAie_DmaGetChannelStatus(g_DevInst, tile, channel, dir, &ch_status);
        printf("[aie_runtime] ch_status tile(%u,%u) ch=%u dir=%d raw=0x%08x rc=%d\n", (unsigned)tile.Col,
               (unsigned)tile.Row, (unsigned)channel, (int)dir, (unsigned)ch_status, (int)src);
    }
    while (numPendingBDs > 0) {
        AieRC rc = XAie_DmaGetPendingBdCount(g_DevInst, tile, channel, dir, &numPendingBDs);
        if (rc != XAIE_OK) {
            printf("[aie_runtime] wait_io ERROR: XAie_DmaGetPendingBdCount "
                   "failed rc=%d tile(%u,%u) ch=%u dir=%d\n",
                   (int)rc, (unsigned)tile.Col, (unsigned)tile.Row, (unsigned)channel, (int)dir);
            return;
        }
        if (numPendingBDs > 0) {
            if (++iter >= max_iters) {
                printf("[aie_runtime] wait_io TIMEOUT after %u ms "
                       "tile(%u,%u) ch=%u dir=%d pending=%u\n",
                       (unsigned)(max_iters * poll_interval_us / 1000), (unsigned)tile.Col, (unsigned)tile.Row,
                       (unsigned)channel, (int)dir, (unsigned)numPendingBDs);
                return;
            } else if (g_runtime_debug_level >= 1) {
                printf("[aie_runtime] wait_io pending tile(%u,%u) ch=%u dir=%d pending=%u iter=%u\n",
                       (unsigned)tile.Col, (unsigned)tile.Row, (unsigned)channel, (int)dir, (unsigned)numPendingBDs,
                       (unsigned)iter);
            }
            usleep(poll_interval_us);
        }
    }

    if (g_runtime_debug_level >= 1)
        printf("[aie_runtime] wait_io done tile(%u,%u) ch=%u dir=%d\n", (unsigned)tile.Col, (unsigned)tile.Row,
               (unsigned)channel, (int)dir);
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

/**
 * Auto-initialization: runs before main() via __attribute__((constructor)).
 * Ensures g_DevInst and g_RoutingInst are ready before generated host code
 * uses them directly (e.g. XAie_MemAllocate(g_DevInst, ...)).
 */
static void __Runtime_auto_init(void) {
    printf("[aie_runtime] platform_init\n");
    __Runtime_platform_init();
    printf("[aie_runtime] auto_init (constructor)\n");
    AieRC rc = __Runtime_device_init();
    if (rc != XAIE_OK) {
        printf("[aie_runtime] auto_init: device_init FAILED rc=%d\n", (int)rc);
        return;
    }
    __Runtime_routing_init();

    printf("[aie_runtime] auto_init OK\n");
}

/**
 * Auto-teardown: runs after main() via __attribute__((destructor)).
 */
static void __Runtime_auto_teardown(void) {
    printf("[aie_runtime] auto_teardown (destructor)\n");
    if (g_DevInst != NULL) {
        /* Kernel logs are already read in __Runtime_wait_event() right after
         * cores finish, so we don't duplicate the read here. */
        if (g_runtime_debug_level >= 1)
            AieRtSS_PrintRange(g_DevInst, 0, 3, 0, 5, /*print_all=*/0);
    }
    __Runtime_free_all_allocs();
    if (g_DevInst != NULL) {
        __Runtime_device_teardown();
    }
}
