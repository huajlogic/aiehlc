// Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: MIT

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
    %7 = "emitc.constant"() <{value = 7 : i8}> : () -> i8
    %8 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %9 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %10 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %11 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %12 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %13 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %14 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %15 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %16 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %17 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %18 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %19 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %20 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %21 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %22 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %23 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %24 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %25 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %26 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    %27 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %28 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %29 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %30 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %31 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    %32 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %33 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %34 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %35 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %36 = "emitc.constant"() <{value = #emitc.opaque<"g_DevInst">}> : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
    %37 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_MEM_CACHEABLE">}> : () -> i32
    %38 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %39 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %40 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %43 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %44 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %45 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %46 = emitc.call_opaque "XAie_TileLoc"(%35, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %47 = emitc.call_opaque "__runtime_buffer_arg"(%45) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %48 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %46, %47, %42, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %49 = emitc.call_opaque "__Runtime_dma_createio_4"(%46, %48, %42, %42, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %50 = emitc.call_opaque "XAie_TileLoc"(%34, %30) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %50, %51, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %53 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %54 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %50, %53, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %55 = emitc.call_opaque "__Runtime_dma_createio_4"(%50, %54, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %56 = emitc.call_opaque "XAie_TileLoc"(%34, %25) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %57 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %58 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %56, %57, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %59 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %60 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %56, %59, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %61 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %60, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %62 = emitc.call_opaque "XAie_TileLoc"(%34, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %63 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %64 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %62, %63, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %65 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %66 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %62, %65, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %67 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %66, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %68 = emitc.call_opaque "XAie_TileLoc"(%34, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %69 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %70 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %68, %69, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %71 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %72 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %68, %71, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %73 = emitc.call_opaque "__Runtime_dma_createio_4"(%68, %72, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %74 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %75 = emitc.call_opaque "__runtime_buffer_arg"(%74) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %76 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %46, %75, %43, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %77 = emitc.call_opaque "__Runtime_dma_createio_4"(%46, %76, %43, %43, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %78 = emitc.call_opaque "XAie_TileLoc"(%21, %30) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %79 = emitc.call_opaque "__runtime_buffer_offset"(%74, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %80 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %81 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %78, %80, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %82 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %83 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %78, %82, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %84 = emitc.call_opaque "__Runtime_dma_createio_4"(%78, %83, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %85 = emitc.call_opaque "XAie_TileLoc"(%21, %25) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %86 = emitc.call_opaque "__runtime_buffer_offset"(%74, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %87 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %88 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %85, %87, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %89 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %90 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %85, %89, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %91 = emitc.call_opaque "__Runtime_dma_createio_4"(%85, %90, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %92 = emitc.call_opaque "XAie_TileLoc"(%21, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %93 = emitc.call_opaque "__runtime_buffer_offset"(%74, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %94 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %95 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %92, %94, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %96 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %97 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %92, %96, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %98 = emitc.call_opaque "__Runtime_dma_createio_4"(%92, %97, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %99 = emitc.call_opaque "XAie_TileLoc"(%21, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %100 = emitc.call_opaque "__runtime_buffer_offset"(%74, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %101 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %102 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %99, %101, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %103 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %104 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %99, %103, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %105 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %104, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %106 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %107 = emitc.call_opaque "XAie_TileLoc"(%30, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %108 = emitc.call_opaque "__runtime_buffer_arg"(%106) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %109 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %107, %108, %42, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %110 = emitc.call_opaque "__Runtime_dma_createio_4"(%107, %109, %42, %42, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %111 = emitc.call_opaque "XAie_TileLoc"(%35, %30) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %112 = emitc.call_opaque "__runtime_buffer_offset"(%106, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %113 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %114 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %111, %113, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %115 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %116 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %111, %115, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %117 = emitc.call_opaque "__Runtime_dma_createio_4"(%111, %116, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %118 = emitc.call_opaque "XAie_TileLoc"(%35, %25) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %119 = emitc.call_opaque "__runtime_buffer_offset"(%106, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %120 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %121 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %118, %120, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %122 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %123 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %118, %122, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %124 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %123, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %125 = emitc.call_opaque "XAie_TileLoc"(%35, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %126 = emitc.call_opaque "__runtime_buffer_offset"(%106, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %127 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %128 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %125, %127, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %129 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %130 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %125, %129, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %131 = emitc.call_opaque "__Runtime_dma_createio_4"(%125, %130, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %132 = emitc.call_opaque "XAie_TileLoc"(%35, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %133 = emitc.call_opaque "__runtime_buffer_offset"(%106, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %134 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %135 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %132, %134, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %136 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %137 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %132, %136, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %138 = emitc.call_opaque "__Runtime_dma_createio_4"(%132, %137, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %139 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %140 = emitc.call_opaque "__runtime_buffer_arg"(%139) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %141 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %107, %140, %43, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(3,0), direction=MM2S */"
    %142 = emitc.call_opaque "__Runtime_dma_createio_4"(%107, %141, %43, %43, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %143 = emitc.call_opaque "XAie_TileLoc"(%30, %30) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %144 = emitc.call_opaque "__runtime_buffer_offset"(%139, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %145 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %146 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %143, %145, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %147 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %148 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %143, %147, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %149 = emitc.call_opaque "__Runtime_dma_createio_4"(%143, %148, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %150 = emitc.call_opaque "XAie_TileLoc"(%30, %25) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %151 = emitc.call_opaque "__runtime_buffer_offset"(%139, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %152 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %153 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %150, %152, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %154 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %155 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %150, %154, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %156 = emitc.call_opaque "__Runtime_dma_createio_4"(%150, %155, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %157 = emitc.call_opaque "XAie_TileLoc"(%30, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %158 = emitc.call_opaque "__runtime_buffer_offset"(%139, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %159 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %160 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %157, %159, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %161 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %162 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %157, %161, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %163 = emitc.call_opaque "__Runtime_dma_createio_4"(%157, %162, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %164 = emitc.call_opaque "XAie_TileLoc"(%30, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %165 = emitc.call_opaque "__runtime_buffer_offset"(%139, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %166 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %167 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %164, %166, %43, %44, %27, %42, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %168 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %169 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %164, %168, %42, %44, %27, %43, %42, %42, %41, %32, %40, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %170 = emitc.call_opaque "__Runtime_dma_createio_4"(%164, %169, %43, %42, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %171 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %172 = emitc.call_opaque "XAie_TileLoc"(%23, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %173 = emitc.call_opaque "__runtime_buffer_arg"(%171) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %174 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %172, %173, %42, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(6,0), direction=MM2S */"
    %175 = emitc.call_opaque "__Runtime_dma_createio_4"(%172, %174, %42, %42, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %176 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %177 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %50, %176, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %178 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %179 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %50, %178, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %180 = emitc.call_opaque "__Runtime_dma_createio_4"(%50, %179, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %181 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %182 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %78, %181, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %183 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %184 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %78, %183, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %185 = emitc.call_opaque "__Runtime_dma_createio_4"(%78, %184, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %186 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %187 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %111, %186, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %188 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %189 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %111, %188, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %190 = emitc.call_opaque "__Runtime_dma_createio_4"(%111, %189, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %191 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %192 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %143, %191, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %193 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %194 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %143, %193, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %195 = emitc.call_opaque "__Runtime_dma_createio_4"(%143, %194, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (6,0) */"
    %196 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %197 = emitc.call_opaque "__runtime_buffer_arg"(%196) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %198 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%36, %107, %197, %41, %44, %33, %32, %42, %42, %42, %42, %42, %42, %40, %38, %43, %16, %38, %38, %38, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    %199 = emitc.call_opaque "__Runtime_dma_createio_4"(%107, %198, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %200 = emitc.call_opaque "__runtime_buffer_offset"(%196, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %201 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %202 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %50, %201, %39, %44, %13, %38, %43, %43, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %203 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %204 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %50, %203, %38, %44, %13, %39, %43, %43, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %205 = emitc.call_opaque "__Runtime_dma_createio_4"(%50, %204, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %206 = emitc.call_opaque "__runtime_buffer_offset"(%196, %12) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %207 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %208 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %78, %207, %39, %44, %13, %38, %43, %41, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %209 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %210 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %78, %209, %38, %44, %13, %39, %43, %41, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %211 = emitc.call_opaque "__Runtime_dma_createio_4"(%78, %210, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %212 = emitc.call_opaque "__runtime_buffer_offset"(%196, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %213 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %214 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %111, %213, %39, %44, %13, %38, %43, %40, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %215 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %216 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %111, %215, %38, %44, %13, %39, %43, %40, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %217 = emitc.call_opaque "__Runtime_dma_createio_4"(%111, %216, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %218 = emitc.call_opaque "__runtime_buffer_offset"(%196, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %219 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %220 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %143, %219, %39, %44, %13, %38, %43, %38, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %221 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %222 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %143, %221, %38, %44, %13, %39, %43, %38, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %223 = emitc.call_opaque "__Runtime_dma_createio_4"(%143, %222, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %224 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %225 = emitc.call_opaque "__runtime_buffer_arg"(%224) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %226 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %172, %225, %43, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(6,0), direction=MM2S */"
    %227 = emitc.call_opaque "__Runtime_dma_createio_4"(%172, %226, %43, %43, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %228 = emitc.call_opaque "__runtime_buffer_offset"(%224, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %229 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %230 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %56, %229, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %231 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %232 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %56, %231, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %233 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %232, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %234 = emitc.call_opaque "__runtime_buffer_offset"(%224, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %235 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %236 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %85, %235, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %237 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %238 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %85, %237, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %239 = emitc.call_opaque "__Runtime_dma_createio_4"(%85, %238, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %240 = emitc.call_opaque "__runtime_buffer_offset"(%224, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %241 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %242 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %118, %241, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %243 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %244 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %118, %243, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %245 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %244, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %246 = emitc.call_opaque "__runtime_buffer_offset"(%224, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %247 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %248 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %150, %247, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %249 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %250 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %150, %249, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %251 = emitc.call_opaque "__Runtime_dma_createio_4"(%150, %250, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (6,0) */"
    %252 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %22) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %253 = emitc.call_opaque "__runtime_buffer_arg"(%252) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%36, %107, %253, %40, %44, %33, %32, %42, %42, %42, %42, %42, %42, %40, %38, %43, %16, %38, %38, %38, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(3,0), direction=S2MM */"
    %255 = emitc.call_opaque "__Runtime_dma_createio_4"(%107, %254, %43, %40, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %256 = emitc.call_opaque "__runtime_buffer_offset"(%252, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %257 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %258 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %56, %257, %39, %44, %13, %38, %43, %39, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %259 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %260 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %56, %259, %38, %44, %13, %39, %43, %39, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %261 = emitc.call_opaque "__Runtime_dma_createio_4"(%56, %260, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %262 = emitc.call_opaque "__runtime_buffer_offset"(%252, %12) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %263 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %264 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %85, %263, %39, %44, %13, %38, %43, %9, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %265 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %266 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %85, %265, %38, %44, %13, %39, %43, %9, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %267 = emitc.call_opaque "__Runtime_dma_createio_4"(%85, %266, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %268 = emitc.call_opaque "__runtime_buffer_offset"(%252, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %269 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %270 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %118, %269, %39, %44, %13, %38, %43, %8, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %271 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %118, %271, %38, %44, %13, %39, %43, %8, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %273 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %272, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %274 = emitc.call_opaque "__runtime_buffer_offset"(%252, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %275 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %276 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %150, %275, %39, %44, %13, %38, %43, %13, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %277 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %278 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %150, %277, %38, %44, %13, %39, %43, %13, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %279 = emitc.call_opaque "__Runtime_dma_createio_4"(%150, %278, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %280 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %281 = emitc.call_opaque "XAie_TileLoc"(%7, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %282 = emitc.call_opaque "__runtime_buffer_arg"(%280) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %283 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %281, %282, %42, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(7,0), direction=MM2S */"
    %284 = emitc.call_opaque "__Runtime_dma_createio_4"(%281, %283, %42, %42, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %285 = emitc.call_opaque "__runtime_buffer_offset"(%280, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %286 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %287 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %62, %286, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %288 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %289 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %62, %288, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %290 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %289, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %291 = emitc.call_opaque "__runtime_buffer_offset"(%280, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %292 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %293 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %92, %292, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %294 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %295 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %92, %294, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %296 = emitc.call_opaque "__Runtime_dma_createio_4"(%92, %295, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %297 = emitc.call_opaque "__runtime_buffer_offset"(%280, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %298 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %299 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %125, %298, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %300 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %301 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %125, %300, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %302 = emitc.call_opaque "__Runtime_dma_createio_4"(%125, %301, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %303 = emitc.call_opaque "__runtime_buffer_offset"(%280, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %304 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %305 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %157, %304, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %306 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %307 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %157, %306, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %308 = emitc.call_opaque "__Runtime_dma_createio_4"(%157, %307, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (7,0) */"
    %309 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %310 = emitc.call_opaque "__runtime_buffer_arg"(%309) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %311 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%36, %46, %310, %41, %44, %33, %32, %42, %42, %42, %42, %42, %42, %40, %38, %43, %16, %38, %38, %38, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,0), direction=S2MM */"
    %312 = emitc.call_opaque "__Runtime_dma_createio_4"(%46, %311, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %313 = emitc.call_opaque "__runtime_buffer_offset"(%309, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %314 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %315 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %62, %314, %39, %44, %13, %38, %43, %6, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %316 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %317 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %62, %316, %38, %44, %13, %39, %43, %6, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %318 = emitc.call_opaque "__Runtime_dma_createio_4"(%62, %317, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %319 = emitc.call_opaque "__runtime_buffer_offset"(%309, %12) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %320 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %321 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %92, %320, %39, %44, %13, %38, %43, %5, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %322 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %323 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %92, %322, %38, %44, %13, %39, %43, %5, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %324 = emitc.call_opaque "__Runtime_dma_createio_4"(%92, %323, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %325 = emitc.call_opaque "__runtime_buffer_offset"(%309, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %326 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %327 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %125, %326, %39, %44, %13, %38, %43, %4, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %328 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %329 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %125, %328, %38, %44, %13, %39, %43, %4, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %330 = emitc.call_opaque "__Runtime_dma_createio_4"(%125, %329, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %331 = emitc.call_opaque "__runtime_buffer_offset"(%309, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %332 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %333 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %157, %332, %39, %44, %13, %38, %43, %3, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %334 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %335 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %157, %334, %38, %44, %13, %39, %43, %3, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %336 = emitc.call_opaque "__Runtime_dma_createio_4"(%157, %335, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %337 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %338 = emitc.call_opaque "__runtime_buffer_arg"(%337) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %339 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %281, %338, %43, %44, %33, %32, %42, %42, %42, %42, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(7,0), direction=MM2S */"
    %340 = emitc.call_opaque "__Runtime_dma_createio_4"(%281, %339, %43, %43, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %341 = emitc.call_opaque "__runtime_buffer_offset"(%337, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %342 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %343 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %68, %342, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %344 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %345 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %68, %344, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %346 = emitc.call_opaque "__Runtime_dma_createio_4"(%68, %345, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %347 = emitc.call_opaque "__runtime_buffer_offset"(%337, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %348 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %349 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %99, %348, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %350 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %351 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %99, %350, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %352 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %351, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %353 = emitc.call_opaque "__runtime_buffer_offset"(%337, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %354 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %355 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %132, %354, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %356 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %357 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %132, %356, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %358 = emitc.call_opaque "__Runtime_dma_createio_4"(%132, %357, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %359 = emitc.call_opaque "__runtime_buffer_offset"(%337, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %360 = emitc.call_opaque "__runtime_buffer_arg"(%17) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %361 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %164, %360, %40, %44, %27, %41, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %362 = emitc.call_opaque "__runtime_buffer_arg"(%18) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %363 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %164, %362, %41, %44, %27, %40, %42, %42, %42, %32, %43, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %364 = emitc.call_opaque "__Runtime_dma_createio_4"(%164, %363, %42, %41, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (7,0) */"
    %365 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %366 = emitc.call_opaque "__runtime_buffer_arg"(%365) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %367 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%36, %46, %366, %40, %44, %33, %32, %42, %42, %42, %42, %42, %42, %40, %38, %43, %16, %38, %38, %38, %42, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(2,0), direction=S2MM */"
    %368 = emitc.call_opaque "__Runtime_dma_createio_4"(%46, %367, %43, %40, %26) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %369 = emitc.call_opaque "__runtime_buffer_offset"(%365, %44) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %370 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %371 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %68, %370, %39, %44, %13, %38, %43, %2, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %372 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %373 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %68, %372, %38, %44, %13, %39, %43, %2, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %374 = emitc.call_opaque "__Runtime_dma_createio_4"(%68, %373, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %375 = emitc.call_opaque "__runtime_buffer_offset"(%365, %12) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %376 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %377 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %99, %376, %39, %44, %13, %38, %43, %1, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %378 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %379 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %99, %378, %38, %44, %13, %39, %43, %1, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %380 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %379, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %381 = emitc.call_opaque "__runtime_buffer_offset"(%365, %11) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %382 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %383 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %132, %382, %39, %44, %13, %38, %43, %0, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %384 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %385 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %132, %384, %38, %44, %13, %39, %43, %0, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %386 = emitc.call_opaque "__Runtime_dma_createio_4"(%132, %385, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %387 = emitc.call_opaque "__runtime_buffer_offset"(%365, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %388 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %389 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %164, %388, %39, %44, %13, %38, %43, %16, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %390 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %391 = emitc.call_opaque "__Runtime_dma_bd_config"(%36, %164, %390, %38, %44, %13, %39, %43, %16, %39, %32, %38, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %392 = emitc.call_opaque "__Runtime_dma_createio_4"(%164, %391, %42, %38, %31) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %393 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%50, %56, %62, %68, %78, %85, %92, %99, %111, %118, %125, %132, %143, %150, %157, %164, %16) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %394 = emitc.call_opaque "__Runtime_launch_kernel_group"(%393) : (!emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %395 = emitc.call_opaque "__Runtime_startio"(%55, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %396 = emitc.call_opaque "__Runtime_startio"(%61, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %397 = emitc.call_opaque "__Runtime_startio"(%67, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %398 = emitc.call_opaque "__Runtime_startio"(%73, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %399 = emitc.call_opaque "__Runtime_startio"(%49, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %400 = emitc.call_opaque "__Runtime_startio"(%84, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %401 = emitc.call_opaque "__Runtime_startio"(%91, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %402 = emitc.call_opaque "__Runtime_startio"(%98, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %403 = emitc.call_opaque "__Runtime_startio"(%105, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %404 = emitc.call_opaque "__Runtime_startio"(%77, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %405 = emitc.call_opaque "__Runtime_startio"(%117, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %406 = emitc.call_opaque "__Runtime_startio"(%124, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %407 = emitc.call_opaque "__Runtime_startio"(%131, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %408 = emitc.call_opaque "__Runtime_startio"(%138, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %409 = emitc.call_opaque "__Runtime_startio"(%110, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %410 = emitc.call_opaque "__Runtime_startio"(%149, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %411 = emitc.call_opaque "__Runtime_startio"(%156, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %412 = emitc.call_opaque "__Runtime_startio"(%163, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %413 = emitc.call_opaque "__Runtime_startio"(%170, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %414 = emitc.call_opaque "__Runtime_startio"(%142, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %415 = emitc.call_opaque "__Runtime_startio"(%180, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %416 = emitc.call_opaque "__Runtime_startio"(%185, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %417 = emitc.call_opaque "__Runtime_startio"(%190, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %418 = emitc.call_opaque "__Runtime_startio"(%195, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %419 = emitc.call_opaque "__Runtime_startio"(%175, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %420 = emitc.call_opaque "__Runtime_startio"(%205, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %421 = emitc.call_opaque "__Runtime_startio"(%211, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %422 = emitc.call_opaque "__Runtime_startio"(%217, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %423 = emitc.call_opaque "__Runtime_startio"(%223, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %424 = emitc.call_opaque "__Runtime_startio"(%199, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %425 = emitc.call_opaque "__Runtime_startio"(%233, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %426 = emitc.call_opaque "__Runtime_startio"(%239, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %427 = emitc.call_opaque "__Runtime_startio"(%245, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %428 = emitc.call_opaque "__Runtime_startio"(%251, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %429 = emitc.call_opaque "__Runtime_startio"(%227, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %430 = emitc.call_opaque "__Runtime_startio"(%261, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %431 = emitc.call_opaque "__Runtime_startio"(%267, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %432 = emitc.call_opaque "__Runtime_startio"(%273, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %433 = emitc.call_opaque "__Runtime_startio"(%279, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %434 = emitc.call_opaque "__Runtime_startio"(%255, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %435 = emitc.call_opaque "__Runtime_startio"(%290, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %436 = emitc.call_opaque "__Runtime_startio"(%296, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %437 = emitc.call_opaque "__Runtime_startio"(%302, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %438 = emitc.call_opaque "__Runtime_startio"(%308, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %439 = emitc.call_opaque "__Runtime_startio"(%284, %42) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %440 = emitc.call_opaque "__Runtime_startio"(%318, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %441 = emitc.call_opaque "__Runtime_startio"(%324, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %442 = emitc.call_opaque "__Runtime_startio"(%330, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %443 = emitc.call_opaque "__Runtime_startio"(%336, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %444 = emitc.call_opaque "__Runtime_startio"(%312, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %445 = emitc.call_opaque "__Runtime_startio"(%346, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %446 = emitc.call_opaque "__Runtime_startio"(%352, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %447 = emitc.call_opaque "__Runtime_startio"(%358, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %448 = emitc.call_opaque "__Runtime_startio"(%364, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %449 = emitc.call_opaque "__Runtime_startio"(%340, %43) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %450 = emitc.call_opaque "__Runtime_startio"(%374, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %451 = emitc.call_opaque "__Runtime_startio"(%380, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %452 = emitc.call_opaque "__Runtime_startio"(%386, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %453 = emitc.call_opaque "__Runtime_startio"(%392, %41) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %454 = emitc.call_opaque "__Runtime_startio"(%368, %40) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%394) : (!emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%399) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%404) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%409) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%414) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%419) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%424) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%429) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%434) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%439) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%444) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%449) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%454) : (!emitc.opaque<"ioevent">) -> ()
    emitc.verbatim "/* AieRt debug snapshot */"
    emitc.verbatim "{"
    emitc.verbatim "  uint8_t _dbg_io_cols[] = {2, 0, 0, 0, 0, 2, 1, 1, 1, 1, 3, 2, 2, 2, 2, 3, 3, 3, 3, 3, 6, 0, 1, 2, 3, 3, 0, 1, 2, 3, 6, 0, 1, 2, 3, 3, 0, 1, 2, 3, 7, 0, 1, 2, 3, 2, 0, 1, 2, 3, 7, 0, 1, 2, 3, 2, 0, 1, 2, 3};"
    emitc.verbatim "  uint8_t _dbg_io_rows[] = {0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 3, 3, 3, 0, 3, 3, 3, 3, 0, 4, 4, 4, 4, 0, 4, 4, 4, 4, 0, 5, 5, 5, 5, 0, 5, 5, 5, 5, 0, 6, 6, 6, 6, 0, 6, 6, 6, 6};"
    emitc.verbatim "  uint8_t _dbg_io_chs[] = {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0};"
    emitc.verbatim "  uint8_t _dbg_io_bds[] = {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 4, 4, 4, 4, 1, 2, 2, 2, 2, 3, 4, 4, 4, 4, 0, 2, 2, 2, 2, 2, 4, 4, 4, 4, 1, 2, 2, 2, 2, 3, 4, 4, 4, 4};"
    emitc.verbatim "  int _dbg_io_dirs[] = {DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S};"
    emitc.verbatim "  uint8_t _dbg_t_cols[] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3};"
    emitc.verbatim "  uint8_t _dbg_t_rows[] = {3, 4, 5, 6, 3, 4, 5, 6, 3, 4, 5, 6, 3, 4, 5, 6};"
    emitc.verbatim "  AieRt_DebugSnapshotFromCoords(g_DevInst,\0A      _dbg_io_cols, _dbg_io_rows, _dbg_io_chs, _dbg_io_bds, _dbg_io_dirs, 60,\0A      _dbg_t_cols, _dbg_t_rows, 16);"
    emitc.verbatim "}"
    emitc.return
  }
  emitc.func @dskernel_receiver(%arg0: index) attributes {specifiers = ["__global__"]} {
    emitc.verbatim "// the real kernel will be emitted separately\0A"
    emitc.return
  }
}
