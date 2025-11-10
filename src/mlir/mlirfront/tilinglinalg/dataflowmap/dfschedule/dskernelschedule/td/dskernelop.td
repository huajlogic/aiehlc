#ifndef DSKERNEL_OPS
#define DSKERNEL_OPS

include "mlir/IR/BuiltinTypes.td"
include "mlir/Dialect/MemRef/IR/MemRefBase.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/ShapedOpInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"

include "dskerneltype.td"
// NOTE: replace `dskernelop` below with the op-wrapper macro your dialect defines
// (e.g. dskernelop or similar). If you haven't defined one, add it in your dialect .td.



////////////////////////////////////////////////////////////////////////////////
// dskernel.lock_init
// Usage: %lock = "dskernel.lock_init"(1) : () -> !dskernel.lock
def DSKernel_LockInitOp : dskernelop<"lock_init"> {
  let summary = "Create/init a kernel-local lock (initial count)";
  // init count passed as an integer attribute in assembly: "dskernel.lock_init"(1)
  let arguments = (ins I64Attr:$count);
  let results   = (outs DSKernel_LockType:$lock);
  let assemblyFormat = "attr-dict `(` $count `)` `->` type($lock)";
}

////////////////////////////////////////////////////////////////////////////////
// dskernel.launch_dma_s2m_loop
// Usage (example):
// dskernel.launch_dma_s2m_loop %ping, %pong, %pktid, %ping_acq, %pong_acq, %ping_rel, %pong_rel { ...region... }
//
// This operation launches a DMA loop that performs ping-pong double-buffering:
// - ping_acquire_lock: DMA releases this when ping buffer is full (compute waits on this)
// - pong_acquire_lock: DMA releases this when pong buffer is full (compute waits on this)
// - ping_release_lock: DMA waits on this before refilling ping buffer (compute releases this)
// - pong_release_lock: DMA waits on this before refilling pong buffer (compute releases this)
def DSKernel_LaunchDmaS2MLoopOp : dskernelop<"launch_dma_s2m_loop"> {
  let summary = "Launch a local DMA s2m ping-pong loop that listens on a packet id";
  // operands: ping buffer, pong buffer, packet id (i32), 
  //           ping_acquire, pong_acquire, ping_release, pong_release locks
  let arguments = (ins 
    AnyMemRef:$ping, 
    AnyMemRef:$pong, 
    I32:$listen_on_packet_id, 
    DSKernel_LockType:$ping_acquire_lock, 
    DSKernel_LockType:$pong_acquire_lock,
    DSKernel_LockType:$ping_release_lock,
    DSKernel_LockType:$pong_release_lock
  );
  // no direct results; operation contains a region representing the DMA loop body (optional)
  let regions = (region AnyRegion:$body);
  // Assembly format with all 4 locks
  let assemblyFormat = "$ping `:` type($ping) `,` $pong `:` type($pong) `,` $listen_on_packet_id `,` $ping_acquire_lock `,` $pong_acquire_lock `,` $ping_release_lock `,` $pong_release_lock attr-dict-with-keyword $body";
  let extraClassDeclaration = [{
    // expose nice attribute names if you later want to set attributes instead of operands
    static StringRef getListenAttrName() { return "listen_on_packet_id"; }
    static StringRef getPingAcquireLockName() { return "ping_acquire_lock"; }
    static StringRef getPongAcquireLockName() { return "pong_acquire_lock"; }
    static StringRef getPingReleaseLockName() { return "ping_release_lock"; }
    static StringRef getPongReleaseLockName() { return "pong_release_lock"; }
  }];
}

////////////////////////////////////////////////////////////////////////////////
// dskernel.acquire_lock / release_lock
// Usage: "dskernel.acquire_lock"(%lock, %token)  // %token is i32
def DSKernel_AcquireLockOp : dskernelop<"acquire_lock"> {
  let summary = "Acquire a kernel lock for a token";
  let arguments = (ins DSKernel_LockType:$lock, I32:$token);
  let results   = (outs);
  let assemblyFormat = "$lock `,` $token attr-dict";
}

def DSKernel_ReleaseLockOp : dskernelop<"release_lock"> {
  let summary = "Release a kernel lock for a token";
  let arguments = (ins DSKernel_LockType:$lock, I32:$token);
  let results   = (outs);
  let assemblyFormat = "$lock `,` $token attr-dict";
}

////////////////////////////////////////////////////////////////////////////////
// dskernel.compute
// Usage: "dskernel.compute"(%buffer) : (memref<256xf32>) -> ()
// This operation represents a compute kernel that processes data from a buffer
def DSKernel_ComputeOp : dskernelop<"compute"> {
  let summary = "Perform computation on a buffer";
  let description = [{
    This operation represents a compute kernel that processes data from a memory buffer.
    It can be used as a placeholder for actual compute operations in the AIE kernel.
    The operation takes a memref buffer as input and performs computation on it.
  }];
  let arguments = (ins AnyMemRef:$buffer);
  let results = (outs);
  let assemblyFormat = "$buffer `:` type($buffer) attr-dict";
}

// ==========================================================
// `dskernel.pipeline_g2s`
// ==========================================================
def DSKernel_L2PipelineG2sOp : dskernelop<"pipeline_g2s", []> {

  let summary = "Abstracts a Gmem->Smem ping-pong buffer dataflow pipeline.";

  let arguments = (ins
    AnyMemRef:$gmem_buffer,
    AnyMemRef:$ping_buffer,
    AnyMemRef:$pong_buffer
  );

  let results = (outs);

  let regions = (region SizedRegion<1>:$bodyRegion);

  // --- C++ Declarations for Builder and Verifier ---

  // --- Assembly Format ---
  let assemblyFormat = [{
    $gmem_buffer `,` $ping_buffer `,` $pong_buffer
    `yields` `(` $bodyRegion `)`
    attr-dict
    `:` functional-type(operands, results)
  }];
}

def DSKernel_L2YieldOp : dskernelop<"yield", [
    Terminator,
    HasParent<"L2PipelineG2sOp">
  ]> {
  let summary = "Terminator for dskernel.pipeline_g2s regions.";
  let arguments = (ins);
  let assemblyFormat = "attr-dict";
}

#endif // DSKERNEL_OPS
