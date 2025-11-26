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

// DataSliceOp printer
void dfscheblueprint::DataSliceOp::print(OpAsmPrinter &printer) {
    printer << " @" << getSymName() << " {";
    printer << "\n          view = " << getView() << " : " << getView().getType() << ",";
    printer << "\n          slice = " << getSliceParams();
    printer << " \n     }";
    printer.printOptionalAttrDict(getOperation()->getAttrs(), /*elidedAttrs=*/{"sym_name", "view", "slice_params"});
}

// DataSliceOp parser
ParseResult dfscheblueprint::DataSliceOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();
    
    if (parser.parseLBrace())
        return failure();
    
    OpAsmParser::UnresolvedOperand viewOperand;
    Type viewType;
    dfscheblueprint::SliceAttr sliceParams;
    
    while (true) {
        StringRef attrName;
        if (parser.parseOptionalKeyword(&attrName)) {
            break;
        }
        
        if (parser.parseEqual())
            return failure();
        
        if (attrName == "view") {
            if (parser.parseOperand(viewOperand) || parser.parseColonType(viewType))
                return failure();
        } else if (attrName == "slice") {
            if (parser.parseAttribute(sliceParams))
                return failure();
        }
        
        parser.parseOptionalComma();
    }
    
    if (parser.parseRBrace())
        return failure();
    
    if (parser.resolveOperand(viewOperand, viewType, result.operands))
        return failure();
        
    result.addAttribute("slice_params", sliceParams);
    parser.parseOptionalAttrDict(result.attributes);
    
    return success();
}

// BindGroupOp printer
void dfscheblueprint::BindGroupOp::print(OpAsmPrinter &printer) {
    printer << " @" << getSymName() << " {";
    printer << "\n          target_group = " << getTargetGroup() << ",";
    printer << "\n          view = " << getView() << " : " << getView().getType() << ",";
    printer << "\n          distribution = \"" << getDistribution() << "\",";
    printer << "\n          dma = " << getDma();
    if (getSliceSymbols()) {
        printer << ",\n          slice_symbols = " << getSliceSymbols();
    }
    printer << " \n     }";
    printer.printOptionalAttrDict(getOperation()->getAttrs(), 
        /*elidedAttrs=*/{"sym_name", "target_group", "view", "distribution", "dma", "slice_symbols"});
}

// BindGroupOp parser
ParseResult dfscheblueprint::BindGroupOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();
    
    if (parser.parseLBrace())
        return failure();
    
    SymbolRefAttr targetGroup;
    OpAsmParser::UnresolvedOperand viewOperand;
    Type viewType;
    StringAttr distribution;
    dfscheblueprint::DMAAttr dma;
    ArrayAttr sliceSymbols;
    
    while (true) {
        OptionalParseResult res = parser.parseOptionalRBrace();
        if (res.has_value()) {
            if (failed(res.value())) return failure();
            break;
        }

        StringRef attrName;
        if (parser.parseKeyword(&attrName) || parser.parseEqual())
            return failure();
        
        if (attrName == "target_group") {
            if (parser.parseAttribute(targetGroup, "target_group", result.attributes)) return failure();
        } else if (attrName == "view") {
            if (parser.parseOperand(viewOperand) || parser.parseColonType(viewType))
                return failure();
        } else if (attrName == "distribution") {
            if (parser.parseAttribute(distribution, "distribution", result.attributes)) return failure();
        } else if (attrName == "dma") {
            if (parser.parseAttribute(dma, "dma", result.attributes)) return failure();
        } else if (attrName == "slice_symbols") {
            if (parser.parseAttribute(sliceSymbols, "slice_symbols", result.attributes)) return failure();
        } else {
             return parser.emitError(parser.getCurrentLocation(), "unknown attribute: ") << attrName;
        }
        
        parser.parseOptionalComma();
    }
    
    if (parser.resolveOperand(viewOperand, viewType, result.operands))
        return failure();
        
    parser.parseOptionalAttrDict(result.attributes);
    
    return success();
}

// BindOp printer
void dfscheblueprint::BindOp::print(OpAsmPrinter &printer) {
    printer << " @" << getSymName() << " {";
    printer << "\n          target = " << getTarget() << ",";
    printer << "\n          view = " << getView() << " : " << getView().getType() << ",";
    printer << "\n          slice = \"" << getSlice() << "\",";
    printer << "\n          dma = " << getDma();
    if (getSliceSymbol()) {
        printer << ",\n          slice_symbol = " << getSliceSymbol();
    }
    printer << " \n     }";
    printer.printOptionalAttrDict(getOperation()->getAttrs(), 
        /*elidedAttrs=*/{"sym_name", "target", "view", "slice", "dma", "slice_symbol"});
}

