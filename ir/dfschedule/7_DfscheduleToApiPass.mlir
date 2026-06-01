module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.effective_k = 16 : i64, routing.full_k = 64 : i64, routing.k_rounds = 4 : i64, routing.m_rounds = 4 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}, routing.tile_m = 4 : i64, routing.tile_rows = 16 : i64} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<64x64xi8>, %arg1: memref<64x64xi8>, %arg2: memref<64x64xi8>) {
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %18 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %19 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %20 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %21 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %22 = emitc.call_opaque "__runtime_buffer_arg"(%14) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %23 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %24 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %25 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %26 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %27 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %28 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %29 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %30 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %31 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %33 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %34 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %35 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
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
    %47 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %48 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %49 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %60 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %61 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %81 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %82 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %83 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %94 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %95 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %115 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %116 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %117 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %128 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %129 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %149 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %150 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %151 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %162 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %163 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %182 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %183 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %182) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %184 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %185 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %186 = emitc.call_opaque "XAie_TileLoc"(%184, %185) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %187 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %188 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %189 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %190 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %191 = emitc.call_opaque "__runtime_buffer_arg"(%183) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %192 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %193 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %194 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %195 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %196 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %197 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %198 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %199 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %200 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %201 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %202 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %203 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %204 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
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
    %215 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %216 = emitc.call_opaque "__runtime_buffer_offset"(%183, %215) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %217 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %218 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %219 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %220 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %231 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %232 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %251 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %252 = emitc.call_opaque "__runtime_buffer_offset"(%183, %251) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %253 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %254 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %255 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %256 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %267 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %268 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %287 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %288 = emitc.call_opaque "__runtime_buffer_offset"(%183, %287) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %289 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %291 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %292 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %303 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %304 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %323 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %324 = emitc.call_opaque "__runtime_buffer_offset"(%183, %323) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %325 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %326 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %327 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %328 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %339 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %340 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %359 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %360 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %359) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %361 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %362 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %363 = emitc.call_opaque "XAie_TileLoc"(%361, %362) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %364 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %365 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %366 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %368 = emitc.call_opaque "__runtime_buffer_arg"(%360) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %369 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %370 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %371 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %373 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %374 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %375 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %376 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %377 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %378 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %379 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %380 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %381 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
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
    %392 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %393 = emitc.call_opaque "__runtime_buffer_offset"(%360, %392) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %394 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %395 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %396 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %397 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %408 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %409 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %428 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %429 = emitc.call_opaque "__runtime_buffer_offset"(%360, %428) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %430 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %431 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %432 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %433 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %444 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %445 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %464 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %465 = emitc.call_opaque "__runtime_buffer_offset"(%360, %464) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %466 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %467 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %468 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %469 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %480 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %481 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %500 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %501 = emitc.call_opaque "__runtime_buffer_offset"(%360, %500) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %502 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %503 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %504 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %505 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %516 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %517 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %536 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %537 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %536) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %538 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %539 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %540 = emitc.call_opaque "XAie_TileLoc"(%538, %539) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %541 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %542 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %543 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %544 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %545 = emitc.call_opaque "__runtime_buffer_arg"(%537) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %546 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %547 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %548 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %549 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %550 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %551 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %552 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %553 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %554 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %555 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %556 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %557 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %558 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
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
    %569 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %570 = emitc.call_opaque "__runtime_buffer_offset"(%537, %569) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %571 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %572 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %573 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %574 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %585 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %586 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %605 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %606 = emitc.call_opaque "__runtime_buffer_offset"(%537, %605) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %607 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %608 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %609 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %610 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %621 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %622 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %641 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %642 = emitc.call_opaque "__runtime_buffer_offset"(%537, %641) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %643 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %644 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %645 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %646 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %657 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %658 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %677 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %678 = emitc.call_opaque "__runtime_buffer_offset"(%537, %677) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %679 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %680 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %681 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %682 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %693 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %694 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %715 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %716 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %717 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %718 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %719 = emitc.call_opaque "__runtime_buffer_arg"(%714) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %721 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %722 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %723 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %724 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %725 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %726 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %727 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %728 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %729 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %730 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %731 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %732 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %733 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %734 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %735 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %17, %719, %12, %716, %717, %734, %718, %720, %721, %722, %723, %724, %725, %726, %727, %728, %729, %730, %731, %732, %733) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %736 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %737 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %738 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
    %739 = emitc.call_opaque "__Runtime_dma_createio_4"(%17, %735, %736, %737, %738) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %740 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %741 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %742 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %743 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %754 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %755 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %771 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %772 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %773 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %774 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %785 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %786 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %802 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %803 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %804 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %805 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %816 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %817 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    %833 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %834 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %835 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %836 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %847 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %848 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
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
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=48, len=256, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %869 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %870 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %871 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %872 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %873 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %874 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %875 = emitc.call_opaque "__runtime_buffer_offset"(%873, %874) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %876 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %877 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %878 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %879 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %880 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %881 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %882 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %883 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %884 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %885 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %886 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %887 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %888 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %889 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %890 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %891 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %875, %8, %870, %871, %890, %872, %876, %877, %878, %879, %880, %881, %882, %883, %884, %885, %886, %887, %888, %889) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=32, len=256, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %892 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %893 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %894 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %895 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %896 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %897 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %898 = emitc.call_opaque "__runtime_buffer_offset"(%896, %897) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %899 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %900 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %901 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %902 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %903 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %904 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %905 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %906 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %907 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %908 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %909 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %910 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %911 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %912 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %913 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %914 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %898, %7, %893, %894, %913, %895, %899, %900, %901, %902, %903, %904, %905, %906, %907, %908, %909, %910, %911, %912) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=16, len=256, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %915 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %916 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %917 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %918 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %919 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %920 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %921 = emitc.call_opaque "__runtime_buffer_offset"(%919, %920) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %922 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %923 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %924 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %925 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %926 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %927 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %928 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %929 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %930 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %931 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %932 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %933 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %934 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %935 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %936 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %937 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %921, %9, %916, %917, %936, %918, %922, %923, %924, %925, %926, %927, %928, %929, %930, %931, %932, %933, %934, %935) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=256, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %938 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %939 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %940 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %941 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %942 = emitc.call_opaque "__runtime_buffer_arg"(%868) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %943 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %944 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %945 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %946 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %947 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %948 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %949 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %950 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %951 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %952 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %953 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %954 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
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
    %965 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %966 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %967 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %968 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %969 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %970 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %971 = emitc.call_opaque "__runtime_buffer_arg"(%966) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %972 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %973 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %974 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %975 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %976 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %977 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %978 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %971, %8, %968, %969, %977, %970, %972, %973, %974, %975, %976) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %979 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %980 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %981 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %982 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %983 = emitc.call_opaque "__runtime_buffer_arg"(%965) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %984 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %985 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %986 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %987 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %988 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %989 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %990 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %45, %983, %7, %980, %981, %989, %982, %984, %985, %986, %987, %988) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %991 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %992 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %993 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %994 = emitc.call_opaque "__Runtime_dma_createio_4"(%45, %990, %991, %992, %993) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %995 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %996 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %997 = emitc.call_opaque "__runtime_buffer_offset"(%868, %996) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %998 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %999 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1000 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1001 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1002 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1003 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1004 = emitc.call_opaque "__runtime_buffer_arg"(%999) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1005 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1006 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1007 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1008 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1009 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1010 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1011 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %1004, %8, %1001, %1002, %1010, %1003, %1005, %1006, %1007, %1008, %1009) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1012 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1013 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1014 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1015 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1016 = emitc.call_opaque "__runtime_buffer_arg"(%998) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1017 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1018 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1019 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1020 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1021 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1022 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1023 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %214, %1016, %7, %1013, %1014, %1022, %1015, %1017, %1018, %1019, %1020, %1021) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1024 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1025 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1026 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %1027 = emitc.call_opaque "__Runtime_dma_createio_4"(%214, %1023, %1024, %1025, %1026) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %1028 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1029 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %1030 = emitc.call_opaque "__runtime_buffer_offset"(%868, %1029) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1031 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1032 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1033 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1034 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1035 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1036 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1037 = emitc.call_opaque "__runtime_buffer_arg"(%1032) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1038 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1039 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1040 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1041 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1042 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1043 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1044 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %1037, %8, %1034, %1035, %1043, %1036, %1038, %1039, %1040, %1041, %1042) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1045 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1046 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1047 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1048 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1049 = emitc.call_opaque "__runtime_buffer_arg"(%1031) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1050 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1051 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1052 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1053 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1054 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1055 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1056 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %391, %1049, %7, %1046, %1047, %1055, %1048, %1050, %1051, %1052, %1053, %1054) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1057 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1058 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1059 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %1060 = emitc.call_opaque "__Runtime_dma_createio_4"(%391, %1056, %1057, %1058, %1059) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %1061 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1062 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %1063 = emitc.call_opaque "__runtime_buffer_offset"(%868, %1062) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1064 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1065 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1067 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1068 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1070 = emitc.call_opaque "__runtime_buffer_arg"(%1065) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1071 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1072 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1073 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1074 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1075 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1076 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1077 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1070, %8, %1067, %1068, %1076, %1069, %1071, %1072, %1073, %1074, %1075) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1078 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1079 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1080 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1081 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1082 = emitc.call_opaque "__runtime_buffer_arg"(%1064) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1083 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1084 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1085 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1086 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1087 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1088 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1089 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %568, %1082, %7, %1079, %1080, %1088, %1081, %1083, %1084, %1085, %1086, %1087) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1090 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1091 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1092 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %1093 = emitc.call_opaque "__Runtime_dma_createio_4"(%568, %1089, %1090, %1091, %1092) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    %1094 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %1095 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1096 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1097 = emitc.call_opaque "__Runtime_startio"(%arg0, %962, %1095, %1096) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1098 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1099 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1098) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1100 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1101 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1102 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1103 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1104 = emitc.call_opaque "__runtime_buffer_arg"(%1099) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1105 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1106 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1108 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1109 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1110 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1111 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1112 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1113 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1114 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1115 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1116 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1117 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1118 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1119 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1120 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %186, %1104, %12, %1101, %1102, %1119, %1103, %1105, %1106, %1107, %1108, %1109, %1110, %1111, %1112, %1113, %1114, %1115, %1116, %1117, %1118) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1121 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1122 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1123 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
    %1124 = emitc.call_opaque "__Runtime_dma_createio_4"(%186, %1120, %1121, %1122, %1123) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1125 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1126 = emitc.call_opaque "__runtime_buffer_offset"(%1099, %1125) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1127 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1128 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1129 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1130 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1131 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1132 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1133 = emitc.call_opaque "__runtime_buffer_arg"(%1128) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1134 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1135 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1136 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1137 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1138 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1139 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1140 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1133, %9, %1130, %1131, %1139, %1132, %1134, %1135, %1136, %1137, %1138) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1141 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1142 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1143 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1144 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1145 = emitc.call_opaque "__runtime_buffer_arg"(%1127) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1147 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1148 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1149 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1150 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1151 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1152 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1145, %10, %1142, %1143, %1151, %1144, %1146, %1147, %1148, %1149, %1150) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1153 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1154 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1155 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %1156 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %1152, %1153, %1154, %1155) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %1157 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1158 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1159 = emitc.call_opaque "__runtime_buffer_offset"(%1099, %1158) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1160 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1161 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1162 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1163 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1164 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1165 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1166 = emitc.call_opaque "__runtime_buffer_arg"(%1161) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1167 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1168 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1169 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1170 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1171 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1172 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1173 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1166, %9, %1163, %1164, %1172, %1165, %1167, %1168, %1169, %1170, %1171) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1174 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1175 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1176 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1177 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1178 = emitc.call_opaque "__runtime_buffer_arg"(%1160) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1180 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1181 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1182 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1183 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1184 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1185 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1178, %10, %1175, %1176, %1184, %1177, %1179, %1180, %1181, %1182, %1183) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1186 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1187 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1188 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %1189 = emitc.call_opaque "__Runtime_dma_createio_4"(%250, %1185, %1186, %1187, %1188) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %1190 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1191 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1192 = emitc.call_opaque "__runtime_buffer_offset"(%1099, %1191) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1193 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1194 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1195 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1196 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1197 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1198 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1199 = emitc.call_opaque "__runtime_buffer_arg"(%1194) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1200 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1201 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1202 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1203 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1204 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1205 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1206 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1199, %9, %1196, %1197, %1205, %1198, %1200, %1201, %1202, %1203, %1204) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1207 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1208 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1209 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1210 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1211 = emitc.call_opaque "__runtime_buffer_arg"(%1193) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1212 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1213 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1214 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1215 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1216 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1217 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1218 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1211, %10, %1208, %1209, %1217, %1210, %1212, %1213, %1214, %1215, %1216) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1219 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1220 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1221 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %1222 = emitc.call_opaque "__Runtime_dma_createio_4"(%427, %1218, %1219, %1220, %1221) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %1223 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1224 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1225 = emitc.call_opaque "__runtime_buffer_offset"(%1099, %1224) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1226 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1227 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1228 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1229 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1230 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1231 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1232 = emitc.call_opaque "__runtime_buffer_arg"(%1227) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1233 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1234 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1235 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1236 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1237 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1238 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1239 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1232, %9, %1229, %1230, %1238, %1231, %1233, %1234, %1235, %1236, %1237) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1240 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1241 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1242 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1243 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1244 = emitc.call_opaque "__runtime_buffer_arg"(%1226) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1245 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1246 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1247 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1248 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1249 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1250 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1251 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1244, %10, %1241, %1242, %1250, %1243, %1245, %1246, %1247, %1248, %1249) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1252 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1253 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1254 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %1255 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1251, %1252, %1253, %1254) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    %1256 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
    %1257 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1258 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1259 = emitc.call_opaque "__Runtime_startio"(%arg0, %1124, %1257, %1258) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1260 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1261 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1260) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=48, len=256, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1262 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %1263 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1264 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1265 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1266 = emitc.call_opaque "__runtime_buffer_arg"(%1261) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1267 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %1268 = emitc.call_opaque "__runtime_buffer_offset"(%1266, %1267) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1269 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1270 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1271 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1272 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1273 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1274 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1275 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1276 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1277 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1278 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1279 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1280 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1281 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1282 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1284 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1268, %6, %1263, %1264, %1283, %1265, %1269, %1270, %1271, %1272, %1273, %1274, %1275, %1276, %1277, %1278, %1279, %1280, %1281, %1282) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=32, len=256, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1285 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1286 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1287 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1288 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1289 = emitc.call_opaque "__runtime_buffer_arg"(%1261) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1290 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %1291 = emitc.call_opaque "__runtime_buffer_offset"(%1289, %1290) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1292 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1293 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1294 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1295 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1296 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1297 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1298 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1299 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1300 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1301 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1302 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1303 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1304 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1305 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1306 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1307 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1291, %5, %1286, %1287, %1306, %1288, %1292, %1293, %1294, %1295, %1296, %1297, %1298, %1299, %1300, %1301, %1302, %1303, %1304, %1305) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=16, len=256, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1308 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1309 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1310 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1311 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1312 = emitc.call_opaque "__runtime_buffer_arg"(%1261) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1313 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %1314 = emitc.call_opaque "__runtime_buffer_offset"(%1312, %1313) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1315 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1316 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1317 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1318 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1319 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1320 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1321 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1322 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1323 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1324 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1325 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1326 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1327 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1328 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1329 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1330 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1314, %4, %1309, %1310, %1329, %1311, %1315, %1316, %1317, %1318, %1319, %1320, %1321, %1322, %1323, %1324, %1325, %1326, %1327, %1328) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, offset=0, len=256, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1331 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1332 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1333 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1334 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1335 = emitc.call_opaque "__runtime_buffer_arg"(%1261) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1336 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1337 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1338 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1339 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1340 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1341 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1342 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1343 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1344 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1345 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1346 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1347 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1348 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1349 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1350 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1351 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %540, %1335, %3, %1332, %1333, %1350, %1334, %1336, %1337, %1338, %1339, %1340, %1341, %1342, %1343, %1344, %1345, %1346, %1347, %1348, %1349) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1352 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1353 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1354 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %540, %1352, %1354) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1355 = emitc.call_opaque "__Runtime_dma_createio_4"(%540, %1351, %1352, %1353, %1354) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1356 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1357 = emitc.call_opaque "__runtime_buffer_offset"(%1261, %1356) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1358 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1359 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1360 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1361 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1362 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1363 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1364 = emitc.call_opaque "__runtime_buffer_arg"(%1359) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1365 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1366 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1367 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1368 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1369 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1370 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1371 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1364, %8, %1361, %1362, %1370, %1363, %1365, %1366, %1367, %1368, %1369) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1373 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1374 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1375 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1376 = emitc.call_opaque "__runtime_buffer_arg"(%1358) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1377 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1378 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1379 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1380 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1381 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1382 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1383 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %79, %1376, %7, %1373, %1374, %1382, %1375, %1377, %1378, %1379, %1380, %1381) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1384 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1385 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1386 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %1387 = emitc.call_opaque "__Runtime_dma_createio_4"(%79, %1383, %1384, %1385, %1386) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %1388 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1389 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %1390 = emitc.call_opaque "__runtime_buffer_offset"(%1261, %1389) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1391 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1392 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1393 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1394 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1395 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1396 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1397 = emitc.call_opaque "__runtime_buffer_arg"(%1392) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1398 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1399 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1400 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1401 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1402 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1403 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1404 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1397, %8, %1394, %1395, %1403, %1396, %1398, %1399, %1400, %1401, %1402) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1405 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1406 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1407 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1408 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1409 = emitc.call_opaque "__runtime_buffer_arg"(%1391) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1410 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1411 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1412 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1413 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1414 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1415 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1416 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %250, %1409, %7, %1406, %1407, %1415, %1408, %1410, %1411, %1412, %1413, %1414) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1417 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1418 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1419 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %1420 = emitc.call_opaque "__Runtime_dma_createio_4"(%250, %1416, %1417, %1418, %1419) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %1421 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1422 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %1423 = emitc.call_opaque "__runtime_buffer_offset"(%1261, %1422) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1424 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1425 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1426 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1427 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1428 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1429 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1430 = emitc.call_opaque "__runtime_buffer_arg"(%1425) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1431 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1432 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1433 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1434 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1435 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1436 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1437 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1430, %8, %1427, %1428, %1436, %1429, %1431, %1432, %1433, %1434, %1435) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1438 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1439 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1440 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1441 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1442 = emitc.call_opaque "__runtime_buffer_arg"(%1424) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1443 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1444 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1445 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1446 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1447 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1448 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1449 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %427, %1442, %7, %1439, %1440, %1448, %1441, %1443, %1444, %1445, %1446, %1447) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1450 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1451 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1452 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %1453 = emitc.call_opaque "__Runtime_dma_createio_4"(%427, %1449, %1450, %1451, %1452) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %1454 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1455 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %1456 = emitc.call_opaque "__runtime_buffer_offset"(%1261, %1455) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1457 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1458 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1459 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1460 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1461 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1462 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1463 = emitc.call_opaque "__runtime_buffer_arg"(%1458) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1464 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1465 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1466 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1467 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1468 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1469 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1470 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1463, %8, %1460, %1461, %1469, %1462, %1464, %1465, %1466, %1467, %1468) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1471 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1472 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1473 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1474 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1475 = emitc.call_opaque "__runtime_buffer_arg"(%1457) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1476 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1477 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1478 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1479 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1480 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1481 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1482 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %604, %1475, %7, %1472, %1473, %1481, %1474, %1476, %1477, %1478, %1479, %1480) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1483 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1484 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1485 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %1486 = emitc.call_opaque "__Runtime_dma_createio_4"(%604, %1482, %1483, %1484, %1485) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    %1487 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %1488 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1489 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1490 = emitc.call_opaque "__Runtime_startio"(%arg0, %1355, %1488, %1489) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1491 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1492 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1491) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1493 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1494 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1495 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1496 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1497 = emitc.call_opaque "__runtime_buffer_arg"(%1492) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1498 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1499 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1500 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1501 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1502 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1503 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1504 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1505 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1506 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1507 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1508 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1509 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1510 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1511 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1512 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1513 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %363, %1497, %12, %1494, %1495, %1512, %1496, %1498, %1499, %1500, %1501, %1502, %1503, %1504, %1505, %1506, %1507, %1508, %1509, %1510, %1511) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1514 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1515 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1516 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %1517 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %1513, %1514, %1515, %1516) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1518 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1519 = emitc.call_opaque "__runtime_buffer_offset"(%1492, %1518) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1520 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1521 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1522 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1523 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1524 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1525 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1526 = emitc.call_opaque "__runtime_buffer_arg"(%1521) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1527 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1528 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1529 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1530 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1531 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1532 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1533 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1526, %9, %1523, %1524, %1532, %1525, %1527, %1528, %1529, %1530, %1531) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1534 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1535 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1536 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1537 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1538 = emitc.call_opaque "__runtime_buffer_arg"(%1520) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1539 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1540 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1541 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1542 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1543 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1544 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1545 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1538, %10, %1535, %1536, %1544, %1537, %1539, %1540, %1541, %1542, %1543) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1546 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1547 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1548 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %1549 = emitc.call_opaque "__Runtime_dma_createio_4"(%113, %1545, %1546, %1547, %1548) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %1550 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1551 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1552 = emitc.call_opaque "__runtime_buffer_offset"(%1492, %1551) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1553 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1554 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1555 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1556 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1557 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1558 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1559 = emitc.call_opaque "__runtime_buffer_arg"(%1554) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1560 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1561 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1562 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1563 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1564 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1565 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1566 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1559, %9, %1556, %1557, %1565, %1558, %1560, %1561, %1562, %1563, %1564) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1567 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1568 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1569 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1570 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1571 = emitc.call_opaque "__runtime_buffer_arg"(%1553) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1572 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1573 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1574 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1575 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1576 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1577 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1578 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1571, %10, %1568, %1569, %1577, %1570, %1572, %1573, %1574, %1575, %1576) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1579 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1580 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1581 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %1582 = emitc.call_opaque "__Runtime_dma_createio_4"(%286, %1578, %1579, %1580, %1581) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %1583 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1584 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1585 = emitc.call_opaque "__runtime_buffer_offset"(%1492, %1584) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1586 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1587 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1588 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1589 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1590 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1591 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1592 = emitc.call_opaque "__runtime_buffer_arg"(%1587) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1593 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1594 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1595 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1596 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1597 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1598 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1599 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1592, %9, %1589, %1590, %1598, %1591, %1593, %1594, %1595, %1596, %1597) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1600 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1601 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1602 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1603 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1604 = emitc.call_opaque "__runtime_buffer_arg"(%1586) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1605 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1606 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1607 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1608 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1609 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1610 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1611 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1604, %10, %1601, %1602, %1610, %1603, %1605, %1606, %1607, %1608, %1609) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1612 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1613 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1614 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %1615 = emitc.call_opaque "__Runtime_dma_createio_4"(%463, %1611, %1612, %1613, %1614) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %1616 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1617 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1618 = emitc.call_opaque "__runtime_buffer_offset"(%1492, %1617) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1619 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1620 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1621 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1622 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1623 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1624 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1625 = emitc.call_opaque "__runtime_buffer_arg"(%1620) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1626 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1627 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1628 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1629 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1630 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1631 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1632 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1625, %9, %1622, %1623, %1631, %1624, %1626, %1627, %1628, %1629, %1630) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1633 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1634 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1635 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1636 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1637 = emitc.call_opaque "__runtime_buffer_arg"(%1619) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1638 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1639 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1640 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1641 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1642 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1643 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1644 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1637, %10, %1634, %1635, %1643, %1636, %1638, %1639, %1640, %1641, %1642) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1645 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1646 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1647 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %1648 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1644, %1645, %1646, %1647) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    %1649 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %1650 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1651 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1652 = emitc.call_opaque "__Runtime_startio"(%arg0, %1517, %1650, %1651) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1653 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1654 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1653) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, offset=48, len=256, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1655 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %1656 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1657 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1658 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1659 = emitc.call_opaque "__runtime_buffer_arg"(%1654) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1660 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %1661 = emitc.call_opaque "__runtime_buffer_offset"(%1659, %1660) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1662 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1663 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1664 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1665 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1666 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1667 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1668 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1669 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1670 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1671 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1672 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1673 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1674 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1675 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1676 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1677 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1661, %2, %1656, %1657, %1676, %1658, %1662, %1663, %1664, %1665, %1666, %1667, %1668, %1669, %1670, %1671, %1672, %1673, %1674, %1675) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=32, len=256, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1678 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %1679 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1680 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1681 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1682 = emitc.call_opaque "__runtime_buffer_arg"(%1654) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1683 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %1684 = emitc.call_opaque "__runtime_buffer_offset"(%1682, %1683) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1685 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1686 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1687 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1688 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1689 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1690 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1691 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1692 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1693 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1694 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1695 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1696 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1697 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1698 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1699 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1700 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1684, %8, %1679, %1680, %1699, %1681, %1685, %1686, %1687, %1688, %1689, %1690, %1691, %1692, %1693, %1694, %1695, %1696, %1697, %1698) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=16, len=256, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1701 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1702 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1703 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1704 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1705 = emitc.call_opaque "__runtime_buffer_arg"(%1654) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1706 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %1707 = emitc.call_opaque "__runtime_buffer_offset"(%1705, %1706) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1708 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1709 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1710 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1711 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1712 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1713 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1714 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1715 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1716 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1717 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1718 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1719 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1721 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1722 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1723 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1707, %7, %1702, %1703, %1722, %1704, %1708, %1709, %1710, %1711, %1712, %1713, %1714, %1715, %1716, %1717, %1718, %1719, %1720, %1721) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=256, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1724 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1725 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1726 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1727 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1728 = emitc.call_opaque "__runtime_buffer_arg"(%1654) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1729 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1730 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1731 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1732 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1733 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1734 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1735 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1736 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1737 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1738 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1739 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1740 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1741 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1742 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1743 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1744 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %1728, %9, %1725, %1726, %1743, %1727, %1729, %1730, %1731, %1732, %1733, %1734, %1735, %1736, %1737, %1738, %1739, %1740, %1741, %1742) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1745 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1746 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1747 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %363, %1745, %1747) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1748 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %1744, %1745, %1746, %1747) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1749 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1750 = emitc.call_opaque "__runtime_buffer_offset"(%1654, %1749) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1751 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1752 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1753 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1754 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1755 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1756 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1757 = emitc.call_opaque "__runtime_buffer_arg"(%1752) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1758 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1759 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1760 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1761 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1762 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1763 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1764 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1757, %8, %1754, %1755, %1763, %1756, %1758, %1759, %1760, %1761, %1762) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1765 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1766 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1767 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1768 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1769 = emitc.call_opaque "__runtime_buffer_arg"(%1751) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1770 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1771 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1772 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1773 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1774 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1775 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1776 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %113, %1769, %7, %1766, %1767, %1775, %1768, %1770, %1771, %1772, %1773, %1774) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1777 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1778 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1779 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %1780 = emitc.call_opaque "__Runtime_dma_createio_4"(%113, %1776, %1777, %1778, %1779) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %1781 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1782 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %1783 = emitc.call_opaque "__runtime_buffer_offset"(%1654, %1782) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1784 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1785 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1786 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1787 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1788 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1789 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1790 = emitc.call_opaque "__runtime_buffer_arg"(%1785) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1791 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1792 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1793 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1794 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1795 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1796 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1797 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1790, %8, %1787, %1788, %1796, %1789, %1791, %1792, %1793, %1794, %1795) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1798 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1799 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1800 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1801 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1802 = emitc.call_opaque "__runtime_buffer_arg"(%1784) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1803 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1804 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1805 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1806 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1807 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1808 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1809 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %286, %1802, %7, %1799, %1800, %1808, %1801, %1803, %1804, %1805, %1806, %1807) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1810 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1811 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1812 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %1813 = emitc.call_opaque "__Runtime_dma_createio_4"(%286, %1809, %1810, %1811, %1812) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %1814 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1815 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %1816 = emitc.call_opaque "__runtime_buffer_offset"(%1654, %1815) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1817 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1818 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1819 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1820 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1821 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1822 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1823 = emitc.call_opaque "__runtime_buffer_arg"(%1818) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1824 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1825 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1826 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1827 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1828 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1829 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1830 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1823, %8, %1820, %1821, %1829, %1822, %1824, %1825, %1826, %1827, %1828) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1831 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1832 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1833 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1834 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1835 = emitc.call_opaque "__runtime_buffer_arg"(%1817) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1836 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1837 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1838 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1839 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1840 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1841 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1842 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %463, %1835, %7, %1832, %1833, %1841, %1834, %1836, %1837, %1838, %1839, %1840) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1843 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1844 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1845 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %1846 = emitc.call_opaque "__Runtime_dma_createio_4"(%463, %1842, %1843, %1844, %1845) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %1847 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1848 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %1849 = emitc.call_opaque "__runtime_buffer_offset"(%1654, %1848) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1850 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1851 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1852 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1853 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1854 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1855 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1856 = emitc.call_opaque "__runtime_buffer_arg"(%1851) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1857 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1858 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1859 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1860 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1861 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1862 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1863 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1856, %8, %1853, %1854, %1862, %1855, %1857, %1858, %1859, %1860, %1861) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1864 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1865 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1866 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1867 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1868 = emitc.call_opaque "__runtime_buffer_arg"(%1850) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1869 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1870 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1871 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1872 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1873 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1874 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1875 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %640, %1868, %7, %1865, %1866, %1874, %1867, %1869, %1870, %1871, %1872, %1873) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1876 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1877 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1878 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %1879 = emitc.call_opaque "__Runtime_dma_createio_4"(%640, %1875, %1876, %1877, %1878) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    %1880 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %1881 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1882 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1883 = emitc.call_opaque "__Runtime_startio"(%arg0, %1748, %1881, %1882) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1884 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1885 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1884) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %1886 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1887 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1888 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1889 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1890 = emitc.call_opaque "__runtime_buffer_arg"(%1885) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1891 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1892 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1893 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1894 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1895 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1896 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1897 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1898 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1899 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1900 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1901 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1902 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1903 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1904 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1905 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1906 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %540, %1890, %1, %1887, %1888, %1905, %1889, %1891, %1892, %1893, %1894, %1895, %1896, %1897, %1898, %1899, %1900, %1901, %1902, %1903, %1904) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1907 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1908 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1909 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
    %1910 = emitc.call_opaque "__Runtime_dma_createio_4"(%540, %1906, %1907, %1908, %1909) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1911 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1912 = emitc.call_opaque "__runtime_buffer_offset"(%1885, %1911) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1913 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1914 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1915 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1916 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1917 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1918 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1919 = emitc.call_opaque "__runtime_buffer_arg"(%1914) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1920 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1921 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1922 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1923 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1924 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1925 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1926 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %1919, %9, %1916, %1917, %1925, %1918, %1920, %1921, %1922, %1923, %1924) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1927 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1928 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1929 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1930 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1931 = emitc.call_opaque "__runtime_buffer_arg"(%1913) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1932 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1933 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1934 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1935 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1936 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1937 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1938 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %1931, %10, %1928, %1929, %1937, %1930, %1932, %1933, %1934, %1935, %1936) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1939 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1940 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1941 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %1942 = emitc.call_opaque "__Runtime_dma_createio_4"(%147, %1938, %1939, %1940, %1941) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %1943 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1944 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1945 = emitc.call_opaque "__runtime_buffer_offset"(%1885, %1944) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1946 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1947 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1948 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1949 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1950 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1951 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1952 = emitc.call_opaque "__runtime_buffer_arg"(%1947) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1953 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1954 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1955 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1956 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1957 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1958 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1959 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %1952, %9, %1949, %1950, %1958, %1951, %1953, %1954, %1955, %1956, %1957) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1960 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1961 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1962 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1963 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1964 = emitc.call_opaque "__runtime_buffer_arg"(%1946) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1965 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1966 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1967 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1968 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1969 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1970 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1971 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %1964, %10, %1961, %1962, %1970, %1963, %1965, %1966, %1967, %1968, %1969) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1972 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1973 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1974 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %1975 = emitc.call_opaque "__Runtime_dma_createio_4"(%322, %1971, %1972, %1973, %1974) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %1976 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1977 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1978 = emitc.call_opaque "__runtime_buffer_offset"(%1885, %1977) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1979 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1980 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1981 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1982 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1983 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1984 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1985 = emitc.call_opaque "__runtime_buffer_arg"(%1980) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1986 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1987 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1988 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1989 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1990 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1991 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1992 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %1985, %9, %1982, %1983, %1991, %1984, %1986, %1987, %1988, %1989, %1990) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1993 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1994 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1995 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1996 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1997 = emitc.call_opaque "__runtime_buffer_arg"(%1979) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1998 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1999 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2000 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2001 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2002 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2003 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2004 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %1997, %10, %1994, %1995, %2003, %1996, %1998, %1999, %2000, %2001, %2002) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2005 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2006 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2007 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %2008 = emitc.call_opaque "__Runtime_dma_createio_4"(%499, %2004, %2005, %2006, %2007) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %2009 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2010 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %2011 = emitc.call_opaque "__runtime_buffer_offset"(%1885, %2010) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2012 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2013 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %2014 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2015 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2016 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2017 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2018 = emitc.call_opaque "__runtime_buffer_arg"(%2013) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2019 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2020 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2021 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2022 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2023 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2024 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2025 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %2018, %9, %2015, %2016, %2024, %2017, %2019, %2020, %2021, %2022, %2023) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %2026 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2027 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2028 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2029 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2030 = emitc.call_opaque "__runtime_buffer_arg"(%2012) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2031 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2032 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2033 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2034 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2035 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2036 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2037 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %2030, %10, %2027, %2028, %2036, %2029, %2031, %2032, %2033, %2034, %2035) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2038 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2039 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2040 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %2041 = emitc.call_opaque "__Runtime_dma_createio_4"(%676, %2037, %2038, %2039, %2040) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    %2042 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %2043 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2044 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2045 = emitc.call_opaque "__Runtime_startio"(%arg0, %1910, %2043, %2044) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2046 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %2047 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %2046) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=48, len=256, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %2048 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %2049 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2050 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2051 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2052 = emitc.call_opaque "__runtime_buffer_arg"(%2047) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2053 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %2054 = emitc.call_opaque "__runtime_buffer_offset"(%2052, %2053) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2055 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2056 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2057 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2058 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2059 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2060 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2061 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2062 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2063 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2064 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2065 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %2066 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2067 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2068 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2069 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2070 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %2054, %1, %2049, %2050, %2069, %2051, %2055, %2056, %2057, %2058, %2059, %2060, %2061, %2062, %2063, %2064, %2065, %2066, %2067, %2068) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=32, len=256, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %2071 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %2072 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2073 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2074 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2075 = emitc.call_opaque "__runtime_buffer_arg"(%2047) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2076 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %2077 = emitc.call_opaque "__runtime_buffer_offset"(%2075, %2076) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2078 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2079 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2080 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2081 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2082 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2083 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2085 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2086 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2087 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2088 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %2089 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2090 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2091 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2092 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2093 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %2077, %6, %2072, %2073, %2092, %2074, %2078, %2079, %2080, %2081, %2082, %2083, %2084, %2085, %2086, %2087, %2088, %2089, %2090, %2091) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=16, len=256, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %2094 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2095 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2096 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2097 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2098 = emitc.call_opaque "__runtime_buffer_arg"(%2047) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2099 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %2100 = emitc.call_opaque "__runtime_buffer_offset"(%2098, %2099) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2101 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2102 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2103 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2104 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2105 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2106 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2107 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2108 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2109 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2110 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2111 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %2112 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2113 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2114 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2115 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2116 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %2100, %5, %2095, %2096, %2115, %2097, %2101, %2102, %2103, %2104, %2105, %2106, %2107, %2108, %2109, %2110, %2111, %2112, %2113, %2114) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=0, len=256, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %2117 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2118 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2119 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2120 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %2121 = emitc.call_opaque "__runtime_buffer_arg"(%2047) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2122 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2123 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2124 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2125 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2126 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2127 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2128 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2129 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2130 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %2131 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2132 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %2133 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2134 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2135 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2136 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2137 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %363, %2121, %4, %2118, %2119, %2136, %2120, %2122, %2123, %2124, %2125, %2126, %2127, %2128, %2129, %2130, %2131, %2132, %2133, %2134, %2135) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2138 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2139 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2140 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %363, %2138, %2140) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %2141 = emitc.call_opaque "__Runtime_dma_createio_4"(%363, %2137, %2138, %2139, %2140) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %2142 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %2143 = emitc.call_opaque "__runtime_buffer_offset"(%2047, %2142) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2144 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2145 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %2146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2147 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2148 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2149 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %2150 = emitc.call_opaque "__runtime_buffer_arg"(%2145) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2151 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2152 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2153 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2154 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2155 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2156 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2157 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %2150, %8, %2147, %2148, %2156, %2149, %2151, %2152, %2153, %2154, %2155) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %2158 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2159 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2160 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2161 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %2162 = emitc.call_opaque "__runtime_buffer_arg"(%2144) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2163 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2164 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2165 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2166 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2167 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %2168 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2169 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %147, %2162, %7, %2159, %2160, %2168, %2161, %2163, %2164, %2165, %2166, %2167) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2170 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2171 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2172 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %2173 = emitc.call_opaque "__Runtime_dma_createio_4"(%147, %2169, %2170, %2171, %2172) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %2174 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2175 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %2176 = emitc.call_opaque "__runtime_buffer_offset"(%2047, %2175) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2177 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2178 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %2179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2180 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2181 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2182 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2183 = emitc.call_opaque "__runtime_buffer_arg"(%2178) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2184 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2185 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2186 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2187 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2188 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %2189 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2190 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %2183, %8, %2180, %2181, %2189, %2182, %2184, %2185, %2186, %2187, %2188) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %2191 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2192 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2193 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2194 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2195 = emitc.call_opaque "__runtime_buffer_arg"(%2177) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2196 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2197 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2198 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2199 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2200 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %2201 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2202 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %322, %2195, %7, %2192, %2193, %2201, %2194, %2196, %2197, %2198, %2199, %2200) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2203 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2204 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2205 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %2206 = emitc.call_opaque "__Runtime_dma_createio_4"(%322, %2202, %2203, %2204, %2205) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %2207 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2208 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %2209 = emitc.call_opaque "__runtime_buffer_offset"(%2047, %2208) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2210 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2211 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %2212 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2213 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2214 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2215 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2216 = emitc.call_opaque "__runtime_buffer_arg"(%2211) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2217 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2218 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2219 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2220 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2221 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %2222 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2223 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %2216, %8, %2213, %2214, %2222, %2215, %2217, %2218, %2219, %2220, %2221) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %2224 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2225 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2226 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2227 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %2228 = emitc.call_opaque "__runtime_buffer_arg"(%2210) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2229 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2230 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2231 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2232 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2233 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %2234 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2235 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %499, %2228, %7, %2225, %2226, %2234, %2227, %2229, %2230, %2231, %2232, %2233) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2236 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2237 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2238 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %2239 = emitc.call_opaque "__Runtime_dma_createio_4"(%499, %2235, %2236, %2237, %2238) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %2240 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %2241 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %2242 = emitc.call_opaque "__runtime_buffer_offset"(%2047, %2241) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %2243 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %2244 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %2245 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2246 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2247 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2248 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2249 = emitc.call_opaque "__runtime_buffer_arg"(%2244) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2250 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2251 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2252 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2253 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2254 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %2255 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2256 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %2249, %8, %2246, %2247, %2255, %2248, %2250, %2251, %2252, %2253, %2254) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %2257 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2258 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %2259 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2260 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2261 = emitc.call_opaque "__runtime_buffer_arg"(%2243) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %2262 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %2263 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %2264 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2265 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2266 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %2267 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2268 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %676, %2261, %7, %2258, %2259, %2267, %2260, %2262, %2263, %2264, %2265, %2266) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %2269 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %2270 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2271 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %2272 = emitc.call_opaque "__Runtime_dma_createio_4"(%676, %2268, %2269, %2270, %2271) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    %2273 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %2274 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %2275 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2276 = emitc.call_opaque "__Runtime_startio"(%arg0, %2141, %2274, %2275) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %2277 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %2278 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %45, %79, %113, %147, %214, %250, %286, %322, %391, %427, %463, %499, %568, %604, %640, %676, %2277) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %2279 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %2278) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %2280 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2281 = emitc.call_opaque "__Runtime_startio"(%arg0, %75, %76, %2280) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2282 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2283 = emitc.call_opaque "__Runtime_startio"(%arg0, %109, %110, %2282) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2284 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2285 = emitc.call_opaque "__Runtime_startio"(%arg0, %143, %144, %2284) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2286 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2287 = emitc.call_opaque "__Runtime_startio"(%arg0, %177, %178, %2286) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2288 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2289 = emitc.call_opaque "__Runtime_startio"(%arg0, %246, %247, %2288) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2290 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2291 = emitc.call_opaque "__Runtime_startio"(%arg0, %282, %283, %2290) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2292 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2293 = emitc.call_opaque "__Runtime_startio"(%arg0, %318, %319, %2292) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2294 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2295 = emitc.call_opaque "__Runtime_startio"(%arg0, %354, %355, %2294) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2296 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2297 = emitc.call_opaque "__Runtime_startio"(%arg0, %423, %424, %2296) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2298 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2299 = emitc.call_opaque "__Runtime_startio"(%arg0, %459, %460, %2298) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2300 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2301 = emitc.call_opaque "__Runtime_startio"(%arg0, %495, %496, %2300) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2302 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2303 = emitc.call_opaque "__Runtime_startio"(%arg0, %531, %532, %2302) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2304 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2305 = emitc.call_opaque "__Runtime_startio"(%arg0, %600, %601, %2304) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2306 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2307 = emitc.call_opaque "__Runtime_startio"(%arg0, %636, %637, %2306) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2308 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2309 = emitc.call_opaque "__Runtime_startio"(%arg0, %672, %673, %2308) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2310 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2311 = emitc.call_opaque "__Runtime_startio"(%arg0, %708, %709, %2310) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2312 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2313 = emitc.call_opaque "__Runtime_startio"(%arg0, %769, %770, %2312) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2314 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2315 = emitc.call_opaque "__Runtime_startio"(%arg0, %800, %801, %2314) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2316 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2317 = emitc.call_opaque "__Runtime_startio"(%arg0, %831, %832, %2316) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2318 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2319 = emitc.call_opaque "__Runtime_startio"(%arg0, %862, %863, %2318) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2320 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2321 = emitc.call_opaque "__Runtime_startio"(%arg0, %994, %995, %2320) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2322 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2323 = emitc.call_opaque "__Runtime_startio"(%arg0, %1027, %1028, %2322) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2324 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2325 = emitc.call_opaque "__Runtime_startio"(%arg0, %1060, %1061, %2324) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2326 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2327 = emitc.call_opaque "__Runtime_startio"(%arg0, %1093, %1094, %2326) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2328 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2329 = emitc.call_opaque "__Runtime_startio"(%arg0, %1156, %1157, %2328) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2330 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2331 = emitc.call_opaque "__Runtime_startio"(%arg0, %1189, %1190, %2330) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2332 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2333 = emitc.call_opaque "__Runtime_startio"(%arg0, %1222, %1223, %2332) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2334 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2335 = emitc.call_opaque "__Runtime_startio"(%arg0, %1255, %1256, %2334) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2336 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2337 = emitc.call_opaque "__Runtime_startio"(%arg0, %1387, %1388, %2336) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2338 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2339 = emitc.call_opaque "__Runtime_startio"(%arg0, %1420, %1421, %2338) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2340 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2341 = emitc.call_opaque "__Runtime_startio"(%arg0, %1453, %1454, %2340) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2342 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2343 = emitc.call_opaque "__Runtime_startio"(%arg0, %1486, %1487, %2342) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2344 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2345 = emitc.call_opaque "__Runtime_startio"(%arg0, %1549, %1550, %2344) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2346 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2347 = emitc.call_opaque "__Runtime_startio"(%arg0, %1582, %1583, %2346) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2348 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2349 = emitc.call_opaque "__Runtime_startio"(%arg0, %1615, %1616, %2348) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2350 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2351 = emitc.call_opaque "__Runtime_startio"(%arg0, %1648, %1649, %2350) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2352 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2353 = emitc.call_opaque "__Runtime_startio"(%arg0, %1780, %1781, %2352) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2354 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2355 = emitc.call_opaque "__Runtime_startio"(%arg0, %1813, %1814, %2354) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2356 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2357 = emitc.call_opaque "__Runtime_startio"(%arg0, %1846, %1847, %2356) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2358 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2359 = emitc.call_opaque "__Runtime_startio"(%arg0, %1879, %1880, %2358) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2360 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2361 = emitc.call_opaque "__Runtime_startio"(%arg0, %1942, %1943, %2360) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2362 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2363 = emitc.call_opaque "__Runtime_startio"(%arg0, %1975, %1976, %2362) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2364 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2365 = emitc.call_opaque "__Runtime_startio"(%arg0, %2008, %2009, %2364) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2366 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2367 = emitc.call_opaque "__Runtime_startio"(%arg0, %2041, %2042, %2366) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2368 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2369 = emitc.call_opaque "__Runtime_startio"(%arg0, %2173, %2174, %2368) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2370 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2371 = emitc.call_opaque "__Runtime_startio"(%arg0, %2206, %2207, %2370) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2372 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2373 = emitc.call_opaque "__Runtime_startio"(%arg0, %2239, %2240, %2372) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2374 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2375 = emitc.call_opaque "__Runtime_startio"(%arg0, %2272, %2273, %2374) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %2279) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %181) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %358) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %535) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %712) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %866) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1097) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1259) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1490) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1652) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1883) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %2045) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %2276) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
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
