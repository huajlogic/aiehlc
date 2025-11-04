#ifndef _TYPE_DSHOST_
#define _TYPE_DSHOST_
include "dshostattr.td"

//=== DsHost Types ===//
def DsHost_EventType : TypeDef<DsHost_Dialect, "Event"> {
  let mnemonic = "event";
  let summary = "Opaque async event type for host runtime";
}

def DsHost_StreamType : TypeDef<DsHost_Dialect, "Stream"> {
  let mnemonic = "stream";
  let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Host-visible stream handle carrying element type";
  let assemblyFormat = "`<` $elemTy `>`";
}
#endif //_TYPE_DSHOST_