/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef AIE_RUNTIME_XAIE_SEQ_H
#define AIE_RUNTIME_XAIE_SEQ_H

#include <stdint.h>
#include <xaiengine.h>

#include "aie_runtime_control_plan.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int32_t bd_id, len, next_bd, enable_packet, packet_id;
    int32_t acquire_lock_id, acquire_lock_val, release_lock_id, release_lock_val;
    int32_t out_of_order_bd_id, num_dims;
    int32_t stride[4], wrap[4];
    int32_t iter_step_size, iter_wrap;
    int ooo;
} rt_seq_bd_args;

/* AXI burst length (beats) for every shim BD built by rt_seq_bd_desc.
 * AIE2PS also accepts 32; override with -DRT_SEQ_SHIM_AXI_BURST=... */
#ifndef RT_SEQ_SHIM_AXI_BURST
#define RT_SEQ_SHIM_AXI_BURST 16U
#endif
/* AxCACHE / AxQOS for the same BDs (XAie_DmaSetAxi). 0 = device
 * non-bufferable, the driver default; override with -DRT_SEQ_SHIM_AXI_CACHE=... */
#ifndef RT_SEQ_SHIM_AXI_CACHE
#define RT_SEQ_SHIM_AXI_CACHE 0U
#endif
#ifndef RT_SEQ_SHIM_AXI_QOS
#define RT_SEQ_SHIM_AXI_QOS 0U
#endif

/* BD-length guard (aie_runtime_bdlimits.h). rt_seq_bd_len_guard prints
 * `BDLEN_OVF tile(c,r) bd=N words=W max=0x..`, bumps the sticky rt_seq_bdlen_ovf_n and
 * returns 0 when len_bytes is over the tile's Buffer_Length field; rt_seq_bd_desc runs
 * it first and returns XAIE_INVALID_ARGS for such a BD. */
extern int rt_seq_bdlen_ovf_n;
int rt_seq_bd_len_guard(XAie_DevInst *dev, XAie_LocType tile, int bd_id, int64_t len_bytes);

AieRC rt_seq_bd_desc(XAie_DevInst *dev, XAie_LocType tile, uint64_t dma_addr, const rt_seq_bd_args *a,
                     XAie_DmaDesc *desc);

AieRC rt_seq_channel_ooo_desc(XAie_DevInst *dev, XAie_LocType tile, XAie_DmaChannelDesc *desc);

AieRC rt_seq_start_queue(XAie_DevInst *dev, XAie_LocType tile, uint8_t channel, XAie_DmaDirection dir, uint8_t bd_id,
                         int32_t repeat);

#define RT_SEQ_SHIM_BD_ADDR_W0 1U
#define RT_SEQ_SHIM_BD_ADDR_W1 2U
#define RT_SEQ_SHIM_BD_ADDR_W2 8U
AieRC rt_seq_shim_bd_addr_fields(XAie_DevInst *dev, XAie_LocType tile, uint64_t addr, uint32_t f[3]);

StrmSwPortType rt_seq_acr_port(acr_port p);
uint8_t rt_seq_acr_chan(acr_port p, int is_master, uint8_t idx);

AieRC rt_seq_row_op(XAie_DevInst *dev, const acr_op *op);

#ifdef __cplusplus
}
#endif

#endif
