#ifndef DSKERNEL_OPS
#define DSKERNEL_OPS

include "mlir/IR/BuiltinTypes.td"
include "mlir/Dialect/MemRef/IR/MemRefBase.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/ShapedOpInterfaces.td"

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
  let extraClassDeclaration = [{
    static StringRef getCountAttrName() { return "count"; }
  }];
}

////////////////////////////////////////////////////////////////////////////////
// dskernel.launch_dma_s2m_loop
// Usage (example):
// "dskernel.launch_dma_s2m_loop"(%ping, %pong, %pktid, %wait_lock, %release_lock) { ...region... }
def DSKernel_LaunchDmaS2MLoopOp : dskernelop<"launch_dma_s2m_loop"> {
  let summary = "Launch a local DMA s2m ping-pong loop that listens on a packet id";
  // operands: ping buffer, pong buffer, packet id (i32), wait-lock, release-lock
  let arguments = (ins AnyMemRef:$ping, AnyMemRef:$pong, I32:$listen_on_packet_id, DSKernel_LockType:$dma_wait_lock, DSKernel_LockType:$dma_release_lock);
  // no direct results; operation contains a region representing the DMA loop body (optional)
  let regions = (region AnyRegion:$body);
  // include types for the memref operands so the builder can construct the op
  // Add the $body directive to parse/print the region.
  let assemblyFormat = "$ping `:` type($ping) `,` $pong `:` type($pong) `,` $listen_on_packet_id `,` $dma_wait_lock `,` $dma_release_lock attr-dict-with-keyword $body";
  let extraClassDeclaration = [{
    // expose nice attribute names if you later want to set attributes instead of operands
    static StringRef getListenAttrName() { return "listen_on_packet_id"; }
    static StringRef getDmaWaitLockName() { return "dma_wait_lock"; }
    static StringRef getDmaReleaseLockName() { return "dma_release_lock"; }
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

#endif // DSKERNEL_OPS
