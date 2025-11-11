#ifndef dfschedule_OPS
#define dfschedule_OPS

include "mlir/Dialect/Arith/IR/ArithBase.td"
include "mlir/Dialect/MemRef/IR/MemRefBase.td"
include "mlir/Interfaces/CastInterfaces.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/CopyOpInterface.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/MemorySlotInterfaces.td"
include "mlir/Interfaces/ShapedOpInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/ViewLikeInterface.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td" // Added from dskernelop.td

include "mlir/IR/BuiltinTypes.td"
include "dfscheduletype.td"
// You may need to merge dskerneltype.td into dfscheduletype.td
// and ensure types like dfschedule_LockType are defined.

// Base traits helpers
//def HasRecursiveSideEffects : Trait<"HasRecursiveSideEffects">;

def dfschedule_FuncOp : dfscheduleop<"func",[IsolatedFromAbove, SymbolTable, Symbol]>
{
    let summary = "Defines a function in the Starplat Dialect";
    let description = [{This operation represents a function definiton in the Starplat dialect.
                        It contains a name, other related arguments and an optional return type.
                        It has a single region for the function body.
                        }];

  let arguments = (ins 
                    SymbolNameAttr:$sym_name,
                    TypeAttrOf<FunctionType>:$funcType
                  );

  let regions = (region AnyRegion:$body);
}

// amd.host.alloc_device_mem
def dfschedule_AllocDeviceMemOp : dfscheduleop< "alloc_device_mem", []> {
  let summary = "Allocate device global memory";
  let arguments = (ins);
  let results   = (outs AnyMemRef:$memref);
  let assemblyFormat = "attr-dict `:` type($memref)";
}

// amd.host.free_device_mem
def dfschedule_FreeDeviceMemOp : dfscheduleop< "free_device_mem", []> {
  let summary = "Free device global memory";
  let arguments = (ins AnyMemRef:$memref);
  let results   = (outs);
  let assemblyFormat = "$memref attr-dict `:` type($memref)";
}

// amd.host.copy_h2d_async
def dfschedule_CopyH2DAsyncOp : dfscheduleop< "copy_h2d_async",
  [MemoryEffects<[MemWrite]>]> {
  let summary = "Async copy Host->Device";
  let arguments = (ins AnyMemRef:$host, AnyMemRef:$device);
  let results   = (outs dfschedule_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getViaAttrName() { return "via"; }  // Flow_ShimEndpointAttr
  }];
  let assemblyFormat = [{
    $host `,` $device  attr-dict `:` `(` type($host) `,` type($device) `)` `->` type($event)
  }];
}

// amd.host.copy_d2h_async
def dfschedule_CopyD2HAsyncOp : dfscheduleop< "copy_d2h_async",
  [MemoryEffects<[MemRead]>]> {
  let summary = "Async copy Device->Host";
  let arguments = (ins AnyMemRef:$device, AnyMemRef:$host);
  let results   = (outs dfschedule_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getViaAttrName() { return "via"; }
  }];
  let assemblyFormat = [{
    $device `,` $host attr-dict `:` `(` type($device) `,` type($host) `)` `->` type($event)
  }];
}

def dfschedule_GetTileHandleOp : dfscheduleop<"get_tile_handle"> {
  let summary = "Gets a runtime handle to a physical tile by coordinates.";
  let arguments = (ins
    I32Attr:$col,
    I32Attr:$row
  );
  let results = (outs dfschedule_TileHandleType:$handle);
  let assemblyFormat = "attr-dict `->` type($handle)";
}

def dfschedule_GetStreamHandleOp : dfscheduleop<"get_stream_handle"> {
  let summary = "Gets a runtime handle for a statically defined stream route contract.";
  let arguments = (ins
    SymbolRefAttr:$route // The contract: @my_routes::@route_A
  );
  let results = (outs dfschedule_StreamType:$stream);
  let assemblyFormat = "$route attr-dict `->` type($stream)";
}

def dfschedule_GetPacketIdOp : dfscheduleop<"get_packet_id"> {
  let summary = "Gets a runtime handle for a statically defined stream route contract.";
  let arguments = (ins
    SymbolRefAttr:$route // The contract: @my_routes::@route_A
  );
  let results = (outs dfschedule_PacketType:$packetid);
  let assemblyFormat = "$route attr-dict `->` type($packetid)";
}

def dfschedule_LaunchKernelAsyncOp : dfscheduleop< "launch_kernel_async"> {
  let summary = "Launch a device kernel on a tile asynchronously";
  let arguments = (ins Variadic<AnyType>:$operands);
  let results   = (outs dfschedule_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getOnTileAttrName() { return "on_tile"; } // AMD_TileAttr
    static StringRef getWaitDepsAttrName() { return "wait"; }  // Array of dfschedule_EventType
    static StringRef getCalleeAttrName() { return "callee"; }  // SymbolRefAttr
  }];
  let assemblyFormat = [{
     `(` $operands `)` attr-dict `:` `(` type($operands) `)` `->` type($event)
  }];
}

