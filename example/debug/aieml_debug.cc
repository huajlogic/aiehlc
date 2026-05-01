/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

// #include <iostream>
// #include <sstream>
#include "xaiengine.h"
#include "xil_printf.h"
// #include "xil_io.h"
#include "aie_runtime_common.h"
#include "xil_cache.h"
#include <math.h>
#include <stdio.h>
#if AIE_GEN <= 2
#define HW_GEN XAIE_DEV_GEN_AIEML
#include "xtime_l.h"
#else
#define HW_GEN XAIE_DEV_GEN_AIE2PS
#include "xiltimer.h"
#endif
// #include "unistd.h"
#define uint_TYPE uint32_t

#if AIE_GEN <= 2

#define XAIE_BASE_ADDR 0x20000000000
#define XAIE_COL_SHIFT 25
#define XAIE_ROW_SHIFT 20

#define XAIE_NUM_ROWS 11
#define XAIE_NUM_COLS 38
#define XAIE_SHIM_ROW 0
#define XAIE_RES_TILE_ROW_START 1
#define XAIE_RES_TILE_NUM_ROWS 2
#define XAIE_AIE_TILE_ROW_START 3
#define XAIE_AIE_TILE_NUM_ROWS 8
#else

#define XAIE_BASE_ADDR 0x20000000000
#define XAIE_COL_SHIFT 25
#define XAIE_ROW_SHIFT 20

#define XAIE_NUM_ROWS 7
#define XAIE_NUM_COLS 36
#define XAIE_SHIM_ROW 0
#define XAIE_RES_TILE_ROW_START 1
#define XAIE_RES_TILE_NUM_ROWS 2
#define XAIE_AIE_TILE_ROW_START 3
#define XAIE_AIE_TILE_NUM_ROWS 4

#endif

#define CORE_IP_MEM 0x1000
#define CORE_OP_MEM 0x6000

__global__ void dummy_kernel(input_window_int32 *in
                             __attribute__((annotate("mem_address:0x1000"), annotate("size_hint:16"))),
                             output_window_int32 *out
                             __attribute__((annotate("mem_address:0x6000"), annotate("size_hint:16")))) {}

#define TEST_DATA_SIZE 64 // number of uint32_t words to send
#define TEST_DATA_BYTES (TEST_DATA_SIZE * sizeof(uint32_t))

// ---------------------------------------------------------------------------
// Include the generated routing configuration.
// routing.cc calls getOrCreateDeviceInstance(), so we provide the impl here.
// ---------------------------------------------------------------------------
static XAie_DevInst *g_DevInst = nullptr;
XAie_DevInst *getOrCreateDeviceInstance() { return g_DevInst; }
#include "./routing4x4.cc"

// ---------------------------------------------------------------------------
// test_routing_packet:
//   Tests the output path from tile(0,3) → Shim(3,0) using the
//   packet-switched route established by routing() round-0 row-split.
// ---------------------------------------------------------------------------
int test_routing_packet(XAie_DevInst *DevInst) {
    AieRC RC = XAIE_OK;
    printf("=== test_routing_packet: tile(0,3) → Shim(3,0) ===\n");

    // --- Step 1: Apply the full routing configuration ---
    g_DevInst = DevInst;
    printf("[1] Configuring stream switch routing...\n");
    routing();
    printf("[1] Routing configured.\n");

    // --- Step 2: Write test data into tile(0,3) data memory at 0x0 ---
    printf("[2] Writing test data to tile(0,3) data memory at 0x0...\n");
    {
        uint32_t test_data[TEST_DATA_SIZE];
        for (uint32_t i = 0; i < TEST_DATA_SIZE; i++) {
            test_data[i] = 0xA0000000 | i;
        }
        RC = XAie_DataMemBlockWrite(DevInst, XAie_TileLoc(0, 3), 0x0, (void *)test_data, TEST_DATA_BYTES);
        if (RC != XAIE_OK) {
            printf("ERROR: DataMemBlockWrite to tile(0,3) failed: %d\n", RC);
            return -1;
        }
    }
    printf("[2] Test data written.\n");

    // --- Step 3: Move data from tile(0,3) → Shim(3,0) via Runtime_Movedata ---
    // OOO mode: send packet out-of-order, dst BD=2, stride/wrap receive [[2,2],[2,2]]
    printf("[3] Moving data (OOO): tile(0,3) → Shim(3,0), dst_bd=2...\n");
    XAie_MemInst *recv_buf = nullptr;
    u64 recv_phy = 0;
    MovedataOpt ooo_opt;
    ooo_opt.mode = MOVEDATA_MODE_OOO_STRIDE;
    ooo_opt.num_dims = 3;
    ooo_opt.dims[0] = {.AieMlDimDesc = {.StepSize = 4, .Wrap = 1}};
    ooo_opt.dims[1] = {.AieMlDimDesc = {.StepSize = 8, .Wrap = 8}};
    ooo_opt.dims[2] = {.AieMlDimDesc = {.StepSize = 4, .Wrap = 2}};
    RC = Runtime_Movedata(DevInst, XAie_TileLoc(0, 3), 0x0,                    // src: tile(0,3), addr=0x0
                          0 /*src_ch*/, 0 /*src_bd*/, XAie_TileLoc(3, 0), 0x0, // dst: Shim(3,0)
                          0 /*dst_ch*/, 2 /*dst_bd*/, TEST_DATA_BYTES, 1 /*pkt_id*/, &recv_buf, &recv_phy, &ooo_opt);
    if (RC != XAIE_OK) {
        printf("ERROR: Runtime_Movedata failed: %d\n", RC);
        return -1;
    }
    printf("[3] OOO data move enqueued, waiting for completion...\n");
    RC = Runtime_Movedata_WaitAll(DevInst);
    if (RC != XAIE_OK) {
        printf("ERROR: Runtime_Movedata_WaitAll failed: %d\n", RC);
        return -1;
    }
    printf("[3] Data move completed.\n");

    // --- Step 4: Verify received data ---
    printf("[4] Verifying received data...\n");
    XAie_MemSyncForCPU(recv_buf);

    int mismatches = 0;
    for (uint32_t i = 0; i < TEST_DATA_SIZE; i++) {
        uint32_t expected = 0xA0000000 | i;
        uint32_t actual = ((uint32_t *)recv_phy)[i];
        if (actual != expected) {
            if (mismatches < 64) {
                printf("  MISMATCH [%2d]: expected=0x%08x, got=0x%08x\n", i, expected, actual);
            }
            mismatches++;
        }
    }

    if (mismatches == 0) {
        printf("[4] SUCCESS: All %d words match. Routing tile(0,3)→Shim(3,0) verified.\n", TEST_DATA_SIZE);
    } else {
        printf("[4] FAIL: %d / %d mismatches.\n", mismatches, TEST_DATA_SIZE);
    }

    // Print first 8 words for visual inspection
    printf("  First 8 received words:\n");
    for (uint32_t i = 0; i < 8 && i < TEST_DATA_SIZE; i++) {
        printf("    [%d] = 0x%08x\n", i, ((uint32_t *)recv_phy)[i]);
    }

    return (mismatches == 0) ? 0 : -1;
}

