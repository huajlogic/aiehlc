/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plan -> the C text that is not a DMA program: routing.cc routes and aiehlc_plan.h
// (the DMA program is dfschedule ops: plandma.cpp).

#include "dataflowplan.h"
#include "plantarget.h"

#include "llvm/Support/JSON.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <deque>
#include <map>
#include <sstream>

namespace dfplan {

namespace {

// ---------------------------------------------------------------- port model (plantarget.h)
enum class Kind { Shim, Mem, Core };

int portCount(Kind k, char ms, const std::string &dir) {
    return planTarget().portCount(k == Kind::Core ? "core" : k == Kind::Mem ? "mem" : "shim", ms, dir);
}

const char *kDirs[] = {"NORTH", "EAST", "WEST", "SOUTH"};
int stepC(const std::string &d) { return d == "EAST" ? 1 : d == "WEST" ? -1 : 0; }
int stepR(const std::string &d) { return d == "NORTH" ? 1 : d == "SOUTH" ? -1 : 0; }
std::string opp(const std::string &d) {
    return d == "NORTH" ? "SOUTH" : d == "SOUTH" ? "NORTH" : d == "EAST" ? "WEST" : "EAST";
}

struct Fabric {
    PortBook &book;
    int colLo, colHi, rows, memRows;
    Kind kind(int r) const { return r == 0 ? Kind::Shim : r <= memRows ? Kind::Mem : Kind::Core; }
    bool inside(int c, int r) const { return c >= colLo && c <= colHi && r >= 0 && r < rows; }
    bool free(int c, int r, char ms, const std::string &d, int i) const {
        return i < portCount(kind(r), ms, d) && !book.used.count({c, r, ms, d, i});
    }
    void take(int c, int r, char ms, const std::string &d, int i) { book.used.insert({c, r, ms, d, i}); }
};

struct Slave {
    std::string dir;
    int idx;
    bool operator<(const Slave &o) const { return dir != o.dir ? dir < o.dir : idx < o.idx; }
};

// One multicast net: BFS from the tree grown so far to each destination, with
// the MemTile rule that a SOUTH / NORTH slave k passes only to SOUTH / NORTH
// master k (anything else is silently not connected -- skill memtilepassthroughlane).
bool routeNet(Fabric &f, Tile src, Slave srcSlave, const std::vector<std::pair<Tile, int>> &dsts,
              std::vector<std::string> &lines, std::string &why) {
    std::map<Tile, Slave> tree;
    tree[src] = srcSlave;
    f.take(src.col, src.row, 's', srcSlave.dir, srcSlave.idx);
    for (const auto &[dt, dch] : dsts) {
        if (!tree.count(dt)) {
            using State = std::tuple<int, int, std::string, int>; // col,row,incoming slave dir,idx
            std::map<State, std::tuple<State, std::string, int, bool>> prev;
            std::deque<State> q;
            for (auto &[t, s] : tree) {
                State st{t.col, t.row, s.dir, s.idx};
                prev[st] = {st, "", -1, true};
                q.push_back(st);
            }
            bool found = false;
            State goal;
            while (!q.empty() && !found) {
                State st = q.front();
                q.pop_front();
                auto [c, r, sd, si] = st;
                for (const char *dp : kDirs) {
                    std::string d = dp;
                    int nc = c + stepC(d), nr = r + stepR(d);
                    if (!f.inside(nc, nr) || tree.count({nc, nr}))
                        continue;
                    bool tied =
                        f.kind(r) == Kind::Mem && (sd == "SOUTH" || sd == "NORTH") && (d == "SOUTH" || d == "NORTH");
                    for (int k = 0; k < portCount(f.kind(r), 'm', d); k++) {
                        if ((tied && k != si) || !f.free(c, r, 'm', d, k) || !f.free(nc, nr, 's', opp(d), k))
                            continue;
                        State ns{nc, nr, opp(d), k};
                        if (prev.count(ns))
                            continue;
                        prev[ns] = {st, d, k, false};
                        if (nc == dt.col && nr == dt.row) {
                            goal = ns;
                            found = true;
                            break;
                        }
                        q.push_back(ns);
                    }
                    if (found)
                        break;
                }
            }
            if (!found) {
                why = "no free path to (" + std::to_string(dt.col) + "," + std::to_string(dt.row) + ")";
                return false;
            }
            std::vector<std::tuple<int, int, std::string, int>> path; // tile, master dir, idx
            for (State st = goal; !std::get<3>(prev[st]);) {
                auto [ps, d, k, root] = prev[st];
                path.push_back({std::get<0>(ps), std::get<1>(ps), d, k});
                st = ps;
            }
            for (auto it = path.rbegin(); it != path.rend(); ++it) {
                auto [c, r, d, k] = *it;
                Slave in = tree[{c, r}];
                int nc = c + stepC(d), nr = r + stepR(d);
                f.take(c, r, 'm', d, k);
                f.take(nc, nr, 's', opp(d), k);
                tree[{nc, nr}] = {opp(d), k};
                std::ostringstream os;
                os << "AIEHLC_PLAN_RT(XAie_StrmConnCctEnable(v1, XAie_TileLoc(" << c << "," << r << "), " << in.dir
                   << ", " << in.idx << ", " << d << ", " << k << "));";
                lines.push_back(os.str());
            }
        }
        if (!f.free(dt.col, dt.row, 'm', "DMA", dch)) {
            why = "DMA master " + std::to_string(dch) + " of (" + std::to_string(dt.col) + "," +
                  std::to_string(dt.row) + ") is taken";
            return false;
        }
        f.take(dt.col, dt.row, 'm', "DMA", dch);
        Slave in = tree[dt];
        std::ostringstream os;
        os << "AIEHLC_PLAN_RT(XAie_StrmConnCctEnable(v1, XAie_TileLoc(" << dt.col << "," << dt.row << "), " << in.dir
           << ", " << in.idx << ", DMA, " << dch << "));";
        lines.push_back(os.str());
    }
    return true;
}

} // namespace

bool loadPortBook(const std::string &path, PortBook &book) {
    auto buf = llvm::MemoryBuffer::getFile(path);
    if (!buf)
        return false;
    auto parsed = llvm::json::parse((*buf)->getBuffer());
    if (!parsed) {
        llvm::consumeError(parsed.takeError());
        return false;
    }
    auto *root = parsed->getAsObject();
    auto *conns = root ? root->getArray("connections") : nullptr;
    if (!conns)
        return false;
    for (auto &cv : *conns) {
        auto *c = cv.getAsObject();
        auto *tile = c ? c->getObject("tile") : nullptr;
        if (!tile)
            continue;
        int col = (int)tile->getInteger("col").value_or(-1), row = (int)tile->getInteger("row").value_or(-1);
        auto port = [&](const char *key, char ms) {
            if (auto *p = c->getObject(key)) {
                std::string d = p->getString("dir").value_or("NONE").str();
                if (d != "NONE")
                    book.used.insert({col, row, ms, d, (int)p->getInteger("idx").value_or(0)});
            }
        };
        std::string kind = c->getString("kind").value_or("").str();
        if (kind == "shim_ext_to_aie")
            port("port", 's');
        else if (kind == "shim_aie_to_ext")
            port("port", 'm');
        port("slave", 's');
        port("master", 'm');
        port("recv_slave", 's');
        port("local_dma", 's');
        port("forward_master", 'm');
    }
    return true;
}

bool emitPlanRouting(const DataflowPlan &plan, PortBook &book, int colLo, int colHi, int numRows, int memRows,
                     std::string &out) {
    Fabric f{book, colLo, colHi, numRows, memRows};
    // control-packet row fabric: forward EAST / return WEST on port 0 through every core row
    for (int r = memRows + 1; r < numRows; r++)
        for (int c = colLo; c <= colHi; c++)
            for (const char *d : {"EAST", "WEST"}) {
                f.take(c, r, 's', d, 0);
                f.take(c, r, 'm', d, 0);
            }
    std::vector<std::string> lines;
    for (const auto &rt : plan.routes) {
        Slave s;
        if (rt.srcShim) {
            // a shim MM2S channel enters the switch on a fixed SOUTH slave port (plantarget.h)
            if (rt.srcCh < 0 || rt.srcCh > 1) {
                llvm::errs() << "[DataflowPlan] ERROR: shim MM2S channel " << rt.srcCh << " does not exist\n";
                return false;
            }
            int port = planTarget().shimMm2sSouth[rt.srcCh];
            s = {"SOUTH", port};
            lines.push_back("AIEHLC_PLAN_RT(XAie_EnableShimDmaToAieStrmPort(v1, XAie_TileLoc(" +
                            std::to_string(rt.src.col) + ",0), " + std::to_string(port) + "));");
        } else {
            s = {"DMA", rt.srcCh};
        }
        std::string why;
        if (!f.free(rt.src.col, rt.src.row, 's', s.dir, s.idx)) {
            llvm::errs() << "[DataflowPlan] ERROR: route source (" << rt.src.col << "," << rt.src.row << ") " << s.dir
                         << " " << s.idx << " is already used by a generated route\n";
            return false;
        }
        if (!routeNet(f, rt.src, s, rt.dsts, lines, why)) {
            llvm::errs() << "[DataflowPlan] ERROR: route from (" << rt.src.col << "," << rt.src.row << ") ch "
                         << rt.srcCh << ": " << why << "\n";
            return false;
        }
    }
    std::ostringstream os;
    os << "/* ===== dataflow plan routes (dmaphop.plan_route), generated ===== */\n"
       << "#include <stdio.h>\n"
       << "#define AIEHLC_PLAN_RT(call) do { if ((call) != XAIE_OK) printf(\"[dataflow plan] route FAILED: %s\\n\", "
          "#call); } while (0)\n"
       << "static void aiehlc_plan_routing(XAie_DevInst *v1) {\n";
    for (auto &l : lines)
        os << "  " << l << "\n";
    os << "}\n\n";
    out = os.str();
    llvm::outs() << "[DataflowPlan] routed " << plan.routes.size() << " plan net(s): " << lines.size()
                 << " switch connections\n";
    return true;
}

// aiehlc_plan.h: the constants the kernel side of the plan reads -- the block calls on the shared ports
// (src/mlir/runtime/aie_block_io_plan.h, bound to them when AIEHLC_PLAN_SHARED is defined) and the
// persistent kernel loop. Per-operand / per-row values are select chains, not tables: pm and the operand
// are register values / compile-time constants on the core, and a table would be a data-memory load at
// every use. Emitted in name order, so a plan gives the same header whichever way it came in.
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
    if (!plan.shareArgs.empty())
        os << "#define AIEHLC_PLAN_SHARED 1 /* aie_block_io.h binds the block calls (aie_block_io_plan.h) */\n"
           << "#ifndef AIEHLC_BLOCK_CHECK /* blocks proved by the kernel analysis on x86 */\n"
           << "#define AIEHLC_BLOCK_CHECK 0\n#endif\n";
    os << "#endif\n";
    return os.str();
}

} // namespace dfplan
