/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Plan reader: dmaphop.plan* ops -> DataflowPlan (see dataflowplan.h).

#include "dataflowplan.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Operation.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>

namespace dfplan {

using namespace mlir;

bool DataflowPlan::replaces(int arg) const {
    return std::find(replacedArgs.begin(), replacedArgs.end(), arg) != replacedArgs.end();
}

bool DataflowPlan::sharesArg(int arg) const {
    return std::find(shareArgs.begin(), shareArgs.end(), arg) != shareArgs.end();
}

std::set<int> DataflowPlan::coreS2mmChannels(int memtileRows) const {
    std::set<int> out;
    for (const auto &c : channels)
        for (const auto &t : c.tiles)
            if (c.s2mm && t.row > memtileRows)
                out.insert(c.ch);
    return out;
}

DataflowPlan &activePlan() {
    static DataflowPlan p;
    return p;
}

namespace {

struct Reader {
    Operation *op;
    bool ok = true;

    InFlightDiagnostic err() {
        ok = false;
        return op->emitError() << "[dataflow plan] " << op->getName().getStringRef() << ": ";
    }
    bool has(StringRef n) { return op->hasAttr(n); }
    int64_t i64(StringRef n, int64_t dflt, bool required = false) {
        Attribute a = op->getAttr(n);
        if (!a) {
            if (required)
                err() << "missing integer attribute '" << n << "'";
            return dflt;
        }
        if (auto ia = dyn_cast<IntegerAttr>(a))
            return ia.getValue().getSExtValue();
        if (auto ba = dyn_cast<BoolAttr>(a))
            return ba.getValue() ? 1 : 0;
        err() << "attribute '" << n << "' must be an integer";
        return dflt;
    }
    bool flag(StringRef n) { return i64(n, 0) != 0; }
    std::string str(StringRef n, StringRef dflt) {
        Attribute a = op->getAttr(n);
        if (!a)
            return dflt.str();
        if (auto s = dyn_cast<StringAttr>(a))
            return s.getValue().str();
        err() << "attribute '" << n << "' must be a string";
        return dflt.str();
    }
    std::vector<int64_t> ints(Attribute a, StringRef what) {
        std::vector<int64_t> v;
        auto arr = dyn_cast_or_null<ArrayAttr>(a);
        if (!arr) {
            err() << "'" << what << "' must be an array of integers";
            return v;
        }
        for (Attribute e : arr) {
            auto ia = dyn_cast<IntegerAttr>(e);
            if (!ia) {
                err() << "'" << what << "' must be an array of integers";
                return {};
            }
            v.push_back(ia.getValue().getSExtValue());
        }
        return v;
    }
    std::vector<int64_t> ints(StringRef n, bool required = true) {
        if (!has(n)) {
            if (required)
                err() << "missing array attribute '" << n << "'";
            return {};
        }
        return ints(op->getAttr(n), n);
    }
    std::vector<std::vector<int64_t>> nested(StringRef n, bool required = true) {
        std::vector<std::vector<int64_t>> v;
        if (!has(n)) {
            if (required)
                err() << "missing array attribute '" << n << "'";
            return v;
        }
        auto arr = dyn_cast<ArrayAttr>(op->getAttr(n));
        if (!arr) {
            err() << "'" << n << "' must be an array of integer arrays";
            return v;
        }
        for (Attribute e : arr)
            v.push_back(ints(e, n));
        return v;
    }
    std::vector<Tile> tiles() {
        std::vector<Tile> t;
        for (auto &p : nested("tiles")) {
            if (p.size() != 2) {
                err() << "each entry of 'tiles' must be [col, row]";
                return {};
            }
            t.push_back({(int)p[0], (int)p[1]});
        }
        if (t.empty() && ok)
            err() << "'tiles' is empty";
        return t;
    }
    Dims dims(StringRef n) {
        Dims d;
        for (auto &p : nested(n, /*required=*/false)) {
            if (p.size() != 2) {
                err() << "each entry of '" << n << "' must be [step, wrap]";
                return {};
            }
            d.push_back({p[0], p[1]});
        }
        if (d.size() > 3)
            err() << "'" << n << "' has " << d.size() << " dims; at most 3";
        return d;
    }
    void lockPair(StringRef n, int &id, int &val) {
        if (!has(n))
            return;
        auto v = ints(n);
        if (v.size() != 2) {
            err() << "'" << n << "' must be [lock, value]";
            return;
        }
        id = (int)v[0];
        val = (int)v[1];
    }
};

// The kernel argument a dmaphop.push moves: follow operand 0 up to the routing
// func's block argument (to_tensor <- createscheduletensor <- partitiontensor <-
// extract_data).
int traceArg(Value v) {
    for (int guard = 0; guard < 32 && v; guard++) {
        if (auto ba = dyn_cast<BlockArgument>(v)) {
            Operation *parent = ba.getOwner()->getParentOp();
            if (parent && parent->getName().getStringRef() == "func.func")
                return (int)ba.getArgNumber();
            return -1;
        }
        Operation *def = v.getDefiningOp();
        if (!def || def->getNumOperands() == 0)
            return -1;
        v = def->getOperand(0);
    }
    return -1;
}

void readHeader(Reader &r, DataflowPlan &p) {
    for (int64_t a : r.ints("replace_args"))
        p.replacedArgs.push_back((int)a);
    p.persistentGoLock = (int)r.i64("persistent_go_lock", -1);
    p.bdOnce = r.flag("bd_once");
    if (r.has("share_args"))
        for (int64_t a : r.ints("share_args")) {
            if (!p.replaces((int)a))
                r.err() << "share_args: arg " << a << " is not in replace_args";
            p.shareArgs.push_back((int)a);
        }
    if (p.persistentGoLock > 15)
        r.err() << "persistent_go_lock " << p.persistentGoLock << " is not a core lock (0..15)";
}

void readRoute(Reader &r, DataflowPlan &p) {
    PlanRoute rt;
    auto s = r.ints("src");
    if (s.size() != 3) {
        r.err() << "'src' must be [col, row, channel]";
        return;
    }
    rt.src = {(int)s[0], (int)s[1]};
    rt.srcCh = (int)s[2];
    std::string kind = r.str("src_kind", rt.src.row == 0 ? "shim" : "dma");
    if (kind != "shim" && kind != "dma")
        r.err() << "src_kind must be \"shim\" or \"dma\"";
    rt.srcShim = kind == "shim";
    if (rt.srcShim && rt.src.row != 0)
        r.err() << "a shim source must be on row 0";
    for (auto &d : r.nested("dsts")) {
        if (d.size() != 3) {
            r.err() << "each entry of 'dsts' must be [col, row, s2mm channel]";
            return;
        }
        rt.dsts.push_back({{(int)d[0], (int)d[1]}, (int)d[2]});
    }
    if (rt.dsts.empty())
        r.err() << "'dsts' is empty";
    p.routes.push_back(rt);
}

void readLock(Reader &r, DataflowPlan &p, int memtileRows) {
    PlanLock l;
    l.tiles = r.tiles();
    l.id = (int)r.i64("id", 0, true);
    l.init = (int)r.i64("init", 0, true);
    l.later = (int)r.i64("later", -1);
    l.once = r.flag("once");
    for (auto &t : l.tiles) {
        int maxId = (t.row >= 1 && t.row <= memtileRows) ? 63 : 15;
        if (t.row == 0 || l.id < 0 || l.id > maxId)
            r.err() << "lock " << l.id << " is not valid on tile (" << t.col << "," << t.row << ")";
    }
    p.locks.push_back(l);
}

void readBd(Reader &r, DataflowPlan &p, int memtileRows) {
    PlanBd b;
    b.tiles = r.tiles();
    b.bd = (int)r.i64("bd", 0, true);
    b.addr = r.i64("addr", 0, true);
    b.len = r.i64("len", 0, true);
    b.dims = r.dims("dims");
    if (r.has("iter")) {
        auto it = r.ints("iter");
        if (it.size() != 2)
            r.err() << "'iter' must be [step, wrap]";
        else {
            b.iterStep = it[0];
            b.iterWrap = it[1];
        }
    }
    r.lockPair("acq", b.acqLock, b.acqVal);
    r.lockPair("rel", b.relLock, b.relVal);
    b.next = (int)r.i64("next", -1);
    for (auto &t : b.tiles) {
        bool mem = t.row >= 1 && t.row <= memtileRows;
        int maxBd = mem ? 47 : 15;
        if (t.row == 0)
            r.err() << "use dmaphop.plan_shim_bd for shim tiles";
        if (b.bd < 0 || b.bd > maxBd || b.next > maxBd)
            r.err() << "BD id out of range on tile (" << t.col << "," << t.row << ")";
        for (auto &d : b.dims)
            if (d.second > (mem ? 1023 : 255))
                r.err() << "wrap " << d.second << " does not fit the " << (mem ? "10" : "8")
                        << "-bit BD wrap field (it would silently turn the dimension off)";
    }
    if (b.len <= 0 || b.len % 4)
        r.err() << "len must be a positive multiple of 4 bytes";
    p.bds.push_back(b);
}

void readChannel(Reader &r, DataflowPlan &p) {
    PlanChannel c;
    c.tiles = r.tiles();
    std::string dir = r.str("dir", "");
    if (dir != "s2mm" && dir != "mm2s")
        r.err() << "dir must be \"s2mm\" or \"mm2s\"";
    c.s2mm = dir == "s2mm";
    c.ch = (int)r.i64("ch", 0, true);
    c.startBd = (int)r.i64("start_bd", 0, true);
    c.repeat = (int)r.i64("repeat", 1);
    c.firstLaunchOnly = r.flag("first_launch_only");
    if (c.repeat < 1 || c.repeat > 256)
        r.err() << "repeat " << c.repeat << " outside 1..256 (8-bit start-queue repeat field)";
    p.channels.push_back(c);
}

void readShimBd(Reader &r, DataflowPlan &p) {
    PlanShimBd s;
    s.col = (int)r.i64("col", 0, true);
    s.ch = (int)r.i64("ch", 0, true);
    s.bd = (int)r.i64("bd", 0, true);
    s.arg = (int)r.i64("arg", 0, true);
    s.mm2s = r.str("dir", "mm2s") == "mm2s";
    s.offset = r.i64("offset", 0);
    s.len = r.i64("len", 0, true);
    s.dims = r.dims("dims");
    if (r.has("iter")) {
        auto it = r.ints("iter");
        if (it.size() != 2)
            r.err() << "'iter' must be [step, wrap]";
        else {
            s.iterStep = it[0];
            s.iterWrap = it[1];
        }
    }
    s.repeat = (int)r.i64("repeat", 1);
    s.firstLaunchOnly = r.flag("first_launch_only");
    if (s.bd < 0 || s.bd > 15)
        r.err() << "shim BD id " << s.bd << " outside 0..15";
    if (s.iterWrap > 64)
        r.err() << "iteration wrap " << s.iterWrap << " exceeds the 6-bit field (64)";
    if (!p.replaces(s.arg))
        r.err() << "arg " << s.arg << " is not in the plan's replace_args";
    p.shimBds.push_back(s);
}

void readParam(Reader &r, DataflowPlan &p) {
    PlanKernelParam k;
    k.name = r.str("name", "");
    if (k.name.empty())
        r.err() << "missing 'name'";
    if (r.has("value"))
        k.perMeshRow = {r.i64("value", 0)}, k.scalar = true;
    else
        k.perMeshRow = r.ints("per_mesh_row");
    p.params.push_back(k);
}

// Tag every create_path / push that moves a replaced argument.
void tagReplacedFlows(ModuleOp module, const DataflowPlan &plan) {
    Builder b(module.getContext());
    int tagged = 0;
    module.walk([&](Operation *op) {
        if (op->getName().getStringRef() != "dmaphop.push")
            return;
        int arg = traceArg(op->getOperand(0));
        if (arg < 0 || !plan.replaces(arg))
            return;
        op->setAttr("dmaphop.plan_replaced", b.getI64IntegerAttr(arg));
        if (Operation *path = op->getOperand(1).getDefiningOp())
            path->setAttr("dmaphop.plan_replaced", b.getI64IntegerAttr(arg));
        tagged++;
    });
    llvm::outs() << "[DataflowPlan] " << tagged << " generated flow(s) replaced by the plan\n";
}

} // namespace

bool collectDataflowPlan(ModuleOp module, DataflowPlan &plan, int memtileRows) {
    plan = DataflowPlan();
    plan.memtileRows = memtileRows;
    std::vector<Operation *> ops;
    module.walk([&](Operation *op) {
        if (op->getName().getStringRef().starts_with("dmaphop.plan"))
            ops.push_back(op);
    });
    if (ops.empty())
        return true;
    bool ok = true;
    // header first: replace_args is needed to check the shim BDs
    for (Operation *op : ops)
        if (op->getName().getStringRef() == "dmaphop.plan") {
            Reader r{op};
            if (plan.present)
                r.err() << "more than one dmaphop.plan";
            plan.present = true;
            readHeader(r, plan);
            ok &= r.ok;
        }
    if (!plan.present) {
        ops.front()->emitError() << "[dataflow plan] plan ops without a dmaphop.plan header";
        return false;
    }
    for (Operation *op : ops) {
        Reader r{op};
        StringRef n = op->getName().getStringRef();
        if (n == "dmaphop.plan_route")
            readRoute(r, plan);
        else if (n == "dmaphop.plan_lock")
            readLock(r, plan, memtileRows);
        else if (n == "dmaphop.plan_bd")
            readBd(r, plan, memtileRows);
        else if (n == "dmaphop.plan_channel")
            readChannel(r, plan);
        else if (n == "dmaphop.plan_shim_bd")
            readShimBd(r, plan);
        else if (n == "dmaphop.plan_kernel_param")
            readParam(r, plan);
        ok &= r.ok;
    }
    if (!ok)
        return false;
    for (const auto &c : plan.bds)
        for (const auto &t : c.tiles)
            if (t.row > memtileRows && (plan.coreRowBase < 0 || t.row < plan.coreRowBase))
                plan.coreRowBase = t.row;
    for (int a : plan.shareArgs)
        for (const char *suf : {"_VIEW", "_LOCK", "_FIRST"}) {
            std::string n = "S" + std::to_string(a) + suf;
            if (std::none_of(plan.params.begin(), plan.params.end(), [&](auto &k) { return k.name == n; })) {
                ops.front()->emitError() << "[dataflow plan] share_args has " << a << " but no kernel param " << n;
                return false;
            }
        }
    tagReplacedFlows(module, plan);
    Builder b(module.getContext());
    SmallVector<int64_t> args(plan.replacedArgs.begin(), plan.replacedArgs.end());
    module->setAttr("dmaphop.plan_replaced_args", b.getI64ArrayAttr(args));
    for (Operation *op : ops)
        op->erase();
    llvm::outs() << "[DataflowPlan] plan: " << plan.routes.size() << " routes, " << plan.bds.size() << " BDs, "
                 << plan.locks.size() << " locks, " << plan.channels.size() << " channels, " << plan.shimBds.size()
                 << " shim BDs, " << plan.params.size() << " kernel params"
                 << (plan.persistentGoLock >= 0 ? ", persistent kernel" : "") << (plan.bdOnce ? ", BD write-once" : "")
                 << "\n";
    return true;
}

} // namespace dfplan
