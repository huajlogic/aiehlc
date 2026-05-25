module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 1 : i32}} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<256x256xi8>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>) {
    emitc.call_opaque "host_canonicalized"() : () -> ()
    return
  }
  emitc.func @host_canonicalized(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: !emitc.ptr<!emitc.opaque<"void">>, %arg2: !emitc.ptr<!emitc.opaque<"void">>, %arg3: !emitc.ptr<!emitc.opaque<"void">>) {
    emitc.verbatim "XAie_DevInst* dev = v1;"
    %0 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %2 = emitc.call_opaque "__runtime_buffer_arg"(%0) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %3 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %1, %2) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,0), direction=MM2S */"
    %4 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %3) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %5 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %6 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %7 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %5, %6) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %8 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %9 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %5, %8) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %10 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %9) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %11 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %12 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %13 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %11, %12) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %14 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %15 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %11, %14) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %16 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %15) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %17 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %18 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %19 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %18) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %20 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %21 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %20) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %22 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %21) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %23 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %24 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %25 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %23, %24) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %26 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %27 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %23, %26) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %28 = emitc.call_opaque "__Runtime_dma_createio_4"(%23, %27) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,0) */"
    %29 = emitc.call_opaque "__Runtime_startio"(%arg0, %4) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %30 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %31 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %32 = emitc.call_opaque "__runtime_buffer_arg"(%30) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %33 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %31, %32) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,0), direction=MM2S */"
    %34 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %33) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %35 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %36 = emitc.call_opaque "__runtime_buffer_offset"(%30) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %37 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %38 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %37) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %39 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %40 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %39) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %41 = emitc.call_opaque "__Runtime_dma_createio_4"(%35, %40) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %42 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %43 = emitc.call_opaque "__runtime_buffer_offset"(%30) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %44 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %45 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %44) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %46 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %47 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %46) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %48 = emitc.call_opaque "__Runtime_dma_createio_4"(%42, %47) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %49 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %50 = emitc.call_opaque "__runtime_buffer_offset"(%30) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %51) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %53 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %54 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %53) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %55 = emitc.call_opaque "__Runtime_dma_createio_4"(%49, %54) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %56 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %57 = emitc.call_opaque "__runtime_buffer_offset"(%30) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %58 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %59 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %58) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %60 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %61 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %60) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %62 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %61) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,0) */"
    %63 = emitc.call_opaque "__Runtime_startio"(%arg0, %34) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %64 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %65 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %66 = emitc.call_opaque "__runtime_buffer_arg"(%64) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %67 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %66) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %68 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %67) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %69 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %70 = emitc.call_opaque "__runtime_buffer_offset"(%64) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %71 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %72 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %69, %71) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %73 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %74 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %69, %73) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %75 = emitc.call_opaque "__Runtime_dma_createio_4"(%69, %74) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %76 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %77 = emitc.call_opaque "__runtime_buffer_offset"(%64) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %78 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %79 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %76, %78) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %80 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %81 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %76, %80) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %82 = emitc.call_opaque "__Runtime_dma_createio_4"(%76, %81) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %83 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %84 = emitc.call_opaque "__runtime_buffer_offset"(%64) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %85 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %86 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %83, %85) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %87 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %88 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %83, %87) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %89 = emitc.call_opaque "__Runtime_dma_createio_4"(%83, %88) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %90 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %91 = emitc.call_opaque "__runtime_buffer_offset"(%64) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %92 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %93 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %90, %92) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %94 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %95 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %90, %94) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %96 = emitc.call_opaque "__Runtime_dma_createio_4"(%90, %95) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %97 = emitc.call_opaque "__Runtime_startio"(%arg0, %68) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %98 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %99 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %100 = emitc.call_opaque "__runtime_buffer_arg"(%98) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %101 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %99, %100) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %102 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %101) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %103 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %104 = emitc.call_opaque "__runtime_buffer_offset"(%98) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %105 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %106 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %103, %105) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %107 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %108 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %103, %107) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %109 = emitc.call_opaque "__Runtime_dma_createio_4"(%103, %108) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %110 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %111 = emitc.call_opaque "__runtime_buffer_offset"(%98) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %112 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %113 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %110, %112) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %114 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %115 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %110, %114) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %116 = emitc.call_opaque "__Runtime_dma_createio_4"(%110, %115) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %117 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %118 = emitc.call_opaque "__runtime_buffer_offset"(%98) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %119 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %120 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %117, %119) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %121 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %122 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %117, %121) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %123 = emitc.call_opaque "__Runtime_dma_createio_4"(%117, %122) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %124 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %125 = emitc.call_opaque "__runtime_buffer_offset"(%98) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %126 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)36864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %127 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %124, %126) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 4096 : i32, 0 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %128 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %129 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %124, %128) {args = [0 : index, 1 : index, 2 : index, 0 : i32, 4096 : i32, 1 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %130 = emitc.call_opaque "__Runtime_dma_createio_4"(%124, %129) {args = [0 : index, 1 : index, 1 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %131 = emitc.call_opaque "__Runtime_startio"(%arg0, %102) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %132 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %133 = emitc.call_opaque "__runtime_buffer_arg"(%132) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %134 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %1, %133) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
    %135 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %134) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %136 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %137 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %5, %136) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %138 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %139 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %5, %138) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %140 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %139) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %141 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %142 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %141) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %143 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %144 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %143) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %145 = emitc.call_opaque "__Runtime_dma_createio_4"(%35, %144) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %146 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %147 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %69, %146) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %148 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %149 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %69, %148) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %150 = emitc.call_opaque "__Runtime_dma_createio_4"(%69, %149) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %151 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %152 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %103, %151) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %153 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %154 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %103, %153) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %155 = emitc.call_opaque "__Runtime_dma_createio_4"(%103, %154) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,0) */"
    %156 = emitc.call_opaque "__Runtime_startio"(%arg0, %135) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %157 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=192, len=4096, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %158 = emitc.call_opaque "__runtime_buffer_arg"(%157) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %159 = emitc.call_opaque "__runtime_buffer_offset"(%158) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %160 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %159) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 4096 : i32, -1 : i32, 0 : i32, 4 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=128, len=4096, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %161 = emitc.call_opaque "__runtime_buffer_arg"(%157) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %162 = emitc.call_opaque "__runtime_buffer_offset"(%161) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %163 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %162) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 0 : i32, 3 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=64, len=4096, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %164 = emitc.call_opaque "__runtime_buffer_arg"(%157) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %165 = emitc.call_opaque "__runtime_buffer_offset"(%164) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %166 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %165) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, -1 : i32, 0 : i32, 2 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %167 = emitc.call_opaque "__runtime_buffer_arg"(%157) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %168 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %167) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, -1 : i32, 0 : i32, 1 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %99) {args = [0 : index, 1 : index, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %169 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %168) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %170 = emitc.call_opaque "__runtime_buffer_offset"(%157) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=1, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %171 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %172 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %5, %171) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 1 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 2 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %173 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %172) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %174 = emitc.call_opaque "__runtime_buffer_offset"(%157) {args = [0 : index, 4096]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=2, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %175 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %176 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %35, %175) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 2 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 3 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %177 = emitc.call_opaque "__Runtime_dma_createio_4"(%35, %176) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %178 = emitc.call_opaque "__runtime_buffer_offset"(%157) {args = [0 : index, 8192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=3, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %179 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %180 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %69, %179) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 3 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %181 = emitc.call_opaque "__Runtime_dma_createio_4"(%69, %180) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %182 = emitc.call_opaque "__runtime_buffer_offset"(%157) {args = [0 : index, 12288]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=4, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %183 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %184 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %103, %183) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 4 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 5 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %185 = emitc.call_opaque "__Runtime_dma_createio_4"(%103, %184) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %186 = emitc.call_opaque "__Runtime_startio"(%arg0, %169) {args = [0 : index, 1 : index, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %187 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %188 = emitc.call_opaque "__runtime_buffer_arg"(%187) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %189 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %31, %188) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
    %190 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %189) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %191 = emitc.call_opaque "__runtime_buffer_offset"(%187) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %192 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %193 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %11, %192) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %194 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %195 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %11, %194) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %196 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %195) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %197 = emitc.call_opaque "__runtime_buffer_offset"(%187) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %198 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %199 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %198) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %200 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %201 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %200) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %202 = emitc.call_opaque "__Runtime_dma_createio_4"(%42, %201) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %203 = emitc.call_opaque "__runtime_buffer_offset"(%187) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %204 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %205 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %76, %204) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %206 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %207 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %76, %206) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %208 = emitc.call_opaque "__Runtime_dma_createio_4"(%76, %207) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %209 = emitc.call_opaque "__runtime_buffer_offset"(%187) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %210 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %211 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %110, %210) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %212 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %213 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %110, %212) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %214 = emitc.call_opaque "__Runtime_dma_createio_4"(%110, %213) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
    %215 = emitc.call_opaque "__Runtime_startio"(%arg0, %190) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %216 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 16384]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=192, len=4096, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %217 = emitc.call_opaque "__runtime_buffer_arg"(%216) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %218 = emitc.call_opaque "__runtime_buffer_offset"(%217) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %219 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %218) {args = [0 : index, 1 : index, 2 : index, 10 : i32, 4096 : i32, -1 : i32, 0 : i32, 8 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=128, len=4096, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %220 = emitc.call_opaque "__runtime_buffer_arg"(%216) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %221 = emitc.call_opaque "__runtime_buffer_offset"(%220) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %222 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %221) {args = [0 : index, 1 : index, 2 : index, 9 : i32, 4096 : i32, -1 : i32, 0 : i32, 7 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=64, len=4096, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %223 = emitc.call_opaque "__runtime_buffer_arg"(%216) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %224 = emitc.call_opaque "__runtime_buffer_offset"(%223) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %225 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %224) {args = [0 : index, 1 : index, 2 : index, 8 : i32, 4096 : i32, -1 : i32, 0 : i32, 6 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, offset=0, len=4096, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %226 = emitc.call_opaque "__runtime_buffer_arg"(%216) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %227 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %99, %226) {args = [0 : index, 1 : index, 2 : index, 7 : i32, 4096 : i32, -1 : i32, 0 : i32, 5 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %99) {args = [0 : index, 1 : index, 1 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %228 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %227) {args = [0 : index, 1 : index, 1 : i32, 7 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %229 = emitc.call_opaque "__runtime_buffer_offset"(%216) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=5, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %230 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %231 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %11, %230) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 5 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 7 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %232 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %231) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %233 = emitc.call_opaque "__runtime_buffer_offset"(%216) {args = [0 : index, 4096]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=6, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %234 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %235 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %42, %234) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 6 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %236 = emitc.call_opaque "__Runtime_dma_createio_4"(%42, %235) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %237 = emitc.call_opaque "__runtime_buffer_offset"(%216) {args = [0 : index, 8192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=7, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %238 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %239 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %76, %238) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 7 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 9 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %240 = emitc.call_opaque "__Runtime_dma_createio_4"(%76, %239) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %241 = emitc.call_opaque "__runtime_buffer_offset"(%216) {args = [0 : index, 12288]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=8, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %242 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %243 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %110, %242) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 8 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 10 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %244 = emitc.call_opaque "__Runtime_dma_createio_4"(%110, %243) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %245 = emitc.call_opaque "__Runtime_startio"(%arg0, %228) {args = [0 : index, 1 : index, 2 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %246 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %247 = emitc.call_opaque "__runtime_buffer_arg"(%246) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %248 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %65, %247) {args = [0 : index, 1 : index, 2 : index, 1 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %249 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %248) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %250 = emitc.call_opaque "__runtime_buffer_offset"(%246) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %251 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %252 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %251) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %253 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %253) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %255 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %254) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %256 = emitc.call_opaque "__runtime_buffer_offset"(%246) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %257 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %258 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %257) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %259 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %260 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %259) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %261 = emitc.call_opaque "__Runtime_dma_createio_4"(%49, %260) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %262 = emitc.call_opaque "__runtime_buffer_offset"(%246) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %263 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %264 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %83, %263) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %265 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %266 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %83, %265) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %267 = emitc.call_opaque "__Runtime_dma_createio_4"(%83, %266) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %268 = emitc.call_opaque "__runtime_buffer_offset"(%246) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %269 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %270 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %117, %269) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %271 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %117, %271) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %273 = emitc.call_opaque "__Runtime_dma_createio_4"(%117, %272) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %274 = emitc.call_opaque "__Runtime_startio"(%arg0, %249) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %275 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 32768]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, offset=192, len=4096, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %276 = emitc.call_opaque "__runtime_buffer_arg"(%275) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %277 = emitc.call_opaque "__runtime_buffer_offset"(%276) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %278 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %277) {args = [0 : index, 1 : index, 2 : index, 6 : i32, 4096 : i32, -1 : i32, 0 : i32, 12 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=128, len=4096, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %279 = emitc.call_opaque "__runtime_buffer_arg"(%275) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %280 = emitc.call_opaque "__runtime_buffer_offset"(%279) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %281 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %280) {args = [0 : index, 1 : index, 2 : index, 5 : i32, 4096 : i32, -1 : i32, 0 : i32, 11 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=64, len=4096, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %282 = emitc.call_opaque "__runtime_buffer_arg"(%275) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %283 = emitc.call_opaque "__runtime_buffer_offset"(%282) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %284 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %283) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 0 : i32, 10 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %285 = emitc.call_opaque "__runtime_buffer_arg"(%275) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %286 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %285) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, -1 : i32, 0 : i32, 9 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %65) {args = [0 : index, 1 : index, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %287 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %286) {args = [0 : index, 1 : index, 0 : i32, 3 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %288 = emitc.call_opaque "__runtime_buffer_offset"(%275) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=9, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %289 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %289) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 3 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %291 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %290) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %292 = emitc.call_opaque "__runtime_buffer_offset"(%275) {args = [0 : index, 4096]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=10, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %293 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %294 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %49, %293) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 4 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %295 = emitc.call_opaque "__Runtime_dma_createio_4"(%49, %294) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %296 = emitc.call_opaque "__runtime_buffer_offset"(%275) {args = [0 : index, 8192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=11, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %297 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %298 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %83, %297) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 5 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %299 = emitc.call_opaque "__Runtime_dma_createio_4"(%83, %298) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %300 = emitc.call_opaque "__runtime_buffer_offset"(%275) {args = [0 : index, 12288]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=12, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %301 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %302 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %117, %301) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 6 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %303 = emitc.call_opaque "__Runtime_dma_createio_4"(%117, %302) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %304 = emitc.call_opaque "__Runtime_startio"(%arg0, %287) {args = [0 : index, 1 : index, 2 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %305 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %306 = emitc.call_opaque "__runtime_buffer_arg"(%305) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %307 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %99, %306) {args = [0 : index, 1 : index, 2 : index, 11 : i32, 16384 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
    %308 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %307) {args = [0 : index, 1 : index, 1 : i32, 11 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %309 = emitc.call_opaque "__runtime_buffer_offset"(%305) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %310 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %311 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %23, %310) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %312 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %313 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %23, %312) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %314 = emitc.call_opaque "__Runtime_dma_createio_4"(%23, %313) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %315 = emitc.call_opaque "__runtime_buffer_offset"(%305) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %316 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %317 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %316) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %318 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %319 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %318) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %320 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %319) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %321 = emitc.call_opaque "__runtime_buffer_offset"(%305) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %322 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %323 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %90, %322) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %324 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %325 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %90, %324) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %326 = emitc.call_opaque "__Runtime_dma_createio_4"(%90, %325) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %327 = emitc.call_opaque "__runtime_buffer_offset"(%305) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %328 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)45056">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %329 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %124, %328) {args = [0 : index, 1 : index, 2 : index, 3 : i32, 4096 : i32, 2 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %330 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)40960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %331 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %124, %330) {args = [0 : index, 1 : index, 2 : index, 2 : i32, 4096 : i32, 3 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32, -1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %332 = emitc.call_opaque "__Runtime_dma_createio_4"(%124, %331) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %333 = emitc.call_opaque "__Runtime_startio"(%arg0, %308) {args = [0 : index, 1 : index, 3 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %334 = emitc.call_opaque "__runtime_buffer_offset"(%arg3) {args = [0 : index, 49152]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=192, len=4096, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %335 = emitc.call_opaque "__runtime_buffer_arg"(%334) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %336 = emitc.call_opaque "__runtime_buffer_offset"(%335) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %337 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %336) {args = [0 : index, 1 : index, 2 : index, 11 : i32, 4096 : i32, -1 : i32, 0 : i32, 16 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=128, len=4096, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %338 = emitc.call_opaque "__runtime_buffer_arg"(%334) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %339 = emitc.call_opaque "__runtime_buffer_offset"(%338) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %340 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %339) {args = [0 : index, 1 : index, 2 : index, 10 : i32, 4096 : i32, -1 : i32, 0 : i32, 15 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=64, len=4096, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %341 = emitc.call_opaque "__runtime_buffer_arg"(%334) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %342 = emitc.call_opaque "__runtime_buffer_offset"(%341) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %343 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %342) {args = [0 : index, 1 : index, 2 : index, 9 : i32, 4096 : i32, -1 : i32, 0 : i32, 14 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=0, len=4096, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %344 = emitc.call_opaque "__runtime_buffer_arg"(%334) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %345 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %65, %344) {args = [0 : index, 1 : index, 2 : index, 8 : i32, 4096 : i32, -1 : i32, 0 : i32, 13 : i32, -1 : i32, 0 : i32, -1 : i32, 0 : i32, -1 : i32, 2 : i32, 4 : i32, 16 : i32, 256 : i32, 64 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %65) {args = [0 : index, 1 : index, 1 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">) -> ()
    %346 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %345) {args = [0 : index, 1 : index, 1 : i32, 8 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %347 = emitc.call_opaque "__runtime_buffer_offset"(%334) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=13, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %348 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %349 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %23, %348) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 13 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %350 = emitc.call_opaque "__Runtime_dma_createio_4"(%23, %349) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %351 = emitc.call_opaque "__runtime_buffer_offset"(%334) {args = [0 : index, 4096]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=14, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %352 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %353 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %56, %352) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 14 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 9 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %354 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %353) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %355 = emitc.call_opaque "__runtime_buffer_offset"(%334) {args = [0 : index, 8192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=15, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %356 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %357 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %90, %356) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 15 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 10 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %358 = emitc.call_opaque "__Runtime_dma_createio_4"(%90, %357) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %359 = emitc.call_opaque "__runtime_buffer_offset"(%334) {args = [0 : index, 12288]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=16, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %360 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)49152">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %361 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %124, %360) {args = [0 : index, 1 : index, 2 : index, 4 : i32, 4096 : i32, -1 : i32, 1 : i32, 16 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32, 11 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 1));"
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %362 = emitc.call_opaque "__Runtime_dma_createio_4"(%124, %361) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %363 = emitc.call_opaque "__Runtime_startio"(%arg0, %346) {args = [0 : index, 1 : index, 3 : i32, 8 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %364 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %5, %11, %17, %23, %35, %42, %49, %56, %69, %76, %83, %90, %103, %110, %117, %124) {args = [0 : index, 1 : index, 2 : index, 3 : index, 4 : index, 5 : index, 6 : index, 7 : index, 8 : index, 9 : index, 10 : index, 11 : index, 12 : index, 13 : index, 14 : index, 15 : index, 16 : index, 16 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %365 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %364) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %366 = emitc.call_opaque "__Runtime_startio"(%arg0, %10) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %367 = emitc.call_opaque "__Runtime_startio"(%arg0, %16) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %368 = emitc.call_opaque "__Runtime_startio"(%arg0, %22) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %369 = emitc.call_opaque "__Runtime_startio"(%arg0, %28) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %370 = emitc.call_opaque "__Runtime_startio"(%arg0, %41) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %371 = emitc.call_opaque "__Runtime_startio"(%arg0, %48) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %372 = emitc.call_opaque "__Runtime_startio"(%arg0, %55) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %373 = emitc.call_opaque "__Runtime_startio"(%arg0, %62) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %374 = emitc.call_opaque "__Runtime_startio"(%arg0, %75) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %375 = emitc.call_opaque "__Runtime_startio"(%arg0, %82) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %376 = emitc.call_opaque "__Runtime_startio"(%arg0, %89) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %377 = emitc.call_opaque "__Runtime_startio"(%arg0, %96) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %378 = emitc.call_opaque "__Runtime_startio"(%arg0, %109) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %379 = emitc.call_opaque "__Runtime_startio"(%arg0, %116) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %380 = emitc.call_opaque "__Runtime_startio"(%arg0, %123) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %381 = emitc.call_opaque "__Runtime_startio"(%arg0, %130) {args = [0 : index, 1 : index, 0 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %382 = emitc.call_opaque "__Runtime_startio"(%arg0, %140) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %383 = emitc.call_opaque "__Runtime_startio"(%arg0, %145) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %384 = emitc.call_opaque "__Runtime_startio"(%arg0, %150) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %385 = emitc.call_opaque "__Runtime_startio"(%arg0, %155) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %386 = emitc.call_opaque "__Runtime_startio"(%arg0, %173) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %387 = emitc.call_opaque "__Runtime_startio"(%arg0, %177) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %388 = emitc.call_opaque "__Runtime_startio"(%arg0, %181) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %389 = emitc.call_opaque "__Runtime_startio"(%arg0, %185) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %390 = emitc.call_opaque "__Runtime_startio"(%arg0, %196) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %391 = emitc.call_opaque "__Runtime_startio"(%arg0, %202) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %392 = emitc.call_opaque "__Runtime_startio"(%arg0, %208) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %393 = emitc.call_opaque "__Runtime_startio"(%arg0, %214) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %394 = emitc.call_opaque "__Runtime_startio"(%arg0, %232) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %395 = emitc.call_opaque "__Runtime_startio"(%arg0, %236) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %396 = emitc.call_opaque "__Runtime_startio"(%arg0, %240) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %397 = emitc.call_opaque "__Runtime_startio"(%arg0, %244) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %398 = emitc.call_opaque "__Runtime_startio"(%arg0, %255) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %399 = emitc.call_opaque "__Runtime_startio"(%arg0, %261) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %400 = emitc.call_opaque "__Runtime_startio"(%arg0, %267) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %401 = emitc.call_opaque "__Runtime_startio"(%arg0, %273) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %402 = emitc.call_opaque "__Runtime_startio"(%arg0, %291) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %403 = emitc.call_opaque "__Runtime_startio"(%arg0, %295) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %404 = emitc.call_opaque "__Runtime_startio"(%arg0, %299) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %405 = emitc.call_opaque "__Runtime_startio"(%arg0, %303) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %406 = emitc.call_opaque "__Runtime_startio"(%arg0, %314) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %407 = emitc.call_opaque "__Runtime_startio"(%arg0, %320) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %408 = emitc.call_opaque "__Runtime_startio"(%arg0, %326) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %409 = emitc.call_opaque "__Runtime_startio"(%arg0, %332) {args = [0 : index, 1 : index, 1 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %410 = emitc.call_opaque "__Runtime_startio"(%arg0, %350) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %411 = emitc.call_opaque "__Runtime_startio"(%arg0, %354) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %412 = emitc.call_opaque "__Runtime_startio"(%arg0, %358) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %413 = emitc.call_opaque "__Runtime_startio"(%arg0, %362) {args = [0 : index, 1 : index, 2 : i32, 1 : i32]} : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %365) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %29) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %63) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %97) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %131) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %156) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %186) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %215) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %245) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %274) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %304) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %333) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %363) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.verbatim "/* AieRt debug snapshot */"
    emitc.verbatim "{"
    emitc.verbatim "  uint8_t _dbg_io_cols[] = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 0, 0, 1, 2, 3, 3, 0, 1, 2, 3, 1, 0, 1, 2, 3, 3, 0, 1, 2, 3, 2, 0, 1, 2, 3, 2, 0, 1, 2, 3, 3, 0, 1, 2, 3, 2, 0, 1, 2, 3};"
    emitc.verbatim "  uint8_t _dbg_io_rows[] = {0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 3, 3, 3, 0, 3, 3, 3, 3, 0, 4, 4, 4, 4, 0, 4, 4, 4, 4, 0, 5, 5, 5, 5, 0, 5, 5, 5, 5, 0, 6, 6, 6, 6, 0, 6, 6, 6, 6};"
    emitc.verbatim "  uint8_t _dbg_io_chs[] = {0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0};"
    emitc.verbatim "  uint8_t _dbg_io_bds[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 4, 4, 4, 4, 1, 2, 2, 2, 2, 7, 4, 4, 4, 4, 1, 2, 2, 2, 2, 3, 4, 4, 4, 4, 11, 2, 2, 2, 2, 8, 4, 4, 4, 4};"
    emitc.verbatim "  int _dbg_io_dirs[] = {DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S};"
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
