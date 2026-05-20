// User-provided compute kernel (extracted from __global__ function)
// User macro definitions from source file
#define DEBUG_OUTPUT_ORDER 1

void matmul(input_window_int8 *win_a, input_window_int8 *win_b, output_window_int8 *win_c) {

    // Compiler-resolved tiling parameters
    const int tile_rows = 4;
    const int tile_cols = 4;
    const int k_dim = 16;
    const int num_a_rounds = 2;
    const int num_b_rounds = 2;
    const int num_c_rounds = 2;
    const int buf_sz_a = 32;
    const int buf_sz_b = 32;
    const int buf_sz_c = 8;

    // Derived per-round sizes
    const int rows_per_round = buf_sz_a / k_dim;
    const int cols_per_round = buf_sz_b / k_dim;

#if DEBUG_OUTPUT_ORDER
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;
    int8_t tag = (int8_t)((row & 0x7) | ((col & 0x7) << 3));
    klog("DEBUG", 3);
#endif

    // Local buffers
    int8_t all_A[tile_rows * k_dim];
    int8_t local_out[tile_rows * tile_cols];

    // ===== Phase 1: Receive and cache all A chunks =====
    for (int ra = 0; ra < num_a_rounds; ra++) {
        int8_t *A_ptr = (int8_t *)acquire_input_window(win_a);
        for (int i = 0; i < buf_sz_a; i++)
            all_A[ra * buf_sz_a + i] = A_ptr[i];
        release_input_window(win_a);
    }

#if DEBUG_OUTPUT_ORDER
    for (int i = 0; i < 16; i++) {
        klog("A0  ", (int32_t)all_A[i]);
    }
#endif

    // ===== Phase 2: Stream B, compute all sub-blocks =====
    for (int rb = 0; rb < num_b_rounds; rb++) {
        int8_t *B_ptr = (int8_t *)acquire_input_window(win_b);

#if DEBUG_OUTPUT_ORDER
        if (rb == 0) {
            for (int i = 0; i < 16; i++) {
                klog("B0  ", (int32_t)B_ptr[i]);
            }
        }
#endif

        for (int ra = 0; ra < num_a_rounds; ra++) {
            for (int i = 0; i < rows_per_round; i++) {
                for (int j = 0; j < cols_per_round; j++) {
                    int16_t sum = 0;
                    for (int k = 0; k < k_dim; k++)
                        sum += (int16_t)all_A[(ra * rows_per_round + i) * k_dim + k] * (int16_t)B_ptr[j * k_dim + k];
                    if (sum > 127)
                        sum = 127;
                    else if (sum < -128)
                        sum = -128;
#if DEBUG_OUTPUT_ORDER
                    if (j == 0)
                        sum = tag | (((ra * num_b_rounds + rb) & 0x3) << 6);
#endif
                    local_out[(ra * rows_per_round + i) * tile_cols + rb * cols_per_round + j] = (int8_t)sum;
                }
            }
        }

        release_input_window(win_b);
    }

    // ===== Phase 3: Output =====
    for (int rc = 0; rc < num_c_rounds; rc++) {
        int8_t *out = (int8_t *)acquire_output_window(win_c);
        for (int i = 0; i < buf_sz_c; i++)
            out[i] = local_out[rc * buf_sz_c + i];
#if DEBUG_OUTPUT_ORDER
        if (rc == 0) {
            for (int l = 0; l < 8; l++) {
                klog("C0 ", (int32_t)out[l]);
            }
        }
#endif
        release_output_window(win_c);
    }
}
