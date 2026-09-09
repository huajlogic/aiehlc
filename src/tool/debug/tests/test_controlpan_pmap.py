import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import controlpan_pmap as c

SAMPLE = """
some unrelated log line
CONTROLPAN-PMAP col=0 row=0 port=SOUTH idx=3 dir=fwd ms=master id=1
CONTROLPAN-PMAP col=0 row=3 port=CTRL idx=0 dir=fwd ms=master id=1
[aie_runtime] ctrl_route ok: ...
CONTROLPAN-PMAP col=0 row=3 port=CTRL idx=0 dir=ret ms=slave id=1
"""

def test_parse_ports_basic():
    ports = c.parse_ports(SAMPLE)
    assert len(ports) == 3
    assert ports[0] == {"col": 0, "row": 0, "port": "SOUTH", "idx": 3,
                        "dir": "fwd", "ms": "master", "id": 1}
    assert ports[1]["port"] == "CTRL" and ports[1]["ms"] == "master"
    assert ports[2]["dir"] == "ret"

def test_parse_ports_ignores_malformed():
    bad = "CONTROLPAN-PMAP col=x row= port=SOUTH\nCONTROLPAN-PMAP col=1 row=2 port=EAST idx=0 dir=fwd ms=master id=7\n"
    ports = c.parse_ports(bad)
    assert ports == [{"col": 1, "row": 2, "port": "EAST", "idx": 0,
                      "dir": "fwd", "ms": "master", "id": 7}]

SPINE = """
CONTROLPAN-PMAP col=0 row=0 port=NORTH idx=0 dir=fwd ms=master id=1
CONTROLPAN-PMAP col=0 row=1 port=SOUTH idx=0 dir=fwd ms=slave id=1
CONTROLPAN-PMAP col=0 row=1 port=NORTH idx=0 dir=fwd ms=master id=1
CONTROLPAN-PMAP col=0 row=2 port=SOUTH idx=0 dir=fwd ms=slave id=1
"""

def test_edges_spine_pairs_north_master_to_south_slave():
    edges = c.parse_edges(SPINE)
    assert {"from": [0, 0], "to": [0, 1], "dir": "fwd", "id": 1, "port": "NORTH"} in edges
    assert {"from": [0, 1], "to": [0, 2], "dir": "fwd", "id": 1, "port": "NORTH"} in edges
    assert len(edges) == 2

EAST = """
CONTROLPAN-PMAP col=0 row=3 port=EAST idx=0 dir=fwd ms=master id=2
CONTROLPAN-PMAP col=1 row=3 port=WEST idx=0 dir=fwd ms=slave id=2
"""

def test_edges_east_chain_pairs_east_master_to_west_slave():
    edges = c.parse_edges(EAST)
    assert edges == [{"from": [0, 3], "to": [1, 3], "dir": "fwd", "id": 2, "port": "EAST"}]

def test_edges_ctrl_is_not_an_edge():
    ctrl = "CONTROLPAN-PMAP col=0 row=3 port=CTRL idx=0 dir=fwd ms=master id=1\n"
    assert c.parse_edges(ctrl) == []

def test_parse_summary_counts():
    r = c.parse(SPINE)
    assert r["count"] == 4 and len(r["edges"]) == 2
