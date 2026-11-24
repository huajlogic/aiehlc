/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// tutorial/perfoptmize step 1: the same GEMM with a vector kernel -- aie::mmul<8, 8, 8> (one 512-MAC
// instruction per cycle) in a 2 x 2 register block, operands host-packed in mmul order.
#define GEN_VECTOR 1
#define GEN_LAUNCH 0
#include "gemm_generic_body.cc"
