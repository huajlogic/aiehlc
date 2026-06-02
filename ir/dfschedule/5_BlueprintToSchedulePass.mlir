module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.effective_k = 16 : i64, routing.full_k = 64 : i64, routing.k_rounds = 4 : i64, routing.m_rounds = 4 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}, routing.tile_m = 4 : i64, routing.tile_rows = 16 : i64} {
  func.func @main(%arg0: memref<64x64xi8>, %arg1: memref<64x64xi8>, %arg2: memref<64x64xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[0, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1]>>
        %4 = dfschedule.declaretile {col = 0 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_3 = arith.constant 1 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c1_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_5 = arith.constant 0 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c0_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c1_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_10 = arith.constant 0 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c0_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_13 = arith.constant 1 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c1_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_15 = arith.constant 0 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c0_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_18 = arith.constant 1 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c1_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_20 = arith.constant 0 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c0_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig0 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig1 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig2 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig3 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig0, @kernelconfig1, @kernelconfig2, @kernelconfig3]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %48 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %49 = arith.muli %48, %c256_i32 : i32
          %50 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0, %49) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 0 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %51 = dfschedule.config.create_io(%50, %4) {
            channel = 0,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %52 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %53 = dfschedule.schedule.start_io(%51, %52) {flow_index = 0 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%53) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[16, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %4 = dfschedule.declaretile {col = 1 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_3 = arith.constant 1 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c1_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_5 = arith.constant 0 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c0_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c1_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_10 = arith.constant 0 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c0_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_13 = arith.constant 1 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c1_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_15 = arith.constant 0 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c0_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_18 = arith.constant 1 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c1_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_20 = arith.constant 0 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c0_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig4 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig5 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig6 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig7 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig4, @kernelconfig5, @kernelconfig6, @kernelconfig7]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %48 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %49 = arith.muli %48, %c256_i32 : i32
          %50 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0, %49) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 0 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %51 = dfschedule.config.create_io(%50, %4) {
            channel = 0,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %52 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %53 = dfschedule.schedule.start_io(%51, %52) {flow_index = 1 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%53) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 1024>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[32, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_3 = arith.constant 1 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c1_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_5 = arith.constant 0 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c0_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c1_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_10 = arith.constant 0 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c0_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_13 = arith.constant 1 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c1_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_15 = arith.constant 0 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c0_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_18 = arith.constant 1 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c1_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_20 = arith.constant 0 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c0_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig8 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig9 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig10 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig11 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig8, @kernelconfig9, @kernelconfig10, @kernelconfig11]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %48 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %49 = arith.muli %48, %c256_i32 : i32
          %50 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0, %49) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 0 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %51 = dfschedule.config.create_io(%50, %4) {
            channel = 0,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %52 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %53 = dfschedule.schedule.start_io(%51, %52) {flow_index = 2 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%53) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 2048>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[48, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_3 = arith.constant 1 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c1_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_5 = arith.constant 0 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c0_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c1_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_10 = arith.constant 0 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c0_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_13 = arith.constant 1 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c1_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_15 = arith.constant 0 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c0_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_18 = arith.constant 1 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c1_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c0_i32_20 = arith.constant 0 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c0_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig12 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig13 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig14 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig15 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig12, @kernelconfig13, @kernelconfig14, @kernelconfig15]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %48 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %49 = arith.muli %48, %c256_i32 : i32
          %50 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0, %49) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 0 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %51 = dfschedule.config.create_io(%50, %4) {
            channel = 0,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %52 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %53 = dfschedule.schedule.start_io(%51, %52) {flow_index = 3 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%53) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 3072>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[0, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1]>>
        %4 = dfschedule.declaretile {col = 0 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_3 = arith.constant 3 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c3_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_5 = arith.constant 2 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c2_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c3_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_10 = arith.constant 2 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c2_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_13 = arith.constant 3 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c3_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_15 = arith.constant 2 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c2_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_18 = arith.constant 3 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c3_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_20 = arith.constant 2 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c2_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig16 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig17 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig18 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig19 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig16, @kernelconfig17, @kernelconfig18, @kernelconfig19]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %98 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %99 = arith.muli %98, %c256_i32 : i32
          %100 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0, %99) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 1 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %101 = dfschedule.config.create_io(%100, %4) {
            channel = 1,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %102 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %103 = dfschedule.schedule.start_io(%101, %102) {flow_index = 4 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%103) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1]>>
        %subview_22 = memref.subview %arg2[0, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1]>>
        %48 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_23 = arith.constant 1 : i32
        %c5_i32 = arith.constant 5 : i32
        %c48_i32 = arith.constant 48 : i32
        %49 = dfschedule.config.dma_bd(%subview_22, %48, %c5_i32, %c48_i32) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 4 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %c32_i32 = arith.constant 32 : i32
        %50 = dfschedule.config.dma_bd(%subview_22, %48, %c4_i32, %c32_i32, %49) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 3 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c3_i32_24 = arith.constant 3 : i32
        %c16_i32 = arith.constant 16 : i32
        %51 = dfschedule.config.dma_bd(%subview_22, %48, %c3_i32_24, %c16_i32, %50) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 2 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c2_i32_25 = arith.constant 2 : i32
        %c0_i32_26 = arith.constant 0 : i32
        %52 = dfschedule.config.dma_bd(%subview_22, %48, %c2_i32_25, %c0_i32_26, %51) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 1 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %53 = dfschedule.config.create_io(%52, %48) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %54 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_27 = memref.subview %subview_22[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1]>>
        %55 = dfschedule.memref_mapping %subview_27 : (memref<4x64xi8, strided<[64, 1]>>) -> memref<4x64xi8>
        %56 = dfschedule.bind_core_buffer(%55, %54) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %57 = dfschedule.bind_core_buffer(%55, %54) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_28 = arith.constant 5 : i32
        %c0_i32_29 = arith.constant 0 : i32
        %58 = dfschedule.config.dma_bd(%57, %54, %c5_i32_28, %c0_i32_29) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 1 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 2 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_30 = arith.constant 4 : i32
        %c0_i32_31 = arith.constant 0 : i32
        %59 = dfschedule.config.dma_bd(%56, %54, %c4_i32_30, %c0_i32_31, %58) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 1 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 2 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %60 = dfschedule.config.create_io(%59, %54) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %61 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
        %62 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_32 = memref.subview %subview_22[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1], offset: 256>>
        %63 = dfschedule.memref_mapping %subview_32 : (memref<4x64xi8, strided<[64, 1], offset: 256>>) -> memref<4x64xi8>
        %64 = dfschedule.bind_core_buffer(%63, %62) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %65 = dfschedule.bind_core_buffer(%63, %62) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_33 = arith.constant 5 : i32
        %c0_i32_34 = arith.constant 0 : i32
        %66 = dfschedule.config.dma_bd(%65, %62, %c5_i32_33, %c0_i32_34) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 2 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_35 = arith.constant 4 : i32
        %c0_i32_36 = arith.constant 0 : i32
        %67 = dfschedule.config.dma_bd(%64, %62, %c4_i32_35, %c0_i32_36, %66) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 2 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %68 = dfschedule.config.create_io(%67, %62) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %69 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
        %70 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_37 = memref.subview %subview_22[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1], offset: 512>>
        %71 = dfschedule.memref_mapping %subview_37 : (memref<4x64xi8, strided<[64, 1], offset: 512>>) -> memref<4x64xi8>
        %72 = dfschedule.bind_core_buffer(%71, %70) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %73 = dfschedule.bind_core_buffer(%71, %70) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_38 = arith.constant 5 : i32
        %c0_i32_39 = arith.constant 0 : i32
        %74 = dfschedule.config.dma_bd(%73, %70, %c5_i32_38, %c0_i32_39) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 3 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_40 = arith.constant 4 : i32
        %c0_i32_41 = arith.constant 0 : i32
        %75 = dfschedule.config.dma_bd(%72, %70, %c4_i32_40, %c0_i32_41, %74) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 3 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %76 = dfschedule.config.create_io(%75, %70) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %77 = dfschedule.schedule.getbdid(%70) : (!dfschedule.tile) -> i32
        %78 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_42 = memref.subview %subview_22[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1], offset: 768>>
        %79 = dfschedule.memref_mapping %subview_42 : (memref<4x64xi8, strided<[64, 1], offset: 768>>) -> memref<4x64xi8>
        %80 = dfschedule.bind_core_buffer(%79, %78) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %81 = dfschedule.bind_core_buffer(%79, %78) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_43 = arith.constant 5 : i32
        %c0_i32_44 = arith.constant 0 : i32
        %82 = dfschedule.config.dma_bd(%81, %78, %c5_i32_43, %c0_i32_44) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 4 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_45 = arith.constant 4 : i32
        %c0_i32_46 = arith.constant 0 : i32
        %83 = dfschedule.config.dma_bd(%80, %78, %c4_i32_45, %c0_i32_46, %82) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 4 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %84 = dfschedule.config.create_io(%83, %78) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %85 = dfschedule.schedule.getbdid(%78) : (!dfschedule.tile) -> i32
        %86 = dfschedule.declare_kernel_config @kernelconfig20 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 1 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %87 = dfschedule.declare_kernel_config @kernelconfig21 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 2 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %88 = dfschedule.declare_kernel_config @kernelconfig22 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 3 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %89 = dfschedule.declare_kernel_config @kernelconfig23 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 4 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %90 = dfschedule.schedule.getbdid(%48) : (!dfschedule.tile) -> i32
        %91 = dfschedule.schedule.start_io(%53, %90) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %92 = dfschedule.config.load_kernel_group(%54, %62, %70, %78) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig20, @kernelconfig21, @kernelconfig22, @kernelconfig23]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %93 = dfschedule.schedule.launch_kernel_group(%92) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %94 = dfschedule.schedule.start_io(%60, %61) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.schedule.start_io(%68, %69) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %96 = dfschedule.schedule.start_io(%76, %77) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%84, %85) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%93, %91) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_22 : memref<16x64xi8, strided<[64, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[16, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %4 = dfschedule.declaretile {col = 1 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_3 = arith.constant 3 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c3_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_5 = arith.constant 2 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c2_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c3_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_10 = arith.constant 2 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c2_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_13 = arith.constant 3 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c3_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_15 = arith.constant 2 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c2_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_18 = arith.constant 3 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c3_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_20 = arith.constant 2 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c2_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig24 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig25 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig26 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig27 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig24, @kernelconfig25, @kernelconfig26, @kernelconfig27]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %98 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %99 = arith.muli %98, %c256_i32 : i32
          %100 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0, %99) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 1 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %101 = dfschedule.config.create_io(%100, %4) {
            channel = 1,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %102 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %103 = dfschedule.schedule.start_io(%101, %102) {flow_index = 6 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%103) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %subview_22 = memref.subview %arg2[16, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %48 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c6_i32 = arith.constant 6 : i32
        %c10_i32 = arith.constant 10 : i32
        %c48_i32 = arith.constant 48 : i32
        %49 = dfschedule.config.dma_bd(%subview_22, %48, %c10_i32, %c48_i32) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 8 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c9_i32 = arith.constant 9 : i32
        %c32_i32 = arith.constant 32 : i32
        %50 = dfschedule.config.dma_bd(%subview_22, %48, %c9_i32, %c32_i32, %49) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 7 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c8_i32 = arith.constant 8 : i32
        %c16_i32 = arith.constant 16 : i32
        %51 = dfschedule.config.dma_bd(%subview_22, %48, %c8_i32, %c16_i32, %50) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 6 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c7_i32 = arith.constant 7 : i32
        %c0_i32_23 = arith.constant 0 : i32
        %52 = dfschedule.config.dma_bd(%subview_22, %48, %c7_i32, %c0_i32_23, %51) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 5 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %53 = dfschedule.config.create_io(%52, %48) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %54 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_24 = memref.subview %subview_22[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1024>>
        %55 = dfschedule.memref_mapping %subview_24 : (memref<4x64xi8, strided<[64, 1], offset: 1024>>) -> memref<4x64xi8>
        %56 = dfschedule.bind_core_buffer(%55, %54) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %57 = dfschedule.bind_core_buffer(%55, %54) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32 = arith.constant 5 : i32
        %c0_i32_25 = arith.constant 0 : i32
        %58 = dfschedule.config.dma_bd(%57, %54, %c5_i32, %c0_i32_25) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 5 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 7 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %c0_i32_26 = arith.constant 0 : i32
        %59 = dfschedule.config.dma_bd(%56, %54, %c4_i32, %c0_i32_26, %58) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 5 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 7 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %60 = dfschedule.config.create_io(%59, %54) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %61 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
        %62 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_27 = memref.subview %subview_22[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1280>>
        %63 = dfschedule.memref_mapping %subview_27 : (memref<4x64xi8, strided<[64, 1], offset: 1280>>) -> memref<4x64xi8>
        %64 = dfschedule.bind_core_buffer(%63, %62) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %65 = dfschedule.bind_core_buffer(%63, %62) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_28 = arith.constant 5 : i32
        %c0_i32_29 = arith.constant 0 : i32
        %66 = dfschedule.config.dma_bd(%65, %62, %c5_i32_28, %c0_i32_29) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 6 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_30 = arith.constant 4 : i32
        %c0_i32_31 = arith.constant 0 : i32
        %67 = dfschedule.config.dma_bd(%64, %62, %c4_i32_30, %c0_i32_31, %66) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 6 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %68 = dfschedule.config.create_io(%67, %62) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %69 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
        %70 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_32 = memref.subview %subview_22[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1536>>
        %71 = dfschedule.memref_mapping %subview_32 : (memref<4x64xi8, strided<[64, 1], offset: 1536>>) -> memref<4x64xi8>
        %72 = dfschedule.bind_core_buffer(%71, %70) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %73 = dfschedule.bind_core_buffer(%71, %70) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_33 = arith.constant 5 : i32
        %c0_i32_34 = arith.constant 0 : i32
        %74 = dfschedule.config.dma_bd(%73, %70, %c5_i32_33, %c0_i32_34) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 7 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_35 = arith.constant 4 : i32
        %c0_i32_36 = arith.constant 0 : i32
        %75 = dfschedule.config.dma_bd(%72, %70, %c4_i32_35, %c0_i32_36, %74) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 7 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %76 = dfschedule.config.create_io(%75, %70) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %77 = dfschedule.schedule.getbdid(%70) : (!dfschedule.tile) -> i32
        %78 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_37 = memref.subview %subview_22[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1792>>
        %79 = dfschedule.memref_mapping %subview_37 : (memref<4x64xi8, strided<[64, 1], offset: 1792>>) -> memref<4x64xi8>
        %80 = dfschedule.bind_core_buffer(%79, %78) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %81 = dfschedule.bind_core_buffer(%79, %78) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_38 = arith.constant 5 : i32
        %c0_i32_39 = arith.constant 0 : i32
        %82 = dfschedule.config.dma_bd(%81, %78, %c5_i32_38, %c0_i32_39) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 8 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_40 = arith.constant 4 : i32
        %c0_i32_41 = arith.constant 0 : i32
        %83 = dfschedule.config.dma_bd(%80, %78, %c4_i32_40, %c0_i32_41, %82) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 8 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %84 = dfschedule.config.create_io(%83, %78) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %85 = dfschedule.schedule.getbdid(%78) : (!dfschedule.tile) -> i32
        %86 = dfschedule.declare_kernel_config @kernelconfig28 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 5 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %87 = dfschedule.declare_kernel_config @kernelconfig29 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 6 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %88 = dfschedule.declare_kernel_config @kernelconfig30 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 7 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %89 = dfschedule.declare_kernel_config @kernelconfig31 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 8 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %90 = dfschedule.schedule.getbdid(%48) : (!dfschedule.tile) -> i32
        %91 = dfschedule.schedule.start_io(%53, %90) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %92 = dfschedule.config.load_kernel_group(%54, %62, %70, %78) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig28, @kernelconfig29, @kernelconfig30, @kernelconfig31]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %93 = dfschedule.schedule.launch_kernel_group(%92) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %94 = dfschedule.schedule.start_io(%60, %61) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.schedule.start_io(%68, %69) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %96 = dfschedule.schedule.start_io(%76, %77) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%84, %85) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%93, %91) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_22 : memref<16x64xi8, strided<[64, 1], offset: 1024>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[32, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %c0_i32_1 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_2 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %6 = dfschedule.memref_mapping %subview_2 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_3 = arith.constant 3 : i32
        %c0_i32_4 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c3_i32_3, %c0_i32_4) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_5 = arith.constant 2 : i32
        %c0_i32_6 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c2_i32_5, %c0_i32_6, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %14 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %c0_i32_9 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c3_i32_8, %c0_i32_9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_10 = arith.constant 2 : i32
        %c0_i32_11 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c2_i32_10, %c0_i32_11, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_12 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %22 = dfschedule.memref_mapping %subview_12 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_13 = arith.constant 3 : i32
        %c0_i32_14 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c3_i32_13, %c0_i32_14) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_15 = arith.constant 2 : i32
        %c0_i32_16 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c2_i32_15, %c0_i32_16, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %30 = dfschedule.memref_mapping %subview_17 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_18 = arith.constant 3 : i32
        %c0_i32_19 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c3_i32_18, %c0_i32_19) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_20 = arith.constant 2 : i32
        %c0_i32_21 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c2_i32_20, %c0_i32_21, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig32 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig33 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig34 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig35 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig32, @kernelconfig33, @kernelconfig34, @kernelconfig35]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %98 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %99 = arith.muli %98, %c256_i32 : i32
          %100 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0, %99) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 1 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %101 = dfschedule.config.create_io(%100, %4) {
            channel = 1,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %102 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %103 = dfschedule.schedule.start_io(%101, %102) {flow_index = 8 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%103) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %subview_22 = memref.subview %arg2[32, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %48 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c2_i32_23 = arith.constant 2 : i32
        %c6_i32 = arith.constant 6 : i32
        %c48_i32 = arith.constant 48 : i32
        %49 = dfschedule.config.dma_bd(%subview_22, %48, %c6_i32, %c48_i32) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 12 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c5_i32 = arith.constant 5 : i32
        %c32_i32 = arith.constant 32 : i32
        %50 = dfschedule.config.dma_bd(%subview_22, %48, %c5_i32, %c32_i32, %49) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 11 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %c16_i32 = arith.constant 16 : i32
        %51 = dfschedule.config.dma_bd(%subview_22, %48, %c4_i32, %c16_i32, %50) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 10 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c3_i32_24 = arith.constant 3 : i32
        %c0_i32_25 = arith.constant 0 : i32
        %52 = dfschedule.config.dma_bd(%subview_22, %48, %c3_i32_24, %c0_i32_25, %51) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 9 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %53 = dfschedule.config.create_io(%52, %48) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %54 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_26 = memref.subview %subview_22[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2048>>
        %55 = dfschedule.memref_mapping %subview_26 : (memref<4x64xi8, strided<[64, 1], offset: 2048>>) -> memref<4x64xi8>
        %56 = dfschedule.bind_core_buffer(%55, %54) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %57 = dfschedule.bind_core_buffer(%55, %54) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_27 = arith.constant 5 : i32
        %c0_i32_28 = arith.constant 0 : i32
        %58 = dfschedule.config.dma_bd(%57, %54, %c5_i32_27, %c0_i32_28) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_29 = arith.constant 4 : i32
        %c0_i32_30 = arith.constant 0 : i32
        %59 = dfschedule.config.dma_bd(%56, %54, %c4_i32_29, %c0_i32_30, %58) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %60 = dfschedule.config.create_io(%59, %54) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %61 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
        %62 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_31 = memref.subview %subview_22[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2304>>
        %63 = dfschedule.memref_mapping %subview_31 : (memref<4x64xi8, strided<[64, 1], offset: 2304>>) -> memref<4x64xi8>
        %64 = dfschedule.bind_core_buffer(%63, %62) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %65 = dfschedule.bind_core_buffer(%63, %62) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_32 = arith.constant 5 : i32
        %c0_i32_33 = arith.constant 0 : i32
        %66 = dfschedule.config.dma_bd(%65, %62, %c5_i32_32, %c0_i32_33) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_34 = arith.constant 4 : i32
        %c0_i32_35 = arith.constant 0 : i32
        %67 = dfschedule.config.dma_bd(%64, %62, %c4_i32_34, %c0_i32_35, %66) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %68 = dfschedule.config.create_io(%67, %62) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %69 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
        %70 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_36 = memref.subview %subview_22[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2560>>
        %71 = dfschedule.memref_mapping %subview_36 : (memref<4x64xi8, strided<[64, 1], offset: 2560>>) -> memref<4x64xi8>
        %72 = dfschedule.bind_core_buffer(%71, %70) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %73 = dfschedule.bind_core_buffer(%71, %70) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_37 = arith.constant 5 : i32
        %c0_i32_38 = arith.constant 0 : i32
        %74 = dfschedule.config.dma_bd(%73, %70, %c5_i32_37, %c0_i32_38) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_39 = arith.constant 4 : i32
        %c0_i32_40 = arith.constant 0 : i32
        %75 = dfschedule.config.dma_bd(%72, %70, %c4_i32_39, %c0_i32_40, %74) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %76 = dfschedule.config.create_io(%75, %70) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %77 = dfschedule.schedule.getbdid(%70) : (!dfschedule.tile) -> i32
        %78 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_41 = memref.subview %subview_22[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2816>>
        %79 = dfschedule.memref_mapping %subview_41 : (memref<4x64xi8, strided<[64, 1], offset: 2816>>) -> memref<4x64xi8>
        %80 = dfschedule.bind_core_buffer(%79, %78) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %81 = dfschedule.bind_core_buffer(%79, %78) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_42 = arith.constant 5 : i32
        %c0_i32_43 = arith.constant 0 : i32
        %82 = dfschedule.config.dma_bd(%81, %78, %c5_i32_42, %c0_i32_43) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 6 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_44 = arith.constant 4 : i32
        %c0_i32_45 = arith.constant 0 : i32
        %83 = dfschedule.config.dma_bd(%80, %78, %c4_i32_44, %c0_i32_45, %82) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 6 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %84 = dfschedule.config.create_io(%83, %78) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %85 = dfschedule.schedule.getbdid(%78) : (!dfschedule.tile) -> i32
        %86 = dfschedule.declare_kernel_config @kernelconfig36 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 9 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %87 = dfschedule.declare_kernel_config @kernelconfig37 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 10 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %88 = dfschedule.declare_kernel_config @kernelconfig38 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 11 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %89 = dfschedule.declare_kernel_config @kernelconfig39 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 12 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %90 = dfschedule.schedule.getbdid(%48) : (!dfschedule.tile) -> i32
        %91 = dfschedule.schedule.start_io(%53, %90) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %92 = dfschedule.config.load_kernel_group(%54, %62, %70, %78) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig36, @kernelconfig37, @kernelconfig38, @kernelconfig39]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %93 = dfschedule.schedule.launch_kernel_group(%92) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %94 = dfschedule.schedule.start_io(%60, %61) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.schedule.start_io(%68, %69) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %96 = dfschedule.schedule.start_io(%76, %77) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%84, %85) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%93, %91) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_22 : memref<16x64xi8, strided<[64, 1], offset: 2048>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[48, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c11_i32 = arith.constant 11 : i32
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %6 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %7 = dfschedule.bind_core_buffer(%6, %5) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %8 = dfschedule.bind_core_buffer(%6, %5) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %c0_i32_3 = arith.constant 0 : i32
        %9 = dfschedule.config.dma_bd(%8, %5, %c3_i32_2, %c0_i32_3) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_4 = arith.constant 2 : i32
        %c0_i32_5 = arith.constant 0 : i32
        %10 = dfschedule.config.dma_bd(%7, %5, %c2_i32_4, %c0_i32_5, %9) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %11 = dfschedule.config.create_io(%10, %5) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %12 = dfschedule.schedule.getbdid(%5) : (!dfschedule.tile) -> i32
        %13 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_6 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %14 = dfschedule.memref_mapping %subview_6 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %15 = dfschedule.bind_core_buffer(%14, %13) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %16 = dfschedule.bind_core_buffer(%14, %13) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_7 = arith.constant 3 : i32
        %c0_i32_8 = arith.constant 0 : i32
        %17 = dfschedule.config.dma_bd(%16, %13, %c3_i32_7, %c0_i32_8) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %c0_i32_10 = arith.constant 0 : i32
        %18 = dfschedule.config.dma_bd(%15, %13, %c2_i32_9, %c0_i32_10, %17) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %19 = dfschedule.config.create_io(%18, %13) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %20 = dfschedule.schedule.getbdid(%13) : (!dfschedule.tile) -> i32
        %21 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_11 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %22 = dfschedule.memref_mapping %subview_11 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %23 = dfschedule.bind_core_buffer(%22, %21) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %24 = dfschedule.bind_core_buffer(%22, %21) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_12 = arith.constant 3 : i32
        %c0_i32_13 = arith.constant 0 : i32
        %25 = dfschedule.config.dma_bd(%24, %21, %c3_i32_12, %c0_i32_13) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_14 = arith.constant 2 : i32
        %c0_i32_15 = arith.constant 0 : i32
        %26 = dfschedule.config.dma_bd(%23, %21, %c2_i32_14, %c0_i32_15, %25) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %27 = dfschedule.config.create_io(%26, %21) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %28 = dfschedule.schedule.getbdid(%21) : (!dfschedule.tile) -> i32
        %29 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_16 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %30 = dfschedule.memref_mapping %subview_16 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %31 = dfschedule.bind_core_buffer(%30, %29) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %32 = dfschedule.bind_core_buffer(%30, %29) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_17 = arith.constant 3 : i32
        %c0_i32_18 = arith.constant 0 : i32
        %33 = dfschedule.config.dma_bd(%32, %29, %c3_i32_17, %c0_i32_18) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c2_i32_19 = arith.constant 2 : i32
        %c0_i32_20 = arith.constant 0 : i32
        %34 = dfschedule.config.dma_bd(%31, %29, %c2_i32_19, %c0_i32_20, %33) {
          len = 64 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<16x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %35 = dfschedule.config.create_io(%34, %29) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %36 = dfschedule.schedule.getbdid(%29) : (!dfschedule.tile) -> i32
        %37 = dfschedule.declare_kernel_config @kernelconfig40 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %38 = dfschedule.declare_kernel_config @kernelconfig41 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %39 = dfschedule.declare_kernel_config @kernelconfig42 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig43 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %41 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %42 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig40, @kernelconfig41, @kernelconfig42, @kernelconfig43]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %43 = dfschedule.schedule.launch_kernel_group(%42) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %44 = dfschedule.schedule.start_io(%11, %12) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.schedule.start_io(%19, %20) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %46 = dfschedule.schedule.start_io(%27, %28) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%35, %36) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %c0 = arith.constant 0 : index
        %c4 = arith.constant 4 : index
        %c1 = arith.constant 1 : index
        scf.for %arg4 = %c0 to %c4 step %c1 {
          %98 = arith.index_cast %arg4 : index to i32
          %c256_i32 = arith.constant 256 : i32
          %99 = arith.muli %98, %c256_i32 : i32
          %100 = dfschedule.config.dma_bd(%subview, %4, %c11_i32, %99) {
            len = 256 : i32,
            enable_packet = false,
            packet_id = 0 : i32,
            next_bd = 4294967295 : i32,
            acquire_lock_id = 0 : i32,
            acquire_lock_val = 0 : i32,
            release_lock_id = 0 : i32,
            release_lock_val = 0 : i32,
            data_id = 1 : i32,
            out_of_order_bd_id = -1 : i32,
            dim_strides = [4, 64, 16],
            dim_wraps = [4, 4, 4],
            iter_step_size = 16 : i32,
            iter_wrap = 4 : i32
          } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
          %101 = dfschedule.config.create_io(%100, %4) {
            channel = 1,
            direction = "MM2S",
            io_operation = "SEND",
            enable_out_of_order = false
          } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
          %102 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
          %103 = dfschedule.schedule.start_io(%101, %102) {flow_index = 10 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
          dfschedule.schedule.wait(%103) : (!dfschedule.event)
        }
        dfschedule.schedule.wait(%43) : (!dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %subview_21 = memref.subview %arg2[48, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %48 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c7_i32 = arith.constant 7 : i32
        %c11_i32_22 = arith.constant 11 : i32
        %c48_i32 = arith.constant 48 : i32
        %49 = dfschedule.config.dma_bd(%subview_21, %48, %c11_i32_22, %c48_i32) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 16 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c10_i32 = arith.constant 10 : i32
        %c32_i32 = arith.constant 32 : i32
        %50 = dfschedule.config.dma_bd(%subview_21, %48, %c10_i32, %c32_i32, %49) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 15 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c9_i32 = arith.constant 9 : i32
        %c16_i32 = arith.constant 16 : i32
        %51 = dfschedule.config.dma_bd(%subview_21, %48, %c9_i32, %c16_i32, %50) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 14 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c8_i32 = arith.constant 8 : i32
        %c0_i32_23 = arith.constant 0 : i32
        %52 = dfschedule.config.dma_bd(%subview_21, %48, %c8_i32, %c0_i32_23, %51) {
          len = 256 : i32,
          enable_packet = false,
          packet_id = 13 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 64, 260],
          dim_wraps = [1, 4, 4],
          iter_step_size = 0 : i32,
          iter_wrap = 1 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %53 = dfschedule.config.create_io(%52, %48) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %54 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_24 = memref.subview %subview_21[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3072>>
        %55 = dfschedule.memref_mapping %subview_24 : (memref<4x64xi8, strided<[64, 1], offset: 3072>>) -> memref<4x64xi8>
        %56 = dfschedule.bind_core_buffer(%55, %54) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %57 = dfschedule.bind_core_buffer(%55, %54) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32 = arith.constant 5 : i32
        %c0_i32_25 = arith.constant 0 : i32
        %58 = dfschedule.config.dma_bd(%57, %54, %c5_i32, %c0_i32_25) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 13 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %c0_i32_26 = arith.constant 0 : i32
        %59 = dfschedule.config.dma_bd(%56, %54, %c4_i32, %c0_i32_26, %58) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 13 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %60 = dfschedule.config.create_io(%59, %54) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %61 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
        %62 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_27 = memref.subview %subview_21[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3328>>
        %63 = dfschedule.memref_mapping %subview_27 : (memref<4x64xi8, strided<[64, 1], offset: 3328>>) -> memref<4x64xi8>
        %64 = dfschedule.bind_core_buffer(%63, %62) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %65 = dfschedule.bind_core_buffer(%63, %62) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_28 = arith.constant 5 : i32
        %c0_i32_29 = arith.constant 0 : i32
        %66 = dfschedule.config.dma_bd(%65, %62, %c5_i32_28, %c0_i32_29) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 14 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_30 = arith.constant 4 : i32
        %c0_i32_31 = arith.constant 0 : i32
        %67 = dfschedule.config.dma_bd(%64, %62, %c4_i32_30, %c0_i32_31, %66) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 14 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %68 = dfschedule.config.create_io(%67, %62) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %69 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
        %70 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_32 = memref.subview %subview_21[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3584>>
        %71 = dfschedule.memref_mapping %subview_32 : (memref<4x64xi8, strided<[64, 1], offset: 3584>>) -> memref<4x64xi8>
        %72 = dfschedule.bind_core_buffer(%71, %70) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %73 = dfschedule.bind_core_buffer(%71, %70) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_33 = arith.constant 5 : i32
        %c0_i32_34 = arith.constant 0 : i32
        %74 = dfschedule.config.dma_bd(%73, %70, %c5_i32_33, %c0_i32_34) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 15 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_35 = arith.constant 4 : i32
        %c0_i32_36 = arith.constant 0 : i32
        %75 = dfschedule.config.dma_bd(%72, %70, %c4_i32_35, %c0_i32_36, %74) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 15 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %76 = dfschedule.config.create_io(%75, %70) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %77 = dfschedule.schedule.getbdid(%70) : (!dfschedule.tile) -> i32
        %78 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_37 = memref.subview %subview_21[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3840>>
        %79 = dfschedule.memref_mapping %subview_37 : (memref<4x64xi8, strided<[64, 1], offset: 3840>>) -> memref<4x64xi8>
        %80 = dfschedule.bind_core_buffer(%79, %78) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %81 = dfschedule.bind_core_buffer(%79, %78) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_38 = arith.constant 5 : i32
        %c0_i32_39 = arith.constant 0 : i32
        %82 = dfschedule.config.dma_bd(%81, %78, %c5_i32_38, %c0_i32_39) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 16 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 11 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32) -> !dfschedule.bd_handle
        %c4_i32_40 = arith.constant 4 : i32
        %c0_i32_41 = arith.constant 0 : i32
        %83 = dfschedule.config.dma_bd(%80, %78, %c4_i32_40, %c0_i32_41, %82) {
          len = 256 : i32,
          enable_packet = true,
          packet_id = 16 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 11 : i32
        } : (memref<4x64xi8>, !dfschedule.tile, i32, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %84 = dfschedule.config.create_io(%83, %78) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %85 = dfschedule.schedule.getbdid(%78) : (!dfschedule.tile) -> i32
        %86 = dfschedule.declare_kernel_config @kernelconfig44 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 13 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %87 = dfschedule.declare_kernel_config @kernelconfig45 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 14 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %88 = dfschedule.declare_kernel_config @kernelconfig46 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 15 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %89 = dfschedule.declare_kernel_config @kernelconfig47 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 16 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %90 = dfschedule.schedule.getbdid(%48) : (!dfschedule.tile) -> i32
        %91 = dfschedule.schedule.start_io(%53, %90) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %92 = dfschedule.config.load_kernel_group(%54, %62, %70, %78) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig44, @kernelconfig45, @kernelconfig46, @kernelconfig47]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %93 = dfschedule.schedule.launch_kernel_group(%92) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %94 = dfschedule.schedule.start_io(%60, %61) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.schedule.start_io(%68, %69) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %96 = dfschedule.schedule.start_io(%76, %77) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%84, %85) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%93, %91) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_21 : memref<16x64xi8, strided<[64, 1], offset: 3072>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
