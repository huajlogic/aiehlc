/* M2 GEMM-op contract shared by kernel and host (plain C, no includes).
 * Op header = first 4 KB A-chunk of every op (int32 words, then bias bf16 at
 * byte M2_BIAS_OFF, N entries, global column order).
 * C = A[M x K] * B[N x K]^T (+bias) on the 4x4 mesh: core (r,c) owns rows of
 * mesh-row block r and columns c*NB*96 .. ; loops nb (outer) / mb / k-chunk.
 * Activation layout in DDR ("BLK"): [r 4][cb N/96][rg 96][kt 12][4][8] bf16,
 * i.e. tile (r, cb) = 384 rows x 96 cols, 72 KB, rows in 4-row groups. */
#ifndef M2_DESC_H
#define M2_DESC_H
#define M2_HDR_BYTES 4096
#define M2_BIAS_OFF 256
#define M2_TM 64                       /* rows per block (16 row-groups of 4) */
#define M2_TN 96                       /* cols per block (12 col-tiles of 8) */
#define M2_KC 32                       /* k per chunk (4 k-tiles of 8) */
#define M2_A_CHUNK (M2_TM * M2_KC * 2) /* 4096 */
#define M2_B_CHUNK (M2_TN * M2_KC * 2) /* 6144 */
#define M2_OUT_BLK (M2_TM * M2_TN * 2) /* 12288 */
#define M2_MAGIC 0x324D5745            /* "EWM2" */
#define M2_F_BIAS 1
#define M2_F_GELU 2
#define M2_F_RES 4 /* residual tile (bf16 BLK block) follows each block's k-chunks on A, 3 chunks */
enum { MH_MAGIC = 0, MH_MB, MH_NB, MH_KCN, MH_FLAGS, MH_N, MH_SEQ, MH_NWORDS };
#endif
