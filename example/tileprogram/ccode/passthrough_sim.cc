/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

#include <stdint.h>
#include <stdio.h>

#define TILE_ROWS 16
#define TILE_COLS 16
#define ELEMENTS (TILE_ROWS * TILE_COLS)
#define HW_ROWS 1
#define HW_COLS 1

constexpr aie::GemmSpace InputSpace = {
    .policy = {.map = {.act = aie::Pattern::Broadcast, .layout = aie::Layout::Row},
               .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None},
               .sched = {.pp_depth = 1, .l1_budget = aie::Bytes{4096}}},
    .d1 = {.fullsize = TILE_ROWS, .tile_size = TILE_ROWS, .stride = TILE_ROWS},
    .d2 = {.fullsize = TILE_COLS, .tile_size = TILE_COLS, .stride = TILE_COLS}};

constexpr aie::GemmSpace OutputSpace = {
    .policy = {.map = {.layout = aie::Layout::Row, .merge_order = aie::Flow::LeftToRight},
               .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None},
               .sched = {.pp_depth = 1, .l1_budget = aie::Bytes{4096}}},
    .d1 = {.fullsize = TILE_ROWS, .tile_size = TILE_ROWS, .stride = TILE_ROWS},
    .d2 = {.fullsize = TILE_COLS, .tile_size = TILE_COLS, .stride = TILE_COLS}};

__global__ void passthrough(aie::port<input_window_int8 *, InputSpace> input,
                            aie::port<output_window_int8 *, OutputSpace> output) {
    int8_t *in = (int8_t *)acquire_input_window(input);
    int8_t *out = (int8_t *)acquire_output_window(output);
    for (int i = 0; i < ELEMENTS; ++i)
        out[i] = in[i];
    release_input_window(input);
    release_output_window(output);
}

int main(int, char **) {
    printf("[passthrough] 1x1 tilinglinalg copy, %d int8\n", ELEMENTS);

    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({0, 3, 0, 6}, HW_ROWS, HW_COLS);

    int8_t *input = (int8_t *)device.alloc(ELEMENTS * sizeof(int8_t) * 4);
    int8_t *output = (int8_t *)device.alloc(ELEMENTS * sizeof(int8_t) * 4);
    if (!input || !output) {
        printf("[passthrough] allocation failed\n");
        if (input)
            device.free(input);
        if (output)
            device.free(output);
        return 1;
    }

    for (int i = 0; i < ELEMENTS; ++i) {
        input[i] = (int8_t)((i % 31) - 16);
        output[i] = 0;
    }

    passthrough<<<mesh>>>(input, output);
    device.synchronizecpu(output, ELEMENTS * sizeof(int8_t));

    int errors = 0;
    for (int i = 0; i < ELEMENTS; ++i) {
        if (output[i] != input[i]) {
            if (errors < 8)
                printf("[passthrough] mismatch %d: got %d expected %d\n", i, (int)output[i], (int)input[i]);
            ++errors;
        }
    }

    device.free(input);
    device.free(output);

    if (errors) {
        printf("[passthrough] FAIL: %d/%d elements wrong\n", errors, ELEMENTS);
        printf("\nKernel test failed!\n");
        return 1;
    }

    printf("[passthrough] PASS: %d/%d elements copied\n", ELEMENTS, ELEMENTS);
    printf("\nKernel test passed!\n");
    return 0;
}
