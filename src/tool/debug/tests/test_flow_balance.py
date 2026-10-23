###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""compute_flow_balance: the static supply/demand check behind the red tiles
and the warning badge in the debug UI's tile grid."""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import schedule_view as sv  # noqa: E402


def _flow(shim_len, core_lens, idx=0):
    entries = [{"tile_col": 0, "tile_row": 0, "io_direction": "MM2S",
                "channel": 0, "bd_len": shim_len}]
    entries += [{"tile_col": 0, "tile_row": 3 + i, "io_direction": "S2MM",
                 "channel": 1, "bd_len": n} for i, n in enumerate(core_lens)]
    return {"flow_index": idx, "direction": "input", "entries": entries}


def test_replicating_broadcast_is_balanced():
    # ColBC filter window: the same 3136 B to every core in the column.
    (b,) = sv.compute_flow_balance([_flow(3136, [3136] * 4)])
    assert b["pattern"] == "broadcast"
    assert b["balanced"] is True
    assert b["demand_per_round"] == 3136


def test_splitting_scatter_is_balanced():
    (b,) = sv.compute_flow_balance([_flow(18544, [4636] * 4)])
    assert b["pattern"] == "scatter"
    assert b["balanced"] is True


def test_real_mismatch_still_flagged():
    # Neither replicate (each read != supply) nor split (sum != supply).
    (b,) = sv.compute_flow_balance([_flow(3136, [3136, 3136, 1000, 3136])])
    assert b["balanced"] is False


if __name__ == "__main__":
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            fn()
            print("PASS", name)
