module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @routing(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: memref<256xi8>, %arg2: memref<158xi8>, %arg3: memref<256xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg1 : memref<256xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<256xi8> shape = [256], dim = 1 -> tensor<256xi8>
    %2 = bufferization.to_tensor %arg2 : memref<158xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<158xi8> shape = [158], dim = 1 -> tensor<158xi8>
    %4 = bufferization.to_tensor %arg3 : memref<256xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<256xi8> shape = [256], dim = 1 -> tensor<256xi8>
    scf.execute_region {
      %6 = routing.partitiontensor %3 : tensor<158xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<158xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %9 = routing.routingextract_data %6, %arg4 : tensor<158xi8>, i32 -> tensor<79xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f24_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f24_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f24_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f24_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f24_consumer0 {dma_port = 1 : i64, from = @f24_corePortIn0}
        %17 = dmaphop.consumer @f24_consumer1 {dma_port = 1 : i64, from = @f24_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f24_shimPortOut on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f24_shimPortIn on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f24_shimPortIn]], consumers = [[@f24_consumer0, @f24_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<79xi8> !dmaphop.path tensor<79xi8>, tensor<79xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %9 = routing.routingextract_data %6, %arg4 : tensor<158xi8>, i32 -> tensor<79xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f25_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f25_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f25_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f25_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f25_consumer0 {dma_port = 1 : i64, from = @f25_corePortIn0}
        %17 = dmaphop.consumer @f25_consumer1 {dma_port = 1 : i64, from = @f25_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f25_shimPortOut on %18 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f25_shimPortIn on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f25_shimPortIn]], consumers = [[@f25_consumer0, @f25_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<79xi8> !dmaphop.path tensor<79xi8>, tensor<79xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor %1 : tensor<256xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<256xi8>
      %7 = routing.partitiontensor %5 : tensor<256xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<256xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %10 = routing.routingextract_data %6, %arg4 : tensor<256xi8>, i32 -> tensor<128xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %12 = dmaphop.port @f26_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f26_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %15 = dmaphop.port @f26_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f26_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f26_consumer0 {dma_port = 0 : i64, from = @f26_corePortIn0}
        %18 = dmaphop.consumer @f26_consumer1 {dma_port = 0 : i64, from = @f26_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f26_shimPortOut on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f26_shimPortIn on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f26_shimPortIn]], consumers = [[@f26_consumer0, @f26_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<128xi8> !dmaphop.path tensor<128xi8>, tensor<128xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg4 : tensor<256xi8>, i32 -> tensor<128xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %27 = dmaphop.port @f27_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f27_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %30 = dmaphop.port @f27_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f27_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f27_producer0 {dma_port = 0 : i64, tp = @f27_corePortOut0}
        %33 = dmaphop.producer @f27_producer1 {dma_port = 0 : i64, tp = @f27_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f27_shimPortOut on %34 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f27_shimPortIn on %34 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f27_producer0, @f27_producer1]], consumers = [[@f27_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [64] [1] {tag = "producer0"} : tensor<128xi8> to tensor<64xi8>
        %extracted_slice_0 = tensor.extract_slice %25[64] [64] [1] {tag = "producer1"} : tensor<128xi8> to tensor<64xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<128xi8> !dmaphop.path tensor<64xi8>, tensor<64xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %10 = routing.routingextract_data %6, %arg4 : tensor<256xi8>, i32 -> tensor<128xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %12 = dmaphop.port @f28_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f28_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %15 = dmaphop.port @f28_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f28_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f28_consumer0 {dma_port = 0 : i64, from = @f28_corePortIn0}
        %18 = dmaphop.consumer @f28_consumer1 {dma_port = 0 : i64, from = @f28_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f28_shimPortOut on %19 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f28_shimPortIn on %19 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f28_shimPortIn]], consumers = [[@f28_consumer0, @f28_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<128xi8> !dmaphop.path tensor<128xi8>, tensor<128xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg4 : tensor<256xi8>, i32 -> tensor<128xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %27 = dmaphop.port @f29_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f29_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %30 = dmaphop.port @f29_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f29_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f29_producer0 {dma_port = 0 : i64, tp = @f29_corePortOut0}
        %33 = dmaphop.producer @f29_producer1 {dma_port = 0 : i64, tp = @f29_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f29_shimPortOut on %34 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f29_shimPortIn on %34 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f29_producer0, @f29_producer1]], consumers = [[@f29_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [64] [1] {tag = "producer0"} : tensor<128xi8> to tensor<64xi8>
        %extracted_slice_0 = tensor.extract_slice %25[64] [64] [1] {tag = "producer1"} : tensor<128xi8> to tensor<64xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<128xi8> !dmaphop.path tensor<64xi8>, tensor<64xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
