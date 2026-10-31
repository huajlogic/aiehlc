###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""``ag.offload_interface``: what a kernel file must look like to take a layer.

    ag.offload_interface()                    # the kernel-file format, no model needed
    emod.offload_interface("layer1")          # TVM layer 1: its exact interface
    emod.offload_interface(region="conv1")    # the layer behind an ONNX region
    itf.write("my_kernels/")                  # <entry>.cc + <entry>_ref.c templates

A layer's interface is read from the deployed graph (``aiekernel.graph``): its
arguments in TVM call order, each with kind / dtype / shape, the role the
layer's own generated C gives every constant (``network_md.param_role``), and
facts about the constant values over every call of the layer. From that it
writes the ``AIEK_SPEC`` a kernel needs, and PROVES it: the spec is parsed with
the real grammar (``aiekernel.spec``) and matched against every call of the
layer with ``aiekernel.match`` -- the same checks ``detect`` / ``offload_check``
run -- so a kernel built on this interface is not refused at the signature.
Contract: ``include/aie_user_kernel.h``; walkthrough: ``doc/tutorial_userkernel.md``.
"""

from __future__ import annotations

import re
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from . import _env
from .errors import AiegraphError

__all__ = ["OffloadInterface", "InterfaceArg", "KernelFormat", "Interfaces", "layer_interface"]

_C_TYPE = {"int8": "int8_t", "int16": "int16_t", "int32": "int32_t", "int64": "int64_t",
           "uint8": "uint8_t", "uint16": "uint16_t", "uint32": "uint32_t", "uint64": "uint64_t",
           "float16": "uint16_t", "float32": "float", "float64": "double"}

_FORMAT = """\
AIE user-kernel file format  (contract: include/aie_user_kernel.h)

A kernel that replaces a network layer is ONE aiehlc source file (library mode:
no main()) holding four things, in this order:

  1. the AIE kernel and its mesh launch, exactly like any aiehlc app
     (example: src/aietensorop/conv2dstem/conv2dstem.cc, conv2dstem_uk.cc);
  2. #include "aie_user_kernel.h"  -- AFTER the kernel (nothing that reaches the
     launch may be declared above it);
  3. the entry, fixed signature:
         AIEK_ENTRY(my_kernel) { ... return AIEK_OK; }
     = extern "C" int my_kernel(const aiek_tensor *args, int num_args)
     args[] are the layer's tensors in TVM call order: every input as the graph
     passes it (activations `in` and constants `param`, interleaved), then every
     output `out`. aiek_tensor: data, ndim, code/bits/lanes (dtype), shape, nbytes.
     Read them with AIEK_PTR(&args[i], const int8_t) etc.; return AIEK_OK, or
     AIEK_ERR_PARAM / AIEK_ERR_ALLOC / AIEK_ERR_KERNEL;
  4. the signature as data:
         AIEK_SPEC(my_kernel,
             "kernel    my_kernel\\n"
             "op        conv2d\\n"
             "match     contrib_conv2d_NCHWc\\n"      every match must be in the TVM symbol
             "reference my_kernel_ref.c\\n"           optional x86 reference, next file
             "in    int8  [1,1,230,230,3]  ifm\\n"     one line per argument, call order
             "param int8  [16,1,7,7,3,4]   weight\\n"
             "param int32 [1,16,1,1,4]     zero_point  require=zero\\n"
             "out   uint8 [1,16,112,112,4] output  tol=0\\n");
     dims: integer, `*`, or a NAME that must agree everywhere it appears;
     require=zero|nonzero|uniform|nonneg|range(lo,hi) checks a param's values,
     tol=N bounds |reference - TVM| on an output.

Optional second file, plain C for x86, the bit-exact reference of the same op:
     #include "aie_user_kernel.h"
     AIEK_REFERENCE(my_kernel) { ... }          defines my_kernel_ref()
offload_check diffs it against TVM's kernel on every matched layer, then swaps
it into the whole network on x86 and compares the logits.

Rules (each breaks the aiehlc frontend SILENTLY; `ag.lint(file)` checks them):
  - the aiehlc kernel keyword and the triple-angle launch token never in a
    comment or a string;
  - helpers the kernel body calls are #define macros in the .cc itself.
You do NOT write the TVM packed-call function: offload generates one adapter
per replaced layer that binds TVM's tensors, re-checks dtype/shape and calls
your entry.

Gates (all on x86, none on a board): lint -> detect (the spec vs every layer)
-> calibrate (reference vs TVM) -> emulate (whole network) -> build -> link.

