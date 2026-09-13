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
 *   __Runtime_ctrl_row_broadcast_write - fire a WRITE control packet (id[4]=1)
 *                              that every tile on every configured row consumes
 *   __Runtime_ctrl_row_{all_but_last,only_last,whole_row}_write - fire a WRITE
 *                              control packet (id = (class<<2)|rowidx) that a
 *                              COLUMN SUBSET of one target row consumes:
 *                              all-but-last = every column except col_hi;
 *                              only-last = only col_hi; whole-row = every column.
 *                              The packet climbs the shared spine past any
 *                              intervening head via its transit-north slot.
 *   __Runtime_ctrl_row_close - tear down
 *
 * The E2E flow configures TWO core rows on one shared spine to prove spine reuse
 * and per-row column-subset targeting:
 *   1. row_add row A (lower)  -> spine climbs shim..A            (add-order idx 0)
 *   2. row_add row B (higher) -> spine EXTENDS to B, reusing hops shim..A (idx 1)
 *   3. re-add row A           -> idempotent no-op (nrows unchanged)
 *   4. broadcast_write sentinel to a scratch L1 addr on every tile of both rows
 *   5. per-class writes to row A (all-but-last, only-last, whole-row) then a
 *      whole-row + only-last to row B, verifying via the direct debug memory
 *      interface that exactly the intended column subset of the targeted row
 *      changed and the other row did not (row B is ABOVE head row A, so this also
 *      checks the spine climb past a head).
 * Success = every class probe PASSes and the run reaches teardown with no AIE
 * ERROR.
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

/* Column-subset multicast: a distinct value per probe so both cross-column and
 * cross-row leaks are visible. Verified via the direct debug memory interface
 * (XAie_DataMemBlockRead), not a control-response readback. */
#define DEMO_MC_ADDR 0x2000u /* separate in-range core L1 scratch */
#define DEMO_MC_BD 3         /* shim MM2S BD for the multicast send */

/* Send @val to a column subset of @target_row (selected by @cls) at DEMO_MC_ADDR,
 * then verify via the direct debug memory interface that exactly the intended
 * columns of @target_row hold @val (all-but-last: cols < col_hi; only-last: col_hi;
 * whole-row: all) and no column of the other configured row @other_row does (no
 * cross-row leak). Distinct @val per call keeps stale writes from other classes
 * out of the equality test. Returns 0 on PASS, -1 otherwise. */
