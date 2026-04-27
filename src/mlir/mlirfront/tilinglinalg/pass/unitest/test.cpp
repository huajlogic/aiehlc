/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#include "../passblueprinttoschedule/passblueprinttoschedule.h"
#include "../passblueprinttoschedulekernel/passblueprinttoschedulekernel.h"
#include "../passdfscheduletoapi/passdfscheduletoapi.h"
#include "../passdfscheduletokernelapi/passdfscheduletokernelapi.h"
#include "../passdmaphoptodfscheblueprint/passdmaphoptodfscheblueprint.h"
#include "../passdmaphoptoroutinghw/passdmaphoptoroutinghw.h"
#include "../passdmaptodmaphop/dmaptodmaphop.h"
#include "../passroutingtodmap/routingtodmap.h"
#include "../passschedulecanonicalize/passschedulecanonicalize.h"
#include "dfscheblueprintmanager.h"
#include "dfschedulemanager.h"
#include "dmaphopmanager.h"
#include "dmapmanager.h"
#include "mlir/Conversion/SCFToEmitC/SCFToEmitC.h"
#include "mlir/Dialect/Tensor/IR/Tensor.h"
#include "routinghwlower.h"
#include "routinghwmanager.h"
#include "routinghwverify.h"
#include "routinglower.h"
#include "routingmanager.h"
#include "routingunrolling.h"
#include <iostream>
//#include "llvm/IR/IRPrintingPasses.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/IRPrinter/IRPrintingPasses.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/Parser/Parser.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlow.h"
#include "mlir/Dialect/Bufferization/IR/Bufferization.h"
#include "mlir/Dialect/EmitC/IR/EmitC.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"


#include "routingdeadargclean.h"

#include "../kernelconfig/kernelconfig.h"
#include "../passkernelgraphtorouting/passkernelgraphtorouting.h"
#include "../tilinglinalg_pipeline.h"
#include "hw/ResourceManager.h"
#include "kernelgraphmanager.h"
#include "mlir/Transforms/Passes.h"
#include "routingconstantfold.h"

// ---------------------------------------------------------------------------
// IR dump helpers
// ---------------------------------------------------------------------------

static std::string setupIRDir(const std::string &subdir) {
    llvm::SmallString<256> cwdPath;
    if (std::error_code EC = llvm::sys::fs::current_path(cwdPath)) {
        llvm::errs() << "Failed to get current directory: " << EC.message() << "\n";
        return "";
    }
    std::string dir = (cwdPath + "/ir/" + subdir).str();
    if (std::error_code EC = llvm::sys::fs::create_directories(dir)) {
        llvm::errs() << "Failed to create IR directory " << dir << ": " << EC.message() << "\n";
        return "";
    }
    std::cout << "IR output directory: " << dir << std::endl;
    return dir;
}

static std::string setupWorklocalDir() {
    llvm::SmallString<256> cwdPath;
    if (std::error_code EC = llvm::sys::fs::current_path(cwdPath)) {
        llvm::errs() << "Failed to get current directory: " << EC.message() << "\n";
        return "";
    }
    std::string dir = (cwdPath + "/worklocal").str();
    if (std::error_code EC = llvm::sys::fs::create_directories(dir)) {
        llvm::errs() << "Failed to create directory " << dir << ": " << EC.message() << "\n";
        return "";
    }
    return dir;
}

static void dumpIRToFile(mlir::ModuleOp module, const std::string &dir, int stage, const std::string &passName) {
    if (dir.empty())
        return;
    std::string filename = dir + "/" + std::to_string(stage) + "_" + passName + ".mlir";
    std::error_code ec;
    llvm::raw_fd_ostream os(filename, ec, llvm::sys::fs::OF_None);
    if (ec) {
        llvm::errs() << "Failed to write IR to " << filename << ": " << ec.message() << "\n";
        return;
    }
    module.print(os);
    std::cout << "  IR -> " << filename << std::endl;
}

