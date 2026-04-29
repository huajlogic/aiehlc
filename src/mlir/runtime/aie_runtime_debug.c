/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/

#include "aie_runtime_debug.h"
#include "aie_device_map.h"
#include <stdio.h>
#include <string.h>

/* --------------------------------------------------------------------------
 * AIE generation — global, default AIE2PS
 * -------------------------------------------------------------------------- */

AieRt_AieGen g_aiert_gen = AIERT_GEN_AIE2PS;

void AieRt_SetAieGen(AieRt_AieGen gen) { g_aiert_gen = gen; }

/* --------------------------------------------------------------------------
 * Event name lookup tables
 *
 * Sourced directly from:
 *   thirdparty/alib/include/xaiengine/xaie_events_aieml.h  (XAIEML_EVENTS_*)
 *   thirdparty/alib/include/xaiengine/xaie_events_aie2ps.h (XAIE2PS_EVENTS_*)
 *
 * CORE and MEM module IDs are identical between AIEML and AIE2PS.
 * PL module IDs differ: AIEML max=127, AIE2PS max=183 (NOC0/NOC1 extras).
 *
 * Tables are sparse arrays indexed by local hardware event ID.
 * NULL entries indicate gaps (reserved / not defined for this generation).
 * -------------------------------------------------------------------------- */

/* --- CORE module (identical for AIEML and AIE2PS, max ID=127) --- */
static const char *s_core_evt_names[128] = {
    "NONE",                         /* 0 */
    "TRUE",                         /* 1 */
    "GROUP_0",                      /* 2 */
    "TIMER_SYNC",                   /* 3 */
    "TIMER_VALUE_REACHED",          /* 4 */
    "PERF_CNT_0",                   /* 5 */
    "PERF_CNT_1",                   /* 6 */
    "PERF_CNT_2",                   /* 7 */
    "PERF_CNT_3",                   /* 8 */
    "COMBO_EVENT_0",                /* 9 */
    "COMBO_EVENT_1",                /* 10 */
    "COMBO_EVENT_2",                /* 11 */
    "COMBO_EVENT_3",                /* 12 */
    "EDGE_DETECTION_EVENT_0",       /* 13 */
    "EDGE_DETECTION_EVENT_1",       /* 14 */
    "GROUP_PC_EVENT",               /* 15 */
    "PC_0",                         /* 16 */
    "PC_1",                         /* 17 */
    "PC_2",                         /* 18 */
    "PC_3",                         /* 19 */
    "PC_RANGE_0_1",                 /* 20 */
    "PC_RANGE_2_3",                 /* 21 */
    "GROUP_STALL",                  /* 22 */
    "MEMORY_STALL",                 /* 23 */
    "STREAM_STALL",                 /* 24 */
    "CASCADE_STALL",                /* 25 */
    "LOCK_STALL",                   /* 26 */
    "DEBUG_HALTED",                 /* 27 */
    "ACTIVE",                       /* 28 */
    "DISABLED",                     /* 29 */
    "ECC_ERROR_STALL",              /* 30 */
    "ECC_SCRUBBING_STALL",          /* 31 */
    "GROUP_CORE_PROGRAM_FLOW",      /* 32 */
    "INSTR_EVENT_0",                /* 33 */
    "INSTR_EVENT_1",                /* 34 */
    "INSTR_CALL",                   /* 35 */
    "INSTR_RETURN",                 /* 36 */
    "INSTR_VECTOR",                 /* 37 */
    "INSTR_LOAD",                   /* 38 */
    "INSTR_STORE",                  /* 39 */
    "INSTR_STREAM_GET",             /* 40 */
    "INSTR_STREAM_PUT",             /* 41 */
    "INSTR_CASCADE_GET",            /* 42 */
    "INSTR_CASCADE_PUT",            /* 43 */
    "INSTR_LOCK_ACQUIRE_REQ",       /* 44 */
    "INSTR_LOCK_RELEASE_REQ",       /* 45 */
    "GROUP_ERRORS_0",               /* 46 */
    "GROUP_ERRORS_1",               /* 47 */
    "SRS_SATURATE",                 /* 48 */
    "UPS_SATURATE",                 /* 49 */
    "FP_OVERFLOW",                  /* 50 */
    "FP_UNDERFLOW",                 /* 51 */
    "FP_INVALID",                   /* 52 */
    "FP_DIV_BY_ZERO",               /* 53 */
    "TLAST_IN_WSS_WORDS_0_2",       /* 54 */
    "PM_REG_ACCESS_FAILURE",        /* 55 */
    "STREAM_PKT_PARITY_ERROR",      /* 56 */
    "CONTROL_PKT_ERROR",            /* 57 */
    "AXI_MM_SLAVE_ERROR",           /* 58 */
    "INSTR_DECOMPRSN_ERROR",        /* 59 */
    "DM_ADDRESS_OUT_OF_RANGE",      /* 60 */
    "PM_ECC_ERROR_SCRUB_CORRECTED", /* 61 */
    "PM_ECC_ERROR_SCRUB_2BIT",      /* 62 */
    "PM_ECC_ERROR_1BIT",            /* 63 */
    "PM_ECC_ERROR_2BIT",            /* 64 */
    "PM_ADDRESS_OUT_OF_RANGE",      /* 65 */
    "DM_ACCESS_TO_UNAVAILABLE",     /* 66 */
    "LOCK_ACCESS_TO_UNAVAILABLE",   /* 67 */
    NULL,                           /* 68 */
    NULL,                           /* 69 */
    "GROUP_STREAM_SWITCH",          /* 70 */
    "PORT_IDLE_0",                  /* 71 */
    "PORT_RUNNING_0",               /* 72 */
    "PORT_STALLED_0",               /* 73 */
    "PORT_TLAST_0",                 /* 74 */
    "PORT_IDLE_1",                  /* 75 */
    "PORT_RUNNING_1",               /* 76 */
    "PORT_STALLED_1",               /* 77 */
    "PORT_TLAST_1",                 /* 78 */
    "PORT_IDLE_2",                  /* 79 */
    "PORT_RUNNING_2",               /* 80 */
    "PORT_STALLED_2",               /* 81 */
    "PORT_TLAST_2",                 /* 82 */
    "PORT_IDLE_3",                  /* 83 */
    "PORT_RUNNING_3",               /* 84 */
    "PORT_STALLED_3",               /* 85 */
    "PORT_TLAST_3",                 /* 86 */
    "PORT_IDLE_4",                  /* 87 */
    "PORT_RUNNING_4",               /* 88 */
    "PORT_STALLED_4",               /* 89 */
    "PORT_TLAST_4",                 /* 90 */
    "PORT_IDLE_5",                  /* 91 */
    "PORT_RUNNING_5",               /* 92 */
    "PORT_STALLED_5",               /* 93 */
    "PORT_TLAST_5",                 /* 94 */
    "PORT_IDLE_6",                  /* 95 */
    "PORT_RUNNING_6",               /* 96 */
    "PORT_STALLED_6",               /* 97 */
    "PORT_TLAST_6",                 /* 98 */
    "PORT_IDLE_7",                  /* 99 */
    "PORT_RUNNING_7",               /* 100 */
    "PORT_STALLED_7",               /* 101 */
    "PORT_TLAST_7",                 /* 102 */
    "GROUP_BROADCAST",              /* 103 */
    "BROADCAST_0",                  /* 104 */
    "BROADCAST_1",                  /* 105 */
    "BROADCAST_2",                  /* 106 */
    "BROADCAST_3",                  /* 107 */
    "BROADCAST_4",                  /* 108 */
    "BROADCAST_5",                  /* 109 */
    "BROADCAST_6",                  /* 110 */
    "BROADCAST_7",                  /* 111 */
    "BROADCAST_8",                  /* 112 */
    "BROADCAST_9",                  /* 113 */
    "BROADCAST_10",                 /* 114 */
    "BROADCAST_11",                 /* 115 */
    "BROADCAST_12",                 /* 116 */
    "BROADCAST_13",                 /* 117 */
    "BROADCAST_14",                 /* 118 */
    "BROADCAST_15",                 /* 119 */
    "GROUP_USER_EVENT",             /* 120 */
    "USER_EVENT_0",                 /* 121 */
    "USER_EVENT_1",                 /* 122 */
    "USER_EVENT_2",                 /* 123 */
    "USER_EVENT_3",                 /* 124 */
    NULL,                           /* 125 */
    NULL,                           /* 126 */
    NULL,                           /* 127 */
};
#define AIERT_CORE_EVT_MAX 127u

/* --- MEM module (identical for AIEML and AIE2PS, max ID=160) --- */
static const char *s_mem_evt_names[161] = {
    "NONE",                            /* 0 */
    "TRUE",                            /* 1 */
    "GROUP_0",                         /* 2 */
    "TIMER_SYNC",                      /* 3 */
    "TIMER_VALUE_REACHED",             /* 4 */
    "PERF_CNT_0",                      /* 5 */
    "PERF_CNT_1",                      /* 6 */
    "COMBO_EVENT_0",                   /* 7 */
    "COMBO_EVENT_1",                   /* 8 */
    "COMBO_EVENT_2",                   /* 9 */
    "COMBO_EVENT_3",                   /* 10 */
    "EDGE_DETECTION_EVENT_0",          /* 11 */
    "EDGE_DETECTION_EVENT_1",          /* 12 */
    NULL,                              /* 13 */
    NULL,                              /* 14 */
    "GROUP_WATCHPOINT",                /* 15 */
    "WATCHPOINT_0",                    /* 16 */
    "WATCHPOINT_1",                    /* 17 */
    "GROUP_DMA_ACTIVITY",              /* 18 */
    "DMA_S2MM_0_START_TASK",           /* 19 */
    "DMA_S2MM_1_START_TASK",           /* 20 */
    "DMA_MM2S_0_START_TASK",           /* 21 */
    "DMA_MM2S_1_START_TASK",           /* 22 */
    "DMA_S2MM_0_FINISHED_BD",          /* 23 */
    "DMA_S2MM_1_FINISHED_BD",          /* 24 */
    "DMA_MM2S_0_FINISHED_BD",          /* 25 */
    "DMA_MM2S_1_FINISHED_BD",          /* 26 */
    "DMA_S2MM_0_FINISHED_TASK",        /* 27 */
    "DMA_S2MM_1_FINISHED_TASK",        /* 28 */
    "DMA_MM2S_0_FINISHED_TASK",        /* 29 */
    "DMA_MM2S_1_FINISHED_TASK",        /* 30 */
    "DMA_S2MM_0_STALLED_LOCK",         /* 31 */
    "DMA_S2MM_1_STALLED_LOCK",         /* 32 */
    "DMA_MM2S_0_STALLED_LOCK",         /* 33 */
    "DMA_MM2S_1_STALLED_LOCK",         /* 34 */
    "DMA_S2MM_0_STREAM_STARVATION",    /* 35 */
    "DMA_S2MM_1_STREAM_STARVATION",    /* 36 */
    "DMA_MM2S_0_STREAM_BACKPRESSURE",  /* 37 — stream switch won't accept packet */
    "DMA_MM2S_1_STREAM_BACKPRESSURE",  /* 38 */
    "DMA_S2MM_0_MEMORY_BACKPRESSURE",  /* 39 */
    "DMA_S2MM_1_MEMORY_BACKPRESSURE",  /* 40 */
    "DMA_MM2S_0_MEMORY_STARVATION",    /* 41 */
    "DMA_MM2S_1_MEMORY_STARVATION",    /* 42 */
    "GROUP_LOCK",                      /* 43 */
    "LOCK_SEL0_ACQ_EQ",                /* 44 */
    "LOCK_SEL0_ACQ_GE",                /* 45 */
    "LOCK_0_REL",                      /* 46 */
    "LOCK_SEL0_EQUAL_TO_VALUE",        /* 47 */
    "LOCK_SEL1_ACQ_EQ",                /* 48 */
    "LOCK_SEL1_ACQ_GE",                /* 49 */
    "LOCK_1_REL",                      /* 50 */
    "LOCK_SEL1_EQUAL_TO_VALUE",        /* 51 */
    "LOCK_SEL2_ACQ_EQ",                /* 52 */
    "LOCK_SEL2_ACQ_GE",                /* 53 */
    "LOCK_2_REL",                      /* 54 */
    "LOCK_SEL2_EQUAL_TO_VALUE",        /* 55 */
    "LOCK_SEL3_ACQ_EQ",                /* 56 */
    "LOCK_SEL3_ACQ_GE",                /* 57 */
    "LOCK_3_REL",                      /* 58 */
    "LOCK_SEL3_EQUAL_TO_VALUE",        /* 59 */
    "LOCK_SEL4_ACQ_EQ",                /* 60 */
    "LOCK_SEL4_ACQ_GE",                /* 61 */
    "LOCK_4_REL",                      /* 62 */
    "LOCK_SEL4_EQUAL_TO_VALUE",        /* 63 */
    "LOCK_SEL5_ACQ_EQ",                /* 64 */
    "LOCK_SEL5_ACQ_GE",                /* 65 */
    "LOCK_5_REL",                      /* 66 */
    "LOCK_SEL5_EQUAL_TO_VALUE",        /* 67 */
    "LOCK_SEL6_ACQ_EQ",                /* 68 */
    "LOCK_SEL6_ACQ_GE",                /* 69 */
    "LOCK_6_REL",                      /* 70 */
    "LOCK_SEL6_EQUAL_TO_VALUE",        /* 71 */
    "LOCK_SEL7_ACQ_EQ",                /* 72 */
    "LOCK_SEL7_ACQ_GE",                /* 73 */
    "LOCK_7_REL",                      /* 74 */
    "LOCK_SEL7_EQUAL_TO_VALUE",        /* 75 */
    NULL,                              /* 76 */
    NULL,                              /* 77 */
    NULL,                              /* 78 */
    NULL,                              /* 79 */
    NULL,                              /* 80 */
    NULL,                              /* 81 */
    NULL,                              /* 82 */
    NULL,                              /* 83 */
    NULL,                              /* 84 */
    NULL,                              /* 85 */
    NULL,                              /* 86 */
    NULL,                              /* 87 */
    NULL,                              /* 88 */
    NULL,                              /* 89 */
    NULL,                              /* 90 */
    NULL,                              /* 91 */
    NULL,                              /* 92 */
    NULL,                              /* 93 */
    NULL,                              /* 94 */
    NULL,                              /* 95 */
    "GROUP_ERRORS",                    /* 96 */
    "DM_ECC_ERROR_SCRUB_CORRECTED",    /* 97 */
    "DM_ECC_ERROR_SCRUB_2BIT",         /* 98 */
    "DM_ECC_ERROR_1BIT",               /* 99 */
    "DM_ECC_ERROR_2BIT",               /* 100 */
    "DM_PARITY_ERROR_BANK_2",          /* 101 */
    "DM_PARITY_ERROR_BANK_3",          /* 102 */
    "DM_PARITY_ERROR_BANK_4",          /* 103 */
    "DM_PARITY_ERROR_BANK_5",          /* 104 */
    "DM_PARITY_ERROR_BANK_6",          /* 105 */
    "DM_PARITY_ERROR_BANK_7",          /* 106 */
    "DMA_S2MM_0_ERROR",                /* 107 */
    "DMA_S2MM_1_ERROR",                /* 108 */
    "DMA_MM2S_0_ERROR",                /* 109 */
    "DMA_MM2S_1_ERROR",                /* 110 */
    NULL,                              /* 111 */
    "GROUP_BROADCAST",                 /* 112 */
    "BROADCAST_0",                     /* 113 */
    "BROADCAST_1",                     /* 114 */
    "BROADCAST_2",                     /* 115 */
    "BROADCAST_3",                     /* 116 */
    "BROADCAST_4",                     /* 117 */
    "BROADCAST_5",                     /* 118 */
    "BROADCAST_6",                     /* 119 */
    "BROADCAST_7",                     /* 120 */
    "BROADCAST_8",                     /* 121 */
    "BROADCAST_9",                     /* 122 */
    "BROADCAST_10",                    /* 123 */
    "BROADCAST_11",                    /* 124 */
    "BROADCAST_12",                    /* 125 */
    "BROADCAST_13",                    /* 126 */
    "BROADCAST_14",                    /* 127 */
    "BROADCAST_15",                    /* 128 */
    "GROUP_USER_EVENT",                /* 129 */
    "USER_EVENT_0",                    /* 130 */
    "USER_EVENT_1",                    /* 131 */
    "USER_EVENT_2",                    /* 132 */
    "USER_EVENT_3",                    /* 133 */
    NULL,                              /* 134 */
    NULL,                              /* 135 */
    "DMA_S2MM_0_START_TASK2",          /* 136 — XAIEML_EVENTS_MEM_DMA_S2MM_0_START_TASK=136 (2nd alias) */
    "DMA_S2MM_1_START_TASK2",          /* 137 */
    "DMA_MM2S_0_START_TASK2",          /* 138 */
    "DMA_MM2S_1_START_TASK2",          /* 139 */
    "DMA_S2MM_0_FINISHED_TASK2",       /* 140 */
    "DMA_S2MM_1_FINISHED_TASK2",       /* 141 */
    "DMA_MM2S_0_FINISHED_TASK2",       /* 142 */
    "DMA_MM2S_1_FINISHED_TASK2",       /* 143 */
    "DMA_S2MM_0_STALLED_LOCK2",        /* 144 */
    "DMA_S2MM_1_STALLED_LOCK2",        /* 145 */
    "DMA_MM2S_0_STALLED_LOCK2",        /* 146 */
    "DMA_MM2S_1_STALLED_LOCK2",        /* 147 */
    "DMA_S2MM_0_STREAM_STARVATION2",   /* 148 */
    "DMA_S2MM_1_STREAM_STARVATION2",   /* 149 */
    "DMA_MM2S_0_STREAM_BACKPRESSURE2", /* 150 */
    "DMA_MM2S_1_STREAM_BACKPRESSURE2", /* 151 */
    "DMA_S2MM_0_MEMORY_BACKPRESSURE2", /* 152 */
    "DMA_S2MM_1_MEMORY_BACKPRESSURE2", /* 153 */
    "DMA_MM2S_0_MEMORY_STARVATION2",   /* 154 */
    "DMA_MM2S_1_MEMORY_STARVATION2",   /* 155 */
    "LOCK_SEL0_ACQ_EQ2",               /* 156 */
    "LOCK_SEL0_ACQ_GE2",               /* 157 */
    "LOCK_SEL0_EQUAL_TO_VALUE2",       /* 158 */
    "LOCK_SEL1_ACQ_EQ2",               /* 159 */
    "LOCK_ERROR",                      /* 160 */
};
#define AIERT_MEM_EVT_MAX 160u

