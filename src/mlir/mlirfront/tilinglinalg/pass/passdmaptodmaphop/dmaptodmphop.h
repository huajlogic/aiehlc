/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef __ROUTING_TODMAP__
#define __ROUTING_TODMAP__
#include "common.h"
#include "dmapmanager.h"
#include "routingmanager.h"
#include "routing/routingpath.h"
#include "routing/routingtopology.h"
using namespace mlir;
class DmapToDmaphopPass : public PassWrapper<DmapToDmaphopPass, OperationPass<>> {
public:
    DmapToDmaphopPass(RoutingTopology& rtopology);
private:
    void runOnOperation() override;
    void getDependentDialects(DialectRegistry &registry) const;
    RoutingTopology& rtopology_;
};
#endif //