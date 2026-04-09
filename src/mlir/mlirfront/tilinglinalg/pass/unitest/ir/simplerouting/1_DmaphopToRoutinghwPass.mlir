module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @routing(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 1 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_1", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %13 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %14 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %15 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %16 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %17 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %18 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %19 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 2 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_2", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %13 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %14 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %15 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %16 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %17 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %18 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %19 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %20 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %21 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %22 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %23 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %1 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 3 : i32, channelused = 0 : i32, col = 3 : i32, comments = "shim_dma_3", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %13 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %14 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %15 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %16 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %17 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %18 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 2} : i32
        %19 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 2} : i32
        %20 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "DMA", masterportidx = 1} : i32
        %21 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 4 : i32, channelused = 1 : i32, col = 3 : i32, comments = "shim_dma_4", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %13 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %14 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %15 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %16 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %17 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %18 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %19 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %20 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 3} : i32
        %21 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 3} : i32
        %22 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 1} : i32
        %23 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 1} : i32
        %24 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %25 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %2 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 5 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_5", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %8 = routinghw.connectpktstreamswitchport %5 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 9 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %9 = routinghw.connectpktstreamswitchport %6 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 10 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %10 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %11 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %13 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %14 = routinghw.enableaietoextshimport %7 : i32 {portdirection = "NORTH", portidx = 1 : i32} -> i32
        %15 = routinghw.connectpktstreamswitchport %6 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %16 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %17 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %18 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %19 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 6 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_6", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %8 = routinghw.connectpktstreamswitchport %5 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 11 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %9 = routinghw.connectpktstreamswitchport %6 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 12 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %10 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %11 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %13 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %15 = routinghw.enableaietoextshimport %7 : i32 {portdirection = "NORTH", portidx = 3 : i32} -> i32
        %16 = routinghw.connectpktstreamswitchport %6 : i32 {forwardmasterdirection = "SOUTH", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %17 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 1} : i32
        %18 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "WEST", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %19 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %20 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %21 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 3} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
