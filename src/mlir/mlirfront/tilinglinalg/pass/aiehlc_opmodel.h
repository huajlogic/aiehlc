/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// Op + mapping programming model:
//
//   constexpr aie::Conv2d conv = {.h = 224, .w = 224, .c = 3, .k = 64,
//                                 .kh = 7, .kw = 7, .stride = 2, .pad = 3};
//   constexpr aie::Mapping map = {.space = {aie::split(aie::OH, 4), aie::split(aie::OC, 4)},
//                                 .time  = {aie::tile(aie::OH, 7), aie::tile(aie::OW, 28)},
//                                 .hints = {...}};
//   __global__(conv, map) void k(aie::port<input_window_int8 *, aie::IFM> a,
//                                aie::port<input_window_int8 *, aie::WEIGHTS> b,
//                                aie::port<output_window_int8 *, aie::OFM> c);
//
// The kernel declares the operator it computes and how it is mapped; each port
// only names its data role. aiehlc lowers this onto the existing per-port
// GemmSpace path, so the host DMA / routing generation is unchanged:
//   - opModelPrelude(): the aie:: types plus a constexpr aie::derive(role, op, map)
//     that computes the port's GemmSpace (and aie::derive_policy its GlobalPolicy).
//   - rewriteOpBinding(): __global__(conv, map) and the aie::IFM/WEIGHTS/OFM tags
//     become an ordinary policy binding and aie::derive(...) NTTP arguments.
//   - kernelOpDecl(): the op as a literal constexpr struct for the kernel TU, so
//     the kernel body can read conv.kh / conv.kw / conv.stride.
// Design: doc/design/op_mapping_programming_model.md.
#ifndef AIEHLC_OPMODEL_H
#define AIEHLC_OPMODEL_H

#include <cctype>
#include <string>
#include <utility>
#include <vector>

