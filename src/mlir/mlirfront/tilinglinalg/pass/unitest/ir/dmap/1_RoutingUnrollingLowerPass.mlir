module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @routing() {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %cst = arith.constant dense<"0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF"> : tensor<16x16xi8>
    %cst_0 = arith.constant dense<"0x02030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF0001"> : tensor<16x16xi8>
    %cst_1 = arith.constant dense<"0x0102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00"> : tensor<16x16xi8>
    %0 = routing.routingcreatehwmesh row = 2, col = 2 -> i32
    %1 = routing.routingcreatescheduletensor %cst_1 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    %2 = routing.routingcreatescheduletensor %cst_0 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    %3 = routing.routingcreatescheduletensor %cst : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %4 = routing.partitionmesh mesh = %0, splitnum = 2, splitaxis = "row" : i32 -> i32
      %5 = routing.partitiontensor tensor = %1 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %6 = routing.partitiontensor tensor = %2 : tensor<16x16xi8> {
          splitnum = 1,
          splitdim = 0,
          hw_axis_owner = "",
          replicate_on = "row",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.partitiontensor tensor = %3 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %10 = routing.routingextract_tiles %4, %arg0 : i32, i32 -> i32
        %11 = routing.routingextract_data %5, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %12 = routing.routingcreatehwiowithtarget targettilelist = %10 : i32 {direction = "input", iotype = "mem2"} -> i32
        %13 = routing.routingmovedatabyio tensordata = %11, hwiowithtarget = %12 : tensor<8x16xi8>, i32 -> i32
        %14 = routing.routingextract_data %6, %arg0 : tensor<16x16xi8>, i32 -> tensor<16x16xi8>
        %15 = routing.routingcreatehwiowithtarget targettilelist = %10 : i32 {direction = "input", iotype = "mem2"} -> i32
        %16 = routing.routingmovedatabyio tensordata = %14, hwiowithtarget = %15 : tensor<16x16xi8>, i32 -> i32
        %17 = routing.routingextract_data %7, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %18 = routing.routingroutinggatherout tilelist = %10, tensordata = %17 : i32, tensor<8x16xi8> -> tensor<8x16xi8>
        %19 = routing.routingcreatehwiowithtarget targettilelist = %10 : i32 {direction = "output", iotype = "mem2"} -> i32
        %20 = routing.routingmovedatabyio tensordata = %18, hwiowithtarget = %19 : tensor<8x16xi8>, i32 -> i32
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %10 = routing.routingextract_tiles %4, %arg0 : i32, i32 -> i32
        %11 = routing.routingextract_data %5, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %12 = routing.routingcreatehwiowithtarget targettilelist = %10 : i32 {direction = "input", iotype = "mem2"} -> i32
        %13 = routing.routingmovedatabyio tensordata = %11, hwiowithtarget = %12 : tensor<8x16xi8>, i32 -> i32
        %14 = routing.routingextract_data %6, %arg0 : tensor<16x16xi8>, i32 -> tensor<16x16xi8>
        %15 = routing.routingcreatehwiowithtarget targettilelist = %10 : i32 {direction = "input", iotype = "mem2"} -> i32
        %16 = routing.routingmovedatabyio tensordata = %14, hwiowithtarget = %15 : tensor<16x16xi8>, i32 -> i32
        %17 = routing.routingextract_data %7, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %18 = routing.routingroutinggatherout tilelist = %10, tensordata = %17 : i32, tensor<8x16xi8> -> tensor<8x16xi8>
        %19 = routing.routingcreatehwiowithtarget targettilelist = %10 : i32 {direction = "output", iotype = "mem2"} -> i32
        %20 = routing.routingmovedatabyio tensordata = %18, hwiowithtarget = %19 : tensor<8x16xi8>, i32 -> i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
