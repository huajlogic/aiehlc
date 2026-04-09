module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    %1 = dfscheblueprint.declare_data %0 : tensor<16x16xi8> -> tensor<16x16xi8>
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
        dfscheblueprint.tile_group @group_src_0{tiles = [[2, 0]]}
        dfscheblueprint.tile_group @group_dst_0{tiles = [[0, 3], [1, 3]]}
        %extracted_slice = tensor.extract_slice %6[0, 0] [8, 16] [1, 1] {tag = "partitionslice0"} : tensor<16x16xi8> to tensor<8x16xi8>
        %9 = dfscheblueprint.data_slice @consumer_slice_0_0 wrap %extracted_slice : tensor<8x16xi8>
        %10 = dfscheblueprint.data_slice @consumer_slice_0_1 wrap %extracted_slice : tensor<8x16xi8>
        dfscheblueprint.flowconfig @flow_src_0 {
          target = @group_src_0,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,type = "shim"
          ,data_id = 0 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_0 {
          target = @group_dst_0,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_0_0, @consumer_slice_0_1]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_0 {
          type = "one_to_many",
          from = @flow_src_0,
          to = @flow_dst_0
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 0 : i32
        }
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_1{tiles = [[2, 0]]}
        dfscheblueprint.tile_group @group_dst_1{tiles = [[0, 4], [1, 4]]}
        %extracted_slice = tensor.extract_slice %6[8, 0] [8, 16] [1, 1] {tag = "partitionslice1"} : tensor<16x16xi8> to tensor<8x16xi8>
        %9 = dfscheblueprint.data_slice @consumer_slice_1_0 wrap %extracted_slice : tensor<8x16xi8>
        %10 = dfscheblueprint.data_slice @consumer_slice_1_1 wrap %extracted_slice : tensor<8x16xi8>
        dfscheblueprint.flowconfig @flow_src_1 {
          target = @group_src_1,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = MM2S>
          ,type = "shim"
          ,data_id = 0 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_1 {
          target = @group_dst_1,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_1_0, @consumer_slice_1_1]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_1 {
          type = "one_to_many",
          from = @flow_src_1,
          to = @flow_dst_1
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 1 : i32
        }
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %2 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    %3 = dfscheblueprint.declare_data %2 : tensor<16x16xi8> -> tensor<16x16xi8>
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
        dfscheblueprint.tile_group @group_src_2{tiles = [[3, 0]]}
        dfscheblueprint.tile_group @group_dst_2{tiles = [[0, 3], [1, 3]]}
        %extracted_slice = tensor.extract_slice %6[0, 0] [8, 16] [1, 1] {tag = "partitionslice0"} : tensor<16x16xi8> to tensor<8x16xi8>
        %9 = dfscheblueprint.data_slice @consumer_slice_2_0 wrap %extracted_slice : tensor<8x16xi8>
        %10 = dfscheblueprint.data_slice @consumer_slice_2_1 wrap %extracted_slice : tensor<8x16xi8>
        dfscheblueprint.flowconfig @flow_src_2 {
          target = @group_src_2,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,type = "shim"
          ,data_id = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_2 {
          target = @group_dst_2,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_2_0, @consumer_slice_2_1]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_2 {
          type = "one_to_many",
          from = @flow_src_2,
          to = @flow_dst_2
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 2 : i32
        }
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_3{tiles = [[3, 0]]}
        dfscheblueprint.tile_group @group_dst_3{tiles = [[0, 4], [1, 4]]}
        %extracted_slice = tensor.extract_slice %6[8, 0] [8, 16] [1, 1] {tag = "partitionslice1"} : tensor<16x16xi8> to tensor<8x16xi8>
        %9 = dfscheblueprint.data_slice @consumer_slice_3_0 wrap %extracted_slice : tensor<8x16xi8>
        %10 = dfscheblueprint.data_slice @consumer_slice_3_1 wrap %extracted_slice : tensor<8x16xi8>
        dfscheblueprint.flowconfig @flow_src_3 {
          target = @group_src_3,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = MM2S>
          ,type = "shim"
          ,data_id = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_3 {
          target = @group_dst_3,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_3_0, @consumer_slice_3_1]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_3 {
          type = "one_to_many",
          from = @flow_src_3,
          to = @flow_dst_3
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 3 : i32
        }
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %4 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    %5 = dfscheblueprint.declare_data %4 : tensor<16x16xi8> -> tensor<16x16xi8>
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
        dfscheblueprint.tile_group @group_src_4{tiles = [[0, 3], [1, 3]]}
        dfscheblueprint.tile_group @group_dst_4{tiles = [[2, 0]]}
        %extracted_slice = tensor.extract_slice %6[0, 0] [8, 16] [1, 1] {tag = "partitionslice0"} : tensor<16x16xi8> to tensor<8x16xi8>
        %extracted_slice_0 = tensor.extract_slice %extracted_slice[0, 0] [4, 16] [1, 1] {tag = "producer0"} : tensor<8x16xi8> to tensor<4x16xi8>
        %extracted_slice_1 = tensor.extract_slice %extracted_slice[4, 0] [4, 16] [1, 1] {tag = "producer1"} : tensor<8x16xi8> to tensor<4x16xi8>
        %9 = dfscheblueprint.data_slice @producer_slice_4_0 wrap %extracted_slice_0 : tensor<4x16xi8>
        %10 = dfscheblueprint.data_slice @producer_slice_4_1 wrap %extracted_slice_1 : tensor<4x16xi8>
        dfscheblueprint.flowconfig @flow_src_4 {
          target = @group_src_4,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,slice_symbols = [@producer_slice_4_0, @producer_slice_4_1]
          ,type = "core"
        }
        dfscheblueprint.flowconfig @flow_dst_4 {
          target = @group_dst_4,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,type = "shim"
          ,data_id = 2 : i32
        }
        dfscheblueprint.flow_transfer @transfer_4 {
          type = "many_to_one",
          from = @flow_src_4,
          to = @flow_dst_4
          ,ordering = "sequential"
          ,base_packet_id = 9 : i32,
          flow_index = 4 : i32
        }
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_5{tiles = [[0, 4], [1, 4]]}
        dfscheblueprint.tile_group @group_dst_5{tiles = [[2, 0]]}
        %extracted_slice = tensor.extract_slice %6[8, 0] [8, 16] [1, 1] {tag = "partitionslice1"} : tensor<16x16xi8> to tensor<8x16xi8>
        %extracted_slice_0 = tensor.extract_slice %extracted_slice[0, 0] [4, 16] [1, 1] {tag = "producer0"} : tensor<8x16xi8> to tensor<4x16xi8>
        %extracted_slice_1 = tensor.extract_slice %extracted_slice[4, 0] [4, 16] [1, 1] {tag = "producer1"} : tensor<8x16xi8> to tensor<4x16xi8>
        %9 = dfscheblueprint.data_slice @producer_slice_5_0 wrap %extracted_slice_0 : tensor<4x16xi8>
        %10 = dfscheblueprint.data_slice @producer_slice_5_1 wrap %extracted_slice_1 : tensor<4x16xi8>
        dfscheblueprint.flowconfig @flow_src_5 {
          target = @group_src_5,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,slice_symbols = [@producer_slice_5_0, @producer_slice_5_1]
          ,type = "core"
        }
        dfscheblueprint.flowconfig @flow_dst_5 {
          target = @group_dst_5,
          view = %extracted_slice : tensor<8x16xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,type = "shim"
          ,data_id = 2 : i32
        }
        dfscheblueprint.flow_transfer @transfer_5 {
          type = "many_to_one",
          from = @flow_src_5,
          to = @flow_dst_5
          ,ordering = "sequential"
          ,base_packet_id = 11 : i32,
          flow_index = 5 : i32
        }
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
