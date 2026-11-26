/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// #pragma dataflow_slices pre-queue planner (gemm90 m3362124222211 PI). MLIR-free so the kernel_trace_cases
// stub (dataflow_slices_prequeue_altbd) runs the same rules as SlicePrequeuePass.
//
// The sliced host function serves one slice per call. Without pre-queue every call issues its shim MM2S inputs,
// then waits for them: the shim is idle between call i's last input word and call i+1's first startio. With it:
//   issue(i): B (sliced inputs) -> C (shim S2MM outputs) -> A (unsliced inputs), each skipped by the runtime when
//             the previous call already pre-queued it (__Runtime_startio_slice);
//   issue_ab(i+1): every shim MM2S input is pushed once more on its channel for slice i+1 (__Runtime_startio_prequeue);
//             the runtime alternates the hardware BD between the io's own BD and its alt BD (picked here: the lowest
//             shim BD the host function does not use on that column) so the BD of the in-flight transfer is never
//             rewritten;
//   wait(i):  the inputs' waits become __Runtime_wait_io_pq (pending <= 1 while a pre-queued task is behind).
// Limits: start queue depth (aie-rt XAIE_DMA_MAX_QUEUE_SIZE = 4, xaie_dma.c:45): pre-queue keeps <= 2 tasks per
// channel; the start-queue repeat count is 8 bits (repeat <= 256); a BD chain (next_bd != -1, e.g. a BD split for
// the 0x1FFFF-word length limit) is not pre-queued (the alt BD would need the whole chain).
#ifndef __SLICEPREQUEUE_PLAN_H__
#define __SLICEPREQUEUE_PLAN_H__

#include <algorithm>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace sliceprequeue {

enum Dir { MM2S = 0, S2MM = 1 };

struct Io {
    int col = 0, row = 0, ch = 0, bd = 0;
    Dir dir = MM2S;
    bool sliced = false;  // its shim BD is rebased per call (dfplan.slice)
    bool chained = false; // next_bd != -1
    int repeat = 1;
};

struct Plan {
    std::vector<int> order;  // startio indices (into ios) in issue order: class 0 (sliced in), 1 (out), 2 (in)
    std::vector<int> altBd;  // per io: the alt shim BD of its pre-queue, -1 = not pre-queued
    int prequeued = 0;
    std::string note;        // why an input is not pre-queued (empty = all)
};

constexpr int kShimBds = 16;
constexpr int kQueueDepth = 4; // aie-rt XAIE_DMA_MAX_QUEUE_SIZE
constexpr int kMaxRepeat = 256;

inline int ioClass(const Io &io) {
    if (io.row != 0)
        return 3; // not a shim io: left where it is
    if (io.dir == S2MM)
        return 1;
    return io.sliced ? 0 : 2;
}

// used[col] = the shim BDs the host function configures / rebases / starts on that column
inline Plan plan(const std::vector<Io> &ios, std::map<int, std::set<int>> used) {
    Plan p;
    p.altBd.assign(ios.size(), -1);
    for (int c = 0; c < 3; c++)
        for (size_t i = 0; i < ios.size(); i++)
            if (ioClass(ios[i]) == c)
                p.order.push_back((int)i);
    std::map<std::pair<int, int>, int> perCh; // (col, ch) MM2S -> tasks in flight + queued
    for (int i : p.order) {
        const Io &io = ios[i];
        if (io.dir != MM2S)
            continue;
        if (io.chained || io.repeat < 1 || io.repeat > kMaxRepeat) {
            p.note += (p.note.empty() ? "" : "; ") + std::string(io.chained ? "BD chain" : "repeat > 256") +
                      " on shim col " + std::to_string(io.col) + " bd " + std::to_string(io.bd);
            continue;
        }
        if (++perCh[{io.col, io.ch}] * 2 > kQueueDepth) {
            p.note += (p.note.empty() ? "" : "; ") + std::string("start queue depth on shim col ") +
                      std::to_string(io.col) + " ch " + std::to_string(io.ch);
            continue;
        }
        std::set<int> &u = used[io.col];
        int alt = -1;
        for (int b = 0; b < kShimBds; b++)
            if (!u.count(b)) {
                alt = b;
                break;
            }
        if (alt < 0) {
            p.note += (p.note.empty() ? "" : "; ") + std::string("no free shim BD on col ") + std::to_string(io.col);
            continue;
        }
        u.insert(alt);
        p.altBd[i] = alt;
        p.prequeued++;
    }
    return p;
}

// the runtime's hardware BD for a pre-queue (aie_runtime.c __Runtime_startio_prequeue): never the in-flight BD
inline int pickTarget(int inFlightBd, int ownBd, int altBd) { return inFlightBd == altBd ? ownBd : altBd; }

} // namespace sliceprequeue

#endif
