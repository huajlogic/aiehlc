module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  dfschedule.module @kernel_driver_dskernel_receiver {
    dfschedule.kernel_config_def @config {buffer_size = 1024 : i32, element_type = i8, kernel_file = "computekernel.cc", kernel_name = "computekernel", vector_width = 4 : i32}
    dfschedule.lock_def @LOCK_window_in_0_ACQ {id = 48 : i32, init_value = 2 : i32}
    dfschedule.lock_def @LOCK_window_in_0_REL {id = 49 : i32}
    dfschedule.buffer_def @buf_in_ping_0 : memref<1024xvector<4xi8>, "LOCAL"> {address = 499712 : i64}
    dfschedule.buffer_def @buf_in_pong_0 : memref<1024xvector<4xi8>, "LOCAL"> {address = 503808 : i64}
    dfschedule.window_def @window_in_0 {acquire_lock = @LOCK_window_in_0_ACQ, async = true, buffer_size = 1024 : i32, direction = "in", num_rounds = 4 : i32, ping_buffer = @buf_in_ping_0, pong_buffer = @buf_in_pong_0, release_lock = @LOCK_window_in_0_REL}
    dfschedule.lock_def @LOCK_window_in_1_ACQ {id = 50 : i32, init_value = 2 : i32}
    dfschedule.lock_def @LOCK_window_in_1_REL {id = 51 : i32}
    dfschedule.buffer_def @buf_in_ping_1 : memref<1024xvector<4xi8>, "LOCAL"> {address = 491520 : i64}
    dfschedule.buffer_def @buf_in_pong_1 : memref<1024xvector<4xi8>, "LOCAL"> {address = 495616 : i64}
    dfschedule.window_def @window_in_1 {acquire_lock = @LOCK_window_in_1_ACQ, async = true, buffer_size = 1024 : i32, direction = "in", num_rounds = 4 : i32, ping_buffer = @buf_in_ping_1, pong_buffer = @buf_in_pong_1, release_lock = @LOCK_window_in_1_REL}
    dfschedule.lock_def @LOCK_window_out_0_ACQ {id = 52 : i32, init_value = 0 : i32}
    dfschedule.lock_def @LOCK_window_out_0_REL {id = 53 : i32}
    dfschedule.buffer_def @buf_out_ping_0 : memref<512xvector<4xi8>, "LOCAL"> {address = 507904 : i64}
    dfschedule.buffer_def @buf_out_pong_0 : memref<512xvector<4xi8>, "LOCAL"> {address = 512000 : i64}
    dfschedule.window_def @window_out_0 {acquire_lock = @LOCK_window_out_0_ACQ, async = true, buffer_size = 512 : i32, direction = "out", num_rounds = 2 : i32, ping_buffer = @buf_out_ping_0, pong_buffer = @buf_out_pong_0, release_lock = @LOCK_window_out_0_REL}
    dfschedule.kernel_decl @computekernel {inputs = [@window_in_0, @window_in_1], iteration_style = "internal", outputs = [@window_out_0]}
    dfschedule.main @main {
      %0 = dfschedule.alloc_sync_buffer {size = 8 : i32} : !dfschedule.sync_buffer
      %c0_i32 = arith.constant 0 : i32
      dfschedule.sync_buffer_write(%0, %c0_i32) {index = 0 : i32}
      %c1_i32 = arith.constant 1 : i32
      dfschedule.log(%c1_i32)
      %1 = dfschedule.window_init(@window_in_0) : !dfschedule.input_window<i8>
      %2 = dfschedule.window_init(@window_in_1) : !dfschedule.input_window<i8>
      %3 = dfschedule.window_init(@window_out_0) : !dfschedule.output_window<i8>
      dfschedule.kernel_invoke @computekernel(%1, %2, %3) : (!dfschedule.input_window<i8>, !dfschedule.input_window<i8>, !dfschedule.output_window<i8>)
      dfschedule.done
      dfschedule.kernel_return
    }
  }
}
