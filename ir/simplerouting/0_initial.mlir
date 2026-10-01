module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.control_plan_group_reg_write = 0 : i64, routing.control_plan_op_control_packet = 0 : i64, routing.fullconnect_auto = 1 : i64, routing.kernel_config_offload = 1 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @routing(%arg0: !emitc.ptr<!emitc.opaque<"XAie_DevInst">>, %arg1: memref<256x256xi8>, %arg2: memref<256x256xi8>, %arg3: memref<256x256xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg1 : memref<25088xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<25088xi8> shape = [25088], dim = 1 -> tensor<25088xi8>
    %2 = bufferization.to_tensor %arg2 : memref<2360332xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<2360332xi8> shape = [2360332], dim = 1 -> tensor<2360332xi8>
    %4 = bufferization.to_tensor %arg3 : memref<25088xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<25088xi8> shape = [25088], dim = 1 -> tensor<25088xi8>
    scf.execute_region {
      %6 = routing.partitiontensor %3 : tensor<2360332xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<2360332xi8>
      %7 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %9 = routing.routingextract_data %6, %arg4 : tensor<2360332xi8>, i32 -> tensor<1180166xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f60_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f60_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f60_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f60_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f60_consumer0 {dma_port = 1 : i64, from = @f60_corePortIn0}
        %17 = dmaphop.consumer @f60_consumer1 {dma_port = 1 : i64, from = @f60_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f60_shimPortOut on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f60_shimPortIn on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f60_shimPortIn]], consumers = [[@f60_consumer0, @f60_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<1180166xi8> !dmaphop.path tensor<1180166xi8>, tensor<1180166xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %9 = routing.routingextract_data %6, %arg4 : tensor<2360332xi8>, i32 -> tensor<1180166xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f61_corePortIn0 on %10 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f61_corePortOut0 on %10 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f61_corePortIn1 on %13 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f61_corePortOut1 on %13 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.consumer @f61_consumer0 {dma_port = 1 : i64, from = @f61_corePortIn0}
        %17 = dmaphop.consumer @f61_consumer1 {dma_port = 1 : i64, from = @f61_corePortIn1}
        %18 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %19 = dmaphop.port @f61_shimPortOut on %18 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f61_shimPortIn on %18 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.create_hop %19 -> %11 -> !dmaphop.hop
        %22 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %23 = dmaphop.create_path[%21, %22] {producers = [[@f61_shimPortIn]], consumers = [[@f61_consumer0, @f61_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %23 consumer(%9, %9 at %11, %14) : tensor<1180166xi8> !dmaphop.path tensor<1180166xi8>, tensor<1180166xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %23
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %6 = routing.partitiontensor %1 : tensor<25088xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<25088xi8>
      %7 = routing.partitiontensor %5 : tensor<25088xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<25088xi8>
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %10 = routing.routingextract_data %6, %arg4 : tensor<25088xi8>, i32 -> tensor<12544xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %12 = dmaphop.port @f62_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f62_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %15 = dmaphop.port @f62_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f62_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f62_consumer0 {dma_port = 0 : i64, from = @f62_corePortIn0}
        %18 = dmaphop.consumer @f62_consumer1 {dma_port = 0 : i64, from = @f62_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f62_shimPortOut on %19 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f62_shimPortIn on %19 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f62_shimPortIn]], consumers = [[@f62_consumer0, @f62_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<12544xi8> !dmaphop.path tensor<12544xi8>, tensor<12544xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg4 : tensor<25088xi8>, i32 -> tensor<12544xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %27 = dmaphop.port @f63_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f63_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %30 = dmaphop.port @f63_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f63_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f63_producer0 {dma_port = 0 : i64, tp = @f63_corePortOut0}
        %33 = dmaphop.producer @f63_producer1 {dma_port = 0 : i64, tp = @f63_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f63_shimPortOut on %34 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f63_shimPortIn on %34 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f63_producer0, @f63_producer1]], consumers = [[@f63_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [6272] [1] {tag = "producer0"} : tensor<12544xi8> to tensor<6272xi8>
        %extracted_slice_0 = tensor.extract_slice %25[6272] [6272] [1] {tag = "producer1"} : tensor<12544xi8> to tensor<6272xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<12544xi8> !dmaphop.path tensor<6272xi8>, tensor<6272xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg4: i32):
        %10 = routing.routingextract_data %6, %arg4 : tensor<25088xi8>, i32 -> tensor<12544xi8>
        %11 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %12 = dmaphop.port @f64_corePortIn0 on %11 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.port @f64_corePortOut0 on %11 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %15 = dmaphop.port @f64_corePortIn1 on %14 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.port @f64_corePortOut1 on %14 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.consumer @f64_consumer0 {dma_port = 0 : i64, from = @f64_corePortIn0}
        %18 = dmaphop.consumer @f64_consumer1 {dma_port = 0 : i64, from = @f64_corePortIn1}
        %19 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %20 = dmaphop.port @f64_shimPortOut on %19 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.port @f64_shimPortIn on %19 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %22 = dmaphop.create_hop %20 -> %12 -> !dmaphop.hop
        %23 = dmaphop.create_hop %13 -> %15 -> !dmaphop.hop
        %24 = dmaphop.create_path[%22, %23] {producers = [[@f64_shimPortIn]], consumers = [[@f64_consumer0, @f64_consumer1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %10 into %24 consumer(%10, %10 at %12, %15) : tensor<12544xi8> !dmaphop.path tensor<12544xi8>, tensor<12544xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %24
        %25 = routing.routingextract_data %7, %arg4 : tensor<25088xi8>, i32 -> tensor<12544xi8>
        %26 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %27 = dmaphop.port @f65_corePortIn0 on %26 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %28 = dmaphop.port @f65_corePortOut0 on %26 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %29 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %30 = dmaphop.port @f65_corePortIn1 on %29 { direction = "In", direction_channel = 2 } : !dmaphop.tile -> !dmaphop.port
        %31 = dmaphop.port @f65_corePortOut1 on %29 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %32 = dmaphop.producer @f65_producer0 {dma_port = 0 : i64, tp = @f65_corePortOut0}
        %33 = dmaphop.producer @f65_producer1 {dma_port = 0 : i64, tp = @f65_corePortOut1}
        %34 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %35 = dmaphop.port @f65_shimPortOut on %34 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %36 = dmaphop.port @f65_shimPortIn on %34 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %37 = dmaphop.create_hop %31 -> %36 -> !dmaphop.hop
        %38 = dmaphop.create_hop %28 -> %30 -> !dmaphop.hop
        %39 = dmaphop.create_path[%37, %38] {producers = [[@f65_producer0, @f65_producer1]], consumers = [[@f65_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %25[0] [6272] [1] {tag = "producer0"} : tensor<12544xi8> to tensor<6272xi8>
        %extracted_slice_0 = tensor.extract_slice %25[6272] [6272] [1] {tag = "producer1"} : tensor<12544xi8> to tensor<6272xi8>
        dmaphop.pull %25 from %39 producer(%extracted_slice, %extracted_slice_0 at %27, %30) : tensor<12544xi8> !dmaphop.path tensor<6272xi8>, tensor<6272xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %39
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