/* --- PL module (Shim tile) event status register bit layout.
 *
 * Source: aie2psevent.md §4 "Shim Tile Events (IDs 0-116)"
 * This is the HARDWARE event status register bit layout, NOT the XAie
 * driver enum values (xaie_events_aieml.h / xaie_events_aie2ps.h).
 * The XAie enums are software IDs used to program event counters and
 * do NOT match the hardware register bit positions.
 *
 * Both AIEML and AIE2PS use the same shim event status register layout.
 * Max hardware event ID = 116 (COMBO_EVENT_3). One table covers both gens.
 */
static const char *s_pl_evt_names[117] = {
    "NONE",                           /* 0 */
    "TRUE",                           /* 1 */
    "PERF_CNT0",                      /* 2 */
    "PERF_CNT1",                      /* 3 */
    "PERF_CNT0_HALF",                 /* 4 */
    "PERF_CNT1_HALF",                 /* 5 */
    "PL_FALLING_EDGE_0",              /* 6 */
    "PL_FALLING_EDGE_1",              /* 7 */
    "PL_RISING_EDGE_0",               /* 8 */
    "PL_RISING_EDGE_1",               /* 9 */
    "PL_FALLING_EDGE_2",              /* 10 */
    "PL_FALLING_EDGE_3",              /* 11 */
    "PL_RISING_EDGE_2",               /* 12 */
    "PL_RISING_EDGE_3",               /* 13 */
    "DMA_S2MM_0_START_TASK",          /* 14 */
    "DMA_S2MM_1_START_TASK",          /* 15 */
    "DMA_MM2S_0_START_TASK",          /* 16 */
    "DMA_MM2S_1_START_TASK",          /* 17 */
    "DMA_S2MM_0_FINISHED_TASK",       /* 18 */
    "DMA_S2MM_1_FINISHED_TASK",       /* 19 */
    "DMA_MM2S_0_FINISHED_TASK",       /* 20 */
    "DMA_MM2S_1_FINISHED_TASK",       /* 21 */
    "DMA_S2MM_0_STALLED_LOCK",        /* 22 */
    "DMA_S2MM_1_STALLED_LOCK",        /* 23 */
    "DMA_MM2S_0_STALLED_LOCK",        /* 24 */
    "DMA_MM2S_1_STALLED_LOCK",        /* 25 */
    "DMA_S2MM_0_STREAM_STARVATION",   /* 26 */
    "DMA_S2MM_1_STREAM_STARVATION",   /* 27 */
    "DMA_MM2S_0_STREAM_BACKPRESSURE", /* 28 */
    "DMA_MM2S_1_STREAM_BACKPRESSURE", /* 29 */
    "DMA_S2MM_0_MEMORY_BACKPRESSURE", /* 30 */
    "DMA_S2MM_1_MEMORY_BACKPRESSURE", /* 31 */
    "DMA_MM2S_0_MEMORY_STARVATION",   /* 32 */
    "DMA_MM2S_1_MEMORY_STARVATION",   /* 33 */
    "LOCK_0_ACQ_EQ",                  /* 34 */
    "LOCK_0_ACQ_GE",                  /* 35 */
    "LOCK_0_EQUAL_TO_VALUE",          /* 36 */
    "LOCK_1_ACQ_EQ",                  /* 37 */
    "LOCK_1_ACQ_GE",                  /* 38 */
    "LOCK_1_EQUAL_TO_VALUE",          /* 39 */
    "LOCK_2_ACQ_EQ",                  /* 40 */
    "LOCK_2_ACQ_GE",                  /* 41 */
    "LOCK_2_EQUAL_TO_VALUE",          /* 42 */
    "LOCK_3_ACQ_EQ",                  /* 43 */
    "LOCK_3_ACQ_GE",                  /* 44 */
    "LOCK_3_EQUAL_TO_VALUE",          /* 45 */
    "LOCK_4_ACQ_EQ",                  /* 46 */
    "LOCK_4_ACQ_GE",                  /* 47 */
    "LOCK_4_EQUAL_TO_VALUE",          /* 48 */
    "LOCK_5_ACQ_EQ",                  /* 49 */
    "LOCK_5_ACQ_GE",                  /* 50 */
    "LOCK_5_EQUAL_TO_VALUE",          /* 51 */
    "SS_STALL_0",                     /* 52 */
    "SS_STALL_1",                     /* 53 */
    "SS_STALL_2",                     /* 54 */
    "SS_STALL_3",                     /* 55 */
    "SS_STALL_4",                     /* 56 */
    "SS_STALL_5",                     /* 57 */
    "SS_STALL_6",                     /* 58 */
    "SS_STALL_7",                     /* 59 */
    "SS_OVERFLOW",                    /* 60 */
    "PORT_IDLE_0",                    /* 61 */
    "PORT_IDLE_1",                    /* 62 */
    "PORT_IDLE_2",                    /* 63 */
    "PORT_IDLE_3",                    /* 64 */
    "PORT_IDLE_4",                    /* 65 */
    "PORT_IDLE_5",                    /* 66 */
    "PORT_IDLE_6",                    /* 67 */
    "PORT_IDLE_7",                    /* 68 */
    "PORT_RUNNING_0",                 /* 69 */
    "PORT_RUNNING_1",                 /* 70 */
    "PORT_RUNNING_2",                 /* 71 */
    "PORT_RUNNING_3",                 /* 72 */
    "PORT_RUNNING_4",                 /* 73 */
    "PORT_RUNNING_5",                 /* 74 */
    "PORT_RUNNING_6",                 /* 75 */
    "PORT_RUNNING_7",                 /* 76 */
    "PORT_STALL_0",                   /* 77 */
    "PORT_STALL_1",                   /* 78 */
    "PORT_STALL_2",                   /* 79 */
    "PORT_STALL_3",                   /* 80 */
    "PORT_STALL_4",                   /* 81 */
    "PORT_STALL_5",                   /* 82 */
    "PORT_STALL_6",                   /* 83 */
    "PORT_STALL_7",                   /* 84 */
    "PORT_TLAST_0",                   /* 85 */
    "PORT_TLAST_1",                   /* 86 */
    "PORT_TLAST_2",                   /* 87 */
    "PORT_TLAST_3",                   /* 88 */
    "PORT_TLAST_4",                   /* 89 */
    "PORT_TLAST_5",                   /* 90 */
    "PORT_TLAST_6",                   /* 91 */
    "PORT_TLAST_7",                   /* 92 */
    "BROADCAST_A_0",                  /* 93 */
    "BROADCAST_A_1",                  /* 94 */
    "BROADCAST_A_2",                  /* 95 */
    "BROADCAST_A_3",                  /* 96 */
    "BROADCAST_A_4",                  /* 97 */
    "BROADCAST_A_5",                  /* 98 */
    "BROADCAST_A_6",                  /* 99 */
    "BROADCAST_A_7",                  /* 100 */
    "BROADCAST_A_8",                  /* 101 */
    "BROADCAST_A_9",                  /* 102 */
    "BROADCAST_A_10",                 /* 103 */
    "BROADCAST_A_11",                 /* 104 */
    "BROADCAST_A_12",                 /* 105 */
    "BROADCAST_A_13",                 /* 106 */
    "BROADCAST_A_14",                 /* 107 */
    "BROADCAST_A_15",                 /* 108 */
    "USER_EVENT_0",                   /* 109 */
    "USER_EVENT_1",                   /* 110 */
    "EDGE_DETECTION_EVENT_0",         /* 111 */
    "EDGE_DETECTION_EVENT_1",         /* 112 */
    "COMBO_EVENT_0",                  /* 113 */
    "COMBO_EVENT_1",                  /* 114 */
    "COMBO_EVENT_2",                  /* 115 */
    "COMBO_EVENT_3",                  /* 116 */
};
#define AIERT_PL_EVT_MAX 116u
/* Both AIEML and AIE2PS share the same shim event status register bit layout */
#define AIERT_PL_EVT_AIEML_MAX AIERT_PL_EVT_MAX
#define AIERT_PL_EVT_AIE2PS_MAX AIERT_PL_EVT_MAX

/* --------------------------------------------------------------------------
 * Internal helpers
 * -------------------------------------------------------------------------- */

static int s_is_shim(XAie_LocType tile) { return tile.Row == XAIE_SHIM_ROW; }
static int s_is_memtile(XAie_LocType tile) {
    return tile.Row >= XAIE_RES_TILE_ROW_START && tile.Row < (XAIE_RES_TILE_ROW_START + XAIE_RES_TILE_NUM_ROWS);
}
static int s_is_core(XAie_LocType tile) { return tile.Row >= XAIE_AIE_TILE_ROW_START; }

