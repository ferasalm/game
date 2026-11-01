# Coach audit by Haiku 5.5 medium, read-only (2026-11-01, row 25; saved verbatim from the sub-agent's hand-back)
Task given: the kaizen:coach checklists (skills, hooks, rules, memory, permissions, plugins, claude-md, usage-stale-friction) applied to
the row25 worktree, at most 40 lines, cite file and line, no invented findings. Used as the reference when the cf DeepSeek V4.1 Flash max
read-only audit is tested against it (docs/audits/2026-11-01-coach-compare.md). Cost: 100k Claude tokens, 37 tool calls, 113 s.

COACH AUDIT (read-only, nothing written). Worktree: C:\dev\game\.claude\worktrees\row25

Setup Score: 8/10 (down from 9/10 on 2026-10-31). Why down: a GDScript LSP is enabled through the studio plugin with no lsp-fallbacks rule, and one memory file contradicts the 11-01 worker rule. The four hooks moved to the studio plugin are clean (no duplicates in settings.local.json or ~/.claude/settings.json).

| # | Area | Suggestion | Why (cite) | Effort |
|---|------|-----------|------------|--------|
| 1 | Rules / LSP | Create .claude/rules/tooling/lsp-fallbacks.md after testing hover, go-to-definition and find-references on a .gd file | studio enables a GDScript LSP (plugins/studio/.lsp.json:2-12; .claude/settings.json:86-87 studio@neon true); rules.md row 2 marks it high priority; the rules/tooling folder does not exist | S |
| 2 | Memory | Rewrite big-asks-plan-mode-agents.md lines 14-16 and 19 to the 11-01 rule (Haiku 5.5 at low, cf for cross-review, never a Sonnet subagent); update the index line 1 of MEMORY.md | Says "Haiku at effort high" and "DeepSeek at max"; DECISIONS.md 11-01 Process line says Haiku low | XS |
| 3 | Plugin rollout | Before relying on the moved hooks, confirm in the main checkout that studio@neon and pm@neon load (plugin list shows them enabled) | heredoc_guard, stop_notify, token_handoff, instructions-loaded run only through plugins/studio/hooks/hooks.json; a repo plugin loads only from the main checkout (LESSONS section 4); HANDOFF open point 11-01 still open | XS (Feras) |
| 4 | Tests | Add a check in tools/check.sh that every command in plugins/studio/hooks/hooks.json and .claude/settings.json resolves to an existing file | Cutover makes a silent drop possible; the plugin hook paths were moved by hand | S |
| 5 | Memory | Memory duplicates rules: model-routing-feras.md ("Sonnet only at high") overlaps the 11-01 DECISIONS lines; trim it to Feras's taste only | memory.md row 10 (no duplication) | S |
| 6 | Coach log | Append a 2026-11-01 entry to .claude/coach-history.md (score 8/10, items 1-5) after the row 25 merge | last entry is 2026-10-31 (coach-history.md:2) | XS |
| 7 | Permissions | Run /fewer-permission-prompts once the usage log has a week of data | shared settings.json has deny rules only (.claude/settings.json:2-22); no usage log was read, so this is not verified | S |
| 8 | Hooks | Optional: a CLAUDE.local.md for the "He is on Claude Pro" plan line (CLAUDE.md, Start/Limits section) | checklist claude-md.md row 10 (personal content in shared CLAUDE.md); low value | XS |

Already great (3 lines):
- Enforcement is in the right place: safety hooks in settings.json (SessionStart, pre_spend, review_gate) and never-read deny rules (.claude/settings.json:3-22).
- Plugins are split by purpose: studio (hooks, six reviewers, LSP) and pm (queue board), each with plugin.json (plugins/studio/.claude-plugin/plugin.json, plugins/pm/.claude-plugin/plugin.json).
- Memory index is lean (7 entries, all files exist); CLAUDE.md is 76 lines, under the 100-line cap; code.md is path-scoped (.claude/rules/code.md:1-2).

Plugin gaps still open: a GDScript LSP fallback rule (item 1). Context7 and RTK are not planned or declined (coach-history.md:24), so they are not re-suggested.

Stale or broken references checked (all exist unless noted):
- CLAUDE.md @imports: HANDOFF.md, docs/DECISIONS.md, docs/LESSONS.md. Present.
- CLAUDE.md:23 names pre_spend.py, review_gate.py, doc_check.py: present under tools/hooks/ and tools/. test_template.py was NOT checked.
- settings.json hook paths: .claude/hooks/session-start.sh, .claude/hooks/instructions-loaded.sh, tools/hooks/run.sh, tools/statusline.py. Present.
- Main checkout only: .claude/settings.local.json has a PostToolUse track_usage.py hook (line 16-21); .claude/hooks/track_usage.py exists there. No copy in the worktree, which is expected because the file is gitignored.
- players-eye-gate/SKILL.md:25 names tools/hooks/review_gate.py. Present.
- No broken references found. HANDOFF.md no longer cites docs/briefs/row25-opus-gate.md.

Not verified: the usage log (~/.claude/coach-usage-log.jsonl) was not read, so usage-pattern and friction checks are not scored.

## Status of its items after row 25 (added by Sonnet, 11-01)
1 done (rule written, LSP files verified to exist) | 2 done | 3 Feras (open point) | 4 done as a test (tools/test_plugins.py), not in check.sh | 5 open | 6 done | 7 open (needs a week of data) | 8 not planned.
