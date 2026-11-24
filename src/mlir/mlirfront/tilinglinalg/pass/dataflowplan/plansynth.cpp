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

std::string tilesText(const std::vector<std::pair<int, int>> &t) {
    std::ostringstream os;
    os << "[";
    for (size_t i = 0; i < t.size(); i++)
        os << (i ? ", " : "") << "[" << t[i].first << ", " << t[i].second << "]";
    os << "]";
    return os.str();
}

// Per-column host-tile matching for the neighbour-shared streams. stream s has
// consumer mesh rows {lo, hi}; its host row must be within one row of both.
// Returns host[s] (mesh row) or empty when no matching exists.
std::vector<int> matchHosts(const std::vector<std::pair<int, int>> &consumers, int meshRows) {
    std::vector<int> host(consumers.size(), -1), owner(meshRows, -1);
    std::function<bool(size_t)> place = [&](size_t s) {
        if (s == consumers.size())
            return true;
        auto [lo, hi] = consumers[s];
        for (int r = hi - 1; r <= lo + 1; r++) {
            if (r < 0 || r >= meshRows || owner[r] >= 0)
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

// The plan text (one op per line), mirroring example/tileprogram/ccode/gemm_plan/gen_plan.py.
bool synthText(const Geometry &g, const Operand &A, const Operand &B, bool persistent, std::ostringstream &os) {
    const int SA = g.meshRows / 2, SB = 2 * g.meshCols;
    if (g.meshRows % 2 || 2 * SA != g.meshCols)
        return fail("share = \"neighbor\" needs mesh rows = 2 x (A strips) and 2 x A strips = mesh columns (4 x 4)");
    if (g.TM != g.TN)
        return fail("A and B blocks must have the same row count (one chunk size)");
    const int64_t chunk = g.TM * g.KC, NK = g.K / g.KC, R2 = g.M / SA / g.TM, NT2 = g.N / SB / g.TN;
    const int maxIter = planTarget().bdMaxIterWrap; // the shim walks a column's tiles as one BD's iterations
    if (NT2 != 1 || R2 * NT2 != g.tiles || NK % 2 || R2 > maxIter)
        return fail("shape: need N = 2 x cols x block rows, M / (rows/2) / block rows = output tiles per core (<= " +
                    std::to_string(maxIter) + ", a shim BD's iterations), K / chunk even");
    // The kernel's shared-port state restarts every launch (a register copy, see resolveBlockIoBuiltins):
    // a launch must take a whole number of slot periods (2 channels x 2 slots = 4 chunks).
    if ((R2 * NK) % 4)
        return fail("chunks per launch (" + std::to_string(R2 * NK) +
                    ") must be a multiple of 4 (2 channels x 2 slots)");
    const int64_t half = chunk / 2, aLen = NK / 2 * chunk, bLen = NK * chunk;
    const int64_t ring = dint(A.df, "ring", 0);
    if (ring <= 0)
        return fail("stage = \"memtile_ring\" needs ring = N (MemTile FIFO buffers)");
    const int64_t aRounds = R2 * aLen / (ring * 2 * chunk);
    if (R2 * aLen % (ring * 2 * chunk))
        return fail("the A ring (" + std::to_string(ring) + " x 2 chunks) does not divide one strip's stream");
    const bool bLaunches = dstr(B.df, "resident") == "launches";
    auto col = [&](int c) { return g.colLo + c; };
    auto row = [&](int pm) { return g.rowLo + pm; };
    const int mtA = g.memRows, mtB = 1;
    // ---- consumers and per-column host matching (identical for every column)
    std::vector<std::pair<int, int>> cons; // A strips, then B strips (one column: b and b + C)
    for (int h = 0; h < SA; h++)
        cons.push_back({2 * h, 2 * h + 1});
    for (int k = 0; k < 2; k++)
        cons.push_back({k, k + 2});
    std::vector<int> host = matchHosts(cons, g.meshRows);
    if (host.empty())
        return fail("no host-tile matching for the shared streams");
    os << "dmaphop.plan {replace_args = [" << A.arg << ", " << B.arg << "], share_args = [" << A.arg << ", " << B.arg
       << "], persistent = " << (persistent ? "true" : "false") << ", bd_once = true}\n";
    // ---- routes
    for (int c = 0; c < g.meshCols; c++) {
        os << "dmaphop.plan_route {arg = " << A.arg << ", src = [" << col(c) << ", 0, 1], src_kind = \"shim\", "
           << "dsts = [[" << col(c) << ", " << mtA << ", 1]]}\n";
        os << "dmaphop.plan_route {arg = " << B.arg << ", src = [" << col(c) << ", 0, 0], src_kind = \"shim\", "
           << "dsts = [[" << col(c) << ", " << mtB << ", 0]]}\n";
    }
    for (int c = 0; c < g.meshCols; c++) { // column c's MemTile carries A strip c / 2, chunk parity c % 2
        int h = c / 2, p = c % 2, hr = row(host[h]);
        os << "dmaphop.plan_route {arg = " << A.arg << ", src = [" << col(c) << ", " << mtA
           << ", 1], src_kind = \"dma\", dsts = [";
        for (int x = 0; x < g.meshCols; x++)
            os << (x ? ", " : "") << "[" << col(x) << ", " << hr << ", " << p << "]";
        os << "]}\n";
    }
    for (int c = 0; c < g.meshCols; c++)
        for (int m = 0; m < 4; m++) // MM2S m = (B strip c + C (m / 2), parity m % 2)
            os << "dmaphop.plan_route {arg = " << B.arg << ", src = [" << col(c) << ", " << mtB << ", " << m
               << "], src_kind = \"dma\", "
               << "dsts = [[" << col(c) << ", " << row(host[SA + m / 2]) << ", " << m % 2 << "]]}\n";
    // ---- the streams: what the DMA program (derived in dfschedule, plandma.cpp) realizes
    auto list = [](std::initializer_list<int64_t> v) {
        std::string t = "[";
        for (int64_t x : v)
            t += (t.size() > 1 ? ", " : "") + std::to_string(x);
        return t + "]";
    };
    os << "dmaphop.plan_stream {arg = " << A.arg << ", role = \"a\", share = \"neighbor\", stage = \"memtile_ring\", "
       << "ring = " << ring << ", resident = \"launch\", chunk = " << list({g.TM, g.KC}) << ", chunks = " << NK
       << ", rounds = " << R2 << ", tensor = " << list({g.M, g.K}) << ", host_rows = " << list({host[0], host[1]})
       << ", first_rows = " << list({cons[0].first, cons[1].first}) << "}\n";
    os << "dmaphop.plan_stream {arg = " << B.arg << ", role = \"b\", share = \"neighbor\", stage = \"memtile\", "
       << "resident = \"" << (bLaunches ? "launches" : "launch") << "\", chunk = " << list({g.TN, g.KC})
       << ", chunks = " << NK << ", rounds = " << R2 << ", tensor = " << list({g.N, g.K})
       << ", host_rows = " << list({host[2], host[3]}) << ", first_rows = " << list({cons[2].first, cons[3].first})
       << "}\n";
    llvm::outs() << "[DataflowPlan] synthesized from the routing IR: A strips " << SA << " x B strips " << SB << ", "
                 << R2 << " tiles / core, K chunks " << NK << ", A ring " << ring << ", B "
                 << (bLaunches ? "resident across launches" : "per launch") << ", host rows A" << host[0] << "/"
                 << host[1] << " B" << host[2] << "/" << host[3] << (persistent ? ", persistent kernel" : "") << "\n";
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
