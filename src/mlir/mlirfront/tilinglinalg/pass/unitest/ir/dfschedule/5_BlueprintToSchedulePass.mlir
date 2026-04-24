module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[0, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1]>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32
        } : (memref<4x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig0 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig1 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig2 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig3 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig0, @kernelconfig1, @kernelconfig2, @kernelconfig3]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[4, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 64>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 64>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig4 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig5 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig6 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig7 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig4, @kernelconfig5, @kernelconfig6, @kernelconfig7]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 64>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[8, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig8 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig9 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig10 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig11 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig8, @kernelconfig9, @kernelconfig10, @kernelconfig11]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 128>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[12, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 192>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 192>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig12 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig13 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig14 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig15 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig12, @kernelconfig13, @kernelconfig14, @kernelconfig15]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 192>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[0, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1]>>
        %4 = dfschedule.declaretile {col = 6 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32
        } : (memref<4x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[0, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig16 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig17 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig18 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig19 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig16, @kernelconfig17, @kernelconfig18, @kernelconfig19]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[4, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 64>>
        %4 = dfschedule.declaretile {col = 6 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 64>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig20 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig21 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig22 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig23 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig20, @kernelconfig21, @kernelconfig22, @kernelconfig23]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 64>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[8, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %4 = dfschedule.declaretile {col = 7 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig24 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig25 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig26 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig27 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig24, @kernelconfig25, @kernelconfig26, @kernelconfig27]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 128>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[12, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 192>>
        %4 = dfschedule.declaretile {col = 7 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 192>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 8 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig28 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig29 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig30 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig31 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig28, @kernelconfig29, @kernelconfig30, @kernelconfig31]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 192>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg2[0, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1]>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c2_i32_0 = arith.constant 2 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c2_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32
        } : (memref<4x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<1x16xi8, strided<[16, 1]>>) -> memref<1x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32 = arith.constant 5 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c5_i32) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 1 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c4_i32, %11) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 1 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1], offset: 16>>
        %16 = dfschedule.memref_mapping %subview_2 : (memref<1x16xi8, strided<[16, 1], offset: 16>>) -> memref<1x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_3 = arith.constant 5 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c5_i32_3) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 2 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_4 = arith.constant 4 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c4_i32_4, %19) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 2 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_5 = memref.subview %subview[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1], offset: 32>>
        %24 = dfschedule.memref_mapping %subview_5 : (memref<1x16xi8, strided<[16, 1], offset: 32>>) -> memref<1x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_6 = arith.constant 5 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c5_i32_6) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 3 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_7 = arith.constant 4 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c4_i32_7, %27) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 3 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_8 = memref.subview %subview[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1], offset: 48>>
        %32 = dfschedule.memref_mapping %subview_8 : (memref<1x16xi8, strided<[16, 1], offset: 48>>) -> memref<1x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_9 = arith.constant 5 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c5_i32_9) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 4 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_10 = arith.constant 4 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c4_i32_10, %35) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 4 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig32 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig33 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig34 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig35 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 4 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig32, @kernelconfig33, @kernelconfig34, @kernelconfig35]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg2[4, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 64>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c3_i32_0 = arith.constant 3 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c3_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 64>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 64>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<1x16xi8, strided<[16, 1], offset: 64>>) -> memref<1x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32 = arith.constant 5 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c5_i32) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 5 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c4_i32, %11) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 5 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 80>>
        %16 = dfschedule.memref_mapping %subview_2 : (memref<1x16xi8, strided<[16, 1], offset: 80>>) -> memref<1x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_3 = arith.constant 5 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c5_i32_3) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 6 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_4 = arith.constant 4 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c4_i32_4, %19) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 6 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_5 = memref.subview %subview[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 96>>
        %24 = dfschedule.memref_mapping %subview_5 : (memref<1x16xi8, strided<[16, 1], offset: 96>>) -> memref<1x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_6 = arith.constant 5 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c5_i32_6) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 7 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_7 = arith.constant 4 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c4_i32_7, %27) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 7 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_8 = memref.subview %subview[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 112>>
        %32 = dfschedule.memref_mapping %subview_8 : (memref<1x16xi8, strided<[16, 1], offset: 112>>) -> memref<1x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_9 = arith.constant 5 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c5_i32_9) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 8 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_10 = arith.constant 4 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c4_i32_10, %35) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 8 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig36 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 5 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig37 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 6 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig38 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 7 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig39 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 8 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig36, @kernelconfig37, @kernelconfig38, @kernelconfig39]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 64>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg2[8, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 128>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c2_i32_0 = arith.constant 2 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c2_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 128>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<1x16xi8, strided<[16, 1], offset: 128>>) -> memref<1x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32 = arith.constant 5 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c5_i32) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c4_i32, %11) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 144>>
        %16 = dfschedule.memref_mapping %subview_2 : (memref<1x16xi8, strided<[16, 1], offset: 144>>) -> memref<1x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_3 = arith.constant 5 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c5_i32_3) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_4 = arith.constant 4 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c4_i32_4, %19) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_5 = memref.subview %subview[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 160>>
        %24 = dfschedule.memref_mapping %subview_5 : (memref<1x16xi8, strided<[16, 1], offset: 160>>) -> memref<1x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_6 = arith.constant 5 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c5_i32_6) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_7 = arith.constant 4 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c4_i32_7, %27) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_8 = memref.subview %subview[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 176>>
        %32 = dfschedule.memref_mapping %subview_8 : (memref<1x16xi8, strided<[16, 1], offset: 176>>) -> memref<1x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_9 = arith.constant 5 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c5_i32_9) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_10 = arith.constant 4 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c4_i32_10, %35) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig40 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 9 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig41 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 10 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig42 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 11 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig43 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 12 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig40, @kernelconfig41, @kernelconfig42, @kernelconfig43]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 128>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg2[12, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 192>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c3_i32_0 = arith.constant 3 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c3_i32_0) {
          offset = 0 : i32,
          len = 16 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32
        } : (memref<4x16xi8, strided<[16, 1], offset: 192>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 192>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<1x16xi8, strided<[16, 1], offset: 192>>) -> memref<1x16xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32 = arith.constant 5 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c5_i32) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 13 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c4_i32, %11) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 13 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 208>>
        %16 = dfschedule.memref_mapping %subview_2 : (memref<1x16xi8, strided<[16, 1], offset: 208>>) -> memref<1x16xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_3 = arith.constant 5 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c5_i32_3) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 14 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_4 = arith.constant 4 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c4_i32_4, %19) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 14 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_5 = memref.subview %subview[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 224>>
        %24 = dfschedule.memref_mapping %subview_5 : (memref<1x16xi8, strided<[16, 1], offset: 224>>) -> memref<1x16xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_6 = arith.constant 5 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c5_i32_6) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 15 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_7 = arith.constant 4 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c4_i32_7, %27) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 15 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_8 = memref.subview %subview[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 240>>
        %32 = dfschedule.memref_mapping %subview_8 : (memref<1x16xi8, strided<[16, 1], offset: 240>>) -> memref<1x16xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
        %c5_i32_9 = arith.constant 5 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c5_i32_9) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 16 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_10 = arith.constant 4 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c4_i32_10, %35) {
          offset = 0 : i32,
          len = 2 : i32,
          enable_packet = true,
          packet_id = 16 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32
        } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND"
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig44 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 13 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig45 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 14 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig46 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 15 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig47 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 8 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 16 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig44, @kernelconfig45, @kernelconfig46, @kernelconfig47]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %44 = dfschedule.schedule.launch_kernel_group(%43) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%13, %14) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%21, %22) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%29, %30) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%37, %38) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %50 = dfschedule.schedule.start_io(%6, %49) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%44, %50) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<4x16xi8, strided<[16, 1], offset: 192>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
