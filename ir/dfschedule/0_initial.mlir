module attributes {routing.effective_k = 64 : i64, routing.full_k = 512 : i64, routing.k_rounds = 8 : i64, routing.m_rounds = 8 : i64, routing.n_rounds = 8 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}, routing.tile_cols = 128 : i64, routing.tile_m = 16 : i64, routing.tile_n = 16 : i64, routing.tile_rows = 128 : i64} {
  func.func @main(%arg0: memref<512x512xi8>, %arg1: memref<512x512xi8>, %arg2: memref<512x512xi8>) {
    %0 = routing.routingcreatehwmesh row = 4, col = 4 partition = 3, 6, 0, 6 -> i32
    %1 = bufferization.to_tensor %arg0 : memref<512x512xi8>
    %2 = routing.routingcreatescheduletensor %1 : tensor<512x512xi8> shape = [512, 512], dim = 2 -> tensor<512x512xi8>
    %3 = bufferization.to_tensor %arg1 : memref<512x512xi8>
    %4 = routing.routingcreatescheduletensor %3 : tensor<512x512xi8> shape = [512, 512], dim = 2 -> tensor<512x512xi8>
    %5 = bufferization.to_tensor %arg2 : memref<512x512xi8>
    %6 = routing.routingcreatescheduletensor %5 : tensor<512x512xi8> shape = [512, 512], dim = 2 -> tensor<512x512xi8>
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "col" : i32 -> i32
      %8 = routing.partitiontensor tensor = %4 : tensor<512x512xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "col",
          replicate_on = "row",
          single_tile_owner = ""
     } -> tensor<512x512xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %9 = arith.index_cast %arg3 : index to i32
        %10 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %9 : i32) -> i32{
        ^bb0(%arg4: i32):
          %11 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %12 = routing.routingextract_data %8, %arg4 : tensor<512x512xi8>, i32 -> tensor<128x512xi8>
          %13 = routing.routingcreatehwiowithtarget targettilelist = %11 : i32 {direction = "input", iotype = "mem2"} -> i32
          %14 = routing.routingmovedatabyio tensordata = %12, hwiowithtarget = %13 : tensor<128x512xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "row" : i32 -> i32
      %8 = routing.partitiontensor tensor = %2 : tensor<512x512xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<512x512xi8>
      %9 = routing.partitiontensor tensor = %6 : tensor<512x512xi8> {
          splitnum = 4,
          splitdim = 0,
          hw_axis_owner = "row",
          replicate_on = "col",
          single_tile_owner = ""
     } -> tensor<512x512xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %10 = arith.index_cast %arg3 : index to i32
        %11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %10 : i32) -> i32{
        ^bb0(%arg4: i32):
          %12 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %13 = routing.routingextract_data %8, %arg4 : tensor<512x512xi8>, i32 -> tensor<128x512xi8>
          %14 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
          %15 = routing.routingmovedatabyio tensordata = %13, hwiowithtarget = %14 : tensor<128x512xi8>, i32 -> i32
          %16 = routing.routingextract_data %9, %arg4 : tensor<512x512xi8>, i32 -> tensor<128x512xi8>
          %17 = routing.routingroutinggatherout tilelist = %12, tensordata = %16 : i32, tensor<128x512xi8> -> tensor<128x512xi8>
          %18 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "output", iotype = "mem2"} -> i32
          %19 = routing.routingmovedatabyio tensordata = %17, hwiowithtarget = %18 : tensor<128x512xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
