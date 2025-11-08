/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include <iostream>
#include "dskernelmanager.h"

int main(int argc, char* argv[]) {
    MLIRContext ctx;
    dskernelmanager hoptest;
    
    // Load the dskernelhop dialect
    hoptest.loaddialect(&ctx);
    
    // Run the cache-and-forward broadcast test
    hoptest.ops_test(&ctx);
    
    std::cout << "Completed dskernelhop dialect test" << std::endl;
    return 0;
}