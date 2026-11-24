/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// The dataflow plan's DMA program (doc/design/dmaphop_dataflow_plan.md):
//   deriveDmaProgram      dmaphop.plan_stream decisions -> locks / BDs / channels / shim transfers
//   materializeHostPlan   -> dfschedule ops in the host module (MemTiles, shim)
//   materializeKernelPlan -> dfschedule ops in the kernel module (cores, declaretile.self)
//   lowerKernelPlanOps    kernel module plan ops -> the core's KERNELCONFIGOFFLOAD text

#include "dataflowplan.h"

#include "dfschedulemanager.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "llvm/Support/raw_ostream.h"

#include "plantarget.h"

#include <algorithm>
#include <map>
#include <set>
#include <sstream>

namespace dfplan {

using namespace mlir;

const PlanStream *streamOfRole(const DataflowPlan &p, const char *role) {
    for (const auto &s : p.streams)
        if (s.role == role)
            return &s;
    return nullptr;
}

std::vector<const PlanRoute *> routesOf(const DataflowPlan &p, int arg, bool fromShim, int col) {
    std::vector<const PlanRoute *> out;
    for (const auto &r : p.routes)
        if (r.arg == arg && r.srcShim == fromShim && (col < 0 || r.src.col == col))
            out.push_back(&r);
    return out;
}

namespace {

int64_t chunkBytes(const PlanStream &s) { return (int64_t)s.chunkRows * s.chunkCols; }

// A contiguous run of `words` 32-bit words as two BD dimensions {1, in} {in, out} (in * out = words),
// both wraps within the tile kind's limit (maxW); {0, 0} when it cannot be split.
std::pair<int64_t, int64_t> splitWords(int64_t words, int64_t maxW) {
    for (int64_t in = std::min(words, maxW); in >= 1; in--)
        if (words % in == 0 && words / in <= maxW)
            return {in, words / in};
    return {0, 0};
}

// The chunk stream a shim BD reads from DDR, chunk by chunk (bytes): rows of chunkCols, chunkRows rows,
// then n chunks. The host lays the stream out contiguously in this order (the plan's DDR contract).
Dims shimChunkDims(const PlanStream &s, int64_t n) {
    const int w = planTarget().bdWordBytes;
    return {{w, s.chunkCols / w}, {s.chunkCols, s.chunkRows}, {chunkBytes(s), n}};
}

// MemTile side of a memtile_ring stream, per column: the shim's chunks enter a FIFO ring of `ring`
// buffers of 2 chunks (counting locks: lockA = empty, lockB = full) and leave on the MemTile's MM2S route.
bool deriveRing(DataflowPlan &p, size_t si, std::string &why) {
    const PlanStream &A = p.streams[si];
    const PlanResources::Mem &m = p.res.mem[si];
    const int64_t chunk = chunkBytes(A), buf = 2 * chunk, aLen = (int64_t)A.chunks / 2 * chunk;
    const int ring = A.ring, rounds = (int)(A.rounds * aLen / (ring * buf));
    for (int c = 0; c < p.meshCols; c++) {
        auto in = routesOf(p, A.arg, true, p.colLo + c);
        if (in.size() != 1 || in[0]->dsts.size() != 1) {
            why = "stream " + std::to_string(A.arg) + ": column " + std::to_string(c) +
                  " needs one shim route to one MemTile";
            return false;
        }
        const Tile mt = in[0]->dsts[0].first;
        const int s2mm = in[0]->dsts[0].second;
        const PlanRoute *out = nullptr;
        for (const PlanRoute *r : routesOf(p, A.arg, false, mt.col))
            if (r->src == mt)
                out = r;
        if (!out) {
            why = "stream " + std::to_string(A.arg) + ": no route out of MemTile (" + std::to_string(mt.col) + ", " +
                  std::to_string(mt.row) + ")";
            return false;
        }
        const std::vector<Tile> t{mt};
        p.locks.push_back({t, m.lockA, ring, -1, false, true});
        p.locks.push_back({t, m.lockB, 0, -1, false, true});
        for (int b = 0; b < ring; b++) {
            const bool last = b == ring - 1;
            const int64_t addr = m.addr + b * buf;
            p.bds.push_back({t, m.bdIn + b, addr, buf, {}, 0, 0, m.lockA, -1, m.lockB, 1, last ? -1 : m.bdIn + b + 1});
            p.bds.push_back(
                {t, m.bdOut[0] + b, addr, buf, {}, 0, 0, m.lockB, -1, m.lockA, 1, last ? -1 : m.bdOut[0] + b + 1});
        }
        p.channels.push_back({t, true, s2mm, m.bdIn, rounds, false});
        p.channels.push_back({t, false, out->srcCh, m.bdOut[0], rounds, false});
    }
    return true;
}

// Strip group of a core row for a stream: the g with hostRows[g] == mesh row.
int groupOfHostRow(const PlanStream &s, int meshRow) {
    for (size_t g = 0; g < s.hostRows.size(); g++)
        if (s.hostRows[g] == meshRow)
            return (int)g;
    return -1;
}

// MemTile side of a memtile (resident) stream, per column: the column's strips held whole (one S2MM load,
// on the first launch only when resident across launches; lockA = ready, lockB = free), replayed by one
// MM2S BD per route -- the route's destination says which strip (its host row) and which chunk parity
// (its S2MM channel).
bool deriveResident(DataflowPlan &p, size_t si, std::string &why) {
    const PlanStream &B = p.streams[si];
    const PlanResources::Mem &m = p.res.mem[si];
    const int64_t chunk = chunkBytes(B), bLen = (int64_t)B.chunks * chunk, groups = B.hostRows.size();
    const bool keep = B.residentLaunches;
    const auto [in, out] = splitWords(chunk / planTarget().bdWordBytes, planTarget().memBdMaxWrap);
    const int64_t chunkW = chunk / planTarget().bdWordBytes;
    for (int c = 0; c < p.meshCols; c++) {
        auto load = routesOf(p, B.arg, true, p.colLo + c);
        if (load.size() != 1 || load[0]->dsts.size() != 1) {
            why = "stream " + std::to_string(B.arg) + ": column " + std::to_string(c) +
                  " needs one shim route to one MemTile";
            return false;
        }
        const Tile mt = load[0]->dsts[0].first;
        const std::vector<Tile> t{mt};
        const int replays = (int)groups * 2;
        p.locks.push_back({t, m.lockA, 0, keep ? replays : -1, false, true});
        p.locks.push_back({t, m.lockB, 1, keep ? 0 : -1, false, true});
        p.bds.push_back({t, m.bdIn, m.addr, groups * bLen, {}, 0, 0, m.lockB, -1, m.lockA, replays, -1});
        p.channels.push_back({t, true, load[0]->dsts[0].second, m.bdIn, 1, keep});
        size_t k = 0;
        for (const PlanRoute *r : routesOf(p, B.arg, false, mt.col)) {
            if (!(r->src == mt))
                continue;
            if (r->dsts.size() != 1 || k >= m.bdOut.size()) {
                why = "stream " + std::to_string(B.arg) + ": each MemTile replay route has one destination";
                return false;
            }
            const int g = groupOfHostRow(B, r->dsts[0].first.row - p.coreRowBase), q = r->dsts[0].second;
            if (g < 0 || q > 1) {
                why = "stream " + std::to_string(B.arg) + ": a replay route ends on a core that hosts no strip";
                return false;
            }
            // every other chunk of strip g, from chunk q
            Dims d = {{1, in}, {in, out}, {2 * chunkW, B.chunks / 2}};
            p.bds.push_back(
                {t, m.bdOut[k], m.addr + g * bLen + q * chunk, bLen / 2, d, 0, 0, m.lockA, -1, m.lockA, 1, -1});
            p.channels.push_back({t, false, r->srcCh, m.bdOut[k], B.rounds, false});
            k++;
        }
        if ((int)k != replays) {
            why = "stream " + std::to_string(B.arg) + ": MemTile (" + std::to_string(mt.col) + ", " +
                  std::to_string(mt.row) + ") has " + std::to_string(k) + " replay routes, the layout needs " +
                  std::to_string(replays);
            return false;
        }
    }
    return true;
}

// Every core hosts one stream: per S2MM channel (chunk parity) two buffers, each chunk split in two parts
// (SLOT_LO / SLOT_HI halves of the slot region -- different memory banks). Buffer index = channel + 2 slot
// = chunk g & 3, one AND on the core. Locks (res): F (DMA -> first reader) and G = F + delta (first ->
// second reader) per channel, the no-op pair G + delta (held at 0), E per buffer (both readers -> DMA).
void deriveCoreSlots(DataflowPlan &p, const PlanStream &s, const std::vector<Tile> &cores) {
    const PlanResources &r = p.res;
    const PlanTarget &T = planTarget();
    const int64_t chunk = chunkBytes(s), half = chunk / 2, part = 4 * half;
    const auto [in, out] = splitWords(half / T.bdWordBytes, T.coreBdMaxWrap);
    for (int ch = 0; ch < 2; ch++)
        for (int k = 0; k < 2; k++) {
            const int buf = ch + 2 * k;
            Dims d = {{1, in}, {in, out}, {part / T.bdWordBytes, 0}}; // half, then the other half one part on
            p.bds.push_back({cores, r.coreBd[ch][k], r.slotBase + buf * half, chunk, d, 0, 0, r.lockE + ch + 2 * k, -2,
                             r.lockF + ch, 1, r.coreBd[ch][k ^ 1]});
        }
    for (int ch = 0; ch < 2; ch++) {
        for (int k = 0; k < 2; k++)
            p.locks.push_back({cores, r.lockE + ch + 2 * k, 2, -1, false});
        for (int j = 0; j < 3; j++) // F, G, no-op
            p.locks.push_back({cores, r.lockF + ch + j * r.handDelta, 0, -1, false});
    }
    if (p.persistent)
        p.locks.push_back({cores, r.lockGo, 1, -1, false});
    p.locks.push_back({cores, r.lockSync, 0, -1, false});
    for (int ch = 0; ch < 2; ch++)
        p.channels.push_back({cores, true, ch, r.coreBd[ch][0], 1, false});
    const int64_t lo = r.slotBase - T.coreOwnView;
    const std::pair<const char *, int64_t> scal[] = {{"SLOT_LO", lo},          {"SLOT_HI", lo + part},
                                                     {"SLOT_STRIDE", half},    {"SLOT_CH_STRIDE", 1},
                                                     {"SLOT_SLOT_STRIDE", 2},  {"PART_STRIDE", part},
                                                     {"LOCK_F", r.lockF},      {"LOCK_G", r.lockF + r.handDelta},
                                                     {"LOCK_E", r.lockE},      {"LOCK_HAND_DELTA", r.handDelta},
                                                     {"LOCK_CH_STRIDE", 1},    {"LOCK_E_SLOT_STRIDE", 2},
                                                     {"LOCK_SYNC", r.lockSync}};
    for (auto &[n, v] : scal)
        p.params.push_back({n, {v}, true, false});
}

// The kernel's view of the hosted streams, per shared operand o and mesh row: the host core's memory view
// (own / north / south), its lock-id bias and whether this row reads first.
bool deriveKernelParams(DataflowPlan &p, std::string &why) {
    const PlanTarget &T = planTarget();
    PlanKernelParam v{"VIEW", {}, false, true}, l{"LOCK", {}, false, true}, f{"FIRST", {}, false, true};
    int syncOperand = -1;
    for (size_t o = 0; o < p.shareArgs.size(); o++) {
        const PlanStream *s = nullptr;
        for (const auto &st : p.streams)
            if (st.arg == p.shareArgs[o])
                s = &st;
        if (!s) {
            why = "share_args has " + std::to_string(p.shareArgs[o]) + " but no plan_stream for it";
            return false;
        }
        if (s->role == "a")
            syncOperand = (int)o;
        for (int pm = 0; pm < p.meshRows; pm++) {
            const int g = s->role == "a" ? pm / 2 : pm % 2, host = s->hostRows[g];
            if (host < pm - 1 || host > pm + 1) {
                why = "mesh row " + std::to_string(pm) + " reads stream " + std::to_string(s->arg) + " hosted on row " +
                      std::to_string(host) + ", which is not a neighbour";
                return false;
            }
            v.perMeshRow.push_back(host == pm ? T.coreOwnView : host == pm + 1 ? T.coreNorthView : T.coreSouthView);
            l.perMeshRow.push_back(host == pm       ? T.coreOwnLockBias
                                   : host == pm + 1 ? T.coreNorthLockBias
                                                    : T.coreSouthLockBias);
            f.perMeshRow.push_back(s->firstRows[g] == pm);
        }
    }
    p.params.push_back(v);
    p.params.push_back(l);
    p.params.push_back(f);
    p.params.push_back({"OPERANDS", {(int64_t)p.shareArgs.size()}, true, false});
    p.params.push_back({"SYNC_OPERAND", {syncOperand}, true, false});
    p.params.push_back({"OWN_LOCK_BIAS", {T.coreOwnLockBias}, true, false});
    return true;
}

} // namespace

bool checkPlanLayout(const DataflowPlan &p, std::string &why) {
    const PlanStream *A = streamOfRole(p, "a"), *B = streamOfRole(p, "b");
    if (!A || !B) {
        why = "the plan needs one plan_stream of role \"a\" and one of role \"b\"";
        return false;
    }
    if (A->stage != "memtile_ring" || B->stage != "memtile" || A->ring <= 0) {
        why = "implemented: role a stage memtile_ring (ring > 0), role b stage memtile";
        return false;
    }
    // The neighbour-shared layout: core (pm, pn) reads A strip pm / 2 and B strip pn + C (pm % 2), so
    // each stream has 2 strip groups and the mesh has 2 x 2 rows.
    if (A->chunkRows != B->chunkRows || A->chunkCols != B->chunkCols || A->chunks != B->chunks ||
        A->rounds != B->rounds || A->hostRows.size() != 2 || B->hostRows.size() != 2 || A->firstRows.size() != 2 ||
        B->firstRows.size() != 2 || p.meshRows != 4 || A->chunks % 2) {
        why = "streams a / b must share chunk shape, chunks and rounds, with 2 strip groups each on 4 mesh rows "
              "(the neighbour-shared layout)";
        return false;
    }
    const int64_t chunk = chunkBytes(*A);
    if ((A->rounds * (int64_t)A->chunks / 2 * chunk) % (A->ring * 2 * chunk)) {
        why = "the A ring does not divide one strip's stream";
        return false;
    }
    for (const auto &r : p.routes)
        if (r.arg < 0) {
            why = "every plan_route names the stream it carries (arg = N)";
            return false;
        }
    const PlanTarget &T = planTarget();
    if (splitWords(chunk / 2 / T.bdWordBytes, T.coreBdMaxWrap).first == 0 ||
        splitWords(chunk / T.bdWordBytes, T.memBdMaxWrap).first == 0) {
        why = "a chunk does not split into two BD dimensions within the core / MemTile wrap limits";
        return false;
    }
    if (A->chunkCols / T.bdWordBytes > T.shimBdMaxWrap || A->chunkRows > T.shimBdMaxWrap ||
        A->chunks > T.shimBdMaxWrap) {
        why = "a chunk row / chunk count exceeds the shim BD wrap limit";
        return false;
    }
    return true;
}

bool deriveDmaProgram(DataflowPlan &p, std::string &why) {
    p.locks.clear(), p.bds.clear(), p.channels.clear(), p.shimBds.clear(), p.params.clear();
    if (!p.res.assigned) {
        why = "the plan's resources are not assigned (assignPlanResources)";
        return false;
    }
    if (!checkPlanLayout(p, why))
        return false;
    std::vector<Tile> cores;
    for (int c = 0; c < p.meshCols; c++)
        for (int pm = 0; pm < p.meshRows; pm++)
            cores.push_back({p.colLo + c, p.coreRowBase + pm});
    for (size_t si = 0; si < p.streams.size(); si++) {
        const PlanStream &s = p.streams[si];
        if (!(s.stage == "memtile_ring" ? deriveRing(p, si, why) : deriveResident(p, si, why)))
            return false;
        // shim: the column's part of the stream, contiguous in DDR in the order the MemTile takes it
        const int64_t chunk = chunkBytes(s);
        const bool ring = s.stage == "memtile_ring";
        const int64_t len = ring ? (int64_t)s.chunks / 2 * chunk : (int64_t)s.chunks * chunk;
        const int reps = ring ? s.rounds : (int)s.hostRows.size();
        for (int c = 0; c < p.meshCols; c++) {
            const PlanRoute *r = routesOf(p, s.arg, true, p.colLo + c)[0];
            p.shimBds.push_back({p.colLo + c, r->srcCh, p.res.shimBd[si][c], s.arg, true, c * reps * len, len,
                                 shimChunkDims(s, len / chunk), len, reps, reps, !ring && s.residentLaunches});
        }
    }
    deriveCoreSlots(p, *streamOfRole(p, "a"), cores);
    if (!deriveKernelParams(p, why))
        return false;
    p.persistentGoLock = p.persistent ? p.res.lockGo : -1;
    return true;
}

// ---------------------------------------------------------------- host module

namespace {

struct HostBuilder {
    OpBuilder &b;
    Location loc;
    std::map<Tile, Value> tiles;
    Value tile(Tile t) {
        auto it = tiles.find(t);
        if (it != tiles.end())
            return it->second;
        Value v = b.create<dfschedule::DeclareTileOp>(loc, dfschedule::TileType::get(b.getContext()),
                                                      b.getI32IntegerAttr(t.col), b.getI32IntegerAttr(t.row));
        return tiles[t] = v;
    }
    Value i32(int64_t v) { return b.create<arith::ConstantOp>(loc, b.getI32IntegerAttr((int32_t)v)); }
};

ArrayAttr dimsAttr(OpBuilder &b, const Dims &d, bool wraps, int64_t scale) {
    SmallVector<int32_t> v;
    for (auto &[step, wrap] : d)
        v.push_back((int32_t)(wraps ? wrap : step * scale));
    return b.getI32ArrayAttr(v);
}

bool isMem(const DataflowPlan &p, const Tile &t) { return t.row >= 1 && t.row <= p.memtileRows; }

void emitMemtileProgram(HostBuilder &h, const DataflowPlan &p) {
    OpBuilder &b = h.b;
    const PlanTarget &T = planTarget();
    const int W = T.bdWordBytes;
    for (const auto &l : p.locks)
        for (const auto &t : l.tiles)
            if (isMem(p, t)) {
                auto op = b.create<dfschedule::ConfigLockSetOp>(h.loc, h.tile(t), l.id, l.init, l.later);
                if (l.restored)
                    op.setRestored(true);
            }
    for (const auto &bd : p.bds)
        for (const auto &t : bd.tiles)
            if (isMem(p, t)) // a MemTile BD names its own locks with a bias (neighbourhood-relative ids)
                b.create<dfschedule::ConfigTileBdOp>(
                    h.loc, h.tile(t), bd.bd, bd.addr, (int32_t)bd.len, dimsAttr(b, bd.dims, false, W),
                    dimsAttr(b, bd.dims, true, 1), (int32_t)(bd.iterStep * W), (int32_t)bd.iterWrap,
                    bd.acqLock >= 0 ? T.memLockBdBias + bd.acqLock : -1, bd.acqVal,
                    bd.relLock >= 0 ? T.memLockBdBias + bd.relLock : -1, bd.relVal, bd.next);
    for (const auto &c : p.channels)
        for (const auto &t : c.tiles)
            if (isMem(p, t))
                b.create<dfschedule::ConfigChannelEnableOp>(h.loc, h.tile(t), c.ch, c.s2mm ? "S2MM" : "MM2S");
    for (const auto &c : p.channels)
        for (const auto &t : c.tiles)
            if (isMem(p, t))
                b.create<dfschedule::ConfigChannelStartOp>(h.loc, h.tile(t), c.ch, c.s2mm ? "S2MM" : "MM2S", c.startBd,
                                                           c.repeat, c.firstLaunchOnly);
}

void emitShimProgram(HostBuilder &h, const DataflowPlan &p, Block &host, SmallVector<Value> &events) {
    OpBuilder &b = h.b;
    MLIRContext *ctx = b.getContext();
    int flow = 1000;
    for (const auto &s : p.shimBds) {
        Value t = h.tile({s.col, 0});
        OperationState st(h.loc, dfschedule::ConfigDmaBdOp::getOperationName());
        st.addOperands({host.getArgument(s.arg), t, h.i32(s.bd), h.i32(s.offset), h.i32(0), h.i32(-1)});
        st.addAttribute("len", b.getI32IntegerAttr((int32_t)s.len));
        st.addAttribute("enable_packet", b.getBoolAttr(false));
        st.addAttribute("next_bd", b.getI32IntegerAttr(-1));
        st.addAttribute("dim_strides", dimsAttr(b, s.dims, false, 1));
        st.addAttribute("dim_wraps", dimsAttr(b, s.dims, true, 1));
        st.addAttribute("iter_step_size", b.getI32IntegerAttr((int32_t)s.iterStep));
        st.addAttribute("iter_wrap", b.getI32IntegerAttr((int32_t)s.iterWrap));
        st.addTypes(dfschedule::BdHandleType::get(ctx));
        Value bd = b.create(st)->getResult(0);
        Value io = b.create<dfschedule::ConfigCreateIoOp>(h.loc, dfschedule::IoHandleType::get(ctx), bd, t,
                                                          b.getI32IntegerAttr(s.ch), b.getStringAttr("MM2S"),
                                                          b.getStringAttr("SEND"), b.getBoolAttr(false));
        auto start = b.create<dfschedule::StartIoOp>(h.loc, dfschedule::EventType::get(ctx), io, h.i32(s.bd),
                                                     b.getI32IntegerAttr(flow++), b.getI32IntegerAttr(s.repeat));
        if (s.firstLaunchOnly)
            start->setAttr("dfschedule.first_launch_only", b.getUnitAttr());
        events.push_back(start.getResult());
    }
}

} // namespace

bool materializeHostPlan(ModuleOp hostModule, DataflowPlan &p) {
    if (!p.present)
        return true;
    // ids and addresses against the generated flows (before the plan's own ops exist), then the program
    std::string why;
    if (!assignPlanResources(hostModule, p, why) || !deriveDmaProgram(p, why)) {
        llvm::errs() << "[DataflowPlan] ERROR: " << why << "\n";
        return false;
    }
    dfschedule::HostBlockOp hostOp;
    hostModule.walk([&](dfschedule::HostBlockOp h) { hostOp = h; });
    if (!hostOp || hostOp.getBody().empty()) {
        llvm::errs() << "[DataflowPlan] ERROR: no dfschedule.host block to put the plan's DMA program in\n";
        return false;
    }
    Block &host = hostOp.getBody().front();
    Operation *launch = nullptr, *lastWait = nullptr;
    for (Operation &op : host) {
        if (isa<dfschedule::LaunchKernelGroupOp>(op))
            launch = &op;
        if (isa<dfschedule::ScheduleWaitOp>(op))
            lastWait = &op;
    }
    if (!launch || !lastWait) {
        llvm::errs() << "[DataflowPlan] ERROR: the host schedule has no kernel launch / final wait\n";
        return false;
    }
    for (const auto &s : p.shimBds)
        if (s.arg >= (int)host.getNumArguments()) {
            llvm::errs() << "[DataflowPlan] ERROR: shim transfer over arg " << s.arg << ", the host block has "
                         << host.getNumArguments() << " arguments\n";
            return false;
        }
    OpBuilder b(launch->getContext());
    b.setInsertionPointAfter(launch);
    HostBuilder h{b, launch->getLoc(), {}};
    emitMemtileProgram(h, p);
    SmallVector<Value> events;
    emitShimProgram(h, p, host, events);
    b.setInsertionPoint(lastWait);
    b.create<dfschedule::ScheduleWaitOp>(lastWait->getLoc(), events);
    hostModule->setAttr("dfschedule.plan_bd_once", b.getI64IntegerAttr(p.bdOnce ? 1 : 0));
    hostModule->setAttr("dfschedule.plan_go_lock", b.getI64IntegerAttr(p.persistentGoLock));
    llvm::outs() << "[DataflowPlan] host dfschedule: MemTile + shim DMA program after the kernel launch ("
                 << p.shimBds.size() << " shim transfers)\n";
    return true;
}

// ---------------------------------------------------------------- kernel module

bool materializeKernelPlan(ModuleOp kernelModule, const DataflowPlan &p) {
    if (!p.present)
        return true;
    if (!p.res.assigned) {
        llvm::errs() << "[DataflowPlan] ERROR: the kernel module's plan needs the resources the host module "
                        "assigned (materializeHostPlan first)\n";
        return false;
    }
    dfschedule::KernelModuleOp km;
    kernelModule.walk([&](dfschedule::KernelModuleOp k) { km = k; });
    if (!km || km.getBody().empty()) {
        llvm::errs() << "[DataflowPlan] ERROR: no dfschedule.module (kernel) to put the cores' DMA program in\n";
        return false;
    }
    std::set<Tile> cores;
    for (const auto &bd : p.bds)
        for (auto &t : bd.tiles)
            if (!isMem(p, t))
                cores.insert(t);
    OpBuilder b(km.getContext());
    b.setInsertionPointToStart(&km.getBody().front());
    Location loc = km.getLoc();
    Value self = b.create<dfschedule::DeclareTileSelfOp>(loc, dfschedule::TileType::get(b.getContext()));
    std::map<Tile, Value> named;
    // tiles == every core -> declaretile.self (one ELF, every core runs it); else one op per tile
    auto forTiles = [&](const std::vector<Tile> &tiles, auto emit) {
        std::set<Tile> ts;
        for (auto &t : tiles)
            if (!isMem(p, t))
                ts.insert(t);
        if (ts.empty())
            return;
        if (ts == cores)
            return emit(self);
        for (auto &t : ts) {
            if (!named.count(t))
                named[t] = b.create<dfschedule::DeclareTileOp>(loc, dfschedule::TileType::get(b.getContext()),
                                                               b.getI32IntegerAttr(t.col), b.getI32IntegerAttr(t.row));
            emit(named[t]);
        }
    };
    for (const auto &bd : p.bds)
        forTiles(bd.tiles, [&](Value t) {
            const int W = planTarget().bdWordBytes;
            b.create<dfschedule::ConfigTileBdOp>(loc, t, bd.bd, bd.addr, (int32_t)bd.len,
                                                 dimsAttr(b, bd.dims, false, W), dimsAttr(b, bd.dims, true, 1),
                                                 (int32_t)(bd.iterStep * W), (int32_t)bd.iterWrap, bd.acqLock,
                                                 bd.acqVal, bd.relLock, bd.relVal, bd.next);
        });
    for (const auto &l : p.locks)
        forTiles(l.tiles, [&](Value t) { b.create<dfschedule::ConfigLockSetOp>(loc, t, l.id, l.init, -1); });
    for (const auto &c : p.channels)
        forTiles(c.tiles, [&](Value t) {
            b.create<dfschedule::ConfigChannelStartOp>(loc, t, c.ch, c.s2mm ? "S2MM" : "MM2S", c.startBd, c.repeat,
                                                       false);
        });
    kernelModule->setAttr("dfschedule.plan_go_lock", b.getI64IntegerAttr(p.persistentGoLock));
    llvm::outs() << "[DataflowPlan] kernel dfschedule: cores' DMA program on declaretile.self\n";
    return true;
}

// Kernel path: the plan ops of a kernel module -> the core's own MMIO (aie_kernel_runtime.h), run once
// at kernel start. Byte strides back to the BD's 32-bit-word steps. Erases the ops.
std::string lowerKernelPlanOps(Operation *km, int partStartCol) {
    std::ostringstream os;
    SmallVector<Operation *> erase;
    auto cond = [&](Value t) -> std::string {
        if (auto d = t.getDefiningOp<dfschedule::DeclareTileOp>())
            return "(_pcol == " + std::to_string(d.getCol()) + " && _prow == " + std::to_string(d.getRow()) + ")";
        return ""; // declaretile.self: every core
    };
    auto open = [&](Value t) {
        std::string c = cond(t);
        os << (c.empty() ? "  {\n" : "  if " + c + " {\n");
    };
    auto I = [](uint32_t v) { return (int32_t)v; }; // I32Attr getters are unsigned; -1 = "none"
    km->walk([&](Operation *op) {
        auto w = [](ArrayAttr a, size_t i) -> int64_t {
            return a && i < a.size() ? (int64_t)cast<IntegerAttr>(a[i]).getInt() : 0;
        };
        if (auto bd = dyn_cast<dfschedule::ConfigTileBdOp>(op)) {
            open(bd.getTile());
            ArrayAttr s = bd.getDimStrides(), r = bd.getDimWraps();
            const int W = planTarget().bdWordBytes;
            os << "    const AieKcDims _d = {" << w(s, 0) / W << ", " << w(r, 0) << ", " << w(s, 1) / W << ", "
               << w(r, 1) << ", " << w(s, 2) / W << ", " << I(bd.getIterStepSize()) / W << ", " << I(bd.getIterWrap())
               << "};\n"
               << "    _n = aie_kc_encode_bd_nd(_kc, " << I(bd.getBdId()) << ", (uintptr_t)0x" << std::hex
               << bd.getAddr() << std::dec << ", " << I(bd.getLen()) << ", " << I(bd.getNextBd()) << ", "
               << I(bd.getAcquireLockId()) << ", " << I(bd.getAcquireLockVal()) << ", " << I(bd.getReleaseLockId())
               << ", " << I(bd.getReleaseLockVal())
               << ", 0, 0, 0, -1, &_d);\n    core_reg_write_block(_kc, _n);\n  }\n";
        } else if (auto l = dyn_cast<dfschedule::ConfigLockSetOp>(op)) {
            open(l.getTile());
            os << "    aie_kc_encode_lock(_kc, " << I(l.getLockId()) << ", " << I(l.getValue())
               << ");\n    core_reg_write(_kc[0].off, _kc[0].val);\n  }\n";
        } else if (auto c = dyn_cast<dfschedule::ConfigChannelStartOp>(op)) {
            open(c.getTile());
            os << "    aie_kc_encode_" << (c.getDirection() == "S2MM" ? "s2mm" : "mm2s") << "_start(_kc, "
               << I(c.getChannel()) << ", " << I(c.getStartBd()) << ", " << I(c.getRepeatCount())
               << ", 0);\n    core_reg_write(_kc[0].off, _kc[0].val);\n  }\n";
        } else {
            return;
        }
        erase.push_back(op);
    });
    if (erase.empty())
        return "";
    std::set<Operation *> tileDefs;
    for (Operation *op : erase)
        if (Operation *d = op->getOperand(0).getDefiningOp())
            tileDefs.insert(d);
    for (Operation *op : erase)
        op->erase();
    for (Operation *d : tileDefs)
        if (d->use_empty())
            d->erase();
    std::ostringstream out;
    out << "{ // DATAFLOW PLAN core-tile DMA (dfschedule.config.tile_bd / lock_set / channel_start), generated\n"
        << "  AieKcReg _kc[8];\n  int _n;\n"
        << "  const unsigned _pcid = get_coreid();\n"
        << "  const int _pcol = (int)(_pcid >> 16) - " << partStartCol << ", _prow = (int)(_pcid & 0x1F);\n"
        << "  (void)_pcol; (void)_prow; (void)_n;\n"
        << os.str();
    out << "}\n";
    return out.str();
}

} // namespace dfplan
