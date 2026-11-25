/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// #pragma gemm_autotile: the compiler picks the mesh and the A ring of a 2 x 8 shared-operand GEMM
// (example/tileprogram/ccode/gemm_plan/gemm_plan_body.cc) from its shape and dtype, with a cost model
// calibrated on board measurements (doc/design/dmaphop_dataflow_plan.md "Tiling"). It runs on the source
// text before the kernel is traced -- the trace needs the mesh -- and writes its choice as #define lines,
// so the front end, the trace, the dataflow plan and both compiles follow it (like --define).

#ifndef AIEHLC_GEMM_AUTOTILE_H
#define AIEHLC_GEMM_AUTOTILE_H

#include <string>
#include <vector>

namespace gemmtile {

// One board's measured facts (script/perf/gemm_plan.py BOARDS; doc/performance/gemm_e2e_progress.md).
struct Board {
    const char *name;
    double aieMhz;
    double ddrRdGBs, ddrWrGBs; // sustained DDR read / write rate
    bool ddrOverlap;           // reads and writes overlap (several interleaved controllers)
    double shimChGBs;          // one shim MM2S channel's DDR read rate (lower bound where not binding)
};

struct Shape {
    long M = 0, N = 0, K = 0; // C[M x N] = A[M x K] . B[N x K]^T, elements
    int elemBytes = 1;        // 1 int8, 2 bf16
};

// A candidate tiling and its predicted time per launch (steady state).
struct Choice {
    int rows = 0, cols = 0, ring = 0;
    bool bKeep = false; // B held in the MemTiles across launches (else re-read per output tile)
    long tilesPerCore = 0, kChunks = 0;
    double coreMs = 0, shimMs = 0, ddrMs = 0, launchMs = 0, totalMs = 0, peakMs = 0;
    std::string bound; // what sets totalMs
};

const Board *findBoard(const std::string &name); // nullptr: unknown

// Every feasible tiling, fastest first; `why` lists the reasons when none is.
std::vector<Choice> rankTilings(const Shape &s, const Board &b, std::string &why);

// The source-text pass: when `src` holds `#pragma gemm_autotile[(board)]`, reads GP_M / GP_N / GP_K /
// GP_DTYPE from the text, ranks the tilings and prepends #define GP_HW_ROWS / GP_HW_COLS / GP_RING for
// the ones the source does not set itself. Returns false (with `err`) when no tiling is feasible.
// `log` gets the ranking.
bool applyGemmAutoTile(std::string &src, std::string &log, std::string &err);

} // namespace gemmtile

#endif
