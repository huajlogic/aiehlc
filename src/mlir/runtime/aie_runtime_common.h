/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#ifndef AIE_RUNTIME_COMMON_H
#define AIE_RUNTIME_COMMON_H

#include "xaiengine.h"
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* --- Out-of-order DMA transfer modes --- */
#define MOVEDATA_MODE_BLOCKING 0   /* Blocking: wait for S2MM completion */
#define MOVEDATA_MODE_OOO 1        /* OOO: non-blocking, contiguous receive */
#define MOVEDATA_MODE_OOO_STRIDE 2 /* OOO: non-blocking, stride/wrap receive */

#define MOVEDATA_MAX_PENDING 16

typedef struct {
    int mode;                /* MOVEDATA_MODE_* */
    int num_dims;            /* 0-4, used when mode == OOO_STRIDE */
    XAie_DmaDimDesc dims[4]; /* stride/wrap per dimension */
} MovedataOpt;

/**
 * Runtime_Movedata - Move data between tile DMAs (mem tile or shim tile).
 *
 * Configures MM2S on src_tile and S2MM on dst_tile, starts the transfer.
 * Behavior depends on opt->mode:
 *   MOVEDATA_MODE_BLOCKING   - waits for S2MM completion before returning.
 *   MOVEDATA_MODE_OOO        - non-blocking; receive BD uses contiguous addr.
 *   MOVEDATA_MODE_OOO_STRIDE - non-blocking; receive BD uses stride/wrap
 *                               addressing (opt->num_dims / opt->dims[]).
 *
 * For OOO modes, call Runtime_Movedata_WaitAll() to drain all pending
 * transfers before reading the data.
 *
 * For shim dst (row==0): allocates a DDR buffer, returns it via
 *   out_recv_buf/out_recv_phy so the caller can read back the data.
 * For mem dst (row>0): uses dst_addr as the local tile memory offset.
 *
 * @param opt       Transfer options (mode + optional stride/wrap). NULL for
 *                  blocking (backward-compatible).
 * @param pkt_id    Packet ID for packet-switched paths (>=0), or <0 for
 *                  circuit-switched (no packet header).
 * @param out_recv_buf  [out] DDR MemInst when dst is shim (may be NULL).
 * @param out_recv_phy  [out] DDR physical address when dst is shim (may be NULL).
 *
 * @return XAIE_OK on success, error code otherwise.
 */
AieRC Runtime_Movedata(XAie_DevInst *DevInst, XAie_LocType src_tile, uint32_t src_addr, uint8_t src_ch, uint8_t src_bd,
                       XAie_LocType dst_tile, uint32_t dst_addr, uint8_t dst_ch, uint8_t dst_bd, uint32_t data_bytes,
                       int pkt_id, XAie_MemInst **out_recv_buf, u64 *out_recv_phy, MovedataOpt *opt = nullptr);

/**
 * Runtime_Movedata_WaitAll - Wait for all pending OOO transfers to complete.
 *
 * Iterates through all transfers launched with MOVEDATA_MODE_OOO or
 * MOVEDATA_MODE_OOO_STRIDE and waits for their S2MM channels to finish.
 * Resets the pending count to 0 after all waits succeed.
 *
 * @return XAIE_OK if all transfers completed, first error code otherwise.
 */
AieRC Runtime_Movedata_WaitAll(XAie_DevInst *DevInst);

#ifdef __cplusplus
}
#endif

#endif /* AIE_RUNTIME_COMMON_H */
