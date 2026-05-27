// User-provided compute kernel (extracted from __global__ function)
// User macro definitions from source file
#define DEBUG_OUTPUT_ORDER 1

void matmul(input_window_int8 *win_a, input_window_int8 *win_b, output_window_int8 *win_c) {

    // Compiler-resolved tiling parameters
    const int tile_rows = 64;
    const int tile_cols = 64;
    const int eff_k = 64;       // K chunk size per k-round
    const int k_rounds = 4;     // number of K-accumulation rounds
    const int num_a_rounds = 1; // DMA rounds per k-round for A
    const int num_b_rounds = 1; // DMA rounds per k-round for B
    const int num_c_rounds = 1;
    const int buf_sz_a = 4096;
    const int buf_sz_b = 4096;
    const int buf_sz_c = 4096;

    // Derived per-round sizes (using effective_k, not full k_dim)
    const int rows_per_round = buf_sz_a / eff_k;
    const int cols_per_round = buf_sz_b / eff_k;

#if DEBUG_OUTPUT_ORDER
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;
    int8_t tag = (int8_t)((row & 0x7) | ((col & 0x7) << 3));
    klog("DEBUG", 3);
#endif

    // Local buffers — sized with effective_k, not full K
    int8_t all_A[tile_rows * eff_k];
    int16_t accum[tile_rows * tile_cols]; // int16 accumulator for partial sums across k-rounds
    int8_t local_out[tile_rows * tile_cols];

    // Zero accumulators
    for (int i = 0; i < tile_rows * tile_cols; i++)
        accum[i] = 0;

    // ===== K-round loop: accumulate partial products =====
    for (int kr = 0; kr < k_rounds; kr++) {

        // --- Phase 1: Receive and cache A chunk for this k-round ---
        for (int ra = 0; ra < num_a_rounds; ra++) {
            int8_t *A_ptr = (int8_t *)acquire_input_window(win_a);
            for (int i = 0; i < buf_sz_a; i++)
                all_A[ra * buf_sz_a + i] = A_ptr[i];
#if DEBUG_OUTPUT_ORDER
            if (ra == 0) {
                klog("A0  ", (int32_t)A_ptr[0]);
            }
#endif
            release_input_window(win_a);
        }

#if DEBUG_OUTPUT_ORDER
        // if (kr == 0) {
        //     for (int i = 0; i < 16; i++) {
        //         klog("A0  ", (int32_t)all_A[i]);
        //     }
        // }
#endif

        // --- Phase 2: Stream B chunk, accumulate partial products ---
        for (int rb = 0; rb < num_b_rounds; rb++) {
            int8_t *B_ptr = (int8_t *)acquire_input_window(win_b);

#if DEBUG_OUTPUT_ORDER
            if (rb == 0) {
                // for (int i = 0; i < 16; i++) {
                klog("B0  ", (int32_t)B_ptr[0]);
                //}
            }
#endif

            for (int ra = 0; ra < num_a_rounds; ra++) {
                for (int i = 0; i < rows_per_round; i++) {
                    for (int j = 0; j < cols_per_round; j++) {
                        int16_t sum = 0;
                        for (int k = 0; k < eff_k; k++)
                            sum +=
                                (int16_t)all_A[(ra * rows_per_round + i) * eff_k + k] * (int16_t)B_ptr[j * eff_k + k];
                        accum[(ra * rows_per_round + i) * tile_cols + rb * cols_per_round + j] += sum;
                    }
                }
            }

            release_input_window(win_b);
        }
    } // end k_rounds

    // ===== Saturate accumulators to int8 =====
    for (int i = 0; i < tile_rows * tile_cols; i++) {
        int16_t val = accum[i];
#if DEBUG_OUTPUT_ORDER
        // Tag output for debug ordering verification
#else
        if (val > 127)
            val = 127;
        else if (val < -128)
            val = -128;
#endif
        local_out[i] = (int8_t)val;
    }

    // ===== Phase 3: Output =====
    for (int rc = 0; rc < num_c_rounds; rc++) {
        int8_t *out = (int8_t *)acquire_output_window(win_c);
        for (int i = 0; i < buf_sz_c; i++)
            out[i] = local_out[rc * buf_sz_c + i];
#if DEBUG_OUTPUT_ORDER
        // if (rc == 0) {
        // for (int l = 0; l < 8; l++) {
        klog("C0 ", (int32_t)out[0]);
        //}
        //}///
#endif
        release_output_window(win_c);
    }
}
