# Brief: row28-j-night-queue (nv; shell and Python, RUN_KIND=py)
You are in your own worktree on branch oc/row28-j-night-queue (made from origin/main after parts d and a). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/nv_build.sh, tools/test_nv_build.py
Timebox: 40 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: NVIDIA NIM is for prototyping, so it serves only work where time has zero priority: an overnight queue. NIM is slow (DeepSeek 439 s and GLM 218 s on a toy task), so QUIET_SEC needs headroom. Pillar served: none directly (free capacity).

## Read first
tools/nv_build.sh, tools/builders.conf (CAP_NV, QUIET_SEC), tools/slots.sh, docs/queue-rules.md.

## What to build
1. `tools/night_queue.sh <queue-file>`: the file lists one task per line (`task brief base`). Between 00:00 and 07:00 GMT+3 it runs them one after another through nv_build.sh pinned to nvidia/deepseek-ai/deepseek-v4.1-flash (or nvidia/z-ai/glm-5.3-flash when the line says glm), QUIET_SEC=600; outside the window it prints `waiting for 00:00 GMT+3` and exits 0 without running anything.
2. After each task it appends one line to a log file in the worktree folder (task, result word, minutes); it stops at 07:00 even mid-queue (the running task is allowed to finish its check, nothing new starts).
3. It refuses a queue line whose task or base does not exist, before running anything.
4. One paragraph in routing.md: NIM is overnight only; day chains do not use it.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`.claude/skills/low-cost-pipeline/routing.md`

## Ripple
nv_build.sh stays unchanged (it has the part d preflight); CAP_NV 3 still bounds parallel NIM runs: the queue runs serially. docs/queue-rules.md is not changed.

## Pre-mortem
- The clock window is wrong near midnight: the test fixes the time through an env var at 23:59, 00:00, 06:59 and 07:00.
- NIM rate limits end a night early: NV_FALLBACK_RE already falls through to the chain's next model; the log marks quota.
- Two queues overlap: a lock file in the worktree folder refuses a second start.

## Tests
- tools/test_night_queue.py :: window edges, bad line refused, lock refused, stub nv_build called once per line (red on the base). Player-visible: not applicable.

## Checklist
- file: tools/night_queue.sh
- has: tools/night_queue.sh :: QUIET_SEC
- test: tools/test_night_queue.py :: test_waits_outside_the_window

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
