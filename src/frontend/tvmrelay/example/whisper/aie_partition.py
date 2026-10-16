###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""AIE-first partition of a Whisper Relay graph: every layer is an AIE layer.

TVM's ``FuseOps`` groups operators for a CPU (a dense with its bias pushed into
the *next* kernel, layer norm as three reductions). Here the AIE op set decides
the boundaries instead. Each **anchor** -- an op that does real work --
starts a group, and the group then absorbs what the AIE can do for free:

======================  ===================================================
anchor                  absorbs
======================  ===================================================
``nn.dense``            input reshape chain; ``+bias`` (rank-1), GELU,
                        output reshape/transpose chain (head split)
``nn.batch_matmul``     input chains; output chain (head merge)
``nn.conv1d``           ``bias_add`` + GELU + output transpose
``mean`` (layer norm)   ``variance``/``subtract``/``rsqrt``/scale/shift
``nn.softmax``          an additive mask on its input; output reshape
``add`` (two tensors)   input chains (residual, positional embedding)
``take``                index normalization (``less/add/where``), ``+pos``
======================  ===================================================

Layout ops (``reshape``/``transpose``) never become layers of their own: a
group pulls a chain on its *inputs* when the chain has no other consumer, and
on its *output* when nothing else reads the intermediate. On the host they turn
into the strided staging copy that has to happen anyway (TVM's tensors are not
DMA buffers); on silicon they are BD address patterns.

The groups are then cut out as Relay functions with ``Compiler="aie_whisper"``
-- exactly what ``PartitionGraph`` produces -- so ``relay.build`` hands each to
``relay.ext.aie_whisper`` (``aie_codegen_whisper``) and compiles whatever is
left for the CPU. ``check_all_offloaded`` then requires that "whatever is left"
is nothing but metadata reshapes.

