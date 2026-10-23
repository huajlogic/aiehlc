###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""TVM BYOC backend behind ``deploy_flow --aie-offload``: partition selected
layers of the int8 graph onto the aiehlc AIE library.

Four files, matching the four things BYOC requires, plus a checker:

    aie_patterns.py     pattern table   the FUSED qconv the AIE kernel computes,
                                        and ``extract_fused`` naming its constants
    aie_annotate.py     annotation      offload the convs selected by weight
                                        fingerprint (not position)
    aie_codegen.py      codegen         wrapper C: uint8 shift, folded qparams,
                                        layouts -> conv2d_stem_prepadded()
    aie_byoc.py         entry point     ``partition_for_aie(mod, params, convs=...)``
    verify_aie_stem.py  bit-exact check vs TVM (subgraph and whole network)

Design: ``doc/design/aie_offload_byoc.md``.
"""