The exact interface of a layer:  emod.offload_interface("layer1")
                                 emod.offload_interface(region="conv1")
"""


class KernelFormat(str):
    """The general file format (``ag.offload_interface()``); prints as text."""

    def __repr__(self) -> str:
        return str(self)


@dataclass
class InterfaceArg:
    index: int
    kind: str              # in | param | out
    dtype: str
    shape: tuple
    name: str
    role: str
    facts: str = ""        # value summary of a param over every call
    requires: tuple = ()   # suggested require= keys

    @property
    def ctype(self) -> str:
        return _C_TYPE.get(self.dtype, "uint8_t")

    def spec_line(self) -> str:
        shape = "[" + ",".join(str(d) for d in self.shape) + "]"
        keys = " ".join(f"require={r}" for r in self.requires)
        return f"{self.kind:<5} {self.dtype:<6} {shape:<22} {self.name}" + (f"  {keys}" if keys else "")


@dataclass
class OffloadInterface:
    """One layer's kernel interface: signature, roles, spec, templates."""

    layer: int
    symbol: str
    dir: str
    calls: list
    label: str
    entry: str
    op: str
    match: str
    args: list = field(default_factory=list)
    regions: list = field(default_factory=list)
    verified: str = ""
    also_fits: list = field(default_factory=list)

    # ── the spec and the templates ──────────────────────────────────────

    def spec_text(self) -> str:
        lines = [f"kernel    {self.entry}", f"op        {self.op}", f"match     {self.match}",
                 f"reference {self.entry}_ref.c"] + [a.spec_line() for a in self.args]
        return "\n".join(lines) + "\n"

    def spec(self) -> str:
        """The ``AIEK_SPEC(...)`` C text, ready to paste."""
        body = "\n".join(f'    "{line}\\n"' for line in self.spec_text().splitlines())
        return f"AIEK_SPEC({self.entry},\n{body});\n"

    def _pointers(self, const_out: bool) -> str:
        out = []
        for a in self.args:
            qual = "" if (a.kind == "out" and not const_out) else "const "
            dims = ",".join(map(str, a.shape))
            var = re.sub(r"\W", "_", a.name)
            out.append(f"    {qual}{a.ctype} *{var} = AIEK_PTR(&args[{a.index}], {qual}{a.ctype}); "
                       f"// {a.kind} {a.dtype}[{dims}] {a.role}")
        return "\n".join(out)

    def kernel_template(self) -> str:
        """``<entry>.cc``: the host entry + spec; the AIE kernel and launch are yours."""
        names = ", ".join(re.sub(r"\W", "_", a.name) for a in self.args)
        return f"""\
// {self.entry}.cc -- AIE user kernel for layer {self.layer} ({self.label})
// TVM symbol: {self.symbol}
// Interface generated by aiegraph.offload_interface; contract: include/aie_user_kernel.h
//
// 1. Define the AIE kernel and its mesh launch ABOVE the include below, as in
//    src/aietensorop/conv2dstem/conv2dstem.cc (library mode: no main()).
// 2. Fill the entry: stage args[] into the layout the kernel's DMA reads, run
//    the launch, write the outputs.
// 3. Prove it on x86:  emod.offload_check("layer{self.layer}", "{self.entry}.cc")

#include "aie_user_kernel.h"

AIEK_ENTRY({self.entry}) {{
    (void)num_args; // the generated adapter already checked count, dtypes and shapes
{self._pointers(const_out=False)}
    (void){names.replace(", ", "; (void)")};
    // TODO: stage the inputs, run the AIE launch, write the outputs.
    return AIEK_ERR_KERNEL; // until implemented: the adapter reports it, nothing is computed silently
}}

{self.spec()}"""

    def reference_template(self) -> str:
        """``<entry>_ref.c``: the x86 reference offload_check calibrates against TVM."""
        names = ", ".join(re.sub(r"\W", "_", a.name) for a in self.args)
        return f"""\
// {self.entry}_ref.c -- x86 reference of layer {self.layer} ({self.label}), plain C.
// Must give TVM's results bit for bit (or within the spec's tol= on an output).
#include "aie_user_kernel.h"

AIEK_REFERENCE({self.entry}) {{
    (void)num_args;
{self._pointers(const_out=False)}
    (void){names.replace(", ", "; (void)")};
    // TODO: the op, element by element.
    return AIEK_ERR_KERNEL;
}}
"""

    def write(self, out_dir) -> list:
        """Write ``<entry>.cc`` and ``<entry>_ref.c`` into *out_dir*; refuse to overwrite."""
        out = Path(out_dir)
        out.mkdir(parents=True, exist_ok=True)
        files = {out / f"{self.entry}.cc": self.kernel_template(),
                 out / f"{self.entry}_ref.c": self.reference_template()}
        exist = [str(p) for p in files if p.exists()]
        if exist:
            raise AiegraphError("offload_interface", f"{', '.join(exist)} already exist(s)",
                                hint="pick another directory or entry= name")
        for p, text in files.items():
            p.write_text(text)
        print(f"[aiegraph] wrote {', '.join(str(p) for p in files)}")
        return list(files)

    def __repr__(self) -> str:
        w = max(len(a.name) for a in self.args)
        calls = ", ".join(f"[{c:02d}]" for c in self.calls)
        lines = [f"Offload interface of layer{self.layer}: {self.label}  (calls {calls})",
                 f"  TVM symbol: {self.symbol}"]
        if self.regions:
            lines.append(f"  regions:    {', '.join(self.regions)}")
        lines += ["", f"  entry: AIEK_ENTRY({self.entry})  ->  "
                      f"int {self.entry}(const aiek_tensor *args, int num_args)",
                  f"  args[] in TVM call order ({len(self.args)}):"]
        for a in self.args:
            shape = f"{a.dtype}[{','.join(map(str, a.shape))}]"
            lines.append(f"    args[{a.index}]  {a.kind:<5} {shape:<24} {a.name:<{w}}  {a.role}"
                         + (f"  -- {a.facts}" if a.facts else ""))
        lines += ["", "  AIEK_SPEC (paste into the kernel file):"]
        lines += ["    " + l for l in self.spec().splitlines()]
        lines += ["", f"  verified: {self.verified}"]
        if self.also_fits:
            lines.append(f"  the same interface also fits: {', '.join(f'layer{l}' for l in self.also_fits)}")
        lines += ["  templates: itf.write('dir/')  ->  "
                  f"{self.entry}.cc (entry + spec) and {self.entry}_ref.c (x86 reference)",
                  "  format and rules: print(ag.offload_interface())"]
        return "\n".join(lines)


