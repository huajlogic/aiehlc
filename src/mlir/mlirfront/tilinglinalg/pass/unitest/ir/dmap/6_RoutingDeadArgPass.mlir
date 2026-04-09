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
  func.func @routing() {
    %0 = "emitc.constant"() <{value = #emitc.opaque<"{.PktId=12, .PktType=0}">}> : () -> !emitc.opaque<"XAie_Packet">
    %1 = "emitc.constant"() <{value = #emitc.opaque<"{.PktId=11, .PktType=0}">}> : () -> !emitc.opaque<"XAie_Packet">
    %2 = "emitc.constant"() <{value = 4 : i32}> : () -> i32
    %3 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_SS_PKT_DROP_HEADER">}> : () -> !emitc.ptr<i8>
    %4 = "emitc.constant"() <{value = #emitc.opaque<"{.PktId=6, .PktType=0}">}> : () -> !emitc.opaque<"XAie_Packet">
    %5 = "emitc.constant"() <{value = #emitc.opaque<"XAIE_SS_PKT_DONOT_DROP_HEADER">}> : () -> !emitc.ptr<i8>
    %6 = "emitc.constant"() <{value = 31 : i32}> : () -> i32
    %7 = "emitc.constant"() <{value = #emitc.opaque<"NONE">}> : () -> !emitc.ptr<i8>
    %8 = "emitc.constant"() <{value = #emitc.opaque<"{.PktId=5, .PktType=0}">}> : () -> !emitc.opaque<"XAie_Packet">
    %9 = "emitc.constant"() <{value = #emitc.opaque<"{.PktId=0, .PktType=0}">}> : () -> !emitc.opaque<"XAie_Packet">
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
    %21 = "emitc.constant"() <{value = dense<"0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF"> : tensor<16x16xi8>}> : () -> tensor<16x16xi8>
    %22 = "emitc.constant"() <{value = dense<"0x02030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF0001"> : tensor<16x16xi8>}> : () -> tensor<16x16xi8>
    %23 = "emitc.constant"() <{value = dense<"0x0102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF00"> : tensor<16x16xi8>}> : () -> tensor<16x16xi8>
    emitc.verbatim "\0A{ //----routing creation in row ----start-------"
    emitc.verbatim "\0A//round is 0 hw split in : row -----------"
    emitc.if %18 {
      %24 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %25 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %26 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%25, %24, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %27 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %28 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %29 = emitc.call @XAie_StrmConnCctEnable(%28, %27, %14, %16, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %31 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %32 = emitc.call @XAie_StrmConnCctEnable(%31, %30, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %33 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %34 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %35 = emitc.call @XAie_StrmConnCctEnable(%34, %33, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %36 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %37 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %38 = emitc.call @XAie_StrmConnCctEnable(%37, %36, %14, %20, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %40 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %41 = emitc.call @XAie_StrmConnCctEnable(%40, %39, %12, %20, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %42 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %43 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %44 = emitc.call @XAie_StrmConnCctEnable(%43, %42, %12, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %45 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %46 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %47 = emitc.call @XAie_StrmConnCctEnable(%46, %45, %12, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %48 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %49 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %50 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%49, %48, %10) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %51 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %52 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %53 = emitc.call @XAie_StrmConnCctEnable(%52, %51, %14, %10, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %54 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %55 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %56 = emitc.call @XAie_StrmConnCctEnable(%55, %54, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %57 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %58 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %59 = emitc.call @XAie_StrmConnCctEnable(%58, %57, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %60 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %61 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %62 = emitc.call @XAie_StrmConnCctEnable(%61, %60, %14, %19, %13, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %63 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %64 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %65 = emitc.call @XAie_StrmConnCctEnable(%64, %63, %12, %19, %13, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %66 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %67 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %68 = emitc.call @XAie_StrmConnCctEnable(%67, %66, %12, %19, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %69 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %70 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %71 = emitc.call @XAie_StrmConnCctEnable(%70, %69, %12, %19, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %72 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %73 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %74 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%73, %72, %11, %20, %20, %8, %6, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %75 = emitc.call @XAie_StrmPktSwSlavePortEnable(%73, %72, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %76 = emitc.call @XAie_StrmPktSwMstrPortEnable(%73, %72, %12, %20, %5, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %77 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %78 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %79 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%78, %77, %13, %20, %20, %9, %20, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %80 = emitc.call @XAie_StrmPktSwSlavePortEnable(%78, %77, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %81 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%78, %77, %11, %20, %20, %4, %6, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %82 = emitc.call @XAie_StrmPktSwSlavePortEnable(%78, %77, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %83 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %84 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %85 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%84, %83, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %86 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %87 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %88 = emitc.call @XAie_StrmPktSwMstrPortEnable(%87, %86, %12, %20, %3, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %89 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %90 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %91 = emitc.call @XAie_StrmConnCctEnable(%90, %89, %13, %20, %14, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %92 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %93 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %94 = emitc.call @XAie_StrmConnCctEnable(%93, %92, %15, %20, %14, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %95 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %96 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %97 = emitc.call @XAie_StrmConnCctEnable(%96, %95, %15, %20, %14, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %98 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %99 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %100 = emitc.call @XAie_StrmConnCctEnable(%99, %98, %15, %20, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A//round is 1 hw split in : row -----------"
    emitc.if %18 {
      %24 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %25 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %26 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%25, %24, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %27 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %28 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %29 = emitc.call @XAie_StrmConnCctEnable(%28, %27, %14, %16, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %30 = emitc.call @XAie_TileLoc(%16, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %31 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %32 = emitc.call @XAie_StrmConnCctEnable(%31, %30, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %33 = emitc.call @XAie_TileLoc(%16, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %34 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %35 = emitc.call @XAie_StrmConnCctEnable(%34, %33, %14, %20, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %36 = emitc.call @XAie_TileLoc(%16, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %37 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %38 = emitc.call @XAie_StrmConnCctEnable(%37, %36, %14, %20, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %39 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %40 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %41 = emitc.call @XAie_StrmConnCctEnable(%40, %39, %12, %20, %13, %17) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %42 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %43 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %44 = emitc.call @XAie_StrmConnCctEnable(%43, %42, %12, %17, %13, %17) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %45 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %46 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %47 = emitc.call @XAie_StrmConnCctEnable(%46, %45, %12, %17, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %48 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %49 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %50 = emitc.call @XAie_StrmConnCctEnable(%49, %48, %12, %17, %15, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %51 = emitc.call @XAie_TileLoc(%20, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %52 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %53 = emitc.call @XAie_StrmConnCctEnable(%52, %51, %14, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %54 = emitc.call @XAie_TileLoc(%19, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %55 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %56 = emitc.call @XAie_StrmConnCctEnable(%55, %54, %14, %20, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %57 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %58 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %59 = emitc.call @XAie_EnableShimDmaToAieStrmPort(%58, %57, %10) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %60 = emitc.call @XAie_TileLoc(%16, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %61 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %62 = emitc.call @XAie_StrmConnCctEnable(%61, %60, %14, %10, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %63 = emitc.call @XAie_TileLoc(%16, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %64 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %65 = emitc.call @XAie_StrmConnCctEnable(%64, %63, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %66 = emitc.call @XAie_TileLoc(%16, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %67 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %68 = emitc.call @XAie_StrmConnCctEnable(%67, %66, %14, %19, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %69 = emitc.call @XAie_TileLoc(%16, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %70 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %71 = emitc.call @XAie_StrmConnCctEnable(%70, %69, %14, %19, %13, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %72 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %73 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %74 = emitc.call @XAie_StrmConnCctEnable(%73, %72, %12, %19, %13, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %75 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %76 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %77 = emitc.call @XAie_StrmConnCctEnable(%76, %75, %12, %16, %13, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %78 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %79 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %80 = emitc.call @XAie_StrmConnCctEnable(%79, %78, %12, %16, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %81 = emitc.call @XAie_TileLoc(%20, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %82 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %83 = emitc.call @XAie_StrmConnCctEnable(%82, %81, %12, %16, %15, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %84 = emitc.call @XAie_TileLoc(%20, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %85 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %86 = emitc.call @XAie_StrmConnCctEnable(%85, %84, %14, %19, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %87 = emitc.call @XAie_TileLoc(%19, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %88 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %89 = emitc.call @XAie_StrmConnCctEnable(%88, %87, %14, %19, %11, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %90 = emitc.call @XAie_TileLoc(%20, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %91 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %92 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%91, %90, %11, %20, %20, %1, %6, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %93 = emitc.call @XAie_StrmPktSwSlavePortEnable(%91, %90, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %94 = emitc.call @XAie_StrmPktSwMstrPortEnable(%91, %90, %12, %20, %5, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %95 = emitc.call @XAie_TileLoc(%19, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %96 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %97 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%96, %95, %13, %20, %20, %9, %20, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %98 = emitc.call @XAie_StrmPktSwSlavePortEnable(%96, %95, %13, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %99 = emitc.call @XAie_StrmPktSwSlaveSlotEnable(%96, %95, %11, %20, %20, %0, %6, %20, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, i32, !emitc.opaque<"XAie_Packet">, i32, i32, i32) -> i32
      %100 = emitc.call @XAie_StrmPktSwSlavePortEnable(%96, %95, %11, %20) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32) -> i32
      %101 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %102 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %103 = emitc.call @XAie_EnableAieToShimDmaStrmPort(%102, %101, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, i32) -> i32
      %104 = emitc.call @XAie_TileLoc(%19, %2) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %105 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %106 = emitc.call @XAie_StrmPktSwMstrPortEnable(%105, %104, %14, %20, %3, %20, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32, i32) -> i32
      %107 = emitc.call @XAie_TileLoc(%19, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %108 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %109 = emitc.call @XAie_StrmConnCctEnable(%108, %107, %15, %20, %12, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %110 = emitc.call @XAie_TileLoc(%17, %16) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %111 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %112 = emitc.call @XAie_StrmConnCctEnable(%111, %110, %13, %19, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %113 = emitc.call @XAie_TileLoc(%17, %17) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %114 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %115 = emitc.call @XAie_StrmConnCctEnable(%114, %113, %15, %19, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %116 = emitc.call @XAie_TileLoc(%17, %19) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %117 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %118 = emitc.call @XAie_StrmConnCctEnable(%117, %116, %15, %19, %14, %19) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
      %119 = emitc.call @XAie_TileLoc(%17, %20) : (i32, i32) -> !emitc.opaque<"XAie_LocType">
      %120 = emitc.call @getOrCreateDeviceInstance() : () -> !emitc.ptr<!emitc.opaque<"XAie_DevInst">>
      %121 = emitc.call @XAie_StrmConnCctEnable(%120, %119, %15, %19, %14, %16) : (!emitc.ptr<!emitc.opaque<"XAie_DevInst">>, !emitc.opaque<"XAie_LocType">, !emitc.ptr<i8>, i32, !emitc.ptr<i8>, i32) -> i32
    }
    emitc.verbatim "\0A} //----routing creation in row ----end-------\0A"
    return
  }
}
