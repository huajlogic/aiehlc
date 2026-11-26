/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Readback (doc/design/dmaphop_dataflow_plan.md, "Readback"): the dfschedule DMA program -> the levels
// above it. Every op the plan materializes carries its role (dfplan.tag, plandma.cpp), so an edited
// dfschedule program (AIEHLC_DFSCHEDULE_IR_IN / AIEHLC_DFSCHEDULE_KERNEL_IR_IN) is lifted into what the
// higher levels can say: resources (BD / lock ids, buffer addresses -> dmaphop.plan_resources, adopted by
// the allocator) and ring sizes (-> plan_stream ring). The program is then regenerated from the lifted plan
// and must come out identical to the edited one -- an edit that cannot be expressed above dfschedule is
// reported, not silently dropped. The read-back plan is written to the dfscheblueprint level
// (dfscheblueprint.plan on the shared tensors' declare_data) and to the dmaphop level (a re-enterable dump).

#include "dataflowplan.h"

#include "dfschedulemanager.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/Parser/Parser.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdlib>
#include <map>
#include <sstream>

namespace dfplan {

using namespace mlir;

namespace {

std::vector<std::string> split(const std::string &s) {
    std::vector<std::string> out;
    std::stringstream ss(s);
    for (std::string x; std::getline(ss, x, '/');)
        out.push_back(x);
    return out;
}

int constInt(Value v) {
    if (auto c = v ? v.getDefiningOp<arith::ConstantOp>() : arith::ConstantOp())
        if (auto i = dyn_cast<IntegerAttr>(c.getValue()))
            return (int)i.getInt();
    return -1;
}

struct MemAcc {
    std::map<int, int> locks;
    std::map<int, std::pair<int, int64_t>> in; // i -> (bd, addr)
    std::map<int, std::map<int, int>> out;     // route k -> b -> bd
};

struct Acc {
    std::map<int, int> E;
    std::map<std::pair<int, int>, int> R;
    int go = -1, sync = -1;
    std::map<std::pair<int, int>, std::pair<int, int64_t>> bd; // (ch, k) -> (bd, addr)
    std::map<std::pair<int, int>, MemAcc> mem;                 // (stream, col)
    std::map<std::pair<int, int>, int> shim;
};

void collect(ModuleOp m, Acc &a) {
    if (!m)
        return;
    m.walk([&](Operation *op) {
        auto tag = op->getAttrOfType<StringAttr>("dfplan.tag");
        if (!tag)
            return;
        auto t = split(tag.getValue().str());
        auto I = [&](size_t i) { return i < t.size() ? std::atoi(t[i].c_str()) : -1; };
        int id = -1;
        int64_t addr = 0;
        if (auto l = dyn_cast<dfschedule::ConfigLockSetOp>(op))
            id = (int)(int32_t)l.getLockId();
        else if (auto b = dyn_cast<dfschedule::ConfigTileBdOp>(op)) // (a shim transfer: its plan-program record)
            id = (int)(int32_t)b.getBdId(), addr = (int64_t)b.getAddr();
        else if (auto d = dyn_cast<dfschedule::ConfigDmaBdOp>(op))
            id = constInt(d.getBdId());
        else
            return; // channel ops: derived from the BDs
        if (t[0] == "core") {
            if (t[1] == "E")
                a.E[I(2)] = id;
            else if (t[1] == "R")
                a.R[{I(2), I(3)}] = id;
            else if (t[1] == "go")
                a.go = id;
            else if (t[1] == "sync")
                a.sync = id;
            else if (t[1] == "bd")
                a.bd[{I(2), I(3)}] = {id, addr};
        } else if (t[0] == "mem") {
            MemAcc &m2 = a.mem[{I(1), I(2)}];
            if (t[3] == "lock")
                m2.locks[I(4)] = id;
            else if (t[3] == "in")
                m2.in[I(4)] = {id, addr};
            else if (t[3] == "out")
                m2.out[I(4)][I(5)] = id;
        } else if (t[0] == "shim") {
            a.shim[{I(1), I(2)}] = id;
        }
    });
}

bool liftCore(const Acc &a, const DataflowPlan &p, PlanResources &out, std::string &why) {
    if (a.E.empty() && a.R.empty() && a.bd.empty())
        return true;
    const PlanStream s = p.coreProtocol();
    out.lockE = a.E.count(0) ? a.E.at(0) : -1;
    for (auto &[b, id] : a.E)
        if (id != out.lockE + b) {
            why =
                "core E locks must be in a row (E + buffer): E" + std::to_string(b) + " is lock " + std::to_string(id);
            return false;
        }
    out.lockF = a.R.count({0, 0}) ? a.R.at({0, 0}) : -1;
    out.handDelta = a.R.count({1, 0}) ? a.R.at({1, 0}) - out.lockF : s.channels;
    if (out.handDelta < s.channels) {
        why = "core reader-lock rows overlap: the rows are " + std::to_string(out.handDelta) + " apart, a row holds " +
              std::to_string(s.channels) + " channels";
        return false;
    }
    for (auto &[ic, id] : a.R)
        if (id != out.lockF + ic.first * out.handDelta + ic.second) {
            why = "core reader lock (reader " + std::to_string(ic.first) + ", channel " + std::to_string(ic.second) +
                  ") is " + std::to_string(id) + ", not F + reader x delta + channel";
            return false;
        }
    out.lockGo = a.go, out.lockSync = a.sync;
    out.coreBd.assign(s.channels, -1);
    for (auto &[ck, v] : a.bd) {
        if (ck.second == 0)
            out.coreBd[ck.first] = v.first;
    }
    const int64_t part = s.chunkBytes() / s.parts;
    out.slotBase = a.bd.count({0, 0}) ? a.bd.at({0, 0}).second : 0;
    for (auto &[ck, v] : a.bd) {
        const int buf = ck.first + s.channels * ck.second;
        if (v.first != out.coreBd[ck.first] + ck.second || v.second != out.slotBase + buf * part) {
            why = "core BD (channel " + std::to_string(ck.first) + ", slot " + std::to_string(ck.second) +
                  "): ids must run in a row per channel and buffers sit at slot base + buffer x part";
            return false;
        }
    }
    out.slotBytes = (int64_t)s.buffers() * s.chunkBytes();
    out.hasCore = true;
    return true;
}

bool liftMem(const Acc &a, DataflowPlan &p, PlanResources &out, std::string &why) {
    if (a.mem.empty() && a.shim.empty())
        return true;
    out.mem.assign(p.streams.size(), std::vector<PlanResources::Mem>(p.meshCols));
    out.shimBd.assign(p.streams.size(), std::vector<int>(p.meshCols, -1));
    for (auto &[key, m] : a.mem) {
        auto [si, c] = key;
        if (si < 0 || si >= (int)p.streams.size() || c < 0 || c >= p.meshCols || m.in.empty())
            continue;
        PlanResources::Mem &r = out.mem[si][c];
        for (auto &[j, id] : m.locks)
            r.locks.push_back(id);
        r.bdIn = m.in.begin()->second.first;
        r.addr = m.in.begin()->second.second;
        int expect = r.bdIn;
        for (auto &[i, v] : m.in)
            if (v.first != expect++) {
                why = "MemTile of stream " + std::to_string(si) + " column " + std::to_string(c) +
                      ": the S2MM chain's BDs must run in a row";
                return false;
            }
        for (auto &[k, bds] : m.out) {
            r.bdOut.push_back(bds.begin()->second);
            int e = bds.begin()->second;
            for (auto &[b, id] : bds)
                if (id != e++) {
                    why = "MemTile of stream " + std::to_string(si) + " column " + std::to_string(c) +
                          ": an MM2S chain's BDs must run in a row";
                    return false;
                }
        }
        PlanStream &s = p.streams[si];
        if (s.stage == "memtile_ring") { // the ring the chain spells
            const int k = (int)m.out.size(), n = (int)m.in.size(), ring = k <= 1 ? n : n / k;
            if (ring != s.ring) {
                llvm::outs() << "[DataflowPlan] readback: stream " << s.arg << " ring " << s.ring << " -> " << ring
                             << " (from the dfschedule program)\n";
                s.ring = ring;
            }
        }
    }
    for (auto &[key, id] : a.shim)
        if (key.first >= 0 && key.first < (int)p.streams.size() && key.second >= 0 && key.second < p.meshCols)
            out.shimBd[key.first][key.second] = id;
    out.hasMem = !a.mem.empty(), out.hasShim = !a.shim.empty();
    return true;
}

// the plan program read back, for checkReadBack
std::string g_programText;

std::string readFile(const char *path) {
    auto buf = llvm::MemoryBuffer::getFile(path);
    return buf ? (*buf)->getBuffer().str() : std::string();
}

int traceArg(Value v) {
    for (int guard = 0; guard < 32 && v; guard++) {
        if (auto ba = dyn_cast<BlockArgument>(v))
            return (int)ba.getArgNumber();
        Operation *d = v.getDefiningOp();
        if (!d || d->getNumOperands() == 0)
            return -1;
        v = d->getOperand(0);
    }
    return -1;
}

ArrayAttr ints(Builder &b, const std::vector<int64_t> &v) {
    SmallVector<Attribute> a;
    for (int64_t x : v)
        a.push_back(b.getI64IntegerAttr(x));
    return b.getArrayAttr(a);
}

SmallVector<NamedAttribute> resourceAttrsOf(Builder &b, const PlanResources &r) {
    SmallVector<NamedAttribute> na;
    na.push_back(b.getNamedAttr("core_bd", ints(b, std::vector<int64_t>(r.coreBd.begin(), r.coreBd.end()))));
    na.push_back(b.getNamedAttr("lock_f", b.getI64IntegerAttr(r.lockF)));
    na.push_back(b.getNamedAttr("hand_delta", b.getI64IntegerAttr(r.handDelta)));
    na.push_back(b.getNamedAttr("lock_e", b.getI64IntegerAttr(r.lockE)));
    na.push_back(b.getNamedAttr("lock_go", b.getI64IntegerAttr(r.lockGo)));
    na.push_back(b.getNamedAttr("lock_sync", b.getI64IntegerAttr(r.lockSync)));
    na.push_back(b.getNamedAttr("slot_base", b.getI64IntegerAttr(r.slotBase)));
    SmallVector<Attribute> mem, shim;
    for (size_t si = 0; si < r.mem.size(); si++)
        for (size_t c = 0; c < r.mem[si].size(); c++) {
            const auto &m = r.mem[si][c];
            if (m.bdIn < 0)
                continue;
            std::vector<int64_t> e{(int64_t)si, (int64_t)c, m.addr, m.bdIn, (int64_t)m.bdOut.size()};
            e.insert(e.end(), m.bdOut.begin(), m.bdOut.end());
            e.push_back((int64_t)m.locks.size());
            e.insert(e.end(), m.locks.begin(), m.locks.end());
            mem.push_back(ints(b, e));
        }
    for (size_t si = 0; si < r.shimBd.size(); si++)
        for (size_t c = 0; c < r.shimBd[si].size(); c++)
            if (r.shimBd[si][c] >= 0)
                shim.push_back(ints(b, {(int64_t)si, (int64_t)c, r.shimBd[si][c]}));
    na.push_back(b.getNamedAttr("mem", b.getArrayAttr(mem)));
    na.push_back(b.getNamedAttr("shim", b.getArrayAttr(shim)));
    return na;
}
SmallVector<NamedAttribute> resourceAttrs(Builder &b, const DataflowPlan &p) { return resourceAttrsOf(b, p.res); }

} // namespace

bool liftDfschedulePlan(ModuleOp host, ModuleOp kernel, DataflowPlan &p, PlanResources &out, std::string &why) {
    Acc a;
    collect(host, a);
    collect(kernel, a);
    return liftCore(a, p, out, why) && liftMem(a, p, out, why);
}

OwningOpRef<ModuleOp> buildPlanProgram(ModuleOp host, ModuleOp kernel) {
    MLIRContext *ctx = host ? host.getContext() : kernel.getContext();
    OpBuilder b(ctx);
    OwningOpRef<ModuleOp> prog = ModuleOp::create(b.getUnknownLoc());
    b.setInsertionPointToEnd(prog->getBody());
    std::map<std::pair<int, int>, Value> tiles;
    Value self;
    auto tileOf = [&](Value v) -> Value {
        Operation *d = v ? v.getDefiningOp() : nullptr;
        if (d && isa<dfschedule::DeclareTileSelfOp>(d)) {
            if (!self)
                self = b.create<dfschedule::DeclareTileSelfOp>(b.getUnknownLoc(), dfschedule::TileType::get(ctx));
            return self;
        }
        auto t = d ? dyn_cast<dfschedule::DeclareTileOp>(d) : dfschedule::DeclareTileOp();
        if (!t)
            return Value();
        auto key = std::make_pair((int)t.getCol(), (int)t.getRow());
        auto it = tiles.find(key);
        if (it != tiles.end())
            return it->second;
        return tiles[key] = b.create<dfschedule::DeclareTileOp>(b.getUnknownLoc(), dfschedule::TileType::get(ctx),
                                                                t.getColAttr(), t.getRowAttr());
    };
    for (ModuleOp m : {host, kernel}) {
        if (!m)
            continue;
        m.walk([&](Operation *op) {
            auto tag = op->getAttrOfType<StringAttr>("dfplan.tag");
            if (!tag)
                return;
            if (auto d = dyn_cast<dfschedule::ConfigDmaBdOp>(op)) { // a shim transfer -> its record
                Value t = tileOf(d.getTile());
                auto rec = b.create<dfschedule::ConfigTileBdOp>(
                    b.getUnknownLoc(), t, constInt(d.getBdId()), (int64_t)constInt(d.getOffset()), (int32_t)d.getLen(),
                    d.getDimStridesAttr(), d.getDimWrapsAttr(), (int32_t)d.getIterStepSize(), (int32_t)d.getIterWrap(),
                    -1, 0, -1, 0, -1);
                rec->setAttr("dfplan.tag", tag);
                return;
            }
            Value t = tileOf(op->getOperand(0));
            if (!t)
                return;
            Operation *c = b.clone(*op);
            c->setOperand(0, t);
        });
    }
    return prog;
}

std::string printOp(ModuleOp m) {
    std::string s;
    llvm::raw_string_ostream os(s);
    m.print(os);
    os.flush();
    return s;
}

bool readBackDfscheduleFiles(MLIRContext *ctx, DataflowPlan &p, std::string &why) {
    const char *path = std::getenv("AIEHLC_DFSCHEDULE_PLAN_IN");
    if (!path || !*path)
        return true;
    OwningOpRef<ModuleOp> prog = parseSourceFile<ModuleOp>(path, ctx);
    if (!prog) {
        why = std::string("cannot parse the dfschedule plan program ") + path;
        return false;
    }
    g_programText = readFile(path);
    PlanResources r;
    if (!liftDfschedulePlan(*prog, ModuleOp(), p, r, why))
        return false;
    p.pinned = r;
    llvm::outs() << "[DataflowPlan] readback: lifted the dfschedule plan program " << path << ": core "
                 << (r.hasCore ? "yes" : "no") << ", MemTiles " << (r.hasMem ? "yes" : "no") << ", shim "
                 << (r.hasShim ? "yes" : "no") << "\n";
    return true;
}

bool checkReadBack(ModuleOp host, ModuleOp kernel, const std::string &dumpPath, std::string &why) {
    OwningOpRef<ModuleOp> prog = buildPlanProgram(host, kernel);
    const std::string got = printOp(*prog);
    if (!dumpPath.empty()) {
        std::error_code ec;
        llvm::raw_fd_ostream f(dumpPath, ec);
        if (!ec)
            f << got;
    }
    if (g_programText.empty())
        return true;
    if (got == g_programText) {
        llvm::outs() << "[DataflowPlan] readback: the regenerated dfschedule plan program equals the edited one\n";
        return true;
    }
    std::istringstream a(g_programText), b(got);
    std::string la, lb, first;
    int line = 0, diffs = 0;
    while (true) {
        bool ea = !std::getline(a, la), eb = !std::getline(b, lb);
        if (ea && eb)
            break;
        line++;
        if (la != lb && diffs++ == 0)
            first = "line " + std::to_string(line) + ":\n  edited:      " + la + "\n  regenerated: " + lb;
    }
    why = "the edited dfschedule plan program has " + std::to_string(diffs) +
          " line(s) the dmaphop / dfscheblueprint levels cannot express (resource ids, buffer addresses and ring "
          "sizes read back; nothing else); first at " +
          first;
    return false;
}

void readPlanResources(Operation *op, DataflowPlan &p) { readPlanResources(op->getAttrDictionary(), p); }

void readPlanResources(DictionaryAttr d, DataflowPlan &p) {
    PlanResources &r = p.pinned;
    auto I = [&](StringRef n, int dflt) {
        auto a = d.getAs<IntegerAttr>(n);
        return a ? (int)a.getInt() : dflt;
    };
    auto vec = [](Attribute a) {
        std::vector<int64_t> v;
        if (auto arr = dyn_cast_or_null<ArrayAttr>(a))
            for (Attribute x : arr)
                if (auto i = dyn_cast<IntegerAttr>(x))
                    v.push_back(i.getInt());
        return v;
    };
    for (int64_t x : vec(d.get("core_bd")))
        r.coreBd.push_back((int)x);
    r.lockF = I("lock_f", -1), r.handDelta = I("hand_delta", 0), r.lockE = I("lock_e", -1);
    r.lockGo = I("lock_go", -1), r.lockSync = I("lock_sync", -1);
    if (auto a = d.getAs<IntegerAttr>("slot_base"))
        r.slotBase = a.getInt();
    r.hasCore = !r.coreBd.empty() && r.lockF >= 0 && r.lockE >= 0;
    r.mem.clear(), r.shimBd.clear();
    if (auto mem = d.getAs<ArrayAttr>("mem"))
        for (Attribute e : mem) {
            auto v = vec(e);
            if (v.size() < 6)
                continue;
            const size_t si = v[0], c = v[1];
            if (r.mem.size() <= si)
                r.mem.resize(si + 1);
            if (r.mem[si].size() <= c)
                r.mem[si].resize(c + 1);
            PlanResources::Mem &m = r.mem[si][c];
            m.addr = v[2], m.bdIn = (int)v[3];
            size_t i = 4, nOut = v[i++];
            for (size_t k = 0; k < nOut && i < v.size(); k++)
                m.bdOut.push_back((int)v[i++]);
            size_t nL = i < v.size() ? v[i++] : 0;
            for (size_t k = 0; k < nL && i < v.size(); k++)
                m.locks.push_back((int)v[i++]);
            r.hasMem = true;
        }
    if (auto shim = d.getAs<ArrayAttr>("shim"))
        for (Attribute e : shim) {
            auto v = vec(e);
            if (v.size() != 3)
                continue;
            if (r.shimBd.size() <= (size_t)v[0])
                r.shimBd.resize(v[0] + 1);
            if (r.shimBd[v[0]].size() <= (size_t)v[1])
                r.shimBd[v[0]].resize(v[1] + 1, -1);
            r.shimBd[v[0]][v[1]] = (int)v[2];
            r.hasShim = true;
        }
}

// The whole plan on the dfscheblueprint level, typed: each shared tensor's declare_data carries its stream
// (#dmaphop.stream), the module the plan-level facts (replaced / shared args, persistent, BD write-once, the
// mesh the plan was laid out on), the routes (#dmaphop.route, in router order) and any pinned resources. The
// DMA program is derived from what planFromBlueprint reads back here (the pipeline checks it equals the
// dmaphop plan, then adopts it). withResources (the read-back dump) adds the assigned resources.
void annotateBlueprint(ModuleOp bp, const DataflowPlan &p, bool withResources) {
    if (!p.present)
        return;
    MLIRContext *ctx = bp.getContext();
    Builder b(ctx);
    auto i64s = [&](const std::vector<int> &v) {
        return DenseI64ArrayAttr::get(ctx, std::vector<int64_t>(v.begin(), v.end()));
    };
    bp->setAttr("dfscheblueprint.plan_args", i64s(p.replacedArgs));
    bp->setAttr("dfscheblueprint.plan_share_args", i64s(p.shareArgs));
    bp->setAttr("dfscheblueprint.plan_persistent", b.getBoolAttr(p.persistent));
    bp->setAttr("dfscheblueprint.plan_bd_once", b.getBoolAttr(p.bdOnce));
    bp->setAttr("dfscheblueprint.plan_mesh", i64s({p.colLo, p.meshCols, p.meshRows, p.coreRowBase, p.memtileRows}));
    SmallVector<Attribute> routes;
    for (const PlanRoute &r : p.routes)
        routes.push_back(routeToAttr(ctx, r));
    bp->setAttr("dfscheblueprint.plan_routes", b.getArrayAttr(routes));
    if (p.pinned.hasCore || p.pinned.hasMem || p.pinned.hasShim)
        bp->setAttr("dfscheblueprint.plan_pinned", b.getDictionaryAttr(resourceAttrsOf(b, p.pinned)));
    if (withResources && p.res.assigned)
        bp->setAttr("dfscheblueprint.plan_resources", b.getDictionaryAttr(resourceAttrs(b, p)));
    bp.walk([&](Operation *op) {
        if (op->getName().getStringRef() != "dfscheblueprint.declare_data" || op->getNumOperands() == 0)
            return;
        const int arg = traceArg(op->getOperand(0));
        for (const PlanStream &s : p.streams)
            if (s.arg == arg)
                op->setAttr("dfscheblueprint.plan_stream", streamToAttr(ctx, s));
    });
}

bool planFromBlueprint(ModuleOp bp, DataflowPlan &p, std::string &why) {
    p = DataflowPlan();
    auto args = bp->getAttrOfType<DenseI64ArrayAttr>("dfscheblueprint.plan_args");
    if (!args)
        return true; // no plan
    auto ints = [](DenseI64ArrayAttr a) {
        std::vector<int> v;
        if (a)
            for (int64_t x : a.asArrayRef())
                v.push_back((int)x);
        return v;
    };
    p.present = true;
    p.replacedArgs = ints(args);
    p.shareArgs = ints(bp->getAttrOfType<DenseI64ArrayAttr>("dfscheblueprint.plan_share_args"));
    auto flag = [&](StringRef n) {
        auto a = bp->getAttrOfType<BoolAttr>(n);
        return a && a.getValue();
    };
    p.persistent = flag("dfscheblueprint.plan_persistent");
    p.bdOnce = flag("dfscheblueprint.plan_bd_once");
    std::vector<int> mesh = ints(bp->getAttrOfType<DenseI64ArrayAttr>("dfscheblueprint.plan_mesh"));
    if (mesh.size() != 5) {
        why = "dfscheblueprint.plan_mesh must be [col_lo, mesh_cols, mesh_rows, core_row_base, memtile_rows]";
        return false;
    }
    p.colLo = mesh[0], p.meshCols = mesh[1], p.meshRows = mesh[2], p.coreRowBase = mesh[3], p.memtileRows = mesh[4];
    if (auto routes = bp->getAttrOfType<ArrayAttr>("dfscheblueprint.plan_routes"))
        for (Attribute a : routes) {
            PlanRoute r;
            if (!routeFromAttr(a, r)) {
                why = "dfscheblueprint.plan_routes holds a non-#dmaphop.route entry";
                return false;
            }
            p.routes.push_back(r);
        }
    if (auto pin = bp->getAttrOfType<DictionaryAttr>("dfscheblueprint.plan_pinned"))
        readPlanResources(pin, p);
    // the streams, one per replaced argument, in the plan's argument order
    std::map<int, PlanStream> byArg;
    bp.walk([&](Operation *op) {
        PlanStream s;
        if (op->getName().getStringRef() == "dfscheblueprint.declare_data" &&
            streamFromAttr(op->getAttr("dfscheblueprint.plan_stream"), s))
            byArg.emplace(s.arg, s);
    });
    for (int a : p.replacedArgs) {
        auto it = byArg.find(a);
        if (it == byArg.end()) {
            why = "replaced argument " + std::to_string(a) + " has no declare_data with a plan_stream";
            return false;
        }
        p.streams.push_back(it->second);
    }
    return true;
}

bool samePlanDataflow(const DataflowPlan &a, const DataflowPlan &b, MLIRContext *ctx, std::string &why) {
    Builder bl(ctx);
    auto routesEq = [&]() {
        if (a.routes.size() != b.routes.size())
            return false;
        for (size_t i = 0; i < a.routes.size(); i++)
            if (routeToAttr(ctx, a.routes[i]) != routeToAttr(ctx, b.routes[i]))
                return false;
        return true;
    };
    auto streamsEq = [&]() {
        if (a.streams.size() != b.streams.size())
            return false;
        for (size_t i = 0; i < a.streams.size(); i++)
            if (streamToAttr(ctx, a.streams[i]) != streamToAttr(ctx, b.streams[i]))
                return false;
        return true;
    };
    const std::pair<const char *, bool> checks[] = {
        {"present", a.present == b.present},
        {"replaced args", a.replacedArgs == b.replacedArgs},
        {"shared args", a.shareArgs == b.shareArgs},
        {"persistent / bd_once", a.persistent == b.persistent && a.bdOnce == b.bdOnce},
        {"mesh", a.colLo == b.colLo && a.meshCols == b.meshCols && a.meshRows == b.meshRows &&
                     a.coreRowBase == b.coreRowBase && a.memtileRows == b.memtileRows},
        {"routes", routesEq()},
        {"streams", streamsEq()},
        {"pinned resources",
         bl.getDictionaryAttr(resourceAttrsOf(bl, a.pinned)) == bl.getDictionaryAttr(resourceAttrsOf(bl, b.pinned))},
    };
    for (const auto &[what, same] : checks)
        if (!same) {
            why = std::string("the blueprint's plan differs from the dmaphop plan in its ") + what;
            return false;
        }
    return true;
}

void readBackDmaphop(ModuleOp snap, const DataflowPlan &p) {
    Builder b(snap.getContext());
    Operation *header = nullptr;
    SmallVector<Operation *> stale;
    snap.walk([&](Operation *op) {
        StringRef n = op->getName().getStringRef();
        if (n == "dmaphop.plan")
            header = op;
        else if (n == "dmaphop.plan_resources")
            stale.push_back(op);
    });
    for (Operation *op : stale)
        op->erase();
    // the streams (with the ring sizes the build ended with) + routes as plan paths, the form the pipeline reads
    std::string why;
    if (!writePlanPaths(snap, p, why))
        llvm::errs() << "[DataflowPlan] readback: " << why << "\n";
    if (!header || !p.res.assigned)
        return;
    OpBuilder ob(header->getContext());
    ob.setInsertionPointAfter(header);
    OperationState st(header->getLoc(), "dmaphop.plan_resources");
    st.addAttributes(resourceAttrs(b, p));
    ob.create(st);
}

} // namespace dfplan
