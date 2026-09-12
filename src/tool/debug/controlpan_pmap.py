"""Parse CONTROLPAN-PMAP applog lines into device-map ports and edges.

A CONTROLPAN-PMAP line (emitted by the aie_ctrl* runtime when
__Runtime_ctrl_pmap_enable is on, or AIE_CTRL_PMAP is set) describes one
programmed stream port:

    CONTROLPAN-PMAP col=<c> row=<r> port=<SOUTH|NORTH|CTRL|EAST|WEST> idx=<n> \
        dir=<fwd|ret> ms=<master|slave> id=<id> sw=<pkt|circuit> slot=<n> \
        arb=<n> msel=<n> mask=<n>

sw/slot/arb/msel/mask are optional (legacy lines default sw=circuit, slot=-1 and
arb/msel/mask=-1). arb/msel/mask are the AIE stream-switch packet-routing params:
a packet slave slot carries (mask, msel, arbiter); a packet master port carries
(arbiter, mselen, emitted as msel). Circuit ports emit -1 for all three.
parse_ports() returns the port dicts; parse_edges() pairs master ports with the
slave port on the adjacent tile to synthesize device-map routing edges carrying
the master hop's sw/slot and both port indices.
"""
import re

_TAG = "CONTROLPAN-PMAP"
_KV = re.compile(r"(\w+)=(\S+)")
_INT_KEYS = ("col", "row", "idx", "id", "slot", "arb", "msel", "mask")
_REQUIRED = ("col", "row", "port", "idx", "dir", "ms", "id")
_OPTIONAL = ("sw", "slot", "arb", "msel", "mask")

# Master-port direction -> neighbor tile delta (col,row). AIE grid: row 0 = shim
# at the bottom; NORTH points up (+row), SOUTH down (-row), EAST +col, WEST -col.
_DELTA = {"NORTH": (0, 1), "SOUTH": (0, -1), "EAST": (1, 0), "WEST": (-1, 0)}
_OPP = {"NORTH": "SOUTH", "SOUTH": "NORTH", "EAST": "WEST", "WEST": "EAST"}


def parse_ports(text):
    ports = []
    for line in text.splitlines():
        i = line.find(_TAG)
        if i < 0:
            continue
        kv = dict(_KV.findall(line[i + len(_TAG):]))
        if not set(_REQUIRED) <= set(kv):
            continue
        # sw/slot/arb/msel/mask are optional (legacy lines omit them).
        kv.setdefault("sw", "circuit")
        kv.setdefault("slot", "-1")
        kv.setdefault("arb", "-1")
        kv.setdefault("msel", "-1")
        kv.setdefault("mask", "-1")
        try:
            rec = {k: (int(kv[k]) if k in _INT_KEYS else kv[k])
                   for k in _REQUIRED + _OPTIONAL}
        except ValueError:
            continue
        ports.append(rec)
    return ports


def parse_edges(text):
    """Pair each master port with the opposite-direction slave port on the
    neighbor tile. CTRL master/slave are tile-local consume/emit markers (no
    edge). Returns a list of {from:[c,r], to:[c,r], dir, id, port} edges."""
    ports = parse_ports(text)
    # Key slaves by (col,row,port,dir,id): one neighbor port can serve several
    # flows (e.g. EAST<->WEST for both a fwd and a ret route), so keying on the
    # port alone would keep only the last slave and bind the wrong to_idx.
    slaves = {(p["col"], p["row"], p["port"], p["dir"], p["id"]): p
              for p in ports if p["ms"] == "slave"}
    edges = []
    for p in ports:
        if p["ms"] != "master" or p["port"] not in _DELTA:
            continue
        dc, dr = _DELTA[p["port"]]
        nb = (p["col"] + dc, p["row"] + dr, _OPP[p["port"]], p["dir"], p["id"])
        if nb in slaves:
            edges.append({"from": [p["col"], p["row"]],
                          "to": [nb[0], nb[1]], "dir": p["dir"],
                          "id": p["id"], "port": p["port"],
                          "sw": p["sw"], "slot": p["slot"],
                          "from_idx": p["idx"], "to_idx": slaves[nb]["idx"]})
    return edges