static const char *s_dir_str(XAie_DmaDirection dir) { return (dir == DMA_S2MM) ? "S2MM" : "MM2S"; }

static const char *s_status_str(uint8_t status) {
    switch (status) {
    case AIERT_DMA_STATUS_IDLE:
        return "Idle";
    case AIERT_DMA_STATUS_RUNNING:
        return "Running";
    case AIERT_DMA_STATUS_PAUSED:
        return "Paused";
    default:
        return "Unknown";
    }
}
/* --------------------------------------------------------------------------
 * AieRt_EventName — module-local ID → string
 * -------------------------------------------------------------------------- */

const char *AieRt_EventName(XAie_ModuleType module, uint32_t id) {
    static char s_fallback[24]; /* non-re-entrant fallback for unknown IDs */

    if (module == XAIE_CORE_MOD) {
        if (id <= AIERT_CORE_EVT_MAX && s_core_evt_names[id])
            return s_core_evt_names[id];
    } else if (module == XAIE_MEM_MOD) {
        if (id <= AIERT_MEM_EVT_MAX && s_mem_evt_names[id])
            return s_mem_evt_names[id];
    } else if (module == XAIE_PL_MOD) {
        if (id <= AIERT_PL_EVT_MAX && s_pl_evt_names[id])
            return s_pl_evt_names[id];
    }
    /* Unknown: format into static buffer */
    snprintf(s_fallback, sizeof(s_fallback), "EVT_%u", (unsigned)id);
    return s_fallback;
}

/* --------------------------------------------------------------------------
 * Memory Module event status print — all set bits with names
 *
 * Reads the core tile Memory Module event status registers:
 *   0x00014200 : MEM module event IDs  0-31
 *   0x00014204 : MEM module event IDs 32-63
 *
 * For each set bit, prints: id + name from AieRt_EventName(XAIE_MEM_MOD, id)
 * -------------------------------------------------------------------------- */

#define AIERT_CORE_MEM_EVT_STATUS_REG1 0x00014204u

void AieRt_PrintMemModuleEvents(XAie_DevInst *dev, XAie_LocType tile) {
    if (!s_is_core(tile)) {
        printf("[AieRt_Debug] tile(%u,%u): not a core tile, skip mem module events\n", (unsigned)tile.Col,
               (unsigned)tile.Row);
        return;
    }

    u64 base = ((u64)tile.Col << 25) | ((u64)tile.Row << 20);
    u32 reg0 = 0, reg1 = 0;
    XAie_Read32(dev, base | AIERT_CORE_MEM_EVT_STATUS_REG, &reg0);
    XAie_Read32(dev, base | AIERT_CORE_MEM_EVT_STATUS_REG1, &reg1);

    const char *gen_str = (g_aiert_gen == AIERT_GEN_AIE2PS) ? "AIE2PS" : "AIEML";
    printf("[AieRt_Debug] tile(%u,%u) MEM module events [gen=%s]"
           "  reg0(IDs 0-31)=0x%08X  reg1(IDs 32-63)=0x%08X\n",
           (unsigned)tile.Col, (unsigned)tile.Row, gen_str, (unsigned)reg0, (unsigned)reg1);

    int any = 0;
    for (int bit = 0; bit < 32; bit++) {
        if ((reg0 >> bit) & 1u) {
            printf("  MEM evt %3d  %s\n", bit, AieRt_EventName(XAIE_MEM_MOD, (uint32_t)bit));
            any = 1;
        }
    }
    for (int bit = 0; bit < 32; bit++) {
        if ((reg1 >> bit) & 1u) {
            int id = 32 + bit;
            printf("  MEM evt %3d  %s\n", id, AieRt_EventName(XAIE_MEM_MOD, (uint32_t)id));
            any = 1;
        }
    }
    if (!any)
        printf("  (no MEM module events set)\n");
}

void AieRt_PrintMemModuleEventsAll(XAie_DevInst *dev, const XAie_LocType *tiles, uint32_t num_tiles) {
    const char *gen_str = (g_aiert_gen == AIERT_GEN_AIE2PS) ? "AIE2PS" : "AIEML";
    printf("[AieRt_Debug] ===== MEM Module Events [gen=%s] (%u tiles) =====\n", gen_str, (unsigned)num_tiles);
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (s_is_core(tiles[i]))
            AieRt_PrintMemModuleEvents(dev, tiles[i]);
    }
}

/* --------------------------------------------------------------------------
 * Core Module event status print — all set bits with names
 *
 * Reads the core tile Core Module event status registers:
 *   0x00034200 : CORE module event IDs  0-31
 *   0x00034204 : CORE module event IDs 32-63
 *
 * For each set bit, prints: id + name from AieRt_EventName(XAIE_CORE_MOD, id)
 * -------------------------------------------------------------------------- */

void AieRt_PrintCoreModuleEvents(XAie_DevInst *dev, XAie_LocType tile) {
    if (!s_is_core(tile)) {
        printf("[AieRt_Debug] tile(%u,%u): not a core tile, skip core module events\n", (unsigned)tile.Col,
               (unsigned)tile.Row);
        return;
    }

    u64 base = ((u64)tile.Col << 25) | ((u64)tile.Row << 20);
    u32 reg0 = 0, reg1 = 0;
    XAie_Read32(dev, base | AIERT_CORE_CORE_EVT_STATUS_REG, &reg0);
    XAie_Read32(dev, base | AIERT_CORE_CORE_EVT_STATUS_REG1, &reg1);

    const char *gen_str = (g_aiert_gen == AIERT_GEN_AIE2PS) ? "AIE2PS" : "AIEML";
    printf("[AieRt_Debug] tile(%u,%u) CORE module events [gen=%s]"
           "  reg0(IDs 0-31)=0x%08X  reg1(IDs 32-63)=0x%08X\n",
           (unsigned)tile.Col, (unsigned)tile.Row, gen_str, (unsigned)reg0, (unsigned)reg1);

    int any = 0;
    for (int bit = 0; bit < 32; bit++) {
        if ((reg0 >> bit) & 1u) {
            printf("  CORE evt %3d  %s\n", bit, AieRt_EventName(XAIE_CORE_MOD, (uint32_t)bit));
            any = 1;
        }
    }
    for (int bit = 0; bit < 32; bit++) {
        if ((reg1 >> bit) & 1u) {
            int id = 32 + bit;
            printf("  CORE evt %3d  %s\n", id, AieRt_EventName(XAIE_CORE_MOD, (uint32_t)id));
            any = 1;
        }
    }
    if (!any)
        printf("  (no CORE module events set)\n");
}

void AieRt_PrintCoreModuleEventsAll(XAie_DevInst *dev, const XAie_LocType *tiles, uint32_t num_tiles) {
    const char *gen_str = (g_aiert_gen == AIERT_GEN_AIE2PS) ? "AIE2PS" : "AIEML";
    printf("[AieRt_Debug] ===== CORE Module Events [gen=%s] (%u tiles) =====\n", gen_str, (unsigned)num_tiles);
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (s_is_core(tiles[i]))
            AieRt_PrintCoreModuleEvents(dev, tiles[i]);
    }
}

/* --------------------------------------------------------------------------
 * Core status
 * -------------------------------------------------------------------------- */

void AieRt_PrintCoreStatus(XAie_DevInst *dev, XAie_LocType tile) {
    if (!s_is_core(tile)) {
        printf("[AieRt_Debug] tile(%u,%u) is not a core tile, skip core status\n", (unsigned)tile.Col,
               (unsigned)tile.Row);
        return;
    }

    u32 core_status = 0;
    AieRC rc = XAie_CoreGetStatus(dev, tile, &core_status);
    if (rc != XAIE_OK) {
        printf("[AieRt_Debug] CoreGetStatus tile(%u,%u) failed rc=%d\n", (unsigned)tile.Col, (unsigned)tile.Row,
               (int)rc);
        return;
    }

    u32 lr = 0;
    int in_reset = (core_status & XAIE_CORE_STATUS_RESET) != 0;
    if (!in_reset)
        XAie_CoreGetLRValue(dev, tile, &lr);

    /* Read status, PC, SP directly from hardware registers */
    u64 status_reg_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_STATUS_REG;
    u64 pc_reg_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_PC_REG;
    u64 sp_reg_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_SP_REG;
    u32 raw_status = 0, raw_pc = 0, raw_sp = 0;
    XAie_Read32(dev, status_reg_off, &raw_status);
    XAie_Read32(dev, pc_reg_off, &raw_pc);
    XAie_Read32(dev, sp_reg_off, &raw_sp);

    /* Decode raw_status per xaiemlgbl_params.h / Core_Status register layout:
     *   [21] CORE_PROCESSOR_BUS_STALL   [20] CORE_DONE
     *   [19] ERROR_HALT                 [18] ECC_SCRUBBING_STALL
     *   [17] ECC_ERROR_STALL            [16] DEBUG_HALT
     *   [15] CASCADE_STALL_MCD         [14] CASCADE_STALL_SCD
     *   [12] STREAM_STALL_MS0          [10] STREAM_STALL_SS0
     *   [ 9] LOCK_STALL_E  [ 8] LOCK_STALL_N  [ 7] LOCK_STALL_W  [ 6] LOCK_STALL_S
     *   [ 5] MEMORY_STALL_E [ 4] MEMORY_STALL_N [ 3] MEMORY_STALL_W [ 2] MEMORY_STALL_S
     *   [ 1] RESET          [ 0] ENABLE
     * mask 0x003FFFFF  (bits 22-31 reserved)
     */
    printf("[AieRt_Debug] Core tile(%u,%u) status=0x%08X\n", (unsigned)tile.Col, (unsigned)tile.Row,
           (unsigned)core_status);
    printf("  Core_Status  : 0x%08X  (reg 0x%05X, mask 0x003FFFFF)\n", (unsigned)raw_status,
           (unsigned)AIERT_CORE_STATUS_REG);
    printf("  Core_PC      : 0x%05X  (reg 0x%05X, mask 0x000FFFFF)\n", (unsigned)(raw_pc & AIERT_CORE_PC_MASK),
           (unsigned)AIERT_CORE_PC_REG);
    printf("  Core_SP      : 0x%08X  (reg 0x%05X)\n", (unsigned)raw_sp, (unsigned)AIERT_CORE_SP_REG);
    /* Bit-field decode of Core_Status */
    printf("  [21] PROC_BUS_STALL  : %s\n", (raw_status & 0x00200000u) ? "YES" : "no");
    printf("  [20] CORE_DONE       : %s\n", (raw_status & 0x00100000u) ? "YES" : "no");
    printf("  [19] ERROR_HALT      : %s\n", (raw_status & 0x00080000u) ? "YES" : "no");
    printf("  [18] ECC_SCRUB_STALL : %s\n", (raw_status & 0x00040000u) ? "YES" : "no");
    printf("  [17] ECC_ERR_STALL   : %s\n", (raw_status & 0x00020000u) ? "YES" : "no");
    printf("  [16] DEBUG_HALT      : %s\n", (raw_status & 0x00010000u) ? "YES" : "no");
    printf("  [15] CASCADE_STALL_MCD: %s\n", (raw_status & 0x00008000u) ? "YES" : "no");
    printf("  [14] CASCADE_STALL_SCD: %s\n", (raw_status & 0x00004000u) ? "YES" : "no");
    printf("  [12] STREAM_STALL_MS0: %s\n", (raw_status & 0x00001000u) ? "YES" : "no");
    printf("  [10] STREAM_STALL_SS0: %s\n", (raw_status & 0x00000400u) ? "YES" : "no");
    printf("  [ 9] LOCK_STALL_E    : %s\n", (raw_status & 0x00000200u) ? "YES" : "no");
    printf("  [ 8] LOCK_STALL_N    : %s\n", (raw_status & 0x00000100u) ? "YES" : "no");
    printf("  [ 7] LOCK_STALL_W    : %s\n", (raw_status & 0x00000080u) ? "YES" : "no");
    printf("  [ 6] LOCK_STALL_S    : %s\n", (raw_status & 0x00000040u) ? "YES" : "no");
    printf("  [ 5] MEMORY_STALL_E  : %s\n", (raw_status & 0x00000020u) ? "YES" : "no");
    printf("  [ 4] MEMORY_STALL_N  : %s\n", (raw_status & 0x00000010u) ? "YES" : "no");
    printf("  [ 3] MEMORY_STALL_W  : %s\n", (raw_status & 0x00000008u) ? "YES" : "no");
    printf("  [ 2] MEMORY_STALL_S  : %s\n", (raw_status & 0x00000004u) ? "YES" : "no");
    printf("  [ 1] RESET           : %s\n", (raw_status & 0x00000002u) ? "YES" : "no");
    printf("  [ 0] ENABLE          : %s\n", (raw_status & 0x00000001u) ? "YES" : "no");
    /* LR from XAie API (not directly in Core_Status register) */
    if (!in_reset)
        printf("  LR             : 0x%08X\n", (unsigned)lr);

    /* Read core module event status registers for a live activity snapshot.
     * REG0 (0x00034200): event IDs  0-31
     * REG1 (0x00034204): event IDs 32-63 — contains stall / active bits */
    u64 evt_reg0_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_CORE_EVT_STATUS_REG;
    u64 evt_reg1_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_CORE_EVT_STATUS_REG1;
    u32 evt0 = 0, evt1 = 0;
    AieRC rc_e0 = XAie_Read32(dev, evt_reg0_off, &evt0);
    AieRC rc_e1 = XAie_Read32(dev, evt_reg1_off, &evt1);
    if (rc_e0 == XAIE_OK && rc_e1 == XAIE_OK) {
        printf("  CoreEvtReg0  : 0x%08X  (event IDs  0-31)\n", (unsigned)evt0);
        printf("  CoreEvtReg1  : 0x%08X  (event IDs 32-63)\n", (unsigned)evt1);
        int active = (int)((evt1 >> AIERT_CORE_EVT1_ACTIVE_BIT) & 1u);
        int disabled = (int)((evt1 >> AIERT_CORE_EVT1_DISABLED_BIT) & 1u);
        int ms_stall = (int)((evt1 >> AIERT_CORE_EVT1_MS_STALL_BIT) & 1u);
        int pm_stall = (int)((evt1 >> AIERT_CORE_EVT1_PM_STALL_BIT) & 1u);
        int stream_stall = (int)((evt1 >> AIERT_CORE_EVT1_STREAM_STALL_BIT) & 1u);
        int cascade_stall = (int)((evt1 >> AIERT_CORE_EVT1_CASCADE_STALL_BIT) & 1u);
        int lock_stall = (int)((evt1 >> AIERT_CORE_EVT1_LOCK_STALL_BIT) & 1u);
        int ecc_err_stall = (int)((evt1 >> AIERT_CORE_EVT1_ECC_ERR_STALL_BIT) & 1u);
        int ecc_scrub = (int)((evt1 >> AIERT_CORE_EVT1_ECC_SCRUB_STALL_BIT) & 1u);
        int stall_nop = (int)((evt1 >> AIERT_CORE_EVT1_STALL_NOP_BIT) & 1u);
        printf("  ACTIVE       : %s\n", active ? "YES" : "no");
        printf("  DISABLED     : %s\n", disabled ? "YES" : "no");
        printf("  MS_STALL     : %s\n", ms_stall ? "*** STALL ***" : "no");
        printf("  PM_STALL     : %s\n", pm_stall ? "*** STALL ***" : "no");
        printf("  STREAM_STALL : %s\n", stream_stall ? "*** STALL ***" : "no");
        printf("  CASCADE_STALL: %s\n", cascade_stall ? "*** STALL ***" : "no");
        printf("  LOCK_STALL   : %s\n", lock_stall ? "*** STALL ***" : "no");
        printf("  ECC_ERR_STALL: %s\n", ecc_err_stall ? "*** STALL ***" : "no");
        printf("  ECC_SCRUB    : %s\n", ecc_scrub ? "*** STALL ***" : "no");
        printf("  STALL_NOP    : %s\n", stall_nop ? "YES" : "no");
        if (disabled)
            printf("  *** WARN: core is DISABLED\n");
        if (ms_stall || pm_stall || stream_stall || cascade_stall || lock_stall || ecc_err_stall || ecc_scrub)
            printf("  *** WARN: core has active stall(s)\n");
    } else {
        printf("  CoreEvtReg   : read failed (rc0=%d rc1=%d)\n", (int)rc_e0, (int)rc_e1);
    }
}

