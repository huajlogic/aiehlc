module attributes {codegen.headers = ["stdint.h", "stdio.h", "custom_lib.h"], routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}} {
  func.func @main(%arg0: memref<32xi8>, %arg1: memref<9286xi8>, %arg2: memref<32xi8>) {
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = routing.routingcreatehwmesh row = 2, col = 2 -> i32
    %1 = bufferization.to_tensor %arg0 : memref<32xi8>
    %2 = routing.routingcreatescheduletensor %1 : tensor<32xi8> shape = [32], dim = 1 -> tensor<32xi8>
    %3 = bufferization.to_tensor %arg1 : memref<9286xi8>
    %4 = routing.routingcreatescheduletensor %3 : tensor<9286xi8> shape = [9286], dim = 1 -> tensor<9286xi8>
    %5 = bufferization.to_tensor %arg2 : memref<32xi8>
    %6 = routing.routingcreatescheduletensor %5 : tensor<32xi8> shape = [32], dim = 1 -> tensor<32xi8>
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 2, splitaxis = "col" : i32 -> i32
      %8 = routing.partitiontensor %4 : tensor<9286xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">
} -> tensor<9286xi8>
      %9 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_tiles %7, %arg3 : i32, i32 -> i32
        %12 = routing.routingextract_data %8, %arg3 : tensor<9286xi8>, i32 -> tensor<4643xi8>
        %13 = routing.routingcreatehwiowithtarget targettilelist = %11 : i32 {direction = "input", iotype = "mem2"} -> i32
        %14 = routing.routingmovedatabyio tensordata = %12, hwiowithtarget = %13 : tensor<4643xi8>, i32 -> i32
        "routing.yield"() : () -> ()
      }
      %10 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %11 = routing.routingextract_tiles %7, %arg3 : i32, i32 -> i32
        %12 = routing.routingextract_data %8, %arg3 : tensor<9286xi8>, i32 -> tensor<4643xi8>
        %13 = routing.routingcreatehwiowithtarget targettilelist = %11 : i32 {direction = "input", iotype = "mem2"} -> i32
        %14 = routing.routingmovedatabyio tensordata = %12, hwiowithtarget = %13 : tensor<4643xi8>, i32 -> i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 2, splitaxis = "row" : i32 -> i32
      %8 = routing.partitiontensor %2 : tensor<32xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<32xi8>
      %9 = routing.partitiontensor %6 : tensor<32xi8> {
  partition = #routing.partition<splitnum = 2, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">
} -> tensor<32xi8>
      %10 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c0_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %12 = routing.routingextract_tiles %7, %arg3 : i32, i32 -> i32
        %13 = routing.routingextract_data %8, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %14 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
        %15 = routing.routingmovedatabyio tensordata = %13, hwiowithtarget = %14 : tensor<16xi8>, i32 -> i32
        %16 = routing.routingextract_data %9, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %17 = routing.routingroutinggatherout tilelist = %12, tensordata = %16 : i32, tensor<16xi8> -> tensor<16xi8>
        %18 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "output", iotype = "mem2"} -> i32
        %19 = routing.routingmovedatabyio tensordata = %17, hwiowithtarget = %18 : tensor<16xi8>, i32 -> i32
        "routing.yield"() : () -> ()
      }
      %11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %c1_i32 : i32) -> i32{
      ^bb0(%arg3: i32):
        %12 = routing.routingextract_tiles %7, %arg3 : i32, i32 -> i32
        %13 = routing.routingextract_data %8, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %14 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
        %15 = routing.routingmovedatabyio tensordata = %13, hwiowithtarget = %14 : tensor<16xi8>, i32 -> i32
        %16 = routing.routingextract_data %9, %arg3 : tensor<32xi8>, i32 -> tensor<16xi8>
        %17 = routing.routingroutinggatherout tilelist = %12, tensordata = %16 : i32, tensor<16xi8> -> tensor<16xi8>
        %18 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "output", iotype = "mem2"} -> i32
        %19 = routing.routingmovedatabyio tensordata = %17, hwiowithtarget = %18 : tensor<16xi8>, i32 -> i32
        "routing.yield"() : () -> ()
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
