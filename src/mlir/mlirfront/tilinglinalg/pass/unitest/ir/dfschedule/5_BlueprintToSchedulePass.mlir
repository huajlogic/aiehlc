module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[0, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1]>>
        %2 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %3 = dfschedule.config.dma_bd(%subview, %2, %c0_i32_0) {
          offset = 0 : i32,
          len = 32 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32
        } : (memref<8x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %4 = dfschedule.config.create_io(%3, %2) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %5 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<8x16xi8, strided<[16, 1]>>
        %6 = dfschedule.memref_mapping %subview_1 : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c1_i32_2) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c0_i32_3, %9) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<8x16xi8, strided<[16, 1]>>
        %14 = dfschedule.memref_mapping %subview_4 : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c1_i32_5) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c0_i32_6, %17) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declare_kernel_config @kernelconfig0 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %22 = dfschedule.declare_kernel_config @kernelconfig1 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %23 = dfschedule.config.load_kernel_group(%5, %13) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0],
          distributed_args = [@kernelconfig0, @kernelconfig1]
        } : (!dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %24 = dfschedule.schedule.launch_kernel_group(%23) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %25 = dfschedule.schedule.start_io(%11, %12) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %26 = dfschedule.schedule.start_io(%19, %20) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %27 = dfschedule.schedule.getbdid(%2) : (!dfschedule.tile) -> i32
        %28 = dfschedule.schedule.start_io(%4, %27) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%24, %28) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<8x16xi8, strided<[16, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[8, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1], offset: 128>>
        %2 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %3 = dfschedule.config.dma_bd(%subview, %2, %c1_i32_0) {
          offset = 0 : i32,
          len = 32 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32
        } : (memref<8x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %4 = dfschedule.config.create_io(%3, %2) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %5 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
        %6 = dfschedule.memref_mapping %subview_1 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c1_i32_2) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c0_i32_3, %9) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
        %14 = dfschedule.memref_mapping %subview_4 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c1_i32_5) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c0_i32_6, %17) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declare_kernel_config @kernelconfig2 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %22 = dfschedule.declare_kernel_config @kernelconfig3 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %23 = dfschedule.config.load_kernel_group(%5, %13) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0],
          distributed_args = [@kernelconfig2, @kernelconfig3]
        } : (!dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %24 = dfschedule.schedule.launch_kernel_group(%23) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %25 = dfschedule.schedule.start_io(%11, %12) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %26 = dfschedule.schedule.start_io(%19, %20) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %27 = dfschedule.schedule.getbdid(%2) : (!dfschedule.tile) -> i32
        %28 = dfschedule.schedule.start_io(%4, %27) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%24, %28) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<8x16xi8, strided<[16, 1], offset: 128>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[0, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1]>>
        %2 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %3 = dfschedule.config.dma_bd(%subview, %2, %c0_i32_0) {
          offset = 0 : i32,
          len = 32 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32
        } : (memref<8x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %4 = dfschedule.config.create_io(%3, %2) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %5 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<8x16xi8, strided<[16, 1]>>
        %6 = dfschedule.memref_mapping %subview_1 : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c3_i32 = arith.constant 3 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c3_i32) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32 = arith.constant 2 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c2_i32, %9) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[0, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<8x16xi8, strided<[16, 1]>>
        %14 = dfschedule.memref_mapping %subview_2 : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c3_i32_3 = arith.constant 3 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c3_i32_3) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_4 = arith.constant 2 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c2_i32_4, %17) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declare_kernel_config @kernelconfig4 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %22 = dfschedule.declare_kernel_config @kernelconfig5 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %23 = dfschedule.config.load_kernel_group(%5, %13) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0],
          distributed_args = [@kernelconfig4, @kernelconfig5]
        } : (!dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %24 = dfschedule.schedule.launch_kernel_group(%23) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %25 = dfschedule.schedule.start_io(%11, %12) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %26 = dfschedule.schedule.start_io(%19, %20) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %27 = dfschedule.schedule.getbdid(%2) : (!dfschedule.tile) -> i32
        %28 = dfschedule.schedule.start_io(%4, %27) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%24, %28) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<8x16xi8, strided<[16, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[8, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1], offset: 128>>
        %2 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %3 = dfschedule.config.dma_bd(%subview, %2, %c1_i32_0) {
          offset = 0 : i32,
          len = 32 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32
        } : (memref<8x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %4 = dfschedule.config.create_io(%3, %2) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %5 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
        %6 = dfschedule.memref_mapping %subview_1 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c3_i32 = arith.constant 3 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c3_i32) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32 = arith.constant 2 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c2_i32, %9) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
        %14 = dfschedule.memref_mapping %subview_2 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
        %c3_i32_3 = arith.constant 3 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c3_i32_3) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_4 = arith.constant 2 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c2_i32_4, %17) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declare_kernel_config @kernelconfig6 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %22 = dfschedule.declare_kernel_config @kernelconfig7 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %23 = dfschedule.config.load_kernel_group(%5, %13) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0],
          distributed_args = [@kernelconfig6, @kernelconfig7]
        } : (!dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %24 = dfschedule.schedule.launch_kernel_group(%23) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %25 = dfschedule.schedule.start_io(%11, %12) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %26 = dfschedule.schedule.start_io(%19, %20) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %27 = dfschedule.schedule.getbdid(%2) : (!dfschedule.tile) -> i32
        %28 = dfschedule.schedule.start_io(%4, %27) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%24, %28) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<8x16xi8, strided<[16, 1], offset: 128>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg2[0, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1]>>
        %2 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c2_i32 = arith.constant 2 : i32
        %3 = dfschedule.config.dma_bd(%subview, %2, %c2_i32) {
          offset = 0 : i32,
          len = 32 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32
        } : (memref<8x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %4 = dfschedule.config.create_io(%3, %2) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %5 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_0 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %6 = dfschedule.memref_mapping %subview_0 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c5_i32 = arith.constant 5 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c5_i32) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c4_i32, %9) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1], offset: 64>>
        %14 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 64>>) -> memref<4x16xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c5_i32_2 = arith.constant 5 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c5_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_3 = arith.constant 4 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c4_i32_3, %17) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declare_kernel_config @kernelconfig8 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 9 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %22 = dfschedule.declare_kernel_config @kernelconfig9 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 10 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %23 = dfschedule.config.load_kernel_group(%5, %13) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0],
          distributed_args = [@kernelconfig8, @kernelconfig9]
        } : (!dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %24 = dfschedule.schedule.launch_kernel_group(%23) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %25 = dfschedule.schedule.start_io(%11, %12) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %26 = dfschedule.schedule.start_io(%19, %20) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %27 = dfschedule.schedule.getbdid(%2) : (!dfschedule.tile) -> i32
        %28 = dfschedule.schedule.start_io(%4, %27) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%24, %28) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<8x16xi8, strided<[16, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg2[8, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1], offset: 128>>
        %2 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c3_i32 = arith.constant 3 : i32
        %3 = dfschedule.config.dma_bd(%subview, %2, %c3_i32) {
          offset = 0 : i32,
          len = 32 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32
        } : (memref<8x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %4 = dfschedule.config.create_io(%3, %2) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %5 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_0 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %6 = dfschedule.memref_mapping %subview_0 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c5_i32 = arith.constant 5 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c5_i32) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c4_i32, %9) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 192>>
        %14 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 192>>) -> memref<4x16xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c5_i32_2 = arith.constant 5 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c5_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_3 = arith.constant 4 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c4_i32_3, %17) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declare_kernel_config @kernelconfig10 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 11 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %22 = dfschedule.declare_kernel_config @kernelconfig11 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 12 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %23 = dfschedule.config.load_kernel_group(%5, %13) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0],
          distributed_args = [@kernelconfig10, @kernelconfig11]
        } : (!dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %24 = dfschedule.schedule.launch_kernel_group(%23) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %25 = dfschedule.schedule.start_io(%11, %12) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %26 = dfschedule.schedule.start_io(%19, %20) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %27 = dfschedule.schedule.getbdid(%2) : (!dfschedule.tile) -> i32
        %28 = dfschedule.schedule.start_io(%4, %27) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%24, %28) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<8x16xi8, strided<[16, 1], offset: 128>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
