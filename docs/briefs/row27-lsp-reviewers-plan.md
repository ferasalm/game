# Row 27: plan the language server (LSP) for the reviewer agents (chat brief, Opus high; output = a brief for Sonnet high)
Department: Ops. Model: Opus high. Skills: builders. Persona: none. Feras 11-02: Opus plans it in a dedicated chat, Sonnet high executes it later.
Goal: decide with evidence whether the 6 reviewer agents should get the `LSP` tool, and if yes write the execution brief (TEMPLATE, red tests first).
Read: this file, plugins/studio/agents/review-code.md (and the 5 siblings), plugins/studio/.lsp.json, plugins/studio/scripts/godot_lsp.py,
docs/archive/briefs/row22-probe.md (probe c/d: LSP latency, memory), .claude/rules/tooling/lsp-fallbacks.md, tools/test_plugins.py,
tools/test_godot_lsp.py, docs/audits/2026-11-01-coach-compare.md (where the idea came from). Grep for the rest.

## What we know (checked 11-02)
- All 6 agents declare `tools: Read, Grep, Glob`. The studio plugin starts a Godot language server for `.gd` files (hover, definition, references, diagnostics;
  no codeAction or formatting). find-references took 1.3-2.5 s; the server costs about 0.75 GB per worktree and can take up to 130 s to start; below the
  memory floor (2000 MB available RAM, tools/free_mb.py) it refuses to start.
- review-code asks for "Ripple misses" (what else a change touches): exact references would answer that; grep answers it by name.
- There is almost no gameplay code until M1 (row 4), so the payoff is small before then.

## Questions to settle by probe, not by reading (Opus runs them; cf and Haiku low for reading only)
1. Can a plugin agent's `tools:` list include `LSP` (frontmatter accepted by `claude plugin validate --strict`; the agent really gets the tool in a live call)? If not, stop: record why in the report.
2. Is the LSP tool available inside sub-agents at all, and does it start one server per agent call or reuse the session's? Measure start time and memory for one `studio:review-code` call on a `.gd` diff.
3. Which reviewers gain: review-code surely; review-canon, review-feras, review-market, review-cost, review-player read docs and renders (no).
4. Failure path: server down, floor refused, timeout. The agent must fall back to Grep without looping (the rule file exists).
5. Value test: take 3 real past diffs (git log, features/**/*.gd) and compare review-code with and without LSP: does it find a Ripple miss grep missed? One line per diff.

## Deliverables
- docs/audits/<date>-lsp-reviewers.md: the probe results, a DO or DON'T DO verdict, and the cost (RAM, seconds) in numbers.
- If DO: docs/briefs/<row>-lsp-reviewers.md for Sonnet high (low-cost-pipeline skill: GLM max red tests, DeepSeek hand), with Ripple (plugins/studio/agents/*.md, tools/test_plugins.py, plugins/studio/README.md, docs/MAP.md, docs/DOCMAP.md), a pre-mortem, and tests that fail if an agent that needs LSP lacks it or one that does not has it.
- If DON'T: one line in docs/decisions-log.md and close the coach suggestion.
- A queue row for the execution (HANDOFF) and the /handoff report.

## Stop rules
Same question unanswered after 2 probes: ask Feras with AskUserQuestion, options with a pick. Never /advisor unasked. Never a Sonnet subagent.
