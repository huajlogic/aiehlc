<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Steps 0-2: the generic path -- kernel first, then the launch

All three steps share one source, `example/tileprogram/ccode/gemm_plan/gemm_generic_body.cc`; the step
files only set two macros and (step 2) the pragmas.

## The kernel every step starts from

Core (pm, pn) of the 4 x 4 mesh owns `KA_R` = 30 output tiles of 64 x 64. For each tile it walks K in
chunks of 64, keeping the int32 partial sums in core memory:

```c++
__global__ void gemm_gen(aie::port<input_window_int8 *, aie::IFM, aie::shape<KA_M, KA_K>> a,
                         aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<KA_N, KA_K>> b,
                         aie::port<output_window_int8 *, aie::OFM, aie::shape<KA_M, KA_N>> c) {
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    alignas(64) static int32_t acc[KA_TM * KA_TN];
    for (int s = 0; s < KA_R; s++) {                                   // output tiles
        int8_t *y = aie::store_buffer(c, {(pm * KA_R + s) * KA_TM, pn * KA_TN}, {KA_TM, KA_TN}, ...);
        for (int j = 0; j < nk; j++) {                                 // K chunks
            const int8_t *x = aie::load_buffer(a, {(pm * KA_R + s) * KA_TM, j * KA_KC}, {KA_TM, KA_KC}, {.depth = 2, ...});
            const int8_t *w = aie::load_buffer(b, {pn * KA_TN, j * KA_KC}, {KA_TN, KA_KC}, {.depth = 2, ...});
            ... // acc += x . w^T, last chunk: acc -> int8 into y
            aie::release(a);
            aie::release(b);
        }
        aie::commit(c);
    }
}
```

Nothing here says how data moves. The compiler **traces** the kernel on x86 (every `load_buffer` /
`store_buffer` with its offsets and shape, for every core), fits the blocks as an affine sequence --
core (pm, pn) round (i, j) -> offset -- and derives the core windows (ping-pong because of
`{.depth = 2}`), the shim BDs that walk A and B in DDR, the stream routes and the output path. The
kernel reads `x` / `w` as plain pointers; `release` / `commit` hand the buffers back to the DMA.

## Step 0: the baseline (`step0_baseline.cc`) -- 3194.4 ms per launch, 0.015 % of peak

```c++
#define GEN_VECTOR 0      // scalar MACs
#define GEN_LAUNCH 0      // plain launch
#include "gemm_generic_body.cc"
```

The scalar inner loop does one multiply-add per element:

```c++
for (int k = 0; k < KA_KC; k++)
    sum += x[(mi * kb + k / 8) * 64 + r * 8 + k % 8] * w[(ni * kb + k / 8) * 64 + (k % 8) * 8 + q];
```

The operands are already **host-packed in `mmul` order** (`ka_pack`: [mi][kb][8 rows][8 k] for A,
[ni][kb][8 k][8 cols] for B) so that step 1 can switch the arithmetic without touching the data. On
the baseline that layout costs nothing extra; the core simply cannot do more than a few MACs per cycle
with scalar code, against 512 for one `mac_8x8_8x8`.

