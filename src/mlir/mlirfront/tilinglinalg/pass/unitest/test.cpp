/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include <iostream>
#include "routinghwmanager.h"
#include "routinghwlower.h"
#include "routingmanager.h"
#include "routinglower.h"
#include "../passroutingtodmap/routingtodmap.h"
#include "../passdmaptodmaphop/dmaptodmaphop.h"
#include "../passdmaphoptoroutinghw/passdmaphoptoroutinghw.h"
#include "routingunrolling.h"
#include "mlir/Conversion/SCFToEmitC/SCFToEmitC.h"
//#include "llvm/IR/IRPrintingPasses.h"
#include "llvm/IRPrinter/IRPrintingPasses.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlow.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"


#include "routingdeadargclean.h"

#include "routingconstantfold.h"

// Unit test function to verify path contiguity for RoutingLowerPass
void testRoutingLowerPassPathContiguity() {
    std::cout << "\n=== Testing RoutingLowerPass Path Contiguity ===" << std::endl;
    
    MLIRContext ctx;
    
    routingmanager mtest;
    routinghwmanager mtesthw;
    mtesthw.loaddialect(&ctx);
    mtest.loaddialect(&ctx);
    ctx.getOrLoadDialect<arith::ArithDialect>();
    
    // Create test module with row-based tiling
    auto module1 = mtest.ops_testNew(&ctx, 1);
    
    // Apply passes up to RoutingLowerPass
    mlir::PassManager pm(&ctx);
    RoutingTopology rtopology("Gen2");
    
    pm.addPass(std::make_unique<RoutingUnrollingLowerPass>());
    pm.addPass(std::make_unique<RoutingLowerPass>(rtopology));
    
    if (failed(pm.run(module1))) {
        std::cerr << "ERROR: Pass execution failed!" << std::endl;
        return;
    }
    
    // Print the module after running the passes
    std::cout << "\n--- Module IR after RoutingLowerPass ---" << std::endl;
    module1.dump();
    std::cout << "--- End of Module IR ---\n" << std::endl;
    
    // Extract and verify path information from the module
    std::cout << "\n--- Verifying Path Contiguity ---" << std::endl;
    
    struct TileLocation {
        int row;
        int col;
        TileLocation(int r = -1, int c = -1) : row(r), col(c) {}
        bool operator==(const TileLocation& other) const {
            return row == other.row && col == other.col;
        }
        bool operator<(const TileLocation& other) const {
            if (row != other.row) return row < other.row;
            return col < other.col;
        }
        bool isValid() const { return row >= 0 && col >= 0; }
        
        // Helper to print in (col, row) format
        std::string toString() const {
            return "( col:" + std::to_string(col) + ",row:" + std::to_string(row) + ")";
        }
    };
    
    struct TileInfo {
        TileLocation loc;
        Operation* op;
        std::string comments;
    };
    
    struct PortConnection {
        Operation* tileOp;
        TileLocation tileLoc;
        std::string slavePortDir;
        int slavePortIdx;
        std::string masterPortDir;
        int masterPortIdx;
    };
    
    // Map to store paths grouped by routing::RoutingCreate operations
    std::map<Operation*, std::vector<TileInfo>> tilesByRoutingCreate;
    std::map<Operation*, std::vector<PortConnection>> connectionsByRoutingCreate;
    
    // Walk through the module to find routing::RoutingCreate operations
    module1.walk([&](Operation* op) {
        if (auto routingCreateOp = dyn_cast<routing::RoutingCreate>(op)) {
            std::vector<TileInfo> tiles;
            std::vector<PortConnection> connections;
            std::map<Operation*, TileLocation> opToLocation;
            
            // First pass: collect all tiles
            routingCreateOp->walk([&](Operation* innerOp) {
                if (auto tileOp = dyn_cast<routinghw::TileCreate>(innerOp)) {
                    if (auto rowAttr = tileOp.getRowAttr()) {
                        if (auto colAttr = tileOp.getColAttr()) {
                            int row = rowAttr.getInt();
                            int col = colAttr.getInt();
                            TileLocation loc(row, col);
                            std::string comments = tileOp.getComments().str();
                            tiles.push_back({loc, tileOp, comments});
                            opToLocation[tileOp] = loc;
                        }
                    }
                } else if (auto shimTileOp = dyn_cast<routinghw::IOShimTileCreate>(innerOp)) {
                    if (auto rowAttr = shimTileOp.getRowAttr()) {
                        if (auto colAttr = shimTileOp.getColAttr()) {
                            int row = rowAttr.getInt();
                            int col = colAttr.getInt();
                            TileLocation loc(row, col);
                            tiles.push_back({loc, shimTileOp, "shim"});
                            opToLocation[shimTileOp] = loc;
                        }
                    }
                }
            });
            
            // Second pass: collect all port connections
            routingCreateOp->walk([&](Operation* innerOp) {
                if (auto connectOp = dyn_cast<routinghw::ConnectStreamSingleSwitchPort>(innerOp)) {
                    // The tile is the first operand of the ConnectStreamSingleSwitchPort operation
                    if (connectOp->getNumOperands() > 0) {
                        Operation* tileOp = connectOp->getOperand(0).getDefiningOp();
                        if (opToLocation.count(tileOp)) {
                            auto slaveDir = connectOp.getSlaveportdirection().str();
                            auto masterDir = connectOp.getMasterportdirection().str();
                            int slaveIdx = connectOp.getSlaveportidx();
                            int masterIdx = connectOp.getMasterportidx();
                            
                            // Skip connections that involve DMA (source or dest)
                            // DMA connections typically use "DMA" in the port direction
                            if (slaveDir == "DMA" || masterDir == "DMA") {
                                std::cout << "  Skipping DMA connection at tile (" << opToLocation[tileOp].col 
                                          << "," << opToLocation[tileOp].row << "): "
                                          << slaveDir << " -> " << masterDir << std::endl;
                                return;
                            }
                            
                            connections.push_back({
                                tileOp,
                                opToLocation[tileOp],
                                slaveDir,
                                slaveIdx,
                                masterDir,
                                masterIdx
                            });
                        }
                    }
                }
            });
            
            if (!tiles.empty()) {
                tilesByRoutingCreate[routingCreateOp] = tiles;
                connectionsByRoutingCreate[routingCreateOp] = connections;
            }
        }
    });
    
    if (tilesByRoutingCreate.empty()) {
        std::cerr << "ERROR: No paths found in the module!" << std::endl;
        return;
    }
    
    std::cout << "Found " << tilesByRoutingCreate.size() << " routing path(s)" << std::endl;
    
    // Helper function to get neighbor location based on direction
    auto getNeighbor = [](const TileLocation& loc, const std::string& dir) -> TileLocation {
        if (dir == "NORTH") return TileLocation(loc.row+1, loc.col );
        if (dir == "SOUTH") return TileLocation(loc.row-1, loc.col );
        if (dir == "EAST") return TileLocation(loc.row, loc.col + 1);
        if (dir == "WEST") return TileLocation(loc.row, loc.col - 1);
        return TileLocation(-1, -1);
    };
    
    // Helper function to check if two tiles are contiguous (adjacent)
    auto isContiguousTiles = [](const TileLocation& tile1, const TileLocation& tile2) -> bool {
        int rowDiff = std::abs(tile2.row - tile1.row);
        int colDiff = std::abs(tile2.col - tile1.col);
        // Contiguous means: (same row and col distance is 1) OR (same col and row distance is 1)
        return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
    };
    
    // Verify each path
    int pathIndex = 0;
    bool allPathsPass = true;
    
    for (const auto& [routingOp, tiles] : tilesByRoutingCreate) {
        pathIndex++;
        std::cout << "\n--- Path " << pathIndex << " ---" << std::endl;
        
        auto& connections = connectionsByRoutingCreate[routingOp];
        
        // ========== STEP 1: Build map for all tile locations and operations ==========
        std::map<TileLocation, TileInfo> tileMap;
        std::map<TileLocation, PortConnection> connectionMap;
        
        for (const auto& tile : tiles) {
            tileMap[tile.loc] = tile;
            std::cout << "Tile at " << tile.loc.toString() << ": " << tile.comments << std::endl;
        }
        
        for (const auto& conn : connections) {
            connectionMap[conn.tileLoc] = conn;
            std::cout << "Connection at " << conn.tileLoc.toString() << ": "
                      << conn.slavePortDir << "[" << conn.slavePortIdx << "] -> "
                      << conn.masterPortDir << "[" << conn.masterPortIdx << "]" << std::endl;
        }
        
        // ========== STEP 2: Find the start point ==========
        // Start point: a tile that has no incoming connection from its slave port direction
        std::cout << "\n--- Step 2: Finding start point ---" << std::endl;
        
        // Build a set of tiles that receive data (have incoming connections)
        std::set<TileLocation> tilesWithIncoming;
        for (const auto& conn : connections) {
            // Master port sends data in masterPortDir direction
            TileLocation targetTile = getNeighbor(conn.tileLoc, conn.masterPortDir);
            if (targetTile.isValid() && tileMap.count(targetTile)) {
                tilesWithIncoming.insert(targetTile);
                std::cout << "  Tile " << targetTile.toString() 
                          << " receives from " << conn.tileLoc.toString() << std::endl;
            }
        }
        
        // Start tiles are those with connections but no incoming data
        std::vector<TileLocation> startTiles;
        // End tiles are those with no outgoing connections
        std::vector<TileLocation> endTiles;
        
        std::set<TileLocation> tilesWithConnections;
        for (const auto& conn : connections) {
            tilesWithConnections.insert(conn.tileLoc);
        }
        
        for (const auto& conn : connections) {
            if (tilesWithIncoming.find(conn.tileLoc) == tilesWithIncoming.end()) {
                startTiles.push_back(conn.tileLoc);
                std::cout << "  Found start tile: " << conn.tileLoc.toString() << std::endl;
            }
        }
        
        // Find end tiles (tiles that are in tileMap but have no outgoing connections)
        for (const auto& [loc, tileInfo] : tileMap) {
            if (tilesWithConnections.find(loc) == tilesWithConnections.end() && 
                tilesWithIncoming.find(loc) != tilesWithIncoming.end()) {
                endTiles.push_back(loc);
                std::cout << "  Found end tile: " << loc.toString() << std::endl;
            }
        }
        
        // Validate: exactly one start point and one end point
        bool hasValidStartEnd = true;
        
        if (startTiles.size() == 0) {
            std::cerr << "✗ ERROR: No start point found for path " << pathIndex << "!" << std::endl;
            allPathsPass = false;
            hasValidStartEnd = false;
        } else if (startTiles.size() > 1) {
            std::cerr << "✗ ERROR: Path " << pathIndex << " has " << startTiles.size() 
                      << " start points (expected 1)!" << std::endl;
            std::cerr << "  Start points: ";
            for (size_t i = 0; i < startTiles.size(); ++i) {
                std::cerr << startTiles[i].toString();
                if (i < startTiles.size() - 1) std::cerr << ", ";
            }
            std::cerr << std::endl;
            allPathsPass = false;
            // Don't set hasValidStartEnd = false, we'll still trace all paths
        }
        
        if (endTiles.size() == 0) {
            std::cerr << "✗ ERROR: No end point found for path " << pathIndex << "!" << std::endl;
            allPathsPass = false;
            hasValidStartEnd = false;
        } else if (endTiles.size() > 1) {
            std::cerr << "✗ ERROR: Path " << pathIndex << " has " << endTiles.size() 
                      << " end points (expected 1)!" << std::endl;
            std::cerr << "  End points: ";
            for (size_t i = 0; i < endTiles.size(); ++i) {
                std::cerr << endTiles[i].toString();
                if (i < endTiles.size() - 1) std::cerr << ", ";
            }
            std::cerr << std::endl;
            allPathsPass = false;
            // Don't set hasValidStartEnd = false, we'll still trace all paths
        }
        
        if (!hasValidStartEnd || startTiles.empty()) {
            std::cout << "✗ FAIL: Path has invalid start/end point configuration!" << std::endl;
            continue;
        }
        
        if (startTiles.size() == 1 && endTiles.size() == 1) {
            std::cout << "✓ Valid path configuration: 1 start point, 1 end point" << std::endl;
        }
        
        // ========== STEP 3: Build path by following master port directions ==========
        // Process each start tile separately if there are multiple
        for (size_t startIdx = 0; startIdx < startTiles.size(); ++startIdx) {
            if (startTiles.size() > 1) {
                std::cout << "\n--- Step 3: Building path from start point " << (startIdx + 1) 
                          << " of " << startTiles.size() << " ---" << std::endl;
            } else {
                std::cout << "\n--- Step 3: Building path from start point ---" << std::endl;
            }
            
            std::vector<TileLocation> path;
            std::set<TileLocation> visited;
            TileLocation currentTile = startTiles[startIdx];
            
            path.push_back(currentTile);
            visited.insert(currentTile);
            std::cout << "Starting at: " << currentTile.toString() << std::endl;
            
            // Follow the path by looking at master port directions
            while (connectionMap.count(currentTile)) {
                const auto& conn = connectionMap[currentTile];
                
                // Find next tile based on master port direction
                TileLocation nextTile = getNeighbor(currentTile, conn.masterPortDir);
                
                std::cout << "  Current tile " << currentTile.toString()
                          << " master port " << conn.masterPortDir 
                          << " points to " << nextTile.toString() << std::endl;
                
                // Check if next tile is valid and in our tile map
                if (!nextTile.isValid() || !tileMap.count(nextTile)) {
                    std::cout << "  Next tile not found in tile map, ending path." << std::endl;
                    break;
                }
                
                // Check for cycles
                if (visited.count(nextTile)) {
                    std::cout << "  Cycle detected at " << nextTile.toString() << ", ending path." << std::endl;
                    break;
                }
                
                // ========== STEP 4: Verify contiguity ==========
                if (!isContiguousTiles(currentTile, nextTile)) {
                    std::cout << "  ✗ ERROR: Non-contiguous hop from " << currentTile.toString()
                              << " to " << nextTile.toString() << std::endl;
                } else {
                    std::cout << "  ✓ Contiguous hop to " << nextTile.toString() << std::endl;
                }
                
                path.push_back(nextTile);
                visited.insert(nextTile);
                currentTile = nextTile;
            }
            
            // ========== Path verification for this start point ==========
            std::cout << "\n--- Path Verification";
            if (startTiles.size() > 1) {
                std::cout << " (Start Point " << (startIdx + 1) << ")";
            }
            std::cout << " ---" << std::endl;
            
            std::cout << "Reconstructed path (" << path.size() << " tiles): ";
            for (size_t i = 0; i < path.size(); ++i) {
                std::cout << path[i].toString();
                if (i < path.size() - 1) std::cout << " -> ";
            }
            std::cout << std::endl;
            
            // Print detailed path with port information
            std::cout << "\nDetailed path with port connections:" << std::endl;
            for (size_t i = 0; i < path.size(); ++i) {
                const TileLocation& tile = path[i];
                std::cout << "  [" << i << "] " << tile.toString();
                
                // Print connection info if this tile has an outgoing connection
                if (connectionMap.count(tile)) {
                    const auto& conn = connectionMap[tile];
                    std::cout << "\n      Source (Slave): " << conn.slavePortDir << "[" << conn.slavePortIdx << "]"
                              << " -> Dest (Master): " << conn.masterPortDir << "[" << conn.masterPortIdx << "]";
                }
                std::cout << std::endl;
            }
            
            // Verify all hops are contiguous
            bool isContiguous = true;
            std::vector<std::string> contiguityErrors;
            
            for (size_t i = 0; i < path.size() - 1; ++i) {
                const TileLocation& current = path[i];
                const TileLocation& next = path[i + 1];
                
                if (!isContiguousTiles(current, next)) {
                    isContiguous = false;
                    std::ostringstream error;
                    error << "Non-contiguous hop from " << current.toString()
                          << " to " << next.toString();
                    contiguityErrors.push_back(error.str());
                }
            }
            
            // Report results
            if (!path.empty()) {
                std::cout << "\nStarting location: " << path[0].toString() << std::endl;
                std::cout << "Ending location: " << path.back().toString() << std::endl;
            }
            
            if (isContiguous && !path.empty()) {
                std::cout << "✓ Contiguity check: Path is contiguous!" << std::endl;
            } else {
                std::cout << "✗ Contiguity check: ";
                if (path.empty()) {
                    std::cout << "Could not reconstruct path!" << std::endl;
                } else {
                    std::cout << "Path has non-contiguous hops!" << std::endl;
                    for (const auto& error : contiguityErrors) {
                        std::cout << "  - " << error << std::endl;
                    }
                }
                allPathsPass = false;
            }
        }
        
        // Final result for this routing path
        if (startTiles.size() == 1 && endTiles.size() == 1) {
            std::cout << "\n✓ PASS: Path is valid and contiguous!" << std::endl;
        } else {
            std::cout << "\n✗ FAIL: Path topology is invalid (multiple start/end points)" << std::endl;
            allPathsPass = false;
        }
    }
    
    // Overall summary
    std::cout << "\n--- Overall Test Results ---" << std::endl;
    std::cout << "Total paths tested: " << tilesByRoutingCreate.size() << std::endl;
    if (allPathsPass) {
        std::cout << "✓ PASS: All paths are contiguous!" << std::endl;
    } else {
        std::cout << "✗ FAIL: One or more paths have issues!" << std::endl;
    }
    
    std::cout << "\n=== Test Complete ===" << std::endl;
}