int main(int argc, char *argv[]) {
#ifdef DISABLE_CACHE
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    printf("1Cache Disabled performance will have big drop (this test should >350us(8*8 and 16*16)\n ");
#else
    printf("1cache enabled, this test should be 15us(8*8) 215 us(16*16)");
#endif

    XAie_SetupConfig(ConfigPtr, HW_GEN, XAIE_BASE_ADDR, XAIE_COL_SHIFT, XAIE_ROW_SHIFT, XAIE_NUM_COLS, XAIE_NUM_ROWS,
                     XAIE_SHIM_ROW, XAIE_RES_TILE_ROW_START, XAIE_RES_TILE_NUM_ROWS, XAIE_AIE_TILE_ROW_START,
                     XAIE_AIE_TILE_NUM_ROWS);

    ///*

    XAie_InstDeclare(DevInst, &ConfigPtr);

    int partitonnum = 34;
    int startcol = 1;
    int colnum = (startcol + partitonnum <= XAIE_NUM_COLS) ? partitonnum : (XAIE_NUM_COLS - startcol);

    AieRC RC;
    /*
    RC = XAie_SetupPartitionConfig(&DevInst, XAIE_BASE_ADDR + (startcol<<XAIE_COL_SHIFT),
                                       startcol, colnum);
    if(RC != XAIE_OK) {
        printf("Driver XAie_SetupPartitionConfig failed.\n");
        return -1;
    }
    //*/

    RC = XAie_CfgInitialize(&DevInst, &ConfigPtr);
    if (RC != XAIE_OK) {
        printf("Driver initialization failed.\n");
        return -1;
    }

    XAie_SetIOBackend(&DevInst, XAIE_IO_BACKEND_BAREMETAL);

#if AIE_GEN >= 2
    if (DevInst.Backend->Type == XAIE_IO_BACKEND_BAREMETAL) {
        printf("XAie_UpdateNpiAddr()\n");
#if AIE_GEN == 5 // aie2ps
        printf("XAie_UpdateNpiAddr(0xf6d50000)\n");
        RC = XAie_UpdateNpiAddr(&DevInst, 0xf6d50000);
#else
        RC = XAie_UpdateNpiAddr(&DevInst, 0xF6D10000);
#endif
        if (RC != XAIE_OK) {
            printf("Failed to update NPI address\n");
            return -1;
        }
    }
    printf("before XAie_PartitionInitialize-2--\n");
    // fix in aie2 the shim dma not work issue
    RC = XAie_PartitionInitialize(&DevInst, NULL);
#else
    // fix in aie1 shimd dma not work issue
    XAie_PmRequestTiles(&DevInst, NULL, 0);
#endif

    test_routing_packet(&DevInst);

    RC = XAie_PartitionTeardown(&DevInst);
    if (RC != XAIE_OK) {
        printf("Failed to Teardown partition\n");
        return -1;
    }

    return 1;
}
