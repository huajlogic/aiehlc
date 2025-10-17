/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
#ifndef dmap_OPS
#define dmap_OPS
include "dmaptype.td"
/*
      %data = dataflowmap.create_data {type="i32", dim1=10, dim2 20}
      %pegroup = dataflowmap.dmap_create_pe_group {group_idx = 1, pe_count=4, "row"}
      %coreenginegroup = dataflowmap.dmap_create_core_engine_group {1, 4, "row"}
      %ioengine = dataflowmap.dmap_create_io_engine {0, "shim"}
      %portsend = dataflowmap.configure_port %ioengine {peorioidx=0, dataacces=}  
      %portreceive1 = dataflowmap.configure_port on %{peorioidx = 0, dataacces=}  
      %portreceive2 = dataflowmap.configure_port on %{peorioidx = 1, dataacces=}   
      %receive_group = dataflowmap.create_port_group(%portreceive1, %portreceive2)    
      %broadcast_stream = dataflowmap.create_stream %send_port, %receive_group         
      dataflowmap.push %data, %broadcast_stream {cache_policy = "force_memtile" }
*/
def dmap_create_data : dmapop<"create_data"> {
  let summary = "create data";
  let description = [{

  }];

  let arguments = (ins
    ArrayAttr:$shape,
    TypeAttr:$element_type
  );
  let results = (outs dmapdatatype:$data );

  let assemblyFormat = [{
    attr-dict `->` type($data)
  }];
}

def dmap_create_core_engine_group : dmapop<"create_core_engine_group"> {
  let summary = "create core engine group";
  let description = [{

  }];

  let arguments = (ins
    I32Attr:$group_idx,
    I32Attr:$core_count,
    StrAttr:$group_axis // row or col
  );
  let results = (outs dmapcoreenginegrouptype:$pegroup );

  let assemblyFormat = [{
    attr-dict `->` type($pegroup)
  }];
}

def dmap_create_io_engine : dmapop<"create_io_group"> {
  let summary = "create io group";
  let description = [{

  }];

  let arguments = (ins
    I32Attr:$io_idx,
    StrAttr:$comments // row or col
  );
  let results = (outs dmapioenginetype:$ioengine );

  let assemblyFormat = [{
    attr-dict `->` type($ioengine)
  }];
}

def dmap_configure_port : dmapop<"configure_port"> {
  let summary = "Configures a logical data port on a physical hardware entity.";
  let description = [{
    Binds a physical hardware handle (e.g., a tile from the routinghw dialect)
    to a logical data port, specifying its direction and a logical channel ID.
    This creates a node in the logical dataflow graph.
  }];

  let arguments = (ins
    AnyTypeOf<[dmapioenginetype, dmapcoreenginegrouptype]>:$pegrouporioengine,
    I32Attr:$peorioidx,
    dataaccesspattern:$accesspattern
  );

  let results = (outs dmapporttype:$port);

  let assemblyFormat = [{
     $pegrouporioengine `:` type($pegrouporioengine) attr-dict `->` type($port) 
  }];
}

def dmap_createport_group : dmapop<"create_port_group"> {
  let summary = "Groups multiple destination ports into a single multicast group.";
  let description = [{
    Takes a list of destination ports and bundles them into a single, addressable
    port group. This is used to enable one-to-many communication patterns like
    broadcast or multicast.
  }];

  let arguments = (ins
    Variadic<dmapporttype>:$ports
  );

  let results = (outs dmapportgrouptype:$group);

  let assemblyFormat = [{
    `(` $ports `)` attr-dict `:` type($ports) `->` type($group)
  }];
}

def dmap_createSstream : dmapop<"create_stream"> {
  let summary = "Defines a logical data stream from a source to a destination.";
  let description = [{
    Creates an edge in the dataflow graph, explicitly connecting a source port
    with a destination port or port group. The resulting stream handle encapsulates
    the entire end-to-end path topology, simplifying execution ops.
  }];

  let arguments = (ins
    //dmapportorgroup:$source,
    AnyTypeOf<[dmapporttype, dmapportgrouptype]>:$source,
    AnyTypeOf<[dmapporttype, dmapportgrouptype]>:$destination
  );

  let results = (outs dmapportstreamtype:$stream);

  let assemblyFormat = [{
    $source `,` $destination `:` type($source) type($destination) attr-dict `->` type($stream)
  }];
}

//===----------------------------------------------------------------------===//
// Execution Operators
//===----------------------------------------------------------------------===//

def dmap_push : dmapop<"push"> {
  let summary = "Pushes a block of data into a pre-defined stream.";
  let description = [{
    The primary execution-phase operation. It takes a memref of data and
    a stream handle, initiating the data transfer along the path defined
    by the stream. This operation can be implemented asynchronously.
  }];

  let arguments = (ins
    dmapdatatype:$data,
    dmapportstreamtype:$stream
  );

  let assemblyFormat = [{
    $data `to` $stream attr-dict
  }];

}
/*
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
*/
#endif // dmap_OPS