/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plan -> the C text that is not a DMA program: routing.cc routes and aiehlc_plan.h
// (the DMA program is dfschedule ops: plandma.cpp).

#include "dataflowplan.h"

#include "llvm/Support/JSON.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <deque>
#include <map>
#include <sstream>

namespace dfplan {

namespace {

// ---------------------------------------------------------------- port model
// AIE2PS stream-switch port counts (xaie2psgbl_reginit.c): masters / slaves per direction.
enum class Kind { Shim, Mem, Core };

int portCount(Kind k, char ms, const std::string &dir) {
    static const std::map<std::string, int> coreM = {{"NORTH", 6}, {"SOUTH", 4}, {"EAST", 4}, {"WEST", 4}, {"DMA", 2}};
    static const std::map<std::string, int> coreS = {{"SOUTH", 6}, {"NORTH", 4}, {"EAST", 4}, {"WEST", 4}, {"DMA", 2}};
    static const std::map<std::string, int> memM = {{"NORTH", 6}, {"SOUTH", 4}, {"DMA", 6}};
    static const std::map<std::string, int> memS = {{"SOUTH", 6}, {"NORTH", 4}, {"DMA", 6}};
    static const std::map<std::string, int> shimM = {{"NORTH", 6}, {"SOUTH", 6}, {"EAST", 4}, {"WEST", 4}};
    static const std::map<std::string, int> shimS = {{"SOUTH", 8}, {"NORTH", 4}, {"EAST", 4}, {"WEST", 4}};
    const auto &m = k == Kind::Core  ? (ms == 'm' ? coreM : coreS)
                    : k == Kind::Mem ? (ms == 'm' ? memM : memS)
                                     : (ms == 'm' ? shimM : shimS);
    auto it = m.find(dir);
    return it == m.end() ? 0 : it->second;
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
            // Gen5 shim MM2S ch0 / ch1 enter the switch on SOUTH 3 / 7
            int port = rt.srcCh == 0 ? 3 : 7;
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

// Kernel side of the shared ports: aie::load_buffer / aie::release on a share_args port become
// these (the pipeline's body rewrite). One block = one chunk of the hosted stream: the first reader
// acquires F and hands the chunk on through G, the second acquires G (and "releases" a lock held at
// 0, branch-free); slot q = 2 (chunk & 1) + ((chunk >> 1) & 1) (channel = chunk parity, 2 slots each);
// the two parts sit in different memory banks (SLOT_LO / SLOT_HI). Release frees the slot's E lock.
static std::string shareRuntime(const DataflowPlan &plan) {
    std::ostringstream os;
    os << "#ifndef AIEHLC_BLOCK_CHECK // blocks proved by the kernel analysis (aie_block_io.h)\n"
       << "#define AIEHLC_BLOCK_CHECK 0\n#endif\n"
       << "#include \"aie_block_io.h\"\n"
       << "struct aiehlc_share_port {\n  uintptr_t view;\n  int lock, first;\n  unsigned g, r;\n};\n"
       << "static aiehlc_share_port aiehlc_plan_share["
       << *std::max_element(plan.shareArgs.begin(), plan.shareArgs.end()) + 1 << "];\n"
       << "struct aiehlc_share_block {\n  int8_t *p0, *p1;\n"
       << "  template <typename T> operator T *() const { return (T *)p0; }\n"
       << "  int8_t *part(int i) const { return i ? p1 : p0; }\n};\n"
       << "// the block's offset / shape are the kernel's (checked by the kernel analysis); the slot is the plan's\n"
       << "static inline aiehlc_share_block aiehlc_share_load(aiehlc_share_port &s, const aiehlc_blk_desc &,\n"
       << "                                                   aiehlc_blk_cursor &, int, int, aiehlc_blk, aiehlc_blk,\n"
       << "                                                   int = 1) {\n"
       << "  const unsigned g = s.g++;\n"
       << "  const int ch_ = AIEHLC_PLAN_LOCK_CH_STRIDE * (int)(g & 1u);\n"
       << "  acquire_greater_equal(s.lock + (s.first ? AIEHLC_PLAN_LOCK_F : AIEHLC_PLAN_LOCK_G) + ch_, 1);\n"
       << "  release(s.first ? s.lock + AIEHLC_PLAN_LOCK_G + ch_ : AIEHLC_PLAN_LOCK_NOP, s.first ? 1 : 0);\n"
       << "  // no fence here: the rewrite puts ONE chess_memory_fence() after a run of shared loads\n"
       << "  const unsigned q_ = 2u * (g & 1u) + ((g >> 1) & 1u);\n"
       << "  return {(int8_t *)(s.view + AIEHLC_PLAN_SLOT_LO + q_ * AIEHLC_PLAN_SLOT_STRIDE),\n"
       << "          (int8_t *)(s.view + AIEHLC_PLAN_SLOT_HI + q_ * AIEHLC_PLAN_SLOT_STRIDE)};\n}\n"
       << "// no fence here: the rewrite puts ONE chess_memory_fence() before a run of shared releases\n"
       << "static inline void aiehlc_share_release(aiehlc_share_port &s) {\n"
       << "  const unsigned g = s.r++;\n"
       << "  release(s.lock + AIEHLC_PLAN_LOCK_E + AIEHLC_PLAN_LOCK_CH_STRIDE * (int)(g & 1u) + (int)((g >> 1) & 1u), "
          "1);\n"
       << "}\n"
       << "static inline void aiehlc_plan_share_init(int pm) {\n";
    for (int a : plan.shareArgs)
        os << "  aiehlc_plan_share[" << a << "] = {(uintptr_t)AIEHLC_PLAN_S" << a << "_VIEW(pm), (int)AIEHLC_PLAN_S"
           << a << "_LOCK(pm), (int)AIEHLC_PLAN_S" << a << "_FIRST(pm), 0u, 0u};\n";
    os << "}\n";
    return os.str();
}

std::string emitPlanHeader(const DataflowPlan &plan) {
    std::ostringstream os;
    os << "/* aiehlc_plan.h -- generated from the dmaphop dataflow plan; do not edit. */\n"
       << "#ifndef AIEHLC_PLAN_H\n#define AIEHLC_PLAN_H\n"
       << "#define AIEHLC_PLAN 1\n"
       << "#define AIEHLC_PLAN_PERSISTENT " << (plan.persistentGoLock >= 0 ? 1 : 0) << "\n"
       << "#define AIEHLC_PLAN_GO_LOCK " << (plan.persistentGoLock >= 0 ? 48 + plan.persistentGoLock : -1)
       << " /* kernel lock id (own locks are 48 + hw id) */\n";
    for (const auto &p : plan.params) {
        if (p.scalar) {
            os << "#define AIEHLC_PLAN_" << p.name << " " << p.perMeshRow[0] << "\n";
            continue;
        }
        os << "static const long aiehlc_plan_" << p.name << "[" << std::max<size_t>(p.perMeshRow.size(), 1) << "] = {";
        for (size_t i = 0; i < p.perMeshRow.size(); i++)
            os << (i ? ", " : "") << p.perMeshRow[i];
        os << "};\n#define AIEHLC_PLAN_" << p.name << "(pm) (aiehlc_plan_" << p.name << "[(pm)])\n";
    }
    if (!plan.shareArgs.empty())
        os << shareRuntime(plan);
    os << "#endif\n";
    return os.str();
}

} // namespace dfplan
