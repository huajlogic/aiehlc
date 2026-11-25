/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plans (doc/design/dmaphop_dataflow_plan.md): replace the generated data movement of
// selected kernel arguments by an explicit one, in two IR levels.
//
// dmaphop -- the dataflow decisions (attribute-only ops):
//   dmaphop.plan        {replace_args = [0, 1], share_args = [0, 1], persistent = true, bd_once = true}
//   dmaphop.plan_route  {arg = 0, src = [col, row, ch], src_kind = "shim"|"dma", dsts = [[col, row, ch], ...]}
//   dmaphop.plan_stream {arg = 0, role = "a", share = "neighbor", stage = "memtile_ring", ring = 10,
//                        resident = "launch"|"launches", chunk = [64, 128], chunks = 20, rounds = 60,
//                        tensor = [7680, 2560], host_rows = [0, 3], first_rows = [0, 2],
//                        channels = 2, slots = 2, readers = 2, parts = 2, elem_bytes = 1}
// dfschedule -- the DMA program that realizes them (deriveDmaProgram -> materializeHostPlan /
//   materializeKernelPlan): config.tile_bd / lock_set / channel_enable / channel_start on the
//   MemTiles (host module) and the cores (kernel module, declaretile.self), config.dma_bd + create_io
//   + start_io + wait for the shim transfers, module switches dfschedule.plan_bd_once /
//   dfschedule.plan_go_lock. DfscheduleToApiPass / DfscheduleToKernelApiPass lower them.
//
// Ids (BDs, locks), MemTile / core buffer addresses and the go / sync locks are not part of either
// level: assignPlanResources (planresource.cpp) allocates them against what the generated flows already
// use, and every device fact comes from plantarget.h.
//
// Columns are partition-relative, rows absolute. Lifecycle: synthesizeDataflowPlan (routing-level
// `dataflow` attrs -> dmaphop ops) and collectDataflowPlan (read + validate + derive, tag the
// replaced flows, erase the ops) run right after the dmaphop stage.

#ifndef TILINGLINALG_DATAFLOWPLAN_H
#define TILINGLINALG_DATAFLOWPLAN_H

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"
#include <algorithm>
#include <cstdint>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace dfplan {

struct Tile {
    int col = 0, row = 0;
    bool operator<(const Tile &o) const { return col != o.col ? col < o.col : row < o.row; }
    bool operator==(const Tile &o) const { return col == o.col && row == o.row; }
};

using Dims = std::vector<std::pair<int64_t, int64_t>>; // {step, wrap}, innermost first

struct PlanLock {
    std::vector<Tile> tiles;
    int id = 0;
    int init = 0;
    int later = -1; // value from the second launch on (-1 = init every launch)
    bool once = false;
    // the dataflow hands the lock back at its launch-start value (balanced acquires / releases per launch):
    // the host writes it only when that value changes -- launch 0, and launch 1 when `later` differs (each
    // MMIO lock write is ~372 ns on the launch's critical path).
    bool restored = false;
    std::string tag; // the op's role (dfplan.tag on the dfschedule op): what the readback lifts it into
};

struct PlanBd {
    std::vector<Tile> tiles;
    int bd = 0;
    int64_t addr = 0, len = 0;
    Dims dims;
    int64_t iterStep = 0, iterWrap = 0;
    int acqLock = -1, acqVal = 0, relLock = -1, relVal = 0;
    int next = -1;
    std::string tag;
};

struct PlanChannel {
    std::vector<Tile> tiles;
    bool s2mm = true;
    int ch = 0, startBd = 0, repeat = 1;
    bool firstLaunchOnly = false;
    std::string tag;
};

struct PlanShimBd {
    int col = 0, ch = 0, bd = 0, arg = 0;
    bool mm2s = true;
    int64_t offset = 0, len = 0;
    Dims dims;
    int64_t iterStep = 0, iterWrap = 1;
    int repeat = 1;
    bool firstLaunchOnly = false;
    std::string tag;
};

struct PlanRoute {
    int arg = -1; // the stream (plan_stream arg) the route carries
    Tile src;
    int srcCh = 0;
    bool srcShim = true;                    // shim MM2S channel, else a MemTile / core DMA MM2S channel
    std::vector<std::pair<Tile, int>> dsts; // (tile, S2MM channel)
};

struct PlanKernelParam {
    std::string name;
    std::vector<int64_t> perMeshRow; // per shared operand o: perMeshRow[o * meshRows + pm] (perOperand)
    bool scalar = false;             // AIEHLC_PLAN_<name> is a plain constant
    bool perOperand = false;         // AIEHLC_PLAN_<name>(o, pm)
};

