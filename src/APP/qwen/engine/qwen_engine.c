/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* Qwen3.5 text decoder: see qwen_engine.h. Follows transformers' modeling_qwen3_5.py (text part):
 *   RMSNorm x * rsqrt(mean x^2 + eps) * (1 + w); the DeltaNet's gated norm uses w (no 1 +)
 *   linear attention: conv1d (k 4) + SiLU on qkv, l2norm(q, k), q / sqrt(dk), g = -exp(A_log) softplus(a + dt_bias),
 *     beta = sigmoid(b), S = S e^g; S += k (beta (v - S^T k))^T; o = S^T q; o = norm(o) silu(z)
 *   full attention: q / gate interleaved per head, q_norm / k_norm, partial RoPE (first rope_frac of the head,
 *     rotate-half), GQA, softmax(q k^T / sqrt(d)) v, times sigmoid(gate)
 *   MLP: down(silu(gate) * up) */
#include "qwen_engine.h"

#include <math.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

float qw_bf16(uint16_t h) {
    uint32_t u = (uint32_t)h << 16;
    float r;
    memcpy(&r, &u, 4);
    return r;
}

float qw_f16(uint16_t h) {
    uint32_t s = (uint32_t)(h & 0x8000) << 16, e = (h >> 10) & 0x1F, f = h & 0x3FF, u;
    if (e == 0) {
        if (!f)
            u = s;
        else { /* subnormal */
            e = 127 - 15 + 1;
            while (!(f & 0x400))
                f <<= 1, e--;
            u = s | (e << 23) | ((f & 0x3FF) << 13);
        }
    } else if (e == 31)
        u = s | 0x7F800000 | (f << 13);
    else
        u = s | ((e + 127 - 15) << 23) | (f << 13);
    float r;
    memcpy(&r, &u, 4);
    return r;
}

#define PROF_T0(m) double pt0_ = (m)->now ? (m)->now() : 0
#define PROF_RE(m) pt0_ = (m)->now ? (m)->now() : 0
#define PROF_ADD(m, k)                                                                                                 \
    do {                                                                                                               \
        if ((m)->now)                                                                                                  \
            (m)->prof[k] += (m)->now() - pt0_;                                                                         \
    } while (0)

/* ---- the blob ---- */
static const qw_model *g_bind; /* the model being bound: its segment table */

static int find(const void *blob, size_t size, const char *name, qw_mat *out) {
    (void)size;
    const qw_model *m = g_bind;
    const struct qw_header *h = (const struct qw_header *)blob;
    const struct qw_tensor_ent *e = (const struct qw_tensor_ent *)((const uint8_t *)blob + h->table_off);
    for (uint32_t i = 0; i < h->n_tensors; i++)
        if (!strncmp(e[i].name, name, sizeof(e[i].name))) {
            const size_t sg = (size_t)(e[i].offset / m->seg_bytes), in = (size_t)(e[i].offset % m->seg_bytes);
            if (sg >= (size_t)m->nseg || in + e[i].bytes > m->seg_bytes)
                return -1;
            out->name = e[i].name, out->type = (int)e[i].type, out->rows = (int)e[i].rows, out->cols = (int)e[i].cols;
            out->prow = e[i].reserved ? (int)e[i].reserved : out->rows;
            out->data = m->seg[sg] + in;
            return 0;
        }
    return -1;
}

#define NEED(nm, dst)                                                                                                  \
    do {                                                                                                               \
        if (find(blob, size, (nm), (dst))) {                                                                           \
            snprintf(err, errn, "tensor %s missing", (nm));                                                            \
            return -1;                                                                                                 \
        }                                                                                                              \
    } while (0)

static int bind_layers(qw_model *m, const void *blob, size_t size, uint64_t full_mask, char *err, size_t errn) {
    char nm[64];
    m->n_full = m->n_la = 0;
    for (int i = 0; i < m->layers; i++) {
        qw_layer *L = &m->layer[i];
        L->full = (int)((full_mask >> i) & 1);
        m->slot[i] = L->full ? m->n_full++ : m->n_la++;
#define LN(sfx, dst) (snprintf(nm, sizeof nm, "l%d." sfx, i), find(blob, size, nm, (dst)))
        if (LN("in_norm", &L->in_norm) || LN("post_norm", &L->post_norm) || LN("mlp.gu", &L->mlp_gu) ||
            LN("mlp.down", &L->mlp_down))
            goto missing;
        if (L->full) {
            if (LN("fa.qkv", &L->qkv) || LN("fa.q_norm", &L->q_norm) || LN("fa.k_norm", &L->k_norm) ||
                LN("fa.o", &L->o))
                goto missing;
        } else if (LN("la.qkvz", &L->qkvz) || LN("la.ab", &L->ab) || LN("la.conv", &L->conv) ||
                   LN("la.A_log", &L->A_log) || LN("la.dt_bias", &L->dt_bias) || LN("la.norm", &L->la_norm) ||
                   LN("la.out", &L->la_out))
            goto missing;
#undef LN
    }
    return 0;
missing:
    snprintf(err, errn, "layer tensor %s missing", nm);
    return -1;
}

int qw_open(qw_model *m, const void *blob, size_t size, int max_ctx, int max_batch, char *err, size_t errn) {
    const struct qw_header *h = (const struct qw_header *)blob;
    if (size < sizeof *h || h->magic != QW_MAGIC) {
        snprintf(err, errn, "not a qwen blob");
        return -1;
    }
    const size_t sb = (size_t)h->ints[QWC_SEG_MB] << 20;
    const void *seg[QW_MAX_SEG];
    int n = 0;
    for (size_t o = 0; o < size && n < QW_MAX_SEG; o += sb)
        seg[n++] = (const uint8_t *)blob + o;
    return qw_open_seg(m, seg, n, max_ctx, max_batch, err, errn);
}

