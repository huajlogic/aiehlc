/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plan -> aiehlc_plan.h, the constants of the kernel side (the DMA program is dfschedule ops:
// plandma.cpp; the routes are routinghw ops: passdmaphoptoroutinghw/planroutes.cpp).

#include "dataflowplan.h"
#include "plantarget.h"

#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <map>
#include <sstream>
#include <vector>

namespace dfplan {

// aiehlc_plan.h: the constants the kernel side of the plan reads -- the block calls on the shared ports
// (src/mlir/runtime/aie_block_io_plan.h, bound to them when AIEHLC_PLAN_SHARED is defined) and the
// persistent kernel loop. Per-operand / per-row values are select chains, not tables: pm and the operand
// are register values / compile-time constants on the core, and a table would be a data-memory load at
// every use. Emitted in name order, so a plan gives the same header whichever way it came in.
// Host side: aiehlc_plan_arrange(arg, src, dst) lays a stream's tensor (row-major, as the kernel declares
// it) out in DDR in the order the plan's shim transfers read it -- per column, the MemTile's part of the
// stream (a ring: every tile's chunks of the parities it serves; resident: its strips whole), the columns
// one after the other. Derived from the same streams and routes as the shim BDs (plandma.cpp).
static std::string emitPlanArrange(const DataflowPlan &plan) {
    std::ostringstream os;
    os << "#if !defined(__chess__) && !defined(__AIENGINE__)\n#include <string.h>\n"
       << "/* the DDR order the plan's shim transfers read stream `arg` in (src: the tensor, row-major) */\n"
       << "static inline void aiehlc_plan_arrange(int arg, const void *src_, void *dst_) {\n"
       << "    const unsigned char *src = (const unsigned char *)src_;\n"
       << "    unsigned char *dst = (unsigned char *)dst_;\n";
    for (const PlanStream &s : plan.streams) {
        int strips = 0;
        for (int x : s.strips)
            strips = std::max(strips, x + 1);
        const int64_t eb = s.elemBytes, rowB = (int64_t)s.chunkCols * eb,
                      stripRows = s.tensorRows / std::max(strips, 1);
        const size_t groups = s.hostRows.size();
        os << "    if (arg == " << s.arg << ") { /* " << s.role << ": " << s.tensorRows << " x " << s.tensorCols
           << " x " << eb << " B, chunk " << s.chunkRows << " x " << s.chunkCols << " */\n";
        for (int c = 0; c < plan.meshCols; c++) {
            const MemtileUse u = memtileUse(plan, s, plan.colLo + c);
            if (!u.present)
                continue;
            // a ring serving several strips (one chunk-tall strip per group): its chain takes, per round, the
            // served (strip, parity) streams in route order, chunk q + n x channels of each; a stream that does
            // not advance over rounds is laid out once (the shim BD re-reads it)
            std::vector<std::pair<int, int>> sq;
            for (const PlanRoute *r : u.out) {
                const auto &d = r->dsts[0];
                int g = 0;
                for (size_t x = 0; x < groups; x++)
                    if ((int)s.hostRows[x] == d.first.row - plan.coreRowBase)
                        g = (int)x;
                sq.push_back({s.strips[(d.first.col - plan.colLo) * groups + g], d.second});
            }
            bool multi = false;
            for (auto &x : sq)
                multi |= x.first != sq[0].first;
            if (s.stage == "memtile_ring" && multi) {
                const int k = (int)sq.size();
                const int64_t per = (int64_t)s.chunks * k / s.channels, rounds = s.rereadsEveryRound() ? 1 : s.rounds;
                os << "        { /* column " << c << ": " << k << " (strip, parity) ring streams */\n"
                   << "            static const long sq[" << k << "][2] = {";
                for (int j = 0; j < k; j++)
                    os << (j ? ", " : "") << "{" << sq[j].first << ", " << sq[j].second << "}";
                os << "};\n"
                   << "            for (long t = 0; t < " << rounds << "; t++)\n"
                   << "                for (long i = 0; i < " << per << "; i++)\n"
                   << "                    for (long r = 0; r < " << s.chunkRows << "; r++, dst += " << rowB << ")\n"
                   << "                        memcpy(dst, src + ((sq[i % " << k << "][0] * " << stripRows
                   << "L + t * " << s.chunkRows << " + r) * " << s.tensorCols << " + (sq[i % " << k
                   << "][1] + i / " << k << " * " << s.channels << ") * " << s.chunkCols << ") * " << eb << ", "
                   << rowB << ");\n"
                   << "        }\n";
            } else if (s.stage == "memtile_ring") {
                unsigned mask = 0;
                for (int q : u.parities)
                    mask |= 1u << q;
                const int g = [&] {
                    for (size_t x = 0; x < groups; x++)
                        if ((int)s.hostRows[x] == u.out[0]->dsts[0].first.row - plan.coreRowBase)
                            return (int)x;
                    return 0;
                }();
                const int strip = s.strips[c * groups + g];
                os << "        for (long t = 0; t < " << s.rounds << "; t++) /* column " << c << ": strip " << strip
                   << ", parities 0x" << std::hex << mask << std::dec << " */\n"
                   << "            for (long j = 0; j < " << s.chunks << "; j++)\n"
                   << "                if ((0x" << std::hex << mask << std::dec << "u >> (j % " << s.channels
                   << ")) & 1u)\n"
                   << "                    for (long r = 0; r < " << s.chunkRows << "; r++, dst += " << rowB << ")\n"
                   << "                        memcpy(dst, src + ((" << strip * stripRows << "L + t * " << s.chunkRows
                   << " + r) * " << s.tensorCols << " + j * " << s.chunkCols << ") * " << eb << ", " << rowB << ");\n";
            } else {
                for (size_t g = 0; g < groups; g++) {
                    const int strip = s.strips[c * groups + g];
                    os << "        for (long t = 0; t < " << stripRows / s.chunkRows << "; t++) /* column " << c
                       << ", group " << g << ": strip " << strip << " */\n"
                       << "            for (long j = 0; j < " << s.chunks << "; j++)\n"
                       << "                for (long r = 0; r < " << s.chunkRows << "; r++, dst += " << rowB << ")\n"
                       << "                    memcpy(dst, src + ((" << strip * stripRows << "L + t * " << s.chunkRows
                       << " + r) * " << s.tensorCols << " + j * " << s.chunkCols << ") * " << eb << ", " << rowB
                       << ");\n";
                }
            }
        }
        os << "        return;\n    }\n";
    }
    os << "}\n#endif\n";
    return os.str();
}

std::string emitPlanHeader(const DataflowPlan &plan) {
    const PlanTarget &T = planTarget();
    std::ostringstream os;
    os << "/* aiehlc_plan.h -- generated from the dataflow plan (" << T.name << "); do not edit. */\n"
       << "#ifndef AIEHLC_PLAN_H\n#define AIEHLC_PLAN_H\n"
       << "#define AIEHLC_PLAN 1\n"
       << "#define AIEHLC_PLAN_PERSISTENT " << (plan.persistentGoLock >= 0 ? 1 : 0) << "\n"
       << "#define AIEHLC_PLAN_GO_LOCK "
       << (plan.persistentGoLock >= 0 ? T.coreOwnLockBias + plan.persistentGoLock : -1)
       << " /* the core program's id of its own go lock */\n";
    std::vector<const PlanKernelParam *> params;
    for (const auto &p : plan.params)
        params.push_back(&p);
    std::stable_sort(params.begin(), params.end(),
                     [](const PlanKernelParam *a, const PlanKernelParam *b) { return a->name < b->name; });
    const int rows = std::max(plan.meshRows, 1);
    for (const PlanKernelParam *pp : params) {
        const PlanKernelParam &p = *pp;
        if (p.scalar) {
            os << "#define AIEHLC_PLAN_" << p.name << " " << p.perMeshRow[0] << "\n";
            continue;
        }
        const size_t n = p.perMeshRow.size();
        os << "#define AIEHLC_PLAN_" << p.name << (p.perOperand ? "(o, pm) (" : "(pm) (");
        for (size_t i = 0; i + 1 < n; i++) {
            if (p.perOperand)
                os << "((o) == " << i / rows << " && (pm) == " << i % rows << ") ? " << p.perMeshRow[i] << "L : ";
            else
                os << "(pm) == " << i << " ? " << p.perMeshRow[i] << "L : ";
        }
        os << (n ? p.perMeshRow.back() : 0) << "L)\n";
    }
    os << emitPlanArrange(plan);
    if (!plan.shareArgs.empty())
        os << "#define AIEHLC_PLAN_SHARED 1 /* aie_block_io.h binds the block calls (aie_block_io_plan.h) */\n"
           << "#ifndef AIEHLC_BLOCK_CHECK /* blocks proved by the kernel analysis on x86 */\n"
           << "#define AIEHLC_BLOCK_CHECK 0\n#endif\n";
    os << "#endif\n";
    return os.str();
}

} // namespace dfplan