void AieRt_PrintCoreStatusAll(XAie_DevInst *dev, const XAie_LocType *tiles, uint32_t num_tiles) {
    printf("[AieRt_Debug] ===== Core Status (%u tiles) =====\n", (unsigned)num_tiles);
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (s_is_core(tiles[i]))
            AieRt_PrintCoreStatus(dev, tiles[i]);
    }
}

/* --------------------------------------------------------------------------
 * Core module activity / stall event analysis
 *
 * Uses AIERT_CORE_CORE_EVT_STATUS_REG  (0x00034200) for event IDs  0-31
 * and   AIERT_CORE_CORE_EVT_STATUS_REG1 (0x00034204) for event IDs 32-63.
 *
 * Address formula from debug.md:
 *   full addr = 0x20000000000 + (col<<25) + (row<<20) + register_offset
 *   tile-relative offset passed to XAie_Read32:
 *     (col<<25) | (row<<20) | offset
 *
 * Relevant events (all in register 1, event IDs 41-55):
 *   bit  9  ID 41  MS_STALL
 *   bit 10  ID 42  PM_STALL (program-memory / instr-load stall)
 *   bit 11  ID 43  STREAM_STALL
 *   bit 12  ID 44  CASCADE_STALL
 *   bit 13  ID 45  LOCK_STALL
 *   bit 15  ID 47  ACTIVE
 *   bit 16  ID 48  DISABLED
 *   bit 17  ID 49  ECC_ERROR_STALL
 *   bit 18  ID 50  ECC_SCRUBBING_STALL
 *   bit 23  ID 55  STALL_NOP
 * -------------------------------------------------------------------------- */

void AieRt_PrintCoreActivityEvents(XAie_DevInst *dev, XAie_LocType tile) {
    if (!s_is_core(tile)) {
        printf("[AieRt_Debug] tile(%u,%u): not a core tile, skip core activity events\n", (unsigned)tile.Col,
               (unsigned)tile.Row);
        return;
    }

    /* Read core module event status register 1 (event IDs 32-63) */
    u64 reg1_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_CORE_EVT_STATUS_REG1;
    u32 evt1 = 0;
    AieRC rc = XAie_Read32(dev, reg1_off, &evt1);
    if (rc != XAIE_OK) {
        printf("[AieRt_Debug] tile(%u,%u): failed to read core_evt_status1 rc=%d\n", (unsigned)tile.Col,
               (unsigned)tile.Row, (int)rc);
        return;
    }

    /* Also read register 0 for completeness (event IDs 0-31) */
    u64 reg0_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_CORE_EVT_STATUS_REG;
    u32 evt0 = 0;
    XAie_Read32(dev, reg0_off, &evt0); /* best-effort; errors non-fatal here */

    int active = (int)((evt1 >> AIERT_CORE_EVT1_ACTIVE_BIT) & 1u);
    int disabled = (int)((evt1 >> AIERT_CORE_EVT1_DISABLED_BIT) & 1u);
    int ms_stall = (int)((evt1 >> AIERT_CORE_EVT1_MS_STALL_BIT) & 1u);
    int pm_stall = (int)((evt1 >> AIERT_CORE_EVT1_PM_STALL_BIT) & 1u);
    int stream_stall = (int)((evt1 >> AIERT_CORE_EVT1_STREAM_STALL_BIT) & 1u);
    int cascade_stall = (int)((evt1 >> AIERT_CORE_EVT1_CASCADE_STALL_BIT) & 1u);
    int lock_stall = (int)((evt1 >> AIERT_CORE_EVT1_LOCK_STALL_BIT) & 1u);
    int ecc_err_stall = (int)((evt1 >> AIERT_CORE_EVT1_ECC_ERR_STALL_BIT) & 1u);
    int ecc_scrub = (int)((evt1 >> AIERT_CORE_EVT1_ECC_SCRUB_STALL_BIT) & 1u);
    int stall_nop = (int)((evt1 >> AIERT_CORE_EVT1_STALL_NOP_BIT) & 1u);

    printf("[AieRt_Debug] Core tile(%u,%u) core_evt_status0(0x%llX)=0x%08X  core_evt_status1(0x%llX)=0x%08X\n",
           (unsigned)tile.Col, (unsigned)tile.Row, (unsigned long long)reg0_off, (unsigned)evt0,
           (unsigned long long)reg1_off, (unsigned)evt1);

    /* Activity state */
    printf("  ACTIVE          : %s\n", active ? "YES" : "no");
    printf("  DISABLED        : %s\n", disabled ? "YES" : "no");

    /* Stall events */
    printf("  MS_STALL        : %s\n", ms_stall ? "*** STALL ***" : "no");
    printf("  PM_STALL(instr) : %s\n", pm_stall ? "*** STALL ***" : "no");
    printf("  STREAM_STALL    : %s\n", stream_stall ? "*** STALL ***" : "no");
    printf("  CASCADE_STALL   : %s\n", cascade_stall ? "*** STALL ***" : "no");
    printf("  LOCK_STALL      : %s\n", lock_stall ? "*** STALL ***" : "no");
    printf("  ECC_ERR_STALL   : %s\n", ecc_err_stall ? "*** STALL ***" : "no");
    printf("  ECC_SCRUB_STALL : %s\n", ecc_scrub ? "*** STALL ***" : "no");
    printf("  STALL_NOP       : %s\n", stall_nop ? "YES" : "no");

    /* Summary warnings */
    if (disabled)
        printf("  *** WARN: core is DISABLED\n");
    if (ms_stall || pm_stall || stream_stall || cascade_stall || lock_stall || ecc_err_stall || ecc_scrub)
        printf("  *** WARN: core has active stall(s) - check stall lines above\n");
    if (pm_stall)
        printf("  *** WARN: PM_STALL - core stalled on instruction load (instr fetch)\n");
}

void AieRt_PrintCoreActivityEventsAll(XAie_DevInst *dev, const XAie_LocType *tiles, uint32_t num_tiles) {
    printf("[AieRt_Debug] ===== Core Activity Events (%u tiles) =====\n", (unsigned)num_tiles);
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (s_is_core(tiles[i]))
            AieRt_PrintCoreActivityEvents(dev, tiles[i]);
    }
}

/* --------------------------------------------------------------------------
 * Core tile DMA BD event analysis
 *
 * The core tile Memory Module event status register 0 at tile-relative offset
 * 0x00014200 holds sticky bits for hardware-local event IDs 0-31.
 * (Full address: 0x20000000000 + (col<<25) + (row<<20) + 0x00014200)
 *
 * From debug.md: DMA_S2MM_0_START_TASK = local event 19 = bit 19.
 * Consecutive layout for all four DMA channels:
 *   bit 19  DMA_S2MM_0_START_TASK       bit 23  DMA_S2MM_0_FINISHED_TASK
 *   bit 20  DMA_S2MM_1_START_TASK       bit 24  DMA_S2MM_1_FINISHED_TASK
 *   bit 21  DMA_MM2S_0_START_TASK       bit 25  DMA_MM2S_0_FINISHED_TASK
 *   bit 22  DMA_MM2S_1_START_TASK       bit 26  DMA_MM2S_1_FINISHED_TASK
 *
 * A channel that has a START bit set but no FINISH bit indicates a stall or
 * incomplete transfer at the moment the snapshot was taken.
 * -------------------------------------------------------------------------- */

void AieRt_PrintCoreTileDmaBdEvents(XAie_DevInst *dev, XAie_LocType tile) {
    if (!s_is_core(tile)) {
        printf("[AieRt_Debug] tile(%u,%u): not a core tile, skip BD events\n", (unsigned)tile.Col, (unsigned)tile.Row);
        return;
    }

    /* Read memory module event status register directly */
    u64 reg_off = ((u64)tile.Col << 25) | ((u64)tile.Row << 20) | AIERT_CORE_MEM_EVT_STATUS_REG;
    u32 evt = 0;
    AieRC rc_ev = XAie_Read32(dev, reg_off, &evt);
    if (rc_ev != XAIE_OK) {
        printf("[AieRt_Debug] tile(%u,%u): failed to read mem_evt_status rc=%d\n", (unsigned)tile.Col,
               (unsigned)tile.Row, (int)rc_ev);
        return;
    }

    int s2mm0_start = (int)((evt >> AIERT_EVT_DMA_S2MM_0_START_BIT) & 1u);
    int s2mm1_start = (int)((evt >> AIERT_EVT_DMA_S2MM_1_START_BIT) & 1u);
    int mm2s0_start = (int)((evt >> AIERT_EVT_DMA_MM2S_0_START_BIT) & 1u);
    int mm2s1_start = (int)((evt >> AIERT_EVT_DMA_MM2S_1_START_BIT) & 1u);
    int s2mm0_finish = (int)((evt >> AIERT_EVT_DMA_S2MM_0_FINISH_BIT) & 1u);
    int s2mm1_finish = (int)((evt >> AIERT_EVT_DMA_S2MM_1_FINISH_BIT) & 1u);
    int mm2s0_finish = (int)((evt >> AIERT_EVT_DMA_MM2S_0_FINISH_BIT) & 1u);
    int mm2s1_finish = (int)((evt >> AIERT_EVT_DMA_MM2S_1_FINISH_BIT) & 1u);

    printf("[AieRt_Debug] Core tile(%u,%u) DMA BD events  mem_evt_status(0x%08X)=0x%08X\n", (unsigned)tile.Col,
           (unsigned)tile.Row, reg_off, (unsigned)evt);

    /* START events */
    printf("  S2MM ch0  START_TASK   : %s\n", s2mm0_start ? "FIRED" : "-");
    printf("  S2MM ch1  START_TASK   : %s\n", s2mm1_start ? "FIRED" : "-");
    printf("  MM2S ch0  START_TASK   : %s\n", mm2s0_start ? "FIRED" : "-");
    printf("  MM2S ch1  START_TASK   : %s\n", mm2s1_start ? "FIRED" : "-");

    /* FINISHED events */
    printf("  S2MM ch0  FINISHED_TASK: %s\n", s2mm0_finish ? "FIRED" : "-");
    printf("  S2MM ch1  FINISHED_TASK: %s\n", s2mm1_finish ? "FIRED" : "-");
    printf("  MM2S ch0  FINISHED_TASK: %s\n", mm2s0_finish ? "FIRED" : "-");
    printf("  MM2S ch1  FINISHED_TASK: %s\n", mm2s1_finish ? "FIRED" : "-");

    /* Stall diagnosis: started but never finished */
    if (s2mm0_start && !s2mm0_finish)
        printf("  *** WARN: S2MM ch0 started but not finished (stall or in-flight?)\n");
    if (s2mm1_start && !s2mm1_finish)
        printf("  *** WARN: S2MM ch1 started but not finished (stall or in-flight?)\n");
    if (mm2s0_start && !mm2s0_finish)
        printf("  *** WARN: MM2S ch0 started but not finished (stall or in-flight?)\n");
    if (mm2s1_start && !mm2s1_finish)
        printf("  *** WARN: MM2S ch1 started but not finished (stall or in-flight?)\n");

    if (!s2mm0_start && !s2mm1_start && !mm2s0_start && !mm2s1_start)
        printf("  (no DMA activity recorded in this tile)\n");
}

