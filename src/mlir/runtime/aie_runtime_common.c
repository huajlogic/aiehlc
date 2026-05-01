/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#include "aie_runtime_common.h"

/* --- Pending OOO transfer tracker --- */
typedef struct {
    XAie_LocType dst_tile;
    uint8_t dst_ch;
} MovedataPending;

static MovedataPending g_pending[MOVEDATA_MAX_PENDING];
static int g_pending_count = 0;

AieRC Runtime_Movedata(XAie_DevInst *DevInst, XAie_LocType src_tile, uint32_t src_addr, uint8_t src_ch, uint8_t src_bd,
                       XAie_LocType dst_tile, uint32_t dst_addr, uint8_t dst_ch, uint8_t dst_bd, uint32_t data_bytes,
                       int pkt_id, XAie_MemInst **out_recv_buf, u64 *out_recv_phy, MovedataOpt *opt) {
    AieRC RC = XAIE_OK;
    int dst_is_shim = (dst_tile.Row == 0);
    int src_is_shim = (src_tile.Row == 0);
    int mode = (opt != NULL) ? opt->mode : MOVEDATA_MODE_BLOCKING;

    printf("  Runtime_Movedata: (%d,%d) MM2S ch%d -> (%d,%d) S2MM ch%d, %u bytes, mode=%d", src_tile.Col, src_tile.Row,
           src_ch, dst_tile.Col, dst_tile.Row, dst_ch, data_bytes, mode);
    if (pkt_id >= 0)
        printf(", pkt_id=%d", pkt_id);
    printf("\n");

    /* ---- Configure destination (S2MM) ---- */
    {
        XAie_DmaDesc DmaInst;
        RC = XAie_DmaDescInit(DevInst, &DmaInst, dst_tile);
        if (RC != XAIE_OK) {
            printf("ERROR: dst DmaDescInit: %d\n", RC);
            return RC;
        }

        if (dst_is_shim) {
            /* Shim tile: allocate DDR buffer */
            XAie_MemInst *buf = XAie_MemAllocate(DevInst, data_bytes, XAIE_MEM_CACHEABLE);
            if (!buf) {
                printf("ERROR: DDR alloc for dst shim failed\n");
                return XAIE_ERR;
            }
            u64 phy = (u64)XAie_MemGetDevAddr(buf);
            /* Clear buffer */
            uint32_t i;
            for (i = 0; i < data_bytes / sizeof(uint32_t); i++)
                ((uint32_t *)phy)[i] = 0xDEADBEEF;
            XAie_MemSyncForDev(buf);

            if (mode == MOVEDATA_MODE_OOO_STRIDE && opt->num_dims > 0) {
                /* Stride/wrap addressing on receive BD */
                XAie_DmaTensor tensor;
                tensor.NumDim = opt->num_dims;
                tensor.Dim = opt->dims;
                RC = XAie_DmaSetMultiDimAddr(&DmaInst, &tensor, phy, data_bytes);
            } else {
                RC = XAie_DmaSetAddrLen(&DmaInst, phy, data_bytes);
            }
            if (RC != XAIE_OK) {
                printf("ERROR: dst DmaSetAddr: %d\n", RC);
                return RC;
            }

            if (out_recv_buf)
                *out_recv_buf = buf;
            if (out_recv_phy)
                *out_recv_phy = phy;
        } else {
            /* Mem tile: use local memory address */
            if (mode == MOVEDATA_MODE_OOO_STRIDE && opt->num_dims > 0) {
                XAie_DmaTensor tensor;
                tensor.NumDim = opt->num_dims;
                tensor.Dim = opt->dims;
                RC = XAie_DmaSetMultiDimAddr(&DmaInst, &tensor, dst_addr, data_bytes);
            } else {
                RC = XAie_DmaSetAddrLen(&DmaInst, dst_addr, data_bytes);
            }
            if (RC != XAIE_OK) {
                printf("ERROR: dst DmaSetAddr: %d\n", RC);
                return RC;
            }
        }

        RC = XAie_DmaEnableBd(&DmaInst);
        RC = XAie_DmaWriteBd(DevInst, &DmaInst, dst_tile, dst_bd);
        if (RC != XAIE_OK) {
            printf("ERROR: dst DmaWriteBd: %d\n", RC);
            return RC;
        }

        RC = XAie_DmaChannelPushBdToQueue(DevInst, dst_tile, dst_ch, DMA_S2MM, dst_bd);
        if (RC != XAIE_OK) {
            printf("ERROR: dst PushBdToQueue: %d\n", RC);
            return RC;
        }

        RC = XAie_DmaChannelEnable(DevInst, dst_tile, dst_ch, DMA_S2MM);
        if (RC != XAIE_OK) {
            printf("ERROR: dst DmaChannelEnable: %d\n", RC);
            return RC;
        }
    }

    /* ---- Configure source (MM2S) ---- */
    {
        XAie_DmaDesc DmaInst;
        RC = XAie_DmaDescInit(DevInst, &DmaInst, src_tile);
        if (RC != XAIE_OK) {
            printf("ERROR: src DmaDescInit: %d\n", RC);
            return RC;
        }

        if (src_is_shim) {
            RC = XAie_DmaSetAddrLen(&DmaInst, (u64)src_addr, data_bytes);
        } else {
            RC = XAie_DmaSetAddrLen(&DmaInst, src_addr, data_bytes);
        }
        if (RC != XAIE_OK) {
            printf("ERROR: src DmaSetAddrLen: %d\n", RC);
            return RC;
        }

        /* Attach packet header if needed */
        if (pkt_id >= 0) {
            XAie_Packet pkt = XAie_PacketInit(pkt_id, 0);
            RC = XAie_DmaSetPkt(&DmaInst, pkt);
            if (RC != XAIE_OK) {
                printf("ERROR: src DmaSetPkt: %d\n", RC);
                return RC;
            }
        }

        RC = XAie_DmaEnableBd(&DmaInst);
        RC = XAie_DmaWriteBd(DevInst, &DmaInst, src_tile, src_bd);
        if (RC != XAIE_OK) {
            printf("ERROR: src DmaWriteBd: %d\n", RC);
            return RC;
        }

        RC = XAie_DmaChannelPushBdToQueue(DevInst, src_tile, src_ch, DMA_MM2S, src_bd);
        if (RC != XAIE_OK) {
            printf("ERROR: src PushBdToQueue: %d\n", RC);
            return RC;
        }

        RC = XAie_DmaChannelEnable(DevInst, src_tile, src_ch, DMA_MM2S);
        if (RC != XAIE_OK) {
            printf("ERROR: src DmaChannelEnable: %d\n", RC);
            return RC;
        }
    }

    /* ---- Blocking mode: wait for destination S2MM to complete ---- */
    if (mode == MOVEDATA_MODE_BLOCKING) {
        RC = XAie_DmaWaitForDone(DevInst, dst_tile, dst_ch, DMA_S2MM, 5000000 /*5s*/);
        if (RC != XAIE_OK) {
            printf("ERROR: dst S2MM wait timed out: %d\n", RC);
            return RC;
        }
    } else {
        /* OOO mode: record pending transfer for later WaitAll */
        if (g_pending_count >= MOVEDATA_MAX_PENDING) {
            printf("ERROR: too many pending OOO transfers (max %d)\n", MOVEDATA_MAX_PENDING);
            return XAIE_ERR;
        }
        g_pending[g_pending_count].dst_tile = dst_tile;
        g_pending[g_pending_count].dst_ch = dst_ch;
        g_pending_count++;
    }

    return XAIE_OK;
}

