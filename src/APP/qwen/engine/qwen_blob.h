/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* The qwen weight blob (written by tools/qwen_convert.py). Little endian, packed. */
#ifndef QWEN_BLOB_H
#define QWEN_BLOB_H

#include <stdint.h>

#ifdef __cplusplus
#define QW_STATIC_ASSERT(c, m) static_assert(c, m)
#else
#define QW_STATIC_ASSERT(c, m) _Static_assert(c, m)
#endif

#define QW_MAGIC 0x35335751U /* 'QW35' */
#define QW_VERSION 7         /* 7: launches in the natural-kernel plan order */
#define QW_SLICE_K 4096 /* Q4G64: K stored in 4096-wide slices, slice-major */

enum qw_type { QW_F32 = 1, QW_Q4G64 = 2, QW_Q4R64 = 3, QW_I32 = 4 };

/* QW_Q4G64: a group is 16 rows x 64 K = four 16(K) x 16(N) int4 tiles (512 B) + 16 bf16 scales (32 B);
 * a chunk is 16 groups of one row block: [16 x 512 B tiles][16 x 32 B scales] = 8704 B */
#define QW_G 64
#define QW_RB 16
#define QW_CHUNK_G 16
#define QW_GROUP_TILES 512
#define QW_GROUP_SCALES 32
#define QW_CHUNK_BYTES (QW_CHUNK_G * (QW_GROUP_TILES + QW_GROUP_SCALES))
/* QW_Q4R64 group: 32 B of nibbles + a bf16 scale */
#define QW_RGROUP_BYTES 34

enum qw_cfg {
    QWC_LAYERS,
    QWC_HIDDEN,
    QWC_FFN,
    QWC_HEADS,
    QWC_KV_HEADS,
    QWC_HEAD_DIM,
    QWC_VOCAB,
    QWC_LA_K_HEADS,
    QWC_LA_V_HEADS,
    QWC_LA_K_DIM,
    QWC_LA_V_DIM,
    QWC_CONV_K,
    QWC_MTP,
    QWC_FULL_MASK_LO,
    QWC_FULL_MASK_HI,
    QWC_SEG_MB /* the blob's segment size (MiB): segment i may live anywhere, no tensor crosses one */
};
enum qw_cfgf { QWF_EPS, QWF_THETA, QWF_ROPE_FRAC };

struct qw_header {
    uint32_t magic, version, n_ints, n_flts;
    int32_t ints[16];
    float flts[4];
    uint32_t n_tensors, pad;
    uint64_t table_off;
} __attribute__((packed));

struct qw_tensor_ent {
    char name[64];
    uint32_t type, rows, cols, reserved;
    uint64_t offset, bytes;
} __attribute__((packed));

QW_STATIC_ASSERT(sizeof(struct qw_header) == 112, "qw_header layout");
QW_STATIC_ASSERT(sizeof(struct qw_tensor_ent) == 96, "qw_tensor_ent layout");

#endif
