// User-provided compute kernel (extracted from __global__ function)
// User macro definitions from source file
#define M 128
#define K 128
#define N 128
#define HW_ROWS 4
#define HW_COLS 4
#define TILE_ROWS (M / HW_ROWS)                 // 4: total output rows per tile
#define TILE_COLS (N / HW_COLS)                 // 4: total output cols per tile
#define ROWS_PER_ROUND (TILE_ROWS / 2)          // 2: A/B rows per DMA input round
#define COLS_PER_ROUND (TILE_COLS / 2)          // 2: B cols per DMA input round
#define K_DIM K                                 // 16: inner product dimension
#define BUF_SZ_OUT (ROWS_PER_ROUND * TILE_COLS) // 8: output bytes per DMA round (2 rows * 4 cols)
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
    int8_t cache_A[ROWS_PER_ROUND * K_DIM];
    int8_t cache_B[ROWS_PER_ROUND * K_DIM];
    int8_t local_out[TILE_ROWS * TILE_COLS];

    // ===== Step 1: Receive-only ping — acquire+cache+release inputs =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1);
    for (int i = 0; i < ROWS_PER_ROUND * K_DIM; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }
    release_input_window(window_in_0);
    release_input_window(window_in_1);
#if DEBUG_OUTPUT_ORDER
    // Log first COLS_PER_ROUND elements of A and B
    for (int i = 0; i < K_DIM; i++) {
        klog("A0  ", (int32_t)cache_A[i]);
    }
    for (int i = 0; i < K_DIM; i++) {
        klog("B0  ", (int32_t)cache_B[i]);
    }
#endif

    // ===== Step 2: Compute top-left quadrant from cached data =====
    // C[0:RPR-1, 0:CPR-1] = A0 * B0^T (top-left)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)cache_A[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((0 & 0x3) << 6);
#endif
            local_out[i * TILE_COLS + j] = (int8_t)sum;
        }
    }

    // ===== Step 3: Receive pong =====
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1);

    // ===== Step 4: Compute remaining 3 quadrants =====
    // C[0:RPR-1, CPR:TILE_COLS-1] = cached_A0 * B1^T (top-right)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)cache_A[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((1 & 0x3) << 6);
#endif
            local_out[i * TILE_COLS + j + COLS_PER_ROUND] = (int8_t)sum;
        }
    }

    // C[RPR:TILE_ROWS-1, 0:CPR-1] = A1 * cached_B0^T (bottom-left)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)A1[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((2 & 0x3) << 6);
#endif
            local_out[(i + ROWS_PER_ROUND) * TILE_COLS + j] = (int8_t)sum;
        }
    }

    // C[RPR:TILE_ROWS-1, CPR:TILE_COLS-1] = A1 * B1^T (bottom-right)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)A1[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((3 & 0x3) << 6);
#endif
            local_out[(i + ROWS_PER_ROUND) * TILE_COLS + j + COLS_PER_ROUND] = (int8_t)sum;
        }
    }

    // ===== Step 5: Release pong inputs =====
    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // ===== Step 6-7: Output 2 rounds (8 bytes each, sequential row-major) =====
    for (int round = 0; round < 2; round++) {
        int8_t *out = (int8_t *)acquire_output_window(window_out_0);
        for (int i = 0; i < BUF_SZ_OUT; i++) {
            out[i] = local_out[round * BUF_SZ_OUT + i];
        }
        release_output_window(window_out_0);
    }
}
