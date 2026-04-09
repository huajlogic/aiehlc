module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @routing() {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %cst = arith.constant dense<"0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF"> : tensor<16x16xi8>
    %cst_0 = arith.constant dense<"0x02030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF0001"> : tensor<16x16xi8>
    %cst_1 = arith.constant dense<"0x0102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00"> : tensor<16x16xi8>
    %0 = routing.routingcreatescheduletensor %cst_1 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    %1 = routing.routingcreatescheduletensor %cst_0 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    %2 = routing.routingcreatescheduletensor %cst : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %3 = routing.partitiontensor tensor = %0 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %4 = routing.partitiontensor tensor = %1 : tensor<16x16xi8> {
          splitnum = 1,
          splitdim = 0,
          hw_axis_owner = "",
          replicate_on = "row",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %5 = routing.partitiontensor tensor = %2 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %6 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %8 = routing.routingextract_data %3, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %9 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %10 = dmaphop.port @f6_corePortIn0 on %9 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %11 = dmaphop.port @f6_corePortOut0 on %9 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f6_corePortIn1 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f6_corePortOut1 on %12 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %16 = dmaphop.port @f6_shimPortOut on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f6_shimPortIn on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.create_hop %16 -> %10 -> !dmaphop.hop
        %19 = dmaphop.create_hop %11 -> %13 -> !dmaphop.hop
        %20 = dmaphop.create_path[%18, %19] {producers = [[@f6_shimPortIn]], consumers = [[@f6_corePortIn0, @f6_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %8 into %20 consumer(%8, %8 at %10, %13) : tensor<8x16xi8> !dmaphop.path tensor<8x16xi8>, tensor<8x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %20
        %21 = routing.routingextract_data %4, %arg0 : tensor<16x16xi8>, i32 -> tensor<16x16xi8>
        %22 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %23 = dmaphop.port @f7_corePortIn0 on %22 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.port @f7_corePortOut0 on %22 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %25 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %26 = dmaphop.port @f7_corePortIn1 on %25 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.port @f7_corePortOut1 on %25 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %29 = dmaphop.port @f7_shimPortOut on %28 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %30 = dmaphop.port @f7_shimPortIn on %28 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.create_hop %29 -> %23 -> !dmaphop.hop
        %32 = dmaphop.create_hop %24 -> %26 -> !dmaphop.hop
        %33 = dmaphop.create_path[%31, %32] {producers = [[@f7_shimPortIn]], consumers = [[@f7_corePortIn0, @f7_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %21 into %33 consumer(%21, %21 at %23, %26) : tensor<16x16xi8> !dmaphop.path tensor<16x16xi8>, tensor<16x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %33
        %34 = routing.routingextract_data %5, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %35 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %36 = dmaphop.port @f8_corePortIn0 on %35 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.port @f8_corePortOut0 on %35 { direction = "Out", direction_channel = 0, dmapktid = 5 : i32 } : !dmaphop.tile -> !dmaphop.port
        %38 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %39 = dmaphop.port @f8_corePortIn1 on %38 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %40 = dmaphop.port @f8_corePortOut1 on %38 { direction = "Out", direction_channel = 0, dmapktid = 6 : i32 } : !dmaphop.tile -> !dmaphop.port
        %41 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %42 = dmaphop.port @f8_shimPortOut on %41 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %43 = dmaphop.port @f8_shimPortIn on %41 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %44 = dmaphop.create_hop %40 -> %43 -> !dmaphop.hop
        %45 = dmaphop.create_hop %37 -> %39 -> !dmaphop.hop
        %46 = dmaphop.create_path[%44, %45] {producers = [[@f8_corePortOut0, @f8_corePortOut1]], consumers = [[@f8_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %34[0, 0] [4, 16] [1, 1] {tag = "producer0"} : tensor<8x16xi8> to tensor<4x16xi8>
        %extracted_slice_2 = tensor.extract_slice %34[4, 0] [4, 16] [1, 1] {tag = "producer1"} : tensor<8x16xi8> to tensor<4x16xi8>
        dmaphop.pull %34 from %46 producer(%extracted_slice, %extracted_slice_2 at %36, %39) : tensor<8x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %46
        "routing.yield"() : () -> ()
      }
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %8 = routing.routingextract_data %3, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %9 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %10 = dmaphop.port @f9_corePortIn0 on %9 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %11 = dmaphop.port @f9_corePortOut0 on %9 { direction = "Out", direction_channel = 0, dmapktid = 7 : i32 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %13 = dmaphop.port @f9_corePortIn1 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f9_corePortOut1 on %12 { direction = "Out", direction_channel = 0, dmapktid = 8 : i32 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %16 = dmaphop.port @f9_shimPortOut on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f9_shimPortIn on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.create_hop %16 -> %10 -> !dmaphop.hop
        %19 = dmaphop.create_hop %11 -> %13 -> !dmaphop.hop
        %20 = dmaphop.create_path[%18, %19] {producers = [[@f9_shimPortIn]], consumers = [[@f9_corePortIn0, @f9_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %8 into %20 consumer(%8, %8 at %10, %13) : tensor<8x16xi8> !dmaphop.path tensor<8x16xi8>, tensor<8x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %20
        %21 = routing.routingextract_data %4, %arg0 : tensor<16x16xi8>, i32 -> tensor<16x16xi8>
        %22 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %23 = dmaphop.port @f10_corePortIn0 on %22 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.port @f10_corePortOut0 on %22 { direction = "Out", direction_channel = 0, dmapktid = 9 : i32 } : !dmaphop.tile -> !dmaphop.port
        %25 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %26 = dmaphop.port @f10_corePortIn1 on %25 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.port @f10_corePortOut1 on %25 { direction = "Out", direction_channel = 0, dmapktid = 10 : i32 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %29 = dmaphop.port @f10_shimPortOut on %28 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %30 = dmaphop.port @f10_shimPortIn on %28 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.create_hop %29 -> %23 -> !dmaphop.hop
        %32 = dmaphop.create_hop %24 -> %26 -> !dmaphop.hop
        %33 = dmaphop.create_path[%31, %32] {producers = [[@f10_shimPortIn]], consumers = [[@f10_corePortIn0, @f10_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %21 into %33 consumer(%21, %21 at %23, %26) : tensor<16x16xi8> !dmaphop.path tensor<16x16xi8>, tensor<16x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %33
        %34 = routing.routingextract_data %5, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %35 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %36 = dmaphop.port @f11_corePortIn0 on %35 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.port @f11_corePortOut0 on %35 { direction = "Out", direction_channel = 0, dmapktid = 11 : i32 } : !dmaphop.tile -> !dmaphop.port
        %38 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %39 = dmaphop.port @f11_corePortIn1 on %38 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %40 = dmaphop.port @f11_corePortOut1 on %38 { direction = "Out", direction_channel = 0, dmapktid = 12 : i32 } : !dmaphop.tile -> !dmaphop.port
        %41 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %42 = dmaphop.port @f11_shimPortOut on %41 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %43 = dmaphop.port @f11_shimPortIn on %41 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %44 = dmaphop.create_hop %40 -> %43 -> !dmaphop.hop
        %45 = dmaphop.create_hop %37 -> %39 -> !dmaphop.hop
        %46 = dmaphop.create_path[%44, %45] {producers = [[@f11_corePortOut0, @f11_corePortOut1]], consumers = [[@f11_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %34[0, 0] [4, 16] [1, 1] {tag = "producer0"} : tensor<8x16xi8> to tensor<4x16xi8>
        %extracted_slice_2 = tensor.extract_slice %34[4, 0] [4, 16] [1, 1] {tag = "producer1"} : tensor<8x16xi8> to tensor<4x16xi8>
        dmaphop.pull %34 from %46 producer(%extracted_slice, %extracted_slice_2 at %36, %39) : tensor<8x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %46
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
