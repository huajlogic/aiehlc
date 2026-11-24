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

// Core tiles: chunk buffers, BDs, locks; every core the same (the protocol of streams[0]: checkPlanLayout
// makes every shared stream agree).
bool assignCores(const DataflowPlan &p, const Used &u, PlanResources &r, std::string &why) {
    const PlanTarget &T = planTarget();
    const PlanStream &s = p.streams[0];
    std::vector<Tile> cores;
    for (int c = 0; c < p.meshCols; c++)
        for (int pm = 0; pm < p.meshRows; pm++)
            cores.push_back({p.colLo + c, p.coreRowBase + pm});
    for (const Tile &t : cores) {
        auto it = u.channels.find(t);
        for (int ch = 0; ch < s.channels && it != u.channels.end(); ch++)
            if (it->second.count({ch, true})) {
                why = "core " + tileStr(t) + " S2MM channel " + std::to_string(ch) +
                      " is used by a generated flow; the plan's hosted streams need it";
                return false;
            }
    }
    Pool bd = poolOver(u.bds, cores, 0, T.coreBds), lk = poolOver(u.locks, cores, 0, T.coreLocks);
    r.coreBd.assign(s.channels, -1);
    for (int ch = 0; ch < s.channels; ch++)
        if ((r.coreBd[ch] = bd.run(s.slots)) < 0) {
            why = "no " + std::to_string(s.slots) + " free core BDs in a row for S2MM channel " + std::to_string(ch);
            return false;
        }
    // reader locks: (readers + 1) rows of `channels` (aie_block_io_plan.h hands on to acquire id + delta);
    // E: one per buffer, in a row; then the go and sync locks
    r.handDelta = s.channels;
    r.lockF = lk.run((s.readers + 1) * s.channels);
    r.lockE = lk.run(s.buffers());
    r.lockGo = p.persistent ? lk.run(1) : -1;
    r.lockSync = lk.run(1);
    if (r.lockF < 0 || r.lockE < 0 || r.lockSync < 0 || (p.persistent && r.lockGo < 0)) {
        why = "not enough free core locks (" + std::to_string(lk.hi - (int)lk.used.size()) + " left; the plan needs " +
              std::to_string((s.readers + 1) * s.channels) + " reader locks, " + std::to_string(s.buffers()) +
              " E locks, a sync lock" + (p.persistent ? " and a go lock)" : ")");
        return false;
    }
    // the hosted chunks: in the memory the allocator gave the replaced ports' windows
    const int64_t need = (int64_t)s.buffers() * s.chunkBytes();
    int64_t lo = INT64_MAX, hi = 0, total = 0;
    try {
        for (const CoreMemSlot &m : ResourceMgr::instance()->coreMemAllocator().getAllocations())
            if (p.replaces(m.ownerId)) {
                lo = std::min<int64_t>(lo, m.address), hi = std::max<int64_t>(hi, m.address + m.size);
                total += m.size;
            }
    } catch (...) {
    }
    if (total == 0 || hi - lo != total || total < need) {
        why = "the replaced ports' core buffers (" + std::to_string(total) + " B, " +
              (total && hi - lo != total ? "not contiguous" : "contiguous") + ") cannot hold the hosted chunks (" +
              std::to_string(need) + " B: channels x slots x one chunk)";
        return false;
    }
    r.slotBase = lo, r.slotBytes = need;
    return true;
}