int qw_open_seg(qw_model *m, const void *const *segs, int nseg, int max_ctx, int max_batch, char *err, size_t errn) {
    const struct qw_header *h = (const struct qw_header *)segs[0];
    const void *blob = segs[0];
    memset(m, 0, sizeof *m);
    if (h->magic != QW_MAGIC || h->version != QW_VERSION || nseg < 1 || nseg > QW_MAX_SEG) {
        snprintf(err, errn, "not a qwen blob v%d (magic %08x version %u)", QW_VERSION, h->magic, h->version);
        return -1;
    }
    m->nseg = nseg, m->seg_bytes = (size_t)h->ints[QWC_SEG_MB] << 20;
    for (int i = 0; i < nseg; i++)
        m->seg[i] = (const uint8_t *)segs[i];
    g_bind = m;
    const size_t size = 0; /* find() checks segment bounds */
    int32_t c[16];
    memcpy(c, (const uint8_t *)blob + offsetof(struct qw_header, ints), sizeof c);
    m->layers = c[QWC_LAYERS], m->hidden = c[QWC_HIDDEN], m->ffn = c[QWC_FFN], m->heads = c[QWC_HEADS];
    m->kv_heads = c[QWC_KV_HEADS], m->head_dim = c[QWC_HEAD_DIM], m->vocab = c[QWC_VOCAB];
    m->la_kh = c[QWC_LA_K_HEADS], m->la_vh = c[QWC_LA_V_HEADS], m->la_kd = c[QWC_LA_K_DIM], m->la_vd = c[QWC_LA_V_DIM];
    m->conv_k = c[QWC_CONV_K], m->mtp = c[QWC_MTP];
    m->eps = h->flts[QWF_EPS], m->theta = h->flts[QWF_THETA], m->rope_frac = h->flts[QWF_ROPE_FRAC];
    uint64_t full_mask = (uint32_t)c[QWC_FULL_MASK_LO] | ((uint64_t)(uint32_t)c[QWC_FULL_MASK_HI] << 32);
    NEED("embed", &m->embed);
    NEED("final_norm", &m->final_norm);
    NEED("lm_head", &m->lm_head);
    {
        qw_mat pm;
        m->lm_perm = find(blob, size, "lm_perm", &pm) ? NULL : (const int32_t *)pm.data;
    }
    if (m->mtp) {
        qw_layer *L = &m->mtp_layer;
        L->full = 1;
        NEED("mtp.fc", &m->mtp_fc);
        NEED("mtp.pre_fc_norm_embedding", &m->mtp_norm_e);
        NEED("mtp.pre_fc_norm_hidden", &m->mtp_norm_h);
        NEED("mtp.norm", &m->mtp_norm);
        NEED("mtp.in_norm", &L->in_norm);
        NEED("mtp.post_norm", &L->post_norm);
        NEED("mtp.fa.qkv", &L->qkv);
        NEED("mtp.fa.q_norm", &L->q_norm);
        NEED("mtp.fa.k_norm", &L->k_norm);
        NEED("mtp.fa.o", &L->o);
        NEED("mtp.mlp.gu", &L->mlp_gu);
        NEED("mtp.mlp.down", &L->mlp_down);
    }
    m->layer = (qw_layer *)calloc((size_t)m->layers, sizeof(qw_layer));
    m->slot = (int *)calloc((size_t)m->layers, sizeof(int));
    if (!m->layer || !m->slot || bind_layers(m, blob, size, full_mask, err, errn))
        return -1;
    m->max_ctx = max_ctx, m->max_batch = max_batch;
    const size_t kvd = (size_t)m->kv_heads * m->head_dim,
                 convc = (size_t)2 * m->la_kh * m->la_kd + (size_t)m->la_vh * m->la_vd;
    m->kcache = (float *)calloc((size_t)m->n_full * max_ctx * kvd, sizeof(float));
    m->vcache = (float *)calloc((size_t)m->n_full * max_ctx * kvd, sizeof(float));
    m->la_state = (qw_state_t *)calloc((size_t)2 * m->n_la * m->la_vh * m->la_kd * m->la_vd, sizeof(qw_state_t));
    m->la_cur = (unsigned char *)calloc((size_t)m->n_la + 1, 1);
    m->la_sigma = (float *)malloc(sizeof(float) * 2 * (size_t)m->n_la * m->la_vh + 4);
    for (size_t i = 0; i < 2 * (size_t)m->n_la * m->la_vh; i++)
        m->la_sigma[i] = 1.0f;
    m->conv_state = (float *)calloc((size_t)m->n_la * convc * (m->conv_k - 1), sizeof(float));
    /* widest activation: the fused MLP gate + up (2 x ffn) or the linear attention qkvz */
    size_t wide = (size_t)2 * m->ffn;
    size_t qkvz = convc + (size_t)m->la_vh * m->la_vd, qkv = (size_t)m->heads * m->head_dim * 2 + 2 * kvd;
    if (qkvz > wide)
        wide = qkvz;
    if (qkv > wide)
        wide = qkv;
    m->x = (float *)calloc((size_t)max_batch * m->hidden, sizeof(float));
    m->xn = (float *)calloc((size_t)max_batch * m->hidden, sizeof(float));
    m->buf0 = (float *)calloc((size_t)max_batch * wide, sizeof(float));
    m->buf1 = (float *)calloc((size_t)max_batch * wide, sizeof(float));
    m->buf2 = (float *)calloc((size_t)max_batch * m->hidden, sizeof(float));
    m->logits = (float *)calloc((size_t)QW_MAX_LOG * m->vocab, sizeof(float));
    m->hid = (float *)calloc((size_t)max_batch * m->hidden, sizeof(float));
    m->hid_pre = (float *)calloc((size_t)max_batch * m->hidden, sizeof(float));
    m->conv_ckpt = (float *)calloc((size_t)m->n_la * convc * (m->conv_k - 1), sizeof(float));
    m->ckpt_t = -1;
    if (m->mtp) {
        m->mtp_k = (float *)calloc((size_t)max_ctx * kvd, sizeof(float));
        m->mtp_v = (float *)calloc((size_t)max_ctx * kvd, sizeof(float));
        m->mlogits = (float *)calloc((size_t)m->vocab, sizeof(float));
        if (!m->mtp_k || !m->mtp_v || !m->mlogits)
            m->mtp = 0;
    }
    if (!m->kcache || !m->vcache || !m->la_state || !m->conv_state || !m->x || !m->xn || !m->buf0 || !m->buf1 ||
        !m->buf2 || !m->logits || !m->hid || !m->hid_pre || !m->la_cur || !m->conv_ckpt) {
        snprintf(err, errn, "out of memory for the model state");
        return -1;
    }
    m->matmul = qw_matmul_cpu;
    return 0;
}