def parse(text):
    """Convenience: {ports, edges, count}."""
    ports = parse_ports(text)
    return {"ports": ports, "edges": parse_edges(text), "count": len(ports)}


def tile_switch_view(text, col, row):
    """Group one tile's CONTROLPAN-PMAP ports into stream-switch routes.

    Groups the (col,row) ports by (dir, id): the slave ports are the switch
    inputs, the master ports the fan-out outputs. Each master is annotated with
    its destination -- the neighbor tile "(c,r) PORT" from parse_edges, or
    "CTRL (local endpoint)" for a CTRL master, or a dash if unpaired.

    The runtime emits one line per slot for a port, so the same (port,idx) can
    recur within a group; slaves/masters are de-duplicated by (port,idx). The
    group "slot" is the routing slot -- the largest slot>=0 among the group's
    master ports, else the largest slot>=0 among any port, else -1; "sw" is
    "pkt" if any port in the group is packet-switched, else "circuit".

    Each slave carries its packet-routing params (mask, msel, arb); each master
    carries (msel, arb). A (port,idx) may recur with a params-bearing line (the
    SLOT/MASTER_EN line, arb>=0) and a bare enable line (arb<0); the params from
    the record with arb>=0 win.

    Returns {col, row, groups:[{dir,id,slot,sw,
    slaves:[{port,idx,mask,msel,arb}], masters:[{port,idx,dest,msel,arb}]}]}.
    """
    ports = [p for p in parse_ports(text)
             if p["col"] == col and p["row"] == row]
    # master (port,idx,dir,id) on this tile -> neighbor "(c,r) PORT".
    dest_of = {}
    for e in parse_edges(text):
        if e["from"] == [col, row]:
            dest_of[(e["port"], e["from_idx"], e["dir"], e["id"])] = \
                "({},{}) {}".format(e["to"][0], e["to"][1], _OPP[e["port"]])
    groups = {}
    for p in ports:
        key = (p["dir"], p["id"])
        g = groups.setdefault(key, {"dir": p["dir"], "id": p["id"],
                                    "slaves": [], "masters": [],
                                    "_sslot": [], "_mslot": [], "_pkt": False})
        g["_pkt"] = g["_pkt"] or (p["sw"] == "pkt")
        if p["ms"] == "slave":
            g["_sslot"].append(p["slot"])
            ex = next((s for s in g["slaves"]
                       if s["port"] == p["port"] and s["idx"] == p["idx"]), None)
            if ex is None:
                g["slaves"].append({"port": p["port"], "idx": p["idx"],
                                    "mask": p["mask"], "msel": p["msel"],
                                    "arb": p["arb"]})
            elif ex["arb"] < 0 and p["arb"] >= 0:
                ex["mask"], ex["msel"], ex["arb"] = p["mask"], p["msel"], p["arb"]
        else:
            g["_mslot"].append(p["slot"])
            ex = next((m for m in g["masters"]
                       if m["port"] == p["port"] and m["idx"] == p["idx"]), None)
            if ex is not None:
                if ex["arb"] < 0 and p["arb"] >= 0:
                    ex["msel"], ex["arb"] = p["msel"], p["arb"]
                continue
            if p["port"] == "CTRL":
                dest = "CTRL (local endpoint)"
            else:
                dest = dest_of.get((p["port"], p["idx"], p["dir"], p["id"]), "\u2014")
            g["masters"].append({"port": p["port"], "idx": p["idx"], "dest": dest,
                                 "msel": p["msel"], "arb": p["arb"]})
    for g in groups.values():
        # Prefer a routing slot from the masters; fall back to any port's slot.
        mpos = [s for s in g.pop("_mslot") if s >= 0]
        apos = mpos + [s for s in g.pop("_sslot") if s >= 0]
        g["slot"] = max(mpos) if mpos else (max(apos) if apos else -1)
        g["sw"] = "pkt" if g.pop("_pkt") else "circuit"
    ordered = sorted(groups.values(), key=lambda g: (g["dir"], g["id"]))
    return {"col": col, "row": row, "groups": ordered}
