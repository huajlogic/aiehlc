module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @main(%arg0: memref<158700xi8>, %arg1: memref<9548xi8>, %arg2: memref<846400xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<158700xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<158700xi8> shape = [158700], dim = 1 -> tensor<158700xi8>
    %2 = bufferization.to_tensor %arg1 : memref<9548xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<9548xi8> shape = [9548], dim = 1 -> tensor<9548xi8>
    %4 = bufferization.to_tensor %arg2 : memref<846400xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<846400xi8> shape = [846400], dim = 1 -> tensor<846400xi8>
    scf.execute_region {
      %6 = routing.partitiontensor %3 : tensor<9548xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<9548xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<9548xi8>, i32 -> tensor<4774xi8>
        %10 = dmap.define_io_engine {io_id = 0 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "col", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @receive_port_0 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @receive_port_0}, {1, @receive_port_0}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %13, dst = %14, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %9 : tensor<4774xi8> to %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<9548xi8>, i32 -> tensor<4774xi8>
        %10 = dmap.define_io_engine {io_id = 1 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %11 = dmap.define_core_group {core_count = 2 : i32, group_axis = "col", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %12 = dmap.define_port_configure @receive_port_1 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %13 = dmap.create_io_engin_with_config %10 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %14 = dmap.create_core_group_with_config %11{[{0, @receive_port_1}, {1, @receive_port_1}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %15 = dmap.create_stream src = %13, dst = %14, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %9 : tensor<4774xi8> to %15 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor %1 : tensor<158700xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<158700xi8>
      %7 = routing.partitiontensor %5 : tensor<846400xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<846400xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %10 = routing.routingextract_data %6, %arg3 : tensor<158700xi8>, i32 -> tensor<79350xi8>
        %11 = dmap.define_io_engine {io_id = 2 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %12 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %13 = dmap.define_port_configure @receive_port_2 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %14 = dmap.create_io_engin_with_config %11 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %15 = dmap.create_core_group_with_config %12{[{0, @receive_port_2}, {1, @receive_port_2}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %16 = dmap.create_stream src = %14, dst = %15, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %10 : tensor<79350xi8> to %16 : !dmap.dmapportstream
        %17 = routing.routingextract_data %7, %arg3 : tensor<846400xi8>, i32 -> tensor<423200xi8>
        %18 = dmap.define_io_engine {io_id = 3 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %19 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 0 : i32} -> !dmap.dmacoreenginegroupType
        %20 = dmap.define_port_configure @send_port_3 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %21 = dmap.create_io_engin_with_config %18 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %22 = dmap.create_core_group_with_config %19{[{0, @send_port_3}, {1, @send_port_3}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %23 = dmap.create_stream src = %22, dst = %21, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %17 : tensor<423200xi8> from %23 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %10 = routing.routingextract_data %6, %arg3 : tensor<158700xi8>, i32 -> tensor<79350xi8>
        %11 = dmap.define_io_engine {io_id = 4 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %12 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %13 = dmap.define_port_configure @receive_port_4 : {"RECEIVE", 16, 1, 1} -> !dmap.dmapportconfig
        %14 = dmap.create_io_engin_with_config %11 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"SEND", 16, 1, 1}>} -> !dmap.dmapioconfig
        %15 = dmap.create_core_group_with_config %12{[{0, @receive_port_4}, {1, @receive_port_4}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %16 = dmap.create_stream src = %14, dst = %15, !dmap.dmapioconfig !dmap.dmacoregroupconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.push %10 : tensor<79350xi8> to %16 : !dmap.dmapportstream
        %17 = routing.routingextract_data %7, %arg3 : tensor<846400xi8>, i32 -> tensor<423200xi8>
        %18 = dmap.define_io_engine {io_id = 5 : i32, ioattr = "SHIM"} -> !dmap.dmapioenginetype
        %19 = dmap.define_core_group {core_count = 2 : i32, group_axis = "row", group_idx = 1 : i32} -> !dmap.dmacoreenginegroupType
        %20 = dmap.define_port_configure @send_port_5 : {"SEND", 16, 1, 1} -> !dmap.dmapportconfig
        %21 = dmap.create_io_engin_with_config %18 : !dmap.dmapioenginetype {accesspattern = #dmap<dataaccesspattern{"RECEIVE", 16, 1, 1}>} -> !dmap.dmapioconfig
        %22 = dmap.create_core_group_with_config %19{[{0, @send_port_5}, {1, @send_port_5}], "row"} : !dmap.dmacoreenginegroupType -> !dmap.dmacoregroupconfig
        %23 = dmap.create_stream src = %22, dst = %21, !dmap.dmacoregroupconfig !dmap.dmapioconfig {streamType = #dmap.io<DMAP_SHIMIO>, stream_group_index = 0 : i32, stream_id = 1 : i32} -> !dmap.dmapportstream
        dmap.pull %17 : tensor<423200xi8> from %23 : !dmap.dmapportstream
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
