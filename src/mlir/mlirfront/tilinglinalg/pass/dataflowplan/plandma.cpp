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

#include <map>
#include <set>
#include <sstream>

namespace dfplan {

using namespace mlir;

namespace {

const PlanStream *streamOfRole(const DataflowPlan &p, const char *role) {
    for (const auto &s : p.streams)
        if (s.role == role)
            return &s;
    return nullptr;
}

// MemTile side of the A stream: a FIFO ring of `ring` buffers of 2 chunks, counting locks 20 (empty)
// and 24 (full), S2MM ch 1 from the shim, MM2S ch 1 broadcasting to the strip's host row.
void deriveRingA(DataflowPlan &p, const PlanStream &A, int64_t chunk, const std::vector<Tile> &mt) {
    const int64_t aLen = (int64_t)A.chunks / 2 * chunk;
    const int ring = A.ring, rounds = (int)(A.rounds * aLen / (ring * 2 * chunk));
    p.locks.push_back({mt, 20, ring, -1, false});
    p.locks.push_back({mt, 24, 0, -1, false});
    for (int b = 0; b < ring; b++) {
        const int nx = b < ring - 1 ? b + 1 : -1;
        const int64_t addr = 0x80000 + b * 2 * chunk;
        p.bds.push_back({mt, 24 + b, addr, 2 * chunk, {}, 0, 0, 20, -1, 24, 1, nx >= 0 ? 24 + nx : -1});
        p.bds.push_back({mt, 24 + ring + b, addr, 2 * chunk, {}, 0, 0, 24, -1, 20, 1, nx >= 0 ? 24 + ring + nx : -1});
    }
    p.channels.push_back({mt, true, 1, 24, rounds, false});
    p.channels.push_back({mt, false, 1, 24 + ring, rounds, false});
}

// MemTile side of the B stream: strips c and c + C held whole (S2MM ch 0, once when resident across
// launches), replayed by 4 MM2S channels (strip, parity) `rounds` times per launch.
void deriveResidentB(DataflowPlan &p, const PlanStream &B, int64_t chunk, const std::vector<Tile> &mt) {
    const int64_t bLen = (int64_t)B.chunks * chunk;
    const bool keep = B.residentLaunches;
    p.locks.push_back({mt, 6, 0, keep ? 4 : -1, false});
    p.locks.push_back({mt, 7, 1, keep ? 0 : -1, false});
    p.bds.push_back({mt, 0, 0x80000, 2 * bLen, {}, 0, 0, 7, -1, 6, 4, -1});
    p.channels.push_back({mt, true, 0, 0, 1, keep});
    const int mbd[4] = {1, 24, 2, 25}; // odd MemTile channels use BDs 24..47
    for (int m = 0; m < 4; m++) {
        Dims d = {{1, chunk / 16}, {chunk / 16, 4}, {chunk / 2, B.chunks / 2}}; // words: every other chunk
        p.bds.push_back({mt, mbd[m], 0x80000 + (m / 2) * bLen + (m % 2) * chunk, bLen / 2, d, 0, 0, 6, -1, 6, 1, -1});
        p.channels.push_back({mt, false, m, mbd[m], B.rounds, false});
    }
}

// Every core hosts one stream: 2 channels x 2 slots of one chunk at the top of its memory, each chunk
// split over two DM banks; locks per channel F (DMA -> first reader), G (first -> second), E per slot.
void deriveCoreSlots(DataflowPlan &p, int64_t chunk, const std::vector<Tile> &cores) {
    const int64_t half = chunk / 2, base = 0x80000 - 4 * chunk;
    for (int ch = 0; ch < 2; ch++)
        for (int k = 0; k < 2; k++) {
            const int q = 2 * ch + k;
            Dims d = {{1, 128}, {128, half / 512}, {half, 0}}; // words: 512 B rows, half, then +4 halves
            p.bds.push_back(
                {cores, q, base + q * half, chunk, d, 0, 0, 8 + 4 * ch + k, -2, 6 + 4 * ch, 1, 2 * ch + (k ^ 1)});
        }
    for (int ch = 0; ch < 2; ch++) {
        for (int k = 0; k < 2; k++)
            p.locks.push_back({cores, 8 + 4 * ch + k, 2, -1, false});
        p.locks.push_back({cores, 6 + 4 * ch, 0, -1, false});
        p.locks.push_back({cores, 7 + 4 * ch, 0, -1, false});
    }
    if (p.persistentGoLock >= 0)
        p.locks.push_back({cores, p.persistentGoLock, 1, -1, false});
    p.locks.push_back({cores, 15, 0, -1, false});
    for (int ch = 0; ch < 2; ch++)
        p.channels.push_back({cores, true, ch, 2 * ch, 1, false});
    const std::pair<const char *, int64_t> scal[] = {{"SLOT_LO", base - 0x70000},
                                                     {"SLOT_HI", base - 0x70000 + 4 * half},
                                                     {"SLOT_STRIDE", half},
                                                     {"LOCK_F", 6},
                                                     {"LOCK_G", 7},
                                                     {"LOCK_E", 8},
                                                     {"LOCK_CH_STRIDE", 4},
                                                     {"LOCK_NOP", 48 + 15}};
    for (auto &[n, v] : scal)
        p.params.push_back({n, {v}, true});
}

// The kernel's view of the hosted streams: per mesh row, the operand's view (own 0x70000 / north
// 0x60000 / south 0x40000), its lock base (48 / 32 / 0) and whether this row reads first.
void deriveKernelParams(DataflowPlan &p, const PlanStream &A, const PlanStream &B) {
    auto view = [](int pm, int host, bool lock) -> int64_t {
        if (host == pm)
            return lock ? 48 : 0x70000;
        return host == pm + 1 ? (lock ? 32 : 0x60000) : (lock ? 0 : 0x40000);
    };
    for (const PlanStream *s : {&A, &B}) {
        PlanKernelParam v{"S" + std::to_string(s->arg) + "_VIEW", {}, false};
        PlanKernelParam l{"S" + std::to_string(s->arg) + "_LOCK", {}, false};
        PlanKernelParam f{"S" + std::to_string(s->arg) + "_FIRST", {}, false};
        for (int pm = 0; pm < p.meshRows; pm++) {
            const int g = s->role == "a" ? pm / 2 : pm % 2;
            v.perMeshRow.push_back(view(pm, s->hostRows[g], false));
            l.perMeshRow.push_back(view(pm, s->hostRows[g], true));
            f.perMeshRow.push_back(s->firstRows[g] == pm);
        }
        p.params.push_back(v);
        p.params.push_back(l);
        p.params.push_back(f);
    }
}

} // namespace

bool deriveDmaProgram(DataflowPlan &p, std::string &why) {
    p.locks.clear(), p.bds.clear(), p.channels.clear(), p.shimBds.clear(), p.params.clear();
    const PlanStream *A = streamOfRole(p, "a"), *B = streamOfRole(p, "b");
    if (!A || !B) {
        why = "the plan needs one plan_stream of role \"a\" and one of role \"b\"";
        return false;
    }
    if (A->stage != "memtile_ring" || B->stage != "memtile" || A->ring <= 0) {
        why = "implemented: role a stage memtile_ring (ring > 0), role b stage memtile";
        return false;
    }
    if (A->chunkRows != B->chunkRows || A->chunkCols != B->chunkCols || A->chunks != B->chunks ||
        A->rounds != B->rounds || A->hostRows.size() != 2 || B->hostRows.size() != 2 || A->firstRows.size() != 2 ||
        B->firstRows.size() != 2 || p.meshRows != 4 || p.meshCols != 4 || A->chunks % 2) {
        why = "streams a / b must share chunk shape, chunks and rounds, with 2 host groups each on a 4 x 4 mesh";
        return false;
    }
    const int64_t chunk = (int64_t)A->chunkRows * A->chunkCols;
    if ((A->rounds * (int64_t)A->chunks / 2 * chunk) % (A->ring * 2 * chunk)) {
        why = "the A ring does not divide one strip's stream";
        return false;
    }
    std::vector<Tile> mtA, mtB, cores;
    for (int c = 0; c < p.meshCols; c++) {
        mtA.push_back({p.colLo + c, p.memtileRows});
        mtB.push_back({p.colLo + c, 1});
        for (int pm = 0; pm < p.meshRows; pm++)
            cores.push_back({p.colLo + c, p.coreRowBase + pm});
    }
    deriveRingA(p, *A, chunk, mtA);
    deriveResidentB(p, *B, chunk, mtB);
    deriveCoreSlots(p, chunk, cores);
    deriveKernelParams(p, *A, *B);
    // shim: one contiguous stream per column (the host lays A / B out in this order)
    const int64_t aLen = (int64_t)A->chunks / 2 * chunk, bLen = (int64_t)B->chunks * chunk;
    for (int c = 0; c < p.meshCols; c++) {
        p.shimBds.push_back({p.colLo + c,
                             1,
                             14,
                             A->arg,
                             true,
                             c * A->rounds * aLen,
                             aLen,
                             {{4, 32}, {128, 64}, {chunk, A->chunks / 2}},
                             aLen,
                             A->rounds,
                             A->rounds,
                             false});
        p.shimBds.push_back({p.colLo + c,
                             0,
                             15,
                             B->arg,
                             true,
                             c * 2 * bLen,
                             bLen,
                             {{4, 32}, {128, 64}, {chunk, B->chunks}},
                             bLen,
                             2,
                             2,
                             B->residentLaunches});
    }
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
    for (const auto &l : p.locks)
        for (const auto &t : l.tiles)
            if (isMem(p, t))
                b.create<dfschedule::ConfigLockSetOp>(h.loc, h.tile(t), l.id, l.init, l.later);
    for (const auto &bd : p.bds)
        for (const auto &t : bd.tiles)
            if (isMem(p, t)) // MemTile own locks are 64.. in a BD (neighbourhood-relative); dims bytes
                b.create<dfschedule::ConfigTileBdOp>(h.loc, h.tile(t), bd.bd, bd.addr, (int32_t)bd.len,
                                                     dimsAttr(b, bd.dims, false, 4), dimsAttr(b, bd.dims, true, 1),
                                                     (int32_t)(bd.iterStep * 4), (int32_t)bd.iterWrap,
                                                     bd.acqLock >= 0 ? 64 + bd.acqLock : -1, bd.acqVal,
                                                     bd.relLock >= 0 ? 64 + bd.relLock : -1, bd.relVal, bd.next);
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

bool materializeHostPlan(ModuleOp hostModule, const DataflowPlan &p) {
    if (!p.present)
        return true;
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
            b.create<dfschedule::ConfigTileBdOp>(loc, t, bd.bd, bd.addr, (int32_t)bd.len,
                                                 dimsAttr(b, bd.dims, false, 4), dimsAttr(b, bd.dims, true, 1),
                                                 (int32_t)(bd.iterStep * 4), (int32_t)bd.iterWrap, bd.acqLock,
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
    int rowBase = activePlan().coreRowBase;
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
            os << "    const AieKcDims _d = {" << w(s, 0) / 4 << ", " << w(r, 0) << ", " << w(s, 1) / 4 << ", "
               << w(r, 1) << ", " << w(s, 2) / 4 << ", " << I(bd.getIterStepSize()) / 4 << ", " << I(bd.getIterWrap())
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
    if (!activePlan().shareArgs.empty()) // this core's view / lock base / role of every shared port
        out << "  aiehlc_plan_share_init(_prow - " << rowBase << ");\n";
    out << "}\n";
    return out.str();
}

} // namespace dfplan
