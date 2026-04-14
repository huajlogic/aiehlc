module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @routing(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 1 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_1", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %16 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %17 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %18 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %19 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %20 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %21 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %22 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %23 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %24 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %25 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 2 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_2", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %19 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %20 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %21 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %22 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %23 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %24 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %25 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %26 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %27 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %28 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %29 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %30 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %31 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        "routing.yield"() : () -> ()
      }
      %5 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 3 : i32, channelused = 0 : i32, col = 3 : i32, comments = "shim_dma_3", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %19 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %20 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %21 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %22 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %23 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %24 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %25 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 2} : i32
        %26 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 2} : i32
        %27 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 1} : i32
        %28 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %29 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %30 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %31 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %32 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %33 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %34 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %35 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        "routing.yield"() : () -> ()
      }
      %6 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 4 : i32, channelused = 1 : i32, col = 3 : i32, comments = "shim_dma_4", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %19 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %20 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 5 : i32} -> i32
        %21 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %22 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %23 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %24 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %25 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %26 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 3} : i32
        %27 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 3} : i32
        %28 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 2} : i32
        %29 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "SOUTH", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 1} : i32
        %30 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %31 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %32 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %33 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %34 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %35 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 0} : i32
        %36 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %37 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %1 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 5 : i32, channelused = 0 : i32, col = 6 : i32, comments = "shim_dma_5", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 5 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 4 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %19 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %20 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %21 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %22 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %23 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %24 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %25 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %26 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %27 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %28 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 2} : i32
        %29 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %30 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 1} : i32
        %31 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 2} : i32
        %32 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "DMA", masterportidx = 1} : i32
        %33 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "SOUTH", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 1} : i32
        %34 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %35 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %36 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %37 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 6 : i32, channelused = 1 : i32, col = 6 : i32, comments = "shim_dma_6", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 5 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 4 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %19 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %20 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %21 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %22 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %23 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %24 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %25 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %26 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %27 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 3} : i32
        %28 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %29 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 3} : i32
        %30 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 2} : i32
        %31 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "DMA", masterportidx = 1} : i32
        %32 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 1} : i32
        %33 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "DMA", masterportidx = 1} : i32
        %34 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %35 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %5 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 7 : i32, channelused = 0 : i32, col = 7 : i32, comments = "shim_dma_7", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 5 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 4 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %19 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %20 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %21 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %22 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %23 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %24 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %25 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %26 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %27 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %28 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %29 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 2} : i32
        %30 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 2} : i32
        %31 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 2} : i32
        %32 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 1} : i32
        %33 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 0} : i32
        %34 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %35 = routinghw.connectsinglestreamswitchport %21 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 3} : i32
        %36 = routinghw.connectsinglestreamswitchport %21 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %37 = routinghw.connectsinglestreamswitchport %22 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 2} : i32
        %38 = routinghw.connectsinglestreamswitchport %22 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %39 = routinghw.connectsinglestreamswitchport %23 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 2} : i32
        %40 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 2, masterportdirection = "DMA", masterportidx = 1} : i32
        %41 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %42 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %43 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %6 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 8 : i32, channelused = 1 : i32, col = 7 : i32, comments = "shim_dma_8", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %12 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %13 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %14 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %15 = routinghw.tilecreate {col = 7 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %16 = routinghw.tilecreate {col = 6 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 5 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 4 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %19 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %20 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %21 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %22 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 5 : i32} -> i32
        %23 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 5 : i32} -> i32
        %24 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 5 : i32} -> i32
        %25 = routinghw.enableexttoaieshimport %11 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %26 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %27 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %28 = routinghw.connectsinglestreamswitchport %14 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %29 = routinghw.connectsinglestreamswitchport %15 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %30 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 3} : i32
        %31 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 3} : i32
        %32 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 3} : i32
        %33 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 2} : i32
        %34 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "SOUTH", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 1} : i32
        %35 = routinghw.connectsinglestreamswitchport %21 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %36 = routinghw.connectsinglestreamswitchport %22 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 0} : i32
        %37 = routinghw.connectsinglestreamswitchport %22 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %38 = routinghw.connectsinglestreamswitchport %23 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %39 = routinghw.connectsinglestreamswitchport %23 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %40 = routinghw.connectsinglestreamswitchport %24 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 1} : i32
        %41 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %42 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %43 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 1} : i32
        %44 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %45 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "WEST", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %2 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 9 : i32, channelused = 0 : i32, col = 3 : i32, comments = "shim_dma_9", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %12 = routinghw.connectpktstreamswitchport %7 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 1 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %13 = routinghw.connectpktstreamswitchport %8 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 2 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %14 = routinghw.connectpktstreamswitchport %9 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 3 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %15 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 4 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %16 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %17 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %18 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %19 = routinghw.enableaietoextshimport %11 : i32 {portdirection = "NORTH", portidx = 1 : i32} -> i32
        %20 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "SOUTH", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %21 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %22 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %23 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 10 : i32, channelused = 1 : i32, col = 3 : i32, comments = "shim_dma_10", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %12 = routinghw.connectpktstreamswitchport %7 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 5 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %13 = routinghw.connectpktstreamswitchport %8 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 6 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %14 = routinghw.connectpktstreamswitchport %9 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 7 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %15 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 8 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %16 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %17 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %18 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %19 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %20 = routinghw.enableaietoextshimport %11 : i32 {portdirection = "NORTH", portidx = 3 : i32} -> i32
        %21 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "SOUTH", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %22 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %23 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %24 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %25 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 3} : i32
        "routing.yield"() : () -> ()
      }
      %5 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 5 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 11 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_11", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %12 = routinghw.connectpktstreamswitchport %7 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 9 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %13 = routinghw.connectpktstreamswitchport %8 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 10 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %14 = routinghw.connectpktstreamswitchport %9 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 11 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %15 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 12 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %16 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %17 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %18 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %19 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %20 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %21 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %22 = routinghw.enableaietoextshimport %11 : i32 {portdirection = "NORTH", portidx = 1 : i32} -> i32
        %23 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "SOUTH", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %24 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 2} : i32
        %25 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %26 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %27 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %28 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %29 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %6 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %7 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %8 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "core_tile", row = 6 : i32} -> i32
        %11 = routinghw.ioshimtilecreate {IOID = 12 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_12", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %12 = routinghw.connectpktstreamswitchport %7 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 13 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %13 = routinghw.connectpktstreamswitchport %8 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 14 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %14 = routinghw.connectpktstreamswitchport %9 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 2 : i32, localdmadirection = "DMA", localdmapktid = 15 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %15 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 16 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 2 : i32} -> i32
        %16 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 5 : i32} -> i32
        %17 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %18 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %19 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %20 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %21 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %22 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %23 = routinghw.enableaietoextshimport %11 : i32 {portdirection = "NORTH", portidx = 3 : i32} -> i32
        %24 = routinghw.connectpktstreamswitchport %10 : i32 {forwardmasterdirection = "SOUTH", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %25 = routinghw.connectsinglestreamswitchport %16 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %26 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 3} : i32
        %27 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %28 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %29 = routinghw.connectsinglestreamswitchport %20 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %30 = routinghw.connectsinglestreamswitchport %21 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %31 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 3} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