// MemTiles: per stream and column, the MemTile its shim route ends on; locks, BDs (in each channel's bank)
// and memory (bump-allocated per MemTile, capacity checked).
bool assignMemTiles(const DataflowPlan &p, const Used &u, PlanResources &r, std::string &why) {
    const PlanTarget &T = planTarget();
    std::map<Tile, int64_t> next;
    std::map<Tile, std::set<int>> takenBd = u.bds, takenLock = u.locks;
    r.mem.assign(p.streams.size(), std::vector<PlanResources::Mem>(p.meshCols));
    for (size_t si = 0; si < p.streams.size(); si++) {
        const PlanStream &s = p.streams[si];
        for (int c = 0; c < p.meshCols; c++) {
            const MemtileUse mu = memtileUse(p, s, p.colLo + c);
            if (!mu.present)
                continue;
            const Tile &t = mu.mt;
            auto uit = u.bds.find(t);
            if (uit != u.bds.end() && !uit->second.empty()) {
                why = "MemTile " + tileStr(t) + " is used by a generated flow (BD " +
                      std::to_string(*uit->second.begin()) + "); the plan does not share a MemTile's memory";
                return false;
            }
            PlanResources::Mem &m = r.mem[si][c];
            Pool lk = poolOver(takenLock, {t}, 0, T.memLocks);
            for (int i = 0; i < mu.locks; i++)
                m.locks.push_back(lk.run(1));
            auto bankRun = [&](int ch, int n) {
                Pool b = poolOver(takenBd, {t}, T.memBankLo(ch), T.memBankLo(ch) + T.memBdBank);
                const int x = b.run(n);
                if (x >= 0)
                    for (int k = 0; k < n; k++)
                        takenBd[t].insert(x + k);
                return x;
            };
            m.bdIn = bankRun(mu.s2mm, mu.s2mmBds);
            for (size_t k = 0; k < mu.out.size(); k++)
                m.bdOut.push_back(bankRun(mu.out[k]->srcCh, mu.mm2sBds[k]));
            bool ok = m.bdIn >= 0;
            for (int x : m.locks)
                ok &= x >= 0;
            for (int x : m.bdOut)
                ok &= x >= 0;
            if (!ok) {
                why = "stream " + std::to_string(s.arg) +
                      ": not enough free locks / BDs (in the channels' banks) on "
                      "MemTile " +
                      tileStr(t);
                return false;
            }
            takenLock[t].insert(m.locks.begin(), m.locks.end());
            if (next[t] + mu.bytes > T.memBytes) {
                why = "stream " + std::to_string(s.arg) + ": " + std::to_string(mu.bytes) +
                      " B of buffers on MemTile " + tileStr(t) + " exceed its " + std::to_string(T.memBytes) + " B";
                return false;
            }
            m.addr = T.memOwnBase + next[t];
            next[t] += mu.bytes;
        }
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
            if (!memtileUse(p, p.streams[si], p.colLo + c).present)
                continue;
            if ((r.shimBd[si][c] = bd.run(1, 1, /*top*/ true)) < 0) {
                why = "shim " + tileStr(t) + ": no free BD for stream " + std::to_string(p.streams[si].arg);
                return false;
            }
        }
    }
    return true;
}

} // namespace

