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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %2 = emitc.call_opaque "__runtime_buffer_arg"(%0) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %3 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %2) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %4 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %3) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %5 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %6 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %7 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %6) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %8 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %9 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %8) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,3), direction=S2MM */"
    %10 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %9) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %11 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %12 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %13 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %12) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %14 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %15 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %14) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,3), direction=S2MM */"
    %16 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %15) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %17 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %18 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %19 = emitc.call_opaque "__Runtime_dma_bd_config"(%17, %18) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %20 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %21 = emitc.call_opaque "__Runtime_dma_bd_config"(%17, %20) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,3), direction=S2MM */"
    %22 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %21) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %23 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 3 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %24 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %25 = emitc.call_opaque "__Runtime_dma_bd_config"(%23, %24) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %26 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %27 = emitc.call_opaque "__Runtime_dma_bd_config"(%23, %26) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,3), direction=S2MM */"
    %28 = emitc.call_opaque "__Runtime_dma_createio_4"(%23, %27) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %29 = emitc.call_opaque "__runtime_buffer_offset"(%arg0) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %30 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %31 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %30) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %32 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %31) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %33 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %34 = emitc.call_opaque "__runtime_buffer_offset"(%29) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %35 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %36 = emitc.call_opaque "__Runtime_dma_bd_config"(%33, %35) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %37 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %38 = emitc.call_opaque "__Runtime_dma_bd_config"(%33, %37) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,4), direction=S2MM */"
    %39 = emitc.call_opaque "__Runtime_dma_createio_4"(%33, %38) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %40 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %41 = emitc.call_opaque "__runtime_buffer_offset"(%29) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %42 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %43 = emitc.call_opaque "__Runtime_dma_bd_config"(%40, %42) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %44 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %45 = emitc.call_opaque "__Runtime_dma_bd_config"(%40, %44) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,4), direction=S2MM */"
    %46 = emitc.call_opaque "__Runtime_dma_createio_4"(%40, %45) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %47 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %48 = emitc.call_opaque "__runtime_buffer_offset"(%29) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %49 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %50 = emitc.call_opaque "__Runtime_dma_bd_config"(%47, %49) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config"(%47, %51) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,4), direction=S2MM */"
    %53 = emitc.call_opaque "__Runtime_dma_createio_4"(%47, %52) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %54 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 4 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %55 = emitc.call_opaque "__runtime_buffer_offset"(%29) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %56 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %57 = emitc.call_opaque "__Runtime_dma_bd_config"(%54, %56) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %58 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %59 = emitc.call_opaque "__Runtime_dma_bd_config"(%54, %58) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,4), direction=S2MM */"
    %60 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %59) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %61 = emitc.call_opaque "__runtime_buffer_offset"(%arg0) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %62 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %63 = emitc.call_opaque "__runtime_buffer_arg"(%61) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %64 = emitc.call_opaque "__Runtime_dma_bd_config"(%62, %63) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %65 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %64) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %66 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %67 = emitc.call_opaque "__runtime_buffer_offset"(%61) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %68 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %69 = emitc.call_opaque "__Runtime_dma_bd_config"(%66, %68) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %70 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %71 = emitc.call_opaque "__Runtime_dma_bd_config"(%66, %70) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,5), direction=S2MM */"
    %72 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %71) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %73 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %74 = emitc.call_opaque "__runtime_buffer_offset"(%61) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %75 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %76 = emitc.call_opaque "__Runtime_dma_bd_config"(%73, %75) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %77 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %78 = emitc.call_opaque "__Runtime_dma_bd_config"(%73, %77) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,5), direction=S2MM */"
    %79 = emitc.call_opaque "__Runtime_dma_createio_4"(%73, %78) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %80 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %81 = emitc.call_opaque "__runtime_buffer_offset"(%61) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %82 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %83 = emitc.call_opaque "__Runtime_dma_bd_config"(%80, %82) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %84 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %85 = emitc.call_opaque "__Runtime_dma_bd_config"(%80, %84) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,5), direction=S2MM */"
    %86 = emitc.call_opaque "__Runtime_dma_createio_4"(%80, %85) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %87 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 5 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %88 = emitc.call_opaque "__runtime_buffer_offset"(%61) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %89 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %90 = emitc.call_opaque "__Runtime_dma_bd_config"(%87, %89) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %91 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %92 = emitc.call_opaque "__Runtime_dma_bd_config"(%87, %91) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,5), direction=S2MM */"
    %93 = emitc.call_opaque "__Runtime_dma_createio_4"(%87, %92) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %94 = emitc.call_opaque "__runtime_buffer_offset"(%arg0) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %95 = emitc.call_opaque "__runtime_buffer_arg"(%94) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %96 = emitc.call_opaque "__Runtime_dma_bd_config"(%62, %95) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(3,0), direction=MM2S */"
    %97 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %96) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %98 = emitc.call_opaque "XAie_TileLoc"() {args = [0 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %99 = emitc.call_opaque "__runtime_buffer_offset"(%94) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %100 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %101 = emitc.call_opaque "__Runtime_dma_bd_config"(%98, %100) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %102 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %103 = emitc.call_opaque "__Runtime_dma_bd_config"(%98, %102) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,6), direction=S2MM */"
    %104 = emitc.call_opaque "__Runtime_dma_createio_4"(%98, %103) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    %105 = emitc.call_opaque "XAie_TileLoc"() {args = [1 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %106 = emitc.call_opaque "__runtime_buffer_offset"(%94) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %107 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %108 = emitc.call_opaque "__Runtime_dma_bd_config"(%105, %107) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %109 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %110 = emitc.call_opaque "__Runtime_dma_bd_config"(%105, %109) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,6), direction=S2MM */"
    %111 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %110) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    %112 = emitc.call_opaque "XAie_TileLoc"() {args = [2 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %113 = emitc.call_opaque "__runtime_buffer_offset"(%94) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %114 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %115 = emitc.call_opaque "__Runtime_dma_bd_config"(%112, %114) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %116 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %117 = emitc.call_opaque "__Runtime_dma_bd_config"(%112, %116) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,6), direction=S2MM */"
    %118 = emitc.call_opaque "__Runtime_dma_createio_4"(%112, %117) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    %119 = emitc.call_opaque "XAie_TileLoc"() {args = [3 : i8, 6 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    %120 = emitc.call_opaque "__runtime_buffer_offset"(%94) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %121 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32800">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %122 = emitc.call_opaque "__Runtime_dma_bd_config"(%119, %121) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 8 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %123 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32768">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %124 = emitc.call_opaque "__Runtime_dma_bd_config"(%119, %123) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 8 : i32, 1 : i32, 0 : i32, 0 : i32, 0 : i32, -1 : i32, 1 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,6), direction=S2MM */"
    %125 = emitc.call_opaque "__Runtime_dma_createio_4"(%119, %124) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %126 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %127 = emitc.call_opaque "XAie_TileLoc"() {args = [6 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %128 = emitc.call_opaque "__runtime_buffer_arg"(%126) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %129 = emitc.call_opaque "__Runtime_dma_bd_config"(%127, %128) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(6,0), direction=MM2S */"
    %130 = emitc.call_opaque "__Runtime_dma_createio_4"(%127, %129) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %131 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %132 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %131) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %133 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %134 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %133) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,3), direction=S2MM */"
    %135 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %134) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %136 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %137 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %136) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %138 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %139 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %138) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,3), direction=S2MM */"
    %140 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %139) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %141 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %142 = emitc.call_opaque "__Runtime_dma_bd_config"(%17, %141) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %143 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %144 = emitc.call_opaque "__Runtime_dma_bd_config"(%17, %143) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,3), direction=S2MM */"
    %145 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %144) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %146 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %147 = emitc.call_opaque "__Runtime_dma_bd_config"(%23, %146) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %148 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %149 = emitc.call_opaque "__Runtime_dma_bd_config"(%23, %148) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,3), direction=S2MM */"
    %150 = emitc.call_opaque "__Runtime_dma_createio_4"(%23, %149) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (6,0) */"
    %151 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %152 = emitc.call_opaque "__runtime_buffer_arg"(%151) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %153 = emitc.call_opaque "__Runtime_dma_bd_config"(%127, %152) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(6,0), direction=MM2S */"
    %154 = emitc.call_opaque "__Runtime_dma_createio_4"(%127, %153) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %155 = emitc.call_opaque "__runtime_buffer_offset"(%151) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %156 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %157 = emitc.call_opaque "__Runtime_dma_bd_config"(%33, %156) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %158 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %159 = emitc.call_opaque "__Runtime_dma_bd_config"(%33, %158) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,4), direction=S2MM */"
    %160 = emitc.call_opaque "__Runtime_dma_createio_4"(%33, %159) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %161 = emitc.call_opaque "__runtime_buffer_offset"(%151) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %162 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %163 = emitc.call_opaque "__Runtime_dma_bd_config"(%40, %162) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %164 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %165 = emitc.call_opaque "__Runtime_dma_bd_config"(%40, %164) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,4), direction=S2MM */"
    %166 = emitc.call_opaque "__Runtime_dma_createio_4"(%40, %165) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %167 = emitc.call_opaque "__runtime_buffer_offset"(%151) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %168 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %169 = emitc.call_opaque "__Runtime_dma_bd_config"(%47, %168) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %170 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %171 = emitc.call_opaque "__Runtime_dma_bd_config"(%47, %170) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,4), direction=S2MM */"
    %172 = emitc.call_opaque "__Runtime_dma_createio_4"(%47, %171) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %173 = emitc.call_opaque "__runtime_buffer_offset"(%151) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %174 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %175 = emitc.call_opaque "__Runtime_dma_bd_config"(%54, %174) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %176 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %177 = emitc.call_opaque "__Runtime_dma_bd_config"(%54, %176) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,4), direction=S2MM */"
    %178 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %177) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (6,0) */"
    %179 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %180 = emitc.call_opaque "XAie_TileLoc"() {args = [7 : i8, 0 : i8]} : () -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %181 = emitc.call_opaque "__runtime_buffer_arg"(%179) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %182 = emitc.call_opaque "__Runtime_dma_bd_config"(%180, %181) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 0 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(7,0), direction=MM2S */"
    %183 = emitc.call_opaque "__Runtime_dma_createio_4"(%180, %182) {args = [0 : index, 1 : index, 0 : i32, 0 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %184 = emitc.call_opaque "__runtime_buffer_offset"(%179) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %185 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %186 = emitc.call_opaque "__Runtime_dma_bd_config"(%66, %185) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %187 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %188 = emitc.call_opaque "__Runtime_dma_bd_config"(%66, %187) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,5), direction=S2MM */"
    %189 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %188) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %190 = emitc.call_opaque "__runtime_buffer_offset"(%179) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %191 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %192 = emitc.call_opaque "__Runtime_dma_bd_config"(%73, %191) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %193 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %194 = emitc.call_opaque "__Runtime_dma_bd_config"(%73, %193) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,5), direction=S2MM */"
    %195 = emitc.call_opaque "__Runtime_dma_createio_4"(%73, %194) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %196 = emitc.call_opaque "__runtime_buffer_offset"(%179) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %197 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %198 = emitc.call_opaque "__Runtime_dma_bd_config"(%80, %197) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %199 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %200 = emitc.call_opaque "__Runtime_dma_bd_config"(%80, %199) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,5), direction=S2MM */"
    %201 = emitc.call_opaque "__Runtime_dma_createio_4"(%80, %200) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %202 = emitc.call_opaque "__runtime_buffer_offset"(%179) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %203 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %204 = emitc.call_opaque "__Runtime_dma_bd_config"(%87, %203) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %205 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %206 = emitc.call_opaque "__Runtime_dma_bd_config"(%87, %205) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,5), direction=S2MM */"
    %207 = emitc.call_opaque "__Runtime_dma_createio_4"(%87, %206) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (7,0) */"
    %208 = emitc.call_opaque "__runtime_buffer_offset"(%arg1) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %209 = emitc.call_opaque "__runtime_buffer_arg"(%208) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %210 = emitc.call_opaque "__Runtime_dma_bd_config"(%180, %209) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 1 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(7,0), direction=MM2S */"
    %211 = emitc.call_opaque "__Runtime_dma_createio_4"(%180, %210) {args = [0 : index, 1 : index, 1 : i32, 1 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %212 = emitc.call_opaque "__runtime_buffer_offset"(%208) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %213 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %214 = emitc.call_opaque "__Runtime_dma_bd_config"(%98, %213) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %215 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %216 = emitc.call_opaque "__Runtime_dma_bd_config"(%98, %215) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,6), direction=S2MM */"
    %217 = emitc.call_opaque "__Runtime_dma_createio_4"(%98, %216) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %218 = emitc.call_opaque "__runtime_buffer_offset"(%208) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %219 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %220 = emitc.call_opaque "__Runtime_dma_bd_config"(%105, %219) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %221 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %222 = emitc.call_opaque "__Runtime_dma_bd_config"(%105, %221) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,6), direction=S2MM */"
    %223 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %222) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %224 = emitc.call_opaque "__runtime_buffer_offset"(%208) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %225 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %226 = emitc.call_opaque "__Runtime_dma_bd_config"(%112, %225) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %227 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %228 = emitc.call_opaque "__Runtime_dma_bd_config"(%112, %227) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,6), direction=S2MM */"
    %229 = emitc.call_opaque "__Runtime_dma_createio_4"(%112, %228) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %230 = emitc.call_opaque "__runtime_buffer_offset"(%208) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %231 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32864">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %232 = emitc.call_opaque "__Runtime_dma_bd_config"(%119, %231) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 8 : i32, 2 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %233 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32832">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %234 = emitc.call_opaque "__Runtime_dma_bd_config"(%119, %233) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 8 : i32, 3 : i32, 0 : i32, 0 : i32, 2 : i32, -1 : i32, 3 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,6), direction=S2MM */"
    %235 = emitc.call_opaque "__Runtime_dma_createio_4"(%119, %234) {args = [0 : index, 1 : index, 1 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (7,0) */"
    %236 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %237 = emitc.call_opaque "__runtime_buffer_arg"(%236) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %238 = emitc.call_opaque "__Runtime_dma_bd_config"(%62, %237) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    %239 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %238) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %240 = emitc.call_opaque "__runtime_buffer_offset"(%236) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %241 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %242 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %241) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 1 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %243 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %244 = emitc.call_opaque "__Runtime_dma_bd_config"(%5, %243) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 1 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %245 = emitc.call_opaque "__Runtime_dma_createio_4"(%5, %244) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %246 = emitc.call_opaque "__runtime_buffer_offset"(%236) {args = [0 : index, 16]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %247 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %248 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %247) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 2 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %249 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %250 = emitc.call_opaque "__Runtime_dma_bd_config"(%11, %249) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 2 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %251 = emitc.call_opaque "__Runtime_dma_createio_4"(%11, %250) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %252 = emitc.call_opaque "__runtime_buffer_offset"(%236) {args = [0 : index, 32]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %253 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = emitc.call_opaque "__Runtime_dma_bd_config"(%17, %253) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 3 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %255 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %256 = emitc.call_opaque "__Runtime_dma_bd_config"(%17, %255) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 3 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %257 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %256) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %258 = emitc.call_opaque "__runtime_buffer_offset"(%236) {args = [0 : index, 48]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %259 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %260 = emitc.call_opaque "__Runtime_dma_bd_config"(%23, %259) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 4 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %261 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %262 = emitc.call_opaque "__Runtime_dma_bd_config"(%23, %261) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 4 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %263 = emitc.call_opaque "__Runtime_dma_createio_4"(%23, %262) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %264 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 64]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %265 = emitc.call_opaque "__runtime_buffer_arg"(%264) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %266 = emitc.call_opaque "__Runtime_dma_bd_config"(%62, %265) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(3,0), direction=S2MM */"
    %267 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %266) {args = [0 : index, 1 : index, 1 : i32, 3 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %268 = emitc.call_opaque "__runtime_buffer_offset"(%264) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %269 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %270 = emitc.call_opaque "__Runtime_dma_bd_config"(%33, %269) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 5 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %271 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = emitc.call_opaque "__Runtime_dma_bd_config"(%33, %271) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 5 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %273 = emitc.call_opaque "__Runtime_dma_createio_4"(%33, %272) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %274 = emitc.call_opaque "__runtime_buffer_offset"(%264) {args = [0 : index, 16]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %275 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %276 = emitc.call_opaque "__Runtime_dma_bd_config"(%40, %275) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 6 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %277 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %278 = emitc.call_opaque "__Runtime_dma_bd_config"(%40, %277) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 6 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %279 = emitc.call_opaque "__Runtime_dma_createio_4"(%40, %278) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %280 = emitc.call_opaque "__runtime_buffer_offset"(%264) {args = [0 : index, 32]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %281 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %282 = emitc.call_opaque "__Runtime_dma_bd_config"(%47, %281) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 7 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %283 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %284 = emitc.call_opaque "__Runtime_dma_bd_config"(%47, %283) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 7 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %285 = emitc.call_opaque "__Runtime_dma_createio_4"(%47, %284) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %286 = emitc.call_opaque "__runtime_buffer_offset"(%264) {args = [0 : index, 48]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %287 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %288 = emitc.call_opaque "__Runtime_dma_bd_config"(%54, %287) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 8 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %289 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = emitc.call_opaque "__Runtime_dma_bd_config"(%54, %289) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 8 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %291 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %290) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %292 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 128]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %293 = emitc.call_opaque "__runtime_buffer_arg"(%292) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %294 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %293) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 2 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,0), direction=S2MM */"
    %295 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %294) {args = [0 : index, 1 : index, 0 : i32, 2 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %296 = emitc.call_opaque "__runtime_buffer_offset"(%292) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %297 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %298 = emitc.call_opaque "__Runtime_dma_bd_config"(%66, %297) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %299 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %300 = emitc.call_opaque "__Runtime_dma_bd_config"(%66, %299) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 9 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %301 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %300) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %302 = emitc.call_opaque "__runtime_buffer_offset"(%292) {args = [0 : index, 16]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %303 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %304 = emitc.call_opaque "__Runtime_dma_bd_config"(%73, %303) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %305 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %306 = emitc.call_opaque "__Runtime_dma_bd_config"(%73, %305) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 10 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %307 = emitc.call_opaque "__Runtime_dma_createio_4"(%73, %306) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %308 = emitc.call_opaque "__runtime_buffer_offset"(%292) {args = [0 : index, 32]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %309 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %310 = emitc.call_opaque "__Runtime_dma_bd_config"(%80, %309) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %311 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %312 = emitc.call_opaque "__Runtime_dma_bd_config"(%80, %311) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 11 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %313 = emitc.call_opaque "__Runtime_dma_createio_4"(%80, %312) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %314 = emitc.call_opaque "__runtime_buffer_offset"(%292) {args = [0 : index, 48]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %315 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %316 = emitc.call_opaque "__Runtime_dma_bd_config"(%87, %315) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %317 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %318 = emitc.call_opaque "__Runtime_dma_bd_config"(%87, %317) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 12 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %319 = emitc.call_opaque "__Runtime_dma_createio_4"(%87, %318) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %320 = emitc.call_opaque "__runtime_buffer_offset"(%arg2) {args = [0 : index, 192]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %321 = emitc.call_opaque "__runtime_buffer_arg"(%320) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %322 = emitc.call_opaque "__Runtime_dma_bd_config"(%1, %321) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 3 : i32, 0, 16 : i32, -1 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32, 0 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(2,0), direction=S2MM */"
    %323 = emitc.call_opaque "__Runtime_dma_createio_4"(%1, %322) {args = [0 : index, 1 : index, 1 : i32, 3 : i32, #emitc.opaque<"DMA_S2MM">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    %324 = emitc.call_opaque "__runtime_buffer_offset"(%320) {args = [0 : index, 0]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %325 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %326 = emitc.call_opaque "__Runtime_dma_bd_config"(%98, %325) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 13 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %327 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %328 = emitc.call_opaque "__Runtime_dma_bd_config"(%98, %327) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 13 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %329 = emitc.call_opaque "__Runtime_dma_createio_4"(%98, %328) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %330 = emitc.call_opaque "__runtime_buffer_offset"(%320) {args = [0 : index, 16]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %331 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %332 = emitc.call_opaque "__Runtime_dma_bd_config"(%105, %331) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 14 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %333 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %334 = emitc.call_opaque "__Runtime_dma_bd_config"(%105, %333) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 14 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %335 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %334) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %336 = emitc.call_opaque "__runtime_buffer_offset"(%320) {args = [0 : index, 32]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %337 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %338 = emitc.call_opaque "__Runtime_dma_bd_config"(%112, %337) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 15 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %339 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %340 = emitc.call_opaque "__Runtime_dma_bd_config"(%112, %339) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 15 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %341 = emitc.call_opaque "__Runtime_dma_createio_4"(%112, %340) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %342 = emitc.call_opaque "__runtime_buffer_offset"(%320) {args = [0 : index, 48]} : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %343 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32928">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %344 = emitc.call_opaque "__Runtime_dma_bd_config"(%119, %343) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 5 : i32, 0, 2 : i32, 4 : i32, 1 : i32, 16 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %345 = emitc.call_opaque "__runtime_buffer_arg"() {args = [#emitc.opaque<"(void*)32896">]} : () -> !emitc.ptr<!emitc.opaque<"void">>
    %346 = emitc.call_opaque "__Runtime_dma_bd_config"(%119, %345) {args = [#emitc.opaque<"g_DevInst">, 0 : index, 1 : index, 4 : i32, 0, 2 : i32, 5 : i32, 1 : i32, 16 : i32, 5 : i32, -1 : i32, 4 : i32, 1 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %347 = emitc.call_opaque "__Runtime_dma_createio_4"(%119, %346) {args = [0 : index, 1 : index, 0 : i32, 4 : i32, #emitc.opaque<"DMA_MM2S">]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %348 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%5, %11, %17, %23, %33, %40, %47, %54, %66, %73, %80, %87, %98, %105, %112, %119) {args = [0 : index, 1 : index, 2 : index, 3 : index, 4 : index, 5 : index, 6 : index, 7 : index, 8 : index, 9 : index, 10 : index, 11 : index, 12 : index, 13 : index, 14 : index, 15 : index, 16 : i32]} : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %349 = emitc.call_opaque "__Runtime_launch_kernel_group"(%348) : (!emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %350 = emitc.call_opaque "__Runtime_startio"(%10) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %351 = emitc.call_opaque "__Runtime_startio"(%16) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %352 = emitc.call_opaque "__Runtime_startio"(%22) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %353 = emitc.call_opaque "__Runtime_startio"(%28) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %354 = emitc.call_opaque "__Runtime_startio"(%4) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %355 = emitc.call_opaque "__Runtime_startio"(%39) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %356 = emitc.call_opaque "__Runtime_startio"(%46) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %357 = emitc.call_opaque "__Runtime_startio"(%53) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %358 = emitc.call_opaque "__Runtime_startio"(%60) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %359 = emitc.call_opaque "__Runtime_startio"(%32) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %360 = emitc.call_opaque "__Runtime_startio"(%72) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %361 = emitc.call_opaque "__Runtime_startio"(%79) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %362 = emitc.call_opaque "__Runtime_startio"(%86) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %363 = emitc.call_opaque "__Runtime_startio"(%93) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %364 = emitc.call_opaque "__Runtime_startio"(%65) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %365 = emitc.call_opaque "__Runtime_startio"(%104) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %366 = emitc.call_opaque "__Runtime_startio"(%111) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %367 = emitc.call_opaque "__Runtime_startio"(%118) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %368 = emitc.call_opaque "__Runtime_startio"(%125) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %369 = emitc.call_opaque "__Runtime_startio"(%97) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %370 = emitc.call_opaque "__Runtime_startio"(%135) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %371 = emitc.call_opaque "__Runtime_startio"(%140) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %372 = emitc.call_opaque "__Runtime_startio"(%145) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %373 = emitc.call_opaque "__Runtime_startio"(%150) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %374 = emitc.call_opaque "__Runtime_startio"(%130) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %375 = emitc.call_opaque "__Runtime_startio"(%160) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %376 = emitc.call_opaque "__Runtime_startio"(%166) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %377 = emitc.call_opaque "__Runtime_startio"(%172) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %378 = emitc.call_opaque "__Runtime_startio"(%178) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %379 = emitc.call_opaque "__Runtime_startio"(%154) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %380 = emitc.call_opaque "__Runtime_startio"(%189) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %381 = emitc.call_opaque "__Runtime_startio"(%195) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %382 = emitc.call_opaque "__Runtime_startio"(%201) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %383 = emitc.call_opaque "__Runtime_startio"(%207) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %384 = emitc.call_opaque "__Runtime_startio"(%183) {args = [0 : index, 0 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %385 = emitc.call_opaque "__Runtime_startio"(%217) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %386 = emitc.call_opaque "__Runtime_startio"(%223) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %387 = emitc.call_opaque "__Runtime_startio"(%229) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %388 = emitc.call_opaque "__Runtime_startio"(%235) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %389 = emitc.call_opaque "__Runtime_startio"(%211) {args = [0 : index, 1 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %390 = emitc.call_opaque "__Runtime_startio"(%245) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %391 = emitc.call_opaque "__Runtime_startio"(%251) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %392 = emitc.call_opaque "__Runtime_startio"(%257) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %393 = emitc.call_opaque "__Runtime_startio"(%263) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %394 = emitc.call_opaque "__Runtime_startio"(%239) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %395 = emitc.call_opaque "__Runtime_startio"(%273) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %396 = emitc.call_opaque "__Runtime_startio"(%279) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %397 = emitc.call_opaque "__Runtime_startio"(%285) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %398 = emitc.call_opaque "__Runtime_startio"(%291) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %399 = emitc.call_opaque "__Runtime_startio"(%267) {args = [0 : index, 3 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %400 = emitc.call_opaque "__Runtime_startio"(%301) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %401 = emitc.call_opaque "__Runtime_startio"(%307) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %402 = emitc.call_opaque "__Runtime_startio"(%313) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %403 = emitc.call_opaque "__Runtime_startio"(%319) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %404 = emitc.call_opaque "__Runtime_startio"(%295) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %405 = emitc.call_opaque "__Runtime_startio"(%329) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %406 = emitc.call_opaque "__Runtime_startio"(%335) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %407 = emitc.call_opaque "__Runtime_startio"(%341) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %408 = emitc.call_opaque "__Runtime_startio"(%347) {args = [0 : index, 2 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    %409 = emitc.call_opaque "__Runtime_startio"(%323) {args = [0 : index, 3 : i32]} : (!emitc.opaque<"io">) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%349) : (!emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%354) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%359) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%364) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%369) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%374) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%379) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%384) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%389) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%394) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%399) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%404) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%409) : (!emitc.opaque<"ioevent">) -> ()
    emitc.verbatim "/* AieRt debug snapshot */"
    emitc.verbatim "{"
    emitc.verbatim "  uint8_t _dbg_io_cols[] = {2, 0, 1, 2, 3, 2, 0, 1, 2, 3, 3, 0, 1, 2, 3, 3, 0, 1, 2, 3, 6, 0, 1, 2, 3, 6, 0, 1, 2, 3, 7, 0, 1, 2, 3, 7, 0, 1, 2, 3, 3, 0, 1, 2, 3, 3, 0, 1, 2, 3, 2, 0, 1, 2, 3, 2, 0, 1, 2, 3};"
    emitc.verbatim "  uint8_t _dbg_io_rows[] = {0, 3, 3, 3, 3, 0, 4, 4, 4, 4, 0, 5, 5, 5, 5, 0, 6, 6, 6, 6, 0, 3, 3, 3, 3, 0, 4, 4, 4, 4, 0, 5, 5, 5, 5, 0, 6, 6, 6, 6, 0, 3, 3, 3, 3, 0, 4, 4, 4, 4, 0, 5, 5, 5, 5, 0, 6, 6, 6, 6};"
    emitc.verbatim "  uint8_t _dbg_io_chs[] = {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0};"
    emitc.verbatim "  uint8_t _dbg_io_bds[] = {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 1, 2, 2, 2, 2, 0, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 4, 4, 4, 4, 3, 4, 4, 4, 4, 2, 4, 4, 4, 4, 3, 4, 4, 4, 4};"
    emitc.verbatim "  int _dbg_io_dirs[] = {DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S};"
    emitc.verbatim "  uint8_t _dbg_t_cols[] = {0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3};"
    emitc.verbatim "  uint8_t _dbg_t_rows[] = {3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6};"
    emitc.verbatim "  AieRt_DebugSnapshotFromCoords(g_DevInst,\0A      _dbg_io_cols, _dbg_io_rows, _dbg_io_chs, _dbg_io_bds, _dbg_io_dirs, 60,\0A      _dbg_t_cols, _dbg_t_rows, 16);"
    emitc.verbatim "}"
    emitc.return
  }
  emitc.func @dskernel_receiver(%arg0: index) attributes {specifiers = ["__global__"]} {
    emitc.verbatim "// the real kernel will be emitted separately\0A"
    emitc.return
  }
}
