#!/usr/bin/env python3
"""Unit test for __Runtime_core_trace_decode (src/mlir/runtime/aie_runtime.c).

The C decoder cannot be linked standalone (aie_runtime.c pulls in xaiengine.h),
so this test extracts ONLY the self-contained decoder region from the real
source -- the `s_core_trace_slot_name[]` table plus everything from
`#define XAIE_TRACE_SYNC_CYCLES` down to the end of __Runtime_core_trace_decode
-- wraps it in a tiny main() harness, compiles it with gcc, and runs it. It is
the actual production bytes that are exercised, so a regression in aie_runtime.c
fails this test.

Each case is driven by an INDEPENDENT frame encoder (the inverse of the decoder,
built directly from Figure 4-14) and checked two ways:
  1. against a hand-derived golden timeline, and
  2. against the Python reference model core_trace_decode.CoreTraceDecoder,
     which must produce byte-identical faithful output.
"""

import io
import os
import re
import shutil
import subprocess
import sys
import tempfile
from contextlib import redirect_stdout

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import core_trace_decode as ctd  # noqa: E402

_RUNTIME_C = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..",
                 "mlir", "runtime", "aie_runtime.c"))

# --------------------------------------------------------------------------
# Extract the real decoder from aie_runtime.c and build a compilable harness.
# --------------------------------------------------------------------------
def _extract_c_decoder(src):
    m = re.search(r"static const char \*const s_core_trace_slot_name\[4\][^;]*;", src)
    assert m, "s_core_trace_slot_name[4] table not found in aie_runtime.c"
    slot_tbl = m.group(0)

    start = src.index("#define XAIE_TRACE_SYNC_CYCLES")
    end = src.index("// Global routing instance", start)
    block = src[start:end].rstrip()
    assert "__Runtime_core_trace_decode" in block, "decoder body not captured"
    return slot_tbl, block


_HARNESS_MAIN = r"""
int main(int argc, char **argv) {
    static uint32_t buf[8192];
    uint32_t n = 0;
    for (int i = 1; i < argc && n < 8192; i++)
        buf[n++] = (uint32_t)strtoul(argv[i], NULL, 0);
    __Runtime_core_trace_decode(buf, n);
    return 0;
}
"""


def _build_harness():
    """Compile the extracted decoder + harness. Returns the binary path, or
    None if gcc is unavailable (caller skips)."""
    if shutil.which("gcc") is None:
        return None
    with open(_RUNTIME_C) as f:
        src = f.read()
    slot_tbl, block = _extract_c_decoder(src)
    prog = ("#include <stdint.h>\n#include <stdio.h>\n#include <stdlib.h>\n\n"
            + slot_tbl + "\n\n" + block + "\n" + _HARNESS_MAIN)

    d = tempfile.mkdtemp(prefix="ctd_ut_")
    cpath = os.path.join(d, "harness.c")
    bpath = os.path.join(d, "harness")
    with open(cpath, "w") as f:
        f.write(prog)
    r = subprocess.run(["gcc", "-Wall", "-std=c11", "-O0", "-o", bpath, cpath],
                       capture_output=True, text=True)
    assert r.returncode == 0, f"decoder failed to compile:\n{r.stderr}"
    return bpath


_CC_BIN = None
_CC_TRIED = False


def _cc_bin():
    global _CC_BIN, _CC_TRIED
    if not _CC_TRIED:
        _CC_TRIED = True
        _CC_BIN = _build_harness()
    return _CC_BIN


# --------------------------------------------------------------------------
# Independent frame encoder (inverse of the decoder, from Figure 4-14).
# Frames are byte-aligned (all widths are multiples of 8), MSB-first.
# --------------------------------------------------------------------------
def _u16(v):
    return bytes([(v >> 8) & 0xFF, v & 0xFF])