static bool runSinglePass(MLIRContext &ctx, mlir::ModuleOp module, std::unique_ptr<mlir::Pass> pass,
                          const std::string &irDir, int &stage, const std::string &passName) {
    mlir::PassManager singlePm(&ctx);
    singlePm.addPass(std::move(pass));
    if (failed(singlePm.run(module))) {
        llvm::errs() << "ERROR: " << passName << " failed!\n";
        return false;
    }
    dumpIRToFile(module, irDir, stage, passName);
    stage++;
    return true;
}

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
    
    // Helper function to get neighbor location based on direction
    auto getNeighbor = [](const TileLocation& loc, const std::string& dir) -> TileLocation {
        if (dir == "NORTH") return TileLocation(loc.row + 1, loc.col);
        if (dir == "SOUTH") return TileLocation(loc.row - 1, loc.col);
        if (dir == "EAST") return TileLocation(loc.row, loc.col + 1);
        if (dir == "WEST") return TileLocation(loc.row, loc.col - 1);
        return TileLocation(-1, -1);
    };
    
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
            
            // Helper to check if a tile location exists in our tile set
            auto tileExists = [&opToLocation](const TileLocation& loc) -> bool {
                for (const auto& [op, tileLoc] : opToLocation) {
                    if (tileLoc == loc) return true;
                }
                return false;
            };
            
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
                                std::cout << "  Skipping DMA connection at tile " << opToLocation[tileOp].toString() 
                                          << ": " << slaveDir << " -> " << masterDir << std::endl;
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
                } else if (auto pktConnectOp = dyn_cast<routinghw::ConnectStreamPktSwitchPort>(innerOp)) {
                    // Handle packet switch port connections
                    if (pktConnectOp->getNumOperands() > 0) {
                        Operation* tileOp = pktConnectOp->getOperand(0).getDefiningOp();
                        if (opToLocation.count(tileOp)) {
                            auto receiveSlaveDir = pktConnectOp.getReceiveslavedirection().str();
                            auto localDmaDir = pktConnectOp.getLocaldmadirection().str();
                            auto forwardMasterDir = pktConnectOp.getForwardmasterdirection().str();
                            
                            int receiveSlaveIdx = pktConnectOp.getReceiveslaveportidx();
                            int localDmaIdx = pktConnectOp.getLocaldmaportidx();
                            int forwardMasterIdx = pktConnectOp.getForwardmasterportidx();
                            
                            // For packet connections with DMA:
                            // - If localdmadirection == "DMA", the tile has a DMA that sends data
                            // - The forwardmasterdirection shows where DMA data goes
                            // - The receiveslavedirection shows if tile receives from neighbor
                            
                            bool hasDma = (localDmaDir == "DMA");
                            bool receivesFromNeighbor = (receiveSlaveDir != "DMA" && receiveSlaveDir != "NONE");
                            bool forwardsToNeighbor = (forwardMasterDir != "DMA" && forwardMasterDir != "NONE");
                            
                            if (hasDma) {
                                // Case 1: DMA sends to a neighbor (DMA -> stream out)
                                // This creates an outgoing connection
                                if (forwardsToNeighbor) {
                                    connections.push_back({
                                        tileOp,
                                        opToLocation[tileOp],
                                        localDmaDir,  // DMA as source (slave)
                                        localDmaIdx,
                                        forwardMasterDir,  // Direction to neighbor (master)
                                        forwardMasterIdx
                                    });
                                    std::cout << "  PKT connection (DMA->stream) at tile " << opToLocation[tileOp].toString() 
                                              << ": DMA[" << localDmaIdx << "] -> "
                                              << forwardMasterDir << "[" << forwardMasterIdx << "]" << std::endl;
                                }
                                
                                // Case 2: Tile also receives from neighbor -> DMA
                                // This creates an incoming connection that feeds the DMA
                                if (receivesFromNeighbor) {
                                    connections.push_back({
                                        tileOp,
                                        opToLocation[tileOp],
                                        receiveSlaveDir,  // Receive from neighbor (slave)
                                        receiveSlaveIdx,
                                        localDmaDir,  // To DMA (master)
                                        localDmaIdx
                                    });
                                    std::cout << "  PKT connection (stream->DMA) at tile " << opToLocation[tileOp].toString()
                                              << ": " << receiveSlaveDir << "[" << receiveSlaveIdx << "] -> "
                                              << "DMA[" << localDmaIdx << "]" << std::endl;
                                }
                            } else {
                                // Case 3: Pure stream-to-stream forwarding (no DMA involved)
                                if (receivesFromNeighbor && forwardsToNeighbor) {
                                    connections.push_back({
                                        tileOp,
                                        opToLocation[tileOp],
                                        receiveSlaveDir,
                                        receiveSlaveIdx,
                                        forwardMasterDir,
                                        forwardMasterIdx
                                    });
                                    std::cout << "  PKT connection (stream->stream) at tile " << opToLocation[tileOp].toString()
                                              << ": " << receiveSlaveDir << "[" << receiveSlaveIdx << "] -> "
                                              << forwardMasterDir << "[" << forwardMasterIdx << "]" << std::endl;
                                }
                            }
                        }
                    }
                }
            });
            
            // **NEW: Third pass - infer DMA output connections for packet switches with NONE forward**
            // This handles the case where a tile has DMA but forwardmasterdirection = "NONE"
            // We infer the output direction by finding neighbors that receive from this tile
            routingCreateOp->walk([&](Operation* innerOp) {
                if (auto pktConnectOp = dyn_cast<routinghw::ConnectStreamPktSwitchPort>(innerOp)) {
                    if (pktConnectOp->getNumOperands() > 0) {
                        Operation* tileOp = pktConnectOp->getOperand(0).getDefiningOp();
                        if (opToLocation.count(tileOp)) {
                            auto localDmaDir = pktConnectOp.getLocaldmadirection().str();
                            auto forwardMasterDir = pktConnectOp.getForwardmasterdirection().str();
                            int localDmaIdx = pktConnectOp.getLocaldmaportidx();
                            
                            // Only process tiles with DMA and no explicit forward direction
                            if (localDmaDir == "DMA" && forwardMasterDir == "NONE") {
                                TileLocation dmaLoc = opToLocation[tileOp];
                                std::cout << "  Checking DMA tile at " << dmaLoc.toString() 
                                          << " for implicit output connections..." << std::endl;
                                
                                // Check all 4 directions for tiles that receive from this DMA tile
                                std::vector<std::string> directions = {"NORTH", "SOUTH", "EAST", "WEST"};
                                
                                for (const auto& dir : directions) {
                                    TileLocation neighborLoc = getNeighbor(dmaLoc, dir);
                                    if (!neighborLoc.isValid() || !tileExists(neighborLoc)) continue;
                                    
                                    // What direction does neighbor use to receive from us?
                                    std::string oppositeDir = "";
                                    if (dir == "NORTH") oppositeDir = "SOUTH";
                                    else if (dir == "SOUTH") oppositeDir = "NORTH";
                                    else if (dir == "EAST") oppositeDir = "WEST";
                                    else if (dir == "WEST") oppositeDir = "EAST";
                                    
                                    // Check if neighbor has a connection receiving from oppositeDir
                                    bool foundReceiver = false;
                                    routingCreateOp->walk([&](Operation* checkOp) {
                                        if (auto checkConnect = dyn_cast<routinghw::ConnectStreamSingleSwitchPort>(checkOp)) {
                                            if (checkConnect->getNumOperands() > 0) {
                                                Operation* checkTileOp = checkConnect->getOperand(0).getDefiningOp();
                                                if (opToLocation.count(checkTileOp) && 
                                                    opToLocation[checkTileOp] == neighborLoc) {
                                                    auto slaveDir = checkConnect.getSlaveportdirection().str();
                                                    if (slaveDir == oppositeDir) {
                                                        foundReceiver = true;
                                                    }
                                                }
                                            }
                                        }
                                    });
                                    
                                    if (foundReceiver) {
                                        // Found a neighbor that receives from this DMA tile
                                        // Create the inferred DMA output connection
                                        connections.push_back({
                                            tileOp,
                                            dmaLoc,
                                            localDmaDir,  // DMA as source
                                            localDmaIdx,
                                            dir,  // Direction to neighbor
                                            0  // Use index 0 for inferred connection
                                        });
                                        std::cout << "  ✓ Inferred DMA output: " << dmaLoc.toString()
                                                  << " DMA[" << localDmaIdx << "] -> " << dir 
                                                  << " to neighbor " << neighborLoc.toString() << std::endl;
                                        break;  // Found the output, stop checking other directions
                                    }
                                }
                            }
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
        // Changed from map to multimap to support multiple connections per tile
        std::multimap<TileLocation, PortConnection> connectionMap;
        
        for (const auto& tile : tiles) {
            tileMap[tile.loc] = tile;
            std::cout << "Tile at " << tile.loc.toString() << ": " << tile.comments << std::endl;
        }
        
        for (const auto& conn : connections) {
            connectionMap.insert({conn.tileLoc, conn});
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
            // Skip if master is DMA (not a tile-to-tile connection)
            if (conn.masterPortDir == "DMA") continue;
            
            TileLocation targetTile = getNeighbor(conn.tileLoc, conn.masterPortDir);
            if (targetTile.isValid() && tileMap.count(targetTile)) {
                tilesWithIncoming.insert(targetTile);
                std::cout << "  Tile " << targetTile.toString() 
                          << " receives from " << conn.tileLoc.toString() 
                          << " via " << conn.masterPortDir << std::endl;
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
        
        // Find tiles with outgoing connections (excluding DMA-only)
        std::set<TileLocation> tilesWithOutgoing;
        for (const auto& conn : connections) {
            if (conn.masterPortDir != "DMA") {
                tilesWithOutgoing.insert(conn.tileLoc);
                if (tilesWithIncoming.find(conn.tileLoc) == tilesWithIncoming.end()) {
                    // This tile sends but doesn't receive - it's a start point
                    if (std::find(startTiles.begin(), startTiles.end(), conn.tileLoc) == startTiles.end()) {
                        startTiles.push_back(conn.tileLoc);
                        std::cout << "  Found start tile: " << conn.tileLoc.toString() << std::endl;
                    }
                }
            }
        }
        
        // Find end tiles (tiles that receive but have no outgoing tile-to-tile connections)
        for (const auto& [loc, tileInfo] : tileMap) {
            if (tilesWithIncoming.find(loc) != tilesWithIncoming.end() &&
                tilesWithOutgoing.find(loc) == tilesWithOutgoing.end()) {
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
            while (true) {
                // Find outgoing connection to next tile (not DMA)
                auto range = connectionMap.equal_range(currentTile);
                bool foundNext = false;
                
                for (auto it = range.first; it != range.second; ++it) {
                    const auto& conn = it->second;
                    
                    // Skip DMA connections - we're looking for tile-to-tile
                    if (conn.masterPortDir == "DMA") continue;
                    
                    // Find next tile based on master port direction
                    TileLocation nextTile = getNeighbor(currentTile, conn.masterPortDir);
                    
                    std::cout << "  Current tile " << currentTile.toString()
                              << " master port " << conn.masterPortDir 
                              << " points to " << nextTile.toString() << std::endl;
                    
                    // Check if next tile is valid and in our tile map
                    if (!nextTile.isValid() || !tileMap.count(nextTile)) {
                        std::cout << "  Next tile not found in tile map." << std::endl;
                        continue;
                    }
                    
                    // Check for cycles
                    if (visited.count(nextTile)) {
                        std::cout << "  Cycle detected at " << nextTile.toString() << ", skipping." << std::endl;
                        continue;
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
                    foundNext = true;
                    break;  // Follow first valid outgoing connection
                }
                
                if (!foundNext) {
                    std::cout << "  No more outgoing connections, ending path." << std::endl;
                    break;
                }
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
                
                // Print all connection info for this tile
                auto range = connectionMap.equal_range(tile);
                if (range.first != range.second) {
                    std::cout << "\n      Connections:";
                    for (auto it = range.first; it != range.second; ++it) {
                        const auto& conn = it->second;
                        std::cout << "\n        " << conn.slavePortDir << "[" << conn.slavePortIdx << "]"
                                  << " -> " << conn.masterPortDir << "[" << conn.masterPortIdx << "]";
                    }
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

// ---------------------------------------------------------------------------
// IR dialect validation
// ---------------------------------------------------------------------------

// Pipeline stage order (earliest to latest):
//   routing -> dmap -> dmaphop -> dfscheblueprint -> dfschedule
//   routing -> routinghw  (alternative path)
//
// If the user says "--parse routing <file>", the file must contain routing
// dialect ops and must NOT contain ops from a later stage.

// Detect whether a post-branch module is host or kernel IR.
// Returns "host", "kernel", or "unknown".
static std::string detectHostOrKernel(mlir::ModuleOp module) {
    bool isHost = false, isKernel = false;
    module.walk([&](Operation *op) {
        auto name = op->getName().getStringRef();
        // dfschedule host-path ops
        if (name == "dfschedule.declaretile" ||
            name == "dfschedule.config.dma_bd")
            isHost = true;
        // dfschedule kernel-path ops
        if (name == "dfschedule.kernel_config_def")
            isKernel = true;
        // emitc-level detection
        if (name == "emitc.call_opaque") {
            if (auto callee = op->getAttrOfType<StringAttr>("callee")) {
                if (callee.getValue().starts_with("__Runtime_"))
                    isHost = true;
            }
        }
        if (name == "emitc.verbatim") {
            if (auto valAttr = op->getAttrOfType<StringAttr>("value")) {
                auto text = valAttr.getValue();
                if (text.contains("aie_api/aie.hpp"))
                    isKernel = true;
                if (text.contains("__Runtime_"))
                    isHost = true;
            }
        }
    });
    if (isHost && !isKernel) return "host";
    if (isKernel && !isHost) return "kernel";
    return "unknown";
}

// Auto-detect the pipeline stage from the dialects present in the module.
// Returns the stage name (routing, dmap, dmaphop, dfscheblueprint, dfschedule, emitc)
// or "" if unrecognizable.
static std::string autoDetectStage(mlir::ModuleOp module) {
    std::set<std::string> foundDialects;
    bool hasEmitC = false;
    module.walk([&](Operation *op) {
        if (auto *dialect = op->getDialect()) {
            std::string ns = dialect->getNamespace().str();
            if (ns == "routing" || ns == "routinghw" || ns == "dmap" ||
                ns == "dmaphop" || ns == "dfscheblueprint" ||
                ns == "dfschedule") {
                foundDialects.insert(ns);
            }
            if (ns == "emitc")
                hasEmitC = true;
        }
    });

    // Detect based on the "latest" dialect present (pipeline order)
    if (foundDialects.count("dfschedule"))     return "dfschedule";
    if (foundDialects.count("dfscheblueprint")) return "dfscheblueprint";
    if (foundDialects.count("dmaphop"))         return "dmaphop";
    if (foundDialects.count("routinghw"))       return "routinghw";
    if (foundDialects.count("dmap"))            return "dmap";
    if (foundDialects.count("routing")) {
        // Check if still stage 0 (has scf.for) or stage 1 (unrolled)
        bool hasScfFor = false;
        module.walk([&](Operation *op) {
            if (op->getName().getStringRef() == "scf.for")
                hasScfFor = true;
        });
        return "routing"; // stage 0 or 1 — both map to "routing" for entry
    }
    if (hasEmitC && foundDialects.empty())      return "emitc";
    return "";
}

static bool validateIRDialect(mlir::ModuleOp module,
                              const std::string &expectedMode,
                              const std::string &filepath,
                              std::string &detectedMode) {
    detectedMode = autoDetectStage(module);

    if (detectedMode.empty()) {
        llvm::errs() << "ERROR: Could not detect any known pipeline dialect in IR.\n"
                     << "  File: " << filepath << "\n";
        return false;
    }

    // If expected mode matches detected mode, we're good
    if (expectedMode == detectedMode) {
        // Extra check for routing stage 0: scf.for must still be present
        if (expectedMode == "routing") {
            bool hasScfFor = false;
            module.walk([&](Operation *op) {
                if (op->getName().getStringRef() == "scf.for")
                    hasScfFor = true;
            });
            if (!hasScfFor) {
                // Stage 1 (post-unrolling) — still has routing but no scf.for
                // Treat as "dmap" entry point (startStage=1)
                std::cout << "Note: IR has routing dialect but scf.for already unrolled (stage 1).\n"
                          << "  Adjusting to startStage=1." << std::endl;
                detectedMode = "routing_unrolled";
            }
        }
        std::cout << "IR validation passed: file contains " << detectedMode
                  << " dialect ops." << std::endl;
        return true;
    }

    // Mismatch: auto-correct with a warning
    std::cout << "WARNING: --parse " << expectedMode
              << " specified, but IR contains " << detectedMode
              << " dialect.\n"
              << "  File: " << filepath << "\n"
              << "  Auto-correcting to --parse " << detectedMode << ".\n";
    return true;
}

// ---------------------------------------------------------------------------
// IR file parser helper
// ---------------------------------------------------------------------------

static mlir::OwningOpRef<mlir::ModuleOp> loadModuleFromFile(
    MLIRContext &ctx, const std::string &filepath) {
    llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>> fileOrErr =
        llvm::MemoryBuffer::getFileOrSTDIN(filepath);
    if (std::error_code ec = fileOrErr.getError()) {
        llvm::errs() << "Could not open file: " << filepath << ": "
                     << ec.message() << "\n";
        return nullptr;
    }
    llvm::SourceMgr sourceMgr;
    sourceMgr.AddNewSourceBuffer(std::move(*fileOrErr), llvm::SMLoc());

    // Print diagnostics directly to stderr so they're always visible
    mlir::SourceMgrDiagnosticHandler diagHandler(sourceMgr, &ctx, llvm::errs());

    auto result = mlir::parseSourceFile<mlir::ModuleOp>(sourceMgr, &ctx);
    if (!result) {
        llvm::errs() << "Failed to parse: " << filepath << "\n";
    }
    return result;
}

void routingtoroutinghw(mlir::ModuleOp module1 = nullptr) {
    MLIRContext ctx;

    routingmanager mtest;
    routinghwmanager mtesthw;
    mtesthw.loaddialect(&ctx);
    mtest.loaddialect(&ctx);

    ctx.getOrLoadDialect<arith::ArithDialect>();

    if (!module1) {
        module1 = mtest.ops_testNew(&ctx, 1, "routing");
    }

    std::string irDir = setupIRDir("simplerouting");
    RoutingTopology rtopology("Gen2");
    int stage = 0;

    dumpIRToFile(module1, irDir, stage++, "initial");

    if (!runSinglePass(ctx, module1, std::make_unique<RoutingUnrollingLowerPass>(), irDir, stage,
                       "RoutingUnrollingLowerPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingLowerPass>(rtopology), irDir, stage, "RoutingLowerPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingHWLowerPass>(rtopology), irDir, stage,
                       "RoutingHWLowerPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingDeadArgPass>(), irDir, stage, "RoutingDeadArgPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingConstantFoldPass>(), irDir, stage,
                       "RoutingConstantFoldPass"))
        return;
    if (!runSinglePass(ctx, module1, mlir::createCanonicalizerPass(), irDir, stage, "CanonicalizerPass"))
        return;

    const std::string worklocalDir = setupWorklocalDir();
    if (worklocalDir.empty()) return;

    std::string routingPath = worklocalDir + "/routing_hw.cc";
    std::error_code routingEC;
    llvm::raw_fd_ostream routingStream(routingPath, routingEC, llvm::sys::fs::OF_None);
    if (routingEC) {
        llvm::errs() << "Failed to open " << routingPath << ": " << routingEC.message() << "\n";
        return;
    }
    mlir::LogicalResult result = mlir::emitc::translateToCpp(module1, routingStream);
    routingStream.close();
    if (failed(result)) {
        llvm::errs() << "Failed to translate routing MLIR to C++.\n";
        return;
    }
    std::cout << "Routing code written to " << routingPath << std::endl;
}
void routingtodmap(const std::string &irFilepath = "", int startStage = 0) {
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
    ctx.getOrLoadDialect<mlir::func::FuncDialect>();
    ctx.getOrLoadDialect<mlir::memref::MemRefDialect>();
    ctx.getOrLoadDialect<mlir::scf::SCFDialect>();
    ctx.getOrLoadDialect<mlir::tensor::TensorDialect>();
    ctx.getOrLoadDialect<mlir::bufferization::BufferizationDialect>();
    ctx.getOrLoadDialect<mlir::emitc::EmitCDialect>();
    ctx.getOrLoadDialect<mlir::cf::ControlFlowDialect>();

    // Create module: either parse from file or build programmatically
    mlir::OwningOpRef<mlir::ModuleOp> parsedModule;
    mlir::ModuleOp module1;
    if (!irFilepath.empty()) {
        parsedModule = loadModuleFromFile(ctx, irFilepath);
        if (!parsedModule) return;
        module1 = *parsedModule;
        std::cout << "Parsed module from " << irFilepath << std::endl;
    } else {
        module1 = mtest.ops_testNew(&ctx, 1, "routing");
    }

    std::string irDir = setupIRDir("dmap");
    RoutingTopology rtopology("Gen2");
    int stage = startStage;

    dumpIRToFile(module1, irDir, stage++, "initial");

    // Stages 0-2 are shared with dfschedule; stage 3+ diverges
    if (startStage <= 0) {
        if (!runSinglePass(ctx, module1, std::make_unique<RoutingUnrollingLowerPass>(), irDir, stage,
                           "RoutingUnrollingLowerPass"))
            return;
    }
    if (startStage <= 1) {
        if (!runSinglePass(ctx, module1, std::make_unique<RoutingToDmapPass>(rtopology), irDir, stage,
                           "RoutingToDmapPass"))
            return;
    }
    if (startStage <= 2) {
        if (!runSinglePass(ctx, module1, std::make_unique<DmapToDmaphopPass>(rtopology), irDir, stage,
                           "DmapToDmaphopPass"))
            return;
    }
    // Stage 3+: routing.cc-specific path (diverges from dfschedule here)
    if (!runSinglePass(ctx, module1, std::make_unique<DmaphopToRoutinghwPass>(rtopology), irDir, stage,
                       "DmaphopToRoutinghwPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingHWVerifyPass>(), irDir, stage, "RoutingHWVerifyPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingHWLowerPass>(rtopology), irDir, stage,
                       "RoutingHWLowerPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingDeadArgPass>(), irDir, stage, "RoutingDeadArgPass"))
        return;
    if (!runSinglePass(ctx, module1, std::make_unique<RoutingConstantFoldPass>(), irDir, stage,
                       "RoutingConstantFoldPass"))
        return;
    if (!runSinglePass(ctx, module1, mlir::createCanonicalizerPass(), irDir, stage, "CanonicalizerPass"))
        return;

    const std::string worklocalDir = setupWorklocalDir();
    if (worklocalDir.empty()) return;

    std::string routingPath = worklocalDir + "/routing.cc";
    std::error_code routingEC;
    llvm::raw_fd_ostream routingStream(routingPath, routingEC, llvm::sys::fs::OF_None);
    if (routingEC) {
        llvm::errs() << "Failed to open " << routingPath << ": " << routingEC.message() << "\n";
        return;
    }
    mlir::LogicalResult result = mlir::emitc::translateToCpp(module1, routingStream);
    routingStream.close();
    if (failed(result)) {
        llvm::errs() << "Failed to translate routing MLIR to C++.\n";
        return;
    }
    std::cout << "Routing code written to " << routingPath << std::endl;
}

void routingtodfschedule(const std::string &irFilepath = "", int startStage = 0) {
    MLIRContext ctx;
    TilingLinalgPipeline::registerDialects(ctx);

    // Default tensor config for GEMM: 2 inputs + 1 output
    std::vector<TensorParam> tensors = {
        {{16, 16}, 8, true},  // input A (window_in_0)
        {{16, 16}, 8, true},  // input B (window_in_1)
        {{16, 16}, 8, false}, // output C (window_out_0)
    };

    // Create module: either parse from file or build programmatically
    mlir::OwningOpRef<mlir::ModuleOp> parsedModule;
    mlir::ModuleOp module;
    if (!irFilepath.empty()) {
        parsedModule = loadModuleFromFile(ctx, irFilepath);
        if (!parsedModule) return;
        module = *parsedModule;
        std::cout << "Parsed module from " << irFilepath << std::endl;
    } else {
        module = TilingLinalgPipeline::buildRoutingIR(ctx, 4, 4, tensors);
    }

    // When startStage==0 and using the default pipeline, delegate to
    // TilingLinalgPipeline::runPipeline which handles the full flow.
    if (startStage == 0) {
        std::string outputDir = setupWorklocalDir();
        if (outputDir.empty()) return;

        if (!TilingLinalgPipeline::runPipeline(ctx, module, outputDir,
                                               /*userKernelBody=*/"", /*userKernelFuncName=*/"",
                                               /*runtimeDebugLevel=*/-1, /*userRewrittenSource=*/"", tensors)) {
            llvm::errs() << "TilingLinalgPipeline::runPipeline failed!\n";
        }
        return;
    }

    // Stage-aware pipeline for --parse mode (startStage > 0)
    RoutingTopology rtopology("Gen2");

    // Determine which paths to run based on startStage
    // Stages 0-4: shared path (can produce host + kernel + bcf/prx)
    // Stages 5-9: host-only path (host.cc + bcf/prx)
    // Stages 10-11: kernel-only path (kernel.cc)
    bool doHostPath = (startStage <= 9);
    bool doKernelPath = (startStage <= 4 || startStage >= 10);

    // Print output summary
    std::cout << "Stage: startStage=" << startStage << std::endl;
    std::cout << "Will produce:";
    if (doHostPath) std::cout << " host.cc, aieml.bcf, aieml.prx";
    if (doHostPath && doKernelPath) std::cout << ",";
    if (doKernelPath) std::cout << " kernel.cc";
    std::cout << std::endl;

    std::string irDir = setupIRDir("dfschedule");
    int stage = startStage;

    dumpIRToFile(module, irDir, stage++, "initial");

    // Phase 1: shared path (routing -> dmap -> dmaphop -> dfscheblueprint)
    if (startStage <= 0) {
        if (!runSinglePass(ctx, module, std::make_unique<RoutingUnrollingLowerPass>(), irDir, stage,
                           "RoutingUnrollingLowerPass"))
            return;
    }
    if (startStage <= 1) {
        if (!runSinglePass(ctx, module, std::make_unique<RoutingToDmapPass>(rtopology), irDir, stage,
                           "RoutingToDmapPass"))
            return;
    }
    if (startStage <= 2) {
        if (!runSinglePass(ctx, module, std::make_unique<DmapToDmaphopPass>(rtopology), irDir, stage,
                           "DmapToDmaphopPass"))
            return;
    }
    if (startStage <= 3) {
        if (!runSinglePass(ctx, module, std::make_unique<DmaphopTodfscheblueprintPass>(), irDir, stage,
                           "DmaphopTodfscheblueprintPass"))
            return;
    }

    // Branch point: clone for host and kernel paths (only when entering at shared stages)
    mlir::ModuleOp hostModule;
    mlir::ModuleOp kernelModule;

    if (startStage <= 4) {
        // Pre-branch or at branch point: clone for both paths
        if (doHostPath)
            hostModule = cast<ModuleOp>(module->clone());
        if (doKernelPath)
            kernelModule = cast<ModuleOp>(module->clone());
    } else if (startStage <= 9) {
        // Host-only stages: use module directly
        hostModule = module;
    } else {
        // Kernel-only stages: use module directly
        kernelModule = module;
    }

    // Initialize ResourceMgr singleton for CoreMemAllocator (BCF/PRX generation)
    // The singleton may already exist from a previous pass; init only creates once.
    if (doHostPath) {
        auto hwRes = makeResource("Gen2");
        ResourceMgr::init(std::move(hwRes));
    }

    // Phase 2: host path (blueprint -> schedule -> API -> EmitC)
    if (doHostPath) {
        if (startStage <= 4) {
            if (!runSinglePass(ctx, hostModule, std::make_unique<mlir::BlueprintToSchedulePass>(0.5), irDir, stage,
                               "BlueprintToSchedulePass"))
                return;
        }
        if (startStage <= 5) {
            if (!runSinglePass(ctx, hostModule, std::make_unique<mlir::ScheduleCanonicalizePass>(), irDir, stage,
                               "ScheduleCanonicalizePass"))
                return;
        }
        if (startStage <= 6) {
            if (!runSinglePass(ctx, hostModule, std::make_unique<mlir::DfscheduleToApiPass>(/*enableDebug=*/true),
                               irDir, stage, "DfscheduleToApiPass"))
                return;
        }
        if (startStage <= 7) {
            if (!runSinglePass(ctx, hostModule, mlir::createCanonicalizerPass(), irDir, stage, "CanonicalizerPass"))
                return;
        }
        if (startStage <= 8) {
            if (!runSinglePass(ctx, hostModule, std::make_unique<RoutingConstantFoldPass>(), irDir, stage,
                               "RoutingConstantFoldPass"))
                return;
        }
    }

    // Phase 3: kernel path (blueprint -> kernel schedule -> kernel API)
    if (doKernelPath) {
        if (startStage <= 4) {
            if (!runSinglePass(ctx, kernelModule, std::make_unique<mlir::BlueprintToScheduleKernelPass>(0.5), irDir,
                               stage, "BlueprintToScheduleKernelPass"))
                return;
        }
        if (startStage <= 10) {
            if (!runSinglePass(ctx, kernelModule, std::make_unique<mlir::DfscheduleToKernelApiPass>(), irDir, stage,
                               "DfscheduleToKernelApiPass"))
                return;
        }
    }

    // Output generated C++ code
    const std::string worklocalDir = setupWorklocalDir();
    if (worklocalDir.empty()) return;

    if (doHostPath) {
        std::string hostPath = worklocalDir + "/host.cc";
        std::error_code hostEC;
        llvm::raw_fd_ostream hostStream(hostPath, hostEC, llvm::sys::fs::OF_None);
        if (hostEC) {
            llvm::errs() << "Failed to open " << hostPath << ": " << hostEC.message() << "\n";
            return;
        }
        mlir::LogicalResult result = mlir::emitc::translateToCpp(hostModule, hostStream);
        hostStream.close();
        if (failed(result)) {
            llvm::errs() << "Failed to translate host MLIR to C++.\n";
            return;
        }
        std::cout << "Host code written to " << hostPath << std::endl;
    }

    if (doKernelPath) {
        std::string kernelPath = worklocalDir + "/kernel.cc";
        std::error_code kernelEC;
        llvm::raw_fd_ostream kernelStream(kernelPath, kernelEC, llvm::sys::fs::OF_None);
        if (kernelEC) {
            llvm::errs() << "Failed to open " << kernelPath << ": " << kernelEC.message() << "\n";
            return;
        }
        mlir::LogicalResult result2 = mlir::emitc::translateToCpp(kernelModule, kernelStream);
        kernelStream.close();
        if (failed(result2)) {
            llvm::errs() << "Failed to translate kernel MLIR to C++.\n";
            return;
        }
        std::cout << "Kernel code written to " << kernelPath << std::endl;
    }

    // Phase 4: Generate BCF/PRX for kernel compilation
    // The CoreMemAllocator was populated during BlueprintToSchedulePass (host path)
    // with buffer symbol addresses. Generate BCF/PRX files that pin those symbols
    // so the kernel linker places buffers where the host DMA BDs expect.
    if (doHostPath) {
        try {
            auto &allocator = ResourceMgr::instance()->coreMemAllocator();
            const auto &allocations = allocator.getAllocations();

            if (!allocations.empty()) {
                TilingBcf bcf;
                bcf.setStack(0x70000, 0x1024);
                bcf.addReservedDMB(0x40000, 0x10000);
                // Reserve the last 2KB of DM for kernel_log.h klog() region
                // (DM absolute 0x7F800-0x7FFFF = DM offset 0xF800, 0x800 bytes)
                bcf.addReservedDMB(0x7F800, 0x800);
                for (const auto &slot : allocations) {
                    bcf.addSymbol(slot.symbolName, slot.address);
                }

                std::string bcfPath = worklocalDir + "/aieml.bcf";
                if (bcf.exportToFile(bcfPath)) {
                    std::cout << "BCF written to " << bcfPath << std::endl;
                } else {
                    llvm::errs() << "Failed to write BCF to " << bcfPath << "\n";
                }

                TilingPrx prx("kernel", 22); // AIE2PS arch=22
                prx.setBcfPath("aieml.bcf");
                prx.setKernelLLPath("./build/");

                std::string prxPath = worklocalDir + "/aieml.prx";
                if (prx.exportToFile(prxPath)) {
                    std::cout << "PRX written to " << prxPath << std::endl;
                } else {
                    llvm::errs() << "Failed to write PRX to " << prxPath << "\n";
                }

                // Print allocation summary
                std::cout << "\n=== Core Memory Allocation Summary ===" << std::endl;
                for (const auto &slot : allocations) {
                    std::cout << "  " << slot.symbolName << " @ 0x" << std::hex << slot.address << " (size="
                              << std::dec << slot.size << " bytes)" << std::endl;
                }
                std::cout << "  Free space: " << allocator.getFreeSpace() << " bytes" << std::endl;
            } else {
                std::cout << "No buffer allocations found; skipping BCF/PRX generation." << std::endl;
            }
        } catch (...) {
            std::cout << "ResourceMgr not initialized; skipping BCF/PRX generation." << std::endl;
        }
    }
}

// ---------------------------------------------------------------------------
// Multi-dimensional BD addressing test
// ---------------------------------------------------------------------------
// Runs the standard dfschedule pipeline, then creates a standalone dfschedule
// module with dim_strides/dim_wraps on a config.dma_bd op and runs the
// DfscheduleToApiPass to verify __Runtime_dma_bd_config_multidim emission.

void testMultidimBd() {
    std::cout << "\n=== Multi-Dimensional BD Addressing Test ===" << std::endl;

    // First, run the normal pipeline to verify no regression
    std::cout << "\n--- Phase 1: Regression check (normal pipeline) ---" << std::endl;
    routingtodfschedule("");

    // Phase 2: Build a minimal dfschedule module with dim_strides/dim_wraps
    // and run DfscheduleToApiPass to check multidim call emission
    std::cout << "\n--- Phase 2: Multi-dim BD emission test ---" << std::endl;

    MLIRContext ctx;
    TilingLinalgPipeline::registerDialects(ctx);

    // Build a 2x2 mesh GEMM routing IR and run through shared stages
    std::vector<TensorParam> tensors = {
        {{16, 16}, 8, true},  // input A
        {{16, 16}, 8, true},  // input B
        {{16, 16}, 8, false}, // output C
    };
    auto module = TilingLinalgPipeline::buildRoutingIR(ctx, 4, 4, tensors);

    RoutingTopology rtopology("Gen2");
    std::string irDir = setupIRDir("multidim");
    int stage = 0;

    dumpIRToFile(module, irDir, stage++, "initial");

    // Run shared stages: routing -> dmap -> dmaphop -> blueprint
    if (!runSinglePass(ctx, module, std::make_unique<RoutingUnrollingLowerPass>(), irDir, stage,
                       "RoutingUnrollingLowerPass"))
        return;
    if (!runSinglePass(ctx, module, std::make_unique<RoutingToDmapPass>(rtopology), irDir, stage, "RoutingToDmapPass"))
        return;
    if (!runSinglePass(ctx, module, std::make_unique<DmapToDmaphopPass>(rtopology), irDir, stage, "DmapToDmaphopPass"))
        return;
    if (!runSinglePass(ctx, module, std::make_unique<DmaphopTodfscheblueprintPass>(), irDir, stage,
                       "DmaphopTodfscheblueprintPass"))
        return;

    // Clone for host path
    auto hostModule = cast<ModuleOp>(module->clone());

    // Initialize ResourceMgr
    auto hwRes = makeResource("Gen2");
    ResourceMgr::init(std::move(hwRes));

    // Run BlueprintToSchedulePass (host path)
    if (!runSinglePass(ctx, hostModule, std::make_unique<mlir::BlueprintToSchedulePass>(0.5), irDir, stage,
                       "BlueprintToSchedulePass"))
        return;
    if (!runSinglePass(ctx, hostModule, std::make_unique<mlir::ScheduleCanonicalizePass>(), irDir, stage,
                       "ScheduleCanonicalizePass"))
        return;

    // Now inject dim_strides/dim_wraps on the first Shim tile config.dma_bd
    // that corresponds to B-matrix input (data_id = 1 convention)
    std::cout << "Injecting dim_strides/dim_wraps on B-matrix BD..." << std::endl;
    bool injected = false;
    hostModule.walk([&](dfschedule::ConfigDmaBdOp bdOp) {
        // Inject on the first BD that doesn't already have multidim attrs
        // We target a shim-tile BD (data_id >= 0, no locks = shim tile pattern)
        if (!injected && !bdOp.getDimStrides()) {
            // B-matrix transpose for 16x16:
            // dim0: stride=16, wrap=16 (jump across rows for one column)
            // dim1: stride=1, wrap=8 (next column, 8 columns per tile)
            SmallVector<Attribute, 2> strides = {
                IntegerAttr::get(IntegerType::get(&ctx, 32), 16),
                IntegerAttr::get(IntegerType::get(&ctx, 32), 1),
            };
            SmallVector<Attribute, 2> wraps = {
                IntegerAttr::get(IntegerType::get(&ctx, 32), 16),
                IntegerAttr::get(IntegerType::get(&ctx, 32), 8),
            };
            bdOp.setDimStridesAttr(ArrayAttr::get(&ctx, strides));
            bdOp.setDimWrapsAttr(ArrayAttr::get(&ctx, wraps));
            injected = true;
            std::cout << "  Injected multidim attrs: dim_strides=[16,1], dim_wraps=[16,8]" << std::endl;
        }
    });

    if (!injected) {
        std::cerr << "WARNING: Could not find a BD op to inject multidim attrs" << std::endl;
    }

    dumpIRToFile(hostModule, irDir, stage++, "MultidimInjected");

    // Run DfscheduleToApiPass
    if (!runSinglePass(ctx, hostModule, std::make_unique<mlir::DfscheduleToApiPass>(true), irDir, stage,
                       "DfscheduleToApiPass"))
        return;
    if (!runSinglePass(ctx, hostModule, mlir::createCanonicalizerPass(), irDir, stage, "CanonicalizerPass"))
        return;
    if (!runSinglePass(ctx, hostModule, std::make_unique<RoutingConstantFoldPass>(), irDir, stage,
                       "RoutingConstantFoldPass"))
        return;

    // Emit host.cc and check for __Runtime_dma_bd_config_multidim
    const std::string worklocalDir = setupWorklocalDir();
    if (worklocalDir.empty())
        return;

    std::string hostPath = worklocalDir + "/host_multidim.cc";
    std::error_code hostEC;
    llvm::raw_fd_ostream hostStream(hostPath, hostEC, llvm::sys::fs::OF_None);
    if (hostEC) {
        llvm::errs() << "Failed to open " << hostPath << ": " << hostEC.message() << "\n";
        return;
    }
    mlir::LogicalResult result = mlir::emitc::translateToCpp(hostModule, hostStream);
    hostStream.close();
    if (failed(result)) {
        llvm::errs() << "Failed to translate host MLIR to C++.\n";
        return;
    }
    std::cout << "Host code (multidim) written to " << hostPath << std::endl;

    // Verify: read host_multidim.cc and check for __Runtime_dma_bd_config_multidim
    auto bufOrErr = llvm::MemoryBuffer::getFile(hostPath);
    if (bufOrErr) {
        auto content = (*bufOrErr)->getBuffer();
        if (content.contains("__Runtime_dma_bd_config_multidim")) {
            std::cout << "\n✓ PASS: host_multidim.cc contains __Runtime_dma_bd_config_multidim call" << std::endl;
        } else {
            std::cout << "\n✗ FAIL: host_multidim.cc does NOT contain __Runtime_dma_bd_config_multidim call"
                      << std::endl;
        }
        // Also verify regular config still present for non-multidim BDs
        if (content.contains("__Runtime_dma_bd_config(")) {
            std::cout << "✓ PASS: host_multidim.cc still contains regular __Runtime_dma_bd_config calls (no regression)"
                      << std::endl;
        }
    }

    std::cout << "\n=== Multi-Dimensional BD Test Complete ===" << std::endl;
}

// ---------------------------------------------------------------------------
// Multi-kernel test
// ---------------------------------------------------------------------------
// Tests the multi-kernel pipeline: builds a 2-kernel graph (gemm + relu),
// runs KernelGraphToRoutingPass, then runs the full pipeline per-kernel.

void testMultiKernel() {
    std::cout << "\n=== Multi-Kernel Pipeline Test ===" << std::endl;

    MLIRContext ctx;
    TilingLinalgPipeline::registerDialects(ctx);

    // Build a 2-kernel graph:
    //   kernel "gemm" on 2x2 mesh at (row=3, col=2)
    //   kernel "relu" on 2x2 mesh at (row=3, col=4)
    //   data_edge: gemm output[0] -> relu input[0] via DDR bounce
    std::vector<KernelInfo> kernels = {
        {/*kernelName=*/"gemm",
         /*kernelFuncName=*/"gemm_i8_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/2,
         /*kernelId=*/0},
        {/*kernelName=*/"relu",
         /*kernelFuncName=*/"relu_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/4,
         /*kernelId=*/1},
    };

    // Step 1: Build the kernelgraph IR
    std::cout << "\n--- Step 1: Building kernelgraph IR ---" << std::endl;
    kernelgraphmanager kgm;
    auto module = kgm.buildMultiKernelGraph(&ctx, kernels);
    std::cout << "Kernelgraph IR:" << std::endl;
    module.dump();

    // Step 2: Run KernelGraphToRoutingPass
    std::cout << "\n--- Step 2: Running KernelGraphToRoutingPass ---" << std::endl;
    {
        mlir::PassManager pm(&ctx);
        pm.addPass(std::make_unique<KernelGraphToRoutingPass>());
        if (failed(pm.run(module))) {
            llvm::errs() << "ERROR: KernelGraphToRoutingPass failed!\n";
            return;
        }
    }

    std::cout << "\nPost-KernelGraphToRoutingPass module:" << std::endl;
    module.dump();

    // Step 3: Run the multi-kernel pipeline
    std::cout << "\n--- Step 3: Running multi-kernel pipeline ---" << std::endl;

    const std::string worklocalDir = setupWorklocalDir();
    if (worklocalDir.empty())
        return;

    std::string mkDir = worklocalDir + "/multikernel";
    if (std::error_code EC = llvm::sys::fs::create_directories(mkDir)) {
        llvm::errs() << "Failed to create " << mkDir << ": " << EC.message() << "\n";
        return;
    }

    if (!TilingLinalgPipeline::runMultiKernelPipeline(ctx, module, mkDir, kernels)) {
        llvm::errs() << "ERROR: runMultiKernelPipeline failed!\n";
        return;
    }

    std::cout << "\n--- Step 4: Verification ---" << std::endl;

    // Check that output files exist
    std::vector<std::string> expectedFiles = {
        mkDir + "/host_main.cc",
        mkDir + "/compile_all_kernels.sh",
    };
    for (const auto &ki : kernels) {
        expectedFiles.push_back(mkDir + "/" + ki.kernelName + "/host.cc");
        expectedFiles.push_back(mkDir + "/" + ki.kernelName + "/kernel.cc");
    }

    bool allExist = true;
    for (const auto &f : expectedFiles) {
        bool exists = llvm::sys::fs::exists(f);
        std::cout << "  " << (exists ? "OK" : "MISSING") << ": " << f << std::endl;
        if (!exists)
            allExist = false;
    }

    if (allExist) {
        std::cout << "\nPASS: All expected multi-kernel output files generated." << std::endl;
    } else {
        std::cout << "\nFAIL: Some output files are missing." << std::endl;
    }

    std::cout << "\n=== Multi-Kernel Pipeline Test Complete ===" << std::endl;
}

// ---------------------------------------------------------------------------
// Multi-kernel sequential test
// ---------------------------------------------------------------------------
// Tests sequential execution: 2 kernels on the SAME tile region,
// where the second kernel reloads ELF after the first completes.

void testMultiKernelSequential() {
    std::cout << "\n=== Multi-Kernel Sequential Test ===" << std::endl;

    MLIRContext ctx;
    TilingLinalgPipeline::registerDialects(ctx);

    // Build a 2-kernel graph:
    //   kernel "conv2d" on 2x2 mesh at (row=3, col=2) — spatial_parallel (runs first)
    //   kernel "relu"  on 2x2 mesh at (row=3, col=2) — sequential_reuse (same region)
    //   data_edge: conv2d output[0] -> relu input[0] via DDR bounce
    std::vector<KernelInfo> kernels = {
        {/*kernelName=*/"conv2d",
         /*kernelFuncName=*/"conv2d_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/2,
         /*kernelId=*/0,
         /*executionMode=*/"spatial_parallel",
         /*placementStrategy=*/"manual"},
        {/*kernelName=*/"relu",
         /*kernelFuncName=*/"relu_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/2,
         /*kernelId=*/1,
         /*executionMode=*/"sequential_reuse",
         /*placementStrategy=*/"manual"},
    };

    // Data edge: conv2d output -> relu input
    std::vector<DataEdgeInfo> dataEdges = {
        {/*producerKernelId=*/0, /*consumerKernelId=*/1,
         /*producerOutputIdx=*/0, /*consumerInputIdx=*/0,
         /*transferMode=*/"ddr_bounce", /*priority=*/0},
    };

    // Step 1: Build the kernelgraph IR
    std::cout << "\n--- Step 1: Building kernelgraph IR ---" << std::endl;
    kernelgraphmanager kgm;
    auto module = kgm.buildMultiKernelGraph(&ctx, kernels);
    std::cout << "Kernelgraph IR:" << std::endl;
    module.dump();

    // Step 2: Run KernelGraphToRoutingPass
    std::cout << "\n--- Step 2: Running KernelGraphToRoutingPass ---" << std::endl;
    {
        mlir::PassManager pm(&ctx);
        pm.addPass(std::make_unique<KernelGraphToRoutingPass>());
        if (failed(pm.run(module))) {
            llvm::errs() << "ERROR: KernelGraphToRoutingPass failed!\n";
            return;
        }
    }

    // Step 3: Run the multi-kernel pipeline
    std::cout << "\n--- Step 3: Running multi-kernel pipeline ---" << std::endl;

    llvm::SmallString<256> cwdPath;
    llvm::sys::fs::current_path(cwdPath);
    std::string worklocalDir = (cwdPath + "/worklocal").str();
    llvm::sys::fs::create_directories(worklocalDir);

    std::string mkDir = worklocalDir + "/multikernel_seq";
    llvm::sys::fs::create_directories(mkDir);

    if (!TilingLinalgPipeline::runMultiKernelPipeline(ctx, module, mkDir, kernels, dataEdges)) {
        llvm::errs() << "ERROR: runMultiKernelPipeline failed!\n";
        return;
    }

    // Step 4: Verification
    std::cout << "\n--- Step 4: Verification ---" << std::endl;

    std::vector<std::string> expectedFiles = {
        mkDir + "/host_main.cc",
        mkDir + "/compile_all_kernels.sh",
    };
    for (const auto &ki : kernels) {
        expectedFiles.push_back(mkDir + "/" + ki.kernelName + "/host.cc");
        expectedFiles.push_back(mkDir + "/" + ki.kernelName + "/kernel.cc");
    }

    bool allExist = true;
    for (const auto &f : expectedFiles) {
        bool exists = llvm::sys::fs::exists(f);
        std::cout << "  " << (exists ? "OK" : "MISSING") << ": " << f << std::endl;
        if (!exists)
            allExist = false;
    }

    // Verify host_main.cc has 2 stages (conv2d in stage 0, relu in stage 1)
    auto bufOrErr = llvm::MemoryBuffer::getFile(mkDir + "/host_main.cc");
    if (bufOrErr) {
        auto content = (*bufOrErr)->getBuffer();
        bool hasStage0 = content.contains("Stage 0");
        bool hasStage1 = content.contains("Stage 1");
        bool hasDataTransfer = content.contains("Transferring data");
        std::cout << "  " << (hasStage0 ? "OK" : "FAIL") << ": host_main.cc has Stage 0" << std::endl;
        std::cout << "  " << (hasStage1 ? "OK" : "FAIL") << ": host_main.cc has Stage 1" << std::endl;
        std::cout << "  " << (hasDataTransfer ? "OK" : "FAIL") << ": host_main.cc has data transfer" << std::endl;
        if (!hasStage0 || !hasStage1 || !hasDataTransfer)
            allExist = false;
    }

    if (allExist) {
        std::cout << "\nPASS: Sequential multi-kernel test passed." << std::endl;
    } else {
        std::cout << "\nFAIL: Some checks failed." << std::endl;
    }

    std::cout << "\n=== Multi-Kernel Sequential Test Complete ===" << std::endl;
}

// ---------------------------------------------------------------------------
// Multi-kernel mixed test
// ---------------------------------------------------------------------------
// Tests mixed parallel+sequential execution:
//   Stage 0: gemm (2x2 at col 2) and conv (2x2 at col 4) run in parallel
//   Stage 1: relu (2x2 at col 2, sequential_reuse after gemm) consumes gemm output

void testMultiKernelMixed() {
    std::cout << "\n=== Multi-Kernel Mixed Test ===" << std::endl;

    MLIRContext ctx;
    TilingLinalgPipeline::registerDialects(ctx);

    // 3 kernels:
    //   gemm: spatial_parallel at (3,2) — stage 0
    //   conv: spatial_parallel at (3,4) — stage 0 (parallel with gemm, no dependency)
    //   relu: sequential_reuse at (3,2) — stage 1 (depends on gemm output)
    std::vector<KernelInfo> kernels = {
        {/*kernelName=*/"gemm",
         /*kernelFuncName=*/"gemm_i8_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/2,
         /*kernelId=*/0,
         /*executionMode=*/"spatial_parallel",
         /*placementStrategy=*/"manual"},
        {/*kernelName=*/"conv",
         /*kernelFuncName=*/"conv_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/4,
         /*kernelId=*/1,
         /*executionMode=*/"spatial_parallel",
         /*placementStrategy=*/"manual"},
        {/*kernelName=*/"relu",
         /*kernelFuncName=*/"relu_i8",
         /*kernelBody=*/"",
         /*meshRows=*/2, /*meshCols=*/2,
         /*originRow=*/3, /*originCol=*/2,
         /*kernelId=*/2,
         /*executionMode=*/"sequential_reuse",
         /*placementStrategy=*/"manual"},
    };

    // Data edge: gemm output -> relu input
    std::vector<DataEdgeInfo> dataEdges = {
        {/*producerKernelId=*/0, /*consumerKernelId=*/2,
         /*producerOutputIdx=*/0, /*consumerInputIdx=*/0,
         /*transferMode=*/"ddr_bounce", /*priority=*/0},
    };

    // Step 1: Build the kernelgraph IR
    std::cout << "\n--- Step 1: Building kernelgraph IR ---" << std::endl;
    kernelgraphmanager kgm;
    auto module = kgm.buildMultiKernelGraph(&ctx, kernels);
    std::cout << "Kernelgraph IR:" << std::endl;
    module.dump();

    // Step 2: Run KernelGraphToRoutingPass
    std::cout << "\n--- Step 2: Running KernelGraphToRoutingPass ---" << std::endl;
    {
        mlir::PassManager pm(&ctx);
        pm.addPass(std::make_unique<KernelGraphToRoutingPass>());
        if (failed(pm.run(module))) {
            llvm::errs() << "ERROR: KernelGraphToRoutingPass failed!\n";
            return;
        }
    }

    // Step 3: Run the multi-kernel pipeline
    std::cout << "\n--- Step 3: Running multi-kernel pipeline ---" << std::endl;

    llvm::SmallString<256> cwdPath;
    llvm::sys::fs::current_path(cwdPath);
    std::string worklocalDir = (cwdPath + "/worklocal").str();
    llvm::sys::fs::create_directories(worklocalDir);

    std::string mkDir = worklocalDir + "/multikernel_mixed";
    llvm::sys::fs::create_directories(mkDir);

    if (!TilingLinalgPipeline::runMultiKernelPipeline(ctx, module, mkDir, kernels, dataEdges)) {
        llvm::errs() << "ERROR: runMultiKernelPipeline failed!\n";
        return;
    }

    // Step 4: Verification
    std::cout << "\n--- Step 4: Verification ---" << std::endl;

    std::vector<std::string> expectedFiles = {
        mkDir + "/host_main.cc",
        mkDir + "/compile_all_kernels.sh",
    };
    for (const auto &ki : kernels) {
        expectedFiles.push_back(mkDir + "/" + ki.kernelName + "/host.cc");
        expectedFiles.push_back(mkDir + "/" + ki.kernelName + "/kernel.cc");
    }

    bool allExist = true;
    for (const auto &f : expectedFiles) {
        bool exists = llvm::sys::fs::exists(f);
        std::cout << "  " << (exists ? "OK" : "MISSING") << ": " << f << std::endl;
        if (!exists)
            allExist = false;
    }

    // Verify host_main.cc has 2 stages
    // Stage 0: gemm + conv (parallel)
    // Stage 1: relu (depends on gemm)
    auto bufOrErr = llvm::MemoryBuffer::getFile(mkDir + "/host_main.cc");
    if (bufOrErr) {
        auto content = (*bufOrErr)->getBuffer();
        bool hasStage0 = content.contains("Stage 0");
        bool hasStage1 = content.contains("Stage 1");
        bool hasDataTransfer = content.contains("Transferring data");
        bool has2Stages = content.contains("2 stage(s)");
        std::cout << "  " << (hasStage0 ? "OK" : "FAIL") << ": host_main.cc has Stage 0" << std::endl;
        std::cout << "  " << (hasStage1 ? "OK" : "FAIL") << ": host_main.cc has Stage 1" << std::endl;
        std::cout << "  " << (hasDataTransfer ? "OK" : "FAIL") << ": host_main.cc has data transfer" << std::endl;
        std::cout << "  " << (has2Stages ? "OK" : "FAIL") << ": host_main.cc reports 2 stages" << std::endl;
        if (!hasStage0 || !hasStage1 || !hasDataTransfer || !has2Stages)
            allExist = false;
    }

    if (allExist) {
        std::cout << "\nPASS: Mixed multi-kernel test passed." << std::endl;
    } else {
        std::cout << "\nFAIL: Some checks failed." << std::endl;
    }

    std::cout << "\n=== Multi-Kernel Mixed Test Complete ===" << std::endl;
}

int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string arg = argv[1];
        if (arg == "--parse") {
            if (argc < 4) {
                std::cerr << "Usage: ./test --parse <stage> <mlir_file>\n"
                          << "Supported stages:\n"
                          << "  routing        - stage 0 (initial routing IR)\n"
                          << "  dmap           - stage 2 (post-RoutingToDmap)\n"
                          << "  dmaphop        - stage 3 (post-DmapToDmaphop)\n"
                          << "  dfscheblueprint - stage 4 (post-DmaphopTodfscheblueprint, branch point)\n"
                          << "  dfschedule     - stage 5/6/10 (post-branch, auto-detects host/kernel)\n"
                          << "  emitc          - stage 7/8/9/11 (pure EmitC, auto-detects host/kernel)\n"
                          << std::endl;
                return 1;
            }
            std::string mode = argv[2];
            std::string filepath = argv[3];

            std::cout << "Executing --parse " << mode << " with IR from " << filepath << std::endl;

            // Validate IR dialect and auto-detect actual stage
            std::string detectedMode;
            {
                MLIRContext valCtx;
                valCtx.allowUnregisteredDialects();
                routingmanager valRouting;
                routinghwmanager valRoutinghw;
                dmapmanager valDmap;
                dmaphopmanager valDmaphop;
                dfscheblueprintmanager valBlueprint;
                dfschedulemanager valSchedule;
                valRouting.loaddialect(&valCtx);
                valRoutinghw.loaddialect(&valCtx);
                valDmap.loaddialect(&valCtx);
                valDmaphop.loaddialect(&valCtx);
                valBlueprint.loaddialect(&valCtx);
                valSchedule.loaddialect(&valCtx);
                valCtx.getOrLoadDialect<arith::ArithDialect>();
                valCtx.getOrLoadDialect<mlir::func::FuncDialect>();
                valCtx.getOrLoadDialect<mlir::scf::SCFDialect>();
                valCtx.getOrLoadDialect<mlir::tensor::TensorDialect>();
                valCtx.getOrLoadDialect<mlir::emitc::EmitCDialect>();
                valCtx.getOrLoadDialect<mlir::cf::ControlFlowDialect>();
                valCtx.getOrLoadDialect<mlir::bufferization::BufferizationDialect>();
                valCtx.getOrLoadDialect<mlir::memref::MemRefDialect>();

                auto valModule = loadModuleFromFile(valCtx, filepath);
                if (!valModule) return 1;
                if (!validateIRDialect(*valModule, mode, filepath, detectedMode))
                    return 1;

                // Use the detected mode (may differ from user-specified mode)
                mode = detectedMode;

                // For post-branch stages, auto-detect host vs kernel
                if (mode == "dfschedule" || mode == "emitc") {
                    std::string kind = detectHostOrKernel(*valModule);
                    if (kind == "unknown") {
                        std::cerr << "ERROR: Could not auto-detect host vs kernel for "
                                  << mode << " IR.\n"
                                  << "  File: " << filepath << "\n"
                                  << "  Hint: ensure the IR contains characteristic ops "
                                     "(dfschedule.declaretile for host, "
                                     "dfschedule.kernel_config_def for kernel).\n";
                        return 1;
                    }
                    // Store kind for startStage computation below
                    if (mode == "dfschedule")
                        mode = (kind == "host") ? "dfschedule_host" : "dfschedule_kernel";
                    else
                        mode = (kind == "host") ? "emitc_host" : "emitc_kernel";
                    std::cout << "Auto-detected " << kind << " path." << std::endl;
                }
            }

            // Map detected mode to startStage
            int startStage = -1;
            bool canProduceRouting = false;

            if (mode == "routing")                startStage = 0, canProduceRouting = true;
            else if (mode == "routing_unrolled")  startStage = 1, canProduceRouting = true;
            else if (mode == "dmap")              startStage = 2, canProduceRouting = true;
            else if (mode == "dmaphop")           startStage = 3, canProduceRouting = true;
            else if (mode == "dfscheblueprint")   startStage = 4;
            else if (mode == "dfschedule_host")   startStage = 5;
            else if (mode == "dfschedule_kernel") startStage = 10;
            else if (mode == "emitc_host")        startStage = 7;
            else if (mode == "emitc_kernel")      startStage = 11;
            else {
                std::cerr << "ERROR: Unrecognized detected mode: " << mode << "\n";
                return 1;
            }

            // Run dfschedule pipeline from the detected start stage
            routingtodfschedule(filepath, startStage);

            // Run routing.cc pipeline only if the entry stage is early enough
            if (canProduceRouting) {
                routingtodmap(filepath, startStage);
            }
        } else if (arg == "routing") {
            if (argc < 3) {
                std::cerr << "Usage: ./test routing <mlir_file>" << std::endl;
                return 1;
            }
            std::string filepath = argv[2];
            std::cout << "Executing routingtodfschedule with IR from " << filepath << std::endl;
            routingtodfschedule(filepath);
        } else if (arg == "hw") {
            std::cout << "Executing routingtoroutinghw..." << std::endl;
            routingtoroutinghw();
        } else if (arg == "test") {
            std::cout << "Executing unit test for RoutingLowerPass..." << std::endl;
            testRoutingLowerPassPathContiguity();
        } else if (arg == "dfschedule") {
            std::cout << "Executing routingtodfschedule..." << std::endl;
            routingtodfschedule();
        } else if (arg == "dmaphw") {
            std::cout << "Executing routingtodmap..." << std::endl;
            routingtodmap();
        } else if (arg == "multidim") {
            std::cout << "Executing multi-dimensional BD addressing test..." << std::endl;
            testMultidimBd();
        } else if (arg == "multikernel") {
            std::cout << "Executing multi-kernel pipeline test..." << std::endl;
            testMultiKernel();
        } else if (arg == "multikernel_seq") {
            std::cout << "Executing multi-kernel sequential test..." << std::endl;
            testMultiKernelSequential();
        } else if (arg == "multikernel_mixed") {
            std::cout << "Executing multi-kernel mixed test..." << std::endl;
            testMultiKernelMixed();
        } else {
            std::cout << "Invalid argument. Please use hw, test, dfschedule, dmaphw, multidim, "
                         "multikernel, multikernel_seq, multikernel_mixed, routing, --parse "
                         "<stage> <file>\n"
                      << "Stages: routing, dmap, dmaphop, dfscheblueprint, dfschedule, emitc" << std::endl;
        }
    } else {
        // Default behavior: routingtodfschedule generates host.cc, kernel.cc,
        // AND routing.cc (via the dmaphop->routinghw path in TilingLinalgPipeline).
        // Do NOT run routingtodmap() here — it would overwrite routing.cc with
        // independently-allocated packet IDs that don't match host.cc.
        std::cout << "Executing routingtodfschedule..." << std::endl;
        routingtodfschedule();
    }
    return 0;

}