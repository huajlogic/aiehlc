#include "simpleconv2d_new_load.h"
#pragma aie_debug_level(2 | AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN | AIE_DMA_ISSUE_COUNT)
// ═══════════════════════════════════════════════════════════════════════════
// Kernel-only conv2d: no aie::Conv2d, no aie::Mapping.
//
// The kernel says what it moves -- each port's whole tensor (aie::shape) and,
// per core, which blocks of it it loads and stores -- and the compiler derives
// the DMA from that. Before compiling, aiehlc runs the kernel's block schedule
// on x86 for every core of the launch mesh (kernel analysis, see
// doc/design/op_mapping_programming_model.md "Kernel analysis") and:
//   * fits each port's block sequence to base + i*step_i + j*step_j (a DMA BD),
//   * recognizes the spatial-halo conv in it (mesh split, tiles, stride, halo),
//   * checks every block against the derived DMA, the tensor bounds, the core
//     memory, pp_depth, release/commit pairing, output coverage, and -- under
//     AddressSanitizer -- that the kernel touches only data it loaded.
// `aiehlc-convtile trace <this file>` runs the same analysis standalone.
//
// Tensors are the DDR buffers as the host lays them out:
//   win_a  [230, 230, 4]  input, pre-padded by 3 and channel-aligned 3 -> 4
//   win_b  [64, 7, 7, 4]  filter B^T: [oc][kh][kw][c]
//   win_c  [112, 112, 64] output, HWC
// ═══════════════════════════════════════════════════════════════════════════
__global__ void conv2d_spatial(aie::port<input_window_int8 *, aie::IFM, aie::shape<230, 230, 4>> win_a,
                               aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<64, 7, 7, 4>> win_b,
                               aie::port<output_window_int8 *, aie::OFM, aie::shape<112, 112, 64>> win_c) {
    // The operator and the tiling live in the kernel.
    const int KH = 7, KW = 7, S = 2, C = 4;         // 7x7 stride-2 conv, 4 (aligned) channels
    const int oh_t = 7, ow_t = 28, oc_t = 16;       // output block computed per round
    const int ih_t = (oh_t - 1) * S + KH;           // 19: input footprint of one output block
    const int iw_t = (ow_t - 1) * S + KW;           // 61
    const int oh_core = 112 / aie::num_programs(0); // 28 output rows per mesh row
    const int TAPS = KH * KW * C;                   // 196

    const int pid_h = aie::program_id(0); // mesh row: which OH band
    const int pid_c = aie::program_id(1); // mesh col: which OC group

    // This core's filters: output channels [pid_c*16, +16), all taps.
    const int8_t *w = aie::load_buffer(win_b, {pid_c * oc_t, 0, 0, 0}, {oc_t, KH, KW, C});

    for (int i = 0; i < oh_core / oh_t; i++) {          // 4 row blocks
        for (int j = 0; j < 112 / ow_t; j++) {          // 4 column blocks
            const int oh0 = pid_h * oh_core + i * oh_t; // output block origin
            const int ow0 = j * ow_t;
            // Its input footprint (the halo overlaps the neighbouring blocks).
            const int8_t *x = aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C});
            int8_t *y = aie::store_buffer(win_c, {oh0, ow0, pid_c * oc_t}, {oh_t, ow_t, oc_t});

            for (int oh = 0; oh < oh_t; oh++) {
                for (int ow = 0; ow < ow_t; ow++) {
                    for (int oc = 0; oc < oc_t; oc++) {
                        int16_t sum = 0;
                        int kk = 0;
                        for (int kh = 0; kh < KH; kh++)
                            for (int kw = 0; kw < KW; kw++)
                                for (int c = 0; c < C; c++, kk++)
                                    sum += (int16_t)x[((oh * S + kh) * iw_t + ow * S + kw) * C + c] *
                                           (int16_t)w[oc * TAPS + kk];
                        y[(oh * ow_t + ow) * oc_t + oc] = (int8_t)(sum > 127 ? 127 : (sum < -128 ? -128 : sum));
                    }
                }
            }
            aie::release(win_a);
            aie::commit(win_c);
        }
    }
    aie::release(win_b);
}
// ═══════════════════════════════════════════════════════════════════════════
// HOST
// ═══════════════════════════════════════════════════════════════════════════
int main() {
    printf("=== Conv2d via Im2col on AIE %dx%d Mesh ===\n", HW_ROWS, HW_COLS);
    printf("    Input:  [%d, %d, %d]\n", INPUT_H, INPUT_W, INPUT_C);
    printf("    Filter: [%d, %d, %d, %d]\n", KERNEL_H, KERNEL_W, INPUT_C, NUM_FILTERS);
    printf("    Output: [%d, %d, %d]\n", OUTPUT_H, OUTPUT_W, NUM_FILTERS);
    printf("    Im2col GEMM: [%d, %d] x [%d, %d] = [%d, %d]\n", M, K, K, N, M, N);

    // --- Device + mesh ---
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({3, 6, 0, 6}, HW_ROWS, HW_COLS);

    // --- Allocate host memory (DDR pre-pad: spatial border + channel layout) ---
    int8_t *input = (int8_t *)__Runtime_Alloc(INPUT_H_PAD * INPUT_W_PAD * INPUT_C_ALIGN * sizeof(int8_t));
    int8_t *filter = (int8_t *)__Runtime_Alloc(KERNEL_H * KERNEL_W * INPUT_C_ALIGN * NUM_FILTERS * sizeof(int8_t));
    int8_t *output = (int8_t *)__Runtime_Alloc(OUTPUT_H * OUTPUT_W * NUM_FILTERS * sizeof(int8_t));

    // --- Initialize test data ---
    memset(input, 0, INPUT_H_PAD * INPUT_W_PAD * INPUT_C_ALIGN * sizeof(int8_t));
    for (int h = 0; h < INPUT_H; h++) {
        for (int w = 0; w < INPUT_W; w++) {
            for (int c = 0; c < INPUT_C; c++) {
                int real_idx = (h * INPUT_W + w) * INPUT_C + c;
                int val = (int)(mix32((uint32_t)real_idx + INPUT_SEED) % 9u) - 4; // [-4, 4]
                input[((h + PAD) * INPUT_W_PAD + (w + PAD)) * INPUT_C_ALIGN + c] = (int8_t)val;
            }
            // padding channels [INPUT_C, INPUT_C_ALIGN) and spatial border left at 0
        }
    }

    // Filter: zero-mean samples in {-1, 0, 1} for the real channels, 0 for the
    memset(filter, 0, KERNEL_H * KERNEL_W * INPUT_C_ALIGN * NUM_FILTERS * sizeof(int8_t));
    for (int f = 0; f < NUM_FILTERS; f++) {
        for (int kh = 0; kh < KERNEL_H; kh++) {
            for (int kw = 0; kw < KERNEL_W; kw++) {
                for (int c = 0; c < INPUT_C; c++) {
                    int kk = (kh * KERNEL_W + kw) * INPUT_C_ALIGN + c;
                    int filt_key = ((f * KERNEL_H + kh) * KERNEL_W + kw) * INPUT_C + c;
                    int val = (int)(mix32((uint32_t)filt_key + FILTER_SEED) % 3u) - 1; // {-1,0,1}
                    filter[f * K + kk] = (int8_t)val;
                }
                // padding channel c == INPUT_C..INPUT_C_ALIGN-1 left at 0
            }
        }
    }

    memset(output, 0, OUTPUT_H * OUTPUT_W * NUM_FILTERS * sizeof(int8_t));
    printf("\n--- Launching conv2d_spatial (spatial-halo) on AIE ---\n");
    XTime t_aie_start, t_aie_end;
    XTime_GetTime(&t_aie_start);
    conv2d_spatial<<<mesh>>>(input, filter, output, M, N, K);
    XTime_GetTime(&t_aie_end);
    double aie_wall_ms = 1.0 * (t_aie_end - t_aie_start) / COUNTS_PER_SECOND * 1000.0;
    printf("[BENCH] aie_wall_ms=%.3f\n", aie_wall_ms);

    printf("\n--- Verification ---\n");
    int result = verify_conv2d(input, filter, output);
    uint32_t timeout = 0;
    while (result > 0) {
        sleep(1);
        timeout++;
        printf("ERROR: conv2d output mismatch,app waiting for debug... ( %u second) \n", timeout);
    }
    // --- Cleanup ---
    free(input);
    free(filter);
    free(output);

    return result;
}