void AieRt_PrintCoreTileDmaBdEventsAll(XAie_DevInst *dev, const XAie_LocType *tiles, uint32_t num_tiles) {
    printf("[AieRt_Debug] ===== Core Tile DMA BD Events (%u tiles) =====\n", (unsigned)num_tiles);
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (s_is_core(tiles[i]))
            AieRt_PrintCoreTileDmaBdEvents(dev, tiles[i]);
    }
}

/* --------------------------------------------------------------------------
 * DMA BD info
 * -------------------------------------------------------------------------- */

void AieRt_PrintBdInfo(XAie_DevInst *dev, XAie_LocType tile, uint8_t bd_id) {
    XAie_DmaDesc desc;
    memset(&desc, 0, sizeof(desc));

    AieRC rc = XAie_DmaReadBd(dev, &desc, tile, (u16)bd_id);
    if (rc != XAIE_OK) {
        printf("[AieRt_Debug]   BD%-2u: read failed rc=%d\n", (unsigned)bd_id, (int)rc);
        return;
    }

    /* Extract fields from the descriptor struct.
     * XAie_DmaDesc has a union inside (AieMLDma or AieDma); we access
     * the generic fields that are present in both via the AddrDesc. */
    u64 addr = desc.AddrDesc.Address;
    u32 len = desc.AddrDesc.Length; /* bytes */

    /* Lock fields */
    int acq_lock_id = (int)desc.LockDesc.LockAcqId;
    int acq_lock_val = (int)desc.LockDesc.LockAcqVal;
    int rel_lock_id = (int)desc.LockDesc.LockRelId;
    int rel_lock_val = (int)desc.LockDesc.LockRelVal;
    int acq_en = (int)desc.LockDesc.LockAcqEn;
    int rel_en = (int)desc.LockDesc.LockRelEn;

    /* Next BD */
    int next_bd_en = (int)desc.BdEnDesc.UseNxtBd;
    int next_bd_id = (int)desc.BdEnDesc.NxtBd;

    /* Packet */
    int pkt_en = (int)desc.PktDesc.PktEn;
    int pkt_id = (int)desc.PktDesc.PktId;

    printf("[AieRt_Debug]   BD%-2u: addr=0x%llx len=%u bytes", (unsigned)bd_id, (unsigned long long)addr,
           (unsigned)len);

    if (next_bd_en)
        printf("  next->BD%u", (unsigned)next_bd_id);
    else
        printf("  next=(none)");

    if (pkt_en)
        printf("  pkt_id=%u", (unsigned)pkt_id);

    printf("\n");
    printf("         lock acq: en=%d id=%d val=%d  rel: en=%d id=%d val=%d\n", acq_en, acq_lock_id, acq_lock_val,
           rel_en, rel_lock_id, rel_lock_val);

    /* Multi-dimensional addressing: stride/wrap for D0-D3 and iteration
     * XAie_DmaReadBd populates desc.MultiDimDesc from hardware registers.
     * Access via AieMlMultiDimDesc for AIEML/AIE2 devices. */
    {
        XAie_AieMlMultiDimDesc *md = &desc.MultiDimDesc.AieMlMultiDimDesc;
        int has_dim = 0;
        for (int d = 0; d < 4; d++) {
            if (md->DimDesc[d].StepSize != 0 || md->DimDesc[d].Wrap != 0)
                has_dim = 1;
        }
        if (md->IterDesc.StepSize != 0 || md->IterDesc.Wrap != 0)
            has_dim = 1;

        if (has_dim) {
            printf("         dims:");
            for (int d = 0; d < 4; d++) {
                if (md->DimDesc[d].StepSize != 0 || md->DimDesc[d].Wrap != 0)
                    printf("  D%d(step=%u,wrap=%u)", d, (unsigned)md->DimDesc[d].StepSize,
                           (unsigned)md->DimDesc[d].Wrap);
            }
            if (md->IterDesc.StepSize != 0 || md->IterDesc.Wrap != 0)
                printf("  Iter(step=%u,wrap=%u,curr=%u)", (unsigned)md->IterDesc.StepSize, (unsigned)md->IterDesc.Wrap,
                       (unsigned)md->IterCurr);
            printf("\n");
        }
    }
}

void AieRt_PrintAllBds(XAie_DevInst *dev, XAie_LocType tile) {
    u8 num_bds = 0;
    AieRC rc = XAie_DmaGetNumBds(dev, tile, &num_bds);
    if (rc != XAIE_OK || num_bds == 0) {
        printf("[AieRt_Debug] tile(%u,%u): cannot determine BD count (rc=%d)\n", (unsigned)tile.Col, (unsigned)tile.Row,
               (int)rc);
        return;
    }
    printf("[AieRt_Debug] tile(%u,%u) BDs (total=%u, printing configured only):\n", (unsigned)tile.Col,
           (unsigned)tile.Row, (unsigned)num_bds);
    int printed = 0;
    for (u8 i = 0; i < num_bds; i++) {
        /* Quick check: read the BD via API; skip if addr and len are both zero */
        XAie_DmaDesc desc;
        memset(&desc, 0, sizeof(desc));
        AieRC rbd = XAie_DmaReadBd(dev, &desc, tile, (u16)i);
        if (rbd != XAIE_OK)
            continue;
        if (desc.AddrDesc.Address == 0 && desc.AddrDesc.Length == 0)
            continue;
        AieRt_PrintBdInfo(dev, tile, i);
        printed++;
    }
    if (printed == 0)
        printf("[AieRt_Debug]   (no configured BDs)\n");
}

/* --------------------------------------------------------------------------
 * Raw BD register dump for shim tiles
 *
 * Reads all 16 BD slots via XAie_Read32 at tile-relative offsets.
 * Decodes stride/wrap/iteration/lock/packet fields from raw register words.
 * -------------------------------------------------------------------------- */

void AieRt_PrintShimBdRawAll(XAie_DevInst *dev, uint8_t col) {
    printf("[AieRt_Debug] ===== Shim tile(%u,0) Raw BD Dump (16 BDs) =====\n", (unsigned)col);

    int printed = 0;
    for (uint32_t bd = 0; bd < AIERT_SHIM_BD_COUNT; bd++) {
        uint32_t base = AIERT_SHIM_BD_BASE + bd * AIERT_SHIM_BD_STRIDE;
        u32 w[AIERT_SHIM_BD_WORDS];

        /* Read all 8 words of this BD.
         * Shim tile address: (col << 25) | (row << 20) | reg_offset, row=0. */
        u64 tile_base = (u64)col << 25; /* shim row=0 */
        for (uint32_t wi = 0; wi < AIERT_SHIM_BD_WORDS; wi++) {
            AieRC rc = XAie_Read32(dev, tile_base | (u64)(base + wi * 4), &w[wi]);
            if (rc != XAIE_OK)
                w[wi] = 0;
        }

        /* Skip if Buffer_Length (word0) is zero — BD not configured */
        if (w[0] == 0)
            continue;

        /* Decode word 0: Buffer_Length */
        uint32_t buf_len = w[0];

        /* Decode word 1: Base_Address_Low */
        uint32_t addr_lo = w[1];

        /* Decode word 2: Base_Address_High[15:0], Packet_ID[28:24], Packet_Type[22:20] */
        uint32_t addr_hi = w[2] & 0xFFFFu;
        uint32_t pkt_id = (w[2] >> 24) & 0x1Fu;
        uint32_t pkt_type = (w[2] >> 20) & 0x7u;

        /* Decode word 3: D0_Stepsize[19:0], D0_Wrap[29:20] */
        uint32_t d0_step = w[3] & 0xFFFFFu;
        uint32_t d0_wrap = (w[3] >> 20) & 0x3FFu;

        /* Decode word 4: D1_Stepsize[19:0], D1_Wrap[29:20] */
        uint32_t d1_step = w[4] & 0xFFFFFu;
        uint32_t d1_wrap = (w[4] >> 20) & 0x3FFu;

        /* Decode word 5: D2_Stepsize[19:0], D2_Wrap[29:20] */
        uint32_t d2_step = w[5] & 0xFFFFFu;
        uint32_t d2_wrap = (w[5] >> 20) & 0x3FFu;

        /* Decode word 6: Iter_Stepsize[19:0], Iter_Wrap[25:20], Iter_Current[31:26] */
        uint32_t iter_step = w[6] & 0xFFFFFu;
        uint32_t iter_wrap = (w[6] >> 20) & 0x3Fu;
        uint32_t iter_curr = (w[6] >> 26) & 0x3Fu;

        /* Decode word 7: Valid[0], Next_BD[4:1], Use_Next[5],
         * Lock_Acq_Val[13:6], Lock_Acq_ID[17:14],
         * Lock_Rel_Val[25:18], Lock_Rel_ID[29:26],
         * Lock_Acq_En[30], Lock_Rel_En[31] */
        uint32_t valid = w[7] & 0x1u;
        uint32_t next_bd = (w[7] >> 1) & 0xFu;
        uint32_t use_next = (w[7] >> 5) & 0x1u;
        int32_t acq_val = (int32_t)((int8_t)((w[7] >> 6) & 0xFFu));
        uint32_t acq_id = (w[7] >> 14) & 0xFu;
        int32_t rel_val = (int32_t)((int8_t)((w[7] >> 18) & 0xFFu));
        uint32_t rel_id = (w[7] >> 26) & 0xFu;
        uint32_t acq_en = (w[7] >> 30) & 0x1u;
        uint32_t rel_en = (w[7] >> 31) & 0x1u;

        /* Print header with raw words */
        printf("[AieRt_Debug]   BD%-2u raw: [%08x %08x %08x %08x %08x %08x %08x %08x]\n", (unsigned)bd, w[0], w[1],
               w[2], w[3], w[4], w[5], w[6], w[7]);

        /* Print decoded fields */
        uint64_t full_addr = ((uint64_t)addr_hi << 32) | (uint64_t)addr_lo;
        printf("[AieRt_Debug]     addr=0x%llx len=%u valid=%u", (unsigned long long)full_addr, buf_len, valid);
        if (use_next)
            printf("  next->BD%u", next_bd);
        else
            printf("  next=(none)");
        if (pkt_id || pkt_type)
            printf("  pkt_id=%u pkt_type=%u", pkt_id, pkt_type);
        printf("\n");

        /* Print dimension strides/wraps */
        printf("[AieRt_Debug]     D0: step=%u wrap=%u  D1: step=%u wrap=%u  D2: step=%u wrap=%u\n", d0_step, d0_wrap,
               d1_step, d1_wrap, d2_step, d2_wrap);

        /* Print iteration */
        if (iter_step || iter_wrap || iter_curr)
            printf("[AieRt_Debug]     Iter: step=%u wrap=%u current=%u\n", iter_step, iter_wrap, iter_curr);

        /* Print lock */
        if (acq_en || rel_en)
            printf("[AieRt_Debug]     Lock: acq_en=%u id=%u val=%d  rel_en=%u id=%u val=%d\n", acq_en, acq_id, acq_val,
                   rel_en, rel_id, rel_val);

        printed++;
    }

    if (printed == 0)
        printf("[AieRt_Debug]   (no configured BDs — all Buffer_Length == 0)\n");

    printf("[AieRt_Debug] ===== End Shim tile(%u,0) Raw BD Dump =====\n", (unsigned)col);
}

/* --------------------------------------------------------------------------
 * DMA channel status
 * -------------------------------------------------------------------------- */

AieRt_DmaChStatusDecoded AieRt_DecodeDmaChStatus(uint32_t raw) {
    AieRt_DmaChStatusDecoded d;
    memset(&d, 0, sizeof(d));
    d.raw = raw;
    d.status = (uint8_t)((raw & AIERT_DMA_STATUS_MASK));
    d.stall_lock_acq = (raw & AIERT_DMA_STALL_LOCK_ACQ_MASK) ? 1u : 0u;
    d.stall_lock_rel = (raw & AIERT_DMA_STALL_LOCK_REL_MASK) ? 1u : 0u;
    d.stall_stream = (raw & AIERT_DMA_STALL_STREAM_MASK) ? 1u : 0u;
    d.stall_tct = (raw & AIERT_DMA_STALL_TCT_MASK) ? 1u : 0u;
    d.err_bd_unavail = (raw & AIERT_DMA_ERR_BD_UNAVAIL_MASK) ? 1u : 0u;
    d.err_bd_invalid = (raw & AIERT_DMA_ERR_BD_INVALID_MASK) ? 1u : 0u;
    d.err_fot_len = (raw & AIERT_DMA_ERR_FOT_LEN_MASK) ? 1u : 0u;
    d.err_fot_bds = (raw & AIERT_DMA_ERR_FOT_BDS_MASK) ? 1u : 0u;
    d.err_axi_decode = (raw & AIERT_DMA_ERR_AXI_DECODE_MASK) ? 1u : 0u;
    d.err_axi_slave = (raw & AIERT_DMA_ERR_AXI_SLAVE_MASK) ? 1u : 0u;
    d.task_q_overflow = (raw & AIERT_DMA_TASK_Q_OVERFLOW_MASK) ? 1u : 0u;
    d.channel_running = (raw & AIERT_DMA_CHANNEL_RUNNING_MASK) ? 1u : 0u;
    d.task_q_size = (uint8_t)((raw & AIERT_DMA_TASK_Q_SIZE_MASK) >> AIERT_DMA_TASK_Q_SIZE_LSB);
    d.cur_bd = (uint8_t)((raw & AIERT_DMA_CUR_BD_MASK) >> AIERT_DMA_CUR_BD_LSB);
    return d;
}

