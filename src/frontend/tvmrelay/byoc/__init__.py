###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""TVM BYOC backend: partition the qconv subgraphs of a quantized graph onto AIE.

Four files, matching the four things BYOC requires:

    aie_patterns.py   pattern table   which subgraphs an AIE kernel can take
    aie_annotate.py   annotation pass offload only the first N ("get the first
                                      5 layers working first")
    aie_codegen.py    codegen + runtime  what a subgraph compiles into
    aie_byoc.py       entry point     chains the three above in the correct
                                      order + TVM's merge/partition

Merging, partitioning, and host-side compilation/execution are TVM's job. The
entry point is ``aie_byoc.partition_for_aie(mod, params, n=5)``.
"""