AieRC Runtime_Movedata_WaitAll(XAie_DevInst *DevInst) {
    AieRC RC = XAIE_OK;
    int i;

    printf("  Runtime_Movedata_WaitAll: waiting for %d pending transfers...\n", g_pending_count);

    for (i = 0; i < g_pending_count; i++) {
        AieRC rc = XAie_DmaWaitForDone(DevInst, g_pending[i].dst_tile, g_pending[i].dst_ch, DMA_S2MM, 5000000 /*5s*/);
        if (rc != XAIE_OK) {
            printf("ERROR: WaitAll: transfer %d (tile(%d,%d) ch%d) timed out: %d\n", i, g_pending[i].dst_tile.Col,
                   g_pending[i].dst_tile.Row, g_pending[i].dst_ch, rc);
            if (RC == XAIE_OK)
                RC = rc; /* report first error */
        }
    }

    g_pending_count = 0;
    printf("  Runtime_Movedata_WaitAll: done.\n");
    return RC;
}

AieRC Runtime_Movedata_ManyToOne(XAie_DevInst *DevInst, MovedataSrcDesc *srcs, int num_srcs, XAie_LocType dst_tile,
                                 uint8_t dst_ch) {
    AieRC RC = XAIE_OK;
    int i;

    if (num_srcs <= 0 || num_srcs > MOVEDATA_MAX_SOURCES) {
        printf("ERROR: ManyToOne: invalid num_srcs=%d (max %d)\n", num_srcs, MOVEDATA_MAX_SOURCES);
        return XAIE_ERR;
    }

    if (dst_tile.Row != 0) {
        printf("ERROR: ManyToOne: dst_tile (%d,%d) is not a shim tile\n", dst_tile.Col, dst_tile.Row);
        return XAIE_ERR;
    }

    if (g_pending_count + num_srcs > MOVEDATA_MAX_PENDING) {
        printf("ERROR: ManyToOne: would exceed max pending (%d + %d > %d)\n", g_pending_count, num_srcs,
               MOVEDATA_MAX_PENDING);
        return XAIE_ERR;
    }

    printf("  Runtime_Movedata_ManyToOne: %d sources → Shim(%d,%d) S2MM ch%d\n", num_srcs, dst_tile.Col, dst_tile.Row,
           dst_ch);

    /* ---- Configure each source ---- */
    for (i = 0; i < num_srcs; i++) {
        MovedataSrcDesc *s = &srcs[i];

        u64 dst_addr = s->recv_phy;
        uint32_t dst_len = (s->dst_len > 0) ? s->dst_len : s->data_bytes;

        printf("    [src %d] tile(%d,%d) MM2S ch%d bd%d → dst bd%d, src %u bytes, dst addr=0x%llx len=%u", i,
               s->src_tile.Col, s->src_tile.Row, s->src_ch, s->src_bd, s->dst_bd, s->data_bytes,
               (unsigned long long)dst_addr, dst_len);
        if (s->src_pkt_id >= 0)
            printf(", pkt_id=%d", s->src_pkt_id);
        if (s->dst_num_dims > 0)
            printf(", dims=%d", s->dst_num_dims);
        printf("\n");

        /* ---- 2a: Configure destination BD (S2MM on dst_tile) ---- */
        {
            XAie_DmaDesc DmaInst;
            RC = XAie_DmaDescInit(DevInst, &DmaInst, dst_tile);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: dst DmaDescInit: %d\n", i, RC);
                return RC;
            }

            if (s->dst_num_dims > 0) {
                XAie_DmaTensor tensor;
                tensor.NumDim = s->dst_num_dims;
                tensor.Dim = s->dst_dims;
                RC = XAie_DmaSetMultiDimAddr(&DmaInst, &tensor, dst_addr, dst_len);
            } else {
                RC = XAie_DmaSetAddrLen(&DmaInst, dst_addr, dst_len);
            }
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: dst DmaSetAddr: %d\n", i, RC);
                return RC;
            }

            RC = XAie_DmaEnableBd(&DmaInst);
            RC = XAie_DmaWriteBd(DevInst, &DmaInst, dst_tile, s->dst_bd);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: dst DmaWriteBd: %d\n", i, RC);
                return RC;
            }

            RC = XAie_DmaChannelPushBdToQueue(DevInst, dst_tile, dst_ch, DMA_S2MM, s->dst_bd);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: dst PushBdToQueue: %d\n", i, RC);
                return RC;
            }

            RC = XAie_DmaChannelEnable(DevInst, dst_tile, dst_ch, DMA_S2MM);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: dst DmaChannelEnable: %d\n", i, RC);
                return RC;
            }
        }

        /* ---- 2b: Configure source BD (MM2S on src_tile) ---- */
        {
            XAie_DmaDesc DmaInst;
            RC = XAie_DmaDescInit(DevInst, &DmaInst, s->src_tile);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: src DmaDescInit: %d\n", i, RC);
                return RC;
            }

            RC = XAie_DmaSetAddrLen(&DmaInst, s->src_addr, s->data_bytes);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: src DmaSetAddrLen: %d\n", i, RC);
                return RC;
            }

            if (s->src_pkt_id >= 0) {
                XAie_Packet pkt = XAie_PacketInit(s->src_pkt_id, 0);
                RC = XAie_DmaSetPkt(&DmaInst, pkt);
                if (RC != XAIE_OK) {
                    printf("ERROR: ManyToOne[%d]: src DmaSetPkt: %d\n", i, RC);
                    return RC;
                }
            }

            RC = XAie_DmaEnableBd(&DmaInst);
            RC = XAie_DmaWriteBd(DevInst, &DmaInst, s->src_tile, s->src_bd);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: src DmaWriteBd: %d\n", i, RC);
                return RC;
            }

            RC = XAie_DmaChannelPushBdToQueue(DevInst, s->src_tile, s->src_ch, DMA_MM2S, s->src_bd);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: src PushBdToQueue: %d\n", i, RC);
                return RC;
            }

            RC = XAie_DmaChannelEnable(DevInst, s->src_tile, s->src_ch, DMA_MM2S);
            if (RC != XAIE_OK) {
                printf("ERROR: ManyToOne[%d]: src DmaChannelEnable: %d\n", i, RC);
                return RC;
            }
        }

        /* ---- 2c: Record pending for WaitAll ---- */
        g_pending[g_pending_count].dst_tile = dst_tile;
        g_pending[g_pending_count].dst_ch = dst_ch;
        g_pending_count++;
    }

    return XAIE_OK;
}
