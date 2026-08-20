---
name: debugui-llm-reset
description: Diagnoses embedded debug UI LLM context loss and replies that stop mid-sentence during Connect, board changes, or target retargeting. Use when switching targets starts a new Claude session, a transcript ends with session end, or live tools keep using the previous board.
---

# Debug UI LLM Reset

## Diagnose

1. Find the latest matching `llm_*.log` under the selected app's `worklocal`.
2. Inspect the final marker:
   - `[watchdog: ... turn abandoned]` or `[watchdog: ... claude exited]` means the
     daemon hard-stopped the turn (process gone, or 600s silence).
   - While the claude subprocess is still running, the UI keeps polling silently
     with the working indicator — no interim warning. Multi-tool turns can go
     minutes between stream-json lines while the model processes tool results.
   - `[session end]` means `llm_reset()` terminated the process.
   - No marker plus closed output means the Claude process exited independently.
3. Compare the transcript target with the next transcript and the daemon process timeline.
4. Check whether `/settarget` ran while the answer was active.

## Retarget invariant

Changing the board target or device must not restart Claude. `/settarget`
updates `backend_status.json`; the existing `aiemcp` process reads that file
before each tool call and refreshes its in-process `AieGdb` configuration.

Preserve all three:

1. The Claude subprocess and conversation.
2. The browser transcript and pending response.
3. The in-process `AieGdb` object and tile/channel scope.

Refresh the AieGdb target, device, start column, AIE version, `_reg_read`, and
`_passthrough`. Only explicit **New chat** or process recovery may advance
`llm_generation`.

## Verify

Run:

```bash
python3 -m unittest src/tool/debug/test_schedule_debug_server_llm.py
python3 -m unittest src/tool/debug/test_aiemcp_retarget.py
python3 -m py_compile src/tool/debug/schedule_debug_server.py src/tool/debug/schedule_view.py
```

Confirm both same-target reconnects and real board changes preserve the active
conversation, while the next `aie_exec` call uses the new target and device.
