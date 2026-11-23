/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plan -> C text for routing.cc, host.cc, kernel.cc and aiehlc_plan.h.

#include "dataflowplan.h"

#include "llvm/Support/JSON.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"

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

std::string tileCond(const std::vector<Tile> &tiles, const std::set<Tile> &allCores) {
    std::set<Tile> s(tiles.begin(), tiles.end());
    if (s == allCores)
        return "";
    std::string c;
    for (const auto &t : s)
        c += (c.empty() ? "" : " || ") + std::string("(_pcol == ") + std::to_string(t.col) +
             " && _prow == " + std::to_string(t.row) + ")";
    return c;
}

std::string dimsInit(const Dims &d, int64_t itStep, int64_t itWrap) {
    // AieKcDims {d0_step, d0_wrap, d1_step, d1_wrap, d2_step, iter_step, iter_wrap} (words)
    auto g = [&](size_t i, bool wrap) -> int64_t { return i < d.size() ? (wrap ? d[i].second : d[i].first) : 0; };
    std::ostringstream os;
    os << "{" << g(0, false) << ", " << g(0, true) << ", " << g(1, false) << ", " << g(1, true) << ", " << g(2, false)
       << ", " << itStep << ", " << itWrap << "}";
    return os.str();
}

bool isMem(const Tile &t, int memRows) { return t.row >= 1 && t.row <= memRows; }

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

static void emitMemtileBds(const DataflowPlan &plan, int memRows, std::ostringstream &os) {
    for (const auto &b : plan.bds)
        for (const auto &t : b.tiles) {
            if (!isMem(t, memRows))
                continue;
            os << "    { const unsigned d_[] = {";
            for (size_t i = 0; i < b.dims.size(); i++)
                os << (i ? ", " : "") << b.dims[i].first << ", " << b.dims[i].second;
            if (b.dims.empty())
                os << "0";
            os << "}; aiehlc_plan_mt_bd(v1, XAie_TileLoc(" << t.col << ", " << t.row << "), " << b.bd << ", 0x"
               << std::hex << b.addr << std::dec << "u, " << b.len << "u, " << b.dims.size() << ", d_, " << b.iterStep
               << ", " << b.iterWrap << ", " << b.acqLock << ", " << b.acqVal << ", " << b.relLock << ", " << b.relVal
               << ", " << b.next << "); }\n";
        }
}

