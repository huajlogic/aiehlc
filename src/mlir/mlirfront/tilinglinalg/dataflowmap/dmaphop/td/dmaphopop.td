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