class Interfaces(list):
    """Several layers' interfaces (a multi-layer reference); prints each."""

    def __repr__(self) -> str:
        return "\n\n".join(repr(i) for i in self)


# ── building one ─────────────────────────────────────────────────────────

_ROLE_NAME = {"weight": "weight", "bias": "bias", "zero-point": "zero_point",
              "requant multiplier": "requant_mult", "requant shift": "requant_shift",
              "unused": "unused", "param": "param"}


def _roles(net, layer: int, symbol: str) -> dict:
    """{slot: role} for the constants, from the layer's generated C (network_md)."""
    try:
        from frontend.tvmrelay.network_md import kernel_param_usage, param_role
        src = net.layer_source(layer)
        if src is None:
            return {}
        usage = kernel_param_usage(src.read_text(errors="replace"), symbol)
        return {slot: param_role(u) for slot, u in usage.items()}
    except Exception:  # roles are a courtesy; the spec does not depend on them
        return {}


def _facts(net, calls, slot) -> tuple:
    """(summary, suggested requires) for a param over every call of the layer."""
    import numpy as np

    lo = hi = None
    zero = uniform = True
    for c in calls:
        a = c.args[slot]
        v = net.param_array(a.param, a.dtype, a.shape).astype(np.int64 if a.dtype[0] in "iu" else np.float64)
        if v.size == 0:
            continue
        lo = v.min() if lo is None else min(lo, v.min())
        hi = v.max() if hi is None else max(hi, v.max())
        zero &= not v.any()
        uniform &= bool((v == v.flat[0]).all())
    if lo is None:
        return "", ()
    if zero:
        return "all zero", ("zero",)
    fmt = (lambda x: f"{int(x)}") if float(lo).is_integer() and float(hi).is_integer() else (lambda x: f"{x:g}")
    per = "per call" if len(calls) > 1 else ""
    if uniform:
        return f"uniform {fmt(lo)}" + (f" ({per})" if per else ""), ()
    return f"values in [{fmt(lo)}, {fmt(hi)}]", ()


def _op(symbol: str) -> str:
    for key in ("conv2d", "dense", "matmul", "pool", "add", "softmax"):
        if key in symbol:
            return key
    return "op"


def _match(symbol: str) -> str:
    """The symbol minus TVM's prefix and content hash: shared by every layer of
    the same fused pattern, so one kernel can serve all of them."""
    s = re.sub(r"^tvmgen_default_fused_", "", symbol)
    s = re.sub(r"_[0-9a-f]{16}_*(\d+)?_*$", "", s)
    return re.sub(r"_\d+$", "", s) or symbol


