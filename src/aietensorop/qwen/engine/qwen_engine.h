/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* Qwen3.5 text decoder (Gated DeltaNet + gated attention) over a qwen weight blob.
 * Portable C99: the same file runs on x86 (check against the torch reference) and on the baremetal A78. */
#ifndef QWEN_ENGINE_H
#define QWEN_ENGINE_H

#include <stddef.h>
#include <stdint.h>

#include "qwen_blob.h"

#ifdef __cplusplus
extern "C" {
#endif

#define QW_MAX_SEG 8 /* blob segments */

typedef float qw_state_t; /* the DeltaNet recurrent state (fp16 storage measured slower on the A78) */

typedef struct {
    const char *name;
    int type, rows, cols;
    int prow; /* Q4G64: rows padded to a multiple of 4096 (blocks exist for all of them) */
    const uint8_t *data;
} qw_mat;

/* y[t][rows] = W . x[t][cols] for t < n (W4A8: x quantized per 64 to int8, int32 per group, fp32 scaled sum). */
typedef void (*qw_matmul_fn)(void *ctx, const qw_mat *w, const float *x, int n, float *y);

typedef struct {
    qw_mat in_norm, post_norm, mlp_gu, mlp_down;
    int full;
    /* linear attention */
    qw_mat qkvz, ab, conv, A_log, dt_bias, la_norm, la_out;
    /* full attention */
    qw_mat qkv, q_norm, k_norm, o;
} qw_layer;

typedef struct {
    const uint8_t *seg[QW_MAX_SEG]; /* the blob's segments */
    int nseg;
    size_t seg_bytes;
    int layers, hidden, ffn, heads, kv_heads, head_dim, vocab;
    int la_kh, la_vh, la_kd, la_vd, conv_k, mtp;
    float eps, theta, rope_frac;
    qw_mat embed, final_norm, lm_head;
    const int32_t *lm_perm; /* lm_head row -> token id (rows in frequency order), or NULL */
    qw_layer *layer;
    /* state */
    int max_ctx;
    float *kcache, *vcache; /* [full layer][ctx][kv_heads * head_dim] */
    qw_state_t *la_state;   /* [2][la layer][v heads][k dim][v dim]: two banks, la_cur[layer] is live */
    unsigned char *la_cur;
    float *la_sigma;         /* [2][la layer][v heads]: the state is sigma x the stored matrix (lazy decay) */
    float *conv_state;       /* [la layer][conv channels][conv_k - 1] */
    int n_full, n_la, *slot; /* layer -> its index among full / linear layers */
    /* scratch (sized for max_batch tokens) */
    int max_batch;
    float *x, *xn, *buf0, *buf1, *buf2;
    float *logits;  /* [QW_MAX_LOG][vocab]: the last nlog tokens of a forward */
    float *hid;     /* [max_batch][hidden]: every token's last hidden state, after the final norm */
    float *hid_pre; /* [max_batch][hidden]: the same before the final norm */
    /* speculative decoding: tokens after ckpt_t of a forward update the DeltaNet state into the other bank
     * (qw_commit makes it live, qw_rollback drops it); the conv state is checkpointed by copy */
    float *conv_ckpt;
    int ckpt_t;
    /* MTP (multi-token prediction) head: one full-attention layer with its own KV cache */
    qw_layer mtp_layer;
    qw_mat mtp_fc, mtp_norm_e, mtp_norm_h, mtp_norm;
    float *mtp_k, *mtp_v, *mlogits;
    int mtp_hid_pre; /* feed the MTP the hidden state before (1) or after (0) the final norm */
    int mtp_pos_off; /* the MTP layer's position: the hidden's position + mtp_pos_off */
    int mtp_vocab;   /* the draft picks among token ids < mtp_vocab only (0: all): fewer lm_head rows per draft */
    int mtp_fill;    /* after an accepted draft, also enter the skipped (token, hidden) pair in the MTP's KV cache */
    qw_matmul_fn matmul;
    void *matmul_ctx;
    /* optional profile: seconds per part (QW_P_*), when now is set */
    double (*now)(void);
    double prof[12];
} qw_model;

enum {
    QW_P_MATMUL,
    QW_P_AB,
    QW_P_DELTANET,
    QW_P_ATTN,
    QW_P_MLPACT,
    QW_P_NORM,
    QW_P_LM,
    QW_P_DN_CONV,
    QW_P_DN_HEADS,
    QW_P_N
};

#define QW_MAX_LOG 2

/* Bind a blob in memory (not copied). Returns 0, or -1 with a message in err. */
int qw_open(qw_model *m, const void *blob, size_t size, int max_ctx, int max_batch, char *err, size_t errn);
/* The same for a blob whose segments (QWC_SEG_MB each, header in segment 0) sit at seg[0 .. nseg - 1]. */
int qw_open_seg(qw_model *m, const void *const *seg, int nseg, int max_ctx, int max_batch, char *err, size_t errn);
void qw_close(qw_model *m);
void qw_reset(qw_model *m);
/* Run n tokens starting at position pos; logits of the last one in m->logits (vocab floats). */
int qw_forward(qw_model *m, const int *tok, int n, int pos);
/* The same with logits for the last nlog (<= QW_MAX_LOG) tokens (m->logits[i * vocab], oldest first), and the
 * recurrent state checkpointed after token ckpt_t (-1: none) for qw_rollback. */
int qw_forward_ex(qw_model *m, const int *tok, int n, int pos, int nlog, int ckpt_t);
/* After a qw_forward_ex with ckpt_t >= 0: keep its tokens after ckpt_t (commit) or drop them (rollback). */
void qw_commit(qw_model *m);
void qw_rollback(qw_model *m);
/* MTP: n pairs (next token tok[i], hidden hid[i] of the token before it at position pos + i); fills the MTP
 * KV cache and, when want, returns the argmax of the last pair's logits (m->mlogits): the draft. */
int qw_mtp(qw_model *m, const int *tok, const float *hid, int n, int pos, int want);
int qw_argmax(const float *v, int n);
/* the greedy token of lm_head logits (row index mapped through lm_perm) */
int qw_token(const qw_model *m, const float *logits, int rows);

typedef struct {
    int emitted, steps, drafted, accepted;
    double prefill_s, decode_s;
} qw_gen_stats;
typedef void (*qw_emit_fn)(void *ctx, int tok);
/* Greedy generation: prefill the prompt (max_batch tokens per forward), then emit up to ngen tokens, stopping
 * after a token in stop[]. spec: the MTP drafts one token per step and the main model verifies it together with
 * the previous one (one weight pass for two tokens); the output is the plain greedy output. now: a clock (s). */
int qw_generate(qw_model *m, const int *prompt, int n, int ngen, int spec, const int *stop, int nstop, qw_emit_fn emit,
                void *ctx, double (*now)(void), qw_gen_stats *st);

/* The CPU W4A8 matmul (the reference the AIE kernel is checked against). */
void qw_matmul_cpu(void *ctx, const qw_mat *w, const float *x, int n, float *y);
float qw_f16(uint16_t h);
float qw_bf16(uint16_t h);

#ifdef __cplusplus
}
#endif
#endif
