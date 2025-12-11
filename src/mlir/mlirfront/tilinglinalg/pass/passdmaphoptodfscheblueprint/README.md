# Pass: DmaphopTodfscheblueprintPass

## Overview
This pass converts `dmaphop` dialect operations into `dfscheblueprint` dialect operations for AIE dataflow scheduling blueprints.

## Location
- Header: `src/mlir/mlirfront/tilinglinalg/pass/passdmaphoptodfscheblueprint/passdmaphoptodfscheblueprint.h`
- Implementation: `src/mlir/mlirfront/tilinglinalg/pass/passdmaphoptodfscheblueprint/passdmaphoptodfscheblueprint.cpp`

## Purpose
The pass translates the physical data movement hops defined in `dmaphop` into a high-level schedule blueprint (`dfscheblueprint`). This blueprint defines the logical and physical resources, data partitions, and bindings required for the schedule.

## Input
- A module containing `dmaphop` operations, typically within `routing.RoutingCreate` regions or similar structures.

## Output
- A module containing `dfscheblueprint.ConfigOp` and its nested operations (`ResourceGroupOp`, `DeclareDataOp`, `PartitionOp`, `BindOp`, `BindGroupOp`, `CollectiveTransferOp`).

## Dependencies
- `dmaphop` dialect
- `dfscheblueprint` dialect
- `routing` dialect