def _u24(v):
    return bytes([(v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF])


def _u32(v):
    return bytes([(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF])


def start(timer, overrun=0):
    w0 = (0x1E << 27) | ((overrun & 1) << 26) | (0 << 24) | ((timer >> 32) & 0xFFFFFF)
    return _u32(w0) + _u32(timer & 0xFFFFFFFF)


def single(event, cyc):
    if cyc < 16:                                             # Single0 8b: 0 eee cccc
        return bytes([((event & 7) << 4) | (cyc & 0xF)])
    if cyc < 1024:                                           # Single1 16b: 100 eee c(10)
        return _u16((0b100 << 13) | ((event & 7) << 10) | (cyc & 0x3FF))
    return _u24((0b101 << 21) | ((event & 7) << 18) | (cyc & 0x3FFFF))  # Single2 24b


def multiple(mask, cyc):
    if cyc < 16:                                             # Multiple0 16b: 1100 m(8) c(4)
        return _u16((0b1100 << 12) | ((mask & 0xFF) << 4) | (cyc & 0xF))
    if cyc < 1024:                                           # Multiple1 24b: 110100 m(8) c(10)
        return _u24((0b110100 << 18) | ((mask & 0xFF) << 10) | (cyc & 0x3FF))
    return _u32((0b110101 << 26) | ((mask & 0xFF) << 18) | (cyc & 0x3FFFF))  # Multiple2 32b


def repeat(n):
    if n < 16:                                               # Repeat0 8b: 1110 r(4)
        return bytes([(0b1110 << 4) | (n & 0xF)])
    return _u16((0b110110 << 10) | (n & 0x3FF))             # Repeat1 16b: 110110 r(10)


def stop(cyc, x=0):                                          # Stop 32b: 110111 x(8) c(18)
    return _u32((0b110111 << 26) | ((x & 0xFF) << 18) | (cyc & 0x3FFFF))


def filler():
    return b"\xFE"


def sync():
    return b"\xFF"


PKT_HDR = 0x00000001  # packet id=1, type=0


def pack(*frames, header=PKT_HDR, terminate=True):
    """Concatenate frames, pad the final packet with Filler (as the trace unit
    does), split into 7-word payload packets each prefixed with a header word,
    and append an all-zero terminator packet."""
    data = b"".join(frames)
    while len(data) % 28 != 0:      # 28 bytes = 7 words = one packet payload
        data += b"\xFE"
    words = [(data[i] << 24) | (data[i + 1] << 16) | (data[i + 2] << 8) | data[i + 3]
             for i in range(0, len(data), 4)]
    out = []
    for i in range(0, len(words), 7):
        out.append(header)
        out.extend(words[i:i + 7])
    if terminate:
        out.extend([0] * 8)
    return out


FILLER_WORD = 0xFEFEFEFE  # four Filler bytes -> alignment pad, decodes to nothing


def pack_payload(words, header=PKT_HDR, terminate=True):
    """Place `words` VERBATIM into payload slots (buf[1..7] of each 8-word
    packet) so the header-skipping transport decodes them as ONE contiguous
    frame stream with NO packet header of their own -- i.e. word[0] is decoded
    as a real frame, not consumed as a routing header.

    Unlike pack(), which treats its arguments as an encoded frame byte stream,
    pack_payload takes already-formed 32-bit trace words (e.g. a raw capture)
    and just routes them through the transport untouched. The final packet is
    padded with Filler words (0xFEFEFEFE, a decode no-op) up to a whole packet,
    and an all-zero terminator packet is appended."""
    out = []
    for i in range(0, len(words), 7):
        chunk = list(words[i:i + 7])
        while len(chunk) < 7:
            chunk.append(FILLER_WORD)
        out.append(header)
        out.extend(chunk)
    if terminate:
        out.extend([0] * 8)
    return out


# --------------------------------------------------------------------------
# Runners: real C decoder and Python reference model, faithful output.
# --------------------------------------------------------------------------
def _norm(text):
    """C prints buf=<pointer>; the Python model prints buf=<sim>. Normalise so
    the two faithful transcripts are directly comparable."""
    return re.sub(r"buf=(0x[0-9a-fA-F]+|\(nil\))", "buf=<sim>", text)


def run_c(words):
    b = _cc_bin()
    assert b is not None
    r = subprocess.run([b] + [hex(w) for w in words], capture_output=True, text=True)
    assert r.returncode == 0, f"harness crashed: {r.stderr}"
    return _norm(r.stdout)


def run_py(words):
    buf = io.StringIO()
    with redirect_stdout(buf):
        ctd.CoreTraceDecoder(mode="faithful").decode(words, nwords=len(words))
    return buf.getvalue()


# Faithful output is run-length compressed: a single cycle is "<cycle>  <events>",
# an interval is "<start> -- <end>  <events>  (<N> cyc)", and <events> joins slot
# names with '|'. Banners start with '[' and never match. Expanding an interval
# back to per-cycle, per-slot tuples reconstructs the exact old timeline.
_EVT = re.compile(r"^(\d+)(?:\s+--\s+(\d+))?  (\S+?)(?:  \(\d+ cyc\))?$")


def timeline(text):
    out = []
    for ln in text.splitlines():
        m = _EVT.match(ln)
        if not m:
            continue
        start = int(m.group(1))
        end = int(m.group(2)) if m.group(2) else start
        names = m.group(3).split("|")
        for cyc in range(start, end + 1):
            for nm in names:
                out.append((cyc, nm))
    return out


def format_parse_detail(label, text, head=20, tail=5):
    """Render a human-readable parse report from a faithful transcript: the API
    banner, any START/STOP control lines, event/cycle span, the per-slot
    histogram, and a head/tail sample of the decoded timeline. Used by the
    capture tests to SHOW what was parsed, not just assert pass/fail."""
    import collections
    lines = text.splitlines()
    ctrl = [l for l in lines if "START" in l or "STOP" in l]
    tl = timeline(text)
    hist = dict(collections.Counter(n for _, n in tl))
    r = ["=== parse detail: %s ===" % label]
    if lines:
        r.append(lines[0])                     # [aie_runtime] ... banner
    r.extend(ctrl)
    if tl:
        r.append("events: %d   cycles: %d..%d" % (len(tl), tl[0][0], tl[-1][0]))
    else:
        r.append("events: 0")
    r.append("slots : %s" % hist)
    sample = tl[:head]
    r.append("first %d:" % len(sample))
    r += ["  %d  %s" % (cy, nm) for cy, nm in sample]
    if len(tl) > head + tail:
        r.append("  ... (%d more) ..." % (len(tl) - head - tail))
    if len(tl) > head:
        last = tl[-tail:]
        r.append("last %d:" % len(last))
        r += ["  %d  %s" % (cy, nm) for cy, nm in last]
    return "\n".join(r)


def _skip_if_no_cc():
    if _cc_bin() is None:
        try:
            import pytest
            pytest.skip("gcc not available")
        except ImportError:
            raise SystemExit("SKIP: gcc not available")


# --------------------------------------------------------------------------
# Cross-check helper: C == Python (faithful), and timeline == golden.
# --------------------------------------------------------------------------
def _check(words, golden):
    _skip_if_no_cc()
    c_out = run_c(words)
    py_out = run_py(words)
    assert c_out == py_out, (
        "C decoder and Python model disagree:\n--- C ---\n%s\n--- PY ---\n%s"
        % (c_out, py_out))
    assert timeline(c_out) == golden, (
        "timeline mismatch:\n got %s\n want %s" % (timeline(c_out), golden))
    return c_out


# --------------------------------------------------------------------------
# Extraction sanity (runs without a compiler).
# --------------------------------------------------------------------------
def test_extract_regions_present():
    with open(_RUNTIME_C) as f:
        src = f.read()
    slot_tbl, block = _extract_c_decoder(src)
    assert "ACTIVE" in slot_tbl and "MEMORY_STALL" in slot_tbl
    assert "__core_trace_bits" in block
    assert "void __Runtime_core_trace_decode(" in block


# --------------------------------------------------------------------------
# Per-frame decode cases.
# --------------------------------------------------------------------------
def test_demo_start_single_multiple_sync():
    words = pack(start(1000), single(0, 10), single(2, 100),
                 filler(), multiple(0x03, 5), sync())
    out = _check(words, [(1010, "ACTIVE"), (1110, "STREAM_STALL"),
                         (1115, "ACTIVE"), (1115, "LOCK_STALL")])
    assert "START timer=1000 overrun=0" in out


def test_demo_words_match_reference_demo():
    # The independently packed demo must equal core_trace_decode._demo_words().
    words = pack(start(1000), single(0, 10), single(2, 100),
                 filler(), multiple(0x03, 5), sync())
    assert words[:8] == ctd._demo_words()


def test_single2_wide_cycle():
    # cyc=100000 forces the 24-bit Single2 form; slot 3 = MEMORY_STALL.
    words = pack(start(0), single(3, 100000))
    _check(words, [(100000, "MEMORY_STALL")])


def test_multiple1_and_multiple2_with_event_slots():
    words = pack(start(0), multiple(0xFF, 500), multiple(0x81, 200000))
    golden = [(500, "ACTIVE"), (500, "LOCK_STALL"), (500, "STREAM_STALL"),
              (500, "MEMORY_STALL"), (500, "EVENT4"), (500, "EVENT5"),
              (500, "EVENT6"), (500, "EVENT7"),
              (200500, "ACTIVE"), (200500, "EVENT7")]
    _check(words, golden)


def test_repeat0_after_single():
    # Repeat0 (n<16) re-emits the previous single event, +1 cycle each.
    words = pack(start(0), single(0, 10), repeat(3))
    _check(words, [(10, "ACTIVE"), (11, "ACTIVE"), (12, "ACTIVE"), (13, "ACTIVE")])


def test_repeat1_after_single():
    # n>=16 forces the 16-bit Repeat1 form.
    words = pack(start(0), single(0, 10), repeat(16))
    golden = [(10, "ACTIVE")] + [(11 + i, "ACTIVE") for i in range(16)]
    _check(words, golden)


def test_repeat_after_multiple_reemits_mask():
    words = pack(start(0), multiple(0x05, 5), repeat(2))
    golden = [(5, "ACTIVE"), (5, "STREAM_STALL"),
              (6, "ACTIVE"), (6, "STREAM_STALL"),
              (7, "ACTIVE"), (7, "STREAM_STALL")]
    _check(words, golden)


def test_stop_frame_prints_and_ends_events():
    words = pack(start(0), single(1, 5), stop(3))
    out = _check(words, [(5, "LOCK_STALL")])
    assert "STOP @ 8" in out


def test_start_overrun_flag():
    words = pack(start(1000, overrun=1), single(0, 1))
    out = _check(words, [(1001, "ACTIVE")])
    assert "START timer=1000 overrun=1" in out


# --------------------------------------------------------------------------
# Transport-framing cases.
# --------------------------------------------------------------------------
def test_frames_span_multiple_packets():
    # 1 Start (8B) + 30 x Single0 (1B) = 38B -> 2 packets; the header word of
    # the 2nd packet must be skipped mid-frame-stream.
    frames = [start(0)] + [single(0, 1) for _ in range(30)]
    words = pack(*frames)
    assert words.count(PKT_HDR) == 2  # two real packets
    _check(words, [(i + 1, "ACTIVE") for i in range(30)])


def test_all_zero_packet_terminates_before_garbage():
    # A real packet, the all-zero terminator, THEN a bogus non-zero packet that
    # must be ignored (caller passes full buffer capacity).
    good = pack(start(1000), single(0, 10), single(2, 100),
                filler(), multiple(0x03, 5), sync())
    garbage = pack(start(9), single(0, 7), terminate=False)  # must not be decoded
    words = good + garbage
    _check(words, [(1010, "ACTIVE"), (1110, "STREAM_STALL"),
                   (1115, "ACTIVE"), (1115, "LOCK_STALL")])


def test_empty_buffer_is_header_only():
    _skip_if_no_cc()
    words = [0] * 8  # a single all-zero packet: nothing to decode
    c_out = run_c(words)
    assert timeline(c_out) == []
    assert run_c(words) == run_py(words)


# --------------------------------------------------------------------------
# Real captured buffer -- a raw 8-word packet exactly as passed by a caller.
#
#   [0] 0xf0000000  [1] 0x00d5922e  [2] 0x00d971ff  [3] 0xd833fefe
#   [4] 0xa1373300  [5] 0xd999fffe  [6] 0xdbffdbff  [7] 0xdbffdbff
#
# NOTE: word[0]=0xf0000000 is consumed as the stream-packet ROUTING HEADER (the
# transport layer skips buf[0] of every 8-word packet), so frame decoding starts
# at buf[1]=0x00d5922e -- NOT at word[0]. Even though 0xf0000000 looks like a
# Start frame, here it is the header and is skipped. The 7 payload words contain
# Repeat1 frames (count 1023) that expand into a large timeline (1522 events).
# This is a CHARACTERIZATION test: the anchors are ground truth captured from
# the real decoder, and all three drivers (C harness, Python model, and -- in
# test_core_trace_decode_cython -- the in-process Cython bind) must agree.
# --------------------------------------------------------------------------
USER_CAPTURE = [0xf0000000, 0x00d5922e, 0x00d971ff, 0xd833fefe,
                0xa1373300, 0xd999fffe, 0xdbffdbff, 0xdbffdbff]


def test_user_capture_8word_packet():
    import collections
    _skip_if_no_cc()
    c_out = run_c(USER_CAPTURE)
    assert c_out == run_py(USER_CAPTURE)        # C decoder == Python model

    tl = timeline(c_out)
    assert c_out.splitlines()[0] == (
        "[aie_runtime] core_trace_decode: buf=<sim> nwords=8")
    # buf[0]=0xf0000000 skipped as header; first payload byte 0x00 -> Single0
    # event 0, cycle 0.
    assert tl[0] == (0, "ACTIVE")
    assert tl[1:4] == [(142848, "STREAM_STALL"), (142848, "EVENT5"),
                       (142848, "EVENT6")]
    assert tl[-1] == (13854729, "ACTIVE")
    assert len(tl) == 1522
    assert max(cyc for cyc, _ in tl) == 13854729
    assert dict(collections.Counter(n for _, n in tl)) == {
        "ACTIVE": 412, "STREAM_STALL": 370, "EVENT5": 370, "EVENT6": 370}


# --------------------------------------------------------------------------
# Same 8 words, but with NO packet header -- the words ARE the raw payload.
#
#   [0] 0xf0000000  [1] 0x00d5922e  [2] 0x00d971ff  [3] 0xd833fefe
#   [4] 0xa1373300  [5] 0xd999fffe  [6] 0xdbffdbff  [7] 0xdbffdbff
#
# Here word[0]=0xf0000000 is NOT a routing header: type byte 0xf0 = 11110000
# matches the Start-frame prefix (11110 O 00), so it IS decoded as Start
# (timer = 0x00d5922e = 13996590, overrun=0). pack_payload() drops the words
# straight into payload slots so the header-skipping transport sees them as one
# contiguous frame stream. The trailing Repeat1 frames (0xdbff = 1023 reps,
# 0xd971 = 369 reps, ...) expand the single ACTIVE events into an 781-entry
# timeline. This decode was cross-checked against an independent no-header
# reference (pw = identity, 256-bit stream) and matches exactly.
# --------------------------------------------------------------------------
USER_CAPTURE_NOHDR = [0xf0000000, 0x00d5922e, 0x00d971ff, 0xd833fefe,
                      0xa1373300, 0xd999fffe, 0xdbffdbff, 0xdbffdbff]


def test_user_capture_8word_no_pkt_header():
    import collections
    _skip_if_no_cc()
    words = pack_payload(USER_CAPTURE_NOHDR)
    c_out = run_c(words)
    assert c_out == run_py(words)               # C decoder == Python model

    # SHOW the parse detail, not just pass/fail.
    print("\n" + format_parse_detail("USER_CAPTURE no-pkt-header (C API)", c_out))

    tl = timeline(c_out)
    # word[0]=0xf0000000 decoded as Start: timer = 0x00d5922e = 13996590.
    assert any("START timer=13996590 overrun=0" in l for l in c_out.splitlines())
    assert tl[0] == (13996590, "ACTIVE")        # Single0 event0 at the timer base
    assert tl[-1] == (27708471, "ACTIVE")
    assert len(tl) == 781
    assert max(cyc for cyc, _ in tl) == 27708471
    assert dict(collections.Counter(n for _, n in tl)) == {"ACTIVE": 781}


# --------------------------------------------------------------------------
# Standalone runner (works without pytest installed).
# --------------------------------------------------------------------------
def _main():
    fns = [g for n, g in sorted(globals().items())
           if n.startswith("test_") and callable(g)]
    passed = skipped = 0
    for fn in fns:
        try:
            fn()
            passed += 1
            print(f"PASS  {fn.__name__}")
        except SystemExit as e:
            skipped += 1
            print(f"SKIP  {fn.__name__}: {e}")
        except AssertionError as e:
            print(f"FAIL  {fn.__name__}: {e}")
            return 1
    print(f"\n{passed} passed, {skipped} skipped")
    return 0


if __name__ == "__main__":
    sys.exit(_main())