History: the first compiler-generated GEMM ran at 0.09 % (293 ms on VEK385_2, 998 MHz, a smaller
problem) -- a scalar kernel *and* a
host loop that re-programmed the shim BDs for every strip. Today's compiler already removes the host
loop (one shim BD walks every round, back-pressured by the core's locked ring), so step 0 is the
scalar kernel alone.

## Step 1: the vector kernel (`step1_vector.cc`) -- 99.25 ms per launch, 0.50 % of peak

```c++
#define GEN_VECTOR 1
```

Two things change in the body:

```c++
typedef aie::mmul<8, 8, 8, int8_t, int8_t> MM;     // one mac_8x8_8x8 = 512 int8 MAC in one cycle
for (int mh = 0; mh < KA_TM / 16; mh++)
    for (int nh = 0; nh < KA_TN / 16; nh++) {      // a 16 x 16 piece of the tile:
        MM c00, c01, c10, c11;                     //   2 x 2 register block of 8 x 8 accumulators
        ...                                        //   (reloaded from acc[] unless j == 0)
        for (int ki = 1; ki < kb; ki++) {
            const aie::vector<int8_t, 64> a0 = aie::load_v<64>(pa0 + ki * 64), a1 = aie::load_v<64>(pa1 + ki * 64);
            const aie::vector<int8_t, 64> b0 = aie::load_v<64>(pb0 + ki * 64), b1 = aie::load_v<64>(pb1 + ki * 64);
            c00.mac(a0, b0); c01.mac(a0, b1); c10.mac(a1, b0); c11.mac(a1, b1);
        }
        ...                                        // last chunk: to_vector<int8_t>() into y, else back to acc[]
    }
```

- **2 x 2 register blocking**: four loads feed four MACs, so every operand vector is used twice.
- **`{.align = 64}`** on the loads and the store (`GEN_ALIGN`). `aie::load_v<64>` is a 64-byte load;
  a DMA window is only 32-byte aligned by default and the kernel analysis refuses the build with
  `needs a 64-byte aligned address`. The option makes the compiler place the port buffers 64-aligned.

The kernel gets more than 30x faster, yet the result is still two orders of magnitude below the peak:
the launch now dominates. Every launch re-initializes the partition, reloads the kernel ELF and its BSS
over MMIO (~372 ns per 32-bit write, `doc/performance/register_write_cost.md`), programs every BD, and
tears the partition down again.

## Step 2: take the launch off the MMIO path (`step2_launch.cc`) -- 2.042 ms per launch, 24.1 % of peak

```c++
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)  // keep the partition between launches
#pragma control_plan_op_control_packet   // kernel ELF + core launch as control packets on the stream fabric
#pragma control_packet_mode(aot)         // warm relaunch resends only reset + data, not program memory
#pragma KERNELCONFIGOFFLOAD              // each core programs its own DMA (BDs, locks) from kernel.cc
#pragma output_tile_major                // C as whole tiles: ONE out-of-order shim BD covers every round
#define GEN_VECTOR 1
#define GEN_LAUNCH 1
```

and in the host part of the body:

```c++
__Runtime_ctrl_high_throughput_enable(1);                         // required by the control-packet ELF load
aieMesh mesh = device.partition({2, 6, 0, 6}, GP_HW_ROWS, GP_HW_COLS);  // + one column for the control plane
int8_t *Ap = (int8_t *)__Runtime_alloc_uncached(M * K);           // operands and C non-cacheable:
int8_t *Ct = (int8_t *)__Runtime_alloc_uncached(M * N);           //   no cache maintenance per launch
```

| knob | what it removes |
|---|---|
| `DISABLE_PARTITIONTEARDOWN` | partition re-init + teardown per launch |
| `control_plan_op_control_packet` | the MMIO ELF load: packets on the stream fabric at ~2.9 ns per word |
| `control_packet_mode(aot)` | resending program memory on every warm relaunch |
| `KERNELCONFIGOFFLOAD` | host MMIO writes of 16 cores' BDs and locks |
| `output_tile_major` | per-round output re-arming: tiles stream out back to back |
| uncached A / B / C | a by-VA clean / invalidate of 20+ MB every launch (the runtime only issues a barrier for a non-cacheable range) |

Partition `{2, 6}`: five columns for a four-column mesh -- the control plane needs a column of its own;
the data plane stays on columns 3..6.

History: this is the 14.6 % milestone ("the compiler alone", 0.897 ms per 1.07 G MAC on VEK385_2). Today it
lands higher, because warm reload, the plan cache and uncached buffers did not exist then. It is now
bound by the generic data path: every core pulls its A and B chunks from DDR through its own shim
channel, so DDR and the per-core input streams, not the MACs, set the pace.
