module {
  func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>) {
    %0 = routing.routingcreatehwmesh row = 4, col = 4 -> i32
    %1 = bufferization.to_tensor %arg0 : memref<16x16xi8>
    %2 = routing.routingcreatescheduletensor %1 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "row" : i32 -> i32
      %8 = routing.partitiontensor tensor = %2 : tensor<16x16xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %9 = arith.index_cast %arg3 : index to i32
        %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %9 : i32) -> i32{
        ^bb0(%arg4: i32):
          %11 = routing.routingextract_data %8, %arg4 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
          %12 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %13 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
          %14 = routing.routingmovedatabyio tensordata = %11, hwiowithtarget = %13 : tensor<4x16xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "row"}
    %3 = bufferization.to_tensor %arg1 : memref<16x16xi8>
    %4 = routing.routingcreatescheduletensor %3 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "row" : i32 -> i32
      %8 = routing.partitiontensor tensor = %4 : tensor<16x16xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %9 = arith.index_cast %arg3 : index to i32
        %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %9 : i32) -> i32{
        ^bb0(%arg4: i32):
          %11 = routing.routingextract_data %8, %arg4 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
          %12 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %13 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
          %14 = routing.routingmovedatabyio tensordata = %11, hwiowithtarget = %13 : tensor<4x16xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "row"}
    %5 = bufferization.to_tensor %arg2 : memref<16x16xi8>
    %6 = routing.routingcreatescheduletensor %5 : tensor<16x16xi8> shape = [16, 16], dim = 2 -> tensor<16x16xi8>
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "row" : i32 -> i32
      %8 = routing.partitiontensor tensor = %6 : tensor<16x16xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<16x16xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %9 = arith.index_cast %arg3 : index to i32
        %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %9 : i32) -> i32{
        ^bb0(%arg4: i32):
          %11 = routing.routingextract_data %8, %arg4 : tensor<16x16xi8>, i32 -> tensor<4x16xi8>
          %12 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %13 = routing.routingroutinggatherout tilelist = %12, tensordata = %11 : i32, tensor<4x16xi8> -> tensor<4x16xi8>
          %14 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "output", iotype = "mem2"} -> i32
          %15 = routing.routingmovedatabyio tensordata = %13, hwiowithtarget = %14 : tensor<4x16xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
