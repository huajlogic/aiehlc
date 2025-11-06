#ifndef DSHOST_OPS
#define DSHOST_OPS

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

include "mlir/IR/BuiltinTypes.td"  // Add this line for MemRefType
include "dshosttype.td"

// Base traits helpers
//def HasRecursiveSideEffects : Trait<"HasRecursiveSideEffects">;

// amd.host.alloc_device_mem
def DSHost_AllocDeviceMemOp : dshosop< "alloc_device_mem", []> {
  let summary = "Allocate device global memory";
  let arguments = (ins);
  let results   = (outs AnyMemRef:$memref);
  let assemblyFormat = [{
    attr-dict `:` type($memref)
  }];
  let hasVerifier = 1;
  let builders = [
    OpBuilder<(ins "Type":$memrefTy)>
  ];
}

// amd.host.free_device_mem
def DSHost_FreeDeviceMemOp : dshosop< "free_device_mem", []> {
  let summary = "Free device global memory";
  let arguments = (ins AnyMemRef:$memref);
  let results   = (outs);
  let assemblyFormat = "$memref attr-dict `:` type($memref)";
  let hasVerifier = 1;
}

// amd.host.copy_h2d_async
def DSHost_CopyH2DAsyncOp : dshosop< "copy_h2d_async",
  [MemoryEffects<[MemWrite]>]> {
  let summary = "Async copy Host->Device";
  let arguments = (ins AnyMemRef:$host, AnyMemRef:$device);
  let results   = (outs DSHost_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getViaAttrName() { return "via"; }  // Flow_ShimEndpointAttr
  }];
  let assemblyFormat = [{
    $host `,` $device  attr-dict `:` `(` type($host) `,` type($device) `)` `->` type($event)
  }];
}

// amd.host.copy_d2h_async
def DSHost_CopyD2HAsyncOp : dshosop< "copy_d2h_async",
  [MemoryEffects<[MemRead]>]> {
  let summary = "Async copy Device->Host";
  let arguments = (ins AnyMemRef:$device, AnyMemRef:$host);
  let results   = (outs DSHost_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getViaAttrName() { return "via"; }
  }];
  let assemblyFormat = [{
    $device `,` $host attr-dict `:` `(` type($device) `,` type($host) `)` `->` type($event)
  }];
}

// amd.host.create_stream
def DSHost_CreateStreamOp : dshosop< "create_stream", []> {
  let summary = "Create a host-visible stream";
  let arguments = (ins TypeAttr:$elem_type);
  let results   = (outs DSHost_StreamType:$stream);
  let assemblyFormat = [{
    `(` $elem_type `)` attr-dict `:` type($stream)
  }];
}

// amd.host.stream_push
def DSHost_StreamPushOp : dshosop< "stream_push",
  [MemoryEffects<[MemRead]>]> {
  let summary = "Push host buffer into a stream";
  let arguments = (ins DSHost_StreamType:$stream, AnyMemRef:$host);
  let results   = (outs);
  let assemblyFormat = "$stream `,` $host attr-dict `:` `(` type($stream) `,` type($host) `)`";
}

// amd.host.stream_pull
def DSHost_StreamPullOp : dshosop< "stream_pull",
  [MemoryEffects<[MemWrite]>]> {
  let summary = "Pull stream data into a host buffer";
  let arguments = (ins DSHost_StreamType:$stream, AnyMemRef:$host);
  let results   = (outs);
  let assemblyFormat = "$stream `,` $host attr-dict `:` `(` type($stream) `,` type($host) `)`";
}

// amd.host.launch_kernel_async
/*
def DSHost_LaunchKernelAsyncOp : dshosop< "launch_kernel_async"> {
  let summary = "Launch a device kernel on a tile asynchronously";
  let arguments = (ins Variadic<AnyType>:$operands);
  let results   = (outs DSHost_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getOnTileAttrName() { return "on_tile"; } // AMD_TileAttr
    static StringRef getWaitDepsAttrName() { return "wait"; }  // Array of DSHost_EventType
    static StringRef getCalleeAttrName() { return "callee"; }  // SymbolRefAttr
  }];
  let assemblyFormat = [{
     `(` $operands `)` 
    ( `wait` `(` $wait^ `:` type($event) `)` )?
    ( `on_tile` `=` $on_tile^ )?
    attr-dict `:` `(` type($operands) `)` `->` type($event)
  }];
}
*/

// amd.host.wait
def DSHost_WaitOp : dshosop< "wait", []> {
  let summary = "Wait for an event to complete";
  let arguments = (ins DSHost_EventType:$event);
  let results   = (outs);
  let assemblyFormat = "$event attr-dict `:` type($event)";
}
 
#endif // DSHOST_OPS
