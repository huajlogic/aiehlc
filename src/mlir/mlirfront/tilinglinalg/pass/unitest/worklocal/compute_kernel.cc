/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

// Compute kernel implementation
// This is the actual kernel logic

void compute_kernel(output_window_int8 window_out) {
    int8_t *out = acquire_output_window(window_out);

    // Kernel logic here
    for (int i = 0; i < 256; i++) {
        v4int8 data;
        // Initialize vector using member-wise assignment
        ((int8_t *)&data)[0] = i;
        ((int8_t *)&data)[1] = i + 1;
        ((int8_t *)&data)[2] = i + 2;
        ((int8_t *)&data)[3] = i + 3;
        *((v4int8 *)&out[i * 4]) = data;
    }

    release_output_window(window_out);
}
