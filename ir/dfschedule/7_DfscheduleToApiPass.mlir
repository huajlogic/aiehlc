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
    %0 = "emitc.constant"() <{value = #emitc.opaque<"g_DevInst">}> : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
    %1 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_MEM_CACHEABLE">}> : () -> i32
    %2 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %3 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %4 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %5 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %6 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %7 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %8 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %9 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %8) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %10 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %11 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %12 = emitc.call_opaque "XAie_TileLoc"(%10, %11) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %13 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %14 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %15 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %16 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %17 = emitc.call_opaque "__runtime_buffer_arg"(%9) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %18 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %19 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %20 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %21 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %22 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %23 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %24 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %12, %17, %6, %18, %14, %15, %23, %16, %19, %20, %21, %22) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %25 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %26 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %27 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %28 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %24, %25, %26, %27) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %29 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %30 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %31 = emitc.call_opaque "XAie_TileLoc"(%29, %30) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %32 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %33 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %34 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %35 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %36 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %37 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %38 = emitc.call_opaque "__runtime_buffer_arg"(%33) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %39 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %40 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %43 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %44 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %45 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %38, %7, %39, %35, %36, %44, %37, %40, %41, %42, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %46 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %47 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %48 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %49 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %50 = emitc.call_opaque "__runtime_buffer_arg"(%32) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %51 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %52 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %53 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %54 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %55 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %56 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %57 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %50, %6, %51, %47, %48, %56, %49, %52, %53, %54, %55) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %58 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %59 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %60 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %61 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %57, %58, %59, %60) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %62 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %63 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %64 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %65 = emitc.call_opaque "XAie_TileLoc"(%63, %64) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %66 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %67 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %68 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %69 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %70 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %71 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %72 = emitc.call_opaque "__runtime_buffer_arg"(%67) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %73 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %74 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %75 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %76 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %77 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %78 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %79 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %72, %7, %73, %69, %70, %78, %71, %74, %75, %76, %77) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %80 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %81 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %82 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %83 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %84 = emitc.call_opaque "__runtime_buffer_arg"(%66) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %85 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %86 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %87 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %88 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %89 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %90 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %91 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %84, %6, %85, %81, %82, %90, %83, %86, %87, %88, %89) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %92 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %93 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %94 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %95 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %91, %92, %93, %94) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %96 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %97 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %98 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %99 = emitc.call_opaque "XAie_TileLoc"(%97, %98) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %100 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %101 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %102 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %103 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %104 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %105 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %106 = emitc.call_opaque "__runtime_buffer_arg"(%101) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %107 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %108 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %109 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %110 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %111 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %112 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %113 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %99, %106, %7, %107, %103, %104, %112, %105, %108, %109, %110, %111) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %114 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %115 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %116 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %117 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %118 = emitc.call_opaque "__runtime_buffer_arg"(%100) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %119 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %120 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %121 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %122 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %123 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %124 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %125 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %99, %118, %6, %119, %115, %116, %124, %117, %120, %121, %122, %123) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %126 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %127 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %128 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %129 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %125, %126, %127, %128) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %130 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %131 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %132 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %133 = emitc.call_opaque "XAie_TileLoc"(%131, %132) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %134 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %135 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %136 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %137 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %138 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %139 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %140 = emitc.call_opaque "__runtime_buffer_arg"(%135) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %141 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %142 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %143 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %144 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %145 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %147 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %133, %140, %7, %141, %137, %138, %146, %139, %142, %143, %144, %145) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %148 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %149 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %150 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %151 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %152 = emitc.call_opaque "__runtime_buffer_arg"(%134) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %153 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %154 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %155 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %156 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %157 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %158 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %159 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %133, %152, %6, %153, %149, %150, %158, %151, %154, %155, %156, %157) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %160 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %161 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %162 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %163 = emitc.call_opaque "__Runtime_dma_createio_4"(%133, %159, %160, %161, %162) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    %164 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %165 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %166 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %167 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %166) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %168 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %169 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %170 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %171 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %172 = emitc.call_opaque "__runtime_buffer_arg"(%167) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %173 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %174 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %175 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %176 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %177 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %178 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %179 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %12, %172, %7, %173, %169, %170, %178, %171, %174, %175, %176, %177) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %180 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %181 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %182 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %183 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %179, %180, %181, %182) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %184 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %185 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %186 = emitc.call_opaque "XAie_TileLoc"(%184, %185) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %187 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %188 = emitc.call_opaque "__runtime_buffer_offset"(%167, %187) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %189 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %190 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %191 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %192 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %193 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %194 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %195 = emitc.call_opaque "__runtime_buffer_arg"(%190) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %196 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %197 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %198 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %199 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %200 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %201 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %202 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %186, %195, %7, %196, %192, %193, %201, %194, %197, %198, %199, %200) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %203 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %204 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %205 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %206 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %207 = emitc.call_opaque "__runtime_buffer_arg"(%189) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %208 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %209 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %210 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %211 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %212 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %213 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %214 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %186, %207, %6, %208, %204, %205, %213, %206, %209, %210, %211, %212) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %215 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %216 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %217 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %218 = emitc.call_opaque "__Runtime_dma_createio_4"(%186, %214, %215, %216, %217) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %219 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %220 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %221 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %222 = emitc.call_opaque "XAie_TileLoc"(%220, %221) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %223 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %224 = emitc.call_opaque "__runtime_buffer_offset"(%167, %223) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %225 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %226 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %227 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %228 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %229 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %230 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %231 = emitc.call_opaque "__runtime_buffer_arg"(%226) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %232 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %233 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %234 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %235 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %236 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %237 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %238 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %222, %231, %7, %232, %228, %229, %237, %230, %233, %234, %235, %236) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %239 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %240 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %241 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %242 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %243 = emitc.call_opaque "__runtime_buffer_arg"(%225) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %244 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %245 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %246 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %247 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %248 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %249 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %250 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %222, %243, %6, %244, %240, %241, %249, %242, %245, %246, %247, %248) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %251 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %252 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %253 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %254 = emitc.call_opaque "__Runtime_dma_createio_4"(%222, %250, %251, %252, %253) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %255 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %256 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %257 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %258 = emitc.call_opaque "XAie_TileLoc"(%256, %257) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %259 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %260 = emitc.call_opaque "__runtime_buffer_offset"(%167, %259) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %261 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %262 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %263 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %264 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %265 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %266 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %267 = emitc.call_opaque "__runtime_buffer_arg"(%262) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %268 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %269 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %270 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %271 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %272 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %273 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %274 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %258, %267, %7, %268, %264, %265, %273, %266, %269, %270, %271, %272) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %275 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %276 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %277 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %278 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %279 = emitc.call_opaque "__runtime_buffer_arg"(%261) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %280 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %281 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %282 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %283 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %284 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %286 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %258, %279, %6, %280, %276, %277, %285, %278, %281, %282, %283, %284) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %287 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %288 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %289 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %290 = emitc.call_opaque "__Runtime_dma_createio_4"(%258, %286, %287, %288, %289) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %291 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %292 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %293 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %294 = emitc.call_opaque "XAie_TileLoc"(%292, %293) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %295 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %296 = emitc.call_opaque "__runtime_buffer_offset"(%167, %295) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %297 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %298 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %299 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %300 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %301 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %302 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %303 = emitc.call_opaque "__runtime_buffer_arg"(%298) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %304 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %305 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %306 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %307 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %308 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %309 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %310 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %294, %303, %7, %304, %300, %301, %309, %302, %305, %306, %307, %308) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %311 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %312 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %313 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %314 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %315 = emitc.call_opaque "__runtime_buffer_arg"(%297) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %316 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %317 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %318 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %319 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %320 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %321 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %322 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %294, %315, %6, %316, %312, %313, %321, %314, %317, %318, %319, %320) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %323 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %324 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %325 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %326 = emitc.call_opaque "__Runtime_dma_createio_4"(%294, %322, %323, %324, %325) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    %327 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %328 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %329 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %330 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %329) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %331 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %332 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %333 = emitc.call_opaque "XAie_TileLoc"(%331, %332) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %334 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %335 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %336 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %337 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %338 = emitc.call_opaque "__runtime_buffer_arg"(%330) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %339 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %340 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %341 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %342 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %343 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %344 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %345 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %333, %338, %6, %339, %335, %336, %344, %337, %340, %341, %342, %343) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %346 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %347 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %348 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %349 = emitc.call_opaque "__Runtime_dma_createio_4"(%333, %345, %346, %347, %348) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %350 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %351 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %352 = emitc.call_opaque "XAie_TileLoc"(%350, %351) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %353 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %354 = emitc.call_opaque "__runtime_buffer_offset"(%330, %353) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %355 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %356 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %357 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %358 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %359 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %360 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %361 = emitc.call_opaque "__runtime_buffer_arg"(%356) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %362 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %363 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %364 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %365 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %366 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %368 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %352, %361, %7, %362, %358, %359, %367, %360, %363, %364, %365, %366) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %369 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %370 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %371 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %373 = emitc.call_opaque "__runtime_buffer_arg"(%355) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %374 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %375 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %376 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %377 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %378 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %379 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %380 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %352, %373, %6, %374, %370, %371, %379, %372, %375, %376, %377, %378) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %381 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %382 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %383 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %384 = emitc.call_opaque "__Runtime_dma_createio_4"(%352, %380, %381, %382, %383) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %385 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %386 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %387 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %388 = emitc.call_opaque "XAie_TileLoc"(%386, %387) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %389 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %390 = emitc.call_opaque "__runtime_buffer_offset"(%330, %389) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %391 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %392 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %393 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %394 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %395 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %396 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %397 = emitc.call_opaque "__runtime_buffer_arg"(%392) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %398 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %399 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %400 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %401 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %402 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %403 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %404 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %388, %397, %7, %398, %394, %395, %403, %396, %399, %400, %401, %402) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %406 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %407 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %408 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %409 = emitc.call_opaque "__runtime_buffer_arg"(%391) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %410 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %411 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %412 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %413 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %414 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %415 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %416 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %388, %409, %6, %410, %406, %407, %415, %408, %411, %412, %413, %414) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %417 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %418 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %419 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %420 = emitc.call_opaque "__Runtime_dma_createio_4"(%388, %416, %417, %418, %419) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %421 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %422 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %423 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %424 = emitc.call_opaque "XAie_TileLoc"(%422, %423) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %425 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %426 = emitc.call_opaque "__runtime_buffer_offset"(%330, %425) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %427 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %428 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %429 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %430 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %431 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %432 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %433 = emitc.call_opaque "__runtime_buffer_arg"(%428) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %434 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %435 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %436 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %437 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %438 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %439 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %440 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %424, %433, %7, %434, %430, %431, %439, %432, %435, %436, %437, %438) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %441 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %442 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %443 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %444 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %445 = emitc.call_opaque "__runtime_buffer_arg"(%427) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %446 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %447 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %448 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %449 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %450 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %451 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %452 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %424, %445, %6, %446, %442, %443, %451, %444, %447, %448, %449, %450) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %453 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %454 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %455 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %456 = emitc.call_opaque "__Runtime_dma_createio_4"(%424, %452, %453, %454, %455) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %457 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %458 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %459 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %460 = emitc.call_opaque "XAie_TileLoc"(%458, %459) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %461 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %462 = emitc.call_opaque "__runtime_buffer_offset"(%330, %461) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %463 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %464 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %465 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %466 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %467 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %468 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %469 = emitc.call_opaque "__runtime_buffer_arg"(%464) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %470 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %471 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %472 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %473 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %474 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %475 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %476 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %460, %469, %7, %470, %466, %467, %475, %468, %471, %472, %473, %474) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %477 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %478 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %479 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %480 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %481 = emitc.call_opaque "__runtime_buffer_arg"(%463) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %482 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %483 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %484 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %485 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %486 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %487 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %488 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %460, %481, %6, %482, %478, %479, %487, %480, %483, %484, %485, %486) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %489 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %490 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %491 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %492 = emitc.call_opaque "__Runtime_dma_createio_4"(%460, %488, %489, %490, %491) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    %493 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %494 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %495 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %496 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %495) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %497 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %498 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %499 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %500 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %501 = emitc.call_opaque "__runtime_buffer_arg"(%496) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %502 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %503 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %504 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %505 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %506 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %507 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %508 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %333, %501, %7, %502, %498, %499, %507, %500, %503, %504, %505, %506) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %509 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %510 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %511 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(3,0), direction=MM2S */"
    %512 = emitc.call_opaque "__Runtime_dma_createio_4"(%333, %508, %509, %510, %511) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %513 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %514 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %515 = emitc.call_opaque "XAie_TileLoc"(%513, %514) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %516 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %517 = emitc.call_opaque "__runtime_buffer_offset"(%496, %516) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %518 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %519 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %520 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %521 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %522 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %523 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %524 = emitc.call_opaque "__runtime_buffer_arg"(%519) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %525 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %526 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %527 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %528 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %529 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %530 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %531 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %515, %524, %7, %525, %521, %522, %530, %523, %526, %527, %528, %529) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %532 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %533 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %534 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %535 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %536 = emitc.call_opaque "__runtime_buffer_arg"(%518) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %537 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %538 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %539 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %540 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %541 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %542 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %543 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %515, %536, %6, %537, %533, %534, %542, %535, %538, %539, %540, %541) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %544 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %545 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %546 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %547 = emitc.call_opaque "__Runtime_dma_createio_4"(%515, %543, %544, %545, %546) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %548 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %549 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %550 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %551 = emitc.call_opaque "XAie_TileLoc"(%549, %550) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %552 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %553 = emitc.call_opaque "__runtime_buffer_offset"(%496, %552) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %554 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %555 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %556 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %557 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %558 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %559 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %560 = emitc.call_opaque "__runtime_buffer_arg"(%555) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %561 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %562 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %563 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %564 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %565 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %566 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %567 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %551, %560, %7, %561, %557, %558, %566, %559, %562, %563, %564, %565) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %568 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %569 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %570 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %571 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %572 = emitc.call_opaque "__runtime_buffer_arg"(%554) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %573 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %574 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %575 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %576 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %577 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %578 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %579 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %551, %572, %6, %573, %569, %570, %578, %571, %574, %575, %576, %577) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %580 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %581 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %582 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %583 = emitc.call_opaque "__Runtime_dma_createio_4"(%551, %579, %580, %581, %582) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %584 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %585 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %586 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %587 = emitc.call_opaque "XAie_TileLoc"(%585, %586) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %588 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %589 = emitc.call_opaque "__runtime_buffer_offset"(%496, %588) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %590 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %591 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %592 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %593 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %594 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %595 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %596 = emitc.call_opaque "__runtime_buffer_arg"(%591) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %597 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %598 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %599 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %600 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %601 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %602 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %603 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %587, %596, %7, %597, %593, %594, %602, %595, %598, %599, %600, %601) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %604 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %605 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %606 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %607 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %608 = emitc.call_opaque "__runtime_buffer_arg"(%590) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %609 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %610 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %611 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %612 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %613 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %614 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %615 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %587, %608, %6, %609, %605, %606, %614, %607, %610, %611, %612, %613) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %616 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %617 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %618 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %619 = emitc.call_opaque "__Runtime_dma_createio_4"(%587, %615, %616, %617, %618) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %620 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %621 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %622 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %623 = emitc.call_opaque "XAie_TileLoc"(%621, %622) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %624 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %625 = emitc.call_opaque "__runtime_buffer_offset"(%496, %624) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %626 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %627 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32800">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %628 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %629 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %630 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %631 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %632 = emitc.call_opaque "__runtime_buffer_arg"(%627) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %633 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %634 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %635 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %636 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %637 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %638 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %639 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %623, %632, %7, %633, %629, %630, %638, %631, %634, %635, %636, %637) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %640 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %641 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %642 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %643 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %644 = emitc.call_opaque "__runtime_buffer_arg"(%626) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %645 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %646 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %647 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %648 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %649 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %650 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %651 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %623, %644, %6, %645, %641, %642, %650, %643, %646, %647, %648, %649) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %652 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %653 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %654 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %655 = emitc.call_opaque "__Runtime_dma_createio_4"(%623, %651, %652, %653, %654) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    %656 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %657 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %658 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %659 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %658) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %660 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %661 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %662 = emitc.call_opaque "XAie_TileLoc"(%660, %661) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %663 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %664 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %665 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %666 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %667 = emitc.call_opaque "__runtime_buffer_arg"(%659) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %668 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %669 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %670 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %671 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %672 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %673 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %674 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %662, %667, %6, %668, %664, %665, %673, %666, %669, %670, %671, %672) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %675 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %676 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %677 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(6,0), direction=MM2S */"
    %678 = emitc.call_opaque "__Runtime_dma_createio_4"(%662, %674, %675, %676, %677) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %679 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %680 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %681 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %682 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %683 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %684 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %685 = emitc.call_opaque "__runtime_buffer_arg"(%680) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %686 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %687 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %688 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %689 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %690 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %691 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %692 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %685, %4, %686, %682, %683, %691, %684, %687, %688, %689, %690) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %693 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %694 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %695 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %696 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %697 = emitc.call_opaque "__runtime_buffer_arg"(%679) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %698 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %699 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %700 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %701 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %702 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %703 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %704 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %697, %5, %698, %694, %695, %703, %696, %699, %700, %701, %702) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %705 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %706 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %707 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %708 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %704, %705, %706, %707) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    %709 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %710 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %711 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %712 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %713 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %714 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %715 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %716 = emitc.call_opaque "__runtime_buffer_arg"(%711) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %717 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %718 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %719 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %720 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %721 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %722 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %723 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %186, %716, %4, %717, %713, %714, %722, %715, %718, %719, %720, %721) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %724 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %725 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %726 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %727 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %728 = emitc.call_opaque "__runtime_buffer_arg"(%710) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %729 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %730 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %731 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %732 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %733 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %734 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %735 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %186, %728, %5, %729, %725, %726, %734, %727, %730, %731, %732, %733) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %736 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %737 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %738 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %739 = emitc.call_opaque "__Runtime_dma_createio_4"(%186, %735, %736, %737, %738) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    %740 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %741 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %742 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %743 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %744 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %745 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %746 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %747 = emitc.call_opaque "__runtime_buffer_arg"(%742) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %748 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %749 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %750 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %751 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %752 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %753 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %754 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %352, %747, %4, %748, %744, %745, %753, %746, %749, %750, %751, %752) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %755 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %756 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %757 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %758 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %759 = emitc.call_opaque "__runtime_buffer_arg"(%741) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %760 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %761 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %762 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %763 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %764 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %765 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %766 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %352, %759, %5, %760, %756, %757, %765, %758, %761, %762, %763, %764) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %767 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %768 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %769 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %770 = emitc.call_opaque "__Runtime_dma_createio_4"(%352, %766, %767, %768, %769) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    %771 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %772 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %773 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %774 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %775 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %776 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %777 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %778 = emitc.call_opaque "__runtime_buffer_arg"(%773) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %779 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %780 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %781 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %782 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %783 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %784 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %785 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %515, %778, %4, %779, %775, %776, %784, %777, %780, %781, %782, %783) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %786 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %787 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %788 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %789 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %790 = emitc.call_opaque "__runtime_buffer_arg"(%772) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %791 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %792 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %793 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %794 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %795 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %796 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %797 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %515, %790, %5, %791, %787, %788, %796, %789, %792, %793, %794, %795) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %798 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %799 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %800 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %801 = emitc.call_opaque "__Runtime_dma_createio_4"(%515, %797, %798, %799, %800) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    %802 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (6,0) */"
    %803 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %804 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %805 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %804) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %806 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %807 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %808 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %809 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %810 = emitc.call_opaque "__runtime_buffer_arg"(%805) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %811 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %812 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %813 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %814 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %815 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %816 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %817 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %818 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %819 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %820 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %821 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %822 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %823 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %824 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %825 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %826 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%0, %333, %810, %5, %811, %807, %808, %825, %809, %812, %813, %814, %815, %816, %817, %818, %819, %820, %821, %822, %823, %824) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %827 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %828 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %829 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    %830 = emitc.call_opaque "__Runtime_dma_createio_4"(%333, %826, %827, %828, %829) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %831 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %832 = emitc.call_opaque "__runtime_buffer_offset"(%805, %831) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %833 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %834 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %835 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %836 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %837 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %838 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %839 = emitc.call_opaque "__runtime_buffer_arg"(%834) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %840 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %841 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %842 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %843 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %844 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %845 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %846 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %839, %3, %840, %836, %837, %845, %838, %841, %842, %843, %844) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %847 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %848 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %849 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %850 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %851 = emitc.call_opaque "__runtime_buffer_arg"(%833) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %852 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %853 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %854 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %855 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %856 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %857 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %858 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %851, %2, %852, %848, %849, %857, %850, %853, %854, %855, %856) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %859 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %860 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %861 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %862 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %858, %859, %860, %861) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %863 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %864 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %865 = emitc.call_opaque "__runtime_buffer_offset"(%805, %864) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %866 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %867 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %868 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %869 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %870 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %871 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %872 = emitc.call_opaque "__runtime_buffer_arg"(%867) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %873 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %874 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %875 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %876 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %877 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %878 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %879 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %186, %872, %3, %873, %869, %870, %878, %871, %874, %875, %876, %877) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %880 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %881 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %882 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %883 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %884 = emitc.call_opaque "__runtime_buffer_arg"(%866) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %885 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %886 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %887 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %888 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %889 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %890 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %891 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %186, %884, %2, %885, %881, %882, %890, %883, %886, %887, %888, %889) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %892 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %893 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %894 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %895 = emitc.call_opaque "__Runtime_dma_createio_4"(%186, %891, %892, %893, %894) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %896 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %897 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %898 = emitc.call_opaque "__runtime_buffer_offset"(%805, %897) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %899 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %900 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %901 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %902 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %903 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %904 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %905 = emitc.call_opaque "__runtime_buffer_arg"(%900) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %906 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %907 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %908 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %909 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %910 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %911 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %912 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %352, %905, %3, %906, %902, %903, %911, %904, %907, %908, %909, %910) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %913 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %914 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %915 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %916 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %917 = emitc.call_opaque "__runtime_buffer_arg"(%899) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %918 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %919 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %920 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %921 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %922 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %923 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %924 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %352, %917, %2, %918, %914, %915, %923, %916, %919, %920, %921, %922) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %925 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %926 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %927 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %928 = emitc.call_opaque "__Runtime_dma_createio_4"(%352, %924, %925, %926, %927) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %929 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %930 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %931 = emitc.call_opaque "__runtime_buffer_offset"(%805, %930) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %932 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %933 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %934 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %935 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %936 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %937 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %938 = emitc.call_opaque "__runtime_buffer_arg"(%933) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %939 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %940 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %941 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %942 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %943 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %944 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %945 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %515, %938, %3, %939, %935, %936, %944, %937, %940, %941, %942, %943) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %946 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %947 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %948 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %949 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %950 = emitc.call_opaque "__runtime_buffer_arg"(%932) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %951 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %952 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %953 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %954 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %955 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %956 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %957 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %515, %950, %2, %951, %947, %948, %956, %949, %952, %953, %954, %955) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %958 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %959 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %960 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %961 = emitc.call_opaque "__Runtime_dma_createio_4"(%515, %957, %958, %959, %960) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    %962 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %963 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %964 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %965 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %964) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %966 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %967 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %968 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %969 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %970 = emitc.call_opaque "__runtime_buffer_arg"(%965) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %971 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %972 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %973 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %974 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %975 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %976 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %977 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %662, %970, %7, %971, %967, %968, %976, %969, %972, %973, %974, %975) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %978 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %979 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %980 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(6,0), direction=MM2S */"
    %981 = emitc.call_opaque "__Runtime_dma_createio_4"(%662, %977, %978, %979, %980) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %982 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %983 = emitc.call_opaque "__runtime_buffer_offset"(%965, %982) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %984 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %985 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %986 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %987 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %988 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %989 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %990 = emitc.call_opaque "__runtime_buffer_arg"(%985) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %991 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %992 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %993 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %994 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %995 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %996 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %997 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %990, %4, %991, %987, %988, %996, %989, %992, %993, %994, %995) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %998 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %999 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1000 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1001 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1002 = emitc.call_opaque "__runtime_buffer_arg"(%984) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1003 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1004 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1005 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1006 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1007 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1008 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1009 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %1002, %5, %1003, %999, %1000, %1008, %1001, %1004, %1005, %1006, %1007) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1010 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1011 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1012 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %1013 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %1009, %1010, %1011, %1012) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %1014 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1015 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1016 = emitc.call_opaque "__runtime_buffer_offset"(%965, %1015) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1017 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1018 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1019 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1020 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1021 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1022 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1023 = emitc.call_opaque "__runtime_buffer_arg"(%1018) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1024 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1025 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1026 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1027 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1028 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1029 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1030 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %222, %1023, %4, %1024, %1020, %1021, %1029, %1022, %1025, %1026, %1027, %1028) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1031 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1032 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1033 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1034 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1035 = emitc.call_opaque "__runtime_buffer_arg"(%1017) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1036 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1037 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1038 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1039 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1040 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1041 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1042 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %222, %1035, %5, %1036, %1032, %1033, %1041, %1034, %1037, %1038, %1039, %1040) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1043 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1044 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1045 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %1046 = emitc.call_opaque "__Runtime_dma_createio_4"(%222, %1042, %1043, %1044, %1045) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %1047 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1048 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1049 = emitc.call_opaque "__runtime_buffer_offset"(%965, %1048) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1050 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1051 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1052 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1053 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1054 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1055 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1056 = emitc.call_opaque "__runtime_buffer_arg"(%1051) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1057 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1058 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1059 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1060 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1061 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1062 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1063 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %388, %1056, %4, %1057, %1053, %1054, %1062, %1055, %1058, %1059, %1060, %1061) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1065 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1066 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1067 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1068 = emitc.call_opaque "__runtime_buffer_arg"(%1050) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1069 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1070 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1071 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1072 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1073 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1074 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1075 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %388, %1068, %5, %1069, %1065, %1066, %1074, %1067, %1070, %1071, %1072, %1073) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1076 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1077 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1078 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %1079 = emitc.call_opaque "__Runtime_dma_createio_4"(%388, %1075, %1076, %1077, %1078) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %1080 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1081 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1082 = emitc.call_opaque "__runtime_buffer_offset"(%965, %1081) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1083 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1084 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1085 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1086 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1087 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1088 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1089 = emitc.call_opaque "__runtime_buffer_arg"(%1084) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1090 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1091 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1092 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1093 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1094 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1095 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1096 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %551, %1089, %4, %1090, %1086, %1087, %1095, %1088, %1091, %1092, %1093, %1094) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1097 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1098 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1099 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1100 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1101 = emitc.call_opaque "__runtime_buffer_arg"(%1083) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1102 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1103 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1104 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1105 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1106 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1108 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %551, %1101, %5, %1102, %1098, %1099, %1107, %1100, %1103, %1104, %1105, %1106) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1109 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1110 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1111 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %1112 = emitc.call_opaque "__Runtime_dma_createio_4"(%551, %1108, %1109, %1110, %1111) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    %1113 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (6,0) */"
    %1114 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1115 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1116 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %1115) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %1117 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1118 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1119 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1120 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1121 = emitc.call_opaque "__runtime_buffer_arg"(%1116) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1122 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1123 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1124 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1125 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1126 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1127 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1128 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1129 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1130 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1131 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1132 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1133 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1134 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1135 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1136 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1137 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%0, %333, %1121, %4, %1122, %1118, %1119, %1136, %1120, %1123, %1124, %1125, %1126, %1127, %1128, %1129, %1130, %1131, %1132, %1133, %1134, %1135) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1138 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1139 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1140 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(3,0), direction=S2MM */"
    %1141 = emitc.call_opaque "__Runtime_dma_createio_4"(%333, %1137, %1138, %1139, %1140) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1142 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1143 = emitc.call_opaque "__runtime_buffer_offset"(%1116, %1142) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1144 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1145 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1147 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1148 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1149 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1150 = emitc.call_opaque "__runtime_buffer_arg"(%1145) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1151 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1152 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1153 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1154 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1155 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1156 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1157 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %1150, %3, %1151, %1147, %1148, %1156, %1149, %1152, %1153, %1154, %1155) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1158 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1159 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1160 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1161 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1162 = emitc.call_opaque "__runtime_buffer_arg"(%1144) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1163 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1164 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1165 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1166 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1167 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1168 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1169 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %1162, %2, %1163, %1159, %1160, %1168, %1161, %1164, %1165, %1166, %1167) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1170 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1171 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1172 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %1173 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %1169, %1170, %1171, %1172) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %1174 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1175 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %1176 = emitc.call_opaque "__runtime_buffer_offset"(%1116, %1175) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1177 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1178 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1180 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1181 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1182 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1183 = emitc.call_opaque "__runtime_buffer_arg"(%1178) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1184 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1185 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1186 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1187 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1188 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1189 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1190 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %222, %1183, %3, %1184, %1180, %1181, %1189, %1182, %1185, %1186, %1187, %1188) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1191 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1192 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1193 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1194 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1195 = emitc.call_opaque "__runtime_buffer_arg"(%1177) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1196 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1197 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1198 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1199 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1200 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1201 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1202 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %222, %1195, %2, %1196, %1192, %1193, %1201, %1194, %1197, %1198, %1199, %1200) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1203 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1204 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1205 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %1206 = emitc.call_opaque "__Runtime_dma_createio_4"(%222, %1202, %1203, %1204, %1205) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %1207 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1208 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %1209 = emitc.call_opaque "__runtime_buffer_offset"(%1116, %1208) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1210 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1211 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1212 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1213 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1214 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1215 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1216 = emitc.call_opaque "__runtime_buffer_arg"(%1211) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1217 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1218 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1220 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1221 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1222 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1223 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %388, %1216, %3, %1217, %1213, %1214, %1222, %1215, %1218, %1219, %1220, %1221) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1224 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1225 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1226 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1227 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1228 = emitc.call_opaque "__runtime_buffer_arg"(%1210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1229 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1230 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1231 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1232 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1233 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1234 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1235 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %388, %1228, %2, %1229, %1225, %1226, %1234, %1227, %1230, %1231, %1232, %1233) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1236 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1237 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1238 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %1239 = emitc.call_opaque "__Runtime_dma_createio_4"(%388, %1235, %1236, %1237, %1238) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %1240 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1241 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %1242 = emitc.call_opaque "__runtime_buffer_offset"(%1116, %1241) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1243 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1244 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1245 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1246 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1247 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1248 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1249 = emitc.call_opaque "__runtime_buffer_arg"(%1244) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1250 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1251 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1252 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1253 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1254 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1255 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1256 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %551, %1249, %3, %1250, %1246, %1247, %1255, %1248, %1251, %1252, %1253, %1254) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1257 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1258 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1259 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1260 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1261 = emitc.call_opaque "__runtime_buffer_arg"(%1243) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1262 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1263 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1264 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1265 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1266 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1267 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1268 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %551, %1261, %2, %1262, %1258, %1259, %1267, %1260, %1263, %1264, %1265, %1266) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1269 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1270 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1271 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %1272 = emitc.call_opaque "__Runtime_dma_createio_4"(%551, %1268, %1269, %1270, %1271) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    %1273 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %1274 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1275 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1276 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %1275) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1277 = "emitc.constant"() <{value = 7 : i8}> : () -> i8
    %1278 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %1279 = emitc.call_opaque "XAie_TileLoc"(%1277, %1278) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %1280 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1281 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1282 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1284 = emitc.call_opaque "__runtime_buffer_arg"(%1276) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1285 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1286 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1287 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1288 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1289 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1290 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1291 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %1279, %1284, %6, %1285, %1281, %1282, %1290, %1283, %1286, %1287, %1288, %1289) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1292 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1293 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1294 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(7,0), direction=MM2S */"
    %1295 = emitc.call_opaque "__Runtime_dma_createio_4"(%1279, %1291, %1292, %1293, %1294) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1296 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1297 = emitc.call_opaque "__runtime_buffer_offset"(%1276, %1296) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1298 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1299 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1300 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1301 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1302 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1303 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1304 = emitc.call_opaque "__runtime_buffer_arg"(%1299) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1305 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1306 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1307 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1308 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1309 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1310 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1311 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %99, %1304, %4, %1305, %1301, %1302, %1310, %1303, %1306, %1307, %1308, %1309) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1312 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1313 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1314 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1315 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1316 = emitc.call_opaque "__runtime_buffer_arg"(%1298) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1317 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1318 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1319 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1320 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1321 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1322 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1323 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %99, %1316, %5, %1317, %1313, %1314, %1322, %1315, %1318, %1319, %1320, %1321) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1324 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1325 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1326 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %1327 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %1323, %1324, %1325, %1326) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %1328 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1329 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1330 = emitc.call_opaque "__runtime_buffer_offset"(%1276, %1329) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1331 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1332 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1333 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1334 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1335 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1336 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1337 = emitc.call_opaque "__runtime_buffer_arg"(%1332) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1338 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1339 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1340 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1341 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1342 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1343 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1344 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %258, %1337, %4, %1338, %1334, %1335, %1343, %1336, %1339, %1340, %1341, %1342) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1345 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1346 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1347 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1348 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1349 = emitc.call_opaque "__runtime_buffer_arg"(%1331) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1350 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1351 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1352 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1353 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1354 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1355 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1356 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %258, %1349, %5, %1350, %1346, %1347, %1355, %1348, %1351, %1352, %1353, %1354) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1357 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1358 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1359 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %1360 = emitc.call_opaque "__Runtime_dma_createio_4"(%258, %1356, %1357, %1358, %1359) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %1361 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1362 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1363 = emitc.call_opaque "__runtime_buffer_offset"(%1276, %1362) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1364 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1365 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1366 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1367 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1368 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1369 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1370 = emitc.call_opaque "__runtime_buffer_arg"(%1365) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1371 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1373 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1374 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1375 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1376 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1377 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %424, %1370, %4, %1371, %1367, %1368, %1376, %1369, %1372, %1373, %1374, %1375) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1378 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1379 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1380 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1381 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1382 = emitc.call_opaque "__runtime_buffer_arg"(%1364) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1383 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1384 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1385 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1386 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1387 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1388 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1389 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %424, %1382, %5, %1383, %1379, %1380, %1388, %1381, %1384, %1385, %1386, %1387) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1390 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1391 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1392 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %1393 = emitc.call_opaque "__Runtime_dma_createio_4"(%424, %1389, %1390, %1391, %1392) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %1394 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1395 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1396 = emitc.call_opaque "__runtime_buffer_offset"(%1276, %1395) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1397 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1398 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1399 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1400 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1401 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1402 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1403 = emitc.call_opaque "__runtime_buffer_arg"(%1398) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1404 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1406 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1407 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1408 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1409 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1410 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %587, %1403, %4, %1404, %1400, %1401, %1409, %1402, %1405, %1406, %1407, %1408) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1411 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1412 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1413 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1414 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1415 = emitc.call_opaque "__runtime_buffer_arg"(%1397) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1416 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1417 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1418 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1419 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1420 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1421 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1422 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %587, %1415, %5, %1416, %1412, %1413, %1421, %1414, %1417, %1418, %1419, %1420) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1423 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1424 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1425 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %1426 = emitc.call_opaque "__Runtime_dma_createio_4"(%587, %1422, %1423, %1424, %1425) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    %1427 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (7,0) */"
    %1428 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1429 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1430 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %1429) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %1431 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1432 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1433 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1434 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1435 = emitc.call_opaque "__runtime_buffer_arg"(%1430) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1436 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1437 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1438 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1439 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1440 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1441 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1442 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1443 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1444 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1445 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1446 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1447 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1448 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1449 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1450 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1451 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%0, %12, %1435, %5, %1436, %1432, %1433, %1450, %1434, %1437, %1438, %1439, %1440, %1441, %1442, %1443, %1444, %1445, %1446, %1447, %1448, %1449) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1452 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1453 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1454 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,0), direction=S2MM */"
    %1455 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %1451, %1452, %1453, %1454) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1456 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1457 = emitc.call_opaque "__runtime_buffer_offset"(%1430, %1456) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1458 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1459 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1460 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1461 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1462 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1463 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1464 = emitc.call_opaque "__runtime_buffer_arg"(%1459) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1465 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1466 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1467 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1468 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1469 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1470 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1471 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %99, %1464, %3, %1465, %1461, %1462, %1470, %1463, %1466, %1467, %1468, %1469) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1472 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1473 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1474 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1475 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1476 = emitc.call_opaque "__runtime_buffer_arg"(%1458) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1477 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1478 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1479 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1480 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1481 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1482 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1483 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %99, %1476, %2, %1477, %1473, %1474, %1482, %1475, %1478, %1479, %1480, %1481) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1484 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1485 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1486 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %1487 = emitc.call_opaque "__Runtime_dma_createio_4"(%99, %1483, %1484, %1485, %1486) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %1488 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1489 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %1490 = emitc.call_opaque "__runtime_buffer_offset"(%1430, %1489) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1491 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1492 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1493 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1494 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1495 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1496 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1497 = emitc.call_opaque "__runtime_buffer_arg"(%1492) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1498 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1499 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1500 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1501 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1502 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1503 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1504 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %258, %1497, %3, %1498, %1494, %1495, %1503, %1496, %1499, %1500, %1501, %1502) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1505 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1506 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1507 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1508 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1509 = emitc.call_opaque "__runtime_buffer_arg"(%1491) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1510 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1511 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1512 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1513 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1514 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1515 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1516 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %258, %1509, %2, %1510, %1506, %1507, %1515, %1508, %1511, %1512, %1513, %1514) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1517 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1518 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1519 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %1520 = emitc.call_opaque "__Runtime_dma_createio_4"(%258, %1516, %1517, %1518, %1519) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %1521 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1522 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %1523 = emitc.call_opaque "__runtime_buffer_offset"(%1430, %1522) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1524 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1525 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1526 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1527 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1528 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1529 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1530 = emitc.call_opaque "__runtime_buffer_arg"(%1525) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1531 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1532 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1533 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1534 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1535 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1536 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1537 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %424, %1530, %3, %1531, %1527, %1528, %1536, %1529, %1532, %1533, %1534, %1535) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1538 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1539 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1540 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1541 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1542 = emitc.call_opaque "__runtime_buffer_arg"(%1524) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1543 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1544 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1545 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1546 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1547 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1548 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1549 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %424, %1542, %2, %1543, %1539, %1540, %1548, %1541, %1544, %1545, %1546, %1547) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1550 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1551 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1552 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %1553 = emitc.call_opaque "__Runtime_dma_createio_4"(%424, %1549, %1550, %1551, %1552) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %1554 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1555 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %1556 = emitc.call_opaque "__runtime_buffer_offset"(%1430, %1555) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1557 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1558 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1559 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1560 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1561 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1562 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1563 = emitc.call_opaque "__runtime_buffer_arg"(%1558) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1564 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1565 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1566 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1567 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1568 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1569 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1570 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %587, %1563, %3, %1564, %1560, %1561, %1569, %1562, %1565, %1566, %1567, %1568) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1571 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1572 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1573 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1574 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1575 = emitc.call_opaque "__runtime_buffer_arg"(%1557) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1576 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1577 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1578 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1579 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1580 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1581 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1582 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %587, %1575, %2, %1576, %1572, %1573, %1581, %1574, %1577, %1578, %1579, %1580) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1583 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1584 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1585 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %1586 = emitc.call_opaque "__Runtime_dma_createio_4"(%587, %1582, %1583, %1584, %1585) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    %1587 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %1588 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1589 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1590 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %1589) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %1591 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1592 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1593 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1594 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1595 = emitc.call_opaque "__runtime_buffer_arg"(%1590) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1596 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1597 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1598 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1599 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1600 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1601 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1602 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %1279, %1595, %7, %1596, %1592, %1593, %1601, %1594, %1597, %1598, %1599, %1600) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1603 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1604 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1605 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(7,0), direction=MM2S */"
    %1606 = emitc.call_opaque "__Runtime_dma_createio_4"(%1279, %1602, %1603, %1604, %1605) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1607 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1608 = emitc.call_opaque "__runtime_buffer_offset"(%1590, %1607) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1609 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1610 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1611 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1612 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1613 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1614 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1615 = emitc.call_opaque "__runtime_buffer_arg"(%1610) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1616 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1617 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1618 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1619 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1620 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1621 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1622 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %133, %1615, %4, %1616, %1612, %1613, %1621, %1614, %1617, %1618, %1619, %1620) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1623 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1624 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1625 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1626 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1627 = emitc.call_opaque "__runtime_buffer_arg"(%1609) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1628 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1629 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1630 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1631 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1632 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1633 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1634 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %133, %1627, %5, %1628, %1624, %1625, %1633, %1626, %1629, %1630, %1631, %1632) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1635 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1636 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1637 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %1638 = emitc.call_opaque "__Runtime_dma_createio_4"(%133, %1634, %1635, %1636, %1637) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %1639 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1640 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1641 = emitc.call_opaque "__runtime_buffer_offset"(%1590, %1640) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1642 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1643 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1644 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1645 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1646 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1647 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1648 = emitc.call_opaque "__runtime_buffer_arg"(%1643) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1649 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1650 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1651 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1652 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1653 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1654 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1655 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %294, %1648, %4, %1649, %1645, %1646, %1654, %1647, %1650, %1651, %1652, %1653) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1656 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1657 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1658 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1659 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1660 = emitc.call_opaque "__runtime_buffer_arg"(%1642) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1661 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1662 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1663 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1664 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1665 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1666 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1667 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %294, %1660, %5, %1661, %1657, %1658, %1666, %1659, %1662, %1663, %1664, %1665) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1668 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1669 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1670 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %1671 = emitc.call_opaque "__Runtime_dma_createio_4"(%294, %1667, %1668, %1669, %1670) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %1672 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1673 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1674 = emitc.call_opaque "__runtime_buffer_offset"(%1590, %1673) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1675 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1676 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1677 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1678 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1679 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1680 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1681 = emitc.call_opaque "__runtime_buffer_arg"(%1676) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1682 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1683 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1684 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1685 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1686 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1687 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1688 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %460, %1681, %4, %1682, %1678, %1679, %1687, %1680, %1683, %1684, %1685, %1686) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1689 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1690 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1691 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1692 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1693 = emitc.call_opaque "__runtime_buffer_arg"(%1675) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1694 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1695 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1696 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1697 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1698 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1699 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1700 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %460, %1693, %5, %1694, %1690, %1691, %1699, %1692, %1695, %1696, %1697, %1698) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1701 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1702 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1703 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %1704 = emitc.call_opaque "__Runtime_dma_createio_4"(%460, %1700, %1701, %1702, %1703) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %1705 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1706 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1707 = emitc.call_opaque "__runtime_buffer_offset"(%1590, %1706) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1708 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1709 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1710 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1711 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1712 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1713 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1714 = emitc.call_opaque "__runtime_buffer_arg"(%1709) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1715 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1716 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1717 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1718 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1719 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1721 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %623, %1714, %4, %1715, %1711, %1712, %1720, %1713, %1716, %1717, %1718, %1719) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %1722 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1723 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1724 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1725 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1726 = emitc.call_opaque "__runtime_buffer_arg"(%1708) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1727 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1728 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1729 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1730 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1731 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1732 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1733 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %623, %1726, %5, %1727, %1723, %1724, %1732, %1725, %1728, %1729, %1730, %1731) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1734 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1735 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1736 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %1737 = emitc.call_opaque "__Runtime_dma_createio_4"(%623, %1733, %1734, %1735, %1736) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    %1738 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (7,0) */"
    %1739 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1740 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1741 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %1740) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %1742 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1743 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1744 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1745 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1746 = emitc.call_opaque "__runtime_buffer_arg"(%1741) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1747 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1748 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1749 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1750 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1751 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1752 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1753 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1754 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1755 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1756 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1757 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1758 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1759 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1760 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1761 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1762 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%0, %12, %1746, %4, %1747, %1743, %1744, %1761, %1745, %1748, %1749, %1750, %1751, %1752, %1753, %1754, %1755, %1756, %1757, %1758, %1759, %1760) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1763 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1764 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1765 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(2,0), direction=S2MM */"
    %1766 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %1762, %1763, %1764, %1765) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1767 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1768 = emitc.call_opaque "__runtime_buffer_offset"(%1741, %1767) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1769 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1770 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1771 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1772 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1773 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1774 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1775 = emitc.call_opaque "__runtime_buffer_arg"(%1770) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1776 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1777 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1778 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1779 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1780 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1781 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1782 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %133, %1775, %3, %1776, %1772, %1773, %1781, %1774, %1777, %1778, %1779, %1780) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1783 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1784 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1785 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1786 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1787 = emitc.call_opaque "__runtime_buffer_arg"(%1769) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1788 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1789 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1790 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1791 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1792 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1793 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1794 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %133, %1787, %2, %1788, %1784, %1785, %1793, %1786, %1789, %1790, %1791, %1792) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1795 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1796 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1797 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %1798 = emitc.call_opaque "__Runtime_dma_createio_4"(%133, %1794, %1795, %1796, %1797) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %1799 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1800 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %1801 = emitc.call_opaque "__runtime_buffer_offset"(%1741, %1800) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1802 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1803 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1804 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1805 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1806 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1807 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1808 = emitc.call_opaque "__runtime_buffer_arg"(%1803) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1809 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1810 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1811 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1812 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1813 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1814 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1815 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %294, %1808, %3, %1809, %1805, %1806, %1814, %1807, %1810, %1811, %1812, %1813) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1816 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1817 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1818 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1819 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1820 = emitc.call_opaque "__runtime_buffer_arg"(%1802) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1821 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1822 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1823 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1824 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1825 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1826 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1827 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %294, %1820, %2, %1821, %1817, %1818, %1826, %1819, %1822, %1823, %1824, %1825) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1828 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1829 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1830 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %1831 = emitc.call_opaque "__Runtime_dma_createio_4"(%294, %1827, %1828, %1829, %1830) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %1832 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1833 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %1834 = emitc.call_opaque "__runtime_buffer_offset"(%1741, %1833) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1835 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1836 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1837 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1838 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1839 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1840 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1841 = emitc.call_opaque "__runtime_buffer_arg"(%1836) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1842 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1843 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1844 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1845 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1846 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1847 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1848 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %460, %1841, %3, %1842, %1838, %1839, %1847, %1840, %1843, %1844, %1845, %1846) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1849 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1850 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1851 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1852 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1853 = emitc.call_opaque "__runtime_buffer_arg"(%1835) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1854 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1855 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1856 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1857 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1858 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1859 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1860 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %460, %1853, %2, %1854, %1850, %1851, %1859, %1852, %1855, %1856, %1857, %1858) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1861 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1862 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1863 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %1864 = emitc.call_opaque "__Runtime_dma_createio_4"(%460, %1860, %1861, %1862, %1863) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %1865 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1866 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %1867 = emitc.call_opaque "__runtime_buffer_offset"(%1741, %1866) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1868 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1869 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32928">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1870 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1871 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1872 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1873 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1874 = emitc.call_opaque "__runtime_buffer_arg"(%1869) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1875 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1876 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1877 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1878 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1879 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1880 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1881 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %623, %1874, %3, %1875, %1871, %1872, %1880, %1873, %1876, %1877, %1878, %1879) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %1882 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1883 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1884 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1885 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1886 = emitc.call_opaque "__runtime_buffer_arg"(%1868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1887 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1888 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1889 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1890 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1891 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1892 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1893 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %623, %1886, %2, %1887, %1883, %1884, %1892, %1885, %1888, %1889, %1890, %1891) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1894 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1895 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1896 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %1897 = emitc.call_opaque "__Runtime_dma_createio_4"(%623, %1893, %1894, %1895, %1896) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    %1898 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %1899 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %1900 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1901 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%31, %65, %99, %133, %186, %222, %258, %294, %352, %388, %424, %460, %515, %551, %587, %623, %1900) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %1902 = emitc.call_opaque "__Runtime_launch_kernel_group"(%1901) : (!emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %1903 = emitc.call_opaque "__Runtime_startio"(%61, %62) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1904 = emitc.call_opaque "__Runtime_startio"(%95, %96) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1905 = emitc.call_opaque "__Runtime_startio"(%129, %130) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1906 = emitc.call_opaque "__Runtime_startio"(%163, %164) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1907 = emitc.call_opaque "__Runtime_startio"(%28, %165) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1908 = emitc.call_opaque "__Runtime_startio"(%218, %219) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1909 = emitc.call_opaque "__Runtime_startio"(%254, %255) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1910 = emitc.call_opaque "__Runtime_startio"(%290, %291) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1911 = emitc.call_opaque "__Runtime_startio"(%326, %327) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1912 = emitc.call_opaque "__Runtime_startio"(%183, %328) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1913 = emitc.call_opaque "__Runtime_startio"(%384, %385) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1914 = emitc.call_opaque "__Runtime_startio"(%420, %421) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1915 = emitc.call_opaque "__Runtime_startio"(%456, %457) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1916 = emitc.call_opaque "__Runtime_startio"(%492, %493) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1917 = emitc.call_opaque "__Runtime_startio"(%349, %494) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1918 = emitc.call_opaque "__Runtime_startio"(%547, %548) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1919 = emitc.call_opaque "__Runtime_startio"(%583, %584) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1920 = emitc.call_opaque "__Runtime_startio"(%619, %620) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1921 = emitc.call_opaque "__Runtime_startio"(%655, %656) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1922 = emitc.call_opaque "__Runtime_startio"(%512, %657) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1923 = emitc.call_opaque "__Runtime_startio"(%708, %709) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1924 = emitc.call_opaque "__Runtime_startio"(%739, %740) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1925 = emitc.call_opaque "__Runtime_startio"(%770, %771) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1926 = emitc.call_opaque "__Runtime_startio"(%801, %802) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1927 = emitc.call_opaque "__Runtime_startio"(%678, %803) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1928 = emitc.call_opaque "__Runtime_startio"(%862, %863) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1929 = emitc.call_opaque "__Runtime_startio"(%895, %896) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1930 = emitc.call_opaque "__Runtime_startio"(%928, %929) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1931 = emitc.call_opaque "__Runtime_startio"(%961, %962) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1932 = emitc.call_opaque "__Runtime_startio"(%830, %963) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1933 = emitc.call_opaque "__Runtime_startio"(%1013, %1014) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1934 = emitc.call_opaque "__Runtime_startio"(%1046, %1047) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1935 = emitc.call_opaque "__Runtime_startio"(%1079, %1080) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1936 = emitc.call_opaque "__Runtime_startio"(%1112, %1113) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1937 = emitc.call_opaque "__Runtime_startio"(%981, %1114) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1938 = emitc.call_opaque "__Runtime_startio"(%1173, %1174) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1939 = emitc.call_opaque "__Runtime_startio"(%1206, %1207) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1940 = emitc.call_opaque "__Runtime_startio"(%1239, %1240) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1941 = emitc.call_opaque "__Runtime_startio"(%1272, %1273) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1942 = emitc.call_opaque "__Runtime_startio"(%1141, %1274) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1943 = emitc.call_opaque "__Runtime_startio"(%1327, %1328) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1944 = emitc.call_opaque "__Runtime_startio"(%1360, %1361) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1945 = emitc.call_opaque "__Runtime_startio"(%1393, %1394) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1946 = emitc.call_opaque "__Runtime_startio"(%1426, %1427) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1947 = emitc.call_opaque "__Runtime_startio"(%1295, %1428) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1948 = emitc.call_opaque "__Runtime_startio"(%1487, %1488) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1949 = emitc.call_opaque "__Runtime_startio"(%1520, %1521) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1950 = emitc.call_opaque "__Runtime_startio"(%1553, %1554) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1951 = emitc.call_opaque "__Runtime_startio"(%1586, %1587) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1952 = emitc.call_opaque "__Runtime_startio"(%1455, %1588) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1953 = emitc.call_opaque "__Runtime_startio"(%1638, %1639) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1954 = emitc.call_opaque "__Runtime_startio"(%1671, %1672) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1955 = emitc.call_opaque "__Runtime_startio"(%1704, %1705) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1956 = emitc.call_opaque "__Runtime_startio"(%1737, %1738) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1957 = emitc.call_opaque "__Runtime_startio"(%1606, %1739) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1958 = emitc.call_opaque "__Runtime_startio"(%1798, %1799) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1959 = emitc.call_opaque "__Runtime_startio"(%1831, %1832) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1960 = emitc.call_opaque "__Runtime_startio"(%1864, %1865) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1961 = emitc.call_opaque "__Runtime_startio"(%1897, %1898) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %1962 = emitc.call_opaque "__Runtime_startio"(%1766, %1899) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%1902) : (!emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1907) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1912) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1917) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1922) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1927) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1932) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1937) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1942) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1947) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1952) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1957) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%1962) : (!emitc.opaque<"ioevent">) -> ()
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
