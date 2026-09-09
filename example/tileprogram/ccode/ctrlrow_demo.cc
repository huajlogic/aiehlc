/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

/*
 * ctrlrow_demo.cc — row-based control connection demo.
 *
 * Exercises the stateful row-control fabric API (design:
 * 2026-09-08-row-control-connection):
 *   __Runtime_ctrl_row_open  - init the fabric on a shim column
 *   __Runtime_ctrl_row_add   - configure an EAST chain on a core row (the
 *                              packet climbs a shared vertical spine to the
 *                              row's left tile, then daisy-chains EAST)
 *   __Runtime_ctrl_row_broadcast_write - fire a WRITE control packet that every
 *                              tile on the row consumes (broadcast)
 *   __Runtime_ctrl_row_close - tear down
 *
 * This Task-7 demo is write-only: it configures one core row and broadcasts a
 * sentinel to a scratch L1 address on all tiles of the row. Success = the shim
 * MM2S send drains without a ctrl_push TIMEOUT and the run reaches teardown with
 * no AIE ERROR. Register-readback verification via the memtile response path is
 * added in Task 8 (unicast read).
 *
 * Build (single-kernel flow — the dummy kernel below is extracted into a kernel
 * ELF; aie_runtime.c + aie_runtime_control_plan.c are linked in):
 *   source script/aiehlc.sh --aie-version 5 \
 *       --runtime-source-file example/tileprogram/ccode/ctrlrow_demo.cc
 * Run:
 *   python3 script/test/apppaltest.py -y -nonreboot > ./applog 2>&1
 */

#include "xaiengine.h"
#include <stdio.h>

#ifndef __AIESIM__
#include "xil_cache.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"
#else
#include <unistd.h>
#endif /* __AIESIM__ */

#if AIE_GEN <= 2
#define HW_GEN XAIE_DEV_GEN_AIEML
#else
#define HW_GEN XAIE_DEV_GEN_AIE2PS
#endif

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

// __Runtime_* wrappers + row-control API, linked in from src/mlir/runtime by
// aiehlc.sh's RUNTIME_SRCS. Included after xaiengine.h.
#include "aie_runtime.h"

// Dummy kernel so the aiehlc single-kernel flow still produces a kernel ELF. The
// cores never compute in this control-plane demo; the body is intentionally
// empty.
__global__ void ctrlrow_demo_dummy(input_window_int32 *win
                                   __attribute__((annotate("mem_address:0x1000"), annotate("size_hint:512"))),
                                   output_window_int32 *out
                                   __attribute__((annotate("mem_address:0x6000"), annotate("size_hint:512")))) {
    (void)win;
    (void)out;
}

// Demo geometry (AIE2PS): shim row 0, memtile rows 1-2, core rows 3-6.
#define DEMO_SHIM_COL 0u
#define DEMO_CTRL_ID 0u
#define DEMO_MEMTILE_ROW 1u
#define DEMO_CORE_ROW 3u
#define DEMO_COL_LO 0u
#define DEMO_COL_HI 1u            /* 2-tile chain: head consumes+forwards, east consumes */
#define DEMO_SCRATCH_ADDR 0x1000u /* in-range core L1 (DMA-view) scratch */
#define DEMO_SENTINEL 0xC0DE0001u
#define DEMO_BD_ID 2
#define DEMO_MM2S_CH 0
#define DEMO_S2MM_CH 1
#define DEMO_RESP_BD 4

int run_ctrlrow_demo(XAie_DevInst *dev) {
    __Runtime_CtrlRowFabric fab;
    XAie_LocType memtile = XAie_TileLoc(DEMO_SHIM_COL, DEMO_MEMTILE_ROW);

    AieRC rc =
        __Runtime_ctrl_row_open(&fab, dev, DEMO_SHIM_COL, memtile, DEMO_S2MM_CH, DEMO_RESP_BD, (uint8_t)DEMO_CTRL_ID);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] row_open rc=%d\n", (int)rc);
        return -1;
    }

    rc = __Runtime_ctrl_row_add(&fab, DEMO_CORE_ROW, DEMO_COL_LO, DEMO_COL_HI);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] row_add rc=%d\n", (int)rc);
        __Runtime_ctrl_row_close(&fab);
        return -1;
    }
    printf("[ctrlrow] row_add row=%u cols[%u..%u] nrows=%u spine_top=%u\n", DEMO_CORE_ROW, DEMO_COL_LO, DEMO_COL_HI,
           (unsigned)fab.nrows, (unsigned)fab.spine.spine_top);

    uint32_t sentinel = DEMO_SENTINEL;
    rc = __Runtime_ctrl_row_broadcast_write(&fab, DEMO_SCRATCH_ADDR, &sentinel, /*nwords=*/1u, DEMO_BD_ID, DEMO_MM2S_CH,
                                            /*log=*/1);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] broadcast_write rc=%d\n", (int)rc);
        __Runtime_ctrl_row_close(&fab);
        return -1;
    }
    printf("[ctrlrow] broadcast_write 0x%08x -> addr 0x%x on row %u done\n", DEMO_SENTINEL, DEMO_SCRATCH_ADDR,
           DEMO_CORE_ROW);

    __Runtime_ctrl_row_close(&fab);
    printf("[ctrlrow] DONE\n");
    return 0;
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    XAie_SetupConfig(ConfigPtr, HW_GEN, XAIE_BASE_ADDR, XAIE_COL_SHIFT, XAIE_ROW_SHIFT, XAIE_NUM_COLS, XAIE_NUM_ROWS,
                     XAIE_SHIM_ROW, XAIE_RES_TILE_ROW_START, XAIE_RES_TILE_NUM_ROWS, XAIE_AIE_TILE_ROW_START,
                     XAIE_AIE_TILE_NUM_ROWS);

    XAie_InstDeclare(DevInst, &ConfigPtr);

    AieRC RC = XAie_CfgInitialize(&DevInst, &ConfigPtr);
    if (RC != XAIE_OK) {
        printf("Driver initialization failed.\n");
        return -1;
    }

#ifdef __AIESIM__
    XAie_SetIOBackend(&DevInst, XAIE_IO_BACKEND_SIM);
#else
    XAie_SetIOBackend(&DevInst, XAIE_IO_BACKEND_BAREMETAL);
#if AIE_GEN >= 2
    if (DevInst.Backend->Type == XAIE_IO_BACKEND_BAREMETAL) {
#if AIE_GEN == 5
        RC = XAie_UpdateNpiAddr(&DevInst, 0xf6d50000);
#else
        RC = XAie_UpdateNpiAddr(&DevInst, 0xF6D10000);
#endif
        if (RC != XAIE_OK) {
            printf("Failed to update NPI address\n");
            return -1;
        }
    }
    XAie_PartInitOpts PartInitOpts;
    PartInitOpts.Locs = NULL;
    PartInitOpts.NumUseTiles = 0;
    PartInitOpts.InitOpts = XAIE_PART_INIT_OPT_DEFAULT | XAIE_PART_INIT_OPT_CTRL_TLASTERROR_DISABLE;
    RC = XAie_PartitionInitialize(&DevInst, &PartInitOpts);
#else
    XAie_PmRequestTiles(&DevInst, NULL, 0);
#endif
#endif /* __AIESIM__ */

    run_ctrlrow_demo(&DevInst);
    return 0;
}
