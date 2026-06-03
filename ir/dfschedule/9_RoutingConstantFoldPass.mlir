module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.effective_k = 16 : i64, routing.full_k = 64 : i64, routing.k_rounds = 4 : i64, routing.m_rounds = 2 : i64, routing.n_rounds = 2 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}, routing.tile_cols = 16 : i64, routing.tile_m = 8 : i64, routing.tile_n = 8 : i64, routing.tile_rows = 16 : i64} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<64x64xi8>, %arg1: memref<64x64xi8>, %arg2: memref<64x64xi8>) {
    emitc.call_opaque "host_canonicalized"() : () -> ()
    return
  }
  emitc.func @host_canonicalized(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: !emitc.ptr<!emitc.opaque<"void">>, %arg2: !emitc.ptr<!emitc.opaque<"void">>, %arg3: !emitc.ptr<!emitc.opaque<"void">>) {
    %0 = "emitc.constant"() <{value = 1 : index}> : () -> index
    %1 = "emitc.constant"() <{value = 2 : index}> : () -> index
    %2 = "emitc.constant"() <{value = 0 : index}> : () -> index
    %3 = "emitc.constant"() <{value = 512 : i32}> : () -> i32
    %4 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %5 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %6 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    emitc.verbatim "XAie_DevInst* dev = v1;"
    %7 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %8 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %9 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %10 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %11 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %9, %10) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %12 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %13 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %9, %12) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %14 = emitc.call_opaque "__Runtime_dma_createio_4"(%9, %13) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %15 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %16 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %17 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %15, %16) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %18 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %19 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %15, %18) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %20 = emitc.call_opaque "__Runtime_dma_createio_4"(%15, %19) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %21 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %22 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %23 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %21, %22) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %24 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %25 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %21, %24) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %26 = emitc.call_opaque "__Runtime_dma_createio_4"(%21, %25) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %27 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %28 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %29 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %28) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %30 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %31 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %30) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %32 = emitc.call_opaque "__Runtime_dma_createio_4"(%27, %31) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %8, %437) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%8, %438) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (0,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %33 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %34 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %35 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %36 = emitc.call_opaque "__runtime_buffer_offset"(%33) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %37 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %38 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %37) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %39 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %40 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %39) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %41 = emitc.call_opaque "__Runtime_dma_createio_4"(%35, %40) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %42 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %43 = emitc.call_opaque "__runtime_buffer_offset"(%33) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %44 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %45 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %44) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %46 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %47 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %46) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %48 = emitc.call_opaque "__Runtime_dma_createio_4"(%42, %47) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %49 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %50 = emitc.call_opaque "__runtime_buffer_offset"(%33) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %51) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %53 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %54 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %53) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %55 = emitc.call_opaque "__Runtime_dma_createio_4"(%49, %54) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %56 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %57 = emitc.call_opaque "__runtime_buffer_offset"(%33) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %58 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %59 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %58) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %60 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %61 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %60) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %62 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %61) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%33) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %34, %437) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%34, %438) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %63 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %64 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %65 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %66 = emitc.call_opaque "__runtime_buffer_offset"(%63) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %67 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %68 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %67) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %69 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %70 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %69) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %71 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %70) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %72 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %73 = emitc.call_opaque "__runtime_buffer_offset"(%63) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %74 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %75 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %74) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %76 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %77 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %76) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %78 = emitc.call_opaque "__Runtime_dma_createio_4"(%72, %77) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %79 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %80 = emitc.call_opaque "__runtime_buffer_offset"(%63) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %81 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %82 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %81) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %83 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %84 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %83) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %85 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %84) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %86 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %87 = emitc.call_opaque "__runtime_buffer_offset"(%63) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %88 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %89 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %86, %88) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %90 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %91 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %86, %90) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %92 = emitc.call_opaque "__Runtime_dma_createio_4"(%86, %91) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%63) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %64, %437) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%64, %438) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %93 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %94 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %95 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %96 = emitc.call_opaque "__runtime_buffer_offset"(%93) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %97 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %98 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %95, %97) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %99 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %100 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %95, %99) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %101 = emitc.call_opaque "__Runtime_dma_createio_4"(%95, %100) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %102 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %103 = emitc.call_opaque "__runtime_buffer_offset"(%93) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %104 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %105 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %102, %104) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %106 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %107 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %102, %106) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %108 = emitc.call_opaque "__Runtime_dma_createio_4"(%102, %107) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %109 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %110 = emitc.call_opaque "__runtime_buffer_offset"(%93) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %111 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %112 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %109, %111) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %113 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %114 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %109, %113) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %115 = emitc.call_opaque "__Runtime_dma_createio_4"(%109, %114) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %116 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %117 = emitc.call_opaque "__runtime_buffer_offset"(%93) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=128, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %118 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %119 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %116, %118) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 128 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=128, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %120 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %121 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %116, %120) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 128 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %122 = emitc.call_opaque "__Runtime_dma_createio_4"(%116, %121) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%93) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %94, %437) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%94, %438) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %123 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %124 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %125 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %9, %124) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %126 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %127 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %9, %126) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %128 = emitc.call_opaque "__Runtime_dma_createio_4"(%9, %127) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %129 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %130 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %129) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %131 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %132 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %131) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %133 = emitc.call_opaque "__Runtime_dma_createio_4"(%35, %132) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %134 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %135 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %134) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %136 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %137 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %136) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %138 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %137) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %139 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %140 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %95, %139) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %141 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %142 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %95, %141) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %143 = emitc.call_opaque "__Runtime_dma_createio_4"(%95, %142) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=1, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%123) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %8, %437) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%8, %438) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 3 for tile (0,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 3 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %144 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %145 = emitc.call_opaque "__runtime_buffer_arg"(%144) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %146 = emitc.cast %4 : i32 to i64
    %147 = emitc.call_opaque "__runtime_buffer_offset"(%145, %146) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %148 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %147) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, -1 : i32, 0 : i32, 4 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %149 = emitc.call_opaque "__runtime_buffer_arg"(%144) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %150 = emitc.cast %5 : i32 to i64
    %151 = emitc.call_opaque "__runtime_buffer_offset"(%149, %150) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %152 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %151) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, -1 : i32, 0 : i32, 3 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=256, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %153 = emitc.call_opaque "__runtime_buffer_arg"(%144) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %154 = emitc.cast %6 : i32 to i64
    %155 = emitc.call_opaque "__runtime_buffer_offset"(%153, %154) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %156 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %155) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 256 : i32, -1 : i32, 0 : i32, 2 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=256, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %157 = emitc.call_opaque "__runtime_buffer_arg"(%144) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %158 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %157) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 256 : i32, -1 : i32, 0 : i32, 1 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %94) {args = [0 : index, 1 : index, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %159 = emitc.call_opaque "__Runtime_dma_createio_4"(%94, %158) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %160 = emitc.call_opaque "__runtime_buffer_offset"(%144) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %161 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %162 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %9, %161) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 1 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %163 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %164 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %9, %163) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 1 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %165 = emitc.call_opaque "__Runtime_dma_createio_4"(%9, %164) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %166 = emitc.call_opaque "__runtime_buffer_offset"(%144) {args = [0 : index, 256]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %167 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %168 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %167) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 2 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 3 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %169 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %170 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %169) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 2 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 3 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %171 = emitc.call_opaque "__Runtime_dma_createio_4"(%35, %170) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %172 = emitc.call_opaque "__runtime_buffer_offset"(%144) {args = [0 : index, 512]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %173 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %174 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %173) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 3 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %175 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %176 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %175) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 3 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %177 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %176) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %178 = emitc.call_opaque "__runtime_buffer_offset"(%144) {args = [0 : index, 768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %179 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %180 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %95, %179) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 4 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 5 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %181 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %182 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %95, %181) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 4 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 5 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %183 = emitc.call_opaque "__Runtime_dma_createio_4"(%95, %182) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %184 = emitc.call_opaque "__Runtime_startio"(%arg0, %159) {args = [0 : index, 1 : index, 2 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %185 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %186 = emitc.call_opaque "__runtime_buffer_offset"(%185) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %187 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %188 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %15, %187) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %189 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %190 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %15, %189) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %191 = emitc.call_opaque "__Runtime_dma_createio_4"(%15, %190) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %192 = emitc.call_opaque "__runtime_buffer_offset"(%185) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %193 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %194 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %193) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %195 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %196 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %195) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %197 = emitc.call_opaque "__Runtime_dma_createio_4"(%42, %196) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %198 = emitc.call_opaque "__runtime_buffer_offset"(%185) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %199 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %200 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %199) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %201 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %202 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %201) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %203 = emitc.call_opaque "__Runtime_dma_createio_4"(%72, %202) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %204 = emitc.call_opaque "__runtime_buffer_offset"(%185) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %205 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %206 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %102, %205) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %207 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %208 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %102, %207) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %209 = emitc.call_opaque "__Runtime_dma_createio_4"(%102, %208) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=1, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%185) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %34, %437) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%34, %438) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 3 for tile (1,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 3 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %210 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 1024]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, len=256, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %211 = emitc.call_opaque "__runtime_buffer_arg"(%210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %212 = emitc.cast %4 : i32 to i64
    %213 = emitc.call_opaque "__runtime_buffer_offset"(%211, %212) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %214 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %213) {args = [0 : index, 1 : index, 2 : index, 10 : i32, 256 : i32, -1 : i32, 0 : i32, 8 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, len=256, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %215 = emitc.call_opaque "__runtime_buffer_arg"(%210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %216 = emitc.cast %5 : i32 to i64
    %217 = emitc.call_opaque "__runtime_buffer_offset"(%215, %216) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %218 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %217) {args = [0 : index, 1 : index, 2 : index, 9 : i32, 256 : i32, -1 : i32, 0 : i32, 7 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, len=256, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %219 = emitc.call_opaque "__runtime_buffer_arg"(%210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %220 = emitc.cast %6 : i32 to i64
    %221 = emitc.call_opaque "__runtime_buffer_offset"(%219, %220) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %222 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %221) {args = [0 : index, 1 : index, 2 : index, 8 : i32, 256 : i32, -1 : i32, 0 : i32, 6 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, len=256, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %223 = emitc.call_opaque "__runtime_buffer_arg"(%210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %224 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %94, %223) {args = [0 : index, 1 : index, 2 : index, 7 : i32, 256 : i32, -1 : i32, 0 : i32, 5 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %94) {args = [0 : index, 1 : index, 1 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %225 = emitc.call_opaque "__Runtime_dma_createio_4"(%94, %224) {args = [0 : index, 1 : index, 1 : i32, 7 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %226 = emitc.call_opaque "__runtime_buffer_offset"(%210) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %227 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %228 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %15, %227) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 5 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 7 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %229 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %230 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %15, %229) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 5 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 7 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %231 = emitc.call_opaque "__Runtime_dma_createio_4"(%15, %230) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %232 = emitc.call_opaque "__runtime_buffer_offset"(%210) {args = [0 : index, 256]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %233 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %234 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %233) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 6 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %235 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %236 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %235) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 6 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %237 = emitc.call_opaque "__Runtime_dma_createio_4"(%42, %236) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %238 = emitc.call_opaque "__runtime_buffer_offset"(%210) {args = [0 : index, 512]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %239 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %240 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %239) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 7 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 9 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %241 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %242 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %241) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 7 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 9 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %243 = emitc.call_opaque "__Runtime_dma_createio_4"(%72, %242) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %244 = emitc.call_opaque "__runtime_buffer_offset"(%210) {args = [0 : index, 768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %245 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %246 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %102, %245) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 8 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 10 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %247 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %248 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %102, %247) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 8 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 10 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %249 = emitc.call_opaque "__Runtime_dma_createio_4"(%102, %248) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %250 = emitc.call_opaque "__Runtime_startio"(%arg0, %225) {args = [0 : index, 1 : index, 3 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %251 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %252 = emitc.call_opaque "__runtime_buffer_offset"(%251) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %253 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %21, %253) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %255 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %256 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %21, %255) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %257 = emitc.call_opaque "__Runtime_dma_createio_4"(%21, %256) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %258 = emitc.call_opaque "__runtime_buffer_offset"(%251) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %259 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %260 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %259) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %261 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %262 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %261) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %263 = emitc.call_opaque "__Runtime_dma_createio_4"(%49, %262) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %264 = emitc.call_opaque "__runtime_buffer_offset"(%251) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %265 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %266 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %265) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %267 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %268 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %267) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %269 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %268) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %270 = emitc.call_opaque "__runtime_buffer_offset"(%251) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %271 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %109, %271) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %273 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %274 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %109, %273) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %275 = emitc.call_opaque "__Runtime_dma_createio_4"(%109, %274) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=1, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%251) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %64, %437) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%64, %438) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 3 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %276 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 2048]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, len=256, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %277 = emitc.call_opaque "__runtime_buffer_arg"(%276) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %278 = emitc.cast %4 : i32 to i64
    %279 = emitc.call_opaque "__runtime_buffer_offset"(%277, %278) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %280 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %279) {args = [0 : index, 1 : index, 2 : index, 6 : i32, 256 : i32, -1 : i32, 0 : i32, 12 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %281 = emitc.call_opaque "__runtime_buffer_arg"(%276) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %282 = emitc.cast %5 : i32 to i64
    %283 = emitc.call_opaque "__runtime_buffer_offset"(%281, %282) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %284 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %283) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, -1 : i32, 0 : i32, 11 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %285 = emitc.call_opaque "__runtime_buffer_arg"(%276) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %286 = emitc.cast %6 : i32 to i64
    %287 = emitc.call_opaque "__runtime_buffer_offset"(%285, %286) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %288 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %287) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, -1 : i32, 0 : i32, 10 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=256, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %289 = emitc.call_opaque "__runtime_buffer_arg"(%276) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %289) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 256 : i32, -1 : i32, 0 : i32, 9 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %64) {args = [0 : index, 1 : index, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %291 = emitc.call_opaque "__Runtime_dma_createio_4"(%64, %290) {args = [0 : index, 1 : index, 0 : i32, 3 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %292 = emitc.call_opaque "__runtime_buffer_offset"(%276) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %293 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %294 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %21, %293) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 3 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %295 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %296 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %21, %295) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 3 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %297 = emitc.call_opaque "__Runtime_dma_createio_4"(%21, %296) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %298 = emitc.call_opaque "__runtime_buffer_offset"(%276) {args = [0 : index, 256]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %299 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %300 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %299) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %301 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %302 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %301) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %303 = emitc.call_opaque "__Runtime_dma_createio_4"(%49, %302) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %304 = emitc.call_opaque "__runtime_buffer_offset"(%276) {args = [0 : index, 512]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %305 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %306 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %305) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 5 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %307 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %308 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %307) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 5 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %309 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %308) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %310 = emitc.call_opaque "__runtime_buffer_offset"(%276) {args = [0 : index, 768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %311 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %312 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %109, %311) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 6 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %313 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %314 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %109, %313) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 6 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %315 = emitc.call_opaque "__Runtime_dma_createio_4"(%109, %314) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 4 for tile (2,0) */"
    %316 = emitc.call_opaque "__Runtime_startio"(%arg0, %291) {args = [0 : index, 1 : index, 4 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %317 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %318 = emitc.call_opaque "__runtime_buffer_offset"(%317) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %319 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %320 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %319) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %321 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %322 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %321) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %323 = emitc.call_opaque "__Runtime_dma_createio_4"(%27, %322) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %324 = emitc.call_opaque "__runtime_buffer_offset"(%317) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %325 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %326 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %325) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %327 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %328 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %327) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %329 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %328) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %330 = emitc.call_opaque "__runtime_buffer_offset"(%317) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %331 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %332 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %86, %331) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %333 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %334 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %86, %333) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %335 = emitc.call_opaque "__Runtime_dma_createio_4"(%86, %334) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %336 = emitc.call_opaque "__runtime_buffer_offset"(%317) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=128, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %337 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %338 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %116, %337) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 128 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=128, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %339 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %340 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %116, %339) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 128 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %341 = emitc.call_opaque "__Runtime_dma_createio_4"(%116, %340) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 4 for tile (3,0) */"
    emitc.for %arg4 = %2 to %1 step %0 {
      %433 = emitc.cast %arg4 : index to i32
      %434 = emitc.mul %433, %3 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=11, len=512, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %435 = emitc.call_opaque "__runtime_buffer_arg"(%317) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %436 = emitc.cast %434 : i32 to i64
      %437 = emitc.call_opaque "__runtime_buffer_offset"(%435, %436) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %438 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %94, %437) {args = [0 : index, 1 : index, 2 : index, 11 : i32, 512 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 4 : i32, 64 : i32, 8 : i32, 16 : i32, 4 : i32, 512 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
      %439 = emitc.call_opaque "__Runtime_dma_createio_4"(%94, %438) {args = [0 : index, 1 : index, 1 : i32, 11 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 5 for tile (3,0) */"
      %440 = emitc.call_opaque "__Runtime_startio"(%arg0, %439) {args = [0 : index, 1 : index, 5 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %440) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %342 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 3072]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, len=256, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %343 = emitc.call_opaque "__runtime_buffer_arg"(%342) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %344 = emitc.cast %4 : i32 to i64
    %345 = emitc.call_opaque "__runtime_buffer_offset"(%343, %344) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %346 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %345) {args = [0 : index, 1 : index, 2 : index, 11 : i32, 256 : i32, -1 : i32, 0 : i32, 16 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, len=256, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %347 = emitc.call_opaque "__runtime_buffer_arg"(%342) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %348 = emitc.cast %5 : i32 to i64
    %349 = emitc.call_opaque "__runtime_buffer_offset"(%347, %348) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %350 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %349) {args = [0 : index, 1 : index, 2 : index, 10 : i32, 256 : i32, -1 : i32, 0 : i32, 15 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, len=256, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %351 = emitc.call_opaque "__runtime_buffer_arg"(%342) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %352 = emitc.cast %6 : i32 to i64
    %353 = emitc.call_opaque "__runtime_buffer_offset"(%351, %352) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %354 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %353) {args = [0 : index, 1 : index, 2 : index, 9 : i32, 256 : i32, -1 : i32, 0 : i32, 14 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, len=256, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %355 = emitc.call_opaque "__runtime_buffer_arg"(%342) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %356 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %64, %355) {args = [0 : index, 1 : index, 2 : index, 8 : i32, 256 : i32, -1 : i32, 0 : i32, 13 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 3 : i32, 4 : i32, 1 : i32, 64 : i32, 8 : i32, 516 : i32, 2 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %64) {args = [0 : index, 1 : index, 1 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %357 = emitc.call_opaque "__Runtime_dma_createio_4"(%64, %356) {args = [0 : index, 1 : index, 1 : i32, 8 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %358 = emitc.call_opaque "__runtime_buffer_offset"(%342) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %359 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %360 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %359) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 13 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %361 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %362 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %361) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 13 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %363 = emitc.call_opaque "__Runtime_dma_createio_4"(%27, %362) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %364 = emitc.call_opaque "__runtime_buffer_offset"(%342) {args = [0 : index, 256]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %365 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %366 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %365) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 14 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 9 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %367 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %368 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %367) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 14 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 9 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %369 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %368) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %370 = emitc.call_opaque "__runtime_buffer_offset"(%342) {args = [0 : index, 512]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %371 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %372 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %86, %371) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 15 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 10 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %373 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %374 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %86, %373) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 15 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 10 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %375 = emitc.call_opaque "__Runtime_dma_createio_4"(%86, %374) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %376 = emitc.call_opaque "__runtime_buffer_offset"(%342) {args = [0 : index, 768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %377 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33536">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %378 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %116, %377) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 256 : i32, 4 : i32, 1 : i32, 16 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 11 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %379 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33280">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %380 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %116, %379) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 256 : i32, 5 : i32, 1 : i32, 16 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 11 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %381 = emitc.call_opaque "__Runtime_dma_createio_4"(%116, %380) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 5 for tile (2,0) */"
    %382 = emitc.call_opaque "__Runtime_startio"(%arg0, %357) {args = [0 : index, 1 : index, 5 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %383 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %9, %15, %21, %27, %35, %42, %49, %56, %65, %72, %79, %86, %95, %102, %109, %116) {args = [0 : index, 1 : index, 2 : index, 3 : index, 4 : index, 5 : index, 6 : index, 7 : index, 8 : index, 9 : index, 10 : index, 11 : index, 12 : index, 13 : index, 14 : index, 15 : index, 16 : index, 16 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %384 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %383) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %385 = emitc.call_opaque "__Runtime_startio"(%arg0, %14) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %386 = emitc.call_opaque "__Runtime_startio"(%arg0, %20) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %387 = emitc.call_opaque "__Runtime_startio"(%arg0, %26) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %388 = emitc.call_opaque "__Runtime_startio"(%arg0, %32) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %389 = emitc.call_opaque "__Runtime_startio"(%arg0, %41) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %390 = emitc.call_opaque "__Runtime_startio"(%arg0, %48) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %391 = emitc.call_opaque "__Runtime_startio"(%arg0, %55) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %392 = emitc.call_opaque "__Runtime_startio"(%arg0, %62) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %393 = emitc.call_opaque "__Runtime_startio"(%arg0, %71) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %394 = emitc.call_opaque "__Runtime_startio"(%arg0, %78) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %395 = emitc.call_opaque "__Runtime_startio"(%arg0, %85) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %396 = emitc.call_opaque "__Runtime_startio"(%arg0, %92) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %397 = emitc.call_opaque "__Runtime_startio"(%arg0, %101) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %398 = emitc.call_opaque "__Runtime_startio"(%arg0, %108) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %399 = emitc.call_opaque "__Runtime_startio"(%arg0, %115) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %400 = emitc.call_opaque "__Runtime_startio"(%arg0, %122) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %401 = emitc.call_opaque "__Runtime_startio"(%arg0, %128) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %402 = emitc.call_opaque "__Runtime_startio"(%arg0, %133) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %403 = emitc.call_opaque "__Runtime_startio"(%arg0, %138) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %404 = emitc.call_opaque "__Runtime_startio"(%arg0, %143) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %405 = emitc.call_opaque "__Runtime_startio"(%arg0, %165) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %406 = emitc.call_opaque "__Runtime_startio"(%arg0, %171) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %407 = emitc.call_opaque "__Runtime_startio"(%arg0, %177) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %408 = emitc.call_opaque "__Runtime_startio"(%arg0, %183) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %409 = emitc.call_opaque "__Runtime_startio"(%arg0, %191) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %410 = emitc.call_opaque "__Runtime_startio"(%arg0, %197) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %411 = emitc.call_opaque "__Runtime_startio"(%arg0, %203) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %412 = emitc.call_opaque "__Runtime_startio"(%arg0, %209) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %413 = emitc.call_opaque "__Runtime_startio"(%arg0, %231) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %414 = emitc.call_opaque "__Runtime_startio"(%arg0, %237) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %415 = emitc.call_opaque "__Runtime_startio"(%arg0, %243) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %416 = emitc.call_opaque "__Runtime_startio"(%arg0, %249) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %417 = emitc.call_opaque "__Runtime_startio"(%arg0, %257) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %418 = emitc.call_opaque "__Runtime_startio"(%arg0, %263) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %419 = emitc.call_opaque "__Runtime_startio"(%arg0, %269) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %420 = emitc.call_opaque "__Runtime_startio"(%arg0, %275) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %421 = emitc.call_opaque "__Runtime_startio"(%arg0, %297) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %422 = emitc.call_opaque "__Runtime_startio"(%arg0, %303) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %423 = emitc.call_opaque "__Runtime_startio"(%arg0, %309) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %424 = emitc.call_opaque "__Runtime_startio"(%arg0, %315) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %425 = emitc.call_opaque "__Runtime_startio"(%arg0, %323) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %426 = emitc.call_opaque "__Runtime_startio"(%arg0, %329) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %427 = emitc.call_opaque "__Runtime_startio"(%arg0, %335) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %428 = emitc.call_opaque "__Runtime_startio"(%arg0, %341) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %429 = emitc.call_opaque "__Runtime_startio"(%arg0, %363) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %430 = emitc.call_opaque "__Runtime_startio"(%arg0, %369) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %431 = emitc.call_opaque "__Runtime_startio"(%arg0, %375) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %432 = emitc.call_opaque "__Runtime_startio"(%arg0, %381) {args = [0 : index, 1 : index, 2 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 5 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %384) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %184) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %250) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %316) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %382) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.verbatim "/* AieRt debug snapshot */"
    emitc.verbatim "{"
    emitc.verbatim "  uint8_t _dbg_io_cols[] = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 0, 1, 2, 3, 0, 3, 0, 1, 2, 3, 0, 1, 2, 3, 1, 3, 0, 1, 2, 3, 0, 1, 2, 3, 2, 2, 0, 1, 2, 3, 0, 1, 2, 3, 3, 2, 0, 1, 2, 3};"
    emitc.verbatim "  uint8_t _dbg_io_rows[] = {3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 4, 4, 4, 4, 0, 0, 4, 4, 4, 4, 5, 5, 5, 5, 0, 0, 5, 5, 5, 5, 6, 6, 6, 6, 0, 0, 6, 6, 6, 6};"
    emitc.verbatim "  uint8_t _dbg_io_chs[] = {1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0};"
    emitc.verbatim "  uint8_t _dbg_io_bds[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 1, 2, 4, 4, 4, 4, 2, 2, 2, 2, 1, 7, 4, 4, 4, 4, 2, 2, 2, 2, 1, 3, 4, 4, 4, 4, 2, 2, 2, 2, 11, 8, 4, 4, 4, 4};"
    emitc.verbatim "  int _dbg_io_dirs[] = {DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S};"
    emitc.verbatim "  uint8_t _dbg_t_cols[] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3};"
    emitc.verbatim "  uint8_t _dbg_t_rows[] = {3, 4, 5, 6, 3, 4, 5, 6, 3, 4, 5, 6, 3, 4, 5, 6};"
    emitc.verbatim "  AieRt_DebugSnapshotFromCoords(dev,\0A      _dbg_io_cols, _dbg_io_rows, _dbg_io_chs, _dbg_io_bds, _dbg_io_dirs, 60,\0A      _dbg_t_cols, _dbg_t_rows, 16);"
    emitc.verbatim "}"
    emitc.return
  }
  emitc.func @dskernel_receiver(%arg0: index) attributes {specifiers = ["__global__"]} {
    emitc.verbatim "// the real kernel will be emitted separately\0A"
    emitc.return
  }
}
