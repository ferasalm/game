# Brief: efficiency-tools (<= 60 lines)
You are in your own worktree on branch gemini/efficiency-tools (made from main). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill only for its testing habits; this task is Python and bash.

## Why
Feras (2026-10-23): reviews must be checklist-gated so Opus only judges design and renders; Claude must see which
builder slots are busy (2 agy, 2 Cloudflare DeepSeek, 1 Inkling) and what DeepSeek costs.

## Read first
tools/build_gate.py (all of it), tools/test_build_gate.py, tools/build_pipeline.sh, tools/cf_build.sh,
tools/oc_task.sh, docs/briefs/TEMPLATE.md, docs/EFFICIENCY.md section 3b.

## What to build
1. Checklist in briefs. A brief may end with a section `## Checklist` with one item per line, exactly these forms:
   `- file: <path>` (exists in the branch), `- has: <path> :: <literal text>` (the file contains the text),
   `- test: <path> :: <func name>` (the file defines `func <name>(`), `- key: <csv path> :: <KEY>` (a line of that
   CSV starts with `<KEY>,`). build_gate.py `gate` checks every item in the worktree: each miss prints
   `CHECKLIST missing: <item>` and the verdict becomes FAIL (after NOWORK and BREACH, which keep priority). A brief
   with no `## Checklist` section prints `WARN no checklist in the brief`. An unknown form prints `WARN checklist
   item not understood: <line>`.
2. Builder in the result. build_pipeline.sh takes a builder name it already knows (agy, oc, or cf when cf_build.sh
   calls it; read cf_build.sh to see how it calls the pipeline, and pass the name through without changing its
   other behaviour) and writes `builder <agy|oc|cf>` as line 2 of `../game-wt/<task>.result` (line 1 stays
   `<STATUS> <HH:MM> <branch-or-step>`; every later line moves down one; the RUNNING lines get it too).
3. tools/slots.sh: reads `../game-wt/*.result` (relative to the repo root's parent, like the pipeline). Prints one
   line per run whose first word is RUNNING: `<builder> <task> <step> since <HH:MM>`; then `agy n/2  cf n/2  oc n/1`;
   exits 1 when any builder is over its cap, else 0. A RUNNING result whose log `../game-wt/<task>.log` has not
   changed for 120 minutes is printed with `STALE?` and not counted. Caps live in one line at the top of the script.
4. DeepSeek spend log: after a cf run ends, cf_build.sh appends one CSV line to `../game-wt/cf_spend.csv`:
   `date,task,input_tokens,output_tokens,usd` with tokens parsed from the run's log (opencode prints usage; read a
   real log in ../game-wt/*.log to find the format; if it is absent write blanks and usd `?`). Rates (USD per million
   tokens) at the top of cf_build.sh: input 0.30, output 1.20. slots.sh prints `cf spend this month: $X.XX`.
5. docs/briefs/TEMPLATE.md: add the `## Checklist` section (the four forms, one example each) before `## Proof`.

## Do NOT edit
`features/`, `core/`, `content/`, `localization/`, `docs/DECISIONS.md`, `HANDOFF.md`, `CLAUDE.md`, `GEMINI.md`,
`AGENTS.md`, `docs/EFFICIENCY.md`, `.claude/`

## Tests (tools/test_build_gate.py, tools/test_slots.py; check.sh's tool_tests runs them)
Each checklist form passes and misses on a tmp git repo; a miss makes the verdict FAIL; NOWORK still wins; no
checklist gives the WARN; an unknown form gives its WARN; slots.sh counts per builder, flags STALE?, exits 1 over a
cap; the spend line parses a sample log and writes blanks plus `?` when usage is absent.

## Checklist
- file: tools/slots.sh
- file: tools/test_slots.py
- has: tools/build_gate.py :: CHECKLIST missing
- has: docs/briefs/TEMPLATE.md :: ## Checklist
- has: tools/cf_build.sh :: cf_spend.csv

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
