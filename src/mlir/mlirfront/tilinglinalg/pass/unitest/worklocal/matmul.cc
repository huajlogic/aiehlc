// User-provided compute kernel (extracted from __global__ function)
void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1, output_window_int8 *window_out_0) {

#define M 16
#define K 16
#define N 16
#define CHUNK_M 4     // Rows per input acquire (both A and B chunks)
#define CHUNK_N 4     // Output cols per sub-block (= B rows per acquire mapped to C cols)
#define BUF_SZ_IN 16  // Input buffer: 16 v4int8 = 64 bytes = 4 rows x 16 cols
#define BUF_SZ_OUT 4  // Output buffer: 4 v4int8 = 16 bytes = 4 rows x 4 cols
#define CACHE_SIZE 64 // Local cache per input: CHUNK_M * K = 4 x 16 = 64 bytes

    // Local cache for round-1 data reuse in round-2
    int8_t cache_A[CHUNK_M * K]; // 4 x 16 = 64 bytes
    int8_t cache_B[CHUNK_M * K]; // 4 x 16 = 64 bytes

    // ===== Round 1: acquire + cache + compute 1 sub-block =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0); // A[0:3, 0:15]
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1); // B[0:3, 0:15]

    // Cache for reuse in round 2
    for (int i = 0; i < CHUNK_M * K; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }

    // Compute C[0:3, 0:3] = dot(A0, B0^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)A0[i * K + k] * (int16_t)B0[j * K + k];
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
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)cache_A[i * K + k] * (int16_t)B1[j * K + k];
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
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)A1[i * K + k] * (int16_t)cache_B[j * K + k];
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
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)A1[i * K + k] * (int16_t)B1[j * K + k];
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
