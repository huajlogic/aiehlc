module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"]} {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %c3_i32 = arith.constant 3 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    %1 = routing.routingcreatescheduletensor %0 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %1 : tensor<16x16xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f0_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f0_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %16 = dmaphop.port @f0_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f0_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 3} -> !dmaphop.tile
        %19 = dmaphop.port @f0_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f0_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 3} -> !dmaphop.tile
        %22 = dmaphop.port @f0_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f0_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f0_shimPortOut on %24 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f0_shimPortIn on %24 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f0_shimPortIn]], consumers = [[@f0_corePortIn0, @f0_corePortIn1, @f0_corePortIn2, @f0_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %13 = dmaphop.port @f1_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f1_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f1_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f1_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 4} -> !dmaphop.tile
        %19 = dmaphop.port @f1_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f1_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 4} -> !dmaphop.tile
        %22 = dmaphop.port @f1_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f1_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f1_shimPortOut on %24 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f1_shimPortIn on %24 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f1_shimPortIn]], consumers = [[@f1_corePortIn0, @f1_corePortIn1, @f1_corePortIn2, @f1_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 5} -> !dmaphop.tile
        %13 = dmaphop.port @f2_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f2_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 5} -> !dmaphop.tile
        %16 = dmaphop.port @f2_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f2_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f2_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f2_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 5} -> !dmaphop.tile
        %22 = dmaphop.port @f2_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f2_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f2_shimPortOut on %24 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f2_shimPortIn on %24 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f2_shimPortIn]], consumers = [[@f2_corePortIn0, @f2_corePortIn1, @f2_corePortIn2, @f2_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 6} -> !dmaphop.tile
        %13 = dmaphop.port @f3_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f3_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 6} -> !dmaphop.tile
        %16 = dmaphop.port @f3_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f3_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 6} -> !dmaphop.tile
        %19 = dmaphop.port @f3_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f3_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f3_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f3_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f3_shimPortOut on %24 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f3_shimPortIn on %24 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f3_shimPortIn]], consumers = [[@f3_corePortIn0, @f3_corePortIn1, @f3_corePortIn2, @f3_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %2 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    %3 = routing.routingcreatescheduletensor %2 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %3 : tensor<16x16xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f4_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f4_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %16 = dmaphop.port @f4_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f4_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 3} -> !dmaphop.tile
        %19 = dmaphop.port @f4_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f4_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 3} -> !dmaphop.tile
        %22 = dmaphop.port @f4_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f4_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 6, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f4_shimPortOut on %24 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f4_shimPortIn on %24 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f4_shimPortIn]], consumers = [[@f4_corePortIn0, @f4_corePortIn1, @f4_corePortIn2, @f4_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %13 = dmaphop.port @f5_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f5_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f5_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f5_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 4} -> !dmaphop.tile
        %19 = dmaphop.port @f5_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f5_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 4} -> !dmaphop.tile
        %22 = dmaphop.port @f5_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f5_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 6, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f5_shimPortOut on %24 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f5_shimPortIn on %24 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f5_shimPortIn]], consumers = [[@f5_corePortIn0, @f5_corePortIn1, @f5_corePortIn2, @f5_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 5} -> !dmaphop.tile
        %13 = dmaphop.port @f6_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f6_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 5} -> !dmaphop.tile
        %16 = dmaphop.port @f6_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f6_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f6_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f6_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 5} -> !dmaphop.tile
        %22 = dmaphop.port @f6_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f6_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 7, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f6_shimPortOut on %24 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f6_shimPortIn on %24 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f6_shimPortIn]], consumers = [[@f6_corePortIn0, @f6_corePortIn1, @f6_corePortIn2, @f6_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 6} -> !dmaphop.tile
        %13 = dmaphop.port @f7_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f7_corePortOut0 on %12 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 6} -> !dmaphop.tile
        %16 = dmaphop.port @f7_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f7_corePortOut1 on %15 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 6} -> !dmaphop.tile
        %19 = dmaphop.port @f7_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f7_corePortOut2 on %18 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f7_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f7_corePortOut3 on %21 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 7, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f7_shimPortOut on %24 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f7_shimPortIn on %24 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %25 -> %13 -> !dmaphop.hop
        %28 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f7_shimPortIn]], consumers = [[@f7_corePortIn0, @f7_corePortIn1, @f7_corePortIn2, @f7_corePortIn3]], tee_points = [[]]} -> !dmaphop.path
        dmaphop.push %11 into %31 consumer(%11, %11, %11, %11 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8>, tensor<4x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    %4 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    %5 = routing.routingcreatescheduletensor %4 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %6 = routing.partitiontensor tensor = %5 : tensor<16x16xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %7 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
        %13 = dmaphop.port @f8_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f8_corePortOut0 on %12 { direction = "Out", direction_channel = 0, dmapktid = 1 : i32 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 3} -> !dmaphop.tile
        %16 = dmaphop.port @f8_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f8_corePortOut1 on %15 { direction = "Out", direction_channel = 0, dmapktid = 2 : i32 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 3} -> !dmaphop.tile
        %19 = dmaphop.port @f8_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f8_corePortOut2 on %18 { direction = "Out", direction_channel = 0, dmapktid = 3 : i32 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 3} -> !dmaphop.tile
        %22 = dmaphop.port @f8_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f8_corePortOut3 on %21 { direction = "Out", direction_channel = 0, dmapktid = 4 : i32 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f8_shimPortOut on %24 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f8_shimPortIn on %24 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %23 -> %26 -> !dmaphop.hop
        %28 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f8_corePortOut0, @f8_corePortOut1, @f8_corePortOut2, @f8_corePortOut3]], consumers = [[@f8_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %11[0, 0] [1, 16] [1, 1] {tag = "producer0"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_0 = tensor.extract_slice %11[1, 0] [1, 16] [1, 1] {tag = "producer1"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_1 = tensor.extract_slice %11[2, 0] [1, 16] [1, 1] {tag = "producer2"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_2 = tensor.extract_slice %11[3, 0] [1, 16] [1, 1] {tag = "producer3"} : tensor<4x16xi8> to tensor<1x16xi8>
        dmaphop.pull %11 from %31 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %8 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 4} -> !dmaphop.tile
        %13 = dmaphop.port @f9_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f9_corePortOut0 on %12 { direction = "Out", direction_channel = 0, dmapktid = 5 : i32 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 4} -> !dmaphop.tile
        %16 = dmaphop.port @f9_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f9_corePortOut1 on %15 { direction = "Out", direction_channel = 0, dmapktid = 6 : i32 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 4} -> !dmaphop.tile
        %19 = dmaphop.port @f9_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f9_corePortOut2 on %18 { direction = "Out", direction_channel = 0, dmapktid = 7 : i32 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 4} -> !dmaphop.tile
        %22 = dmaphop.port @f9_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f9_corePortOut3 on %21 { direction = "Out", direction_channel = 0, dmapktid = 8 : i32 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 3, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f9_shimPortOut on %24 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f9_shimPortIn on %24 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %23 -> %26 -> !dmaphop.hop
        %28 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f9_corePortOut0, @f9_corePortOut1, @f9_corePortOut2, @f9_corePortOut3]], consumers = [[@f9_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %11[0, 0] [1, 16] [1, 1] {tag = "producer0"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_0 = tensor.extract_slice %11[1, 0] [1, 16] [1, 1] {tag = "producer1"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_1 = tensor.extract_slice %11[2, 0] [1, 16] [1, 1] {tag = "producer2"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_2 = tensor.extract_slice %11[3, 0] [1, 16] [1, 1] {tag = "producer3"} : tensor<4x16xi8> to tensor<1x16xi8>
        dmaphop.pull %11 from %31 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %9 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c2_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 5} -> !dmaphop.tile
        %13 = dmaphop.port @f10_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f10_corePortOut0 on %12 { direction = "Out", direction_channel = 0, dmapktid = 9 : i32 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 5} -> !dmaphop.tile
        %16 = dmaphop.port @f10_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f10_corePortOut1 on %15 { direction = "Out", direction_channel = 0, dmapktid = 10 : i32 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 5} -> !dmaphop.tile
        %19 = dmaphop.port @f10_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f10_corePortOut2 on %18 { direction = "Out", direction_channel = 0, dmapktid = 11 : i32 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 5} -> !dmaphop.tile
        %22 = dmaphop.port @f10_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f10_corePortOut3 on %21 { direction = "Out", direction_channel = 0, dmapktid = 12 : i32 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f10_shimPortOut on %24 { direction = "Out", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f10_shimPortIn on %24 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %23 -> %26 -> !dmaphop.hop
        %28 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f10_corePortOut0, @f10_corePortOut1, @f10_corePortOut2, @f10_corePortOut3]], consumers = [[@f10_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %11[0, 0] [1, 16] [1, 1] {tag = "producer0"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_0 = tensor.extract_slice %11[1, 0] [1, 16] [1, 1] {tag = "producer1"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_1 = tensor.extract_slice %11[2, 0] [1, 16] [1, 1] {tag = "producer2"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_2 = tensor.extract_slice %11[3, 0] [1, 16] [1, 1] {tag = "producer3"} : tensor<4x16xi8> to tensor<1x16xi8>
        dmaphop.pull %11 from %31 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c3_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_data %6, %arg3 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
        %12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 6} -> !dmaphop.tile
        %13 = dmaphop.port @f11_corePortIn0 on %12 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %14 = dmaphop.port @f11_corePortOut0 on %12 { direction = "Out", direction_channel = 0, dmapktid = 13 : i32 } : !dmaphop.tile -> !dmaphop.port
        %15 = dmaphop.tile{TILETYPE = "core", col = 1, row = 6} -> !dmaphop.tile
        %16 = dmaphop.port @f11_corePortIn1 on %15 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %17 = dmaphop.port @f11_corePortOut1 on %15 { direction = "Out", direction_channel = 0, dmapktid = 14 : i32 } : !dmaphop.tile -> !dmaphop.port
        %18 = dmaphop.tile{TILETYPE = "core", col = 2, row = 6} -> !dmaphop.tile
        %19 = dmaphop.port @f11_corePortIn2 on %18 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %20 = dmaphop.port @f11_corePortOut2 on %18 { direction = "Out", direction_channel = 0, dmapktid = 15 : i32 } : !dmaphop.tile -> !dmaphop.port
        %21 = dmaphop.tile{TILETYPE = "core", col = 3, row = 6} -> !dmaphop.tile
        %22 = dmaphop.port @f11_corePortIn3 on %21 { direction = "In", direction_channel = 0 } : !dmaphop.tile -> !dmaphop.port
        %23 = dmaphop.port @f11_corePortOut3 on %21 { direction = "Out", direction_channel = 0, dmapktid = 16 : i32 } : !dmaphop.tile -> !dmaphop.port
        %24 = dmaphop.tile{TILETYPE = "shim", col = 2, row = 0} -> !dmaphop.tile
        %25 = dmaphop.port @f11_shimPortOut on %24 { direction = "Out", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %26 = dmaphop.port @f11_shimPortIn on %24 { direction = "In", direction_channel = 1 } : !dmaphop.tile -> !dmaphop.port
        %27 = dmaphop.create_hop %23 -> %26 -> !dmaphop.hop
        %28 = dmaphop.create_hop %20 -> %22 -> !dmaphop.hop
        %29 = dmaphop.create_hop %17 -> %19 -> !dmaphop.hop
        %30 = dmaphop.create_hop %14 -> %16 -> !dmaphop.hop
        %31 = dmaphop.create_path[%27, %28, %29, %30] {producers = [[@f11_corePortOut0, @f11_corePortOut1, @f11_corePortOut2, @f11_corePortOut3]], consumers = [[@f11_shimPortOut]], tee_points = [[]]} -> !dmaphop.path
        %extracted_slice = tensor.extract_slice %11[0, 0] [1, 16] [1, 1] {tag = "producer0"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_0 = tensor.extract_slice %11[1, 0] [1, 16] [1, 1] {tag = "producer1"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_1 = tensor.extract_slice %11[2, 0] [1, 16] [1, 1] {tag = "producer2"} : tensor<4x16xi8> to tensor<1x16xi8>
        %extracted_slice_2 = tensor.extract_slice %11[3, 0] [1, 16] [1, 1] {tag = "producer3"} : tensor<4x16xi8> to tensor<1x16xi8>
        dmaphop.pull %11 from %31 producer(%extracted_slice, %extracted_slice_0, %extracted_slice_1, %extracted_slice_2 at %13, %16, %19, %22) : tensor<4x16xi8> !dmaphop.path tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8>, tensor<1x16xi8> !dmaphop.port, !dmaphop.port, !dmaphop.port, !dmaphop.port
        dmaphop.sync %31
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
