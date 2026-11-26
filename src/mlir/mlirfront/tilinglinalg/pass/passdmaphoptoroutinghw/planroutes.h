/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef TILINGLINALG_DMAPHOP_PLANROUTES_H
#define TILINGLINALG_DMAPHOP_PLANROUTES_H

#include "dataflowplan/dataflowplan.h"
#include "mlir/IR/BuiltinOps.h"

#include <vector>

class RoutingTopology;

// The dataflow plan's routes, taken from its paths (#dmaphop.stream create_path, dataflowplan.h) BEFORE the
// generic conversion -- the plan paths, their hops, ports and tiles are erased so the generated-flow patterns
// never see them. `at` is the block the paths sat in (the front of the routing function).
struct PlanRouteSet {
    std::vector<dfplan::PlanRoute> routes;
    mlir::Block *at = nullptr;
    mlir::Location loc;
};
mlir::FailureOr<PlanRouteSet> takeDataflowPlanRoutes(mlir::ModuleOp module);

// Lower the routes to routinghw circuit connections at the front of `at`, in route order (routed around the
// routinghw ops already present and the control plane's reserved ports).
mlir::LogicalResult lowerDataflowPlanRoutes(mlir::ModuleOp module, RoutingTopology &topo, const PlanRouteSet &set);

#endif