std::string emitPlanHost(const DataflowPlan &plan, int memRows, int nargs) {
    std::ostringstream os;
    os << "/* ===== dataflow plan host side (dmaphop.plan*), generated ===== */\n"
       << "static void aiehlc_plan_mt_bd(XAie_DevInst *dev, XAie_LocType t, int bd, unsigned addr, unsigned len,\n"
       << "                              int nd, const unsigned *dims, int it_step, int it_wrap, int acq, int acqv,\n"
       << "                              int rel, int relv, int next) {\n"
       << "  /* MemTile BD: own memory at 0x80000, own locks 64.. (neighbourhood-relative addressing) */\n"
       << "  XAie_DmaDesc d;\n"
       << "  XAie_DmaDescInit(dev, &d, t);\n"
       << "  if (nd > 0) {\n"
       << "    XAie_DmaDimDesc dd[3];\n"
       << "    for (int i = 0; i < nd; i++) {\n"
       << "      dd[i].AieMlDimDesc.StepSize = dims[2 * i];\n"
       << "      dd[i].AieMlDimDesc.Wrap = (u16)dims[2 * i + 1];\n"
       << "    }\n"
       << "    XAie_DmaTensor ts = {(u8)nd, dd};\n"
       << "    XAie_DmaSetMultiDimAddr(&d, &ts, addr, len);\n"
       << "  } else {\n"
       << "    XAie_DmaSetAddrLen(&d, addr, len);\n"
       << "  }\n"
       << "  if (it_wrap > 1)\n"
       << "    XAie_DmaSetBdIteration(&d, (u32)it_step, (u16)it_wrap, 0);\n"
       << "  if (acq >= 0 && rel >= 0)\n"
       << "    XAie_DmaSetLock(&d, XAie_LockInit(64 + acq, acqv), XAie_LockInit(64 + rel, relv));\n"
       << "  if (next >= 0)\n"
       << "    XAie_DmaSetNextBd(&d, (u16)next, XAIE_ENABLE);\n"
       << "  XAie_DmaEnableBd(&d);\n"
       << "  if (XAie_DmaWriteBd(dev, &d, t, (u8)bd) != XAIE_OK)\n"
       << "    printf(\"[dataflow plan] MemTile BD %d on (%d,%d) FAILED\\n\", bd, t.Col, t.Row);\n"
       << "}\n"
       << "static unsigned aiehlc_plan_nlaunch;\n"
       << "static ioevent aiehlc_plan_ev[" << std::max<size_t>(plan.shimBds.size(), 1) << "];\n"
       << "static int aiehlc_plan_nev;\n"
       << "static void aiehlc_plan_host_setup(XAie_DevInst *v1) {\n"
       << "  (void)v1;\n"
       << "  __Runtime_plan_setup(" << (plan.bdOnce ? 1 : 0) << ", " << plan.persistentGoLock << ");\n"
       << "}\n"
       << "static void aiehlc_plan_host_launch(XAie_DevInst *v1";
    for (int i = 0; i < nargs; i++)
        os << ", void *a" << i;
    os << ") {\n  void *const args[] = {";
    for (int i = 0; i < nargs; i++)
        os << (i ? ", " : "") << "a" << i;
    if (nargs == 0)
        os << "0";
    os << "};\n"
       << "  const int first = aiehlc_plan_nlaunch == 0;\n"
       << "  (void)args;\n";
    os << "  /* MemTile locks (every launch; `later` from the second launch on) */\n";
    for (const auto &l : plan.locks)
        for (const auto &t : l.tiles) {
            if (!isMem(t, memRows))
                continue;
            os << "  " << (l.once ? "if (first) " : "") << "XAie_LockSetValue(v1, XAie_TileLoc(" << t.col << ", "
               << t.row << "), XAie_LockInit(" << l.id << ", ";
            if (l.later >= 0 && l.later != l.init)
                os << "first ? " << l.init << " : " << l.later;
            else
                os << l.init;
            os << "));\n";
        }
    os << "  if (" << (plan.bdOnce ? "first" : "1") << ") { /* MemTile BDs + channel enables */\n";
    emitMemtileBds(plan, memRows, os);
    for (const auto &c : plan.channels)
        for (const auto &t : c.tiles)
            if (isMem(t, memRows))
                os << "    XAie_DmaChannelEnable(v1, XAie_TileLoc(" << t.col << ", " << t.row << "), " << c.ch << ", "
                   << (c.s2mm ? "DMA_S2MM" : "DMA_MM2S") << ");\n";
    os << "  }\n  /* MemTile start queues */\n";
    for (const auto &c : plan.channels)
        for (const auto &t : c.tiles)
            if (isMem(t, memRows))
                os << "  " << (c.firstLaunchOnly ? "if (first) " : "")
                   << "XAie_DmaChannelSetStartQueue(v1, XAie_TileLoc(" << t.col << ", " << t.row << "), " << c.ch
                   << ", " << (c.s2mm ? "DMA_S2MM" : "DMA_MM2S") << ", " << c.startBd << ", " << c.repeat << ", 0);\n";
    os << "  /* shim transfers over the kernel arguments */\n";
    for (const auto &s : plan.shimBds) {
        auto g = [&](size_t i, bool wrap) -> int64_t {
            return i < s.dims.size() ? (wrap ? s.dims[i].second : s.dims[i].first) : 0;
        };
        os << "  " << (s.firstLaunchOnly ? "if (first) " : "") << "{\n"
           << "    XAie_DmaDesc d = __Runtime_dma_bd_config_multidim_ooo(v1, XAie_TileLoc(" << s.col << ", 0), "
           << "__runtime_buffer_offset(args[" << s.arg << "], (int64_t)" << s.offset << "LL), " << s.bd << ", " << s.len
           << ", -1, 0, 0, -1, 0, -1, 0, -1, " << s.dims.size() << ", " << g(0, false) << ", " << g(0, true) << ", "
           << g(1, false) << ", " << g(1, true) << ", " << g(2, false) << ", " << g(2, true) << ", " << s.iterStep
           << ", " << s.iterWrap << ");\n"
           << "    io o = __Runtime_dma_createio_4(XAie_TileLoc(" << s.col << ", 0), d, " << s.ch << ", " << s.bd
           << ", " << (s.mm2s ? "DMA_MM2S" : "DMA_S2MM") << ");\n"
           << "    aiehlc_plan_ev[aiehlc_plan_nev++] = __Runtime_startio(v1, o, " << s.bd << ", " << s.repeat << ");\n"
           << "  }\n";
    }
    os << "  aiehlc_plan_nlaunch++;\n}\n"
       << "static void aiehlc_plan_host_wait(XAie_DevInst *v1) {\n"
       << "  for (int i = 0; i < aiehlc_plan_nev; i++)\n"
       << "    __Runtime_wait(v1, aiehlc_plan_ev[i]);\n"
       << "  aiehlc_plan_nev = 0;\n"
       << "}\n\n";
    return os.str();
}

