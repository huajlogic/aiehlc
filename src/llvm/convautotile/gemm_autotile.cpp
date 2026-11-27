/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// #pragma gemm_autotile -- see gemm_autotile.h. The device facts come from the dataflow plan's target
// (plantarget.h), the board facts and the per-chunk core cost from measurements.

#include "gemm_autotile.h"

#include "../../mlir/mlirfront/tilinglinalg/pass/dataflowplan/plantarget.h"
#include "../../mlir/runtime/aie_runtime_resource.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <regex>
#include <sstream>

namespace gemmtile {

namespace {

// Measured boards (script/perf/gemm_plan.py BOARDS): VEK385_2 one controller, reads and writes do not
// overlap. VEK385 three interleaved controllers: one shim MM2S channel ~5.2 GB/s, and the aggregate DDR
// read rate when B is re-read per output tile fitted on the stage-4 runs (84 MB / 3.14 ms, 168 MB / 6.21
// ms, 147 MB / 6.77 ms -> 26.7 / 27.0 / 21.7 GB/s): 24 GB/s, within +-12 % of all three. Its write
// rate was never binding (C is small): not measured.
const Board kBoards[] = {
    {"vek385", 1250.0, 24.0, 100.0, true, 5.2},
    {"palmyra", 998.0, 16.1, 3.58, false, 3.6},
};

// The 2 x 8 kernel (gemm_plan_body.cc): one chunk = 64 rows x 128 B of A and of B. Core cycles per chunk
// in a live run, input waits included: int8 1188 (gemm_plan.py DESIGNS '2x8', 1.200 ms at 60 tiles x 20
// chunks); bf16 calibrated on the board in the stage-4 runs (doc/plan/dataflowplan_generalize.md).
constexpr int kTileRows = 64, kChunkBytes = 128;
constexpr double kCycChunkInt8 = 1188.0, kCycChunkBf16 = 2600.0;
constexpr double kLaunchMs = 0.02; // persistent kernel: pipeline fill / drain per launch
constexpr int kMaxRing = 10;

} // namespace

const Board *findBoard(const std::string &name) {
    for (const Board &b : kBoards)
        if (name == b.name)
            return &b;
    return nullptr;
}

std::vector<Choice> rankTilings(const Shape &s, const Board &b, std::string &why) {
    const dfplan::PlanTarget &T = dfplan::planTarget();
    std::vector<Choice> out;
    std::ostringstream no;
    const long kBytes = s.K * s.elemBytes, chunk = (long)kTileRows * kChunkBytes;
    if (kBytes % (2L * kChunkBytes)) {
        why = "K x element bytes (" + std::to_string(kBytes) + ") must be a multiple of 2 chunks of " +
              std::to_string(kChunkBytes) + " B";
        return out;
    }
    // B: one 64-row tile per core column x 2 parities -> the mesh width is fixed by N
    if (s.N % (2L * kTileRows)) {
        why = "N must be a multiple of 2 x 64 (one 64-row B tile per core, two per mesh column)";
        return out;
    }
    const int cols = (int)(s.N / (2L * kTileRows));
    if (cols + 1 > T.arrayCols - 2) { // + the control-plane column, from partition column 2
        why = "N = " + std::to_string(s.N) + " needs " + std::to_string(cols) + " mesh columns, the array has " +
              std::to_string(T.arrayCols - 3) + " for the data plane";
        return out;
    }
    const long nk = kBytes / kChunkBytes;
    // the output gathers every core's tiles as packets: one packet id per core, from the ids the control
    // plane does not reserve (aie_runtime_resource.c)
    const int pktFree = T.pktIds - __builtin_popcount(__Runtime_res_reserved_pktid_mask((rt_res_gen)T.resGen) & ~1u);
    const double cyc = s.elemBytes == 1 ? kCycChunkInt8 : kCycChunkBf16, macPerCyc = s.elemBytes == 1 ? 512 : 256;
    for (int rows = 2; rows <= T.coreRows; rows += 2) {
        const int strips = rows / 2;
        // A's strips are row pairs (2 readers each), B's groups the row parities (rows / 2 readers each): one
        // hosted-stream program on every core needs both counts equal (plansynth), so rows = 4
        if (rows / 2 != 2) {
            no << "rows " << rows << ": A strips have 2 readers, B groups " << rows / 2 << "; ";
            continue;
        }
        if (cols < strips || s.M % ((long)rows * kTileRows)) {
            no << "rows " << rows << ": M % " << rows * kTileRows << " != 0 or fewer columns than A strips; ";
            continue;
        }
        if (rows * cols > pktFree) {
            no << rows << " x " << cols << " mesh: " << rows * cols << " output cores, " << pktFree
               << " packet ids free; ";
            continue;
        }
        const long tiles = s.M / strips / kTileRows;
        if (tiles > T.bdMaxIterWrap) {
            no << "rows " << rows << ": " << tiles << " output tiles per core > " << T.bdMaxIterWrap << "; ";
            continue;
        }
        int ring = 0;
        for (int r = kMaxRing; r >= 2 && !ring; r--)
            if ((tiles * nk) % (2L * r) == 0 && (long)r * 2 * chunk <= T.memBytes)
                ring = r;
        if (!ring) {
            no << "rows " << rows << ": no A ring of 2.." << kMaxRing << " divides " << tiles * nk << " chunks; ";
            continue;
        }
        Choice c;
        c.rows = rows, c.cols = cols, c.ring = ring, c.tilesPerCore = tiles, c.kChunks = nk;
        // B held whole when its column's two strips fit a MemTile and one BD (the plan's own rule)
        const long bWhole = 2L * nk * chunk;
        c.bKeep = bWhole <= T.memBytes && bWhole / T.bdWordBytes <= T.memBdMaxLenWords;
        c.coreMs = (double)tiles * nk * cyc / (b.aieMhz * 1e3);
        const double aBytes = (double)s.M * kBytes, bBytes = c.bKeep ? 0.0 : (double)s.N * kBytes * tiles,
                     cBytes = (double)s.M * s.N * s.elemBytes;
        // A: each (strip, parity) stream on one column's shim channel; B: one channel per column
        const int aChannels = strips * std::min(T.coreS2mmChannels, cols / strips);
        c.shimMs = std::max(aBytes / aChannels, bBytes / cols) / (b.shimChGBs * 1e6);
        const double rd = aBytes + bBytes;
        c.ddrMs = b.ddrOverlap ? std::max(rd / b.ddrRdGBs, cBytes / b.ddrWrGBs) / 1e6
                               : (rd / b.ddrRdGBs + cBytes / b.ddrWrGBs) / 1e6;
        c.launchMs = kLaunchMs;
        const double m = std::max({c.coreMs, c.shimMs, c.ddrMs});
        c.bound = m == c.coreMs ? "cores" : m == c.shimMs ? "shim channels" : "DDR";
        c.totalMs = m + c.launchMs;
        c.peakMs = (double)s.M * s.N * s.K / ((double)rows * cols * macPerCyc * b.aieMhz * 1e6) * 1e3;
        out.push_back(c);
    }
    std::stable_sort(out.begin(), out.end(), [](const Choice &a, const Choice &x) { return a.totalMs < x.totalMs; });
    if (out.empty())
        why = no.str();
    return out;
}

namespace {

// The first `#define NAME <integer>` in the text: the injected / entry-file value precedes the body's
// `#ifndef NAME` default. `isDefault`: that first definition is such a default.
bool firstDefine(const std::string &src, const std::string &name, long &v, bool &isDefault) {
    std::regex re("(^|\\n)[ \\t]*#[ \\t]*define[ \\t]+" + name + "[ \\t]+\\(?(-?[0-9]+)L?\\)?[ \\t]*(\\n|/)");
    std::smatch m;
    if (!std::regex_search(src, m, re))
        return false;
    v = std::strtol(m[2].str().c_str(), nullptr, 10);
    const std::string before = src.substr(0, m.position(0) + m.length(1)); // up to the #define's line
    std::regex guard("#[ \\t]*ifndef[ \\t]+" + name + "[ \\t]*\\n$");
    isDefault = std::regex_search(before, guard);
    return true;
}

} // namespace

bool applyGemmAutoTile(std::string &src, std::string &log, std::string &err) {
    std::smatch pm;
    std::regex pragma("(^|\\n)([ \\t]*#[ \\t]*pragma[ \\t]+gemm_autotile(\\([ \\t]*([a-z0-9_]+)[ \\t]*\\))?)[^\\n]*");
    if (!std::regex_search(src, pm, pragma))
        return true;
    std::string boardName = pm[4].matched ? pm[4].str() : "";
    if (boardName.empty()) {
        const char *e = std::getenv("AIEHLC_GEMM_BOARD");
        boardName = e && *e ? e : "vek385";
    }
    const Board *b = findBoard(boardName);
    if (!b) {
        err = "#pragma gemm_autotile: unknown board '" + boardName + "' (vek385, palmyra)";
        return false;
    }
    Shape s;
    long v = 0, dtype = 1;
    bool dflt = false;
    if (!firstDefine(src, "GP_M", s.M, dflt) || !firstDefine(src, "GP_N", s.N, dflt) ||
        !firstDefine(src, "GP_K", s.K, dflt)) {
        err = "#pragma gemm_autotile: GP_M / GP_N / GP_K not found as integer #defines";
        return false;
    }
    if (firstDefine(src, "GP_DTYPE", v, dflt))
        dtype = v;
    s.elemBytes = dtype == 2 ? 2 : 1;
    std::string why;
    std::vector<Choice> ranked = rankTilings(s, *b, why);
    if (ranked.empty()) {
        err = "#pragma gemm_autotile: no feasible tiling for C[" + std::to_string(s.M) + " x " + std::to_string(s.N) +
              "] K " + std::to_string(s.K) + ": " + why;
        return false;
    }
    std::ostringstream os;
    char line[256];
    os << "[GemmAutoTile] " << b->name << ", " << (s.elemBytes == 1 ? "int8" : "bf16") << " C[" << s.M << " x " << s.N
       << "] K " << s.K << ": " << ranked.size() << " tiling(s)\n";
    for (const Choice &c : ranked) {
        std::snprintf(line, sizeof line,
                      "[GemmAutoTile]   %d x %d mesh, ring %d, B %s, %ld tiles x %ld chunks: core %.3f shim %.3f "
                      "DDR %.3f ms -> %.3f ms (%s), %.1f %% of peak\n",
                      c.rows, c.cols, c.ring, c.bKeep ? "kept" : "re-read", c.tilesPerCore, c.kChunks, c.coreMs,
                      c.shimMs, c.ddrMs, c.totalMs, c.bound.c_str(), 100.0 * c.peakMs / c.totalMs);
        os << line;
    }
    // the chosen tiling as #defines, except where the source sets the knob itself
    const Choice &c = ranked.front();
    std::string defs;
    const std::pair<const char *, int> knobs[] = {{"GP_HW_ROWS", c.rows}, {"GP_HW_COLS", c.cols}, {"GP_RING", c.ring}};
    for (auto &[name, val] : knobs) {
        if (firstDefine(src, name, v, dflt) && !dflt) {
            os << "[GemmAutoTile] " << name << " = " << v << " set by the source (model: " << val << ")\n";
            continue;
        }
        defs += std::string("#define ") + name + " " + std::to_string(val) + "\n";
        os << "[GemmAutoTile] " << name << " = " << val << "\n";
    }
    // the pragma line becomes a comment (same line count); the defines go first, as --define's
    const size_t at = pm.position(2);
    src.replace(at, pm.length(2), "// gemm_autotile applied");
    if (!defs.empty()) { // after any --define lines (aiehlc injectUserDefines: "#define ..." x n, "#line 1")
        size_t p = 0;
        while (src.compare(p, 8, "#define ") == 0 && src.find('\n', p) != std::string::npos)
            p = src.find('\n', p) + 1;
        if (src.compare(p, 8, "#line 1\n") == 0)
            src.insert(p, defs);
        else
            src = defs + "#line 1\n" + src;
    }
    log = os.str();
    return true;
}

} // namespace gemmtile
