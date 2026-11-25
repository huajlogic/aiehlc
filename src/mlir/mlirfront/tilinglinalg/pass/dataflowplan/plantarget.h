/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// The device facts a dataflow plan is built on (doc/design/dmaphop_dataflow_plan.md), in ONE place:
// tile resource counts, address views, lock numbering and DMA descriptor limits. (The stream-switch
// port model is the router's own -- hwresource.cpp -- the plan's routes go through DmaphopToRoutinghwPass.) Everything
// in pass/dataflowplan/ that is a property of the silicon reads it from here; everything else is derived from the
// plan's streams or allocated against what the generated flows already use (planresource.cpp). Values: AIE2PS
// (xaie2psgbl_reginit.c, the AIE2PS register map).

#ifndef TILINGLINALG_DATAFLOWPLAN_TARGET_H
#define TILINGLINALG_DATAFLOWPLAN_TARGET_H

#include <cstdint>
#include <vector>

namespace dfplan {

struct PlanTarget {
    const char *name;
    // ---- resources per tile
    int coreLocks, coreBds, coreS2mmChannels;
    int memLocks, memBds, memChannels; // MemTile: per direction
    int memBdBank;                     // a MemTile channel c may only use BDs [memBdBank (c & 1), + memBdBank)
    int shimBds, shimMm2sChannels;
    // ---- memories, as the DMAs and the core address them
    int64_t memOwnBase; // a MemTile BD's address of its own memory (the window covers its neighbours too)
    int64_t memBytes;   // MemTile data memory
    int memLockBdBias;  // a MemTile's own lock as named in its BDs (neighbourhood-relative ids)
    // A core's data memory views: own / north neighbour / south neighbour, and the matching lock-id bias
    // (the core program names its own lock k as ownLockBias + k, the north one's as northLockBias + k ...).
    int64_t coreOwnView, coreNorthView, coreSouthView;
    int coreOwnLockBias, coreNorthLockBias, coreSouthLockBias;
    // ---- DMA descriptors
    int bdWordBytes; // BD strides / lengths count 32-bit words
    // largest wrap of one BD dimension, per tile kind (the field is 8 bits in a core tile's BD, 10 bits in a
    // MemTile's / shim's: xaie2psgbl_params.h *_D0_WRAP_MASK); a wider wrap is silently truncated
    int coreBdMaxWrap, memBdMaxWrap, shimBdMaxWrap;
    int bdMaxIterWrap; // largest BD iteration count
    // largest buffer length of ONE BD, in 32-bit words, per tile kind (the BUFFER_LENGTH field; aie-rt masks the
    // length into it, so a longer BD is silently truncated -- 0x20000 words & 0x1FFFF = 0). aie-rt
    // xaie2psgbl_params.h (aienginev2/src/global):
    //   core  MEMORY_MODULE_DMA_BD0_0_BUFFER_LENGTH_MASK   0x00003FFF  (xaie2psgbl_params.h:8678)
    //   mem   MEM_TILE_MODULE_DMA_BD0_0_BUFFER_LENGTH_MASK 0x0001FFFF  (xaie2psgbl_params.h:26106)
    //   shim  NOC_MODULE_DMA_BD0_0_BUFFER_LENGTH_MASK      0xFFFFFFFF  (xaie2psgbl_params.h:21663)
    int64_t coreBdMaxLenWords, memBdMaxLenWords, shimBdMaxLenWords;
    int memBankLo(int ch) const { return memBdBank * (ch & 1); }
};

// The device the plan targets (AIE2PS -- the only generation the dataflow plans support today).
inline const PlanTarget &planTarget() {
    static const PlanTarget t{
        "aie2ps",
        /*coreLocks*/ 16,
        /*coreBds*/ 16,
        /*coreS2mmChannels*/ 2,
        /*memLocks*/ 64,
        /*memBds*/ 48,
        /*memChannels*/ 6,
        /*memBdBank*/ 24,
        /*shimBds*/ 16,
        /*shimMm2sChannels*/ 2,
        /*memOwnBase*/ 0x80000,
        /*memBytes*/ 0x80000,
        /*memLockBdBias*/ 64,
        /*coreOwnView*/ 0x70000,
        /*coreNorthView*/ 0x60000,
        /*coreSouthView*/ 0x40000,
        /*coreOwnLockBias*/ 48,
        /*coreNorthLockBias*/ 32,
        /*coreSouthLockBias*/ 0,
        /*bdWordBytes*/ 4,
        /*coreBdMaxWrap*/ 255,
        /*memBdMaxWrap*/ 1023,
        /*shimBdMaxWrap*/ 1023,
        /*bdMaxIterWrap*/ 64,
        /*coreBdMaxLenWords*/ 0x3FFF,
        /*memBdMaxLenWords*/ 0x1FFFF,
        /*shimBdMaxLenWords*/ 0xFFFFFFFFLL,
    };
    return t;
}

// splitBdLen: a transfer of `bytes` as a chain of BDs, each at most `maxWords` 32-bit words long and each a
// whole number of `unitBytes` (the transfer's natural cut: a chunk, a strip). Returns the BD lengths in bytes --
// as few BDs as the limit allows, the units spread evenly over them -- one entry when the transfer fits one BD;
// empty when it cannot be cut (unitBytes not a multiple of a word, does not divide `bytes`, or one unit alone
// is over the limit). The ONE place the BD length limit is applied: the plan's DMA program (plandma.cpp), its
// resource count (planresource.cpp via memtileUse) and the front end's note (convautotile/kernel_trace.cpp).
inline std::vector<int64_t> splitBdLen(int64_t bytes, int64_t maxWords, int64_t unitBytes, int wordBytes = 4) {
    if (bytes <= 0 || maxWords <= 0)
        return {};
    if (bytes / wordBytes <= maxWords && bytes % wordBytes == 0)
        return {bytes};
    if (unitBytes <= 0 || unitBytes % wordBytes || bytes % unitBytes)
        return {};
    const int64_t perBd = maxWords * wordBytes / unitBytes; // units per BD at most
    if (perBd < 1)
        return {};
    const int64_t units = bytes / unitBytes, n = (units + perBd - 1) / perBd;
    std::vector<int64_t> out;
    for (int64_t i = 0; i < n; i++)
        out.push_back((units / n + (i < units % n ? 1 : 0)) * unitBytes);
    return out;
}

} // namespace dfplan

#endif
