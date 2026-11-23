/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// Explicit dataflow plan carried in the dmaphop IR (doc/design/dmaphop_dataflow_plan.md).
//
// A plan replaces the generated data movement of selected kernel arguments with
// an explicit one, written as attribute-only `dmaphop.plan*` ops:
//
//   dmaphop.plan              {replace_args = [0, 1], persistent_go_lock = 14, bd_once = true}
//   dmaphop.plan_route        {src = [col, row, ch], src_kind = "shim"|"dma", dsts = [[col, row, ch], ...]}
//   dmaphop.plan_lock         {tiles = [[col, row], ...], id = 6, init = 0, later = 4}
//   dmaphop.plan_bd           {tiles = [...], bd = 24, addr = 0x80000, len = 16384, dims = [[1, 512], ...],
//                              acq = [20, -1], rel = [24, 1], next = 25}
//   dmaphop.plan_channel      {tiles = [...], dir = "s2mm"|"mm2s", ch = 1, start_bd = 24, repeat = 30,
//                              first_launch_only = false}
//   dmaphop.plan_shim_bd      {col = 1, ch = 1, dir = "mm2s", arg = 0, offset = 0, len = 81920, bd = 1,
//                              dims = [[4, 32], [128, 64], [8192, 10]], iter = [81920, 60], repeat = 60,
//                              first_launch_only = false}
//   dmaphop.plan_kernel_param {name = "A_VIEW", per_mesh_row = [0x70000, 0x40000, 0x60000, 0x70000]}
//
// Columns are partition-relative (as in routing.cc / host.cc). MemTile and core
// BD dims / addresses are in the tile's own units (32-bit words for steps and
// wraps, byte addresses in the core's / MemTile's own view); shim dims are in
// bytes (the runtime's __Runtime_dma_bd_config_multidim_ooo convention).
//
// Lifecycle: collectDataflowPlan() reads + validates the ops right after the
// dmaphop stage, tags the replaced flows (create_path / push get
// `dmaphop.plan_replaced`), publishes `dmaphop.plan_replaced_args` /
// `dmaphop.plan_core_s2mm` on the module and erases the plan ops. The routing,
// host and kernel paths then skip the replaced flows, and the emitters below
// add the plan's code to routing.cc / host.cc / kernel.cc.

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

struct DataflowPlan {
    bool present = false;
    int memtileRows = 2; // rows 1..memtileRows are MemTiles; set by collectDataflowPlan
    std::vector<int> replacedArgs;
    int persistentGoLock = -1; // >= 0: kernel loaded once, later launches release this core lock
    bool bdOnce = false;       // identical BD / channel writes are skipped after the first launch
    std::vector<PlanRoute> routes;
    std::vector<PlanLock> locks;
    std::vector<PlanBd> bds;
    std::vector<PlanChannel> channels;
    std::vector<PlanShimBd> shimBds;
    std::vector<PlanKernelParam> params;

    bool replaces(int arg) const;
    // core-tile (row >= 2 and not a MemTile) S2MM channels the plan programs itself
    std::set<int> coreS2mmChannels(int memtileRows) const;
};

// Reads, validates and erases the plan ops; tags the replaced flows. Returns
// false (with diagnostics on llvm::errs) on a malformed plan. A module with no
// plan leaves `plan.present == false` and is untouched.
bool collectDataflowPlan(mlir::ModuleOp module, DataflowPlan &plan, int memtileRows);

// Routing-level dataflow intent (`dataflow = {share = "neighbor", ...}` on the
// tensors' routingcreatescheduletensor ops, `routing.persistent_kernel`) ->
// dmaphop.plan* ops inserted at the top of @main (plansynth.cpp). A module with
// explicit plan ops or no dataflow attributes is left alone. false + `why` on
// an unsupported request.
bool synthesizeDataflowPlan(mlir::ModuleOp module, std::string &why);

// The plan is published to the later stages (routing.cc / host.cc / kernel.cc
// emission) through this process-wide slot, like ResourceMgr's offload plan.
DataflowPlan &activePlan();

// ---- emitters (C text) ----

// Ports already taken by the generated (kept) routes, from routingresourcemap.json.
struct PortBook {
    std::set<std::tuple<int, int, char, std::string, int>> used; // col,row,'m'|'s',dir,idx
};
bool loadPortBook(const std::string &resourceMapJson, PortBook &book);

// `static void aiehlc_plan_routing(XAie_DevInst *v1)`; false on an unroutable net.
bool emitPlanRouting(const DataflowPlan &plan, PortBook &book, int dataColLo, int dataColHi, int numRows,
                     int memtileRows, std::string &out);

// Host functions: `aiehlc_plan_host_setup(dev)` (persistent / BD-once switches,
// before the kernel load) and `aiehlc_plan_host_launch(dev, args, nargs)`
// (MemTile locks + BDs + start queues, shim BDs + start queues), and
// `aiehlc_plan_host_wait(dev)`.
std::string emitPlanHost(const DataflowPlan &plan, int memtileRows, int nargs);

// KERNELCONFIGOFFLOAD-style block run by every core at kernel start.
std::string emitPlanKernelBlock(const DataflowPlan &plan, int memtileRows, int partStartCol);

// aiehlc_plan.h: AIEHLC_PLAN_<name>(pm) and AIEHLC_PLAN_PERSISTENT / _GO_LOCK.
std::string emitPlanHeader(const DataflowPlan &plan);

} // namespace dfplan

#endif