void qw_close(qw_model *m) {
    free(m->layer), free(m->slot), free(m->kcache), free(m->vcache), free(m->la_state), free(m->conv_state);
    free(m->x), free(m->xn), free(m->buf0), free(m->buf1), free(m->buf2), free(m->logits);
    free(m->hid), free(m->hid_pre), free(m->la_cur), free(m->la_sigma), free(m->conv_ckpt), free(m->mtp_k),
        free(m->mtp_v), free(m->mlogits);
    memset(m, 0, sizeof *m);
}

void qw_reset(qw_model *m) {
    const size_t convc = (size_t)2 * m->la_kh * m->la_kd + (size_t)m->la_vh * m->la_vd;
    memset(m->la_state, 0, (size_t)2 * m->n_la * m->la_vh * m->la_kd * m->la_vd * sizeof(qw_state_t));
    memset(m->la_cur, 0, (size_t)m->n_la);
    for (size_t i = 0; i < 2 * (size_t)m->n_la * m->la_vh; i++)
        m->la_sigma[i] = 1.0f;
    memset(m->conv_state, 0, (size_t)m->n_la * convc * (m->conv_k - 1) * sizeof(float));
}

/* ---- CPU W4A8 matmul ---- */
static void quant_act(const float *x, int K, int8_t *q, float *s) {
    for (int g = 0; g < K / QW_G; g++) {
        float a = 0;
        for (int k = 0; k < QW_G; k++) {
            float v = fabsf(x[g * QW_G + k]);
            a = v > a ? v : a;
        }
        float sc = a / 127.0f, inv = a > 0 ? 127.0f / a : 0;
        s[g] = sc;
        for (int k = 0; k < QW_G; k++) {
            float v = x[g * QW_G + k] * inv;
            q[g * QW_G + k] = (int8_t)(v >= 0 ? (int)(v + 0.5f) : -(int)(-v + 0.5f));
        }
    }
}

/* the chunk holding group g of row block rb in a Q4G64 matrix: K slices slice-major, each slice's 4096-row
 * launches contiguous, a launch's 1024 chunks in the qwen_gemv stream order [pn][jj][pm] (qwen_convert.py) */
static const uint8_t *q4_chunk(const qw_mat *w, int rb, int g) {
    const int gs = QW_SLICE_K / QW_G, L = w->prow / 4096, s = g / gs, kc = (g % gs) / QW_CHUNK_G;
    const int l = rb / 256, rbl = rb % 256, c = rbl / 16, u = rbl % 16, pm = c / 4, pn = c % 4;
    const int jj = ((kc / 2) * 16 + u) * 2 + kc % 2;
    return w->data + (((size_t)s * L + l) * 1024 + ((size_t)pn * 64 + jj) * 4 + pm) * QW_CHUNK_BYTES;
}

