module attributes {routing.effective_k = 64 : i64, routing.full_k = 4096 : i64, routing.fullconnect_auto = 1 : i64, routing.k_rounds = 64 : i64, routing.m_rounds = 256 : i64, routing.n_rounds = 256 : i64, routing.pp_depth_map = {tensor_0 = 2 : i32, tensor_1 = 2 : i32, tensor_2 = 2 : i32}, routing.tile_cols = 1024 : i64, routing.tile_m = 16 : i64, routing.tile_n = 16 : i64, routing.tile_rows = 1024 : i64} {
  func.func @main(%arg0: memref<4096x4096xi8>, %arg1: memref<4096x4096xi8>, %arg2: memref<4096x4096xi8>) {
    %0 = routing.routingcreatehwmesh row = 4, col = 4 partition = 0, 3, 0, 6 -> i32
    %1 = bufferization.to_tensor %arg0 : memref<4096x4096xi8>
    %2 = routing.routingcreatescheduletensor %1 : tensor<4096x4096xi8> shape = [4096, 4096], dim = 2 -> tensor<4096x4096xi8>
    %3 = bufferization.to_tensor %arg1 : memref<4096x4096xi8>
    %4 = routing.routingcreatescheduletensor %3 : tensor<4096x4096xi8> shape = [4096, 4096], dim = 2 -> tensor<4096x4096xi8>
    %5 = bufferization.to_tensor %arg2 : memref<4096x4096xi8>
    %6 = routing.routingcreatescheduletensor %5 : tensor<4096x4096xi8> shape = [4096, 4096], dim = 2 -> tensor<4096x4096xi8>
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "col" : i32 -> i32
      %8 = routing.partitiontensor %4 : tensor<4096x4096xi8> {
  partition = #routing.partition<splitnum = 4, splitdim = 0, hwAxisOwner = "col", replicateOn = "row", singleTileOwner = "">,
  tiling = #routing.tiling<d0 = #routing.dim<outer = #routing.level<base = 4096, total = 4096, slice = 1024, step = 1024, rounds = 4, slice_tiling = #routing.level<base = 1024, total = 4096, slice = 16, step = 16, rounds = 256>>>, d1 = #routing.dim<outer = #routing.level<base = 4096, total = 4096, slice = 4096, step = 4096, rounds = 1, slice_tiling = #routing.level<base = 4096, total = 4096, slice = 64, step = 64, rounds = 64>>>>
} -> tensor<4096x4096xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %9 = arith.index_cast %arg3 : index to i32
        %10 = routing.RoutingCreate<Memo = "col"> ( scf_idx = %9 : i32) -> i32{
        ^bb0(%arg4: i32):
          %11 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %12 = routing.routingextract_data %8, %arg4 : tensor<4096x4096xi8>, i32 -> tensor<1024x4096xi8>
          %13 = routing.routingcreatehwiowithtarget targettilelist = %11 : i32 {direction = "input", iotype = "mem2"} -> i32
          %14 = routing.routingmovedatabyio tensordata = %12, hwiowithtarget = %13 : tensor<1024x4096xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "col"}
    scf.execute_region {
      %7 = routing.partitionmesh mesh = %0, splitnum = 4, splitaxis = "row" : i32 -> i32
      %8 = routing.partitiontensor %2 : tensor<4096x4096xi8> {
  partition = #routing.partition<splitnum = 4, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">,
  tiling = #routing.tiling<d0 = #routing.dim<outer = #routing.level<base = 4096, total = 4096, slice = 1024, step = 1024, rounds = 4, slice_tiling = #routing.level<base = 1024, total = 4096, slice = 16, step = 16, rounds = 256>>>, d1 = #routing.dim<outer = #routing.level<base = 4096, total = 4096, slice = 4096, step = 4096, rounds = 1, slice_tiling = #routing.level<base = 4096, total = 4096, slice = 64, step = 64, rounds = 64>>>>
} -> tensor<4096x4096xi8>
      %9 = routing.partitiontensor %6 : tensor<4096x4096xi8> {
  partition = #routing.partition<splitnum = 4, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", singleTileOwner = "">,
  tiling = #routing.tiling<d0 = #routing.dim<outer = #routing.level<base = 4096, total = 4096, slice = 1024, step = 1024, rounds = 4, slice_tiling = #routing.level<base = 1024, total = 4096, slice = 16, step = 16, rounds = 256>>>, d1 = #routing.dim<outer = #routing.level<base = 4096, total = 4096, slice = 1024, step = 1024, rounds = 4, slice_tiling = #routing.level<base = 1024, total = 4096, slice = 16, step = 16, rounds = 256>>>>
} -> tensor<4096x4096xi8>
      %c0 = arith.constant 0 : index
      %c4 = arith.constant 4 : index
      %c1 = arith.constant 1 : index
      scf.for %arg3 = %c0 to %c4 step %c1 {
        %10 = arith.index_cast %arg3 : index to i32
        %11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %10 : i32) -> i32{
        ^bb0(%arg4: i32):
          %12 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
          %13 = routing.routingextract_data %8, %arg4 : tensor<4096x4096xi8>, i32 -> tensor<1024x4096xi8>
          %14 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
          %15 = routing.routingmovedatabyio tensordata = %13, hwiowithtarget = %14 : tensor<1024x4096xi8>, i32 -> i32
          %16 = routing.routingextract_data %9, %arg4 : tensor<4096x4096xi8>, i32 -> tensor<1024x4096xi8>
          %17 = routing.routingroutinggatherout tilelist = %12, tensordata = %16 : i32, tensor<1024x4096xi8> -> tensor<1024x4096xi8>
          %18 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "output", iotype = "mem2"} -> i32
          %19 = routing.routingmovedatabyio tensordata = %17, hwiowithtarget = %18 : tensor<1024x4096xi8>, i32 -> i32
          "routing.yield"() : () -> ()
        }
      }
      scf.yield
    } {routing_memo = "row"}
    return
  }
}
