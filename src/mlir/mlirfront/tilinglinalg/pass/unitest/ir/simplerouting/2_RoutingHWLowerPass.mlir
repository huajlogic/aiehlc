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
    %0 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(12, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %1 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(11, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %2 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">}> : () -> !emitc.ptr<i8>
    %3 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(10, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %4 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">}> : () -> !emitc.ptr<i8>
    %5 = "emitc.constant"() <{value = 31 : i32}> : () -> i32
    %6 = "emitc.constant"() <{value = #emitc.opaque<"NONE">}> : () -> !emitc.ptr<i8>
    %7 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(9, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %8 = "emitc.constant"() <{value = #emitc.opaque<"XAie_PacketInit(0, 0)">}> : () -> !emitc.opaque<"XAie_Packet">
    %9 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %10 = "emitc.constant"() <{value = 7 : i32}> : () -> i32
    %11 = "emitc.constant"() <{value = #emitc.opaque<"DMA">}> : () -> !emitc.ptr<i8>
    %12 = "emitc.constant"() <{value = #emitc.opaque<"EAST">}> : () -> !emitc.ptr<i8>
    %13 = "emitc.constant"() <{value = #emitc.opaque<"WEST">}> : () -> !emitc.ptr<i8>
    %14 = "emitc.constant"() <{value = #emitc.opaque<"SOUTH">}> : () -> !emitc.ptr<i8>
    %15 = "emitc.constant"() <{value = #emitc.opaque<"NORTH">}> : () -> !emitc.ptr<i8>
    %16 = "emitc.constant"() <{value = 3 : i32}> : () -> i32
    %17 = "emitc.constant"() <{value = 2 : i32}> : () -> i32
    %18 = "emitc.constant"() <{value = true}> : () -> i1
    %19 = "emitc.constant"() <{value = 1 : i32}> : () -> i32
    %20 = "emitc.constant"() <{value = 0 : i32}> : () -> i32
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %18 {
      %21 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %22 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %23 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%22, %21, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %24 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %25 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %26 = emitc.call @XAie_StrmConnCctEnable(%25, %24, %14, %16, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %27 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %28 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %29 = emitc.call @XAie_StrmConnCctEnable(%28, %27, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %31 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %32 = emitc.call @XAie_StrmConnCctEnable(%31, %30, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %33 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %34 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %35 = emitc.call @XAie_StrmConnCctEnable(%34, %33, %14, %20, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %36 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %37 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %38 = emitc.call @XAie_StrmConnCctEnable(%37, %36, %12, %20, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %40 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %41 = emitc.call @XAie_StrmConnCctEnable(%40, %39, %12, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %42 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %43 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %44 = emitc.call @XAie_StrmConnCctEnable(%43, %42, %12, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %18 {
      %21 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %22 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %23 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%22, %21, %10) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %24 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %25 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %26 = emitc.call @XAie_StrmConnCctEnable(%25, %24, %14, %10, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %27 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %28 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %29 = emitc.call @XAie_StrmConnCctEnable(%28, %27, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %31 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %32 = emitc.call @XAie_StrmConnCctEnable(%31, %30, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %33 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %34 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %35 = emitc.call @XAie_StrmConnCctEnable(%34, %33, %14, %19, %13, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %36 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %37 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %38 = emitc.call @XAie_StrmConnCctEnable(%37, %36, %12, %19, %13, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %40 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %41 = emitc.call @XAie_StrmConnCctEnable(%40, %39, %12, %19, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %42 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %43 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %44 = emitc.call @XAie_StrmConnCctEnable(%43, %42, %12, %19, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %45 = emitc.call @XAie_TileLoc(%20, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %46 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %47 = emitc.call @XAie_StrmConnCctEnable(%46, %45, %14, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %48 = emitc.call @XAie_TileLoc(%19, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %49 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %50 = emitc.call @XAie_StrmConnCctEnable(%49, %48, %14, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %18 {
      %21 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %22 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %23 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%22, %21, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %24 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %25 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %26 = emitc.call @XAie_StrmConnCctEnable(%25, %24, %14, %16, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %27 = emitc.call @XAie_TileLoc(%16, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %28 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %29 = emitc.call @XAie_StrmConnCctEnable(%28, %27, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_TileLoc(%16, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %31 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %32 = emitc.call @XAie_StrmConnCctEnable(%31, %30, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %33 = emitc.call @XAie_TileLoc(%16, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %34 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %35 = emitc.call @XAie_StrmConnCctEnable(%34, %33, %14, %20, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %36 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %37 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %38 = emitc.call @XAie_StrmConnCctEnable(%37, %36, %12, %20, %13, %17) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %40 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %41 = emitc.call @XAie_StrmConnCctEnable(%40, %39, %12, %17, %13, %17) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %42 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %43 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %44 = emitc.call @XAie_StrmConnCctEnable(%43, %42, %12, %17, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %45 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %46 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %47 = emitc.call @XAie_StrmConnCctEnable(%46, %45, %12, %17, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %18 {
      %21 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %22 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %23 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%22, %21, %10) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %24 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %25 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %26 = emitc.call @XAie_StrmConnCctEnable(%25, %24, %14, %10, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %27 = emitc.call @XAie_TileLoc(%16, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %28 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %29 = emitc.call @XAie_StrmConnCctEnable(%28, %27, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_TileLoc(%16, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %31 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %32 = emitc.call @XAie_StrmConnCctEnable(%31, %30, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %33 = emitc.call @XAie_TileLoc(%16, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %34 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %35 = emitc.call @XAie_StrmConnCctEnable(%34, %33, %14, %19, %13, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %36 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %37 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %38 = emitc.call @XAie_StrmConnCctEnable(%37, %36, %12, %19, %13, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %40 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %41 = emitc.call @XAie_StrmConnCctEnable(%40, %39, %12, %16, %13, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %42 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %43 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %44 = emitc.call @XAie_StrmConnCctEnable(%43, %42, %12, %16, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %45 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %46 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %47 = emitc.call @XAie_StrmConnCctEnable(%46, %45, %12, %16, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %48 = emitc.call @XAie_TileLoc(%20, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %49 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %50 = emitc.call @XAie_StrmConnCctEnable(%49, %48, %14, %19, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %51 = emitc.call @XAie_TileLoc(%19, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %52 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %53 = emitc.call @XAie_StrmConnCctEnable(%52, %51, %14, %19, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %18 {
      %21 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %22 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %23 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%22, %21, %11, %20, %20, %7, %5, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %24 = emitc.call @XAie_StrmPktSwSlavePortEnable(%22, %21, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %25 = emitc.call @XAie_StrmPktSwMstrPortEnable(%22, %21, %12, %20, %4, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %26 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %27 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %28 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%27, %26, %13, %20, %20, %8, %20, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %29 = emitc.call @XAie_StrmPktSwSlavePortEnable(%27, %26, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%27, %26, %11, %20, %20, %3, %5, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %31 = emitc.call @XAie_StrmPktSwSlavePortEnable(%27, %26, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %32 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %33 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %34 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%33, %32, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %35 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_StrmPktSwMstrPortEnable(%36, %35, %12, %20, %2, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %13, %20, %14, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %15, %20, %14, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %15, %20, %14, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %15, %20, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %18 {
      %21 = emitc.call @XAie_TileLoc(%20, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %22 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %23 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%22, %21, %11, %20, %20, %1, %5, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %24 = emitc.call @XAie_StrmPktSwSlavePortEnable(%22, %21, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %25 = emitc.call @XAie_StrmPktSwMstrPortEnable(%22, %21, %12, %20, %4, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %26 = emitc.call @XAie_TileLoc(%19, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %27 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %28 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%27, %26, %13, %20, %20, %8, %20, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %29 = emitc.call @XAie_StrmPktSwSlavePortEnable(%27, %26, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%27, %26, %11, %20, %20, %0, %5, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %31 = emitc.call @XAie_StrmPktSwSlavePortEnable(%27, %26, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %32 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %33 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %34 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%33, %32, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %35 = emitc.call @XAie_TileLoc(%19, %9) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %36 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %37 = emitc.call @XAie_StrmPktSwMstrPortEnable(%36, %35, %14, %20, %2, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %38 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %39 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %40 = emitc.call @XAie_StrmConnCctEnable(%39, %38, %15, %20, %12, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %41 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %42 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %43 = emitc.call @XAie_StrmConnCctEnable(%42, %41, %13, %19, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %44 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %45 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %46 = emitc.call @XAie_StrmConnCctEnable(%45, %44, %15, %19, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %47 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %48 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %49 = emitc.call @XAie_StrmConnCctEnable(%48, %47, %15, %19, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %50 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %51 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %52 = emitc.call @XAie_StrmConnCctEnable(%51, %50, %15, %19, %14, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    return
  }
}
