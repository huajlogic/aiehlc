# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""A chat web page in front of the qwen engine on a vek385_2 board (baremetal A78 + AIE).

  qwen_web.py --model <Qwen3.5-9B dir> --lib <dir with libqwen_gemv_lib.a, libxaienginea78.a>
              --board palmyra-14 --host gomphus12 [--port 8101]

Per question: the chat template on the host tokenizer, a tiny object with the token ids linked against the
prebuilt engine (~1 s), one netboot run on the board (the weights already sit in its DDR, qwen_board.py load),
the board's "QWT <id>" console lines decoded and streamed to the page (server-sent events), then the run's
measured profile ("QW PERF / PROF / AIE") turned into the hardware panel's utilization. One board: questions
queue. The tile utilization is derived from those measured times (AIE launch time, CPU parts), not per-core
hardware counters.
"""
import argparse, http.server, json, os, queue, re, socketserver, subprocess, sys, tempfile, threading, time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "../../../.."))
sys.path.insert(0, os.path.join(HERE, "../board"))
import qwen_board  # noqa: E402

ENGINE = os.path.join(HERE, "../engine")
SEGS = "0x800000000ULL,0x870000000ULL,0x8E0000000ULL"


class Board:
    """Builds the per-question ELF and runs it, one at a time."""

    def __init__(self, a):
        self.a = a
        self.lock = threading.Lock()
        self.work = tempfile.mkdtemp(prefix="qwen_web_")
        defs = ["QW_AIE", "QW_VERIFY=0", "QW_STREAM", "QW_PROMPT_EXTERN", f"QW_SEGS={SEGS}"]
        self.objs = qwen_board.compile_objs(
            os.path.join(self.work, "obj"),
            [os.path.join(HERE, "../board/qwen_main.c"), os.path.join(ENGINE, "qwen_engine.c"),
             os.path.join(ENGINE, "qwen_aie.c")], defs=defs, incs=[ENGINE])
        self.waiting = 0

    def elf(self, ids, ngen):
        d = tempfile.mkdtemp(dir=self.work)
        src = os.path.join(d, "prompt.c")
        with open(src, "w") as f:
            # C++ (built with the archives): `extern` keeps the const definitions external
            f.write('extern "C" const int qw_prompt_ids[] = {' + ",".join(map(str, ids)) + "};\n")
            f.write(f'extern "C" const int qw_prompt_n = {len(ids)};\n')
            f.write(f'extern "C" const int qw_prompt_ngen = {ngen};\n')
        out = os.path.join(d, "qwen.elf")
        qwen_board.build_elf(out, [src], objs=self.objs + [os.path.join(self.a.lib, "libqwen_gemv_lib.a")],
                             heap=0x20000000, opt="-O2", extra_ld=["-L" + self.a.lib],
                             libs=["xaienginea78"])
        return out

    def run(self, elf):
        """yields console lines of one board run"""
        cmd = [sys.executable, os.path.join(REPO, "script/test/apppaltest.py"), "-board", self.a.board, "-host",
               self.a.host, "-y", "--netload", "--netload-max-run-ms", "300000", "--lock-wait", "1800", elf]
        p = subprocess.Popen(cmd, cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1,
                             errors="replace")
        for line in p.stdout:
            yield line.rstrip("\n")
        p.wait()


def hw_model(perf, prof, aie):
    """Utilization (0..1) per hardware block from the run's measured times."""
    wall = perf.get("prefill", 0) + perf.get("decode", 0)
    if wall <= 0:
        return {}
    aie_s = aie.get("aie_s", 0)
    cpu = max(0.0, wall - aie_s)
    gbs = aie.get("launches", 0) * 8912896 / aie_s / 1e9 if aie_s else 0
    return {
        "aie": min(1.0, aie_s / wall),           # the 16 cores, their MemTile rings and shims stream weights
        "cpu": min(1.0, cpu / wall),             # the A78: DeltaNet, attention, norms, x/y glue
        "ddr_gbs": gbs,                          # int4 weight bytes per second of launch time
        "ddr_peak_gbs": 26.0,                    # measured AIE read bandwidth on vek385_2
        "cpu_parts": {k: v for k, v in prof.items() if k not in ("matmul", "lm_head")},
        "glue_s": aie.get("glue_s", 0),
        "wall_s": wall,
    }