// What assignPlanResources picked (planresource.cpp): ids and addresses, never literals in the derivation.
struct PlanResources {
    bool assigned = false;
    bool hasCore = false, hasMem = false, hasShim = false; // pinned: which parts were read back
    // core tiles (the same on every core: one kernel ELF reads them as constants)
    std::vector<int> coreBd; // per S2MM channel: the first of `slots` chained BDs
    // reader locks: reader i of channel ch takes lockF + i * handDelta + ch and hands on handDelta above;
    // the last reader's hand-on lands on the no-op row (held at 0) -- (readers + 1) x channels locks
    int lockF = -1;
    int handDelta = 0; // = channels
    int lockE = -1;    // E(buffer) = lockE + buffer, buffer = channel + channels x slot
    int lockGo = -1, lockSync = -1;
    int64_t slotBase = 0, slotBytes = 0; // core memory (core view) the hosted chunks occupy
    // the K-accumulator (a GEMM's partial sums across K chunks): placed by the plan right after the chunk
    // slots when it does not fit next to the core's windows (accAddr < 0: the kernel keeps its own)
    int64_t accBytes = 0, accAddr = -1, dmFree = 0;
    // per-core copies (copyPlan): per stream (index into streams) its core S2MM BD chain, its F lock (DMA ->
    // kernel, counting), its E locks (kernel -> DMA, one per slot) and its slots' memory (core view)
    std::vector<int> copyBd, copyF, copyE;
    std::vector<int64_t> copySlotBase, copySlotStride; // first slot, slot to slot (the windows' alignment)
    // MemTiles: per stream (index into DataflowPlan::streams), per column
    struct Mem {
        std::vector<int> locks; // ring: (empty, full) per served parity; resident: ready, free
        int bdIn = -1;          // first S2MM BD of the chain
        std::vector<int> bdOut; // per MM2S route: its first BD
        int64_t addr = 0;
    };
    std::vector<std::vector<Mem>> mem;
    // shim: per stream, per column (-1: the column carries no part of the stream)
    std::vector<std::vector<int>> shimBd;
};

// One shared operand's stream (dmaphop.plan_stream): a sequence of chunk x chunks blocks per
// output tile (rounds tiles per core), hosted in one core's memory per (column, strip group).
struct PlanStream {
    int arg = -1;
    std::string role;              // a label ("a" / "b": the legacy row_groups / strips defaults)
    std::string stage;             // "memtile_ring" | "memtile"
    // "neighbor": hosted in one core, read by it and its neighbours (the 2 x 8 GEMM); "broadcast": one stream
    // per mesh row multicast to every core of the row, each core holding its own copy on S2MM channel
    // `channel` (readers 1, channels 1 -- several such streams share a core, one channel each)
    std::string share = "neighbor";
    int channel = 0;
    int ring = 0;                  // memtile_ring: FIFO buffers of 2 chunks
    bool residentLaunches = false; // loaded on the first launch only
    int chunkRows = 0, chunkCols = 0, chunks = 0, rounds = 0;
    int64_t tensorRows = 0, tensorCols = 0;
    std::vector<int> hostRows;  // mesh row hosting strip group g
    std::vector<int> firstRows; // mesh row that reads strip group g first
    // The hosted-stream protocol (aie_block_io_plan.h), carried in the IR rather than fixed: chunk g goes to
    // core S2MM channel g % channels and buffer g % (channels x slots); `readers` cores read every chunk
    // (reader i hands it on to reader i + 1); the kernel addresses a chunk as `parts` row parts, which the
    // plan puts PART_STRIDE apart (different memory banks).
    int channels = 2, slots = 2, readers = 2, parts = 2;
    int elemBytes = 1;
    // where the blocks sit in the tensor: round t / chunk j of strip s starts at row s * stripStep +
    // t * rowStep, column j * colStep (elements); 0 = back to back (chunkRows / chunkCols / rounds x
    // chunkRows). Overlapping blocks (a conv's halo) step less than they span; the DDR layout repeats them.
    int64_t rowStep = 0, colStep = 0, stripStep = 0;
    // per strip id its first row / column (a per-core stream, share = "none": the core's block origin);
    // empty = strip * stripStep, column 0
    std::vector<int64_t> stripRowBase, stripColBase;
    int64_t rowStepJ = 0, colStepI = 0; // rows per chunk, columns per round (blocks that move both ways)
    // (0 = back to back only for a neighbour-hosted stream, whose plans predate the steps; a per-core copy
    // always states its steps, and 0 there means the blocks do not move that way)
    int64_t rowStepOr() const { return rowStep || share != "neighbor" ? rowStep : chunkRows; }
    int64_t colStepOr() const { return colStep || share != "neighbor" ? colStep : chunkCols; }
    // the logical grid, per mesh row: the strip group a row reads (row_groups), and per column and group
    // the tensor strip that column's cores read (strips, column-major) -- what the host lays out in DDR
    std::vector<int> rowGroups;
    std::vector<int> strips;
    int64_t chunkBytes() const { return (int64_t)chunkRows * chunkCols * elemBytes; }
    int buffers() const { return channels * slots; }
    // rows of one tensor strip (the tensor split evenly over the strips the layout names)
    int64_t stripRows() const {
        int n = 0;
        for (int x : strips)
            n = std::max(n, x + 1);
        return tensorRows / std::max(n, 1);
    }
    // strip group of the mesh row that hosts it: the g with hostRows[g] == meshRow, else -1
    int groupOfHostRow(int meshRow) const {
        for (size_t g = 0; g < hostRows.size(); g++)
            if (hostRows[g] == meshRow)
                return (int)g;
        return -1;
    }
};

