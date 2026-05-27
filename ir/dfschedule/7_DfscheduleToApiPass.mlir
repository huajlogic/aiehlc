module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.effective_k = 64 : i64, routing.full_k = 256 : i64, routing.k_rounds = 4 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 1 : i32}} {
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %18 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %19 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %20 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %21 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %22 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %23 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %24 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %25 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %26 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %27 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %28 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %29 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %30 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %31 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %33 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %34 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %35 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %36 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %37 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %38 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %17, %22, %11, %19, %20, %37, %21, %23, %24, %25, %26, %27, %28, %29, %30, %31, %32, %33, %34, %35, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %39 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %40 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,0), direction=MM2S */"
    %42 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %38, %39, %40, %41) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %43 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %44 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %45 = emitc.call_opaque "XAie_TileLoc"(%43, %44) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %46 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %47 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %48 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %49 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %50 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %51 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %52 = emitc.call_opaque "__runtime_buffer_arg"(%47) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %53 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %54 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %55 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %56 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %57 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %58 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %59 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %52, %12, %49, %50, %58, %51, %53, %54, %55, %56, %57) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %60 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %61 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %62 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %63 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %64 = emitc.call_opaque "__runtime_buffer_arg"(%46) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %65 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %66 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %67 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %68 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %69 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %70 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %71 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %64, %11, %61, %62, %70, %63, %65, %66, %67, %68, %69) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %72 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %73 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %74 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %75 = emitc.call_opaque "__Runtime_dma_createio_4"(%45, %71, %72, %73, %74) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %76 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %77 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %78 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %79 = emitc.call_opaque "XAie_TileLoc"(%77, %78) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %80 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %81 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %82 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %83 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %84 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %85 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %86 = emitc.call_opaque "__runtime_buffer_arg"(%81) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %87 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %88 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %89 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %90 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %91 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %92 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %93 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %86, %12, %83, %84, %92, %85, %87, %88, %89, %90, %91) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %94 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %95 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %96 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %97 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %98 = emitc.call_opaque "__runtime_buffer_arg"(%80) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %99 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %100 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %101 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %102 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %103 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %104 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %105 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %98, %11, %95, %96, %104, %97, %99, %100, %101, %102, %103) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %106 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %108 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %109 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %105, %106, %107, %108) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %110 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %111 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %112 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %113 = emitc.call_opaque "XAie_TileLoc"(%111, %112) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %114 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %115 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %116 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %117 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %118 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %119 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %120 = emitc.call_opaque "__runtime_buffer_arg"(%115) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %121 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %122 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %123 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %124 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %125 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %126 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %127 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %120, %12, %117, %118, %126, %119, %121, %122, %123, %124, %125) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %128 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %129 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %130 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %131 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %132 = emitc.call_opaque "__runtime_buffer_arg"(%114) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %133 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %134 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %135 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %136 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %137 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %138 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %139 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %132, %11, %129, %130, %138, %131, %133, %134, %135, %136, %137) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %140 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %141 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %142 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %143 = emitc.call_opaque "__Runtime_dma_createio_4"(%113, %139, %140, %141, %142) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %144 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %145 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %146 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %147 = emitc.call_opaque "XAie_TileLoc"(%145, %146) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %148 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %149 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %150 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %151 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %152 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %153 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %154 = emitc.call_opaque "__runtime_buffer_arg"(%149) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %155 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %156 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %157 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %158 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %159 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %160 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %161 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %154, %12, %151, %152, %160, %153, %155, %156, %157, %158, %159) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %162 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %163 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %164 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %165 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %166 = emitc.call_opaque "__runtime_buffer_arg"(%148) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %167 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %168 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %169 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %170 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %171 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %172 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %173 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %166, %11, %163, %164, %172, %165, %167, %168, %169, %170, %171) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %174 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %175 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %176 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %177 = emitc.call_opaque "__Runtime_dma_createio_4"(%147, %173, %174, %175, %176) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    %178 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,0) */"
    %179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %180 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %181 = emitc.call_opaque "__Runtime_startio"(%arg0, %42, %179, %180) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %182 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %183 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %182) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %184 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %185 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %186 = emitc.call_opaque "XAie_TileLoc"(%184, %185) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %187 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %188 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %189 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %190 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %191 = emitc.call_opaque "__runtime_buffer_arg"(%183) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %192 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %193 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %194 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %195 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %196 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %197 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %198 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %199 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %200 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %201 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %202 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %203 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %204 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %205 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %206 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %207 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %186, %191, %11, %188, %189, %206, %190, %192, %193, %194, %195, %196, %197, %198, %199, %200, %201, %202, %203, %204, %205) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %208 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %209 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %210 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,0), direction=MM2S */"
    %211 = emitc.call_opaque "__Runtime_dma_createio_4"(%186, %207, %208, %209, %210) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %212 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %213 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %214 = emitc.call_opaque "XAie_TileLoc"(%212, %213) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %215 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %216 = emitc.call_opaque "__runtime_buffer_offset"(%183, %215) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %217 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %218 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %219 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %220 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %221 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %222 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %223 = emitc.call_opaque "__runtime_buffer_arg"(%218) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %224 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %225 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %226 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %227 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %228 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %229 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %230 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %223, %12, %220, %221, %229, %222, %224, %225, %226, %227, %228) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %231 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %232 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %233 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %234 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %235 = emitc.call_opaque "__runtime_buffer_arg"(%217) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %236 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %237 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %238 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %239 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %240 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %241 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %242 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %235, %11, %232, %233, %241, %234, %236, %237, %238, %239, %240) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %243 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %244 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %245 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %246 = emitc.call_opaque "__Runtime_dma_createio_4"(%214, %242, %243, %244, %245) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %247 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %248 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %249 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %250 = emitc.call_opaque "XAie_TileLoc"(%248, %249) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %251 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %252 = emitc.call_opaque "__runtime_buffer_offset"(%183, %251) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %253 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %255 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %256 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %257 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %258 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %259 = emitc.call_opaque "__runtime_buffer_arg"(%254) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %260 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %261 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %262 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %263 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %264 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %265 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %266 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %259, %12, %256, %257, %265, %258, %260, %261, %262, %263, %264) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %267 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %268 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %269 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %270 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %271 = emitc.call_opaque "__runtime_buffer_arg"(%253) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %273 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %274 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %275 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %276 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %277 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %278 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %271, %11, %268, %269, %277, %270, %272, %273, %274, %275, %276) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %279 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %280 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %281 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %282 = emitc.call_opaque "__Runtime_dma_createio_4"(%250, %278, %279, %280, %281) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %284 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %285 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %286 = emitc.call_opaque "XAie_TileLoc"(%284, %285) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %287 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %288 = emitc.call_opaque "__runtime_buffer_offset"(%183, %287) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %289 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %291 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %292 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %293 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %294 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %295 = emitc.call_opaque "__runtime_buffer_arg"(%290) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %296 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %297 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %298 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %299 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %300 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %301 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %302 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %295, %12, %292, %293, %301, %294, %296, %297, %298, %299, %300) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %303 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %304 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %305 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %306 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %307 = emitc.call_opaque "__runtime_buffer_arg"(%289) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %308 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %309 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %310 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %311 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %312 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %313 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %314 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %307, %11, %304, %305, %313, %306, %308, %309, %310, %311, %312) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %315 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %316 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %317 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %318 = emitc.call_opaque "__Runtime_dma_createio_4"(%286, %314, %315, %316, %317) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %319 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %320 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %321 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %322 = emitc.call_opaque "XAie_TileLoc"(%320, %321) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %323 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %324 = emitc.call_opaque "__runtime_buffer_offset"(%183, %323) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %325 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %326 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %327 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %328 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %329 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %330 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %331 = emitc.call_opaque "__runtime_buffer_arg"(%326) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %332 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %333 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %334 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %335 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %336 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %337 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %338 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %331, %12, %328, %329, %337, %330, %332, %333, %334, %335, %336) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %339 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %340 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %341 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %342 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %343 = emitc.call_opaque "__runtime_buffer_arg"(%325) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %344 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %345 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %346 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %347 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %348 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %349 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %350 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %343, %11, %340, %341, %349, %342, %344, %345, %346, %347, %348) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %351 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %352 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %353 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %354 = emitc.call_opaque "__Runtime_dma_createio_4"(%322, %350, %351, %352, %353) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    %355 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,0) */"
    %356 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %357 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %358 = emitc.call_opaque "__Runtime_startio"(%arg0, %211, %356, %357) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %359 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %360 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %359) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %361 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %362 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %363 = emitc.call_opaque "XAie_TileLoc"(%361, %362) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %364 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %365 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %366 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %368 = emitc.call_opaque "__runtime_buffer_arg"(%360) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %369 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %370 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %371 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %373 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %374 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %375 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %376 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %377 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %378 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %379 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %380 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %381 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %382 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %383 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %384 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %363, %368, %11, %365, %366, %383, %367, %369, %370, %371, %372, %373, %374, %375, %376, %377, %378, %379, %380, %381, %382) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %385 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %386 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %387 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %388 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %384, %385, %386, %387) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %389 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %390 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %391 = emitc.call_opaque "XAie_TileLoc"(%389, %390) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %392 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %393 = emitc.call_opaque "__runtime_buffer_offset"(%360, %392) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %394 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %395 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %396 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %397 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %398 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %399 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %400 = emitc.call_opaque "__runtime_buffer_arg"(%395) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %401 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %402 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %403 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %404 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %405 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %406 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %407 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %400, %12, %397, %398, %406, %399, %401, %402, %403, %404, %405) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %408 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %409 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %410 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %411 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %412 = emitc.call_opaque "__runtime_buffer_arg"(%394) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %413 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %414 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %415 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %416 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %417 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %418 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %419 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %412, %11, %409, %410, %418, %411, %413, %414, %415, %416, %417) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %420 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %421 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %422 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %423 = emitc.call_opaque "__Runtime_dma_createio_4"(%391, %419, %420, %421, %422) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %424 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %425 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %426 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %427 = emitc.call_opaque "XAie_TileLoc"(%425, %426) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %428 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %429 = emitc.call_opaque "__runtime_buffer_offset"(%360, %428) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %430 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %431 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %432 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %433 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %434 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %435 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %436 = emitc.call_opaque "__runtime_buffer_arg"(%431) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %437 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %438 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %439 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %440 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %441 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %442 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %443 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %436, %12, %433, %434, %442, %435, %437, %438, %439, %440, %441) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %444 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %445 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %446 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %447 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %448 = emitc.call_opaque "__runtime_buffer_arg"(%430) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %449 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %450 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %451 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %452 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %453 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %454 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %455 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %448, %11, %445, %446, %454, %447, %449, %450, %451, %452, %453) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %456 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %457 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %458 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %459 = emitc.call_opaque "__Runtime_dma_createio_4"(%427, %455, %456, %457, %458) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %460 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %461 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %462 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %463 = emitc.call_opaque "XAie_TileLoc"(%461, %462) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %464 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %465 = emitc.call_opaque "__runtime_buffer_offset"(%360, %464) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %466 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %467 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %468 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %469 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %470 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %471 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %472 = emitc.call_opaque "__runtime_buffer_arg"(%467) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %473 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %474 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %475 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %476 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %477 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %478 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %479 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %472, %12, %469, %470, %478, %471, %473, %474, %475, %476, %477) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %480 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %481 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %482 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %483 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %484 = emitc.call_opaque "__runtime_buffer_arg"(%466) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %485 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %486 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %487 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %488 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %489 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %490 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %491 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %484, %11, %481, %482, %490, %483, %485, %486, %487, %488, %489) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %492 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %493 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %494 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %495 = emitc.call_opaque "__Runtime_dma_createio_4"(%463, %491, %492, %493, %494) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %496 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %497 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %498 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %499 = emitc.call_opaque "XAie_TileLoc"(%497, %498) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %500 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %501 = emitc.call_opaque "__runtime_buffer_offset"(%360, %500) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %502 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %503 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %504 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %505 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %506 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %507 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %508 = emitc.call_opaque "__runtime_buffer_arg"(%503) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %509 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %510 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %511 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %512 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %513 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %514 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %515 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %508, %12, %505, %506, %514, %507, %509, %510, %511, %512, %513) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %516 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %517 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %518 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %519 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %520 = emitc.call_opaque "__runtime_buffer_arg"(%502) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %521 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %522 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %523 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %524 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %525 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %526 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %527 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %520, %11, %517, %518, %526, %519, %521, %522, %523, %524, %525) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %528 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %529 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %530 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %531 = emitc.call_opaque "__Runtime_dma_createio_4"(%499, %527, %528, %529, %530) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    %532 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %533 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %534 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %535 = emitc.call_opaque "__Runtime_startio"(%arg0, %388, %533, %534) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %536 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %537 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %536) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %538 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %539 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %540 = emitc.call_opaque "XAie_TileLoc"(%538, %539) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %541 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %542 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %543 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %544 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %545 = emitc.call_opaque "__runtime_buffer_arg"(%537) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %546 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %547 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %548 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %549 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %550 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %551 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %552 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %553 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %554 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %555 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %556 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %557 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %558 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %559 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %560 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %561 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %540, %545, %11, %542, %543, %560, %544, %546, %547, %548, %549, %550, %551, %552, %553, %554, %555, %556, %557, %558, %559) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %562 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %563 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %564 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %565 = emitc.call_opaque "__Runtime_dma_createio_4"(%540, %561, %562, %563, %564) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %566 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %567 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %568 = emitc.call_opaque "XAie_TileLoc"(%566, %567) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %569 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %570 = emitc.call_opaque "__runtime_buffer_offset"(%537, %569) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
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
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
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
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %600 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %596, %597, %598, %599) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %601 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %602 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %603 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %604 = emitc.call_opaque "XAie_TileLoc"(%602, %603) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %605 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %606 = emitc.call_opaque "__runtime_buffer_offset"(%537, %605) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
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
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
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
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %636 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %632, %633, %634, %635) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %637 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %638 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %639 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %640 = emitc.call_opaque "XAie_TileLoc"(%638, %639) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %641 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %642 = emitc.call_opaque "__runtime_buffer_offset"(%537, %641) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
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
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
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
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %672 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %668, %669, %670, %671) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %673 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %674 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %675 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %676 = emitc.call_opaque "XAie_TileLoc"(%674, %675) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %677 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %678 = emitc.call_opaque "__runtime_buffer_offset"(%537, %677) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %679 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %680 = "emitc.constant"() <{value = #emitc.opaque<"(void*)36864">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %681 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %682 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %683 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %684 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %685 = emitc.call_opaque "__runtime_buffer_arg"(%680) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %686 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %687 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %688 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %689 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %690 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %691 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %692 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %685, %12, %682, %683, %691, %684, %686, %687, %688, %689, %690) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %693 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %694 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %695 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %696 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %697 = emitc.call_opaque "__runtime_buffer_arg"(%679) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %698 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %699 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %700 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %701 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %702 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %703 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %704 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %697, %11, %694, %695, %703, %696, %698, %699, %700, %701, %702) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %705 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %706 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %707 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %708 = emitc.call_opaque "__Runtime_dma_createio_4"(%676, %704, %705, %706, %707) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    %709 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %710 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %711 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %712 = emitc.call_opaque "__Runtime_startio"(%arg0, %565, %710, %711) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %713 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %714 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %713) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %715 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %716 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %717 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %718 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %719 = emitc.call_opaque "__runtime_buffer_arg"(%714) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %721 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %722 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %723 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %724 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %725 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %726 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %727 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %728 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %729 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %730 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %731 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %732 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %733 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %734 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %735 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %17, %719, %12, %716, %717, %734, %718, %720, %721, %722, %723, %724, %725, %726, %727, %728, %729, %730, %731, %732, %733) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %736 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %737 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %738 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
    %739 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %735, %736, %737, %738) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %740 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %741 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %742 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %743 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %744 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %745 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %746 = emitc.call_opaque "__runtime_buffer_arg"(%741) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %747 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %748 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %749 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %750 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %751 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %752 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %753 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %746, %9, %743, %744, %752, %745, %747, %748, %749, %750, %751) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %754 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %755 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %756 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %757 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %758 = emitc.call_opaque "__runtime_buffer_arg"(%740) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %759 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %760 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %761 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %762 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %763 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %764 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %765 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %758, %10, %755, %756, %764, %757, %759, %760, %761, %762, %763) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %766 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %767 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %768 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %769 = emitc.call_opaque "__Runtime_dma_createio_4"(%45, %765, %766, %767, %768) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    %770 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %771 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %772 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %773 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %774 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %775 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %776 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %777 = emitc.call_opaque "__runtime_buffer_arg"(%772) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %778 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %779 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %780 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %781 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %782 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %783 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %784 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %777, %9, %774, %775, %783, %776, %778, %779, %780, %781, %782) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %785 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %786 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %787 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %788 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %789 = emitc.call_opaque "__runtime_buffer_arg"(%771) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %790 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %791 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %792 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %793 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %794 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %795 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %796 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %789, %10, %786, %787, %795, %788, %790, %791, %792, %793, %794) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %797 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %798 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %799 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %800 = emitc.call_opaque "__Runtime_dma_createio_4"(%214, %796, %797, %798, %799) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    %801 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %802 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %803 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %804 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %805 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %806 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %807 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %808 = emitc.call_opaque "__runtime_buffer_arg"(%803) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %809 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %810 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %811 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %812 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %813 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %814 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %815 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %808, %9, %805, %806, %814, %807, %809, %810, %811, %812, %813) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %816 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %817 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %818 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %819 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %820 = emitc.call_opaque "__runtime_buffer_arg"(%802) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %821 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %822 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %823 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %824 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %825 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %826 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %827 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %820, %10, %817, %818, %826, %819, %821, %822, %823, %824, %825) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %828 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %829 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %830 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %831 = emitc.call_opaque "__Runtime_dma_createio_4"(%391, %827, %828, %829, %830) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    %832 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %833 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %834 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %835 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %836 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %837 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %838 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %839 = emitc.call_opaque "__runtime_buffer_arg"(%834) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %840 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %841 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %842 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %843 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %844 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %845 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %846 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %839, %9, %836, %837, %845, %838, %840, %841, %842, %843, %844) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %847 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %848 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %849 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %850 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %851 = emitc.call_opaque "__runtime_buffer_arg"(%833) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %852 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %853 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %854 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %855 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %856 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %857 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %858 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %851, %10, %848, %849, %857, %850, %852, %853, %854, %855, %856) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %859 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %860 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %861 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %862 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %858, %859, %860, %861) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    %863 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,0) */"
    %864 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %865 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %866 = emitc.call_opaque "__Runtime_startio"(%arg0, %739, %864, %865) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %867 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %868 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %867) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=192, len=4096, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %869 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %870 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %871 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %872 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %873 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %874 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %875 = emitc.call_opaque "__runtime_buffer_offset"(%873, %874) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %876 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %877 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %878 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %879 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %880 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %881 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %882 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %883 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %884 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %885 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %886 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %887 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %888 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %889 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %890 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %891 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %875, %8, %870, %871, %890, %872, %876, %877, %878, %879, %880, %881, %882, %883, %884, %885, %886, %887, %888, %889) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=128, len=4096, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %892 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %893 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %894 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %895 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %896 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %897 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %898 = emitc.call_opaque "__runtime_buffer_offset"(%896, %897) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %899 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %900 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %901 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %902 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %903 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %904 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %905 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %906 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %907 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %908 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %909 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %910 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %911 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %912 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %913 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %914 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %898, %7, %893, %894, %913, %895, %899, %900, %901, %902, %903, %904, %905, %906, %907, %908, %909, %910, %911, %912) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=64, len=4096, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %915 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %916 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %917 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %918 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %919 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %920 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %921 = emitc.call_opaque "__runtime_buffer_offset"(%919, %920) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %922 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %923 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %924 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %925 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %926 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %927 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %928 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %929 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %930 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %931 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %932 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %933 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %934 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %935 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %936 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %937 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %921, %9, %916, %917, %936, %918, %922, %923, %924, %925, %926, %927, %928, %929, %930, %931, %932, %933, %934, %935) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %938 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %939 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %940 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %941 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %942 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %943 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %944 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %945 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %946 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %947 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %948 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %949 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %950 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %951 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %952 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %953 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %954 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %955 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %956 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %957 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %958 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %942, %10, %939, %940, %957, %941, %943, %944, %945, %946, %947, %948, %949, %950, %951, %952, %953, %954, %955, %956) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %959 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %960 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %961 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %540, %959, %961) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %962 = emitc.call_opaque "__Runtime_dma_createio_4"(%540, %958, %959, %960, %961) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %963 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %964 = emitc.call_opaque "__runtime_buffer_offset"(%868, %963) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %965 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=1, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %966 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %967 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %968 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %969 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %970 = emitc.call_opaque "__runtime_buffer_arg"(%965) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %971 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %972 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %973 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %974 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %975 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %976 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %977 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %970, %7, %967, %968, %976, %969, %971, %972, %973, %974, %975) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 1));"
    %978 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %979 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %980 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %981 = emitc.call_opaque "__Runtime_dma_createio_4"(%45, %977, %978, %979, %980) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %982 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %983 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %984 = emitc.call_opaque "__runtime_buffer_offset"(%868, %983) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %985 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=2, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %986 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %987 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %988 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %989 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %990 = emitc.call_opaque "__runtime_buffer_arg"(%985) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %991 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %992 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %993 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %994 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %995 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %996 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %997 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %990, %7, %987, %988, %996, %989, %991, %992, %993, %994, %995) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 1));"
    %998 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %999 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1000 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %1001 = emitc.call_opaque "__Runtime_dma_createio_4"(%214, %997, %998, %999, %1000) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %1002 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1003 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1004 = emitc.call_opaque "__runtime_buffer_offset"(%868, %1003) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1005 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=3, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1006 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1007 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1008 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1009 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1010 = emitc.call_opaque "__runtime_buffer_arg"(%1005) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1011 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1012 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1013 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1014 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1015 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1016 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1017 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %1010, %7, %1007, %1008, %1016, %1009, %1011, %1012, %1013, %1014, %1015) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 1));"
    %1018 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1019 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1020 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %1021 = emitc.call_opaque "__Runtime_dma_createio_4"(%391, %1017, %1018, %1019, %1020) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %1022 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1023 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1024 = emitc.call_opaque "__runtime_buffer_offset"(%868, %1023) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1025 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=4, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1026 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1027 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1028 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1029 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1030 = emitc.call_opaque "__runtime_buffer_arg"(%1025) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1031 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1032 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1033 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1034 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1035 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1036 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1037 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1030, %7, %1027, %1028, %1036, %1029, %1031, %1032, %1033, %1034, %1035) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 1));"
    %1038 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1039 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1040 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %1041 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %1037, %1038, %1039, %1040) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    %1042 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %1043 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1044 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1045 = emitc.call_opaque "__Runtime_startio"(%arg0, %962, %1043, %1044) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1046 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1047 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1046) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1048 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1049 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1050 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1051 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1052 = emitc.call_opaque "__runtime_buffer_arg"(%1047) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1053 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1054 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1055 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1056 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1057 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1058 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1059 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1060 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1061 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1062 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1065 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1066 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1067 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1068 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %186, %1052, %12, %1049, %1050, %1067, %1051, %1053, %1054, %1055, %1056, %1057, %1058, %1059, %1060, %1061, %1062, %1063, %1064, %1065, %1066) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1069 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1070 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1071 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
    %1072 = emitc.call_opaque "__Runtime_dma_createio_4"(%186, %1068, %1069, %1070, %1071) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1073 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1074 = emitc.call_opaque "__runtime_buffer_offset"(%1047, %1073) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1075 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1076 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1078 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1079 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1081 = emitc.call_opaque "__runtime_buffer_arg"(%1076) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1082 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1083 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1084 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1085 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1086 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1087 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1088 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1081, %9, %1078, %1079, %1087, %1080, %1082, %1083, %1084, %1085, %1086) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1089 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1090 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1091 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1092 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1093 = emitc.call_opaque "__runtime_buffer_arg"(%1075) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1094 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1095 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1096 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1097 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1098 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1099 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1100 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1093, %10, %1090, %1091, %1099, %1092, %1094, %1095, %1096, %1097, %1098) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1101 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1102 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1103 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %1104 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %1100, %1101, %1102, %1103) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %1105 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1106 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1107 = emitc.call_opaque "__runtime_buffer_offset"(%1047, %1106) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1108 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1109 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1110 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1111 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1112 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1113 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1114 = emitc.call_opaque "__runtime_buffer_arg"(%1109) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1115 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1116 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1117 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1118 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1119 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1120 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1121 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1114, %9, %1111, %1112, %1120, %1113, %1115, %1116, %1117, %1118, %1119) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1122 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1123 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1124 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1125 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1126 = emitc.call_opaque "__runtime_buffer_arg"(%1108) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1127 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1128 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1129 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1130 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1131 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1132 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1133 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1126, %10, %1123, %1124, %1132, %1125, %1127, %1128, %1129, %1130, %1131) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1134 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1135 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1136 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %1137 = emitc.call_opaque "__Runtime_dma_createio_4"(%250, %1133, %1134, %1135, %1136) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %1138 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1139 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1140 = emitc.call_opaque "__runtime_buffer_offset"(%1047, %1139) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1141 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1142 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1143 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1144 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1145 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1147 = emitc.call_opaque "__runtime_buffer_arg"(%1142) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1148 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1149 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1150 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1151 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1152 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1153 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1154 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1147, %9, %1144, %1145, %1153, %1146, %1148, %1149, %1150, %1151, %1152) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1155 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1156 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1157 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1158 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1159 = emitc.call_opaque "__runtime_buffer_arg"(%1141) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1160 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1161 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1162 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1163 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1164 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1165 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1166 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1159, %10, %1156, %1157, %1165, %1158, %1160, %1161, %1162, %1163, %1164) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1167 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1168 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1169 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %1170 = emitc.call_opaque "__Runtime_dma_createio_4"(%427, %1166, %1167, %1168, %1169) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %1171 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1172 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1173 = emitc.call_opaque "__runtime_buffer_offset"(%1047, %1172) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1174 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1175 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1176 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1177 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1178 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1180 = emitc.call_opaque "__runtime_buffer_arg"(%1175) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1181 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1182 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1183 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1184 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1185 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1186 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1187 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1180, %9, %1177, %1178, %1186, %1179, %1181, %1182, %1183, %1184, %1185) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1188 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1189 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1190 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1191 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1192 = emitc.call_opaque "__runtime_buffer_arg"(%1174) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1193 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1194 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1195 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1196 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1197 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1198 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1199 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1192, %10, %1189, %1190, %1198, %1191, %1193, %1194, %1195, %1196, %1197) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1200 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1201 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1202 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %1203 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1199, %1200, %1201, %1202) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    %1204 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
    %1205 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1206 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1207 = emitc.call_opaque "__Runtime_startio"(%arg0, %1072, %1205, %1206) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1208 = "emitc.constant"() <{value = 16384 : i64}> : () -> i64
    %1209 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1208) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=192, len=4096, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1210 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1211 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1212 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1213 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1214 = emitc.call_opaque "__runtime_buffer_arg"(%1209) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1215 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1216 = emitc.call_opaque "__runtime_buffer_offset"(%1214, %1215) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1217 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1218 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1220 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1221 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1222 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1223 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1224 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1225 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1226 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1227 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1228 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1229 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1230 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1231 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1232 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1216, %6, %1211, %1212, %1231, %1213, %1217, %1218, %1219, %1220, %1221, %1222, %1223, %1224, %1225, %1226, %1227, %1228, %1229, %1230) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=128, len=4096, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1233 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1234 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1235 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1236 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1237 = emitc.call_opaque "__runtime_buffer_arg"(%1209) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1238 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1239 = emitc.call_opaque "__runtime_buffer_offset"(%1237, %1238) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1240 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1241 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1242 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1243 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1244 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1245 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1246 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1247 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1248 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1249 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1250 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1251 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1252 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1253 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1254 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1255 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1239, %5, %1234, %1235, %1254, %1236, %1240, %1241, %1242, %1243, %1244, %1245, %1246, %1247, %1248, %1249, %1250, %1251, %1252, %1253) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=64, len=4096, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1256 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1257 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1258 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1259 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1260 = emitc.call_opaque "__runtime_buffer_arg"(%1209) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1261 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1262 = emitc.call_opaque "__runtime_buffer_offset"(%1260, %1261) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1263 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1264 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1265 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1266 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1267 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1268 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1269 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1270 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1271 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1272 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1273 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1274 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1275 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1276 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1277 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1278 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1262, %4, %1257, %1258, %1277, %1259, %1263, %1264, %1265, %1266, %1267, %1268, %1269, %1270, %1271, %1272, %1273, %1274, %1275, %1276) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, offset=0, len=4096, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1279 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1280 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1281 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1282 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1283 = emitc.call_opaque "__runtime_buffer_arg"(%1209) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1284 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1286 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1287 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1288 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1289 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1290 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1291 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1292 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1293 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1294 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1295 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1296 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1297 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1298 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1299 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1283, %3, %1280, %1281, %1298, %1282, %1284, %1285, %1286, %1287, %1288, %1289, %1290, %1291, %1292, %1293, %1294, %1295, %1296, %1297) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1300 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1301 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1302 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %540, %1300, %1302) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1303 = emitc.call_opaque "__Runtime_dma_createio_4"(%540, %1299, %1300, %1301, %1302) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1304 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1305 = emitc.call_opaque "__runtime_buffer_offset"(%1209, %1304) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1306 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=5, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1307 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1308 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1309 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1310 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1311 = emitc.call_opaque "__runtime_buffer_arg"(%1306) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1312 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1313 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1314 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1315 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1316 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1317 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1318 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1311, %7, %1308, %1309, %1317, %1310, %1312, %1313, %1314, %1315, %1316) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 1));"
    %1319 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1320 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1321 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %1322 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %1318, %1319, %1320, %1321) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %1323 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1324 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1325 = emitc.call_opaque "__runtime_buffer_offset"(%1209, %1324) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1326 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=6, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1327 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1328 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1329 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1330 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1331 = emitc.call_opaque "__runtime_buffer_arg"(%1326) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1332 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1333 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1334 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1335 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1336 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1337 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1338 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1331, %7, %1328, %1329, %1337, %1330, %1332, %1333, %1334, %1335, %1336) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 1));"
    %1339 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1340 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1341 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %1342 = emitc.call_opaque "__Runtime_dma_createio_4"(%250, %1338, %1339, %1340, %1341) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %1343 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1344 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1345 = emitc.call_opaque "__runtime_buffer_offset"(%1209, %1344) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1346 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=7, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1347 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1348 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1349 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1350 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1351 = emitc.call_opaque "__runtime_buffer_arg"(%1346) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1352 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1353 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1354 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1355 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1356 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1357 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1358 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1351, %7, %1348, %1349, %1357, %1350, %1352, %1353, %1354, %1355, %1356) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 1));"
    %1359 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1360 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1361 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %1362 = emitc.call_opaque "__Runtime_dma_createio_4"(%427, %1358, %1359, %1360, %1361) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %1363 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1364 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1365 = emitc.call_opaque "__runtime_buffer_offset"(%1209, %1364) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1366 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=8, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1368 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1369 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1370 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1371 = emitc.call_opaque "__runtime_buffer_arg"(%1366) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1372 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1373 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1374 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1375 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1376 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1377 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1378 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1371, %7, %1368, %1369, %1377, %1370, %1372, %1373, %1374, %1375, %1376) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 1));"
    %1379 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1380 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1381 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %1382 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1378, %1379, %1380, %1381) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    %1383 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %1384 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1385 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1386 = emitc.call_opaque "__Runtime_startio"(%arg0, %1303, %1384, %1385) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1387 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1388 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1387) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1389 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1390 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1391 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1392 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1393 = emitc.call_opaque "__runtime_buffer_arg"(%1388) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1394 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1395 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1396 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1397 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1398 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1399 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1400 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1401 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1402 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1403 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1404 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1406 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1407 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1408 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1409 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %363, %1393, %12, %1390, %1391, %1408, %1392, %1394, %1395, %1396, %1397, %1398, %1399, %1400, %1401, %1402, %1403, %1404, %1405, %1406, %1407) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1410 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1411 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1412 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %1413 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %1409, %1410, %1411, %1412) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1414 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1415 = emitc.call_opaque "__runtime_buffer_offset"(%1388, %1414) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1416 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1417 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1418 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1419 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1420 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1421 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1422 = emitc.call_opaque "__runtime_buffer_arg"(%1417) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1423 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1424 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1425 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1426 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1427 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1428 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1429 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1422, %9, %1419, %1420, %1428, %1421, %1423, %1424, %1425, %1426, %1427) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1430 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1431 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1432 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1433 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1434 = emitc.call_opaque "__runtime_buffer_arg"(%1416) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1435 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1436 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1437 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1438 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1439 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1440 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1441 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1434, %10, %1431, %1432, %1440, %1433, %1435, %1436, %1437, %1438, %1439) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1442 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1443 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1444 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %1445 = emitc.call_opaque "__Runtime_dma_createio_4"(%113, %1441, %1442, %1443, %1444) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %1446 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1447 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1448 = emitc.call_opaque "__runtime_buffer_offset"(%1388, %1447) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1449 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1450 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1451 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1452 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1453 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1454 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1455 = emitc.call_opaque "__runtime_buffer_arg"(%1450) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1456 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1457 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1458 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1459 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1460 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1461 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1462 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1455, %9, %1452, %1453, %1461, %1454, %1456, %1457, %1458, %1459, %1460) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1463 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1464 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1465 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1466 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1467 = emitc.call_opaque "__runtime_buffer_arg"(%1449) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1468 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1469 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1470 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1471 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1472 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1473 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1474 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1467, %10, %1464, %1465, %1473, %1466, %1468, %1469, %1470, %1471, %1472) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1475 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1476 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1477 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %1478 = emitc.call_opaque "__Runtime_dma_createio_4"(%286, %1474, %1475, %1476, %1477) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %1479 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1480 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1481 = emitc.call_opaque "__runtime_buffer_offset"(%1388, %1480) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1482 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1483 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1484 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1485 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1486 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1487 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1488 = emitc.call_opaque "__runtime_buffer_arg"(%1483) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1489 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1490 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1491 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1492 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1493 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1494 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1495 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1488, %9, %1485, %1486, %1494, %1487, %1489, %1490, %1491, %1492, %1493) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1496 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1497 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1498 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1499 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1500 = emitc.call_opaque "__runtime_buffer_arg"(%1482) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1501 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1502 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1503 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1504 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1505 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1506 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1507 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1500, %10, %1497, %1498, %1506, %1499, %1501, %1502, %1503, %1504, %1505) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1508 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1509 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1510 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %1511 = emitc.call_opaque "__Runtime_dma_createio_4"(%463, %1507, %1508, %1509, %1510) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %1512 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1513 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1514 = emitc.call_opaque "__runtime_buffer_offset"(%1388, %1513) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1515 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1516 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1517 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1518 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1519 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1520 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1521 = emitc.call_opaque "__runtime_buffer_arg"(%1516) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1522 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1523 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1524 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1525 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1526 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1527 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1528 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1521, %9, %1518, %1519, %1527, %1520, %1522, %1523, %1524, %1525, %1526) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1529 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1530 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1531 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1532 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1533 = emitc.call_opaque "__runtime_buffer_arg"(%1515) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1534 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1535 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1536 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1537 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1538 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1539 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1540 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1533, %10, %1530, %1531, %1539, %1532, %1534, %1535, %1536, %1537, %1538) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1541 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1542 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1543 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %1544 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1540, %1541, %1542, %1543) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    %1545 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %1546 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1547 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1548 = emitc.call_opaque "__Runtime_startio"(%arg0, %1413, %1546, %1547) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1549 = "emitc.constant"() <{value = 32768 : i64}> : () -> i64
    %1550 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1549) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, offset=192, len=4096, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1551 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1552 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1553 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1554 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1555 = emitc.call_opaque "__runtime_buffer_arg"(%1550) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1556 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1557 = emitc.call_opaque "__runtime_buffer_offset"(%1555, %1556) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1558 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1559 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1560 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1561 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1562 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1563 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1564 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1565 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1566 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1567 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1568 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1569 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1570 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1571 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1572 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1573 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1557, %2, %1552, %1553, %1572, %1554, %1558, %1559, %1560, %1561, %1562, %1563, %1564, %1565, %1566, %1567, %1568, %1569, %1570, %1571) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=128, len=4096, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1574 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1575 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1576 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1577 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1578 = emitc.call_opaque "__runtime_buffer_arg"(%1550) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1579 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1580 = emitc.call_opaque "__runtime_buffer_offset"(%1578, %1579) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1581 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1582 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1583 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1584 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1585 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1586 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1587 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1588 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1589 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1590 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1591 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1592 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1593 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1594 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1595 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1596 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1580, %8, %1575, %1576, %1595, %1577, %1581, %1582, %1583, %1584, %1585, %1586, %1587, %1588, %1589, %1590, %1591, %1592, %1593, %1594) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=64, len=4096, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1597 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1598 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1599 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1600 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1601 = emitc.call_opaque "__runtime_buffer_arg"(%1550) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1602 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1603 = emitc.call_opaque "__runtime_buffer_offset"(%1601, %1602) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1604 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1605 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1606 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1607 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1608 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1609 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1610 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1611 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1612 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1613 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1614 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1615 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1616 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1617 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1618 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1619 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1603, %7, %1598, %1599, %1618, %1600, %1604, %1605, %1606, %1607, %1608, %1609, %1610, %1611, %1612, %1613, %1614, %1615, %1616, %1617) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1620 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1621 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1622 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1623 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1624 = emitc.call_opaque "__runtime_buffer_arg"(%1550) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1625 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1626 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1627 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1628 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1629 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1630 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1631 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1632 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1633 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1634 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1635 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1636 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1637 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1638 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1639 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1640 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1624, %9, %1621, %1622, %1639, %1623, %1625, %1626, %1627, %1628, %1629, %1630, %1631, %1632, %1633, %1634, %1635, %1636, %1637, %1638) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1641 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1642 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1643 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %363, %1641, %1643) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1644 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %1640, %1641, %1642, %1643) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1645 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1646 = emitc.call_opaque "__runtime_buffer_offset"(%1550, %1645) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1647 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=9, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1648 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1649 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1650 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1651 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1652 = emitc.call_opaque "__runtime_buffer_arg"(%1647) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1653 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1654 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1655 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1656 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1657 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1658 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1659 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1652, %7, %1649, %1650, %1658, %1651, %1653, %1654, %1655, %1656, %1657) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 1));"
    %1660 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1661 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1662 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %1663 = emitc.call_opaque "__Runtime_dma_createio_4"(%113, %1659, %1660, %1661, %1662) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %1664 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1665 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %1666 = emitc.call_opaque "__runtime_buffer_offset"(%1550, %1665) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1667 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=10, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1668 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1669 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1670 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1671 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1672 = emitc.call_opaque "__runtime_buffer_arg"(%1667) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1673 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1674 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1675 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1676 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1677 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1678 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1679 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1672, %7, %1669, %1670, %1678, %1671, %1673, %1674, %1675, %1676, %1677) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 1));"
    %1680 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1681 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1682 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %1683 = emitc.call_opaque "__Runtime_dma_createio_4"(%286, %1679, %1680, %1681, %1682) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %1684 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1685 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %1686 = emitc.call_opaque "__runtime_buffer_offset"(%1550, %1685) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1687 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=11, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1688 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1689 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1690 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1691 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1692 = emitc.call_opaque "__runtime_buffer_arg"(%1687) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1693 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1694 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1695 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1696 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1697 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1698 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1699 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1692, %7, %1689, %1690, %1698, %1691, %1693, %1694, %1695, %1696, %1697) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 1));"
    %1700 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1701 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1702 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %1703 = emitc.call_opaque "__Runtime_dma_createio_4"(%463, %1699, %1700, %1701, %1702) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %1704 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1705 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %1706 = emitc.call_opaque "__runtime_buffer_offset"(%1550, %1705) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1707 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=12, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1708 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1709 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1710 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1711 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1712 = emitc.call_opaque "__runtime_buffer_arg"(%1707) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1713 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1714 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1715 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1716 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1717 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1718 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1719 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1712, %7, %1709, %1710, %1718, %1711, %1713, %1714, %1715, %1716, %1717) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 1));"
    %1720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1721 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1722 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %1723 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1719, %1720, %1721, %1722) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    %1724 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %1725 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1726 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1727 = emitc.call_opaque "__Runtime_startio"(%arg0, %1644, %1725, %1726) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1728 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1729 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1728) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1730 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1731 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1732 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1733 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1734 = emitc.call_opaque "__runtime_buffer_arg"(%1729) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1735 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1736 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1737 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1738 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1739 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1740 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1741 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1742 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1743 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1744 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1745 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1746 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1747 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1748 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1749 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1750 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %540, %1734, %1, %1731, %1732, %1749, %1733, %1735, %1736, %1737, %1738, %1739, %1740, %1741, %1742, %1743, %1744, %1745, %1746, %1747, %1748) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1751 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1752 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1753 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
    %1754 = emitc.call_opaque "__Runtime_dma_createio_4"(%540, %1750, %1751, %1752, %1753) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1755 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1756 = emitc.call_opaque "__runtime_buffer_offset"(%1729, %1755) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1757 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1758 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1759 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1760 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1761 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1762 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1763 = emitc.call_opaque "__runtime_buffer_arg"(%1758) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1764 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1765 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1766 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1767 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1768 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1769 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1770 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %1763, %9, %1760, %1761, %1769, %1762, %1764, %1765, %1766, %1767, %1768) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1771 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1772 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1773 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1774 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1775 = emitc.call_opaque "__runtime_buffer_arg"(%1757) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1776 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1777 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1778 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1779 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1780 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1781 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1782 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %1775, %10, %1772, %1773, %1781, %1774, %1776, %1777, %1778, %1779, %1780) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1783 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1784 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1785 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %1786 = emitc.call_opaque "__Runtime_dma_createio_4"(%147, %1782, %1783, %1784, %1785) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %1787 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1788 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1789 = emitc.call_opaque "__runtime_buffer_offset"(%1729, %1788) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1790 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1791 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1792 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1793 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1794 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1795 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1796 = emitc.call_opaque "__runtime_buffer_arg"(%1791) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1797 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1798 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1799 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1800 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1801 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1802 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1803 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %1796, %9, %1793, %1794, %1802, %1795, %1797, %1798, %1799, %1800, %1801) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1804 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1805 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1806 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1807 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1808 = emitc.call_opaque "__runtime_buffer_arg"(%1790) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1809 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1810 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1811 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1812 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1813 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1814 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1815 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %1808, %10, %1805, %1806, %1814, %1807, %1809, %1810, %1811, %1812, %1813) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1816 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1817 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1818 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %1819 = emitc.call_opaque "__Runtime_dma_createio_4"(%322, %1815, %1816, %1817, %1818) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %1820 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1821 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1822 = emitc.call_opaque "__runtime_buffer_offset"(%1729, %1821) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1823 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1824 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1825 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1826 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1827 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1828 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1829 = emitc.call_opaque "__runtime_buffer_arg"(%1824) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1830 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1831 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1832 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1833 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1834 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1835 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1836 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %1829, %9, %1826, %1827, %1835, %1828, %1830, %1831, %1832, %1833, %1834) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1837 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1838 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1839 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1840 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1841 = emitc.call_opaque "__runtime_buffer_arg"(%1823) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1842 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1843 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1844 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1845 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1846 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1847 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1848 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %1841, %10, %1838, %1839, %1847, %1840, %1842, %1843, %1844, %1845, %1846) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1849 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1850 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1851 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %1852 = emitc.call_opaque "__Runtime_dma_createio_4"(%499, %1848, %1849, %1850, %1851) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %1853 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1854 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1855 = emitc.call_opaque "__runtime_buffer_offset"(%1729, %1854) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1856 = "emitc.constant"() <{value = #emitc.opaque<"(void*)40960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1857 = "emitc.constant"() <{value = #emitc.opaque<"(void*)45056">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1858 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1859 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1860 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1861 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1862 = emitc.call_opaque "__runtime_buffer_arg"(%1857) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1863 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1864 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1865 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1866 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1867 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1868 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1869 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %1862, %9, %1859, %1860, %1868, %1861, %1863, %1864, %1865, %1866, %1867) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=4096, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1870 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1871 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1872 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1873 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1874 = emitc.call_opaque "__runtime_buffer_arg"(%1856) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1875 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1876 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1877 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1878 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1879 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1880 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1881 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %1874, %10, %1871, %1872, %1880, %1873, %1875, %1876, %1877, %1878, %1879) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1882 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1883 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1884 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %1885 = emitc.call_opaque "__Runtime_dma_createio_4"(%676, %1881, %1882, %1883, %1884) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    %1886 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %1887 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1888 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1889 = emitc.call_opaque "__Runtime_startio"(%arg0, %1754, %1887, %1888) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1890 = "emitc.constant"() <{value = 49152 : i64}> : () -> i64
    %1891 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1890) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=192, len=4096, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1892 = "emitc.constant"() <{value = 192 : i32}> : () -> i32
    %1893 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1894 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1895 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1896 = emitc.call_opaque "__runtime_buffer_arg"(%1891) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1897 = "emitc.constant"() <{value = 192 : i64}> : () -> i64
    %1898 = emitc.call_opaque "__runtime_buffer_offset"(%1896, %1897) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1899 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1900 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1901 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1902 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1903 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1904 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1905 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1906 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1907 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1908 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1909 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1910 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1911 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1912 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1913 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1914 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1898, %1, %1893, %1894, %1913, %1895, %1899, %1900, %1901, %1902, %1903, %1904, %1905, %1906, %1907, %1908, %1909, %1910, %1911, %1912) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=128, len=4096, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1915 = "emitc.constant"() <{value = 128 : i32}> : () -> i32
    %1916 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1917 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1918 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1919 = emitc.call_opaque "__runtime_buffer_arg"(%1891) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1920 = "emitc.constant"() <{value = 128 : i64}> : () -> i64
    %1921 = emitc.call_opaque "__runtime_buffer_offset"(%1919, %1920) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1922 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1923 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1924 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1925 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1926 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1927 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1928 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1929 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1930 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1931 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1932 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1933 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1934 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1935 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1936 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1937 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1921, %6, %1916, %1917, %1936, %1918, %1922, %1923, %1924, %1925, %1926, %1927, %1928, %1929, %1930, %1931, %1932, %1933, %1934, %1935) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=64, len=4096, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1938 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1939 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1940 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1941 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1942 = emitc.call_opaque "__runtime_buffer_arg"(%1891) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1943 = "emitc.constant"() <{value = 64 : i64}> : () -> i64
    %1944 = emitc.call_opaque "__runtime_buffer_offset"(%1942, %1943) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1945 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1946 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1947 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1948 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1949 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1950 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1951 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1952 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1953 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1954 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1955 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1956 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1957 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1958 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1959 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1960 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1944, %5, %1939, %1940, %1959, %1941, %1945, %1946, %1947, %1948, %1949, %1950, %1951, %1952, %1953, %1954, %1955, %1956, %1957, %1958) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=0, len=4096, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1961 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1962 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1963 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1964 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1965 = emitc.call_opaque "__runtime_buffer_arg"(%1891) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1966 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1967 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1968 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1969 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1970 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1971 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1972 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1973 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1974 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1975 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1976 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1977 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1978 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1979 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1980 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1981 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1965, %4, %1962, %1963, %1980, %1964, %1966, %1967, %1968, %1969, %1970, %1971, %1972, %1973, %1974, %1975, %1976, %1977, %1978, %1979) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1982 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1983 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1984 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %363, %1982, %1984) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1985 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %1981, %1982, %1983, %1984) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1986 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1987 = emitc.call_opaque "__runtime_buffer_offset"(%1891, %1986) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1988 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=13, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1989 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1990 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %1991 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1992 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1993 = emitc.call_opaque "__runtime_buffer_arg"(%1988) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1994 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1995 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1996 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1997 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1998 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1999 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2000 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %1993, %7, %1990, %1991, %1999, %1992, %1994, %1995, %1996, %1997, %1998) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 1));"
    %2001 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2002 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2003 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %2004 = emitc.call_opaque "__Runtime_dma_createio_4"(%147, %2000, %2001, %2002, %2003) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %2005 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2006 = "emitc.constant"() <{value = 4096 : i64}> : () -> i64
    %2007 = emitc.call_opaque "__runtime_buffer_offset"(%1891, %2006) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2008 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=14, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %2009 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2010 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %2011 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2012 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2013 = emitc.call_opaque "__runtime_buffer_arg"(%2008) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2014 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2015 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2016 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2017 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2018 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %2019 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2020 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %2013, %7, %2010, %2011, %2019, %2012, %2014, %2015, %2016, %2017, %2018) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 1));"
    %2021 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2022 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2023 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %2024 = emitc.call_opaque "__Runtime_dma_createio_4"(%322, %2020, %2021, %2022, %2023) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %2025 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2026 = "emitc.constant"() <{value = 8192 : i64}> : () -> i64
    %2027 = emitc.call_opaque "__runtime_buffer_offset"(%1891, %2026) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2028 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=15, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %2029 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2030 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %2031 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2032 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2033 = emitc.call_opaque "__runtime_buffer_arg"(%2028) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2034 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2035 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2036 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2037 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2038 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %2039 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2040 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %2033, %7, %2030, %2031, %2039, %2032, %2034, %2035, %2036, %2037, %2038) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 1));"
    %2041 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2042 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2043 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %2044 = emitc.call_opaque "__Runtime_dma_createio_4"(%499, %2040, %2041, %2042, %2043) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %2045 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2046 = "emitc.constant"() <{value = 12288 : i64}> : () -> i64
    %2047 = emitc.call_opaque "__runtime_buffer_offset"(%1891, %2046) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2048 = "emitc.constant"() <{value = #emitc.opaque<"(void*)49152">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=4096, enable_packet=true, packet_id=16, next_bd=-1, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %2049 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2050 = "emitc.constant"() <{value = 4096 : i32}> : () -> i32
    %2051 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2052 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2053 = emitc.call_opaque "__runtime_buffer_arg"(%2048) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2054 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2055 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2056 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2057 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2058 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %2059 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2060 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %2053, %7, %2050, %2051, %2059, %2052, %2054, %2055, %2056, %2057, %2058) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=1 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 1));"
    %2061 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2062 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2063 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %2064 = emitc.call_opaque "__Runtime_dma_createio_4"(%676, %2060, %2061, %2062, %2063) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    %2065 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %2066 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2067 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2068 = emitc.call_opaque "__Runtime_startio"(%arg0, %1985, %2066, %2067) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %2069 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2070 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %45, %79, %113, %147, %214, %250, %286, %322, %391, %427, %463, %499, %568, %604, %640, %676, %2069) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %2071 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %2070) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %2072 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2073 = emitc.call_opaque "__Runtime_startio"(%arg0, %75, %76, %2072) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2074 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2075 = emitc.call_opaque "__Runtime_startio"(%arg0, %109, %110, %2074) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2076 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2077 = emitc.call_opaque "__Runtime_startio"(%arg0, %143, %144, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2078 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2079 = emitc.call_opaque "__Runtime_startio"(%arg0, %177, %178, %2078) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2080 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2081 = emitc.call_opaque "__Runtime_startio"(%arg0, %246, %247, %2080) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2082 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2083 = emitc.call_opaque "__Runtime_startio"(%arg0, %282, %283, %2082) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2084 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %318, %319, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2086 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2087 = emitc.call_opaque "__Runtime_startio"(%arg0, %354, %355, %2086) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2088 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2089 = emitc.call_opaque "__Runtime_startio"(%arg0, %423, %424, %2088) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2090 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2091 = emitc.call_opaque "__Runtime_startio"(%arg0, %459, %460, %2090) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2092 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2093 = emitc.call_opaque "__Runtime_startio"(%arg0, %495, %496, %2092) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2094 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2095 = emitc.call_opaque "__Runtime_startio"(%arg0, %531, %532, %2094) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2096 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2097 = emitc.call_opaque "__Runtime_startio"(%arg0, %600, %601, %2096) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2098 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2099 = emitc.call_opaque "__Runtime_startio"(%arg0, %636, %637, %2098) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2100 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2101 = emitc.call_opaque "__Runtime_startio"(%arg0, %672, %673, %2100) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2102 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2103 = emitc.call_opaque "__Runtime_startio"(%arg0, %708, %709, %2102) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2104 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2105 = emitc.call_opaque "__Runtime_startio"(%arg0, %769, %770, %2104) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2106 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2107 = emitc.call_opaque "__Runtime_startio"(%arg0, %800, %801, %2106) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2108 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2109 = emitc.call_opaque "__Runtime_startio"(%arg0, %831, %832, %2108) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2110 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2111 = emitc.call_opaque "__Runtime_startio"(%arg0, %862, %863, %2110) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2112 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2113 = emitc.call_opaque "__Runtime_startio"(%arg0, %981, %982, %2112) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2114 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2115 = emitc.call_opaque "__Runtime_startio"(%arg0, %1001, %1002, %2114) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2116 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2117 = emitc.call_opaque "__Runtime_startio"(%arg0, %1021, %1022, %2116) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2118 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2119 = emitc.call_opaque "__Runtime_startio"(%arg0, %1041, %1042, %2118) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2120 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2121 = emitc.call_opaque "__Runtime_startio"(%arg0, %1104, %1105, %2120) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2122 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2123 = emitc.call_opaque "__Runtime_startio"(%arg0, %1137, %1138, %2122) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2124 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2125 = emitc.call_opaque "__Runtime_startio"(%arg0, %1170, %1171, %2124) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2126 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2127 = emitc.call_opaque "__Runtime_startio"(%arg0, %1203, %1204, %2126) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2128 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2129 = emitc.call_opaque "__Runtime_startio"(%arg0, %1322, %1323, %2128) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2130 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2131 = emitc.call_opaque "__Runtime_startio"(%arg0, %1342, %1343, %2130) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2132 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2133 = emitc.call_opaque "__Runtime_startio"(%arg0, %1362, %1363, %2132) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2134 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2135 = emitc.call_opaque "__Runtime_startio"(%arg0, %1382, %1383, %2134) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2136 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2137 = emitc.call_opaque "__Runtime_startio"(%arg0, %1445, %1446, %2136) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2138 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2139 = emitc.call_opaque "__Runtime_startio"(%arg0, %1478, %1479, %2138) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2140 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2141 = emitc.call_opaque "__Runtime_startio"(%arg0, %1511, %1512, %2140) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2142 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2143 = emitc.call_opaque "__Runtime_startio"(%arg0, %1544, %1545, %2142) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2144 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2145 = emitc.call_opaque "__Runtime_startio"(%arg0, %1663, %1664, %2144) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2146 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2147 = emitc.call_opaque "__Runtime_startio"(%arg0, %1683, %1684, %2146) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2148 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2149 = emitc.call_opaque "__Runtime_startio"(%arg0, %1703, %1704, %2148) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2150 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2151 = emitc.call_opaque "__Runtime_startio"(%arg0, %1723, %1724, %2150) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2152 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2153 = emitc.call_opaque "__Runtime_startio"(%arg0, %1786, %1787, %2152) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2154 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2155 = emitc.call_opaque "__Runtime_startio"(%arg0, %1819, %1820, %2154) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2156 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2157 = emitc.call_opaque "__Runtime_startio"(%arg0, %1852, %1853, %2156) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2158 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2159 = emitc.call_opaque "__Runtime_startio"(%arg0, %1885, %1886, %2158) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2160 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2161 = emitc.call_opaque "__Runtime_startio"(%arg0, %2004, %2005, %2160) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2162 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2163 = emitc.call_opaque "__Runtime_startio"(%arg0, %2024, %2025, %2162) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2164 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2165 = emitc.call_opaque "__Runtime_startio"(%arg0, %2044, %2045, %2164) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2166 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2167 = emitc.call_opaque "__Runtime_startio"(%arg0, %2064, %2065, %2166) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %2071) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %181) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %358) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %535) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %712) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %866) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1045) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1207) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1386) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1548) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1727) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1889) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %2068) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
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
