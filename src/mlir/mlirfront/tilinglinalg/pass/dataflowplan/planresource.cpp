/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// The dataflow plan's resources (doc/design/dmaphop_dataflow_plan.md, "Resources"): every BD id, lock id
// and buffer address the plan's DMA program uses is allocated here, against
//   * the host module's generated flows (config.dma_bd / create_io on each tile: BD ids, lock ids,
//     channels),
//   * the cores' self-programmed DMA (ResourceMgr::coreOffloadPlan, KERNELCONFIGOFFLOAD),
//   * the control plane's runtime-programmed shim BDs (aie_runtime_resource.h), and
//   * the core buffer allocator: the hosted chunks live in the memory the allocator gave the replaced
//     ports' windows (the kernel never touches those windows once the plan serves the ports),
// with the device limits of plantarget.h. Nothing is a literal: a conflict is a build error naming the
// tile and the resource instead of a silently shared BD or lock.

#include "dataflowplan.h"
#include "plantarget.h"

#include "dfschedulemanager.h"
#include "aie_runtime_resource.h"
#include "hw/ResourceManager.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "llvm/Support/raw_ostream.h"

#include <climits>
#include <map>
#include <set>
#include <sstream>

namespace dfplan {

using namespace mlir;

namespace {

struct Used {
    std::map<Tile, std::set<int>> bds, locks;
    std::map<Tile, std::set<std::pair<int, bool>>> channels; // (channel, s2mm)
};

int constInt(Value v) {
    if (auto c = v ? v.getDefiningOp<arith::ConstantOp>() : arith::ConstantOp())
        if (auto i = dyn_cast<IntegerAttr>(c.getValue()))
            return (int)i.getInt();
    return INT_MIN;
}

bool tileOf(Value v, Tile &t) {
    auto d = v ? v.getDefiningOp<dfschedule::DeclareTileOp>() : dfschedule::DeclareTileOp();
    if (!d)
        return false;
    t = {(int)d.getCol(), (int)d.getRow()};
    return true;
}

bool isMemRow(const DataflowPlan &p, int row) { return row >= 1 && row <= p.memtileRows; }

// A lock id as a tile's BD names it -> the tile's own lock (a MemTile BD names its own locks with a bias).
int ownLock(const DataflowPlan &p, const Tile &t, int id) {
    const PlanTarget &T = planTarget();
    if (!isMemRow(p, t.row))
        return id;
    return id >= T.memLockBdBias && id < T.memLockBdBias + T.memLocks ? id - T.memLockBdBias : -1;
}

Used collectUsed(ModuleOp host, const DataflowPlan &p) {
    Used u;
    host.walk([&](Operation *op) {
        Tile t;
        if (auto bd = dyn_cast<dfschedule::ConfigDmaBdOp>(op)) {
            if (!tileOf(bd.getTile(), t))
                return;
            if (int id = constInt(bd.getBdId()); id >= 0)
                u.bds[t].insert(id);
            for (int l : {(int)(int32_t)bd.getAcquireLockId(), (int)(int32_t)bd.getReleaseLockId()})
                if (l >= 0 && ownLock(p, t, l) >= 0)
                    u.locks[t].insert(ownLock(p, t, l));
        } else if (auto io = dyn_cast<dfschedule::ConfigCreateIoOp>(op)) {
            if (tileOf(io.getTile(), t))
                u.channels[t].insert({(int)io.getChannel(), io.getDirection() == "S2MM"});
        }
    });
    // The control plane's shim BDs (aie_runtime_resource.h) are programmed by the runtime, not by host ops:
    // reserved on the control column exactly as the blueprint lowering reserves them.
    auto attr = [&](const char *n) {
        auto a = host->getAttrOfType<IntegerAttr>(n);
        return a ? (int)a.getInt() : -1;
    };
    if (attr("routing.control_plan_op_control_packet") > 0 && attr("routing.control_plan_shim_col") >= 0) {
        std::set<int> &bds = u.bds[{attr("routing.control_plan_shim_col"), 0}];
        for (int b = RT_RES_CTRL_BD_LO; b <= RT_RES_CTRL_BD_HI; b++)
            bds.insert(b);
        for (int b = RT_RES_CTRL_ACK_BD_LO; b <= RT_RES_CTRL_ACK_BD_HI; b++)
            bds.insert(b);
        if (attr("routing.control_plan_shim_bd_ctrl") > 0) {
            for (int b = RT_RES_SHIMROW_BD_LO; b <= RT_RES_SHIMROW_BD_HI; b++)
                bds.insert(b);
            bds.insert(RT_RES_SHIMROW_ACK_BD);
        }
    }
    try {
        for (const CoreOffloadTileConfig &c : ResourceMgr::instance()->coreOffloadPlan()) {
            if (p.replaces(c.funcArgIdx)) // the plan programs that data movement itself
                continue;
            const Tile t{c.col, c.row};
            for (int b : {c.pingBdId, c.pongBdId})
                if (b >= 0)
                    u.bds[t].insert(b);
            for (int l : {c.bdAcquireLockId, c.bdReleaseLockId})
                if (l >= 0)
                    u.locks[t].insert(l);
            u.channels[t].insert({c.channel, !c.isOutput});
        }
    } catch (...) {
        // no ResourceMgr (unit tests): only the host module's flows
    }
    return u;
}

// Free ids of a resource over a set of tiles (the same id on every tile: one kernel ELF / one program).
struct Pool {
    std::set<int> used;
    int lo = 0, hi = 0;
    bool free(int id) const { return id >= lo && id < hi && !used.count(id); }
    // first base with base + k * stride free for k < n (top: search from the top down)
    int run(int n, int stride = 1, bool top = false) {
        for (int i = 0; i < hi - lo; i++) {
            const int b = top ? hi - 1 - i - (n - 1) * stride : lo + i;
            bool ok = b >= lo;
            for (int k = 0; ok && k < n; k++)
                ok = free(b + k * stride);
            if (ok) {
                for (int k = 0; k < n; k++)
                    used.insert(b + k * stride);
                return b;
            }
        }
        return -1;
    }
};

Pool poolOver(const std::map<Tile, std::set<int>> &used, const std::vector<Tile> &tiles, int lo, int hi) {
    Pool pl;
    pl.lo = lo, pl.hi = hi;
    for (const Tile &t : tiles) {
        auto it = used.find(t);
        if (it != used.end())
            pl.used.insert(it->second.begin(), it->second.end());
    }
    return pl;
}

std::string tileStr(const Tile &t) { return "(" + std::to_string(t.col) + ", " + std::to_string(t.row) + ")"; }

// Core tiles: chunk buffers, BDs, locks; every core the same.
bool assignCores(const DataflowPlan &p, const Used &u, PlanResources &r, std::string &why) {
    const PlanTarget &T = planTarget();
    std::vector<Tile> cores;
    for (int c = 0; c < p.meshCols; c++)
        for (int pm = 0; pm < p.meshRows; pm++)
            cores.push_back({p.colLo + c, p.coreRowBase + pm});
    for (const Tile &t : cores) {
        auto it = u.channels.find(t);
        for (int ch = 0; ch < T.coreS2mmChannels && it != u.channels.end(); ch++)
            if (it->second.count({ch, true})) {
                why = "core " + tileStr(t) + " S2MM channel " + std::to_string(ch) +
                      " is used by a generated flow; the plan's hosted streams need every core S2MM channel";
                return false;
            }
    }
    Pool bd = poolOver(u.bds, cores, 0, T.coreBds), lk = poolOver(u.locks, cores, 0, T.coreLocks);
    for (int ch = 0; ch < 2; ch++) {
        const int b = bd.run(2);
        if (b < 0) {
            why = "no two free core BDs for S2MM channel " + std::to_string(ch);
            return false;
        }
        r.coreBd[ch][0] = b, r.coreBd[ch][1] = b + 1;
    }
    // F / G / no-op: three pairs handDelta apart (aie_block_io_plan.h hands on to acquire id + delta);
    // E: four in a row (buffer index ch + 2 slot); then the go and sync locks
    r.lockF = lk.run(3 * r.handDelta);
    r.lockE = lk.run(4);
    r.lockGo = p.persistent ? lk.run(1) : -1;
    r.lockSync = lk.run(1);
    if (r.lockF < 0 || r.lockE < 0 || r.lockSync < 0 || (p.persistent && r.lockGo < 0)) {
        why = "not enough free core locks (" + std::to_string(lk.hi - (int)lk.used.size()) +
              " left; the plan needs F / G / no-op pairs, 4 E locks, a sync lock and a go lock)";
        return false;
    }
    // the hosted chunks: in the memory the allocator gave the replaced ports' windows
    const PlanStream *A = streamOfRole(p, "a");
    const int64_t need = 4 * (int64_t)A->chunkRows * A->chunkCols;
    int64_t lo = INT64_MAX, hi = 0, total = 0;
    try {
        for (const CoreMemSlot &s : ResourceMgr::instance()->coreMemAllocator().getAllocations())
            if (p.replaces(s.ownerId)) {
                lo = std::min<int64_t>(lo, s.address), hi = std::max<int64_t>(hi, s.address + s.size);
                total += s.size;
            }
    } catch (...) {
    }
    if (total == 0 || hi - lo != total || total < need) {
        why = "the replaced ports' core buffers (" + std::to_string(total) + " B, " +
              (total && hi - lo != total ? "not contiguous" : "contiguous") + ") cannot hold the hosted chunks (" +
              std::to_string(need) + " B: 2 channels x 2 buffers x one chunk)";
        return false;
    }
    r.slotBase = lo, r.slotBytes = need;
    return true;
}

// MemTiles: per stream, the tiles its shim routes end on; locks, BDs (in the channel's bank) and memory.
bool assignMemTiles(const DataflowPlan &p, const Used &u, PlanResources &r, std::string &why) {
    const PlanTarget &T = planTarget();
    std::map<Tile, int64_t> next; // bump allocation of each MemTile's memory
    r.mem.assign(p.streams.size(), {});
    for (size_t si = 0; si < p.streams.size(); si++) {
        const PlanStream &s = p.streams[si];
        PlanResources::Mem &m = r.mem[si];
        std::vector<Tile> mts;
        int s2mm = -1;
        std::vector<int> mm2s; // MM2S channels out of the MemTile (column 0's; every column alike)
        for (int c = 0; c < p.meshCols; c++)
            for (const PlanRoute *rt : routesOf(p, s.arg, true, p.colLo + c)) {
                const Tile mt = rt->dsts.front().first;
                if (!isMemRow(p, mt.row)) {
                    why = "stream " + std::to_string(s.arg) + ": its shim route ends on " + tileStr(mt) +
                          ", not a MemTile";
                    return false;
                }
                mts.push_back(mt);
                s2mm = rt->dsts.front().second;
                if (c == 0)
                    for (const PlanRoute *o : routesOf(p, s.arg, false, mt.col))
                        if (o->src == mt)
                            mm2s.push_back(o->srcCh);
            }
        for (const Tile &t : mts) {
            auto it = u.bds.find(t);
            if (it != u.bds.end() && !it->second.empty()) {
                why = "MemTile " + tileStr(t) + " is used by a generated flow (BD " +
                      std::to_string(*it->second.begin()) + "); the plan does not share a MemTile's memory";
                return false;
            }
        }
        Pool lk = poolOver(u.locks, mts, 0, T.memLocks), bd = poolOver(u.bds, mts, 0, T.memBds);
        auto bankRun = [&](int ch, int n) {
            Pool b = bd;
            b.lo = T.memBankLo(ch), b.hi = b.lo + T.memBdBank;
            const int x = b.run(n);
            if (x >= 0)
                bd.used = b.used, bd.used.insert(x); // keep the taken ids
            return x;
        };
        m.lockA = lk.run(1), m.lockB = lk.run(1);
        const bool ring = s.stage == "memtile_ring";
        const int64_t chunk = (int64_t)s.chunkRows * s.chunkCols;
        const int64_t bytes = ring ? (int64_t)s.ring * 2 * chunk : (int64_t)s.hostRows.size() * s.chunks * chunk;
        m.bdIn = bankRun(s2mm, ring ? s.ring : 1);
        m.bdOut.clear();
        if (ring)
            m.bdOut.push_back(mm2s.size() == 1 ? bankRun(mm2s[0], s.ring) : -1);
        else
            for (int ch : mm2s)
                m.bdOut.push_back(bankRun(ch, 1));
        bool ok = m.lockA >= 0 && m.lockB >= 0 && m.bdIn >= 0 && !m.bdOut.empty();
        for (int b : m.bdOut)
            ok &= b >= 0;
        if (!ok) {
            why = "stream " + std::to_string(s.arg) + ": not enough free MemTile locks / BDs in the channels' banks";
            return false;
        }
        int64_t at = 0;
        for (const Tile &t : mts)
            at = std::max(at, next[t]);
        if (at + bytes > T.memBytes) {
            why = "stream " + std::to_string(s.arg) + ": " + std::to_string(bytes) + " B of MemTile buffers at " +
                  std::to_string(at) + " exceed the MemTile's " + std::to_string(T.memBytes) + " B";
            return false;
        }
        m.addr = T.memOwnBase + at;
        for (const Tile &t : mts)
            next[t] = at + bytes;
    }
    return true;
}

bool assignShim(const DataflowPlan &p, const Used &u, PlanResources &r, std::string &why) {
    const PlanTarget &T = planTarget();
    r.shimBd.assign(p.streams.size(), std::vector<int>(p.meshCols, -1));
    for (int c = 0; c < p.meshCols; c++) {
        const Tile t{p.colLo + c, 0};
        Pool bd = poolOver(u.bds, {t}, 0, T.shimBds);
        for (size_t si = 0; si < p.streams.size(); si++) {
            r.shimBd[si][c] = bd.run(1, 1, /*top*/ true);
            if (r.shimBd[si][c] < 0) {
                why = "shim " + tileStr(t) + ": no free BD for stream " + std::to_string(p.streams[si].arg);
                return false;
            }
        }
    }
    return true;
}

} // namespace

bool assignPlanResources(ModuleOp hostModule, DataflowPlan &p, std::string &why) {
    const Used u = collectUsed(hostModule, p);
    PlanResources r;
    if (!assignCores(p, u, r, why) || !assignMemTiles(p, u, r, why) || !assignShim(p, u, r, why))
        return false;
    r.assigned = true;
    p.res = r;
    std::ostringstream os;
    os << "[DataflowPlan] resources (" << planTarget().name << "): core BDs " << r.coreBd[0][0] << "," << r.coreBd[0][1]
       << "/" << r.coreBd[1][0] << "," << r.coreBd[1][1] << ", core locks F " << r.lockF << " E " << r.lockE << " go "
       << r.lockGo << " sync " << r.lockSync << ", chunk slots 0x" << std::hex << r.slotBase << std::dec << "+"
       << r.slotBytes << " (the replaced windows)";
    for (size_t si = 0; si < r.mem.size(); si++) {
        os << "; stream " << p.streams[si].arg << ": MemTile locks " << r.mem[si].lockA << "/" << r.mem[si].lockB
           << " BDs in " << r.mem[si].bdIn << " out";
        for (int b : r.mem[si].bdOut)
            os << " " << b;
        os << " @0x" << std::hex << r.mem[si].addr << std::dec << ", shim BD " << r.shimBd[si][0];
    }
    llvm::outs() << os.str() << "\n";
    return true;
}

} // namespace dfplan
