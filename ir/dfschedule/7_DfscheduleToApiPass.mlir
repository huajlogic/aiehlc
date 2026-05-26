module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<256x256xi8>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>) {
    emitc.call_opaque "host_canonicalized"() : () -> ()
    return
  }
  emitc.func @host_canonicalized(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: !emitc.ptr<!emitc.opaque<"void">>, %arg2: !emitc.ptr<!emitc.opaque<"void">>, %arg3: !emitc.ptr<!emitc.opaque<"void">>) {
    emitc.verbatim "XAie_DevInst* dev = v1;"
    %0 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_MEM_CACHEABLE">}> : () -> i32
    %1 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %2 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %3 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %4 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %5 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %6 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %7 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %8 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %9 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %10 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %11 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %12 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %13 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %14 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %13) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %15 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %16 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %17 = emitc.call_opaque "XAie_TileLoc"(%15, %16) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %18 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %19 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %20 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %21 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %22 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %23 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %24 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %25 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %26 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %27 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %28 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %29 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %22, %11, %19, %20, %28, %21, %23, %24, %25, %26, %27) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %30 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %31 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,0), direction=MM2S */"
    %33 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %29, %30, %31, %32) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %34 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %35 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %36 = emitc.call_opaque "XAie_TileLoc"(%34, %35) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %37 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %38 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %39 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %40 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %43 = emitc.call_opaque "__runtime_buffer_arg"(%38) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %44 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %45 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %46 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %47 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %48 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %49 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %50 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %43, %12, %40, %41, %49, %42, %44, %45, %46, %47, %48) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %51 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %52 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %53 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %54 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %55 = emitc.call_opaque "__runtime_buffer_arg"(%37) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %56 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %57 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %58 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %59 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %60 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %61 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %62 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %55, %11, %52, %53, %61, %54, %56, %57, %58, %59, %60) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %63 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %64 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %65 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %66 = emitc.call_opaque "__Runtime_dma_createio_4"(%36, %62, %63, %64, %65) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %67 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %68 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %69 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %70 = emitc.call_opaque "XAie_TileLoc"(%68, %69) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %71 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %72 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %73 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %74 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %75 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %76 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %77 = emitc.call_opaque "__runtime_buffer_arg"(%72) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %78 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %79 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %80 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %81 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %82 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %83 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %84 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %77, %12, %74, %75, %83, %76, %78, %79, %80, %81, %82) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %85 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %86 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %87 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %88 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %89 = emitc.call_opaque "__runtime_buffer_arg"(%71) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %90 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %91 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %92 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %93 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %94 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %95 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %96 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %89, %11, %86, %87, %95, %88, %90, %91, %92, %93, %94) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %97 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %98 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %99 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %100 = emitc.call_opaque "__Runtime_dma_createio_4"(%70, %96, %97, %98, %99) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %101 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %102 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %103 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %104 = emitc.call_opaque "XAie_TileLoc"(%102, %103) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %105 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %106 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %108 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %109 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %110 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %111 = emitc.call_opaque "__runtime_buffer_arg"(%106) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %112 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %113 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %114 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %115 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %116 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %117 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %118 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %111, %12, %108, %109, %117, %110, %112, %113, %114, %115, %116) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %119 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %120 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %121 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %122 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %123 = emitc.call_opaque "__runtime_buffer_arg"(%105) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %124 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %125 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %126 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %127 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %128 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %129 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %130 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %123, %11, %120, %121, %129, %122, %124, %125, %126, %127, %128) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %131 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %132 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %133 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %134 = emitc.call_opaque "__Runtime_dma_createio_4"(%104, %130, %131, %132, %133) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %135 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %136 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %137 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %138 = emitc.call_opaque "XAie_TileLoc"(%136, %137) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %139 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %140 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %141 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %142 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %143 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %144 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %145 = emitc.call_opaque "__runtime_buffer_arg"(%140) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %146 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %147 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %148 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %149 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %150 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %151 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %152 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %145, %12, %142, %143, %151, %144, %146, %147, %148, %149, %150) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %153 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %154 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %155 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %156 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %157 = emitc.call_opaque "__runtime_buffer_arg"(%139) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %158 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %159 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %160 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %161 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %162 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %163 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %164 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %157, %11, %154, %155, %163, %156, %158, %159, %160, %161, %162) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %165 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %166 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %167 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %168 = emitc.call_opaque "__Runtime_dma_createio_4"(%138, %164, %165, %166, %167) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    %169 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,0) */"
    %170 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %171 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %172 = emitc.call_opaque "__Runtime_startio"(%arg0, %33, %170, %171) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %173 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %174 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %173) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %175 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %176 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %177 = emitc.call_opaque "XAie_TileLoc"(%175, %176) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %178 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %179 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %180 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %181 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %182 = emitc.call_opaque "__runtime_buffer_arg"(%174) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %183 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %184 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %185 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %186 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %187 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %188 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %189 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %177, %182, %11, %179, %180, %188, %181, %183, %184, %185, %186, %187) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %190 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %191 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %192 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,0), direction=MM2S */"
    %193 = emitc.call_opaque "__Runtime_dma_createio_4"(%177, %189, %190, %191, %192) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %194 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %195 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %196 = emitc.call_opaque "XAie_TileLoc"(%194, %195) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %197 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %198 = emitc.call_opaque "__runtime_buffer_offset"(%174, %197) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %199 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %200 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %201 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %202 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %203 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %204 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %205 = emitc.call_opaque "__runtime_buffer_arg"(%200) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %206 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %207 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %208 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %209 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %210 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %211 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %212 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %205, %12, %202, %203, %211, %204, %206, %207, %208, %209, %210) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %213 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %214 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %215 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %216 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %217 = emitc.call_opaque "__runtime_buffer_arg"(%199) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %218 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %220 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %221 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %222 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %223 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %224 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %217, %11, %214, %215, %223, %216, %218, %219, %220, %221, %222) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %225 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %226 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %227 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %228 = emitc.call_opaque "__Runtime_dma_createio_4"(%196, %224, %225, %226, %227) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %229 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %230 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %231 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %232 = emitc.call_opaque "XAie_TileLoc"(%230, %231) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %233 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %234 = emitc.call_opaque "__runtime_buffer_offset"(%174, %233) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %235 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %236 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %237 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %238 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %239 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %240 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %241 = emitc.call_opaque "__runtime_buffer_arg"(%236) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %242 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %243 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %244 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %245 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %246 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %247 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %248 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %241, %12, %238, %239, %247, %240, %242, %243, %244, %245, %246) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %249 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %250 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %251 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %252 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %253 = emitc.call_opaque "__runtime_buffer_arg"(%235) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %255 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %256 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %257 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %258 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %259 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %260 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %253, %11, %250, %251, %259, %252, %254, %255, %256, %257, %258) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %261 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %262 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %263 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %264 = emitc.call_opaque "__Runtime_dma_createio_4"(%232, %260, %261, %262, %263) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %265 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %266 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %267 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %268 = emitc.call_opaque "XAie_TileLoc"(%266, %267) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %269 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %270 = emitc.call_opaque "__runtime_buffer_offset"(%174, %269) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %271 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %273 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %274 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %275 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %276 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %277 = emitc.call_opaque "__runtime_buffer_arg"(%272) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %278 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %279 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %280 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %281 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %282 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %284 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %277, %12, %274, %275, %283, %276, %278, %279, %280, %281, %282) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %286 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %287 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %288 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %289 = emitc.call_opaque "__runtime_buffer_arg"(%271) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %291 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %292 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %293 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %294 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %295 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %296 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %289, %11, %286, %287, %295, %288, %290, %291, %292, %293, %294) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %297 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %298 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %299 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %300 = emitc.call_opaque "__Runtime_dma_createio_4"(%268, %296, %297, %298, %299) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %301 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %302 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %303 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %304 = emitc.call_opaque "XAie_TileLoc"(%302, %303) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %305 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %306 = emitc.call_opaque "__runtime_buffer_offset"(%174, %305) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %307 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %308 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %309 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %310 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %311 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %312 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %313 = emitc.call_opaque "__runtime_buffer_arg"(%308) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %314 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %315 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %316 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %317 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %318 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %319 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %320 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %313, %12, %310, %311, %319, %312, %314, %315, %316, %317, %318) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %321 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %322 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %323 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %324 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %325 = emitc.call_opaque "__runtime_buffer_arg"(%307) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %326 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %327 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %328 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %329 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %330 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %331 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %332 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %325, %11, %322, %323, %331, %324, %326, %327, %328, %329, %330) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %333 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %334 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %335 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %336 = emitc.call_opaque "__Runtime_dma_createio_4"(%304, %332, %333, %334, %335) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    %337 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,0) */"
    %338 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %339 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %340 = emitc.call_opaque "__Runtime_startio"(%arg0, %193, %338, %339) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %341 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %342 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %341) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %343 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %344 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %345 = emitc.call_opaque "XAie_TileLoc"(%343, %344) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %346 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %347 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %348 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %349 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %350 = emitc.call_opaque "__runtime_buffer_arg"(%342) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %351 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %352 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %353 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %354 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %355 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %356 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %357 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %345, %350, %11, %347, %348, %356, %349, %351, %352, %353, %354, %355) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %358 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %359 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %360 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %361 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %357, %358, %359, %360) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %362 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %363 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %364 = emitc.call_opaque "XAie_TileLoc"(%362, %363) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %365 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %366 = emitc.call_opaque "__runtime_buffer_offset"(%342, %365) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %367 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %368 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %369 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %370 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %371 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %373 = emitc.call_opaque "__runtime_buffer_arg"(%368) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %374 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %375 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %376 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %377 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %378 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %379 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %380 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %373, %12, %370, %371, %379, %372, %374, %375, %376, %377, %378) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %381 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %382 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %383 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %384 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %385 = emitc.call_opaque "__runtime_buffer_arg"(%367) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %386 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %387 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %388 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %389 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %390 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %391 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %392 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %385, %11, %382, %383, %391, %384, %386, %387, %388, %389, %390) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %393 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %394 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %395 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %396 = emitc.call_opaque "__Runtime_dma_createio_4"(%364, %392, %393, %394, %395) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %397 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %398 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %399 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %400 = emitc.call_opaque "XAie_TileLoc"(%398, %399) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %401 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %402 = emitc.call_opaque "__runtime_buffer_offset"(%342, %401) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %403 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %404 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %406 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %407 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %408 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %409 = emitc.call_opaque "__runtime_buffer_arg"(%404) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %410 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %411 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %412 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %413 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %414 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %415 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %416 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %409, %12, %406, %407, %415, %408, %410, %411, %412, %413, %414) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %417 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %418 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %419 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %420 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %421 = emitc.call_opaque "__runtime_buffer_arg"(%403) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %422 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %423 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %424 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %425 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %426 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %427 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %428 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %421, %11, %418, %419, %427, %420, %422, %423, %424, %425, %426) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %429 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %430 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %431 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %432 = emitc.call_opaque "__Runtime_dma_createio_4"(%400, %428, %429, %430, %431) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %433 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %434 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %435 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %436 = emitc.call_opaque "XAie_TileLoc"(%434, %435) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %437 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %438 = emitc.call_opaque "__runtime_buffer_offset"(%342, %437) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %439 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %440 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %441 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %442 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %443 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %444 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %445 = emitc.call_opaque "__runtime_buffer_arg"(%440) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %446 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %447 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %448 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %449 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %450 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %451 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %452 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %445, %12, %442, %443, %451, %444, %446, %447, %448, %449, %450) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %453 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %454 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %455 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %456 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %457 = emitc.call_opaque "__runtime_buffer_arg"(%439) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %458 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %459 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %460 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %461 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %462 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %463 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %464 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %457, %11, %454, %455, %463, %456, %458, %459, %460, %461, %462) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %465 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %466 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %467 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %468 = emitc.call_opaque "__Runtime_dma_createio_4"(%436, %464, %465, %466, %467) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %469 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %470 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %471 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %472 = emitc.call_opaque "XAie_TileLoc"(%470, %471) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %473 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %474 = emitc.call_opaque "__runtime_buffer_offset"(%342, %473) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %475 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %476 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %477 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %478 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %479 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %480 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %481 = emitc.call_opaque "__runtime_buffer_arg"(%476) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %482 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %483 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %484 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %485 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %486 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %487 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %488 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %481, %12, %478, %479, %487, %480, %482, %483, %484, %485, %486) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %489 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %490 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %491 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %492 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %493 = emitc.call_opaque "__runtime_buffer_arg"(%475) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %494 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %495 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %496 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %497 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %498 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %499 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %500 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %493, %11, %490, %491, %499, %492, %494, %495, %496, %497, %498) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %501 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %502 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %503 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %504 = emitc.call_opaque "__Runtime_dma_createio_4"(%472, %500, %501, %502, %503) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    %505 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %506 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %507 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %508 = emitc.call_opaque "__Runtime_startio"(%arg0, %361, %506, %507) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %509 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %510 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %509) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %511 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %512 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %513 = emitc.call_opaque "XAie_TileLoc"(%511, %512) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %514 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %515 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %516 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %517 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %518 = emitc.call_opaque "__runtime_buffer_arg"(%510) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %519 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %520 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %521 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %522 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %523 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %524 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %525 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %518, %11, %515, %516, %524, %517, %519, %520, %521, %522, %523) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %526 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %527 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %528 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %529 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %525, %526, %527, %528) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %530 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %531 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %532 = emitc.call_opaque "XAie_TileLoc"(%530, %531) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %533 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %534 = emitc.call_opaque "__runtime_buffer_offset"(%510, %533) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %535 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %536 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %537 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %538 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %539 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %540 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %541 = emitc.call_opaque "__runtime_buffer_arg"(%536) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %542 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %543 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %544 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %545 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %546 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %547 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %548 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %541, %12, %538, %539, %547, %540, %542, %543, %544, %545, %546) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %549 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %550 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %551 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %552 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %553 = emitc.call_opaque "__runtime_buffer_arg"(%535) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %554 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %555 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %556 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %557 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %558 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %559 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %560 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %553, %11, %550, %551, %559, %552, %554, %555, %556, %557, %558) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %561 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %562 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %563 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %564 = emitc.call_opaque "__Runtime_dma_createio_4"(%532, %560, %561, %562, %563) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %565 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %566 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %567 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %568 = emitc.call_opaque "XAie_TileLoc"(%566, %567) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %569 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %570 = emitc.call_opaque "__runtime_buffer_offset"(%510, %569) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %571 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %572 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %573 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %574 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %575 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %576 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %577 = emitc.call_opaque "__runtime_buffer_arg"(%572) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %578 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %579 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %580 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %581 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %582 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %583 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %584 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %577, %12, %574, %575, %583, %576, %578, %579, %580, %581, %582) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %585 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %586 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %587 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %588 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %589 = emitc.call_opaque "__runtime_buffer_arg"(%571) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %590 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %591 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %592 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %593 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %594 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %595 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %596 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %589, %11, %586, %587, %595, %588, %590, %591, %592, %593, %594) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %597 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %598 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %599 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %600 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %596, %597, %598, %599) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %601 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %602 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %603 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %604 = emitc.call_opaque "XAie_TileLoc"(%602, %603) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %605 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %606 = emitc.call_opaque "__runtime_buffer_offset"(%510, %605) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %607 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %608 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %609 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %610 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %611 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %612 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %613 = emitc.call_opaque "__runtime_buffer_arg"(%608) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %614 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %615 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %616 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %617 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %618 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %619 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %620 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %613, %12, %610, %611, %619, %612, %614, %615, %616, %617, %618) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %621 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %622 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %623 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %624 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %625 = emitc.call_opaque "__runtime_buffer_arg"(%607) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %626 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %627 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %628 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %629 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %630 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %631 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %632 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %625, %11, %622, %623, %631, %624, %626, %627, %628, %629, %630) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %633 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %634 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %635 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %636 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %632, %633, %634, %635) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %637 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %638 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %639 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %640 = emitc.call_opaque "XAie_TileLoc"(%638, %639) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %641 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %642 = emitc.call_opaque "__runtime_buffer_offset"(%510, %641) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %643 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %644 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %645 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %646 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %647 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %648 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %649 = emitc.call_opaque "__runtime_buffer_arg"(%644) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %650 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %651 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %652 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %653 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %654 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %655 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %656 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %649, %12, %646, %647, %655, %648, %650, %651, %652, %653, %654) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %657 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %658 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %659 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %660 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %661 = emitc.call_opaque "__runtime_buffer_arg"(%643) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %662 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %663 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %664 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %665 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %666 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %667 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %668 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %661, %11, %658, %659, %667, %660, %662, %663, %664, %665, %666) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %669 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %670 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %671 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %672 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %668, %669, %670, %671) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    %673 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %674 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %675 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %676 = emitc.call_opaque "__Runtime_startio"(%arg0, %529, %674, %675) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %677 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %678 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %677) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %679 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %680 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %681 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %682 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %683 = emitc.call_opaque "__runtime_buffer_arg"(%678) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %684 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %685 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %686 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %687 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %688 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %689 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %690 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %17, %683, %12, %680, %681, %689, %682, %684, %685, %686, %687, %688) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %691 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %692 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %693 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
    %694 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %690, %691, %692, %693) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %695 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %696 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %697 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %698 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %699 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %700 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %701 = emitc.call_opaque "__runtime_buffer_arg"(%696) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %702 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %703 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %704 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %705 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %706 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %707 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %708 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %701, %9, %698, %699, %707, %700, %702, %703, %704, %705, %706) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %709 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %710 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %711 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %712 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %713 = emitc.call_opaque "__runtime_buffer_arg"(%695) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %714 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %715 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %716 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %717 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %718 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %719 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %720 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %713, %10, %710, %711, %719, %712, %714, %715, %716, %717, %718) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %721 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %722 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %723 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %724 = emitc.call_opaque "__Runtime_dma_createio_4"(%36, %720, %721, %722, %723) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    %725 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %726 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %727 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %728 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %729 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %730 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %731 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %732 = emitc.call_opaque "__runtime_buffer_arg"(%727) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %733 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %734 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %735 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %736 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %737 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %738 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %739 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %732, %9, %729, %730, %738, %731, %733, %734, %735, %736, %737) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %740 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %741 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %742 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %743 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %744 = emitc.call_opaque "__runtime_buffer_arg"(%726) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %745 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %746 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %747 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %748 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %749 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %750 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %751 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %744, %10, %741, %742, %750, %743, %745, %746, %747, %748, %749) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %752 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %753 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %754 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %755 = emitc.call_opaque "__Runtime_dma_createio_4"(%196, %751, %752, %753, %754) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    %756 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %757 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %758 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %759 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %760 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %761 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %762 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %763 = emitc.call_opaque "__runtime_buffer_arg"(%758) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %764 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %765 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %766 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %767 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %768 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %769 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %770 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %763, %9, %760, %761, %769, %762, %764, %765, %766, %767, %768) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %771 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %772 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %773 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %774 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %775 = emitc.call_opaque "__runtime_buffer_arg"(%757) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %776 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %777 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %778 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %779 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %780 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %781 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %782 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %775, %10, %772, %773, %781, %774, %776, %777, %778, %779, %780) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %783 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %784 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %785 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %786 = emitc.call_opaque "__Runtime_dma_createio_4"(%364, %782, %783, %784, %785) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    %787 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %788 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %789 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %790 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %791 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %792 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %793 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %794 = emitc.call_opaque "__runtime_buffer_arg"(%789) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %795 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %796 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %797 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %798 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %799 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %800 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %801 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %794, %9, %791, %792, %800, %793, %795, %796, %797, %798, %799) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %802 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %803 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %804 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %805 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %806 = emitc.call_opaque "__runtime_buffer_arg"(%788) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %807 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %808 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %809 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %810 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %811 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %812 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %813 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %806, %10, %803, %804, %812, %805, %807, %808, %809, %810, %811) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %814 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %815 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %816 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %817 = emitc.call_opaque "__Runtime_dma_createio_4"(%532, %813, %814, %815, %816) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    %818 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,0) */"
    %819 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %820 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %821 = emitc.call_opaque "__Runtime_startio"(%arg0, %694, %819, %820) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %822 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %823 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %822) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=192, len=2048, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %824 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %825 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %826 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %827 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %828 = emitc.call_opaque "__runtime_buffer_arg"(%823) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %829 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %830 = emitc.call_opaque "__runtime_buffer_offset"(%828, %829) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %831 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %832 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %833 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %834 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %835 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %836 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %837 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %838 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %839 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %840 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %841 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %842 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %843 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %844 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %845 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %846 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %830, %8, %825, %826, %845, %827, %831, %832, %833, %834, %835, %836, %837, %838, %839, %840, %841, %842, %843, %844) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=128, len=2048, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %847 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %848 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %849 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %850 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %851 = emitc.call_opaque "__runtime_buffer_arg"(%823) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %852 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %853 = emitc.call_opaque "__runtime_buffer_offset"(%851, %852) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %854 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %855 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %856 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %857 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %858 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %859 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %860 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %861 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %862 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %863 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %864 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %865 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %866 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %867 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %868 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %869 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %853, %7, %848, %849, %868, %850, %854, %855, %856, %857, %858, %859, %860, %861, %862, %863, %864, %865, %866, %867) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=64, len=2048, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %870 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %871 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %872 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %873 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %874 = emitc.call_opaque "__runtime_buffer_arg"(%823) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %875 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %876 = emitc.call_opaque "__runtime_buffer_offset"(%874, %875) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %877 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %878 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %879 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %880 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %881 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %882 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %883 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %884 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %885 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %886 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %887 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %888 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %889 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %890 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %891 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %892 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %876, %9, %871, %872, %891, %873, %877, %878, %879, %880, %881, %882, %883, %884, %885, %886, %887, %888, %889, %890) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=2048, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %893 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %894 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %895 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %896 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %897 = emitc.call_opaque "__runtime_buffer_arg"(%823) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %898 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %899 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %900 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %901 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %902 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %903 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %904 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %905 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %906 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %907 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %908 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %909 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %910 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %911 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %912 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %913 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %897, %10, %894, %895, %912, %896, %898, %899, %900, %901, %902, %903, %904, %905, %906, %907, %908, %909, %910, %911) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %914 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %915 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %916 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %513, %914, %916) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %917 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %913, %914, %915, %916) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %918 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %919 = emitc.call_opaque "__runtime_buffer_offset"(%823, %918) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %920 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %921 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %922 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %923 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %924 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %925 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %926 = emitc.call_opaque "__runtime_buffer_arg"(%921) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %927 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %928 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %929 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %930 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %931 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %932 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %933 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %926, %8, %923, %924, %932, %925, %927, %928, %929, %930, %931) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %934 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %935 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %936 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %937 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %938 = emitc.call_opaque "__runtime_buffer_arg"(%920) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %939 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %940 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %941 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %942 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %943 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %944 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %945 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %938, %7, %935, %936, %944, %937, %939, %940, %941, %942, %943) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %946 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %947 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %948 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %949 = emitc.call_opaque "__Runtime_dma_createio_4"(%36, %945, %946, %947, %948) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %950 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %951 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %952 = emitc.call_opaque "__runtime_buffer_offset"(%823, %951) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %953 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %954 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %955 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %956 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %957 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %958 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %959 = emitc.call_opaque "__runtime_buffer_arg"(%954) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %960 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %961 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %962 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %963 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %964 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %965 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %966 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %959, %8, %956, %957, %965, %958, %960, %961, %962, %963, %964) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %967 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %968 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %969 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %970 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %971 = emitc.call_opaque "__runtime_buffer_arg"(%953) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %972 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %973 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %974 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %975 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %976 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %977 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %978 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %971, %7, %968, %969, %977, %970, %972, %973, %974, %975, %976) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %979 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %980 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %981 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %982 = emitc.call_opaque "__Runtime_dma_createio_4"(%196, %978, %979, %980, %981) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %983 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %984 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %985 = emitc.call_opaque "__runtime_buffer_offset"(%823, %984) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %986 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %987 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %988 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %989 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %990 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %991 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %992 = emitc.call_opaque "__runtime_buffer_arg"(%987) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %993 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %994 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %995 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %996 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %997 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %998 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %999 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %992, %8, %989, %990, %998, %991, %993, %994, %995, %996, %997) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1000 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1001 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1002 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1003 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1004 = emitc.call_opaque "__runtime_buffer_arg"(%986) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1005 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1006 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1007 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1008 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1009 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1010 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1011 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %1004, %7, %1001, %1002, %1010, %1003, %1005, %1006, %1007, %1008, %1009) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1012 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1013 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1014 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %1015 = emitc.call_opaque "__Runtime_dma_createio_4"(%364, %1011, %1012, %1013, %1014) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %1016 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1017 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1018 = emitc.call_opaque "__runtime_buffer_offset"(%823, %1017) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1019 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1020 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1021 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1022 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1023 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1024 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1025 = emitc.call_opaque "__runtime_buffer_arg"(%1020) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1026 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1027 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1028 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1029 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1030 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1031 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1032 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %1025, %8, %1022, %1023, %1031, %1024, %1026, %1027, %1028, %1029, %1030) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1033 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1034 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1035 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1036 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1037 = emitc.call_opaque "__runtime_buffer_arg"(%1019) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1038 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1039 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1040 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1041 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1042 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1043 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1044 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %1037, %7, %1034, %1035, %1043, %1036, %1038, %1039, %1040, %1041, %1042) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1045 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1046 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1047 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %1048 = emitc.call_opaque "__Runtime_dma_createio_4"(%532, %1044, %1045, %1046, %1047) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    %1049 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %1050 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1051 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1052 = emitc.call_opaque "__Runtime_startio"(%arg0, %917, %1050, %1051) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1053 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1054 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1053) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1055 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1056 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %1057 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1058 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1059 = emitc.call_opaque "__runtime_buffer_arg"(%1054) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1060 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1061 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1062 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1064 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1066 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %177, %1059, %12, %1056, %1057, %1065, %1058, %1060, %1061, %1062, %1063, %1064) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1067 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1068 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1069 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
    %1070 = emitc.call_opaque "__Runtime_dma_createio_4"(%177, %1066, %1067, %1068, %1069) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1071 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1072 = emitc.call_opaque "__runtime_buffer_offset"(%1054, %1071) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1073 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1074 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1075 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1076 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1077 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1078 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1079 = emitc.call_opaque "__runtime_buffer_arg"(%1074) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1081 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1082 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1083 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1084 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1085 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1086 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1079, %9, %1076, %1077, %1085, %1078, %1080, %1081, %1082, %1083, %1084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1087 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1088 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1089 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1090 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1091 = emitc.call_opaque "__runtime_buffer_arg"(%1073) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1092 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1093 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1094 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1095 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1096 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1097 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1098 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1091, %10, %1088, %1089, %1097, %1090, %1092, %1093, %1094, %1095, %1096) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1099 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1100 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1101 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %1102 = emitc.call_opaque "__Runtime_dma_createio_4"(%70, %1098, %1099, %1100, %1101) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %1103 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1104 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1105 = emitc.call_opaque "__runtime_buffer_offset"(%1054, %1104) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1106 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1107 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1108 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1109 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1110 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1111 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1112 = emitc.call_opaque "__runtime_buffer_arg"(%1107) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1113 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1114 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1115 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1116 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1117 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1118 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1119 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1112, %9, %1109, %1110, %1118, %1111, %1113, %1114, %1115, %1116, %1117) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1120 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1121 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1122 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1123 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1124 = emitc.call_opaque "__runtime_buffer_arg"(%1106) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1125 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1126 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1127 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1128 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1129 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1130 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1131 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1124, %10, %1121, %1122, %1130, %1123, %1125, %1126, %1127, %1128, %1129) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1132 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1133 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1134 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %1135 = emitc.call_opaque "__Runtime_dma_createio_4"(%232, %1131, %1132, %1133, %1134) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %1136 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1137 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1138 = emitc.call_opaque "__runtime_buffer_offset"(%1054, %1137) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1139 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1140 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1141 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1142 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1143 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1144 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1145 = emitc.call_opaque "__runtime_buffer_arg"(%1140) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1147 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1148 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1149 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1150 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1151 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1152 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1145, %9, %1142, %1143, %1151, %1144, %1146, %1147, %1148, %1149, %1150) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1153 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1154 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1155 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1156 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1157 = emitc.call_opaque "__runtime_buffer_arg"(%1139) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1158 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1159 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1160 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1161 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1162 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1163 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1164 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1157, %10, %1154, %1155, %1163, %1156, %1158, %1159, %1160, %1161, %1162) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1165 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1166 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1167 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %1168 = emitc.call_opaque "__Runtime_dma_createio_4"(%400, %1164, %1165, %1166, %1167) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %1169 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1170 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1171 = emitc.call_opaque "__runtime_buffer_offset"(%1054, %1170) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1172 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1173 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1174 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1175 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1176 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1177 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1178 = emitc.call_opaque "__runtime_buffer_arg"(%1173) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1180 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1181 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1182 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1183 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1184 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1185 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1178, %9, %1175, %1176, %1184, %1177, %1179, %1180, %1181, %1182, %1183) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1186 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1187 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1188 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1189 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1190 = emitc.call_opaque "__runtime_buffer_arg"(%1172) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1191 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1192 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1193 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1194 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1195 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1196 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1197 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1190, %10, %1187, %1188, %1196, %1189, %1191, %1192, %1193, %1194, %1195) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1198 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1199 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1200 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %1201 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %1197, %1198, %1199, %1200) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    %1202 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
    %1203 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1204 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1205 = emitc.call_opaque "__Runtime_startio"(%arg0, %1070, %1203, %1204) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1206 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1207 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1206) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=192, len=2048, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1208 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1209 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1210 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1211 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1212 = emitc.call_opaque "__runtime_buffer_arg"(%1207) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1213 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1214 = emitc.call_opaque "__runtime_buffer_offset"(%1212, %1213) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1215 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1216 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1217 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1218 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1220 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1221 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1222 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1223 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1224 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1225 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1226 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1227 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1228 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1229 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1230 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %1214, %6, %1209, %1210, %1229, %1211, %1215, %1216, %1217, %1218, %1219, %1220, %1221, %1222, %1223, %1224, %1225, %1226, %1227, %1228) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=128, len=2048, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1231 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1232 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1233 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1234 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1235 = emitc.call_opaque "__runtime_buffer_arg"(%1207) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1236 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1237 = emitc.call_opaque "__runtime_buffer_offset"(%1235, %1236) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1238 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1239 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1240 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1241 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1242 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1243 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1244 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1245 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1246 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1247 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1248 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1249 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1250 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1251 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1252 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1253 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %1237, %5, %1232, %1233, %1252, %1234, %1238, %1239, %1240, %1241, %1242, %1243, %1244, %1245, %1246, %1247, %1248, %1249, %1250, %1251) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=64, len=2048, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1254 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1255 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1256 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1257 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1258 = emitc.call_opaque "__runtime_buffer_arg"(%1207) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1259 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1260 = emitc.call_opaque "__runtime_buffer_offset"(%1258, %1259) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1261 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1262 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1263 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1264 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1265 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1266 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1267 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1268 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1269 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1270 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1271 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1272 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1273 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1274 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1275 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1276 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %1260, %4, %1255, %1256, %1275, %1257, %1261, %1262, %1263, %1264, %1265, %1266, %1267, %1268, %1269, %1270, %1271, %1272, %1273, %1274) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, offset=0, len=2048, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1277 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1278 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1279 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1280 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1281 = emitc.call_opaque "__runtime_buffer_arg"(%1207) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1282 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1284 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1286 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1287 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1288 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1289 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1290 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1291 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1292 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1293 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1294 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1295 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1296 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1297 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %513, %1281, %3, %1278, %1279, %1296, %1280, %1282, %1283, %1284, %1285, %1286, %1287, %1288, %1289, %1290, %1291, %1292, %1293, %1294, %1295) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1298 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1299 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1300 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %513, %1298, %1300) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1301 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %1297, %1298, %1299, %1300) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1302 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1303 = emitc.call_opaque "__runtime_buffer_offset"(%1207, %1302) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1304 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1305 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1306 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1307 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1308 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1309 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1310 = emitc.call_opaque "__runtime_buffer_arg"(%1305) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1311 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1312 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1313 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1314 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1315 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1316 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1317 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1310, %8, %1307, %1308, %1316, %1309, %1311, %1312, %1313, %1314, %1315) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1318 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1319 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1320 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1321 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1322 = emitc.call_opaque "__runtime_buffer_arg"(%1304) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1323 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1324 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1325 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1326 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1327 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1328 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1329 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1322, %7, %1319, %1320, %1328, %1321, %1323, %1324, %1325, %1326, %1327) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1330 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1331 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1332 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %1333 = emitc.call_opaque "__Runtime_dma_createio_4"(%70, %1329, %1330, %1331, %1332) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %1334 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1335 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1336 = emitc.call_opaque "__runtime_buffer_offset"(%1207, %1335) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1337 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1338 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1339 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1340 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1341 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1342 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1343 = emitc.call_opaque "__runtime_buffer_arg"(%1338) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1344 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1345 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1346 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1347 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1348 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1349 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1350 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1343, %8, %1340, %1341, %1349, %1342, %1344, %1345, %1346, %1347, %1348) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1351 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1352 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1353 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1354 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1355 = emitc.call_opaque "__runtime_buffer_arg"(%1337) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1356 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1357 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1358 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1359 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1360 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1361 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1362 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1355, %7, %1352, %1353, %1361, %1354, %1356, %1357, %1358, %1359, %1360) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1363 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1364 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1365 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %1366 = emitc.call_opaque "__Runtime_dma_createio_4"(%232, %1362, %1363, %1364, %1365) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %1367 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1368 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1369 = emitc.call_opaque "__runtime_buffer_offset"(%1207, %1368) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1370 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1371 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1373 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1374 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1375 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1376 = emitc.call_opaque "__runtime_buffer_arg"(%1371) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1377 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1378 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1379 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1380 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1381 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1382 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1383 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1376, %8, %1373, %1374, %1382, %1375, %1377, %1378, %1379, %1380, %1381) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1384 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1385 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1386 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1387 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1388 = emitc.call_opaque "__runtime_buffer_arg"(%1370) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1389 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1390 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1391 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1392 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1393 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1394 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1395 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1388, %7, %1385, %1386, %1394, %1387, %1389, %1390, %1391, %1392, %1393) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1396 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1397 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1398 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %1399 = emitc.call_opaque "__Runtime_dma_createio_4"(%400, %1395, %1396, %1397, %1398) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %1400 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1401 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1402 = emitc.call_opaque "__runtime_buffer_offset"(%1207, %1401) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1403 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1404 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1406 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1407 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1408 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1409 = emitc.call_opaque "__runtime_buffer_arg"(%1404) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1410 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1411 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1412 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1413 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1414 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1415 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1416 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1409, %8, %1406, %1407, %1415, %1408, %1410, %1411, %1412, %1413, %1414) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1417 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1418 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1419 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1420 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1421 = emitc.call_opaque "__runtime_buffer_arg"(%1403) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1422 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1423 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1424 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1425 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1426 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1427 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1428 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1421, %7, %1418, %1419, %1427, %1420, %1422, %1423, %1424, %1425, %1426) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1429 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1430 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1431 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %1432 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %1428, %1429, %1430, %1431) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    %1433 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %1434 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1435 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1436 = emitc.call_opaque "__Runtime_startio"(%arg0, %1301, %1434, %1435) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1437 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1438 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1437) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1439 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1440 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %1441 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1442 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1443 = emitc.call_opaque "__runtime_buffer_arg"(%1438) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1444 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1445 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1446 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1447 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1448 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1449 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1450 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %345, %1443, %12, %1440, %1441, %1449, %1442, %1444, %1445, %1446, %1447, %1448) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1451 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1452 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1453 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %1454 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %1450, %1451, %1452, %1453) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1455 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1456 = emitc.call_opaque "__runtime_buffer_offset"(%1438, %1455) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1457 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1458 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1459 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1460 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1461 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1462 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1463 = emitc.call_opaque "__runtime_buffer_arg"(%1458) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1464 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1465 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1466 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1467 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1468 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1469 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1470 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1463, %9, %1460, %1461, %1469, %1462, %1464, %1465, %1466, %1467, %1468) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1471 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1472 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1473 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1474 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1475 = emitc.call_opaque "__runtime_buffer_arg"(%1457) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1476 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1477 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1478 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1479 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1480 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1481 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1482 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1475, %10, %1472, %1473, %1481, %1474, %1476, %1477, %1478, %1479, %1480) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1483 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1484 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1485 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %1486 = emitc.call_opaque "__Runtime_dma_createio_4"(%104, %1482, %1483, %1484, %1485) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %1487 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1488 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1489 = emitc.call_opaque "__runtime_buffer_offset"(%1438, %1488) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1490 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1491 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1492 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1493 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1494 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1495 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1496 = emitc.call_opaque "__runtime_buffer_arg"(%1491) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1497 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1498 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1499 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1500 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1501 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1502 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1503 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1496, %9, %1493, %1494, %1502, %1495, %1497, %1498, %1499, %1500, %1501) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1504 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1505 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1506 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1507 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1508 = emitc.call_opaque "__runtime_buffer_arg"(%1490) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1509 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1510 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1511 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1512 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1513 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1514 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1515 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1508, %10, %1505, %1506, %1514, %1507, %1509, %1510, %1511, %1512, %1513) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1516 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1517 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1518 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %1519 = emitc.call_opaque "__Runtime_dma_createio_4"(%268, %1515, %1516, %1517, %1518) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %1520 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1521 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1522 = emitc.call_opaque "__runtime_buffer_offset"(%1438, %1521) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1523 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1524 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1525 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1526 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1527 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1528 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1529 = emitc.call_opaque "__runtime_buffer_arg"(%1524) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1530 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1531 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1532 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1533 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1534 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1535 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1536 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1529, %9, %1526, %1527, %1535, %1528, %1530, %1531, %1532, %1533, %1534) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1537 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1538 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1539 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1540 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1541 = emitc.call_opaque "__runtime_buffer_arg"(%1523) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1542 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1543 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1544 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1545 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1546 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1547 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1548 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1541, %10, %1538, %1539, %1547, %1540, %1542, %1543, %1544, %1545, %1546) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1549 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1550 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1551 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %1552 = emitc.call_opaque "__Runtime_dma_createio_4"(%436, %1548, %1549, %1550, %1551) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %1553 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1554 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1555 = emitc.call_opaque "__runtime_buffer_offset"(%1438, %1554) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1556 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1557 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1558 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1559 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1560 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1561 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1562 = emitc.call_opaque "__runtime_buffer_arg"(%1557) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1563 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1564 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1565 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1566 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1567 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1568 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1569 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1562, %9, %1559, %1560, %1568, %1561, %1563, %1564, %1565, %1566, %1567) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1570 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1571 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1572 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1573 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1574 = emitc.call_opaque "__runtime_buffer_arg"(%1556) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1575 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1576 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1577 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1578 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1579 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1580 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1581 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1574, %10, %1571, %1572, %1580, %1573, %1575, %1576, %1577, %1578, %1579) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1582 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1583 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1584 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %1585 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1581, %1582, %1583, %1584) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    %1586 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %1587 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1588 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1589 = emitc.call_opaque "__Runtime_startio"(%arg0, %1454, %1587, %1588) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1590 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1591 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1590) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, offset=192, len=2048, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1592 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1593 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1594 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1595 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1596 = emitc.call_opaque "__runtime_buffer_arg"(%1591) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1597 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1598 = emitc.call_opaque "__runtime_buffer_offset"(%1596, %1597) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1599 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1600 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1601 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1602 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1603 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1604 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1605 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1606 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1607 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1608 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1609 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1610 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1611 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1612 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1613 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1614 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %1598, %2, %1593, %1594, %1613, %1595, %1599, %1600, %1601, %1602, %1603, %1604, %1605, %1606, %1607, %1608, %1609, %1610, %1611, %1612) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=128, len=2048, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1615 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1616 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1617 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1618 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1619 = emitc.call_opaque "__runtime_buffer_arg"(%1591) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1620 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1621 = emitc.call_opaque "__runtime_buffer_offset"(%1619, %1620) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1622 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1623 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1624 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1625 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1626 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1627 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1628 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1629 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1630 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1631 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1632 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1633 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1634 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1635 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1636 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1637 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %1621, %8, %1616, %1617, %1636, %1618, %1622, %1623, %1624, %1625, %1626, %1627, %1628, %1629, %1630, %1631, %1632, %1633, %1634, %1635) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=64, len=2048, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1638 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1639 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1640 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1641 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1642 = emitc.call_opaque "__runtime_buffer_arg"(%1591) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1643 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1644 = emitc.call_opaque "__runtime_buffer_offset"(%1642, %1643) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1645 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1646 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1647 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1648 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1649 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1650 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1651 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1652 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1653 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1654 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1655 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1656 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1657 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1658 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1659 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1660 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %1644, %7, %1639, %1640, %1659, %1641, %1645, %1646, %1647, %1648, %1649, %1650, %1651, %1652, %1653, %1654, %1655, %1656, %1657, %1658) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=2048, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1661 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1662 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1663 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1664 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1665 = emitc.call_opaque "__runtime_buffer_arg"(%1591) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1666 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1667 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1668 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1669 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1670 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1671 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1672 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1673 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1674 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1675 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1676 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1677 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1678 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1679 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1680 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1681 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %1665, %9, %1662, %1663, %1680, %1664, %1666, %1667, %1668, %1669, %1670, %1671, %1672, %1673, %1674, %1675, %1676, %1677, %1678, %1679) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1682 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1683 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1684 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %345, %1682, %1684) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1685 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %1681, %1682, %1683, %1684) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1686 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1687 = emitc.call_opaque "__runtime_buffer_offset"(%1591, %1686) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1688 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1689 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1690 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1691 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1692 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1693 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1694 = emitc.call_opaque "__runtime_buffer_arg"(%1689) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1695 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1696 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1697 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1698 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1699 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1700 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1701 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1694, %8, %1691, %1692, %1700, %1693, %1695, %1696, %1697, %1698, %1699) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1702 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1703 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1704 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1705 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1706 = emitc.call_opaque "__runtime_buffer_arg"(%1688) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1707 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1708 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1709 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1710 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1711 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1712 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1713 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1706, %7, %1703, %1704, %1712, %1705, %1707, %1708, %1709, %1710, %1711) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1714 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1715 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1716 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %1717 = emitc.call_opaque "__Runtime_dma_createio_4"(%104, %1713, %1714, %1715, %1716) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %1718 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1719 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1720 = emitc.call_opaque "__runtime_buffer_offset"(%1591, %1719) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1721 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1722 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1723 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1724 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1725 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1726 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1727 = emitc.call_opaque "__runtime_buffer_arg"(%1722) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1728 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1729 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1730 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1731 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1732 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1733 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1734 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1727, %8, %1724, %1725, %1733, %1726, %1728, %1729, %1730, %1731, %1732) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1735 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1736 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1737 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1738 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1739 = emitc.call_opaque "__runtime_buffer_arg"(%1721) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1740 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1741 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1742 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1743 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1744 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1745 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1746 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1739, %7, %1736, %1737, %1745, %1738, %1740, %1741, %1742, %1743, %1744) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1747 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1748 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1749 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %1750 = emitc.call_opaque "__Runtime_dma_createio_4"(%268, %1746, %1747, %1748, %1749) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %1751 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1752 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1753 = emitc.call_opaque "__runtime_buffer_offset"(%1591, %1752) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1754 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1755 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1756 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1757 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1758 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1759 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1760 = emitc.call_opaque "__runtime_buffer_arg"(%1755) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1761 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1762 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1763 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1764 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1765 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1766 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1767 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1760, %8, %1757, %1758, %1766, %1759, %1761, %1762, %1763, %1764, %1765) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1768 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1769 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1770 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1771 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1772 = emitc.call_opaque "__runtime_buffer_arg"(%1754) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1773 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1774 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1775 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1776 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1777 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1778 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1779 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1772, %7, %1769, %1770, %1778, %1771, %1773, %1774, %1775, %1776, %1777) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1780 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1781 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1782 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %1783 = emitc.call_opaque "__Runtime_dma_createio_4"(%436, %1779, %1780, %1781, %1782) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %1784 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1785 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1786 = emitc.call_opaque "__runtime_buffer_offset"(%1591, %1785) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1787 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1788 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1789 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1790 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1791 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1792 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1793 = emitc.call_opaque "__runtime_buffer_arg"(%1788) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1794 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1795 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1796 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1797 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1798 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1799 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1800 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1793, %8, %1790, %1791, %1799, %1792, %1794, %1795, %1796, %1797, %1798) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1801 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1802 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1803 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1804 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1805 = emitc.call_opaque "__runtime_buffer_arg"(%1787) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1806 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1807 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1808 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1809 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1810 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1811 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1812 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1805, %7, %1802, %1803, %1811, %1804, %1806, %1807, %1808, %1809, %1810) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1813 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1814 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1815 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %1816 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1812, %1813, %1814, %1815) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    %1817 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %1818 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1819 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1820 = emitc.call_opaque "__Runtime_startio"(%arg0, %1685, %1818, %1819) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1821 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1822 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1821) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1823 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1824 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %1825 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1826 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1827 = emitc.call_opaque "__runtime_buffer_arg"(%1822) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1828 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1829 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1830 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1831 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1832 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1833 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1834 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %1827, %1, %1824, %1825, %1833, %1826, %1828, %1829, %1830, %1831, %1832) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1835 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1836 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1837 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
    %1838 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %1834, %1835, %1836, %1837) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1839 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1840 = emitc.call_opaque "__runtime_buffer_offset"(%1822, %1839) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1841 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1842 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1843 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1844 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1845 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1846 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1847 = emitc.call_opaque "__runtime_buffer_arg"(%1842) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1848 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1849 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1850 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1851 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1852 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1853 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1854 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %1847, %9, %1844, %1845, %1853, %1846, %1848, %1849, %1850, %1851, %1852) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1855 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1856 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1857 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1858 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1859 = emitc.call_opaque "__runtime_buffer_arg"(%1841) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1860 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1861 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1862 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1863 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1864 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1865 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1866 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %1859, %10, %1856, %1857, %1865, %1858, %1860, %1861, %1862, %1863, %1864) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1867 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1868 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1869 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %1870 = emitc.call_opaque "__Runtime_dma_createio_4"(%138, %1866, %1867, %1868, %1869) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %1871 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1872 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1873 = emitc.call_opaque "__runtime_buffer_offset"(%1822, %1872) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1874 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1875 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1876 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1877 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1878 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1879 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1880 = emitc.call_opaque "__runtime_buffer_arg"(%1875) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1881 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1882 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1883 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1884 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1885 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1886 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1887 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %1880, %9, %1877, %1878, %1886, %1879, %1881, %1882, %1883, %1884, %1885) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1888 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1889 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1890 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1891 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1892 = emitc.call_opaque "__runtime_buffer_arg"(%1874) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1893 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1894 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1895 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1896 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1897 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1898 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1899 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %1892, %10, %1889, %1890, %1898, %1891, %1893, %1894, %1895, %1896, %1897) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1900 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1901 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1902 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %1903 = emitc.call_opaque "__Runtime_dma_createio_4"(%304, %1899, %1900, %1901, %1902) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %1904 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1905 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1906 = emitc.call_opaque "__runtime_buffer_offset"(%1822, %1905) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1907 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1908 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1909 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1910 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1911 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1912 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1913 = emitc.call_opaque "__runtime_buffer_arg"(%1908) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1914 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1915 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1916 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1917 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1918 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1919 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1920 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %1913, %9, %1910, %1911, %1919, %1912, %1914, %1915, %1916, %1917, %1918) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1921 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1922 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1923 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1924 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1925 = emitc.call_opaque "__runtime_buffer_arg"(%1907) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1926 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1927 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1928 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1929 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1930 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1931 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1932 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %1925, %10, %1922, %1923, %1931, %1924, %1926, %1927, %1928, %1929, %1930) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1933 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1934 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1935 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %1936 = emitc.call_opaque "__Runtime_dma_createio_4"(%472, %1932, %1933, %1934, %1935) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %1937 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1938 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1939 = emitc.call_opaque "__runtime_buffer_offset"(%1822, %1938) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1940 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1941 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1942 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1943 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1944 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1945 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1946 = emitc.call_opaque "__runtime_buffer_arg"(%1941) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1947 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1948 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1949 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1950 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1951 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1952 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1953 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1946, %9, %1943, %1944, %1952, %1945, %1947, %1948, %1949, %1950, %1951) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1954 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1955 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1956 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1957 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1958 = emitc.call_opaque "__runtime_buffer_arg"(%1940) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1959 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1960 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1961 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1962 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1963 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1964 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1965 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1958, %10, %1955, %1956, %1964, %1957, %1959, %1960, %1961, %1962, %1963) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1966 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1967 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1968 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %1969 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1965, %1966, %1967, %1968) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    %1970 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %1971 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1972 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1973 = emitc.call_opaque "__Runtime_startio"(%arg0, %1838, %1971, %1972) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1974 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1975 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1974) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=192, len=2048, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1976 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1977 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %1978 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1979 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1980 = emitc.call_opaque "__runtime_buffer_arg"(%1975) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1981 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1982 = emitc.call_opaque "__runtime_buffer_offset"(%1980, %1981) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1983 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1984 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1985 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1986 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1987 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1988 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1989 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1990 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1991 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1992 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1993 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1994 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1995 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %1996 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1997 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1998 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %1982, %1, %1977, %1978, %1997, %1979, %1983, %1984, %1985, %1986, %1987, %1988, %1989, %1990, %1991, %1992, %1993, %1994, %1995, %1996) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=128, len=2048, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1999 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %2000 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2001 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2002 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2003 = emitc.call_opaque "__runtime_buffer_arg"(%1975) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2004 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %2005 = emitc.call_opaque "__runtime_buffer_offset"(%2003, %2004) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2006 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2007 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2008 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2009 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2010 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2011 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2012 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2013 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2014 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2015 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %2016 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2017 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2018 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %2019 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2020 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2021 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %2005, %6, %2000, %2001, %2020, %2002, %2006, %2007, %2008, %2009, %2010, %2011, %2012, %2013, %2014, %2015, %2016, %2017, %2018, %2019) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=64, len=2048, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %2022 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2023 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2024 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2025 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2026 = emitc.call_opaque "__runtime_buffer_arg"(%1975) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2027 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %2028 = emitc.call_opaque "__runtime_buffer_offset"(%2026, %2027) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2029 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2030 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2031 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2032 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2033 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2034 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2035 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2036 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2037 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2038 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %2039 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2040 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2041 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %2042 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2043 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2044 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %2028, %5, %2023, %2024, %2043, %2025, %2029, %2030, %2031, %2032, %2033, %2034, %2035, %2036, %2037, %2038, %2039, %2040, %2041, %2042) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=0, len=2048, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %2045 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2046 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2047 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2048 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %2049 = emitc.call_opaque "__runtime_buffer_arg"(%1975) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2050 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2051 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2052 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2053 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2054 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2055 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2056 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2057 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2058 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2059 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %2060 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2061 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2062 = "emitc.constant"() <{value = 8192 : i32}> : () -> i32
    %2063 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2065 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %345, %2049, %4, %2046, %2047, %2064, %2048, %2050, %2051, %2052, %2053, %2054, %2055, %2056, %2057, %2058, %2059, %2060, %2061, %2062, %2063) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2066 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2067 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2068 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %345, %2066, %2068) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %2069 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %2065, %2066, %2067, %2068) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %2070 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %2071 = emitc.call_opaque "__runtime_buffer_offset"(%1975, %2070) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2072 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2073 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %2074 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2075 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2077 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %2078 = emitc.call_opaque "__runtime_buffer_arg"(%2073) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2079 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2080 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2081 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2082 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2083 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2084 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2085 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %2078, %8, %2075, %2076, %2084, %2077, %2079, %2080, %2081, %2082, %2083) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %2086 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2087 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2088 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2089 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %2090 = emitc.call_opaque "__runtime_buffer_arg"(%2072) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2091 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2092 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2093 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2094 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2095 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2096 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2097 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %2090, %7, %2087, %2088, %2096, %2089, %2091, %2092, %2093, %2094, %2095) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2098 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2099 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2100 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %2101 = emitc.call_opaque "__Runtime_dma_createio_4"(%138, %2097, %2098, %2099, %2100) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %2102 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2103 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %2104 = emitc.call_opaque "__runtime_buffer_offset"(%1975, %2103) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2105 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2106 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %2107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2108 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2109 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2110 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2111 = emitc.call_opaque "__runtime_buffer_arg"(%2106) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2112 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2113 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2114 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2115 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2116 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %2117 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2118 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %2111, %8, %2108, %2109, %2117, %2110, %2112, %2113, %2114, %2115, %2116) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %2119 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2120 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2121 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2122 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2123 = emitc.call_opaque "__runtime_buffer_arg"(%2105) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2124 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2125 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2126 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2127 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2128 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %2129 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2130 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %2123, %7, %2120, %2121, %2129, %2122, %2124, %2125, %2126, %2127, %2128) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2131 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2132 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2133 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %2134 = emitc.call_opaque "__Runtime_dma_createio_4"(%304, %2130, %2131, %2132, %2133) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %2135 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2136 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %2137 = emitc.call_opaque "__runtime_buffer_offset"(%1975, %2136) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2138 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2139 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %2140 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2141 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2142 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2143 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2144 = emitc.call_opaque "__runtime_buffer_arg"(%2139) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2145 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2146 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2147 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2148 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2149 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %2150 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2151 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %2144, %8, %2141, %2142, %2150, %2143, %2145, %2146, %2147, %2148, %2149) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %2152 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2153 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2154 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2155 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2156 = emitc.call_opaque "__runtime_buffer_arg"(%2138) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2157 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2158 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2159 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2160 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2161 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %2162 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2163 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %2156, %7, %2153, %2154, %2162, %2155, %2157, %2158, %2159, %2160, %2161) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2164 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2165 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2166 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %2167 = emitc.call_opaque "__Runtime_dma_createio_4"(%472, %2163, %2164, %2165, %2166) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %2168 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2169 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %2170 = emitc.call_opaque "__runtime_buffer_offset"(%1975, %2169) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2171 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2172 = "emitc.constant"() <{value = #emitc.opaque<"(void*)53248">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=2048, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %2173 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2174 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2175 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2176 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2177 = emitc.call_opaque "__runtime_buffer_arg"(%2172) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2178 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2179 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2180 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2181 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2182 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %2183 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2184 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %2177, %8, %2174, %2175, %2183, %2176, %2178, %2179, %2180, %2181, %2182) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=2048, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %2185 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2186 = "emitc.constant"() <{value = 2048 : i32}> : () -> i32
    %2187 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2188 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2189 = emitc.call_opaque "__runtime_buffer_arg"(%2171) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2190 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2191 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2192 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2193 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2194 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %2195 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2196 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %2189, %7, %2186, %2187, %2195, %2188, %2190, %2191, %2192, %2193, %2194) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2197 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2198 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2199 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %2200 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %2196, %2197, %2198, %2199) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    %2201 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %2202 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2203 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2204 = emitc.call_opaque "__Runtime_startio"(%arg0, %2069, %2202, %2203) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %2205 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2206 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %36, %70, %104, %138, %196, %232, %268, %304, %364, %400, %436, %472, %532, %568, %604, %640, %2205) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %2207 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %2206) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %2208 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2209 = emitc.call_opaque "__Runtime_startio"(%arg0, %66, %67, %2208) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2210 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2211 = emitc.call_opaque "__Runtime_startio"(%arg0, %100, %101, %2210) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2212 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2213 = emitc.call_opaque "__Runtime_startio"(%arg0, %134, %135, %2212) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2214 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2215 = emitc.call_opaque "__Runtime_startio"(%arg0, %168, %169, %2214) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2216 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2217 = emitc.call_opaque "__Runtime_startio"(%arg0, %228, %229, %2216) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2218 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2219 = emitc.call_opaque "__Runtime_startio"(%arg0, %264, %265, %2218) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2220 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2221 = emitc.call_opaque "__Runtime_startio"(%arg0, %300, %301, %2220) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2222 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2223 = emitc.call_opaque "__Runtime_startio"(%arg0, %336, %337, %2222) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2224 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2225 = emitc.call_opaque "__Runtime_startio"(%arg0, %396, %397, %2224) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2226 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2227 = emitc.call_opaque "__Runtime_startio"(%arg0, %432, %433, %2226) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2228 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2229 = emitc.call_opaque "__Runtime_startio"(%arg0, %468, %469, %2228) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2230 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2231 = emitc.call_opaque "__Runtime_startio"(%arg0, %504, %505, %2230) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2232 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2233 = emitc.call_opaque "__Runtime_startio"(%arg0, %564, %565, %2232) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2234 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2235 = emitc.call_opaque "__Runtime_startio"(%arg0, %600, %601, %2234) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2236 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2237 = emitc.call_opaque "__Runtime_startio"(%arg0, %636, %637, %2236) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2238 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2239 = emitc.call_opaque "__Runtime_startio"(%arg0, %672, %673, %2238) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2240 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2241 = emitc.call_opaque "__Runtime_startio"(%arg0, %724, %725, %2240) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2242 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2243 = emitc.call_opaque "__Runtime_startio"(%arg0, %755, %756, %2242) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2244 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2245 = emitc.call_opaque "__Runtime_startio"(%arg0, %786, %787, %2244) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2246 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2247 = emitc.call_opaque "__Runtime_startio"(%arg0, %817, %818, %2246) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2248 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2249 = emitc.call_opaque "__Runtime_startio"(%arg0, %949, %950, %2248) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2250 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2251 = emitc.call_opaque "__Runtime_startio"(%arg0, %982, %983, %2250) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2252 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2253 = emitc.call_opaque "__Runtime_startio"(%arg0, %1015, %1016, %2252) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2254 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2255 = emitc.call_opaque "__Runtime_startio"(%arg0, %1048, %1049, %2254) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2256 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2257 = emitc.call_opaque "__Runtime_startio"(%arg0, %1102, %1103, %2256) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2258 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2259 = emitc.call_opaque "__Runtime_startio"(%arg0, %1135, %1136, %2258) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2260 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2261 = emitc.call_opaque "__Runtime_startio"(%arg0, %1168, %1169, %2260) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2262 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2263 = emitc.call_opaque "__Runtime_startio"(%arg0, %1201, %1202, %2262) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2264 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2265 = emitc.call_opaque "__Runtime_startio"(%arg0, %1333, %1334, %2264) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2266 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2267 = emitc.call_opaque "__Runtime_startio"(%arg0, %1366, %1367, %2266) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2268 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2269 = emitc.call_opaque "__Runtime_startio"(%arg0, %1399, %1400, %2268) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2270 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2271 = emitc.call_opaque "__Runtime_startio"(%arg0, %1432, %1433, %2270) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2272 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2273 = emitc.call_opaque "__Runtime_startio"(%arg0, %1486, %1487, %2272) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2274 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2275 = emitc.call_opaque "__Runtime_startio"(%arg0, %1519, %1520, %2274) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2276 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2277 = emitc.call_opaque "__Runtime_startio"(%arg0, %1552, %1553, %2276) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2278 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2279 = emitc.call_opaque "__Runtime_startio"(%arg0, %1585, %1586, %2278) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2280 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2281 = emitc.call_opaque "__Runtime_startio"(%arg0, %1717, %1718, %2280) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2282 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2283 = emitc.call_opaque "__Runtime_startio"(%arg0, %1750, %1751, %2282) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2284 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2285 = emitc.call_opaque "__Runtime_startio"(%arg0, %1783, %1784, %2284) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2286 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2287 = emitc.call_opaque "__Runtime_startio"(%arg0, %1816, %1817, %2286) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2288 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2289 = emitc.call_opaque "__Runtime_startio"(%arg0, %1870, %1871, %2288) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2290 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2291 = emitc.call_opaque "__Runtime_startio"(%arg0, %1903, %1904, %2290) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2292 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2293 = emitc.call_opaque "__Runtime_startio"(%arg0, %1936, %1937, %2292) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2294 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2295 = emitc.call_opaque "__Runtime_startio"(%arg0, %1969, %1970, %2294) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2296 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2297 = emitc.call_opaque "__Runtime_startio"(%arg0, %2101, %2102, %2296) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2298 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2299 = emitc.call_opaque "__Runtime_startio"(%arg0, %2134, %2135, %2298) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2300 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2301 = emitc.call_opaque "__Runtime_startio"(%arg0, %2167, %2168, %2300) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2302 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2303 = emitc.call_opaque "__Runtime_startio"(%arg0, %2200, %2201, %2302) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %2207) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %172) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %340) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %508) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %676) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %821) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1052) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1205) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1436) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1589) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1820) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1973) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %2204) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
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
