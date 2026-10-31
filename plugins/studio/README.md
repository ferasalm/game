# studio: how Neon Glitch is built (Claude Code plugin)
Loaded from the repo marketplace `neon` (`.claude-plugin/marketplace.json`, plugin source `./plugins/studio`).
## What it holds
- `agents/`: the 7 reviewer agents (`studio:review-code`, `studio:review-player`, `studio:review-feras`, `studio:review-canon`,
  `studio:review-cost`, `studio:review-market`, `studio:ui-finish-gate-reviewer`).
- `hooks/hooks.json`: heredoc_guard, token_handoff, stop_notify, instructions-loaded and a SessionStart marker; the scripts
  stay in `tools/hooks/` and `.claude/hooks/` and run from `$CLAUDE_PROJECT_DIR`.
- `.lsp.json` + `scripts/godot_lsp.py`: Godot's language server (diagnostics, find-references) over a stdio bridge, one port
  per worktree, off below the memory floor (MIN_FREE_MB).
- Skills stay in `.claude/skills/`: `skillOverrides` and `paths:` do not work on plugin skills (docs/briefs/row22-probe.md).

## Use it
- Test edits in a worktree: `claude --plugin-dir <worktree>/plugins/studio`.
- Everywhere else: once, `/plugin marketplace add C:/dev/game`, accept the trust dialog, then enable `studio@neon`. A marketplace
  serves the main checkout, so changes reach it after the merge to main and `bash tools/sync_main.sh`.
- Another project: add the same marketplace, enable `studio@neon`, and give it `tools/hooks/` and `tools/kill_tree.py`.

## What a plugin cannot carry (stay in `.claude/settings.json`)
`skillOverrides`, deny rules, and the wiring of pre_spend (money), review_gate (render review) and session-start (it warns in one
line when this plugin is not loaded): a plugin that fails to load drops its hooks silently.
