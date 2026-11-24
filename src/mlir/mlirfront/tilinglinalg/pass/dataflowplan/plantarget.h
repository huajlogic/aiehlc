/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

// The device facts a dataflow plan is built on (doc/design/dmaphop_dataflow_plan.md), in ONE place:
// tile resource counts, address views, lock numbering, DMA descriptor limits and the stream-switch
// port model. Everything in pass/dataflowplan/ that is a property of the silicon reads it from here;
// everything else is derived from the plan's streams or allocated against what the generated flows
// already use (planresource.cpp). Values: AIE2PS (xaie2psgbl_reginit.c, the AIE2PS register map).

#ifndef TILINGLINALG_DATAFLOWPLAN_TARGET_H
#define TILINGLINALG_DATAFLOWPLAN_TARGET_H

#include <cstdint>
#include <map>
#include <string>

namespace dfplan {

struct PlanTarget {
    const char *name;
    // ---- resources per tile
    int coreLocks, coreBds, coreS2mmChannels;
    int memLocks, memBds, memChannels; // MemTile: per direction
    int memBdBank;                     // a MemTile channel c may only use BDs [memBdBank (c & 1), + memBdBank)
    int shimBds;
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
    // ---- stream switch
    // shim MM2S channel ch enters the switch at SOUTH slave port shimMm2sSouth[ch]
    int shimMm2sSouth[2];
    // master / slave port counts per direction, per tile kind ("core" / "mem" / "shim")
    std::map<std::string, std::map<std::string, int>> masters, slaves;

    int portCount(const std::string &kind, char ms, const std::string &dir) const {
        const auto &m = ms == 'm' ? masters : slaves;
        auto k = m.find(kind);
        if (k == m.end())
            return 0;
        auto it = k->second.find(dir);
        return it == k->second.end() ? 0 : it->second;
    }
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
        /*shimMm2sSouth*/ {3, 7},
        /*masters*/
        {{"core", {{"NORTH", 6}, {"SOUTH", 4}, {"EAST", 4}, {"WEST", 4}, {"DMA", 2}}},
         {"mem", {{"NORTH", 6}, {"SOUTH", 4}, {"DMA", 6}}},
         {"shim", {{"NORTH", 6}, {"SOUTH", 6}, {"EAST", 4}, {"WEST", 4}}}},
        /*slaves*/
        {{"core", {{"SOUTH", 6}, {"NORTH", 4}, {"EAST", 4}, {"WEST", 4}, {"DMA", 2}}},
         {"mem", {{"SOUTH", 6}, {"NORTH", 4}, {"DMA", 6}}},
         {"shim", {{"SOUTH", 8}, {"NORTH", 4}, {"EAST", 4}, {"WEST", 4}}}},
    };
    return t;
}

} // namespace dfplan

#endif
