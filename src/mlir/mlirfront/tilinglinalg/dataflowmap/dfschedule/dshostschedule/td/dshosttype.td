#ifndef _TYPE_DSHOST_
#define _TYPE_DSHOST_
include "dshostattr.td"

//=== DSHost Types ===//
def DSHost_EventType:dshostype<"Event"> {
  let mnemonic = "event";
  let summary = "Opaque async event type for host runtime";
}

def DSHost_StreamType : dshostype<"Stream"> {
  let mnemonic = "stream";
  //let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Host-visible stream handle carrying element type";
}

def DSHost_PacketType : dshostype<"Packet"> {
  let mnemonic = "packet";
  //let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Host-visible patcket handle carrying element type";
}

//=== DSHostDMA Types/Attrs ===//
def DSHost_LockType : dshostype<"Lock"> {
  let mnemonic = "lock";
  let summary = "Abstract device lock handle";
}

//=== DSHostDMA Types/Attrs ===//
def DSHost_TileHandleType : dshostype<"Tile"> {
  let mnemonic = "Tile";
  let summary = "Tile ";
}
#endif //_TYPE_DSHOST_