#ifndef _TYPE_dskernel_
#define _TYPE_dskernel_

include "dskernelattr.td"

//
// dskernel types
//
def DSKernel_LockType:dskerneltype<"lock"> {
  let mnemonic = "lock";
  let summary = "Opaque   lock type for Kernel runtime";
}

def DSKernel_EventType : dskerneltype<"event"> {
  let mnemonic = "event";
  //let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Kernel-visible event handle carrying element type";
}

def DSKernel_PacketType : dskerneltype<"Ppacketcket"> {
  let mnemonic = "packet";
  //let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Kernel-visible patcket handle carrying element type";
}

//=== dskernelDMA Types/Attrs ===//
def DSKernel_StreamType : dskerneltype<"stream"> {
  let mnemonic = "stream";
  let summary = "Abstract device stream handle";
}


#endif //_TYPE_dskernel_