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
    // largest BD buffer length in 32-bit words, per tile kind (the field is 14 bits in a core tile's BD,
    // 17 bits in a MemTile's: *_DMA_BD0_0_BUFFER_LENGTH_MASK); a longer one is silently truncated
    int64_t coreBdMaxLenWords, memBdMaxLenWords;
    // ---- core data memory, as the kernel's link sees it
    int64_t coreDmBytes;       // one core tile's data memory
    int64_t coreMinStack;      // the smallest stack kc.sh relinks a kernel with (AIEHLC_DM_MIN_STACK)
    int64_t coreStaticReserve; // kernel statics besides the accumulator (klog area, block-call state)
    int chMaxRepeat;           // largest repeat count of a DMA channel's start (task queue): MaxRepeatCount
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
        /*coreDmBytes*/ 0x10000,
        /*coreMinStack*/ 4096,
        /*coreStaticReserve*/ 4096,
        /*chMaxRepeat*/ 256,
    };
    return t;
}

} // namespace dfplan

#endif
