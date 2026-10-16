#!/usr/bin/env python3
"""Host client for the netboot supervisor (doc/design/lwip_elf_bootloader.md).

Standard library only. Two ways to reach the board:

  * on the lab host (PALIP), which shares a segment with the board's GEM0: direct TCP;
  * from anywhere that can ssh to PALIP: --via user@PALIP streams the request
    through ssh into netboot_proxy.py on PALIP (copied there once), so the ELF is
    never scp'd and nothing lands on PALIP's disk.

    python3 netload.py load  main.elf [--timeout-ms N]   # send, place, start on the app core
    python3 netload.py load  main.elf --via huaj@10.23.224.213   # same, from the dev box
    python3 netload.py rerun          [--timeout-ms N]   # start the staged ELF again, no transfer
    python3 netload.py kill                              # power the app core down
    python3 netload.py status

Exit status is 0 only when the board replied rc == 0. The app's console output
is NOT on this socket: it stays on the board UART (com0), which apppaltest.py
--netload reads exactly as it does for a JTAG download.
"""
import argparse
import hashlib
import select
import socket
import struct
import subprocess
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


class TcpLink:
    """Direct connection (run on the lab host)."""

    def __init__(self, host, connect_timeout, reply_timeout):
        self.s = socket.create_connection((host, PORT), timeout=connect_timeout)
        self.s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        self.s.settimeout(reply_timeout)

    def send_part(self, data):
        self.s.sendall(data)

    def send(self, data):
        self.s.sendall(data)

    def recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.s.recv(n - len(buf))
            if not chunk:
                raise ConnectionError(f"board closed the connection after {len(buf)}/{n} reply bytes")
            buf += chunk
        return buf

    def close(self):
        self.s.close()


class SshProxyLink:
    """ssh <via> python3 <proxy>: the bytes ride ssh stdin/stdout through netboot_proxy.py."""

    def __init__(self, via, proxy, host, connect_timeout, reply_timeout, ssh_opts=()):
        self.reply_timeout = reply_timeout
        self.p = subprocess.Popen(
            ["ssh", "-o", "BatchMode=yes", *ssh_opts, via, "python3", proxy, "--host", host, "--port", str(PORT),
             "--connect-timeout", str(connect_timeout)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def send_part(self, data):
        self.p.stdin.write(data)
        self.p.stdin.flush()

    def send(self, data):
        self.send_part(data)
        self.p.stdin.close()  # one request per connection: EOF = TCP half-close at the proxy

    def recv_exact(self, n):
        buf = b""
        fd = self.p.stdout.fileno()
        while len(buf) < n:
            if not select.select([fd], [], [], self.reply_timeout)[0]:
                raise ConnectionError(f"no reply within {self.reply_timeout:.0f} s")
            chunk = self.p.stdout.read1(n - len(buf))
            if not chunk:
                err = self.p.stderr.read().decode(errors="replace").strip()
                raise ConnectionError(err or f"proxy closed after {len(buf)}/{n} reply bytes")
            buf += chunk
        return buf

    def close(self):
        try:
            self.p.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.p.kill()


# Optional callable run before the LAST bytes of a request go out. The supervisor
# cannot start the app before it has every byte, so a caller can overlap its own
# setup (apppaltest: attaching the console) with the transfer and still be ready
# before the app prints anything.
send_gate = None
GATE_TAIL = 4096


def request(host, cmd, payload=b"", timeout_ms=0, connect_timeout=5.0, reply_timeout=60.0, via=None, proxy=None,
            ssh_opts=()):
    digest = hashlib.sha256(payload).digest() if payload else bytes(32)
    hdr = struct.pack(REQ_FMT, REQ_MAGIC, VERSION, CMDS[cmd], 0, len(payload), timeout_ms, 0, digest)
    t0 = time.monotonic()
    link = (SshProxyLink(via, proxy, host, connect_timeout, reply_timeout, ssh_opts) if via
            else TcpLink(host, connect_timeout, reply_timeout))
    try:
        body = hdr + payload
        if send_gate and len(body) > GATE_TAIL:
            link.send_part(body[:-GATE_TAIL])
            send_gate()
            link.send(body[-GATE_TAIL:])
        else:
            link.send(body)
        t_sent = time.monotonic()
        rep = struct.unpack(REP_FMT, link.recv_exact(48))
        magic, rc, bytes_rx, rx_ms, place_ms, entry, state, run_ms, runs, msg_len = rep
        if magic != REP_MAGIC:
            raise ConnectionError(f"bad reply magic 0x{magic:08x}")
        msg = link.recv_exact(msg_len).decode(errors="replace") if msg_len else ""
    finally:
        link.close()
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
    ap.add_argument("--via", metavar="USER@HOST", help="reach the board through netboot_proxy.py on this host")
    ap.add_argument("--proxy", default="~/aiehlc/netboot/netboot_proxy.py", help="proxy path on the --via host")
    ap.add_argument("--ssh-opt", action="append", default=[], metavar="OPT",
                    help="extra `ssh -o` option for --via (repeatable), e.g. ControlPath=... to reuse a connection")
    a = ap.parse_args(argv)

    payload = b""
    if a.cmd == "load":
        if not a.elf:
            ap.error("load needs an ELF path")
        with open(a.elf, "rb") as f:
            payload = f.read()
    try:
        ssh_opts = [x for o in a.ssh_opt for x in ("-o", o)]
        r = request(a.host, a.cmd, payload, a.timeout_ms, a.connect_timeout, via=a.via, proxy=a.proxy,
                    ssh_opts=ssh_opts)
    except (OSError, ConnectionError) as e:
        print(f"[netload] {a.cmd}: no answer from {a.host}:{PORT}: {e}")
        return 2
    mb = len(payload) / 1e6
    line = f"[netload] {a.cmd} rc={r['rc']} state={r['state']} runs={r['runs']}"
    if a.cmd == "load":
        rate = mb / r["send_s"] if r["send_s"] > 0 else 0.0
        how = f" via {a.via}" if a.via else ""
        line += (f" | {mb:.2f} MB sent{how} in {r['send_s']:.3f} s ({rate:.1f} MB/s), board rx {r['rx_ms']} ms,"
                 f" place {r['place_ms']} ms, entry 0x{r['entry']:x}")
    elif r["state"] == "running":
        line += f" run_ms={r['run_ms']}"
    print(line)
    if r["msg"]:
        print(f"[netload] board: {r['msg']}")
    return 0 if r["rc"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
