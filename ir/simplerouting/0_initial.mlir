module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @routing(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: memref<158700xi8>, %arg2: memref<9548xi8>, %arg3: memref<846400xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg1 : memref<158700xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<158700xi8> shape = [158700], dim = 1 -> tensor<158700xi8>
    %2 = bufferization.to_tensor %arg2 : memref<9548xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<9548xi8> shape = [9548], dim = 1 -> tensor<9548xi8>
    %4 = bufferization.to_tensor %arg3 : memref<846400xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<846400xi8> shape = [846400], dim = 1 -> tensor<846400xi8>
    scf.execute_region {
      %6 = routing.partitiontensor %3 : tensor<9548xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<9548xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %9 = routing.routingextract_data %6, %arg4 : tensor<9548xi8>, i32 -> tensor<4774xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f0_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f0_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f0_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f0_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f0_consumer0 {dma_port = 1 : i64, from = @f0_corePortIn0}
        %17 = dmaphop.consumer @f0_consumer1 {dma_port = 1 : i64, from = @f0_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f0_shimPortOut on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f0_shimPortIn on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f0_shimPortIn]], consumers = [[@f0_consumer0, @f0_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<4774xi8> !dmaphop.path tensor<4774xi8>, tensor<4774xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %9 = routing.routingextract_data %6, %arg4 : tensor<9548xi8>, i32 -> tensor<4774xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f1_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f1_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f1_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f1_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f1_consumer0 {dma_port = 1 : i64, from = @f1_corePortIn0}
        %17 = dmaphop.consumer @f1_consumer1 {dma_port = 1 : i64, from = @f1_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f1_shimPortOut on %18 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f1_shimPortIn on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f1_shimPortIn]], consumers = [[@f1_consumer0, @f1_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<4774xi8> !dmaphop.path tensor<4774xi8>, tensor<4774xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor %1 : tensor<158700xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<158700xi8>
      %7 = routing.partitiontensor %5 : tensor<846400xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<846400xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %10 = routing.routingextract_data %6, %arg4 : tensor<158700xi8>, i32 -> tensor<79350xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %12 = dmaphop.port @f2_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f2_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %15 = dmaphop.port @f2_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f2_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f2_consumer0 {dma_port = 0 : i64, from = @f2_corePortIn0}
        %18 = dmaphop.consumer @f2_consumer1 {dma_port = 0 : i64, from = @f2_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f2_shimPortOut on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f2_shimPortIn on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f2_shimPortIn]], consumers = [[@f2_consumer0, @f2_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<79350xi8> !dmaphop.path tensor<79350xi8>, tensor<79350xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg4 : tensor<846400xi8>, i32 -> tensor<423200xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %27 = dmaphop.port @f3_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f3_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %30 = dmaphop.port @f3_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f3_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f3_producer0 {dma_port = 0 : i64, tp = @f3_corePortOut0}
        %33 = dmaphop.producer @f3_producer1 {dma_port = 0 : i64, tp = @f3_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f3_shimPortOut on %34 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f3_shimPortIn on %34 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f3_producer0, @f3_producer1]], consumers = [[@f3_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [211600] [1] {tag = "producer0"} : tensor<423200xi8> to tensor<211600xi8>
        %extracted_slice_0 = tensor.extract_slice %25[211600] [211600] [1] {tag = "producer1"} : tensor<423200xi8> to tensor<211600xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<423200xi8> !dmaphop.path tensor<211600xi8>, tensor<211600xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %10 = routing.routingextract_data %6, %arg4 : tensor<158700xi8>, i32 -> tensor<79350xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %12 = dmaphop.port @f4_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f4_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %15 = dmaphop.port @f4_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f4_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f4_consumer0 {dma_port = 0 : i64, from = @f4_corePortIn0}
        %18 = dmaphop.consumer @f4_consumer1 {dma_port = 0 : i64, from = @f4_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f4_shimPortOut on %19 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f4_shimPortIn on %19 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f4_shimPortIn]], consumers = [[@f4_consumer0, @f4_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<79350xi8> !dmaphop.path tensor<79350xi8>, tensor<79350xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg4 : tensor<846400xi8>, i32 -> tensor<423200xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %27 = dmaphop.port @f5_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f5_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %30 = dmaphop.port @f5_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f5_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f5_producer0 {dma_port = 0 : i64, tp = @f5_corePortOut0}
        %33 = dmaphop.producer @f5_producer1 {dma_port = 0 : i64, tp = @f5_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f5_shimPortOut on %34 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f5_shimPortIn on %34 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f5_producer0, @f5_producer1]], consumers = [[@f5_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [211600] [1] {tag = "producer0"} : tensor<423200xi8> to tensor<211600xi8>
        %extracted_slice_0 = tensor.extract_slice %25[211600] [211600] [1] {tag = "producer1"} : tensor<423200xi8> to tensor<211600xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<423200xi8> !dmaphop.path tensor<211600xi8>, tensor<211600xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
