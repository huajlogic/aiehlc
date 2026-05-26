module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @routing(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>, %arg3: memref<256x256xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg1 : memref<256x256xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<256x256xi8> shape = [256, 256], dim = 2 -> tensor<256x256xi8>
    %2 = bufferization.to_tensor %arg2 : memref<256x256xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<256x256xi8> shape = [256, 256], dim = 2 -> tensor<256x256xi8>
    %4 = bufferization.to_tensor %arg3 : memref<256x256xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<256x256xi8> shape = [256, 256], dim = 2 -> tensor<256x256xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %3 : tensor<256x256xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "col",
          replicate_on = "row",
          single_tile_owner = ""
     } -> tensor<256x256xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %11 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f12_corePortIn0 on %12 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f12_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f12_corePortIn1 on %15 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f12_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 0, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f12_corePortIn2 on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f12_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 0, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f12_corePortIn3 on %21 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f12_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.consumer @f12_consumer0 {dma_port = 1 : i64, from = @f12_corePortIn0}
        %25 = dmaphop.consumer @f12_consumer1 {dma_port = 1 : i64, from = @f12_corePortIn1}
        %26 = dmaphop.consumer @f12_consumer2 {dma_port = 1 : i64, from = @f12_corePortIn2}
        %27 = dmaphop.consumer @f12_consumer3 {dma_port = 1 : i64, from = @f12_corePortIn3}
        %28 = dmaphop.tile{TILETYPE = "shim", col = 0, row = 0} -> !dmaphop.tile
        %29 = dmaphop.port @f12_shimPortOut on %28 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %30 = dmaphop.port @f12_shimPortIn on %28 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.create_hop %29 -> %13 -> !dmaphop.hop
        %32 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %33 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %34 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %35 = dmaphop.create_path[%31, %32, %33, %34] {producers = [[@f12_shimPortIn]], consumers = [[@f12_consumer0, @f12_consumer1, @f12_consumer2, @f12_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %35 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %35
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %11 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f13_corePortIn0 on %12 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f13_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f13_corePortIn1 on %15 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f13_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 1, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f13_corePortIn2 on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f13_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 1, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f13_corePortIn3 on %21 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f13_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.consumer @f13_consumer0 {dma_port = 1 : i64, from = @f13_corePortIn0}
        %25 = dmaphop.consumer @f13_consumer1 {dma_port = 1 : i64, from = @f13_corePortIn1}
        %26 = dmaphop.consumer @f13_consumer2 {dma_port = 1 : i64, from = @f13_corePortIn2}
        %27 = dmaphop.consumer @f13_consumer3 {dma_port = 1 : i64, from = @f13_corePortIn3}
        %28 = dmaphop.tile{TILETYPE = "shim", col = 1, row = 0} -> !dmaphop.tile
        %29 = dmaphop.port @f13_shimPortOut on %28 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %30 = dmaphop.port @f13_shimPortIn on %28 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.create_hop %29 -> %13 -> !dmaphop.hop
        %32 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %33 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %34 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %35 = dmaphop.create_path[%31, %32, %33, %34] {producers = [[@f13_shimPortIn]], consumers = [[@f13_consumer0, @f13_consumer1, @f13_consumer2, @f13_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %35 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %35
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %11 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 2, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f14_corePortIn0 on %12 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f14_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 2, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f14_corePortIn1 on %15 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f14_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f14_corePortIn2 on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f14_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 2, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f14_corePortIn3 on %21 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f14_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.consumer @f14_consumer0 {dma_port = 1 : i64, from = @f14_corePortIn0}
        %25 = dmaphop.consumer @f14_consumer1 {dma_port = 1 : i64, from = @f14_corePortIn1}
        %26 = dmaphop.consumer @f14_consumer2 {dma_port = 1 : i64, from = @f14_corePortIn2}
        %27 = dmaphop.consumer @f14_consumer3 {dma_port = 1 : i64, from = @f14_corePortIn3}
        %28 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %29 = dmaphop.port @f14_shimPortOut on %28 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %30 = dmaphop.port @f14_shimPortIn on %28 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.create_hop %29 -> %13 -> !dmaphop.hop
        %32 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %33 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %34 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %35 = dmaphop.create_path[%31, %32, %33, %34] {producers = [[@f14_shimPortIn]], consumers = [[@f14_consumer0, @f14_consumer1, @f14_consumer2, @f14_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %35 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %35
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %11 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 3, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f15_corePortIn0 on %12 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f15_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 3, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f15_corePortIn1 on %15 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f15_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 3, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f15_corePortIn2 on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f15_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f15_corePortIn3 on %21 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f15_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.consumer @f15_consumer0 {dma_port = 1 : i64, from = @f15_corePortIn0}
        %25 = dmaphop.consumer @f15_consumer1 {dma_port = 1 : i64, from = @f15_corePortIn1}
        %26 = dmaphop.consumer @f15_consumer2 {dma_port = 1 : i64, from = @f15_corePortIn2}
        %27 = dmaphop.consumer @f15_consumer3 {dma_port = 1 : i64, from = @f15_corePortIn3}
        %28 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %29 = dmaphop.port @f15_shimPortOut on %28 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %30 = dmaphop.port @f15_shimPortIn on %28 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.create_hop %29 -> %13 -> !dmaphop.hop
        %32 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %33 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %34 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %35 = dmaphop.create_path[%31, %32, %33, %34] {producers = [[@f15_shimPortIn]], consumers = [[@f15_consumer0, @f15_consumer1, @f15_consumer2, @f15_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %35 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %35
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %1 : tensor<256x256xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<256x256xi8>
      %7 = routing.partitiontensor tensor = %5 : tensor<256x256xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<256x256xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %12 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %14 = dmaphop.port @f16_corePortIn0 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f16_corePortOut0 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %17 = dmaphop.port @f16_corePortIn1 on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f16_corePortOut1 on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.tile{TILETYPE = "core", col = 2, row = 3} -> !dmaphop.tile
        %20 = dmaphop.port @f16_corePortIn2 on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f16_corePortOut2 on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.tile{TILETYPE = "core", col = 3, row = 3} -> !dmaphop.tile
        %23 = dmaphop.port @f16_corePortIn3 on %22 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.port @f16_corePortOut3 on %22 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %25 = dmaphop.consumer @f16_consumer0 {dma_port = 0 : i64, from = @f16_corePortIn0}
        %26 = dmaphop.consumer @f16_consumer1 {dma_port = 0 : i64, from = @f16_corePortIn1}
        %27 = dmaphop.consumer @f16_consumer2 {dma_port = 0 : i64, from = @f16_corePortIn2}
        %28 = dmaphop.consumer @f16_consumer3 {dma_port = 0 : i64, from = @f16_corePortIn3}
        %29 = dmaphop.tile{TILETYPE = "shim", col = 0, row = 0} -> !dmaphop.tile
        %30 = dmaphop.port @f16_shimPortOut on %29 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f16_shimPortIn on %29 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.create_hop %30 -> %14 -> !dmaphop.hop
        %33 = dmaphop.create_hop %15 -> %17 -> !dmaphop.hop
        %34 = dmaphop.create_hop %18 -> %20 -> !dmaphop.hop
        %35 = dmaphop.create_hop %21 -> %23 -> !dmaphop.hop
        %36 = dmaphop.create_path[%32, %33, %34, %35] {producers = [[@f16_shimPortIn]], consumers = [[@f16_consumer0, @f16_consumer1, @f16_consumer2, @f16_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %12 into %36 consumer(%12, %12, %12, %12 at %14, %17, %20, %23) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %36
        %37 = routing.routingextract_data %7, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %38 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %39 = dmaphop.port @f17_corePortIn0 on %38 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %40 = dmaphop.port @f17_corePortOut0 on %38 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %41 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %42 = dmaphop.port @f17_corePortIn1 on %41 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %43 = dmaphop.port @f17_corePortOut1 on %41 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %44 = dmaphop.tile{TILETYPE = "core", col = 2, row = 3} -> !dmaphop.tile
        %45 = dmaphop.port @f17_corePortIn2 on %44 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %46 = dmaphop.port @f17_corePortOut2 on %44 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %47 = dmaphop.tile{TILETYPE = "core", col = 3, row = 3} -> !dmaphop.tile
        %48 = dmaphop.port @f17_corePortIn3 on %47 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %49 = dmaphop.port @f17_corePortOut3 on %47 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %50 = dmaphop.producer @f17_producer0 {dma_port = 0 : i64, tp = @f17_corePortOut0}
        %51 = dmaphop.producer @f17_producer1 {dma_port = 0 : i64, tp = @f17_corePortOut1}
        %52 = dmaphop.producer @f17_producer2 {dma_port = 0 : i64, tp = @f17_corePortOut2}
        %53 = dmaphop.producer @f17_producer3 {dma_port = 0 : i64, tp = @f17_corePortOut3}
        %54 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %55 = dmaphop.port @f17_shimPortOut on %54 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %56 = dmaphop.port @f17_shimPortIn on %54 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %57 = dmaphop.create_hop %49 -> %56 -> !dmaphop.hop
        %58 = dmaphop.create_hop %46 -> %48 -> !dmaphop.hop
        %59 = dmaphop.create_hop %43 -> %45 -> !dmaphop.hop
        %60 = dmaphop.create_hop %40 -> %42 -> !dmaphop.hop
        %61 = dmaphop.create_path[%57, %58, %59, %60] {producers = [[@f17_producer0, @f17_producer1, @f17_producer2, @f17_producer3]], consumers = [[@f17_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %37[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_0 = tensor.extract_slice %37[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_1 = tensor.extract_slice %37[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %37[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        dmaphop.pull %37 from %61 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %39, %42, %45, %48) : tensor<64x256xi8> !dmaphop.path tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %61
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %12 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f18_corePortIn0 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f18_corePortOut0 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %17 = dmaphop.port @f18_corePortIn1 on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f18_corePortOut1 on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.tile{TILETYPE = "core", col = 2, row = 4} -> !dmaphop.tile
        %20 = dmaphop.port @f18_corePortIn2 on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f18_corePortOut2 on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.tile{TILETYPE = "core", col = 3, row = 4} -> !dmaphop.tile
        %23 = dmaphop.port @f18_corePortIn3 on %22 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.port @f18_corePortOut3 on %22 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %25 = dmaphop.consumer @f18_consumer0 {dma_port = 0 : i64, from = @f18_corePortIn0}
        %26 = dmaphop.consumer @f18_consumer1 {dma_port = 0 : i64, from = @f18_corePortIn1}
        %27 = dmaphop.consumer @f18_consumer2 {dma_port = 0 : i64, from = @f18_corePortIn2}
        %28 = dmaphop.consumer @f18_consumer3 {dma_port = 0 : i64, from = @f18_corePortIn3}
        %29 = dmaphop.tile{TILETYPE = "shim", col = 1, row = 0} -> !dmaphop.tile
        %30 = dmaphop.port @f18_shimPortOut on %29 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f18_shimPortIn on %29 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.create_hop %30 -> %14 -> !dmaphop.hop
        %33 = dmaphop.create_hop %15 -> %17 -> !dmaphop.hop
        %34 = dmaphop.create_hop %18 -> %20 -> !dmaphop.hop
        %35 = dmaphop.create_hop %21 -> %23 -> !dmaphop.hop
        %36 = dmaphop.create_path[%32, %33, %34, %35] {producers = [[@f18_shimPortIn]], consumers = [[@f18_consumer0, @f18_consumer1, @f18_consumer2, @f18_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %12 into %36 consumer(%12, %12, %12, %12 at %14, %17, %20, %23) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %36
        %37 = routing.routingextract_data %7, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %38 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %39 = dmaphop.port @f19_corePortIn0 on %38 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %40 = dmaphop.port @f19_corePortOut0 on %38 { direction = "Out", direction_channel = 0, dmapktid = 5 : i32 } : !dmaphop.tile -> !dmaphop.port
        %41 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %42 = dmaphop.port @f19_corePortIn1 on %41 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %43 = dmaphop.port @f19_corePortOut1 on %41 { direction = "Out", direction_channel = 0, dmapktid = 6 : i32 } : !dmaphop.tile -> !dmaphop.port
        %44 = dmaphop.tile{TILETYPE = "core", col = 2, row = 4} -> !dmaphop.tile
        %45 = dmaphop.port @f19_corePortIn2 on %44 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %46 = dmaphop.port @f19_corePortOut2 on %44 { direction = "Out", direction_channel = 0, dmapktid = 7 : i32 } : !dmaphop.tile -> !dmaphop.port
        %47 = dmaphop.tile{TILETYPE = "core", col = 3, row = 4} -> !dmaphop.tile
        %48 = dmaphop.port @f19_corePortIn3 on %47 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %49 = dmaphop.port @f19_corePortOut3 on %47 { direction = "Out", direction_channel = 0, dmapktid = 8 : i32 } : !dmaphop.tile -> !dmaphop.port
        %50 = dmaphop.producer @f19_producer0 {dma_port = 0 : i64, tp = @f19_corePortOut0}
        %51 = dmaphop.producer @f19_producer1 {dma_port = 0 : i64, tp = @f19_corePortOut1}
        %52 = dmaphop.producer @f19_producer2 {dma_port = 0 : i64, tp = @f19_corePortOut2}
        %53 = dmaphop.producer @f19_producer3 {dma_port = 0 : i64, tp = @f19_corePortOut3}
        %54 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %55 = dmaphop.port @f19_shimPortOut on %54 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %56 = dmaphop.port @f19_shimPortIn on %54 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %57 = dmaphop.create_hop %49 -> %56 -> !dmaphop.hop
        %58 = dmaphop.create_hop %46 -> %48 -> !dmaphop.hop
        %59 = dmaphop.create_hop %43 -> %45 -> !dmaphop.hop
        %60 = dmaphop.create_hop %40 -> %42 -> !dmaphop.hop
        %61 = dmaphop.create_path[%57, %58, %59, %60] {producers = [[@f19_producer0, @f19_producer1, @f19_producer2, @f19_producer3]], consumers = [[@f19_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %37[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_0 = tensor.extract_slice %37[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_1 = tensor.extract_slice %37[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %37[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        dmaphop.pull %37 from %61 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %39, %42, %45, %48) : tensor<64x256xi8> !dmaphop.path tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %61
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %12 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 5} -> !dmaphop.tile
        %14 = dmaphop.port @f20_corePortIn0 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f20_corePortOut0 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "core", col = 1, row = 5} -> !dmaphop.tile
        %17 = dmaphop.port @f20_corePortIn1 on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f20_corePortOut1 on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.tile{TILETYPE = "core", col = 2, row = 5} -> !dmaphop.tile
        %20 = dmaphop.port @f20_corePortIn2 on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f20_corePortOut2 on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.tile{TILETYPE = "core", col = 3, row = 5} -> !dmaphop.tile
        %23 = dmaphop.port @f20_corePortIn3 on %22 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.port @f20_corePortOut3 on %22 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %25 = dmaphop.consumer @f20_consumer0 {dma_port = 0 : i64, from = @f20_corePortIn0}
        %26 = dmaphop.consumer @f20_consumer1 {dma_port = 0 : i64, from = @f20_corePortIn1}
        %27 = dmaphop.consumer @f20_consumer2 {dma_port = 0 : i64, from = @f20_corePortIn2}
        %28 = dmaphop.consumer @f20_consumer3 {dma_port = 0 : i64, from = @f20_corePortIn3}
        %29 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %30 = dmaphop.port @f20_shimPortOut on %29 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f20_shimPortIn on %29 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.create_hop %30 -> %14 -> !dmaphop.hop
        %33 = dmaphop.create_hop %15 -> %17 -> !dmaphop.hop
        %34 = dmaphop.create_hop %18 -> %20 -> !dmaphop.hop
        %35 = dmaphop.create_hop %21 -> %23 -> !dmaphop.hop
        %36 = dmaphop.create_path[%32, %33, %34, %35] {producers = [[@f20_shimPortIn]], consumers = [[@f20_consumer0, @f20_consumer1, @f20_consumer2, @f20_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %12 into %36 consumer(%12, %12, %12, %12 at %14, %17, %20, %23) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %36
        %37 = routing.routingextract_data %7, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %38 = dmaphop.tile{TILETYPE = "core", col = 0, row = 5} -> !dmaphop.tile
        %39 = dmaphop.port @f21_corePortIn0 on %38 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %40 = dmaphop.port @f21_corePortOut0 on %38 { direction = "Out", direction_channel = 0, dmapktid = 9 : i32 } : !dmaphop.tile -> !dmaphop.port
        %41 = dmaphop.tile{TILETYPE = "core", col = 1, row = 5} -> !dmaphop.tile
        %42 = dmaphop.port @f21_corePortIn1 on %41 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %43 = dmaphop.port @f21_corePortOut1 on %41 { direction = "Out", direction_channel = 0, dmapktid = 10 : i32 } : !dmaphop.tile -> !dmaphop.port
        %44 = dmaphop.tile{TILETYPE = "core", col = 2, row = 5} -> !dmaphop.tile
        %45 = dmaphop.port @f21_corePortIn2 on %44 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %46 = dmaphop.port @f21_corePortOut2 on %44 { direction = "Out", direction_channel = 0, dmapktid = 11 : i32 } : !dmaphop.tile -> !dmaphop.port
        %47 = dmaphop.tile{TILETYPE = "core", col = 3, row = 5} -> !dmaphop.tile
        %48 = dmaphop.port @f21_corePortIn3 on %47 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %49 = dmaphop.port @f21_corePortOut3 on %47 { direction = "Out", direction_channel = 0, dmapktid = 12 : i32 } : !dmaphop.tile -> !dmaphop.port
        %50 = dmaphop.producer @f21_producer0 {dma_port = 0 : i64, tp = @f21_corePortOut0}
        %51 = dmaphop.producer @f21_producer1 {dma_port = 0 : i64, tp = @f21_corePortOut1}
        %52 = dmaphop.producer @f21_producer2 {dma_port = 0 : i64, tp = @f21_corePortOut2}
        %53 = dmaphop.producer @f21_producer3 {dma_port = 0 : i64, tp = @f21_corePortOut3}
        %54 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %55 = dmaphop.port @f21_shimPortOut on %54 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %56 = dmaphop.port @f21_shimPortIn on %54 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %57 = dmaphop.create_hop %49 -> %56 -> !dmaphop.hop
        %58 = dmaphop.create_hop %46 -> %48 -> !dmaphop.hop
        %59 = dmaphop.create_hop %43 -> %45 -> !dmaphop.hop
        %60 = dmaphop.create_hop %40 -> %42 -> !dmaphop.hop
        %61 = dmaphop.create_path[%57, %58, %59, %60] {producers = [[@f21_producer0, @f21_producer1, @f21_producer2, @f21_producer3]], consumers = [[@f21_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %37[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_0 = tensor.extract_slice %37[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_1 = tensor.extract_slice %37[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %37[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        dmaphop.pull %37 from %61 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %39, %42, %45, %48) : tensor<64x256xi8> !dmaphop.path tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %61
        "routing.yield"() : () -> ()
      }
      %11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %12 = routing.routingextract_data %6, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 6} -> !dmaphop.tile
        %14 = dmaphop.port @f22_corePortIn0 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f22_corePortOut0 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "core", col = 1, row = 6} -> !dmaphop.tile
        %17 = dmaphop.port @f22_corePortIn1 on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f22_corePortOut1 on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.tile{TILETYPE = "core", col = 2, row = 6} -> !dmaphop.tile
        %20 = dmaphop.port @f22_corePortIn2 on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f22_corePortOut2 on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.tile{TILETYPE = "core", col = 3, row = 6} -> !dmaphop.tile
        %23 = dmaphop.port @f22_corePortIn3 on %22 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.port @f22_corePortOut3 on %22 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %25 = dmaphop.consumer @f22_consumer0 {dma_port = 0 : i64, from = @f22_corePortIn0}
        %26 = dmaphop.consumer @f22_consumer1 {dma_port = 0 : i64, from = @f22_corePortIn1}
        %27 = dmaphop.consumer @f22_consumer2 {dma_port = 0 : i64, from = @f22_corePortIn2}
        %28 = dmaphop.consumer @f22_consumer3 {dma_port = 0 : i64, from = @f22_corePortIn3}
        %29 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %30 = dmaphop.port @f22_shimPortOut on %29 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f22_shimPortIn on %29 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.create_hop %30 -> %14 -> !dmaphop.hop
        %33 = dmaphop.create_hop %15 -> %17 -> !dmaphop.hop
        %34 = dmaphop.create_hop %18 -> %20 -> !dmaphop.hop
        %35 = dmaphop.create_hop %21 -> %23 -> !dmaphop.hop
        %36 = dmaphop.create_path[%32, %33, %34, %35] {producers = [[@f22_shimPortIn]], consumers = [[@f22_consumer0, @f22_consumer1, @f22_consumer2, @f22_consumer3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %12 into %36 consumer(%12, %12, %12, %12 at %14, %17, %20, %23) : tensor<64x256xi8> !dmaphop.path tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8>, tensor<64x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %36
        %37 = routing.routingextract_data %7, %arg4 : tensor<256x256xi8>, i32 -> tensor<64x256xi8>
        %38 = dmaphop.tile{TILETYPE = "core", col = 0, row = 6} -> !dmaphop.tile
        %39 = dmaphop.port @f23_corePortIn0 on %38 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %40 = dmaphop.port @f23_corePortOut0 on %38 { direction = "Out", direction_channel = 0, dmapktid = 13 : i32 } : !dmaphop.tile -> !dmaphop.port
        %41 = dmaphop.tile{TILETYPE = "core", col = 1, row = 6} -> !dmaphop.tile
        %42 = dmaphop.port @f23_corePortIn1 on %41 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %43 = dmaphop.port @f23_corePortOut1 on %41 { direction = "Out", direction_channel = 0, dmapktid = 14 : i32 } : !dmaphop.tile -> !dmaphop.port
        %44 = dmaphop.tile{TILETYPE = "core", col = 2, row = 6} -> !dmaphop.tile
        %45 = dmaphop.port @f23_corePortIn2 on %44 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %46 = dmaphop.port @f23_corePortOut2 on %44 { direction = "Out", direction_channel = 0, dmapktid = 15 : i32 } : !dmaphop.tile -> !dmaphop.port
        %47 = dmaphop.tile{TILETYPE = "core", col = 3, row = 6} -> !dmaphop.tile
        %48 = dmaphop.port @f23_corePortIn3 on %47 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %49 = dmaphop.port @f23_corePortOut3 on %47 { direction = "Out", direction_channel = 0, dmapktid = 16 : i32 } : !dmaphop.tile -> !dmaphop.port
        %50 = dmaphop.producer @f23_producer0 {dma_port = 0 : i64, tp = @f23_corePortOut0}
        %51 = dmaphop.producer @f23_producer1 {dma_port = 0 : i64, tp = @f23_corePortOut1}
        %52 = dmaphop.producer @f23_producer2 {dma_port = 0 : i64, tp = @f23_corePortOut2}
        %53 = dmaphop.producer @f23_producer3 {dma_port = 0 : i64, tp = @f23_corePortOut3}
        %54 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %55 = dmaphop.port @f23_shimPortOut on %54 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %56 = dmaphop.port @f23_shimPortIn on %54 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %57 = dmaphop.create_hop %49 -> %56 -> !dmaphop.hop
        %58 = dmaphop.create_hop %46 -> %48 -> !dmaphop.hop
        %59 = dmaphop.create_hop %43 -> %45 -> !dmaphop.hop
        %60 = dmaphop.create_hop %40 -> %42 -> !dmaphop.hop
        %61 = dmaphop.create_path[%57, %58, %59, %60] {producers = [[@f23_producer0, @f23_producer1, @f23_producer2, @f23_producer3]], consumers = [[@f23_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %37[0, 0] [16, 256] [1, 1] {tag = "producer0"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_0 = tensor.extract_slice %37[16, 0] [16, 256] [1, 1] {tag = "producer1"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_1 = tensor.extract_slice %37[32, 0] [16, 256] [1, 1] {tag = "producer2"} : tensor<64x256xi8> to tensor<16x256xi8>
        %extracted_slice_2 = tensor.extract_slice %37[48, 0] [16, 256] [1, 1] {tag = "producer3"} : tensor<64x256xi8> to tensor<16x256xi8>
        dmaphop.pull %37 from %61 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %39, %42, %45, %48) : tensor<64x256xi8> !dmaphop.path tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8>, tensor<16x256xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %61
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
