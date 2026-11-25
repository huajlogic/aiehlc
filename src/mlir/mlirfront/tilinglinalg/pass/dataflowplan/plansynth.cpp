/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Plan synthesis: routing-level dataflow intent -> dmaphop.plan* ops.
//
// The routing IR says WHAT (doc/design/dmaphop_dataflow_plan.md, "Routing level"):
//
//   %A = routing.routingcreatescheduletensor ... {dataflow = {share = "neighbor",
//                                                  stage = "memtile_ring", ring = 10 : i64}, kernel_block = ...}
//   %B = routing.routingcreatescheduletensor ... {dataflow = {share = "neighbor",
//                                                  stage = "memtile", resident = "launches"}, kernel_block = ...}
//   module attributes {routing.persistent_kernel = 1 : i64}
//
// and this file decides HOW, from the tensors' traced blocks (#routing.kernel_block)
// and the mesh the dmaphop stage placed:
//   * share = "neighbor": the mesh computes a logical (R/2) x (2C) grid -- core
//     (pm, pn) takes A strip pm / 2 and B strip pn + C (pm % 2) -- so every
//     operand stream has exactly two consumer cores in one column. Each stream is
//     hosted in the memory of ONE core of that column, adjacent (or equal) to
//     both consumers (a per-column matching), which reads it through its own /
//     north / south memory view. The lower consumer reads first and hands the
//     buffer to the other one; the two walk its halves in opposite phase.
//   * stage = "memtile_ring": A goes shim -> MemTile (top MemTile row) FIFO ring
//     of `ring` 2-chunk buffers -> broadcast to the strip's host row.
//   * stage = "memtile" + resident = "launches": B is loaded into the bottom
//     MemTile row once (first launch) and replayed every launch.
//   * persistent kernel: `persistent = true` (the go lock, like every BD / lock id and buffer address, is
//     allocated later in dfschedule against the generated flows -- planresource.cpp).
// The result is the same dmaphop.plan* text gen_plan.py writes by hand, parsed
// and inserted at the top of @main, so the dmaphop dump shows exactly what the
// compiler decided.

#include "dataflowplan.h"
#include "plantarget.h"

#include "routingmanager.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/Parser/Parser.h"
#include "llvm/Support/raw_ostream.h"

#include <functional>
#include <map>
#include <sstream>