static void matmul_rows(const qw_mat *w, const int8_t *xq, const float *xs, int n, float *y, int rb0, int rb1) {
    const int K = w->cols, G = K / QW_G, R = w->rows;
    for (int rb = rb0; rb < rb1; rb++) {
        float acc[16 * 64];
        memset(acc, 0, sizeof(float) * 16 * (size_t)n);
        for (int g = 0; g < G; g++) {
            const uint8_t *ch = q4_chunk(w, rb, g), *blk = ch + (g % QW_CHUNK_G) * QW_GROUP_TILES;
            const uint8_t *sp = ch + QW_CHUNK_G * QW_GROUP_TILES + (g % QW_CHUNK_G) * QW_GROUP_SCALES;
            float ws[16];
            for (int r = 0; r < 16; r++)
                ws[r] = qw_bf16((uint16_t)(sp[2 * r] | sp[2 * r + 1] << 8));
            int8_t wt[64][16]; /* [k][n] */
            for (int t = 0; t < 4; t++)
                for (int e = 0; e < 256; e++) {
                    int b = blk[t * 128 + e / 2], v = (e & 1) ? (b >> 4) : (b & 15);
                    wt[t * 16 + e / 16][e % 16] = (int8_t)(v >= 8 ? v - 16 : v);
                }
            for (int i = 0; i < n; i++) {
                const int8_t *xi = xq + (size_t)i * K + g * QW_G;
                int32_t d[16] = {0};
                for (int k = 0; k < 64; k++)
                    for (int r = 0; r < 16; r++)
                        d[r] += wt[k][r] * xi[k];
                const float sx = xs[(size_t)i * G + g];
                for (int r = 0; r < 16; r++)
                    acc[i * 16 + r] += (float)d[r] * (ws[r] * sx);
            }
        }
        const int nr = R - rb * 16 < 16 ? R - rb * 16 : 16; /* the last real block may be part padding */
        for (int i = 0; i < n; i++)
            memcpy(y + (size_t)i * R + rb * 16, acc + i * 16, (size_t)nr * sizeof(float));
    }
}

void qw_matmul_cpu(void *ctx, const qw_mat *w, const float *x, int n, float *y) {
    (void)ctx;
    const int K = w->cols, G = K / QW_G;
    if (w->type == QW_F32) { /* small f32 matrices (the DeltaNet a / b) */
        const float *W = (const float *)w->data;
        for (int i = 0; i < n; i++)
            for (int r = 0; r < w->rows; r++) {
                const float *wr = W + (size_t)r * K, *xi = x + (size_t)i * K;
                float a[8] = {0, 0, 0, 0, 0, 0, 0, 0};
                int k = 0;
                for (; k + 8 <= K; k += 8)
                    for (int j = 0; j < 8; j++)
                        a[j] += wr[k + j] * xi[k + j];
                for (; k < K; k++)
                    a[0] += wr[k] * xi[k];
                y[(size_t)i * w->rows + r] = ((a[0] + a[1]) + (a[2] + a[3])) + ((a[4] + a[5]) + (a[6] + a[7]));
            }
        return;
    }
    int8_t *xq = (int8_t *)malloc((size_t)n * K);
    float *xs = (float *)malloc(sizeof(float) * (size_t)n * G);
    for (int i = 0; i < n; i++)
        quant_act(x + (size_t)i * K, K, xq + (size_t)i * K, xs + (size_t)i * G);
    const int nrb = (w->rows + 15) / 16; /* padding blocks past the real rows are skipped */
    for (int i0 = 0; i0 < n; i0 += 64) { /* acc holds 64 tokens */
        const int ni = n - i0 < 64 ? n - i0 : 64;
#ifdef _OPENMP
#pragma omp parallel for schedule(static)
#endif
        for (int rb = 0; rb < nrb; rb++)
            matmul_rows(w, xq + (size_t)i0 * K, xs + (size_t)i0 * G, ni, y + (size_t)i0 * w->rows, rb, rb + 1);
    }
    free(xq), free(xs);
}

/* ---- pieces ---- */
static float dot(const float *a, const float *b, int n);
static void rmsnorm(float *o, const float *x, const float *w, int n, float eps, int one_plus) {
    const float r = 1.0f / sqrtf(dot(x, x, n) / n + eps);
    for (int i = 0; i < n; i++)
        o[i] = x[i] * r * (one_plus ? 1.0f + w[i] : w[i]);
}
static float silu(float v) { return v / (1.0f + expf(-v)); }
static float sigm(float v) { return 1.0f / (1.0f + expf(-v)); }

/* ---- vector helpers: NEON on the A78 (the compiler does not vectorize libm calls or fp reductions), scalar elsewhere
 */
#ifdef __aarch64__
#include <arm_neon.h>
/* exp(x), 4 lanes: x = n ln2 + r, |r| <= ln2 / 2, degree-6 polynomial, 2^n through the exponent field */
static inline float32x4_t exp4(float32x4_t x) {
    x = vminq_f32(vmaxq_f32(x, vdupq_n_f32(-87.0f)), vdupq_n_f32(88.0f));
    const int32x4_t ni = vcvtnq_s32_f32(vmulq_n_f32(x, 1.44269504f));
    const float32x4_t n = vcvtq_f32_s32(ni);
    float32x4_t r = vfmsq_f32(x, n, vdupq_n_f32(0.693145752f));
    r = vfmsq_f32(r, n, vdupq_n_f32(1.42860677e-6f));
    float32x4_t p = vdupq_n_f32(0.00138888892f);
    p = vfmaq_f32(vdupq_n_f32(0.00833330024f), p, r);
    p = vfmaq_f32(vdupq_n_f32(0.0416666679f), p, r);
    p = vfmaq_f32(vdupq_n_f32(0.166666672f), p, r);
    p = vfmaq_f32(vdupq_n_f32(0.5f), p, r);
    p = vfmaq_f32(vdupq_n_f32(1.0f), p, r);
    p = vfmaq_f32(vdupq_n_f32(1.0f), p, r);
    return vmulq_f32(p, vreinterpretq_f32_s32(vshlq_n_s32(vaddq_s32(ni, vdupq_n_s32(127)), 23)));
}
static inline float32x4_t silu4(float32x4_t x) {
    return vdivq_f32(x, vaddq_f32(vdupq_n_f32(1.0f), exp4(vnegq_f32(x))));
}
#endif
/* y[i] = silu(x[i]) * (m ? m[i] : 1) */
static void silu_vec(float *y, const float *x, const float *m, int n) {
    int i = 0;
#ifdef __aarch64__
    for (; i + 4 <= n; i += 4) {
        float32x4_t s = silu4(vld1q_f32(x + i));
        vst1q_f32(y + i, m ? vmulq_f32(s, vld1q_f32(m + i)) : s);
    }
#endif
    for (; i < n; i++)
        y[i] = silu(x[i]) * (m ? m[i] : 1.0f);
}
static float dot(const float *a, const float *b, int n) {
    int i = 0;
    float s = 0;
#ifdef __aarch64__
    float32x4_t s0 = vdupq_n_f32(0), s1 = vdupq_n_f32(0);
    for (; i + 8 <= n; i += 8) {
        s0 = vfmaq_f32(s0, vld1q_f32(a + i), vld1q_f32(b + i));
        s1 = vfmaq_f32(s1, vld1q_f32(a + i + 4), vld1q_f32(b + i + 4));
    }
    s = vaddvq_f32(vaddq_f32(s0, s1));
#endif
    for (; i < n; i++)
        s += a[i] * b[i];
    return s;
}
static float softplus(float v) { return v > 20.0f ? v : log1pf(expf(v)); }

