/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plan routes (dmaphop.plan_route, doc/design/dmaphop_dataflow_plan.md) -> routinghw, in the
// same DmaphopToRoutinghwPass as every generated flow: circuit-switched nets routed over the ports the
// generated flows (the routinghw ops already in the module) and the control plane (ResourceMgr
// reservations) left free, with the port counts and shim port numbers of the same hardware model
// (hwresource.cpp). The result is ordinary routinghw.connectsinglestreamswitchport /
// enableexttoaieshimport ops, so RoutingHWVerify, the provenance / resource maps and RoutingHWLower see
// the plan's routes like any other.

#include <cstdlib>
#include "planroutes.h"

#include "hw/ResourceManager.h"
#include "routing/routingtopology.h"
#include "routinghwmanager.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "llvm/Support/raw_ostream.h"

#include <deque>
#include <map>
#include <set>
#include <tuple>

using namespace mlir;

namespace {

const char *dirStr(PortDirection d) {
    switch (d) {
    case PortDirection::North:
        return "NORTH";
    case PortDirection::South:
        return "SOUTH";
    case PortDirection::East:
        return "EAST";
    case PortDirection::West:
        return "WEST";
    case PortDirection::DMA:
        return "DMA";
    default:
        return "NONE";
    }
}
PortDirection dirOf(StringRef s) {
    return s == "NORTH"   ? PortDirection::North
           : s == "SOUTH" ? PortDirection::South
           : s == "EAST"  ? PortDirection::East
           : s == "WEST"  ? PortDirection::West
           : s == "DMA"   ? PortDirection::DMA
                          : PortDirection::NONE;
}
int stepC(PortDirection d) { return d == PortDirection::East ? 1 : d == PortDirection::West ? -1 : 0; }
int stepR(PortDirection d) { return d == PortDirection::North ? 1 : d == PortDirection::South ? -1 : 0; }

// (row, col, master?, dir, hardware port number)
using PortKey = std::tuple<int, int, bool, PortDirection, int>;

struct Fabric {
    ResourceMgr &rm;
    std::set<PortKey> used;

