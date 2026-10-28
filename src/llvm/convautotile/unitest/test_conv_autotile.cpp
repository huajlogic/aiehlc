/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Golden tests for the conv2d auto-tiling model. The reference values are the
 * hand-written RowBC_spatial / ColBC / LtoR_Merge spaces and SP_* macros of
 * example/tileprogram/ccode/simpleconv2d.cc, which run GOLDEN on the board.
 *
 * Build + run:  src/llvm/convautotile/unitest/run.sh
 ******************************************************************************/
#include "../conv_desugar.h"

#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>

using namespace convautotile;

static int g_fail = 0, g_pass = 0;
#define CHECK_EQ(a, b)                                                                                                 \
    do {                                                                                                               \
        long _a = (long)(a), _b = (long)(b);                                                                           \
        if (_a != _b) {                                                                                                \
            std::printf("FAIL %s:%d  %s = %ld, expected %ld\n", __FILE__, __LINE__, #a, _a, _b);                       \
            g_fail++;                                                                                                  \
        } else                                                                                                         \
            g_pass++;                                                                                                  \
    } while (0)
#define CHECK(c)                                                                                                       \
    do {                                                                                                               \
        if (!(c)) {                                                                                                    \
            std::printf("FAIL %s:%d  %s\n", __FILE__, __LINE__, #c);                                                   \
            g_fail++;                                                                                                  \
        } else                                                                                                         \
            g_pass++;                                                                                                  \
    } while (0)

static Conv2dSpec stem() {
    Conv2dSpec c;
    c.h = 224, c.w = 224, c.c = 3, c.k = 64, c.kh = 7, c.kw = 7, c.stride = 2, c.pad = 3;
    return c;
}

static MappingSpec stemMap(int th, int tw) {
    MappingSpec m;
    m.space_rows = {Axis::OH, 4};
    m.space_cols = {Axis::OC, 4};
    if (th)
        m.time.push_back({Axis::OH, th});
    if (tw)
        m.time.push_back({Axis::OW, tw});
    m.hints.pp_depth = 2;
    m.hints.l1_budget = 4096;
    return m;
}

static long kdef(const Derived &d, const std::string &n) {
    for (auto &kv : d.kernel_defines)
        if (kv.first == n)
            return kv.second;
    return -12345;
}

// The hand-written simpleconv2d.cc spaces, field by field.
static void testGoldenStem() {
    Derived d = derive(stem(), stemMap(7, 28));
    CHECK(d.ok);
    // RowBC_spatial
    const auto &a = d.ifm.d;
    CHECK_EQ(a[0].fullsize, 230);
    CHECK_EQ(a[0].tile_round, 4);
    CHECK_EQ(a[0].tile_size, 61);
    CHECK_EQ(a[0].stride, 56);
    CHECK_EQ(a[0].l2_size, 19);
    CHECK_EQ(a[0].l2_stride, 14);
    CHECK_EQ(a[0].l2_rounds, 4);
    CHECK_EQ(a[1].fullsize, 230);
    CHECK_EQ(a[1].tile_round, 4);
    CHECK_EQ(a[1].tile_size, 61);
    CHECK_EQ(a[1].stride, 56);
    CHECK_EQ(a[2].fullsize, 4);
    CHECK_EQ(a[2].tile_size, 4);
    CHECK_EQ(a[2].padsize, 1);
    // ColBC
    const auto &b = d.weights.d;
    CHECK_EQ(b[0].fullsize, 64);
    CHECK_EQ(b[0].tile_round, 4);
    CHECK_EQ(b[0].tile_size, 16);
    CHECK_EQ(b[0].stride, 16);
    CHECK_EQ(b[1].fullsize, 7);
    CHECK_EQ(b[2].fullsize, 7);
    CHECK_EQ(b[3].fullsize, 4);
    CHECK_EQ(b[3].padsize, 1);
    // LtoR_Merge
    const auto &o = d.ofm.d;
    CHECK_EQ(o[0].fullsize, 112);
    CHECK_EQ(o[0].tile_round, 4);
    CHECK_EQ(o[0].tile_size, 28);
    CHECK_EQ(o[0].stride, 28);
    CHECK_EQ(o[0].l2_size, 7);
    CHECK_EQ(o[0].l2_rounds, 4);
    CHECK_EQ(o[1].fullsize, 112);
    CHECK_EQ(o[1].tile_round, 4);
    CHECK_EQ(o[1].tile_size, 28);
    CHECK_EQ(o[2].fullsize, 64);
    CHECK_EQ(o[2].tile_round, 4);
    CHECK_EQ(o[2].tile_size, 16);
    CHECK_EQ(d.ofm.group1_dim, 1);
    CHECK_EQ(d.ofm.group2_dim, 3);
    // Kernel macros of the old file.
    CHECK_EQ(kdef(d, "SP_K"), 196);
    CHECK_EQ(kdef(d, "SP_OHR"), 7);
    CHECK_EQ(kdef(d, "OW_T"), 28);
    CHECK_EQ(kdef(d, "TILE_H"), 19);
    CHECK_EQ(kdef(d, "TILE_W"), 61);
    CHECK_EQ(kdef(d, "TILE_STRIDE_H"), 14);
    CHECK_EQ(kdef(d, "TILE_STRIDE_W"), 56);
    // Pipeline log of the old file: "Buffer memory check passed: 21816 / 49152".
    CHECK_EQ(d.ifm_round_bytes, 4636);
    CHECK_EQ(d.wgt_bytes, 3136);
    CHECK_EQ(d.ofm_round_bytes, 3136);
    CHECK_EQ(d.l1_bytes, 21816);
    CHECK_EQ(d.rounds, 16);
    // kernel.calltree "Maximum stack size: 11200" for this tiling.
    CHECK(d.stack_bytes >= 11200 && d.stack_bytes <= 11200 + 256);
}

static void testFootprintRule() {
    // 3x3 s1 p1 on 56x56: halo = K-S = 2, slice = T+2.
    Conv2dSpec c;
    c.h = 56, c.w = 56, c.c = 64, c.k = 64, c.kh = 3, c.kw = 3, c.stride = 1, c.pad = 1;
    MappingSpec m = stemMap(7, 14);
    m.hints.l1_budget = 16384; // 3x3x64 filters x 16 oc = 9216 B
    Derived d = derive(c, m);
    CHECK(d.ok);
    CHECK_EQ(d.oh, 56);
    CHECK_EQ(d.oh_mesh, 14);
    CHECK_EQ(d.mesh_slice_h, 16);
    CHECK_EQ(d.mesh_step_h, 14);
    CHECK_EQ(d.tile_h, 9);
    CHECK_EQ(d.tile_step_h, 7);
    CHECK_EQ(d.tile_w, 16);
    CHECK_EQ(d.c_align, 64);
    // Dilation 2 widens the window to (K-1)*D+1 = 5.
    c.dilation = 2;
    c.pad = 2;
    d = derive(c, m);
    CHECK(d.ok);
    CHECK_EQ(d.tile_h, 11);
}

static void testRejections() {
    // OH=112 is not divisible by 3 mesh rows.
    MappingSpec m = stemMap(7, 28);
    m.space_rows.factor = 3;
    CHECK(!derive(stem(), m).ok);
    Derived d0;
    // tile(OH,5) does not divide 28 rows per core.
    CHECK(!derive(stem(), stemMap(5, 28)).ok);
    // Splitting OW across mesh rows is not a supported layout.
    m = stemMap(7, 28);
    m.space_rows.axis = Axis::OW;
    CHECK(!derive(stem(), m).ok);
    // One width round (tile(OW, OW)) is not supported downstream.
    MappingSpec mw = stemMap(4, 112);
    mw.hints.l1_budget = 8192;
    d0 = derive(stem(), mw);
    CHECK(!d0.ok && d0.errors[0].find("tile(OW") != std::string::npos);
    // A whole-core tile blows the 48 KB core budget.
    Derived d = derive(stem(), stemMap(28, 112));
    CHECK(!d.ok);
    // Fits the 48 KB buffer budget with pp_depth=1 but not the 32 KB stack.
    MappingSpec m1 = stemMap(7, 56); // 8892 + 3136 + 6272 B ...
    m1.hints.pp_depth = 1;
    m1.hints.l1_budget = 8192;
    Target smallStack;
    smallStack.stack_budget = 16384; // ... over a 16 KB stack
    d = derive(stem(), m1, smallStack);
    CHECK(!d.ok);
    CHECK(d.l1_bytes <= 49152);
    CHECK(!d.errors.empty() && d.errors[0].find("stack") != std::string::npos);
    Target noStack;
    noStack.stack_budget = 0;
    CHECK(derive(stem(), m1, noStack).ok);
}

static void testMeshSymbols() {
    std::string src =
        "#define HW_ROWS 4\n#define HW_COLS 4\n"
        "constexpr aie::Conv2d conv = {.h=224, .w=224, .c=3, .k=64, .kh=7, .kw=7, .stride=2, .pad=3};\n"
        "constexpr aie::Mapping map = {.space = {aie::split(aie::OH, MESH_ROW), aie::split(aie::OC, "
        "MESH_COL)}};\n"
        "__global__(conv, map) void k(aie::port<input_window_int8 *, aie::IFM> a,\n"
        "  aie::port<input_window_int8 *, aie::WEIGHTS> b, aie::port<output_window_int8 *, aie::OFM> c) {}\n"
        "int main() { aieMesh mesh = device.partition({3, 6, 0, 6}, HW_ROWS, HW_COLS); }\n";
    std::string s1 = src;
    DesugarResult r = desugarConvMapping(s1, "", Overrides());
    CHECK(r.ok);
    if (!r.ok)
        std::printf("  mesh symbols: %s\n", r.error.c_str());
    CHECK(r.ok && r.kernels[0].derived.mesh_rows == 4 && r.kernels[0].derived.time_autotuned);
    // An explicit split that disagrees with the launch mesh is rejected.
    std::string s2 = src;
    s2.replace(s2.find("MESH_ROW"), 8, "2");
    CHECK(!desugarConvMapping(s2, "", Overrides()).ok);
    // No partition call: MESH_ROW cannot be resolved.
    std::string s3 = src.substr(0, src.find("int main"));
    CHECK(!desugarConvMapping(s3, "", Overrides()).ok);
}

static void testAutotuneAndOverrides() {
    Derived d = derive(stem(), stemMap(0, 0)); // .time omitted
    CHECK(d.ok);
    CHECK(d.time_autotuned);
    CHECK(d.l1_bytes <= 49152);
    auto cands = enumerateCandidates(stem(), stemMap(0, 0));
    CHECK(!cands.empty());
    CHECK_EQ(cands.front().oh_t, d.oh_t);
    for (auto &c : cands)
        CHECK(c.ok && c.l1_bytes <= 49152);

    Overrides ov;
    std::string err;
    CHECK(parseOverridesJson("{\"time_oh\": 14, \"time_ow\": 28, \"pp_depth\": 2}", ov, &err));
    CHECK_EQ(ov.time_oh, 14);
    // OFM tile 14*28*16 = 6272 B > l1_budget 4096: chunked unevenly downstream.
    d = derive(stem(), stemMap(7, 28), Target(), ov);
    CHECK(!d.ok);
    CHECK(parseOverridesJson("{\"time_oh\": 14, \"time_ow\": 28, \"l1_budget\": 8192}", ov, &err));
    d = derive(stem(), stemMap(7, 28), Target(), ov);
    CHECK(d.ok);
    CHECK_EQ(d.ofm.l1_budget, 8192);
    CHECK_EQ(d.tile_h, 33);
    CHECK_EQ(d.ifm.d[0].l2_rounds, 2);
    CHECK(!parseOverridesJson("{\"time_oh\": }", ov, &err));
}

static std::string readFile(const std::string &p) {
    std::ifstream f(p);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

// End-to-end text rewrite of the real example file.
static void testDesugarExample(const std::string &repo) {
    const std::string dir = repo + "/example/tileprogram/ccode";
    std::string src = readFile(dir + "/simpleconv2d_new_load.cc");
    CHECK(!src.empty());
    DesugarResult r = desugarConvMapping(src, dir, Overrides());
    CHECK(r.found && r.ok);
    if (!r.ok)
        std::printf("  desugar error: %s\n", r.error.c_str());
    CHECK_EQ(r.kernels.size(), 1);
    CHECK(src.find("__global__(__aie_conv2d_spatial_policy) void conv2d_spatial") != std::string::npos);
    CHECK(src.find("aie::port<input_window_int8 *, __aie_conv2d_spatial_IFM>") != std::string::npos);
    CHECK(src.find("aie::port<input_window_int8 *, __aie_conv2d_spatial_WEIGHTS>") != std::string::npos);
    CHECK(src.find("aie::port<output_window_int8 *, __aie_conv2d_spatial_OFM>") != std::string::npos);
    CHECK(src.find("#define TILE_W 61") != std::string::npos);
    CHECK(src.find(".slice_tiling = {.tile_size = 19, .stride = 14, .rounds = 4}") != std::string::npos);
    CHECK(src.find("\nconstexpr aie::Mapping") == std::string::npos); // lowered (commented out)
}

int main(int argc, char **argv) {
    std::string repo = argc > 1 ? argv[1] : ".";
    testGoldenStem();
    testFootprintRule();
    testRejections();
    testAutotuneAndOverrides();
    testMeshSymbols();
    testDesugarExample(repo);
    std::printf("conv_autotile: %d passed, %d failed\n", g_pass, g_fail);
    return g_fail ? 1 : 0;
}
