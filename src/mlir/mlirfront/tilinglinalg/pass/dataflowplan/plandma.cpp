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

MemtileUse memtileUse(const DataflowPlan &p, const PlanStream &s, int col) {
    MemtileUse u;
    auto in = routesOf(p, s.arg, true, col);
    if (in.size() != 1 || in[0]->dsts.size() != 1)
        return u;
    u.shimRoute = in[0];
    u.mt = in[0]->dsts[0].first;
    u.s2mm = in[0]->dsts[0].second;
    for (const PlanRoute *r : routesOf(p, s.arg, false, u.mt.col))
        if (r->src == u.mt && !r->dsts.empty())
            u.out.push_back(r);
    const int64_t chunk = s.chunkBytes();
    if (s.stage == "memtile_ring") {
        for (const PlanRoute *r : u.out)
            u.parities.push_back(r->dsts[0].second - s.channel);
        const int k = (int)u.parities.size();
        u.chunksPerTile = (int64_t)s.chunks * k / s.channels;
        if (k == 1) { // one parity: buffers of 2 chunks, one chain each way
            u.s2mmBds = s.ring, u.mm2sBds = {s.ring}, u.locks = 2, u.bytes = (int64_t)s.ring * 2 * chunk;
        } else { // k parities: per parity `ring` one-chunk buffers and an (empty, full) lock pair
            u.s2mmBds = s.ring * k, u.mm2sBds.assign(k, s.ring), u.locks = 2 * k;
            u.bytes = (int64_t)s.ring * k * chunk;
        }
    } else {
        u.chunksPerTile = s.chunks;
        u.bytes = (int64_t)s.hostRows.size() * s.chunks * chunk;
        // held whole: one S2MM load, a chain of as many BDs as the MemTile BD length field needs
        const int64_t maxBd = planTarget().memBdMaxLenWords * planTarget().bdWordBytes;
        u.s2mmBds = (int)((u.bytes + maxBd - 1) / maxBd), u.mm2sBds.assign(u.out.size(), 1), u.locks = 2;
    }
    u.present = !u.out.empty();
    return u;
}

