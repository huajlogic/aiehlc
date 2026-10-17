/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M11 -- placeholder core program: the probe is host + memory tiles + shims only.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
alignas(64) volatile int32_t m11_res[64];
// kernel_decl m11
int32_t main() {
    m11_res[0] = 1;
    return 0;
}
