/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * aiehlc-convtile — command-line front end of the conv2d auto-tiling model.
 * It is the backend the Python tuner (script/convtune) drives:
 *
 *   aiehlc-convtile derive  <src.cc> [--overrides JSON|@file]   derived d1/d2/d3 + features (JSON)
 *   aiehlc-convtile space   <src.cc> [--overrides JSON|@file]   all legal candidates, ranked (JSON);
 *                                                               only pp_depth / l1_budget / c_align apply
 *   aiehlc-convtile desugar <src.cc> [--overrides JSON|@file]   rewritten source (what aiehlc compiles)
 *
 * Options: --data-mem-budget N (bytes, default 49152), --stack-budget N (bytes,
 *          default 32768; 0 disables the kernel-frame check), --copy-cycles-per-byte F
 *          (default 7; 0 for kernels that compute on the window pointers directly)
 * Exit code: 0 ok, 1 usage / IO error, 2 the model rejected the configuration.
 ******************************************************************************/
#include "conv_desugar.h"

#include <cstdio>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>

using namespace convautotile;

static int usage() {
    std::cerr << "usage: aiehlc-convtile {derive|space|desugar} <src.cc> [--overrides JSON|@file]"
                 " [--data-mem-budget N] [--stack-budget N] [--copy-cycles-per-byte F]\n";
    return 1;
}

static bool readFile(const std::string &p, std::string &out) {
    std::ifstream f(p);
    if (!f)
        return false;
    std::stringstream ss;
    ss << f.rdbuf();
    out = ss.str();
    return true;
}

static std::string dirOf(const std::string &p) {
    size_t s = p.rfind('/');
    return s == std::string::npos ? "." : p.substr(0, s);
}

int main(int argc, char **argv) {
    if (argc < 3)
        return usage();
    std::string cmd = argv[1], path = argv[2], ovText;
    Target tgt;
    for (int i = 3; i < argc; i++) {
        if (!std::strcmp(argv[i], "--overrides") && i + 1 < argc)
            ovText = argv[++i];
        else if (!std::strcmp(argv[i], "--data-mem-budget") && i + 1 < argc)
            tgt.data_mem_budget = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i], "--stack-budget") && i + 1 < argc)
            tgt.stack_budget = std::atoi(argv[++i]);
        else if (!std::strcmp(argv[i], "--copy-cycles-per-byte") && i + 1 < argc)
            tgt.copy_cycles_per_byte = std::atof(argv[++i]);
        else
            return usage();
    }
    if (!ovText.empty() && ovText[0] == '@' && !readFile(ovText.substr(1), ovText)) {
        std::cerr << "cannot read overrides file " << ovText.substr(1) << "\n";
        return 1;
    }
    Overrides ov;
    if (!ovText.empty()) {
        std::string err;
        if (!parseOverridesJson(ovText, ov, &err)) {
            std::cerr << "bad overrides: " << err << "\n";
            return 1;
        }
        if (!err.empty())
            std::cerr << "warning: " << err << "\n";
    }
    std::string src;
    if (!readFile(path, src)) {
        std::cerr << "cannot read " << path << "\n";
        return 1;
    }
    if (cmd == "derive" || cmd == "desugar") {
        std::string text = src;
        DesugarResult r = desugarConvMapping(text, dirOf(path), ov, tgt);
        if (!r.found) {
            std::cerr << path << ": no aie::Mapping declaration\n";
            return 2;
        }
        if (cmd == "desugar" && r.ok)
            std::cout << text;
        else
            std::cout << reportJson(r);
        return r.ok ? 0 : 2;
    }
    if (cmd == "space") {
        DesugarResult r = parseConvMapping(src, dirOf(path));
        if (!r.found || !r.ok || r.kernels.empty()) {
            std::cerr << path << ": " << (r.error.empty() ? "no aie::Conv2d/aie::Mapping kernel" : r.error) << "\n";
            return 2;
        }
        KernelDesugar k = r.kernels.front();
        if (ov.pp_depth > 0)
            k.mapping.hints.pp_depth = ov.pp_depth;
        if (ov.l1_budget > 0)
            k.mapping.hints.l1_budget = ov.l1_budget;
        if (ov.c_align > 0)
            k.conv.c_align = ov.c_align;
        auto cands = enumerateCandidates(k.conv, k.mapping, tgt);
        std::cout << "{\n  \"kernel\": \"" << k.kernel << "\",\n  \"conv\": " << toJson(k.conv)
                  << ",\n  \"mesh_rows\": " << k.mapping.space_rows.factor
                  << ",\n  \"mesh_cols\": " << k.mapping.space_cols.factor
                  << ",\n  \"pp_depth\": " << k.mapping.hints.pp_depth
                  << ",\n  \"l1_budget\": " << k.mapping.hints.l1_budget << ",\n  \"candidates\": [";
        for (size_t i = 0; i < cands.size(); i++)
            std::cout << (i ? "," : "") << "\n    " << toJson(cands[i], "    ");
        std::cout << "]\n}\n";
        return cands.empty() ? 2 : 0;
    }
    return usage();
}
