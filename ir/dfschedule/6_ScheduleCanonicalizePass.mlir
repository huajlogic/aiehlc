// Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: MIT

module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    dfschedule.launchhost @host_canonicalized
    return
  }
  dfschedule.host @host_canonicalized {
    %c4_i32 = arith.constant 4 : i32
    %c5_i32 = arith.constant 5 : i32
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
    %subview = memref.subview %arg1[0, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1]>>
    %0 = dfschedule.declaretile {col = 2 : i32, row = 0 : i32} : !dfschedule.tile
    %1 = dfschedule.config.dma_bd(%subview, %0, %c0_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 0 : i32
    } : (memref<4x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %2 = dfschedule.config.create_io(%1, %0) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %3 = dfschedule.declaretile {col = 0 : i32, row = 3 : i32} : !dfschedule.tile
    %4 = dfschedule.memref_mapping %subview : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %5 = dfschedule.bind_core_buffer(%4, %3) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %6 = dfschedule.bind_core_buffer(%4, %3) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %7 = dfschedule.config.dma_bd(%6, %3, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %8 = dfschedule.config.dma_bd(%5, %3, %c0_i32, %7) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %9 = dfschedule.config.create_io(%8, %3) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %10 = dfschedule.schedule.getbdid(%3) : (!dfschedule.tile) -> i32
    %11 = dfschedule.declaretile {col = 0 : i32, row = 4 : i32} : !dfschedule.tile
    %12 = dfschedule.memref_mapping %subview : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %13 = dfschedule.bind_core_buffer(%12, %11) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %14 = dfschedule.bind_core_buffer(%12, %11) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %15 = dfschedule.config.dma_bd(%14, %11, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %16 = dfschedule.config.dma_bd(%13, %11, %c0_i32, %15) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %17 = dfschedule.config.create_io(%16, %11) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %18 = dfschedule.schedule.getbdid(%11) : (!dfschedule.tile) -> i32
    %19 = dfschedule.declaretile {col = 0 : i32, row = 5 : i32} : !dfschedule.tile
    %20 = dfschedule.memref_mapping %subview : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %21 = dfschedule.bind_core_buffer(%20, %19) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %22 = dfschedule.bind_core_buffer(%20, %19) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %23 = dfschedule.config.dma_bd(%22, %19, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %24 = dfschedule.config.dma_bd(%21, %19, %c0_i32, %23) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %25 = dfschedule.config.create_io(%24, %19) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %26 = dfschedule.schedule.getbdid(%19) : (!dfschedule.tile) -> i32
    %27 = dfschedule.declaretile {col = 0 : i32, row = 6 : i32} : !dfschedule.tile
    %28 = dfschedule.memref_mapping %subview : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %29 = dfschedule.bind_core_buffer(%28, %27) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %30 = dfschedule.bind_core_buffer(%28, %27) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %31 = dfschedule.config.dma_bd(%30, %27, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %32 = dfschedule.config.dma_bd(%29, %27, %c0_i32, %31) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %33 = dfschedule.config.create_io(%32, %27) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %34 = dfschedule.schedule.getbdid(%27) : (!dfschedule.tile) -> i32
    %35 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %subview_0 = memref.subview %arg1[4, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 64>>
    %36 = dfschedule.config.dma_bd(%subview_0, %0, %c1_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 0 : i32
    } : (memref<4x16xi8, strided<[16, 1], offset: 64>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %37 = dfschedule.config.create_io(%36, %0) {
      channel = 1,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %38 = dfschedule.declaretile {col = 1 : i32, row = 3 : i32} : !dfschedule.tile
    %subview_1 = memref.subview %subview_0[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %39 = dfschedule.memref_mapping %subview_1 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %40 = dfschedule.bind_core_buffer(%39, %38) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %41 = dfschedule.bind_core_buffer(%39, %38) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %42 = dfschedule.config.dma_bd(%41, %38, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %43 = dfschedule.config.dma_bd(%40, %38, %c0_i32, %42) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %44 = dfschedule.config.create_io(%43, %38) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %45 = dfschedule.schedule.getbdid(%38) : (!dfschedule.tile) -> i32
    %46 = dfschedule.declaretile {col = 1 : i32, row = 4 : i32} : !dfschedule.tile
    %subview_2 = memref.subview %subview_0[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %47 = dfschedule.memref_mapping %subview_2 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %48 = dfschedule.bind_core_buffer(%47, %46) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %49 = dfschedule.bind_core_buffer(%47, %46) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %50 = dfschedule.config.dma_bd(%49, %46, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %51 = dfschedule.config.dma_bd(%48, %46, %c0_i32, %50) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %52 = dfschedule.config.create_io(%51, %46) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %53 = dfschedule.schedule.getbdid(%46) : (!dfschedule.tile) -> i32
    %54 = dfschedule.declaretile {col = 1 : i32, row = 5 : i32} : !dfschedule.tile
    %subview_3 = memref.subview %subview_0[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %55 = dfschedule.memref_mapping %subview_3 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %56 = dfschedule.bind_core_buffer(%55, %54) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %57 = dfschedule.bind_core_buffer(%55, %54) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %58 = dfschedule.config.dma_bd(%57, %54, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %59 = dfschedule.config.dma_bd(%56, %54, %c0_i32, %58) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %60 = dfschedule.config.create_io(%59, %54) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %61 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
    %62 = dfschedule.declaretile {col = 1 : i32, row = 6 : i32} : !dfschedule.tile
    %subview_4 = memref.subview %subview_0[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %63 = dfschedule.memref_mapping %subview_4 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %64 = dfschedule.bind_core_buffer(%63, %62) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %65 = dfschedule.bind_core_buffer(%63, %62) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %66 = dfschedule.config.dma_bd(%65, %62, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %67 = dfschedule.config.dma_bd(%64, %62, %c0_i32, %66) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %68 = dfschedule.config.create_io(%67, %62) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %69 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
    %70 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %subview_5 = memref.subview %arg1[8, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %71 = dfschedule.declaretile {col = 3 : i32, row = 0 : i32} : !dfschedule.tile
    %72 = dfschedule.config.dma_bd(%subview_5, %71, %c0_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 0 : i32
    } : (memref<4x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %73 = dfschedule.config.create_io(%72, %71) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %74 = dfschedule.declaretile {col = 2 : i32, row = 3 : i32} : !dfschedule.tile
    %subview_6 = memref.subview %subview_5[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %75 = dfschedule.memref_mapping %subview_6 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %76 = dfschedule.bind_core_buffer(%75, %74) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %77 = dfschedule.bind_core_buffer(%75, %74) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %78 = dfschedule.config.dma_bd(%77, %74, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %79 = dfschedule.config.dma_bd(%76, %74, %c0_i32, %78) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %80 = dfschedule.config.create_io(%79, %74) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %81 = dfschedule.schedule.getbdid(%74) : (!dfschedule.tile) -> i32
    %82 = dfschedule.declaretile {col = 2 : i32, row = 4 : i32} : !dfschedule.tile
    %subview_7 = memref.subview %subview_5[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %83 = dfschedule.memref_mapping %subview_7 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %84 = dfschedule.bind_core_buffer(%83, %82) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %85 = dfschedule.bind_core_buffer(%83, %82) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %86 = dfschedule.config.dma_bd(%85, %82, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %87 = dfschedule.config.dma_bd(%84, %82, %c0_i32, %86) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %88 = dfschedule.config.create_io(%87, %82) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %89 = dfschedule.schedule.getbdid(%82) : (!dfschedule.tile) -> i32
    %90 = dfschedule.declaretile {col = 2 : i32, row = 5 : i32} : !dfschedule.tile
    %subview_8 = memref.subview %subview_5[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %91 = dfschedule.memref_mapping %subview_8 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %92 = dfschedule.bind_core_buffer(%91, %90) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %93 = dfschedule.bind_core_buffer(%91, %90) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %94 = dfschedule.config.dma_bd(%93, %90, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %95 = dfschedule.config.dma_bd(%92, %90, %c0_i32, %94) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %96 = dfschedule.config.create_io(%95, %90) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %97 = dfschedule.schedule.getbdid(%90) : (!dfschedule.tile) -> i32
    %98 = dfschedule.declaretile {col = 2 : i32, row = 6 : i32} : !dfschedule.tile
    %subview_9 = memref.subview %subview_5[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %99 = dfschedule.memref_mapping %subview_9 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %100 = dfschedule.bind_core_buffer(%99, %98) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %101 = dfschedule.bind_core_buffer(%99, %98) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %102 = dfschedule.config.dma_bd(%101, %98, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %103 = dfschedule.config.dma_bd(%100, %98, %c0_i32, %102) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %104 = dfschedule.config.create_io(%103, %98) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %105 = dfschedule.schedule.getbdid(%98) : (!dfschedule.tile) -> i32
    %106 = dfschedule.schedule.getbdid(%71) : (!dfschedule.tile) -> i32
    %subview_10 = memref.subview %arg1[12, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 192>>
    %107 = dfschedule.config.dma_bd(%subview_10, %71, %c1_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 0 : i32
    } : (memref<4x16xi8, strided<[16, 1], offset: 192>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %108 = dfschedule.config.create_io(%107, %71) {
      channel = 1,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %109 = dfschedule.declaretile {col = 3 : i32, row = 3 : i32} : !dfschedule.tile
    %subview_11 = memref.subview %subview_10[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %110 = dfschedule.memref_mapping %subview_11 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %111 = dfschedule.bind_core_buffer(%110, %109) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %112 = dfschedule.bind_core_buffer(%110, %109) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %113 = dfschedule.config.dma_bd(%112, %109, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %114 = dfschedule.config.dma_bd(%111, %109, %c0_i32, %113) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %115 = dfschedule.config.create_io(%114, %109) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %116 = dfschedule.schedule.getbdid(%109) : (!dfschedule.tile) -> i32
    %117 = dfschedule.declaretile {col = 3 : i32, row = 4 : i32} : !dfschedule.tile
    %subview_12 = memref.subview %subview_10[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %118 = dfschedule.memref_mapping %subview_12 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %119 = dfschedule.bind_core_buffer(%118, %117) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %120 = dfschedule.bind_core_buffer(%118, %117) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %121 = dfschedule.config.dma_bd(%120, %117, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %122 = dfschedule.config.dma_bd(%119, %117, %c0_i32, %121) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %123 = dfschedule.config.create_io(%122, %117) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %124 = dfschedule.schedule.getbdid(%117) : (!dfschedule.tile) -> i32
    %125 = dfschedule.declaretile {col = 3 : i32, row = 5 : i32} : !dfschedule.tile
    %subview_13 = memref.subview %subview_10[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %126 = dfschedule.memref_mapping %subview_13 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %127 = dfschedule.bind_core_buffer(%126, %125) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %128 = dfschedule.bind_core_buffer(%126, %125) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %129 = dfschedule.config.dma_bd(%128, %125, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %130 = dfschedule.config.dma_bd(%127, %125, %c0_i32, %129) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %131 = dfschedule.config.create_io(%130, %125) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %132 = dfschedule.schedule.getbdid(%125) : (!dfschedule.tile) -> i32
    %133 = dfschedule.declaretile {col = 3 : i32, row = 6 : i32} : !dfschedule.tile
    %subview_14 = memref.subview %subview_10[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %134 = dfschedule.memref_mapping %subview_14 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %135 = dfschedule.bind_core_buffer(%134, %133) {offset = 32768 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %136 = dfschedule.bind_core_buffer(%134, %133) {offset = 32800 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %137 = dfschedule.config.dma_bd(%136, %133, %c1_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 0 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %138 = dfschedule.config.dma_bd(%135, %133, %c0_i32, %137) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 1 : i32,
      acquire_lock_id = 2 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 3 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %139 = dfschedule.config.create_io(%138, %133) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %140 = dfschedule.schedule.getbdid(%133) : (!dfschedule.tile) -> i32
    %141 = dfschedule.schedule.getbdid(%71) : (!dfschedule.tile) -> i32
    %subview_15 = memref.subview %arg0[0, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1]>>
    %142 = dfschedule.declaretile {col = 6 : i32, row = 0 : i32} : !dfschedule.tile
    %143 = dfschedule.config.dma_bd(%subview_15, %142, %c0_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 1 : i32
    } : (memref<4x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %144 = dfschedule.config.create_io(%143, %142) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %145 = dfschedule.memref_mapping %subview_15 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %146 = dfschedule.bind_core_buffer(%145, %3) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %147 = dfschedule.bind_core_buffer(%145, %3) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %148 = dfschedule.config.dma_bd(%147, %3, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %149 = dfschedule.config.dma_bd(%146, %3, %c2_i32, %148) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %150 = dfschedule.config.create_io(%149, %3) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %151 = dfschedule.schedule.getbdid(%3) : (!dfschedule.tile) -> i32
    %152 = dfschedule.memref_mapping %subview_15 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %153 = dfschedule.bind_core_buffer(%152, %38) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %154 = dfschedule.bind_core_buffer(%152, %38) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %155 = dfschedule.config.dma_bd(%154, %38, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %156 = dfschedule.config.dma_bd(%153, %38, %c2_i32, %155) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %157 = dfschedule.config.create_io(%156, %38) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %158 = dfschedule.schedule.getbdid(%38) : (!dfschedule.tile) -> i32
    %159 = dfschedule.memref_mapping %subview_15 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %160 = dfschedule.bind_core_buffer(%159, %74) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %161 = dfschedule.bind_core_buffer(%159, %74) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %162 = dfschedule.config.dma_bd(%161, %74, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %163 = dfschedule.config.dma_bd(%160, %74, %c2_i32, %162) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %164 = dfschedule.config.create_io(%163, %74) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %165 = dfschedule.schedule.getbdid(%74) : (!dfschedule.tile) -> i32
    %166 = dfschedule.memref_mapping %subview_15 : (memref<4x16xi8, strided<[16, 1]>>) -> memref<4x16xi8>
    %167 = dfschedule.bind_core_buffer(%166, %109) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %168 = dfschedule.bind_core_buffer(%166, %109) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %169 = dfschedule.config.dma_bd(%168, %109, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %170 = dfschedule.config.dma_bd(%167, %109, %c2_i32, %169) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %171 = dfschedule.config.create_io(%170, %109) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %172 = dfschedule.schedule.getbdid(%109) : (!dfschedule.tile) -> i32
    %173 = dfschedule.schedule.getbdid(%142) : (!dfschedule.tile) -> i32
    %subview_16 = memref.subview %arg2[0, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1]>>
    %174 = dfschedule.config.dma_bd(%subview_16, %71, %c2_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 2 : i32,
      dim_strides = [4, 16, 4],
      dim_wraps = [1, 4, 4]
    } : (memref<4x16xi8, strided<[16, 1]>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %175 = dfschedule.config.create_io(%174, %71) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_17 = memref.subview %subview_16[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1]>>
    %176 = dfschedule.memref_mapping %subview_17 : (memref<1x16xi8, strided<[16, 1]>>) -> memref<1x16xi8>
    %177 = dfschedule.bind_core_buffer(%176, %3) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %178 = dfschedule.bind_core_buffer(%176, %3) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %179 = dfschedule.config.dma_bd(%178, %3, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 1 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %180 = dfschedule.config.dma_bd(%177, %3, %c4_i32, %179) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 1 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %181 = dfschedule.config.create_io(%180, %3) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %182 = dfschedule.schedule.getbdid(%3) : (!dfschedule.tile) -> i32
    %subview_18 = memref.subview %subview_16[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1], offset: 16>>
    %183 = dfschedule.memref_mapping %subview_18 : (memref<1x16xi8, strided<[16, 1], offset: 16>>) -> memref<1x16xi8>
    %184 = dfschedule.bind_core_buffer(%183, %38) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %185 = dfschedule.bind_core_buffer(%183, %38) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %186 = dfschedule.config.dma_bd(%185, %38, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 2 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %187 = dfschedule.config.dma_bd(%184, %38, %c4_i32, %186) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 2 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %188 = dfschedule.config.create_io(%187, %38) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %189 = dfschedule.schedule.getbdid(%38) : (!dfschedule.tile) -> i32
    %subview_19 = memref.subview %subview_16[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1], offset: 32>>
    %190 = dfschedule.memref_mapping %subview_19 : (memref<1x16xi8, strided<[16, 1], offset: 32>>) -> memref<1x16xi8>
    %191 = dfschedule.bind_core_buffer(%190, %74) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %192 = dfschedule.bind_core_buffer(%190, %74) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %193 = dfschedule.config.dma_bd(%192, %74, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 3 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %194 = dfschedule.config.dma_bd(%191, %74, %c4_i32, %193) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 3 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %195 = dfschedule.config.create_io(%194, %74) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %196 = dfschedule.schedule.getbdid(%74) : (!dfschedule.tile) -> i32
    %subview_20 = memref.subview %subview_16[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1]>> to memref<1x16xi8, strided<[16, 1], offset: 48>>
    %197 = dfschedule.memref_mapping %subview_20 : (memref<1x16xi8, strided<[16, 1], offset: 48>>) -> memref<1x16xi8>
    %198 = dfschedule.bind_core_buffer(%197, %109) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %199 = dfschedule.bind_core_buffer(%197, %109) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %200 = dfschedule.config.dma_bd(%199, %109, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 4 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %201 = dfschedule.config.dma_bd(%198, %109, %c4_i32, %200) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 4 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %202 = dfschedule.config.create_io(%201, %109) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %203 = dfschedule.schedule.getbdid(%109) : (!dfschedule.tile) -> i32
    %204 = dfschedule.schedule.getbdid(%71) : (!dfschedule.tile) -> i32
    %subview_21 = memref.subview %arg0[4, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 64>>
    %205 = dfschedule.config.dma_bd(%subview_21, %142, %c1_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 1 : i32
    } : (memref<4x16xi8, strided<[16, 1], offset: 64>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %206 = dfschedule.config.create_io(%205, %142) {
      channel = 1,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_22 = memref.subview %subview_21[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %207 = dfschedule.memref_mapping %subview_22 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %208 = dfschedule.bind_core_buffer(%207, %11) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %209 = dfschedule.bind_core_buffer(%207, %11) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %210 = dfschedule.config.dma_bd(%209, %11, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %211 = dfschedule.config.dma_bd(%208, %11, %c2_i32, %210) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %212 = dfschedule.config.create_io(%211, %11) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %213 = dfschedule.schedule.getbdid(%11) : (!dfschedule.tile) -> i32
    %subview_23 = memref.subview %subview_21[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %214 = dfschedule.memref_mapping %subview_23 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %215 = dfschedule.bind_core_buffer(%214, %46) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %216 = dfschedule.bind_core_buffer(%214, %46) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %217 = dfschedule.config.dma_bd(%216, %46, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %218 = dfschedule.config.dma_bd(%215, %46, %c2_i32, %217) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %219 = dfschedule.config.create_io(%218, %46) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %220 = dfschedule.schedule.getbdid(%46) : (!dfschedule.tile) -> i32
    %subview_24 = memref.subview %subview_21[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %221 = dfschedule.memref_mapping %subview_24 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %222 = dfschedule.bind_core_buffer(%221, %82) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %223 = dfschedule.bind_core_buffer(%221, %82) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %224 = dfschedule.config.dma_bd(%223, %82, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %225 = dfschedule.config.dma_bd(%222, %82, %c2_i32, %224) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %226 = dfschedule.config.create_io(%225, %82) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %227 = dfschedule.schedule.getbdid(%82) : (!dfschedule.tile) -> i32
    %subview_25 = memref.subview %subview_21[4, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %228 = dfschedule.memref_mapping %subview_25 : (memref<4x16xi8, strided<[16, 1], offset: 128>>) -> memref<4x16xi8>
    %229 = dfschedule.bind_core_buffer(%228, %117) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %230 = dfschedule.bind_core_buffer(%228, %117) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %231 = dfschedule.config.dma_bd(%230, %117, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %232 = dfschedule.config.dma_bd(%229, %117, %c2_i32, %231) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %233 = dfschedule.config.create_io(%232, %117) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %234 = dfschedule.schedule.getbdid(%117) : (!dfschedule.tile) -> i32
    %235 = dfschedule.schedule.getbdid(%142) : (!dfschedule.tile) -> i32
    %subview_26 = memref.subview %arg2[4, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 64>>
    %236 = dfschedule.config.dma_bd(%subview_26, %71, %c3_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 2 : i32,
      dim_strides = [4, 16, 4],
      dim_wraps = [1, 4, 4]
    } : (memref<4x16xi8, strided<[16, 1], offset: 64>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %237 = dfschedule.config.create_io(%236, %71) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_27 = memref.subview %subview_26[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 64>>
    %238 = dfschedule.memref_mapping %subview_27 : (memref<1x16xi8, strided<[16, 1], offset: 64>>) -> memref<1x16xi8>
    %239 = dfschedule.bind_core_buffer(%238, %11) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %240 = dfschedule.bind_core_buffer(%238, %11) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %241 = dfschedule.config.dma_bd(%240, %11, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 5 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %242 = dfschedule.config.dma_bd(%239, %11, %c4_i32, %241) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 5 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %243 = dfschedule.config.create_io(%242, %11) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %244 = dfschedule.schedule.getbdid(%11) : (!dfschedule.tile) -> i32
    %subview_28 = memref.subview %subview_26[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 80>>
    %245 = dfschedule.memref_mapping %subview_28 : (memref<1x16xi8, strided<[16, 1], offset: 80>>) -> memref<1x16xi8>
    %246 = dfschedule.bind_core_buffer(%245, %46) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %247 = dfschedule.bind_core_buffer(%245, %46) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %248 = dfschedule.config.dma_bd(%247, %46, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 6 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %249 = dfschedule.config.dma_bd(%246, %46, %c4_i32, %248) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 6 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %250 = dfschedule.config.create_io(%249, %46) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %251 = dfschedule.schedule.getbdid(%46) : (!dfschedule.tile) -> i32
    %subview_29 = memref.subview %subview_26[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 96>>
    %252 = dfschedule.memref_mapping %subview_29 : (memref<1x16xi8, strided<[16, 1], offset: 96>>) -> memref<1x16xi8>
    %253 = dfschedule.bind_core_buffer(%252, %82) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %254 = dfschedule.bind_core_buffer(%252, %82) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %255 = dfschedule.config.dma_bd(%254, %82, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 7 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %256 = dfschedule.config.dma_bd(%253, %82, %c4_i32, %255) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 7 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %257 = dfschedule.config.create_io(%256, %82) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %258 = dfschedule.schedule.getbdid(%82) : (!dfschedule.tile) -> i32
    %subview_30 = memref.subview %subview_26[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 64>> to memref<1x16xi8, strided<[16, 1], offset: 112>>
    %259 = dfschedule.memref_mapping %subview_30 : (memref<1x16xi8, strided<[16, 1], offset: 112>>) -> memref<1x16xi8>
    %260 = dfschedule.bind_core_buffer(%259, %117) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %261 = dfschedule.bind_core_buffer(%259, %117) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %262 = dfschedule.config.dma_bd(%261, %117, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 8 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %263 = dfschedule.config.dma_bd(%260, %117, %c4_i32, %262) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 8 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %264 = dfschedule.config.create_io(%263, %117) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %265 = dfschedule.schedule.getbdid(%117) : (!dfschedule.tile) -> i32
    %266 = dfschedule.schedule.getbdid(%71) : (!dfschedule.tile) -> i32
    %subview_31 = memref.subview %arg0[8, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %267 = dfschedule.declaretile {col = 7 : i32, row = 0 : i32} : !dfschedule.tile
    %268 = dfschedule.config.dma_bd(%subview_31, %267, %c0_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 1 : i32
    } : (memref<4x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %269 = dfschedule.config.create_io(%268, %267) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_32 = memref.subview %subview_31[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %270 = dfschedule.memref_mapping %subview_32 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %271 = dfschedule.bind_core_buffer(%270, %19) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %272 = dfschedule.bind_core_buffer(%270, %19) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %273 = dfschedule.config.dma_bd(%272, %19, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %274 = dfschedule.config.dma_bd(%271, %19, %c2_i32, %273) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %275 = dfschedule.config.create_io(%274, %19) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %276 = dfschedule.schedule.getbdid(%19) : (!dfschedule.tile) -> i32
    %subview_33 = memref.subview %subview_31[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %277 = dfschedule.memref_mapping %subview_33 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %278 = dfschedule.bind_core_buffer(%277, %54) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %279 = dfschedule.bind_core_buffer(%277, %54) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %280 = dfschedule.config.dma_bd(%279, %54, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %281 = dfschedule.config.dma_bd(%278, %54, %c2_i32, %280) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %282 = dfschedule.config.create_io(%281, %54) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %283 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
    %subview_34 = memref.subview %subview_31[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %284 = dfschedule.memref_mapping %subview_34 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %285 = dfschedule.bind_core_buffer(%284, %90) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %286 = dfschedule.bind_core_buffer(%284, %90) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %287 = dfschedule.config.dma_bd(%286, %90, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %288 = dfschedule.config.dma_bd(%285, %90, %c2_i32, %287) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %289 = dfschedule.config.create_io(%288, %90) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %290 = dfschedule.schedule.getbdid(%90) : (!dfschedule.tile) -> i32
    %subview_35 = memref.subview %subview_31[8, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<4x16xi8, strided<[16, 1], offset: 256>>
    %291 = dfschedule.memref_mapping %subview_35 : (memref<4x16xi8, strided<[16, 1], offset: 256>>) -> memref<4x16xi8>
    %292 = dfschedule.bind_core_buffer(%291, %125) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %293 = dfschedule.bind_core_buffer(%291, %125) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %294 = dfschedule.config.dma_bd(%293, %125, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %295 = dfschedule.config.dma_bd(%292, %125, %c2_i32, %294) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %296 = dfschedule.config.create_io(%295, %125) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %297 = dfschedule.schedule.getbdid(%125) : (!dfschedule.tile) -> i32
    %298 = dfschedule.schedule.getbdid(%267) : (!dfschedule.tile) -> i32
    %subview_36 = memref.subview %arg2[8, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 128>>
    %299 = dfschedule.config.dma_bd(%subview_36, %0, %c2_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 2 : i32,
      dim_strides = [4, 16, 4],
      dim_wraps = [1, 4, 4]
    } : (memref<4x16xi8, strided<[16, 1], offset: 128>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %300 = dfschedule.config.create_io(%299, %0) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_37 = memref.subview %subview_36[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 128>>
    %301 = dfschedule.memref_mapping %subview_37 : (memref<1x16xi8, strided<[16, 1], offset: 128>>) -> memref<1x16xi8>
    %302 = dfschedule.bind_core_buffer(%301, %19) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %303 = dfschedule.bind_core_buffer(%301, %19) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %304 = dfschedule.config.dma_bd(%303, %19, %c5_i32) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %305 = dfschedule.config.dma_bd(%302, %19, %c4_i32, %304) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %306 = dfschedule.config.create_io(%305, %19) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %307 = dfschedule.schedule.getbdid(%19) : (!dfschedule.tile) -> i32
    %subview_38 = memref.subview %subview_36[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 144>>
    %308 = dfschedule.memref_mapping %subview_38 : (memref<1x16xi8, strided<[16, 1], offset: 144>>) -> memref<1x16xi8>
    %309 = dfschedule.bind_core_buffer(%308, %54) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %310 = dfschedule.bind_core_buffer(%308, %54) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %311 = dfschedule.config.dma_bd(%310, %54, %c5_i32) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %312 = dfschedule.config.dma_bd(%309, %54, %c4_i32, %311) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %313 = dfschedule.config.create_io(%312, %54) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %314 = dfschedule.schedule.getbdid(%54) : (!dfschedule.tile) -> i32
    %subview_39 = memref.subview %subview_36[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 160>>
    %315 = dfschedule.memref_mapping %subview_39 : (memref<1x16xi8, strided<[16, 1], offset: 160>>) -> memref<1x16xi8>
    %316 = dfschedule.bind_core_buffer(%315, %90) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %317 = dfschedule.bind_core_buffer(%315, %90) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %318 = dfschedule.config.dma_bd(%317, %90, %c5_i32) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %319 = dfschedule.config.dma_bd(%316, %90, %c4_i32, %318) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %320 = dfschedule.config.create_io(%319, %90) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %321 = dfschedule.schedule.getbdid(%90) : (!dfschedule.tile) -> i32
    %subview_40 = memref.subview %subview_36[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 128>> to memref<1x16xi8, strided<[16, 1], offset: 176>>
    %322 = dfschedule.memref_mapping %subview_40 : (memref<1x16xi8, strided<[16, 1], offset: 176>>) -> memref<1x16xi8>
    %323 = dfschedule.bind_core_buffer(%322, %125) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %324 = dfschedule.bind_core_buffer(%322, %125) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %325 = dfschedule.config.dma_bd(%324, %125, %c5_i32) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %326 = dfschedule.config.dma_bd(%323, %125, %c4_i32, %325) {
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
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %327 = dfschedule.config.create_io(%326, %125) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %328 = dfschedule.schedule.getbdid(%125) : (!dfschedule.tile) -> i32
    %329 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %subview_41 = memref.subview %arg0[12, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 192>>
    %330 = dfschedule.config.dma_bd(%subview_41, %267, %c1_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 1 : i32
    } : (memref<4x16xi8, strided<[16, 1], offset: 192>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %331 = dfschedule.config.create_io(%330, %267) {
      channel = 1,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_42 = memref.subview %subview_41[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %332 = dfschedule.memref_mapping %subview_42 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %333 = dfschedule.bind_core_buffer(%332, %27) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %334 = dfschedule.bind_core_buffer(%332, %27) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %335 = dfschedule.config.dma_bd(%334, %27, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %336 = dfschedule.config.dma_bd(%333, %27, %c2_i32, %335) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %337 = dfschedule.config.create_io(%336, %27) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %338 = dfschedule.schedule.getbdid(%27) : (!dfschedule.tile) -> i32
    %subview_43 = memref.subview %subview_41[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %339 = dfschedule.memref_mapping %subview_43 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %340 = dfschedule.bind_core_buffer(%339, %62) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %341 = dfschedule.bind_core_buffer(%339, %62) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %342 = dfschedule.config.dma_bd(%341, %62, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %343 = dfschedule.config.dma_bd(%340, %62, %c2_i32, %342) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %344 = dfschedule.config.create_io(%343, %62) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %345 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
    %subview_44 = memref.subview %subview_41[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %346 = dfschedule.memref_mapping %subview_44 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %347 = dfschedule.bind_core_buffer(%346, %98) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %348 = dfschedule.bind_core_buffer(%346, %98) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %349 = dfschedule.config.dma_bd(%348, %98, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %350 = dfschedule.config.dma_bd(%347, %98, %c2_i32, %349) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %351 = dfschedule.config.create_io(%350, %98) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %352 = dfschedule.schedule.getbdid(%98) : (!dfschedule.tile) -> i32
    %subview_45 = memref.subview %subview_41[12, 0] [4, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<4x16xi8, strided<[16, 1], offset: 384>>
    %353 = dfschedule.memref_mapping %subview_45 : (memref<4x16xi8, strided<[16, 1], offset: 384>>) -> memref<4x16xi8>
    %354 = dfschedule.bind_core_buffer(%353, %133) {offset = 32832 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %355 = dfschedule.bind_core_buffer(%353, %133) {offset = 32864 : i64} : (memref<4x16xi8>, !dfschedule.tile) -> memref<4x16xi8>
    %356 = dfschedule.config.dma_bd(%355, %133, %c3_i32) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 2 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %357 = dfschedule.config.dma_bd(%354, %133, %c2_i32, %356) {
      offset = 0 : i32,
      len = 32 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 3 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 1 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<4x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %358 = dfschedule.config.create_io(%357, %133) {
      channel = 0,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %359 = dfschedule.schedule.getbdid(%133) : (!dfschedule.tile) -> i32
    %360 = dfschedule.schedule.getbdid(%267) : (!dfschedule.tile) -> i32
    %subview_46 = memref.subview %arg2[12, 0] [4, 16] [1, 1] : memref<16x16xi8> to memref<4x16xi8, strided<[16, 1], offset: 192>>
    %361 = dfschedule.config.dma_bd(%subview_46, %0, %c3_i32) {
      offset = 0 : i32,
      len = 64 : i32,
      enable_packet = false,
      packet_id = 0 : i32,
      next_bd = 4294967295 : i32,
      acquire_lock_id = 0 : i32,
      acquire_lock_val = 0 : i32,
      release_lock_id = 0 : i32,
      release_lock_val = 0 : i32,
      data_id = 2 : i32,
      dim_strides = [4, 16, 4],
      dim_wraps = [1, 4, 4]
    } : (memref<4x16xi8, strided<[16, 1], offset: 192>>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %362 = dfschedule.config.create_io(%361, %0) {
      channel = 1,
      direction = "S2MM",
      io_operation = "RECV"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %subview_47 = memref.subview %subview_46[0, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 192>>
    %363 = dfschedule.memref_mapping %subview_47 : (memref<1x16xi8, strided<[16, 1], offset: 192>>) -> memref<1x16xi8>
    %364 = dfschedule.bind_core_buffer(%363, %27) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %365 = dfschedule.bind_core_buffer(%363, %27) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %366 = dfschedule.config.dma_bd(%365, %27, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 13 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %367 = dfschedule.config.dma_bd(%364, %27, %c4_i32, %366) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 13 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %368 = dfschedule.config.create_io(%367, %27) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %369 = dfschedule.schedule.getbdid(%27) : (!dfschedule.tile) -> i32
    %subview_48 = memref.subview %subview_46[1, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 208>>
    %370 = dfschedule.memref_mapping %subview_48 : (memref<1x16xi8, strided<[16, 1], offset: 208>>) -> memref<1x16xi8>
    %371 = dfschedule.bind_core_buffer(%370, %62) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %372 = dfschedule.bind_core_buffer(%370, %62) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %373 = dfschedule.config.dma_bd(%372, %62, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 14 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %374 = dfschedule.config.dma_bd(%371, %62, %c4_i32, %373) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 14 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %375 = dfschedule.config.create_io(%374, %62) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %376 = dfschedule.schedule.getbdid(%62) : (!dfschedule.tile) -> i32
    %subview_49 = memref.subview %subview_46[2, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 224>>
    %377 = dfschedule.memref_mapping %subview_49 : (memref<1x16xi8, strided<[16, 1], offset: 224>>) -> memref<1x16xi8>
    %378 = dfschedule.bind_core_buffer(%377, %98) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %379 = dfschedule.bind_core_buffer(%377, %98) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %380 = dfschedule.config.dma_bd(%379, %98, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 15 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %381 = dfschedule.config.dma_bd(%378, %98, %c4_i32, %380) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 15 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %382 = dfschedule.config.create_io(%381, %98) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %383 = dfschedule.schedule.getbdid(%98) : (!dfschedule.tile) -> i32
    %subview_50 = memref.subview %subview_46[3, 0] [1, 16] [1, 1] : memref<4x16xi8, strided<[16, 1], offset: 192>> to memref<1x16xi8, strided<[16, 1], offset: 240>>
    %384 = dfschedule.memref_mapping %subview_50 : (memref<1x16xi8, strided<[16, 1], offset: 240>>) -> memref<1x16xi8>
    %385 = dfschedule.bind_core_buffer(%384, %133) {offset = 32896 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %386 = dfschedule.bind_core_buffer(%384, %133) {offset = 32928 : i64} : (memref<1x16xi8>, !dfschedule.tile) -> memref<1x16xi8>
    %387 = dfschedule.config.dma_bd(%386, %133, %c5_i32) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 16 : i32,
      next_bd = 4 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32) -> !dfschedule.bd_handle
    %388 = dfschedule.config.dma_bd(%385, %133, %c4_i32, %387) {
      offset = 0 : i32,
      len = 8 : i32,
      enable_packet = true,
      packet_id = 16 : i32,
      next_bd = 5 : i32,
      acquire_lock_id = 5 : i32,
      acquire_lock_val = -1 : i32,
      release_lock_id = 4 : i32,
      release_lock_val = 1 : i32,
      data_id = -1 : i32
    } : (memref<1x16xi8>, !dfschedule.tile, i32, !dfschedule.bd_handle) -> !dfschedule.bd_handle
    %389 = dfschedule.config.create_io(%388, %133) {
      channel = 0,
      direction = "MM2S",
      io_operation = "SEND"
    } : (!dfschedule.bd_handle, !dfschedule.tile) -> !dfschedule.io_handle
    %390 = dfschedule.schedule.getbdid(%133) : (!dfschedule.tile) -> i32
    %391 = dfschedule.schedule.getbdid(%0) : (!dfschedule.tile) -> i32
    %392 = dfschedule.declare_kernel_config @kernelconfig_merged0 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
    %393 = dfschedule.declare_kernel_config @kernelconfig_merged1 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
    %394 = dfschedule.declare_kernel_config @kernelconfig_merged2 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
    %395 = dfschedule.declare_kernel_config @kernelconfig_merged3 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 0 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
    %396 = dfschedule.declare_kernel_config @kernelconfig_merged4 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
    %397 = dfschedule.declare_kernel_config @kernelconfig_merged5 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
    %398 = dfschedule.declare_kernel_config @kernelconfig_merged6 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
    %399 = dfschedule.declare_kernel_config @kernelconfig_merged7 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 1 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
    %400 = dfschedule.declare_kernel_config @kernelconfig_merged8 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
    %401 = dfschedule.declare_kernel_config @kernelconfig_merged9 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
    %402 = dfschedule.declare_kernel_config @kernelconfig_merged10 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
    %403 = dfschedule.declare_kernel_config @kernelconfig_merged11 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 2 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
    %404 = dfschedule.declare_kernel_config @kernelconfig_merged12 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 0 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 0 : i32, release_lock_id = 3 : i32, tile_index = 0 : i32}]}
    %405 = dfschedule.declare_kernel_config @kernelconfig_merged13 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 16 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 1 : i32, release_lock_id = 3 : i32, tile_index = 1 : i32}]}
    %406 = dfschedule.declare_kernel_config @kernelconfig_merged14 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 32 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 2 : i32, release_lock_id = 3 : i32, tile_index = 2 : i32}]}
    %407 = dfschedule.declare_kernel_config @kernelconfig_merged15 {tile_configs = [{acquire_lock_id = 2 : i32, buffer_mode = 1 : i32, buffer_offset = 48 : i32, buffer_size = 32 : i32, dma_channel = 1 : i32, element_size = 1 : i32, flow_index = 3 : i32, num_buffers = 2 : i32, num_iterations = 2 : i32, packet_id = 3 : i32, release_lock_id = 3 : i32, tile_index = 3 : i32}]}
    %408 = dfschedule.config.load_kernel_group(%3, %11, %19, %27, %38, %46, %54, %62, %74, %82, %90, %98, %109, %117, %125, %133) {
      callee = [@dskernel_receiver],
      distributed_compute_kernel_args = [@compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0, @compute0],
      distributed_args = [@kernelconfig_merged0, @kernelconfig_merged1, @kernelconfig_merged2, @kernelconfig_merged3, @kernelconfig_merged4, @kernelconfig_merged5, @kernelconfig_merged6, @kernelconfig_merged7, @kernelconfig_merged8, @kernelconfig_merged9, @kernelconfig_merged10, @kernelconfig_merged11, @kernelconfig_merged12, @kernelconfig_merged13, @kernelconfig_merged14, @kernelconfig_merged15]
    } : (!dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile, !dfschedule.tile) -> !dfschedule.kernelgroup
    %409 = dfschedule.schedule.launch_kernel_group(%408) : (!dfschedule.kernelgroup) -> !dfschedule.event
    %410 = dfschedule.schedule.start_io(%9, %10) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %411 = dfschedule.schedule.start_io(%17, %18) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %412 = dfschedule.schedule.start_io(%25, %26) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %413 = dfschedule.schedule.start_io(%33, %34) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %414 = dfschedule.schedule.start_io(%2, %35) {flow_index = 0 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %415 = dfschedule.schedule.start_io(%44, %45) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %416 = dfschedule.schedule.start_io(%52, %53) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %417 = dfschedule.schedule.start_io(%60, %61) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %418 = dfschedule.schedule.start_io(%68, %69) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %419 = dfschedule.schedule.start_io(%37, %70) {flow_index = 1 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %420 = dfschedule.schedule.start_io(%80, %81) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %421 = dfschedule.schedule.start_io(%88, %89) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %422 = dfschedule.schedule.start_io(%96, %97) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %423 = dfschedule.schedule.start_io(%104, %105) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %424 = dfschedule.schedule.start_io(%73, %106) {flow_index = 2 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %425 = dfschedule.schedule.start_io(%115, %116) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %426 = dfschedule.schedule.start_io(%123, %124) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %427 = dfschedule.schedule.start_io(%131, %132) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %428 = dfschedule.schedule.start_io(%139, %140) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %429 = dfschedule.schedule.start_io(%108, %141) {flow_index = 3 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %430 = dfschedule.schedule.start_io(%150, %151) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %431 = dfschedule.schedule.start_io(%157, %158) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %432 = dfschedule.schedule.start_io(%164, %165) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %433 = dfschedule.schedule.start_io(%171, %172) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %434 = dfschedule.schedule.start_io(%144, %173) {flow_index = 4 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %435 = dfschedule.schedule.start_io(%181, %182) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %436 = dfschedule.schedule.start_io(%188, %189) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %437 = dfschedule.schedule.start_io(%195, %196) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %438 = dfschedule.schedule.start_io(%202, %203) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %439 = dfschedule.schedule.start_io(%175, %204) {flow_index = 5 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %440 = dfschedule.schedule.start_io(%212, %213) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %441 = dfschedule.schedule.start_io(%219, %220) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %442 = dfschedule.schedule.start_io(%226, %227) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %443 = dfschedule.schedule.start_io(%233, %234) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %444 = dfschedule.schedule.start_io(%206, %235) {flow_index = 6 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %445 = dfschedule.schedule.start_io(%243, %244) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %446 = dfschedule.schedule.start_io(%250, %251) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %447 = dfschedule.schedule.start_io(%257, %258) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %448 = dfschedule.schedule.start_io(%264, %265) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %449 = dfschedule.schedule.start_io(%237, %266) {flow_index = 7 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %450 = dfschedule.schedule.start_io(%275, %276) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %451 = dfschedule.schedule.start_io(%282, %283) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %452 = dfschedule.schedule.start_io(%289, %290) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %453 = dfschedule.schedule.start_io(%296, %297) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %454 = dfschedule.schedule.start_io(%269, %298) {flow_index = 8 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %455 = dfschedule.schedule.start_io(%306, %307) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %456 = dfschedule.schedule.start_io(%313, %314) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %457 = dfschedule.schedule.start_io(%320, %321) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %458 = dfschedule.schedule.start_io(%327, %328) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %459 = dfschedule.schedule.start_io(%300, %329) {flow_index = 9 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %460 = dfschedule.schedule.start_io(%337, %338) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %461 = dfschedule.schedule.start_io(%344, %345) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %462 = dfschedule.schedule.start_io(%351, %352) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %463 = dfschedule.schedule.start_io(%358, %359) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %464 = dfschedule.schedule.start_io(%331, %360) {flow_index = 10 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %465 = dfschedule.schedule.start_io(%368, %369) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %466 = dfschedule.schedule.start_io(%375, %376) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %467 = dfschedule.schedule.start_io(%382, %383) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %468 = dfschedule.schedule.start_io(%389, %390) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    %469 = dfschedule.schedule.start_io(%362, %391) {flow_index = 11 : i32} : (!dfschedule.io_handle, i32) -> !dfschedule.event
    dfschedule.schedule.wait(%409, %414, %419, %424, %429, %434, %439, %444, %449, %454, %459, %464, %469) : (!dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event, !dfschedule.event)
  }
  dfschedule.dskernel_receiver @dskernel_receiver {
  }
}
