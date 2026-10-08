---
name: setup-nounset
description: Fix "XILINX_VITIS: unbound variable" when script/setup.sh is sourced under set -u, including the simulator tutorial GitHub Action. Use when setup.sh or Vitis settings64.sh aborts on an unset XILINX_VITIS, PYTHONPATH, MATLABPATH, or PETALINUX.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Sourcing setup.sh under nounset

## Symptom

`.github/workflows/sim-tutorial.yml` (or any `set -u` shell) dies immediately:

```
script/setup.sh: line 121: XILINX_VITIS: unbound variable
```

The next failure, once that probe is fixed, is inside the Vitis install:

```
.settings64-Vitis.sh: line 13: PYTHONPATH: unbound variable
```

`PETALINUX` fails the same way a few lines later.

## Root cause

The self-hosted runner does not export `XILINX_VITIS`. `setup.sh` is supposed to
source `VITIS_SETTINGS_PATH` in that case. `set -u` aborts on the probe
`[ -n "$XILINX_VITIS" ]` before the fallback runs.

Vitis `settings64.sh` uses the same pattern for `PYTHONPATH` and `MATLABPATH`.
That file is not ours; nounset has to be off while it is sourced.

## Rule

Optional environment probes in `script/setup.sh` use `${VAR:-}`. Around
`source "$VITIS_SETTINGS_PATH"`, save `$-`, `set +u`, source, then restore
`set -u` only if it was already on. Do not leave nounset disabled for the
rest of the caller.
