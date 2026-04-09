module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  emitc.include <"xaiengine.h">
  emitc.func private @getOrCreateDeviceInstance() -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
  func.func @routing() {
    %0 = "emitc.constant"() <{value = true}> : () -> i1
    emitc.verbatim "\0A{ //----routing creation in row ----start-------"
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 3 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"SOUTH">, 3 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 7 : i32]} : () -> i32
      %10 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"SOUTH">, 7 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %11 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %12 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %13 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"WEST">, 1 : i32]} : () -> i32
      %14 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"WEST">, 1 : i32]} : () -> i32
      %15 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
      %16 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
      %17 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"{.PktId=5, .PktType=0}">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %18 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %19 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %20 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"WEST">, 0 : i32, 0 : i32, #emitc.opaque<"{.PktId=0, .PktType=0}">, 0 : i32, 0 : i32, 0 : i32]} : () -> i32
      %21 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %22 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"{.PktId=6, .PktType=0}">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %23 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %24 = emitc.call_opaque "XAie_EnableAieToShimDmaStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 1 : i32]} : () -> i32
      %25 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %26 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"WEST">, 0 : i32, #emitc.opaque<"SOUTH">, 0 : i32]} : () -> i32
      %27 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"SOUTH">, 0 : i32]} : () -> i32
      %28 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"SOUTH">, 0 : i32]} : () -> i32
      %29 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, 3 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, #emitc.opaque<"SOUTH">, 3 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,1)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,2)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,3)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"WEST">, 2 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 2 : i32, #emitc.opaque<"WEST">, 2 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 2 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 2 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %10 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %11 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %12 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, 7 : i32]} : () -> i32
      %13 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, #emitc.opaque<"SOUTH">, 7 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %14 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,1)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %15 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,2)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %16 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,3)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"WEST">, 1 : i32]} : () -> i32
      %17 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"WEST">, 3 : i32]} : () -> i32
      %18 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 3 : i32, #emitc.opaque<"WEST">, 3 : i32]} : () -> i32
      %19 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 3 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %20 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 3 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %21 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
      %22 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
      %23 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"{.PktId=11, .PktType=0}">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %24 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %25 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %26 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"WEST">, 0 : i32, 0 : i32, #emitc.opaque<"{.PktId=0, .PktType=0}">, 0 : i32, 0 : i32, 0 : i32]} : () -> i32
      %27 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %28 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"{.PktId=12, .PktType=0}">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %29 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %30 = emitc.call_opaque "XAie_EnableAieToShimDmaStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 3 : i32]} : () -> i32
      %31 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %32 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"EAST">, 1 : i32]} : () -> i32
      %33 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"WEST">, 1 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
      %34 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"NORTH">, 1 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
      %35 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"NORTH">, 1 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
      %36 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"NORTH">, 1 : i32, #emitc.opaque<"SOUTH">, 3 : i32]} : () -> i32
    }
    emitc.verbatim "\0A} //----routing creation in row ----end-------\0A"
    return
  }
}