void AieRt_PrintDmaChStatus(XAie_DevInst *dev, XAie_LocType tile, uint8_t ch, XAie_DmaDirection dir) {
    u32 raw = 0;
    AieRC rc = XAie_DmaGetChannelStatus(dev, tile, ch, dir, &raw);
    if (rc != XAIE_OK) {
        printf("[AieRt_Debug]   tile(%u,%u) ch%u %s: GetChannelStatus failed rc=%d\n", (unsigned)tile.Col,
               (unsigned)tile.Row, (unsigned)ch, s_dir_str(dir), (int)rc);
        return;
    }

    AieRt_DmaChStatusDecoded d = AieRt_DecodeDmaChStatus(raw);

    printf("[AieRt_Debug]   tile(%u,%u) ch%u %s: raw=0x%08X  %s  running=%d  q_size=%u  cur_bd=%u\n",
           (unsigned)tile.Col, (unsigned)tile.Row, (unsigned)ch, s_dir_str(dir), (unsigned)raw, s_status_str(d.status),
           (int)d.channel_running, (unsigned)d.task_q_size, (unsigned)d.cur_bd);

    /* Report any stalls */
    if (d.stall_lock_acq || d.stall_lock_rel || d.stall_stream || d.stall_tct) {
        printf("             STALLED: lock_acq=%d lock_rel=%d stream=%d tct=%d\n", (int)d.stall_lock_acq,
               (int)d.stall_lock_rel, (int)d.stall_stream, (int)d.stall_tct);
    }

    /* Report any errors */
    if (d.err_bd_unavail || d.err_bd_invalid || d.err_fot_len || d.err_fot_bds || d.err_axi_decode || d.err_axi_slave ||
        d.task_q_overflow) {
        printf("             ERRORS: bd_unavail=%d bd_invalid=%d fot_len=%d fot_bds=%d "
               "axi_decode=%d axi_slave=%d q_overflow=%d\n",
               (int)d.err_bd_unavail, (int)d.err_bd_invalid, (int)d.err_fot_len, (int)d.err_fot_bds,
               (int)d.err_axi_decode, (int)d.err_axi_slave, (int)d.task_q_overflow);
    }

    /* If the channel is actively processing, show the current BD contents */
    if (d.channel_running || d.status == AIERT_DMA_STATUS_RUNNING) {
        printf("             Current BD contents:\n");
        AieRt_PrintBdInfo(dev, tile, d.cur_bd);
    }
}

void AieRt_PrintShimDmaStatus(XAie_DevInst *dev, uint8_t col) {
    XAie_LocType shim = XAie_TileLoc(col, XAIE_SHIM_ROW);
    printf("[AieRt_Debug] Shim tile(%u,0) DMA status:\n", (unsigned)col);
    AieRt_PrintDmaChStatus(dev, shim, 0, DMA_S2MM);
    AieRt_PrintDmaChStatus(dev, shim, 1, DMA_S2MM);
    AieRt_PrintDmaChStatus(dev, shim, 0, DMA_MM2S);
    AieRt_PrintDmaChStatus(dev, shim, 1, DMA_MM2S);
}

void AieRt_PrintShimPlModuleEvents(XAie_DevInst *dev, uint8_t col) {
    u64 base = (u64)col << 25; /* shim row=0 */
    u32 reg[4] = {0, 0, 0, 0};
    XAie_Read32(dev, base | AIERT_SHIM_PL_EVT_STATUS_REG0, &reg[0]);
    XAie_Read32(dev, base | AIERT_SHIM_PL_EVT_STATUS_REG1, &reg[1]);
    XAie_Read32(dev, base | AIERT_SHIM_PL_EVT_STATUS_REG2, &reg[2]);
    XAie_Read32(dev, base | AIERT_SHIM_PL_EVT_STATUS_REG3, &reg[3]);

    const char *gen_str = (g_aiert_gen == AIERT_GEN_AIE2PS) ? "AIE2PS" : "AIEML";
    printf("[AieRt_Debug] Shim(%u,0) PL module events [gen=%s]"
           "  reg0=0x%08X  reg1=0x%08X  reg2=0x%08X  reg3=0x%08X\n",
           (unsigned)col, gen_str, (unsigned)reg[0], (unsigned)reg[1], (unsigned)reg[2], (unsigned)reg[3]);

    int any = 0;
    for (uint32_t r = 0; r < 4u; r++) {
        for (int bit = 0; bit < 32; bit++) {
            if (!((reg[r] >> bit) & 1u))
                continue;
            uint32_t id = r * 32u + (uint32_t)bit;
            if (id > AIERT_PL_EVT_MAX)
                continue;
            const char *name = AieRt_EventName(XAIE_PL_MOD, id);
            /* Flag ranges per aie2psevent.md §4 hardware register bit layout:
             *   DMA activity   : IDs 14-33
             *   Stalled lock   : IDs 22-25  (subset of DMA, more severe)
             *   Stream stall   : IDs 26-29  (starvation/backpressure)
             *   SS_STALL/OVERFLOW: IDs 52-60
             */
            const char *flag = "";
            if (id >= 14u && id <= 33u)
                flag = " [DMA]";
            if (id >= 22u && id <= 25u)
                flag = " *** DMA STALLED_LOCK ***";
            if (id >= 26u && id <= 27u)
                flag = " *** S2MM STREAM STARVATION ***";
            if (id >= 28u && id <= 29u)
                flag = " *** MM2S STREAM BACKPRESSURE ***";
            if (id >= 52u && id <= 60u)
                flag = " *** SS_STALL ***";
            printf("  PL evt %3u  %s%s\n", (unsigned)id, name, flag);
            any = 1;
        }
    }
    if (!any)
        printf("  (no PL module events set)\n");
}

void AieRt_PrintCoreTileDmaStatus(XAie_DevInst *dev, XAie_LocType tile) {
    if (!s_is_core(tile)) {
        printf("[AieRt_Debug] tile(%u,%u) is not a core tile\n", (unsigned)tile.Col, (unsigned)tile.Row);
        return;
    }
    printf("[AieRt_Debug] Core tile(%u,%u) DMA status:\n", (unsigned)tile.Col, (unsigned)tile.Row);
    AieRt_PrintDmaChStatus(dev, tile, 0, DMA_S2MM);
    AieRt_PrintDmaChStatus(dev, tile, 1, DMA_S2MM);
    AieRt_PrintDmaChStatus(dev, tile, 0, DMA_MM2S);
    AieRt_PrintDmaChStatus(dev, tile, 1, DMA_MM2S);
}

/* --------------------------------------------------------------------------
 * Verification
 * -------------------------------------------------------------------------- */

int AieRt_VerifyIoDescriptors(XAie_DevInst *dev, const struct_io *ios, uint32_t num_ios) {
    int fail_count = 0;

    printf("[AieRt_Debug] ===== IO Descriptor Verification (%u IOs) =====\n", (unsigned)num_ios);

    for (uint32_t i = 0; i < num_ios; i++) {
        const struct_io *io = &ios[i];
        u32 raw = 0;
        AieRC rc = XAie_DmaGetChannelStatus(dev, io->tile_loc, io->channel_id, io->direction, &raw);
        if (rc != XAIE_OK) {
            printf("[AieRt_Debug] IO[%u] tile(%u,%u) ch%u %s: GetChannelStatus FAILED rc=%d\n", (unsigned)i,
                   (unsigned)io->tile_loc.Col, (unsigned)io->tile_loc.Row, (unsigned)io->channel_id,
                   s_dir_str(io->direction), (int)rc);
            fail_count++;
            continue;
        }

        AieRt_DmaChStatusDecoded d = AieRt_DecodeDmaChStatus(raw);

        /* Error conditions: any error bit or stall that is not lock-acq transient */
        int has_error = (int)(d.err_bd_unavail | d.err_bd_invalid | d.err_fot_len | d.err_fot_bds | d.err_axi_decode |
                              d.err_axi_slave | d.task_q_overflow);
        int has_stall = (int)(d.stall_lock_acq | d.stall_lock_rel | d.stall_stream | d.stall_tct);

        /* A well-completed IO should be Idle or Running (task queue draining).
         * We flag it as FAIL only if there are hard errors. */
        int io_fail = has_error;

        printf("[AieRt_Debug] IO[%u] tile(%u,%u) ch%u %s bd_id=%u: status=%s running=%d q=%u cur_bd=%u  => %s\n",
               (unsigned)i, (unsigned)io->tile_loc.Col, (unsigned)io->tile_loc.Row, (unsigned)io->channel_id,
               s_dir_str(io->direction), (unsigned)io->bd_id, s_status_str(d.status), (int)d.channel_running,
               (unsigned)d.task_q_size, (unsigned)d.cur_bd, io_fail ? "FAIL" : (has_stall ? "WARN-stall" : "OK"));

        if (has_error) {
            printf("  ERRORS: bd_unavail=%d bd_invalid=%d fot_len=%d fot_bds=%d "
                   "axi_decode=%d axi_slave=%d q_overflow=%d\n",
                   (int)d.err_bd_unavail, (int)d.err_bd_invalid, (int)d.err_fot_len, (int)d.err_fot_bds,
                   (int)d.err_axi_decode, (int)d.err_axi_slave, (int)d.task_q_overflow);
            fail_count++;
        }
        if (has_stall) {
            printf("  STALLS: lock_acq=%d lock_rel=%d stream=%d tct=%d\n", (int)d.stall_lock_acq, (int)d.stall_lock_rel,
                   (int)d.stall_stream, (int)d.stall_tct);
        }

        /* Print the BD that was registered for this IO */
        printf("  Registered BD contents (bd_id=%u):\n", (unsigned)io->bd_id);
        AieRt_PrintBdInfo(dev, io->tile_loc, io->bd_id);

        /* If channel is running, also print the BD currently being processed */
        if (d.channel_running && d.cur_bd != io->bd_id) {
            printf("  Current BD in flight (cur_bd=%u):\n", (unsigned)d.cur_bd);
            AieRt_PrintBdInfo(dev, io->tile_loc, d.cur_bd);
        }
    }

    printf("[AieRt_Debug] ===== Verification result: %d / %u FAILED =====\n", fail_count, (unsigned)num_ios);
    return fail_count;
}

/* --------------------------------------------------------------------------
 * Full debug snapshot
 * -------------------------------------------------------------------------- */

