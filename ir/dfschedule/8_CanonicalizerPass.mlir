module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.effective_k = 16 : i64, routing.full_k = 64 : i64, routing.k_rounds = 4 : i64, routing.m_rounds = 4 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}, routing.tile_m = 4 : i64, routing.tile_rows = 16 : i64} {
  emitc.verbatim "#include \22aie_runtime.h\22"
  emitc.verbatim "#include \22aie_runtime_debug.h\22"
  func.func @main(%arg0: memref<64x64xi8>, %arg1: memref<64x64xi8>, %arg2: memref<64x64xi8>) {
    emitc.call_opaque "host_canonicalized"() : () -> ()
    return
  }
  emitc.func @host_canonicalized(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: !emitc.ptr<!emitc.opaque<"void">>, %arg2: !emitc.ptr<!emitc.opaque<"void">>, %arg3: !emitc.ptr<!emitc.opaque<"void">>) {
    %0 = "emitc.constant"() <{value = 13 : i32}> : () -> i32
    %1 = "emitc.constant"() <{value = 14 : i32}> : () -> i32
    %2 = "emitc.constant"() <{value = 15 : i32}> : () -> i32
    %3 = "emitc.constant"() <{value = 12 : i32}> : () -> i32
    %4 = "emitc.constant"() <{value = 768 : i64}> : () -> i64
    %5 = "emitc.constant"() <{value = 512 : i64}> : () -> i64
    %6 = "emitc.constant"() <{value = 256 : i64}> : () -> i64
    %7 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33280">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %8 = "emitc.constant"() <{value = #emitc.opaque<"(void*)33024">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %9 = "emitc.constant"() <{value = 16 : i64}> : () -> i64
    %10 = "emitc.constant"() <{value = 32 : i64}> : () -> i64
    %11 = "emitc.constant"() <{value = 32 : i32}> : () -> i32
    %12 = "emitc.constant"() <{value = 260 : i32}> : () -> i32
    %13 = "emitc.constant"() <{value = 48 : i64}> : () -> i64
    %14 = "emitc.constant"() <{value = 48 : i32}> : () -> i32
    %15 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32960">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %16 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32896">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %17 = "emitc.constant"() <{value = 3072 : i64}> : () -> i64
    %18 = "emitc.constant"() <{value = 2 : i8}> : () -> i8
    %19 = "emitc.constant"() <{value = 2048 : i64}> : () -> i64
    %20 = "emitc.constant"() <{value = 1 : i8}> : () -> i8
    %21 = "emitc.constant"() <{value = 1024 : i64}> : () -> i64
    %22 = "emitc.constant"() <{value = 6 : i8}> : () -> i8
    %23 = "emitc.constant"() <{value = 5 : i8}> : () -> i8
    %24 = "emitc.constant"() <{value = 4 : i8}> : () -> i8
    %25 = "emitc.constant"() <{value = #emitc.opaque<"DMA_S2MM">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    %26 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32832">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %27 = "emitc.constant"() <{value = #emitc.opaque<"(void*)32768">}> : () -> !emitc.ptr<!emitc.opaque<"void">>
    %28 = "emitc.constant"() <{value = 3 : i8}> : () -> i8
    %29 = "emitc.constant"() <{value = #emitc.opaque<"DMA_MM2S">}> : () -> !emitc.opaque<"XAie_DmaDirection">
    %30 = "emitc.constant"() <{value = 16 : i32}> : () -> i32
    %31 = "emitc.constant"() <{value = 64 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = -1 : i32}> : () -> i32
    %33 = "emitc.constant"() <{value = 256 : i32}> : () -> i32
    %34 = "emitc.constant"() <{value = 0 : i8}> : () -> i8
    %35 = "emitc.constant"() <{value = 0 : i64}> : () -> i64
    %36 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %37 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    %38 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %39 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %40 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %41 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %42 = "emitc.constant"() <{value = 10 : i32}> : () -> i32
    %43 = "emitc.constant"() <{value = 9 : i32}> : () -> i32
    %44 = "emitc.constant"() <{value = 8 : i32}> : () -> i32
    %45 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %46 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %47 = "emitc.constant"() <{value = 11 : i32}> : () -> i32
    %48 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_MEM_CACHEABLE">}> : () -> i32
    emitc.verbatim "XAie_DevInst* dev = v1;"
    %49 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %50 = emitc.call_opaque "XAie_TileLoc"(%34, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %51 = emitc.call_opaque "__runtime_buffer_arg"(%49) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %52 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %50, %51, %37, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(0,0), direction=MM2S */"
    %53 = emitc.call_opaque "__Runtime_dma_createio_4"(%50, %52, %37, %37, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %54 = emitc.call_opaque "XAie_TileLoc"(%34, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %55 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %56 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %54, %55, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %57 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %58 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %54, %57, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,3), direction=S2MM */"
    %59 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %58, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,3) */"
    %60 = emitc.call_opaque "XAie_TileLoc"(%34, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %61 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %62 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %60, %61, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %63 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %64 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %60, %63, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,4), direction=S2MM */"
    %65 = emitc.call_opaque "__Runtime_dma_createio_4"(%60, %64, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,4) */"
    %66 = emitc.call_opaque "XAie_TileLoc"(%34, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %67 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %68 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %66, %67, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %69 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %70 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %66, %69, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,5), direction=S2MM */"
    %71 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %70, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,5) */"
    %72 = emitc.call_opaque "XAie_TileLoc"(%34, %22) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %73 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %74 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %73, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %75 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %76 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %75, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(0,6), direction=S2MM */"
    %77 = emitc.call_opaque "__Runtime_dma_createio_4"(%72, %76, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (0,0) */"
    %78 = emitc.call_opaque "__Runtime_startio"(%arg0, %53, %37, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %79 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %80 = emitc.call_opaque "XAie_TileLoc"(%20, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %81 = emitc.call_opaque "__runtime_buffer_arg"(%79) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %82 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %80, %81, %37, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(1,0), direction=MM2S */"
    %83 = emitc.call_opaque "__Runtime_dma_createio_4"(%80, %82, %37, %37, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %84 = emitc.call_opaque "XAie_TileLoc"(%20, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %85 = emitc.call_opaque "__runtime_buffer_offset"(%79, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %86 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %87 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %84, %86, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %88 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %89 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %84, %88, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,3), direction=S2MM */"
    %90 = emitc.call_opaque "__Runtime_dma_createio_4"(%84, %89, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,3) */"
    %91 = emitc.call_opaque "XAie_TileLoc"(%20, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %92 = emitc.call_opaque "__runtime_buffer_offset"(%79, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %93 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %94 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %93, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %95 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %96 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %95, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,4), direction=S2MM */"
    %97 = emitc.call_opaque "__Runtime_dma_createio_4"(%91, %96, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,4) */"
    %98 = emitc.call_opaque "XAie_TileLoc"(%20, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %99 = emitc.call_opaque "__runtime_buffer_offset"(%79, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %100 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %101 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %98, %100, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %102 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %103 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %98, %102, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,5), direction=S2MM */"
    %104 = emitc.call_opaque "__Runtime_dma_createio_4"(%98, %103, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,5) */"
    %105 = emitc.call_opaque "XAie_TileLoc"(%20, %22) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %106 = emitc.call_opaque "__runtime_buffer_offset"(%79, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %107 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %108 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %105, %107, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %109 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %110 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %105, %109, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(1,6), direction=S2MM */"
    %111 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %110, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (1,0) */"
    %112 = emitc.call_opaque "__Runtime_startio"(%arg0, %83, %37, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %113 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %114 = emitc.call_opaque "XAie_TileLoc"(%18, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %115 = emitc.call_opaque "__runtime_buffer_arg"(%113) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %116 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %114, %115, %37, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(2,0), direction=MM2S */"
    %117 = emitc.call_opaque "__Runtime_dma_createio_4"(%114, %116, %37, %37, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %118 = emitc.call_opaque "XAie_TileLoc"(%18, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %119 = emitc.call_opaque "__runtime_buffer_offset"(%113, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %120 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %121 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %118, %120, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %122 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %123 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %118, %122, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,3), direction=S2MM */"
    %124 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %123, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,3) */"
    %125 = emitc.call_opaque "XAie_TileLoc"(%18, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %126 = emitc.call_opaque "__runtime_buffer_offset"(%113, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %127 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %128 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %125, %127, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %129 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %130 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %125, %129, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,4), direction=S2MM */"
    %131 = emitc.call_opaque "__Runtime_dma_createio_4"(%125, %130, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,4) */"
    %132 = emitc.call_opaque "XAie_TileLoc"(%18, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %133 = emitc.call_opaque "__runtime_buffer_offset"(%113, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %134 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %135 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %132, %134, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %136 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %137 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %132, %136, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,5), direction=S2MM */"
    %138 = emitc.call_opaque "__Runtime_dma_createio_4"(%132, %137, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,5) */"
    %139 = emitc.call_opaque "XAie_TileLoc"(%18, %22) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %140 = emitc.call_opaque "__runtime_buffer_offset"(%113, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %141 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %142 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %139, %141, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %143 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %144 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %139, %143, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(2,6), direction=S2MM */"
    %145 = emitc.call_opaque "__Runtime_dma_createio_4"(%139, %144, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (2,0) */"
    %146 = emitc.call_opaque "__Runtime_startio"(%arg0, %117, %37, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %147 = emitc.call_opaque "__runtime_buffer_offset"(%arg2, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %148 = emitc.call_opaque "XAie_TileLoc"(%28, %34) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %149 = emitc.call_opaque "__runtime_buffer_arg"(%147) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %150 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %148, %149, %37, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=0, tile=(3,0), direction=MM2S */"
    %151 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %150, %37, %37, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %152 = emitc.call_opaque "XAie_TileLoc"(%28, %28) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %153 = emitc.call_opaque "__runtime_buffer_offset"(%147, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %154 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %155 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %152, %154, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %156 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %157 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %152, %156, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,3), direction=S2MM */"
    %158 = emitc.call_opaque "__Runtime_dma_createio_4"(%152, %157, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,3) */"
    %159 = emitc.call_opaque "XAie_TileLoc"(%28, %24) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %160 = emitc.call_opaque "__runtime_buffer_offset"(%147, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %161 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %162 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %159, %161, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %163 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %164 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %159, %163, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,4), direction=S2MM */"
    %165 = emitc.call_opaque "__Runtime_dma_createio_4"(%159, %164, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,4) */"
    %166 = emitc.call_opaque "XAie_TileLoc"(%28, %23) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %167 = emitc.call_opaque "__runtime_buffer_offset"(%147, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %168 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %169 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %166, %168, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %170 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %171 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %166, %170, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,5), direction=S2MM */"
    %172 = emitc.call_opaque "__Runtime_dma_createio_4"(%166, %171, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,5) */"
    %173 = emitc.call_opaque "XAie_TileLoc"(%28, %22) : (i8, i8) -> !emitc.opaque<"XAie_LocType">
    %174 = emitc.call_opaque "__runtime_buffer_offset"(%147, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=0, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %175 = emitc.call_opaque "__runtime_buffer_arg"(%26) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %176 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %173, %175, %36, %31, %37, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=2 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(2, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=0, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=1, acquire_lock_id=2, acquire_lock_val=-1, release_lock_id=3, release_lock_val=1, ooo_bd_id=-1 */"
    %177 = emitc.call_opaque "__runtime_buffer_arg"(%27) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %178 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %173, %177, %37, %31, %36, %37, %37, %38, %32, %39, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=0, tile=(3,6), direction=S2MM */"
    %179 = emitc.call_opaque "__Runtime_dma_createio_4"(%173, %178, %36, %37, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 0 for tile (3,0) */"
    %180 = emitc.call_opaque "__Runtime_startio"(%arg0, %151, %37, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %181 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %182 = emitc.call_opaque "__runtime_buffer_arg"(%181) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %183 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %50, %182, %36, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(0,0), direction=MM2S */"
    %184 = emitc.call_opaque "__Runtime_dma_createio_4"(%50, %183, %36, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %185 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %186 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %54, %185, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %187 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %188 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %54, %187, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,3), direction=S2MM */"
    %189 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %188, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %190 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %191 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %84, %190, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %192 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %193 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %84, %192, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,3), direction=S2MM */"
    %194 = emitc.call_opaque "__Runtime_dma_createio_4"(%84, %193, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %195 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %196 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %118, %195, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %197 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %198 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %118, %197, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,3), direction=S2MM */"
    %199 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %198, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,3) */"
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %200 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %201 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %152, %200, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %202 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %203 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %152, %202, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,3), direction=S2MM */"
    %204 = emitc.call_opaque "__Runtime_dma_createio_4"(%152, %203, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,0) */"
    %205 = emitc.call_opaque "__Runtime_startio"(%arg0, %184, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %206 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=48, len=256, enable_packet=false, packet_id=4, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %207 = emitc.call_opaque "__runtime_buffer_arg"(%206) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %208 = emitc.call_opaque "__runtime_buffer_offset"(%207, %13) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %209 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %208, %40, %33, %32, %37, %41, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=32, len=256, enable_packet=false, packet_id=3, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %210 = emitc.call_opaque "__runtime_buffer_arg"(%206) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %211 = emitc.call_opaque "__runtime_buffer_offset"(%210, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %212 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %211, %41, %33, %32, %37, %39, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=16, len=256, enable_packet=false, packet_id=2, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %213 = emitc.call_opaque "__runtime_buffer_arg"(%206) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %214 = emitc.call_opaque "__runtime_buffer_offset"(%213, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %215 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %214, %39, %33, %32, %37, %38, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=256, enable_packet=false, packet_id=1, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %216 = emitc.call_opaque "__runtime_buffer_arg"(%206) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %217 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %216, %38, %33, %32, %37, %36, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %148, %37, %25) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %218 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %217, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %219 = emitc.call_opaque "__runtime_buffer_offset"(%206, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=1, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %220 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %221 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %54, %220, %40, %33, %41, %36, %36, %40, %32, %41, %36, %38) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=1, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=2 */"
    %222 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %223 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %54, %222, %41, %33, %40, %36, %36, %40, %32, %41, %36, %38) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,3), direction=MM2S */"
    %224 = emitc.call_opaque "__Runtime_dma_createio_4"(%54, %223, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,3) */"
    %225 = emitc.call_opaque "__runtime_buffer_offset"(%206, %6) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=2, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %226 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %227 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %84, %226, %40, %33, %41, %36, %38, %40, %32, %41, %36, %39) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=2, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %228 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %229 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %84, %228, %41, %33, %40, %36, %38, %40, %32, %41, %36, %39) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,3), direction=MM2S */"
    %230 = emitc.call_opaque "__Runtime_dma_createio_4"(%84, %229, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,3) */"
    %231 = emitc.call_opaque "__runtime_buffer_offset"(%206, %5) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=3, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %232 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %233 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %118, %232, %40, %33, %41, %36, %39, %40, %32, %41, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=3, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %234 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %235 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %118, %234, %41, %33, %40, %36, %39, %40, %32, %41, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,3), direction=MM2S */"
    %236 = emitc.call_opaque "__Runtime_dma_createio_4"(%118, %235, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,3) */"
    %237 = emitc.call_opaque "__runtime_buffer_offset"(%206, %4) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=4, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %238 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %239 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %152, %238, %40, %33, %41, %36, %41, %40, %32, %41, %36, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,3) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 3), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=4, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %240 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %241 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %152, %240, %41, %33, %40, %36, %41, %40, %32, %41, %36, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,3), direction=MM2S */"
    %242 = emitc.call_opaque "__Runtime_dma_createio_4"(%152, %241, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,3) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,0) */"
    %243 = emitc.call_opaque "__Runtime_startio"(%arg0, %218, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %244 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %245 = emitc.call_opaque "__runtime_buffer_arg"(%244) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %246 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %80, %245, %36, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(1,0), direction=MM2S */"
    %247 = emitc.call_opaque "__Runtime_dma_createio_4"(%80, %246, %36, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %248 = emitc.call_opaque "__runtime_buffer_offset"(%244, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %249 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %250 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %60, %249, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %251 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %252 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %60, %251, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,4), direction=S2MM */"
    %253 = emitc.call_opaque "__Runtime_dma_createio_4"(%60, %252, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,4) */"
    %254 = emitc.call_opaque "__runtime_buffer_offset"(%244, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %255 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %256 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %255, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %257 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %258 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %257, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,4), direction=S2MM */"
    %259 = emitc.call_opaque "__Runtime_dma_createio_4"(%91, %258, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,4) */"
    %260 = emitc.call_opaque "__runtime_buffer_offset"(%244, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %261 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %262 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %125, %261, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %263 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %264 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %125, %263, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,4), direction=S2MM */"
    %265 = emitc.call_opaque "__Runtime_dma_createio_4"(%125, %264, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,4) */"
    %266 = emitc.call_opaque "__runtime_buffer_offset"(%244, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %267 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %268 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %159, %267, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %269 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %270 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %159, %269, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,4), direction=S2MM */"
    %271 = emitc.call_opaque "__Runtime_dma_createio_4"(%159, %270, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,0) */"
    %272 = emitc.call_opaque "__Runtime_startio"(%arg0, %247, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %273 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %21) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=48, len=256, enable_packet=false, packet_id=8, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %274 = emitc.call_opaque "__runtime_buffer_arg"(%273) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %275 = emitc.call_opaque "__runtime_buffer_offset"(%274, %13) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %276 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %275, %42, %33, %32, %37, %44, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=32, len=256, enable_packet=false, packet_id=7, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %277 = emitc.call_opaque "__runtime_buffer_arg"(%273) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %278 = emitc.call_opaque "__runtime_buffer_offset"(%277, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %279 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %278, %43, %33, %32, %37, %45, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=16, len=256, enable_packet=false, packet_id=6, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %280 = emitc.call_opaque "__runtime_buffer_arg"(%273) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %281 = emitc.call_opaque "__runtime_buffer_offset"(%280, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %282 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %281, %44, %33, %32, %37, %46, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=7, offset=0, len=256, enable_packet=false, packet_id=5, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %283 = emitc.call_opaque "__runtime_buffer_arg"(%273) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %284 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %148, %283, %45, %33, %32, %37, %40, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=7, tile=(3,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(3,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %148, %36, %25) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %285 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %284, %36, %45, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %286 = emitc.call_opaque "__runtime_buffer_offset"(%273, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=5, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %287 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %288 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %60, %287, %40, %33, %41, %36, %40, %40, %32, %41, %36, %45) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=5, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=7 */"
    %289 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %290 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %60, %289, %41, %33, %40, %36, %40, %40, %32, %41, %36, %45) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,4), direction=MM2S */"
    %291 = emitc.call_opaque "__Runtime_dma_createio_4"(%60, %290, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,4) */"
    %292 = emitc.call_opaque "__runtime_buffer_offset"(%273, %6) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=6, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %293 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %294 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %293, %40, %33, %41, %36, %46, %40, %32, %41, %36, %44) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=6, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %295 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %296 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %91, %295, %41, %33, %40, %36, %46, %40, %32, %41, %36, %44) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,4), direction=MM2S */"
    %297 = emitc.call_opaque "__Runtime_dma_createio_4"(%91, %296, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,4) */"
    %298 = emitc.call_opaque "__runtime_buffer_offset"(%273, %5) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=7, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %299 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %300 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %125, %299, %40, %33, %41, %36, %45, %40, %32, %41, %36, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=7, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %301 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %302 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %125, %301, %41, %33, %40, %36, %45, %40, %32, %41, %36, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,4), direction=MM2S */"
    %303 = emitc.call_opaque "__Runtime_dma_createio_4"(%125, %302, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,4) */"
    %304 = emitc.call_opaque "__runtime_buffer_offset"(%273, %4) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=8, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %305 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %306 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %159, %305, %40, %33, %41, %36, %44, %40, %32, %41, %36, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,4) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 4), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=8, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %307 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %308 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %159, %307, %41, %33, %40, %36, %44, %40, %32, %41, %36, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,4), direction=MM2S */"
    %309 = emitc.call_opaque "__Runtime_dma_createio_4"(%159, %308, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,4) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,0) */"
    %310 = emitc.call_opaque "__Runtime_startio"(%arg0, %285, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %311 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=1, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %312 = emitc.call_opaque "__runtime_buffer_arg"(%311) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %313 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %114, %312, %36, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=1, tile=(2,0), direction=MM2S */"
    %314 = emitc.call_opaque "__Runtime_dma_createio_4"(%114, %313, %36, %36, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %315 = emitc.call_opaque "__runtime_buffer_offset"(%311, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %316 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %317 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %66, %316, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %318 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %319 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %66, %318, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,5), direction=S2MM */"
    %320 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %319, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,5) */"
    %321 = emitc.call_opaque "__runtime_buffer_offset"(%311, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %322 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %323 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %98, %322, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %324 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %325 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %98, %324, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,5), direction=S2MM */"
    %326 = emitc.call_opaque "__Runtime_dma_createio_4"(%98, %325, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,5) */"
    %327 = emitc.call_opaque "__runtime_buffer_offset"(%311, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %328 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %329 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %132, %328, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %330 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %331 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %132, %330, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,5), direction=S2MM */"
    %332 = emitc.call_opaque "__Runtime_dma_createio_4"(%132, %331, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,5) */"
    %333 = emitc.call_opaque "__runtime_buffer_offset"(%311, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %334 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %335 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %166, %334, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %336 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %337 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %166, %336, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,5), direction=S2MM */"
    %338 = emitc.call_opaque "__Runtime_dma_createio_4"(%166, %337, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,0) */"
    %339 = emitc.call_opaque "__Runtime_startio"(%arg0, %314, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %340 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %19) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=6, offset=48, len=256, enable_packet=false, packet_id=12, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %341 = emitc.call_opaque "__runtime_buffer_arg"(%340) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %342 = emitc.call_opaque "__runtime_buffer_offset"(%341, %13) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %343 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %342, %46, %33, %32, %37, %3, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=32, len=256, enable_packet=false, packet_id=11, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %344 = emitc.call_opaque "__runtime_buffer_arg"(%340) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %345 = emitc.call_opaque "__runtime_buffer_offset"(%344, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %346 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %345, %40, %33, %32, %37, %47, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=16, len=256, enable_packet=false, packet_id=10, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %347 = emitc.call_opaque "__runtime_buffer_arg"(%340) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %348 = emitc.call_opaque "__runtime_buffer_offset"(%347, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %349 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %348, %41, %33, %32, %37, %42, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=256, enable_packet=false, packet_id=9, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %350 = emitc.call_opaque "__runtime_buffer_arg"(%340) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %351 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %350, %39, %33, %32, %37, %43, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=3, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=0 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %114, %37, %25) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %352 = emitc.call_opaque "__Runtime_dma_createio_4"(%114, %351, %37, %39, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %353 = emitc.call_opaque "__runtime_buffer_offset"(%340, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=9, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %354 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %355 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %66, %354, %40, %33, %41, %36, %43, %40, %32, %41, %36, %39) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=9, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=3 */"
    %356 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %357 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %66, %356, %41, %33, %40, %36, %43, %40, %32, %41, %36, %39) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,5), direction=MM2S */"
    %358 = emitc.call_opaque "__Runtime_dma_createio_4"(%66, %357, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,5) */"
    %359 = emitc.call_opaque "__runtime_buffer_offset"(%340, %6) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=10, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %360 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %361 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %98, %360, %40, %33, %41, %36, %42, %40, %32, %41, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=10, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=4 */"
    %362 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %363 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %98, %362, %41, %33, %40, %36, %42, %40, %32, %41, %36, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,5), direction=MM2S */"
    %364 = emitc.call_opaque "__Runtime_dma_createio_4"(%98, %363, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,5) */"
    %365 = emitc.call_opaque "__runtime_buffer_offset"(%340, %5) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=11, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %366 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %367 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %132, %366, %40, %33, %41, %36, %47, %40, %32, %41, %36, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=11, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=5 */"
    %368 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %369 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %132, %368, %41, %33, %40, %36, %47, %40, %32, %41, %36, %40) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,5), direction=MM2S */"
    %370 = emitc.call_opaque "__Runtime_dma_createio_4"(%132, %369, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,5) */"
    %371 = emitc.call_opaque "__runtime_buffer_offset"(%340, %4) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=12, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %372 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %373 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %166, %372, %40, %33, %41, %36, %3, %40, %32, %41, %36, %46) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,5) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 5), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=12, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=6 */"
    %374 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %375 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %166, %374, %41, %33, %40, %36, %3, %40, %32, %41, %36, %46) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,5), direction=MM2S */"
    %376 = emitc.call_opaque "__Runtime_dma_createio_4"(%166, %375, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,5) */"
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,0) */"
    %377 = emitc.call_opaque "__Runtime_startio"(%arg0, %352, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %378 = emitc.call_opaque "__runtime_buffer_offset"(%arg1, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=0, len=256, enable_packet=false, packet_id=0, next_bd=-1, acquire_lock_id=0, acquire_lock_val=0, release_lock_id=0, release_lock_val=0, ooo_bd_id=-1 */"
    %379 = emitc.call_opaque "__runtime_buffer_arg"(%378) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %380 = emitc.call_opaque "__Runtime_dma_bd_config_multidim_ooo"(%arg0, %148, %379, %47, %33, %32, %37, %37, %37, %37, %37, %37, %32, %39, %41, %41, %31, %41, %30, %41, %33, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=11, tile=(3,0), direction=MM2S */"
    %381 = emitc.call_opaque "__Runtime_dma_createio_4"(%148, %380, %36, %47, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %382 = emitc.call_opaque "__runtime_buffer_offset"(%378, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %383 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %384 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %383, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %385 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %386 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %385, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(0,6), direction=S2MM */"
    %387 = emitc.call_opaque "__Runtime_dma_createio_4"(%72, %386, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (0,6) */"
    %388 = emitc.call_opaque "__runtime_buffer_offset"(%378, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %389 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %390 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %105, %389, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %391 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %392 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %105, %391, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(1,6), direction=S2MM */"
    %393 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %392, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (1,6) */"
    %394 = emitc.call_opaque "__runtime_buffer_offset"(%378, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %395 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %396 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %139, %395, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %397 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %398 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %139, %397, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(2,6), direction=S2MM */"
    %399 = emitc.call_opaque "__Runtime_dma_createio_4"(%139, %398, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (2,6) */"
    %400 = emitc.call_opaque "__runtime_buffer_offset"(%378, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=3, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=2, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %401 = emitc.call_opaque "__runtime_buffer_arg"(%15) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %402 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %173, %401, %39, %31, %38, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=0 init_value=2 */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(0, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=2, offset=0, len=64, enable_packet=false, packet_id=0, next_bd=3, acquire_lock_id=0, acquire_lock_val=-1, release_lock_id=1, release_lock_val=1, ooo_bd_id=-1 */"
    %403 = emitc.call_opaque "__runtime_buffer_arg"(%16) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %404 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %173, %403, %38, %31, %39, %37, %37, %37, %32, %36, %36, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=2, tile=(3,6), direction=S2MM */"
    %405 = emitc.call_opaque "__Runtime_dma_createio_4"(%173, %404, %37, %38, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 1 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (3,0) */"
    %406 = emitc.call_opaque "__Runtime_startio"(%arg0, %381, %39, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %407 = emitc.call_opaque "__runtime_buffer_offset"(%arg3, %17) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=11, offset=48, len=256, enable_packet=false, packet_id=16, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %408 = emitc.call_opaque "__runtime_buffer_arg"(%407) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %409 = emitc.call_opaque "__runtime_buffer_offset"(%408, %13) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %410 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %409, %47, %33, %32, %37, %30, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=10, offset=32, len=256, enable_packet=false, packet_id=15, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %411 = emitc.call_opaque "__runtime_buffer_arg"(%407) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %412 = emitc.call_opaque "__runtime_buffer_offset"(%411, %10) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %413 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %412, %42, %33, %32, %37, %2, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=9, offset=16, len=256, enable_packet=false, packet_id=14, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %414 = emitc.call_opaque "__runtime_buffer_arg"(%407) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %415 = emitc.call_opaque "__runtime_buffer_offset"(%414, %9) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    %416 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %415, %43, %33, %32, %37, %1, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* DMA BD Config: bd_id=8, offset=0, len=256, enable_packet=false, packet_id=13, next_bd=-1, acquire_lock_id=-1, acquire_lock_val=0, release_lock_id=-1, release_lock_val=0, ooo_bd_id=-1 */"
    %417 = emitc.call_opaque "__runtime_buffer_arg"(%407) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %418 = emitc.call_opaque "__Runtime_dma_bd_config_multidim"(%arg0, %114, %417, %44, %33, %32, %37, %0, %32, %37, %32, %37, %32, %39, %41, %36, %31, %41, %12, %41, %37, %37) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=1, bd_id=8, tile=(2,0), direction=S2MM */"
    emitc.verbatim "/* Enable out-of-order BD on tile(2,0) ch=1 dir=S2MM */"
    emitc.call_opaque "__Runtime_dma_channel_enable_ooo"(%arg0, %114, %36, %25) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32, !emitc.opaque<"XAie_DmaDirection">) -> ()
    %419 = emitc.call_opaque "__Runtime_dma_createio_4"(%114, %418, %36, %44, %25) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    %420 = emitc.call_opaque "__runtime_buffer_offset"(%407, %35) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=13, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %421 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %422 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %421, %40, %33, %41, %36, %0, %40, %32, %41, %36, %44) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(0,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(0, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=13, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=8 */"
    %423 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %424 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %72, %423, %41, %33, %40, %36, %0, %40, %32, %41, %36, %44) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(0,6), direction=MM2S */"
    %425 = emitc.call_opaque "__Runtime_dma_createio_4"(%72, %424, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (0,6) */"
    %426 = emitc.call_opaque "__runtime_buffer_offset"(%407, %6) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=14, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %427 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %428 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %105, %427, %40, %33, %41, %36, %1, %40, %32, %41, %36, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(1,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(1, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=14, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=9 */"
    %429 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %430 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %105, %429, %41, %33, %40, %36, %1, %40, %32, %41, %36, %43) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(1,6), direction=MM2S */"
    %431 = emitc.call_opaque "__Runtime_dma_createio_4"(%105, %430, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (1,6) */"
    %432 = emitc.call_opaque "__runtime_buffer_offset"(%407, %5) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=15, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %433 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %434 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %139, %433, %40, %33, %41, %36, %2, %40, %32, %41, %36, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(2,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(2, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=15, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=10 */"
    %435 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %436 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %139, %435, %41, %33, %40, %36, %2, %40, %32, %41, %36, %42) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(2,6), direction=MM2S */"
    %437 = emitc.call_opaque "__Runtime_dma_createio_4"(%139, %436, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (2,6) */"
    %438 = emitc.call_opaque "__runtime_buffer_offset"(%407, %4) : (!emitc.ptr<!emitc.opaque<"void">>, i64) -> !emitc.ptr<!emitc.opaque<"void">>
    emitc.verbatim "/* DMA BD Config: bd_id=5, offset=0, len=256, enable_packet=true, packet_id=16, next_bd=4, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %439 = emitc.call_opaque "__runtime_buffer_arg"(%7) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %440 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %173, %439, %40, %33, %41, %36, %30, %40, %32, %41, %36, %47) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Lock init: tile(3,6) lock=4 init_value=2 (kernel output acquire) */"
    emitc.verbatim "XAie_LockSetValue(dev, XAie_TileLoc(3, 6), XAie_LockInit(4, 2));"
    emitc.verbatim "/* DMA BD Config: bd_id=4, offset=0, len=256, enable_packet=true, packet_id=16, next_bd=5, acquire_lock_id=5, acquire_lock_val=-1, release_lock_id=4, release_lock_val=1, ooo_bd_id=11 */"
    %441 = emitc.call_opaque "__runtime_buffer_arg"(%8) : (!emitc.ptr<!emitc.opaque<"void">>) -> !emitc.ptr<!emitc.opaque<"void">>
    %442 = emitc.call_opaque "__Runtime_dma_bd_config"(%arg0, %173, %441, %41, %33, %40, %36, %30, %40, %32, %41, %36, %47) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<!emitc.opaque<"void">>, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) -> !emitc.opaque<"XAie_DmaDesc">
    emitc.verbatim "/* Create IO: channel_id=0, bd_id=4, tile=(3,6), direction=MM2S */"
    %443 = emitc.call_opaque "__Runtime_dma_createio_4"(%173, %442, %37, %41, %29) : (!emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_DmaDesc">, i32, i32, !emitc.opaque<"XAie_DmaDirection">) -> !emitc.opaque<"io">
    emitc.verbatim "/* Allocated BD ID 2 for tile (3,6) */"
    emitc.verbatim "/* Allocated BD ID 3 for tile (2,0) */"
    %444 = emitc.call_opaque "__Runtime_startio"(%arg0, %419, %39, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Load Kernel Group: 16 tile(s) */"
    %445 = emitc.call_opaque "__Runtime_load_kernel_group_16t"(%arg0, %54, %60, %66, %72, %84, %91, %98, %105, %118, %125, %132, %139, %152, %159, %166, %173, %30) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, !emitc.opaque<"XAie_LocType">, i32) -> !emitc.opaque<"kernel_group">
    emitc.verbatim "/* Launch Kernel Group */"
    %446 = emitc.call_opaque "__Runtime_launch_kernel_group"(%arg0, %445) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"kernel_group">) -> !emitc.opaque<"event">
    %447 = emitc.call_opaque "__Runtime_startio"(%arg0, %59, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %448 = emitc.call_opaque "__Runtime_startio"(%arg0, %65, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %449 = emitc.call_opaque "__Runtime_startio"(%arg0, %71, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %450 = emitc.call_opaque "__Runtime_startio"(%arg0, %77, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %451 = emitc.call_opaque "__Runtime_startio"(%arg0, %90, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %452 = emitc.call_opaque "__Runtime_startio"(%arg0, %97, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %453 = emitc.call_opaque "__Runtime_startio"(%arg0, %104, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %454 = emitc.call_opaque "__Runtime_startio"(%arg0, %111, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %455 = emitc.call_opaque "__Runtime_startio"(%arg0, %124, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %456 = emitc.call_opaque "__Runtime_startio"(%arg0, %131, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %457 = emitc.call_opaque "__Runtime_startio"(%arg0, %138, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %458 = emitc.call_opaque "__Runtime_startio"(%arg0, %145, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %459 = emitc.call_opaque "__Runtime_startio"(%arg0, %158, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %460 = emitc.call_opaque "__Runtime_startio"(%arg0, %165, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %461 = emitc.call_opaque "__Runtime_startio"(%arg0, %172, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %462 = emitc.call_opaque "__Runtime_startio"(%arg0, %179, %37, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %463 = emitc.call_opaque "__Runtime_startio"(%arg0, %189, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %464 = emitc.call_opaque "__Runtime_startio"(%arg0, %194, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %465 = emitc.call_opaque "__Runtime_startio"(%arg0, %199, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %466 = emitc.call_opaque "__Runtime_startio"(%arg0, %204, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %467 = emitc.call_opaque "__Runtime_startio"(%arg0, %224, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %468 = emitc.call_opaque "__Runtime_startio"(%arg0, %230, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %469 = emitc.call_opaque "__Runtime_startio"(%arg0, %236, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %470 = emitc.call_opaque "__Runtime_startio"(%arg0, %242, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %471 = emitc.call_opaque "__Runtime_startio"(%arg0, %253, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %472 = emitc.call_opaque "__Runtime_startio"(%arg0, %259, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %473 = emitc.call_opaque "__Runtime_startio"(%arg0, %265, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %474 = emitc.call_opaque "__Runtime_startio"(%arg0, %271, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %475 = emitc.call_opaque "__Runtime_startio"(%arg0, %291, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %476 = emitc.call_opaque "__Runtime_startio"(%arg0, %297, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %477 = emitc.call_opaque "__Runtime_startio"(%arg0, %303, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %478 = emitc.call_opaque "__Runtime_startio"(%arg0, %309, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %479 = emitc.call_opaque "__Runtime_startio"(%arg0, %320, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %480 = emitc.call_opaque "__Runtime_startio"(%arg0, %326, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %481 = emitc.call_opaque "__Runtime_startio"(%arg0, %332, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %482 = emitc.call_opaque "__Runtime_startio"(%arg0, %338, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %483 = emitc.call_opaque "__Runtime_startio"(%arg0, %358, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %484 = emitc.call_opaque "__Runtime_startio"(%arg0, %364, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %485 = emitc.call_opaque "__Runtime_startio"(%arg0, %370, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %486 = emitc.call_opaque "__Runtime_startio"(%arg0, %376, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %487 = emitc.call_opaque "__Runtime_startio"(%arg0, %387, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %488 = emitc.call_opaque "__Runtime_startio"(%arg0, %393, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %489 = emitc.call_opaque "__Runtime_startio"(%arg0, %399, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %490 = emitc.call_opaque "__Runtime_startio"(%arg0, %405, %36, %36) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %491 = emitc.call_opaque "__Runtime_startio"(%arg0, %425, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %492 = emitc.call_opaque "__Runtime_startio"(%arg0, %431, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %493 = emitc.call_opaque "__Runtime_startio"(%arg0, %437, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    %494 = emitc.call_opaque "__Runtime_startio"(%arg0, %443, %38, %41) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"io">, i32, i32) -> !emitc.opaque<"ioevent">
    emitc.verbatim "/* Wait for 13 event(s) */"
    emitc.call_opaque "__Runtime_wait"(%arg0, %446) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"event">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %78) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %112) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %146) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %180) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %205) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %243) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %272) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %310) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %339) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %377) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %406) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
    emitc.call_opaque "__Runtime_wait"(%arg0, %444) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"ioevent">) -> ()
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
