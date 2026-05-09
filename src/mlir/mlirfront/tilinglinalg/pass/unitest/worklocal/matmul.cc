// User-provided compute kernel (extracted from __global__ function)
// User macro definitions from source file
#define M 256
#define K 256
#define N 256
#define HW_ROWS 4
#define HW_COLS 4
#define K_DIM K                 // inner product dimension
#define PP_MAX_BYTES 4096       // max ping-pong buffer size
#define TILE_ROWS (M / HW_ROWS) // output rows per tile
#define TILE_COLS (N / HW_COLS) // output cols per tile
#define ROWS_PER_ROUND_RAW (TILE_ROWS / 2)
#define ROWS_PER_ROUND ((ROWS_PER_ROUND_RAW * K_DIM > PP_MAX_BYTES) ? (PP_MAX_BYTES / K_DIM) : ROWS_PER_ROUND_RAW)
#define NUM_A_ROUNDS (TILE_ROWS / ROWS_PER_ROUND)
#define COLS_PER_ROUND_RAW (TILE_COLS / 2)
#define COLS_PER_ROUND ((COLS_PER_ROUND_RAW * K_DIM > PP_MAX_BYTES) ? (PP_MAX_BYTES / K_DIM) : COLS_PER_ROUND_RAW)
#define NUM_B_ROUNDS (TILE_COLS / COLS_PER_ROUND)
#define OUTPUT_PER_CORE (TILE_ROWS * TILE_COLS)
#define OUTPUT_PP_RAW (OUTPUT_PER_CORE / 2)
#define BUF_SZ_OUT ((OUTPUT_PP_RAW > PP_MAX_BYTES) ? PP_MAX_BYTES : OUTPUT_PP_RAW)
#define NUM_OUTPUT_ROUNDS (OUTPUT_PER_CORE / BUF_SZ_OUT)
#define DEBUG_OUTPUT_ORDER 0

void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1, output_window_int8 *window_out_0) {

#if DEBUG_OUTPUT_ORDER
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;
    int8_t tag = (int8_t)((row & 0x7) | ((col & 0x7) << 3));
    klog("DEBUG", 2);
#endif

    // Local buffers
    int8_t all_A[TILE_ROWS * K_DIM]; // cache all A data
    int8_t local_out[TILE_ROWS * TILE_COLS];

    // ===== Phase 1: Receive and cache all A chunks =====
    for (int ra = 0; ra < NUM_A_ROUNDS; ra++) {
        int8_t *A_ptr = (int8_t *)acquire_input_window(window_in_0);
        for (int i = 0; i < ROWS_PER_ROUND * K_DIM; i++)
            all_A[ra * ROWS_PER_ROUND * K_DIM + i] = A_ptr[i];
        release_input_window(window_in_0);
    }

#if DEBUG_OUTPUT_ORDER
    // Log first K_DIM elements of cached A
    for (int i = 0; i < K_DIM; i++) {
        klog("A0  ", (int32_t)all_A[i]);
    }
#endif

    // ===== Phase 2: Stream B, compute all sub-blocks =====
    for (int rb = 0; rb < NUM_B_ROUNDS; rb++) {
        int8_t *B_ptr = (int8_t *)acquire_input_window(window_in_1);

#if DEBUG_OUTPUT_ORDER
        if (rb == 0) {
            for (int i = 0; i < K_DIM; i++) {
                klog("B0  ", (int32_t)B_ptr[i]);
            }
        }
#endif

        for (int ra = 0; ra < NUM_A_ROUNDS; ra++) {
            for (int i = 0; i < ROWS_PER_ROUND; i++) {
                for (int j = 0; j < COLS_PER_ROUND; j++) {
                    int16_t sum = 0;
                    for (int k = 0; k < K_DIM; k++)
                        sum += (int16_t)all_A[(ra * ROWS_PER_ROUND + i) * K_DIM + k] * (int16_t)B_ptr[j * K_DIM + k];
                    if (sum > 127)
                        sum = 127;
                    else if (sum < -128)
                        sum = -128;
#if DEBUG_OUTPUT_ORDER
                    if (j == 0)
                        sum = tag | (((ra * NUM_B_ROUNDS + rb) & 0x3) << 6);
#endif
                    local_out[(ra * ROWS_PER_ROUND + i) * TILE_COLS + rb * COLS_PER_ROUND + j] = (int8_t)sum;
                }
            }
        }

        release_input_window(window_in_1);
    }

    // ===== Phase 3: Output =====
    for (int round = 0; round < NUM_OUTPUT_ROUNDS; round++) {
        int8_t *out = (int8_t *)acquire_output_window(window_out_0);
        for (int i = 0; i < BUF_SZ_OUT; i++)
            out[i] = local_out[round * BUF_SZ_OUT + i];
        release_output_window(window_out_0);
    }
}