namespace aiehlc_opmodel {

// The aie:: op/mapping types and the constexpr lowering to GemmSpace. Must be
// emitted inside `namespace aie` AFTER GemmSpace and GlobalPolicy.
inline std::string opModelPrelude() {
    return R"AIEOP(
// ---- op + mapping model: __global__(op, map) (aiehlc_opmodel.h) ----
enum Axis { OH = 0, OW = 1, OC = 2 };
enum Role { IFM = 0, WEIGHTS = 1, OFM = 2 };
struct Conv2d {
  int h = 0; int w = 0; int c = 0; int k = 0;
  int kh = 0; int kw = 0; int stride = 1; int pad = 0;
};
struct AxisSplit { Axis axis = OH; int n = 0; };
struct MapHints {
  PadMaterialize pad = PadMaterialize::DDR;
  Im2col im2col = Im2col::Dma;
  int pp_depth = 2;
  Bytes l1_budget = Bytes{32 * 1024};
};
struct Mapping { AxisSplit space[2]; AxisSplit time[2]; MapHints hints; };
// space: split an output axis into n parts across the mesh (rows, then cols).
constexpr AxisSplit split(Axis a, int parts) { return AxisSplit{a, parts}; }
// time: per-round tile of an output axis on one core.
constexpr AxisSplit tile(Axis a, int size) { return AxisSplit{a, size}; }
constexpr int conv_out_h(Conv2d c) { return (c.h + 2 * c.pad - c.kh) / c.stride + 1; }
constexpr int conv_out_w(Conv2d c) { return (c.w + 2 * c.pad - c.kw) / c.stride + 1; }
// int8 channel stride rounded up to a 32-bit DMA word (cin=3 -> 4).
constexpr int conv_c_align(Conv2d c) { return (c.c + 3) / 4 * 4; }
constexpr int map_find(const AxisSplit (&a)[2], Axis x, int dflt) {
  for (int i = 0; i < 2; ++i)
    if (a[i].n > 0 && a[i].axis == x)
      return a[i].n;
  return dflt;
}
// A mapping the derivation cannot honor is a compile error at the port that
// uses it: reaching a throw makes the constexpr evaluation fail, and Clang
// reports the message below as the note.
constexpr void mapping_check(bool ok, const char *why) {
  if (!ok)
    throw why;
}
constexpr tile_dim make_dim(int full, int rounds, int size, int step, int pad) {
  tile_dim d{};
  d.fullsize = full; d.tile_round = rounds; d.tile_size = size; d.stride = step; d.padsize = pad;
  return d;
}
// The tile arithmetic every derivation shares (one formula, no drift between
// the DMA descriptors and the kernel-side block descriptors).
struct ConvTiles {
  int rows = 0, cols = 0;      // mesh split of OH / OC
  int oh = 0, ow = 0, ca = 0;  // output extent, aligned input channels
  int ohRow = 0, ocCore = 0;   // per-core output rows / channels
  int ohT = 0, owT = 0;        // per-round output tile
  int ihT = 0, iwT = 0;        // per-round input slab (halo included)
};
constexpr ConvTiles conv_tiles(Conv2d c, Mapping m) {
  ConvTiles t{};
  t.rows = map_find(m.space, OH, 1);
  t.cols = map_find(m.space, OC, 1);
  t.oh = conv_out_h(c); t.ow = conv_out_w(c); t.ca = conv_c_align(c);
  mapping_check(c.kh > 0 && c.kw > 0 && c.stride > 0 && c.k > 0, "aie::Conv2d needs kh, kw, stride, k > 0");
  mapping_check(t.rows > 0 && t.cols > 0 && t.oh % t.rows == 0, "split(OH, n): output height must divide by n");
  mapping_check(c.k % t.cols == 0, "split(OC, n): output channels must divide by n");
  t.ohRow = t.oh / t.rows;
  t.ocCore = c.k / t.cols;
  t.ohT = map_find(m.time, OH, t.ohRow);
  t.owT = map_find(m.time, OW, t.ow);
  mapping_check(t.ohT > 0 && t.ohRow % t.ohT == 0, "tile(OH, t): rows per mesh row must divide by t");
  mapping_check(t.owT > 0 && t.ow % t.owT == 0, "tile(OW, t): output width must divide by t");
  t.ihT = (t.ohT - 1) * c.stride + c.kh;
  t.iwT = (t.owT - 1) * c.stride + c.kw;
  return t;
}
// The GemmSpace a port with role `r` gets under (c, m). Spatial-halo conv:
// OH split over mesh rows (overlapping input slabs), OC over mesh cols; the
// time tiles become the on-core rounds. Input is DDR pre-padded and
// channel-aligned (MapHints.pad == DDR).
constexpr GemmSpace derive(Role r, Conv2d c, Mapping m) {
  const ConvTiles t = conv_tiles(c, m);
  const int rows = t.rows, cols = t.cols, oh = t.oh, ow = t.ow, ca = t.ca, s = c.stride;
  const int ohRow = t.ohRow, ohT = t.ohT, owT = t.owT, ocCore = t.ocCore;
  GemmSpace g{};
  g.policy.mat.pad = m.hints.pad;
  g.policy.mat.im2col = m.hints.im2col;
  g.policy.sched.pp_depth = m.hints.pp_depth;
  g.policy.sched.l1_budget = m.hints.l1_budget;
  if (r == IFM) {
    g.policy.map.act = Pattern::Broadcast;
    g.policy.map.layout = Layout::Row;
    g.d1 = make_dim(c.h + 2 * c.pad, rows, (ohRow - 1) * s + c.kh, ohRow * s, 0);
    g.d1.slice_tiling.tile_size = t.ihT;
    g.d1.slice_tiling.stride = ohT * s;
    g.d1.slice_tiling.rounds = ohRow / ohT;
    g.d2 = make_dim(c.w + 2 * c.pad, ow / owT, t.iwT, owT * s, 0);
    g.d3 = make_dim(ca, 0, ca, 0, ca - c.c);
  } else if (r == WEIGHTS) {
    g.policy.map.wgt = Pattern::Broadcast;
    g.policy.map.layout = Layout::Col;
    g.d1 = make_dim(c.k, cols, ocCore, ocCore, 0);
    g.d2 = make_dim(c.kw, 0, c.kh, c.kw, 0);
    g.d3 = make_dim(c.kh, 0, c.kh, c.kh, 0);
    g.d4 = make_dim(ca, 0, ca, ca, ca - c.c);
  } else {
    g.policy.map.layout = Layout::Row;
    g.policy.map.merge_order = Flow::LeftToRight;
    g.policy.map.mesh_tiling_group1_dim = 1; // d1 = OH, split across mesh rows
    g.policy.map.mesh_tiling_group2_dim = 3; // d3 = OC, split across mesh cols
    g.policy.mat.im2col = Im2col::None;
    g.d1 = make_dim(oh, rows, ohRow, ohRow, 0);
    g.d1.slice_tiling.tile_size = ohT;
    g.d1.slice_tiling.stride = ohT;
    g.d1.slice_tiling.rounds = ohRow / ohT;
    g.d2 = make_dim(ow, ow / owT, owT, owT, 0);
    g.d3 = make_dim(c.k, cols, ocCore, 0, 0);
  }
  return g;
}
// Spatial-halo conv sends A and B once each along the tiling (no M x N
// cartesian repeat).
constexpr GlobalPolicy derive_policy(Conv2d, Mapping) { return GlobalPolicy{0}; }

// Block-load convention (aie::load_buffer / aie::store_buffer in the kernel):
// the block a port delivers in round (i, j) on the core with program ids
// (p0, p1), in ELEMENT coordinates of the port's whole tensor:
//   offset[d] = base_p0[d]*p0 + base_p1[d]*p1 + step_i[d]*i + step_j[d]*j
// rounds run i outer (rounds_i), j inner (rounds_j) -- the DMA order.
// IFM coordinates are the DDR (padded, channel-aligned) input tensor.
struct BlockDesc {
  int rank = 0;
  int shape[4] = {0, 0, 0, 0};
  int base_p0[4] = {0, 0, 0, 0};
  int base_p1[4] = {0, 0, 0, 0};
  int step_i[4] = {0, 0, 0, 0};
  int step_j[4] = {0, 0, 0, 0};
  int rounds_i = 1;
  int rounds_j = 1;
};
constexpr BlockDesc block_desc(Role r, Conv2d c, Mapping m) {
  const ConvTiles t = conv_tiles(c, m);
  BlockDesc b{};
  if (r == WEIGHTS) { // B^T [k, kh, kw, c_align]: this core's OC slice, sent once
    b.rank = 4;
    b.shape[0] = t.ocCore; b.shape[1] = c.kh; b.shape[2] = c.kw; b.shape[3] = t.ca;
    b.base_p1[0] = t.ocCore;
    return b;
  }
  b.rank = 3;
  b.rounds_i = t.ohRow / t.ohT;
  b.rounds_j = t.ow / t.owT;
  if (r == IFM) { // [h+2p, w+2p, c_align]: overlapping halo slabs
    b.shape[0] = t.ihT; b.shape[1] = t.iwT; b.shape[2] = t.ca;
    b.base_p0[0] = t.ohRow * c.stride;
    b.step_i[0] = t.ohT * c.stride;
    b.step_j[1] = t.owT * c.stride;
  } else { // OFM [oh, ow, k]
    b.shape[0] = t.ohT; b.shape[1] = t.owT; b.shape[2] = t.ocCore;
    b.base_p0[0] = t.ohRow;
    b.base_p1[2] = t.ocCore;
    b.step_i[0] = t.ohT;
    b.step_j[1] = t.owT;
  }
  return b;
}
// What the kernel sees as `map`: the block sizes of (c, m) (cf. Triton's
// constexpr BLOCK sizes). Field order is the kernel-side struct's.
struct KernelView {
  int oh = 0, ow = 0;          // full output extent
  int oh_per_core = 0;         // output rows per mesh row
  int oc_per_core = 0;         // output channels per mesh col
  int oh_t = 0, ow_t = 0;      // per-round output tile
  int ih_t = 0, iw_t = 0;      // per-round input slab (halo included)
  int c_align = 0;             // input channel stride
};
constexpr KernelView kernel_view(Conv2d c, Mapping m) {
  const ConvTiles t = conv_tiles(c, m);
  return KernelView{t.oh, t.ow, t.ohRow, t.ocCore, t.ohT, t.owT, t.ihT, t.iwT, t.ca};
}
)AIEOP";
}

