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

void erasePlanRoutes(ModuleOp module) {
    SmallVector<Operation *> routes;
    module.walk([&](Operation *op) {
        if (op->getName().getStringRef() == "dmaphop.plan_route")
            routes.push_back(op);
    });
    for (Operation *op : routes)
        op->erase();
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
    // `persistent = true`; the older `persistent_go_lock = N` reads as persistent (the go lock is allocated)
    p.persistent = r.flag("persistent") || r.i64("persistent_go_lock", -1) >= 0;
    p.bdOnce = r.flag("bd_once");
    if (r.has("share_args"))
        for (int64_t a : r.ints("share_args")) {
            if (!p.replaces((int)a))
                r.err() << "share_args: arg " << a << " is not in replace_args";
            p.shareArgs.push_back((int)a);
        }
}

void readRoute(Reader &r, DataflowPlan &p) {
    PlanRoute rt;
    rt.arg = (int)r.i64("arg", -1);
    if (rt.arg >= 0 && !p.replaces(rt.arg))
        r.err() << "arg " << rt.arg << " is not in the plan's replace_args";
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

// dmaphop.plan_stream: one shared operand's stream -- the dataflow decisions the DMA program is
// derived from (deriveDmaProgram, plandma.cpp).
void readStream(Reader &r, DataflowPlan &p) {
    PlanStream st;
    st.arg = (int)r.i64("arg", -1, true);
    st.role = r.str("role", "");
    if (st.role != "a" && st.role != "b")
        r.err() << "role must be \"a\" (strips over mesh-row pairs) or \"b\" (strips over columns x 2)";
    if (r.str("share", "neighbor") != "neighbor")
        r.err() << "only share = \"neighbor\" is implemented";
    st.stage = r.str("stage", "");
    st.ring = (int)r.i64("ring", 0);
    st.residentLaunches = r.str("resident", "launch") == "launches";
    auto chunk = r.ints("chunk"), tensor = r.ints("tensor");
    if (chunk.size() != 2 || tensor.size() != 2)
        r.err() << "'chunk' and 'tensor' must be [rows, cols]";
    else {
        st.chunkRows = (int)chunk[0], st.chunkCols = (int)chunk[1];
        st.tensorRows = tensor[0], st.tensorCols = tensor[1];
    }
    st.chunks = (int)r.i64("chunks", 0, true);
    st.rounds = (int)r.i64("rounds", 0, true);
    for (int64_t v : r.ints("host_rows"))
        st.hostRows.push_back((int)v);
    for (int64_t v : r.ints("first_rows"))
        st.firstRows.push_back((int)v);
    // the hosted-stream protocol (defaults: the values plans written before these attributes used)
    st.channels = (int)r.i64("channels", 2);
    st.slots = (int)r.i64("slots", 2);
    st.readers = (int)r.i64("readers", 2);
    st.parts = (int)r.i64("parts", 2);
    st.elemBytes = (int)r.i64("elem_bytes", 1);
    for (int64_t v : r.ints("row_groups", false))
        st.rowGroups.push_back((int)v);
    for (int64_t v : r.ints("strips", false))
        st.strips.push_back((int)v);
    if (st.channels < 1 || st.slots < 1 || st.readers < 1 || st.parts < 1 || st.elemBytes < 1)
        r.err() << "channels / slots / readers / parts / elem_bytes must be >= 1";
    if (!p.replaces(st.arg))
        r.err() << "arg " << st.arg << " is not in the plan's replace_args";
    p.streams.push_back(st);
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
        else if (n == "dmaphop.plan_stream")
            readStream(r, plan);
        else if (n == "dmaphop.plan_resources") // pinned (read back from a dfschedule program)
            readPlanResources(op, plan);
        else if (n != "dmaphop.plan")
            r.err() << "unknown plan op (the DMA program lives in dfschedule, derived from plan_stream)";
        ok &= r.ok;
    }
    if (!ok)
        return false;
    // the mesh the dmaphop stage placed: partition-relative columns, absolute rows
    int colHi = -1, rowHi = -1;
    plan.colLo = plan.coreRowBase = 1 << 20;
    module.walk([&](Operation *op) {
        if (op->getName().getStringRef() != "dmaphop.tile")
            return;
        auto t = op->getAttrOfType<StringAttr>("tiletype");
        auto c = op->getAttrOfType<IntegerAttr>("col"), rw = op->getAttrOfType<IntegerAttr>("row");
        if (!t || t.getValue() != "core" || !c || !rw)
            return;
        plan.colLo = std::min<int>(plan.colLo, (int)c.getInt()), colHi = std::max<int>(colHi, (int)c.getInt());
        plan.coreRowBase = std::min<int>(plan.coreRowBase, (int)rw.getInt()),
        rowHi = std::max<int>(rowHi, (int)rw.getInt());
    });
    plan.meshCols = colHi - plan.colLo + 1;
    plan.meshRows = rowHi - plan.coreRowBase + 1;
    // plans written before row_groups / strips: the 2 x 8 shared-operand grid they all used
    for (auto &st : plan.streams) {
        const int groups = (int)st.hostRows.size();
        if (st.rowGroups.empty())
            for (int pm = 0; pm < plan.meshRows; pm++)
                st.rowGroups.push_back(st.role == "a" ? pm / 2 : pm % 2);
        if (st.strips.empty())
            for (int c = 0; c < plan.meshCols; c++)
                for (int g = 0; g < groups; g++)
                    st.strips.push_back(st.role == "a" ? g : c + plan.meshCols * g);
    }
    std::string why;
    if (!checkPlanLayout(plan, why)) {
        ops.front()->emitError() << "[dataflow plan] " << why;
        return false;
    }
    tagReplacedFlows(module, plan);
    Builder b(module.getContext());
    SmallVector<int64_t> args(plan.replacedArgs.begin(), plan.replacedArgs.end());
    module->setAttr("dmaphop.plan_replaced_args", b.getI64ArrayAttr(args));
    for (Operation *op : ops) // the routes stay: the routing path lowers them (DmaphopToRoutinghwPass)
        if (op->getName().getStringRef() != "dmaphop.plan_route")
            op->erase();
    llvm::outs() << "[DataflowPlan] plan: " << plan.routes.size() << " routes, " << plan.streams.size() << " streams"
                 << (plan.persistent ? ", persistent kernel" : "") << (plan.bdOnce ? ", BD write-once" : "")
                 << " (DMA program derived in dfschedule once the resources are assigned)\n";
    return true;
}

} // namespace dfplan