static void embed_row(const qw_model *m, int tok, float *o) {
    const int G = m->hidden / QW_G;
    const uint8_t *row = m->embed.data + (size_t)tok * G * QW_RGROUP_BYTES;
    for (int g = 0; g < G; g++) {
        const uint8_t *p = row + g * QW_RGROUP_BYTES;
        const float s = qw_bf16((uint16_t)(p[32] | p[33] << 8));
        for (int j = 0; j < 64; j++) {
            int v = (j & 1) ? (p[j / 2] >> 4) : (p[j / 2] & 15);
            o[g * 64 + j] = (float)(v >= 8 ? v - 16 : v) * s;
        }
    }
}

/* linear attention for n tokens: m->xn (normed) -> m->buf2 (out_proj input -> output via matmul) */
static void linear_attn(qw_model *m, int li, int n) {
    const qw_layer *L = &m->layer[li];
    const int kd = m->la_kd, vd = m->la_vd, kh = m->la_kh, vh = m->la_vh, K = m->conv_k;
    const int keyd = kh * kd, vald = vh * vd, convc = 2 * keyd + vald, wq = convc + vald;
    float *qkvz = m->buf0, *ab = m->buf1;
    {
        PROF_T0(m);
        m->matmul(m->matmul_ctx, &L->qkvz, m->xn, n, qkvz);
        PROF_ADD(m, QW_P_MATMUL);
    }
    {
        PROF_T0(m);
        qw_matmul_cpu(NULL, &L->ab, m->xn, n, ab); /* 2 x vh rows: CPU */
        PROF_ADD(m, QW_P_AB);
    }
    PROF_T0(m);
    const size_t ssz = (size_t)vh * kd * vd, bank = (size_t)m->n_la * ssz;
    qw_state_t *Slive = m->la_state + m->la_cur[m->slot[li]] * bank + (size_t)m->slot[li] * ssz;
    qw_state_t *Sspec = m->la_state + (1 - m->la_cur[m->slot[li]]) * bank + (size_t)m->slot[li] * ssz;
    const size_t gbank = (size_t)m->n_la * vh;
    float *Glive = m->la_sigma + m->la_cur[m->slot[li]] * gbank + (size_t)m->slot[li] * vh;
    float *Gspec = m->la_sigma + (1 - m->la_cur[m->slot[li]]) * gbank + (size_t)m->slot[li] * vh;
    float *cs = m->conv_state + (size_t)m->slot[li] * convc * (K - 1);
    const float *cw = (const float *)L->conv.data, *Alog = (const float *)L->A_log.data;
    const float *dtb = (const float *)L->dt_bias.data, *nw = (const float *)L->la_norm.data;
    float *o = m->buf2; /* reused below as the out_proj input, then output */
    static float conv[16384], qn[4096], kn[4096], core[8192];
    for (int t = 0; t < n; t++) {
        const float *in = qkvz + (size_t)t * wq, *z = in + convc, *a = ab + (size_t)t * 2 * vh, *b = a + vh;
        /* tokens after the checkpoint read the live bank (first one) and write the speculative bank */
        const int spec = m->ckpt_t >= 0 && t > m->ckpt_t;
        qw_state_t *S_in = spec && t > m->ckpt_t + 1 ? Sspec : Slive, *S_out = spec ? Sspec : Slive;
        float *G_in = spec && t > m->ckpt_t + 1 ? Gspec : Glive, *G_out = spec ? Gspec : Glive;
        const double tc0 = m->now ? m->now() : 0;
        for (int c = 0; c < convc; c++) { /* causal conv1d over [state, x] + SiLU, shift the state */
            float *st = cs + (size_t)c * (K - 1), acc = cw[c * K + K - 1] * in[c];
            for (int j = 0; j < K - 1; j++)
                acc += cw[c * K + j] * st[j];
            for (int j = 0; j < K - 2; j++)
                st[j] = st[j + 1];
            st[K - 2] = in[c];
            conv[c] = acc;
        }
        silu_vec(conv, conv, NULL, convc);
        for (int h = 0; h < kh; h++) { /* l2norm q, k per head; q / sqrt(kd) */
            double sq = 0, sk = 0;
            for (int i = 0; i < kd; i++)
                sq += (double)conv[h * kd + i] * conv[h * kd + i],
                    sk += (double)conv[keyd + h * kd + i] * conv[keyd + h * kd + i];
            const float rq = 1.0f / sqrtf((float)sq + 1e-6f) / sqrtf((float)kd), rk = 1.0f / sqrtf((float)sk + 1e-6f);
            for (int i = 0; i < kd; i++)
                qn[h * kd + i] = conv[h * kd + i] * rq, kn[h * kd + i] = conv[keyd + h * kd + i] * rk;
        }
        const double tc1 = m->now ? m->now() : 0;
        if (m->now)
            m->prof[QW_P_DN_CONV] += tc1 - tc0;
        for (int h = 0; h < vh; h++) {
            const int hk = h / (vh / kh);
            const float *q = qn + hk * kd, *k = kn + hk * kd, *v = conv + 2 * keyd + h * vd;
            const float beta = sigm(b[h]), decay = expf(-expf(Alog[h]) * softplus(a[h] + dtb[h]));
            const qw_state_t *Si = S_in + (size_t)h * kd * vd;
            qw_state_t *So = S_out + (size_t)h * kd * vd;
            float kv[256], *out = core + h * vd;
            /* lazy decay: the state is sigma x Sm. With sigma' = decay sigma:
             *   kv  = (v - sigma' Sm^T k) beta,   out = sigma' Sm^T q + kv (k . q)   (S'^T q, S' = decay S + k kv^T)
             *   Sm' = Sm + (k / sigma') kv^T      (one FMA per element; the decay multiply is on sigma only) */
            float qq[256], kq = 0;
            for (int j = 0; j < vd; j++)
                kv[j] = 0, qq[j] = 0;
            for (int i = 0; i < kd; i++) { /* pass 1 (read): Sm^T k and Sm^T q together */
                const float ki = k[i], qi = q[i];
                const qw_state_t *row = Si + (size_t)i * vd;
                kq += ki * qi;
                for (int j = 0; j < vd; j++)
                    kv[j] += row[j] * ki, qq[j] += row[j] * qi;
            }
            float sig = G_in[h] * decay, keep = 1.0f;
            if (sig < 1e-20f) /* renormalize: fold sigma into the matrix (also covers a decay of ~0) */
                keep = sig, sig = 1.0f;
            for (int j = 0; j < vd; j++) {
                kv[j] = (v[j] - (keep * sig) * kv[j]) * beta;
                out[j] = (keep * sig) * qq[j] + kv[j] * kq;
            }
            for (int i = 0; i < kd; i++) { /* pass 2 (read + write): the rank-1 update */
                const float ci = k[i] / sig;
                const qw_state_t *row = Si + (size_t)i * vd;
                qw_state_t *orow = So + (size_t)i * vd;
                if (keep == 1.0f)
                    for (int j = 0; j < vd; j++)
                        orow[j] = row[j] + ci * kv[j];
                else
                    for (int j = 0; j < vd; j++)
                        orow[j] = keep * row[j] + ci * kv[j];
            }
            G_out[h] = sig;
            rmsnorm(out, out, nw, vd, m->eps, 0);
            float zg[256];
            silu_vec(zg, z + h * vd, out, vd); /* silu(z) * out */
            memcpy(out, zg, sizeof(float) * vd);
        }
        if (m->now)
            m->prof[QW_P_DN_HEADS] += m->now() - tc1;
        memcpy(o + (size_t)t * vald, core, sizeof(float) * vald);
        if (t == m->ckpt_t) /* speculative decoding: the conv state after the last token known to be kept */
            memcpy(m->conv_ckpt + (size_t)m->slot[li] * convc * (K - 1), cs, sizeof(float) * convc * (K - 1));
    }
    memcpy(m->buf1, o, sizeof(float) * (size_t)n * vald);
    PROF_ADD(m, QW_P_DELTANET);
    PROF_RE(m);
    m->matmul(m->matmul_ctx, &L->la_out, m->buf1, n, m->buf2);
    PROF_ADD(m, QW_P_MATMUL);
}

