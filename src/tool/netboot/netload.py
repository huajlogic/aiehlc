#!/usr/bin/env python3
"""Host client for the netboot supervisor (doc/design/lwip_elf_bootloader.md).

Runs on the lab host that shares a segment with the board's GEM0 (PALIP),
standard library only:

    python3 netload.py load  main.elf [--timeout-ms N]   # send, place, start on the app core
    python3 netload.py rerun          [--timeout-ms N]   # start the staged ELF again, no transfer
    python3 netload.py kill                              # power the app core down
    python3 netload.py status

Exit status is 0 only when the board replied rc == 0. The app's console output
is NOT on this socket: it stays on the board UART (com0), which apppaltest.py
--netload reads exactly as it does for a JTAG download.
"""
import argparse
import hashlib
import socket
import struct
import sys
import time

PORT = 5155
REQ_MAGIC = 0x3154424E  # 'NBT1'
REP_MAGIC = 0x3152424E  # 'NBR1'
VERSION = 1
CMDS = {"load": 1, "rerun": 2, "kill": 3, "status": 4}
STATES = {0: "idle", 1: "running", 2: "killed", 3: "watchdog-timeout", 4: "exited"}
REQ_FMT = "<IIIIQII32s"            # struct netboot_req, 64 B
REP_FMT = "<IiQIIQIIII"            # struct netboot_rep, 48 B
assert struct.calcsize(REQ_FMT) == 64 and struct.calcsize(REP_FMT) == 48


def recv_exact(sock, n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError(f"board closed the connection after {len(buf)}/{n} reply bytes")
        buf += chunk
    return buf


def request(host, cmd, payload=b"", timeout_ms=0, connect_timeout=5.0, reply_timeout=60.0):
    digest = hashlib.sha256(payload).digest() if payload else bytes(32)
    hdr = struct.pack(REQ_FMT, REQ_MAGIC, VERSION, CMDS[cmd], 0, len(payload), timeout_ms, 0, digest)
    t0 = time.monotonic()
    with socket.create_connection((host, PORT), timeout=connect_timeout) as s:
        s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        s.settimeout(reply_timeout)
        s.sendall(hdr + payload)
        t_sent = time.monotonic()
        rep = struct.unpack(REP_FMT, recv_exact(s, 48))
        magic, rc, bytes_rx, rx_ms, place_ms, entry, state, run_ms, runs, msg_len = rep
        if magic != REP_MAGIC:
            raise ConnectionError(f"bad reply magic 0x{magic:08x}")
        msg = recv_exact(s, msg_len).decode(errors="replace") if msg_len else ""
    t_done = time.monotonic()
    return {
        "rc": rc, "bytes_rx": bytes_rx, "rx_ms": rx_ms, "place_ms": place_ms, "entry": entry,
        "state": STATES.get(state, str(state)), "run_ms": run_ms, "runs": runs, "msg": msg,
        "send_s": t_sent - t0, "total_s": t_done - t0,
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=sorted(CMDS))
    ap.add_argument("elf", nargs="?", help="ELF to send (load only)")
    ap.add_argument("--host", default="10.10.70.50", help="board IP (netboot build.sh NETBOOT_IP)")
    ap.add_argument("--timeout-ms", type=int, default=0, help="watchdog for this run (0 = board default 600 s)")
    ap.add_argument("--connect-timeout", type=float, default=5.0)
    a = ap.parse_args(argv)

    payload = b""
    if a.cmd == "load":
        if not a.elf:
            ap.error("load needs an ELF path")
        with open(a.elf, "rb") as f:
            payload = f.read()
    try:
        r = request(a.host, a.cmd, payload, a.timeout_ms, a.connect_timeout)
    except (OSError, ConnectionError) as e:
        print(f"[netload] {a.cmd}: no answer from {a.host}:{PORT}: {e}")
        return 2
    mb = len(payload) / 1e6
    line = f"[netload] {a.cmd} rc={r['rc']} state={r['state']} runs={r['runs']}"
    if a.cmd == "load":
        rate = mb / r["send_s"] if r["send_s"] > 0 else 0.0
        line += (f" | {mb:.2f} MB sent in {r['send_s']:.3f} s ({rate:.1f} MB/s), board rx {r['rx_ms']} ms,"
                 f" place {r['place_ms']} ms, entry 0x{r['entry']:x}")
    elif r["state"] == "running":
        line += f" run_ms={r['run_ms']}"
    print(line)
    if r["msg"]:
        print(f"[netload] board: {r['msg']}")
    return 0 if r["rc"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
