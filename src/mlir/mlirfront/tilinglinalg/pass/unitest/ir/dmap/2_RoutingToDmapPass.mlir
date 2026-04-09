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
        %9 = dmap.define_io_engine {io_id = 6 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %10 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %11 = dmap.define_port_configure @receive_port_6 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %12 = dmap.create_io_engin_with_config %9 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %13 = dmap.create_core_group_with_config %10{[{0, @receive_port_6}, {1, @receive_port_6}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %14 = dmap.create_stream src = %12, dst = %13, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %8 : tensor<8x16xi8> to %14 : !dmap.dmapportstream
        %15 = routing.routingextract_data %4, %arg0 : tensor<16x16xi8>, i32 -> tensor<16x16xi8>
        %16 = dmap.define_io_engine {io_id = 7 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %17 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %18 = dmap.define_port_configure @receive_port_7 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %19 = dmap.create_io_engin_with_config %16 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %20 = dmap.create_core_group_with_config %17{[{0, @receive_port_7}, {1, @receive_port_7}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %21 = dmap.create_stream src = %19, dst = %20, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %15 : tensor<16x16xi8> to %21 : !dmap.dmapportstream
        %22 = routing.routingextract_data %5, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %23 = dmap.define_io_engine {io_id = 8 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %24 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %25 = dmap.define_port_configure @send_port_8 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %26 = dmap.create_io_engin_with_config %23 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %27 = dmap.create_core_group_with_config %24{[{0, @send_port_8}, {1, @send_port_8}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %28 = dmap.create_stream src = %27, dst = %26, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %22 : tensor<8x16xi8> from %28 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg0: i32):
        %8 = routing.routingextract_data %3, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %9 = dmap.define_io_engine {io_id = 9 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %10 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %11 = dmap.define_port_configure @receive_port_9 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %12 = dmap.create_io_engin_with_config %9 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %13 = dmap.create_core_group_with_config %10{[{0, @receive_port_9}, {1, @receive_port_9}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %14 = dmap.create_stream src = %12, dst = %13, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %8 : tensor<8x16xi8> to %14 : !dmap.dmapportstream
        %15 = routing.routingextract_data %4, %arg0 : tensor<16x16xi8>, i32 -> tensor<16x16xi8>
        %16 = dmap.define_io_engine {io_id = 10 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %17 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %18 = dmap.define_port_configure @receive_port_10 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %19 = dmap.create_io_engin_with_config %16 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %20 = dmap.create_core_group_with_config %17{[{0, @receive_port_10}, {1, @receive_port_10}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %21 = dmap.create_stream src = %19, dst = %20, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %15 : tensor<16x16xi8> to %21 : !dmap.dmapportstream
        %22 = routing.routingextract_data %5, %arg0 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %23 = dmap.define_io_engine {io_id = 11 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %24 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %25 = dmap.define_port_configure @send_port_11 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %26 = dmap.create_io_engin_with_config %23 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %27 = dmap.create_core_group_with_config %24{[{0, @send_port_11}, {1, @send_port_11}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %28 = dmap.create_stream src = %27, dst = %26, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %22 : tensor<8x16xi8> from %28 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
