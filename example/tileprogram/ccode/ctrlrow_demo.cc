/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

/*
 * ctrlrow_demo.cc — row-based control connection demo (Task 9 multi-row E2E).
 *
 * Exercises the stateful row-control fabric API (design:
 * 2026-09-08-row-control-connection):
 *   __Runtime_ctrl_row_open  - init the fabric on a shim column
 *   __Runtime_ctrl_row_add   - configure an EAST chain on a core row (the
 *                              packet climbs a shared vertical spine to the
 *                              row's left tile, then daisy-chains EAST)
 *   __Runtime_ctrl_row_broadcast_write - fire a WRITE control packet that every
 *                              tile on the configured rows consumes (broadcast)
 *   __Runtime_ctrl_row_unicast_write / _read - write to / read back a single
 *                              tile; the read response drains down the shared
 *                              spine to the shim S2MM (FoT-on-TLAST)
 *   __Runtime_ctrl_row_close - tear down
 *
 * The E2E flow configures TWO core rows on one shared spine to prove spine reuse
 * and per-row unicast readback:
 *   1. row_add row A (lower)  -> spine climbs shim..A
 *   2. row_add row B (higher) -> spine EXTENDS to B, reusing hops shim..A
 *   3. re-add row A           -> idempotent no-op (nrows unchanged)
 *   4. broadcast_write sentinel to a scratch L1 addr on every tile of both rows
 *   5. unicast_write + unicast_read a distinct value on col DEMO_UNI_COL of each
 *      row, comparing the readback (drained via the shim S2MM) to the written value
 * Success = both readbacks PASS and the run reaches teardown with no AIE ERROR.
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
#define DEMO_CORE_ROW_A 3u /* lower core row (spine climbs shim..A first) */
#define DEMO_CORE_ROW_B 5u /* higher core row (spine extends A..B, reuses shim..A) */
#define DEMO_COL_LO 0u
#define DEMO_COL_HI 3u            /* 2-tile chain: head consumes+forwards, east consumes */
#define DEMO_SCRATCH_ADDR 0x1000u /* in-range core L1 (DMA-view) scratch */
#define DEMO_SENTINEL 0xC0DE0001u
#define DEMO_BD_ID 2
#define DEMO_MM2S_CH 0
#define DEMO_S2MM_CH 0 /* shim response S2MM (even ch -> bd<24, parity rule) */

/* Unicast: a distinct value to a single tile on each row, read back via the shim
 * S2MM response path. Row A/B get different values so a cross-talk bug is visible. */
#define DEMO_UNI_COL 1u       /* single target column within [col_lo..col_hi] */
#define DEMO_UNI_ADDR 0x2000u /* separate in-range core L1 scratch */
#define DEMO_UNI_VAL_A 0xBEEF0003u
#define DEMO_UNI_VAL_B 0xBEEF0005u
#define DEMO_UNI_BD 3 /* shim MM2S BD for the unicast send */

/* Unicast-write a distinct value to tile(DEMO_UNI_COL,row), read it back through
 * the shim S2MM response path, and compare. Returns 0 on PASS, -1 otherwise. */
static int demo_probe_tile(__Runtime_CtrlRowFabric *fab, uint8_t row, uint32_t val) {
    uint32_t wr = val;
    AieRC rc = __Runtime_ctrl_row_unicast_write(fab, row, DEMO_UNI_COL, DEMO_UNI_ADDR, &wr, /*nwords=*/1u, DEMO_UNI_BD,
                                                DEMO_MM2S_CH, /*log=*/1);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] unicast_write row=%u rc=%d\n", (unsigned)row, (int)rc);
        return -1;
    }
    printf("[ctrlrow] unicast_write 0x%08x -> addr 0x%x on tile(%u,%u) done\n", val, DEMO_UNI_ADDR, DEMO_UNI_COL,
           (unsigned)row);

    uint32_t readback = 0u;
    rc = __Runtime_ctrl_row_unicast_read(fab, row, DEMO_UNI_COL, DEMO_UNI_ADDR, &readback, /*nwords=*/1u, DEMO_UNI_BD,
                                         DEMO_MM2S_CH, /*log=*/1);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] unicast_read row=%u rc=%d\n", (unsigned)row, (int)rc);
        return -1;
    }
    int pass = (readback == val);
    printf("[ctrlrow] unicast_read tile(%u,%u) addr 0x%x -> 0x%08x (expected 0x%08x) %s\n", DEMO_UNI_COL, (unsigned)row,
           DEMO_UNI_ADDR, readback, val, pass ? "PASS" : "MISMATCH");
    return pass ? 0 : -1;
}

