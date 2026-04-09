module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %1 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmap.define_io_engine {io_id = 0 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @receive_port_0 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @receive_port_0}, {1, @receive_port_0}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %13, dst = %14, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %9 : tensor<8x16xi8> to %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmap.define_io_engine {io_id = 1 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @receive_port_1 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @receive_port_1}, {1, @receive_port_1}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %13, dst = %14, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %9 : tensor<8x16xi8> to %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %2 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %3 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmap.define_io_engine {io_id = 2 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @receive_port_2 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @receive_port_2}, {1, @receive_port_2}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %13, dst = %14, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %9 : tensor<8x16xi8> to %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmap.define_io_engine {io_id = 3 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @receive_port_3 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @receive_port_3}, {1, @receive_port_3}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %13, dst = %14, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %9 : tensor<8x16xi8> to %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %4 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %5 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmap.define_io_engine {io_id = 4 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @send_port_4 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @send_port_4}, {1, @send_port_4}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %14, dst = %13, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %9 : tensor<8x16xi8> from %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmap.define_io_engine {io_id = 5 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @send_port_5 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @send_port_5}, {1, @send_port_5}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %14, dst = %13, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %9 : tensor<8x16xi8> from %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