def _verify(itf: OffloadInterface, net) -> None:
    """Parse the spec with the real grammar and match it against every call."""
    from frontend.tvmrelay.aiekernel.match import detect_layers, match_call
    from frontend.tvmrelay.aiekernel.spec import load_source, parse_specs
    with tempfile.TemporaryDirectory() as tmp:
        p = Path(tmp) / f"{itf.entry}.cc"
        p.write_text('#include "aie_user_kernel.h"\n' + itf.spec())
        (Path(tmp) / f"{itf.entry}_ref.c").write_text("")
        spec = parse_specs(load_source(p))[0]
        calls = [c for c in net.calls if c.call in itf.calls]
        bad = [v for v in (match_call(spec, c, net) for c in calls) if not v.ok]
        if bad:
            raise AiegraphError("offload_interface",
                                f"layer{itf.layer}: the generated spec does not match call "
                                f"[{bad[0].call.call:02d}]: {bad[0].reasons[0]}",
                                hint="report this: the interface generator and aiekernel disagree")
        itf.verified = (f"AIEK_SPEC parses and matches {len(calls)}/{len(calls)} call(s) of "
                        f"layer{itf.layer} (aiekernel.match, value checks included)")
        itf.also_fits = [v.layer for v in detect_layers(spec, net)
                         if v.layer != itf.layer and all(c.ok for c in v.calls)]


def layer_interface(net, layer: int, entry: str = None, regions=()) -> OffloadInterface:
    """The interface of manifest layer *layer* of *net* (an ``aiekernel.graph.Network``)."""
    calls = net.layers().get(layer)
    if not calls:
        raise AiegraphError("offload_interface", f"layer{layer} has no kernel call")
    c0 = calls[0]
    for c in calls[1:]:
        if [(a.kind, a.dtype, tuple(a.shape)) for a in c.args] != \
                [(a.kind, a.dtype, tuple(a.shape)) for a in c0.args]:
            raise AiegraphError("offload_interface", f"layer{layer}: calls disagree on the signature")
    roles = _roles(net, layer, c0.symbol)
    args, seen = [], {}
    n_in = sum(1 for a in c0.args if a.kind == "in")
    n_out = sum(1 for a in c0.args if a.kind == "out")
    k_in = k_out = 0
    for a in c0.args:
        facts, req = "", ()
        if a.kind == "param":
            role = roles.get(a.slot, "param")
            facts, req = _facts(net, calls, a.slot)
            name = _ROLE_NAME.get(role, "param")
            if name == "param":
                name = f"p{a.slot}"
        elif a.kind == "in":
            k_in += 1
            role = "activation" if k_in == 1 else "activation (residual / second input)"
            name = "ifm" if n_in == 1 else f"ifm{k_in - 1}"
        else:
            k_out += 1
            role = "output"
            name = "ofm" if n_out == 1 else f"ofm{k_out - 1}"
        seen[name] = seen.get(name, 0) + 1
        if seen[name] > 1:
            name = f"{name}{seen[name]}"
        args.append(InterfaceArg(a.slot, a.kind, a.dtype, tuple(int(d) for d in a.shape),
                                 name, role, facts, req))
    from .embedded import _label
    itf = OffloadInterface(layer=layer, symbol=c0.symbol, dir=c0.dir, calls=[c.call for c in calls],
                           label=_label(c0), entry=entry or f"aiek_layer{layer:02d}", op=_op(c0.symbol),
                           match=_match(c0.symbol), args=args, regions=list(regions))
    _verify(itf, net)
    return itf


def kernel_format() -> KernelFormat:
    return KernelFormat(_FORMAT)


def interface_for(emod, layer=None, region=None, entry: str = None):
    """``emod.offload_interface``: one layer -> OffloadInterface, several -> Interfaces."""
    if layer is None and region is None:
        return kernel_format()
    _env.frontend("")
    net = emod._network()
    if region is not None:
        regs = emod.regions.find(region)
        layers = sorted({r.layer for r in regs if r.layer is not None})
        if not layers:
            raise AiegraphError("offload_interface", f"region {region!r} is not mapped to a TVM layer")
    else:
        layers = emod.resolve(layer)
    by_layer = {}
    if region is not None or emod.model is not None:
        try:
            for r in emod.regions:
                by_layer.setdefault(r.layer, []).append(r.label)
        except Exception:
            pass
    out = Interfaces(layer_interface(net, l, entry if len(layers) == 1 else None, by_layer.get(l, ()))
                     for l in layers)
    return out[0] if len(out) == 1 else out
