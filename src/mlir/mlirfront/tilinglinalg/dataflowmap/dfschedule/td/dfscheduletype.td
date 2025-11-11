#ifndef _TYPE_dfschedule_
#define _TYPE_dfschedule_
include "dfscheduleattr.td"

//=== dfschedule Types ===//
def dfschedule_EventType:dfscheduleype<"Event"> {
  let mnemonic = "event";
  let summary = "Opaque async event type for host runtime";
}

def dfschedule_StreamType : dfscheduleype<"Stream"> {
  let mnemonic = "stream";
  //let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Host-visible stream handle carrying element type";
}

def dfschedule_PacketType : dfscheduleype<"Packet"> {
  let mnemonic = "packet";
  //let parameters = (ins TypeParameter<"element type">:$elemTy);
  let summary = "Host-visible patcket handle carrying element type";
}

//=== dfscheduleDMA Types/Attrs ===//
def dfschedule_LockType : dfscheduleype<"Lock"> {
  let mnemonic = "lock";
  let summary = "Abstract device lock handle";
}

//=== dfscheduleDMA Types/Attrs ===//
def dfschedule_TileHandleType : dfscheduleype<"Tile"> {
  let mnemonic = "Tile";
  let summary = "Tile ";
}
#endif //_TYPE_dfschedule_