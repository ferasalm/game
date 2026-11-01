# Coach audit by cf GLM-5.3-Flash, read-only (2026-11-02, row 25; saved from the opencode output)
Run: `AUDIT_MODEL=cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash bash tools/cf_audit.sh docs/audits/coach-audit-prompt.md <out>` with `AUDIT_ROOT` = a worktree at
b5ab62f (the commit Haiku and DeepSeek audited) and the memory files as they were then. The flash model has no effort levels (Feras 10-31), so this
is its default setting, not "max". Read-only by inline config (bash and write tools absent). Sonnet's check of its claims is in
docs/audits/2026-11-01-coach-compare.md (section "Third lens"). Its own stray tool error: it asked for `docs/briefs/row22-probe.md`, got "File not found"
and then claimed `docs/archive/` is absent: that claim is false (suggestion 3).

# Claude Code setup audit — 2026-11-02 (read-only)

## 1. Score: 9.5/10 (trend ↑ from 9/10 on 2026-10-31)
The one named gap last run — "a project-aware plugin" — is closed: `studio@neon` + `pm@neon` ship the Godot LSP bridge, 7 reviewer agents, the hook wiring and pm skills, all present in-repo. Hook migration matches the stated design exactly: settings.json keeps session-start (line 50), pre_spend (66), review_gate (75); plugins/studio/hooks/hooks.json carries heredoc_guard (14), instructions-loaded (21), token_handoff (28), stop_notify (35). Every referenced script exists. Remaining deductions are hygiene only: no `lsp-fallbacks.md` rule, no Notification hook, two dead doc paths, one stale memory pointer.

## 2. Suggestions
| # | Area | Suggestion | Why (file:line) | Effort |
|---|------|-----------|------------------|--------|
| 1 | Rules | Create `.claude/rules/tooling/lsp-fallbacks.md`: what the Godot LSP answers here (go-to-def/find-refs work, ~0.75 GB/worktree) and the grep/read fallback. Evidence already gathered — just write it down. | rules.md:6 flags it high-priority when an LSP is active; `.claude/rules/` holds only code.md; probe facts sit unclaimed in plugins/studio/scripts/godot_lsp.py:6 and feras/BRIEFING.md:58 | S |
| 2 | Hooks | Add a `Notification`-event hook (alert when input is needed), alongside the existing Stop hook. | hooks.md:27 lists the purpose; plugins/studio/hooks/hooks.json has SessionStart/PreToolUse/InstructionsLoaded/PostToolUse/Stop but no Notification | XS |
| 3 | Stale refs | Fix plugins/studio/README.md:10 — `docs/archive/briefs/row22-probe.md` doesn't exist (`docs/archive/` is absent); point to the real probe location. | usage-stale-friction.md:21–25 (stale-config class) | XS |
| 4 | Stale refs | Fix feras/BRIEFING.md:58 — `docs/briefs/row22-probe.md` also missing; no `row22*` file exists anywhere in the repo. | memory.md:11 broken-reference check, applied to docs | XS |
| 5 | Memory | `.check/audit/memory/openrouter-free-only.md:14` cites "the key expired 10-31 (HANDOFF Open point)", but HANDOFF.md's Open points (lines 26–30) no longer carry that row — update or drop the pointer. | memory.md:11 | XS |
| 6 | Permissions | settings.json holds only deny rules; the allow list and usage log live at user level → **not verified**. In the next ops-review, confirm frequent commands (`bash tools/check.sh`, `tools/run_godot.sh`) are allowed, not re-approved. | permissions.md:4–7, 11–12; coach-history.md:12 shows this class of friction before | XS |
| 7 | CLAUDE.md | Owner-personal content (line 5 "He is on Claude Pro: spend little"; the lean/routing block lines 47–67) could move to CLAUDE.local.md per checklist. Deliberate here (single-owner repo), so only if Feras wants a share-clean file. | claude-md.md:10 | S |

## 3. Already great
- Enforcement with fallbacks: deny rules (settings.json:3–22), `paths:` frontmatter on code.md:2, heredoc_guard hardened 10-31, session-start.sh re-execs to the session's cwd and warns when the plugin didn't load (session-start.sh:16,43).
- Cost discipline end-to-end: 23 unused skills overridden name-only/off (settings.json:24–48), CLAUDE.md cut to 76 lines (<100 ✓), statusline.py writes `.check/usage.json`, all hooks have self-tests (`tools/test_hook_*.py`, `test_token_handoff.py`).
- Memory: 7 files, all typed (6 feedback, 1 user), all modified within 5 days, cross-linked to CLAUDE.md duties instead of duplicating rules.

## 4. Plugin gaps still open
- LSP rule (suggestion 1) is the only checklist-flagged plugin-adjacent gap; the bridge itself (`godot_lsp.py`, `.lsp.json`) is done.
- Real CI for `handoff.sh --main` and statusline stdin field-name confirmation are already tracked (HANDOFF.md:28–29) — no new action here.
- Marketplace serves the main checkout only; worktrees need `--plugin-dir` (plugins/studio/README.md:13) — known, accepted design.

## 5. Stale or broken references (all cited paths verified by me)
Broken: plugins/studio/README.md:10 and feras/BRIEFING.md:58 (the row22 probe, two different wrong paths); `.check/audit/memory/openrouter-free-only.md:14` (stale HANDOFF pointer).
Verified existing: docs/research/calibration-2026-10.md, docs/design/ui.md, .agents/skills/AGENCY-LICENSE, .claude-plugin/marketplace.json (names match `enabledPlugins`), tools/hooks/ all 7 scripts, .claude/hooks/{session-start,instructions-loaded}.sh, tools/{statusline.py,status.sh,cf_probe.py,check.sh,sync_main.sh,merge_base.sh,map.py}, docs/{VISION,DECISIONS,LESSONS,MAP,ARCHITECTURE,CANON,WORKFLOW,SPEND,decisions-log}.md, docs/design/systems-map.md, tests/, HANDOFF.md, feras/BRIEFING.md.
Not verified (user-level, unreadable): ~/.claude/settings.json, settings.local.json (allow list, track_usage wiring, archived agents), the usage log.
