module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @routing() {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %cst = arith.constant dense<"0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF"> : tensor<16x16xi8>
    %cst_0 = arith.constant dense<"0x02030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF0001"> : tensor<16x16xi8>
    %cst_1 = arith.constant dense<"0x0102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00"> : tensor<16x16xi8>
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %2 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %3 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %4 = routinghw.ioshimtilecreate {IOID = 15 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_15", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %5 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %6 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %7 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %8 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %9 = routinghw.enableexttoaieshimport %4 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %10 = routinghw.connectsinglestreamswitchport %4 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %11 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %12 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %13 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %14 = routinghw.connectsinglestreamswitchport %3 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %15 = routinghw.connectsinglestreamswitchport %3 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %16 = routinghw.connectsinglestreamswitchport %2 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %17 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %18 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %19 = routinghw.ioshimtilecreate {IOID = 16 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_16", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %20 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %21 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %22 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %23 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %24 = routinghw.enableexttoaieshimport %19 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %25 = routinghw.connectsinglestreamswitchport %19 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %26 = routinghw.connectsinglestreamswitchport %21 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %27 = routinghw.connectsinglestreamswitchport %22 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %28 = routinghw.connectsinglestreamswitchport %23 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %29 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %30 = routinghw.connectsinglestreamswitchport %18 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %31 = routinghw.connectsinglestreamswitchport %17 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %32 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %33 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 3 : i32} -> i32
        %34 = routinghw.ioshimtilecreate {IOID = 17 : i32, channelused = 0 : i32, col = 2 : i32, comments = "shim_dma_17", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %35 = routinghw.connectpktstreamswitchport %32 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 5 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %36 = routinghw.connectpktstreamswitchport %33 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 6 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %37 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %38 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %39 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %40 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %41 = routinghw.enableaietoextshimport %34 : i32 {portdirection = "NORTH", portidx = 1 : i32} -> i32
        %42 = routinghw.connectpktstreamswitchport %33 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %43 = routinghw.connectsinglestreamswitchport %37 : {slaveportdirection = "WEST", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %44 = routinghw.connectsinglestreamswitchport %38 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %45 = routinghw.connectsinglestreamswitchport %39 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 0} : i32
        %46 = routinghw.connectsinglestreamswitchport %34 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "SOUTH", masterportidx = 1} : i32
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %2 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %3 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %4 = routinghw.ioshimtilecreate {IOID = 18 : i32, channelused = 0 : i32, col = 3 : i32, comments = "shim_dma_18", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %5 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %6 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %7 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %8 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %9 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %10 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %11 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %12 = routinghw.enableexttoaieshimport %4 : i32 {portdirection = "SOUTH", portidx = 3 : i32} -> i32
        %13 = routinghw.connectsinglestreamswitchport %4 : {slaveportdirection = "SOUTH", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 0} : i32
        %14 = routinghw.connectsinglestreamswitchport %6 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %15 = routinghw.connectsinglestreamswitchport %7 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "NORTH", masterportidx = 0} : i32
        %16 = routinghw.connectsinglestreamswitchport %8 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 0} : i32
        %17 = routinghw.connectsinglestreamswitchport %9 : {slaveportdirection = "EAST", slaveportidx = 0, masterportdirection = "WEST", masterportidx = 2} : i32
        %18 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "WEST", masterportidx = 2} : i32
        %19 = routinghw.connectsinglestreamswitchport %10 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 0} : i32
        %20 = routinghw.connectsinglestreamswitchport %11 : {slaveportdirection = "EAST", slaveportidx = 2, masterportdirection = "NORTH", masterportidx = 0} : i32
        %21 = routinghw.connectsinglestreamswitchport %2 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %22 = routinghw.connectsinglestreamswitchport %3 : {slaveportdirection = "SOUTH", slaveportidx = 0, masterportdirection = "DMA", masterportidx = 0} : i32
        %23 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %24 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %25 = routinghw.ioshimtilecreate {IOID = 19 : i32, channelused = 1 : i32, col = 3 : i32, comments = "shim_dma_19", dmadirection = 0 : i32, row = 0 : i32} -> i32
        %26 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %27 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %28 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %29 = routinghw.tilecreate {col = 3 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %30 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %31 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %32 = routinghw.tilecreate {col = 0 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %33 = routinghw.enableexttoaieshimport %25 : i32 {portdirection = "SOUTH", portidx = 7 : i32} -> i32
        %34 = routinghw.connectsinglestreamswitchport %25 : {slaveportdirection = "SOUTH", slaveportidx = 7, masterportdirection = "NORTH", masterportidx = 1} : i32
        %35 = routinghw.connectsinglestreamswitchport %27 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %36 = routinghw.connectsinglestreamswitchport %28 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "NORTH", masterportidx = 1} : i32
        %37 = routinghw.connectsinglestreamswitchport %29 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 1} : i32
        %38 = routinghw.connectsinglestreamswitchport %30 : {slaveportdirection = "EAST", slaveportidx = 1, masterportdirection = "WEST", masterportidx = 3} : i32
        %39 = routinghw.connectsinglestreamswitchport %31 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "WEST", masterportidx = 3} : i32
        %40 = routinghw.connectsinglestreamswitchport %31 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 1} : i32
        %41 = routinghw.connectsinglestreamswitchport %32 : {slaveportdirection = "EAST", slaveportidx = 3, masterportdirection = "NORTH", masterportidx = 1} : i32
        %42 = routinghw.connectsinglestreamswitchport %23 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %43 = routinghw.connectsinglestreamswitchport %24 : {slaveportdirection = "SOUTH", slaveportidx = 1, masterportdirection = "DMA", masterportidx = 1} : i32
        %44 = routinghw.tilecreate {col = 0 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %45 = routinghw.tilecreate {col = 1 : i32, comments = "core_tile", row = 4 : i32} -> i32
        %46 = routinghw.ioshimtilecreate {IOID = 20 : i32, channelused = 1 : i32, col = 2 : i32, comments = "shim_dma_20", dmadirection = 1 : i32, row = 0 : i32} -> i32
        %47 = routinghw.connectpktstreamswitchport %44 : i32 {forwardmasterdirection = "EAST", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 11 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %48 = routinghw.connectpktstreamswitchport %45 : i32 {forwardmasterdirection = "NONE", forwardmasterportidx = 0 : i32, localdmadirection = "DMA", localdmapktid = 12 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "WEST", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %49 = routinghw.tilecreate {col = 1 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %50 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 3 : i32} -> i32
        %51 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 2 : i32} -> i32
        %52 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 1 : i32} -> i32
        %53 = routinghw.tilecreate {col = 2 : i32, comments = "tile in path", row = 0 : i32} -> i32
        %54 = routinghw.enableaietoextshimport %46 : i32 {portdirection = "NORTH", portidx = 3 : i32} -> i32
        %55 = routinghw.connectpktstreamswitchport %45 : i32 {forwardmasterdirection = "SOUTH", forwardmasterportidx = 0 : i32, localdmadirection = "NONE", localdmapktid = 0 : i32, localdmapkttype = 0 : i32, localdmaportidx = 0 : i32, receiveslavedirection = "NONE", receiveslavepktid = 0 : i32, receiveslavepkttype = 0 : i32, receiveslaveportidx = 0 : i32} -> i32
        %56 = routinghw.connectsinglestreamswitchport %49 : {slaveportdirection = "NORTH", slaveportidx = 0, masterportdirection = "EAST", masterportidx = 1} : i32
        %57 = routinghw.connectsinglestreamswitchport %50 : {slaveportdirection = "WEST", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %58 = routinghw.connectsinglestreamswitchport %51 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %59 = routinghw.connectsinglestreamswitchport %52 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 1} : i32
        %60 = routinghw.connectsinglestreamswitchport %46 : {slaveportdirection = "NORTH", slaveportidx = 1, masterportdirection = "SOUTH", masterportidx = 3} : i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
