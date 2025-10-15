/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#ifndef dmap_OPS
#define dmap_OPS

include "mlir/IR/OpBase.td"
include "mlir/IR/Dialect.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

include "dmapattr.td"

def dmap_ConfigurePortOp : dmapop<"configure_port"> {
  let summary = "Configures a logical data port on a physical hardware entity.";
  let description = [{
    Binds a physical hardware handle (e.g., a tile from the routinghw dialect)
    to a logical data port, specifying its direction and a logical channel ID.
    This creates a node in the logical dataflow graph.
  }];

  let arguments = (ins
    I32Attr:$channel,
    portattr:$port,
    dataaccesspattern:$accesspattern,
  );

  let results = (outs dmapporttype:$port);

  let assemblyFormat = [{
     attr-dict `->` $port
  }];
}

def dmap_CreatePortGroupOp : dmapop<"create_port_group"> {
  let summary = "Groups multiple destination ports into a single multicast group.";
  let description = [{
    Takes a list of destination ports and bundles them into a single, addressable
    port group. This is used to enable one-to-many communication patterns like
    broadcast or multicast.
  }];

  let arguments = (ins
    Variadic<dmap_PortType>:$ports
  );

  let results = (outs dmap_PortGroupType:$group);

  let assemblyFormat = [{
    `(` $ports `)` attr-dict `:` type($ports) `->` $group
  }];
}

def dmap_CreateStreamOp : dmapop<"create_stream"> {
  let summary = "Defines a logical data stream from a source to a destination.";
  let description = [{
    Creates an edge in the dataflow graph, explicitly connecting a source port
    with a destination port or port group. The resulting stream handle encapsulates
    the entire end-to-end path topology, simplifying execution ops.
  }];

  let arguments = (ins
    dmap_PortType:$source,
    AnyTypeOf<[dmap_PortType, dmap_PortGroupType]>:$destination
  );

  let results = (outs dmap_StreamType:$stream);

  let assemblyFormat = [{
    $source `,` $destination attr-dict `->` $stream
  }];
}


//===----------------------------------------------------------------------===//
// Execution Operators
//===----------------------------------------------------------------------===//

def dmap_PushOp : dmapop<"push", [MemoryEffect_Interface]> {
  let summary = "Pushes a block of data into a pre-defined stream.";
  let description = [{
    The primary execution-phase operation. It takes a memref of data and
    a stream handle, initiating the data transfer along the path defined
    by the stream. This operation can be implemented asynchronously.
  }];

  let arguments = (ins
    AnyMemRef:$data,
    dmap_StreamType:$stream
  );

  let assemblyFormat = [{
    $data `to` $stream attr-dict
  }];

  let effects = [MemoryEffects::Write]; // This op causes writes to device memory.
}

def dmap_SyncOp : dmapop<"sync", [MemoryEffect_Interface]> {
  let summary = "Waits for all transfers in a stream to complete.";
  let description = [{
    Provides a synchronization point. Execution blocks until all previously
    pushed data in the specified stream has been fully delivered. This is
    essential for ensuring data is ready before computation begins.
  }];

  let arguments = (ins dmap_StreamType:$stream);

  let assemblyFormat = [{
    $stream attr-dict
  }];

  // A sync acts as a full memory barrier.
  let effects = [MemoryEffects::Read, MemoryEffects::Write];
}

#endif // dmap_OPS