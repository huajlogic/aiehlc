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
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig0 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig1 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig2 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig3 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 0 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig0, @kernelconfig1, @kernelconfig2, @kernelconfig3]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[16, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %4 = dfschedule.declaretile {col = 1 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig4 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig5 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig6 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig7 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 1 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig4, @kernelconfig5, @kernelconfig6, @kernelconfig7]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 1024>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[32, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig8 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig9 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig10 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig11 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 2 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig8, @kernelconfig9, @kernelconfig10, @kernelconfig11]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 2048>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[48, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32768 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32832 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig12 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig13 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig14 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig15 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 3 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig12, @kernelconfig13, @kernelconfig14, @kernelconfig15]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
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
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[0, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<16x64xi8, strided<[64, 1]>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1]>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig16 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig17 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig18 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig19 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 4 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 4 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig16, @kernelconfig17, @kernelconfig18, @kernelconfig19]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1]>>
        %subview_13 = memref.subview %arg2[0, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1]>>
        %51 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_14 = arith.constant 1 : i32
        %c5_i32 = arith.constant 5 : i32
        %52 = dfschedule.config.dma_bd(%subview_13, %51, %c5_i32) {
          offset = 48 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %53 = dfschedule.config.dma_bd(%subview_13, %51, %c4_i32, %52) {
          offset = 32 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c3_i32_15 = arith.constant 3 : i32
        %54 = dfschedule.config.dma_bd(%subview_13, %51, %c3_i32_15, %53) {
          offset = 16 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c2_i32_16 = arith.constant 2 : i32
        %55 = dfschedule.config.dma_bd(%subview_13, %51, %c2_i32_16, %54) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1]>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview_13[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1]>>
        %58 = dfschedule.memref_mapping %subview_17 : (memref<4x64xi8, strided<[64, 1]>>) -> memref<4x64xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_18 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32_18) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_19 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32_19, %61) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_20 = memref.subview %subview_13[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1], offset: 256>>
        %66 = dfschedule.memref_mapping %subview_20 : (memref<4x64xi8, strided<[64, 1], offset: 256>>) -> memref<4x64xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_21 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_21) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_22 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_22, %69) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_23 = memref.subview %subview_13[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1], offset: 512>>
        %74 = dfschedule.memref_mapping %subview_23 : (memref<4x64xi8, strided<[64, 1], offset: 512>>) -> memref<4x64xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_24 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_24) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_25 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_25, %77) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_26 = memref.subview %subview_13[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1]>> to memref<4x64xi8, strided<[64, 1], offset: 768>>
        %82 = dfschedule.memref_mapping %subview_26 : (memref<4x64xi8, strided<[64, 1], offset: 768>>) -> memref<4x64xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_27 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_27) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_28 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_28, %85) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig20 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 1 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig21 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 2 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig22 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 3 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig23 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 5 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 4 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig20, @kernelconfig21, @kernelconfig22, @kernelconfig23]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 5 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_13 : memref<16x64xi8, strided<[64, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[16, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %4 = dfschedule.declaretile {col = 1 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[16, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1], offset: 2048>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig24 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig25 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig26 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig27 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 6 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 6 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig24, @kernelconfig25, @kernelconfig26, @kernelconfig27]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %subview_13 = memref.subview %arg2[16, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 1024>>
        %51 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c6_i32 = arith.constant 6 : i32
        %c10_i32 = arith.constant 10 : i32
        %52 = dfschedule.config.dma_bd(%subview_13, %51, %c10_i32) {
          offset = 48 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c9_i32 = arith.constant 9 : i32
        %53 = dfschedule.config.dma_bd(%subview_13, %51, %c9_i32, %52) {
          offset = 32 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c8_i32 = arith.constant 8 : i32
        %54 = dfschedule.config.dma_bd(%subview_13, %51, %c8_i32, %53) {
          offset = 16 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c7_i32 = arith.constant 7 : i32
        %55 = dfschedule.config.dma_bd(%subview_13, %51, %c7_i32, %54) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 1024>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_14 = memref.subview %subview_13[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1024>>
        %58 = dfschedule.memref_mapping %subview_14 : (memref<4x64xi8, strided<[64, 1], offset: 1024>>) -> memref<4x64xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32, %61) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_15 = memref.subview %subview_13[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1280>>
        %66 = dfschedule.memref_mapping %subview_15 : (memref<4x64xi8, strided<[64, 1], offset: 1280>>) -> memref<4x64xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_16 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_16) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_17 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_17, %69) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_18 = memref.subview %subview_13[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1536>>
        %74 = dfschedule.memref_mapping %subview_18 : (memref<4x64xi8, strided<[64, 1], offset: 1536>>) -> memref<4x64xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_19 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_19) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_20 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_20, %77) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_21 = memref.subview %subview_13[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 1024>> to memref<4x64xi8, strided<[64, 1], offset: 1792>>
        %82 = dfschedule.memref_mapping %subview_21 : (memref<4x64xi8, strided<[64, 1], offset: 1792>>) -> memref<4x64xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_22 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_22) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_23 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_23, %85) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig28 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 5 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig29 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 6 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig30 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 7 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig31 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 7 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 8 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig28, @kernelconfig29, @kernelconfig30, @kernelconfig31]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 7 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_13 : memref<16x64xi8, strided<[64, 1], offset: 1024>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[32, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[32, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<16x64xi8, strided<[64, 1], offset: 4096>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<16x64xi8, strided<[64, 1], offset: 4096>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig32 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig33 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig34 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig35 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 8 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 8 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig32, @kernelconfig33, @kernelconfig34, @kernelconfig35]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %subview_13 = memref.subview %arg2[32, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 2048>>
        %51 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c2_i32_14 = arith.constant 2 : i32
        %c6_i32 = arith.constant 6 : i32
        %52 = dfschedule.config.dma_bd(%subview_13, %51, %c6_i32) {
          offset = 48 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c5_i32 = arith.constant 5 : i32
        %53 = dfschedule.config.dma_bd(%subview_13, %51, %c5_i32, %52) {
          offset = 32 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %54 = dfschedule.config.dma_bd(%subview_13, %51, %c4_i32, %53) {
          offset = 16 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c3_i32_15 = arith.constant 3 : i32
        %55 = dfschedule.config.dma_bd(%subview_13, %51, %c3_i32_15, %54) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 2048>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_16 = memref.subview %subview_13[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2048>>
        %58 = dfschedule.memref_mapping %subview_16 : (memref<4x64xi8, strided<[64, 1], offset: 2048>>) -> memref<4x64xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_17 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32_17) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_18 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32_18, %61) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_19 = memref.subview %subview_13[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2304>>
        %66 = dfschedule.memref_mapping %subview_19 : (memref<4x64xi8, strided<[64, 1], offset: 2304>>) -> memref<4x64xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_20 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_20) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_21 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_21, %69) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_22 = memref.subview %subview_13[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2560>>
        %74 = dfschedule.memref_mapping %subview_22 : (memref<4x64xi8, strided<[64, 1], offset: 2560>>) -> memref<4x64xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_23 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_23) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_24 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_24, %77) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_25 = memref.subview %subview_13[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 2048>> to memref<4x64xi8, strided<[64, 1], offset: 2816>>
        %82 = dfschedule.memref_mapping %subview_25 : (memref<4x64xi8, strided<[64, 1], offset: 2816>>) -> memref<4x64xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_26 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_26) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_27 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_27, %85) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig36 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 9 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig37 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 10 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig38 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 11 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig39 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 9 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 12 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig36, @kernelconfig37, @kernelconfig38, @kernelconfig39]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 9 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_13 : memref<16x64xi8, strided<[64, 1], offset: 2048>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[48, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c11_i32 = arith.constant 11 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c11_i32) {
          offset = 0 : i32,
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
          iter_step_size = 256 : i32,
          iter_wrap = 4 : i32
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_0 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %8 = dfschedule.memref_mapping %subview_0 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_1 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_1) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_2 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_2, %11) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_3 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %16 = dfschedule.memref_mapping %subview_3 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_4 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_4) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_5 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_5, %19) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_6 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %24 = dfschedule.memref_mapping %subview_6 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_7 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_7) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_8 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_8, %27) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_9 = memref.subview %subview[48, 0] [16, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<16x64xi8, strided<[64, 1], offset: 6144>>
        %32 = dfschedule.memref_mapping %subview_9 : (memref<16x64xi8, strided<[64, 1], offset: 6144>>) -> memref<16x64xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 32896 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 32960 : i64} : (memref<16x64xi8>, !dfschedule.tile) -> memref<16x64xi8>
        %c3_i32_10 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_10) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_11 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_11, %35) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig40 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig41 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig42 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig43 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 10 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 10 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig40, @kernelconfig41, @kernelconfig42, @kernelconfig43]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %subview_12 = memref.subview %arg2[48, 0] [16, 64] [1, 1] : memref<64x64xi8> to memref<16x64xi8, strided<[64, 1], offset: 3072>>
        %51 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c7_i32 = arith.constant 7 : i32
        %c11_i32_13 = arith.constant 11 : i32
        %52 = dfschedule.config.dma_bd(%subview_12, %51, %c11_i32_13) {
          offset = 48 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c10_i32 = arith.constant 10 : i32
        %53 = dfschedule.config.dma_bd(%subview_12, %51, %c10_i32, %52) {
          offset = 32 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c9_i32 = arith.constant 9 : i32
        %54 = dfschedule.config.dma_bd(%subview_12, %51, %c9_i32, %53) {
          offset = 16 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c8_i32 = arith.constant 8 : i32
        %55 = dfschedule.config.dma_bd(%subview_12, %51, %c8_i32, %54) {
          offset = 0 : i32,
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
        } : (memref<16x64xi8, strided<[64, 1], offset: 3072>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_14 = memref.subview %subview_12[0, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3072>>
        %58 = dfschedule.memref_mapping %subview_14 : (memref<4x64xi8, strided<[64, 1], offset: 3072>>) -> memref<4x64xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32, %61) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_15 = memref.subview %subview_12[4, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3328>>
        %66 = dfschedule.memref_mapping %subview_15 : (memref<4x64xi8, strided<[64, 1], offset: 3328>>) -> memref<4x64xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_16 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_16) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_17 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_17, %69) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_18 = memref.subview %subview_12[8, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3584>>
        %74 = dfschedule.memref_mapping %subview_18 : (memref<4x64xi8, strided<[64, 1], offset: 3584>>) -> memref<4x64xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_19 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_19) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_20 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_20, %77) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_21 = memref.subview %subview_12[12, 0] [4, 64] [1, 1] : memref<16x64xi8, strided<[64, 1], offset: 3072>> to memref<4x64xi8, strided<[64, 1], offset: 3840>>
        %82 = dfschedule.memref_mapping %subview_21 : (memref<4x64xi8, strided<[64, 1], offset: 3840>>) -> memref<4x64xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 33024 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 33280 : i64} : (memref<4x64xi8>, !dfschedule.tile) -> memref<4x64xi8>
        %c5_i32_22 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_22) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_23 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_23, %85) {
          offset = 0 : i32,
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
        } : (memref<4x64xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig44 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 13 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig45 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 256 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 14 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig46 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 512 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 15 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig47 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 768 : i32, buffer_size = 256 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 11 : i32, num_buffers = 2 : i32, num_iterations = 1 : i32, packet_id = 16 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig44, @kernelconfig45, @kernelconfig46, @kernelconfig47]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 11 : i32, repeat_count = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_12 : memref<16x64xi8, strided<[64, 1], offset: 3072>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
