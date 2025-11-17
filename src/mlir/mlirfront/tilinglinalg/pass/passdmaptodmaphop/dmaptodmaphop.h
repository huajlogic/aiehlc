/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef __DMAP__TODMAPHOP__
#define __DMAP__TODMAPHOP__
#include "common.h"
#include "dmapmanager.h"
#include "dmaphopmanager.h"
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