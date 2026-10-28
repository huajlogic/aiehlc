#include "simpleconv2d_new.h"
#pragma aie_debug_level(2 | AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN | AIE_DMA_ISSUE_COUNT)
#define USE_SPATIAL_HALO // default
constexpr aie::Conv2d conv = {.h = 230, .w = 230, .c = 4, .k = 64, .kh = 7, .kw = 7, .stride = 2, .pad = 3};
constexpr aie::Mapping map = {
    .space = {aie::split(aie::OH, MESH_ROW),  // mesh rows
              aie::split(aie::OC, MESH_COL)}, // mesh cols
    .time = {aie::tile(aie::OH, 7),           // optional: omit -> autotune under l1_budget
             aie::tile(aie::OW, 28)},
    .hints = {
        .pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::Dma, .pp_depth = 2, .l1_budget = aie::Bytes{4096}}};

__global__(conv, map) void conv2d_spatial(
    aie::port<input_window_int8 *, aie::IFM> win_a,     // raw slab [halo_slice, W*C] (derived)
    aie::port<input_window_int8 *, aie::WEIGHTS> win_b, // filter [K, tile_N]
    aie::port<output_window_int8 *, aie::OFM> win_c     // output [oh_per_row*OW, tile_N]
) {
    int colid = get_coreid() & 0x1F;         // example for column id, adjust as needed
    int rowid = (get_coreid() >> 16) & 0x7F; // example for row id, adjust as needed
    char *weight = aie::load_buffer(win_b, 0, (conv.k, conv.c, conv.kh, conv.kw));
    int core_buffer_offset = rowid * 61 * 4 * 230 * 4;
    for (int i = 0; i < 4; i++) {
        core_buffer_offset += 19 * 230 * 4; // advance to the next row in the buffer
        for (int j = 0; j < 4; j++) {
            core_buffer_offset += 58 * 4; // advance to the next column in the buffer
            char *ifm_buffer = aie::load_buffer(win_a, core_buffer_offset, (19, 58, 4));
            char *local_out = aie::load_buffer(win_c, core_buffer_offset, (19, 58, 64));
            conv2d(ifm_buffer, weight, local_out); // example function call, replace with actual convolution function
        }
    }
}
/*
__global__(conv, map) void conv2d_spatial(
    aie::port<input_window_int8 *, aie::IFM> win_a,     // raw slab [halo_slice, W*C] (derived)
    aie::port<input_window_int8 *, aie::WEIGHTS> win_b, // filter [K, tile_N]
    aie::port<output_window_int8 *, aie::OFM> win_c     // output [oh_per_row*OW, tile_N]
) {
    const int kh_dim = SP_KH;
    const int kw_dim = SP_KW;
    const int c_dim = SP_C;
    const int stride = SP_S;
    // 2D WIDTH-SPLIT: the conv WIDTH is chunked into on-core rounds (NOT a mesh).
    const int ow_dim = OW_T;       // per-chunk output cols (28), was SP_OW=112
    const int oh_per_row = SP_OHR; // OUTPUT_H / HW_ROWS
    const int k_dim = SP_K;        // KH*KW*C
    int coreid = get_coreid();
    int row = coreid & 0x1F; // bits [0:4]  -> 5 bits
    int col = (coreid >> 16) & 0x7F;
    // const int out_c_num = aie::get_tile_cols(); // output channel number in this tile 16
    const int out_c_num = aie::get_arg_per_round_size_in_dim(2, win_c);

    const int num_a_rounds = aie::get_num_rounds(win_a);
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int num_c_rounds = aie::get_num_rounds(win_c);
    const int buf_sz_a = aie::get_buffer_size(win_a); // halo_slice * (W*C)
    const int buf_sz_c = aie::get_buffer_size(win_c);

    // Number of spatial M sub-tiles (slabs) this core processes. Each slab is a.
    const int m_rounds = aie::get_spatial_multiple_rounds(win_a);
    // Per-chunk input row width (TILE_W*C). With the 2D width-split each round's
    const int raw_wc = TILE_W * SP_C;

    const int buf_sz_b = aie::get_buffer_size(win_b);

    int8_t slab[buf_sz_a]; // raw input slab [halo_slice, raw_wc]
    int8_t local_out[oh_per_row * ow_dim * out_c_num];

    // ===== Receive B (filter) ONCE, before the slab loop =====
    int8_t B_local[num_b_rounds * buf_sz_b];
    for (int rb = 0; rb < num_b_rounds; rb++) {
        int8_t *B_ptr = (int8_t *)acquire_input_window(win_b);
        for (int i = 0; i < buf_sz_b; i++)
            B_local[rb * buf_sz_b + i] = B_ptr[i];
        release_input_window(win_b);
    }

    klog("M_ROU", m_rounds);
    klog("C_ROUN", num_c_rounds);
    // ===== M sub-tile loop: one slab -> one output tile per iteration =====
    for (int mr = 0; mr < m_rounds; mr++) {
        klog("MRIDX", mr);
        // ===== Phase 1: receive the raw input slab =====
        for (int ra = 0; ra < num_a_rounds; ra++) {
            int8_t *A_ptr = (int8_t *)acquire_input_window(win_a);
            for (int i = 0; i < buf_sz_a; i++)
                slab[ra * buf_sz_a + i] = A_ptr[i];
            release_input_window(win_a);
        }

        // ===== Phase 2: on-chip windowing (im2col) + matmul (reads B_local) =====
        for (int oh = 0; oh < oh_per_row; oh++) {
            for (int ow = 0; ow < ow_dim; ow++) {
                for (int j = 0; j < out_c_num; j++) {
                    int16_t sum = 0;
                    // local im2col: gather KH*KW*C patch from the slab
                    int kk = 0;
                    for (int kh = 0; kh < kh_dim; kh++) {
                        for (int kw = 0; kw < kw_dim; kw++) {
                            for (int c = 0; c < c_dim; c++) {
                                int ih = oh * stride + kh;
                                int iw = ow * stride + kw;
                                int8_t iv = slab[ih * raw_wc + iw * c_dim + c];
                                int8_t fv = B_local[j * k_dim + kk];
                                sum += (int16_t)iv * (int16_t)fv;
                                kk++;
                            }
                        }
                    }
                    if (sum > 127)
                        sum = 127;
                    else if (sum < -128)
                        sum = -128;
                    // HWC slab [oh,ow,c]: channel j innermost/contiguous, so the
                    // MM2S stream is (h,w,c) matching the declared output dim
                    // order. buf_sz_c (=oh_per_row*ow_dim*out_c_num) is unchanged;
                    // only the linear write order differs from the legacy CHW form.
                    local_out[(oh * ow_dim + ow) * out_c_num + j] = (int8_t)sum;
                }
            }
        }

        // ===== Phase 3: output =====
        for (int rc = 0; rc < num_c_rounds; rc++) {
            int8_t *out = (int8_t *)acquire_output_window(win_c);
            for (int i = 0; i < buf_sz_c; i++)
                // out[i] = col*10+ row; //local_out[rc * buf_sz_c + i];
                out[i] = local_out[rc * buf_sz_c + i];
            release_output_window(win_c);
        }
    } // end m_rounds
}
    */
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
