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
  let summary = "Host-visible stream handle carrying element type";
}

def dfschedule_PacketType : dfscheduleype<"Packet"> {
  let mnemonic = "packet";
  let summary = "Host-visible packet handle carrying element type";
}

//=== dfscheduleDMA Types/Attrs ===//
def dfschedule_LockType : dfscheduleype<"Lock"> {
  let mnemonic = "lock";
  let summary = "Abstract device lock handle";
}

//=== Tile Types ===//
def dfschedule_TileHandleType : dfscheduleype<"Tile"> {
  let mnemonic = "tile";
  let summary = "Tile handle for physical tile location";
}

//=== Kernel Group Types ===//
def dfschedule_KernelGroupType : dfscheduleype<"KernelGroup"> {
  let mnemonic = "kernelgroup";
  let summary = "Handle to a group of kernel instances to be launched together";
}

//=== Kernel Configuration Types ===//
def dfschedule_KernelConfigType : dfscheduleype<"KernelConfig"> {
  let mnemonic = "kernel_config";
  let summary = "Handle to kernel configuration for all tiles";
}

def dfschedule_TileConfigType : dfscheduleype<"TileConfig"> {
  let mnemonic = "tile_config";
  let summary = "Handle to tile-specific configuration in local memory";
}

//=== Compute Type (for kernel compute logic reference) ===//
def dfschedule_ComputeType : dfscheduleype<"Compute"> {
  let mnemonic = "compute";
  let summary = "Reference to a compute kernel logic block";
}

//=== DMA Configuration Types ===//
def dfschedule_BdHandleType : dfscheduleype<"BdHandle"> {
  let mnemonic = "bd_handle";
  let summary = "Buffer descriptor handle for DMA configuration";
}

def dfschedule_IoHandleType : dfscheduleype<"IoHandle"> {
  let mnemonic = "io_handle";
  let summary = "IO handle for DMA channel operations";
}

//=== DMA Channel Type ===//
def dfschedule_DmaChannelType : dfscheduleype<"DmaChannel"> {
  let mnemonic = "dma_channel";
  let summary = "DMA channel identifier";
}

#endif //_TYPE_dfschedule_