namespace dfplan {

using namespace mlir;

namespace {

struct Operand {
    int arg = -1;
    DictionaryAttr df;
    routing::KernelBlockAttr kb;
    int elemBytes = 1;
    int depth = 0; // pp_depth: the kernel's {.depth} (buffers per channel on the host core)
};

int traceToArg(Value v) {
    for (int guard = 0; guard < 32 && v; guard++) {
        if (auto ba = dyn_cast<BlockArgument>(v))
            return isa<func::FuncOp>(ba.getOwner()->getParentOp()) ? (int)ba.getArgNumber() : -1;
        Operation *def = v.getDefiningOp();
        if (!def || def->getNumOperands() == 0)
            return -1;
        v = def->getOperand(0);
    }
    return -1;
}

std::string dstr(DictionaryAttr d, StringRef k, StringRef dflt = "") {
    if (auto s = d ? d.getAs<StringAttr>(k) : StringAttr())
        return s.getValue().str();
    return dflt.str();
}
int64_t dint(DictionaryAttr d, StringRef k, int64_t dflt) {
    if (auto i = d ? d.getAs<IntegerAttr>(k) : IntegerAttr())
        return i.getInt();
    return dflt;
}

// Per-column host-tile matching for the neighbour-shared streams: stream s is read by the mesh rows in
// consumers[s]; its host row must be within one row of every one of them, one stream per host.
// Returns host[s] (mesh row) or empty when no matching exists.
std::vector<int> matchHosts(const std::vector<std::vector<int>> &consumers, int meshRows) {
    std::vector<int> host(consumers.size(), -1), owner(meshRows, -1);
    std::function<bool(size_t)> place = [&](size_t s) {
        if (s == consumers.size())
            return true;
        for (int r = 0; r < meshRows; r++) {
            bool near = owner[r] < 0;
            for (int c : consumers[s])
                near &= c >= r - 1 && c <= r + 1;
            if (!near)
                continue;
            owner[r] = (int)s;
            host[s] = r;
            if (place(s + 1))
                return true;
            owner[r] = -1;
        }
        return false;
    };
    if (!place(0))
        return {};
    return host;
}

struct Geometry {
    int meshRows = 0, meshCols = 0, colLo = 0, rowLo = 0, memRows = 0;
    int64_t M = 0, N = 0, K = 0, TM = 0, TN = 0, KC = 0;
    int64_t tiles = 0; // output tiles per core
};

bool fail(const std::string &m) {
    llvm::errs() << "[DataflowPlan] synthesis ERROR: " << m << "\n";
    return false;
}

std::string list(const std::vector<int64_t> &v) {
    std::string t = "[";
    for (size_t i = 0; i < v.size(); i++)
        t += (i ? ", " : "") + std::to_string(v[i]);
    return t + "]";
}

// One shared stream as the synthesis lays it out.
struct SynthStream {
    const Operand *op = nullptr;
    std::string role, stage;
    int ring = 0;
    bool keep = false;
    std::vector<int64_t> rowGroups, strips, hostRows, firstRows;
    int groups = 0, readers = 0;
    int64_t rows = 0, blockRows = 0;
};

// MemTile DMA channels for a stream on one MemTile: S2MM / MM2S channels whose BD bank still has room for
// the BDs the derivation will put there (plantarget.h banks), lowest first.
struct MemtileChannels {
    std::map<int, int> bankUse;           // bank lo -> BDs
    std::set<std::pair<int, bool>> taken; // (channel, s2mm)
    int pick(bool s2mm, int bds) {
        const PlanTarget &T = planTarget();
        for (int ch = 0; ch < T.memChannels; ch++) {
            if (taken.count({ch, s2mm}) || bankUse[T.memBankLo(ch)] + bds > T.memBdBank)
                continue;
            taken.insert({ch, s2mm});
            bankUse[T.memBankLo(ch)] += bds;
            return ch;
        }
        return -1;
    }
};

// The plan text (one op per line), mirroring example/tileprogram/ccode/gemm_plan/gen_plan.py. The layout:
//   * logical grid (the kernel analysis' shared-operand grid, kernel_trace.cpp remapSharedGrid): core
//     (pm, pn) reads A strip pm / 2 and B strip pn + C (pm % 2) -- so A's strip groups are row pairs and
//     B's are the row parities; a group's rows are its readers; every stream needs the same reader count;
//   * hosts: per column, one host row per stream within one row of all its readers (matchHosts);
//   * A (memtile_ring): its (strip, parity) streams spread over the columns -- s = min(channels, C / strips)
//     columns per strip, each serving channels / s parities of it -- broadcast to the strip's host row;
//   * B (memtile): per column its strips (one per group) held in a MemTile, one replay per (group, parity);
//   * shim MM2S channels, MemTile rows and channels: assigned in stream order (top-down), banks checked.
bool synthText(const Geometry &g, const Operand &A, const Operand &B, bool persistent, std::ostringstream &os) {
    const PlanTarget &T = planTarget();
    // the hosted-stream protocol: a chunk per core S2MM channel in turn, {.depth} buffers per channel
    const int R = g.meshRows, C = g.meshCols, channels = T.coreS2mmChannels;
    const int slots = std::max({A.depth, B.depth, 1});
    if (R % 2)
        return fail("share = \"neighbor\" needs an even number of mesh rows (A strips are row pairs)");
    const int SA = R / 2, SB = 2 * C;
    if (g.TM != g.TN)
        return fail("A and B blocks must have the same row count (one chunk size)");
    const int64_t NK = g.K / g.KC, R2 = g.M / SA / g.TM, NT2 = g.N / SB / g.TN;
    const int maxIter = planTarget().bdMaxIterWrap; // the shim walks a column's tiles as one BD's iterations
    if (NT2 != 1 || R2 * NT2 != g.tiles || NK % channels || R2 > maxIter)
        return fail("shape: need N = 2 x cols x block rows, M / (rows/2) / block rows = output tiles per core (<= " +
                    std::to_string(maxIter) + ", a shim BD's iterations), K / chunk a multiple of " +
                    std::to_string(channels));
    if (C < SA)
        return fail("A has " + std::to_string(SA) + " strips: the mesh needs at least as many columns");
    // ---- the two streams' groups, readers and hosts
    SynthStream sa, sb;
    sa.op = &A, sa.role = "a", sa.stage = "memtile_ring", sa.ring = (int)dint(A.df, "ring", 0);
    sb.op = &B, sb.role = "b", sb.stage = "memtile", sb.keep = dstr(B.df, "resident") == "launches";
    if (sa.ring <= 0)
        return fail("stage = \"memtile_ring\" needs ring = N (MemTile FIFO buffers)");
    for (int pm = 0; pm < R; pm++)
        sa.rowGroups.push_back(pm / 2), sb.rowGroups.push_back(pm % 2);
    sa.groups = SA, sb.groups = std::min(R, 2);
    std::vector<std::vector<int>> cons;
    for (SynthStream *st : {&sa, &sb})
        for (int k = 0; k < st->groups; k++) {
            cons.push_back({});
            for (int pm = 0; pm < R; pm++)
                if (st->rowGroups[pm] == k)
                    cons.back().push_back(pm);
            st->readers = std::max<int>(st->readers, (int)cons.back().size());
            st->firstRows.push_back(cons.back().front());
        }
    if (sa.readers != sb.readers)
        return fail("A's strips have " + std::to_string(sa.readers) + " readers, B's " + std::to_string(sb.readers) +
                    ": every core runs one hosted-stream program, so they must agree (" + std::to_string(R) +
                    " mesh rows)");
    std::vector<int> host = matchHosts(cons, R);
    if (host.empty())
        return fail("no host-tile matching: every stream needs a host row within one row of all its readers");
    for (int k = 0; k < SA; k++)
        sa.hostRows.push_back(host[k]);
    for (int k = 0; k < sb.groups; k++)
        sb.hostRows.push_back(host[SA + k]);
    for (int c = 0; c < C; c++) {
        for (int k = 0; k < sa.groups; k++)
            sa.strips.push_back(k);
        for (int k = 0; k < sb.groups; k++)
            sb.strips.push_back(c + C * k);
    }
    const int64_t ring = sa.ring, chunk = g.TM * g.KC * A.elemBytes;
    auto col = [&](int c) { return g.colLo + c; };
    auto row = [&](int pm) { return g.rowLo + pm; };
    if (g.memRows < 1)
        return fail("the partition has no MemTile row");
    // MemTile rows and shim MM2S channels: one per stream, in stream order from the top
    const int mtA = g.memRows, mtB = std::max(1, g.memRows - 1);
    // B's staging, by MemTile capacity: held whole (memtile, `keep` across launches) when its column's
    // strips fit next to what else that MemTile holds, else streamed chunk by chunk through a FIFO ring
    // (memtile_ring), re-read from DDR for every output tile. An explicit stage = memtile_ring is kept.
    {
        const int perStripA = std::min(channels, C / SA), kA = channels / perStripA;
        const int64_t aBytes = kA == 1 ? ring * 2 * chunk : ring * kA * chunk;
        const int64_t bChunk = g.TN * g.KC * B.elemBytes, bWhole = (int64_t)sb.groups * NK * bChunk;
        const int64_t room = T.memBytes - (mtA == mtB ? aBytes : 0);
        const std::string want = dstr(B.df, "stage");
        // held whole, the column's strips are ONE S2MM BD: its length field bounds it too
        const bool bdFits = bWhole / T.bdWordBytes <= T.memBdMaxLenWords;
        if (want == "memtile_ring" || bWhole > room || !bdFits) {
            sb.stage = "memtile_ring";
            // the shallowest ring (from .ring, default 2) whose MemTile channels start at most chMaxRepeat
            // times and that divides the column's chunk stream (rounds x groups x K chunks)
            const int64_t stream = R2 * (int64_t)sb.groups * NK, k = (int64_t)sb.groups * channels;
            sb.ring = (int)dint(B.df, "ring", 2);
            while (sb.ring < 64 && (stream % (sb.ring * k) || stream / (sb.ring * k) > T.chMaxRepeat))
                sb.ring++;
            const int64_t bRing = (int64_t)sb.ring * sb.groups * channels * bChunk;
            if (bRing > room)
                return fail("B's MemTile ring (" + std::to_string(sb.ring) + " x " + std::to_string(sb.groups) + " x " +
                            std::to_string(channels) + " chunks = " + std::to_string(bRing) +
                            " B) does not fit next to A's ring: " + std::to_string(room) + " B left");
            if (want != "memtile_ring")
                llvm::outs() << "[DataflowPlan] stream " << B.arg << ": held whole it needs " << bWhole
                             << " B per MemTile (" << room << " B left next to A's ring, one BD holds "
                             << T.memBdMaxLenWords * T.bdWordBytes << " B): streamed as memtile_ring " << sb.ring
                             << " (re-read from DDR per output tile" << (sb.keep ? "; keep ignored" : "") << ")\n";
            sb.keep = false;
        }
        llvm::outs() << "[DataflowPlan] stream " << A.arg << ": memtile_ring " << ring << ", " << aBytes
                     << " B per MemTile; stream " << B.arg << ": " << sb.stage
                     << (sb.stage == "memtile_ring" ? " " + std::to_string(sb.ring)
                                                    : std::string(sb.keep ? " keep" : ""))
                     << ", " << (sb.stage == "memtile_ring" ? (int64_t)sb.ring * sb.groups * channels * bChunk : bWhole)
                     << " B per MemTile (of " << T.memBytes << ")\n";
    }
    const bool bLaunches = sb.keep, bRing = sb.stage == "memtile_ring";
    const int shimA = T.shimMm2sChannels - 1, shimB = std::max(0, T.shimMm2sChannels - 2);
    os << "dmaphop.plan {replace_args = [" << A.arg << ", " << B.arg << "], share_args = [" << A.arg << ", " << B.arg
       << "], persistent = " << (persistent ? "true" : "false") << ", bd_once = true}\n";
    // ---- A: (strip, parity) streams over the columns
    const int perStrip = std::min(channels, C / SA); // columns per strip
    std::map<int, MemtileChannels> mtCh;
    for (int c = 0; c < SA * perStrip; c++) {
        const int h = c / perStrip, q0 = c % perStrip;
        std::vector<int> par;
        for (int q = q0; q < channels; q += perStrip)
            par.push_back(q);
        const int k = (int)par.size();
        MemtileChannels &mc = mtCh[mtA * 1000 + c];
        const int s2mm = mc.pick(true, k == 1 ? (int)ring : (int)ring * k);
        os << "dmaphop.plan_route {arg = " << A.arg << ", src = [" << col(c) << ", 0, " << shimA
           << "], src_kind = \"shim\", dsts = [[" << col(c) << ", " << mtA << ", " << s2mm << "]]}\n";
        for (int q : par) {
            const int mm2s = mc.pick(false, (int)ring);
            if (s2mm < 0 || mm2s < 0)
                return fail("MemTile (" + std::to_string(col(c)) + ", " + std::to_string(mtA) +
                            "): no channel with room in its BD bank for a ring of " + std::to_string(ring));
            os << "dmaphop.plan_route {arg = " << A.arg << ", src = [" << col(c) << ", " << mtA << ", " << mm2s
               << "], src_kind = \"dma\", dsts = [";
            for (int x = 0; x < C; x++)
                os << (x ? ", " : "") << "[" << col(x) << ", " << row(sa.hostRows[h]) << ", " << q << "]";
            os << "]}\n";
        }
    }
    // ---- B: per column its strips, one replay per (group, parity)
    for (int c = 0; c < C; c++) {
        MemtileChannels &mc = mtCh[mtB * 1000 + c];
        // a ring: one S2MM chain over every (group, parity) buffer, `ring` BDs per replay
        const int replays = sb.groups * channels, perOut = bRing ? sb.ring : 1;
        const int s2mm = mc.pick(true, bRing ? sb.ring * replays : 1);
        os << "dmaphop.plan_route {arg = " << B.arg << ", src = [" << col(c) << ", 0, " << shimB
           << "], src_kind = \"shim\", dsts = [[" << col(c) << ", " << mtB << ", " << s2mm << "]]}\n";
        for (int k = 0; k < sb.groups; k++)
            for (int q = 0; q < channels; q++) {
                const int mm2s = mc.pick(false, perOut);
                if (s2mm < 0 || mm2s < 0)
                    return fail("MemTile (" + std::to_string(col(c)) + ", " + std::to_string(mtB) +
                                "): out of DMA channels for B's replays");
                os << "dmaphop.plan_route {arg = " << B.arg << ", src = [" << col(c) << ", " << mtB << ", " << mm2s
                   << "], src_kind = \"dma\", dsts = [[" << col(c) << ", " << row(sb.hostRows[k]) << ", " << q
                   << "]]}\n";
            }
    }
    // ---- the streams: what the DMA program (derived in dfschedule, plandma.cpp) realizes
    const int parts = (int)dint(A.df, "parts", 1);
    for (SynthStream *st : {&sa, &sb}) {
        const bool isA = st == &sa;
        os << "dmaphop.plan_stream {arg = " << st->op->arg << ", role = \"" << st->role
           << "\", share = \"neighbor\", stage = \"" << st->stage << "\", ";
        if (st->stage == "memtile_ring")
            os << "ring = " << st->ring << ", ";
        os << "resident = \"" << (!isA && bLaunches ? "launches" : "launch") << "\", chunk = " << list({g.TM, g.KC})
           << ", chunks = " << NK << ", rounds = " << R2 << ", tensor = " << list({isA ? g.M : g.N, g.K})
           << ", host_rows = " << list(st->hostRows) << ", first_rows = " << list(st->firstRows)
           << ", row_groups = " << list(st->rowGroups) << ", strips = " << list(st->strips)
           << ", channels = " << channels << ", slots = " << slots << ", readers = " << st->readers
           << ", parts = " << parts << ", elem_bytes = " << st->op->elemBytes << "}\n";
    }
    (void)chunk;
    llvm::outs() << "[DataflowPlan] synthesized from the routing IR: " << R << " x " << C << " mesh, A strips " << SA
                 << " x B strips " << SB << ", " << R2 << " tiles / core, K chunks " << NK << ", A ring " << ring
                 << " over " << SA * perStrip << " column(s), " << sa.readers << " readers per stream, B "
                 << (bRing       ? "ring " + std::to_string(sb.ring) + " (re-read per output tile)"
                     : bLaunches ? std::string("resident across launches")
                                 : std::string("per launch"))
                 << ", host rows A" << list(sa.hostRows) << " B" << list(sb.hostRows)
                 << (persistent ? ", persistent kernel" : "") << "\n";
    return true;
}

bool readGeometry(ModuleOp module, const std::map<int, Operand> &ops, int outArg, Geometry &g) {
    int maxRow = -1, maxCol = -1;
    g.rowLo = g.colLo = 1 << 20;
    module.walk([&](Operation *op) {
        if (op->getName().getStringRef() != "dmaphop.tile")
            return;
        auto t = op->getAttrOfType<StringAttr>("tiletype");
        auto c = op->getAttrOfType<IntegerAttr>("col"), r = op->getAttrOfType<IntegerAttr>("row");
        if (!t || t.getValue() != "core" || !c || !r)
            return;
        g.rowLo = std::min<int>(g.rowLo, (int)r.getInt());
        g.colLo = std::min<int>(g.colLo, (int)c.getInt());
        maxRow = std::max<int>(maxRow, (int)r.getInt());
        maxCol = std::max<int>(maxCol, (int)c.getInt());
    });
    if (maxRow < 0)
        return fail("no core tiles in the dmaphop IR");
    g.meshRows = maxRow - g.rowLo + 1;
    g.meshCols = maxCol - g.colLo + 1;
    g.memRows = g.rowLo - 1;
    auto a = ops.begin()->second, b = std::next(ops.begin())->second;
    if (!a.kb || !b.kb || a.kb.getShape().size() != 2 || b.kb.getShape().size() != 2)
        return fail("the shared operands need traced 2-D blocks (#routing.kernel_block)");
    g.M = a.kb.getTensorShape()[0];
    g.K = a.kb.getTensorShape()[1];
    g.N = b.kb.getTensorShape()[0];
    g.TM = a.kb.getShape()[0];
    g.KC = a.kb.getShape()[1];
    g.TN = b.kb.getShape()[0];
    if (b.kb.getShape()[1] != g.KC || b.kb.getTensorShape()[1] != g.K)
        return fail("A and B must share K and the K chunk");
    routing::TensorRoutingInfoMap info = routing::collectTensorRoutingInfo(module);
    const routing::TensorRoutingInfo *ci = routing::lookupTensorRoutingInfo(info, outArg);
    if (!ci || !ci->kernelBlock)
        return fail("the output needs a traced block sequence");
    g.tiles = ci->kernelBlock.getRoundsI() * ci->kernelBlock.getRoundsJ();
    return true;
}

} // namespace

bool synthesizeDataflowPlan(ModuleOp module, std::string &why) {
    std::map<int, Operand> shared;
    bool anyPlanOp = false;
    module.walk([&](Operation *op) {
        if (op->getName().getStringRef().starts_with("dmaphop.plan"))
            anyPlanOp = true;
        auto decl = dyn_cast<routing::createscheduletensor>(op);
        if (!decl)
            return;
        auto df = op->getAttrOfType<DictionaryAttr>("dataflow");
        if (!df)
            return;
        Operand o;
        o.arg = traceToArg(op->getOperand(0));
        o.df = df;
        o.kb = decl.getKernelBlockAttr();
        if (auto tt = dyn_cast<RankedTensorType>(op->getResult(0).getType()))
            o.elemBytes = std::max<int>(1, (int)(tt.getElementTypeBitWidth() / 8));
        if (auto d = op->getAttrOfType<IntegerAttr>("pp_depth"))
            o.depth = (int)d.getInt();
        if (o.arg >= 0)
            shared[o.arg] = o;
    });
    if (shared.empty())
        return true;
    if (anyPlanOp) {
        llvm::outs() << "[DataflowPlan] explicit dmaphop.plan ops present: the routing-level dataflow is not "
                        "re-synthesized\n";
        return true;
    }
    for (auto &[arg, o] : shared)
        if (dstr(o.df, "share") != "neighbor") {
            why = "dataflow on arg " + std::to_string(arg) + ": only share = \"neighbor\" is implemented";
            return false;
        }
    if (shared.size() != 2) {
        why = "share = \"neighbor\" needs exactly two operands (A, B); found " + std::to_string(shared.size());
        return false;
    }
    func::FuncOp main;
    module.walk([&](func::FuncOp f) {
        if (f.getName() == "main")
            main = f;
    });
    if (!main || main.getBody().empty()) {
        why = "no @main";
        return false;
    }
    int outArg = -1;
    for (BlockArgument ba : main.getArguments())
        if (!shared.count((int)ba.getArgNumber()))
            outArg = (int)ba.getArgNumber();
    Geometry g;
    if (!readGeometry(module, shared, outArg, g)) {
        why = "geometry";
        return false;
    }
    bool persistent = false;
    if (auto p = module->getAttrOfType<IntegerAttr>("routing.persistent_kernel"))
        persistent = p.getInt() != 0;
    std::ostringstream os;
    if (!synthText(g, shared.begin()->second, std::next(shared.begin())->second, persistent, os)) {
        why = "synthesis";
        return false;
    }
    std::string text = "module {\n" + os.str() + "}\n";
    OwningOpRef<ModuleOp> parsed = parseSourceString<ModuleOp>(text, module.getContext());
    if (!parsed) {
        why = "synthesized plan does not parse";
        return false;
    }
    Block &entry = main.getBody().front();
    llvm::SmallVector<Operation *> ops;
    for (Operation &op : parsed->getBody()->getOperations())
        ops.push_back(&op);
    for (auto it = ops.rbegin(); it != ops.rend(); ++it) {
        (*it)->remove();
        entry.push_front(*it);
    }
    return true;
}

} // namespace dfplan
