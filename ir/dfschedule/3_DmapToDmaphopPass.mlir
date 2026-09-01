module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @main(%arg0: memref<32xi8>, %arg1: memref<9286xi8>, %arg2: memref<32xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<32xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<32xi8> shape = [32], dim = 1 -> tensor<32xi8>
    %2 = bufferization.to_tensor %arg1 : memref<9286xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<9286xi8> shape = [9286], dim = 1 -> tensor<9286xi8>
    %4 = bufferization.to_tensor %arg2 : memref<32xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<32xi8> shape = [32], dim = 1 -> tensor<32xi8>
    scf.execute_region {
      %6 = routing.partitiontensor %3 : tensor<9286xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<9286xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<9286xi8>, i32 -> tensor<4643xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f114_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f114_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f114_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f114_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f114_consumer0 {dma_port = 1 : i64, from = @f114_corePortIn0}
        %17 = dmaphop.consumer @f114_consumer1 {dma_port = 1 : i64, from = @f114_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f114_shimPortOut on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f114_shimPortIn on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f114_shimPortIn]], consumers = [[@f114_consumer0, @f114_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<4643xi8> !dmaphop.path tensor<4643xi8>, tensor<4643xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<9286xi8>, i32 -> tensor<4643xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f115_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f115_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f115_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f115_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f115_consumer0 {dma_port = 1 : i64, from = @f115_corePortIn0}
        %17 = dmaphop.consumer @f115_consumer1 {dma_port = 1 : i64, from = @f115_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f115_shimPortOut on %18 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f115_shimPortIn on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f115_shimPortIn]], consumers = [[@f115_consumer0, @f115_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<4643xi8> !dmaphop.path tensor<4643xi8>, tensor<4643xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor %1 : tensor<32xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<32xi8>
      %7 = routing.partitiontensor %5 : tensor<32xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<32xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %10 = routing.routingextract_data %6, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %12 = dmaphop.port @f116_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f116_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %15 = dmaphop.port @f116_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f116_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f116_consumer0 {dma_port = 0 : i64, from = @f116_corePortIn0}
        %18 = dmaphop.consumer @f116_consumer1 {dma_port = 0 : i64, from = @f116_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f116_shimPortOut on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f116_shimPortIn on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f116_shimPortIn]], consumers = [[@f116_consumer0, @f116_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<16xi8> !dmaphop.path tensor<16xi8>, tensor<16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %27 = dmaphop.port @f117_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f117_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %30 = dmaphop.port @f117_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f117_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f117_producer0 {dma_port = 0 : i64, tp = @f117_corePortOut0}
        %33 = dmaphop.producer @f117_producer1 {dma_port = 0 : i64, tp = @f117_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f117_shimPortOut on %34 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f117_shimPortIn on %34 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f117_producer0, @f117_producer1]], consumers = [[@f117_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [8] [1] {tag = "producer0"} : tensor<16xi8> to tensor<8xi8>
        %extracted_slice_0 = tensor.extract_slice %25[8] [8] [1] {tag = "producer1"} : tensor<16xi8> to tensor<8xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<16xi8> !dmaphop.path tensor<8xi8>, tensor<8xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %10 = routing.routingextract_data %6, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %12 = dmaphop.port @f118_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f118_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %15 = dmaphop.port @f118_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f118_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f118_consumer0 {dma_port = 0 : i64, from = @f118_corePortIn0}
        %18 = dmaphop.consumer @f118_consumer1 {dma_port = 0 : i64, from = @f118_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f118_shimPortOut on %19 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f118_shimPortIn on %19 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f118_shimPortIn]], consumers = [[@f118_consumer0, @f118_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<16xi8> !dmaphop.path tensor<16xi8>, tensor<16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %27 = dmaphop.port @f119_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f119_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %30 = dmaphop.port @f119_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f119_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f119_producer0 {dma_port = 0 : i64, tp = @f119_corePortOut0}
        %33 = dmaphop.producer @f119_producer1 {dma_port = 0 : i64, tp = @f119_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f119_shimPortOut on %34 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f119_shimPortIn on %34 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f119_producer0, @f119_producer1]], consumers = [[@f119_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [8] [1] {tag = "producer0"} : tensor<16xi8> to tensor<8xi8>
        %extracted_slice_0 = tensor.extract_slice %25[8] [8] [1] {tag = "producer1"} : tensor<16xi8> to tensor<8xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<16xi8> !dmaphop.path tensor<8xi8>, tensor<8xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
