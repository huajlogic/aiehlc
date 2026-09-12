"""Parse CONTROLPAN-PMAP applog lines into device-map ports and edges.

A CONTROLPAN-PMAP line (emitted by the aie_ctrl* runtime when
__Runtime_ctrl_pmap_enable is on, or AIE_CTRL_PMAP is set) describes one
programmed stream port:

    CONTROLPAN-PMAP col=<c> row=<r> port=<SOUTH|NORTH|CTRL|EAST|WEST> idx=<n> \
        dir=<fwd|ret> ms=<master|slave> id=<id> sw=<pkt|circuit> slot=<n>

sw/slot are optional (legacy lines default sw=circuit, slot=-1). parse_ports()
returns the port dicts; parse_edges() pairs master ports with the slave port on
the adjacent tile to synthesize device-map routing edges carrying the master
hop's sw/slot and both port indices.
"""
import re

_TAG = "CONTROLPAN-PMAP"
_KV = re.compile(r"(\w+)=(\S+)")
_INT_KEYS = ("col", "row", "idx", "id", "slot")
_REQUIRED = ("col", "row", "port", "idx", "dir", "ms", "id")

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
        # sw/slot are optional (legacy lines omit them).
        kv.setdefault("sw", "circuit")
        kv.setdefault("slot", "-1")
        try:
            rec = {k: (int(kv[k]) if k in _INT_KEYS else kv[k])
                   for k in _REQUIRED + ("sw", "slot")}
        except ValueError:
            continue
        ports.append(rec)
    return ports


def parse_edges(text):
    """Pair each master port with the opposite-direction slave port on the
    neighbor tile. CTRL master/slave are tile-local consume/emit markers (no
    edge). Returns a list of {from:[c,r], to:[c,r], dir, id, port} edges."""
    ports = parse_ports(text)
    slaves = {(p["col"], p["row"], p["port"]): p
              for p in ports if p["ms"] == "slave"}
    edges = []
    for p in ports:
        if p["ms"] != "master" or p["port"] not in _DELTA:
            continue
        dc, dr = _DELTA[p["port"]]
        nb = (p["col"] + dc, p["row"] + dr, _OPP[p["port"]])
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

    Returns {col, row, groups:[{dir,id,slot,sw,slaves:[{port,idx}],
    masters:[{port,idx,dest}]}]}.
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
                                    "slot": p["slot"], "sw": p["sw"],
                                    "slaves": [], "masters": []})
        if p["ms"] == "slave":
            g["slaves"].append({"port": p["port"], "idx": p["idx"]})
        else:
            if p["port"] == "CTRL":
                dest = "CTRL (local endpoint)"
            else:
                dest = dest_of.get((p["port"], p["idx"], p["dir"], p["id"]), "\u2014")
            g["masters"].append({"port": p["port"], "idx": p["idx"], "dest": dest})
    ordered = sorted(groups.values(), key=lambda g: (g["dir"], g["id"]))
    return {"col": col, "row": row, "groups": ordered}
