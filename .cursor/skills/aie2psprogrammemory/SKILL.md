---
name: aie2psprogrammemory
description: AIE2PS kernel builds rc=0 but the board log says "[AIE ERROR] _XAie_LoadProgMemSection(): Overflow of program memory", or the kernel hangs / behaves randomly after code was added; kernel.map "Used" looks under 16 KB. Shrinking a persistent AIE kernel to fit the 16 KB program memory; chess "Internal error: no Basic_block found".
---

# AIE2PS program memory (16 KB) overflow

## Symptom
- Build succeeds. At load the runtime prints
  `[AIE ERROR] _XAie_LoadProgMemSection():233: Overflow of program memory`
  and silently drops the tail of `.text`. Whatever lands past 0x4000 is gone:
  if that is a rarely-called function the app still "works" (whisperengine ran
  a full transcript with `__cxa_finalize` cut off), otherwise hangs/garbage.
- `kernel.map` "Memory map for memory 'PM': Used = 16300" is NOT the check:
  Used sums item sizes and omits the alignment padding between functions
  (16300 used, last item ending at 0x406d).

## Check
The end address of the last PM item in `aout/worklocal/build/kernel.map` must be
< 0x4000. `src/aietensorop/whisperengine/build.sh` fails the build otherwise:
```
awk '/Memory map for memory .PM./{f=1} /Memory map for memory .DM/{f=0} f && /items\) :/{split($1,a,"\\.\\."); e=a[2]} END{print e}' kernel.map
```
Per-function sizes: same awk, print the `( N items)` field, `sort -rn`.

## What actually shrinks code (measured on eng/kernel.cc, -Os front end)
- **One copy of each loop.** Copy/zero loops written inline in five places cost
  ~600 B; `vcopy(dst, src, n)` / `vzero(dst, n)` noinline helpers.
- **One BD encoder.** `aie_kc_encode_bd` is a big static inline: wrap it once
  (`bd_write`) and call it from every DMA config helper (-354 B).
- **Pointer helpers, not vector-by-reference.** A noinline helper taking
  `const aie::vector<...>&` spills to the stack and the caller's loops get peeled
  (att_raise 2.4 KB). Helpers that load/store through pointers and own their
  loop body: 1.5 KB -> 0.4 KB + small helpers.
- **No modulo/division in scalar code** (`% 5` pulled in a soft routine).
- **No function-local statics with constructors** (`static aie::lut<4> lut(..)`
  drags in guard + atexit code). Make it a plain local.
- **`extern "C" void __cxa_finalize(void *) {}`** in a kernel whose main never
  returns keeps the runtime's atexit.o (174 B) out.
- **fp32 vector `aie::invsqrt` / `aie::to_fixed` / `aie::to_float`** expand to
  large per-lane or emulated code on AIE2PS; use bit tricks (fp32 magic-number
  rounding `x + 1.5*2^23`, exponent arithmetic) or run them on 2 vectors not 16.
- **Did not help:** `#pragma clang loop unroll(disable)` (IR was not unrolled;
  chess peels/pipelines in the backend), removing `chess_prepare_for_pipelining`
  from cold loops (no size change), Newton invsqrt instead of `aie::invsqrt` on
  2 vectors (bigger).
- Unconditional code in a flag-dispatched epilogue can GROW it (1.2 -> 3.3 KB):
  chess versions the loop differently; measure every change.

## Chess internal error
`Internal error: no Basic_block found for block #N` from chess-backend on a
function mixing float add/sub with `cast_to<int32>` and a ternary-chosen
broadcast. Moving the arithmetic into its own noinline helper (`raise_rg`)
compiled.

## Related
Stack: `kernel.calltree` "Maximum stack size" vs `_stack DM_stack` in the bcf
(skill aiecorestackoverflow). whisperengine/eng/aieml.bcf runs a 2 KB stack.
