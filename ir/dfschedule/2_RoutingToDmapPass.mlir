module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @main(%arg0: memref<256x256xi8>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<256x256xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<256x256xi8> shape = [256, 256], dim = 2 -> tensor<256x256xi8>
    %2 = bufferization.to_tensor %arg1 : memref<256x256xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<256x256xi8> shape = [256, 256], dim = 2 -> tensor<256x256xi8>
    %4 = bufferization.to_tensor %arg2 : memref<256x256xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<256x256xi8> shape = [256, 256], dim = 2 -> tensor<256x256xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %3 : tensor<256x256xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "col",
          replicate_on = "row",
          single_tile_owner = ""
     } -> tensor<256x256xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmap.define_io_engine {io_id = 12 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %13 = dmap.define_core_group {core_count = 4 : i32, group_axis = "col", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %14 = dmap.define_port_configure @receive_port_12 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %15 = dmap.create_io_engin_with_config %12 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %16 = dmap.create_core_group_with_config %13{[{0, @receive_port_12}, {1, @receive_port_12}, {2, @receive_port_12}, {3, @receive_port_12}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %17 = dmap.create_stream src = %15, dst = %16, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %11 : tensor<64x256xi8> to %17 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmap.define_io_engine {io_id = 13 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %13 = dmap.define_core_group {core_count = 4 : i32, group_axis = "col", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %14 = dmap.define_port_configure @receive_port_13 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %15 = dmap.create_io_engin_with_config %12 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %16 = dmap.create_core_group_with_config %13{[{0, @receive_port_13}, {1, @receive_port_13}, {2, @receive_port_13}, {3, @receive_port_13}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %17 = dmap.create_stream src = %15, dst = %16, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %11 : tensor<64x256xi8> to %17 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmap.define_io_engine {io_id = 14 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %13 = dmap.define_core_group {core_count = 4 : i32, group_axis = "col", group_idx = 2 : i32} -> !dmap.dmacoreenginegroupType
        %14 = dmap.define_port_configure @receive_port_14 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %15 = dmap.create_io_engin_with_config %12 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %16 = dmap.create_core_group_with_config %13{[{0, @receive_port_14}, {1, @receive_port_14}, {2, @receive_port_14}, {3, @receive_port_14}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %17 = dmap.create_stream src = %15, dst = %16, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %11 : tensor<64x256xi8> to %17 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmap.define_io_engine {io_id = 15 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %13 = dmap.define_core_group {core_count = 4 : i32, group_axis = "col", group_idx = 3 : i32} -> !dmap.dmacoreenginegroupType
        %14 = dmap.define_port_configure @receive_port_15 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %15 = dmap.create_io_engin_with_config %12 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %16 = dmap.create_core_group_with_config %13{[{0, @receive_port_15}, {1, @receive_port_15}, {2, @receive_port_15}, {3, @receive_port_15}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %17 = dmap.create_stream src = %15, dst = %16, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %11 : tensor<64x256xi8> to %17 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %1 : tensor<256x256xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<256x256xi8>
      %7 = routing.partitiontensor tensor = %5 : tensor<256x256xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<256x256xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %12 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmap.define_io_engine {io_id = 16 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %14 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %15 = dmap.define_port_configure @receive_port_16 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %16 = dmap.create_io_engin_with_config %13 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %17 = dmap.create_core_group_with_config %14{[{0, @receive_port_16}, {1, @receive_port_16}, {2, @receive_port_16}, {3, @receive_port_16}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %18 = dmap.create_stream src = %16, dst = %17, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %12 : tensor<64x256xi8> to %18 : !dmap.dmapportstream
        %19 = routing.routingextract_data %7, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %20 = dmap.define_io_engine {io_id = 17 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %21 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %22 = dmap.define_port_configure @send_port_17 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %23 = dmap.create_io_engin_with_config %20 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %24 = dmap.create_core_group_with_config %21{[{0, @send_port_17}, {1, @send_port_17}, {2, @send_port_17}, {3, @send_port_17}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %25 = dmap.create_stream src = %24, dst = %23, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %19 : tensor<64x256xi8> from %25 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %12 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmap.define_io_engine {io_id = 18 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %14 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %15 = dmap.define_port_configure @receive_port_18 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %16 = dmap.create_io_engin_with_config %13 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %17 = dmap.create_core_group_with_config %14{[{0, @receive_port_18}, {1, @receive_port_18}, {2, @receive_port_18}, {3, @receive_port_18}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %18 = dmap.create_stream src = %16, dst = %17, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %12 : tensor<64x256xi8> to %18 : !dmap.dmapportstream
        %19 = routing.routingextract_data %7, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %20 = dmap.define_io_engine {io_id = 19 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %21 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %22 = dmap.define_port_configure @send_port_19 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %23 = dmap.create_io_engin_with_config %20 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %24 = dmap.create_core_group_with_config %21{[{0, @send_port_19}, {1, @send_port_19}, {2, @send_port_19}, {3, @send_port_19}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %25 = dmap.create_stream src = %24, dst = %23, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %19 : tensor<64x256xi8> from %25 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %12 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmap.define_io_engine {io_id = 20 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %14 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 2 : i32} -> !dmap.dmacoreenginegroupType
        %15 = dmap.define_port_configure @receive_port_20 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %16 = dmap.create_io_engin_with_config %13 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %17 = dmap.create_core_group_with_config %14{[{0, @receive_port_20}, {1, @receive_port_20}, {2, @receive_port_20}, {3, @receive_port_20}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %18 = dmap.create_stream src = %16, dst = %17, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %12 : tensor<64x256xi8> to %18 : !dmap.dmapportstream
        %19 = routing.routingextract_data %7, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %20 = dmap.define_io_engine {io_id = 21 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %21 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 2 : i32} -> !dmap.dmacoreenginegroupType
        %22 = dmap.define_port_configure @send_port_21 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %23 = dmap.create_io_engin_with_config %20 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %24 = dmap.create_core_group_with_config %21{[{0, @send_port_21}, {1, @send_port_21}, {2, @send_port_21}, {3, @send_port_21}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %25 = dmap.create_stream src = %24, dst = %23, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %19 : tensor<64x256xi8> from %25 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %12 = routing.routingextract_data %6, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmap.define_io_engine {io_id = 22 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %14 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 3 : i32} -> !dmap.dmacoreenginegroupType
        %15 = dmap.define_port_configure @receive_port_22 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %16 = dmap.create_io_engin_with_config %13 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %17 = dmap.create_core_group_with_config %14{[{0, @receive_port_22}, {1, @receive_port_22}, {2, @receive_port_22}, {3, @receive_port_22}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %18 = dmap.create_stream src = %16, dst = %17, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %12 : tensor<64x256xi8> to %18 : !dmap.dmapportstream
        %19 = routing.routingextract_data %7, %arg3 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %20 = dmap.define_io_engine {io_id = 23 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %21 = dmap.define_core_group {core_count = 4 : i32, group_axis = "row", group_idx = 3 : i32} -> !dmap.dmacoreenginegroupType
        %22 = dmap.define_port_configure @send_port_23 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %23 = dmap.create_io_engin_with_config %20 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %24 = dmap.create_core_group_with_config %21{[{0, @send_port_23}, {1, @send_port_23}, {2, @send_port_23}, {3, @send_port_23}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %25 = dmap.create_stream src = %24, dst = %23, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %19 : tensor<64x256xi8> from %25 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