Each group also yields an ``AieLayer`` descriptor (op, shapes, per-port strided
views) -- the single description both the aiehlc app generator and the C
wrapper are produced from.
"""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

COMPILER = "aie_whisper"
LAYOUT_OPS = ("reshape", "transpose")


def _op(e):
    from tvm import relay
    return getattr(e.op, "name", None) if isinstance(e, relay.Call) else None


def _shape(e):
    return tuple(int(d) for d in e.checked_type.shape)


@dataclass
class PortView:
    """How a logical operand reads (or a result writes) a graph tensor.

    ``shape``/``strides`` describe a strided view over the row-major flat
    buffer of graph tensor ``arg`` (an argument index of the AIE function, or
    ``-1`` for the function's output). Iterating ``shape`` in row-major order
    visits the logical operand in its natural order.
    """
    arg: int
    shape: tuple
    strides: tuple
    scatter: bool = False   # output only: shape/strides index the GRAPH output


@dataclass
class AieLayer:
    symbol: str
    op: str                      # dense | bmm | conv1d | layernorm | softmax | add | embed
    graph: str                   # encoder | decoder
    index: int
    relay_ops: list = field(default_factory=list)
    arg_shapes: list = field(default_factory=list)   # per function argument
    arg_dtypes: list = field(default_factory=list)
    arg_roles: list = field(default_factory=list)    # act | weight | bias | gamma | beta | mask | table | tokens
    out_shape: tuple = ()
    # GEMM: C[b] = epi(A[b] @ B[b]^T + bias)
    batch: int = 1
    M: int = 0
    N: int = 0
    K: int = 0
    gelu: bool = False
    bias_arg: int = -1
    a_view: PortView | None = None   # logical [batch?, M, K]
    b_view: PortView | None = None   # logical [batch?, N, K]
    conv: dict | None = None         # {cin, t_in, t_out, stride, pad, ksize}
    # row map: [rows, cols]
    rows: int = 0
    cols: int = 0
    row_views: list = field(default_factory=list)   # logical [*, cols] views, rowmap inputs
    params: list = field(default_factory=list)      # broadcast operand args (gamma, beta)
    eps: float = 0.0
    # output: graph output (row-major) = view over the logical result
    out_view: PortView | None = None
    lib: dict | None = None          # filled by aie_kernels_whisper.plan_library

    def describe(self) -> str:
        if self.op in ("dense", "bmm", "conv1d"):
            b = f"{self.batch}x" if self.batch > 1 else ""
            return (f"{self.op}{'+gelu' if self.gelu else ''}"
                    f"{'+bias' if self.bias_arg >= 0 else ''} {b}[{self.M}x{self.K}]·[{self.N}x{self.K}]^T")
        return f"{self.op} [{self.rows}x{self.cols}]"


# ═══════════════════════════════════════════════════════════════════════════
#  Strided views
# ═══════════════════════════════════════════════════════════════════════════

def _apply_chain(arr, chain):
    """Apply a list of Relay layout calls (reshape/transpose) to a numpy view."""
    for call in chain:
        if _op(call) == "transpose":
            axes = call.attrs.axes
            arr = np.transpose(arr, None if axes is None else [int(a) for a in axes])
        else:
            arr = arr.reshape(_shape(call))
    return arr


def _view_of(arr, base, arg: int) -> PortView:
    """``arr`` must be a view of ``base`` (an ``arange``); fail closed otherwise."""
    if arr.size and not np.shares_memory(arr, base):
        raise ValueError("layout chain is not a strided view (numpy had to copy)")
    item = base.itemsize
    off = (arr.__array_interface__["data"][0] - base.__array_interface__["data"][0]) // item
    if off != 0:
        raise ValueError("layout chain produced a non-zero view offset")
    return PortView(arg, tuple(int(s) for s in arr.shape),
                    tuple(int(s) // item for s in arr.strides))


def input_view(src_shape, chain, logical_shape, arg: int) -> PortView:
    """View of graph tensor ``src_shape`` that yields ``logical_shape`` after ``chain``.

    A final ``broadcast_to`` covers operands that broadcast against the anchor
    (an attention mask shared by the heads, a bias-like positional table).
    """
    base = np.arange(int(np.prod(src_shape)), dtype=np.int64).reshape(src_shape)
    arr = _apply_chain(base, chain)
    if tuple(arr.shape) != tuple(logical_shape):
        arr = np.broadcast_to(arr, logical_shape)
    return _view_of(arr, base, arg)


def output_view(logical_shape, chain, prefix=()) -> PortView:
    """How the logical result lands in the graph output.

    Preferred form is a *gather* (``scatter=False``): a view over the logical
    result that, read row-major, is the graph output. A head merge
    (``[6,T,64] -> transpose -> [T,384]``) has no such view -- the transpose
    makes the merged dim non-uniformly strided -- but its inverse does, so the
    fallback is a *scatter*: a view over the graph output that, read row-major,
    is the logical result. ``prefix`` is a list of ``(forward, inverse)`` numpy
    functions applied before ``chain`` (the conv1d ``[t,co] -> [1,co,t]`` flip).
    """
    base = np.arange(int(np.prod(logical_shape)), dtype=np.int64).reshape(logical_shape)
    arr = base
    for fwd, _ in prefix:
        arr = fwd(arr)
    arr = _apply_chain(arr, chain)
    try:
        return _view_of(arr, base, -1)
    except ValueError:
        pass
    out_shape = arr.shape
    rbase = np.arange(int(np.prod(out_shape)), dtype=np.int64).reshape(out_shape)
    inv = rbase
    for call in reversed(chain):
        if _op(call) == "transpose":
            axes = call.attrs.axes
            axes = list(range(inv.ndim))[::-1] if axes is None else [int(a) for a in axes]
            inv = np.transpose(inv, np.argsort(axes))
        else:
            inv = inv.reshape(_shape(call.args[0]))
    for _, bwd in reversed(prefix):
        inv = bwd(inv)
    if tuple(inv.shape) != tuple(logical_shape):
        raise ValueError(f"inverse chain gives {inv.shape}, want {logical_shape}")
    v = _view_of(inv, rbase, -1)
    v.scatter = True
    return v


# ═══════════════════════════════════════════════════════════════════════════
#  Grouping
# ═══════════════════════════════════════════════════════════════════════════

class _Graph:
    """Post-order node list + consumer map over ``main``'s body."""

    def __init__(self, func):
        from tvm import relay
        self.order = []
        self.consumers = {}
        self.params = {p: i for i, p in enumerate(func.params)}

        def visit(e):
            self.order.append(e)
            if isinstance(e, relay.Call):
                for a in e.args:
                    self.consumers.setdefault(a, []).append(e)
        relay.analysis.post_order_visit(func.body, visit)
        self.root = func.body

    def cons(self, e):
        return self.consumers.get(e, [])

    def single(self, e):
        c = self.cons(e)
        return c[0] if len(c) == 1 and e is not self.root and not e.same_as(self.root) else None


def _is_scalar_const(e):
    from tvm import relay
    return isinstance(e, relay.Constant) and e.data.numpy().size <= 1


def _is_weight(g, e):
    """A lifted weight: a ``wsp_p*`` graph input."""
    from tvm import relay
    return isinstance(e, relay.Var) and e.name_hint.startswith("wsp_p")


class _Group:
    def __init__(self, anchor):
        self.anchor = anchor
        self.members = [anchor]
        self.root = anchor
        self.extra = {}

    def has(self, e):
        return any(m.same_as(e) for m in self.members)


def _absorb_gelu(g, grp, v):
    """``v -> 0.5 * v * (1 + erf(v / sqrt2))``: the diamond TVM imports GELU as."""
    cs = g.cons(v)
    if len(cs) != 2:
        return None
    div = next((c for c in cs if _op(c) == "divide"), None)
    mul = next((c for c in cs if _op(c) == "multiply"), None)
    if div is None or mul is None or not _is_scalar_const(div.args[1]):
        return None
    erf = g.single(div)
    add = g.single(erf) if erf is not None and _op(erf) == "erf" else None
    if add is None or _op(add) != "add" or g.single(add) is None or not g.single(add).same_as(mul):
        return None
    half = g.single(mul)
    if half is None or _op(half) != "multiply" or not _is_scalar_const(half.args[1]):
        return None
    grp.members += [div, erf, add, mul, half]
    return half


def _absorb_layout_out(g, grp, v, allow_bias=False, allow_gelu=False):
    """Walk forward from ``v`` absorbing layout ops (+bias, +GELU). Returns the root."""
    while True:
        c = g.single(v)
        if c is None:
            # GELU fans out twice from its input, so it is checked before giving up.
            if allow_gelu and not grp.extra.get("gelu"):
                h = _absorb_gelu(g, grp, v)
                if h is not None:
                    grp.extra["gelu"] = True
                    v = h
                    continue
            return v
        name = _op(c)
        if name in LAYOUT_OPS:
            grp.members.append(c)
            grp.extra.setdefault("out_chain", []).append(c)
            v = c
            continue
        if allow_bias and name == "add" and "bias" not in grp.extra and not grp.extra.get("gelu"):
            other = c.args[0] if c.args[1].same_as(v) else c.args[1]
            if _is_weight(g, other) and len(_shape(other)) == 1 and _shape(other)[0] == _shape(v)[-1]:
                grp.members.append(c)
                grp.extra["bias"] = other
                v = c
                continue
        return v


def _absorb_layout_in(g, grp, e):
    """Pull the layout chain producing ``e`` into the group. Returns ``(src, chain)``."""
    chain = []
    while _op(e) in LAYOUT_OPS and len(g.cons(e)) == 1:
        grp.members.append(e)
        chain.insert(0, e)
        e = e.args[0]
    return e, chain


def _layernorm(g, mean):
    """Match the decomposed layer norm rooted at ``mean``; None if it is not one."""
    x = mean.args[0]
    cs = g.cons(mean)
    var = next((c for c in cs if _op(c) == "variance"), None)
    sub = next((c for c in cs if _op(c) == "subtract"), None)
    if var is None or sub is None or len(cs) != 2:
        return None
    add_eps = g.single(var)
    rs = g.single(add_eps) if add_eps is not None else None
    if _op(add_eps) != "add" or _op(rs) != "rsqrt":
        return None
    mul = g.single(sub)
    if mul is None or _op(mul) != "multiply" or g.single(rs) is None or not g.single(rs).same_as(mul):
        return None
    mg = g.single(mul)
    ab = g.single(mg) if mg is not None else None
    if _op(mg) != "multiply" or _op(ab) != "add":
        return None
    grp = _Group(mean)
    grp.members += [var, add_eps, sub, rs, mul, mg, ab]
    grp.root = ab
    grp.extra.update(x=x, eps=float(add_eps.args[1].data.numpy()),
                     gamma=mg.args[1], beta=ab.args[1])
    return grp


def find_groups(func):
    """All AIE groups of ``main``, anchors in topological order."""
    g = _Graph(func)
    taken = set()
    groups = []

    def free(e):
        return not any(e.same_as(t) for t in taken)

    for e in g.order:
        name = _op(e)
        if name is None or not free(e):
            continue
        grp = None
        if name == "mean":
            grp = _layernorm(g, e)
        elif name in ("nn.dense", "nn.batch_matmul"):
            grp = _Group(e)
            grp.root = _absorb_layout_out(g, grp, e, allow_bias=(name == "nn.dense"),
                                          allow_gelu=(name == "nn.dense"))
        elif name == "nn.conv1d":
            grp = _Group(e)
            ba = g.single(e)
            if ba is not None and _op(ba) == "nn.bias_add":
                grp.members.append(ba)
                grp.extra["bias"] = ba.args[1]
                v = ba
                h = _absorb_gelu(g, grp, v)
                if h is not None:
                    grp.extra["gelu"] = True
                    v = h
                grp.root = _absorb_layout_out(g, grp, v)
        elif name == "nn.softmax":
            grp = _Group(e)
            x = e.args[0]
            # absorb a reshape between an additive mask and the softmax
            if _op(x) == "add" and len(g.cons(x)) == 1 and _is_weight(g, x.args[1]):
                grp.members.append(x)
                grp.extra["mask"] = x.args[1]
            grp.root = _absorb_layout_out(g, grp, e)
        elif name == "take":
            grp = _Group(e)
            idx = e.args[1]
            if _op(idx) == "where":            # negative-index normalization
                grp.members += [idx, idx.args[0], idx.args[1]]
            add = g.single(e)
            if add is not None and _op(add) == "add" and _is_weight(g, add.args[1]):
                grp.members.append(add)
                grp.extra["pos"] = add.args[1]
                grp.root = add
        elif name == "add" and not any(_is_scalar_const(a) for a in e.args) \
                and _op(g.single(e)) != "nn.softmax" \
                and not (_is_weight(g, e.args[0]) and len(_shape(e.args[0])) == 1) \
                and not (_is_weight(g, e.args[1]) and len(_shape(e.args[1])) == 1):
            # two full tensors: residual join or positional embedding
            grp = _Group(e)
            grp.root = _absorb_layout_out(g, grp, e)
        if grp is not None:
            groups.append(grp)
            taken.update(grp.members)
    # Pull input layout chains in a second pass, once every group owns its body:
    # a chain a group absorbed forward must not be re-absorbed backward.
    for grp in groups:
        grp.in_chains = {}
        for m in list(grp.members):
            for a in getattr(m, "args", []):
                if _op(a) in LAYOUT_OPS and free(a) and len(g.cons(a)) == 1:
                    src, chain = _absorb_layout_in(g, grp, a)
                    taken.update(chain)
                    grp.in_chains[a] = (src, chain)
    return g, groups


# ═══════════════════════════════════════════════════════════════════════════
#  Group -> Relay function + AieLayer
# ═══════════════════════════════════════════════════════════════════════════

def _externals(grp):
    """Function arguments, in first-use order: everything a member reads that is
    neither a member nor a scalar constant."""
    from tvm import relay
    ext = []
    for m in grp.members:
        for a in getattr(m, "args", []):
            if grp.has(a) or _is_scalar_const(a):
                continue
            if isinstance(a, relay.Constant):
                raise ValueError(f"non-scalar constant inside an AIE group ({_shape(a)})")
            if not any(a.same_as(x) for x in ext):
                ext.append(a)
    return ext


def _rebuild(grp, ext_vars):
    """The group's subgraph with external inputs replaced by function params."""
    from tvm import relay
    memo = {}

    def rb(e):
        for src, v in ext_vars:
            if e.same_as(src):
                return v
        if not isinstance(e, relay.Call):
            return e
        if e in memo:
            return memo[e]
        out = relay.Call(e.op, [rb(a) for a in e.args], e.attrs, e.type_args, e.span)
        memo[e] = out
        return out
    return rb(grp.root)


def _arg_index(ext, e):
    return next(i for i, x in enumerate(ext) if x.same_as(e))


def _chain_to(grp, operand):
    """``(src, chain)`` for an anchor operand: an absorbed input chain or nothing."""
    for a, (src, chain) in grp.in_chains.items():
        if a.same_as(operand):
            return src, chain
    return operand, []


def describe_group(grp, ext, symbol: str, graph: str, index: int) -> AieLayer:
    a = grp.anchor
    name = _op(a)
    L = AieLayer(symbol=symbol, op="", graph=graph, index=index,
                 relay_ops=[_op(m) for m in grp.members],
                 arg_shapes=[_shape(x) for x in ext],
                 arg_dtypes=[str(x.checked_type.dtype) for x in ext],
                 arg_roles=["act"] * len(ext), out_shape=_shape(grp.root))
    out_chain = grp.extra.get("out_chain", [])
    L.gelu = bool(grp.extra.get("gelu"))
    if "bias" in grp.extra:
        L.bias_arg = _arg_index(ext, grp.extra["bias"])
        L.arg_roles[L.bias_arg] = "bias"

    if name == "nn.dense":
        L.op = "dense"
        x, w = a.args
        (L.M, L.K), L.N = _shape(x), _shape(w)[0]
        src, chain = _chain_to(grp, x)
        L.a_view = input_view(_shape(src), chain, (L.M, L.K), _arg_index(ext, src))
        L.b_view = input_view(_shape(w), [], (L.N, L.K), _arg_index(ext, w))
        L.arg_roles[L.b_view.arg] = "weight"
        L.out_view = output_view((L.M, L.N), out_chain)
    elif name == "nn.batch_matmul":
        L.op = "bmm"
        x, y = a.args
        if not bool(a.attrs.transpose_b) or bool(a.attrs.transpose_a):
            raise ValueError("batch_matmul must be A @ B^T")
        (L.batch, L.M, L.K), L.N = _shape(x), _shape(y)[1]
        sx, cx = _chain_to(grp, x)
        sy, cy = _chain_to(grp, y)
        L.a_view = input_view(_shape(sx), cx, (L.batch, L.M, L.K), _arg_index(ext, sx))
        L.b_view = input_view(_shape(sy), cy, (L.batch, L.N, L.K), _arg_index(ext, sy))
        L.out_view = output_view((L.batch, L.M, L.N), out_chain)
    elif name == "nn.conv1d":
        L.op = "conv1d"
        x, w = a.args
        _, cin, t_in = _shape(x)
        cout, _, ks = _shape(w)
        t_out = _shape(a)[2]
        stride, pad = int(a.attrs.strides[0]), int(a.attrs.padding[0])
        L.conv = dict(cin=cin, t_in=t_in, t_out=t_out, stride=stride, pad=pad, ksize=ks,
                      x_arg=_arg_index(ext, x), w_arg=_arg_index(ext, w))
        L.M, L.N, L.K = t_out, cout, cin * ks
        L.arg_roles[L.conv["w_arg"]] = "weight"
        # GEMM result C[t, co]; the conv's own result is [1, co, t]
        L.out_view = output_view((t_out, cout), out_chain,
                                 prefix=((lambda v: v.T.reshape(1, cout, t_out),
                                          lambda r: r.reshape(cout, t_out).T),))
    elif name == "mean":
        L.op = "layernorm"
        x = grp.extra["x"]
        shp = _shape(x)
        L.cols, L.rows = shp[-1], int(np.prod(shp[:-1]))
        L.eps = grp.extra["eps"]
        L.row_views = [input_view(shp, [], shp, _arg_index(ext, x))]
        L.params = [_arg_index(ext, grp.extra["gamma"]), _arg_index(ext, grp.extra["beta"])]
        L.arg_roles[L.params[0]], L.arg_roles[L.params[1]] = "gamma", "beta"
        L.out_view = output_view(shp, out_chain)
    elif name == "nn.softmax":
        L.op = "softmax"
        if int(a.attrs.axis) not in (-1, len(_shape(a)) - 1):
            raise ValueError("softmax must reduce the last axis")
        shp = _shape(a)
        L.cols, L.rows = shp[-1], int(np.prod(shp[:-1]))
        x = a.args[0]
        if "mask" in grp.extra:
            add = x
            x = add.args[0]
            m = grp.extra["mask"]
            L.arg_roles[_arg_index(ext, m)] = "mask"
        src, chain = _chain_to(grp, x)
        L.row_views = [input_view(_shape(src), chain, shp, _arg_index(ext, src))]
        if "mask" in grp.extra:
            L.op = "softmax_mask"
            L.row_views.append(input_view(_shape(m), [], shp, _arg_index(ext, m)))
        L.out_view = output_view(shp, out_chain)
    elif name == "add":
        L.op = "add"
        shp = _shape(a)
        L.cols, L.rows = shp[-1], int(np.prod(shp[:-1]))
        for opnd in a.args:
            src, chain = _chain_to(grp, opnd)
            L.row_views.append(input_view(_shape(src), chain, shp, _arg_index(ext, src)))
            if src.name_hint.startswith("wsp_p") if hasattr(src, "name_hint") else False:
                L.arg_roles[_arg_index(ext, src)] = "weight"
        L.out_view = output_view(shp, out_chain)
    elif name == "take":
        L.op = "embed"
        table, idx = a.args
        tok = idx
        while _op(tok) is not None:
            tok = tok.args[-1] if _op(tok) == "where" else tok.args[0]
        shp = _shape(grp.root)
        L.cols, L.rows = shp[-1], int(np.prod(shp[:-1]))
        t_arg, k_arg = _arg_index(ext, table), _arg_index(ext, tok)
        L.arg_roles[t_arg], L.arg_roles[k_arg] = "table", "tokens"
        L.conv = dict(table_arg=t_arg, tokens_arg=k_arg, vocab=_shape(table)[0])
        pos = grp.extra["pos"]
        L.row_views = [None, input_view(_shape(pos), [], shp, _arg_index(ext, pos))]
        L.arg_roles[_arg_index(ext, pos)] = "weight"
        L.out_view = output_view(shp, out_chain)
    else:
        raise ValueError(f"no AIE description for anchor {name}")
    return L


def partition(mod, graph: str, verbose: bool = True):
    """Cut every AIE group out of ``mod["main"]``. Returns ``(mod, layers)``."""
    import tvm
    from tvm import relay
    from tvm.relay.expr_functor import ExprMutator

    # Work on a copy: the caller keeps the unpartitioned module as the CPU reference.
    mod = tvm.IRModule(dict(mod.functions.items()), dict(mod.type_definitions.items()))
    func = mod["main"]
    g, groups = find_groups(func)
    layers, replace = [], {}
    for i, grp in enumerate(groups):
        ext = _externals(grp)
        symbol = f"wsp_{graph[:3]}_{i:03d}"
        params = [relay.var(f"{symbol}_a{j}", type_annotation=x.checked_type)
                  for j, x in enumerate(ext)]
        body = _rebuild(grp, list(zip(ext, params)))
        fn = relay.Function(params, body)
        fn = fn.with_attr("Compiler", COMPILER)
        fn = fn.with_attr("global_symbol", symbol)
        fn = fn.with_attr("Primitive", tvm.tir.IntImm("int32", 1))
        fn = fn.with_attr("Inline", tvm.tir.IntImm("int32", 1))
        gv = relay.GlobalVar(symbol)
        mod[gv] = fn
        replace[grp.root] = (gv, ext)
        layers.append(describe_group(grp, ext, symbol, graph, i))

    class Swap(ExprMutator):
        def visit_call(self, call):
            for root, (gv, ext) in replace.items():
                if call.same_as(root):
                    return relay.Call(gv, [self.visit(x) for x in ext])
            return super().visit_call(call)

    mod["main"] = relay.Function(func.params, Swap().visit(func.body), func.ret_type)
    mod = relay.transform.InferType()(mod)
    if verbose:
        from collections import Counter
        c = Counter(L.op for L in layers)
        print(f"  [partition] {graph}: {len(layers)} AIE layers "
              f"({', '.join(f'{k} {v}' for k, v in sorted(c.items()))})")
    return mod, layers


def leftover_ops(mod):
    """Relay ops still in ``main`` after partitioning, i.e. not on the AIE."""
    from collections import Counter

    import tvm
    from tvm import relay
    left = Counter()

    def visit(e):
        if isinstance(e, relay.Call) and isinstance(e.op, tvm.ir.Op):
            left[e.op.name] += 1
    relay.analysis.post_order_visit(mod["main"], visit)
    return left