def dfschedule_WaitOp : dfscheduleop< "wait", []> {
  let summary = "Wait for one or more events to complete";
  // accept a variadic list of event operands so builders accept ValueRange
  let arguments = (ins Variadic<dfschedule_EventType>:$events);
  let results   = (outs);
  let assemblyFormat = "$events attr-dict `:` `(` type($events) `)`";
}

// ---- Ops from dskernelop.td ----

def dfschedule_LockInitOp : dfscheduleop<"lock_init"> {
  let summary = "Create/init a kernel-local lock (initial count)";
  let arguments = (ins I64Attr:$count);
  let results   = (outs dfschedule_LockType:$lock);
  let assemblyFormat = "attr-dict `(` $count `)` `->` type($lock)";
}

def dfschedule_LaunchDmaS2MLoopOp : dfscheduleop<"launch_dma_s2m_loop"> {
  let summary = "Launch a local DMA s2m ping-pong loop that listens on a packet id";
  let arguments = (ins 
    AnyMemRef:$ping, 
    AnyMemRef:$pong, 
    I32:$listen_on_packet_id, 
    dfschedule_LockType:$ping_acquire_lock, 
    dfschedule_LockType:$pong_acquire_lock,
    dfschedule_LockType:$ping_release_lock,
    dfschedule_LockType:$pong_release_lock
  );
  let regions = (region AnyRegion:$body);
  let assemblyFormat = "$ping `:` type($ping) `,` $pong `:` type($pong) `,` $listen_on_packet_id `,` $ping_acquire_lock `,` $pong_acquire_lock `,` $ping_release_lock `,` $pong_release_lock attr-dict-with-keyword $body";
  let extraClassDeclaration = [{
    static StringRef getListenAttrName() { return "listen_on_packet_id"; }
    static StringRef getPingAcquireLockName() { return "ping_acquire_lock"; }
    static StringRef getPongAcquireLockName() { return "pong_acquire_lock"; }
    static StringRef getPingReleaseLockName() { return "ping_release_lock"; }
    static StringRef getPongReleaseLockName() { return "pong_release_lock"; }
  }];
}

def dfschedule_AcquireLockOp : dfscheduleop<"acquire_lock"> {
  let summary = "Acquire a kernel lock for a token";
  let arguments = (ins dfschedule_LockType:$lock, I32:$token);
  let results   = (outs);
  let assemblyFormat = "$lock `,` $token attr-dict";
}

def dfschedule_ReleaseLockOp : dfscheduleop<"release_lock"> {
  let summary = "Release a kernel lock for a token";
  let arguments = (ins dfschedule_LockType:$lock, I32:$token);
  let results   = (outs);
  let assemblyFormat = "$lock `,` $token attr-dict";
}

def dfschedule_ComputeOp : dfscheduleop<"compute"> {
  let summary = "Perform computation on a buffer";
  let description = [{
    This operation represents a compute kernel that processes data from a memory buffer.
  }];
  let arguments = (ins AnyMemRef:$buffer);
  let results = (outs);
  let assemblyFormat = "$buffer `:` type($buffer) attr-dict";
}

def dfschedule_L2PipelineG2sOp : dfscheduleop<"pipeline_g2s", []> {
  let summary = "Abstracts a Gmem->Smem ping-pong buffer dataflow pipeline.";
  let arguments = (ins
    AnyMemRef:$gmem_buffer,
    AnyMemRef:$ping_buffer,
    AnyMemRef:$pong_buffer
  );
  let results = (outs);
  let regions = (region SizedRegion<1>:$bodyRegion);
  let assemblyFormat = [{
    $gmem_buffer `,` $ping_buffer `,` $pong_buffer
    `yields` `(`   `)`
    $bodyRegion attr-dict
    `:` functional-type(operands, results)
  }];
  let builders = [
    OpBuilder<(ins "Value":$gmem_buffer, "Value":$ping_buffer, "Value":$pong_buffer,"function_ref<void(OpBuilder &, Location, ValueRange)>":$bodyBuilderCallback),
    [{
      Type indexType = odsBuilder.getIndexType();
      Type smemType = ping_buffer.getType();
      Location loc = $_state.location;
      
      Region *body = $_state.addRegion();
      Block *block = new Block();
      body->push_back(block);
      
      block->addArgument(indexType, loc);
      block->addArgument(smemType, loc);
      
      OpBuilder::InsertionGuard guard(odsBuilder);
      odsBuilder.setInsertionPointToEnd(block);
      odsBuilder.create<L2YieldOp>(loc);
    }]>
  ];
}

def dfschedule_L2YieldOp : dfscheduleop<"yield", [
    Terminator,
    HasParent<"L2PipelineG2sOp">
  ]> {
  let summary = "Terminator for dfschedule.pipeline_g2s regions.";
  let arguments = (ins);
  let assemblyFormat = "attr-dict";
}
 
#endif // dfschedule_OPS