/* Add one core row and log the resulting spine/chain counters. */
static AieRC demo_add_row(__Runtime_CtrlRowFabric *fab, uint8_t row) {
    AieRC rc = __Runtime_ctrl_row_add(fab, row, DEMO_COL_LO, DEMO_COL_HI);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] row_add row=%u rc=%d\n", (unsigned)row, (int)rc);
        return rc;
    }
    printf("[ctrlrow] row_add row=%u cols[%u..%u] nrows=%u spine_top=%u\n", (unsigned)row, DEMO_COL_LO, DEMO_COL_HI,
           (unsigned)fab->nrows, (unsigned)fab->spine.spine_top);
    return XAIE_OK;
}

int run_ctrlrow_demo(XAie_DevInst *dev) {
    __Runtime_CtrlRowFabric fab;

    AieRC rc = __Runtime_ctrl_row_open(&fab, dev, DEMO_SHIM_COL, DEMO_S2MM_CH, (uint8_t)DEMO_CTRL_ID);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] row_open rc=%d\n", (int)rc);
        return -1;
    }

    /* 1. Row A: the spine climbs shim..A. */
    if (demo_add_row(&fab, DEMO_CORE_ROW_A) != XAIE_OK) {
        __Runtime_ctrl_row_close(&fab);
        return -1;
    }
    uint8_t spine_after_a = fab.spine.spine_top;

    /* 2. Row B (higher): the spine EXTENDS to B, reusing the shim..A hops. */
    if (demo_add_row(&fab, DEMO_CORE_ROW_B) != XAIE_OK) {
        __Runtime_ctrl_row_close(&fab);
        return -1;
    }
    printf("[ctrlrow] spine reuse: top %u (after A) -> %u (after B); shared hops shim..%u not re-emitted\n",
           (unsigned)spine_after_a, (unsigned)fab.spine.spine_top, (unsigned)spine_after_a);

    /* 3. Re-add row A: idempotent no-op (nrows must not change). */
    uint8_t nrows_before = fab.nrows;
    rc = __Runtime_ctrl_row_add(&fab, DEMO_CORE_ROW_A, DEMO_COL_LO, DEMO_COL_HI);
    printf("[ctrlrow] re-add row %u idempotent: nrows %u -> %u %s\n", DEMO_CORE_ROW_A, (unsigned)nrows_before,
           (unsigned)fab.nrows, (rc == XAIE_OK && fab.nrows == nrows_before) ? "PASS" : "FAIL");

    /* 4. Broadcast a sentinel to every tile of both configured rows. */
    uint32_t sentinel = DEMO_SENTINEL;
    rc = __Runtime_ctrl_row_broadcast_write(&fab, DEMO_SCRATCH_ADDR, &sentinel, /*nwords=*/1u, DEMO_BD_ID, DEMO_MM2S_CH,
                                            /*log=*/1);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] broadcast_write rc=%d\n", (int)rc);
        __Runtime_ctrl_row_close(&fab);
        return -1;
    }
    printf("[ctrlrow] broadcast_write 0x%08x -> addr 0x%x on rows %u,%u done\n", DEMO_SENTINEL, DEMO_SCRATCH_ADDR,
           DEMO_CORE_ROW_A, DEMO_CORE_ROW_B);

    /* DIAG: direct-read the broadcast sentinel at each row's head+target to see how
     * far the spine climb (msel0) actually reaches (isolates NORTH-up fan-out). */
    for (uint8_t dr = DEMO_CORE_ROW_A; dr <= DEMO_CORE_ROW_B; dr += (uint8_t)(DEMO_CORE_ROW_B - DEMO_CORE_ROW_A)) {
        for (uint8_t dc = DEMO_COL_LO; dc <= DEMO_COL_HI; dc++) {
            uint32_t v = 0u;
            (void)XAie_DataMemBlockRead(dev, XAie_TileLoc(dc, dr), DEMO_SCRATCH_ADDR, &v, sizeof(v));
            printf("[ctrlrow] DIAG bcast tile(%u,%u) addr 0x%x -> 0x%08x\n", (unsigned)dc, (unsigned)dr,
                   DEMO_SCRATCH_ADDR, v);
        }
    }

    /* 5. Per-row unicast write + read-back through the shim S2MM response. */
    int fails = 0;
    fails += demo_probe_tile(&fab, DEMO_CORE_ROW_A, DEMO_UNI_VAL_A) ? 1 : 0;
    fails += demo_probe_tile(&fab, DEMO_CORE_ROW_B, DEMO_UNI_VAL_B) ? 1 : 0;

    __Runtime_ctrl_row_close(&fab);
    printf("[ctrlrow] DONE %s (%d readback failure(s))\n", fails == 0 ? "PASS" : "FAIL", fails);
    return fails == 0 ? 0 : -1;
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