static void rope(float *v, int pos, int rot, float theta) {
    const int h = rot / 2;
    for (int i = 0; i < h; i++) {
        const float f = (float)pos / powf(theta, (float)(2 * i) / (float)rot);
        const float c = cosf(f), s = sinf(f), a = v[i], b = v[i + h];
        v[i] = a * c - b * s, v[i + h] = b * c + a * s;
    }
}

static void full_attn(qw_model *m, const qw_layer *L, float *kc, float *vc, int n, int pos) {
    const int H = m->heads, KV = m->kv_heads, D = m->head_dim, qd = H * D * 2, kvd = KV * D;
    const int rot = (int)(D * m->rope_frac), wq = qd + 2 * kvd;
    float *qkv = m->buf0, *att = m->buf1;
    {
        PROF_T0(m);
        m->matmul(m->matmul_ctx, &L->qkv, m->xn, n, qkv);
        PROF_ADD(m, QW_P_MATMUL);
    }
    PROF_T0(m);
    const float *qnw = (const float *)L->q_norm.data, *knw = (const float *)L->k_norm.data;
    static float sc[1 << 16], q[256];
    for (int t = 0; t < n; t++) {
        const int p = pos + t;
        const float *row = qkv + (size_t)t * wq;
        for (int j = 0; j < KV; j++) { /* k_norm + RoPE into the cache, v as is */
            float *kp = kc + (size_t)p * kvd + j * D;
            rmsnorm(kp, row + qd + j * D, knw, D, m->eps, 1);
            rope(kp, p, rot, m->theta);
            memcpy(vc + (size_t)p * kvd + j * D, row + qd + kvd + j * D, sizeof(float) * D);
        }
        float *o = att + (size_t)t * H * D;
        for (int h = 0; h < H; h++) {
            const float *qh = row + h * 2 * D, *gate = qh + D;
            rmsnorm(q, qh, qnw, D, m->eps, 1);
            rope(q, p, rot, m->theta);
            const int j = h / (H / KV);
            float mx = -1e30f, sum = 0;
            for (int s = 0; s <= p; s++) {
                sc[s] = dot(q, kc + (size_t)s * kvd + j * D, D) / sqrtf((float)D);
                mx = sc[s] > mx ? sc[s] : mx;
            }
            for (int s = 0; s <= p; s++)
                sc[s] = expf(sc[s] - mx), sum += sc[s];
            float *oh = o + h * D;
            for (int i = 0; i < D; i++)
                oh[i] = 0;
            for (int s = 0; s <= p; s++) {
                const float w = sc[s] / sum, *vp = vc + (size_t)s * kvd + j * D;
                for (int i = 0; i < D; i++)
                    oh[i] += w * vp[i];
            }
            for (int i = 0; i < D; i++)
                oh[i] *= sigm(gate[i]);
        }
    }
    PROF_ADD(m, QW_P_ATTN);
    PROF_RE(m);
    m->matmul(m->matmul_ctx, &L->o, att, n, m->buf2);
    PROF_ADD(m, QW_P_MATMUL);
}