static int demo_probe_class(__Runtime_CtrlRowFabric *fab, XAie_DevInst *dev, uint8_t cls, uint8_t target_row,
                            uint8_t other_row, uint32_t val) {
    const char *name = (cls == (uint8_t)ACR_CLASS_ALL_BUT_LAST) ? "all-but-last"
                       : (cls == (uint8_t)ACR_CLASS_ONLY_LAST)  ? "only-last"
                                                                : "whole-row";
    uint32_t wr = val;
    AieRC rc;
    if (cls == (uint8_t)ACR_CLASS_ALL_BUT_LAST)
        rc = __Runtime_ctrl_row_all_but_last_write(fab, target_row, DEMO_MC_ADDR, &wr, 1u, DEMO_MC_BD, DEMO_MM2S_CH, 1);
    else if (cls == (uint8_t)ACR_CLASS_ONLY_LAST)
        rc = __Runtime_ctrl_row_only_last_write(fab, target_row, DEMO_MC_ADDR, &wr, 1u, DEMO_MC_BD, DEMO_MM2S_CH, 1);
    else
        rc = __Runtime_ctrl_row_whole_row_write(fab, target_row, DEMO_MC_ADDR, &wr, 1u, DEMO_MC_BD, DEMO_MM2S_CH, 1);
    if (rc != XAIE_OK) {
        printf("[ctrlrow] %s write row=%u rc=%d\n", name, (unsigned)target_row, (int)rc);
        return -1;
    }
    printf("[ctrlrow] %s write 0x%08x -> addr 0x%x on row %u done\n", name, val, DEMO_MC_ADDR, (unsigned)target_row);

    int fails = 0;
    /* Target row: the intended column subset holds @val; others must not. */
    for (uint8_t dc = DEMO_COL_LO; dc <= DEMO_COL_HI; dc++) {
        int is_last = (dc == DEMO_COL_HI);
        int expect = (cls == (uint8_t)ACR_CLASS_WHOLE_ROW)   ? 1
                     : (cls == (uint8_t)ACR_CLASS_ONLY_LAST) ? is_last
                                                             : !is_last; /* all-but-last */
        uint32_t v = 0u;
        (void)XAie_DataMemBlockRead(dev, XAie_TileLoc(dc, target_row), DEMO_MC_ADDR, &v, sizeof(v));
        int got = (v == val);
        int ok = (got == expect);
        printf("[ctrlrow] %s row=%u tile(%u,%u) -> 0x%08x %s (expect %s) %s\n", name, (unsigned)target_row,
               (unsigned)dc, (unsigned)target_row, v, got ? "SET" : "unset", expect ? "SET" : "unset",
               ok ? "PASS" : "FAIL");
        if (!ok)
            fails++;
    }
    /* Other row: no column may hold this value (no cross-row leak). */
    for (uint8_t dc = DEMO_COL_LO; dc <= DEMO_COL_HI; dc++) {
        uint32_t v = 0u;
        (void)XAie_DataMemBlockRead(dev, XAie_TileLoc(dc, other_row), DEMO_MC_ADDR, &v, sizeof(v));
        int ok = (v != val);
        printf("[ctrlrow] %s row=%u no-leak tile(%u,%u) -> 0x%08x %s\n", name, (unsigned)target_row, (unsigned)dc,
               (unsigned)other_row, v, ok ? "PASS" : "LEAK");
        if (!ok)
            fails++;
    }
    return fails == 0 ? 0 : -1;
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

    /* Emit the control-plan provenance map (CONTROLPAN-PMAP lines) so the
     * aiedebug device-map "Load control plan" button can overlay the row-fabric
     * control route. Must precede the first row_add. On this baremetal target
     * getenv("AIE_CTRL_PMAP") is unavailable, so enable it explicitly here. */
    __Runtime_ctrl_pmap_enable(1);

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

    /* 5. Per-class column-subset writes, verified via the direct debug memory
     * interface. Exercise all three classes on row A (lower head), then whole-row
     * and only-last on row B (ABOVE head A -> also checks the spine climb past a
     * head). only-last on row B rides the transit-east slot through interior tiles
     * to col_hi. Each probe checks exactly the intended columns changed and the
     * other row did not (no cross-row leak). Distinct values keep the checks clean. */
    int fails = 0;
    fails += demo_probe_class(&fab, dev, (uint8_t)ACR_CLASS_ALL_BUT_LAST, DEMO_CORE_ROW_A, DEMO_CORE_ROW_B, 0xA1B00003u)
                 ? 1
                 : 0;
    fails += demo_probe_class(&fab, dev, (uint8_t)ACR_CLASS_ONLY_LAST, DEMO_CORE_ROW_A, DEMO_CORE_ROW_B, 0x0A1A0003u)
                 ? 1
                 : 0;
    fails += demo_probe_class(&fab, dev, (uint8_t)ACR_CLASS_WHOLE_ROW, DEMO_CORE_ROW_A, DEMO_CORE_ROW_B, 0x00110003u)
                 ? 1
                 : 0;
    fails += demo_probe_class(&fab, dev, (uint8_t)ACR_CLASS_WHOLE_ROW, DEMO_CORE_ROW_B, DEMO_CORE_ROW_A, 0x00110005u)
                 ? 1
                 : 0;
    fails += demo_probe_class(&fab, dev, (uint8_t)ACR_CLASS_ONLY_LAST, DEMO_CORE_ROW_B, DEMO_CORE_ROW_A, 0x0A1A0005u)
                 ? 1
                 : 0;

    __Runtime_ctrl_row_close(&fab);
    printf("[ctrlrow] DONE %s (%d multicast failure(s))\n", fails == 0 ? "PASS" : "FAIL", fails);
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
