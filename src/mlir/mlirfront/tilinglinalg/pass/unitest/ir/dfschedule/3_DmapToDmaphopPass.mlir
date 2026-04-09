module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %1 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f0_corePortIn0 on %10 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f0_corePortOut0 on %10 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %14 = dmaphop.port @f0_corePortIn1 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f0_corePortOut1 on %13 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %17 = dmaphop.port @f0_shimPortOut on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f0_shimPortIn on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.create_hop %17 -> %11 -> !dmaphop.hop
        %20 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %21 = dmaphop.create_path[%19, %20] {producers = [[@f0_shimPortIn]], consumers = [[@f0_corePortIn0, @f0_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %21 consumer(%9, %9 at %11, %14) : tensor<8x16xi8> !dmaphop.path tensor<8x16xi8>, tensor<8x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %21
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %11 = dmaphop.port @f1_corePortIn0 on %10 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f1_corePortOut0 on %10 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f1_corePortIn1 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f1_corePortOut1 on %13 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %17 = dmaphop.port @f1_shimPortOut on %16 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f1_shimPortIn on %16 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.create_hop %17 -> %11 -> !dmaphop.hop
        %20 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %21 = dmaphop.create_path[%19, %20] {producers = [[@f1_shimPortIn]], consumers = [[@f1_corePortIn0, @f1_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %21 consumer(%9, %9 at %11, %14) : tensor<8x16xi8> !dmaphop.path tensor<8x16xi8>, tensor<8x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %21
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %2 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %3 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f2_corePortIn0 on %10 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f2_corePortOut0 on %10 { direction = "Out", direction_channel = 0, dmapktid = 5 : i32 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %14 = dmaphop.port @f2_corePortIn1 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f2_corePortOut1 on %13 { direction = "Out", direction_channel = 0, dmapktid = 6 : i32 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %17 = dmaphop.port @f2_shimPortOut on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f2_shimPortIn on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.create_hop %17 -> %11 -> !dmaphop.hop
        %20 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %21 = dmaphop.create_path[%19, %20] {producers = [[@f2_shimPortIn]], consumers = [[@f2_corePortIn0, @f2_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %21 consumer(%9, %9 at %11, %14) : tensor<8x16xi8> !dmaphop.path tensor<8x16xi8>, tensor<8x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %21
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %11 = dmaphop.port @f3_corePortIn0 on %10 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f3_corePortOut0 on %10 { direction = "Out", direction_channel = 0, dmapktid = 7 : i32 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f3_corePortIn1 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f3_corePortOut1 on %13 { direction = "Out", direction_channel = 0, dmapktid = 8 : i32 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %17 = dmaphop.port @f3_shimPortOut on %16 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f3_shimPortIn on %16 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.create_hop %17 -> %11 -> !dmaphop.hop
        %20 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %21 = dmaphop.create_path[%19, %20] {producers = [[@f3_shimPortIn]], consumers = [[@f3_corePortIn0, @f3_corePortIn1]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %9 into %21 consumer(%9, %9 at %11, %14) : tensor<8x16xi8> !dmaphop.path tensor<8x16xi8>, tensor<8x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %21
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %4 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %5 : tensor<16x16xi8> {
          splitnum = 2,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %11 = dmaphop.port @f4_corePortIn0 on %10 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f4_corePortOut0 on %10 { direction = "Out", direction_channel = 0, dmapktid = 9 : i32 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %14 = dmaphop.port @f4_corePortIn1 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f4_corePortOut1 on %13 { direction = "Out", direction_channel = 0, dmapktid = 10 : i32 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %17 = dmaphop.port @f4_shimPortOut on %16 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f4_shimPortIn on %16 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.create_hop %15 -> %18 -> !dmaphop.hop
        %20 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %21 = dmaphop.create_path[%19, %20] {producers = [[@f4_corePortOut0, @f4_corePortOut1]], consumers = [[@f4_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %9[0, 0] [4, 16] [1, 1] {tag = "producer0"} : tensor<8x16xi8> to tensor<4x16xi8>
        %extracted_slice_0 = tensor.extract_slice %9[4, 0] [4, 16] [1, 1] {tag = "producer1"} : tensor<8x16xi8> to tensor<4x16xi8>
        dmaphop.pull %9 from %21 producer(%extracted_slice, %extracted_slice_0 at %11, %14) : tensor<8x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %21
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %9 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<8x16xi8>
        %10 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %11 = dmaphop.port @f5_corePortIn0 on %10 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %12 = dmaphop.port @f5_corePortOut0 on %10 { direction = "Out", direction_channel = 0, dmapktid = 11 : i32 } : !dmaphop.tile -> !dmaphop.port
        %13 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %14 = dmaphop.port @f5_corePortIn1 on %13 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.port @f5_corePortOut1 on %13 { direction = "Out", direction_channel = 0, dmapktid = 12 : i32 } : !dmaphop.tile -> !dmaphop.port
        %16 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %17 = dmaphop.port @f5_shimPortOut on %16 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.port @f5_shimPortIn on %16 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %19 = dmaphop.create_hop %15 -> %18 -> !dmaphop.hop
        %20 = dmaphop.create_hop %12 -> %14 -> !dmaphop.hop
        %21 = dmaphop.create_path[%19, %20] {producers = [[@f5_corePortOut0, @f5_corePortOut1]], consumers = [[@f5_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %9[0, 0] [4, 16] [1, 1] {tag = "producer0"} : tensor<8x16xi8> to tensor<4x16xi8>
        %extracted_slice_0 = tensor.extract_slice %9[4, 0] [4, 16] [1, 1] {tag = "producer1"} : tensor<8x16xi8> to tensor<4x16xi8>
        dmaphop.pull %9 from %21 producer(%extracted_slice, %extracted_slice_0 at %11, %14) : tensor<8x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port
        dmaphop.sync %21
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