// `__global__(<op>, <map>)`: the two comma-separated arguments, trimmed.
// Returns false for the single-argument policy form.
inline bool parseOpBinding(const std::string &args, std::string &opVar, std::string &mapVar) {
    size_t comma = args.find(',');
    if (comma == std::string::npos)
        return false;
    auto trim = [](std::string s) {
        size_t b = s.find_first_not_of(" \t\n");
        size_t e = s.find_last_not_of(" \t\n");
        return b == std::string::npos ? std::string() : s.substr(b, e - b + 1);
    };
    opVar = trim(args.substr(0, comma));
    mapVar = trim(args.substr(comma + 1));
    return !opVar.empty() && !mapVar.empty() && mapVar.find(',') == std::string::npos;
}

// The synthesized GlobalPolicy variable bound to an op-form kernel.
inline std::string opPolicyVar(const std::string &opVar, const std::string &mapVar) {
    return "__aie_policy_" + opVar + "_" + mapVar;
}

// Replace each whole-token `aie::IFM|WEIGHTS|OFM` port tag in a kernel's
// parameter text with the derived GemmSpace: aie::derive(aie::IFM, op, map).
inline std::string rewriteRoleTags(std::string params, const std::string &opVar, const std::string &mapVar) {
    static const char *roles[] = {"IFM", "WEIGHTS", "OFM"};
    for (const char *role : roles) {
        const std::string tag = std::string("aie::") + role;
        size_t pos = 0;
        while ((pos = params.find(tag, pos)) != std::string::npos) {
            size_t end = pos + tag.size();
            bool wholeToken = end >= params.size() || !(std::isalnum((unsigned char)params[end]) || params[end] == '_');
            if (!wholeToken) {
                pos = end;
                continue;
            }
            std::string repl = "aie::derive(aie::" + std::string(role) + ", " + opVar + ", " + mapVar + ")";
            params.replace(pos, tag.size(), repl);
            pos += repl.size();
        }
    }
    return params;
}

