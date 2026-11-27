# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Convert a Qwen3.5 text checkpoint (safetensors, bf16) into the qwen engine's weight blob.

Blob layout (little endian; cut in SEG-byte segments, each placed in its own DDR region on the board -- no
tensor crosses a segment boundary, the header records SEG in MiB):
  header   struct qw_header (qwen_blob.h): magic, version, config, tensor count, table offset
  table    struct qw_tensor[n]: name[64], type, rows, cols, offset, bytes
  data     every tensor 64-byte aligned

Types:
  QW_F32    fp32 row-major
  QW_Q4G64  int4 weights in the AIE small-M GEMM layout: groups of 16 rows x 64 K; a group is four 16(K) x 16(N)
            int4 tiles (element (k, n) at k * 16 + n, two per byte, the even one in the low nibble, 512 B) and the
            16 rows' bf16 scales (32 B). 16 consecutive K groups of a row block form a chunk of 8704 B: the 16
            groups' tiles, then their scales. Rows are zero-padded to a multiple of 4096 (the entry's `reserved` field
            holds the padded count) and K is cut in 4096-wide slices, slice-major. A slice's 4096-row launches
            (rows / 4096 of them) are contiguous. A launch is the kernel's w = [256 row blocks][4 k chunks][8704 B]
            (src/APP/qwen/aie/qwen_gemv_kernel.cc), put into the DDR order the dataflow plan's shim BDs read by
            the compiler's own aiehlc_plan_arrange (--plan-header: the aiehlc_plan.h of the qwen_gemv library
            build), so the AIE reads the blob as it is and no order is written down here.
  QW_I32    int32 (lm_perm: lm_head row -> token id, when lm_head's rows are in frequency order)
  QW_Q4R64  int4 rows (the embedding: one row looked up per token): per row, per 64 columns 32 B of nibbles
            (element j of the group in byte j / 2, the even one low) then a bf16 scale.

Symmetric int4 (-8 .. 7); each group's scale is the absmax / 7.5 x f with f picked from a small grid by the
lowest squared error.

Fused matrices (one weight pass on the AIE per group of outputs that share an input):
  la.qkvz = in_proj_qkv ++ in_proj_z    (12288 x 4096, linear-attention layers)
  fa.qkv  = q_proj ++ k_proj ++ v_proj  (10240 x 4096, full-attention layers)
  mlp.gu  = gate_proj ++ up_proj        (24576 x 4096)
"""
import argparse, ctypes, json, os, struct, subprocess, sys, tempfile, time

import numpy as np
import torch
from safetensors import safe_open

QW_MAGIC = 0x35335751  # 'QW35'
QW_VERSION = 7  # 7: launches in the natural-kernel plan order (aiehlc_plan_arrange)
QW_F32, QW_Q4G64, QW_Q4R64, QW_I32 = 1, 2, 3, 4
ALIGN = 64
SLICE_K = 4096   # one AIE launch: 4096 rows x SLICE_K
SEG = 0x7000_0000  # a segment: one DDR region on the board (a loader ELF's chunk); no tensor crosses one
PAD_ROWS = 4096
GRID = torch.tensor([0.80, 0.85, 0.90, 0.95, 1.00, 1.05])


def quant_groups(w):
    """w [R, K] float -> (q int8 [R, K] in -8..7, scale bf16 [R, K/64]) by per-group MSE-best scale."""
    R, K = w.shape
    g = w.float().reshape(R, K // 64, 64)
    amax = g.abs().amax(-1, keepdim=True).clamp_min(1e-12)
    best_err = best_s = None
    for f in GRID:
        s = amax / 7.5 * f
        q = torch.clamp(torch.round(g / s), -8, 7)
        err = ((q * s - g) ** 2).sum(-1, keepdim=True)
        if best_err is None:
            best_err, best_s = err, s
        else:
            m = err < best_err
            best_err = torch.where(m, err, best_err)
            best_s = torch.where(m, s, best_s)
    s16 = best_s.to(torch.bfloat16)  # bf16: the AIE widens it with a 16-bit shift
    sf = s16.float()
    q = torch.where(sf > 0, torch.clamp(torch.round(g / torch.where(sf > 0, sf, 1.0)), -8, 7), 0).to(torch.int8)
    return q.reshape(R, K), s16.reshape(R, K // 64)


def pack_nibbles(q):
    """int8 [..., 2n] (-8..7) -> uint8 [..., n], even element in the low nibble."""
    u = (q.to(torch.int16) & 0xF).to(torch.uint8)
    return u[..., 0::2] | (u[..., 1::2] << 4)


LAUNCH_CHUNKS, CHUNK_BYTES = 1024, 8704  # one AIE launch: 256 row blocks x 4 k chunks
ARRANGE = None  # aiehlc_plan_arrange of the qwen_gemv build (plan_arranger)


def plan_arranger(header):
    """The compiler's aiehlc_plan_arrange(0, ...) from `header`, as bytes -> bytes for one launch. Checked to
    be a permutation of the launch's chunks (every chunk once, none lost)."""
    d = tempfile.mkdtemp(prefix="qw_arrange_")
    stub = os.path.join(d, "arrange.c")
    with open(stub, "w") as f:
        f.write('#include "%s"\nvoid qw_arrange(int a, const void *s, void *d) { aiehlc_plan_arrange(a, s, d); }\n'
                % os.path.abspath(header))
    so = os.path.join(d, "arrange.so")
    subprocess.run(["gcc", "-O2", "-shared", "-fPIC", "-o", so, stub], check=True)
    fn = ctypes.CDLL(so).qw_arrange
    fn.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p]
    n = LAUNCH_CHUNKS * CHUNK_BYTES

    def arrange(src):
        assert len(src) == n, len(src)
        sbuf, dbuf = ctypes.create_string_buffer(bytes(src), n), ctypes.create_string_buffer(n)
        fn(0, sbuf, dbuf)
        return dbuf.raw
    probe = np.repeat(np.arange(LAUNCH_CHUNKS, dtype=np.int32), CHUNK_BYTES // 4).tobytes()
    ids = np.frombuffer(arrange(probe), dtype=np.int32).reshape(LAUNCH_CHUNKS, CHUNK_BYTES // 4)
    if not (ids == ids[:, :1]).all() or sorted(ids[:, 0].tolist()) != list(range(LAUNCH_CHUNKS)):
        sys.exit(f"{header}: aiehlc_plan_arrange(0) is not a permutation of {LAUNCH_CHUNKS} chunks of "
                 f"{CHUNK_BYTES} B -- not the qwen_gemv plan")
    return arrange


def to_q4g64(w):
    """rows padded with zeros to a multiple of PAD_ROWS; K > SLICE_K stored as SLICE_K slices, slice-major
    ([K / SLICE_K][rows / 16][SLICE_K / 64] blocks): one AIE launch streams one contiguous slice range."""
    R0, K = w.shape
    assert K % SLICE_K == 0, (R0, K)
    R = (R0 + PAD_ROWS - 1) // PAD_ROWS * PAD_ROWS
    if R != R0:
        w = torch.cat([w, torch.zeros(R - R0, K, dtype=w.dtype)])
    q, s = quant_groups(w)
    # [R/16 rb, 16 n, K/64 g, 4 t, 16 k] -> [rb, g, t, k, n]: tile t holds K 16t..16t+15 of the group, (k, n) row-major
    qt = q.reshape(R // 16, 16, K // 64, 4, 16).permute(0, 2, 3, 4, 1).contiguous()
    tiles = pack_nibbles(qt.reshape(R // 16, K // 64, 4 * 256)).reshape(R // 16, K // 64, 512)
    sc = s.reshape(R // 16, 16, K // 64).permute(0, 2, 1).contiguous().view(torch.uint8).reshape(R // 16, K // 64, 32)
    # chunks of 16 groups: [16 x 512 B tiles][16 x 32 B scales] (8704 B; every tile 512 B aligned for the AIE)
    S, C = K // SLICE_K, SLICE_K // 64 // 16
    tiles = tiles.reshape(R // 16, S, C, 16 * 512)
    sc = sc.reshape(R // 16, S, C, 16 * 32)
    blk = torch.cat([tiles, sc], -1).permute(1, 0, 2, 3).contiguous()  # [S, rb, C, 8704]
    # one AIE launch = 256 row blocks of a slice = the kernel's w [row block][k chunk][8704], arranged by the plan
    L = R // 4096
    blk = blk.reshape(S * L, LAUNCH_CHUNKS * CHUNK_BYTES).numpy()
    return b"".join(ARRANGE(blk[i].tobytes()) for i in range(S * L)), R


def to_q4r64(w):
    R, K = w.shape
    q, s = quant_groups(w)
    nib = pack_nibbles(q.reshape(R, K // 64, 64))                      # [R, G, 32]
    sc = s.contiguous().view(torch.uint8).reshape(R, K // 64, 2)       # [R, G, 2]
    return torch.cat([nib, sc], -1).numpy().tobytes()


def s32(v):
    """an unsigned 32-bit value as the signed int the header's int32 field holds"""
    return v - (1 << 32) if v >= 1 << 31 else v


def to_i32(w):
    return w.to(torch.int32).contiguous().numpy().astype("<i4").tobytes()


def to_f32(w):
    return w.float().contiguous().numpy().astype("<f4").tobytes()


class Src:
    def __init__(self, d):
        idx = os.path.join(d, "model.safetensors.index.json")
        if os.path.exists(idx):
            wm = json.load(open(idx))["weight_map"]
        else:
            f = os.path.join(d, "model.safetensors")
            with safe_open(f, "pt") as h:
                wm = {k: "model.safetensors" for k in h.keys()}
        self.d, self.wm, self.h = d, wm, {}

    def has(self, n):
        return n in self.wm

    def get(self, n):
        f = self.wm[n]
        if f not in self.h:
            self.h[f] = safe_open(os.path.join(self.d, f), "pt")
        return self.h[f].get_tensor(n)


def find_prefix(src):
    for p in ("model.language_model.", "model.", ""):
        if src.has(p + "embed_tokens.weight"):
            return p
    sys.exit("no embed_tokens.weight in the checkpoint")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("model_dir")
    ap.add_argument("out")
    ap.add_argument("--layers", type=int, default=0, help="convert only the first N layers (testing)")
    ap.add_argument("--no-mtp", action="store_true")
    ap.add_argument("--plan-header", required=True,
                    help="aiehlc_plan.h of the qwen_gemv library build (aout/worklocal/): the launch DDR order")
    ap.add_argument("--lm-order", help="token ids by frequency (qwen_draftvocab.py): lm_head rows in that order, "
                                       "lm_perm maps a row back to its token id")
    a = ap.parse_args()
    global ARRANGE
    ARRANGE = plan_arranger(a.plan_header)
    cfg = json.load(open(os.path.join(a.model_dir, "config.json")))
    tc = cfg.get("text_config", cfg)
    src = Src(a.model_dir)
    P = find_prefix(src)
    torch.set_num_threads(min(32, os.cpu_count()))
    L = a.layers or tc["num_hidden_layers"]
    types = tc["layer_types"][:L]
    tensors = []  # (name, type, rows, cols, bytes)

    def add(name, t, w, fn):
        t0 = time.time()
        b = fn(w)
        prow = 0
        if isinstance(b, tuple):
            b, prow = b
        tensors.append((name, t, w.shape[0], w.shape[1] if w.dim() > 1 else 1, b, prow))
        print(f"  {name:28s} {tuple(w.shape)} -> {len(b) / 1e6:9.2f} MB ({time.time() - t0:.1f} s)", flush=True)

    g = src.get
    add("embed", QW_Q4R64, g(P + "embed_tokens.weight"), to_q4r64)
    for i in range(L):
        lp = f"{P}layers.{i}."
        add(f"l{i}.in_norm", QW_F32, g(lp + "input_layernorm.weight"), to_f32)
        add(f"l{i}.post_norm", QW_F32, g(lp + "post_attention_layernorm.weight"), to_f32)
        if types[i] == "linear_attention":
            la = lp + "linear_attn."
            add(f"l{i}.la.qkvz", QW_Q4G64, torch.cat([g(la + "in_proj_qkv.weight"), g(la + "in_proj_z.weight")]), to_q4g64)
            add(f"l{i}.la.ab", QW_F32, torch.cat([g(la + "in_proj_a.weight"), g(la + "in_proj_b.weight")]), to_f32)
            add(f"l{i}.la.conv", QW_F32, g(la + "conv1d.weight").reshape(-1, tc["linear_conv_kernel_dim"]), to_f32)
            add(f"l{i}.la.A_log", QW_F32, g(la + "A_log"), to_f32)
            add(f"l{i}.la.dt_bias", QW_F32, g(la + "dt_bias"), to_f32)
            add(f"l{i}.la.norm", QW_F32, g(la + "norm.weight"), to_f32)
            add(f"l{i}.la.out", QW_Q4G64, g(la + "out_proj.weight"), to_q4g64)
        else:
            fa = lp + "self_attn."
            add(f"l{i}.fa.qkv", QW_Q4G64,
                torch.cat([g(fa + "q_proj.weight"), g(fa + "k_proj.weight"), g(fa + "v_proj.weight")]), to_q4g64)
            add(f"l{i}.fa.q_norm", QW_F32, g(fa + "q_norm.weight"), to_f32)
            add(f"l{i}.fa.k_norm", QW_F32, g(fa + "k_norm.weight"), to_f32)
            add(f"l{i}.fa.o", QW_Q4G64, g(fa + "o_proj.weight"), to_q4g64)
        mp = lp + "mlp."
        add(f"l{i}.mlp.gu", QW_Q4G64, torch.cat([g(mp + "gate_proj.weight"), g(mp + "up_proj.weight")]), to_q4g64)
        add(f"l{i}.mlp.down", QW_Q4G64, g(mp + "down_proj.weight"), to_q4g64)
    add("final_norm", QW_F32, g(P + "norm.weight"), to_f32)
    lm = "lm_head.weight" if src.has("lm_head.weight") else P + "embed_tokens.weight"
    W = g(lm)
    if a.lm_order:
        order = [int(t) for t in np.load(a.lm_order) if 0 <= t < W.shape[0]]
        seen = set(order)
        perm = torch.tensor(list(dict.fromkeys(order)) + [t for t in range(W.shape[0]) if t not in seen])
        assert perm.numel() == W.shape[0]
        W = W[perm]
        add("lm_perm", QW_I32, perm, to_i32)
    add("lm_head", QW_Q4G64, W, to_q4g64)
    mtp = not a.no_mtp and src.has("mtp.fc.weight")
    if mtp:
        add("mtp.fc", QW_Q4G64, g("mtp.fc.weight"), to_q4g64)
        for n in ("pre_fc_norm_embedding", "pre_fc_norm_hidden", "norm"):
            add(f"mtp.{n}", QW_F32, g(f"mtp.{n}.weight"), to_f32)
        mp = "mtp.layers.0."
        add("mtp.in_norm", QW_F32, g(mp + "input_layernorm.weight"), to_f32)
        add("mtp.post_norm", QW_F32, g(mp + "post_attention_layernorm.weight"), to_f32)
        add("mtp.fa.qkv", QW_Q4G64, torch.cat([g(mp + "self_attn.q_proj.weight"), g(mp + "self_attn.k_proj.weight"),
                                               g(mp + "self_attn.v_proj.weight")]), to_q4g64)
        add("mtp.fa.q_norm", QW_F32, g(mp + "self_attn.q_norm.weight"), to_f32)
        add("mtp.fa.k_norm", QW_F32, g(mp + "self_attn.k_norm.weight"), to_f32)
        add("mtp.fa.o", QW_Q4G64, g(mp + "self_attn.o_proj.weight"), to_q4g64)
        add("mtp.mlp.gu", QW_Q4G64, torch.cat([g(mp + "mlp.gate_proj.weight"), g(mp + "mlp.up_proj.weight")]), to_q4g64)
        add("mtp.mlp.down", QW_Q4G64, g(mp + "mlp.down_proj.weight"), to_q4g64)

    rope = tc.get("rope_parameters") or tc.get("rope_scaling") or {}
    theta = rope.get("rope_theta", tc.get("rope_theta", 1e7))
    prf = rope.get("partial_rotary_factor", tc.get("partial_rotary_factor", 0.25))
    full_mask = sum(1 << i for i, t in enumerate(types) if t == "full_attention")
    ints = [L, tc["hidden_size"], tc["intermediate_size"], tc["num_attention_heads"], tc["num_key_value_heads"],
            tc["head_dim"], tc["vocab_size"], tc["linear_num_key_heads"], tc["linear_num_value_heads"],
            tc["linear_key_head_dim"], tc["linear_value_head_dim"], tc["linear_conv_kernel_dim"], int(mtp),
            s32(full_mask & 0xFFFFFFFF), s32(full_mask >> 32), SEG >> 20]
    flts = [tc["rms_norm_eps"], theta, prf]
    # header: magic, version, n_ints, n_flts, ints[16], flts[4], n_tensors, pad, table_off (u64)
    ints16 = ints + [0] * (16 - len(ints))
    flts4 = flts + [0.0] * (4 - len(flts))
    hdr_fmt = "<IIII16i4fII Q"
    hdr_size = struct.calcsize(hdr_fmt)
    ent_fmt = "<64sIIIIQQ"
    ent_size = struct.calcsize(ent_fmt)
    table_off = (hdr_size + ALIGN - 1) // ALIGN * ALIGN
    off = (table_off + ent_size * len(tensors) + ALIGN - 1) // ALIGN * ALIGN
    ents = []
    for name, t, r, c, b, prow in tensors:
        if off % SEG + len(b) > SEG:  # starts the next segment
            off = (off // SEG + 1) * SEG
        ents.append(struct.pack(ent_fmt, name.encode(), t, r, c, prow, off, len(b)))
        off = (off + len(b) + ALIGN - 1) // ALIGN * ALIGN
    with open(a.out, "wb") as f:
        f.write(struct.pack(hdr_fmt, QW_MAGIC, QW_VERSION, len(ints), len(flts), *ints16, *flts4, len(tensors), 0,
                            table_off))
        f.seek(table_off)
        f.write(b"".join(ents))
        for (name, t, r, c, b, prow), e in zip(tensors, ents):
            o = struct.unpack(ent_fmt, e)[5]
            f.seek(o)
            f.write(b)
        f.truncate(off)
    print(f"wrote {a.out}: {len(tensors)} tensors, {off / 1e9:.3f} GB, layers {L}, mtp {mtp}")


if __name__ == "__main__":
    main()
