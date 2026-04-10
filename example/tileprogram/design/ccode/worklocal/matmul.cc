// User-provided compute kernel (extracted from __global__ function)
// C_tile[8x8] = A_tile[8x16] * B_tile^T[8x16], int8
// B transposed: C[i][j] = dot(A_row[i,:], B_row[j,:])
//
// 2 input rounds (4x16 per acquire), 4 output rounds (4x4 per acquire)
// Round 1: cache A0,B0 + compute 1 sub-block
// Round 2: use cached + new data, compute 3 sub-blocks
#define CHUNK_M 4
#define CHUNK_N 4
#define K_DIM 16

void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1, output_window_int8 *window_out_0) {

    // Local cache for round-1 data reuse in round-2
    int8_t cache_A[CHUNK_M * K_DIM]; // 4 x 16 = 64 bytes
    int8_t cache_B[CHUNK_M * K_DIM]; // 4 x 16 = 64 bytes

    // ===== Round 1: acquire + cache + compute 1 sub-block =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0); // A[0:3, 0:15]
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1); // B[0:3, 0:15]

    // Cache for reuse in round 2
    for (int i = 0; i < CHUNK_M * K_DIM; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }

    // Compute C[0:3, 0:3] = dot(A0, B0^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A0[i * K_DIM + k] * (int16_t)B0[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // ===== Round 2: acquire + compute 3 sub-blocks =====
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0); // A[4:7, 0:15]
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1); // B[4:7, 0:15]

    // Sub-block 2: C[0:3, 4:7] = dot(cached_A0, B1^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)cache_A[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    // Sub-block 3: C[4:7, 0:3] = dot(A1, cached_B0^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A1[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    // Sub-block 4: C[4:7, 4:7] = dot(A1, B1^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A1[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);
}
