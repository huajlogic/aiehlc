/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "dfscheblueprintmanager.h"
#include "../../routing/routingmanager.h"
#include <iostream>

#define GET_TYPEDEF_CLASSES
#define GET_ATTRDEF_CLASSES
#define GET_OP_CLASSES
#define GET_OP_DEFS
#include "dfscheblueprintdialect.cc.inc"
#include "dfscheblueprintenums.cc.inc"
#include "dfscheblueprintattr.cc.inc"
#include "dfscheblueprinttype.cc.inc"

#include "dfscheblueprintop.cc.inc"
#undef GET_OP_DEFS

#undef GET_OP_CLASSES
#undef GET_ATTRDEF_CLASSES
#undef GET_TYPEDEF_CLASSES

//===----------------------------------------------------------------------===//
// Custom Printers and Parsers
//===----------------------------------------------------------------------===//

// ConfigOp printer
void dfscheblueprint::ConfigOp::print(OpAsmPrinter &printer) {
    printer << " @" << getSymName();
    printer << " ";
    printer.printRegion(getBody(), /*printEntryBlockArgs=*/false, /*printBlockTerminators=*/false);
}

// ConfigOp parser
ParseResult dfscheblueprint::ConfigOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();
    
    Region *body = result.addRegion();
    if (parser.parseRegion(*body, {}, {}))
        return failure();
    
    // Ensure the region has a block
    if (body->empty())
        body->emplaceBlock();
    
    return success();
}

// TransferManifestOp printer
void dfscheblueprint::TransferManifestOp::print(OpAsmPrinter &printer) {
    printer << " @" << getSymName() << " {";
    printer.printNewline();
    printer << "    payload_slice = " << getPayloadSlice() << ",";
    printer.printNewline();
    printer << "    packet_id = " << getPacketId() << ",";
    printer.printNewline();
    printer << "    source = " << getSource() << ",";
    printer.printNewline();
    printer << "    destinations = " << getDestinations();
    printer.printNewline();
    printer << "  }";
}

// TransferManifestOp parser
ParseResult dfscheblueprint::TransferManifestOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();
    
    if (parser.parseLBrace())
        return failure();
    
    dfscheblueprint::SliceAttr payloadSlice;
    IntegerAttr packetId;
    dfscheblueprint::EndpointAttr source;
    ArrayAttr destinations;
    
    while (true) {
        StringRef attrName;
        if (parser.parseOptionalKeyword(&attrName)) {
            break;
        }
        
        if (parser.parseEqual())
            return failure();
        
        if (attrName == "payload_slice") {
            if (parser.parseAttribute(payloadSlice))
                return failure();
        } else if (attrName == "packet_id") {
            if (parser.parseAttribute(packetId))
                return failure();
        } else if (attrName == "source") {
            if (parser.parseAttribute(source))
                return failure();
        } else if (attrName == "destinations") {
            if (parser.parseAttribute(destinations))
                return failure();
        }
        
        parser.parseOptionalComma();
    }
    
    if (parser.parseRBrace())
        return failure();
    
    result.addAttribute("payload_slice", payloadSlice);
    result.addAttribute("packet_id", packetId);
    result.addAttribute("source", source);
    result.addAttribute("destinations", destinations);
    
    return success();
}

//===----------------------------------------------------------------------===//
// Dialect Initialization
//===----------------------------------------------------------------------===//

void dfscheblueprintdialect::initialize()  { 
    addOperations<
    #define GET_OP_LIST
    #include "dfscheblueprintop.cc.inc"
        >();
    // Add Attributes
     addAttributes<
    #define GET_ATTRDEF_LIST
    #include "dfscheblueprintattr.cc.inc"
    >();

    // Add Types
    addTypes<
    #define GET_TYPEDEF_LIST
    #include "dfscheblueprinttype.cc.inc"
    >();
}

ModuleOp dfscheblueprintmanager::ops_test(MLIRContext* ctx) {
    loaddialect(ctx);
    OpBuilder builder(ctx);
    mlir::ModuleOp m = ModuleOp::create(builder.getUnknownLoc());
    
    // Set insertion point to the module body
    builder.setInsertionPointToEnd(m.getBody());
    
    createBlueprintExample(builder, ctx);
    
    // Print with custom format (not generic)
    OpPrintingFlags flags;
    flags.enableDebugInfo(false);
    flags.printGenericOpForm(false);  // Disable generic form
    m.print(llvm::outs(), flags);
    llvm::outs() << "\n";
    
    return m;
}

