/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#ifndef TILINGLINALG_DMAPHOP_PLANROUTES_H
#define TILINGLINALG_DMAPHOP_PLANROUTES_H

#include "mlir/IR/BuiltinOps.h"

class RoutingTopology;

// Lower every dmaphop.plan_route of the module to routinghw circuit connections (routed around the
// routinghw ops already present and the control plane's reserved ports) and erase it.
mlir::LogicalResult lowerDataflowPlanRoutes(mlir::ModuleOp module, RoutingTopology &topo);

#endif
