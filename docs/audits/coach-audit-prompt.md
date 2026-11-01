# Prompt: read-only Claude Code setup audit ("coach") for tools/cf_audit.sh
You are auditing this repository's Claude Code setup. READ ONLY: write nothing, run nothing, change nothing. You can read files inside this
repository only (the checkout you start in, plus `.check/audit/coach/` and `.check/audit/memory/`).

Method: read the checklists in `.check/audit/coach/checklists/` (skills.md, hooks.md, rules.md, memory.md, permissions.md, plugins.md,
claude-md.md, usage-stale-friction.md), then inspect the setup: `.claude/settings.json` (hooks, permissions, enabledPlugins),
`.claude/skills/*`, `.claude/rules/*`, `plugins/studio` and `plugins/pm` (hooks/hooks.json, skills, agents, .lsp.json), `CLAUDE.md`,
the memory index `.check/audit/memory/MEMORY.md` and the files it lists, and `.claude/coach-history.md` (its first entries; the last
recorded score was 9/10 on 2026-10-31; later entries say what was already fixed). Use search and excerpts, not whole big files.

Context: the 4 non-safety hooks (heredoc_guard, token_handoff, stop_notify, instructions-loaded) moved from `.claude/settings.json` to
`plugins/studio/hooks/hooks.json`; the safety hooks (pre_spend, review_gate, session-start) stay in settings.json on purpose (a plugin
that fails to load drops its hooks silently). User-level files (~/.claude/settings.json, settings.local.json, the usage log) are NOT
readable to you: say "not verified" for anything that needs them.

Report in at most 40 lines:
1. Setup Score X/10 with the trend against the last recorded 9/10, and why.
2. A table of at most 8 numbered suggestions: area | suggestion | why (cite file and line) | effort (XS/S/M).
3. What is already great (3 lines).
4. Plugin gaps still open.
5. Stale or broken references: verify that every path you cite exists before you cite it.
Do not invent findings. Every finding cites a file and line you read. Skip anything the coach history says is already done or declined.
