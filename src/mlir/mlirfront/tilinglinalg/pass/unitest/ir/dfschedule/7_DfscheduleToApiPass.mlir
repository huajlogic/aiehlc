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
    %4 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %5 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %6 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %7 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %8 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %9 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %8) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %10 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %11 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %12 = emitc.call_opaque "XAie_TileLoc"(%10, %11) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %13 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %14 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
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
    %33 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %34 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %35 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %36 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %37 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %38 = emitc.call_opaque "__runtime_buffer_arg"(%33) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %39 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %40 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %43 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %44 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %45 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %38, %7, %39, %35, %36, %44, %37, %40, %41, %42, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %46 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %47 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %48 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %49 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %50 = emitc.call_opaque "__runtime_buffer_arg"(%32) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %51 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %52 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %53 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %54 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %55 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %56 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %57 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %50, %6, %51, %47, %48, %56, %49, %52, %53, %54, %55) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %58 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %59 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %60 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,3), direction=S2MM */"
    %61 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %57, %58, %59, %60) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %62 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %63 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %64 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %65 = emitc.call_opaque "XAie_TileLoc"(%63, %64) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %66 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %67 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %68 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %69 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %70 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %71 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %72 = emitc.call_opaque "__runtime_buffer_arg"(%67) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %73 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %74 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %75 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %76 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %77 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %78 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %79 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %72, %7, %73, %69, %70, %78, %71, %74, %75, %76, %77) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %80 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %81 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %82 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %83 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %84 = emitc.call_opaque "__runtime_buffer_arg"(%66) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %85 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %86 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %87 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %88 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %89 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %90 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %91 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %84, %6, %85, %81, %82, %90, %83, %86, %87, %88, %89) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %92 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %93 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %94 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,3), direction=S2MM */"
    %95 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %91, %92, %93, %94) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %96 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %97 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %98 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %99 = emitc.call_opaque "__runtime_buffer_offset"(%arg0, %98) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %100 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %101 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %102 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %103 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %104 = emitc.call_opaque "__runtime_buffer_arg"(%99) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %105 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %106 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %108 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %109 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %110 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %111 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %12, %104, %7, %105, %101, %102, %110, %103, %106, %107, %108, %109) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %112 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %113 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %114 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %115 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %111, %112, %113, %114) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %116 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %117 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %118 = emitc.call_opaque "XAie_TileLoc"(%116, %117) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %119 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %120 = emitc.call_opaque "__runtime_buffer_offset"(%99, %119) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %121 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %122 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %123 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %124 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %125 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %126 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %127 = emitc.call_opaque "__runtime_buffer_arg"(%122) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %128 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %129 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %130 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %131 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %132 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %133 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %134 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %118, %127, %7, %128, %124, %125, %133, %126, %129, %130, %131, %132) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %135 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %136 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %137 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %138 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %139 = emitc.call_opaque "__runtime_buffer_arg"(%121) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %140 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %141 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %142 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %143 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %144 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %145 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %146 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %118, %139, %6, %140, %136, %137, %145, %138, %141, %142, %143, %144) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %147 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %148 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %149 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,4), direction=S2MM */"
    %150 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %146, %147, %148, %149) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %151 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %152 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %153 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %154 = emitc.call_opaque "XAie_TileLoc"(%152, %153) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %155 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %156 = emitc.call_opaque "__runtime_buffer_offset"(%99, %155) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %157 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %158 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %159 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %160 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %161 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %162 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %163 = emitc.call_opaque "__runtime_buffer_arg"(%158) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %164 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %165 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %166 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %167 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %168 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %169 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %170 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %154, %163, %7, %164, %160, %161, %169, %162, %165, %166, %167, %168) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1 */"
    %171 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %172 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %173 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %174 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %175 = emitc.call_opaque "__runtime_buffer_arg"(%157) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %176 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %177 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %178 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %179 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %180 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %181 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %182 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %154, %175, %6, %176, %172, %173, %181, %174, %177, %178, %179, %180) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %183 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %184 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %185 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,4), direction=S2MM */"
    %186 = emitc.call_opaque "__Runtime_dma_createio_4"(%154, %182, %183, %184, %185) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %187 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %188 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %189 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %190 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %189) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %191 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %192 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %193 = emitc.call_opaque "XAie_TileLoc"(%191, %192) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %194 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %195 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %196 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %197 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %198 = emitc.call_opaque "__runtime_buffer_arg"(%190) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %199 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %200 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %201 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %202 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %203 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %204 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %205 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %193, %198, %6, %199, %195, %196, %204, %197, %200, %201, %202, %203) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %206 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %207 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %208 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %209 = emitc.call_opaque "__Runtime_dma_createio_4"(%193, %205, %206, %207, %208) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %210 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %211 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %212 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %213 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %214 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %215 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %216 = emitc.call_opaque "__runtime_buffer_arg"(%211) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %217 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %218 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %220 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %221 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %222 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %223 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %216, %5, %217, %213, %214, %222, %215, %218, %219, %220, %221) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %224 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %225 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %226 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %227 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %228 = emitc.call_opaque "__runtime_buffer_arg"(%210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %229 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %230 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %231 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %232 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %233 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %234 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %235 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %228, %4, %229, %225, %226, %234, %227, %230, %231, %232, %233) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %236 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %237 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %238 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,3), direction=S2MM */"
    %239 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %235, %236, %237, %238) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    %240 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %241 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %242 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %243 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %244 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %245 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %246 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %247 = emitc.call_opaque "__runtime_buffer_arg"(%242) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %248 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %249 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %250 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %251 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %252 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %253 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %254 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %247, %5, %248, %244, %245, %253, %246, %249, %250, %251, %252) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %255 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %256 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %257 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %258 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %259 = emitc.call_opaque "__runtime_buffer_arg"(%241) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %260 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %261 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %262 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %263 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %264 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %265 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %266 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %259, %4, %260, %256, %257, %265, %258, %261, %262, %263, %264) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %267 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %268 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %269 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,3), direction=S2MM */"
    %270 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %266, %267, %268, %269) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    %271 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %272 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %273 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %274 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %273) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %275 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %276 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %277 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %278 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %279 = emitc.call_opaque "__runtime_buffer_arg"(%274) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %280 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %281 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %282 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %284 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %286 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %193, %279, %7, %280, %276, %277, %285, %278, %281, %282, %283, %284) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %287 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %288 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %289 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(3,0), direction=MM2S */"
    %290 = emitc.call_opaque "__Runtime_dma_createio_4"(%193, %286, %287, %288, %289) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %291 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %292 = emitc.call_opaque "__runtime_buffer_offset"(%274, %291) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %293 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %294 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %295 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %296 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %297 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %298 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %299 = emitc.call_opaque "__runtime_buffer_arg"(%294) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %300 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %301 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %302 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %303 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %304 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %305 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %306 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %118, %299, %5, %300, %296, %297, %305, %298, %301, %302, %303, %304) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %307 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %308 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %309 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %310 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %311 = emitc.call_opaque "__runtime_buffer_arg"(%293) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %312 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %313 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %314 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %315 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %316 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %317 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %318 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %118, %311, %4, %312, %308, %309, %317, %310, %313, %314, %315, %316) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %319 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %320 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %321 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(0,4), direction=S2MM */"
    %322 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %318, %319, %320, %321) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %323 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %324 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %325 = emitc.call_opaque "__runtime_buffer_offset"(%274, %324) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %326 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %327 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %328 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %329 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %330 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %331 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %332 = emitc.call_opaque "__runtime_buffer_arg"(%327) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %333 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %334 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %335 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %336 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %337 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %338 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %339 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %154, %332, %5, %333, %329, %330, %338, %331, %334, %335, %336, %337) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=16, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1 */"
    %340 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %341 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %342 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %343 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %344 = emitc.call_opaque "__runtime_buffer_arg"(%326) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %345 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %346 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %347 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %348 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %349 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %350 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %351 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %154, %344, %4, %345, %341, %342, %350, %343, %346, %347, %348, %349) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %352 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %353 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %354 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=2, tile=(1,4), direction=S2MM */"
    %355 = emitc.call_opaque "__Runtime_dma_createio_4"(%154, %351, %352, %353, %354) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %356 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %357 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %358 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %359 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %358) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %360 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %361 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %362 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %363 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %364 = emitc.call_opaque "__runtime_buffer_arg"(%359) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %365 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %366 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %368 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %369 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %370 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %371 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %12, %364, %4, %365, %361, %362, %370, %363, %366, %367, %368, %369) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %373 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %374 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,0), direction=S2MM */"
    %375 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %371, %372, %373, %374) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %376 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %377 = emitc.call_opaque "__runtime_buffer_offset"(%359, %376) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %378 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %379 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33088">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %380 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %381 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %382 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %383 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %384 = emitc.call_opaque "__runtime_buffer_arg"(%379) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %385 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %386 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %387 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %388 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %389 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %390 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %391 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %384, %3, %385, %381, %382, %390, %383, %386, %387, %388, %389) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %392 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %393 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %394 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %395 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %396 = emitc.call_opaque "__runtime_buffer_arg"(%378) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %397 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %398 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %399 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %400 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %401 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %402 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %403 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %31, %396, %2, %397, %393, %394, %402, %395, %398, %399, %400, %401) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %404 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %405 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %406 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %407 = emitc.call_opaque "__Runtime_dma_createio_4"(%31, %403, %404, %405, %406) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %408 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %409 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %410 = emitc.call_opaque "__runtime_buffer_offset"(%359, %409) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %411 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %412 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33088">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %413 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %414 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %415 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %416 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %417 = emitc.call_opaque "__runtime_buffer_arg"(%412) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %418 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %419 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %420 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %421 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %422 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %423 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %424 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %417, %3, %418, %414, %415, %423, %416, %419, %420, %421, %422) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %425 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %426 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %427 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %428 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %429 = emitc.call_opaque "__runtime_buffer_arg"(%411) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %430 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %431 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %432 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %433 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %434 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %435 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %436 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %65, %429, %2, %430, %426, %427, %435, %428, %431, %432, %433, %434) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %437 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %438 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %439 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %440 = emitc.call_opaque "__Runtime_dma_createio_4"(%65, %436, %437, %438, %439) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %441 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %442 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %443 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %444 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %443) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=32, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0 */"
    %445 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %446 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %447 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %448 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %449 = emitc.call_opaque "__runtime_buffer_arg"(%444) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %450 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %451 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %452 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %453 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %454 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %455 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %456 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %12, %449, %5, %450, %446, %447, %455, %448, %451, %452, %453, %454) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %457 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %458 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %459 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=3, tile=(2,0), direction=S2MM */"
    %460 = emitc.call_opaque "__Runtime_dma_createio_4"(%12, %456, %457, %458, %459) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %461 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %462 = emitc.call_opaque "__runtime_buffer_offset"(%444, %461) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %463 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %464 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33088">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %465 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %466 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %467 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %468 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %469 = emitc.call_opaque "__runtime_buffer_arg"(%464) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %470 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %471 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %472 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %473 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %474 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %475 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %476 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %118, %469, %3, %470, %466, %467, %475, %468, %471, %472, %473, %474) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %477 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %478 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %479 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %480 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %481 = emitc.call_opaque "__runtime_buffer_arg"(%463) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %482 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %483 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %484 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %485 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %486 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %487 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %488 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %118, %481, %2, %482, %478, %479, %487, %480, %483, %484, %485, %486) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %489 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %490 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %491 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %492 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %488, %489, %490, %491) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %493 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %494 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %495 = emitc.call_opaque "__runtime_buffer_offset"(%444, %494) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %496 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %497 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33088">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %498 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %499 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %500 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %501 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %502 = emitc.call_opaque "__runtime_buffer_arg"(%497) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %503 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %504 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %505 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %506 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %507 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %508 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %509 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %154, %502, %3, %503, %499, %500, %508, %501, %504, %505, %506, %507) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(g_DevInst, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=8, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1 */"
    %510 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %511 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %512 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %513 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %514 = emitc.call_opaque "__runtime_buffer_arg"(%496) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %515 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %516 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %517 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %518 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %519 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %520 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %521 = emitc.call_opaque "__Runtime_dma_bd_config"(%0, %154, %514, %2, %515, %511, %512, %520, %513, %516, %517, %518, %519) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i64, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %522 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %523 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %524 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %525 = emitc.call_opaque "__Runtime_dma_createio_4"(%154, %521, %522, %523, %524) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %526 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %527 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    emitc.verbatim "/* Load Kernel Group: 4 tile(s) */"
    %528 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %529 = emitc.call_opaque "__Runtime_load_kernel_group_4t"(%31, %65, %118, %154, %528) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %530 = emitc.call_opaque "__Runtime_launch_kernel_group"(%529) : (!emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %531 = emitc.call_opaque "__Runtime_startio"(%61, %62) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %532 = emitc.call_opaque "__Runtime_startio"(%95, %96) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %533 = emitc.call_opaque "__Runtime_startio"(%28, %97) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %534 = emitc.call_opaque "__Runtime_startio"(%150, %151) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %535 = emitc.call_opaque "__Runtime_startio"(%186, %187) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %536 = emitc.call_opaque "__Runtime_startio"(%115, %188) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %537 = emitc.call_opaque "__Runtime_startio"(%239, %240) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %538 = emitc.call_opaque "__Runtime_startio"(%270, %271) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %539 = emitc.call_opaque "__Runtime_startio"(%209, %272) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %540 = emitc.call_opaque "__Runtime_startio"(%322, %323) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %541 = emitc.call_opaque "__Runtime_startio"(%355, %356) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %542 = emitc.call_opaque "__Runtime_startio"(%290, %357) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %543 = emitc.call_opaque "__Runtime_startio"(%407, %408) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %544 = emitc.call_opaque "__Runtime_startio"(%440, %441) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %545 = emitc.call_opaque "__Runtime_startio"(%375, %442) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %546 = emitc.call_opaque "__Runtime_startio"(%492, %493) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %547 = emitc.call_opaque "__Runtime_startio"(%525, %526) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    %548 = emitc.call_opaque "__Runtime_startio"(%460, %527) : (!emitc.opaque<"io">, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 7 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%530) : (!emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%533) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%536) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%539) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%542) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%545) : (!emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%548) : (!emitc.opaque<"ioevent">) -> ()
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
