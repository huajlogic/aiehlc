/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#pragma once

#define chess_duplicate(x) x
#define chess_copy(x) (x)
#define chess_storage(...)
#define chess_flatten_loop
#define chess_memory_fence()

#if !defined(__AIEARCH__) || __AIEARCH__ != 22
#include "aiev2intrin.h"
#else
#include <aie2psintrin.h>
#endif

#include <adf/window/window.h>
// #include <aie_api/adf/window.hpp>

# if 0
//#define __regcall
//#define __constexpr constexpr

// #define restrict
// #define restrict __restrict

float as_float(...);
double as_double(...);
int as_int32(...);
long long int as_int64(...);

float sinf_stub(float a);
float cosf_stub(float a);
float sqrtf_stub(float a);

// typedef __accfloat accfloat;
// typedef long addr_t;
// struct acc80 {};
// struct cacc80 {};
// struct caccfloat {};
#endif

