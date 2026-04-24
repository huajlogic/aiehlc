Root cause: Dangling stream route causing broadcast deadlock on input B                                                 
                                                                                                                          
  The routing in routing.cc line 92 creates a connection:                                                                 
  tile(2,3) EAST:2 → NORTH:1                                                                                              
  This sends data to tile(2,4) SOUTH:1, but there is no routing configured from tile(2,4) SOUTH:1 to any destination. The 
  data has nowhere to go.                                                                                                 
                                                                                                                          
  Since tile(2,3) EAST:2 is broadcast to three outputs (NORTH:1, NORTH:2, DMA:1), and circuit-switched broadcast requires 
  ALL destinations to consume before the source advances, the dead-end on NORTH:1 eventually backpressures the entire     
  input B data flow to all row-3 tiles.                                                                                   
                                                                                                                          
  The effect:                                                                                                             
  - Tiles (0,3), (1,3), (2,3) can't receive input B → stuck on LOCK_STALL_E (waiting for input lock) → never produce      
  output → shim(3,0) S2MM ch0 TIMEOUT → first 64 bytes of output C are all zero                                           
  - Tile(3,3) managed to complete (likely received enough input B before backpressure hit, since it's at the first        
  broadcast point)                                                                                                        
  - All row-4+ tiles completed since they use a different input routing path                                              
                                                                                                                          
  The fix should be in the routing generation pass — either:                                                              
  1. Remove the dangling EAST:2 → NORTH:1 connection on tile(2,3) if it's not needed                                      
  2. Or add proper routing from tile(2,4) SOUTH:1 to the intended destination (likely should route to tile(0,3) and/or    
  tile(1,3) via a different path)                                                                                         
                                                                                                                          
  The bug is likely in the routing path finder or broadcast unrolling logic in the MLIR pass pipeline                     
  (RoutingUnrollingLowerPass or RoutingLowerPass).