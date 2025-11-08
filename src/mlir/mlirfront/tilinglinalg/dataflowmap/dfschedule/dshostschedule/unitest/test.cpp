/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include <iostream>
#include "dshostmanager.h"

int main(int argc, char* argv[]) {
    MLIRContext ctx;
    dshostmanager hoptest;
    
    // Load the dshosthop dialect
    hoptest.loaddialect(&ctx);
    
    // Run the cache-and-forward broadcast test
    hoptest.ops_test(&ctx);
    
    std::cout << "Completed dshosthop dialect test" << std::endl;
    return 0;
}