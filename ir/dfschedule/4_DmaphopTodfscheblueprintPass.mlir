module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 1 : i32}} {
  func.func @main(%arg0: memref<256x256xi8>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<256x256xi8>
    %1 = dfscheblueprint.declare_data %0 : tensor<256x256xi8> -> tensor<256x256xi8>
    %2 = bufferization.to_tensor %arg1 : memref<256x256xi8>
    %3 = dfscheblueprint.declare_data %2 : tensor<256x256xi8> -> tensor<256x256xi8>
    %4 = bufferization.to_tensor %arg2 : memref<256x256xi8>
    %5 = dfscheblueprint.declare_data %4 : tensor<256x256xi8> -> tensor<256x256xi8>
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
        dfscheblueprint.tile_group @group_src_12{tiles = [[0, 0]]}
        dfscheblueprint.tile_group @group_dst_12{tiles = [[0, 3], [0, 4], [0, 5], [0, 6]]}
        %extracted_slice = tensor.extract_slice %6[0, 0] [64, 256] [1, 1] {tag = "partitionslice0"} : tensor<256x256xi8> to tensor<64x256xi8>
        %11 = dfscheblueprint.data_slice @consumer_slice_12_0 wrap %extracted_slice : tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_12_1 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_12_2 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_12_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_12 {
          target = @group_src_12,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,type = "shim"
          ,data_id = 0 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_12 {
          target = @group_dst_12,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,slice_symbols = [@consumer_slice_12_0, @consumer_slice_12_1, @consumer_slice_12_2, @consumer_slice_12_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_12 {
          type = "one_to_many",
          from = @flow_src_12,
          to = @flow_dst_12
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 12 : i32
        }
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_13{tiles = [[1, 0]]}
        dfscheblueprint.tile_group @group_dst_13{tiles = [[1, 3], [1, 4], [1, 5], [1, 6]]}
        %extracted_slice = tensor.extract_slice %6[64, 0] [64, 256] [1, 1] {tag = "partitionslice1"} : tensor<256x256xi8> to tensor<64x256xi8>
        %11 = dfscheblueprint.data_slice @consumer_slice_13_0 wrap %extracted_slice : tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_13_1 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_13_2 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_13_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_13 {
          target = @group_src_13,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,type = "shim"
          ,data_id = 0 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_13 {
          target = @group_dst_13,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,slice_symbols = [@consumer_slice_13_0, @consumer_slice_13_1, @consumer_slice_13_2, @consumer_slice_13_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_13 {
          type = "one_to_many",
          from = @flow_src_13,
          to = @flow_dst_13
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 13 : i32
        }
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_14{tiles = [[2, 0]]}
        dfscheblueprint.tile_group @group_dst_14{tiles = [[2, 3], [2, 4], [2, 5], [2, 6]]}
        %extracted_slice = tensor.extract_slice %6[128, 0] [64, 256] [1, 1] {tag = "partitionslice2"} : tensor<256x256xi8> to tensor<64x256xi8>
        %11 = dfscheblueprint.data_slice @consumer_slice_14_0 wrap %extracted_slice : tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_14_1 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_14_2 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_14_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_14 {
          target = @group_src_14,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,type = "shim"
          ,data_id = 0 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_14 {
          target = @group_dst_14,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,slice_symbols = [@consumer_slice_14_0, @consumer_slice_14_1, @consumer_slice_14_2, @consumer_slice_14_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_14 {
          type = "one_to_many",
          from = @flow_src_14,
          to = @flow_dst_14
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 14 : i32
        }
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_15{tiles = [[3, 0]]}
        dfscheblueprint.tile_group @group_dst_15{tiles = [[3, 3], [3, 4], [3, 5], [3, 6]]}
        %extracted_slice = tensor.extract_slice %6[192, 0] [64, 256] [1, 1] {tag = "partitionslice3"} : tensor<256x256xi8> to tensor<64x256xi8>
        %11 = dfscheblueprint.data_slice @consumer_slice_15_0 wrap %extracted_slice : tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_15_1 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_15_2 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_15_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_15 {
          target = @group_src_15,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,type = "shim"
          ,data_id = 0 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_15 {
          target = @group_dst_15,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,slice_symbols = [@consumer_slice_15_0, @consumer_slice_15_1, @consumer_slice_15_2, @consumer_slice_15_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_15 {
          type = "one_to_many",
          from = @flow_src_15,
          to = @flow_dst_15
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 15 : i32
        }
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
        dfscheblueprint.tile_group @group_src_17{tiles = [[0, 3], [1, 3], [2, 3], [3, 3]]}
        dfscheblueprint.tile_group @group_dst_17{tiles = [[3, 0]]}
        dfscheblueprint.tile_group @group_src_16{tiles = [[0, 0]]}
        dfscheblueprint.tile_group @group_dst_16{tiles = [[0, 3], [1, 3], [2, 3], [3, 3]]}
        %extracted_slice = tensor.extract_slice %6[0, 0] [64, 256] [1, 1] {tag = "partitionslice0"} : tensor<256x256xi8> to tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_16_0 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_16_1 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_16_2 wrap %extracted_slice : tensor<64x256xi8>
        %15 = dfscheblueprint.data_slice @consumer_slice_16_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_16 {
          target = @group_src_16,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = MM2S>
          ,type = "shim"
          ,data_id = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_16 {
          target = @group_dst_16,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_16_0, @consumer_slice_16_1, @consumer_slice_16_2, @consumer_slice_16_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_16 {
          type = "one_to_many",
          from = @flow_src_16,
          to = @flow_dst_16
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 16 : i32
        }
        %extracted_slice_0 = tensor.extract_slice %7[0, 0] [64, 256] [1, 1] {tag = "partitionslice0"} : tensor<256x256xi8> to tensor<64x256xi8>
        %extracted_slice_1 = tensor.extract_slice %extracted_slice_0[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %extracted_slice_0[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_3 = tensor.extract_slice %extracted_slice_0[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_4 = tensor.extract_slice %extracted_slice_0[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        %16 = dfscheblueprint.data_slice @producer_slice_17_0 wrap %extracted_slice_1 : tensor<16x256xi8>
        %17 = dfscheblueprint.data_slice @producer_slice_17_1 wrap %extracted_slice_2 : tensor<16x256xi8>
        %18 = dfscheblueprint.data_slice @producer_slice_17_2 wrap %extracted_slice_3 : tensor<16x256xi8>
        %19 = dfscheblueprint.data_slice @producer_slice_17_3 wrap %extracted_slice_4 : tensor<16x256xi8>
        dfscheblueprint.flowconfig @flow_src_17 {
          target = @group_src_17,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,slice_symbols = [@producer_slice_17_0, @producer_slice_17_1, @producer_slice_17_2, @producer_slice_17_3]
          ,type = "core"
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_17 {
          target = @group_dst_17,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,type = "shim"
          ,data_id = 2 : i32
          ,shim_dim_strides = [4 : i32, 256 : i32, 64 : i32]
          ,shim_dim_wraps = [16 : i32, 64 : i32, 4 : i32]
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flow_transfer @transfer_17 {
          type = "many_to_one",
          from = @flow_src_17,
          to = @flow_dst_17
          ,ordering = "sequential"
          ,base_packet_id = 1 : i32,
          flow_index = 17 : i32
        }
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_19{tiles = [[0, 4], [1, 4], [2, 4], [3, 4]]}
        dfscheblueprint.tile_group @group_dst_19{tiles = [[3, 0]]}
        dfscheblueprint.tile_group @group_src_18{tiles = [[1, 0]]}
        dfscheblueprint.tile_group @group_dst_18{tiles = [[0, 4], [1, 4], [2, 4], [3, 4]]}
        %extracted_slice = tensor.extract_slice %6[64, 0] [64, 256] [1, 1] {tag = "partitionslice1"} : tensor<256x256xi8> to tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_18_0 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_18_1 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_18_2 wrap %extracted_slice : tensor<64x256xi8>
        %15 = dfscheblueprint.data_slice @consumer_slice_18_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_18 {
          target = @group_src_18,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = MM2S>
          ,type = "shim"
          ,data_id = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_18 {
          target = @group_dst_18,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_18_0, @consumer_slice_18_1, @consumer_slice_18_2, @consumer_slice_18_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_18 {
          type = "one_to_many",
          from = @flow_src_18,
          to = @flow_dst_18
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 18 : i32
        }
        %extracted_slice_0 = tensor.extract_slice %7[64, 0] [64, 256] [1, 1] {tag = "partitionslice1"} : tensor<256x256xi8> to tensor<64x256xi8>
        %extracted_slice_1 = tensor.extract_slice %extracted_slice_0[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %extracted_slice_0[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_3 = tensor.extract_slice %extracted_slice_0[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_4 = tensor.extract_slice %extracted_slice_0[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        %16 = dfscheblueprint.data_slice @producer_slice_19_0 wrap %extracted_slice_1 : tensor<16x256xi8>
        %17 = dfscheblueprint.data_slice @producer_slice_19_1 wrap %extracted_slice_2 : tensor<16x256xi8>
        %18 = dfscheblueprint.data_slice @producer_slice_19_2 wrap %extracted_slice_3 : tensor<16x256xi8>
        %19 = dfscheblueprint.data_slice @producer_slice_19_3 wrap %extracted_slice_4 : tensor<16x256xi8>
        dfscheblueprint.flowconfig @flow_src_19 {
          target = @group_src_19,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,slice_symbols = [@producer_slice_19_0, @producer_slice_19_1, @producer_slice_19_2, @producer_slice_19_3]
          ,type = "core"
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_19 {
          target = @group_dst_19,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,type = "shim"
          ,data_id = 2 : i32
          ,shim_dim_strides = [4 : i32, 256 : i32, 64 : i32]
          ,shim_dim_wraps = [16 : i32, 64 : i32, 4 : i32]
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flow_transfer @transfer_19 {
          type = "many_to_one",
          from = @flow_src_19,
          to = @flow_dst_19
          ,ordering = "sequential"
          ,base_packet_id = 5 : i32,
          flow_index = 19 : i32
        }
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_21{tiles = [[0, 5], [1, 5], [2, 5], [3, 5]]}
        dfscheblueprint.tile_group @group_dst_21{tiles = [[2, 0]]}
        dfscheblueprint.tile_group @group_src_20{tiles = [[2, 0]]}
        dfscheblueprint.tile_group @group_dst_20{tiles = [[0, 5], [1, 5], [2, 5], [3, 5]]}
        %extracted_slice = tensor.extract_slice %6[128, 0] [64, 256] [1, 1] {tag = "partitionslice2"} : tensor<256x256xi8> to tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_20_0 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_20_1 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_20_2 wrap %extracted_slice : tensor<64x256xi8>
        %15 = dfscheblueprint.data_slice @consumer_slice_20_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_20 {
          target = @group_src_20,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = MM2S>
          ,type = "shim"
          ,data_id = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_20 {
          target = @group_dst_20,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_20_0, @consumer_slice_20_1, @consumer_slice_20_2, @consumer_slice_20_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_20 {
          type = "one_to_many",
          from = @flow_src_20,
          to = @flow_dst_20
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 20 : i32
        }
        %extracted_slice_0 = tensor.extract_slice %7[128, 0] [64, 256] [1, 1] {tag = "partitionslice2"} : tensor<256x256xi8> to tensor<64x256xi8>
        %extracted_slice_1 = tensor.extract_slice %extracted_slice_0[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %extracted_slice_0[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_3 = tensor.extract_slice %extracted_slice_0[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_4 = tensor.extract_slice %extracted_slice_0[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        %16 = dfscheblueprint.data_slice @producer_slice_21_0 wrap %extracted_slice_1 : tensor<16x256xi8>
        %17 = dfscheblueprint.data_slice @producer_slice_21_1 wrap %extracted_slice_2 : tensor<16x256xi8>
        %18 = dfscheblueprint.data_slice @producer_slice_21_2 wrap %extracted_slice_3 : tensor<16x256xi8>
        %19 = dfscheblueprint.data_slice @producer_slice_21_3 wrap %extracted_slice_4 : tensor<16x256xi8>
        dfscheblueprint.flowconfig @flow_src_21 {
          target = @group_src_21,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,slice_symbols = [@producer_slice_21_0, @producer_slice_21_1, @producer_slice_21_2, @producer_slice_21_3]
          ,type = "core"
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_21 {
          target = @group_dst_21,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,type = "shim"
          ,data_id = 2 : i32
          ,shim_dim_strides = [4 : i32, 256 : i32, 64 : i32]
          ,shim_dim_wraps = [16 : i32, 64 : i32, 4 : i32]
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flow_transfer @transfer_21 {
          type = "many_to_one",
          from = @flow_src_21,
          to = @flow_dst_21
          ,ordering = "sequential"
          ,base_packet_id = 9 : i32,
          flow_index = 21 : i32
        }
        "routing.yield"() : () -> ()
      }
      %11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        dfscheblueprint.tile_group @group_src_23{tiles = [[0, 6], [1, 6], [2, 6], [3, 6]]}
        dfscheblueprint.tile_group @group_dst_23{tiles = [[2, 0]]}
        dfscheblueprint.tile_group @group_src_22{tiles = [[3, 0]]}
        dfscheblueprint.tile_group @group_dst_22{tiles = [[0, 6], [1, 6], [2, 6], [3, 6]]}
        %extracted_slice = tensor.extract_slice %6[192, 0] [64, 256] [1, 1] {tag = "partitionslice3"} : tensor<256x256xi8> to tensor<64x256xi8>
        %12 = dfscheblueprint.data_slice @consumer_slice_22_0 wrap %extracted_slice : tensor<64x256xi8>
        %13 = dfscheblueprint.data_slice @consumer_slice_22_1 wrap %extracted_slice : tensor<64x256xi8>
        %14 = dfscheblueprint.data_slice @consumer_slice_22_2 wrap %extracted_slice : tensor<64x256xi8>
        %15 = dfscheblueprint.data_slice @consumer_slice_22_3 wrap %extracted_slice : tensor<64x256xi8>
        dfscheblueprint.flowconfig @flow_src_22 {
          target = @group_src_22,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = MM2S>
          ,type = "shim"
          ,data_id = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_22 {
          target = @group_dst_22,
          view = %extracted_slice : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = S2MM>
          ,slice_symbols = [@consumer_slice_22_0, @consumer_slice_22_1, @consumer_slice_22_2, @consumer_slice_22_3]
          ,type = "core"
        }
        dfscheblueprint.flow_transfer @transfer_22 {
          type = "one_to_many",
          from = @flow_src_22,
          to = @flow_dst_22
          ,ordering = "sequential"
          ,base_packet_id = 0 : i32,
          flow_index = 22 : i32
        }
        %extracted_slice_0 = tensor.extract_slice %7[192, 0] [64, 256] [1, 1] {tag = "partitionslice3"} : tensor<256x256xi8> to tensor<64x256xi8>
        %extracted_slice_1 = tensor.extract_slice %extracted_slice_0[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %extracted_slice_0[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_3 = tensor.extract_slice %extracted_slice_0[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_4 = tensor.extract_slice %extracted_slice_0[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        %16 = dfscheblueprint.data_slice @producer_slice_23_0 wrap %extracted_slice_1 : tensor<16x256xi8>
        %17 = dfscheblueprint.data_slice @producer_slice_23_1 wrap %extracted_slice_2 : tensor<16x256xi8>
        %18 = dfscheblueprint.data_slice @producer_slice_23_2 wrap %extracted_slice_3 : tensor<16x256xi8>
        %19 = dfscheblueprint.data_slice @producer_slice_23_3 wrap %extracted_slice_4 : tensor<16x256xi8>
        dfscheblueprint.flowconfig @flow_src_23 {
          target = @group_src_23,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "linear",
          dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>
          ,slice_symbols = [@producer_slice_23_0, @producer_slice_23_1, @producer_slice_23_2, @producer_slice_23_3]
          ,type = "core"
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flowconfig @flow_dst_23 {
          target = @group_dst_23,
          view = %extracted_slice_0 : tensor<64x256xi8>,
          distribution = "root",
          dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>
          ,type = "shim"
          ,data_id = 2 : i32
          ,shim_dim_strides = [4 : i32, 256 : i32, 64 : i32]
          ,shim_dim_wraps = [16 : i32, 64 : i32, 4 : i32]
          ,pp_depth = 1 : i32
        }
        dfscheblueprint.flow_transfer @transfer_23 {
          type = "many_to_one",
          from = @flow_src_23,
          to = @flow_dst_23
          ,ordering = "sequential"
          ,base_packet_id = 13 : i32,
          flow_index = 23 : i32
        }
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
