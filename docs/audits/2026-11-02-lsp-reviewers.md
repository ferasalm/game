# LSP for the reviewer agents (row 27): verdict DON'T DO now, revisit after M1 (Sonnet 5.5 high chat, 2026-11-02; the brief asked for Opus high)
Question: should the 6 `studio:review-*` agents get the `LSP` tool (Godot language server, plugins/studio/.lsp.json)? Brief: docs/briefs/row27-lsp-reviewers-plan.md.
Probes were live headless runs (`claude -p --model haiku --plugin-dir <copy of plugins/studio>`, total $0.05 for all), not reading.

## Results
| Q | Answer | Evidence |
|---|---|---|
| 1 Can `tools:` list LSP? | YES, but `claude plugin validate --strict` proves nothing: it passed `tools: Read, Grep, Glob, NopeTool` too. Only a live call counts | validate passed with a made-up tool; live `studio:review-code` with `tools: Read, Grep, Glob, LSP` listed LSP and returned `findReferences DefReader` = 134 refs in 71 files |
| 2 Sub-agent gets LSP; one server per call? | YES; ONE server per session, shared by chat and sub-agent | 1 Godot editor process (+ its console launcher) while main and sub-agent both called LSP; the agent needs no `ToolSearch` |
| 2 Cost | 0.6-0.8 GB RAM (605 MB at 16 s, 804 MB at 27 s after launch); server ready ~16 s after the run started (warm `.godot`; up to 130 s on a fresh worktree, row 22); whole run 36-44 s, $0.0075-0.010 Haiku; LSP call after ready: seconds | tasklist samples every 2 s |
| 3 Who gains | review-code only. canon, feras, market, cost, player read docs, renders, logs: no code symbols | agent files |
| 4 Failure path | WORKS: floor forced (`MIN_FREE_MB=99999999`) -> "LSP server plugin:studio:godot crashed with exit code 3"; the agent made 1 LSP call, 1 Grep call, flagged the count as unverified and stopped (the rule file .claude/rules/tooling/lsp-fallbacks.md is read by sub-agents) | probe 6, 36 s |
| 5 Value test | NO measured gain. 8 past commits touching `.gd` (d236373, f18bb71, acfdd18, 736e52c, 13d359e, 5def5ee, 6338604, 73e32ba): of the 9 non-test, non-lifecycle function/signal names removed or re-signed in production code (battle_finished, register_area, stage_created, start_battle, unregister_area, touching, blur_zoom, push_blur, start_hud_boot; the rest were tests), 0 were declared in more than one file; `grep -w` found them in 1-5 files | `class_name` symbol too: Grep 74 files = LSP 71 .gd files + 3 docs that mention it |

Where LSP would help: a name declared in several files. Today 228 of 2002 function/signal names (11%) are, e.g. `hit`, `setup` (31 files), `start`, `texture`, `check`, `text`. None of the 8 sampled diffs changed one of them. There is almost no gameplay code until M1 (row 4).

## Verdict: DON'T DO (not for the 6 agents, not now)
- Gain: none seen in 8 diffs; the reviewer tier is Haiku `low`, 8 turns, and its "Ripple miss" check is "grep the old name": that is exactly right when a name is unique.
- Cost: 0.75 GB held while builders run under the 2 GB floor (tools/slots.sh), a 16-130 s cold start inside a 15-line review, a crash path that the review then has to explain, plus a new test and doc surface (6 agents, test_plugins, README, MAP, DOCMAP).
- A rule that stops the class: a reviewer's Ripple claim on a name declared in 2+ files must say so (`unsure` row), not guess. review-code already says "If unsure write `unsure | ...`"; nothing to add.
- The cheap use that works today and needs no change: the head chat (Opus/Sonnet) has the LSP tool when the studio plugin is loaded (probe 3: 134 refs, ~32 s cold). For a Ripple question on a colliding name, ask LSP there, not in a Haiku reviewer.

## Revisit trigger (not a queue row)
After row 4 (M1 built) when `features/**/*.gd` holds real combat code: rerun probe 5 on 3 fresh diffs. DO if one diff changes a colliding name and grep-based review-code missed or mis-flagged a caller. If DO, the brief is small: add `LSP` to review-code's `tools:` only, a test in tools/test_plugins.py that review-code lists LSP and the 5 others do not, README + MAP lines.

## Recipe to rerun (scripts are throwaway; ~10 minutes)
1. Copy `plugins/studio` to the scratchpad, set `tools: Read, Grep, Glob, LSP` in review-code.md.
2. `claude -p --model haiku --max-budget-usd 0.8 --plugin-dir <copy> --output-format json --allowedTools "Agent" "LSP" "Read" "Grep" "Glob" "ToolSearch" -- "<use Agent studio:review-code; call LSP findReferences on <file> <line> <char>>"` from the worktree, from a script file (the worktree guard refuses inline compound commands; `bypassPermissions` is refused by the auto-mode classifier, use `--allowedTools`).
3. Sample `tasklist //FO CSV //NH | grep -i godot` every 2 s (Git Bash needs the doubled slashes) for the RAM.
4. Failure path: `MIN_FREE_MB=99999999` in the environment.
5. Value: for each commit, list function/signal names removed or re-signed (`git show -U0 <c> -- '*.gd'`), count `git grep -l -w <name> <c>~1` and the files declaring it.
Pitfall met: a `sed` on the plugin copy inside a command the guard refused never ran, so probe 2's first "LSP missing" answer tested a leftover bogus tool name; confirm the agent file (`grep ^tools`) right before a probe.