def parse_stats(lines):
    perf, prof, aie = {}, {}, {}
    for l in lines:
        m = re.search(r"QW PERF prefill (\d+) tok ([\d.]+) s, decode (\d+) tok in (\d+) steps ([\d.]+) s, ([\d.]+) "
                      r"tok/s(?:, MTP accepted (\d+) / (\d+))?", l)
        if m:
            perf = {"prompt": int(m[1]), "prefill": float(m[2]), "gen": int(m[3]), "steps": int(m[4]),
                    "decode": float(m[5]), "tok_s": float(m[6])}
            if m[7]:
                perf["accepted"], perf["drafted"] = int(m[7]), int(m[8])
        m = re.search(r"QW PROF (.*) s", l)
        if m:
            parts = m[1].split()
            prof = {parts[i]: float(parts[i + 1]) for i in range(0, len(parts) - 1, 2)}
        m = re.search(r"QW AIE (\d+) launches, ([\d.]+) s in launches, ([\d.]+) s CPU x/y glue", l)
        if m:
            aie = {"launches": int(m[1]), "aie_s": float(m[2]), "glue_s": float(m[3])}
    return perf, prof, aie


class App:
    def __init__(self, a):
        from transformers import AutoTokenizer
        self.tok = AutoTokenizer.from_pretrained(a.model)
        self.board = Board(a)
        self.a = a

    def chat(self, body, send):
        msgs = [m for m in body.get("messages", []) if m.get("role") in ("user", "assistant") and m.get("content")]
        think = bool(body.get("think"))
        ngen = max(1, min(int(body.get("max_tokens", 256)), 1500))
        text = self.tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True, enable_thinking=think)
        ids = self.tok(text).input_ids
        if len(ids) + ngen > 2000:
            send({"type": "error", "text": f"prompt {len(ids)} tokens + {ngen} new exceeds the 2048-token context"})
            return
        self.board.waiting += 1
        send({"type": "status", "text": f"queued ({self.board.waiting} on the board)"})
        with self.board.lock:
            self.board.waiting -= 1
            t0 = time.time()
            send({"type": "status", "text": f"building the board app ({len(ids)} prompt tokens)"})
            elf = self.board.elf(ids, ngen)
            send({"type": "status", "text": "loading on " + self.a.board, "prompt_tokens": len(ids)})
            gen, shown, lines, first = [], "", [], None
            for line in self.board.run(elf):
                lines.append(line)
                m = re.search(r"QWT (\d+)", line)
                if m:
                    gen.append(int(m[1]))
                    if first is None:
                        first = time.time()
                        send({"type": "phase", "phase": "decode"})
                    s = self.tok.decode(gen, skip_special_tokens=True)
                    if s.startswith(shown) and len(s) > len(shown):
                        send({"type": "token", "text": s[len(shown):], "n": len(gen)})
                        shown = s
                elif "QW model" in line:
                    send({"type": "phase", "phase": "prefill"})
                elif "QW ERROR" in line or "TIMEOUT" in line:
                    send({"type": "error", "text": line.strip()[:200]})
            perf, prof, aie = parse_stats(lines)
            if not perf:
                tail = [l for l in lines if l.strip()][-6:]
                send({"type": "error", "text": "no result from the board: " + " | ".join(tail)[:400]})
                return
            send({"type": "stats", "perf": perf, "prof": prof, "aie": aie, "hw": hw_model(perf, prof, aie),
                  "host_s": time.time() - t0, "think": think})
        send({"type": "done"})


class Handler(http.server.BaseHTTPRequestHandler):
    app = None

    def log_message(self, fmt, *args):
        pass

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            body = open(os.path.join(HERE, "index.html"), "rb").read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path != "/api/chat":
            self.send_error(404)
            return
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

        def send(ev):
            self.wfile.write(("data: " + json.dumps(ev, ensure_ascii=False) + "\n\n").encode())
            self.wfile.flush()

        try:
            self.app.chat(body, send)
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:  # report to the page, keep serving
            try:
                send({"type": "error", "text": f"{type(e).__name__}: {e}"})
            except OSError:
                pass


class Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--model", required=True, help="the model dir (its tokenizer and chat template)")
    ap.add_argument("--lib", required=True, help="dir with libqwen_gemv_lib.a and libxaienginea78.a")
    ap.add_argument("--board", default="palmyra-14")
    ap.add_argument("--host", default="gomphus12")
    ap.add_argument("--port", type=int, default=8101)
    a = ap.parse_args()
    Handler.app = App(a)
    print(f"qwen web: http://{os.uname().nodename}:{a.port}/  (board {a.board} on {a.host})", flush=True)
    Server(("0.0.0.0", a.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
