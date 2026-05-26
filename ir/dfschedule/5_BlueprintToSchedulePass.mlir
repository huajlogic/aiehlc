module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @main(%arg0: memref<256x256xi8>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[0, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1]>>
        %4 = dfschedule.declaretile {col = 0 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig48 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 12 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig49 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 12 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig50 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 12 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig51 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 12 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 12 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig48, @kernelconfig49, @kernelconfig50, @kernelconfig51]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 12 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 12 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 12 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 12 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[64, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 16384>>
        %4 = dfschedule.declaretile {col = 1 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 16384>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig52 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 13 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig53 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 13 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig54 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 13 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig55 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 13 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 13 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig52, @kernelconfig53, @kernelconfig54, @kernelconfig55]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 13 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 13 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 13 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 13 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1], offset: 16384>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[128, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 32768>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig56 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 14 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig57 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 14 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig58 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 14 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig59 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 14 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 14 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig56, @kernelconfig57, @kernelconfig58, @kernelconfig59]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 14 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 14 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 14 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 14 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1], offset: 32768>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg1[192, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 49152>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c0_i32_0 = arith.constant 0 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 0 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 49152>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_2 = arith.constant 1 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c1_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_3 = arith.constant 0 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c0_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_5 = arith.constant 1 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c1_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_6 = arith.constant 0 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c0_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_8 = arith.constant 1 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c1_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_9 = arith.constant 0 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c0_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 10240 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 14336 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c1_i32_11 = arith.constant 1 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c1_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 0 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c0_i32_12 = arith.constant 0 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c0_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 1 : i32,
          acquire_lock_id = 2 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 3 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig60 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 15 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig61 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 15 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig62 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 15 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig63 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 15 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 15 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig60, @kernelconfig61, @kernelconfig62, @kernelconfig63]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 15 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 15 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 15 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 15 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1], offset: 49152>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %0 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[0, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1]>>
        %4 = dfschedule.declaretile {col = 0 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[0, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<64x256xi8, strided<[256, 1]>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1]>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig64 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 16 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig65 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 16 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig66 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 16 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig67 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 16 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 16 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig64, @kernelconfig65, @kernelconfig66, @kernelconfig67]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 16 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 16 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 16 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 16 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1]>>
        %subview_13 = memref.subview %arg2[0, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1]>>
        %51 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_14 = arith.constant 1 : i32
        %c5_i32 = arith.constant 5 : i32
        %52 = dfschedule.config.dma_bd(%subview_13, %51, %c5_i32) {
          offset = 192 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 4 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %53 = dfschedule.config.dma_bd(%subview_13, %51, %c4_i32, %52) {
          offset = 128 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 3 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1]>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c3_i32_15 = arith.constant 3 : i32
        %54 = dfschedule.config.dma_bd(%subview_13, %51, %c3_i32_15, %53) {
          offset = 64 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 2 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1]>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c2_i32_16 = arith.constant 2 : i32
        %55 = dfschedule.config.dma_bd(%subview_13, %51, %c2_i32_16, %54) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 1 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1]>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_17 = memref.subview %subview_13[0, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<16x256xi8, strided<[256, 1]>>
        %58 = dfschedule.memref_mapping %subview_17 : (memref<16x256xi8, strided<[256, 1]>>) -> memref<16x256xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_18 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32_18) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 1 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 2 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_19 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32_19, %61) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 1 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 2 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_20 = memref.subview %subview_13[16, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<16x256xi8, strided<[256, 1], offset: 4096>>
        %66 = dfschedule.memref_mapping %subview_20 : (memref<16x256xi8, strided<[256, 1], offset: 4096>>) -> memref<16x256xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_21 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_21) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 2 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_22 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_22, %69) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 2 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_23 = memref.subview %subview_13[32, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<16x256xi8, strided<[256, 1], offset: 8192>>
        %74 = dfschedule.memref_mapping %subview_23 : (memref<16x256xi8, strided<[256, 1], offset: 8192>>) -> memref<16x256xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_24 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_24) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 3 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_25 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_25, %77) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 3 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
        %subview_26 = memref.subview %subview_13[48, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1]>> to memref<16x256xi8, strided<[256, 1], offset: 12288>>
        %82 = dfschedule.memref_mapping %subview_26 : (memref<16x256xi8, strided<[256, 1], offset: 12288>>) -> memref<16x256xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_27 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_27) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 4 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_28 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_28, %85) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 4 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig68 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 17 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig69 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 17 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig70 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 17 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig71 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 17 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 4 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 17 : i32, repeat_count = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig68, @kernelconfig69, @kernelconfig70, @kernelconfig71]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 17 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 17 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 17 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 17 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_13 : memref<64x256xi8, strided<[256, 1]>>
        "routing.yield"() : () -> ()
      }
      %1 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[64, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 16384>>
        %4 = dfschedule.declaretile {col = 1 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 16384>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[64, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1], offset: 32768>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig72 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 18 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig73 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 18 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig74 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 18 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig75 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 18 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 18 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig72, @kernelconfig73, @kernelconfig74, @kernelconfig75]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 18 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 18 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 18 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 18 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1], offset: 16384>>
        %subview_13 = memref.subview %arg2[64, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 16384>>
        %51 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c6_i32 = arith.constant 6 : i32
        %c10_i32 = arith.constant 10 : i32
        %52 = dfschedule.config.dma_bd(%subview_13, %51, %c10_i32) {
          offset = 192 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 8 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 16384>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c9_i32 = arith.constant 9 : i32
        %53 = dfschedule.config.dma_bd(%subview_13, %51, %c9_i32, %52) {
          offset = 128 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 7 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 16384>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c8_i32 = arith.constant 8 : i32
        %54 = dfschedule.config.dma_bd(%subview_13, %51, %c8_i32, %53) {
          offset = 64 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 6 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 16384>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c7_i32 = arith.constant 7 : i32
        %55 = dfschedule.config.dma_bd(%subview_13, %51, %c7_i32, %54) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 5 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 16384>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_14 = memref.subview %subview_13[0, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<16x256xi8, strided<[256, 1], offset: 16384>>
        %58 = dfschedule.memref_mapping %subview_14 : (memref<16x256xi8, strided<[256, 1], offset: 16384>>) -> memref<16x256xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 5 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 7 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32, %61) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 5 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 7 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_15 = memref.subview %subview_13[16, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<16x256xi8, strided<[256, 1], offset: 20480>>
        %66 = dfschedule.memref_mapping %subview_15 : (memref<16x256xi8, strided<[256, 1], offset: 20480>>) -> memref<16x256xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_16 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_16) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 6 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_17 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_17, %69) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 6 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_18 = memref.subview %subview_13[32, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<16x256xi8, strided<[256, 1], offset: 24576>>
        %74 = dfschedule.memref_mapping %subview_18 : (memref<16x256xi8, strided<[256, 1], offset: 24576>>) -> memref<16x256xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_19 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_19) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 7 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_20 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_20, %77) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 7 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
        %subview_21 = memref.subview %subview_13[48, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 16384>> to memref<16x256xi8, strided<[256, 1], offset: 28672>>
        %82 = dfschedule.memref_mapping %subview_21 : (memref<16x256xi8, strided<[256, 1], offset: 28672>>) -> memref<16x256xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_22 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_22) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 8 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_23 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_23, %85) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 8 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig76 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 19 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 5 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig77 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 19 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 6 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig78 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 19 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 7 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig79 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 19 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 8 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 19 : i32, repeat_count = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig76, @kernelconfig77, @kernelconfig78, @kernelconfig79]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 19 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 19 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 19 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 19 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_13 : memref<64x256xi8, strided<[256, 1], offset: 16384>>
        "routing.yield"() : () -> ()
      }
      %2 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[128, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %4 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c1_i32_0 = arith.constant 1 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c1_i32_0) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 32768>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_1 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %8 = dfschedule.memref_mapping %subview_1 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_2 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_2) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_3 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_3, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_4 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %16 = dfschedule.memref_mapping %subview_4 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_5 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_5) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_6 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_6, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_7 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %24 = dfschedule.memref_mapping %subview_7 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_8 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_8) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_9 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_9, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_10 = memref.subview %subview[128, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<64x256xi8, strided<[256, 1], offset: 65536>>
        %32 = dfschedule.memref_mapping %subview_10 : (memref<64x256xi8, strided<[256, 1], offset: 65536>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_11 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_12 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_12, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig80 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 20 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig81 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 20 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig82 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 20 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig83 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 20 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 20 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig80, @kernelconfig81, @kernelconfig82, @kernelconfig83]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 20 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 20 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 20 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 20 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %subview_13 = memref.subview %arg2[128, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 32768>>
        %51 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c2_i32_14 = arith.constant 2 : i32
        %c6_i32 = arith.constant 6 : i32
        %52 = dfschedule.config.dma_bd(%subview_13, %51, %c6_i32) {
          offset = 192 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 12 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 32768>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c5_i32 = arith.constant 5 : i32
        %53 = dfschedule.config.dma_bd(%subview_13, %51, %c5_i32, %52) {
          offset = 128 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 11 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 32768>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %54 = dfschedule.config.dma_bd(%subview_13, %51, %c4_i32, %53) {
          offset = 64 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 10 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 32768>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c3_i32_15 = arith.constant 3 : i32
        %55 = dfschedule.config.dma_bd(%subview_13, %51, %c3_i32_15, %54) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 9 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 32768>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_16 = memref.subview %subview_13[0, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<16x256xi8, strided<[256, 1], offset: 32768>>
        %58 = dfschedule.memref_mapping %subview_16 : (memref<16x256xi8, strided<[256, 1], offset: 32768>>) -> memref<16x256xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_17 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32_17) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_18 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32_18, %61) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 9 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 3 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_19 = memref.subview %subview_13[16, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<16x256xi8, strided<[256, 1], offset: 36864>>
        %66 = dfschedule.memref_mapping %subview_19 : (memref<16x256xi8, strided<[256, 1], offset: 36864>>) -> memref<16x256xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_20 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_20) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_21 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_21, %69) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 10 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 4 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_22 = memref.subview %subview_13[32, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<16x256xi8, strided<[256, 1], offset: 40960>>
        %74 = dfschedule.memref_mapping %subview_22 : (memref<16x256xi8, strided<[256, 1], offset: 40960>>) -> memref<16x256xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_23 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_23) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_24 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_24, %77) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 11 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 5 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
        %subview_25 = memref.subview %subview_13[48, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 32768>> to memref<16x256xi8, strided<[256, 1], offset: 45056>>
        %82 = dfschedule.memref_mapping %subview_25 : (memref<16x256xi8, strided<[256, 1], offset: 45056>>) -> memref<16x256xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_26 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_26) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 6 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_27 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_27, %85) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 12 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 6 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig84 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 21 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 9 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig85 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 21 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 10 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig86 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 21 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 11 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig87 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 21 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 12 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 21 : i32, repeat_count = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig84, @kernelconfig85, @kernelconfig86, @kernelconfig87]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 21 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 21 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 21 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 21 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_13 : memref<64x256xi8, strided<[256, 1], offset: 32768>>
        "routing.yield"() : () -> ()
      }
      %3 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %subview = memref.subview %arg0[192, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 49152>>
        %4 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
        %c11_i32 = arith.constant 11 : i32
        %5 = dfschedule.config.dma_bd(%subview, %4, %c11_i32) {
          offset = 0 : i32,
          len = 16384 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = 0 : i32,
          release_lock_val = 0 : i32,
          data_id = 1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 49152>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %6 = dfschedule.config.create_io(%5, %4) {
          channel = 1,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %7 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_0 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %8 = dfschedule.memref_mapping %subview_0 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %9 = dfschedule.bind_core_buffer(%8, %7) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %10 = dfschedule.bind_core_buffer(%8, %7) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_1 = arith.constant 3 : i32
        %11 = dfschedule.config.dma_bd(%10, %7, %c3_i32_1) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_2 = arith.constant 2 : i32
        %12 = dfschedule.config.dma_bd(%9, %7, %c2_i32_2, %11) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %13 = dfschedule.config.create_io(%12, %7) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %14 = dfschedule.schedule.getbdid(%7) : (!dfschedule.tile) -> i32
        %15 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_3 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %16 = dfschedule.memref_mapping %subview_3 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %17 = dfschedule.bind_core_buffer(%16, %15) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %18 = dfschedule.bind_core_buffer(%16, %15) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_4 = arith.constant 3 : i32
        %19 = dfschedule.config.dma_bd(%18, %15, %c3_i32_4) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_5 = arith.constant 2 : i32
        %20 = dfschedule.config.dma_bd(%17, %15, %c2_i32_5, %19) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %21 = dfschedule.config.create_io(%20, %15) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %22 = dfschedule.schedule.getbdid(%15) : (!dfschedule.tile) -> i32
        %23 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_6 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %24 = dfschedule.memref_mapping %subview_6 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %25 = dfschedule.bind_core_buffer(%24, %23) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %26 = dfschedule.bind_core_buffer(%24, %23) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_7 = arith.constant 3 : i32
        %27 = dfschedule.config.dma_bd(%26, %23, %c3_i32_7) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_8 = arith.constant 2 : i32
        %28 = dfschedule.config.dma_bd(%25, %23, %c2_i32_8, %27) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %29 = dfschedule.config.create_io(%28, %23) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %30 = dfschedule.schedule.getbdid(%23) : (!dfschedule.tile) -> i32
        %31 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_9 = memref.subview %subview[192, 0] [64, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<64x256xi8, strided<[256, 1], offset: 98304>>
        %32 = dfschedule.memref_mapping %subview_9 : (memref<64x256xi8, strided<[256, 1], offset: 98304>>) -> memref<64x256xi8>
        %33 = dfschedule.bind_core_buffer(%32, %31) {offset = 18432 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %34 = dfschedule.bind_core_buffer(%32, %31) {offset = 22528 : i64} : (memref<64x256xi8>, !dfschedule.tile) -> memref<64x256xi8>
        %c3_i32_10 = arith.constant 3 : i32
        %35 = dfschedule.config.dma_bd(%34, %31, %c3_i32_10) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 2 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c2_i32_11 = arith.constant 2 : i32
        %36 = dfschedule.config.dma_bd(%33, %31, %c2_i32_11, %35) {
          offset = 0 : i32,
          len = 4096 : i32,
          enable_packet = false,
          packet_id = 0 : i32,
          next_bd = 3 : i32,
          acquire_lock_id = 0 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 1 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = -1 : i32
        } : (memref<64x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %37 = dfschedule.config.create_io(%36, %31) {
          channel = 0,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %38 = dfschedule.schedule.getbdid(%31) : (!dfschedule.tile) -> i32
        %39 = dfschedule.declare_kernel_config @kernelconfig88 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 22 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
        %40 = dfschedule.declare_kernel_config @kernelconfig89 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 22 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
        %41 = dfschedule.declare_kernel_config @kernelconfig90 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 22 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 2 : i32, release_lock_id = 1 : i32, tile_index = 2 : i32}]}
        %42 = dfschedule.declare_kernel_config @kernelconfig91 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 4096 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 22 : i32, num_buffers = 2 : i32, num_iterations = 4 : i32, packet_id = 3 : i32, release_lock_id = 1 : i32, tile_index = 3 : i32}]}
        %43 = dfschedule.schedule.getbdid(%4) : (!dfschedule.tile) -> i32
        %44 = dfschedule.schedule.start_io(%6, %43) {flow_index = 22 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %45 = dfschedule.config.load_kernel_group(%7, %15, %23, %31) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig88, @kernelconfig89, @kernelconfig90, @kernelconfig91]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %46 = dfschedule.schedule.launch_kernel_group(%45) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %47 = dfschedule.schedule.start_io(%13, %14) {flow_index = 22 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %48 = dfschedule.schedule.start_io(%21, %22) {flow_index = 22 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %49 = dfschedule.schedule.start_io(%29, %30) {flow_index = 22 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %50 = dfschedule.schedule.start_io(%37, %38) {flow_index = 22 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%46, %44) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview : memref<64x256xi8, strided<[256, 1], offset: 49152>>
        %subview_12 = memref.subview %arg2[192, 0] [64, 256] [1, 1] : memref<256x256xi8> to memref<64x256xi8, strided<[256, 1], offset: 49152>>
        %51 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
        %c7_i32 = arith.constant 7 : i32
        %c11_i32_13 = arith.constant 11 : i32
        %52 = dfschedule.config.dma_bd(%subview_12, %51, %c11_i32_13) {
          offset = 192 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 16 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 49152>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c10_i32 = arith.constant 10 : i32
        %53 = dfschedule.config.dma_bd(%subview_12, %51, %c10_i32, %52) {
          offset = 128 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 15 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 49152>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c9_i32 = arith.constant 9 : i32
        %54 = dfschedule.config.dma_bd(%subview_12, %51, %c9_i32, %53) {
          offset = 64 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 14 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 49152>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %c8_i32 = arith.constant 8 : i32
        %55 = dfschedule.config.dma_bd(%subview_12, %51, %c8_i32, %54) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = false,
          packet_id = 13 : i32,
          next_bd = 4294967295 : i32,
          acquire_lock_id = -1 : i32,
          acquire_lock_val = 0 : i32,
          release_lock_id = -1 : i32,
          release_lock_val = 0 : i32,
          data_id = 2 : i32,
          out_of_order_bd_id = -1 : i32,
          dim_strides = [4, 256],
          dim_wraps = [16, 32],
          iter_step_size = 8192 : i32,
          iter_wrap = 2 : i32
        } : (memref<64x256xi8, strided<[256, 1], offset: 49152>>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %56 = dfschedule.config.create_io(%55, %51) {
          channel = 1,
          direction = "S2MM",
          io_operation = "RECV",
          enable_out_of_order = true
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %57 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_14 = memref.subview %subview_12[0, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<16x256xi8, strided<[256, 1], offset: 49152>>
        %58 = dfschedule.memref_mapping %subview_14 : (memref<16x256xi8, strided<[256, 1], offset: 49152>>) -> memref<16x256xi8>
        %59 = dfschedule.bind_core_buffer(%58, %57) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %60 = dfschedule.bind_core_buffer(%58, %57) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32 = arith.constant 5 : i32
        %61 = dfschedule.config.dma_bd(%60, %57, %c5_i32) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 13 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32 = arith.constant 4 : i32
        %62 = dfschedule.config.dma_bd(%59, %57, %c4_i32, %61) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 13 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 8 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %63 = dfschedule.config.create_io(%62, %57) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %64 = dfschedule.schedule.getbdid(%57) : (!dfschedule.tile) -> i32
        %65 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_15 = memref.subview %subview_12[16, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<16x256xi8, strided<[256, 1], offset: 53248>>
        %66 = dfschedule.memref_mapping %subview_15 : (memref<16x256xi8, strided<[256, 1], offset: 53248>>) -> memref<16x256xi8>
        %67 = dfschedule.bind_core_buffer(%66, %65) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %68 = dfschedule.bind_core_buffer(%66, %65) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_16 = arith.constant 5 : i32
        %69 = dfschedule.config.dma_bd(%68, %65, %c5_i32_16) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 14 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_17 = arith.constant 4 : i32
        %70 = dfschedule.config.dma_bd(%67, %65, %c4_i32_17, %69) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 14 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 9 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %71 = dfschedule.config.create_io(%70, %65) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %72 = dfschedule.schedule.getbdid(%65) : (!dfschedule.tile) -> i32
        %73 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_18 = memref.subview %subview_12[32, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<16x256xi8, strided<[256, 1], offset: 57344>>
        %74 = dfschedule.memref_mapping %subview_18 : (memref<16x256xi8, strided<[256, 1], offset: 57344>>) -> memref<16x256xi8>
        %75 = dfschedule.bind_core_buffer(%74, %73) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %76 = dfschedule.bind_core_buffer(%74, %73) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_19 = arith.constant 5 : i32
        %77 = dfschedule.config.dma_bd(%76, %73, %c5_i32_19) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 15 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_20 = arith.constant 4 : i32
        %78 = dfschedule.config.dma_bd(%75, %73, %c4_i32_20, %77) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 15 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 10 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %79 = dfschedule.config.create_io(%78, %73) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %80 = dfschedule.schedule.getbdid(%73) : (!dfschedule.tile) -> i32
        %81 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
        %subview_21 = memref.subview %subview_12[48, 0] [16, 256] [1, 1] : memref<64x256xi8, strided<[256, 1], offset: 49152>> to memref<16x256xi8, strided<[256, 1], offset: 61440>>
        %82 = dfschedule.memref_mapping %subview_21 : (memref<16x256xi8, strided<[256, 1], offset: 61440>>) -> memref<16x256xi8>
        %83 = dfschedule.bind_core_buffer(%82, %81) {offset = 26624 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %84 = dfschedule.bind_core_buffer(%82, %81) {offset = 30720 : i64} : (memref<16x256xi8>, !dfschedule.tile) -> memref<16x256xi8>
        %c5_i32_22 = arith.constant 5 : i32
        %85 = dfschedule.config.dma_bd(%84, %81, %c5_i32_22) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 16 : i32,
          next_bd = 4 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 11 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
        %c4_i32_23 = arith.constant 4 : i32
        %86 = dfschedule.config.dma_bd(%83, %81, %c4_i32_23, %85) {
          offset = 0 : i32,
          len = 2048 : i32,
          enable_packet = true,
          packet_id = 16 : i32,
          next_bd = 5 : i32,
          acquire_lock_id = 5 : i32,
          acquire_lock_val = -1 : i32,
          release_lock_id = 4 : i32,
          release_lock_val = 1 : i32,
          data_id = -1 : i32,
          out_of_order_bd_id = 11 : i32
        } : (memref<16x256xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
        %87 = dfschedule.config.create_io(%86, %81) {
          channel = 0,
          direction = "MM2S",
          io_operation = "SEND",
          enable_out_of_order = false
        } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
        %88 = dfschedule.schedule.getbdid(%81) : (!dfschedule.tile) -> i32
        %89 = dfschedule.declare_kernel_config @kernelconfig92 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 23 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 13 : i32, release_lock_id = 5 : i32, tile_index = 0 : i32}]}
        %90 = dfschedule.declare_kernel_config @kernelconfig93 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 4096 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 23 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 14 : i32, release_lock_id = 5 : i32, tile_index = 1 : i32}]}
        %91 = dfschedule.declare_kernel_config @kernelconfig94 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 8192 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 23 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 15 : i32, release_lock_id = 5 : i32, tile_index = 2 : i32}]}
        %92 = dfschedule.declare_kernel_config @kernelconfig95 {tile_configs = [{acquire_lock_id = 4 : i32, buffer_mode = 1 : i32, buffer_offset = 12288 : i32, buffer_size = 2048 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 23 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 16 : i32, release_lock_id = 5 : i32, tile_index = 3 : i32}]}
        %93 = dfschedule.schedule.getbdid(%51) : (!dfschedule.tile) -> i32
        %94 = dfschedule.schedule.start_io(%56, %93) {flow_index = 23 : i32, repeat_count = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %95 = dfschedule.config.load_kernel_group(%57, %65, %73, %81) {
          callee = [@dskernel_receiver],
          distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
          distributed_args = [@kernelconfig92, @kernelconfig93, @kernelconfig94, @kernelconfig95]
        } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
        %96 = dfschedule.schedule.launch_kernel_group(%95) : (!dfschedule.kernelgroup) -> !dfschedule.event
        %97 = dfschedule.schedule.start_io(%63, %64) {flow_index = 23 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %98 = dfschedule.schedule.start_io(%71, %72) {flow_index = 23 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %99 = dfschedule.schedule.start_io(%79, %80) {flow_index = 23 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        %100 = dfschedule.schedule.start_io(%87, %88) {flow_index = 23 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
        dfschedule.schedule.wait(%96, %94) : (!dfschedule.event, !dfschedule.event)
        dfschedule.free_device_mem %subview_12 : memref<64x256xi8, strided<[256, 1], offset: 49152>>
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
