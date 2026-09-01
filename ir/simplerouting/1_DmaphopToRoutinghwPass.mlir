module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @routing(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: memref<32xi8>, %arg2: memref<9286xi8>, %arg3: memref<32xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg1 : memref<32xi8>
    %1 = bufferization.to_tensor %arg2 : memref<9286xi8>
    %2 = bufferization.to_tensor %arg3 : memref<32xi8>
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %6 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 235 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_235", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %13 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %14 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %15 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %16 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %17 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %18 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %19 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %20 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        %21 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %5 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 236 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_236", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %13 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %14 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %15 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %16 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %17 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %18 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %19 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 237 : i32, channelused = 0 : i32, col = 3 : i32, comments = "shim_dma_237", dmadirection = 0 : i32, row = 0 : i32} -> i32
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
        %19 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 1} : i32
        %20 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "DMA", masterportidx = 0} : i32
        %21 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 0} : i32
        %22 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %23 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %24 = routinghw.ioshimtilecreate {IOID = 238 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_238", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %25 = routinghw.connectpktstreamswitchport %22 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 2 : i32, localdmadirection = "DMA", localdmapktid = 1 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, preserveheader = true, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %26 = routinghw.connectpktstreamswitchport %23 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 2 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, preserveheader = true, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 2 : i32} -> i32
        %27 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %28 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %29 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %30 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %31 = routinghw.enableaietoextshimport %24 : i32 {portdirection = "NORTH", portidx = 1 : i32} -> i32
        %32 = routinghw.connectpktstreamswitchport %23 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 3 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, preserveheader = true, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %33 = routinghw.connectsinglestreamswitchport %27 : {slaveportdirection = "WEST", slaveportidx = 3, masterportdirection = "SOUTH", masterportidx = 2} : i32
        %34 = routinghw.connectsinglestreamswitchport %28 : {slaveportdirection = "NORTH", slaveportidx = 2, masterportdirection = "SOUTH", masterportidx = 2} : i32
        %35 = routinghw.connectsinglestreamswitchport %29 : {slaveportdirection = "NORTH", slaveportidx = 2, masterportdirection = "SOUTH", masterportidx = 2} : i32
        %36 = routinghw.connectsinglestreamswitchport %24 : {slaveportdirection = "NORTH", slaveportidx = 2, masterportdirection = "SOUTH", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %4 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %5 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %6 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %7 = routinghw.ioshimtilecreate {IOID = 239 : i32, channelused = 1 : i32, col = 3 : i32, comments = "shim_dma_239", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %8 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %9 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %10 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %11 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %13 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %14 = routinghw.enableexttoaieshimport %7 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %15 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %16 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %17 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %18 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %19 = routinghw.connectsinglestreamswitchport %12 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 0} : i32
        %20 = routinghw.connectsinglestreamswitchport %13 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %21 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %22 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %23 = routinghw.connectsinglestreamswitchport %5 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %24 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %25 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %26 = routinghw.ioshimtilecreate {IOID = 240 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_240", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %27 = routinghw.connectpktstreamswitchport %24 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "DMA", localdmapktid = 3 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, preserveheader = true, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %28 = routinghw.connectpktstreamswitchport %25 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 4 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, preserveheader = true, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 1 : i32} -> i32
        %29 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 4 : i32} -> i32
        %30 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %31 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %32 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %33 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %34 = routinghw.enableaietoextshimport %26 : i32 {portdirection = "NORTH", portidx = 3 : i32} -> i32
        %35 = routinghw.connectpktstreamswitchport %25 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 1 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, preserveheader = true, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %36 = routinghw.connectsinglestreamswitchport %29 : {slaveportdirection = "WEST", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %37 = routinghw.connectsinglestreamswitchport %30 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 3} : i32
        %38 = routinghw.connectsinglestreamswitchport %31 : {slaveportdirection = "NORTH", slaveportidx = 3, masterportdirection = "SOUTH", masterportidx = 3} : i32
        %39 = routinghw.connectsinglestreamswitchport %32 : {slaveportdirection = "NORTH", slaveportidx = 3, masterportdirection = "SOUTH", masterportidx = 3} : i32
        %40 = routinghw.connectsinglestreamswitchport %26 : {slaveportdirection = "NORTH", slaveportidx = 3, masterportdirection = "SOUTH", masterportidx = 3} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