static void mlp(qw_model *m, const qw_layer *L, int n) {
    const int F = m->ffn;
    float *gu = m->buf0, *h = m->buf1;
    {
        PROF_T0(m);
        m->matmul(m->matmul_ctx, &L->mlp_gu, m->xn, n, gu);
        PROF_ADD(m, QW_P_MATMUL);
    }
    {
        PROF_T0(m);
        for (int t = 0; t < n; t++)
            silu_vec(h + (size_t)t * F, gu + (size_t)t * 2 * F, gu + (size_t)t * 2 * F + F, F);
        PROF_ADD(m, QW_P_MLPACT);
    }
    PROF_T0(m);
    m->matmul(m->matmul_ctx, &L->mlp_down, h, n, m->buf2);
    PROF_ADD(m, QW_P_MATMUL);
}

/* one decoder layer on m->x (n tokens): attention (full or linear) and the MLP, each with its residual */
static void decoder_layer(qw_model *m, const qw_layer *L, int li, float *kc, float *vc, int n, int pos) {
    const int Hd = m->hidden;
    for (int t = 0; t < n; t++)
        rmsnorm(m->xn + (size_t)t * Hd, m->x + (size_t)t * Hd, (const float *)L->in_norm.data, Hd, m->eps, 1);
    if (L->full)
        full_attn(m, L, kc, vc, n, pos);
    else
        linear_attn(m, li, n);
    for (size_t i = 0; i < (size_t)n * Hd; i++)
        m->x[i] += m->buf2[i];
    for (int t = 0; t < n; t++)
        rmsnorm(m->xn + (size_t)t * Hd, m->x + (size_t)t * Hd, (const float *)L->post_norm.data, Hd, m->eps, 1);
    mlp(m, L, n);
    for (size_t i = 0; i < (size_t)n * Hd; i++)
        m->x[i] += m->buf2[i];
}

int qw_forward_ex(qw_model *m, const int *tok, int n, int pos, int nlog, int ckpt_t) {
    const int Hd = m->hidden;
    const size_t kvd = (size_t)m->kv_heads * m->head_dim;
    if (n > m->max_batch || pos + n > m->max_ctx || nlog < 1 || nlog > QW_MAX_LOG || nlog > n)
        return -1;
    m->ckpt_t = ckpt_t;
    for (int t = 0; t < n; t++)
        embed_row(m, tok[t], m->x + (size_t)t * Hd);
    for (int li = 0; li < m->layers; li++) {
        const size_t off = (size_t)m->slot[li] * m->max_ctx * kvd;
        decoder_layer(m, &m->layer[li], li, m->kcache + off, m->vcache + off, n, pos);
    }
    m->ckpt_t = -1;
    memcpy(m->hid_pre, m->x, sizeof(float) * (size_t)n * Hd);
    for (int t = 0; t < n; t++)
        rmsnorm(m->hid + (size_t)t * Hd, m->x + (size_t)t * Hd, (const float *)m->final_norm.data, Hd, m->eps, 1);
    {
        PROF_T0(m);
        m->matmul(m->matmul_ctx, &m->lm_head, m->hid + (size_t)(n - nlog) * Hd, nlog, m->logits);
        PROF_ADD(m, QW_P_LM);
    }
    return 0;
}

int qw_forward(qw_model *m, const int *tok, int n, int pos) { return qw_forward_ex(m, tok, n, pos, 1, -1); }

void qw_commit(qw_model *m) {
    for (int i = 0; i < m->n_la; i++)
        m->la_cur[i] ^= 1;
}

void qw_rollback(qw_model *m) { /* the live DeltaNet bank still holds the state after ckpt_t */
    const size_t convc = (size_t)2 * m->la_kh * m->la_kd + (size_t)m->la_vh * m->la_vd;
    memcpy(m->conv_state, m->conv_ckpt, sizeof(float) * (size_t)m->n_la * convc * (m->conv_k - 1));
}

