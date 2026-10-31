# Row 22: studio plugin (chat brief; rules, target and paths' reasons: docs/briefs/system-v3.md)
Department: Ops. Model: Sonnet high, auto mode. Skills: builders. Persona: none.
Goal: all Claude-side skills, reviewer agents and non-safety hooks live in one plugin, with Godot language tools, and nothing breaks.
Read: docs/briefs/system-v3.md, this file, the builders skill. Grep for the rest. Plugin docs: code.claude.com/docs/en/plugins-reference and plugins/loading (WebFetch writes big pages to a file: grep it).
May edit: `plugins/`, `.claude-plugin/`, `.claude/skills/`, `.claude/agents/`, `.claude/settings.json`, `.gitattributes`, `tools/`, path words in docs and skills.
Do NOT edit: `features/`, `core/`, `content/`, `assets/`, `.agents/skills/`, `.claude/rules/code.md`, `opencode.json`, `.opencode/`. WORKFLOW beyond path words (row 24 rewrites it). `.claude/skills/handoff` (row 23 moves it).

## Steps
1. Start: worktree, branch from origin/main, push to `system-v3`. Confirm the `advisor` tool is listed; if not, say so in the report (the rule then stays "ask Feras").
2. First worker, agy `RUN_KIND=py`, driven by one fork: `tools/prompt_check.py <file> --kind brief|oneshot|chat`, exit 1 naming each miss. brief = the TEMPLATE headings; oneshot = Goal, Inputs, Do NOT, Output contract, Done, Stop rules; chat = the WORKFLOW department brief lines; a Sonnet prompt must start with `/goal`, be under 4,000 characters and hold a turn cap. You write `tools/test_prompt_check.py` first, red. cf max cross-reviews. This run is also the smoke test of the agy lane, the cf max lane and the fork: a failure here is fixed before anything else.
3. Probe in a throwaway folder outside the repo, with a plugin of one skill, one agent, one hook and the LSP server. One line each in `docs/briefs/row22-probe.md`:
   a. A repo marketplace (`.claude-plugin/marketplace.json`) loads in a worktree chat. Does it load from the main checkout or the worktree? `--plugin-dir` for testing edits.
   b. Do short names work (`/builders`), or only `/studio:builders`?
   c. Does `skillOverrides` name-only work on a plugin skill? Without it, descriptions cost tokens on every turn.
   d. Do `paths:` skills still trigger? 
   e. Do plugin hooks see `$CLAUDE_PROJECT_DIR` and the hook's stdin `cwd`? 
   f. What is the plugin agent's `subagent_type`, and does review_gate still match what it needs?
   g. Start cost with and without the plugin: first-request tokens from a one-line `claude -p` run on Haiku.
   h. LSP: `godot --headless --editor --lsp-port <free port> --path <worktree>` behind a stdio bridge: Godot errors appear after a bad edit, find-references works, memory used, and `git status` stays clean after the session. Stay off under the memory floor (tools/builders.conf MIN_FREE_MB). One server per worktree, a free port each.
   Must-haves: a, c, e, h's clean `git status`. A failed must-have takes the fallback below.
4. Move, agy `RUN_KIND=py` with this exact map, then cf max cross-review:
   - `.claude/skills/{builders,ops-review,emergency-efficiency,players-eye-gate,sprite-bake,flow-media,3d-model,market-player}` -> `plugins/studio/skills/`.
   - The 10 persona copies in `.claude/skills/` -> `plugins/studio/skills/`; `tools/sync_personas.py` writes there; `.agents/skills` stays the source.
   - `.claude/agents/*.md` -> `plugins/studio/agents/`; doc_check and sync_personas retargeted.
   - `tools/build_pipeline.sh` skill_file() reads the new skills path (no build may be running: LESSONS, never edit a tool a live run executes).
   - heredoc_guard, token_handoff, stop_notify, instructions-loaded wired from `plugins/studio/hooks/hooks.json`; their scripts stay in place. pre_spend, review_gate and session-start stay wired in `.claude/settings.json`.
   - `tools/build_gate.py` and the D6 text protect `plugins/`. `plugins/.gdignore`. map.py covers plugin scripts.
   - Every live reference, ~56 in 32 files, grepped with `\.claude/skills|\.claude/agents` outside docs/archive, docs/audits, docs/briefs, decisions-log and USAGE.
5. cf max: `plugins/studio/scripts/godot_lsp.py` and `.lsp.json`, with a fake TCP server test in `tools/test_godot_lsp.py` (you write it first).
6. session-start warns in one line if `studio` isn't loaded. New `tools/test_plugins.py`: manifests parse; `claude plugin validate` when `claude` is on PATH (CI skips it); every referenced path exists; no skill or agent lives in both places.
7. `plugins/studio/README.md`, 20 lines: what it holds, how to add it to another project, the settings lines it can't carry.

## Fallback
Must-have a or c fails: skills stay in `.claude/`; agents, hooks and LSP move. h fails: no LSP; a `.gd` syntax-check hook takes its place in the plugin. Say which in the report.

## Stop rules
Auto mode refuses a change: stop, ask Feras with the exact diff; he may need to run `/plugin marketplace add` or `/plugin install` himself. Same step failed twice: call the advisor. 3 rounds on one problem: report. Budget: 80 main-chat calls; a chunk of 10+ noisy calls goes to a fork.

## Done when
`bash tools/check.sh` all passed and read; `claude plugin validate plugins/studio --strict` passes; a fresh worktree chat lists the skills once and a reviewer agent runs; row 23's prompt ready; pushed to `system-v3`.

## Report
15 lines or fewer: the probe answers, runs with their one-line results, fallback taken or not, questions for Feras. Then /handoff on `system-v3`: no merge to main, no sync; HANDOFF row 22 done, row 23 next; the next prompt ready to paste.