// A ring stream whose strip is one chunk row tall (a GEMM B strip, one output column block): every
// round (output tile) reads the same strip again -- held once in DDR, the shim BD re-reads it.
inline bool repeatsPerRound(const PlanStream &s) {
    return s.share == "neighbor" && s.rounds > 1 && s.stripRows() == s.chunkRows;
}

struct DataflowPlan {
    bool present = false;
    int memtileRows = 2; // rows 1..memtileRows are MemTiles; set by collectDataflowPlan
    int colLo = 1, meshCols = 4, meshRows = 4;
    std::vector<int> replacedArgs;
    bool persistent = false;   // kernel loaded once, later launches release a go lock (res.lockGo)
    int persistentGoLock = -1; // the go lock's core lock id once assigned
    bool bdOnce = false;       // identical BD / channel writes are skipped after the first launch
    std::vector<PlanRoute> routes;
    std::vector<PlanStream> streams;
    // every stream a per-core copy (share = "broadcast" / "none"): a core hosts all of them, one S2MM channel each
    bool copyPlan() const {
        for (const PlanStream &s : streams)
            if (s.share == "neighbor")
                return false;
        return !streams.empty();
    }
    // The protocol every core runs: streams[0]'s; in a copy plan a core hosts every stream, one S2MM
    // channel each, so its channels are the streams' count (chunk g of operand o on channel o)
    PlanStream coreProtocol() const {
        PlanStream s = streams.front();
        if (copyPlan())
            s.channels = (int)streams.size();
        return s;
    }
    // ---- the derived DMA program (deriveDmaProgram) ----
    std::vector<PlanLock> locks;
    std::vector<PlanBd> bds;
    std::vector<PlanChannel> channels;
    std::vector<PlanShimBd> shimBds;
    std::vector<PlanKernelParam> params;
    PlanResources res;
    // Read back from a dfschedule program (planreadback.cpp) or a dmaphop.plan_resources op: the resources
    // assignPlanResources adopts (checked) instead of allocating.
    PlanResources pinned;

    // Arguments whose blocks the kernel takes from hosted slots (aiehlc_share_load): the kernel body's
    // aie::load_buffer / aie::release on them are rewritten (kernel params S<arg>_VIEW / _LOCK /
    // _FIRST per mesh row).
    std::vector<int> shareArgs;
    int coreRowBase = -1; // absolute row of mesh row 0
    bool replaces(int arg) const;
    bool sharesArg(int arg) const;
    // core-tile (row >= 2 and not a MemTile) S2MM channels the plan programs itself
    std::set<int> coreS2mmChannels(int memtileRows) const;
};

// How a stream uses one column's MemTile (from its routes): the MemTile, its S2MM channel, its MM2S routes
// (one per served chunk parity for a ring, one per (strip group, parity) for a resident stream).
struct MemtileUse {
    bool present = false;
    Tile mt;
    int s2mm = -1;
    const PlanRoute *shimRoute = nullptr;
    std::vector<const PlanRoute *> out;
    std::vector<int> parities; // ring: the chunk parities (core S2MM channels) the MemTile serves
    int s2mmBds = 0, locks = 0;
    std::vector<int> mm2sBds; // per out route
    int64_t bytes = 0;        // MemTile memory
    int64_t chunksPerTile = 0;
};
MemtileUse memtileUse(const DataflowPlan &p, const PlanStream &s, int col);

// Reads + validates the dmaphop plan ops, derives the DMA program, tags the replaced flows and
// erases the ops. false (diagnostics on llvm::errs) on a malformed plan; no plan -> !present.
bool collectDataflowPlan(mlir::ModuleOp module, DataflowPlan &plan, int memtileRows);

// The plan's streams + routes are a layout this compiler implements (checked here, at the dmaphop level).
bool checkPlanLayout(const DataflowPlan &plan, std::string &why);