// (port variable, role) of each `aie::port<T, aie::IFM|WEIGHTS|OFM> var` in a
// kernel's parameter text, in declaration order.
inline std::vector<std::pair<std::string, std::string>> parsePortRoles(const std::string &params) {
    std::vector<std::pair<std::string, std::string>> out;
    static const char *roles[] = {"IFM", "WEIGHTS", "OFM"};
    size_t pos = 0;
    while ((pos = params.find("aie::port<", pos)) != std::string::npos) {
        size_t close = params.find('>', pos);
        if (close == std::string::npos)
            break;
        std::string targs = params.substr(pos, close - pos);
        std::string role;
        for (const char *r : roles) {
            std::string tag = std::string("aie::") + r;
            size_t at = targs.rfind(tag);
            if (at != std::string::npos && at + tag.size() == targs.find_last_not_of(" \t\n") + 1)
                role = r;
        }
        size_t v = params.find_first_not_of(" \t\n", close + 1);
        size_t ve = v;
        while (ve < params.size() && (std::isalnum((unsigned char)params[ve]) || params[ve] == '_'))
            ++ve;
        if (!role.empty() && v != std::string::npos && ve > v)
            out.emplace_back(params.substr(v, ve - v), role);
        pos = close + 1;
    }
    return out;
}

// Source names of the per-port block descriptor and of the kernel view, as
// synthesized constexpr variables the frontend evaluates.
inline std::string blockDescVar(const std::string &port) { return "__aie_blk_" + port; }
inline std::string kernelViewVar(const std::string &mapVar) { return "__aie_view_" + mapVar; }

// The constexpr declarations synthesized in front of an op-form kernel: its
// policy, one aie::BlockDesc per port, and the aie::KernelView of the mapping.
inline std::string opSynthesizedDecls(const std::string &opVar, const std::string &mapVar,
                                      const std::vector<std::pair<std::string, std::string>> &ports) {
    std::string s = "constexpr aie::GlobalPolicy " + opPolicyVar(opVar, mapVar) + " = aie::derive_policy(" + opVar +
                    ", " + mapVar + ");\n";
    for (const auto &p : ports)
        s += "constexpr aie::BlockDesc " + blockDescVar(p.first) + " = aie::block_desc(aie::" + p.second + ", " +
             opVar + ", " + mapVar + ");\n";
    s += "constexpr aie::KernelView " + kernelViewVar(mapVar) + " = aie::kernel_view(" + opVar + ", " + mapVar + ");\n";
    return s;
}

// Kernel-TU declarations from evaluated initializers ("{...}" text).
inline std::string kernelBlockDescDecl(const std::string &port, const std::string &init) {
    return "static const aiehlc_blk_desc aiehlc_desc_" + port + " = " + init + ";\n" +
           "static aiehlc_blk_cursor aiehlc_cur_" + port + ";";
}
inline std::string kernelViewDecl(const std::string &mapVar, const std::string &init) {
    return "static constexpr aiehlc_kernel_view_t " + mapVar + " = " + init + "; // __global__ mapping block sizes";
}

// Kernel-TU declaration of an evaluated aie::Conv2d (its "{h, w, c, k, kh, kw,
// stride, pad}" initializer). The kernel TU includes the AIE API's own
// `namespace aie`, so the op type there lives outside it.
inline std::string kernelOpDecl(const std::string &opVar, const std::string &init) {
    return "#ifndef AIEHLC_OP_CONV2D_T\n#define AIEHLC_OP_CONV2D_T\n"
           "struct aiehlc_conv2d_t { int h, w, c, k, kh, kw, stride, pad; };\n#endif\n"
           "static constexpr aiehlc_conv2d_t " +
           opVar + " = " + init + "; // __global__ op declaration";
}

} // namespace aiehlc_opmodel

#endif // AIEHLC_OPMODEL_H
