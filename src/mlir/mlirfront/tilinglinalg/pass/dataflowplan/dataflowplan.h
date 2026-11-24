/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Dataflow plans (doc/design/dmaphop_dataflow_plan.md): replace the generated data movement of
// selected kernel arguments by an explicit one, in two IR levels.
//
// dmaphop -- the dataflow decisions (attribute-only ops):
//   dmaphop.plan        {replace_args = [0, 1], share_args = [0, 1], persistent_go_lock = 14, bd_once = true}
//   dmaphop.plan_route  {src = [col, row, ch], src_kind = "shim"|"dma", dsts = [[col, row, ch], ...]}
//   dmaphop.plan_stream {arg = 0, role = "a", share = "neighbor", stage = "memtile_ring", ring = 10,
//                        resident = "launch"|"launches", chunk = [64, 128], chunks = 20, rounds = 60,
//                        tensor = [7680, 2560], host_rows = [0, 3], first_rows = [0, 2]}
// dfschedule -- the DMA program that realizes them (deriveDmaProgram -> materializeHostPlan /
//   materializeKernelPlan): config.tile_bd / lock_set / channel_enable / channel_start on the
//   MemTiles (host module) and the cores (kernel module, declaretile.self), config.dma_bd + create_io
//   + start_io + wait for the shim transfers, module switches dfschedule.plan_bd_once /
//   dfschedule.plan_go_lock. DfscheduleToApiPass / DfscheduleToKernelApiPass lower them.
//
// Columns are partition-relative, rows absolute. Lifecycle: synthesizeDataflowPlan (routing-level
// `dataflow` attrs -> dmaphop ops) and collectDataflowPlan (read + validate + derive, tag the
// replaced flows, erase the ops) run right after the dmaphop stage.

#ifndef TILINGLINALG_DATAFLOWPLAN_H
#define TILINGLINALG_DATAFLOWPLAN_H

#include "mlir/IR/BuiltinOps.h"
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
};

struct PlanBd {
    std::vector<Tile> tiles;
    int bd = 0;
    int64_t addr = 0, len = 0;
    Dims dims;
    int64_t iterStep = 0, iterWrap = 0;
    int acqLock = -1, acqVal = 0, relLock = -1, relVal = 0;
    int next = -1;
};

struct PlanChannel {
    std::vector<Tile> tiles;
    bool s2mm = true;
    int ch = 0, startBd = 0, repeat = 1;
    bool firstLaunchOnly = false;
};

struct PlanShimBd {
    int col = 0, ch = 0, bd = 0, arg = 0;
    bool mm2s = true;
    int64_t offset = 0, len = 0;
    Dims dims;
    int64_t iterStep = 0, iterWrap = 1;
    int repeat = 1;
    bool firstLaunchOnly = false;
};

struct PlanRoute {
    Tile src;
    int srcCh = 0;
    bool srcShim = true;                    // shim MM2S channel, else a MemTile / core DMA MM2S channel
    std::vector<std::pair<Tile, int>> dsts; // (tile, S2MM channel)
};

struct PlanKernelParam {
    std::string name;
    std::vector<int64_t> perMeshRow;
    bool scalar = false; // `value = N`: AIEHLC_PLAN_<name> is a plain constant
};

// One shared operand's stream (dmaphop.plan_stream): a sequence of chunk x chunks blocks per
// output tile (rounds tiles per core), hosted in one core's memory per (column, strip group).
struct PlanStream {
    int arg = -1;
    std::string role;              // "a": strips over mesh-row pairs; "b": strips over columns x 2
    std::string stage;             // "memtile_ring" | "memtile"
    int ring = 0;                  // memtile_ring: FIFO buffers of 2 chunks
    bool residentLaunches = false; // loaded on the first launch only
    int chunkRows = 0, chunkCols = 0, chunks = 0, rounds = 0;
    int64_t tensorRows = 0, tensorCols = 0;
    std::vector<int> hostRows;  // mesh row hosting strip group g
    std::vector<int> firstRows; // mesh row that reads strip group g first
};

struct DataflowPlan {
    bool present = false;
    int memtileRows = 2; // rows 1..memtileRows are MemTiles; set by collectDataflowPlan
    int colLo = 1, meshCols = 4, meshRows = 4;
    std::vector<int> replacedArgs;
    int persistentGoLock = -1; // >= 0: kernel loaded once, later launches release this core lock
    bool bdOnce = false;       // identical BD / channel writes are skipped after the first launch
    std::vector<PlanRoute> routes;
    std::vector<PlanStream> streams;
    // ---- the derived DMA program (deriveDmaProgram) ----
    std::vector<PlanLock> locks;
    std::vector<PlanBd> bds;
    std::vector<PlanChannel> channels;
    std::vector<PlanShimBd> shimBds;
    std::vector<PlanKernelParam> params;

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

// Reads + validates the dmaphop plan ops, derives the DMA program, tags the replaced flows and
// erases the ops. false (diagnostics on llvm::errs) on a malformed plan; no plan -> !present.
bool collectDataflowPlan(mlir::ModuleOp module, DataflowPlan &plan, int memtileRows);

// The streams -> the DMA program (locks, BDs, channels, shim transfers, kernel params).
bool deriveDmaProgram(DataflowPlan &plan, std::string &why);

// Routing-level dataflow intent (`dataflow = {share = "neighbor", ...}` on the tensors'
// routingcreatescheduletensor ops, `routing.persistent_kernel`) -> dmaphop.plan / plan_route /
// plan_stream ops at the top of @main (plansynth.cpp). Explicit plan ops or no dataflow attrs: no-op.
bool synthesizeDataflowPlan(mlir::ModuleOp module, std::string &why);

// The DMA program as dfschedule ops: MemTile + shim on the host module (after the kernel launch,
// waits before the final wait), cores on the kernel module (declaretile.self).
bool materializeHostPlan(mlir::ModuleOp hostModule, const DataflowPlan &plan);
bool materializeKernelPlan(mlir::ModuleOp kernelModule, const DataflowPlan &plan);

// The plan is published to the later stages through this process-wide slot.
DataflowPlan &activePlan();

// ---- C text that is not a DMA program ----

// Ports already taken by the generated (kept) routes, from routingresourcemap.json.
struct PortBook {
    std::set<std::tuple<int, int, char, std::string, int>> used; // col,row,'m'|'s',dir,idx
};
bool loadPortBook(const std::string &resourceMapJson, PortBook &book);

// `static void aiehlc_plan_routing(XAie_DevInst *v1)`; false on an unroutable net.
bool emitPlanRouting(const DataflowPlan &plan, PortBook &book, int dataColLo, int dataColHi, int numRows,
                     int memtileRows, std::string &out);

// aiehlc_plan.h: the kernel side of the shared ports (aiehlc_share_load / _release, per-core init,
// AIEHLC_PLAN_<name> constants, AIEHLC_PLAN_PERSISTENT / _GO_LOCK).
std::string emitPlanHeader(const DataflowPlan &plan);

// The kernel-side lowering of the plan ops in a kernel module (KERNELCONFIGOFFLOAD text) -- used by
// DfscheduleToKernelApiPass; erases the ops.
std::string lowerKernelPlanOps(mlir::Operation *kernelModuleOp, int partStartCol);

} // namespace dfplan

#endif
