module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @main(%arg0: memref<32xi8>, %arg1: memref<9292xi8>, %arg2: memref<32xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<32xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<32xi8> shape = [32], dim = 1 -> tensor<32xi8>
    %2 = bufferization.to_tensor %arg1 : memref<9292xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<9292xi8> shape = [9292], dim = 1 -> tensor<9292xi8>
    %4 = bufferization.to_tensor %arg2 : memref<32xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<32xi8> shape = [32], dim = 1 -> tensor<32xi8>
    scf.execute_region {
      %6 = routing.partitiontensor %3 : tensor<9292xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<9292xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<9292xi8>, i32 -> tensor<4646xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f156_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f156_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f156_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f156_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f156_consumer0 {dma_port = 1 : i64, from = @f156_corePortIn0}
        %17 = dmaphop.consumer @f156_consumer1 {dma_port = 1 : i64, from = @f156_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f156_shimPortOut on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f156_shimPortIn on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f156_shimPortIn]], consumers = [[@f156_consumer0, @f156_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<4646xi8> !dmaphop.path tensor<4646xi8>, tensor<4646xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<9292xi8>, i32 -> tensor<4646xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f157_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f157_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f157_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f157_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f157_consumer0 {dma_port = 1 : i64, from = @f157_corePortIn0}
        %17 = dmaphop.consumer @f157_consumer1 {dma_port = 1 : i64, from = @f157_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f157_shimPortOut on %18 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f157_shimPortIn on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f157_shimPortIn]], consumers = [[@f157_consumer0, @f157_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<4646xi8> !dmaphop.path tensor<4646xi8>, tensor<4646xi8> !dmaphop.port, !dmaphop.port
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
        %12 = dmaphop.port @f158_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f158_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %15 = dmaphop.port @f158_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f158_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f158_consumer0 {dma_port = 0 : i64, from = @f158_corePortIn0}
        %18 = dmaphop.consumer @f158_consumer1 {dma_port = 0 : i64, from = @f158_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f158_shimPortOut on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f158_shimPortIn on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f158_shimPortIn]], consumers = [[@f158_consumer0, @f158_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<16xi8> !dmaphop.path tensor<16xi8>, tensor<16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %27 = dmaphop.port @f159_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f159_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %30 = dmaphop.port @f159_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f159_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f159_producer0 {dma_port = 0 : i64, tp = @f159_corePortOut0}
        %33 = dmaphop.producer @f159_producer1 {dma_port = 0 : i64, tp = @f159_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f159_shimPortOut on %34 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f159_shimPortIn on %34 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f159_producer0, @f159_producer1]], consumers = [[@f159_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
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
        %12 = dmaphop.port @f160_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f160_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %15 = dmaphop.port @f160_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f160_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f160_consumer0 {dma_port = 0 : i64, from = @f160_corePortIn0}
        %18 = dmaphop.consumer @f160_consumer1 {dma_port = 0 : i64, from = @f160_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f160_shimPortOut on %19 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f160_shimPortIn on %19 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f160_shimPortIn]], consumers = [[@f160_consumer0, @f160_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<16xi8> !dmaphop.path tensor<16xi8>, tensor<16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %27 = dmaphop.port @f161_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f161_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %30 = dmaphop.port @f161_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f161_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f161_producer0 {dma_port = 0 : i64, tp = @f161_corePortOut0}
        %33 = dmaphop.producer @f161_producer1 {dma_port = 0 : i64, tp = @f161_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f161_shimPortOut on %34 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f161_shimPortIn on %34 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f161_producer0, @f161_producer1]], consumers = [[@f161_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
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
