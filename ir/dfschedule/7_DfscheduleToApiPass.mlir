module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 1 : i32}} {
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
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=192, len=4096, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %824 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %825 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
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
    %840 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %841 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %842 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %843 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %844 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %845 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %846 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %830, %8, %825, %826, %845, %827, %831, %832, %833, %834, %835, %836, %837, %838, %839, %840, %841, %842, %843, %844) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=128, len=4096, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %847 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %848 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
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
    %863 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %864 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %865 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %866 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %867 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %868 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %869 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %853, %7, %848, %849, %868, %850, %854, %855, %856, %857, %858, %859, %860, %861, %862, %863, %864, %865, %866, %867) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=64, len=4096, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %870 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %871 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
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
    %886 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %887 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %888 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %889 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %890 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %891 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %892 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %876, %9, %871, %872, %891, %873, %877, %878, %879, %880, %881, %882, %883, %884, %885, %886, %887, %888, %889, %890) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %893 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %894 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
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
    %907 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %908 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %909 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %910 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %911 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %912 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %913 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %897, %10, %894, %895, %912, %896, %898, %899, %900, %901, %902, %903, %904, %905, %906, %907, %908, %909, %910, %911) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
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
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=1, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %921 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %922 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %923 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %924 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %925 = emitc.call_opaque "__runtime_buffer_arg"(%920) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %926 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %927 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %928 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %929 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %930 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %931 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %932 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %36, %925, %7, %922, %923, %931, %924, %926, %927, %928, %929, %930) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 1));"
    %933 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %934 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %935 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %936 = emitc.call_opaque "__Runtime_dma_createio_4"(%36, %932, %933, %934, %935) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %937 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %938 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %939 = emitc.call_opaque "__runtime_buffer_offset"(%823, %938) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %940 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=2, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %941 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %942 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %943 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %944 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %945 = emitc.call_opaque "__runtime_buffer_arg"(%940) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %946 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %947 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %948 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %949 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %950 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %951 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %952 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %196, %945, %7, %942, %943, %951, %944, %946, %947, %948, %949, %950) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 1));"
    %953 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %954 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %955 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %956 = emitc.call_opaque "__Runtime_dma_createio_4"(%196, %952, %953, %954, %955) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %957 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %958 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %959 = emitc.call_opaque "__runtime_buffer_offset"(%823, %958) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %960 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=3, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %961 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %962 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %963 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %964 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %965 = emitc.call_opaque "__runtime_buffer_arg"(%960) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %966 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %967 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %968 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %969 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %970 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %971 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %972 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %364, %965, %7, %962, %963, %971, %964, %966, %967, %968, %969, %970) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 1));"
    %973 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %974 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %975 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %976 = emitc.call_opaque "__Runtime_dma_createio_4"(%364, %972, %973, %974, %975) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %977 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %978 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %979 = emitc.call_opaque "__runtime_buffer_offset"(%823, %978) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %980 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=4, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %981 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %982 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %983 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %984 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %985 = emitc.call_opaque "__runtime_buffer_arg"(%980) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %986 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %987 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %988 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %989 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %990 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %991 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %992 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %532, %985, %7, %982, %983, %991, %984, %986, %987, %988, %989, %990) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 1));"
    %993 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %994 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %995 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %996 = emitc.call_opaque "__Runtime_dma_createio_4"(%532, %992, %993, %994, %995) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    %997 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %998 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %999 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1000 = emitc.call_opaque "__Runtime_startio"(%arg0, %917, %998, %999) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1001 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1002 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1001) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1003 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1004 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %1005 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1006 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1007 = emitc.call_opaque "__runtime_buffer_arg"(%1002) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1008 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1009 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1010 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1011 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1012 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1013 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1014 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %177, %1007, %12, %1004, %1005, %1013, %1006, %1008, %1009, %1010, %1011, %1012) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1015 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1016 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1017 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
    %1018 = emitc.call_opaque "__Runtime_dma_createio_4"(%177, %1014, %1015, %1016, %1017) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1019 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1020 = emitc.call_opaque "__runtime_buffer_offset"(%1002, %1019) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1021 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1022 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1023 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1024 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1025 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1026 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1027 = emitc.call_opaque "__runtime_buffer_arg"(%1022) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1028 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1029 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1030 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1031 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1032 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1033 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1034 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1027, %9, %1024, %1025, %1033, %1026, %1028, %1029, %1030, %1031, %1032) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1035 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1036 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1037 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1038 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1039 = emitc.call_opaque "__runtime_buffer_arg"(%1021) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1040 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1041 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1042 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1043 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1044 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1045 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1046 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1039, %10, %1036, %1037, %1045, %1038, %1040, %1041, %1042, %1043, %1044) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1047 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1048 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1049 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %1050 = emitc.call_opaque "__Runtime_dma_createio_4"(%70, %1046, %1047, %1048, %1049) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %1051 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1052 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1053 = emitc.call_opaque "__runtime_buffer_offset"(%1002, %1052) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1054 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1055 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1056 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1057 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1058 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1060 = emitc.call_opaque "__runtime_buffer_arg"(%1055) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1061 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1062 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1063 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1064 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1065 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1067 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1060, %9, %1057, %1058, %1066, %1059, %1061, %1062, %1063, %1064, %1065) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1068 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1069 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1070 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1071 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1072 = emitc.call_opaque "__runtime_buffer_arg"(%1054) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1073 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1074 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1075 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1076 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1077 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1078 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1079 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1072, %10, %1069, %1070, %1078, %1071, %1073, %1074, %1075, %1076, %1077) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1081 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1082 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %1083 = emitc.call_opaque "__Runtime_dma_createio_4"(%232, %1079, %1080, %1081, %1082) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %1084 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1085 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1086 = emitc.call_opaque "__runtime_buffer_offset"(%1002, %1085) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1087 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1088 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1089 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1090 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1091 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1092 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1093 = emitc.call_opaque "__runtime_buffer_arg"(%1088) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1094 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1095 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1096 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1097 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1098 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1099 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1100 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1093, %9, %1090, %1091, %1099, %1092, %1094, %1095, %1096, %1097, %1098) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1101 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1102 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1103 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1104 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1105 = emitc.call_opaque "__runtime_buffer_arg"(%1087) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1106 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1107 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1108 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1109 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1110 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1111 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1112 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1105, %10, %1102, %1103, %1111, %1104, %1106, %1107, %1108, %1109, %1110) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1113 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1114 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1115 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %1116 = emitc.call_opaque "__Runtime_dma_createio_4"(%400, %1112, %1113, %1114, %1115) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %1117 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1118 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1119 = emitc.call_opaque "__runtime_buffer_offset"(%1002, %1118) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1120 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1121 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1122 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1123 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1124 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1125 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1126 = emitc.call_opaque "__runtime_buffer_arg"(%1121) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1127 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1128 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1129 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1130 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1131 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1132 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1133 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1126, %9, %1123, %1124, %1132, %1125, %1127, %1128, %1129, %1130, %1131) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1134 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1135 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1136 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1137 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1138 = emitc.call_opaque "__runtime_buffer_arg"(%1120) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1139 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1140 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1141 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1142 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1143 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1144 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1145 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1138, %10, %1135, %1136, %1144, %1137, %1139, %1140, %1141, %1142, %1143) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1147 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1148 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %1149 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %1145, %1146, %1147, %1148) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    %1150 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
    %1151 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1152 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1153 = emitc.call_opaque "__Runtime_startio"(%arg0, %1018, %1151, %1152) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1154 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1155 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1154) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=192, len=4096, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1156 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1157 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1158 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1159 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1160 = emitc.call_opaque "__runtime_buffer_arg"(%1155) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1161 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1162 = emitc.call_opaque "__runtime_buffer_offset"(%1160, %1161) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1163 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1164 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1165 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1166 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1167 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1168 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1169 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1170 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1171 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1172 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1173 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1174 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1175 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1176 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1177 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1178 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %1162, %6, %1157, %1158, %1177, %1159, %1163, %1164, %1165, %1166, %1167, %1168, %1169, %1170, %1171, %1172, %1173, %1174, %1175, %1176) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=128, len=4096, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1179 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1180 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1181 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1182 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1183 = emitc.call_opaque "__runtime_buffer_arg"(%1155) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1184 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1185 = emitc.call_opaque "__runtime_buffer_offset"(%1183, %1184) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1186 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1187 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1188 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1189 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1190 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1191 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1192 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1193 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1194 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1195 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1196 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1197 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1198 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1199 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1200 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1201 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %1185, %5, %1180, %1181, %1200, %1182, %1186, %1187, %1188, %1189, %1190, %1191, %1192, %1193, %1194, %1195, %1196, %1197, %1198, %1199) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=64, len=4096, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1202 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1203 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1204 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1205 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1206 = emitc.call_opaque "__runtime_buffer_arg"(%1155) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1207 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1208 = emitc.call_opaque "__runtime_buffer_offset"(%1206, %1207) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1209 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1210 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1211 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1212 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1213 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1214 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1215 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1216 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1217 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1218 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1219 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1220 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1221 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1222 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1223 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1224 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %1208, %4, %1203, %1204, %1223, %1205, %1209, %1210, %1211, %1212, %1213, %1214, %1215, %1216, %1217, %1218, %1219, %1220, %1221, %1222) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, offset=0, len=4096, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1225 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1226 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1227 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1228 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1229 = emitc.call_opaque "__runtime_buffer_arg"(%1155) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1230 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1231 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1232 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1233 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1234 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1235 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1236 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1237 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1238 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1239 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1240 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1241 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1242 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1243 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1244 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1245 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %513, %1229, %3, %1226, %1227, %1244, %1228, %1230, %1231, %1232, %1233, %1234, %1235, %1236, %1237, %1238, %1239, %1240, %1241, %1242, %1243) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1246 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1247 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1248 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %513, %1246, %1248) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1249 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %1245, %1246, %1247, %1248) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1250 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1251 = emitc.call_opaque "__runtime_buffer_offset"(%1155, %1250) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1252 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=5, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1253 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1254 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1255 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1256 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1257 = emitc.call_opaque "__runtime_buffer_arg"(%1252) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1258 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1259 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1260 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1261 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1262 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1263 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1264 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %70, %1257, %7, %1254, %1255, %1263, %1256, %1258, %1259, %1260, %1261, %1262) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 1));"
    %1265 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1266 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1267 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %1268 = emitc.call_opaque "__Runtime_dma_createio_4"(%70, %1264, %1265, %1266, %1267) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %1269 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1270 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1271 = emitc.call_opaque "__runtime_buffer_offset"(%1155, %1270) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1272 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=6, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1273 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1274 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1275 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1276 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1277 = emitc.call_opaque "__runtime_buffer_arg"(%1272) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1278 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1279 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1280 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1281 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1282 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1283 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1284 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %232, %1277, %7, %1274, %1275, %1283, %1276, %1278, %1279, %1280, %1281, %1282) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 1));"
    %1285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1286 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1287 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %1288 = emitc.call_opaque "__Runtime_dma_createio_4"(%232, %1284, %1285, %1286, %1287) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %1289 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1290 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1291 = emitc.call_opaque "__runtime_buffer_offset"(%1155, %1290) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1292 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=7, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1293 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1294 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1295 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1296 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1297 = emitc.call_opaque "__runtime_buffer_arg"(%1292) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1298 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1299 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1300 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1301 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1302 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1303 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1304 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %400, %1297, %7, %1294, %1295, %1303, %1296, %1298, %1299, %1300, %1301, %1302) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 1));"
    %1305 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1306 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1307 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %1308 = emitc.call_opaque "__Runtime_dma_createio_4"(%400, %1304, %1305, %1306, %1307) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %1309 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1310 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1311 = emitc.call_opaque "__runtime_buffer_offset"(%1155, %1310) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1312 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=8, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1313 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1314 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1315 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1316 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1317 = emitc.call_opaque "__runtime_buffer_arg"(%1312) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1318 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1319 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1320 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1321 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1322 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1323 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1324 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1317, %7, %1314, %1315, %1323, %1316, %1318, %1319, %1320, %1321, %1322) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 1));"
    %1325 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1326 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1327 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %1328 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %1324, %1325, %1326, %1327) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    %1329 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %1330 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1331 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1332 = emitc.call_opaque "__Runtime_startio"(%arg0, %1249, %1330, %1331) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1333 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1334 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1333) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1335 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1336 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %1337 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1338 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1339 = emitc.call_opaque "__runtime_buffer_arg"(%1334) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1340 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1341 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1342 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1343 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1344 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1345 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1346 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %345, %1339, %12, %1336, %1337, %1345, %1338, %1340, %1341, %1342, %1343, %1344) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1347 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1348 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1349 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %1350 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %1346, %1347, %1348, %1349) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1351 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1352 = emitc.call_opaque "__runtime_buffer_offset"(%1334, %1351) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1353 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1354 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1355 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1356 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1357 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1358 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1359 = emitc.call_opaque "__runtime_buffer_arg"(%1354) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1360 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1361 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1362 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1363 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1364 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1365 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1366 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1359, %9, %1356, %1357, %1365, %1358, %1360, %1361, %1362, %1363, %1364) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1368 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1369 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1370 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1371 = emitc.call_opaque "__runtime_buffer_arg"(%1353) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1373 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1374 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1375 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1376 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1377 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1378 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1371, %10, %1368, %1369, %1377, %1370, %1372, %1373, %1374, %1375, %1376) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1379 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1380 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1381 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %1382 = emitc.call_opaque "__Runtime_dma_createio_4"(%104, %1378, %1379, %1380, %1381) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %1383 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1384 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1385 = emitc.call_opaque "__runtime_buffer_offset"(%1334, %1384) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1386 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1387 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1388 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1389 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1390 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1391 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1392 = emitc.call_opaque "__runtime_buffer_arg"(%1387) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1393 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1394 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1395 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1396 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1397 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1398 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1399 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1392, %9, %1389, %1390, %1398, %1391, %1393, %1394, %1395, %1396, %1397) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1400 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1401 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1402 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1403 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1404 = emitc.call_opaque "__runtime_buffer_arg"(%1386) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1406 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1407 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1408 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1409 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1410 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1411 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1404, %10, %1401, %1402, %1410, %1403, %1405, %1406, %1407, %1408, %1409) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1412 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1413 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1414 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %1415 = emitc.call_opaque "__Runtime_dma_createio_4"(%268, %1411, %1412, %1413, %1414) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %1416 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1417 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1418 = emitc.call_opaque "__runtime_buffer_offset"(%1334, %1417) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1419 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1420 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1421 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1422 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1423 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1424 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1425 = emitc.call_opaque "__runtime_buffer_arg"(%1420) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1426 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1427 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1428 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1429 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1430 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1431 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1432 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1425, %9, %1422, %1423, %1431, %1424, %1426, %1427, %1428, %1429, %1430) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1433 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1434 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1435 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1436 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1437 = emitc.call_opaque "__runtime_buffer_arg"(%1419) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1438 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1439 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1440 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1441 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1442 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1443 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1444 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1437, %10, %1434, %1435, %1443, %1436, %1438, %1439, %1440, %1441, %1442) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1445 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1446 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1447 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %1448 = emitc.call_opaque "__Runtime_dma_createio_4"(%436, %1444, %1445, %1446, %1447) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %1449 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1450 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1451 = emitc.call_opaque "__runtime_buffer_offset"(%1334, %1450) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1452 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1453 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1454 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1455 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1456 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1457 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1458 = emitc.call_opaque "__runtime_buffer_arg"(%1453) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1459 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1460 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1461 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1462 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1463 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1464 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1465 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1458, %9, %1455, %1456, %1464, %1457, %1459, %1460, %1461, %1462, %1463) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1466 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1467 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1468 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1469 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1470 = emitc.call_opaque "__runtime_buffer_arg"(%1452) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1471 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1472 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1473 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1474 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1475 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1476 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1477 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1470, %10, %1467, %1468, %1476, %1469, %1471, %1472, %1473, %1474, %1475) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1478 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1479 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1480 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %1481 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1477, %1478, %1479, %1480) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    %1482 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %1483 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1484 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1485 = emitc.call_opaque "__Runtime_startio"(%arg0, %1350, %1483, %1484) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1486 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1487 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1486) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, offset=192, len=4096, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1488 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1489 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1490 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1491 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1492 = emitc.call_opaque "__runtime_buffer_arg"(%1487) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1493 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1494 = emitc.call_opaque "__runtime_buffer_offset"(%1492, %1493) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1495 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1496 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1497 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1498 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1499 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1500 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1501 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1502 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1503 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1504 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1505 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1506 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1507 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1508 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1509 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1510 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1494, %2, %1489, %1490, %1509, %1491, %1495, %1496, %1497, %1498, %1499, %1500, %1501, %1502, %1503, %1504, %1505, %1506, %1507, %1508) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=128, len=4096, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1511 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1512 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1513 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1514 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1515 = emitc.call_opaque "__runtime_buffer_arg"(%1487) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1516 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1517 = emitc.call_opaque "__runtime_buffer_offset"(%1515, %1516) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1518 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1519 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1520 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1521 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1522 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1523 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1524 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1525 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1526 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1527 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1528 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1529 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1530 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1531 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1532 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1533 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1517, %8, %1512, %1513, %1532, %1514, %1518, %1519, %1520, %1521, %1522, %1523, %1524, %1525, %1526, %1527, %1528, %1529, %1530, %1531) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=64, len=4096, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1534 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1535 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1536 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1537 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1538 = emitc.call_opaque "__runtime_buffer_arg"(%1487) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1539 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1540 = emitc.call_opaque "__runtime_buffer_offset"(%1538, %1539) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1541 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1542 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1543 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1544 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1545 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1546 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1547 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1548 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1549 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1550 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1551 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1552 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1553 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1554 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1555 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1556 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1540, %7, %1535, %1536, %1555, %1537, %1541, %1542, %1543, %1544, %1545, %1546, %1547, %1548, %1549, %1550, %1551, %1552, %1553, %1554) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1557 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1558 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1559 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1560 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1561 = emitc.call_opaque "__runtime_buffer_arg"(%1487) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1562 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1563 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1564 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1565 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1566 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1567 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1568 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1569 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1570 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1571 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1572 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1573 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1574 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1575 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1576 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1577 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1561, %9, %1558, %1559, %1576, %1560, %1562, %1563, %1564, %1565, %1566, %1567, %1568, %1569, %1570, %1571, %1572, %1573, %1574, %1575) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1578 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1579 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1580 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %345, %1578, %1580) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1581 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %1577, %1578, %1579, %1580) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1582 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1583 = emitc.call_opaque "__runtime_buffer_offset"(%1487, %1582) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1584 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=9, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1585 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1586 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1587 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1588 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1589 = emitc.call_opaque "__runtime_buffer_arg"(%1584) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1590 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1591 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1592 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1593 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1594 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1595 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1596 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %104, %1589, %7, %1586, %1587, %1595, %1588, %1590, %1591, %1592, %1593, %1594) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 1));"
    %1597 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1598 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1599 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %1600 = emitc.call_opaque "__Runtime_dma_createio_4"(%104, %1596, %1597, %1598, %1599) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %1601 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1602 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1603 = emitc.call_opaque "__runtime_buffer_offset"(%1487, %1602) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1604 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=10, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1605 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1606 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1607 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1608 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1609 = emitc.call_opaque "__runtime_buffer_arg"(%1604) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1610 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1611 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1612 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1613 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1614 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1615 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1616 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %268, %1609, %7, %1606, %1607, %1615, %1608, %1610, %1611, %1612, %1613, %1614) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 1));"
    %1617 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1618 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1619 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %1620 = emitc.call_opaque "__Runtime_dma_createio_4"(%268, %1616, %1617, %1618, %1619) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %1621 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1622 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1623 = emitc.call_opaque "__runtime_buffer_offset"(%1487, %1622) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1624 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=11, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1625 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1626 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1627 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1628 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1629 = emitc.call_opaque "__runtime_buffer_arg"(%1624) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1630 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1631 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1632 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1633 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1634 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1635 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1636 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %436, %1629, %7, %1626, %1627, %1635, %1628, %1630, %1631, %1632, %1633, %1634) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 1));"
    %1637 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1638 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1639 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %1640 = emitc.call_opaque "__Runtime_dma_createio_4"(%436, %1636, %1637, %1638, %1639) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %1641 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1642 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1643 = emitc.call_opaque "__runtime_buffer_offset"(%1487, %1642) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1644 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=12, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1645 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1646 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1647 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1648 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1649 = emitc.call_opaque "__runtime_buffer_arg"(%1644) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1650 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1651 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1652 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1653 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1654 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1655 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1656 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1649, %7, %1646, %1647, %1655, %1648, %1650, %1651, %1652, %1653, %1654) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 1));"
    %1657 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1658 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1659 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %1660 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1656, %1657, %1658, %1659) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    %1661 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %1662 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1663 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1664 = emitc.call_opaque "__Runtime_startio"(%arg0, %1581, %1662, %1663) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1665 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1666 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1665) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=0, len=16384, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1667 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1668 = "emitc.constant"() <{value = 16384 : i32}> : () -> i32
    %1669 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1670 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1671 = emitc.call_opaque "__runtime_buffer_arg"(%1666) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1672 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1673 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1674 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1675 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1676 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1677 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1678 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %1671, %1, %1668, %1669, %1677, %1670, %1672, %1673, %1674, %1675, %1676) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1679 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1680 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1681 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
    %1682 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %1678, %1679, %1680, %1681) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1683 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1684 = emitc.call_opaque "__runtime_buffer_offset"(%1666, %1683) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1685 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1686 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1687 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1688 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1689 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1690 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1691 = emitc.call_opaque "__runtime_buffer_arg"(%1686) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1692 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1693 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1694 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1695 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1696 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1697 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1698 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %1691, %9, %1688, %1689, %1697, %1690, %1692, %1693, %1694, %1695, %1696) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1699 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1700 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1701 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1702 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1703 = emitc.call_opaque "__runtime_buffer_arg"(%1685) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1704 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1705 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1706 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1707 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1708 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1709 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1710 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %1703, %10, %1700, %1701, %1709, %1702, %1704, %1705, %1706, %1707, %1708) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1711 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1712 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1713 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %1714 = emitc.call_opaque "__Runtime_dma_createio_4"(%138, %1710, %1711, %1712, %1713) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %1715 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1716 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1717 = emitc.call_opaque "__runtime_buffer_offset"(%1666, %1716) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1718 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1719 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1721 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1722 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1723 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1724 = emitc.call_opaque "__runtime_buffer_arg"(%1719) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1725 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1726 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1727 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1728 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1729 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1730 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1731 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %1724, %9, %1721, %1722, %1730, %1723, %1725, %1726, %1727, %1728, %1729) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1732 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1733 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1734 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1735 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1736 = emitc.call_opaque "__runtime_buffer_arg"(%1718) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1737 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1738 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1739 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1740 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1741 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1742 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1743 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %1736, %10, %1733, %1734, %1742, %1735, %1737, %1738, %1739, %1740, %1741) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1744 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1745 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1746 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %1747 = emitc.call_opaque "__Runtime_dma_createio_4"(%304, %1743, %1744, %1745, %1746) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %1748 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1749 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1750 = emitc.call_opaque "__runtime_buffer_offset"(%1666, %1749) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1751 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1752 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1753 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1754 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1755 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1756 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1757 = emitc.call_opaque "__runtime_buffer_arg"(%1752) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1758 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1759 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1760 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1761 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1762 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1763 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1764 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %1757, %9, %1754, %1755, %1763, %1756, %1758, %1759, %1760, %1761, %1762) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1765 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1766 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1767 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1768 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1769 = emitc.call_opaque "__runtime_buffer_arg"(%1751) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1770 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1771 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1772 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1773 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1774 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1775 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1776 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %1769, %10, %1766, %1767, %1775, %1768, %1770, %1771, %1772, %1773, %1774) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1777 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1778 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1779 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %1780 = emitc.call_opaque "__Runtime_dma_createio_4"(%472, %1776, %1777, %1778, %1779) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %1781 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1782 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1783 = emitc.call_opaque "__runtime_buffer_offset"(%1666, %1782) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1784 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1785 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1786 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1787 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1788 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1789 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1790 = emitc.call_opaque "__runtime_buffer_arg"(%1785) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1791 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1792 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1793 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1794 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1795 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1796 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1797 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1790, %9, %1787, %1788, %1796, %1789, %1791, %1792, %1793, %1794, %1795) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1798 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1799 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1800 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1801 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1802 = emitc.call_opaque "__runtime_buffer_arg"(%1784) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1803 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1804 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1805 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1806 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1807 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1808 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1809 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1802, %10, %1799, %1800, %1808, %1801, %1803, %1804, %1805, %1806, %1807) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1810 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1811 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1812 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %1813 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1809, %1810, %1811, %1812) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    %1814 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %1815 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1816 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1817 = emitc.call_opaque "__Runtime_startio"(%arg0, %1682, %1815, %1816) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1818 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1819 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1818) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=192, len=4096, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1820 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1821 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1822 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1823 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1824 = emitc.call_opaque "__runtime_buffer_arg"(%1819) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1825 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1826 = emitc.call_opaque "__runtime_buffer_offset"(%1824, %1825) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1827 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1828 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1829 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1830 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1831 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1832 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1833 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1834 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1835 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1836 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1837 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1838 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1839 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1840 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1841 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1842 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1826, %1, %1821, %1822, %1841, %1823, %1827, %1828, %1829, %1830, %1831, %1832, %1833, %1834, %1835, %1836, %1837, %1838, %1839, %1840) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=128, len=4096, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1843 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1844 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1845 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1846 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1847 = emitc.call_opaque "__runtime_buffer_arg"(%1819) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1848 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1849 = emitc.call_opaque "__runtime_buffer_offset"(%1847, %1848) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1850 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1851 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1852 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1853 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1854 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1855 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1856 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1857 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1858 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1859 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1860 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1861 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1862 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1863 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1864 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1865 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1849, %6, %1844, %1845, %1864, %1846, %1850, %1851, %1852, %1853, %1854, %1855, %1856, %1857, %1858, %1859, %1860, %1861, %1862, %1863) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=64, len=4096, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1866 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1867 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1868 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1869 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1870 = emitc.call_opaque "__runtime_buffer_arg"(%1819) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1871 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1872 = emitc.call_opaque "__runtime_buffer_offset"(%1870, %1871) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1873 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1874 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1875 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1876 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1877 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1878 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1879 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1880 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1881 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1882 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1883 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1884 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1885 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1886 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1887 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1888 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1872, %5, %1867, %1868, %1887, %1869, %1873, %1874, %1875, %1876, %1877, %1878, %1879, %1880, %1881, %1882, %1883, %1884, %1885, %1886) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=0, len=4096, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1889 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1890 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1891 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1892 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1893 = emitc.call_opaque "__runtime_buffer_arg"(%1819) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1894 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1895 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1896 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1897 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1898 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1899 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1900 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1901 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1902 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1903 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1904 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1905 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1906 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1907 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1908 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1909 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %345, %1893, %4, %1890, %1891, %1908, %1892, %1894, %1895, %1896, %1897, %1898, %1899, %1900, %1901, %1902, %1903, %1904, %1905, %1906, %1907) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1910 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1911 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1912 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %345, %1910, %1912) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1913 = emitc.call_opaque "__Runtime_dma_createio_4"(%345, %1909, %1910, %1911, %1912) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1914 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1915 = emitc.call_opaque "__runtime_buffer_offset"(%1819, %1914) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1916 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=13, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1917 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1918 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1919 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1920 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1921 = emitc.call_opaque "__runtime_buffer_arg"(%1916) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1922 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1923 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1924 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1925 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1926 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1927 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1928 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %138, %1921, %7, %1918, %1919, %1927, %1920, %1922, %1923, %1924, %1925, %1926) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 1));"
    %1929 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1930 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1931 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %1932 = emitc.call_opaque "__Runtime_dma_createio_4"(%138, %1928, %1929, %1930, %1931) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %1933 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1934 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1935 = emitc.call_opaque "__runtime_buffer_offset"(%1819, %1934) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1936 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=14, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1937 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1938 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1939 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1940 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1941 = emitc.call_opaque "__runtime_buffer_arg"(%1936) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1942 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1943 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1944 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1945 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1946 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1947 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1948 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %304, %1941, %7, %1938, %1939, %1947, %1940, %1942, %1943, %1944, %1945, %1946) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 1));"
    %1949 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1950 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1951 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %1952 = emitc.call_opaque "__Runtime_dma_createio_4"(%304, %1948, %1949, %1950, %1951) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %1953 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1954 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1955 = emitc.call_opaque "__runtime_buffer_offset"(%1819, %1954) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1956 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=15, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1957 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1958 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1959 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1960 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1961 = emitc.call_opaque "__runtime_buffer_arg"(%1956) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1962 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1963 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1964 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1965 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1966 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1967 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1968 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %472, %1961, %7, %1958, %1959, %1967, %1960, %1962, %1963, %1964, %1965, %1966) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 1));"
    %1969 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1970 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1971 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %1972 = emitc.call_opaque "__Runtime_dma_createio_4"(%472, %1968, %1969, %1970, %1971) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %1973 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1974 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1975 = emitc.call_opaque "__runtime_buffer_offset"(%1819, %1974) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1976 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=16, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %1977 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1978 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1979 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1980 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1981 = emitc.call_opaque "__runtime_buffer_arg"(%1976) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1982 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1983 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1984 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1985 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1986 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1987 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1988 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1981, %7, %1978, %1979, %1987, %1980, %1982, %1983, %1984, %1985, %1986) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 1));"
    %1989 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1990 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1991 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %1992 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1988, %1989, %1990, %1991) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    %1993 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %1994 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1995 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1996 = emitc.call_opaque "__Runtime_startio"(%arg0, %1913, %1994, %1995) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %1997 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1998 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %36, %70, %104, %138, %196, %232, %268, %304, %364, %400, %436, %472, %532, %568, %604, %640, %1997) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %1999 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %1998) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %2000 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2001 = emitc.call_opaque "__Runtime_startio"(%arg0, %66, %67, %2000) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2002 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2003 = emitc.call_opaque "__Runtime_startio"(%arg0, %100, %101, %2002) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2004 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2005 = emitc.call_opaque "__Runtime_startio"(%arg0, %134, %135, %2004) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2006 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2007 = emitc.call_opaque "__Runtime_startio"(%arg0, %168, %169, %2006) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2008 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2009 = emitc.call_opaque "__Runtime_startio"(%arg0, %228, %229, %2008) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2010 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2011 = emitc.call_opaque "__Runtime_startio"(%arg0, %264, %265, %2010) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2012 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2013 = emitc.call_opaque "__Runtime_startio"(%arg0, %300, %301, %2012) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2014 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2015 = emitc.call_opaque "__Runtime_startio"(%arg0, %336, %337, %2014) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2016 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2017 = emitc.call_opaque "__Runtime_startio"(%arg0, %396, %397, %2016) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2018 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2019 = emitc.call_opaque "__Runtime_startio"(%arg0, %432, %433, %2018) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2020 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2021 = emitc.call_opaque "__Runtime_startio"(%arg0, %468, %469, %2020) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2022 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2023 = emitc.call_opaque "__Runtime_startio"(%arg0, %504, %505, %2022) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2024 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2025 = emitc.call_opaque "__Runtime_startio"(%arg0, %564, %565, %2024) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2026 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2027 = emitc.call_opaque "__Runtime_startio"(%arg0, %600, %601, %2026) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2028 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2029 = emitc.call_opaque "__Runtime_startio"(%arg0, %636, %637, %2028) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2030 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2031 = emitc.call_opaque "__Runtime_startio"(%arg0, %672, %673, %2030) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2032 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2033 = emitc.call_opaque "__Runtime_startio"(%arg0, %724, %725, %2032) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2034 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2035 = emitc.call_opaque "__Runtime_startio"(%arg0, %755, %756, %2034) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2036 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2037 = emitc.call_opaque "__Runtime_startio"(%arg0, %786, %787, %2036) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2038 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2039 = emitc.call_opaque "__Runtime_startio"(%arg0, %817, %818, %2038) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2040 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2041 = emitc.call_opaque "__Runtime_startio"(%arg0, %936, %937, %2040) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2042 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2043 = emitc.call_opaque "__Runtime_startio"(%arg0, %956, %957, %2042) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2044 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2045 = emitc.call_opaque "__Runtime_startio"(%arg0, %976, %977, %2044) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2046 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2047 = emitc.call_opaque "__Runtime_startio"(%arg0, %996, %997, %2046) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2048 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2049 = emitc.call_opaque "__Runtime_startio"(%arg0, %1050, %1051, %2048) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2050 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2051 = emitc.call_opaque "__Runtime_startio"(%arg0, %1083, %1084, %2050) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2052 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2053 = emitc.call_opaque "__Runtime_startio"(%arg0, %1116, %1117, %2052) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2054 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2055 = emitc.call_opaque "__Runtime_startio"(%arg0, %1149, %1150, %2054) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2056 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2057 = emitc.call_opaque "__Runtime_startio"(%arg0, %1268, %1269, %2056) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2058 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2059 = emitc.call_opaque "__Runtime_startio"(%arg0, %1288, %1289, %2058) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2060 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2061 = emitc.call_opaque "__Runtime_startio"(%arg0, %1308, %1309, %2060) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2062 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2063 = emitc.call_opaque "__Runtime_startio"(%arg0, %1328, %1329, %2062) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2064 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2065 = emitc.call_opaque "__Runtime_startio"(%arg0, %1382, %1383, %2064) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2066 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2067 = emitc.call_opaque "__Runtime_startio"(%arg0, %1415, %1416, %2066) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2068 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2069 = emitc.call_opaque "__Runtime_startio"(%arg0, %1448, %1449, %2068) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2070 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2071 = emitc.call_opaque "__Runtime_startio"(%arg0, %1481, %1482, %2070) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2072 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2073 = emitc.call_opaque "__Runtime_startio"(%arg0, %1600, %1601, %2072) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2074 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2075 = emitc.call_opaque "__Runtime_startio"(%arg0, %1620, %1621, %2074) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2076 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2077 = emitc.call_opaque "__Runtime_startio"(%arg0, %1640, %1641, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2078 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2079 = emitc.call_opaque "__Runtime_startio"(%arg0, %1660, %1661, %2078) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2080 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2081 = emitc.call_opaque "__Runtime_startio"(%arg0, %1714, %1715, %2080) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2082 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2083 = emitc.call_opaque "__Runtime_startio"(%arg0, %1747, %1748, %2082) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2084 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %1780, %1781, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2086 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2087 = emitc.call_opaque "__Runtime_startio"(%arg0, %1813, %1814, %2086) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2088 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2089 = emitc.call_opaque "__Runtime_startio"(%arg0, %1932, %1933, %2088) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2090 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2091 = emitc.call_opaque "__Runtime_startio"(%arg0, %1952, %1953, %2090) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2092 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2093 = emitc.call_opaque "__Runtime_startio"(%arg0, %1972, %1973, %2092) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2094 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2095 = emitc.call_opaque "__Runtime_startio"(%arg0, %1992, %1993, %2094) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %1999) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %172) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %340) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %508) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %676) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %821) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1000) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1153) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1332) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1485) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1664) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1817) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1996) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
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
