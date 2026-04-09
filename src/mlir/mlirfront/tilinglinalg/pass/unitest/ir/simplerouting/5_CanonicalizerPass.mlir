module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @routing() {
    %0 = "emitc.constant"() <{value = true}> : () -> i1
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
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 7 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"SOUTH">, 7 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"WEST">, 1 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"WEST">, 1 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %10 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
    }
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, 3 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, #emitc.opaque<"SOUTH">, 3 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,1)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,2)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"NORTH">, 0 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,3)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"WEST">, 2 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 2 : i32, #emitc.opaque<"WEST">, 2 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 2 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 2 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_EnableShimDmaToAieStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, 7 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,0)">, #emitc.opaque<"SOUTH">, 7 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,1)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,2)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(3,3)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"WEST">, 1 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"EAST">, 1 : i32, #emitc.opaque<"WEST">, 3 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 3 : i32, #emitc.opaque<"WEST">, 3 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 3 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 3 : i32, #emitc.opaque<"NORTH">, 1 : i32]} : () -> i32
      %10 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
      %11 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"SOUTH">, 1 : i32, #emitc.opaque<"DMA">, 1 : i32]} : () -> i32
    }
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"XAie_PacketInit(9, 0)">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"WEST">, 0 : i32, 0 : i32, #emitc.opaque<"XAie_PacketInit(0, 0)">, 0 : i32, 0 : i32, 0 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"XAie_PacketInit(10, 0)">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_EnableAieToShimDmaStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 1 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %10 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"WEST">, 0 : i32, #emitc.opaque<"SOUTH">, 0 : i32]} : () -> i32
      %11 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"SOUTH">, 0 : i32]} : () -> i32
      %12 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"SOUTH">, 0 : i32]} : () -> i32
      %13 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %0 {
      %1 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"XAie_PacketInit(11, 0)">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %2 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %3 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(0,4)">, #emitc.opaque<"EAST">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %4 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"WEST">, 0 : i32, 0 : i32, #emitc.opaque<"XAie_PacketInit(0, 0)">, 0 : i32, 0 : i32, 0 : i32]} : () -> i32
      %5 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"WEST">, 0 : i32]} : () -> i32
      %6 = emitc.call_opaque "XAie_StrmPktSwSlaveSlotEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"DMA">, 0 : i32, 0 : i32, #emitc.opaque<"XAie_PacketInit(12, 0)">, 31 : i32, 0 : i32, 0 : i32]} : () -> i32
      %7 = emitc.call_opaque "XAie_StrmPktSwSlavePortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"DMA">, 0 : i32]} : () -> i32
      %8 = emitc.call_opaque "XAie_EnableAieToShimDmaStrmPort"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, 3 : i32]} : () -> i32
      %9 = emitc.call_opaque "XAie_StrmPktSwMstrPortEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,4)">, #emitc.opaque<"SOUTH">, 0 : i32, #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">, 0 : i32, 1 : i32]} : () -> i32
      %10 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(1,3)">, #emitc.opaque<"NORTH">, 0 : i32, #emitc.opaque<"EAST">, 1 : i32]} : () -> i32
      %11 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,3)">, #emitc.opaque<"WEST">, 1 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
      %12 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,2)">, #emitc.opaque<"NORTH">, 1 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
      %13 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,1)">, #emitc.opaque<"NORTH">, 1 : i32, #emitc.opaque<"SOUTH">, 1 : i32]} : () -> i32
      %14 = emitc.call_opaque "XAie_StrmConnCctEnable"() {args = [#emitc.opaque<"getOrCreateDeviceInstance()">, #emitc.opaque<"XAie_TileLoc(2,0)">, #emitc.opaque<"NORTH">, 1 : i32, #emitc.opaque<"SOUTH">, 3 : i32]} : () -> i32
    }
    return
  }
  emitc.include <"xaiengine.h">
  emitc.func private @getOrCreateDeviceInstance() -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
}