namespace {

// Role tag of a MemTile op of stream si, column c: "mem/<si>/<c>/<what>/<i>[/<j>]" (dfplan.tag).
std::string mtag(size_t si, int c, const char *what, int i, int j = -1) {
    std::string t = "mem/" + std::to_string(si) + "/" + std::to_string(c) + "/" + what + "/" + std::to_string(i);
    return j >= 0 ? t + "/" + std::to_string(j) : t;
}

// A contiguous run of `words` 32-bit words as two BD dimensions {1, in} {in, out} (in * out = words),
// both wraps within the tile kind's limit (maxW); {0, 0} when it cannot be split.
std::pair<int64_t, int64_t> splitWords(int64_t words, int64_t maxW) {
    for (int64_t in = std::min(words, maxW); in >= 1; in--)
        if (words % in == 0 && words / in <= maxW)
            return {in, words / in};
    return {0, 0};
}

// The chunk stream a shim BD reads from DDR, chunk by chunk (bytes): rows of chunkCols elements,
// chunkRows rows, then n chunks. The host lays the stream out contiguously in this order
// (aiehlc_plan_arrange in aiehlc_plan.h).
Dims shimChunkDims(const PlanStream &s, int64_t n) {
    const int w = planTarget().bdWordBytes;
    const int64_t row = (int64_t)s.chunkCols * s.elemBytes;
    return {{w, row / w}, {row, s.chunkRows}, {s.chunkBytes(), n}};
}

// MemTile side of a memtile_ring stream, per column: the shim's chunks enter a FIFO ring and leave on
// the MemTile's MM2S routes. One served parity: `ring` buffers of 2 chunks, counting locks (empty, full).
// Several: chunks alternate parities, so the S2MM chain alternates per-parity (empty, full) lock pairs over
// one-chunk buffers and every MM2S route walks its parity's buffers.
void deriveRing(DataflowPlan &p, size_t si) {
    const PlanStream &A = p.streams[si];
    const int64_t chunk = A.chunkBytes();
    for (int c = 0; c < p.meshCols; c++) {
        const MemtileUse u = memtileUse(p, A, p.colLo + c);
        if (!u.present)
            continue;
        const PlanResources::Mem &m = p.res.mem[si][c];
        const std::vector<Tile> t{u.mt};
        const int ring = A.ring, k = (int)u.parities.size();
        for (int j = 0; j < k; j++) {
            p.locks.push_back({t, m.locks[2 * j], ring, -1, false, true});
            p.locks.back().tag = mtag(si, c, "lock", 2 * j);
            p.locks.push_back({t, m.locks[2 * j + 1], 0, -1, false, true});
            p.locks.back().tag = mtag(si, c, "lock", 2 * j + 1);
        }
        if (k == 1) {
            const int rounds = (int)(A.rounds * u.chunksPerTile / (2 * ring));
            for (int b = 0; b < ring; b++) {
                const bool last = b == ring - 1;
                const int64_t addr = m.addr + b * 2 * chunk;
                p.bds.push_back({t,
                                 m.bdIn + b,
                                 addr,
                                 2 * chunk,
                                 {},
                                 0,
                                 0,
                                 m.locks[0],
                                 -1,
                                 m.locks[1],
                                 1,
                                 last ? -1 : m.bdIn + b + 1});
                p.bds.back().tag = mtag(si, c, "in", b);
                p.bds.push_back({t,
                                 m.bdOut[0] + b,
                                 addr,
                                 2 * chunk,
                                 {},
                                 0,
                                 0,
                                 m.locks[1],
                                 -1,
                                 m.locks[0],
                                 1,
                                 last ? -1 : m.bdOut[0] + b + 1});
                p.bds.back().tag = mtag(si, c, "out", 0, b);
            }
            p.channels.push_back({t, true, u.s2mm, m.bdIn, rounds, false});
            p.channels.back().tag = mtag(si, c, "ch_in", 0);
            p.channels.push_back({t, false, u.out[0]->srcCh, m.bdOut[0], rounds, false});
            p.channels.back().tag = mtag(si, c, "ch_out", 0);
            continue;
        }
        for (int i = 0; i < ring * k; i++) { // buffer i: chunk parity j = i % k
            const int j = i % k;
            p.bds.push_back({t,
                             m.bdIn + i,
                             m.addr + i * chunk,
                             chunk,
                             {},
                             0,
                             0,
                             m.locks[2 * j],
                             -1,
                             m.locks[2 * j + 1],
                             1,
                             i + 1 < ring * k ? m.bdIn + i + 1 : -1});
            p.bds.back().tag = mtag(si, c, "in", i);
        }
        p.channels.push_back({t, true, u.s2mm, m.bdIn, (int)(A.rounds * u.chunksPerTile / (ring * k)), false});
        p.channels.back().tag = mtag(si, c, "ch_in", 0);
        for (int j = 0; j < k; j++) {
            for (int b = 0; b < ring; b++) {
                p.bds.push_back({t,
                                 m.bdOut[j] + b,
                                 m.addr + (b * k + j) * chunk,
                                 chunk,
                                 {},
                                 0,
                                 0,
                                 m.locks[2 * j + 1],
                                 -1,
                                 m.locks[2 * j],
                                 1,
                                 b + 1 < ring ? m.bdOut[j] + b + 1 : -1});
                p.bds.back().tag = mtag(si, c, "out", j, b);
            }
            p.channels.push_back(
                {t, false, u.out[j]->srcCh, m.bdOut[j], (int)(A.rounds * u.chunksPerTile / k / ring), false});
            p.channels.back().tag = mtag(si, c, "ch_out", j);
        }
    }
}

// MemTile side of a memtile (resident) stream, per column: the column's strips held whole (one S2MM load,
// on the first launch only when resident across launches; locks ready, free), replayed by one MM2S BD per
// route -- the route's destination says which strip group (its host row) and which chunk parity (its
// S2MM channel); a replay takes every `channels`-th chunk.
bool deriveResident(DataflowPlan &p, size_t si, std::string &why) {
    const PlanStream &B = p.streams[si];
    const PlanTarget &T = planTarget();
    const int64_t chunk = B.chunkBytes(), bLen = (int64_t)B.chunks * chunk, groups = B.hostRows.size();
    const bool keep = B.residentLaunches;
    const auto [in, out] = splitWords(chunk / T.bdWordBytes, T.memBdMaxWrap);
    const int64_t chunkW = chunk / T.bdWordBytes;
    for (int c = 0; c < p.meshCols; c++) {
        const MemtileUse u = memtileUse(p, B, p.colLo + c);
        if (!u.present)
            continue;
        const PlanResources::Mem &m = p.res.mem[si][c];
        const std::vector<Tile> t{u.mt};
        const int replays = (int)u.out.size();
        // Only a kept B hands its locks back balanced (full: `replays` ready, 0 free). Per launch, the
        // replays acquire and release lock 0 and nothing returns lock 1 -- launch 0 ends at (replays, 0),
        // so the next S2MM would wait on lock 1 forever: write both every launch (`restored` = false).
        p.locks.push_back({t, m.locks[0], 0, keep ? replays : -1, false, keep});
        p.locks.back().tag = mtag(si, c, "lock", 0);
        p.locks.push_back({t, m.locks[1], 1, keep ? 0 : -1, false, keep});
        p.locks.back().tag = mtag(si, c, "lock", 1);
        // the load: u.s2mmBds chained BDs (the first takes the free lock, the last releases the replays)
        const int64_t total = groups * bLen, nIn = u.s2mmBds;
        const int64_t piece = (total / nIn + T.bdWordBytes - 1) / T.bdWordBytes * T.bdWordBytes;
        for (int64_t i = 0, off = 0; i < nIn; i++, off += piece) {
            const bool first = i == 0, last = i == nIn - 1;
            p.bds.push_back({t,
                             m.bdIn + (int)i,
                             m.addr + off,
                             last ? total - off : piece,
                             {},
                             0,
                             0,
                             first ? m.locks[1] : -1,
                             first ? -1 : 0,
                             last ? m.locks[0] : -1,
                             last ? replays : 0,
                             last ? -1 : m.bdIn + (int)i + 1});
            p.bds.back().tag = mtag(si, c, "in", (int)i);
        }
        p.channels.push_back({t, true, u.s2mm, m.bdIn, 1, keep});
        p.channels.back().tag = mtag(si, c, "ch_in", 0);
        for (size_t k = 0; k < u.out.size(); k++) {
            const PlanRoute *r = u.out[k];
            const int g = B.groupOfHostRow(r->dsts[0].first.row - p.coreRowBase), q = r->dsts[0].second - B.channel;
            if ((r->dsts.size() != 1 && B.share == "neighbor") || g < 0 || q >= B.channels) {
                why = "stream " + std::to_string(B.arg) +
                      ": a replay route must end on one core hosting a strip, "
                      "on a channel below `channels`";
                return false;
            }
            Dims d = {{1, in}, {in, out}, {B.channels * chunkW, B.chunks / B.channels}};
            p.bds.push_back({t, m.bdOut[k], m.addr + g * bLen + q * chunk, bLen / B.channels, d, 0, 0, m.locks[0], -1,
                             m.locks[0], 1, -1});
            p.bds.back().tag = mtag(si, c, "out", (int)k, 0);
            p.channels.push_back({t, false, r->srcCh, m.bdOut[k], B.rounds, false});
            p.channels.back().tag = mtag(si, c, "ch_out", (int)k);
        }
    }
    return true;
}

// Per-core copies: stream si on S2MM channel s.channel, its `slots` buffers of one chunk in a chain (BD k:
// E + k acquired, F released by one), parts PART_STRIDE apart -- and the kernel's per-operand constants.
void deriveCopySlots(DataflowPlan &p, const std::vector<Tile> &cores) {
    const PlanResources &r = p.res;
    const PlanTarget &T = planTarget();
    PlanKernelParam pf{"OP_F", {}, false, true}, pe{"OP_E", {}, false, true}, plo{"OP_SLOT_LO", {}, false, true},
        pst{"OP_SLOT_STRIDE", {}, false, true}, ppt{"OP_PART_STRIDE", {}, false, true},
        psl{"OP_SLOTS", {}, false, true};
    for (size_t o = 0; o < p.shareArgs.size(); o++) {
        size_t si = 0;
        while (si < p.streams.size() && p.streams[si].arg != p.shareArgs[o])
            si++;
        const PlanStream &s = p.streams[si];
        // slot k at base + k * slotStride (the aligned chunk); part i of a slot PART_STRIDE further (parts > 1:
        // slotStride == part x parts... = the chunk, so parts interleave the slots as in the hosted streams)
        const int64_t chunk = s.chunkBytes(), part = chunk / s.parts,
                      slotStride = s.parts > 1 ? part : r.copySlotStride[si], stride = (int64_t)s.slots * slotStride;
        const auto [in, out] = splitWords(part / T.bdWordBytes, T.coreBdMaxWrap);
        for (int k = 0; k < s.slots; k++) {
            Dims d = {{1, in}, {in, out}, {stride / T.bdWordBytes, 0}};
            p.bds.push_back({cores, r.copyBd[si] + k, r.copySlotBase[si] + k * slotStride, chunk, d, 0, 0,
                             r.copyE[si] + k, -1, r.copyF[si], 1, r.copyBd[si] + (k + 1) % s.slots});
            p.bds.back().tag = "copy/" + std::to_string(si) + "/bd/" + std::to_string(k);
            p.locks.push_back({cores, r.copyE[si] + k, 1, -1, false});
            p.locks.back().tag = "copy/" + std::to_string(si) + "/E/" + std::to_string(k);
        }
        p.locks.push_back({cores, r.copyF[si], 0, -1, false});
        p.locks.back().tag = "copy/" + std::to_string(si) + "/F";
        p.channels.push_back({cores, true, s.channel, r.copyBd[si], 1, false});
        p.channels.back().tag = "copy/" + std::to_string(si) + "/ch";
        for (int pm = 0; pm < p.meshRows; pm++) {
            pf.perMeshRow.push_back(r.copyF[si]), pe.perMeshRow.push_back(r.copyE[si]);
            plo.perMeshRow.push_back(r.copySlotBase[si] - T.coreOwnView), pst.perMeshRow.push_back(slotStride);
            ppt.perMeshRow.push_back(stride), psl.perMeshRow.push_back(s.slots);
        }
    }
    if (p.persistent) {
        p.locks.push_back({cores, r.lockGo, 1, -1, false});
        p.locks.back().tag = "core/go";
    }
    for (PlanKernelParam *k : {&pf, &pe, &plo, &pst, &ppt, &psl})
        p.params.push_back(*k);
    p.params.push_back({"COPY", {1}, true, false});
    p.params.push_back({"READERS", {1}, true, false});
}

// Every core hosts at most one stream: per S2MM channel `slots` buffers, each chunk in `parts` row parts
// PART_STRIDE apart (different memory banks). Buffer index = channel + channels x slot = chunk g mod
// buffers. Locks (res): per channel a reader lock per reader + the no-op row, handDelta (= channels)
// apart; E per buffer (all readers -> DMA, acquired by `readers`).
void deriveCoreSlots(DataflowPlan &p, const PlanStream &s, const std::vector<Tile> &cores) {
    const PlanResources &r = p.res;
    const PlanTarget &T = planTarget();
    const int64_t chunk = s.chunkBytes(), part = chunk / s.parts, stride = (int64_t)s.buffers() * part;
    const auto [in, out] = splitWords(part / T.bdWordBytes, T.coreBdMaxWrap);
    for (int ch = 0; ch < s.channels; ch++)
        for (int k = 0; k < s.slots; k++) {
            const int buf = ch + s.channels * k;
            Dims d = {{1, in}, {in, out}, {stride / T.bdWordBytes, 0}}; // part 0, then the next part a stride on
            p.bds.push_back({cores, r.coreBd[ch] + k, r.slotBase + buf * part, chunk, d, 0, 0, r.lockE + buf,
                             -s.readers, r.lockF + ch, 1, r.coreBd[ch] + (k + 1) % s.slots});
            p.bds.back().tag = "core/bd/" + std::to_string(ch) + "/" + std::to_string(k);
        }
    for (int b = 0; b < s.buffers(); b++) {
        p.locks.push_back({cores, r.lockE + b, s.readers, -1, false});
        p.locks.back().tag = "core/E/" + std::to_string(b);
    }
    for (int i = 0; i <= s.readers; i++) // reader locks + the no-op row
        for (int ch = 0; ch < s.channels; ch++) {
            p.locks.push_back({cores, r.lockF + i * r.handDelta + ch, 0, -1, false});
            p.locks.back().tag = "core/R/" + std::to_string(i) + "/" + std::to_string(ch);
        }
    if (p.persistent) {
        p.locks.push_back({cores, r.lockGo, 1, -1, false});
        p.locks.back().tag = "core/go";
    }
    p.locks.push_back({cores, r.lockSync, 0, -1, false});
    p.locks.back().tag = "core/sync";
    for (int ch = 0; ch < s.channels; ch++) {
        p.channels.push_back({cores, true, ch, r.coreBd[ch], 1, false});
        p.channels.back().tag = "core/ch/" + std::to_string(ch);
    }
    const std::pair<const char *, int64_t> scal[] = {{"SLOT_LO", r.slotBase - T.coreOwnView},
                                                     {"SLOT_STRIDE", part},
                                                     {"PART_STRIDE", stride},
                                                     {"CHANNELS", s.channels},
                                                     {"SLOTS", s.slots},
                                                     {"BUFFERS", s.buffers()},
                                                     {"READERS", s.readers},
                                                     {"LOCK_F", r.lockF},
                                                     {"LOCK_E", r.lockE},
                                                     {"LOCK_HAND_DELTA", r.handDelta},
                                                     {"LOCK_SYNC", r.lockSync}};
    for (auto &[n, v] : scal)
        p.params.push_back({n, {v}, true, false});
    if (r.accBytes > 0) { // the kernel's K accumulator: ACC when the plan holds it (core address), else its own
        p.params.push_back({"ACC_BYTES", {r.accBytes}, true, false});
        p.params.push_back({"DM_FREE", {r.dmFree}, true, false});
        if (r.accAddr >= 0)
            p.params.push_back({"ACC", {r.accAddr}, true, false});
    }
}

// Reader order of strip group g of a stream: its first row, then the group's other rows ascending.
std::vector<int> readersOf(const PlanStream &s, int g) {
    std::vector<int> rows{s.firstRows[g]};
    for (size_t pm = 0; pm < s.rowGroups.size(); pm++)
        if (s.rowGroups[pm] == g && (int)pm != s.firstRows[g])
            rows.push_back((int)pm);
    return rows;
}

// The kernel's view of the hosted streams, per shared operand o and mesh row: the host core's memory view
// (own / north / south), its lock-id bias and the row's reader index.
bool deriveKernelParams(DataflowPlan &p, std::string &why) {
    const PlanTarget &T = planTarget();
    PlanKernelParam v{"VIEW", {}, false, true}, l{"LOCK", {}, false, true}, rd{"READER", {}, false, true};
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
        if (s->stage == "memtile_ring" && syncOperand < 0)
            syncOperand = (int)o;
        for (int pm = 0; pm < p.meshRows; pm++) {
            const int g = s->rowGroups[pm], host = s->share == "neighbor" ? s->hostRows[g] : pm; // a copy: its own
            if (host < pm - 1 || host > pm + 1) {
                why = "mesh row " + std::to_string(pm) + " reads stream " + std::to_string(s->arg) + " hosted on row " +
                      std::to_string(host) + ", which is not a neighbour";
                return false;
            }
            v.perMeshRow.push_back(host == pm ? T.coreOwnView : host == pm + 1 ? T.coreNorthView : T.coreSouthView);
            l.perMeshRow.push_back(host == pm       ? T.coreOwnLockBias
                                   : host == pm + 1 ? T.coreNorthLockBias
                                                    : T.coreSouthLockBias);
            const std::vector<int> order = readersOf(*s, g);
            rd.perMeshRow.push_back(s->share == "neighbor" ? std::find(order.begin(), order.end(), pm) - order.begin()
                                                           : 0);
        }
    }
    p.params.push_back(v);
    p.params.push_back(l);
    p.params.push_back(rd);
    p.params.push_back({"OPERANDS", {(int64_t)p.shareArgs.size()}, true, false});
    p.params.push_back({"SYNC_OPERAND", {syncOperand}, true, false});
    p.params.push_back({"OWN_LOCK_BIAS", {T.coreOwnLockBias}, true, false});
    return true;
}