// BindOp parser
ParseResult dfscheblueprint::BindOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();
    
    if (parser.parseLBrace())
        return failure();
    
    SymbolRefAttr target;
    OpAsmParser::UnresolvedOperand viewOperand;
    Type viewType;
    StringAttr slice;
    dfscheblueprint::DMAAttr dma;
    SymbolRefAttr sliceSymbol;
    
    while (true) {
        OptionalParseResult res = parser.parseOptionalRBrace();
        if (res.has_value()) {
            if (failed(res.value())) return failure();
            break;
        }

        StringRef attrName;
        if (parser.parseKeyword(&attrName) || parser.parseEqual())
            return failure();
        
        if (attrName == "target") {
            if (parser.parseAttribute(target, "target", result.attributes)) return failure();
        } else if (attrName == "view") {
            if (parser.parseOperand(viewOperand) || parser.parseColonType(viewType))
                return failure();
        } else if (attrName == "slice") {
            if (parser.parseAttribute(slice, "slice", result.attributes)) return failure();
        } else if (attrName == "dma") {
            if (parser.parseAttribute(dma, "dma", result.attributes)) return failure();
        } else if (attrName == "slice_symbol") {
            if (parser.parseAttribute(sliceSymbol, "slice_symbol", result.attributes)) return failure();
        } else {
             return parser.emitError(parser.getCurrentLocation(), "unknown attribute: ") << attrName;
        }
        
        parser.parseOptionalComma();
    }
    
    if (parser.resolveOperand(viewOperand, viewType, result.operands))
        return failure();
        
    parser.parseOptionalAttrDict(result.attributes);
    
    return success();
}

// CollectiveTransferOp printer
void dfscheblueprint::CollectiveTransferOp::print(OpAsmPrinter &printer) {
    printer << " @" << getSymName() << " {";
    printer << "\n          type = \"" << getType() << "\",";
    printer << "\n          from = " << getFrom() << ",";
    printer << "\n          to = " << getTo();
    if (getOrdering()) {
        printer << ",\n          ordering = \"" << getOrdering() << "\"";
    }
    printer << ",\n          base_packet_id = " << getBasePacketId();
    printer << " \n     }";
    printer.printOptionalAttrDict(getOperation()->getAttrs(), 
        /*elidedAttrs=*/{"sym_name", "type", "from", "to", "ordering", "base_packet_id"});
}

// CollectiveTransferOp parser
ParseResult dfscheblueprint::CollectiveTransferOp::parse(OpAsmParser &parser, OperationState &result) {
    StringAttr nameAttr;
    if (parser.parseSymbolName(nameAttr, mlir::SymbolTable::getSymbolAttrName(), result.attributes))
        return failure();
    
    if (parser.parseLBrace())
        return failure();
    
    StringAttr type;
    SymbolRefAttr from;
    SymbolRefAttr to;
    StringAttr ordering;
    IntegerAttr basePacketId;
    
    while (true) {
        OptionalParseResult res = parser.parseOptionalRBrace();
        if (res.has_value()) {
            if (failed(res.value())) return failure();
            break;
        }

        StringRef attrName;
        if (parser.parseKeyword(&attrName) || parser.parseEqual())
            return failure();
        
        if (attrName == "type") {
            if (parser.parseAttribute(type, "type", result.attributes)) return failure();
        } else if (attrName == "from") {
            if (parser.parseAttribute(from, "from", result.attributes)) return failure();
        } else if (attrName == "to") {
            if (parser.parseAttribute(to, "to", result.attributes)) return failure();
        } else if (attrName == "ordering") {
            if (parser.parseAttribute(ordering, "ordering", result.attributes)) return failure();
        } else if (attrName == "base_packet_id") {
            if (parser.parseAttribute(basePacketId, "base_packet_id", result.attributes)) return failure();
        } else {
             return parser.emitError(parser.getCurrentLocation(), "unknown attribute: ") << attrName;
        }
        
        parser.parseOptionalComma();
    }
    
    parser.parseOptionalAttrDict(result.attributes);
    
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
    //auto extractOp = builder.create<dfscheblueprint::ExtractOp>(
    //    location,
    //    viewSplit,
    //    builder.getI32IntegerAttr(0)
    //);
    //auto extractedView = extractOp.getResult();

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
            viewSplit,
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