// Ids and addresses for the DMA program, allocated against the host module's generated flows, the
// cores' self-programmed DMA (ResourceMgr) and the core buffer allocator (planresource.cpp).
bool assignPlanResources(mlir::ModuleOp hostModule, DataflowPlan &plan, std::string &why);

// The streams + routes + assigned resources -> the DMA program (locks, BDs, channels, shim transfers,
// kernel params).
bool deriveDmaProgram(DataflowPlan &plan, std::string &why);

// Route lookups shared by the derivation and the resource assignment.
const PlanStream *streamOfRole(const DataflowPlan &p, const char *role);
std::vector<const PlanRoute *> routesOf(const DataflowPlan &p, int arg, bool fromShim, int col);

// Routing-level dataflow intent (`dataflow = {share = "neighbor", ...}` on the tensors'
// routingcreatescheduletensor ops, `routing.persistent_kernel`) -> dmaphop.plan / plan_route /
// plan_stream ops at the top of @main (plansynth.cpp). Explicit plan ops or no dataflow attrs: no-op.
bool synthesizeDataflowPlan(mlir::ModuleOp module, std::string &why);

// The DMA program as dfschedule ops: MemTile + shim on the host module (after the kernel launch,
// waits before the final wait), cores on the kernel module (declaretile.self).
bool materializeHostPlan(mlir::ModuleOp hostModule, DataflowPlan &plan);
bool materializeKernelPlan(mlir::ModuleOp kernelModule, const DataflowPlan &plan);

// The plan is published to the later stages through this process-wide slot.
DataflowPlan &activePlan();

// ---- the plan's routes: lowered by DmaphopToRoutinghwPass (passdmaphoptoroutinghw/planroutes.cpp) ----
// collectDataflowPlan keeps the plan_route ops; the pipeline erases them from the module the host / kernel
// paths are cloned from.
void erasePlanRoutes(mlir::ModuleOp module);

// aiehlc_plan.h: the kernel side of the shared ports (aiehlc_share_load / _release, per-core init,
// AIEHLC_PLAN_<name> constants, AIEHLC_PLAN_PERSISTENT / _GO_LOCK).
std::string emitPlanHeader(const DataflowPlan &plan);

// ---- readback (planreadback.cpp): dfschedule -> dfscheblueprint / dmaphop ----
// Lift the plan's resources (BD / lock ids, addresses) and ring sizes from the tagged dfschedule ops
// (dfplan.tag) of a host and / or kernel module into `out` / the plan's streams. false + why on an
// inconsistent program (e.g. E locks not in a row).
bool liftDfschedulePlan(mlir::ModuleOp host, mlir::ModuleOp kernel, DataflowPlan &plan, PlanResources &out,
                        std::string &why);
// The plan's DMA program as a standalone dfschedule module (every dfplan-tagged op of the host and kernel
// modules on its own tile declarations; a shim transfer as a config.tile_bd record) -- the readback format.
mlir::OwningOpRef<mlir::ModuleOp> buildPlanProgram(mlir::ModuleOp host, mlir::ModuleOp kernel);
// AIEHLC_DFSCHEDULE_PLAN_IN: an edited plan program (ir/dfschedule/NN_DataflowPlanProgram.mlir) -> plan.pinned
// + rings. No env: no-op.
bool readBackDfscheduleFiles(mlir::MLIRContext *ctx, DataflowPlan &plan, std::string &why);
// After both modules are materialized: write the plan program to dumpPath; when one was read back it must
// come out identical (else: the first line the levels above cannot express, false).
bool checkReadBack(mlir::ModuleOp host, mlir::ModuleOp kernel, const std::string &dumpPath, std::string &why);
// dmaphop.plan_resources <-> PlanResources.
void readPlanResources(mlir::Operation *op, DataflowPlan &plan);
std::string planResourcesText(const DataflowPlan &plan);
// The plan on the dfscheblueprint level: dfscheblueprint.plan = {...} on every shared tensor's
// declare_data (stream decisions; with resources once assigned).
void annotateBlueprint(mlir::ModuleOp blueprint, const DataflowPlan &plan, bool withResources);
// The dmaphop plan as read back: rings and a dmaphop.plan_resources op updated in a snapshot of the dmaphop
// module (re-enterable with AIEHLC_DMAPHOP_IR_IN).
void readBackDmaphop(mlir::ModuleOp dmaphopSnapshot, const DataflowPlan &plan);

// The kernel-side lowering of the plan ops in a kernel module (KERNELCONFIGOFFLOAD text) -- used by
// DfscheduleToKernelApiPass; erases the ops.
std::string lowerKernelPlanOps(mlir::Operation *kernelModuleOp, int partStartCol);

} // namespace dfplan

#endif
