module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    emitc.call_opaque "host_canonicalized"() : () -> ()
    return
  }
  emitc.func @host_canonicalized(%arg0: !emitc.ptr<!emitc.opaque<"void">>, %arg1: !emitc.ptr<!emitc.opaque<"void">>, %arg2: !emitc.ptr<!emitc.opaque<"void">>) {
    %0 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %3 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %4 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %5 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %6 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %7 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %8 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %9 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %10 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %11 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %12 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %13 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %14 = "emitc.constant"() <{value = 7 : i8}> : () -> i8
    %15 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %16 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %17 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %18 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %19 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %20 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %21 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %22 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %23 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %24 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    %25 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %26 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %27 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %28 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %29 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    %30 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %31 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %33 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %34 = "emitc.constant"() <{value = #emitc.opaque<"g_DevInst">}> : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
    %35 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_MEM_CACHEABLE">}> : () -> i32
    %36 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %37 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %38 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %39 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %40 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %43 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %44 = emitc.call_opaque "XAie_TileLoc"(%33, %32) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %45 = emitc.call_opaque "__runtime_buffer_arg"(%43) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %46 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %44, %45, %40, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %47 = emitc.call_opaque "__Runtime_dma_createio_4"(%44, %46, %40, %40, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %48 = emitc.call_opaque "XAie_TileLoc"(%32, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %49 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %50 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %48, %49, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %48, %51, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,3), direction=S2MM */"
    %53 = emitc.call_opaque "__Runtime_dma_createio_4"(%48, %52, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %54 = emitc.call_opaque "XAie_TileLoc"(%23, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %55 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %56 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %54, %55, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %57 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %58 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %54, %57, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,3), direction=S2MM */"
    %59 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %58, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %60 = emitc.call_opaque "XAie_TileLoc"(%33, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %61 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %62 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %60, %61, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %63 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %64 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %60, %63, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,3), direction=S2MM */"
    %65 = emitc.call_opaque "__Runtime_dma_createio_4"(%60, %64, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %66 = emitc.call_opaque "XAie_TileLoc"(%28, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %67 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %68 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %66, %67, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %69 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %70 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %66, %69, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,3), direction=S2MM */"
    %71 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %70, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %72 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %73 = emitc.call_opaque "__runtime_buffer_arg"(%72) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %74 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %44, %73, %41, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %75 = emitc.call_opaque "__Runtime_dma_createio_4"(%44, %74, %41, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %76 = emitc.call_opaque "XAie_TileLoc"(%32, %21) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %77 = emitc.call_opaque "__runtime_buffer_offset"(%72, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %78 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %79 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %76, %78, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %80 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %81 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %76, %80, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,4), direction=S2MM */"
    %82 = emitc.call_opaque "__Runtime_dma_createio_4"(%76, %81, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %83 = emitc.call_opaque "XAie_TileLoc"(%23, %21) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %84 = emitc.call_opaque "__runtime_buffer_offset"(%72, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %85 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %86 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %83, %85, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %87 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %88 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %83, %87, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,4), direction=S2MM */"
    %89 = emitc.call_opaque "__Runtime_dma_createio_4"(%83, %88, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %90 = emitc.call_opaque "XAie_TileLoc"(%33, %21) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %91 = emitc.call_opaque "__runtime_buffer_offset"(%72, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %92 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %93 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %90, %92, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %94 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %95 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %90, %94, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,4), direction=S2MM */"
    %96 = emitc.call_opaque "__Runtime_dma_createio_4"(%90, %95, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %97 = emitc.call_opaque "XAie_TileLoc"(%28, %21) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %98 = emitc.call_opaque "__runtime_buffer_offset"(%72, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %99 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %100 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %97, %99, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %101 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %102 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %97, %101, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,4), direction=S2MM */"
    %103 = emitc.call_opaque "__Runtime_dma_createio_4"(%97, %102, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %104 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %105 = emitc.call_opaque "XAie_TileLoc"(%28, %32) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %106 = emitc.call_opaque "__runtime_buffer_arg"(%104) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %107 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %105, %106, %40, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %108 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %107, %40, %40, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %109 = emitc.call_opaque "XAie_TileLoc"(%32, %19) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %110 = emitc.call_opaque "__runtime_buffer_offset"(%104, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %111 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %112 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %109, %111, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %113 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %114 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %109, %113, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,5), direction=S2MM */"
    %115 = emitc.call_opaque "__Runtime_dma_createio_4"(%109, %114, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %116 = emitc.call_opaque "XAie_TileLoc"(%23, %19) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %117 = emitc.call_opaque "__runtime_buffer_offset"(%104, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %118 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %119 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %116, %118, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %120 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %121 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %116, %120, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,5), direction=S2MM */"
    %122 = emitc.call_opaque "__Runtime_dma_createio_4"(%116, %121, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %123 = emitc.call_opaque "XAie_TileLoc"(%33, %19) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %124 = emitc.call_opaque "__runtime_buffer_offset"(%104, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %125 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %126 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %123, %125, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %127 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %128 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %123, %127, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,5), direction=S2MM */"
    %129 = emitc.call_opaque "__Runtime_dma_createio_4"(%123, %128, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %130 = emitc.call_opaque "XAie_TileLoc"(%28, %19) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %131 = emitc.call_opaque "__runtime_buffer_offset"(%104, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %132 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %133 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %130, %132, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %134 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %135 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %130, %134, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,5), direction=S2MM */"
    %136 = emitc.call_opaque "__Runtime_dma_createio_4"(%130, %135, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %137 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %138 = emitc.call_opaque "__runtime_buffer_arg"(%137) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %139 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %105, %138, %41, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(3,0), direction=MM2S */"
    %140 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %139, %41, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %141 = emitc.call_opaque "XAie_TileLoc"(%32, %17) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %142 = emitc.call_opaque "__runtime_buffer_offset"(%137, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %143 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %144 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %141, %143, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %145 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %146 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %141, %145, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,6), direction=S2MM */"
    %147 = emitc.call_opaque "__Runtime_dma_createio_4"(%141, %146, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    %148 = emitc.call_opaque "XAie_TileLoc"(%23, %17) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %149 = emitc.call_opaque "__runtime_buffer_offset"(%137, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %150 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %151 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %148, %150, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %152 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %153 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %148, %152, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,6), direction=S2MM */"
    %154 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %153, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    %155 = emitc.call_opaque "XAie_TileLoc"(%33, %17) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %156 = emitc.call_opaque "__runtime_buffer_offset"(%137, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %157 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %158 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %155, %157, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %159 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %160 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %155, %159, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,6), direction=S2MM */"
    %161 = emitc.call_opaque "__Runtime_dma_createio_4"(%155, %160, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    %162 = emitc.call_opaque "XAie_TileLoc"(%28, %17) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %163 = emitc.call_opaque "__runtime_buffer_offset"(%137, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %164 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %165 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %162, %164, %41, %42, %25, %40, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %166 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %167 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %162, %166, %40, %42, %25, %41, %40, %40, %40, %30, %41, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,6), direction=S2MM */"
    %168 = emitc.call_opaque "__Runtime_dma_createio_4"(%162, %167, %40, %40, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %169 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %170 = emitc.call_opaque "XAie_TileLoc"(%17, %32) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %171 = emitc.call_opaque "__runtime_buffer_arg"(%169) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %172 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %170, %171, %40, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(6,0), direction=MM2S */"
    %173 = emitc.call_opaque "__Runtime_dma_createio_4"(%170, %172, %40, %40, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %174 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %175 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %48, %174, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %176 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %177 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %48, %176, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,3), direction=S2MM */"
    %178 = emitc.call_opaque "__Runtime_dma_createio_4"(%48, %177, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %179 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %180 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %54, %179, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %181 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %182 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %54, %181, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,3), direction=S2MM */"
    %183 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %182, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %184 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %185 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %60, %184, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %186 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %187 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %60, %186, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,3), direction=S2MM */"
    %188 = emitc.call_opaque "__Runtime_dma_createio_4"(%60, %187, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %189 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %190 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %66, %189, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %191 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %192 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %66, %191, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,3), direction=S2MM */"
    %193 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %192, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (6,0) */"
    %194 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %195 = emitc.call_opaque "__runtime_buffer_arg"(%194) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %196 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %170, %195, %41, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(6,0), direction=MM2S */"
    %197 = emitc.call_opaque "__Runtime_dma_createio_4"(%170, %196, %41, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %198 = emitc.call_opaque "__runtime_buffer_offset"(%194, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %199 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %200 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %76, %199, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %201 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %202 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %76, %201, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,4), direction=S2MM */"
    %203 = emitc.call_opaque "__Runtime_dma_createio_4"(%76, %202, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %204 = emitc.call_opaque "__runtime_buffer_offset"(%194, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %205 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %206 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %83, %205, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %207 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %208 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %83, %207, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,4), direction=S2MM */"
    %209 = emitc.call_opaque "__Runtime_dma_createio_4"(%83, %208, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %210 = emitc.call_opaque "__runtime_buffer_offset"(%194, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %211 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %212 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %90, %211, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %213 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %214 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %90, %213, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,4), direction=S2MM */"
    %215 = emitc.call_opaque "__Runtime_dma_createio_4"(%90, %214, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %216 = emitc.call_opaque "__runtime_buffer_offset"(%194, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %217 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %218 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %97, %217, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %219 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %220 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %97, %219, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,4), direction=S2MM */"
    %221 = emitc.call_opaque "__Runtime_dma_createio_4"(%97, %220, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (6,0) */"
    %222 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %223 = emitc.call_opaque "XAie_TileLoc"(%14, %32) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %224 = emitc.call_opaque "__runtime_buffer_arg"(%222) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %225 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %223, %224, %40, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(7,0), direction=MM2S */"
    %226 = emitc.call_opaque "__Runtime_dma_createio_4"(%223, %225, %40, %40, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %227 = emitc.call_opaque "__runtime_buffer_offset"(%222, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %228 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %229 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %109, %228, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %230 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %231 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %109, %230, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,5), direction=S2MM */"
    %232 = emitc.call_opaque "__Runtime_dma_createio_4"(%109, %231, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %233 = emitc.call_opaque "__runtime_buffer_offset"(%222, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %234 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %235 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %116, %234, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %236 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %237 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %116, %236, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,5), direction=S2MM */"
    %238 = emitc.call_opaque "__Runtime_dma_createio_4"(%116, %237, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %239 = emitc.call_opaque "__runtime_buffer_offset"(%222, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %240 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %241 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %123, %240, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %242 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %243 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %123, %242, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,5), direction=S2MM */"
    %244 = emitc.call_opaque "__Runtime_dma_createio_4"(%123, %243, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %245 = emitc.call_opaque "__runtime_buffer_offset"(%222, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %246 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %247 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %130, %246, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %248 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %249 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %130, %248, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,5), direction=S2MM */"
    %250 = emitc.call_opaque "__Runtime_dma_createio_4"(%130, %249, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (7,0) */"
    %251 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %252 = emitc.call_opaque "__runtime_buffer_arg"(%251) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %253 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %223, %252, %41, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(7,0), direction=MM2S */"
    %254 = emitc.call_opaque "__Runtime_dma_createio_4"(%223, %253, %41, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %255 = emitc.call_opaque "__runtime_buffer_offset"(%251, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %256 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %257 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %141, %256, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %258 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %259 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %141, %258, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,6), direction=S2MM */"
    %260 = emitc.call_opaque "__Runtime_dma_createio_4"(%141, %259, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %261 = emitc.call_opaque "__runtime_buffer_offset"(%251, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %262 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %263 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %148, %262, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %264 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %265 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %148, %264, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,6), direction=S2MM */"
    %266 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %265, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %267 = emitc.call_opaque "__runtime_buffer_offset"(%251, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %268 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %269 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %155, %268, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %270 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %271 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %155, %270, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(2,6), direction=S2MM */"
    %272 = emitc.call_opaque "__Runtime_dma_createio_4"(%155, %271, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %273 = emitc.call_opaque "__runtime_buffer_offset"(%251, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %274 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %275 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %162, %274, %38, %42, %25, %39, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=8, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %276 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %277 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %162, %276, %39, %42, %25, %38, %40, %40, %39, %30, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(3,6), direction=S2MM */"
    %278 = emitc.call_opaque "__Runtime_dma_createio_4"(%162, %277, %41, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (7,0) */"
    %279 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %280 = emitc.call_opaque "__runtime_buffer_arg"(%279) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %281 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %105, %280, %39, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    %282 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %281, %40, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %283 = emitc.call_opaque "__runtime_buffer_offset"(%279, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %284 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %285 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %48, %284, %37, %42, %39, %36, %41, %41, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %286 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %287 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %48, %286, %36, %42, %39, %37, %41, %41, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %288 = emitc.call_opaque "__Runtime_dma_createio_4"(%48, %287, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %289 = emitc.call_opaque "__runtime_buffer_offset"(%279, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %290 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %291 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %54, %290, %37, %42, %39, %36, %41, %39, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %292 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %293 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %54, %292, %36, %42, %39, %37, %41, %39, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %294 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %293, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %295 = emitc.call_opaque "__runtime_buffer_offset"(%279, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %296 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %297 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %60, %296, %37, %42, %39, %36, %41, %38, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %298 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %299 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %60, %298, %36, %42, %39, %37, %41, %38, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %300 = emitc.call_opaque "__Runtime_dma_createio_4"(%60, %299, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %301 = emitc.call_opaque "__runtime_buffer_offset"(%279, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %302 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %303 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %66, %302, %37, %42, %39, %36, %41, %36, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %304 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %305 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %66, %304, %36, %42, %39, %37, %41, %36, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %306 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %305, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %307 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %308 = emitc.call_opaque "__runtime_buffer_arg"(%307) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %309 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %105, %308, %38, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(3,0), direction=S2MM */"
    %310 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %309, %41, %38, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %311 = emitc.call_opaque "__runtime_buffer_offset"(%307, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %312 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %313 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %76, %312, %37, %42, %39, %36, %41, %37, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %314 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %315 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %76, %314, %36, %42, %39, %37, %41, %37, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %316 = emitc.call_opaque "__Runtime_dma_createio_4"(%76, %315, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %317 = emitc.call_opaque "__runtime_buffer_offset"(%307, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %318 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %319 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %83, %318, %37, %42, %39, %36, %41, %8, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %320 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %321 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %83, %320, %36, %42, %39, %37, %41, %8, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %322 = emitc.call_opaque "__Runtime_dma_createio_4"(%83, %321, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %323 = emitc.call_opaque "__runtime_buffer_offset"(%307, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %324 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %325 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %90, %324, %37, %42, %39, %36, %41, %7, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %326 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %327 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %90, %326, %36, %42, %39, %37, %41, %7, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %328 = emitc.call_opaque "__Runtime_dma_createio_4"(%90, %327, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %329 = emitc.call_opaque "__runtime_buffer_offset"(%307, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %330 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %331 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %97, %330, %37, %42, %39, %36, %41, %25, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %332 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %333 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %97, %332, %36, %42, %39, %37, %41, %25, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %334 = emitc.call_opaque "__Runtime_dma_createio_4"(%97, %333, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %335 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %336 = emitc.call_opaque "__runtime_buffer_arg"(%335) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %337 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %44, %336, %39, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,0), direction=S2MM */"
    %338 = emitc.call_opaque "__Runtime_dma_createio_4"(%44, %337, %40, %39, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %339 = emitc.call_opaque "__runtime_buffer_offset"(%335, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %340 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %341 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %109, %340, %37, %42, %39, %36, %41, %6, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %342 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %343 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %109, %342, %36, %42, %39, %37, %41, %6, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %344 = emitc.call_opaque "__Runtime_dma_createio_4"(%109, %343, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %345 = emitc.call_opaque "__runtime_buffer_offset"(%335, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %346 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %347 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %116, %346, %37, %42, %39, %36, %41, %5, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %348 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %349 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %116, %348, %36, %42, %39, %37, %41, %5, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %350 = emitc.call_opaque "__Runtime_dma_createio_4"(%116, %349, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %351 = emitc.call_opaque "__runtime_buffer_offset"(%335, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %352 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %353 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %123, %352, %37, %42, %39, %36, %41, %4, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %354 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %355 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %123, %354, %36, %42, %39, %37, %41, %4, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %356 = emitc.call_opaque "__Runtime_dma_createio_4"(%123, %355, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %357 = emitc.call_opaque "__runtime_buffer_offset"(%335, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %358 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %359 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %130, %358, %37, %42, %39, %36, %41, %3, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %360 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %361 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %130, %360, %36, %42, %39, %37, %41, %3, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %362 = emitc.call_opaque "__Runtime_dma_createio_4"(%130, %361, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %363 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %18) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %364 = emitc.call_opaque "__runtime_buffer_arg"(%363) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %365 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %44, %364, %38, %42, %31, %30, %40, %40, %40, %40, %40, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(2,0), direction=S2MM */"
    %366 = emitc.call_opaque "__Runtime_dma_createio_4"(%44, %365, %41, %38, %24) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %367 = emitc.call_opaque "__runtime_buffer_offset"(%363, %42) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %368 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %369 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %141, %368, %37, %42, %39, %36, %41, %2, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %370 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %371 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %141, %370, %36, %42, %39, %37, %41, %2, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %372 = emitc.call_opaque "__Runtime_dma_createio_4"(%141, %371, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %373 = emitc.call_opaque "__runtime_buffer_offset"(%363, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %374 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %375 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %148, %374, %37, %42, %39, %36, %41, %1, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %376 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %377 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %148, %376, %36, %42, %39, %37, %41, %1, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %378 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %377, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %379 = emitc.call_opaque "__runtime_buffer_offset"(%363, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %380 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %381 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %155, %380, %37, %42, %39, %36, %41, %0, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %382 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %383 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %155, %382, %36, %42, %39, %37, %41, %0, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %384 = emitc.call_opaque "__Runtime_dma_createio_4"(%155, %383, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %385 = emitc.call_opaque "__runtime_buffer_offset"(%363, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %386 = emitc.call_opaque "__runtime_buffer_arg"(%12) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %387 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %162, %386, %37, %42, %39, %36, %41, %31, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %388 = emitc.call_opaque "__runtime_buffer_arg"(%13) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %389 = emitc.call_opaque "__Runtime_dma_bd_config"(%34, %162, %388, %36, %42, %39, %37, %41, %31, %37, %30, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %390 = emitc.call_opaque "__Runtime_dma_createio_4"(%162, %389, %40, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %391 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%48, %54, %60, %66, %76, %83, %90, %97, %109, %116, %123, %130, %141, %148, %155, %162, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %392 = emitc.call_opaque "__Runtime_launch_kernel_group"(%391) : (!emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %393 = emitc.call_opaque "__Runtime_startio"(%53, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %394 = emitc.call_opaque "__Runtime_startio"(%59, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %395 = emitc.call_opaque "__Runtime_startio"(%65, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %396 = emitc.call_opaque "__Runtime_startio"(%71, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %397 = emitc.call_opaque "__Runtime_startio"(%47, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %398 = emitc.call_opaque "__Runtime_startio"(%82, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %399 = emitc.call_opaque "__Runtime_startio"(%89, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %400 = emitc.call_opaque "__Runtime_startio"(%96, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %401 = emitc.call_opaque "__Runtime_startio"(%103, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %402 = emitc.call_opaque "__Runtime_startio"(%75, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %403 = emitc.call_opaque "__Runtime_startio"(%115, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %404 = emitc.call_opaque "__Runtime_startio"(%122, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %405 = emitc.call_opaque "__Runtime_startio"(%129, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %406 = emitc.call_opaque "__Runtime_startio"(%136, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %407 = emitc.call_opaque "__Runtime_startio"(%108, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %408 = emitc.call_opaque "__Runtime_startio"(%147, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %409 = emitc.call_opaque "__Runtime_startio"(%154, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %410 = emitc.call_opaque "__Runtime_startio"(%161, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %411 = emitc.call_opaque "__Runtime_startio"(%168, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %412 = emitc.call_opaque "__Runtime_startio"(%140, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %413 = emitc.call_opaque "__Runtime_startio"(%178, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %414 = emitc.call_opaque "__Runtime_startio"(%183, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %415 = emitc.call_opaque "__Runtime_startio"(%188, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %416 = emitc.call_opaque "__Runtime_startio"(%193, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %417 = emitc.call_opaque "__Runtime_startio"(%173, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %418 = emitc.call_opaque "__Runtime_startio"(%203, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %419 = emitc.call_opaque "__Runtime_startio"(%209, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %420 = emitc.call_opaque "__Runtime_startio"(%215, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %421 = emitc.call_opaque "__Runtime_startio"(%221, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %422 = emitc.call_opaque "__Runtime_startio"(%197, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %423 = emitc.call_opaque "__Runtime_startio"(%232, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %424 = emitc.call_opaque "__Runtime_startio"(%238, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %425 = emitc.call_opaque "__Runtime_startio"(%244, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %426 = emitc.call_opaque "__Runtime_startio"(%250, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %427 = emitc.call_opaque "__Runtime_startio"(%226, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %428 = emitc.call_opaque "__Runtime_startio"(%260, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %429 = emitc.call_opaque "__Runtime_startio"(%266, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %430 = emitc.call_opaque "__Runtime_startio"(%272, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %431 = emitc.call_opaque "__Runtime_startio"(%278, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %432 = emitc.call_opaque "__Runtime_startio"(%254, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %433 = emitc.call_opaque "__Runtime_startio"(%288, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %434 = emitc.call_opaque "__Runtime_startio"(%294, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %435 = emitc.call_opaque "__Runtime_startio"(%300, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %436 = emitc.call_opaque "__Runtime_startio"(%306, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %437 = emitc.call_opaque "__Runtime_startio"(%282, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %438 = emitc.call_opaque "__Runtime_startio"(%316, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %439 = emitc.call_opaque "__Runtime_startio"(%322, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %440 = emitc.call_opaque "__Runtime_startio"(%328, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %441 = emitc.call_opaque "__Runtime_startio"(%334, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %442 = emitc.call_opaque "__Runtime_startio"(%310, %38) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %443 = emitc.call_opaque "__Runtime_startio"(%344, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %444 = emitc.call_opaque "__Runtime_startio"(%350, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %445 = emitc.call_opaque "__Runtime_startio"(%356, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %446 = emitc.call_opaque "__Runtime_startio"(%362, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %447 = emitc.call_opaque "__Runtime_startio"(%338, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %448 = emitc.call_opaque "__Runtime_startio"(%372, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %449 = emitc.call_opaque "__Runtime_startio"(%378, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %450 = emitc.call_opaque "__Runtime_startio"(%384, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %451 = emitc.call_opaque "__Runtime_startio"(%390, %39) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %452 = emitc.call_opaque "__Runtime_startio"(%366, %38) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%392) : (!emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%397) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%402) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%407) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%412) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%417) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%422) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%427) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%432) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%437) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%442) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%447) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%452) : (!emitc.opaque<"ioevent">) -> ()
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
