/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* rt_bd_once.h -- the dataflow-plan write-once table (dmaphop.plan bd_once) with an O(1) lookup.
 *
 * gemm90 m3362124222212 PL (host_gap): every host call of a sliced plan re-issues its shim BD configs and
 * out-of-order channel enables; under bd_once they are skipped when identical to the write already made in
 * this partition generation.  The lookup used to be a linear scan of every recorded write (~36 entries per
 * call for the 4096^3 int8 plan, 36 lookups per call), on the host's critical path between a call's first
 * rebase and its first startio (PM m3362124222212: host_gap 812 us / launch; PL diag: the BD-config calls
 * are ~45 us of the ~97 us per call).  Same semantics as the scan (key = dev, col, row, kind, id; a hit needs
 * the same generation, address and argument hash; a key with other values is re-recorded and written; a full
 * table records nothing and never skips), indexed by an open-addressing hash of the key.
 * Plain C, no aie-rt types: kernel_trace_cases.py "dataflow plan bd_once O(1) table" checks it on x86 against
 * the linear reference. */
#ifndef AIEHLC_RT_BD_ONCE_H
#define AIEHLC_RT_BD_ONCE_H
#include <stdint.h>
#include <string.h>

#define RT_BD_ONCE_MAX 256
#define RT_BD_ONCE_HSZ 1024 /* power of two, 4 x RT_BD_ONCE_MAX: short probe chains */

typedef struct {
    const void *dev;
    unsigned gen;
    uint8_t col, row, id, kind; /* kind 0 = shim BD (ooo), 1 = ooo channel (id = ch | dir << 4), 2 = BD */
    uint64_t addr;
    uint32_t hash;
} rt_bd_once_ent;

typedef struct {
    rt_bd_once_ent e[RT_BD_ONCE_MAX];
    uint16_t ix[RT_BD_ONCE_HSZ]; /* slot + 1, 0 = empty */
    int n;
    unsigned long probes; /* index probes (test statistics) */
} rt_bd_once_tab;

static inline uint32_t rt_bd_once_slot0(const void *dev, uint8_t col, uint8_t row, uint8_t kind, uint8_t id) {
    uint32_t k = ((uint32_t)col << 24) | ((uint32_t)row << 16) | ((uint32_t)kind << 8) | (uint32_t)id;
    k ^= (uint32_t)((uintptr_t)dev >> 4);
    return (k * 2654435761u) >> 22; /* top 10 bits: [0, RT_BD_ONCE_HSZ) */
}

/* 1 if the identical write was already made (skip it); records it otherwise (0). */
static inline int rt_bd_once_check(rt_bd_once_tab *T, const void *dev, unsigned gen, uint8_t col, uint8_t row,
                                   uint8_t kind, uint8_t id, uint64_t addr, uint32_t hash) {
    uint32_t h = rt_bd_once_slot0(dev, col, row, kind, id);
    for (;;) {
        const uint16_t s = T->ix[h];
        T->probes++;
        if (!s)
            break;
        rt_bd_once_ent *e = &T->e[s - 1];
        if (e->dev == dev && e->col == col && e->row == row && e->kind == kind && e->id == id) {
            if (e->gen == gen && e->addr == addr && e->hash == hash)
                return 1;
            e->gen = gen;
            e->addr = addr;
            e->hash = hash;
            return 0;
        }
        h = (h + 1U) & (RT_BD_ONCE_HSZ - 1U);
    }
    if (T->n >= RT_BD_ONCE_MAX)
        return 0;
    rt_bd_once_ent *e = &T->e[T->n];
    e->dev = dev;
    e->gen = gen;
    e->col = col;
    e->row = row;
    e->kind = kind;
    e->id = id;
    e->addr = addr;
    e->hash = hash;
    T->ix[h] = (uint16_t)(++T->n);
    return 0;
}
#endif