// Pinned resources (dmaphop.plan_resources, or read back from a dfschedule program) replace the allocated
// ones part by part -- after a check that they are free of the generated flows and inside the device.
bool adoptPinned(const DataflowPlan &p, const Used &u, PlanResources &r, std::string &why) {
    const PlanTarget &T = planTarget();
    const PlanResources &pin = p.pinned;
    auto clash = [&](const std::map<Tile, std::set<int>> &used, const Tile &t, int id, int n, const char *what) {
        auto it = used.find(t);
        if (id < 0 || id >= n || (it != used.end() && it->second.count(id))) {
            why = std::string("pinned ") + what + " " + std::to_string(id) + " on " + tileStr(t) +
                  " is outside the tile or used by a generated flow";
            return true;
        }
        return false;
    };
    if (pin.hasCore) {
        const PlanStream &s = p.streams[0];
        std::vector<int> locks, bds;
        for (int i = 0; i <= s.readers; i++)
            for (int ch = 0; ch < s.channels; ch++)
                locks.push_back(pin.lockF + i * pin.handDelta + ch);
        for (int b = 0; b < s.buffers(); b++)
            locks.push_back(pin.lockE + b);
        locks.push_back(pin.lockSync);
        if (p.persistent)
            locks.push_back(pin.lockGo);
        for (int ch = 0; ch < (int)pin.coreBd.size(); ch++)
            for (int k = 0; k < s.slots; k++)
                bds.push_back(pin.coreBd[ch] + k);
        for (int c = 0; c < p.meshCols; c++)
            for (int pm = 0; pm < p.meshRows; pm++) {
                const Tile t{p.colLo + c, p.coreRowBase + pm};
                for (int l : locks)
                    if (clash(u.locks, t, l, T.coreLocks, "core lock"))
                        return false;
                for (int b : bds)
                    if (clash(u.bds, t, b, T.coreBds, "core BD"))
                        return false;
            }
        if ((int)pin.coreBd.size() != s.channels || pin.slotBase != r.slotBase) {
            std::ostringstream o;
            o << "pinned core chunk slots must be the replaced windows' memory (0x" << std::hex << r.slotBase
              << std::dec << ") with one BD run per channel";
            why = o.str();
            return false;
        }
        r.coreBd = pin.coreBd, r.lockF = pin.lockF, r.handDelta = pin.handDelta, r.lockE = pin.lockE;
        r.lockGo = pin.lockGo, r.lockSync = pin.lockSync;
    }
    if (pin.hasMem)
        for (size_t si = 0; si < pin.mem.size() && si < r.mem.size(); si++)
            for (size_t c = 0; c < pin.mem[si].size() && c < r.mem[si].size(); c++) {
                const PlanResources::Mem &m = pin.mem[si][c];
                if (m.bdIn < 0)
                    continue;
                const MemtileUse mu = memtileUse(p, p.streams[si], p.colLo + (int)c);
                if (!mu.present || m.locks.size() != (size_t)mu.locks || m.bdOut.size() != mu.out.size() ||
                    m.addr < T.memOwnBase || m.addr + mu.bytes > T.memOwnBase + T.memBytes) {
                    why = "pinned MemTile resources of stream " + std::to_string(p.streams[si].arg) + " column " +
                          std::to_string(c) + " do not fit its layout (locks, MM2S routes, memory)";
                    return false;
                }
                for (int l : m.locks)
                    if (clash(u.locks, mu.mt, l, T.memLocks, "MemTile lock"))
                        return false;
                auto inBank = [&](int ch, int first, int n) {
                    return first >= T.memBankLo(ch) && first + n <= T.memBankLo(ch) + T.memBdBank;
                };
                bool ok = inBank(mu.s2mm, m.bdIn, mu.s2mmBds);
                for (size_t k = 0; k < mu.out.size(); k++)
                    ok &= inBank(mu.out[k]->srcCh, m.bdOut[k], mu.mm2sBds[k]);
                if (!ok) {
                    why = "pinned MemTile BDs of stream " + std::to_string(p.streams[si].arg) + " column " +
                          std::to_string(c) + " leave their channels' BD banks";
                    return false;
                }
                r.mem[si][c] = m;
            }
    if (pin.hasShim)
        for (size_t si = 0; si < pin.shimBd.size() && si < r.shimBd.size(); si++)
            for (size_t c = 0; c < pin.shimBd[si].size() && c < r.shimBd[si].size(); c++) {
                const int b = pin.shimBd[si][c];
                if (b < 0)
                    continue;
                if (clash(u.bds, {p.colLo + (int)c, 0}, b, T.shimBds, "shim BD"))
                    return false;
                r.shimBd[si][c] = b;
            }
    return true;
}

bool assignPlanResources(ModuleOp hostModule, DataflowPlan &p, std::string &why) {
    const Used u = collectUsed(hostModule, p);
    PlanResources r;
    if (!assignCores(p, u, r, why) || !assignMemTiles(p, u, r, why) || !assignShim(p, u, r, why) ||
        !adoptPinned(p, u, r, why))
        return false;
    r.assigned = true;
    p.res = r;
    std::ostringstream os;
    os << "[DataflowPlan] resources (" << planTarget().name << "): core BDs";
    for (int b : r.coreBd)
        os << " " << b;
    os << " (x" << p.streams[0].slots << "), core locks F " << r.lockF << " E " << r.lockE << " go " << r.lockGo
       << " sync " << r.lockSync << ", chunk slots 0x" << std::hex << r.slotBase << std::dec << "+" << r.slotBytes
       << " (the replaced windows)";
    for (size_t si = 0; si < r.mem.size(); si++)
        for (int c = 0; c < p.meshCols; c++) {
            const auto &m = r.mem[si][c];
            if (m.bdIn < 0)
                continue;
            os << "; stream " << p.streams[si].arg << " col " << c << ": locks";
            for (int x : m.locks)
                os << " " << x;
            os << " BDs in " << m.bdIn << " out";
            for (int x : m.bdOut)
                os << " " << x;
            os << " @0x" << std::hex << m.addr << std::dec << " shim BD " << r.shimBd[si][c];
        }
    llvm::outs() << os.str() << "\n";
    return true;
}

} // namespace dfplan
