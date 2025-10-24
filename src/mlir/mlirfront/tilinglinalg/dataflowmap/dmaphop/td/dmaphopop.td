/*
// --- 1. resource
%shim_engine = dataflowmap.create_engine <"shim"> {id = 0}
%shim_port_out = dataflowmap.create_port %shim_engine {direction = "out"}

%split_engine = dataflowmap.create_engine <"memtile"> {id = 1}
%split_port_in = dataflowmap.create_port %split_engine {direction = "in"}
%split_port_out_A = dataflowmap.create_port %split_engine {direction = "out", port_idx = 0}
%split_port_out_B = dataflowmap.create_port %split_engine {direction = "out", port_idx = 1}

%core_engine_A = dataflowmap.create_engine <"core"> {id = 5}
%core_port_in_A = dataflowmap.create_port %core_engine_A {direction = "in"}
%core_engine_B = dataflowmap.create_engine <"core"> {id = 6}
%core_port_in_B = dataflowmap.create_port %core_engine_B {direction = "in"}

%data_to_bcast = dataflowmap.create_data ...

// --- 2. connection
%hop_ingress = dataflowmap.create_hop %shim_port_out -> %split_port_in
%hop_egress_A = dataflowmap.create_hop %split_port_out_A -> %core_port_in_A
%hop_egress_B = dataflowmap.create_hop %split_port_out_B -> %core_port_in_B

// --- 3.path
%path_for_A = dataflowmap.create_path(%hop_ingress, %hop_egress_A) -> !dmap.path_handle
%path_for_B = dataflowmap.create_path(%hop_ingress, %hop_egress_B) -> !dmap.path_handle

// --- 4. broadcast
%broadcast_graph = dataflowmap.create_flow_graph(%path_for_A, %path_for_B) -> !dmap.graph_handle

// --- start
dataflowmap.start %data_to_bcast on %broadcast_graph

// (b) receive
dataflowmap.receive at %core_port_in_A
dataflowmap.receive at %core_port_in_B
*/
/*
builtin.module {
  dma_hop.func @serial_broadcast_final {

    // --- 1. Define Physical Tile Instances ---
    %shim_tile = dma_hop.tile { col = 0, row = 0 } -> !dma_hop.tile
    %tile_A    = dma_hop.tile { col = 1, row = 2 } -> !dma_hop.tile
    %tile_B    = dma_hop.tile { col = 2, row = 2 } -> !dma_hop.tile

    // --- 2. Define Logical Ports ---
    // SHIM Port
    %shim_port_out   = dma_hop.port on %shim_tile { direction = #dma_hop<direction SEND> }    -> !dma_hop.port

    // Tile A Ports (Distinct IN and OUT)
    %tile_A_port_in  = dma_hop.port on %tile_A    { direction = #dma_hop<direction RECEIVE>, channel = 0 } -> !dma_hop.port
    %tile_A_port_out = dma_hop.port on %tile_A    { direction = #dma_hop<direction SEND>, channel = 0 }    -> !dma_hop.port // Output port used for forwarding

    // Tile B Port
    %tile_B_port_in  = dma_hop.port on %tile_B    { direction = #dma_hop<direction RECEIVE>, channel = 0 } -> !dma_hop.port

    // --- 3. Define Hops (OUT -> IN) ---
    // Hop 1: SHIM Output -> Tile A Input
    %hop_shim_to_A = dma_hop.create_hop %shim_port_out -> %tile_A_port_in -> !dma_hop.hop
    // Hop 2: Tile A Output -> Tile B Input
    %hop_A_to_B    = dma_hop.create_hop %tile_A_port_out -> %tile_B_port_in -> !dma_hop.hop

    // --- 4. Define Path, Consumers, and Tee Point ---
    // Path lists the sequential hops.
    // 'tee_points' refers to the INGRESS port where the split needs to happen internally.
    %serial_path = dma_hop.create_path [%hop_shim_to_A, %hop_A_to_B] {
        consumers = [%tile_A_port_in, %tile_B_port_in], // Both A and B consume data arriving at their IN ports
        tee_points = [%tile_A_port_in] // Explicitly state split occurs *upon arrival* at A's IN port
    } -> !dma_hop.path

    // --- 5. Prepare Data and Buffers ---
    %data = memref.alloc(...) : memref<...>
    %buffer_A = dma_hop.alloc_buffer on %tile_A : memref<..., memory_space="L1">
    %buffer_B = dma_hop.alloc_buffer on %tile_B : memref<..., memory_space="L1">

    // --- 6. Execute Transfer ---
    dma_hop.push %data onto %serial_path
                 outputs(%buffer_A at %tile_A_port_in, %buffer_B at %tile_B_port_in)

    // --- 7. Synchronization ---
    dma_hop.sync %serial_path

    // --- 8. Deallocate ---
    dma_hop.dealloc_buffer %buffer_A
    dma_hop.dealloc_buffer %buffer_B

    return
  }
}
*/