std::string str(int v) { return std::to_string(v); }

bool checkStream(const DataflowPlan &p, const PlanStream &s, std::string &why) {
    const PlanTarget &T = planTarget();
    const std::string S = "stream " + str(s.arg) + ": ";
    const size_t groups = s.hostRows.size();
    if (s.stage != "memtile_ring" && s.stage != "memtile") {
        why = S + "implemented stages: memtile_ring, memtile";
        return false;
    }
    if (s.stage == "memtile_ring" && s.ring <= 0) {
        why = S + "stage memtile_ring needs ring > 0";
        return false;
    }
    if ((int)s.rowGroups.size() != p.meshRows || s.firstRows.size() != groups || groups == 0 ||
        s.strips.size() != groups * p.meshCols) {
        why = S + "row_groups needs one entry per mesh row, host_rows / first_rows one per strip group, strips one "
                  "per column and group";
        return false;
    }
    for (size_t g = 0; g < groups && s.share == "neighbor"; g++)
        if ((int)readersOf(s, (int)g).size() != s.readers) {
            why = S + "strip group " + str((int)g) + " has " + str((int)readersOf(s, (int)g).size()) +
                  " reader rows, the stream says readers = " + str(s.readers);
            return false;
        }
    if (s.channels > T.coreS2mmChannels || s.chunks % s.channels || s.chunkBytes() % (s.parts * T.bdWordBytes)) {
        why = S + "channels must fit the core's S2MM channels and divide the chunks; parts must divide a chunk";
        return false;
    }
    if (splitWords(s.chunkBytes() / s.parts / T.bdWordBytes, T.coreBdMaxWrap).first == 0 ||
        splitWords(s.chunkBytes() / T.bdWordBytes, T.memBdMaxWrap).first == 0 ||
        (int64_t)s.chunkCols * s.elemBytes / T.bdWordBytes > T.shimBdMaxWrap || s.chunkRows > T.shimBdMaxWrap) {
        why = S + "a chunk does not fit the core / MemTile / shim BD wrap limits";
        return false;
    }
    // a ring serves each (tensor strip, parity) stream once: count the distinct ones over the columns
    std::set<std::pair<int, int>> served;
    for (int c = 0; c < p.meshCols; c++) {
        const MemtileUse u = memtileUse(p, s, p.colLo + c);
        if (!u.present)
            continue;
        if (u.mt.row < 1 || u.mt.row > p.memtileRows) {
            why = S + "its shim route must end on a MemTile";
            return false;
        }
        if (s.stage == "memtile_ring") {
            const int k = (int)u.parities.size();
            for (const PlanRoute *r : u.out) {
                const int g = s.groupOfHostRow(r->dsts[0].first.row - p.coreRowBase);
                if (g < 0) {
                    why = S + "a ring route of column " + str(c) + " does not end on a strip's host row";
                    return false;
                }
                served.insert({s.strips[c * groups + g], r->dsts[0].second - s.channel});
            }
            const int64_t perTile = u.chunksPerTile;
            if (k == 1 ? (s.rounds * perTile) % (2 * s.ring) : (s.rounds * perTile) % (s.ring * k)) {
                why = S + "the ring does not divide column " + str(c) + "'s chunk stream";
                return false;
            }
        } else if ((int)u.out.size() != (int)groups * s.channels) {
            why = S + "MemTile of column " + str(c) + " needs one replay route per strip group and channel";
            return false;
        }
    }
    if (s.stage == "memtile_ring") {
        const std::set<int> strips(s.strips.begin(), s.strips.end());
        if (served.size() != strips.size() * s.channels) {
            why = S + "the MemTile rings serve " + str((int)served.size()) +
                  " (strip, parity) streams, the layout needs " + str((int)(strips.size() * s.channels));
            return false;
        }
    }
    return true;
}

} // namespace

