/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "dfscheblueprintmanager.h"
#include <iostream>

#define GET_TYPEDEF_CLASSES
#define GET_ATTRDEF_CLASSES
#define GET_OP_CLASSES
#define GET_OP_DEFS
#include "dfscheblueprintdialect.cc.inc"
#include "dfscheblueprintattr.cc.inc"
#include "dfscheblueprinttype.cc.inc"
#include "dfscheblueprintenums.cc.inc"

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
        builder.getStringAttr("tiling_and_broadcast_blueprint")
    );
    /*
    // Set insertion point inside the config body
    Block *configBody = new Block();
    configOp.getBody().push_back(configBody);
    builder.setInsertionPointToStart(configBody);
    
    // --- Transfer Manifest 1: broadcast_upper_half ---
    
    // Create payload_slice attribute for upper half
    auto memrefType1024x1024 = mlir::MemRefType::get({1024, 1024}, builder.getF32Type());
    auto dataTypeAttr = mlir::TypeAttr::get(memrefType1024x1024);
    
    auto offsetAttr = builder.getArrayAttr({
        builder.getI64IntegerAttr(0),
        builder.getI64IntegerAttr(0)
    });
    
    auto sizeAttrUpper = builder.getArrayAttr({
        builder.getI64IntegerAttr(512),
        builder.getI64IntegerAttr(1024)
    });
    
    auto strideAttr = builder.getArrayAttr({
        builder.getI64IntegerAttr(1024),
        builder.getI64IntegerAttr(1)
    });
    
    auto sliceAttrUpper = dfscheblueprint::SliceAttr::get(
        ctx,
        dataTypeAttr,
        offsetAttr,
        sizeAttrUpper,
        strideAttr
    );
    
    // Create source endpoint: tile=(0,2), direction="MM2S", channel=0
    auto sourceEndpoint = dfscheblueprint::EndpointAttr::get(
        ctx,
        0,  // row
        2,  // col
        builder.getStringAttr("MM2S"),
        0  // channel
    );
    
    // Create destination endpoints
    auto dest1 = dfscheblueprint::EndpointAttr::get(
        ctx,
        2,  // row
        2,  // col
        builder.getStringAttr("S2MM"),
        0  // channel
    );
    
    auto dest2 = dfscheblueprint::EndpointAttr::get(
        ctx,
        3,  // row
        2,  // col
        builder.getStringAttr("S2MM"),
        0  // channel
    );
    
    auto destinationsAttr = builder.getArrayAttr({dest1, dest2});
    
    // Create the transfer manifest operation
    builder.create<dfscheblueprint::TransferManifestOp>(
        location,
        builder.getStringAttr("broadcast_upper_half"),
        sliceAttrUpper,
        builder.getI32IntegerAttr(10),  // packet_id
        sourceEndpoint,
        destinationsAttr
    );
    
    // --- Transfer Manifest 2: broadcast_lower_half ---
    
    auto offsetAttrLower = builder.getArrayAttr({
        builder.getI64IntegerAttr(512),  // Start from row 512
        builder.getI64IntegerAttr(0)
    });
    
    auto sizeAttrLower = builder.getArrayAttr({
        builder.getI64IntegerAttr(512),
        builder.getI64IntegerAttr(1024)
    });
    
    auto sliceAttrLower = dfscheblueprint::SliceAttr::get(
        ctx,
        dataTypeAttr,
        offsetAttrLower,
        sizeAttrLower,
        strideAttr
    );
    
    // Source endpoint (same as before)
    auto sourceEndpointLower = dfscheblueprint::EndpointAttr::get(
        ctx,
        0,  // row
        2,  // col
        builder.getStringAttr("MM2S"),
        0  // channel
    );
    
    // Different destination endpoints for lower half
    auto dest3 = dfscheblueprint::EndpointAttr::get(
        ctx,
        4,  // row
        2,  // col
        builder.getStringAttr("S2MM"),
        0  // channel
    );
    
    auto dest4 = dfscheblueprint::EndpointAttr::get(
        ctx,
        5,  // row
        2,  // col
        builder.getStringAttr("S2MM"),
        0  // channel
    );
    
    auto destinationsAttrLower = builder.getArrayAttr({dest3, dest4});
    
    // Create the second transfer manifest
    builder.create<dfscheblueprint::TransferManifestOp>(
        location,
        builder.getStringAttr("broadcast_lower_half"),
        sliceAttrLower,
        builder.getI32IntegerAttr(11),  // Different packet_id
        sourceEndpointLower,
        destinationsAttrLower
    );
    */
}