void routingtoroutinghw() {
     MLIRContext ctx;
    
    routingmanager mtest;
    routinghwmanager mtesthw;
    mtesthw.loaddialect(&ctx);
    mtest.loaddialect(&ctx);

    ctx.getOrLoadDialect<arith::ArithDialect>();
    
    //auto module1 = mtest.createroutingfunc(&ctx,1);
    auto module1 = mtest.ops_testNew(&ctx,1);
    module1.dump();
    //auto module2 = mtesthw.ops_test(&ctx);
    std::cout << "main" <<std::endl;
    
    mlir::PrintIRPassOptions options;

    mlir::PassManager pm(&ctx);;
    RoutingTopology rtopology("Gen2");
    
    options.label = "Before RoutingUnrollingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingUnrollingLowerPass>());
    options.label = "After RoutingUnrollingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingLowerPass>(rtopology));
    options.label = "After RoutingLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    options.label = "After RoutingHWLowerPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //remove dead arg
    pm.addPass(std::make_unique<RoutingDeadArgPass>());
    options.label = "After RoutingDeadArgPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //The constanfold change emitc.call into emic.call_opaque to convert 
    /*
    XAie_LocType v251 = XAie_TileLoc(v1, v10);
    XAie_DevInst* v252 = getOrCreateDeviceInstance();
    int32_t v253 = XAie_StrmConnCctEnable(v252, v251, v6, v13, v5, v12);
    */
    //into
    /*
    int32_t v80 = XAie_StrmConnCctEnable(getOrCreateDeviceInstance(), XAie_TileLoc(6,3), WEST, 0, EAST, 0); 
    */
    pm.addPass(std::make_unique<RoutingConstantFoldPass>());

    options.label = "After RoutingConstantFoldPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    //remove the dead code
    pm.addPass(mlir::createCanonicalizerPass());

    options.label = "After createCanonicalizerPasse:";
    pm.addPass(mlir::createPrintIRPass(options));

    //remove dead arg
    //pm.addPass(mlir::createConvertSCFToEmitCPass());
    (void)pm.run(module1);

    llvm::outs() << "----------module1.dump---------\n";
    module1.dump();
/*
    mlir::PassManager pm2(&ctx);;
    pm2.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    (void)pm2.run(module1);
    module1.dump();
  */
//conver emitc into c code  
    mlir::LogicalResult result = mlir::emitc::translateToCpp(module1, llvm::outs());
    return;
}
void routingtodmap() {
     MLIRContext ctx;
    
    routingmanager mtest;
    routinghwmanager mtesthw;
    dmapmanager mdmaptest;
    dmaphopmanager dmaphoptest;
    mtesthw.loaddialect(&ctx);
    mtest.loaddialect(&ctx);
    mdmaptest.loaddialect(&ctx);
    dmaphoptest.loaddialect(&ctx);

    ctx.getOrLoadDialect<arith::ArithDialect>();
    
    //auto module1 = mtest.createroutingfunc(&ctx,1);
    auto module1 = mtest.ops_testNew(&ctx,1);
    module1.dump();
    //auto module2 = mtesthw.ops_test(&ctx);
    std::cout << "main" <<std::endl;
    
    mlir::PrintIRPassOptions options;

    mlir::PassManager pm(&ctx);;
    RoutingTopology rtopology("Gen2");
    
    options.label = "Before RoutingUnrollingLowerPass:";
    //pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingUnrollingLowerPass>());
    options.label = "After RoutingToDmapPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingToDmapPass>(rtopology));
    options.label = "After DmapToDmaphopPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<DmapToDmaphopPass>(rtopology));
    options.label = "After DmaphopToRoutinghwPass:";
    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<DmaphopToRoutinghwPass>(rtopology));

    pm.addPass(mlir::createPrintIRPass(options));
    pm.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    options.label = "After RoutingHWLowerPass:";
    //pm.addPass(mlir::createPrintIRPass(options));
    //remove dead arg
    pm.addPass(std::make_unique<RoutingDeadArgPass>());
    
    //into
    /*
    int32_t v80 = XAie_StrmConnCctEnable(getOrCreateDeviceInstance(), XAie_TileLoc(6,3), WEST, 0, EAST, 0); 
    */
    pm.addPass(std::make_unique<RoutingConstantFoldPass>());

    options.label = "After RoutingConstantFoldPass:";
    //pm.addPass(mlir::createPrintIRPass(options));
    //remove the dead code
    pm.addPass(mlir::createCanonicalizerPass());

    options.label = "After createCanonicalizerPasse:";
    //pm.addPass(mlir::createPrintIRPass(options));

    //remove dead arg
    //pm.addPass(mlir::createConvertSCFToEmitCPass());
    (void)pm.run(module1);

    llvm::outs() << "----------module1.dump---------\n";
    //module1.dump();
/*
    mlir::PassManager pm2(&ctx);;
    pm2.addPass(std::make_unique<RoutingHWLowerPass>(rtopology));
    (void)pm2.run(module1);
    module1.dump();
  */
//conver emitc into c code  
    mlir::LogicalResult result = mlir::emitc::translateToCpp(module1, llvm::outs());
    if (failed(result)) {
        llvm::errs() << "Failed to translate MLIR to C++.\n";
        return;
    }
    return;
}
int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string arg = argv[1];
        if (arg == "hw") {
            std::cout << "Executing routingtoroutinghw..." << std::endl;
            routingtoroutinghw();
        } else if (arg == "test") {
            std::cout << "Executing unit test for RoutingLowerPass..." << std::endl;
            testRoutingLowerPassPathContiguity();
        } else {
            std::cout << "Executing routingtodmap..." << std::endl;
            routingtodmap();
        }
    } else {
        // Default behavior when no argument is provided
        std::cout << "No argument provided. Executing routingtodmap by default..." << std::endl;
        routingtodmap();
    }
    return 0;

}