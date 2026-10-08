---
name: control-plane-resource-verification
description: Verifies that pragma-enabled TilingLinalg data routing avoids control-plane packet IDs, arbiters, slots, and physical ports. Use when changing control_plan_op_control_packet, ResourceManager reservations, routing topology allocation, or validating generated routes and live VEK385 switch registers.
---

# Control-plane resource verification

## Contract

`#pragma control_plan_op_control_packet` must reserve resources on the
`RoutingTopology` resource manager before any lowering pass allocates packet
IDs or routes. Treat `src/mlir/runtime/aie_runtime_resource.c` as the source of
truth.

Verify that data routing avoids:

- reserved packet IDs
- reserved arbiters
- reserved slave slots for each port type
- cardinal port 0 on partition core rows
- the spine column's vertical ports: `RT_RES_VFWD_PORT` (4) on NORTH master /
  SOUTH slave and `RT_RES_VRET_PORT` (3) on SOUTH master / NORTH slave, which
  are the ports the runtime programs. The old port-0 reservation did not match
  them.
- when placement is exclusive: control's shim DMA channels, their mux/demux
  ports, and shim BDs 2-6 and 12-14

Read the placement from the `control plane:` build-log line and the module
attrs `routing.control_plan_{shim_col,mm2s_ch,s2mm_ch,exclusive}`. For a
dedicated column (spare partition column), also check that no
`Allocated DataIO: shim col=<spine>` appears and that `routing.cc` has no
`XAie_TileLoc(<spine>,` calls.

## Workflow

1. Build the focused ResourceManager unit test and run it.
2. Compile the pragma-enabled example.
3. Confirm the module attribute survives the routing IR pipeline.
4. Audit `aout/worklocal/routingresourcemap.json` and generated `routing.cc`.
5. Run on a reserved VEK385 (skill **vek385-board-benchmark**).
6. Read back at least one representative packet route with `aiedbg`.

The generated-map audit must report every checked connection and zero
collisions. Check packet IDs, arbiter, receive slot, and physical port.

## Live read-back

Prefer one bulk read per tile, because `show switch` starts a separate `aiedbg`
process per register:

```bash
aiedbg --json --target xsdb://<host>:3121 --device vek385 mem read COL ROW 0x3F000 256
```

For core and shim tiles, decode:

- master config: `0x3F000 + physical_master_index * 4`
- slave config: `0x3F100 + physical_slave_index * 4`
- slot config: `0x3F200 + physical_slave_index * 16 + slot * 4`

Packet master configuration is arbiter in bits `[2:0]` and MSelEn in `[6:3]`.
Slot configuration is packet ID `[28:24]`, mask `[20:16]`, enable `[8]`,
msel `[5:4]`, and arbiter `[2:0]`.

Compare decoded values to `routingresourcemap.json` and `routing.cc`; do not
claim live verification from generated files alone.

## Failure signatures

- Reservation happens after `DmapToDmaphopPass`: packet IDs may already collide.
- Reservation uses the singleton instead of the topology manager: routing is
  unaffected.
- Fixed packet slot or arbiter attributes remain in lowering: generated routes
  can consume reserved resources.
- Reserving cardinal port 0 on every tile: dense routing may exhaust ports.
