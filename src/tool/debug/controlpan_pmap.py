"""Parse CONTROLPAN-PMAP applog lines into device-map ports and edges.

A CONTROLPAN-PMAP line (emitted by the aie_ctrl* runtime when
__Runtime_ctrl_pmap_enable is on) describes one programmed stream port:

    CONTROLPAN-PMAP col=<c> row=<r> port=<SOUTH|NORTH|CTRL|EAST|WEST> idx=<n> \
        dir=<fwd|ret> ms=<master|slave> id=<id>

parse_ports() returns the port dicts; parse_edges() pairs master ports with the
slave port on the adjacent tile to synthesize device-map routing edges.
"""
import re

_TAG = "CONTROLPAN-PMAP"
_KV = re.compile(r"(\w+)=(\S+)")
_INT_KEYS = ("col", "row", "idx", "id")

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
        if not {"col", "row", "port", "idx", "dir", "ms", "id"} <= set(kv):
            continue
        try:
            rec = {k: (int(kv[k]) if k in _INT_KEYS else kv[k])
                   for k in ("col", "row", "port", "idx", "dir", "ms", "id")}
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
                          "id": p["id"], "port": p["port"]})
    return edges


def parse(text):
    """Convenience: {ports, edges, count}."""
    ports = parse_ports(text)
    return {"ports": ports, "edges": parse_edges(text), "count": len(ports)}
