module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  emitc.include <"xaiengine.h">
  emitc.func private @XAie_TileLoc(i32, i32) -> !emitc.opaque<"XAie_LocType">
  emitc.func private @getOrCreateDeviceInstance() -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
  emitc.func private @XAie_EnableShimDmaToAieStrmPort(!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
  emitc.func private @XAie_EnableAieToShimDmaStrmPort(!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
  emitc.func private @XAie_StrmConnCctEnable(!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
  emitc.func private @XAie_StrmPktSwSlaveSlotEnable(!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
  emitc.func private @XAie_StrmPktSwMstrPortEnable(!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
  emitc.func private @XAie_StrmPktSwSlavePortEnable(!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
  func.func @routing(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %0 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(16, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %1 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(15, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %2 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(14, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %3 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(13, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %4 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(12, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %5 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(11, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %6 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(10, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %7 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(9, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %8 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(8, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %9 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(7, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %10 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(6, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %11 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(5, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %12 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">}> : () -> !emitc.ptr<i8>
    %13 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(4, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %14 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(3, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %15 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(2, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %16 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">}> : () -> !emitc.ptr<i8>
    %17 = "emitc.constant"() <{value = 31 : i32}> : () -> i32
    %18 = "emitc.constant"() <{value = #emitc.opaque<"NONE">}> : () -> !emitc.ptr<i8>
    %19 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(1, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %20 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(0, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %21 = "emitc.constant"() <{value = 6 : i32}> : () -> i32
    %22 = "emitc.constant"() <{value = 5 : i32}> : () -> i32
    %23 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %24 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %25 = "emitc.constant"() <{value = #emitc.opaque<"DMA">}> : () -> !emitc.ptr<i8>
    %26 = "emitc.constant"() <{value = #emitc.opaque<"EAST">}> : () -> !emitc.ptr<i8>
    %27 = "emitc.constant"() <{value = #emitc.opaque<"WEST">}> : () -> !emitc.ptr<i8>
    %28 = "emitc.constant"() <{value = #emitc.opaque<"SOUTH">}> : () -> !emitc.ptr<i8>
    %29 = "emitc.constant"() <{value = #emitc.opaque<"NORTH">}> : () -> !emitc.ptr<i8>
    %30 = "emitc.constant"() <{value = true}> : () -> i1
    %31 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %32 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %33 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %34 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %31, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%32, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%32, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %28, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %28, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %26, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%34, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %26, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %24) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %24, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%32, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%32, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %28, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%34, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %26, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %28, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %28, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %28, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %28, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 2 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %31, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%31, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%31, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %26, %34, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %32, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%34, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %32, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %28, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%34, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %28, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%34, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %28, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%33, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %27, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%33, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%32, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %27, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%32, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmConnCctEnable(%78, %77, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %80 = emitc.call @XAie_TileLoc(%31, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %81 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %82 = emitc.call @XAie_StrmConnCctEnable(%81, %80, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 3 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %24) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %24, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%31, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%31, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %26, %33, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %31, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%34, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %31, %29, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %28, %32, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%34, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %28, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%34, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %28, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%34, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %28, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%33, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %27, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%33, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%32, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmConnCctEnable(%78, %77, %27, %34, %26, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %80 = emitc.call @XAie_TileLoc(%32, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %81 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %82 = emitc.call @XAie_StrmConnCctEnable(%81, %80, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %83 = emitc.call @XAie_TileLoc(%31, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %84 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %85 = emitc.call @XAie_StrmConnCctEnable(%84, %83, %27, %34, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%21, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%21, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %31, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%21, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%21, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%21, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%22, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %26, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%23, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %34, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %26, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %26, %32, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %26, %32, %29, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %26, %32, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %28, %32, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %26, %33, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmConnCctEnable(%78, %77, %26, %34, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %80 = emitc.call @XAie_TileLoc(%34, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %81 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %82 = emitc.call @XAie_StrmConnCctEnable(%81, %80, %29, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %83 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %84 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %85 = emitc.call @XAie_StrmConnCctEnable(%84, %83, %29, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%21, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %24) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%21, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %24, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%21, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%21, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%21, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%22, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %26, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%23, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %33, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %26, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %26, %31, %29, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %28, %31, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %28, %31, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %26, %32, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %26, %32, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmConnCctEnable(%78, %77, %26, %33, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %80 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %81 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %82 = emitc.call @XAie_StrmConnCctEnable(%81, %80, %28, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 2 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%24, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%24, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %31, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%24, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%24, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%24, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%21, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %26, %34, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%22, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %32, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%23, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %32, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %26, %32, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %28, %33, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %28, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %26, %34, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %26, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %26, %31, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmConnCctEnable(%78, %77, %26, %31, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %80 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %81 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %82 = emitc.call @XAie_StrmConnCctEnable(%81, %80, %26, %32, %29, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %83 = emitc.call @XAie_TileLoc(%34, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %84 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %85 = emitc.call @XAie_StrmConnCctEnable(%84, %83, %28, %32, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %86 = emitc.call @XAie_TileLoc(%33, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %87 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %88 = emitc.call @XAie_StrmConnCctEnable(%87, %86, %28, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %89 = emitc.call @XAie_TileLoc(%32, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %90 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %91 = emitc.call @XAie_StrmConnCctEnable(%90, %89, %28, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %92 = emitc.call @XAie_TileLoc(%31, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %93 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %94 = emitc.call @XAie_StrmConnCctEnable(%93, %92, %28, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 3 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%24, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%36, %35, %24) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%24, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %28, %24, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%24, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%24, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %28, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%24, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %28, %33, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%21, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %26, %33, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_TileLoc(%22, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %54 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %55 = emitc.call @XAie_StrmConnCctEnable(%54, %53, %26, %31, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %56 = emitc.call @XAie_TileLoc(%23, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %57 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %58 = emitc.call @XAie_StrmConnCctEnable(%57, %56, %26, %31, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %59 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %60 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %61 = emitc.call @XAie_StrmConnCctEnable(%60, %59, %26, %31, %29, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %62 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %63 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %64 = emitc.call @XAie_StrmConnCctEnable(%63, %62, %28, %32, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %65 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %66 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %67 = emitc.call @XAie_StrmConnCctEnable(%66, %65, %26, %33, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %68 = emitc.call @XAie_TileLoc(%32, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %69 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %70 = emitc.call @XAie_StrmConnCctEnable(%69, %68, %28, %33, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %71 = emitc.call @XAie_TileLoc(%32, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %72 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %73 = emitc.call @XAie_StrmConnCctEnable(%72, %71, %28, %33, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %74 = emitc.call @XAie_TileLoc(%33, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %75 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %76 = emitc.call @XAie_StrmConnCctEnable(%75, %74, %26, %34, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%33, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmConnCctEnable(%78, %77, %26, %34, %29, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %80 = emitc.call @XAie_TileLoc(%34, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %81 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %82 = emitc.call @XAie_StrmConnCctEnable(%81, %80, %26, %34, %29, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %83 = emitc.call @XAie_TileLoc(%34, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %84 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %85 = emitc.call @XAie_StrmConnCctEnable(%84, %83, %28, %33, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %86 = emitc.call @XAie_TileLoc(%33, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %87 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %88 = emitc.call @XAie_StrmConnCctEnable(%87, %86, %28, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %89 = emitc.call @XAie_TileLoc(%32, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %90 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %91 = emitc.call @XAie_StrmConnCctEnable(%90, %89, %28, %34, %26, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %92 = emitc.call @XAie_TileLoc(%32, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %93 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %94 = emitc.call @XAie_StrmConnCctEnable(%93, %92, %28, %34, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %95 = emitc.call @XAie_TileLoc(%31, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %96 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %97 = emitc.call @XAie_StrmConnCctEnable(%96, %95, %27, %33, %25, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%34, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%36, %35, %25, %34, %34, %19, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %38 = emitc.call @XAie_StrmPktSwSlavePortEnable(%36, %35, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_StrmPktSwMstrPortEnable(%36, %35, %26, %34, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %40 = emitc.call @XAie_TileLoc(%33, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %41 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %42 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %27, %34, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %43 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %25, %34, %34, %15, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %45 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %46 = emitc.call @XAie_StrmPktSwMstrPortEnable(%41, %40, %26, %34, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %27, %34, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %50 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %51 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %25, %34, %34, %14, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %52 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_StrmPktSwMstrPortEnable(%48, %47, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %54 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %55 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %56 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %57 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %58 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %25, %34, %34, %13, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %59 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %60 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %61 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %62 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%61, %60, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %63 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %64 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %65 = emitc.call @XAie_StrmPktSwMstrPortEnable(%64, %63, %28, %34, %12, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %66 = emitc.call @XAie_TileLoc(%31, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %67 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %68 = emitc.call @XAie_StrmConnCctEnable(%67, %66, %29, %34, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %69 = emitc.call @XAie_TileLoc(%31, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %70 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %71 = emitc.call @XAie_StrmConnCctEnable(%70, %69, %29, %34, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %72 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %73 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %74 = emitc.call @XAie_StrmConnCctEnable(%73, %72, %29, %34, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%34, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%36, %35, %25, %34, %34, %11, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %38 = emitc.call @XAie_StrmPktSwSlavePortEnable(%36, %35, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_StrmPktSwMstrPortEnable(%36, %35, %26, %34, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %40 = emitc.call @XAie_TileLoc(%33, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %41 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %42 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %27, %34, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %43 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %25, %34, %34, %10, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %45 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %46 = emitc.call @XAie_StrmPktSwMstrPortEnable(%41, %40, %26, %34, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %27, %34, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %50 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %27, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %51 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %25, %34, %34, %9, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %52 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_StrmPktSwMstrPortEnable(%48, %47, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %54 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %55 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %56 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %57 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %58 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %25, %34, %34, %8, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %59 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %60 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %61 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %62 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%61, %60, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %63 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %64 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %65 = emitc.call @XAie_StrmPktSwMstrPortEnable(%64, %63, %28, %34, %12, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %66 = emitc.call @XAie_TileLoc(%31, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %67 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %68 = emitc.call @XAie_StrmConnCctEnable(%67, %66, %29, %34, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %69 = emitc.call @XAie_TileLoc(%31, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %70 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %71 = emitc.call @XAie_StrmConnCctEnable(%70, %69, %29, %33, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %72 = emitc.call @XAie_TileLoc(%31, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %73 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %74 = emitc.call @XAie_StrmConnCctEnable(%73, %72, %29, %33, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %75 = emitc.call @XAie_TileLoc(%31, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %76 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %77 = emitc.call @XAie_StrmConnCctEnable(%76, %75, %29, %33, %28, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 2 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%34, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%36, %35, %25, %34, %34, %7, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %38 = emitc.call @XAie_StrmPktSwSlavePortEnable(%36, %35, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_StrmPktSwMstrPortEnable(%36, %35, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %40 = emitc.call @XAie_TileLoc(%33, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %41 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %42 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %43 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %25, %34, %34, %6, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %45 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %46 = emitc.call @XAie_StrmPktSwMstrPortEnable(%41, %40, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%32, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %50 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %51 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %25, %34, %34, %5, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %52 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_StrmPktSwMstrPortEnable(%48, %47, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %54 = emitc.call @XAie_TileLoc(%31, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %55 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %56 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %57 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %58 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %25, %34, %34, %4, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %59 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %60 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %61 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %62 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%61, %60, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %63 = emitc.call @XAie_TileLoc(%31, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %64 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %65 = emitc.call @XAie_StrmPktSwMstrPortEnable(%64, %63, %28, %34, %12, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %66 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %67 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %68 = emitc.call @XAie_StrmConnCctEnable(%67, %66, %29, %34, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %69 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %70 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %71 = emitc.call @XAie_StrmConnCctEnable(%70, %69, %26, %32, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %72 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %73 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %74 = emitc.call @XAie_StrmConnCctEnable(%73, %72, %29, %34, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %75 = emitc.call @XAie_TileLoc(%32, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %76 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %77 = emitc.call @XAie_StrmConnCctEnable(%76, %75, %29, %34, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %78 = emitc.call @XAie_TileLoc(%32, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %79 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %80 = emitc.call @XAie_StrmConnCctEnable(%79, %78, %29, %34, %28, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %81 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %82 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %83 = emitc.call @XAie_StrmConnCctEnable(%82, %81, %29, %34, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 3 hw split in : row -----------"
    emitc.if %30 {
      %35 = emitc.call @XAie_TileLoc(%34, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%36, %35, %25, %34, %34, %3, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %38 = emitc.call @XAie_StrmPktSwSlavePortEnable(%36, %35, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_StrmPktSwMstrPortEnable(%36, %35, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %40 = emitc.call @XAie_TileLoc(%33, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %41 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %42 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %43 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%41, %40, %25, %34, %34, %2, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %45 = emitc.call @XAie_StrmPktSwSlavePortEnable(%41, %40, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %46 = emitc.call @XAie_StrmPktSwMstrPortEnable(%41, %40, %26, %33, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%32, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %27, %33, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %50 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %27, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %51 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%48, %47, %25, %34, %34, %1, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %52 = emitc.call @XAie_StrmPktSwSlavePortEnable(%48, %47, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %53 = emitc.call @XAie_StrmPktSwMstrPortEnable(%48, %47, %26, %32, %16, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %54 = emitc.call @XAie_TileLoc(%31, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %55 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %56 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %27, %32, %34, %20, %34, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %57 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %27, %32) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %58 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%55, %54, %25, %34, %34, %0, %17, %34, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %59 = emitc.call @XAie_StrmPktSwSlavePortEnable(%55, %54, %25, %34) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %60 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %61 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %62 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%61, %60, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %63 = emitc.call @XAie_TileLoc(%31, %21) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %64 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %65 = emitc.call @XAie_StrmPktSwMstrPortEnable(%64, %63, %28, %34, %12, %34, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %66 = emitc.call @XAie_TileLoc(%31, %22) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %67 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %68 = emitc.call @XAie_StrmConnCctEnable(%67, %66, %29, %34, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %69 = emitc.call @XAie_TileLoc(%31, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %70 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %71 = emitc.call @XAie_StrmConnCctEnable(%70, %69, %29, %33, %27, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %72 = emitc.call @XAie_TileLoc(%32, %23) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %73 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %74 = emitc.call @XAie_StrmConnCctEnable(%73, %72, %26, %31, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %75 = emitc.call @XAie_TileLoc(%32, %31) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %76 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %77 = emitc.call @XAie_StrmConnCctEnable(%76, %75, %29, %33, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %78 = emitc.call @XAie_TileLoc(%32, %32) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %79 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %80 = emitc.call @XAie_StrmConnCctEnable(%79, %78, %29, %33, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %81 = emitc.call @XAie_TileLoc(%32, %33) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %82 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %83 = emitc.call @XAie_StrmConnCctEnable(%82, %81, %29, %33, %28, %33) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %84 = emitc.call @XAie_TileLoc(%32, %34) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %85 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %86 = emitc.call @XAie_StrmConnCctEnable(%85, %84, %29, %33, %28, %31) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    return
  }
}