std::string emitPlanKernelBlock(const DataflowPlan &plan, int memRows, int partStartCol) {
    std::set<Tile> cores;
    for (const auto &b : plan.bds)
        for (auto &t : b.tiles)
            if (t.row > memRows)
                cores.insert(t);
    for (const auto &l : plan.locks)
        for (auto &t : l.tiles)
            if (t.row > memRows)
                cores.insert(t);
    for (const auto &c : plan.channels)
        for (auto &t : c.tiles)
            if (t.row > memRows)
                cores.insert(t);
    if (cores.empty())
        return "";
    std::ostringstream os;
    os << "{ // DATAFLOW PLAN core-tile DMA (dmaphop.plan_bd / plan_lock / plan_channel), generated\n"
       << "  AieKcReg _kc[8];\n  int _n;\n"
       << "  const unsigned _pcid = get_coreid();\n"
       << "  const int _pcol = (int)(_pcid >> 16) - " << partStartCol << ", _prow = (int)(_pcid & 0x1F);\n"
       << "  (void)_pcol; (void)_prow; (void)_n;\n";
    auto open = [&](const std::vector<Tile> &tiles) {
        std::vector<Tile> ct;
        for (auto &t : tiles)
            if (t.row > memRows)
                ct.push_back(t);
        std::string c = tileCond(ct, cores);
        os << (c.empty() ? "  {\n" : "  if (" + c + ") {\n");
        return !ct.empty();
    };
    for (const auto &b : plan.bds) {
        if (!open(b.tiles)) {
            os << "  }\n";
            continue;
        }
        os << "    const AieKcDims _d = " << dimsInit(b.dims, b.iterStep, b.iterWrap) << ";\n"
           << "    _n = aie_kc_encode_bd_nd(_kc, " << b.bd << ", (uintptr_t)0x" << std::hex << b.addr << std::dec
           << ", " << b.len << ", " << b.next << ", " << b.acqLock << ", " << b.acqVal << ", " << b.relLock << ", "
           << b.relVal << ", 0, 0, 0, -1, &_d);\n    core_reg_write_block(_kc, _n);\n  }\n";
    }
    for (const auto &l : plan.locks) {
        if (!open(l.tiles)) {
            os << "  }\n";
            continue;
        }
        os << "    aie_kc_encode_lock(_kc, " << l.id << ", " << l.init << ");\n"
           << "    core_reg_write(_kc[0].off, _kc[0].val);\n  }\n";
    }
    for (const auto &c : plan.channels) {
        if (!open(c.tiles)) {
            os << "  }\n";
            continue;
        }
        os << "    aie_kc_encode_" << (c.s2mm ? "s2mm" : "mm2s") << "_start(_kc, " << c.ch << ", " << c.startBd << ", "
           << c.repeat << ", 0);\n    core_reg_write(_kc[0].off, _kc[0].val);\n  }\n";
    }
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
    os << "#endif\n";
    return os.str();
}

} // namespace dfplan
