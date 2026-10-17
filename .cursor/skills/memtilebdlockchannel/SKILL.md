---
name: memtilebdlockchannel
description: Memory-tile DMA BD hand-programmed from the host hangs or is rejected — "invalid BD" for BD >= 24 on channel 0, a fill BD that never completes waiting on a lock it never asked for, a streaming fill whose consumer never starts. Memtile BD/channel banking and XAie_DmaSetLock enabling both lock sides.
---

# Memory-tile BDs: channel banks and the lock pair

Found while adding streaming fills to `src/aietensorop/whisperengine/eng/we_host.h`
(`we_mt_bdl`, `we_mt_queue`, `we_gemm_fill_a/_b`).

## 1. BDs 0..23 serve even channels, 24..47 odd channels
A memtile has 48 BDs, but a channel can only start/chain BDs of its own half:
even channels (S2MM0, MM2S0, ...) use BDs 0..23, odd channels use 24..47.
Queuing BD 25 on S2MM0 is rejected (or silently never runs). If one channel
needs more BDs than its half has, move the traffic to an odd channel — the
whisper engine moved the MT_A fill to S2MM **1** (`fabric/routing.cc`: the shim
→ MT_A stream lands on `DMA, 1`, four places) and gave it BDs 24.. .
`we_mt_queue` picks the channel from the BD number (`bd >= 24`).

Also: the memtile task queue holds **4** start entries; chains longer than one
queue's worth must be expressed as BD `next` links, not queue pushes.

## 2. `XAie_DmaSetLock` enables BOTH acquire and release
`XAie_DmaSetLock(&d, XAie_LockInit(acq, -1), XAie_LockInit(rel, +1))` sets
`LockAcqEn` **and** `LockRelEn`. A BD that should only release (producer fill
of a block) or only acquire therefore waits on lock 0 / bumps lock 0 too —
the fill hangs or a stranger's lock gets incremented. Clear the unused side
after the call:
```c
if (lka < 0) d.LockDesc.LockAcqEn = 0, d.LockDesc.LockAcqId = 0, d.LockDesc.LockAcqVal = 0;
if (lkr < 0) d.LockDesc.LockRelEn = 0, d.LockDesc.LockRelId = 0, d.LockDesc.LockRelVal = 0;
```

## 3. Streaming fill lock protocol (what works)
Per A/B block one memtile lock (`WE_LK_A + mb`, `WE_LK_B + i`, `WE_LK_H` for
headers): the shim→memtile S2MM BD of the block only **releases**, by the number
of times it will be replayed (`+NBT` for an A block, `+MBP` for a B panel,
`+NSUB` for the headers); each replay MM2S BD only **acquires** (`-1`). After all
replays the lock is back at 0, so the next op starts from a clean state without a
host reset, and the cores start on block 0 while DDR still delivers the rest.

## 4. Don't rewrite a bank that is in flight
Two BD banks alternate per op. Pre-writing the next op's BDs into `rbank ^ 1`
is only safe when that bank is not the one the still-running op uses — an
earlier attempt (prepare replay(1) before `we_drain`) hung with
`WE HANG waiting output tile(4,0) ch 0 op seq 17`.
