module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    dfschedule.launchhost @host_canonicalized
    return
  }
  dfschedule.host @host_canonicalized {
    %c4_i32 = arith.constant 4 : i32
    %c5_i32 = arith.constant 5 : i32
    %c2_i32 = arith.constant 2 : i32
    %c3_i32 = arith.constant 3 : i32
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
    %subview = memref.subview %arg0[0, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1]>>
    %0 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
    %1 = dfschedule.config.dma_bd(%subview, %0, %c0_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 0 : i32
    } : (memref<8x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %2 = dfschedule.config.create_io(%1, %0) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %3 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
    %4 = dfschedule.memref_mapping %subview : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
    %5 = dfschedule.bind_core_buffer(%4, %3) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %6 = dfschedule.bind_core_buffer(%4, %3) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %7 = dfschedule.config.dma_bd(%6, %3, %c1_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %8 = dfschedule.config.dma_bd(%5, %3, %c0_i32, %7) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %9 = dfschedule.config.create_io(%8, %3) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %10 = dfschedule.schedule.getbdid(%3) : (!dfschedule.tile) -> i32
    %11 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
    %12 = dfschedule.memref_mapping %subview : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
    %13 = dfschedule.bind_core_buffer(%12, %11) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %14 = dfschedule.bind_core_buffer(%12, %11) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %15 = dfschedule.config.dma_bd(%14, %11, %c1_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %16 = dfschedule.config.dma_bd(%13, %11, %c0_i32, %15) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %17 = dfschedule.config.create_io(%16, %11) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %18 = dfschedule.schedule.getbdid(%11) : (!dfschedule.tile) -> i32
    %19 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %subview_0 = memref.subview %arg0[8, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1], offset: 128>>
    %20 = dfschedule.config.dma_bd(%subview_0, %0, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 0 : i32
    } : (memref<8x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %21 = dfschedule.config.create_io(%20, %0) {
      channel = 1,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %22 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
    %subview_1 = memref.subview %subview_0[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
    %23 = dfschedule.memref_mapping %subview_1 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
    %24 = dfschedule.bind_core_buffer(%23, %22) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %25 = dfschedule.bind_core_buffer(%23, %22) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %26 = dfschedule.config.dma_bd(%25, %22, %c1_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %27 = dfschedule.config.dma_bd(%24, %22, %c0_i32, %26) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %28 = dfschedule.config.create_io(%27, %22) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %29 = dfschedule.schedule.getbdid(%22) : (!dfschedule.tile) -> i32
    %30 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
    %subview_2 = memref.subview %subview_0[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
    %31 = dfschedule.memref_mapping %subview_2 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
    %32 = dfschedule.bind_core_buffer(%31, %30) {offset = 32768 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %33 = dfschedule.bind_core_buffer(%31, %30) {offset = 32832 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %34 = dfschedule.config.dma_bd(%33, %30, %c1_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %35 = dfschedule.config.dma_bd(%32, %30, %c0_i32, %34) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %36 = dfschedule.config.create_io(%35, %30) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %37 = dfschedule.schedule.getbdid(%30) : (!dfschedule.tile) -> i32
    %38 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %subview_3 = memref.subview %arg1[0, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1]>>
    %39 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
    %40 = dfschedule.config.dma_bd(%subview_3, %39, %c0_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 1 : i32
    } : (memref<8x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %41 = dfschedule.config.create_io(%40, %39) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %42 = dfschedule.memref_mapping %subview_3 : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
    %43 = dfschedule.bind_core_buffer(%42, %3) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %44 = dfschedule.bind_core_buffer(%42, %3) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %45 = dfschedule.config.dma_bd(%44, %3, %c3_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %46 = dfschedule.config.dma_bd(%43, %3, %c2_i32, %45) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %47 = dfschedule.config.create_io(%46, %3) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %48 = dfschedule.schedule.getbdid(%3) : (!dfschedule.tile) -> i32
    %49 = dfschedule.memref_mapping %subview_3 : (memref<8x16xi8, strided<[16, 1]>>) -> memref<8x16xi8>
    %50 = dfschedule.bind_core_buffer(%49, %11) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %51 = dfschedule.bind_core_buffer(%49, %11) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %52 = dfschedule.config.dma_bd(%51, %11, %c3_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %53 = dfschedule.config.dma_bd(%50, %11, %c2_i32, %52) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %54 = dfschedule.config.create_io(%53, %11) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %55 = dfschedule.schedule.getbdid(%11) : (!dfschedule.tile) -> i32
    %56 = dfschedule.schedule.getbdid(%39) : (!dfschedule.tile) -> i32
    %subview_4 = memref.subview %arg1[8, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1], offset: 128>>
    %57 = dfschedule.config.dma_bd(%subview_4, %39, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 1 : i32
    } : (memref<8x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %58 = dfschedule.config.create_io(%57, %39) {
      channel = 1,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_5 = memref.subview %subview_4[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
    %59 = dfschedule.memref_mapping %subview_5 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
    %60 = dfschedule.bind_core_buffer(%59, %22) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %61 = dfschedule.bind_core_buffer(%59, %22) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %62 = dfschedule.config.dma_bd(%61, %22, %c3_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %63 = dfschedule.config.dma_bd(%60, %22, %c2_i32, %62) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %64 = dfschedule.config.create_io(%63, %22) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %65 = dfschedule.schedule.getbdid(%22) : (!dfschedule.tile) -> i32
    %subview_6 = memref.subview %subview_4[8, 0] [8, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<8x16xi8, strided<[16, 1], offset: 256>>
    %66 = dfschedule.memref_mapping %subview_6 : (memref<8x16xi8, strided<[16, 1], offset: 256>>) -> memref<8x16xi8>
    %67 = dfschedule.bind_core_buffer(%66, %30) {offset = 32896 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %68 = dfschedule.bind_core_buffer(%66, %30) {offset = 32960 : i64} : (memref<8x16xi8>, !dfschedule.tile) -> memref<8x16xi8>
    %69 = dfschedule.config.dma_bd(%68, %30, %c3_i32) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %70 = dfschedule.config.dma_bd(%67, %30, %c2_i32, %69) {
      offset = 0 : i32,
      len = 16 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<8x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %71 = dfschedule.config.create_io(%70, %30) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %72 = dfschedule.schedule.getbdid(%30) : (!dfschedule.tile) -> i32
    %73 = dfschedule.schedule.getbdid(%39) : (!dfschedule.tile) -> i32
    %subview_7 = memref.subview %arg2[0, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1]>>
    %74 = dfschedule.config.dma_bd(%subview_7, %0, %c2_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 2 : i32
    } : (memref<8x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %75 = dfschedule.config.create_io(%74, %0) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_8 = memref.subview %subview_7[0, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1]>>
    %76 = dfschedule.memref_mapping %subview_8 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %77 = dfschedule.bind_core_buffer(%76, %3) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %78 = dfschedule.bind_core_buffer(%76, %3) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %79 = dfschedule.config.dma_bd(%78, %3, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 9 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %80 = dfschedule.config.dma_bd(%77, %3, %c4_i32, %79) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 9 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %81 = dfschedule.config.create_io(%80, %3) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %82 = dfschedule.schedule.getbdid(%3) : (!dfschedule.tile) -> i32
    %subview_9 = memref.subview %subview_7[4, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1]>> to memref<4x16xi8, strided<[16, 1], offset: 64>>
    %83 = dfschedule.memref_mapping %subview_9 : (memref<4x16xi8, strided<[16, 1], offset: 64>>) -> memref<4x16xi8>
    %84 = dfschedule.bind_core_buffer(%83, %11) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %85 = dfschedule.bind_core_buffer(%83, %11) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %86 = dfschedule.config.dma_bd(%85, %11, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 10 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %87 = dfschedule.config.dma_bd(%84, %11, %c4_i32, %86) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 10 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %88 = dfschedule.config.create_io(%87, %11) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %89 = dfschedule.schedule.getbdid(%11) : (!dfschedule.tile) -> i32
    %90 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %subview_10 = memref.subview %arg2[8, 0] [8, 16] [1, 1] : memref<16x16xi8> to memref<8x16xi8, strided<[16, 1], offset: 128>>
    %91 = dfschedule.config.dma_bd(%subview_10, %0, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 2 : i32
    } : (memref<8x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %92 = dfschedule.config.create_io(%91, %0) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_11 = memref.subview %subview_10[0, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %93 = dfschedule.memref_mapping %subview_11 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %94 = dfschedule.bind_core_buffer(%93, %22) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %95 = dfschedule.bind_core_buffer(%93, %22) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %96 = dfschedule.config.dma_bd(%95, %22, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 11 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %97 = dfschedule.config.dma_bd(%94, %22, %c4_i32, %96) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 11 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %98 = dfschedule.config.create_io(%97, %22) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %99 = dfschedule.schedule.getbdid(%22) : (!dfschedule.tile) -> i32
    %subview_12 = memref.subview %subview_10[4, 0] [4, 16] [1, 1] : memref<8x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 192>>
    %100 = dfschedule.memref_mapping %subview_12 : (memref<4x16xi8, strided<[16, 1], offset: 192>>) -> memref<4x16xi8>
    %101 = dfschedule.bind_core_buffer(%100, %30) {offset = 33024 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %102 = dfschedule.bind_core_buffer(%100, %30) {offset = 33088 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %103 = dfschedule.config.dma_bd(%102, %30, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 12 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %104 = dfschedule.config.dma_bd(%101, %30, %c4_i32, %103) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 12 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %105 = dfschedule.config.create_io(%104, %30) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %106 = dfschedule.schedule.getbdid(%30) : (!dfschedule.tile) -> i32
    %107 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %108 = dfschedule.declare_kernel_config @kernelconfig_merged0 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
    %109 = dfschedule.declare_kernel_config @kernelconfig_merged1 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
    %110 = dfschedule.declare_kernel_config @kernelconfig_merged2 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 1 : i32, tile_index = 0 : i32}]}
    %111 = dfschedule.declare_kernel_config @kernelconfig_merged3 {tile_configs = [{acquire_lock_id = 0 : i32, buffer_mode = 1 : i32, buffer_offset = 64 : i32, buffer_size = 64 : i32, dma_channel = 0 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 1 : i32, tile_index = 1 : i32}]}
    %112 = dfschedule.config.load_kernel_group(%3, %11, %22, %30) {
      callee = [@dskernel_receiver],
      distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0],
      distributed_args = [@kernelconfig_merged0, @kernelconfig_merged1, @kernelconfig_merged2, @kernelconfig_merged3]
    } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
    %113 = dfschedule.schedule.launch_kernel_group(%112) : (!dfschedule.kernelgroup) -> !dfschedule.event
    %114 = dfschedule.schedule.start_io(%9, %10) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %115 = dfschedule.schedule.start_io(%17, %18) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %116 = dfschedule.schedule.start_io(%2, %19) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %117 = dfschedule.schedule.start_io(%28, %29) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %118 = dfschedule.schedule.start_io(%36, %37) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %119 = dfschedule.schedule.start_io(%21, %38) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %120 = dfschedule.schedule.start_io(%47, %48) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %121 = dfschedule.schedule.start_io(%54, %55) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %122 = dfschedule.schedule.start_io(%41, %56) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %123 = dfschedule.schedule.start_io(%64, %65) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %124 = dfschedule.schedule.start_io(%71, %72) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %125 = dfschedule.schedule.start_io(%58, %73) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %126 = dfschedule.schedule.start_io(%81, %82) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %127 = dfschedule.schedule.start_io(%88, %89) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %128 = dfschedule.schedule.start_io(%75, %90) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %129 = dfschedule.schedule.start_io(%98, %99) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %130 = dfschedule.schedule.start_io(%105, %106) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %131 = dfschedule.schedule.start_io(%92, %107) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    dfschedule.schedule.wait(%113, %116, %119, %122, %125, %128, %131) : (!dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event)
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
