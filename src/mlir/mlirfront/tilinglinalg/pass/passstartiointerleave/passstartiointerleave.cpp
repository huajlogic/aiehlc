/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#include "passstartiointerleave.h"

#include "mlir/Dialect/EmitC/IR/EmitC.h"

#include "llvm/Support/raw_ostream.h"

using namespace mlir;

static bool attrOn(ModuleOp mod, StringRef name) {
    auto a = mod->getAttrOfType<IntegerAttr>(name);
    return a && a.getInt() != 0;
}

static Operation *latestOperandDef(Operation *op, Block *block) {
    Operation *latest = nullptr;
    for (Value v : op->getOperands()) {
        Operation *def = v.getDefiningOp();
        if (!def || def->getBlock() != block)
            continue;
        if (!latest || latest->isBeforeInBlock(def))
            latest = def;
    }
    return latest;
}

void StartioInterleavePass::runOnOperation() {
    ModuleOp mod = getOperation();
    if (attrOn(mod, "routing.control_packet_mode") || attrOn(mod, "routing.control_plan_shim_bd_ctrl")) {
        llvm::errs() << "[TilingLinalg] StartioInterleavePass skipped (AOT / shim-BD control window)\n";
        return;
    }
    SmallVector<emitc::CallOpaqueOp> starts;
    mod.walk([&](emitc::CallOpaqueOp call) {
        if (call.getCallee() == "__Runtime_startio")
            starts.push_back(call);
    });
    unsigned moved = 0;
    for (emitc::CallOpaqueOp call : starts) {
        Operation *op = call.getOperation();
        Operation *after = latestOperandDef(op, op->getBlock());
        if (!after || after->getNextNode() == op)
            continue;
        op->moveAfter(after);
        moved++;
    }
    llvm::errs() << "[TilingLinalg] StartioInterleavePass: " << moved << " of " << starts.size()
                 << " startio moved next to their createio\n";
}

// ------------------------------------------------------------------------------------------------ SlicePrequeuePass
// #pragma dataflow_slices (gemm90 m3362124222211 PI): see sliceprequeue_plan.h for the schedule and its limits.
#include "sliceprequeue_plan.h"

static int64_t argInt(emitc::CallOpaqueOp call, unsigned i, int64_t dflt = -1) {
    ArrayAttr a = call.getArgsAttr();
    if (!a || i >= a.size())
        return dflt;
    auto ia = dyn_cast<IntegerAttr>(a[i]);
    return ia ? ia.getInt() : dflt;
}

static std::string argOpaque(emitc::CallOpaqueOp call, unsigned i) {
    ArrayAttr a = call.getArgsAttr();
    if (!a || i >= a.size())
        return "";
    auto oa = dyn_cast<emitc::OpaqueAttr>(a[i]);
    return oa ? oa.getValue().str() : "";
}

static emitc::CallOpaqueOp callDef(Value v, StringRef callee) {
    auto c = v ? v.getDefiningOp<emitc::CallOpaqueOp>() : emitc::CallOpaqueOp();
    return c && c.getCallee() == callee ? c : emitc::CallOpaqueOp();
}

static bool tileOfLoc(Value v, int &col, int &row) {
    auto c = callDef(v, "XAie_TileLoc");
    if (!c)
        return false;
    col = (int)argInt(c, 0);
    row = (int)argInt(c, 1);
    return col >= 0 && row >= 0;
}

static ArrayAttr withArg(OpBuilder &b, ArrayAttr a, unsigned i, Attribute v) {
    SmallVector<Attribute> xs(a.begin(), a.end());
    xs[i] = v;
    return b.getArrayAttr(xs);
}