    bool inside(int r, int c) const {
        return r >= 0 && r < rm.rows() && c >= 0 && c < rm.cols() && rm.tileInPartition(r, c);
    }
    TileType kind(int r, int c) const { return rm.tile(r, c).type(); }
    bool isMem(int r, int c) const { return kind(r, c) == TileType::Mem; }
    // ports of a direction / role on a tile, as hardware port numbers (the hardware model's port list)
    std::vector<int> ports(int r, int c, bool master, PortDirection d) const {
        std::vector<int> out;
        const DirBank &b = rm.tile(r, c).bank(d);
        const auto &v = master ? b.master : b.slave;
        for (size_t i = 0; i < v.size(); i++) {
            PortSlot s = v[i];
            out.push_back(s.getportNum() < 0 ? (int)i : s.getportNum());
        }
        return out;
    }
    bool has(int r, int c, bool master, PortDirection d, int p) const {
        for (int x : ports(r, c, master, d))
            if (x == p)
                return true;
        return false;
    }
    bool free(int r, int c, bool master, PortDirection d, int p) const {
        return has(r, c, master, d, p) && !used.count({r, c, master, d, p});
    }
    void take(int r, int c, bool master, PortDirection d, int p) { used.insert({r, c, master, d, p}); }
};

bool tileRC(Value v, int &r, int &c) {
    Operation *d = v ? v.getDefiningOp() : nullptr;
    if (!d)
        return false;
    auto rr = d->getAttrOfType<IntegerAttr>("row"), cc = d->getAttrOfType<IntegerAttr>("col");
    if (!rr || !cc)
        return false;
    r = (int)rr.getInt(), c = (int)cc.getInt();
    return true;
}

// What the module's routinghw ops and the control plane already occupy.
void collectUsed(ModuleOp module, Fabric &f) {
    auto mark = [&](int r, int c, bool master, Attribute dir, Attribute idx) {
        auto d = dyn_cast_or_null<StringAttr>(dir);
        auto i = dyn_cast_or_null<IntegerAttr>(idx);
        if (d && i && dirOf(d.getValue()) != PortDirection::NONE)
            f.take(r, c, master, dirOf(d.getValue()), (int)i.getInt());
    };
    module.walk([&](Operation *op) {
        int r, c;
        if (op->getNumOperands() == 0 || !tileRC(op->getOperand(0), r, c))
            return;
        if (std::getenv("AIEHLC_PLAN_ROUTE_DEBUG") && r >= 2 && r <= 4) {
            std::string s;
            llvm::raw_string_ostream os(s);
            op->print(os);
            llvm::errs() << "[planroute] used at (" << c << ", " << r << "): " << os.str().substr(0, 260) << "\n";
        }
        if (isa<routinghw::ConnectStreamSingleSwitchPort>(op)) {
            mark(r, c, false, op->getAttr("slaveportdirection"), op->getAttr("slaveportidx"));
            mark(r, c, true, op->getAttr("masterportdirection"), op->getAttr("masterportidx"));
        } else if (isa<routinghw::ConnectStreamPktSwitchPort>(op)) {
            mark(r, c, false, op->getAttr("receiveslavedirection"), op->getAttr("receiveslaveportidx"));
            mark(r, c, false, op->getAttr("localdmadirection"), op->getAttr("localdmaportidx"));
            mark(r, c, true, op->getAttr("forwardmasterdirection"), op->getAttr("forwardmasterportidx"));
        } else if (auto e = dyn_cast<routinghw::EnableExtToAieShimPort>(op)) {
            f.take(r, c, false, PortDirection::South, (int)e.getPortidx());
        } else if (auto e = dyn_cast<routinghw::EnableAieToExtShimPort>(op)) {
            f.take(r, c, true, PortDirection::South, (int)e.getPortidx());
        }
    });
    // control-plane stream ports (reserveControlPlaneResources: row fabric, spine)
    for (int r = 0; r < f.rm.rows(); r++)
        for (int c = 0; c < f.rm.cols(); c++) {
            if (!f.rm.tileInPartition(r, c))
                continue;
            for (PortDirection d :
                 {PortDirection::North, PortDirection::South, PortDirection::East, PortDirection::West}) {
                const DirBank &b = f.rm.tile(r, c).bank(d);
                for (int m = 0; m < 2; m++) {
                    const auto &v = m ? b.master : b.slave;
                    for (size_t i = 0; i < v.size(); i++) {
                        PortSlot s = v[i];
                        if (s.used && s.ioId == ResourceMgr::kControlPlaneOwner)
                            f.take(r, c, m == 1, d, s.getportNum() < 0 ? (int)i : s.getportNum());
                    }
                }
            }
        }
}

struct Emitter {
    OpBuilder &b;
    Location loc;
    std::map<std::pair<int, int>, Value> tiles;
    Value tile(int r, int c) {
        auto it = tiles.find({r, c});
        if (it != tiles.end())
            return it->second;
        Value v = b.create<routinghw::TileCreate>(loc, b.getI32Type(), b.getI32IntegerAttr(r), b.getI32IntegerAttr(c),
                                                  b.getStringAttr("dataflow plan route"));
        return tiles[{r, c}] = v;
    }
    void conn(int r, int c, PortDirection sd, int si, PortDirection md, int mi) {
        b.create<routinghw::ConnectStreamSingleSwitchPort>(loc, b.getI32Type(), tile(r, c), dirStr(sd), si, dirStr(md),
                                                           mi);
    }
};

struct In {
    PortDirection dir;
    int idx;
};

// One multicast net: BFS from the tree grown so far to each destination, with the MemTile rule that a
// SOUTH / NORTH slave k passes only to a SOUTH / NORTH master k (skill memtilepassthroughlane).
bool routeNet(Fabric &f, Emitter &e, int sr, int sc, In src, ArrayRef<std::tuple<int, int, int>> dsts,
              std::string &why) {
    std::map<std::pair<int, int>, In> tree;
    tree[{sr, sc}] = src;
    using State = std::tuple<int, int, PortDirection, int>; // row, col, incoming slave dir, port
    const PortDirection kDirs[] = {PortDirection::North, PortDirection::East, PortDirection::West,
                                   PortDirection::South};
    for (auto [dr, dc, dch] : dsts) {
        if (!tree.count({dr, dc})) {
            std::map<State, std::tuple<State, PortDirection, int, bool>> prev;
            std::deque<State> q;
            for (auto &[t, s] : tree) {
                State st{t.first, t.second, s.dir, s.idx};
                prev[st] = {st, PortDirection::NONE, -1, true};
                q.push_back(st);
            }
            bool found = false;
            State goal;
            while (!q.empty() && !found) {
                State st = q.front();
                q.pop_front();
                auto [r, c, sd, si] = st;
                for (PortDirection d : kDirs) {
                    int nr = r + stepR(d), nc = c + stepC(d);
                    if (!f.inside(nr, nc) || tree.count({nr, nc}))
                        continue;
                    const bool vert = [](PortDirection x) {
                        return x == PortDirection::North || x == PortDirection::South;
                    }(sd) && (d == PortDirection::North || d == PortDirection::South);
                    const bool tied = f.isMem(r, c) && vert;
                    for (int k : f.ports(r, c, true, d)) {
                        if ((tied && k != si) || !f.free(r, c, true, d, k) || !f.free(nr, nc, false, opposite(d), k))
                            continue;
                        State ns{nr, nc, opposite(d), k};
                        if (prev.count(ns))
                            continue;
                        prev[ns] = {st, d, k, false};
                        if (nr == dr && nc == dc) {
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
                if (std::getenv("AIEHLC_PLAN_ROUTE_DEBUG")) // the column's vertical ports: free (+) / taken (x)
                    for (int r = 0; r <= std::max(dr, sr); r++) {
                        llvm::errs() << "[planroute] (" << dc << ", " << r << ")";
                        for (PortDirection d : {PortDirection::North, PortDirection::South})
                            for (int m = 1; m >= 0; m--) {
                                llvm::errs() << (d == PortDirection::North ? " N" : " S") << (m ? "m" : "s") << ":";
                                if (f.inside(r, dc))
                                    for (int k : f.ports(r, dc, m == 1, d))
                                        llvm::errs() << k << (f.free(r, dc, m == 1, d, k) ? "+" : "x");
                            }
                        llvm::errs() << "\n";
                    }
                why = "no free path to (" + std::to_string(dc) + ", " + std::to_string(dr) + ")";
                return false;
            }
            std::vector<std::tuple<int, int, PortDirection, int>> path; // tile, master dir, port
            for (State st = goal; !std::get<3>(prev[st]);) {
                auto [ps, d, k, root] = prev[st];
                path.push_back({std::get<0>(ps), std::get<1>(ps), d, k});
                st = ps;
            }
            for (auto it = path.rbegin(); it != path.rend(); ++it) {
                auto [r, c, d, k] = *it;
                In in = tree[{r, c}];
                f.take(r, c, true, d, k);
                f.take(r + stepR(d), c + stepC(d), false, opposite(d), k);
                tree[{r + stepR(d), c + stepC(d)}] = {opposite(d), k};
                e.conn(r, c, in.dir, in.idx, d, k);
            }
        }
        if (!f.free(dr, dc, true, PortDirection::DMA, dch)) {
            why = "DMA master " + std::to_string(dch) + " of (" + std::to_string(dc) + ", " + std::to_string(dr) +
                  ") is taken";
            return false;
        }
        f.take(dr, dc, true, PortDirection::DMA, dch);
        In in = tree[{dr, dc}];
        e.conn(dr, dc, in.dir, in.idx, PortDirection::DMA, dch);
    }
    return true;
}

} // namespace

FailureOr<PlanRouteSet> takeDataflowPlanRoutes(ModuleOp module) {
    PlanRouteSet set{{}, nullptr, UnknownLoc::get(module.getContext())};
    if (!dfplan::hasPlanPaths(module))
        return set;
    module.walk([&](Operation *op) {
        // the routes go to the front of the routing function (where the plan's attribute-only route ops were)
        if (!set.at && op->hasAttr("stream") && op->getName().getStringRef() == "dmaphop.create_path")
            if (auto fn = op->getParentOfType<func::FuncOp>())
                set.at = &fn.getBody().front(), set.loc = op->getLoc();
    });
    dfplan::DataflowPlan p;
    std::string why;
    if (!dfplan::readPlanPaths(module, p, why)) {
        module.emitError() << "[dataflow plan] " << why;
        return failure();
    }
    set.routes = p.routes;
    dfplan::erasePlanPaths(module);
    return set;
}

LogicalResult lowerDataflowPlanRoutes(ModuleOp module, RoutingTopology &topo, const PlanRouteSet &set) {
    if (set.routes.empty())
        return success();
    Fabric f{*topo.getRM(), {}};
    collectUsed(module, f);
    int conns = 0;
    OpBuilder b(module.getContext());
    b.setInsertionPointToStart(set.at);
    const Location loc = set.loc;
    for (const dfplan::PlanRoute &r : set.routes) {
        Emitter e{b, loc, {}};
        const int sc = r.src.col, sr = r.src.row, ch = r.srcCh;
        In s{PortDirection::DMA, ch};
        const bool shim = r.srcShim;
        if (shim) {
            // A shim MM2S channel enters the switch on the SOUTH slave port the hardware model lists for it
            // (hwresource.cpp: the shim's SOUTH "mux" list, named from the mux side, e.g. 3 / 7 on AIE2PS).
            std::vector<int> mux = f.ports(sr, sc, true, PortDirection::South);
            if (ch < 0 || ch >= (int)mux.size())
                return emitError(loc) << "[dataflow plan] shim MM2S channel " << ch << " does not exist";
            s = {PortDirection::South, mux[ch]};
            b.create<routinghw::EnableExtToAieShimPort>(loc, b.getI32Type(), e.tile(sr, sc), "SOUTH", mux[ch]);
        }
        if (shim ? f.used.count({sr, sc, false, s.dir, s.idx}) != 0 : !f.free(sr, sc, false, s.dir, s.idx))
            return emitError(loc) << "[dataflow plan] route source (" << sc << ", " << sr << ") " << dirStr(s.dir)
                                  << " " << s.idx << " is already used by a generated route";
        f.take(sr, sc, false, s.dir, s.idx);
        SmallVector<std::tuple<int, int, int>> dsts;
        for (const auto &[t, dch] : r.dsts)
            dsts.push_back({t.row, t.col, dch});
        std::string why;
        const size_t before = f.used.size();
        if (!routeNet(f, e, sr, sc, s, dsts, why))
            return emitError(loc) << "[dataflow plan] route from (" << sc << ", " << sr << ") ch " << ch << ": " << why;
        conns += (int)(f.used.size() - before) / 2;
    }
    llvm::outs() << "[DataflowPlan] routed " << set.routes.size()
                 << " plan net(s) in DmaphopToRoutinghwPass as routinghw ops (~" << conns << " switch hops)\n";
    return success();
}