void AieRt_DebugSnapshot(XAie_DevInst *dev, const struct_io *ios, uint32_t num_ios, const XAie_LocType *tiles,
                         uint32_t num_tiles) {
    const char *gen_str = (g_aiert_gen == AIERT_GEN_AIE2PS) ? "AIE2PS" : "AIEML";
    printf("\n[AieRt_Debug] ============================================================\n");
    printf("[AieRt_Debug]  DEBUG SNAPSHOT  [gen=%s]\n", gen_str);
    printf("[AieRt_Debug] ============================================================\n");

    /* 1. Core status */
    AieRt_PrintCoreStatusAll(dev, tiles, num_tiles);

    /* 2. Stream switch configuration (JSON) — most useful for routing debug */
    {
        XAie_LocType ss_tiles[512];
        uint32_t ss_count = 0;

        /* Collect all known tiles (core + shim) to determine column/row span */
        uint8_t min_col = 0xFF, max_col = 0;
        uint8_t max_row = 0;

        for (uint32_t i = 0; i < num_tiles; i++) {
            if (tiles[i].Col < min_col)
                min_col = tiles[i].Col;
            if (tiles[i].Col > max_col)
                max_col = tiles[i].Col;
            if (tiles[i].Row > max_row)
                max_row = tiles[i].Row;
        }
        for (uint32_t i = 0; i < num_ios; i++) {
            if (ios[i].tile_loc.Col < min_col)
                min_col = ios[i].tile_loc.Col;
            if (ios[i].tile_loc.Col > max_col)
                max_col = ios[i].tile_loc.Col;
            if (ios[i].tile_loc.Row > max_row)
                max_row = ios[i].tile_loc.Row;
        }
        if (min_col > max_col) {
            min_col = 0;
            max_col = 0;
        }

        /* Scan the full column×row rectangle so that pass-through routing
         * tiles (e.g. shim col 6 → mem-tile rows 1-2 → core row 3) are
         * included.  print_all=0 means tiles with no active ports produce
         * empty JSON and are harmlessly skipped by the visualiser.           */
        for (uint8_t col = min_col; col <= max_col && ss_count < 512; col++) {
            for (uint8_t row = 0; row <= max_row && ss_count < 512; row++) {
                ss_tiles[ss_count++] = XAie_TileLoc(col, row);
            }
        }

        if (AIE_DEBUG_LEVEL(g_runtime_debug_level) >= 1)
            AieRt_PrintStreamSwitchConfigAll(dev, ss_tiles, ss_count, /*print_all=*/0);
    }

    /* 3. Core module activity / stall event analysis (ACTIVE, DISABLED, stalls) */
    AieRt_PrintCoreActivityEventsAll(dev, tiles, num_tiles);

    /* 4. Core tile DMA BD start/finish event analysis */
    AieRt_PrintCoreTileDmaBdEventsAll(dev, tiles, num_tiles);

    /* 5. MEM module event status — all set event bits with names */
    AieRt_PrintMemModuleEventsAll(dev, tiles, num_tiles);

    /* 6. CORE module event status — all set event bits with names */
    AieRt_PrintCoreModuleEventsAll(dev, tiles, num_tiles);

    /* 7. Shim DMA status — collect unique shim columns from ios */
    printf("[AieRt_Debug] ===== Shim DMA Status =====\n");
    {
        uint8_t seen_cols[64];
        uint32_t seen_count = 0;
        for (uint32_t i = 0; i < num_ios; i++) {
            if (!s_is_shim(ios[i].tile_loc))
                continue;
            uint8_t col = ios[i].tile_loc.Col;
            int already = 0;
            for (uint32_t j = 0; j < seen_count; j++) {
                if (seen_cols[j] == col) {
                    already = 1;
                    break;
                }
            }
            if (!already && seen_count < 64) {
                seen_cols[seen_count++] = col;
                AieRt_PrintShimDmaStatus(dev, col);
                AieRt_PrintShimPlModuleEvents(dev, col);
            }
        }
        if (seen_count == 0)
            printf("[AieRt_Debug]  (no shim tiles in ios list)\n");
    }

    /* 8. Core tile DMA status */
    printf("[AieRt_Debug] ===== Core Tile DMA Status =====\n");
    for (uint32_t i = 0; i < num_tiles; i++) {
        if (s_is_core(tiles[i]))
            AieRt_PrintCoreTileDmaStatus(dev, tiles[i]);
    }

    /* 9. BD contents for all referenced tiles */
    printf("[AieRt_Debug] ===== BD Contents (all referenced tiles) =====\n");
    {
        /* Unique tile list derived from ios + tiles */
        XAie_LocType seen[128];
        uint32_t seen_count = 0;

        /* From ios */
        for (uint32_t i = 0; i < num_ios; i++) {
            XAie_LocType t = ios[i].tile_loc;
            int found = 0;
            for (uint32_t j = 0; j < seen_count; j++) {
                if (seen[j].Col == t.Col && seen[j].Row == t.Row) {
                    found = 1;
                    break;
                }
            }
            if (!found && seen_count < 128)
                seen[seen_count++] = t;
        }
        /* From tiles (core tiles) */
        for (uint32_t i = 0; i < num_tiles; i++) {
            XAie_LocType t = tiles[i];
            int found = 0;
            for (uint32_t j = 0; j < seen_count; j++) {
                if (seen[j].Col == t.Col && seen[j].Row == t.Row) {
                    found = 1;
                    break;
                }
            }
            if (!found && seen_count < 128)
                seen[seen_count++] = t;
        }
        for (uint32_t i = 0; i < seen_count; i++)
            AieRt_PrintAllBds(dev, seen[i]);
    }

    /* 10. Raw BD register dump for shim tiles (shows stride/wrap/iteration) */
    printf("[AieRt_Debug] ===== Shim Raw BD Registers (stride/wrap) =====\n");
    {
        uint8_t shim_seen[64];
        uint32_t shim_seen_count = 0;
        for (uint32_t i = 0; i < num_ios; i++) {
            if (!s_is_shim(ios[i].tile_loc))
                continue;
            uint8_t col = ios[i].tile_loc.Col;
            int already = 0;
            for (uint32_t j = 0; j < shim_seen_count; j++) {
                if (shim_seen[j] == col) {
                    already = 1;
                    break;
                }
            }
            if (!already && shim_seen_count < 64) {
                shim_seen[shim_seen_count++] = col;
                AieRt_PrintShimBdRawAll(dev, col);
            }
        }
        if (shim_seen_count == 0)
            printf("[AieRt_Debug]  (no shim tiles in ios list)\n");
    }

    /* 11. IO verification */
    AieRt_VerifyIoDescriptors(dev, ios, num_ios);

    printf("[AieRt_Debug] ============================================================\n\n");
}

/* --------------------------------------------------------------------------
 * Stream switch register debug
 *
 * Reads stream switch master config, slave config, and slave slot registers
 * directly via XAie_Read32, using tile-relative offsets from xaiemlgbl_params.h.
 *
 * Port name tables and counts are sourced directly from xaie2psgbl_params.h.
 * Each tile type has a completely independent port ordering — never mix them.
 *
 * Core tile (CORE_MODULE), base 0x0003F000 / 0x0003F100:
 *   Master[0..22]: CORE0, DMA0-1, CTRL, FIFO0, SOUTH0-3, WEST0-3, NORTH0-5, EAST0-3
 *   Slave[0..24]:  CORE0, DMA0-1, CTRL, FIFO0, SOUTH0-5, WEST0-3, NORTH0-3, EAST0-3,
 *                  AIE_TRACE, MEM_TRACE
 *
 * Shim tile (PL_MODULE), base 0x0003F000 / 0x0003F100:
 *   Master[0..22]: CTRL, FIFO0, SOUTH0-5, WEST0-3, NORTH0-5, EAST0-3, UCONTROLLER
 *   Slave[0..23]:  CTRL, FIFO0, SOUTH0-7, WEST0-3, NORTH0-3, EAST0-3, TRACE, UCONTROLLER
 *
 * MemTile (MEM_TILE_MODULE), base 0x000B0000 / 0x000B0100:
 *   Master[0..16]: DMA0-5, CTRL, SOUTH0-3, NORTH0-5
 *   Slave[0..17]:  DMA0-5, CTRL, SOUTH0-5, NORTH0-3, TRACE
 * -------------------------------------------------------------------------- */

/* --------------------------------------------------------------------------
 * Stream switch port name tables
 *
 * All entries sourced from xaie2psgbl_params.h, listed in register address
 * order (ascending).  Each entry corresponds to one 4-byte register slot.
 * Index 0 = base address, index N = base + N*4.
 * -------------------------------------------------------------------------- */

/* Core tile (CORE_MODULE) master ports — 23 total, base 0x0003F000
 *   XAIE2PSGBL_CORE_MODULE_STREAM_SWITCH_MASTER_CONFIG_AIE_CORE0 = 0x0003F000
 *   ...
 *   XAIE2PSGBL_CORE_MODULE_STREAM_SWITCH_MASTER_CONFIG_EAST3     = 0x0003F058
 */
static const char *s_core_master_names[] = {
    "CORE0",                                                    /* 0:  0x3F000 */
    "DMA0",   "DMA1",                                           /* 1-2: 0x3F004,08 */
    "CTRL",   "FIFO0",                                          /* 3-4: 0x3F00C,10 */
    "SOUTH0", "SOUTH1", "SOUTH2", "SOUTH3",                     /* 5-8: 0x3F014-20 */
    "WEST0",  "WEST1",  "WEST2",  "WEST3",                      /* 9-12: 0x3F024-30 */
    "NORTH0", "NORTH1", "NORTH2", "NORTH3", "NORTH4", "NORTH5", /* 13-18: 0x3F034-48 */
    "EAST0",  "EAST1",  "EAST2",  "EAST3"                       /* 19-22: 0x3F04C-58 */
};
#define AIERT_SS_CORE_MASTER_ACTUAL 23u

/* Core tile (CORE_MODULE) slave ports — 25 total, base 0x0003F100
 *   XAIE2PSGBL_CORE_MODULE_STREAM_SWITCH_SLAVE_CONFIG_AIE_CORE0  = 0x0003F100
 *   ...
 *   XAIE2PSGBL_CORE_MODULE_STREAM_SWITCH_SLAVE_CONFIG_MEM_TRACE  = 0x0003F160
 */
static const char *s_core_slave_names[] = {
    "CORE0",                                                         /* 0:  0x3F100 */
    "DMA0",      "DMA1",                                             /* 1-2: 0x3F104,08 */
    "CTRL",      "FIFO0",                                            /* 3-4: 0x3F10C,10 */
    "SOUTH0",    "SOUTH1",   "SOUTH2", "SOUTH3", "SOUTH4", "SOUTH5", /* 5-10: 0x3F114-28 */
    "WEST0",     "WEST1",    "WEST2",  "WEST3",                      /* 11-14: 0x3F12C-38 */
    "NORTH0",    "NORTH1",   "NORTH2", "NORTH3",                     /* 15-18: 0x3F13C-48 */
    "EAST0",     "EAST1",    "EAST2",  "EAST3",                      /* 19-22: 0x3F14C-58 */
    "AIE_TRACE", "MEM_TRACE"                                         /* 23-24: 0x3F15C,60 */
};
#define AIERT_SS_CORE_SLAVE_ACTUAL 25u

/* --------------------------------------------------------------------------
 * Shim tile (PL_MODULE) stream switch port names
 *
 * DIFFERENT from core tile: no AIE_CORE/DMA on master side; has UCONTROLLER;
 * SOUTH has 6 master outputs but 8 slave inputs (PL interface width).
 *
 * Master ports — 23 total, base 0x0003F000
 *   XAIE2PSGBL_PL_MODULE_STREAM_SWITCH_MASTER_CONFIG_TILE_CTRL   = 0x0003F000
 *   ...
 *   XAIE2PSGBL_PL_MODULE_STREAM_SWITCH_MASTER_CONFIG_UCONTROLLER = 0x0003F058
 *
 * Slave ports — 24 total, base 0x0003F100
 *   XAIE2PSGBL_PL_MODULE_STREAM_SWITCH_SLAVE_CONFIG_TILE_CTRL    = 0x0003F100
 *   ...
 *   XAIE2PSGBL_PL_MODULE_STREAM_SWITCH_SLAVE_CONFIG_UCONTROLLER  = 0x0003F15C
 * -------------------------------------------------------------------------- */

static const char *s_shim_master_names[] = {
    "CTRL",                                                         /* 0:  0x3F000 */
    "FIFO0",                                                        /* 1:  0x3F004 */
    "SOUTH0",     "SOUTH1", "SOUTH2", "SOUTH3", "SOUTH4", "SOUTH5", /* 2-7: 0x3F008-1C */
    "WEST0",      "WEST1",  "WEST2",  "WEST3",                      /* 8-11: 0x3F020-2C */
    "NORTH0",     "NORTH1", "NORTH2", "NORTH3", "NORTH4", "NORTH5", /* 12-17: 0x3F030-44 */
    "EAST0",      "EAST1",  "EAST2",  "EAST3",                      /* 18-21: 0x3F048-54 */
    "UCONTROLLER"                                                   /* 22: 0x3F058 */
};
#define AIERT_SS_SHIM_MASTER_ACTUAL 23u

static const char *s_shim_slave_names[] = {
    "CTRL",                                                                             /* 0:  0x3F100 */
    "FIFO0",                                                                            /* 1:  0x3F104 */
    "SOUTH0",     "SOUTH1", "SOUTH2", "SOUTH3", "SOUTH4", "SOUTH5", "SOUTH6", "SOUTH7", /* 2-9: 0x3F108-24 */
    "WEST0",      "WEST1",  "WEST2",  "WEST3",                                          /* 10-13: 0x3F128-34 */
    "NORTH0",     "NORTH1", "NORTH2", "NORTH3",                                         /* 14-17: 0x3F138-44 */
    "EAST0",      "EAST1",  "EAST2",  "EAST3",                                          /* 18-21: 0x3F148-54 */
    "TRACE",                                                                            /* 22: 0x3F158 */
    "UCONTROLLER"                                                                       /* 23: 0x3F15C */
};
#define AIERT_SS_SHIM_SLAVE_ACTUAL 24u

/* --------------------------------------------------------------------------
 * MemTile (MEM_TILE_MODULE) stream switch port names
 *
 * DIFFERENT from core and shim: no AIE_CORE, no FIFO, no EAST, no WEST;
 * only DMA, CTRL, SOUTH, NORTH connections.
 * SOUTH has 4 master outputs but 6 slave inputs.
 * NORTH has 6 master outputs but 4 slave inputs.
 * Register base is 0x000B0000 (completely separate from core/shim 0x3F000).
 *
 * Master ports — 17 total, base 0x000B0000
 *   XAIE2PSGBL_MEM_TILE_MODULE_STREAM_SWITCH_MASTER_CONFIG_DMA0   = 0x000B0000
 *   ...
 *   XAIE2PSGBL_MEM_TILE_MODULE_STREAM_SWITCH_MASTER_CONFIG_NORTH5 = 0x000B0040
 *
 * Slave ports — 18 total, base 0x000B0100
 *   XAIE2PSGBL_MEM_TILE_MODULE_STREAM_SWITCH_SLAVE_CONFIG_DMA_0   = 0x000B0100
 *   ...
 *   XAIE2PSGBL_MEM_TILE_MODULE_STREAM_SWITCH_SLAVE_CONFIG_TRACE   = 0x000B0144
 * -------------------------------------------------------------------------- */

static const char *s_memtile_master_names[] = {
    "DMA0",   "DMA1",   "DMA2",   "DMA3",   "DMA4",   "DMA5",  /* 0-5:  0xB0000-14 */
    "CTRL",                                                    /* 6:    0xB0018 */
    "SOUTH0", "SOUTH1", "SOUTH2", "SOUTH3",                    /* 7-10: 0xB001C-28 */
    "NORTH0", "NORTH1", "NORTH2", "NORTH3", "NORTH4", "NORTH5" /* 11-16: 0xB002C-40 */
};
#define AIERT_SS_MEMTILE_MASTER_ACTUAL 17u

static const char *s_memtile_slave_names[] = {
    "DMA0",   "DMA1",   "DMA2",   "DMA3",   "DMA4",   "DMA5",   /* 0-5:  0xB0100-14 */
    "CTRL",                                                     /* 6:    0xB0118 */
    "SOUTH0", "SOUTH1", "SOUTH2", "SOUTH3", "SOUTH4", "SOUTH5", /* 7-12: 0xB011C-30 */
    "NORTH0", "NORTH1", "NORTH2", "NORTH3",                     /* 13-16: 0xB0134-40 */
    "TRACE"                                                     /* 17:   0xB0144 */
};
#define AIERT_SS_MEMTILE_SLAVE_ACTUAL 18u

