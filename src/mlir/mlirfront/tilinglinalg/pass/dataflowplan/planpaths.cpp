/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// The dataflow plan in the dmaphop hop graph (see dataflowplan.h, "the plan in the hop graph"): per stream one
// dmaphop.create_path carrying #dmaphop.stream, its routes as dmaphop.create_hop between dmaphop.port ops on
// shim / MemTile / core tiles. One representation for data movement at the dmaphop level: the plan's routes
// are hops like the generated flows', not attribute-only plan_route / plan_stream ops.

#include "dataflowplan.h"

#include "dmaphopmanager.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "llvm/ADT/SmallPtrSet.h"

#include <map>

namespace dfplan {

using namespace mlir;

namespace {

constexpr const char *kStreamAttr = "stream"; // #dmaphop.stream on a plan path
constexpr const char *kRouteAttr = "route";   // the route index on each of a plan path's hops

DenseI64ArrayAttr arr(MLIRContext *ctx, const std::vector<int> &v) {
    return DenseI64ArrayAttr::get(ctx, std::vector<int64_t>(v.begin(), v.end()));
}
DenseI64ArrayAttr arr(MLIRContext *ctx, const std::vector<int64_t> &v) { return DenseI64ArrayAttr::get(ctx, v); }
std::vector<int> ints(DenseI64ArrayAttr a) {
    std::vector<int> v;
    for (int64_t x : a.asArrayRef())
        v.push_back((int)x);
    return v;
}
std::vector<int64_t> int64s(DenseI64ArrayAttr a) {
    return std::vector<int64_t>(a.asArrayRef().begin(), a.asArrayRef().end());
}

dmaphop::StreamAttr toAttr(MLIRContext *ctx, const PlanStream &s) {
    return dmaphop::StreamAttr::get(
        ctx, s.arg, s.role, s.share, s.channel, s.stage, s.ring, s.residentLaunches, s.chunkRows, s.chunkCols,
        s.tensorRows, s.tensorCols, s.chunks, s.rounds, arr(ctx, s.hostRows), arr(ctx, s.firstRows), s.channels,
        s.slots, s.readers, s.parts, s.elemBytes, s.rowStep, s.colStep, s.stripStep, s.rowStepJ, s.colStepI,
        arr(ctx, s.stripRowBase), arr(ctx, s.stripColBase), arr(ctx, s.rowGroups), arr(ctx, s.strips));
}

PlanStream fromAttr(dmaphop::StreamAttr a) {
    PlanStream s;
    s.arg = (int)a.getArg();
    s.role = a.getRole().str();
    s.share = a.getShare().str();
    s.channel = (int)a.getChannel();
    s.stage = a.getStage().str();
    s.ring = (int)a.getRing();
    s.residentLaunches = a.getResident();
    s.chunkRows = (int)a.getChunkRows(), s.chunkCols = (int)a.getChunkCols();
    s.tensorRows = a.getTensorRows(), s.tensorCols = a.getTensorCols();
    s.chunks = (int)a.getChunks(), s.rounds = (int)a.getRounds();
    s.hostRows = ints(a.getHostRows()), s.firstRows = ints(a.getFirstRows());
    s.channels = (int)a.getChannels(), s.slots = (int)a.getSlots(), s.readers = (int)a.getReaders();
    s.parts = (int)a.getParts(), s.elemBytes = (int)a.getElemBytes();
    s.rowStep = a.getRowStep(), s.colStep = a.getColStep(), s.stripStep = a.getStripStep();
    s.rowStepJ = a.getRowStepJ(), s.colStepI = a.getColStepI();
    s.stripRowBase = int64s(a.getStripRowBase()), s.stripColBase = int64s(a.getStripColBase());
    s.rowGroups = ints(a.getRowGroups()), s.strips = ints(a.getStrips());
    return s;
}

bool isPlanPath(Operation *op) {
    auto p = dyn_cast<dmaphop::create_path>(op);
    return p && p->hasAttr(kStreamAttr);
}

bool isPlanRouteOrStream(Operation *op) {
    StringRef n = op->getName().getStringRef();
    return n == "dmaphop.plan_route" || n == "dmaphop.plan_stream";
}

// A plan tile's type from where it sits: row 0 shim, rows 1..memtileRows MemTiles, above that cores.
std::string tileType(const Tile &t, int memtileRows, bool shimSrc) {
    if (t.row == 0 && shimSrc)
        return "shim";
    return t.row <= memtileRows ? "mem" : "core";
}

} // namespace

Attribute streamToAttr(MLIRContext *ctx, const PlanStream &s) { return toAttr(ctx, s); }
bool streamFromAttr(Attribute a, PlanStream &s) {
    auto st = dyn_cast_or_null<dmaphop::StreamAttr>(a);
    if (st)
        s = fromAttr(st);
    return (bool)st;
}
Attribute routeToAttr(MLIRContext *ctx, const PlanRoute &r) {
    std::vector<int64_t> d;
    for (const auto &[t, ch] : r.dsts)
        d.insert(d.end(), {(int64_t)t.col, (int64_t)t.row, (int64_t)ch});
    return dmaphop::RouteAttr::get(ctx, r.arg, r.src.col, r.src.row, r.srcCh, r.srcShim,
                                   DenseI64ArrayAttr::get(ctx, d));
}
bool routeFromAttr(Attribute a, PlanRoute &r) {
    auto ra = dyn_cast_or_null<dmaphop::RouteAttr>(a);
    if (!ra || ra.getDsts().size() % 3)
        return false;
    r = PlanRoute();
    r.arg = (int)ra.getArg();
    r.src = {(int)ra.getSrcCol(), (int)ra.getSrcRow()};
    r.srcCh = (int)ra.getSrcCh();
    r.srcShim = ra.getSrcShim();
    ArrayRef<int64_t> d = ra.getDsts().asArrayRef();
    for (size_t i = 0; i + 2 < d.size(); i += 3)
        r.dsts.push_back({{(int)d[i], (int)d[i + 1]}, (int)d[i + 2]});
    return true;
}

bool hasPlanPaths(ModuleOp module) {
    bool any = false;
    module.walk([&](Operation *op) { any |= isPlanPath(op); });
    return any;
}

namespace {
// the paths, their hops and the ports / tiles only they use (not the header)
void eraseThePaths(ModuleOp module) {
    SmallVector<Operation *> paths;
    module.walk([&](Operation *op) {
        if (isPlanPath(op))
            paths.push_back(op);
    });
    for (Operation *path : paths) {
        SmallVector<Operation *> hops;
        for (Value h : path->getOperands())
            if (Operation *d = h.getDefiningOp())
                hops.push_back(d);
        path->erase();
        llvm::SmallPtrSet<Operation *, 16> ports, tiles;
        for (Operation *h : hops) {
            for (Value v : h->getOperands())
                if (Operation *d = v.getDefiningOp())
                    ports.insert(d);
            if (h->use_empty())
                h->erase();
        }
        for (Operation *p : ports) {
            for (Value v : p->getOperands())
                if (Operation *d = v.getDefiningOp())
                    tiles.insert(d);
            if (p->use_empty())
                p->erase();
        }
        for (Operation *t : tiles)
            if (t->use_empty())
                t->erase();
    }
}
} // namespace

void erasePlanPaths(ModuleOp module) {
    SmallVector<Operation *> header;
    module.walk([&](Operation *op) {
        StringRef n = op->getName().getStringRef();
        if (n == "dmaphop.plan" || n == "dmaphop.plan_resources")
            header.push_back(op);
    });
    for (Operation *op : header)
        op->erase();
    eraseThePaths(module);
}

bool writePlanPaths(ModuleOp module, const DataflowPlan &plan, std::string &why) {
    // where the plan ops were (the front of @main); then drop them and any earlier plan paths
    SmallVector<Operation *> old;
    module.walk([&](Operation *op) {
        if (isPlanRouteOrStream(op))
            old.push_back(op);
    });
    eraseThePaths(module);
    for (Operation *op : old)
        op->erase();
    for (const PlanRoute &r : plan.routes) {
        bool carried = false;
        for (const PlanStream &s : plan.streams)
            carried |= s.arg == r.arg;
        if (!carried) {
            why = "route of arg " + std::to_string(r.arg) + " has no stream";
            return false;
        }
    }
    MLIRContext *ctx = module.getContext();
    OpBuilder b(ctx);
    const Location loc = b.getUnknownLoc();
    for (const PlanStream &s : plan.streams) {
        // next to the tensor's generated flow: the block of its first dmaphop.push (a routing.RoutingCreate
        // body, the symbol table the ports need)
        Block *at = nullptr;
        module.walk([&](dmaphop::push push) {
            if (!at && traceKernelArg(push.getData()) == s.arg)
                at = push->getBlock();
        });
        if (!at) {
            why = "stream of arg " + std::to_string(s.arg) + " has no generated flow (dmaphop.push) to sit next to";
            return false;
        }
        b.setInsertionPointToStart(at);
        std::map<std::pair<std::string, Tile>, Value> tiles;
        auto tile = [&](const std::string &type, const Tile &t) {
            Value &v = tiles[{type, t}];
            if (!v)
                v = b.create<dmaphop::tile>(loc, b.getStringAttr(type), b.getI64IntegerAttr(t.col),
                                            b.getI64IntegerAttr(t.row))
                        .getResult();
            return v;
        };
        SmallVector<Value> hops;
        SmallVector<Attribute> producers, consumers;
        for (size_t i = 0; i < plan.routes.size(); i++) {
            const PlanRoute &r = plan.routes[i];
            if (r.arg != s.arg)
                continue;
            const std::string pre = "plan" + std::to_string(s.arg) + "_r" + std::to_string(i);
            Value src = b.create<dmaphop::port>(loc, tile(tileType(r.src, plan.memtileRows, r.srcShim), r.src),
                                                b.getStringAttr("Out"), b.getStringAttr(pre + "_src"),
                                                b.getI64IntegerAttr(r.srcCh), IntegerAttr())
                            .getResult();
            producers.push_back(FlatSymbolRefAttr::get(ctx, pre + "_src"));
            for (size_t j = 0; j < r.dsts.size(); j++) {
                const auto &[t, ch] = r.dsts[j];
                const std::string name = pre + "_d" + std::to_string(j);
                Value dst =
                    b.create<dmaphop::port>(loc, tile(tileType(t, plan.memtileRows, false), t), b.getStringAttr("In"),
                                            b.getStringAttr(name), b.getI64IntegerAttr(ch), IntegerAttr())
                        .getResult();
                consumers.push_back(FlatSymbolRefAttr::get(ctx, name));
                auto hop = b.create<dmaphop::create_hop>(loc, src, dst);
                hop->setAttr(kRouteAttr, b.getI64IntegerAttr((int64_t)i));
                hops.push_back(hop.getResult());
            }
        }
        auto path = b.create<dmaphop::create_path>(loc, hops, b.getArrayAttr(producers), b.getArrayAttr(consumers),
                                                   b.getArrayAttr({}));
        path->setAttr(kStreamAttr, toAttr(ctx, s));
    }
    return true;
}

bool readPlanPaths(ModuleOp module, DataflowPlan &plan, std::string &why) {
    std::map<int64_t, PlanRoute> routes;
    bool ok = true;
    module.walk([&](Operation *op) {
        if (!ok || !isPlanPath(op))
            return;
        auto st = dyn_cast<dmaphop::StreamAttr>(op->getAttr(kStreamAttr));
        if (!st) {
            why = "a plan path's 'stream' is not a #dmaphop.stream";
            ok = false;
            return;
        }
        plan.streams.push_back(fromAttr(st));
        for (Value h : op->getOperands()) {
            auto hop = h.getDefiningOp<dmaphop::create_hop>();
            auto idx = hop ? hop->getAttrOfType<IntegerAttr>(kRouteAttr) : IntegerAttr();
            auto sp = hop ? hop.getSource().getDefiningOp<dmaphop::port>() : dmaphop::port();
            auto dp = hop ? hop.getDestination().getDefiningOp<dmaphop::port>() : dmaphop::port();
            auto stile = sp ? sp.getTile().getDefiningOp<dmaphop::tile>() : dmaphop::tile();
            auto dtile = dp ? dp.getTile().getDefiningOp<dmaphop::tile>() : dmaphop::tile();
            if (!idx || !stile || !dtile || !sp.getDirectionChannel() || !dp.getDirectionChannel()) {
                why = "a plan path's hop needs `route = i` and ports with a channel on dmaphop.tile ops";
                ok = false;
                return;
            }
            PlanRoute &r = routes[idx.getInt()];
            const Tile s{(int)stile.getCol(), (int)stile.getRow()};
            if (r.dsts.empty()) {
                r.arg = st.getArg();
                r.src = s;
                r.srcCh = (int)*sp.getDirectionChannel();
                r.srcShim = stile.getTiletype() == "shim";
            } else if (!(r.src == s) || r.srcCh != (int)*sp.getDirectionChannel()) {
                why = "route " + std::to_string(idx.getInt()) + ": its hops leave from different ports";
                ok = false;
                return;
            }
            r.dsts.push_back({{(int)dtile.getCol(), (int)dtile.getRow()}, (int)*dp.getDirectionChannel()});
        }
    });
    for (auto &[i, r] : routes)
        plan.routes.push_back(r);
    return ok;
}

} // namespace dfplan
