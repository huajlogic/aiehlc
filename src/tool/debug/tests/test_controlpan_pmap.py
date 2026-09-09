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
