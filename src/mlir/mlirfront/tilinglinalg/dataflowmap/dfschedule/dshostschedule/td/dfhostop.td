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
include "dshostattr.td"

// Base traits helpers
def HasRecursiveSideEffects : Trait<"HasRecursiveSideEffects">;

// amd.host.alloc_device_mem
def DsHost_AllocDeviceMemOp : Op<DsHost_Dialect, "alloc_device_mem", []> {
  let summary = "Allocate device global memory";
  let arguments = (ins);
  let results   = (outs AnyMemRef:$memref);
  let assemblyFormat = [{
    `:` type($memref)
  }];
  let hasVerifier = 1;
  let builders = [
    OpBuilder<(ins "Type":$memrefTy)>
  ];
}

// amd.host.free_device_mem
def DsHost_FreeDeviceMemOp : Op<DsHost_Dialect, "free_device_mem", []> {
  let summary = "Free device global memory";
  let arguments = (ins AnyMemRef:$memref);
  let results   = (outs);
  let assemblyFormat = "$memref attr-dict `:` type($memref)";
  let hasVerifier = 1;
}

// amd.host.copy_h2d_async
def DsHost_CopyH2DAsyncOp : Op<DsHost_Dialect, "copy_h2d_async",
  [MemoryEffects<[MemWrite]>]> {
  let summary = "Async copy Host->Device";
  let arguments = (ins AnyMemRef:$host, AnyMemRef:$device);
  let results   = (outs DsHost_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getViaAttrName() { return "via"; }  // Flow_ShimEndpointAttr
  }];
  let assemblyFormat = [{
    $host `,` $device
    (`,` `via` `=` $via^)?
    attr-dict `:` `(` type($host) `,` type($device) `)` `->` type($event)
  }];
}

// amd.host.copy_d2h_async
def DsHost_CopyD2HAsyncOp : Op<DsHost_Dialect, "copy_d2h_async",
  [MemoryEffects<[MemRead]>]> {
  let summary = "Async copy Device->Host";
  let arguments = (ins AnyMemRef:$device, AnyMemRef:$host);
  let results   = (outs DsHost_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getViaAttrName() { return "via"; }
  }];
  let assemblyFormat = [{
    $device `,` $host
    (`,` `via` `=` $via^)?
    attr-dict `:` `(` type($device) `,` type($host) `)` `->` type($event)
  }];
}

// amd.host.create_stream
def DsHost_CreateStreamOp : Op<DsHost_Dialect, "create_stream", []> {
  let summary = "Create a host-visible stream";
  let arguments = (ins TypeAttr:$elem_type);
  let results   = (outs DsHost_StreamType:$stream);
  let assemblyFormat = [{
    `(` $elem_type `)` attr-dict `:` type($stream)
  }];
}

// amd.host.stream_push
def DsHost_StreamPushOp : Op<DsHost_Dialect, "stream_push",
  [MemoryEffects<[MemRead]>]> {
  let summary = "Push host buffer into a stream";
  let arguments = (ins DsHost_StreamType:$stream, AnyMemRef:$host);
  let results   = (outs);
  let assemblyFormat = "$stream `,` $host attr-dict `:` `(` type($stream) `,` type($host) `)`";
}

// amd.host.stream_pull
def DsHost_StreamPullOp : Op<DsHost_Dialect, "stream_pull",
  [MemoryEffects<[MemWrite]>]> {
  let summary = "Pull stream data into a host buffer";
  let arguments = (ins DsHost_StreamType:$stream, AnyMemRef:$host);
  let results   = (outs);
  let assemblyFormat = "$stream `,` $host attr-dict `:` `(` type($stream) `,` type($host) `)`";
}

// amd.host.launch_kernel_async
def DsHost_LaunchKernelAsyncOp : Op<DsHost_Dialect, "launch_kernel_async",
  [AttrSizedOperandSegments]> {
  let summary = "Launch a device kernel on a tile asynchronously";
  let arguments = (ins Variadic<AnyType>:$operands);
  let results   = (outs DsHost_EventType:$event);
  let extraClassDeclaration = [{
    static StringRef getOnTileAttrName() { return "on_tile"; } // AMD_TileAttr
    static StringRef getWaitDepsAttrName() { return "wait"; }  // Array of DsHost_EventType
    static StringRef getCalleeAttrName() { return "callee"; }  // SymbolRefAttr
  }];
  let assemblyFormat = [{
    $callee `(` $operands `)` 
    ( `wait` `(` $wait^ `:` type($event) `)` )?
    ( `on_tile` `=` $on_tile^ )?
    attr-dict `:` `(` type($operands) `)` `->` type($event)
  }];
}

// amd.host.wait
def DsHost_WaitOp : Op<DsHost_Dialect, "wait", []> {
  let summary = "Wait for an event to complete";
  let arguments = (ins DsHost_EventType:$event);
  let results   = (outs);
  let assemblyFormat = "$event attr-dict `:` type($event)";
}
 
#endif // DSHOST_OPS