bool checkPlanLayout(const DataflowPlan &p, std::string &why) {
    if (p.streams.empty()) {
        why = "the plan has no plan_stream";
        return false;
    }
    for (const auto &r : p.routes)
        if (r.arg < 0) {
            why = "every plan_route names the stream it carries (arg = N)";
            return false;
        }
    const PlanStream &s0 = p.streams[0];
    std::set<int> hosts, copyChannels;
    const bool copy = p.copyPlan();
    if (!copy &&
        std::any_of(p.streams.begin(), p.streams.end(), [](const PlanStream &s) { return s.share != "neighbor"; })) {
        why = "a plan's streams are all neighbour-hosted or all per-core copies (broadcast), not a mix";
        return false;
    }
    if (copy && (int)p.streams.size() > planTarget().coreS2mmChannels) {
        why = str((int)p.streams.size()) + " per-core copy streams: a core has " + str(planTarget().coreS2mmChannels) +
              " S2MM channels, one per stream";
        return false;
    }
    for (const auto &s : p.streams) {
        if (!checkStream(p, s, why))
            return false;
        // one kernel ELF: every core runs the same hosted-stream program (copies: one program per operand)
        if (!copy &&
            (s.chunkBytes() != s0.chunkBytes() || s.channels != s0.channels || s.slots != s0.slots ||
             s.readers != s0.readers || s.parts != s0.parts || s.chunks != s0.chunks || s.rounds != s0.rounds)) {
            why = "the shared streams must agree on chunk bytes, chunks, rounds, channels, slots, readers and parts "
                  "(every core runs the same program)";
            return false;
        }
        if (copy) { // every core holds every stream: one channel each, operand o on channel o
            if (s.channels != 1 || s.readers != 1 || !copyChannels.insert(s.channel).second ||
                s.channel >= (int)p.streams.size()) {
                why = "stream " + str(s.arg) + ": a per-core copy stream takes 1 channel and 1 reader, its own " +
                      "core channel (0 .. streams - 1)";
                return false;
            }
            continue;
        }
        for (int h : s.hostRows)
            if (!hosts.insert(h).second) {
                why = "mesh row " + str(h) + " hosts two streams; a core hosts at most one";
                return false;
            }
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
        if (s.stage == "memtile_ring")
            deriveRing(p, si);
        else if (!deriveResident(p, si, why))
            return false;
        // shim: each column's part of the stream, contiguous in DDR in the order the MemTile takes it,
        // the columns one after the other (aiehlc_plan_arrange)
        const int64_t chunk = s.chunkBytes();
        const bool ring = s.stage == "memtile_ring";
        int64_t off = 0;
        for (int c = 0; c < p.meshCols; c++) {
            const MemtileUse u = memtileUse(p, s, p.colLo + c);
            if (!u.present)
                continue;
            const int64_t len = u.chunksPerTile * chunk;
            const int reps = ring ? s.rounds : (int)s.hostRows.size();
            const bool again = ring && repeatsPerRound(s);
            p.shimBds.push_back({p.colLo + c, u.shimRoute->srcCh, p.res.shimBd[si][c], s.arg, true, off, len,
                                 shimChunkDims(s, u.chunksPerTile), again ? 0 : len, again ? 1 : reps, reps,
                                 !ring && s.residentLaunches});
            p.shimBds.back().tag = "shim/" + std::to_string(si) + "/" + std::to_string(c);
            // the same part again every round: no BD iteration (its step field holds step - 1, so a step of 0
            // cannot be written -- it wraps to the largest step), only the channel start's repeat re-reads it
            off += (again ? 1 : reps) * len;
        }
    }
    if (p.copyPlan())
        deriveCopySlots(p, cores);
    else
        deriveCoreSlots(p, p.coreProtocol(), cores);
    for (const PlanShimBd &sb : p.shimBds)
        if (sb.iterWrap > 1 && sb.iterStep < planTarget().bdWordBytes) {
            why = "shim BD " + std::to_string(sb.bd) + " of column " + std::to_string(sb.col) + " iterates " +
                  std::to_string(sb.iterWrap) + " times with a step of " + std::to_string(sb.iterStep) +
                  " B: the step field holds step - 1 words, a step below one word cannot be written (" + sb.tag + ")";
            return false;
        }
    for (const PlanBd &bd : p.bds) {
        const bool mem = bd.tiles[0].row >= 1 && bd.tiles[0].row <= p.memtileRows;
        const int64_t maxW = mem ? planTarget().memBdMaxLenWords : planTarget().coreBdMaxLenWords;
        if (bd.len / planTarget().bdWordBytes > maxW) {
            why = std::string(mem ? "MemTile" : "core") + " BD " + std::to_string(bd.bd) + " of tile (" +
                  std::to_string(bd.tiles[0].col) + ", " + std::to_string(bd.tiles[0].row) + ") is " +
                  std::to_string(bd.len) + " B, a BD holds at most " + std::to_string(maxW) + " words (" + bd.tag + ")";
            return false;
        }
    }
    // a start repeats at most chMaxRepeat times: a longer walk goes into the task queue as several equal
    // starts (at most chStartQueue)
    {
        std::vector<PlanChannel> split;
        for (const PlanChannel &ch : p.channels) {
            int n = 1;
            while (n <= planTarget().chStartQueue && (ch.repeat % n || ch.repeat / n > planTarget().chMaxRepeat))
                n++;
            if (n == 1 || n > planTarget().chStartQueue) {
                split.push_back(ch);
                continue;
            }
            for (int q = 0; q < n; q++) {
                split.push_back(ch);
                split.back().repeat = ch.repeat / n;
                if (q)
                    split.back().tag += "/q" + std::to_string(q);
            }
        }
        p.channels = split;
    }
    for (const PlanChannel &ch : p.channels)
        if (ch.repeat < 1 || ch.repeat > planTarget().chMaxRepeat) {
            why = "DMA channel " + std::to_string(ch.ch) + (ch.s2mm ? " S2MM" : " MM2S") + " of tile (" +
                  std::to_string(ch.tiles[0].col) + ", " + std::to_string(ch.tiles[0].row) + ") would start " +
                  std::to_string(ch.repeat) + " times, a channel start repeats at most " +
                  std::to_string(planTarget().chMaxRepeat) + " x " + std::to_string(planTarget().chStartQueue) +
                  " queued starts (" + ch.tag + "): use a deeper ring";
            return false;
        }
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

// The op's role in the plan (dfplan.tag): what liftDfschedulePlan reads it back into.
void tagOp(Operation *op, const std::string &tag) {
    if (!tag.empty())
        op->setAttr("dfplan.tag", StringAttr::get(op->getContext(), tag));
}

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
                tagOp(op, l.tag);
            }
    for (const auto &bd : p.bds)
        for (const auto &t : bd.tiles)
            if (isMem(p, t)) // a MemTile BD names its own locks with a bias (neighbourhood-relative ids)
                tagOp(b.create<dfschedule::ConfigTileBdOp>(
                          h.loc, h.tile(t), bd.bd, bd.addr, (int32_t)bd.len, dimsAttr(b, bd.dims, false, W),
                          dimsAttr(b, bd.dims, true, 1), (int32_t)(bd.iterStep * W), (int32_t)bd.iterWrap,
                          bd.acqLock >= 0 ? T.memLockBdBias + bd.acqLock : -1, bd.acqVal,
                          bd.relLock >= 0 ? T.memLockBdBias + bd.relLock : -1, bd.relVal, bd.next),
                      bd.tag);
    for (const auto &c : p.channels)
        for (const auto &t : c.tiles)
            if (isMem(p, t))
                b.create<dfschedule::ConfigChannelEnableOp>(h.loc, h.tile(t), c.ch, c.s2mm ? "S2MM" : "MM2S");
    for (const auto &c : p.channels)
        for (const auto &t : c.tiles)
            if (isMem(p, t))
                tagOp(b.create<dfschedule::ConfigChannelStartOp>(h.loc, h.tile(t), c.ch, c.s2mm ? "S2MM" : "MM2S",
                                                                 c.startBd, c.repeat, c.firstLaunchOnly),
                      c.tag);
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
        Operation *bdOp = b.create(st);
        tagOp(bdOp, s.tag);
        Value bd = bdOp->getResult(0);
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
    if (!readBackDfscheduleFiles(hostModule.getContext(), p, why) || !assignPlanResources(hostModule, p, why) ||
        !deriveDmaProgram(p, why)) {
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
            tagOp(b.create<dfschedule::ConfigTileBdOp>(loc, t, bd.bd, bd.addr, (int32_t)bd.len,
                                                       dimsAttr(b, bd.dims, false, W), dimsAttr(b, bd.dims, true, 1),
                                                       (int32_t)(bd.iterStep * W), (int32_t)bd.iterWrap, bd.acqLock,
                                                       bd.acqVal, bd.relLock, bd.relVal, bd.next),
                  bd.tag);
        });
    for (const auto &l : p.locks)
        forTiles(l.tiles,
                 [&](Value t) { tagOp(b.create<dfschedule::ConfigLockSetOp>(loc, t, l.id, l.init, -1), l.tag); });
    for (const auto &c : p.channels)
        forTiles(c.tiles, [&](Value t) {
            tagOp(b.create<dfschedule::ConfigChannelStartOp>(loc, t, c.ch, c.s2mm ? "S2MM" : "MM2S", c.startBd,
                                                             c.repeat, false),
                  c.tag);
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