/* MTP (Qwen3-Next style): x = fc([norm_e(embed(next token)), norm_h(hidden)]), one full-attention decoder
 * layer with its own KV cache, the MTP norm, the shared lm_head */
int qw_mtp(qw_model *m, const int *tok, const float *hid, int n, int pos, int want) {
    const int Hd = m->hidden;
    if (!m->mtp || n > m->max_batch || pos + n > m->max_ctx || pos < 0)
        return -1;
    float *cat = m->buf1; /* [n][2 Hd] */
    for (int t = 0; t < n; t++) {
        embed_row(m, tok[t], m->xn);
        rmsnorm(cat + (size_t)t * 2 * Hd, m->xn, (const float *)m->mtp_norm_e.data, Hd, m->eps, 1);
        rmsnorm(cat + (size_t)t * 2 * Hd + Hd, hid + (size_t)t * Hd, (const float *)m->mtp_norm_h.data, Hd, m->eps, 1);
    }
    m->matmul(m->matmul_ctx, &m->mtp_fc, cat, n, m->x);
    decoder_layer(m, &m->mtp_layer, -1, m->mtp_k, m->mtp_v, n, pos);
    if (!want)
        return 0;
    rmsnorm(m->xn, m->x + (size_t)(n - 1) * Hd, (const float *)m->mtp_norm.data, Hd, m->eps, 1);
    qw_mat lm = m->lm_head; /* a draft vocabulary: the first rows (whole 4096-row launches) of lm_head */
    if (m->mtp_vocab > 0 && m->mtp_vocab < lm.rows) {
        lm.rows = (m->mtp_vocab + 4095) / 4096 * 4096;
        lm.prow = lm.rows;
    }
    m->matmul(m->matmul_ctx, &lm, m->xn, 1, m->mlogits);
    return qw_token(m, m->mlogits, lm.rows);
}

int qw_token(const qw_model *m, const float *logits, int rows) {
    const int i = qw_argmax(logits, rows);
    return m->lm_perm ? m->lm_perm[i] : i;
}

int qw_argmax(const float *v, int n) {
    int b = 0;
    for (int i = 1; i < n; i++)
        if (v[i] > v[b])
            b = i;
    return b;
}

static int is_stop(int t, const int *stop, int nstop) {
    for (int i = 0; i < nstop; i++)
        if (t == stop[i])
            return 1;
    return 0;
}

int qw_generate(qw_model *m, const int *prompt, int n, int ngen, int spec, const int *stop, int nstop, qw_emit_fn emit,
                void *ctx, double (*now)(void), qw_gen_stats *st) {
    const int Hd = m->hidden, B = m->max_batch;
    float *last = (float *)malloc(sizeof(float) * Hd);
    memset(st, 0, sizeof *st);
    spec = spec && m->mtp;
    double t0 = now ? now() : 0;
    int pos = 0;
    for (int i = 0; i < n; i += B) {
        const int nb = n - i < B ? n - i : B;
        if (qw_forward_ex(m, prompt + i, nb, i, 1, -1))
            return -1;
        const int pairs = n - i - 1 < nb ? n - i - 1 : nb; /* MTP cache: (next token, this hidden) */
        if (spec && pairs > 0)
            qw_mtp(m, prompt + i + 1, m->mtp_hid_pre ? m->hid_pre : m->hid, pairs, i + m->mtp_pos_off, 0);
        if (i + nb == n)
            memcpy(last, (m->mtp_hid_pre ? m->hid_pre : m->hid) + (size_t)(nb - 1) * Hd, sizeof(float) * Hd);
    }
    pos = n;
    double t1 = now ? now() : 0;
    st->prefill_s = t1 - t0;
    int t = qw_token(m, m->logits, m->vocab);
    emit(ctx, t), st->emitted++;
    while (st->emitted < ngen && !is_stop(t, stop, nstop)) {
        st->steps++;
        if (!spec) {
            if (qw_forward_ex(m, &t, 1, pos++, 1, -1))
                break;
            t = qw_token(m, m->logits, m->vocab);
            emit(ctx, t), st->emitted++;
            continue;
        }
        const int d = qw_mtp(m, &t, last, 1, pos - 1 + m->mtp_pos_off, 1);
        const int toks[2] = {t, d};
        st->drafted++;
        if (pos + 2 > m->max_ctx || qw_forward_ex(m, toks, 2, pos, 2, 0))
            break;
        const int a0 = qw_token(m, m->logits, m->vocab);
        const float *hsrc = m->mtp_hid_pre ? m->hid_pre : m->hid;
        if (a0 == d) { /* the draft holds: two tokens for one weight pass */
            qw_commit(m);
            st->accepted++;
            emit(ctx, d), st->emitted++;
            if (is_stop(d, stop, nstop) || st->emitted >= ngen)
                break;
            t = qw_token(m, m->logits + m->vocab, m->vocab);
            memcpy(last, hsrc + Hd, sizeof(float) * Hd);
            if (m->mtp_fill) /* the pair (d, hidden of t) the draft skipped: keeps the MTP's attention gap-free */
                qw_mtp(m, &d, m->hid_pre == hsrc ? m->hid_pre : hsrc, 1, pos + m->mtp_pos_off, 0);
            pos += 2;
        } else { /* drop the draft: back to the state after t */
            qw_rollback(m);
            t = a0;
            memcpy(last, hsrc, sizeof(float) * Hd);
            pos += 1;
        }
        emit(ctx, t), st->emitted++;
    }
    st->decode_s = (now ? now() : 0) - t1;
    free(last);
    return 0;
}
