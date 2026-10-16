/* we_desc.h -- the Whisper engine's op contract, shared by the AIE kernel, the
 * host driver and gen_engine.py. Plain C, no includes.
 * Full picture: doc/design/whisper_aie_engine.md.
 *
 * Every op starts with a WE_HDR_BYTES header on the A channel (core S2MM ch0,
 * row broadcast from MT_A): int32 words WH_*, then a parameter area at
 * WE_PRM_OFF (bias / gamma,beta as bf16).
 *
 * Activation layout in DDR and memtiles ("BLK"): a [M x C] bf16 tensor with
 * M = 4 * RB rows (RB = rows per mesh-row block, multiple of 64) is
 *   [r 4][cb C/48][rg RB/4][kt 6][4][8]
 * tile (r, cb) = RB rows x 48 cols; inside, 4-row groups of 6 8-col tiles:
 * the mmul<4,8,8> A-tile and the GEMM C-tile layout. A 64-row slice of a tile
 * (16 row groups, 6 KB) is one GEMM A chunk and one GEMM output block.
 *
 * GEMM  C[M x N] = epi(A[M x K] * W[N x K]^T): core (r,c) owns rows of block r
 *       and column tiles cb = c*NB + nb (NB = N/192); loops nb, mb, k-chunk.
 *       A chunk 64x48 [rg16][kt6][4][8] (= tile slice), B chunk 48x48
 *       [kt6][nt6][8][8], out block 64x48 [rg16][nt6][4][8] (6 KB).
 *       WE_F_RES: after each block's k-chunks, A carries the residual blocks of
 *       the 4 mesh columns (4 chunks; chunk c is column c's).
 *       WE_F_KT: blocks with cb in [kt_lo, kt_hi) are written transposed,
 *       [dt 6][kp 8][8 dims][8 keys] (the B tile of S = Q K^T).
 *       WE_F_GELU: exact erf-GELU of the bf16-rounded value (table, see
 *       gen_gelu_lut.py / we_model.gelu_aie).
 * LN    y = LayerNorm(x) * gamma + beta (C = 384); A carries the row block one
 *       4-row group at a time (3 KB: [cb 8][kt 6][4][8]); core c of the mesh row
 *       handles groups [c*RGC, (c+1)*RGC) and emits one 3 KB packet each.
 */
#ifndef WE_DESC_H
#define WE_DESC_H

#define WE_MAGIC 0x31455745 /* "EWE1" */
#define WE_HDR_BYTES 4096
#define WE_PRM_OFF 256
#define WE_TM 64
#define WE_TN 48
#define WE_KC 48
#define WE_A_CHUNK (WE_TM * WE_KC * 2) /* 6144 */
#define WE_B_CHUNK (WE_TN * WE_KC * 2) /* 4608 */
#define WE_BLK (WE_TM * WE_TN * 2)     /* 6144: one GEMM output block */
#define WE_RG_ROW (4 * 384 * 2)        /* 3072: one 4-row group of a 384-wide row */

enum { WE_OP_GEMM = 1, WE_OP_LN = 2, WE_OP_ATTN = 3 };

#define WE_F_BIAS 1
#define WE_F_GELU 2
#define WE_F_RES 4
#define WE_F_KT 8

enum {
    WH_MAGIC = 0,
    WH_OP,
    WH_SEQ,
    WH_RACT, /* active mesh rows (decoder: 1) */
    /* GEMM */
    WH_MB = 4,
    WH_NB,
    WH_KCN,
    WH_FLAGS,
    WH_N,
    WH_KT_LO,
    WH_KT_HI,
    /* LN */
    WH_RGC = 4, /* row groups per core */
    WH_EPS,     /* float bits */
    WH_NWORDS = 16
};

#endif
