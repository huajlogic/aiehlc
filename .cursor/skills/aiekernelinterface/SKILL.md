---
name: aiekernelinterface
description: What a user AIE kernel file must contain to replace a network layer -- `ag.offload_interface()` (the format) and `emod.offload_interface("layer4" | region=...)` / `aiegraph interface layer4 --write dir/` (that layer's args in TVM call order with roles and value facts, a proven AIEK_SPEC, entry + reference templates). Use when starting a kernel for a layer, when detect says the arg count/dtype/shape does not match, or to find which constants must be zero.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Kernel interface of a layer

Code: `src/aiegraph/interface.py`; contract `include/aie_user_kernel.h`;
tutorial `doc/tutorial_aiegraph.md` §4b, `doc/tutorial_userkernel.md` §2.

- `ag.offload_interface()` -- the file format and rules, no model needed.
- `emod.offload_interface("layer4")` -- TVM layer numbering (same as
  `offload_check`); `region="layer1.0.conv1"` for an ONNX region.
- The spec is parsed with `aiekernel.spec` and matched with `aiekernel.match`
  against every call of the layer before it is returned
  (`verified: ... matches N/N call(s)`); a failure there is a generator bug.
- `require=zero` is suggested only for constants zero in EVERY call (the
  stem's second zero-point and unused param). Ranges are informational.
- Roles come from `network_md.param_role` on the layer's TVM C; a slot it
  cannot classify is named `p<slot>`.
- `match` = the TVM symbol minus `tvmgen_default_fused_` and the content hash,
  so layers of the same fused pattern match too; shapes are concrete -- turn
  dims into NAMEs by hand for one kernel over several geometries.
- `write(dir)` refuses to overwrite. The entry template returns
  `AIEK_ERR_KERNEL` until filled, and has no AIE kernel yet: lint reports info
  L010 (reference-only) until the kernel and launch are added above the include.