void dfscheblueprintmanager::loaddialect(MLIRContext* ctx) {
    ctx->getOrLoadDialect<mlir::func::FuncDialect>();
    ctx->getOrLoadDialect<dfscheblueprint::dfscheblueprintdialect>();
    ctx->getOrLoadDialect<mlir::memref::MemRefDialect>();
    ctx->getOrLoadDialect<mlir::arith::ArithDialect>();
    ctx->getOrLoadDialect<routing::routingdialect>();
}

/**
 * Creates an example schedule blueprint as shown in the user's specification:
 * 
 * schedule.config @tiling_and_broadcast_blueprint {
 *   schedule.transfer_manifest @broadcast_upper_half {
 *     payload_slice = #schedule.slice<...>,
 *     packet_id = 10 : i32,
 *     source = #schedule.endpoint<tile=(2,0), direction="MM2S", channel=0>,
 *     destinations = [
 *       #schedule.endpoint<tile=(2,2), direction="S2MM", channel=0>,
 *       #schedule.endpoint<tile=(2,3), direction="S2MM", channel=0>
 *     ]
 *   }
 *   schedule.transfer_manifest @broadcast_lower_half { ... }
 * }
 */
void dfscheblueprintmanager::createBlueprintExample(OpBuilder& builder, MLIRContext* ctx) {
    auto location = builder.getUnknownLoc();
    
    // Create the top-level schedule.config operation
    auto configOp = builder.create<dfscheblueprint::ConfigOp>(
        location,
        builder.getStringAttr("broadcast_gather_blueprint")
    );
    
    // Set insertion point inside the config body
    Block *configBody = new Block();
    configOp.getBody().push_back(configBody);
    builder.setInsertionPointToStart(configBody);

    // ============================================================
    // 1. Physical Resources
    // ============================================================
    
    // Shim Gateway: tiles = [(0, 2)]
    auto shimTiles = builder.getArrayAttr({
        builder.getArrayAttr({builder.getI64IntegerAttr(0), builder.getI64IntegerAttr(2)})
    });
    builder.create<dfscheblueprint::ResourceGroupOp>(
        location,
        builder.getStringAttr("shim_gateway"),
        shimTiles
    );

    // Compute Row: tiles = [(2, 0), (2, 1), (2, 2), (2, 3)]
    auto computeTiles = builder.getArrayAttr({
        builder.getArrayAttr({builder.getI64IntegerAttr(2), builder.getI64IntegerAttr(0)}),
        builder.getArrayAttr({builder.getI64IntegerAttr(2), builder.getI64IntegerAttr(1)}),
        builder.getArrayAttr({builder.getI64IntegerAttr(2), builder.getI64IntegerAttr(2)}),
        builder.getArrayAttr({builder.getI64IntegerAttr(2), builder.getI64IntegerAttr(3)})
    });
    builder.create<dfscheblueprint::ResourceGroupOp>(
        location,
        builder.getStringAttr("compute_row"),
        computeTiles
    );

    // ============================================================
    // 2. Logical Data View
    // ============================================================
    
    // Create Dummy Tensor
    auto shapeAttr = builder.getI64ArrayAttr({1024, 1024});
    auto dimAttr = builder.getI64IntegerAttr(2);
    auto dummyTensorOp = builder.create<routing::createdummytensor>(
        location,
        builder.getI32Type(), // result type
        shapeAttr,
        dimAttr
    );
    auto dataMatrix = dummyTensorOp.getResult();

    // Partition Tensor
    auto partitionOp = builder.create<routing::partitiontensor>(
        location,
        builder.getI32Type(), // result type
        dataMatrix,
        builder.getI32IntegerAttr(4), // splitnum
        builder.getI32IntegerAttr(0), // splitdim
        builder.getStringAttr(""),    // hw_axis_owner
        builder.getStringAttr(""),    // replicate_on
        builder.getStringAttr("")     // single_tile_owner
    );
    auto partitionResult = partitionOp.getResult();

    // Extract Data (index 0)
    auto indexOp = builder.create<mlir::arith::ConstantOp>(
        location,
        builder.getI32IntegerAttr(0)
    );
    auto extractOpdata = builder.create<routing::extract_data>(
        location,
        builder.getI32Type(), // result type
        partitionResult,
        indexOp.getResult()
    );
    auto viewSplit = extractOpdata.getResult();

    // ============================================================
    // 3. Binding & Channel Config
    // ============================================================

    // Extract partition 0
    auto extractOp = builder.create<dfscheblueprint::ExtractOp>(
        location,
        viewSplit,
        builder.getI32IntegerAttr(0)
    );
    auto extractedView = extractOp.getResult();

    // Create 4 DataSliceOps for output (4x256 each) using extractedView
    auto subSliceType = mlir::TypeAttr::get(mlir::MemRefType::get({4, 256}, builder.getF32Type()));
    auto subSliceSize = builder.getArrayAttr({builder.getI64IntegerAttr(4), builder.getI64IntegerAttr(256)});
    auto subSliceStride = builder.getArrayAttr({builder.getI64IntegerAttr(256), builder.getI64IntegerAttr(1)});
    
    llvm::SmallVector<mlir::Attribute, 4> outSliceSymbols;
    for (int i = 0; i < 4; ++i) {
        std::string sliceName = "out_slice_" + std::to_string(i);
        auto sliceOffset = builder.getArrayAttr({
            builder.getI64IntegerAttr(i * 4), // Offset row by 4 each time
            builder.getI64IntegerAttr(0)
        });
        auto sliceAttr = dfscheblueprint::SliceAttr::get(ctx, subSliceType, sliceOffset, subSliceSize, subSliceStride);
        
        builder.create<dfscheblueprint::DataSliceOp>(
            location,
            builder.getStringAttr(sliceName),
            extractedView,
            sliceAttr
        );
        outSliceSymbols.push_back(mlir::SymbolRefAttr::get(ctx, sliceName));
    }

    // Bind Shim TX
    llvm::SmallVector<int64_t, 1> shimTxCh = {0};
    auto shimTxDMA = dfscheblueprint::DMAAttr::get(ctx, shimTxCh, dfscheblueprint::bp_direction::MM2S);
    builder.create<dfscheblueprint::BindOp>(
        location,
        builder.getStringAttr("bind_shim_tx"),
        mlir::SymbolRefAttr::get(ctx, "shim_gateway"),
        viewSplit,
        builder.getStringAttr("root"),
        shimTxDMA,
        nullptr // slice_symbol
    );

    // Bind Cores Input (S2MM - Receive)
    llvm::SmallVector<int64_t, 1> coresInCh = {0};
    auto coresInDMA = dfscheblueprint::DMAAttr::get(ctx, coresInCh, dfscheblueprint::bp_direction::S2MM);
    builder.create<dfscheblueprint::BindGroupOp>(
        location,
        builder.getStringAttr("bind_cores_in"),
        mlir::SymbolRefAttr::get(ctx, "compute_row"),
        viewSplit,
        builder.getStringAttr("linear"),
        coresInDMA,
        nullptr // slice_symbols
    );

    // Bind Cores Output (MM2S - Send)
    llvm::SmallVector<int64_t, 1> coresOutCh = {1};
    auto coresOutDMA = dfscheblueprint::DMAAttr::get(ctx, coresOutCh, dfscheblueprint::bp_direction::MM2S);
    builder.create<dfscheblueprint::BindGroupOp>(
        location,
        builder.getStringAttr("bind_cores_out"),
        mlir::SymbolRefAttr::get(ctx, "compute_row"),
        viewSplit,
        builder.getStringAttr("linear"),
        coresOutDMA,
        builder.getArrayAttr(outSliceSymbols) // slice_symbols
    );

    // Bind Shim RX
    llvm::SmallVector<int64_t, 1> shimRxCh = {0};
    auto shimRxDMA = dfscheblueprint::DMAAttr::get(ctx, shimRxCh, dfscheblueprint::bp_direction::S2MM);
    builder.create<dfscheblueprint::BindOp>(
        location,
        builder.getStringAttr("bind_shim_rx"),
        mlir::SymbolRefAttr::get(ctx, "shim_gateway"),
        viewSplit,
        builder.getStringAttr("root"),
        shimRxDMA,
        nullptr // slice_symbol
    );

    // ============================================================
    // 4. Collective Transfers
    // ============================================================

    // Input Scatter
    builder.create<dfscheblueprint::CollectiveTransferOp>(
        location,
        builder.getStringAttr("input_scatter"),
        builder.getStringAttr("one_to_many"),
        mlir::SymbolRefAttr::get(ctx, "bind_shim_tx"),
        mlir::SymbolRefAttr::get(ctx, "bind_cores_in"),
        nullptr, // ordering
        builder.getI32IntegerAttr(10)
    );

    // Output Gather
    builder.create<dfscheblueprint::CollectiveTransferOp>(
        location,
        builder.getStringAttr("output_gather"),
        builder.getStringAttr("many_to_one"),
        mlir::SymbolRefAttr::get(ctx, "bind_cores_out"),
        mlir::SymbolRefAttr::get(ctx, "bind_shim_rx"),
        builder.getStringAttr("sequential"),
        builder.getI32IntegerAttr(20)
    );
}

