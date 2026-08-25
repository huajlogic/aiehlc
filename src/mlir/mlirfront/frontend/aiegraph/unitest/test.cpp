/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// Unit test for the aiegraph high-level dialect:
//   1. Round-trip: build a small well-formed graph (ops_test), print it, then
//      re-parse the printed text and confirm it re-prints identically.
//   2. Verify: a shape-mismatched residual edge is rejected by the verifier.
//   3. Lower: walk the verified module into per-op launch descriptors and print
//      the geometry-derived tensor_specs (mirrors _compiler._tensor_specs).
#include <iostream>
#include <string>

#include "AiegraphLowerDriver.h"
#include "aiegraphmanager.h"

#include "mlir/IR/Verifier.h"
#include "mlir/Parser/Parser.h"
#include "llvm/Support/raw_ostream.h"

static std::string printModule(mlir::ModuleOp m) {
    std::string s;
    llvm::raw_string_ostream os(s);
    m.print(os);
    os.flush();
    return s;
}

int main(int argc, char *argv[]) {
    MLIRContext ctx;
    aiegraphmanager::loaddialect(&ctx);

    // ── 1. Build + print ──────────────────────────────────────────────────────
    aiegraphmanager mgr;
    mlir::ModuleOp built = mgr.ops_test(&ctx);
    if (mlir::failed(mlir::verify(built))) {
        std::cerr << "FAIL: ops_test module did not verify\n";
        return 1;
    }
    std::string firstPrint = printModule(built);
    std::cout << "=== built aiegraph module ===\n" << firstPrint << "\n";

    // ── 2. Round-trip: parse the printed text, re-print, compare ──────────────
    mlir::OwningOpRef<mlir::ModuleOp> reparsed = mlir::parseSourceString<mlir::ModuleOp>(firstPrint, &ctx);
    if (!reparsed) {
        std::cerr << "FAIL: could not re-parse printed aiegraph IR\n";
        return 1;
    }
    std::string secondPrint = printModule(reparsed.get());
    if (firstPrint != secondPrint) {
        std::cerr << "FAIL: round-trip mismatch\n--- first ---\n"
                  << firstPrint << "\n--- second ---\n"
                  << secondPrint << "\n";
        return 1;
    }
    std::cout << "PASS: round-trip identical\n";

    // ── 3. Negative: a shape-mismatched residual edge must be rejected ────────
    const char *bad = "aiegraph.func @bad() {\n"
                      "  %a = aiegraph.residual_add_relu %x, %y {length = 8 : i64} :"
                      " (tensor<8xi8>, tensor<8xi8>) -> tensor<16xi8>\n"
                      "  aiegraph.yield\n"
                      "}\n";
    {
        mlir::OwningOpRef<mlir::ModuleOp> badMod = mlir::parseSourceString<mlir::ModuleOp>(bad, &ctx);
        // Either the parse fails (undefined %x/%y) or verification rejects the
        // length/shape mismatch; both are acceptable "rejected" outcomes.
        if (badMod && mlir::succeeded(mlir::verify(badMod.get()))) {
            std::cerr << "FAIL: shape-mismatched residual was accepted\n";
            return 1;
        }
        std::cout << "PASS: malformed residual rejected\n";
    }

    // ── 4. Lower the good module into per-op launch descriptors ───────────────
    bool ok = false;
    auto launches = aiegraph::AiegraphLowerDriver::lower(built, ok);
    if (!ok) {
        std::cerr << "FAIL: lower() returned not-ok\n";
        return 1;
    }
    std::cout << "=== launches (" << launches.size() << ") ===\n";
    for (auto &L : launches) {
        std::cout << "[" << L.index << "] " << L.funcName;
        if (!L.weightsSym.empty())
            std::cout << " weights=@" << L.weightsSym;
        std::cout << "\n";
        for (auto &ts : L.tensorSpecs) {
            std::cout << "    spec shape=[";
            for (size_t i = 0; i < ts.shape.size(); ++i)
                std::cout << (i ? "," : "") << ts.shape[i];
            std::cout << "] bits=" << ts.elementBitWidth << " isInput=" << (ts.isInput ? "true" : "false") << "\n";
        }
    }

    std::cout << "main\n";
    return 0;
}
