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
    %7 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %8 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %9 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %10 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %11 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %12 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %13 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %14 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %15 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %16 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %17 = "emitc.constant"() <{value = 0 : index}> : () -> index
    %18 = "emitc.constant"() <{value = 4 : index}> : () -> index
    %19 = "emitc.constant"() <{value = 1 : index}> : () -> index
    %20 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %21 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %20) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %22 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %23 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %24 = emitc.call_opaque "XAie_TileLoc"(%22, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %25 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %26 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %27 = emitc.call_opaque "XAie_TileLoc"(%25, %26) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %28 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %29 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %30 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %31 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %33 = emitc.call_opaque "__runtime_buffer_arg"(%29) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %34 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %35 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %36 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %37 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %38 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %39 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %40 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %33, %14, %30, %31, %39, %32, %34, %35, %36, %37, %38) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %41 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %43 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %44 = emitc.call_opaque "__runtime_buffer_arg"(%28) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %45 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %46 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %47 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %48 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %49 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %50 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %51 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %44, %15, %41, %42, %50, %43, %45, %46, %47, %48, %49) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %52 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %53 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %54 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %55 = emitc.call_opaque "__Runtime_dma_createio_4"(%27, %51, %52, %53, %54) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %56 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %57 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %58 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %59 = emitc.call_opaque "XAie_TileLoc"(%57, %58) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %60 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %61 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %62 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %63 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %64 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %65 = emitc.call_opaque "__runtime_buffer_arg"(%61) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %66 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %67 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %68 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %69 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %70 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %71 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %72 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %59, %65, %14, %62, %63, %71, %64, %66, %67, %68, %69, %70) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %73 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %74 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %75 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %76 = emitc.call_opaque "__runtime_buffer_arg"(%60) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %77 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %78 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %79 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %80 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %81 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %82 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %83 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %59, %76, %15, %73, %74, %82, %75, %77, %78, %79, %80, %81) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %84 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %85 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %86 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %87 = emitc.call_opaque "__Runtime_dma_createio_4"(%59, %83, %84, %85, %86) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %88 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %89 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %90 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %91 = emitc.call_opaque "XAie_TileLoc"(%89, %90) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %92 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %93 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %94 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %95 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %96 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %97 = emitc.call_opaque "__runtime_buffer_arg"(%93) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %98 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %99 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %100 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %101 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %102 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %103 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %104 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %97, %14, %94, %95, %103, %96, %98, %99, %100, %101, %102) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %105 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %106 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %107 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %108 = emitc.call_opaque "__runtime_buffer_arg"(%92) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %109 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %110 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %111 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %112 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %113 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %114 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %115 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %108, %15, %105, %106, %114, %107, %109, %110, %111, %112, %113) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %116 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %117 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %118 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %119 = emitc.call_opaque "__Runtime_dma_createio_4"(%91, %115, %116, %117, %118) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %120 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %121 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %122 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %123 = emitc.call_opaque "XAie_TileLoc"(%121, %122) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %124 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %125 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %126 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %127 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %128 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %129 = emitc.call_opaque "__runtime_buffer_arg"(%125) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %130 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %131 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %132 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %133 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %134 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %135 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %136 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %123, %129, %14, %126, %127, %135, %128, %130, %131, %132, %133, %134) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %137 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %138 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %139 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %140 = emitc.call_opaque "__runtime_buffer_arg"(%124) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %141 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %142 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %143 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %144 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %145 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %146 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %147 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %123, %140, %15, %137, %138, %146, %139, %141, %142, %143, %144, %145) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %148 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %149 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %150 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %151 = emitc.call_opaque "__Runtime_dma_createio_4"(%123, %147, %148, %149, %150) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    %152 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,0) */"
    %153 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%21) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %24, %2062, %15, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%24, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (0,0) */"
      %2083 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %154 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %155 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %154) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %156 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %157 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %158 = emitc.call_opaque "XAie_TileLoc"(%156, %157) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %159 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %160 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %161 = emitc.call_opaque "XAie_TileLoc"(%159, %160) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %162 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %163 = emitc.call_opaque "__runtime_buffer_offset"(%155, %162) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %164 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %165 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %166 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %167 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %168 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %169 = emitc.call_opaque "__runtime_buffer_arg"(%165) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %170 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %171 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %172 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %173 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %174 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %175 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %176 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %161, %169, %14, %166, %167, %175, %168, %170, %171, %172, %173, %174) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %177 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %178 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %179 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %180 = emitc.call_opaque "__runtime_buffer_arg"(%164) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %181 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %182 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %183 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %184 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %185 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %186 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %187 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %161, %180, %15, %177, %178, %186, %179, %181, %182, %183, %184, %185) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %188 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %189 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %190 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %191 = emitc.call_opaque "__Runtime_dma_createio_4"(%161, %187, %188, %189, %190) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %192 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %193 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %194 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %195 = emitc.call_opaque "XAie_TileLoc"(%193, %194) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %196 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %197 = emitc.call_opaque "__runtime_buffer_offset"(%155, %196) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %198 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %199 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %200 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %201 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %202 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %203 = emitc.call_opaque "__runtime_buffer_arg"(%199) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %204 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %205 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %206 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %207 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %208 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %209 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %210 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %195, %203, %14, %200, %201, %209, %202, %204, %205, %206, %207, %208) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %211 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %212 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %213 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %214 = emitc.call_opaque "__runtime_buffer_arg"(%198) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %215 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %216 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %217 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %218 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %220 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %221 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %195, %214, %15, %211, %212, %220, %213, %215, %216, %217, %218, %219) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %222 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %223 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %224 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %225 = emitc.call_opaque "__Runtime_dma_createio_4"(%195, %221, %222, %223, %224) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %226 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %227 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %228 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %229 = emitc.call_opaque "XAie_TileLoc"(%227, %228) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %230 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %231 = emitc.call_opaque "__runtime_buffer_offset"(%155, %230) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %232 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %233 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %234 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %235 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %236 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %237 = emitc.call_opaque "__runtime_buffer_arg"(%233) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %238 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %239 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %240 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %241 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %242 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %243 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %244 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %229, %237, %14, %234, %235, %243, %236, %238, %239, %240, %241, %242) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %245 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %246 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %247 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %248 = emitc.call_opaque "__runtime_buffer_arg"(%232) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %249 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %250 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %251 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %252 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %253 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %254 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %255 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %229, %248, %15, %245, %246, %254, %247, %249, %250, %251, %252, %253) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %256 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %257 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %258 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %259 = emitc.call_opaque "__Runtime_dma_createio_4"(%229, %255, %256, %257, %258) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %260 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %261 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %262 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %263 = emitc.call_opaque "XAie_TileLoc"(%261, %262) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %264 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %265 = emitc.call_opaque "__runtime_buffer_offset"(%155, %264) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %266 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %267 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %268 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %269 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %270 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %271 = emitc.call_opaque "__runtime_buffer_arg"(%267) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %272 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %273 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %274 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %275 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %276 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %277 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %278 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %263, %271, %14, %268, %269, %277, %270, %272, %273, %274, %275, %276) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %279 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %280 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %281 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %282 = emitc.call_opaque "__runtime_buffer_arg"(%266) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %283 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %284 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %285 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %286 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %287 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %288 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %289 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %263, %282, %15, %279, %280, %288, %281, %283, %284, %285, %286, %287) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %290 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %291 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %292 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %293 = emitc.call_opaque "__Runtime_dma_createio_4"(%263, %289, %290, %291, %292) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    %294 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,0) */"
    %295 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%155) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %158, %2062, %15, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%158, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
      %2083 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %296 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %297 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %296) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %298 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %299 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %300 = emitc.call_opaque "XAie_TileLoc"(%298, %299) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %301 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %302 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %303 = emitc.call_opaque "XAie_TileLoc"(%301, %302) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %304 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %305 = emitc.call_opaque "__runtime_buffer_offset"(%297, %304) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %306 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %307 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %308 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %309 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %310 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %311 = emitc.call_opaque "__runtime_buffer_arg"(%307) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %312 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %313 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %314 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %315 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %316 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %317 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %318 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %303, %311, %14, %308, %309, %317, %310, %312, %313, %314, %315, %316) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %319 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %320 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %321 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %322 = emitc.call_opaque "__runtime_buffer_arg"(%306) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %323 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %324 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %325 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %326 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %327 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %328 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %329 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %303, %322, %15, %319, %320, %328, %321, %323, %324, %325, %326, %327) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %330 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %331 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %332 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %333 = emitc.call_opaque "__Runtime_dma_createio_4"(%303, %329, %330, %331, %332) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %334 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %335 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %336 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %337 = emitc.call_opaque "XAie_TileLoc"(%335, %336) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %338 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %339 = emitc.call_opaque "__runtime_buffer_offset"(%297, %338) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %340 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %341 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %342 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %343 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %344 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %345 = emitc.call_opaque "__runtime_buffer_arg"(%341) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %346 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %347 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %348 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %349 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %350 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %351 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %352 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %337, %345, %14, %342, %343, %351, %344, %346, %347, %348, %349, %350) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %353 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %354 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %355 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %356 = emitc.call_opaque "__runtime_buffer_arg"(%340) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %357 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %358 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %359 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %360 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %361 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %362 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %363 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %337, %356, %15, %353, %354, %362, %355, %357, %358, %359, %360, %361) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %364 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %365 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %366 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %367 = emitc.call_opaque "__Runtime_dma_createio_4"(%337, %363, %364, %365, %366) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %368 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %369 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %370 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %371 = emitc.call_opaque "XAie_TileLoc"(%369, %370) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %372 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %373 = emitc.call_opaque "__runtime_buffer_offset"(%297, %372) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %374 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %375 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %376 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %377 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %378 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %379 = emitc.call_opaque "__runtime_buffer_arg"(%375) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %380 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %381 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %382 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %383 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %384 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %385 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %386 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %371, %379, %14, %376, %377, %385, %378, %380, %381, %382, %383, %384) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %387 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %388 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %389 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %390 = emitc.call_opaque "__runtime_buffer_arg"(%374) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %391 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %392 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %393 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %394 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %395 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %396 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %397 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %371, %390, %15, %387, %388, %396, %389, %391, %392, %393, %394, %395) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %398 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %399 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %400 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %401 = emitc.call_opaque "__Runtime_dma_createio_4"(%371, %397, %398, %399, %400) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %402 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %403 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %404 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %405 = emitc.call_opaque "XAie_TileLoc"(%403, %404) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %406 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %407 = emitc.call_opaque "__runtime_buffer_offset"(%297, %406) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %408 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %409 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %410 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %411 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %412 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %413 = emitc.call_opaque "__runtime_buffer_arg"(%409) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %414 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %415 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %416 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %417 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %418 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %419 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %420 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %405, %413, %14, %410, %411, %419, %412, %414, %415, %416, %417, %418) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %421 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %422 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %423 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %424 = emitc.call_opaque "__runtime_buffer_arg"(%408) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %425 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %426 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %427 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %428 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %429 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %430 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %431 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %405, %424, %15, %421, %422, %430, %423, %425, %426, %427, %428, %429) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %432 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %433 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %434 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %435 = emitc.call_opaque "__Runtime_dma_createio_4"(%405, %431, %432, %433, %434) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    %436 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %437 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%297) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %300, %2062, %15, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%300, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
      %2083 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %438 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %439 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %438) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %440 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %441 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %442 = emitc.call_opaque "XAie_TileLoc"(%440, %441) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %443 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %444 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %445 = emitc.call_opaque "XAie_TileLoc"(%443, %444) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %446 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %447 = emitc.call_opaque "__runtime_buffer_offset"(%439, %446) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %448 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %449 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %450 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %451 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %452 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %453 = emitc.call_opaque "__runtime_buffer_arg"(%449) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %454 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %455 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %456 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %457 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %458 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %459 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %460 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %445, %453, %14, %450, %451, %459, %452, %454, %455, %456, %457, %458) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %461 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %462 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %463 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %464 = emitc.call_opaque "__runtime_buffer_arg"(%448) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %465 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %466 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %467 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %468 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %469 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %470 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %471 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %445, %464, %15, %461, %462, %470, %463, %465, %466, %467, %468, %469) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %472 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %473 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %474 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %475 = emitc.call_opaque "__Runtime_dma_createio_4"(%445, %471, %472, %473, %474) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %476 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %477 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %478 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %479 = emitc.call_opaque "XAie_TileLoc"(%477, %478) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %480 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %481 = emitc.call_opaque "__runtime_buffer_offset"(%439, %480) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %482 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %483 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %484 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %485 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %486 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %487 = emitc.call_opaque "__runtime_buffer_arg"(%483) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %488 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %489 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %490 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %491 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %492 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %493 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %494 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %479, %487, %14, %484, %485, %493, %486, %488, %489, %490, %491, %492) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %495 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %496 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %497 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %498 = emitc.call_opaque "__runtime_buffer_arg"(%482) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %499 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %500 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %501 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %502 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %503 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %504 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %505 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %479, %498, %15, %495, %496, %504, %497, %499, %500, %501, %502, %503) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %506 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %507 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %508 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %509 = emitc.call_opaque "__Runtime_dma_createio_4"(%479, %505, %506, %507, %508) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %510 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %511 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %512 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %513 = emitc.call_opaque "XAie_TileLoc"(%511, %512) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %514 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %515 = emitc.call_opaque "__runtime_buffer_offset"(%439, %514) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %516 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %517 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %518 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %519 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %520 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %521 = emitc.call_opaque "__runtime_buffer_arg"(%517) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %522 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %523 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %524 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %525 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %526 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %527 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %528 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %521, %14, %518, %519, %527, %520, %522, %523, %524, %525, %526) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %529 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %530 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %531 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %532 = emitc.call_opaque "__runtime_buffer_arg"(%516) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %533 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %534 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %535 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %536 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %537 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %538 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %539 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %532, %15, %529, %530, %538, %531, %533, %534, %535, %536, %537) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %540 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %541 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %542 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %543 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %539, %540, %541, %542) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %544 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %545 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %546 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %547 = emitc.call_opaque "XAie_TileLoc"(%545, %546) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %548 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %549 = emitc.call_opaque "__runtime_buffer_offset"(%439, %548) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %550 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %551 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %552 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %553 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %554 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %555 = emitc.call_opaque "__runtime_buffer_arg"(%551) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %556 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %557 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %558 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %559 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %560 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %561 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %562 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %547, %555, %14, %552, %553, %561, %554, %556, %557, %558, %559, %560) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %563 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %564 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %565 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %566 = emitc.call_opaque "__runtime_buffer_arg"(%550) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %567 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %568 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %569 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %570 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %571 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %572 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %573 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %547, %566, %15, %563, %564, %572, %565, %567, %568, %569, %570, %571) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %574 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %575 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %576 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %577 = emitc.call_opaque "__Runtime_dma_createio_4"(%547, %573, %574, %575, %576) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    %578 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %579 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%439) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %442, %2062, %15, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%442, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
      %2083 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %580 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %581 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %580) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %582 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %583 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %584 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %585 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %586 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %587 = emitc.call_opaque "__runtime_buffer_arg"(%583) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %588 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %589 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %590 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %591 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %592 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %593 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %594 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %587, %12, %584, %585, %593, %586, %588, %589, %590, %591, %592) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %595 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %596 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %597 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %598 = emitc.call_opaque "__runtime_buffer_arg"(%582) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %599 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %600 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %601 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %602 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %603 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %604 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %605 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %598, %13, %595, %596, %604, %597, %599, %600, %601, %602, %603) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %606 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %607 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %608 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %609 = emitc.call_opaque "__Runtime_dma_createio_4"(%27, %605, %606, %607, %608) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    %610 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %611 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %612 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %613 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %614 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %615 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %616 = emitc.call_opaque "__runtime_buffer_arg"(%612) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %617 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %618 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %619 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %620 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %621 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %622 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %623 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %161, %616, %12, %613, %614, %622, %615, %617, %618, %619, %620, %621) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %624 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %625 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %626 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %627 = emitc.call_opaque "__runtime_buffer_arg"(%611) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %628 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %629 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %630 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %631 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %632 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %633 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %634 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %161, %627, %13, %624, %625, %633, %626, %628, %629, %630, %631, %632) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %635 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %636 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %637 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %638 = emitc.call_opaque "__Runtime_dma_createio_4"(%161, %634, %635, %636, %637) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    %639 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %640 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %641 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %642 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %643 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %644 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %645 = emitc.call_opaque "__runtime_buffer_arg"(%641) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %646 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %647 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %648 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %649 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %650 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %651 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %652 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %303, %645, %12, %642, %643, %651, %644, %646, %647, %648, %649, %650) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %653 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %654 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %655 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %656 = emitc.call_opaque "__runtime_buffer_arg"(%640) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %657 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %658 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %659 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %660 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %661 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %662 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %663 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %303, %656, %13, %653, %654, %662, %655, %657, %658, %659, %660, %661) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %664 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %665 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %666 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %667 = emitc.call_opaque "__Runtime_dma_createio_4"(%303, %663, %664, %665, %666) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    %668 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %669 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %670 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %671 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %672 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %673 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %674 = emitc.call_opaque "__runtime_buffer_arg"(%670) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %675 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %676 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %677 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %678 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %679 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %680 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %681 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %445, %674, %12, %671, %672, %680, %673, %675, %676, %677, %678, %679) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %682 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %683 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %684 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %685 = emitc.call_opaque "__runtime_buffer_arg"(%669) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %686 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %687 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %688 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %689 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %690 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %691 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %692 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %445, %685, %13, %682, %683, %691, %684, %686, %687, %688, %689, %690) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %693 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %694 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %695 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %696 = emitc.call_opaque "__Runtime_dma_createio_4"(%445, %692, %693, %694, %695) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    %697 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,0) */"
    %698 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=1, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%581) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %24, %2062, %14, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%24, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 3 for tile (0,0) */"
      %2083 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %699 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %700 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %699) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %701 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %702 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %703 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %704 = emitc.call_opaque "__runtime_buffer_arg"(%700) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %705 = emitc.cast %10 : i32 to i64
    %706 = emitc.call_opaque "__runtime_buffer_offset"(%704, %705) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %707 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %708 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %709 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %710 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %711 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %712 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %713 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %714 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %715 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %716 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %717 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %718 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %719 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %720 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %721 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %722 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %706, %11, %701, %702, %721, %703, %707, %708, %709, %710, %711, %712, %713, %714, %715, %716, %717, %718, %719, %720) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %723 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %724 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %725 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %726 = emitc.call_opaque "__runtime_buffer_arg"(%700) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %727 = emitc.cast %8 : i32 to i64
    %728 = emitc.call_opaque "__runtime_buffer_offset"(%726, %727) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %729 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %730 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %731 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %732 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %733 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %734 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %735 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %736 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %737 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %738 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %739 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %740 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %741 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %742 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %743 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %744 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %728, %9, %723, %724, %743, %725, %729, %730, %731, %732, %733, %734, %735, %736, %737, %738, %739, %740, %741, %742) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=256, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %745 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %746 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %747 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %748 = emitc.call_opaque "__runtime_buffer_arg"(%700) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %749 = emitc.cast %7 : i32 to i64
    %750 = emitc.call_opaque "__runtime_buffer_offset"(%748, %749) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %751 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %752 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %753 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %754 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %755 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %756 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %757 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %758 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %759 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %760 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %761 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %762 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %763 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %764 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %765 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %766 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %750, %12, %745, %746, %765, %747, %751, %752, %753, %754, %755, %756, %757, %758, %759, %760, %761, %762, %763, %764) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=256, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %767 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %768 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %769 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %770 = emitc.call_opaque "__runtime_buffer_arg"(%700) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %771 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %772 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %773 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %774 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %775 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %776 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %777 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %778 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %779 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %780 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %781 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %782 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %783 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %784 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %785 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %786 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %770, %13, %767, %768, %785, %769, %771, %772, %773, %774, %775, %776, %777, %778, %779, %780, %781, %782, %783, %784) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %787 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %788 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %789 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %442, %787, %789) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %790 = emitc.call_opaque "__Runtime_dma_createio_4"(%442, %786, %787, %788, %789) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %791 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %792 = emitc.call_opaque "__runtime_buffer_offset"(%700, %791) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %793 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %794 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %795 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %796 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %797 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %798 = emitc.call_opaque "__runtime_buffer_arg"(%794) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %799 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %800 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %801 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %802 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %803 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %804 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %805 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %798, %11, %795, %796, %804, %797, %799, %800, %801, %802, %803) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %806 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %807 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %808 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %809 = emitc.call_opaque "__runtime_buffer_arg"(%793) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %810 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %811 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %812 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %813 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %814 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %815 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %816 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %27, %809, %9, %806, %807, %815, %808, %810, %811, %812, %813, %814) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %817 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %818 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %819 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %820 = emitc.call_opaque "__Runtime_dma_createio_4"(%27, %816, %817, %818, %819) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %821 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %822 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %823 = emitc.call_opaque "__runtime_buffer_offset"(%700, %822) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %824 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %825 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %826 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %827 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %828 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %829 = emitc.call_opaque "__runtime_buffer_arg"(%825) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %830 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %831 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %832 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %833 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %834 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %835 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %836 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %161, %829, %11, %826, %827, %835, %828, %830, %831, %832, %833, %834) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %837 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %838 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %839 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %840 = emitc.call_opaque "__runtime_buffer_arg"(%824) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %841 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %842 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %843 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %844 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %845 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %846 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %847 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %161, %840, %9, %837, %838, %846, %839, %841, %842, %843, %844, %845) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %848 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %849 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %850 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %851 = emitc.call_opaque "__Runtime_dma_createio_4"(%161, %847, %848, %849, %850) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %852 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %853 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %854 = emitc.call_opaque "__runtime_buffer_offset"(%700, %853) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %855 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %856 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %857 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %858 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %859 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %860 = emitc.call_opaque "__runtime_buffer_arg"(%856) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %861 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %862 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %863 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %864 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %865 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %866 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %867 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %303, %860, %11, %857, %858, %866, %859, %861, %862, %863, %864, %865) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %868 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %869 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %870 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %871 = emitc.call_opaque "__runtime_buffer_arg"(%855) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %872 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %873 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %874 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %875 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %876 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %877 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %878 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %303, %871, %9, %868, %869, %877, %870, %872, %873, %874, %875, %876) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %879 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %880 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %881 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %882 = emitc.call_opaque "__Runtime_dma_createio_4"(%303, %878, %879, %880, %881) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %883 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %884 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %885 = emitc.call_opaque "__runtime_buffer_offset"(%700, %884) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %886 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %887 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %888 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %889 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %890 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %891 = emitc.call_opaque "__runtime_buffer_arg"(%887) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %892 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %893 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %894 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %895 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %896 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %897 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %898 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %445, %891, %11, %888, %889, %897, %890, %892, %893, %894, %895, %896) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %899 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %900 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %901 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %902 = emitc.call_opaque "__runtime_buffer_arg"(%886) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %903 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %904 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %905 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %906 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %907 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %908 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %909 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %445, %902, %9, %899, %900, %908, %901, %903, %904, %905, %906, %907) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %910 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %911 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %912 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %913 = emitc.call_opaque "__Runtime_dma_createio_4"(%445, %909, %910, %911, %912) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    %914 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %915 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %916 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %917 = emitc.call_opaque "__Runtime_startio"(%arg0, %790, %915, %916) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %918 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %919 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %918) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %920 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %921 = emitc.call_opaque "__runtime_buffer_offset"(%919, %920) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %922 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %923 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %924 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %925 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %926 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %927 = emitc.call_opaque "__runtime_buffer_arg"(%923) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %928 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %929 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %930 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %931 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %932 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %933 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %934 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %59, %927, %12, %924, %925, %933, %926, %928, %929, %930, %931, %932) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %935 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %936 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %937 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %938 = emitc.call_opaque "__runtime_buffer_arg"(%922) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %939 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %940 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %941 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %942 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %943 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %944 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %945 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %59, %938, %13, %935, %936, %944, %937, %939, %940, %941, %942, %943) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %946 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %947 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %948 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %949 = emitc.call_opaque "__Runtime_dma_createio_4"(%59, %945, %946, %947, %948) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %950 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %951 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %952 = emitc.call_opaque "__runtime_buffer_offset"(%919, %951) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %953 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %954 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %955 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %956 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %957 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %958 = emitc.call_opaque "__runtime_buffer_arg"(%954) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %959 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %960 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %961 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %962 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %963 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %964 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %965 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %195, %958, %12, %955, %956, %964, %957, %959, %960, %961, %962, %963) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %966 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %967 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %968 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %969 = emitc.call_opaque "__runtime_buffer_arg"(%953) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %970 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %971 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %972 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %973 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %974 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %975 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %976 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %195, %969, %13, %966, %967, %975, %968, %970, %971, %972, %973, %974) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %977 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %978 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %979 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %980 = emitc.call_opaque "__Runtime_dma_createio_4"(%195, %976, %977, %978, %979) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %981 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %982 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %983 = emitc.call_opaque "__runtime_buffer_offset"(%919, %982) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %984 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %985 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %986 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %987 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %988 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %989 = emitc.call_opaque "__runtime_buffer_arg"(%985) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %990 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %991 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %992 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %993 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %994 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %995 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %996 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %337, %989, %12, %986, %987, %995, %988, %990, %991, %992, %993, %994) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %997 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %998 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %999 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1000 = emitc.call_opaque "__runtime_buffer_arg"(%984) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1001 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1002 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1003 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1004 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1005 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1006 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1007 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %337, %1000, %13, %997, %998, %1006, %999, %1001, %1002, %1003, %1004, %1005) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1008 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1009 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1010 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %1011 = emitc.call_opaque "__Runtime_dma_createio_4"(%337, %1007, %1008, %1009, %1010) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %1012 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1013 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1014 = emitc.call_opaque "__runtime_buffer_offset"(%919, %1013) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1015 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1016 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1017 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1018 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1019 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1020 = emitc.call_opaque "__runtime_buffer_arg"(%1016) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1021 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1022 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1023 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1024 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1025 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1026 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1027 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %479, %1020, %12, %1017, %1018, %1026, %1019, %1021, %1022, %1023, %1024, %1025) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1028 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1029 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1030 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1031 = emitc.call_opaque "__runtime_buffer_arg"(%1015) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1032 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1033 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1034 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1035 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1036 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1037 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1038 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %479, %1031, %13, %1028, %1029, %1037, %1030, %1032, %1033, %1034, %1035, %1036) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1039 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1040 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1041 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %1042 = emitc.call_opaque "__Runtime_dma_createio_4"(%479, %1038, %1039, %1040, %1041) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    %1043 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,0) */"
    %1044 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=1, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%919) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %158, %2062, %14, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%158, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 3 for tile (1,0) */"
      %2083 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %1045 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %1046 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1045) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, len=256, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1047 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1048 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1049 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1050 = emitc.call_opaque "__runtime_buffer_arg"(%1046) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1051 = emitc.cast %10 : i32 to i64
    %1052 = emitc.call_opaque "__runtime_buffer_offset"(%1050, %1051) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1053 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1054 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1055 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1056 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1057 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1058 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1059 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1060 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1061 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1062 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1063 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1064 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1067 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1068 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %1052, %6, %1047, %1048, %1067, %1049, %1053, %1054, %1055, %1056, %1057, %1058, %1059, %1060, %1061, %1062, %1063, %1064, %1065, %1066) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, len=256, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1069 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1070 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1071 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1072 = emitc.call_opaque "__runtime_buffer_arg"(%1046) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1073 = emitc.cast %8 : i32 to i64
    %1074 = emitc.call_opaque "__runtime_buffer_offset"(%1072, %1073) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1075 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1076 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1077 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1078 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1079 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1080 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1081 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1082 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1083 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1085 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1086 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1087 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1088 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1089 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1090 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %1074, %5, %1069, %1070, %1089, %1071, %1075, %1076, %1077, %1078, %1079, %1080, %1081, %1082, %1083, %1084, %1085, %1086, %1087, %1088) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, len=256, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1091 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1092 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1093 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1094 = emitc.call_opaque "__runtime_buffer_arg"(%1046) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1095 = emitc.cast %7 : i32 to i64
    %1096 = emitc.call_opaque "__runtime_buffer_offset"(%1094, %1095) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1097 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1098 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1099 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1100 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1101 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1102 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1103 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1104 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1105 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1106 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1107 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1108 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1109 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1110 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1111 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1112 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %1096, %4, %1091, %1092, %1111, %1093, %1097, %1098, %1099, %1100, %1101, %1102, %1103, %1104, %1105, %1106, %1107, %1108, %1109, %1110) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, len=256, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1113 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1114 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1115 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1116 = emitc.call_opaque "__runtime_buffer_arg"(%1046) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1117 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1118 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1119 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1120 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1121 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1122 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1123 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1124 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1125 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1126 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1127 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1128 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1129 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1130 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1131 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1132 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %442, %1116, %3, %1113, %1114, %1131, %1115, %1117, %1118, %1119, %1120, %1121, %1122, %1123, %1124, %1125, %1126, %1127, %1128, %1129, %1130) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1133 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1134 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1135 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %442, %1133, %1135) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1136 = emitc.call_opaque "__Runtime_dma_createio_4"(%442, %1132, %1133, %1134, %1135) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1137 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1138 = emitc.call_opaque "__runtime_buffer_offset"(%1046, %1137) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1139 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1140 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1141 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1142 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1143 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1144 = emitc.call_opaque "__runtime_buffer_arg"(%1140) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1145 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1146 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1147 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1148 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1149 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1150 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1151 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %59, %1144, %11, %1141, %1142, %1150, %1143, %1145, %1146, %1147, %1148, %1149) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %1152 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1153 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1154 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1155 = emitc.call_opaque "__runtime_buffer_arg"(%1139) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1156 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1157 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1158 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1159 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1160 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1161 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1162 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %59, %1155, %9, %1152, %1153, %1161, %1154, %1156, %1157, %1158, %1159, %1160) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1163 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1164 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1165 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %1166 = emitc.call_opaque "__Runtime_dma_createio_4"(%59, %1162, %1163, %1164, %1165) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %1167 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1168 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %1169 = emitc.call_opaque "__runtime_buffer_offset"(%1046, %1168) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1170 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1171 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1172 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1173 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1174 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1175 = emitc.call_opaque "__runtime_buffer_arg"(%1171) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1176 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1177 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1178 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1179 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1180 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1181 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1182 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %195, %1175, %11, %1172, %1173, %1181, %1174, %1176, %1177, %1178, %1179, %1180) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1183 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1184 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1185 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1186 = emitc.call_opaque "__runtime_buffer_arg"(%1170) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1187 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1188 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1189 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1190 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1191 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1192 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1193 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %195, %1186, %9, %1183, %1184, %1192, %1185, %1187, %1188, %1189, %1190, %1191) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1194 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1195 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1196 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %1197 = emitc.call_opaque "__Runtime_dma_createio_4"(%195, %1193, %1194, %1195, %1196) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %1198 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1199 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %1200 = emitc.call_opaque "__runtime_buffer_offset"(%1046, %1199) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1201 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1202 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1203 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1204 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1205 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1206 = emitc.call_opaque "__runtime_buffer_arg"(%1202) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1207 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1208 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1209 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1210 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1211 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1212 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1213 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %337, %1206, %11, %1203, %1204, %1212, %1205, %1207, %1208, %1209, %1210, %1211) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1214 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1215 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1216 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %1217 = emitc.call_opaque "__runtime_buffer_arg"(%1201) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1218 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1219 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1220 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1221 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1222 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1223 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1224 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %337, %1217, %9, %1214, %1215, %1223, %1216, %1218, %1219, %1220, %1221, %1222) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1225 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1226 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1227 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %1228 = emitc.call_opaque "__Runtime_dma_createio_4"(%337, %1224, %1225, %1226, %1227) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %1229 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1230 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %1231 = emitc.call_opaque "__runtime_buffer_offset"(%1046, %1230) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1232 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1233 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1234 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1235 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1236 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1237 = emitc.call_opaque "__runtime_buffer_arg"(%1233) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1238 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1239 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1240 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1241 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1242 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1243 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1244 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %479, %1237, %11, %1234, %1235, %1243, %1236, %1238, %1239, %1240, %1241, %1242) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1245 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1246 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1247 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1248 = emitc.call_opaque "__runtime_buffer_arg"(%1232) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1249 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1250 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1251 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1252 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1253 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1254 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1255 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %479, %1248, %9, %1245, %1246, %1254, %1247, %1249, %1250, %1251, %1252, %1253) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1256 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1257 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1258 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %1259 = emitc.call_opaque "__Runtime_dma_createio_4"(%479, %1255, %1256, %1257, %1258) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    %1260 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %1261 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1262 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1263 = emitc.call_opaque "__Runtime_startio"(%arg0, %1136, %1261, %1262) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1264 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1265 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1264) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1266 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1267 = emitc.call_opaque "__runtime_buffer_offset"(%1265, %1266) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1268 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1269 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1270 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1271 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1272 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1273 = emitc.call_opaque "__runtime_buffer_arg"(%1269) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1274 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1275 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1276 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1277 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1278 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1279 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1280 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %1273, %12, %1270, %1271, %1279, %1272, %1274, %1275, %1276, %1277, %1278) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1281 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1282 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1283 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1284 = emitc.call_opaque "__runtime_buffer_arg"(%1268) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1285 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1286 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1287 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1288 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1289 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1290 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1291 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %1284, %13, %1281, %1282, %1290, %1283, %1285, %1286, %1287, %1288, %1289) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1292 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1293 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1294 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %1295 = emitc.call_opaque "__Runtime_dma_createio_4"(%91, %1291, %1292, %1293, %1294) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %1296 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1297 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1298 = emitc.call_opaque "__runtime_buffer_offset"(%1265, %1297) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1299 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1300 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1301 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1302 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1303 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1304 = emitc.call_opaque "__runtime_buffer_arg"(%1300) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1305 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1306 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1307 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1308 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1309 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1310 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1311 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %229, %1304, %12, %1301, %1302, %1310, %1303, %1305, %1306, %1307, %1308, %1309) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1312 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1313 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1314 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1315 = emitc.call_opaque "__runtime_buffer_arg"(%1299) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1316 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1317 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1318 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1319 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1320 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1321 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1322 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %229, %1315, %13, %1312, %1313, %1321, %1314, %1316, %1317, %1318, %1319, %1320) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1323 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1324 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1325 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %1326 = emitc.call_opaque "__Runtime_dma_createio_4"(%229, %1322, %1323, %1324, %1325) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %1327 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1328 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1329 = emitc.call_opaque "__runtime_buffer_offset"(%1265, %1328) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1330 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1331 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1332 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1333 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1334 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1335 = emitc.call_opaque "__runtime_buffer_arg"(%1331) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1336 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1337 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1338 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1339 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1340 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1341 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1342 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %371, %1335, %12, %1332, %1333, %1341, %1334, %1336, %1337, %1338, %1339, %1340) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1343 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1344 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1345 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1346 = emitc.call_opaque "__runtime_buffer_arg"(%1330) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1347 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1348 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1349 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1350 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1351 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1352 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1353 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %371, %1346, %13, %1343, %1344, %1352, %1345, %1347, %1348, %1349, %1350, %1351) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1354 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1355 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1356 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %1357 = emitc.call_opaque "__Runtime_dma_createio_4"(%371, %1353, %1354, %1355, %1356) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %1358 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1359 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1360 = emitc.call_opaque "__runtime_buffer_offset"(%1265, %1359) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1361 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1362 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1363 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1364 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1365 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1366 = emitc.call_opaque "__runtime_buffer_arg"(%1362) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1367 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1368 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1369 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1370 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1371 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1372 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1373 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %1366, %12, %1363, %1364, %1372, %1365, %1367, %1368, %1369, %1370, %1371) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1374 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1375 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1376 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1377 = emitc.call_opaque "__runtime_buffer_arg"(%1361) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1378 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1379 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1380 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1381 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1382 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1383 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1384 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %1377, %13, %1374, %1375, %1383, %1376, %1378, %1379, %1380, %1381, %1382) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1385 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1386 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1387 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %1388 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %1384, %1385, %1386, %1387) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    %1389 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %1390 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=1, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%1265) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %300, %2062, %14, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%300, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
      %2083 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %1391 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %1392 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1391) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, len=256, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1393 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1394 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1395 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1396 = emitc.call_opaque "__runtime_buffer_arg"(%1392) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1397 = emitc.cast %10 : i32 to i64
    %1398 = emitc.call_opaque "__runtime_buffer_offset"(%1396, %1397) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1399 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1400 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1401 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1402 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1403 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1404 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1405 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1406 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1407 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1408 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1409 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1410 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1411 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1412 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1413 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1414 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1398, %2, %1393, %1394, %1413, %1395, %1399, %1400, %1401, %1402, %1403, %1404, %1405, %1406, %1407, %1408, %1409, %1410, %1411, %1412) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1415 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1416 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1417 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1418 = emitc.call_opaque "__runtime_buffer_arg"(%1392) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1419 = emitc.cast %8 : i32 to i64
    %1420 = emitc.call_opaque "__runtime_buffer_offset"(%1418, %1419) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1421 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1422 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1423 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1424 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1425 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1426 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1427 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1428 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1429 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1430 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1431 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1432 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1433 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1434 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1435 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1436 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1420, %11, %1415, %1416, %1435, %1417, %1421, %1422, %1423, %1424, %1425, %1426, %1427, %1428, %1429, %1430, %1431, %1432, %1433, %1434) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1437 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1438 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1439 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1440 = emitc.call_opaque "__runtime_buffer_arg"(%1392) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1441 = emitc.cast %7 : i32 to i64
    %1442 = emitc.call_opaque "__runtime_buffer_offset"(%1440, %1441) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1443 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1444 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1445 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1446 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1447 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1448 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1449 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1450 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1451 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1452 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1453 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1454 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1455 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1456 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1457 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1458 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1442, %9, %1437, %1438, %1457, %1439, %1443, %1444, %1445, %1446, %1447, %1448, %1449, %1450, %1451, %1452, %1453, %1454, %1455, %1456) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=256, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1459 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1460 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1461 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1462 = emitc.call_opaque "__runtime_buffer_arg"(%1392) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1463 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1464 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1465 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1466 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1467 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1468 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1469 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1470 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1471 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1472 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1473 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1474 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1475 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1476 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1477 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1478 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1462, %12, %1459, %1460, %1477, %1461, %1463, %1464, %1465, %1466, %1467, %1468, %1469, %1470, %1471, %1472, %1473, %1474, %1475, %1476) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1479 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1480 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1481 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %300, %1479, %1481) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1482 = emitc.call_opaque "__Runtime_dma_createio_4"(%300, %1478, %1479, %1480, %1481) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1483 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1484 = emitc.call_opaque "__runtime_buffer_offset"(%1392, %1483) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1485 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1486 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1487 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1488 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1489 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1490 = emitc.call_opaque "__runtime_buffer_arg"(%1486) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1491 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1492 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1493 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1494 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1495 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1496 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1497 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %1490, %11, %1487, %1488, %1496, %1489, %1491, %1492, %1493, %1494, %1495) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %1498 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1499 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1500 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1501 = emitc.call_opaque "__runtime_buffer_arg"(%1485) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1502 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1503 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1504 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1505 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1506 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1507 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1508 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %1501, %9, %1498, %1499, %1507, %1500, %1502, %1503, %1504, %1505, %1506) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1509 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1510 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1511 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %1512 = emitc.call_opaque "__Runtime_dma_createio_4"(%91, %1508, %1509, %1510, %1511) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %1513 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1514 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %1515 = emitc.call_opaque "__runtime_buffer_offset"(%1392, %1514) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1516 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1517 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1518 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1519 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1520 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1521 = emitc.call_opaque "__runtime_buffer_arg"(%1517) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1522 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1523 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1524 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1525 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1526 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1527 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1528 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %229, %1521, %11, %1518, %1519, %1527, %1520, %1522, %1523, %1524, %1525, %1526) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %1529 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1530 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1531 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1532 = emitc.call_opaque "__runtime_buffer_arg"(%1516) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1533 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1534 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1535 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1536 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1537 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1538 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1539 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %229, %1532, %9, %1529, %1530, %1538, %1531, %1533, %1534, %1535, %1536, %1537) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1540 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1541 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1542 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %1543 = emitc.call_opaque "__Runtime_dma_createio_4"(%229, %1539, %1540, %1541, %1542) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %1544 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1545 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %1546 = emitc.call_opaque "__runtime_buffer_offset"(%1392, %1545) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1547 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1548 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1549 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1550 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1551 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1552 = emitc.call_opaque "__runtime_buffer_arg"(%1548) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1553 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1554 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1555 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1556 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1557 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1558 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1559 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %371, %1552, %11, %1549, %1550, %1558, %1551, %1553, %1554, %1555, %1556, %1557) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %1560 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1561 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1562 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1563 = emitc.call_opaque "__runtime_buffer_arg"(%1547) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1564 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1565 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1566 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1567 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1568 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1569 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1570 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %371, %1563, %9, %1560, %1561, %1569, %1562, %1564, %1565, %1566, %1567, %1568) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1571 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1572 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1573 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %1574 = emitc.call_opaque "__Runtime_dma_createio_4"(%371, %1570, %1571, %1572, %1573) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %1575 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1576 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %1577 = emitc.call_opaque "__runtime_buffer_offset"(%1392, %1576) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1578 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1579 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1580 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1581 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1582 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1583 = emitc.call_opaque "__runtime_buffer_arg"(%1579) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1584 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1585 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1586 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1587 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1588 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1589 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1590 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %1583, %11, %1580, %1581, %1589, %1582, %1584, %1585, %1586, %1587, %1588) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %1591 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1592 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1593 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %1594 = emitc.call_opaque "__runtime_buffer_arg"(%1578) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1595 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1596 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1597 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1598 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1599 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %1600 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1601 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %513, %1594, %9, %1591, %1592, %1600, %1593, %1595, %1596, %1597, %1598, %1599) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1602 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1603 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1604 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %1605 = emitc.call_opaque "__Runtime_dma_createio_4"(%513, %1601, %1602, %1603, %1604) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    %1606 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 4 for tile (2,0) */"
    %1607 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1608 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1609 = emitc.call_opaque "__Runtime_startio"(%arg0, %1482, %1607, %1608) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1610 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1611 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %1610) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1612 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1613 = emitc.call_opaque "__runtime_buffer_offset"(%1611, %1612) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1614 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1615 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1616 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1617 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1618 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1619 = emitc.call_opaque "__runtime_buffer_arg"(%1615) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1620 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1621 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1622 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1623 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1624 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1625 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1626 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %123, %1619, %12, %1616, %1617, %1625, %1618, %1620, %1621, %1622, %1623, %1624) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1627 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1628 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1629 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1630 = emitc.call_opaque "__runtime_buffer_arg"(%1614) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1631 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1632 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1633 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1634 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1635 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1636 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1637 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %123, %1630, %13, %1627, %1628, %1636, %1629, %1631, %1632, %1633, %1634, %1635) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1638 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1639 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1640 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %1641 = emitc.call_opaque "__Runtime_dma_createio_4"(%123, %1637, %1638, %1639, %1640) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %1642 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1643 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1644 = emitc.call_opaque "__runtime_buffer_offset"(%1611, %1643) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1645 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1646 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1647 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1648 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1649 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1650 = emitc.call_opaque "__runtime_buffer_arg"(%1646) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1651 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1652 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1653 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1654 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1655 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1656 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1657 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %263, %1650, %12, %1647, %1648, %1656, %1649, %1651, %1652, %1653, %1654, %1655) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1658 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1659 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1660 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1661 = emitc.call_opaque "__runtime_buffer_arg"(%1645) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1662 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1663 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1664 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1665 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1666 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1667 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1668 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %263, %1661, %13, %1658, %1659, %1667, %1660, %1662, %1663, %1664, %1665, %1666) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1669 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1670 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1671 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %1672 = emitc.call_opaque "__Runtime_dma_createio_4"(%263, %1668, %1669, %1670, %1671) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %1673 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1674 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1675 = emitc.call_opaque "__runtime_buffer_offset"(%1611, %1674) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1676 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1677 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1678 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1679 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1680 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1681 = emitc.call_opaque "__runtime_buffer_arg"(%1677) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1682 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1683 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1684 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1685 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1686 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1687 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1688 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %405, %1681, %12, %1678, %1679, %1687, %1680, %1682, %1683, %1684, %1685, %1686) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1689 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1690 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1691 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1692 = emitc.call_opaque "__runtime_buffer_arg"(%1676) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1693 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1694 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1695 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1696 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1697 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1698 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1699 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %405, %1692, %13, %1689, %1690, %1698, %1691, %1693, %1694, %1695, %1696, %1697) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1700 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1701 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1702 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %1703 = emitc.call_opaque "__Runtime_dma_createio_4"(%405, %1699, %1700, %1701, %1702) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %1704 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1705 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1706 = emitc.call_opaque "__runtime_buffer_offset"(%1611, %1705) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1707 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1708 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1709 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1710 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1711 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1712 = emitc.call_opaque "__runtime_buffer_arg"(%1708) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1713 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1714 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1715 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1716 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1717 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1718 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1719 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %547, %1712, %12, %1709, %1710, %1718, %1711, %1713, %1714, %1715, %1716, %1717) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %1720 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1721 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1722 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1723 = emitc.call_opaque "__runtime_buffer_arg"(%1707) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1724 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1725 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1726 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1727 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1728 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1729 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1730 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %547, %1723, %13, %1720, %1721, %1729, %1722, %1724, %1725, %1726, %1727, %1728) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1731 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1732 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1733 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %1734 = emitc.call_opaque "__Runtime_dma_createio_4"(%547, %1730, %1731, %1732, %1733) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    %1735 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 4 for tile (3,0) */"
    %1736 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    emitc.for %arg4 = %17 to %18 step %19 {
      %2055 = emitc.cast %arg4 : index to i32
      %2056 = emitc.mul %2055, %16 : (i32, i32) -> i32
      emitc.verbatim "/* DMA BD Config: bd_id=11, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
      %2057 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
      %2058 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2059 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2060 = emitc.call_opaque "__runtime_buffer_arg"(%1611) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
      %2061 = emitc.cast %2056 : i32 to i64
      %2062 = emitc.call_opaque "__runtime_buffer_offset"(%2060, %2061) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
      %2063 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2064 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2065 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2066 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2067 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
      %2068 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
      %2069 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2070 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2071 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
      %2072 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2073 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2074 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2075 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
      %2076 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2077 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
      %2078 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %442, %2062, %1, %2057, %2058, %2077, %2059, %2063, %2064, %2065, %2066, %2067, %2068, %2069, %2070, %2071, %2072, %2073, %2074, %2075, %2076) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
      %2079 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
      %2080 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
      %2081 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
      emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
      %2082 = emitc.call_opaque "__Runtime_dma_createio_4"(%442, %2078, %2079, %2080, %2081) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
      emitc.verbatim "/* Allocated BD ID 5 for tile (3,0) */"
      %2083 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
      %2084 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
      %2085 = emitc.call_opaque "__Runtime_startio"(%arg0, %2082, %2083, %2084) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
      emitc.verbatim "/* Wait for 1 event(s) */"
      emitc.call_opaque "__Runtime_wait"(%arg0, %2085) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    }
    %1737 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %1738 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %1737) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, len=256, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1739 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1740 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1741 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1742 = emitc.call_opaque "__runtime_buffer_arg"(%1738) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1743 = emitc.cast %10 : i32 to i64
    %1744 = emitc.call_opaque "__runtime_buffer_offset"(%1742, %1743) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1745 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1746 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1747 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1748 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1749 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1750 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1751 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1752 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1753 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1754 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1755 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1756 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1757 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1758 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1759 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1760 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1744, %1, %1739, %1740, %1759, %1741, %1745, %1746, %1747, %1748, %1749, %1750, %1751, %1752, %1753, %1754, %1755, %1756, %1757, %1758) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, len=256, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1761 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1762 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1763 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1764 = emitc.call_opaque "__runtime_buffer_arg"(%1738) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1765 = emitc.cast %8 : i32 to i64
    %1766 = emitc.call_opaque "__runtime_buffer_offset"(%1764, %1765) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1767 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1768 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1769 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1770 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1771 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1772 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1773 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1774 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1775 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1776 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1777 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1778 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1779 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1780 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1781 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1782 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1766, %6, %1761, %1762, %1781, %1763, %1767, %1768, %1769, %1770, %1771, %1772, %1773, %1774, %1775, %1776, %1777, %1778, %1779, %1780) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, len=256, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1783 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1784 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1785 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1786 = emitc.call_opaque "__runtime_buffer_arg"(%1738) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1787 = emitc.cast %7 : i32 to i64
    %1788 = emitc.call_opaque "__runtime_buffer_offset"(%1786, %1787) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1789 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1790 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1791 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1792 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1793 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1794 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1795 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1796 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1797 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1798 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1799 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1800 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1801 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1802 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1803 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1804 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1788, %5, %1783, %1784, %1803, %1785, %1789, %1790, %1791, %1792, %1793, %1794, %1795, %1796, %1797, %1798, %1799, %1800, %1801, %1802) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, len=256, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %1805 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1806 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1807 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1808 = emitc.call_opaque "__runtime_buffer_arg"(%1738) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1809 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1810 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1811 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1812 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1813 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1814 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %1815 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1816 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1817 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %1818 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1819 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %1820 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1821 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1822 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1823 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1824 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %300, %1808, %4, %1805, %1806, %1823, %1807, %1809, %1810, %1811, %1812, %1813, %1814, %1815, %1816, %1817, %1818, %1819, %1820, %1821, %1822) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1825 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1826 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1827 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %300, %1825, %1827) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %1828 = emitc.call_opaque "__Runtime_dma_createio_4"(%300, %1824, %1825, %1826, %1827) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %1829 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %1830 = emitc.call_opaque "__runtime_buffer_offset"(%1738, %1829) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1831 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1832 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1833 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1834 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1835 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1836 = emitc.call_opaque "__runtime_buffer_arg"(%1832) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1837 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1838 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1839 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1840 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1841 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1842 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1843 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %123, %1836, %11, %1833, %1834, %1842, %1835, %1837, %1838, %1839, %1840, %1841) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %1844 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1845 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1846 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1847 = emitc.call_opaque "__runtime_buffer_arg"(%1831) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1848 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1849 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1850 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1851 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1852 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %1853 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1854 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %123, %1847, %9, %1844, %1845, %1853, %1846, %1848, %1849, %1850, %1851, %1852) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1855 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1856 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1857 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %1858 = emitc.call_opaque "__Runtime_dma_createio_4"(%123, %1854, %1855, %1856, %1857) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %1859 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1860 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %1861 = emitc.call_opaque "__runtime_buffer_offset"(%1738, %1860) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1862 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1863 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1864 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1865 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1866 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1867 = emitc.call_opaque "__runtime_buffer_arg"(%1863) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1868 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1869 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1870 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1871 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1872 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1873 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1874 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %263, %1867, %11, %1864, %1865, %1873, %1866, %1868, %1869, %1870, %1871, %1872) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %1875 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1876 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1877 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %1878 = emitc.call_opaque "__runtime_buffer_arg"(%1862) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1879 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1880 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1881 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1882 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1883 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %1884 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1885 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %263, %1878, %9, %1875, %1876, %1884, %1877, %1879, %1880, %1881, %1882, %1883) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1886 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1887 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1888 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %1889 = emitc.call_opaque "__Runtime_dma_createio_4"(%263, %1885, %1886, %1887, %1888) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %1890 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1891 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %1892 = emitc.call_opaque "__runtime_buffer_offset"(%1738, %1891) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1893 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1894 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1895 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1896 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1897 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1898 = emitc.call_opaque "__runtime_buffer_arg"(%1894) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1899 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1900 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1901 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1902 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1903 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1904 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1905 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %405, %1898, %11, %1895, %1896, %1904, %1897, %1899, %1900, %1901, %1902, %1903) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %1906 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1907 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1908 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %1909 = emitc.call_opaque "__runtime_buffer_arg"(%1893) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1910 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1911 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1912 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1913 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1914 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %1915 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1916 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %405, %1909, %9, %1906, %1907, %1915, %1908, %1910, %1911, %1912, %1913, %1914) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1917 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1918 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1919 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %1920 = emitc.call_opaque "__Runtime_dma_createio_4"(%405, %1916, %1917, %1918, %1919) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %1921 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %1922 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %1923 = emitc.call_opaque "__runtime_buffer_offset"(%1738, %1922) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %1924 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %1925 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, len=256, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %1926 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1927 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1928 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1929 = emitc.call_opaque "__runtime_buffer_arg"(%1925) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1930 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1931 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1932 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1933 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1934 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1935 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1936 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %547, %1929, %11, %1926, %1927, %1935, %1928, %1930, %1931, %1932, %1933, %1934) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, len=256, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %1937 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %1938 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1939 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1940 = emitc.call_opaque "__runtime_buffer_arg"(%1924) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %1941 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1942 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %1943 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1944 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1945 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %1946 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1947 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %547, %1940, %9, %1937, %1938, %1946, %1939, %1941, %1942, %1943, %1944, %1945) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    %1948 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %1949 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1950 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %1951 = emitc.call_opaque "__Runtime_dma_createio_4"(%547, %1947, %1948, %1949, %1950) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    %1952 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    emitc.verbatim "/* Allocated BD ID 5 for tile (2,0) */"
    %1953 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %1954 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %1955 = emitc.call_opaque "__Runtime_startio"(%arg0, %1828, %1953, %1954) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %1956 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %1957 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %27, %59, %91, %123, %161, %195, %229, %263, %303, %337, %371, %405, %445, %479, %513, %547, %1956) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %1958 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %1957) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %1959 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1960 = emitc.call_opaque "__Runtime_startio"(%arg0, %55, %56, %1959) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1961 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1962 = emitc.call_opaque "__Runtime_startio"(%arg0, %87, %88, %1961) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1963 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1964 = emitc.call_opaque "__Runtime_startio"(%arg0, %119, %120, %1963) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1965 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1966 = emitc.call_opaque "__Runtime_startio"(%arg0, %151, %152, %1965) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1967 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1968 = emitc.call_opaque "__Runtime_startio"(%arg0, %191, %192, %1967) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1969 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1970 = emitc.call_opaque "__Runtime_startio"(%arg0, %225, %226, %1969) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1971 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1972 = emitc.call_opaque "__Runtime_startio"(%arg0, %259, %260, %1971) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1973 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1974 = emitc.call_opaque "__Runtime_startio"(%arg0, %293, %294, %1973) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1975 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1976 = emitc.call_opaque "__Runtime_startio"(%arg0, %333, %334, %1975) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1977 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1978 = emitc.call_opaque "__Runtime_startio"(%arg0, %367, %368, %1977) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1979 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1980 = emitc.call_opaque "__Runtime_startio"(%arg0, %401, %402, %1979) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1981 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1982 = emitc.call_opaque "__Runtime_startio"(%arg0, %435, %436, %1981) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1983 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1984 = emitc.call_opaque "__Runtime_startio"(%arg0, %475, %476, %1983) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1985 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1986 = emitc.call_opaque "__Runtime_startio"(%arg0, %509, %510, %1985) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1987 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1988 = emitc.call_opaque "__Runtime_startio"(%arg0, %543, %544, %1987) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1989 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1990 = emitc.call_opaque "__Runtime_startio"(%arg0, %577, %578, %1989) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1991 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1992 = emitc.call_opaque "__Runtime_startio"(%arg0, %609, %610, %1991) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1993 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1994 = emitc.call_opaque "__Runtime_startio"(%arg0, %638, %639, %1993) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1995 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1996 = emitc.call_opaque "__Runtime_startio"(%arg0, %667, %668, %1995) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1997 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %1998 = emitc.call_opaque "__Runtime_startio"(%arg0, %696, %697, %1997) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %1999 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2000 = emitc.call_opaque "__Runtime_startio"(%arg0, %820, %821, %1999) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2001 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2002 = emitc.call_opaque "__Runtime_startio"(%arg0, %851, %852, %2001) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2003 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2004 = emitc.call_opaque "__Runtime_startio"(%arg0, %882, %883, %2003) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2005 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2006 = emitc.call_opaque "__Runtime_startio"(%arg0, %913, %914, %2005) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2007 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2008 = emitc.call_opaque "__Runtime_startio"(%arg0, %949, %950, %2007) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2009 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2010 = emitc.call_opaque "__Runtime_startio"(%arg0, %980, %981, %2009) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2011 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2012 = emitc.call_opaque "__Runtime_startio"(%arg0, %1011, %1012, %2011) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2013 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2014 = emitc.call_opaque "__Runtime_startio"(%arg0, %1042, %1043, %2013) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2015 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2016 = emitc.call_opaque "__Runtime_startio"(%arg0, %1166, %1167, %2015) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2017 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2018 = emitc.call_opaque "__Runtime_startio"(%arg0, %1197, %1198, %2017) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2019 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2020 = emitc.call_opaque "__Runtime_startio"(%arg0, %1228, %1229, %2019) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2021 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2022 = emitc.call_opaque "__Runtime_startio"(%arg0, %1259, %1260, %2021) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2023 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2024 = emitc.call_opaque "__Runtime_startio"(%arg0, %1295, %1296, %2023) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2025 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2026 = emitc.call_opaque "__Runtime_startio"(%arg0, %1326, %1327, %2025) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2027 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2028 = emitc.call_opaque "__Runtime_startio"(%arg0, %1357, %1358, %2027) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2029 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2030 = emitc.call_opaque "__Runtime_startio"(%arg0, %1388, %1389, %2029) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2031 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2032 = emitc.call_opaque "__Runtime_startio"(%arg0, %1512, %1513, %2031) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2033 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2034 = emitc.call_opaque "__Runtime_startio"(%arg0, %1543, %1544, %2033) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2035 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2036 = emitc.call_opaque "__Runtime_startio"(%arg0, %1574, %1575, %2035) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2037 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2038 = emitc.call_opaque "__Runtime_startio"(%arg0, %1605, %1606, %2037) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2039 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2040 = emitc.call_opaque "__Runtime_startio"(%arg0, %1641, %1642, %2039) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2041 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2042 = emitc.call_opaque "__Runtime_startio"(%arg0, %1672, %1673, %2041) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2043 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2044 = emitc.call_opaque "__Runtime_startio"(%arg0, %1703, %1704, %2043) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2045 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %2046 = emitc.call_opaque "__Runtime_startio"(%arg0, %1734, %1735, %2045) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2047 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2048 = emitc.call_opaque "__Runtime_startio"(%arg0, %1858, %1859, %2047) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2049 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2050 = emitc.call_opaque "__Runtime_startio"(%arg0, %1889, %1890, %2049) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2051 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2052 = emitc.call_opaque "__Runtime_startio"(%arg0, %1920, %1921, %2051) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %2053 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %2054 = emitc.call_opaque "__Runtime_startio"(%arg0, %1951, %1952, %2053) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 5 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %1958) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %917) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1263) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1609) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %1955) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.verbatim "/* AieRt debug snapshot */"
    emitc.verbatim "{"
    emitc.verbatim "  uint8_t _dbg_io_cols[] = {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 0, 1, 2, 3, 0, 3, 0, 1, 2, 3, 0, 1, 2, 3, 1, 3, 0, 1, 2, 3, 0, 1, 2, 3, 2, 2, 0, 1, 2, 3, 0, 1, 2, 3, 3, 2, 0, 1, 2, 3};"
    emitc.verbatim "  uint8_t _dbg_io_rows[] = {3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 4, 5, 6, 0, 3, 3, 3, 3, 0, 0, 3, 3, 3, 3, 4, 4, 4, 4, 0, 0, 4, 4, 4, 4, 5, 5, 5, 5, 0, 0, 5, 5, 5, 5, 6, 6, 6, 6, 0, 0, 6, 6, 6, 6};"
    emitc.verbatim "  uint8_t _dbg_io_chs[] = {1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0};"
    emitc.verbatim "  uint8_t _dbg_io_bds[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 1, 2, 4, 4, 4, 4, 2, 2, 2, 2, 1, 7, 4, 4, 4, 4, 2, 2, 2, 2, 1, 3, 4, 4, 4, 4, 2, 2, 2, 2, 11, 8, 4, 4, 4, 4};"
    emitc.verbatim "  int _dbg_io_dirs[] = {DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_S2MM, DMA_MM2S, DMA_S2MM, DMA_MM2S, DMA_MM2S, DMA_MM2S, DMA_MM2S};"
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
