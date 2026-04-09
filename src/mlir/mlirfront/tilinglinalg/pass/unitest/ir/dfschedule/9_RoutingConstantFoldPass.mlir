module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    emitc.call_opaque "host_canonicalized"() : () -> ()
    return
  }
  emitc.func @host_canonicalized(%arg0: !emitc.ptr<!emitc.opaque<"void">>, %arg1: !emitc.ptr<!emitc.opaque<"void">>, %arg2: !emitc.ptr<!emitc.opaque<"void">>) {
    %0 = emitc.call_opaque "__runtime_buffer_offset"(%arg0) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %2 = emitc.call_opaque "__runtime_buffer_arg"(%0) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %3 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %2) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 32 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %4 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %3) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %5 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %6 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %7 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %6) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %8 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %9 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %8) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,3), direction=S2MM */"
    %10 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %9) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %11 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %12 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %13 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %12) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %14 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %15 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %14) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,3), direction=S2MM */"
    %16 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %15) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %17 = emitc.call_opaque "__runtime_buffer_offset"(%arg0) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %18 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %19 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %18) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 32 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %20 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %19) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %21 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %22 = emitc.call_opaque "__runtime_buffer_offset"(%17) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %23 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %24 = emitc.call_opaque "__Runtime_dma_bd_config"(%21, %23) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %25 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %26 = emitc.call_opaque "__Runtime_dma_bd_config"(%21, %25) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,4), direction=S2MM */"
    %27 = emitc.call_opaque "__Runtime_dma_createio_4"(%21, %26) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %28 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %29 = emitc.call_opaque "__runtime_buffer_offset"(%17) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %30 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %31 = emitc.call_opaque "__Runtime_dma_bd_config"(%28, %30) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %32 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %33 = emitc.call_opaque "__Runtime_dma_bd_config"(%28, %32) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,4), direction=S2MM */"
    %34 = emitc.call_opaque "__Runtime_dma_createio_4"(%28, %33) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %35 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %36 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %37 = emitc.call_opaque "__runtime_buffer_arg"(%35) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %38 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %37) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 32 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %39 = emitc.call_opaque "__Runtime_dma_createio_4"(%36, %38) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %40 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %41 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %40) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 16 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %42 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %43 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %42) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 16 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,3), direction=S2MM */"
    %44 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %43) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %45 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %46 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %45) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 16 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %47 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %48 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %47) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 16 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,3), direction=S2MM */"
    %49 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %48) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %50 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"(%50) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %51) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 32 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(3,0), direction=MM2S */"
    %53 = emitc.call_opaque "__Runtime_dma_createio_4"(%36, %52) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %54 = emitc.call_opaque "__runtime_buffer_offset"(%50) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %55 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %56 = emitc.call_opaque "__Runtime_dma_bd_config"(%21, %55) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 16 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %57 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %58 = emitc.call_opaque "__Runtime_dma_bd_config"(%21, %57) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 16 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,4), direction=S2MM */"
    %59 = emitc.call_opaque "__Runtime_dma_createio_4"(%21, %58) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %60 = emitc.call_opaque "__runtime_buffer_offset"(%50) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %61 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32960">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %62 = emitc.call_opaque "__Runtime_dma_bd_config"(%28, %61) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 16 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %63 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %64 = emitc.call_opaque "__Runtime_dma_bd_config"(%28, %63) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 16 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,4), direction=S2MM */"
    %65 = emitc.call_opaque "__Runtime_dma_createio_4"(%28, %64) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %66 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %67 = emitc.call_opaque "__runtime_buffer_arg"(%66) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %68 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %67) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 32 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,0), direction=S2MM */"
    %69 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %68) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %70 = emitc.call_opaque "__runtime_buffer_offset"(%66) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %71 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33088">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %72 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %71) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 8 : i32, 4 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %73 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %74 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %73) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 8 : i32, 5 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %75 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %74) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %76 = emitc.call_opaque "__runtime_buffer_offset"(%66) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %77 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33088">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %78 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %77) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 8 : i32, 4 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %79 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %80 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %79) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 8 : i32, 5 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %81 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %80) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %82 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %83 = emitc.call_opaque "__runtime_buffer_arg"(%82) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %84 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %83) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 32 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(2,0), direction=S2MM */"
    %85 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %84) {args = [0 : index, 1 : index, 1 : i32, 3 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %86 = emitc.call_opaque "__runtime_buffer_offset"(%82) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %87 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33088">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %88 = emitc.call_opaque "__Runtime_dma_bd_config"(%21, %87) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 8 : i32, 4 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %89 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %90 = emitc.call_opaque "__Runtime_dma_bd_config"(%21, %89) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 8 : i32, 5 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %91 = emitc.call_opaque "__Runtime_dma_createio_4"(%21, %90) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %92 = emitc.call_opaque "__runtime_buffer_offset"(%82) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %93 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33088">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %94 = emitc.call_opaque "__Runtime_dma_bd_config"(%28, %93) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 8 : i32, 4 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %95 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)33024">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %96 = emitc.call_opaque "__Runtime_dma_bd_config"(%28, %95) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 8 : i32, 5 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %97 = emitc.call_opaque "__Runtime_dma_createio_4"(%28, %96) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    emitc.verbatim "/* Load Kernel Group: 4 tile(s) */"
    %98 = emitc.call_opaque "__Runtime_load_kernel_group_4t"(%5, %11, %21, %28) {args = [0 : index, 1 : index, 2 : index, 3 : index, 4 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %99 = emitc.call_opaque "__Runtime_launch_kernel_group"(%98) : (!emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %100 = emitc.call_opaque "__Runtime_startio"(%10) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %101 = emitc.call_opaque "__Runtime_startio"(%16) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %102 = emitc.call_opaque "__Runtime_startio"(%4) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %103 = emitc.call_opaque "__Runtime_startio"(%27) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %104 = emitc.call_opaque "__Runtime_startio"(%34) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %105 = emitc.call_opaque "__Runtime_startio"(%20) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %106 = emitc.call_opaque "__Runtime_startio"(%44) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %107 = emitc.call_opaque "__Runtime_startio"(%49) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %108 = emitc.call_opaque "__Runtime_startio"(%39) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %109 = emitc.call_opaque "__Runtime_startio"(%59) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %110 = emitc.call_opaque "__Runtime_startio"(%65) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %111 = emitc.call_opaque "__Runtime_startio"(%53) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %112 = emitc.call_opaque "__Runtime_startio"(%75) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %113 = emitc.call_opaque "__Runtime_startio"(%81) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %114 = emitc.call_opaque "__Runtime_startio"(%69) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %115 = emitc.call_opaque "__Runtime_startio"(%91) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %116 = emitc.call_opaque "__Runtime_startio"(%97) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %117 = emitc.call_opaque "__Runtime_startio"(%85) {args = [0 : index, 3 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 7 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%99) : (!emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%102) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%105) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%108) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%111) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%114) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%117) : (!emitc.opaque<"ioevent">) -> ()
    emitc.verbatim "/* AieRt debug snapshot */"
    emitc.verbatim "{"
    emitc.verbatim "  uint8_t _dbg_io_cols[] = {2, 0, 1, 2, 0, 1, 3, 0, 1, 3, 0, 1, 2, 0, 1, 2, 0, 1};"
    emitc.verbatim "  uint8_t _dbg_io_rows[] = {0, 3, 3, 0, 4, 4, 0, 3, 3, 0, 4, 4, 0, 3, 3, 0, 4, 4};"
    emitc.verbatim "  uint8_t _dbg_io_chs[] = {0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0};"
    emitc.verbatim "  uint8_t _dbg_io_bds[] = {0, 0, 0, 1, 0, 0, 0, 2, 2, 1, 2, 2, 2, 4, 4, 3, 4, 4};"
    emitc.verbatim "  int _dbg_io_dirs[] = {DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S};"
    emitc.verbatim "  uint8_t _dbg_t_cols[] = {0, 1, 0, 1};"
    emitc.verbatim "  uint8_t _dbg_t_rows[] = {3, 3, 4, 4};"
    emitc.verbatim "  AieRt_DebugSnapshotFromCoords(g_DevInst,\0A      _dbg_io_cols, _dbg_io_rows, _dbg_io_chs, _dbg_io_bds, _dbg_io_dirs, 18,\0A      _dbg_t_cols, _dbg_t_rows, 4);"
    emitc.verbatim "}"
    emitc.return
  }
  emitc.func @dskernel_receiver(%arg0: index) attributes {specifiers = ["__global__"]} {
    emitc.verbatim "// the real kernel will be emitted separately\0A"
    emitc.return
  }
}