void SlicePrequeuePass::runOnOperation() {
    ModuleOp mod = getOperation();
    auto slAttr = mod->getAttrOfType<IntegerAttr>("dfschedule.plan_slices");
    if (!slAttr || slAttr.getInt() < 2)
        return; // not a #pragma dataflow_slices module: nothing changes (nb101 host.cc byte-identical)
    const int64_t S = slAttr.getInt();
    // the alt / own BD alternation relies on BD write-once: a later call's BD config of a queued BD is skipped
    if (!attrOn(mod, "dfschedule.plan_bd_once")) {
        llvm::errs() << "[TilingLinalg] SlicePrequeuePass skipped: dataflow_slices without plan_bd_once\n";
        return;
    }
    mod.walk([&](emitc::FuncOp fn) {
        // the per-call slice prologue of DfscheduleToApiPass (verbatim `auto __plan_slice_addr = ...`)
        emitc::VerbatimOp lambda;
        fn.walk([&](emitc::VerbatimOp v) {
            if (v.getValue().starts_with("auto __plan_slice_addr ="))
                lambda = v;
        });
        if (!lambda)
            return;
        struct Site {
            emitc::CallOpaqueOp start, io, bd;
            emitc::CallOpaqueOp sliceAddr; // __plan_slice_addr feeding this BD's rebase (sliced input)
        };
        std::vector<Site> sites;
        std::vector<sliceprequeue::Io> ios;
        std::map<int, std::set<int>> used;
        std::map<std::pair<int, int>, emitc::CallOpaqueOp> rebase; // (col, bd) -> __plan_slice_addr
        SmallVector<emitc::CallOpaqueOp> waits;
        fn.walk([&](emitc::CallOpaqueOp c) {
            StringRef cal = c.getCallee();
            int col = -1, row = -1;
            if ((cal == "__Runtime_dma_bd_config_multidim_ooo" || cal == "__Runtime_dma_bd_config_multidim" ||
                 cal == "__Runtime_dma_bd_config") &&
                c.getNumOperands() >= 2 && tileOfLoc(c.getOperand(1), col, row) && row == 0)
                used[col].insert((int)argInt(c, 3));
            else if (cal == "__Runtime_shim_bd_set_addr") {
                used[(int)argInt(c, 0)].insert((int)argInt(c, 2));
                if (c.getNumOperands() == 1)
                    if (auto sa = callDef(c.getOperand(0), "__plan_slice_addr"))
                        rebase[{(int)argInt(c, 0), (int)argInt(c, 2)}] = sa;
            } else if (cal == "__Runtime_dma_createio_4" && c.getNumOperands() >= 1 &&
                       tileOfLoc(c.getOperand(0), col, row) && row == 0)
                used[col].insert((int)argInt(c, 3));
            else if (cal == "__Runtime_wait")
                waits.push_back(c);
        });
        fn.walk([&](emitc::CallOpaqueOp c) {
            if (c.getCallee() != "__Runtime_startio" || c.getNumOperands() != 2)
                return;
            auto io = callDef(c.getOperand(1), "__Runtime_dma_createio_4");
            if (!io || io.getNumOperands() != 2)
                return;
            int col = -1, row = -1;
            if (!tileOfLoc(io.getOperand(0), col, row) || row != 0)
                return;
            auto bd = io.getOperand(1).getDefiningOp<emitc::CallOpaqueOp>();
            if (!bd || bd.getCallee() != "__Runtime_dma_bd_config_multidim_ooo" || bd.getNumOperands() != 3)
                return;
            sliceprequeue::Io x;
            x.col = col;
            x.row = row;
            x.ch = (int)argInt(io, 2);
            x.bd = (int)argInt(io, 3);
            x.dir = argOpaque(io, 4) == "DMA_S2MM" ? sliceprequeue::S2MM : sliceprequeue::MM2S;
            x.chained = argInt(bd, 5) != -1;
            x.repeat = (int)argInt(c, 3);
            auto rb = rebase.find({col, x.bd});
            x.sliced = rb != rebase.end();
            sites.push_back({c, io, bd, x.sliced ? rb->second : emitc::CallOpaqueOp()});
            ios.push_back(x);
        });
        if (sites.empty())
            return;
        sliceprequeue::Plan p = sliceprequeue::plan(ios, used);
        if (!p.note.empty())
            llvm::errs() << "[TilingLinalg] SlicePrequeuePass: not pre-queued: " << p.note << "\n";
        // every wait of a shim startio must come after all of them (the issue + pre-queue block goes before it)
        Operation *last = nullptr;
        for (auto &s : sites)
            if (!last || last->isBeforeInBlock(s.start))
                last = s.start;
        for (auto w : waits)
            if (w->getBlock() != last->getBlock() || w->isBeforeInBlock(last)) {
                for (auto &s : sites)
                    if (w.getNumOperands() == 2 && w.getOperand(1) == s.start.getResult(0)) {
                        llvm::errs() << "[TilingLinalg] SlicePrequeuePass skipped: a shim wait precedes the last "
                                        "startio\n";
                        return;
                    }
            }
        // 1. issue order B (sliced inputs) -> C (outputs) -> A (unsliced inputs): class-2 startios move after the
        //    last class 0/1 startio, in their original order.
        Operation *anchor = nullptr;
        for (int i : p.order)
            if (sliceprequeue::ioClass(ios[i]) < 2 && (!anchor || anchor->isBeforeInBlock(sites[i].start)))
                anchor = sites[i].start;
        unsigned moved = 0;
        for (int i : p.order)
            if (sliceprequeue::ioClass(ios[i]) == 2 && anchor) {
                if (sites[i].start.getOperation() != anchor->getNextNode())
                    moved++;
                sites[i].start->moveAfter(anchor);
                anchor = sites[i].start;
            }
        if (!anchor)
            for (auto &s : sites)
                if (!anchor || anchor->isBeforeInBlock(s.start))
                    anchor = s.start;
        // 2. the slice-aware issue / wait entry points
        OpBuilder b(fn.getContext());
        for (size_t i = 0; i < sites.size(); i++) {
            if (p.altBd[i] < 0)
                continue;
            sites[i].start.setCalleeAttr(b.getStringAttr("__Runtime_startio_slice"));
            for (auto w : waits)
                if (w.getNumOperands() == 2 && w.getOperand(1) == sites[i].start.getResult(0))
                    w.setCalleeAttr(b.getStringAttr("__Runtime_wait_io_pq"));
        }
        if (!p.prequeued)
            return;
        // 3. next-slice address helper next to the prologue's __plan_slice_addr
        b.setInsertionPointAfter(lambda);
        b.create<emitc::VerbatimOp>(
            lambda.getLoc(), "auto __plan_slice_addr_next = [__plan_slice](const void *p, uint64_t d, uint64_t s) -> "
                             "uint64_t { return (uint64_t)(uintptr_t)p + d + ((__plan_slice + 1u) % " +
                                 std::to_string(S) + "u) * s; };");
        // 4. issue_ab(i+1): after the last startio of this call, before its waits
        b.setInsertionPointAfter(anchor);
        b.create<emitc::VerbatimOp>(anchor->getLoc(),
                                    "/* dataflow_slices pre-queue: call i+1's shim inputs on an alt BD before call i's "
                                    "waits (the runtime alternates own / alt BD) */");
        for (int i : p.order) {
            if (p.altBd[i] < 0)
                continue;
            Site &s = sites[i];
            const int alt = p.altBd[i];
            Location loc = s.start.getLoc();
            auto bd = b.create<emitc::CallOpaqueOp>(loc, s.bd.getResultTypes(), s.bd.getCallee(),
                                                    withArg(b, s.bd.getArgsAttr(), 3, b.getI32IntegerAttr(alt)),
                                                    s.bd.getTemplateArgsAttr(), s.bd.getOperands());
            auto io = b.create<emitc::CallOpaqueOp>(
                loc, s.io.getResultTypes(), s.io.getCallee(),
                withArg(b, s.io.getArgsAttr(), 3, b.getI32IntegerAttr(alt)), s.io.getTemplateArgsAttr(),
                ValueRange{s.io.getOperand(0), bd.getResult(0)});
            SmallVector<Value> ops{s.start.getOperand(0), io.getResult(0)};
            SmallVector<Attribute> args{b.getIndexAttr(0), b.getIndexAttr(1), b.getI32IntegerAttr(ios[i].bd),
                                        b.getI32IntegerAttr(ios[i].repeat)};
            if (s.sliceAddr) {
                auto nx = b.create<emitc::CallOpaqueOp>(loc, s.sliceAddr.getResultTypes(), "__plan_slice_addr_next",
                                                        s.sliceAddr.getArgsAttr(), s.sliceAddr.getTemplateArgsAttr(),
                                                        s.sliceAddr.getOperands());
                ops.push_back(nx.getResult(0));
                args.push_back(b.getIndexAttr(2));
            } else {
                args.push_back(b.getI64IntegerAttr(0)); // unsliced: the BD's own address
            }
            b.create<emitc::CallOpaqueOp>(loc, s.start.getResultTypes(), "__Runtime_startio_prequeue",
                                          b.getArrayAttr(args), ArrayAttr(), ops);
        }
        llvm::errs() << "[TilingLinalg] SlicePrequeuePass: " << p.prequeued << " shim input(s) pre-queued on alt BDs, "
                     << moved << " unsliced input startio(s) moved after the outputs (order B -> C -> A)\n";
    });
}