/* Classify a port name into switch type:
 *   "PKT"  — packet-switched port (DMA, CORE, NORTH/SOUTH/EAST/WEST carrying data streams)
 *   "CIRC" — circuit-switched port (same port names but pkt_en=0 on master side)
 *   "CTRL" — control/management port (CTRL, FIFO0, TRACE)
 * For master ports: caller supplies pkt_en from the register.
 * For slave ports: type derived from port name only (no pkt_en bit on slave side).
 */
static const char *s_ss_port_type(const char *name, int pkt_en) {
    /* Control/special ports — never carry DMA data */
    if (strncmp(name, "CTRL", 4) == 0 || strncmp(name, "FIFO", 4) == 0 || strncmp(name, "TRACE", 5) == 0 ||
        strncmp(name, "AIE_TRACE", 9) == 0 || strncmp(name, "MEM_TRACE", 9) == 0)
        return "CTRL";
    /* For master ports, the PACKET_ENABLE bit is definitive */
    if (pkt_en >= 0)
        return pkt_en ? "PKT" : "CIRC";
    /* Slave port — infer from name: DMA/CORE are always packet-switched sources */
    if (strncmp(name, "DMA", 3) == 0 || strncmp(name, "CORE", 4) == 0)
        return "PKT";
    return "CIRC"; /* NORTH/SOUTH/EAST/WEST slave: may carry either, label CIRC */
}

/* Mask semantics note printed for packet-switch slots */
static const char *s_mask_note(uint32_t mask) {
    if (mask == 0x1F)
        return "exact"; /* all 5 PktId bits compared */
    if (mask == 0x00)
        return "wildcard"; /* no bits compared — matches any PktId */
    return "partial";
}

/* Stall interpretation (MEM module local event IDs from xaie_events_aieml.h):
 *   MM2S stall_stream=1 → DMA_MM2S_0_STREAM_BACKPRESSURE (MEM local ID 37): stream switch won't accept packet
 *   S2MM stall_stream=1 → DMA_S2MM_0_STREAM_STARVATION   (MEM local ID 35): waiting for data from stream
 *   stall_lock_acq=1    → DMA_*_STALLED_LOCK              (MEM local IDs 31-34): waiting to acquire lock
 */

void AieRt_PrintStreamSwitchConfig(XAie_DevInst *dev, XAie_LocType tile, int print_all) {
    int is_shim = s_is_shim(tile);
    int is_mem = s_is_memtile(tile);
    uint32_t master_count;
    uint32_t slave_count;
    const char **master_names;
    const char **slave_names;
    const char *tile_type;

    if (is_shim) {
        master_count = AIERT_SS_SHIM_MASTER_ACTUAL;
        slave_count = AIERT_SS_SHIM_SLAVE_ACTUAL;
        master_names = s_shim_master_names;
        slave_names = s_shim_slave_names;
        tile_type = "SHIM";
    } else if (is_mem) {
        master_count = AIERT_SS_MEMTILE_MASTER_ACTUAL;
        slave_count = AIERT_SS_MEMTILE_SLAVE_ACTUAL;
        master_names = s_memtile_master_names;
        slave_names = s_memtile_slave_names;
        tile_type = "MEMTILE";
    } else {
        master_count = AIERT_SS_CORE_MASTER_ACTUAL;
        slave_count = AIERT_SS_CORE_SLAVE_ACTUAL;
        master_names = s_core_master_names;
        slave_names = s_core_slave_names;
        tile_type = "CORE";
    }

    u64 tile_base = ((u64)tile.Col << 25) | ((u64)tile.Row << 20);

    /* Select register bases according to tile type */
    uint32_t ss_master_base = is_mem ? AIERT_SS_MEM_MASTER_BASE : AIERT_SS_MASTER_BASE;
    uint32_t ss_slave_base = is_mem ? AIERT_SS_MEM_SLAVE_BASE : AIERT_SS_SLAVE_BASE;
    uint32_t ss_slot_base = is_mem ? AIERT_SS_MEM_SLOT_BASE : AIERT_SS_SLOT_BASE;

    /* ------------------------------------------------------------------ */
    /* JSON output                                                          */
    /* ------------------------------------------------------------------ */
    printf("{\n");
    printf("  \"tile\": {\"col\": %u, \"row\": %u, \"type\": \"%s\"},\n", (unsigned)tile.Col, (unsigned)tile.Row,
           tile_type);
    printf("  \"masters\": [\n");

    int first_master = 1;
    for (uint32_t i = 0; i < master_count; i++) {
        u64 reg_off = tile_base | (ss_master_base + i * 4u);
        u32 val = 0;
        AieRC rc = XAie_Read32(dev, reg_off, &val);
        if (rc != XAIE_OK)
            continue;

        int enabled = (val & AIERT_SS_MSTR_ENABLE_MASK) ? 1 : 0;
        int pkt_en = (val & AIERT_SS_MSTR_PKT_EN_MASK) ? 1 : 0;
        int drop_hdr = (val & AIERT_SS_MSTR_DROP_MASK) ? 1 : 0;
        uint32_t config = val & AIERT_SS_MSTR_CONFIG_MASK;

        if (!print_all && !enabled)
            continue;

        const char *port_type = s_ss_port_type(master_names[i], pkt_en);

        /* drop_header note: only meaningful for PKT masters */
        const char *drop_note = "";
        if (pkt_en && drop_hdr)
            drop_note = "DROP_HEADER (strip pkt hdr before forwarding — last PKT-SW hop)";
        if (pkt_en && !drop_hdr)
            drop_note = "DONOT_DROP_HEADER (preserve pkt hdr for downstream PKT-SW slave)";

        if (!first_master)
            printf(",\n");
        first_master = 0;

        printf("    {\n");
        printf("      \"index\": %u,\n", (unsigned)i);
        printf("      \"port\": \"%s\",\n", master_names[i]);
        printf("      \"switch_type\": \"%s\",\n", port_type);
        printf("      \"enabled\": %s,\n", enabled ? "true" : "false");
        printf("      \"packet_switch\": %s,\n", pkt_en ? "true" : "false");
        printf("      \"drop_header\": %s,\n", drop_hdr ? "true" : "false");
        if (pkt_en)
            printf("      \"drop_header_note\": \"%s\",\n", drop_note);
        printf("      \"config\": \"0x%02X\",\n", (unsigned)config);
        printf("      \"raw\": \"0x%08X\"\n", (unsigned)val);
        printf("    }");
    }
    printf("\n  ],\n");

    /* --- Slave config + slot registers --- */
    printf("  \"slaves\": [\n");
    int first_slave = 1;
    for (uint32_t i = 0; i < slave_count; i++) {
        u64 slv_cfg_off = tile_base | (ss_slave_base + i * 4u);
        u32 slv_val = 0;
        AieRC rc = XAie_Read32(dev, slv_cfg_off, &slv_val);
        if (rc != XAIE_OK)
            continue;

        int slv_en = (slv_val & AIERT_SS_SLV_ENABLE_MASK) ? 1 : 0;

        u32 slots[4] = {0, 0, 0, 0};
        int slot_en[4] = {0, 0, 0, 0};
        int any_slot = 0;
        for (uint32_t s = 0; s < 4u; s++) {
            u64 slot_off = tile_base | (ss_slot_base + i * 16u + s * 4u);
            AieRC src = XAie_Read32(dev, slot_off, &slots[s]);
            if (src == XAIE_OK && (slots[s] & AIERT_SS_SLOT_ENABLE_MASK)) {
                slot_en[s] = 1;
                any_slot = 1;
            }
        }

        if (!print_all && !slv_en && !any_slot)
            continue;

        /* Slave port type: use pkt_en=-1 (no register bit on slave side) */
        const char *port_type = s_ss_port_type(slave_names[i], -1);
        /* Refine: if any slot is enabled, it must be packet-switched */
        if (any_slot && strcmp(port_type, "CTRL") != 0)
            port_type = "PKT";

        if (!first_slave)
            printf(",\n");
        first_slave = 0;

        printf("    {\n");
        printf("      \"index\": %u,\n", (unsigned)i);
        printf("      \"port\": \"%s\",\n", slave_names[i]);
        printf("      \"switch_type\": \"%s\",\n", port_type);
        printf("      \"enabled\": %s,\n", slv_en ? "true" : "false");
        printf("      \"raw\": \"0x%08X\",\n", (unsigned)slv_val);
        printf("      \"slots\": [\n");

        int first_slot = 1;
        for (uint32_t s = 0; s < 4u; s++) {
            if (!print_all && !slot_en[s])
                continue;
            uint32_t pkt_id = (slots[s] & AIERT_SS_SLOT_PKTID_MASK) >> AIERT_SS_SLOT_PKTID_LSB;
            uint32_t pkt_msk = (slots[s] & AIERT_SS_SLOT_MASK_MASK) >> AIERT_SS_SLOT_MASK_LSB;
            uint32_t msel = (slots[s] & AIERT_SS_SLOT_MSEL_MASK) >> AIERT_SS_SLOT_MSEL_LSB;
            uint32_t arb = (slots[s] & AIERT_SS_SLOT_ARB_MASK) >> AIERT_SS_SLOT_ARB_LSB;
            /* mask=0x1F means exact PktId match required (MEM local ID 37 fires if mismatch);
             * mask=0x00 means wildcard — accepts any PktId (used at merge points) */
            const char *match_note = s_mask_note(pkt_msk);

            if (!first_slot)
                printf(",\n");
            first_slot = 0;
            printf("        {\n");
            printf("          \"slot\": %u,\n", (unsigned)s);
            printf("          \"enabled\": %s,\n", slot_en[s] ? "true" : "false");
            printf("          \"pkt_id\": %u,\n", (unsigned)pkt_id);
            printf("          \"pkt_mask\": \"0x%02X\",\n", (unsigned)pkt_msk);
            printf("          \"match_mode\": \"%s\",\n", match_note);
            /* match_mode note: exact match means wrong pkt_id → DMA_MM2S_0_STREAM_BACKPRESSURE (MEM local ID 37) */
            if (pkt_msk == 0x1F)
                printf("          \"match_note\": \"exact: DMA BD pkt_id must equal %u or "
                       "DMA_MM2S_0_STREAM_BACKPRESSURE (MEM local ID 37) fires\",\n",
                       (unsigned)pkt_id);
            else if (pkt_msk == 0x00)
                printf("          \"match_note\": \"wildcard: any pkt_id accepted (merge point)\",\n");
            printf("          \"msel\": %u,\n", (unsigned)msel);
            printf("          \"arb\": %u,\n", (unsigned)arb);
            printf("          \"raw\": \"0x%08X\"\n", (unsigned)slots[s]);
            printf("        }");
        }
        printf("\n      ]\n");
        printf("    }");
    }
    printf("\n  ]\n");
    printf("}\n");
}

void AieRt_PrintStreamSwitchConfigAll(XAie_DevInst *dev, const XAie_LocType *tiles, uint32_t num_tiles, int print_all) {
    printf("[AieRt_SS] ===== Stream Switch Config (%u tiles) =====\n", (unsigned)num_tiles);
    printf("[\n");
    for (uint32_t i = 0; i < num_tiles; i++) {
        AieRt_PrintStreamSwitchConfig(dev, tiles[i], print_all);
        if (i + 1 < num_tiles)
            printf(",\n");
    }
    printf("]\n");
}

/* --------------------------------------------------------------------------
 * Coordinate-based debug snapshot helper
 * -------------------------------------------------------------------------- */

/* Max IOs and tiles supported by the stack-allocated snapshot helper.
 * Baremetal environments often have broken/limited calloc (nosys.specs),
 * so we avoid heap allocation entirely. */
#define AIERT_SNAPSHOT_MAX_IOS 128
#define AIERT_SNAPSHOT_MAX_TILES 64

void AieRt_DebugSnapshotFromCoords(XAie_DevInst *dev, const uint8_t *io_cols, const uint8_t *io_rows,
                                   const uint8_t *io_chs, const uint8_t *io_bds, const int *io_dirs, uint32_t num_ios,
                                   const uint8_t *tile_cols, const uint8_t *tile_rows, uint32_t num_tiles) {
    /* Stack-allocated arrays — avoids calloc which fails on baremetal */
    struct_io ios[AIERT_SNAPSHOT_MAX_IOS];
    XAie_LocType tiles[AIERT_SNAPSHOT_MAX_TILES];

    if (num_ios > AIERT_SNAPSHOT_MAX_IOS) {
        printf("[AieRt_Debug] WARNING: num_ios=%u exceeds max %d, clamping\n", (unsigned)num_ios,
               AIERT_SNAPSHOT_MAX_IOS);
        num_ios = AIERT_SNAPSHOT_MAX_IOS;
    }
    if (num_tiles > AIERT_SNAPSHOT_MAX_TILES) {
        printf("[AieRt_Debug] WARNING: num_tiles=%u exceeds max %d, clamping\n", (unsigned)num_tiles,
               AIERT_SNAPSHOT_MAX_TILES);
        num_tiles = AIERT_SNAPSHOT_MAX_TILES;
    }

    memset(ios, 0, num_ios * sizeof(struct_io));
    for (uint32_t i = 0; i < num_ios; i++) {
        ios[i].tile_loc = XAie_TileLoc(io_cols[i], io_rows[i]);
        ios[i].channel_id = io_chs[i];
        ios[i].bd_id = io_bds[i];
        ios[i].direction = (XAie_DmaDirection)io_dirs[i];
    }

    for (uint32_t i = 0; i < num_tiles; i++) {
        tiles[i] = XAie_TileLoc(tile_cols[i], tile_rows[i]);
    }

    AieRt_DebugSnapshot(dev, ios, num_ios, tiles, num_tiles);
}
