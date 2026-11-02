[0m
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead .check/audit/prompt.md 
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead .check/audit/coach/checklists/skills.md 
[0m→ [0mRead .check/audit/coach/checklists/memory.md 
[0m→ [0mRead .check/audit/coach/checklists/hooks.md 
[0m→ [0mRead .check/audit/coach/checklists/permissions.md 
[0m→ [0mRead .check/audit/coach/checklists/rules.md 
[0m→ [0mRead .check/audit/coach/checklists/plugins.md 
[0m→ [0mRead .check/audit/coach/checklists/claude-md.md 
[0m→ [0mRead .check/audit/coach/checklists/usage-stale-friction.md 
> build · @cf/zai-org/glm-5.3-flash
Now let me inspect the setup files and directories.
[0m→ [0mRead CLAUDE.md 
[0m→ [0mRead .claude/settings.json 
[0m→ [0mRead .claude/coach-history.md [90m[limit=80][0m
[0m→ [0mRead .claude/skills 
[0m→ [0mRead .claude/rules 
[0m→ [0mRead .check/audit/memory/MEMORY.md 
> build · @cf/zai-org/glm-5.3-flash
Now the plugins and rules directories.
[0m→ [0mRead plugins/studio 
[0m→ [0mRead plugins/pm 
[0m→ [0mRead .claude/rules/tooling 
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead plugins/studio/.lsp.json 
[0m→ [0mRead plugins/studio/hooks/hooks.json 
[0m→ [0mRead plugins/studio/agents 
[0m→ [0mRead plugins/pm/skills 
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead plugins/studio/scripts 
[0m→ [0mRead .claude/rules/code.md 
[0m→ [0mRead plugins/pm/scripts 
[0m→ [0mRead .claude/rules/tooling/lsp-fallbacks.md 
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead .claude/hooks 
[0m→ [0mRead tools/hooks 
[0m→ [0mRead plugins/studio/.claude-plugin 
[0m→ [0mRead .check/audit/memory 
[0m→ [0mRead plugins/pm/.claude-plugin 
> build · @cf/zai-org/glm-5.3-flash
All hook paths check out. Now the memory files themselves.
[0m→ [0mRead .check/audit/memory/model-routing-feras.md 
[0m→ [0mRead .check/audit/memory/big-asks-plan-mode-agents.md 
[0m→ [0mRead .check/audit/memory/openrouter-free-only.md 
[0m→ [0mRead .check/audit/memory/feras-wants-one-queue-and-schedule.md 
[0m→ [0mRead .check/audit/memory/run-only-what-was-asked.md 
[0m→ [0mRead .check/audit/memory/ask-before-waiting-on-feras.md 
[0m→ [0mRead .check/audit/memory/feras-timezone.md 
> build · @cf/zai-org/glm-5.3-flash
Now verifying the paths cited by rules, memory, and coach history exist.
[0m→ [0mRead docs 
[0m→ [0mRead tools 
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead docs/design 
[0m✱ [0mGlob "docs/research/calibration-2026-10.md" [90m1 match[0m
[0m✱ [0mGlob "HANDOFF.md" [90m1 match[0m
[0m✱ [0mGrep "test_every_path_the_settings_hooks_name_exists" [90min tools/test_plugins.py · 1 match[0m
> build · @cf/zai-org/glm-5.3-flash
All paths verified. Now checking cross-references: run.sh routing, plugin agent scopes, pm skills, and the DECISIONS overlap flagged by the last coach run.
[0m✱ [0mGrep "heredoc_guard|token_handoff|stop_notify|pre_spend|review_gate" [90min tools/hooks/run.sh · 1 match[0m
[0m✱ [0mGrep "(HANDOFF|docs/|tools/|\.claude/)[A-Za-z_./-]*" [90min plugins/pm · 21 matches[0m
[0m✱ [0mGrep "docs/[A-Za-z_./-]+|\.claude/[A-Za-z_./-]+|tools/[A-Za-z_./-]+" [90min plugins/studio/agents · 18 matches[0m
[0m✱ [0mGrep "Sonnet|Haiku|worker policy" [90min docs/DECISIONS.md · 3 matches[0m
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead tools/hooks/run.sh 
[0m✱ [0mGlob "docs/story/bible.md" [90m1 match[0m
[0m✱ [0mGlob "docs/archive/audits/2026-10-26-overnight-retro.md" [90m0 matches[0m
> build · @cf/zai-org/glm-5.3-flash
[0m✱ [0mGlob "docs/**/*overnight-retro*" [90m0 matches[0m
[0m✱ [0mGrep "docs/archive|until it exists" [90min plugins/studio · 2 matches[0m
> build · @cf/zai-org/glm-5.3-flash
[0m✱ [0mGlob "docs/archive/**" [90m0 matches[0m
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead docs/audits 
[0m→ [0mRead docs/archive 
> build · @cf/zai-org/glm-5.3-flash
[0m→ [0mRead docs/archive/audits 
[0m→ [0mRead docs/archive/briefs 
> build · @cf/zai-org/glm-5.3-flash
The archive files do exist (my earlier glob was wrong). Now checking the six project skills that aren't in `skillOverrides`, since the 10-31 run counted only 8 project skills — these look newer.
[0m→ [0mRead .claude/skills/sprite-bake/SKILL.md [90m[limit=12][0m
[0m→ [0mRead .claude/skills/3d-model/SKILL.md [90m[limit=12][0m
[0m→ [0mRead .claude/skills/flow-media/SKILL.md [90m[limit=12][0m
[0m→ [0mRead .claude/skills/players-eye-gate/SKILL.md [90m[limit=12][0m
[0m→ [0mRead .claude/skills/low-cost-pipeline/SKILL.md [90m[limit=12][0m
[0m→ [0mRead .claude/skills/builders/SKILL.md [90m[limit=12][0m
> build · @cf/zai-org/glm-5.3-flash
One more cross-check: the pm handoff skill had a hard-coded Windows path. Let me confirm and scan the plugins for other machine-specific paths.
[0m→ [0mRead plugins/pm/skills/handoff/SKILL.md [90m[limit=10, offset=38][0m
[0m✱ [0mGrep "Program Files|[A-Z]:\\" [90min plugins · 2 matches[0m
> build · @cf/zai-org/glm-5.3-flash
All checks are done — everything below cites files I actually opened. Final report:

# Claude Code Setup Audit — 2026-11-02 (read-only)

**1. Setup Score: 9/10.** Trend vs the last recorded 9/10 (2026-10-31, `.claude/coach-history.md:3`): **level**. Row 25's read-only dip to 8/10 (11-01, `coach-history.md:2`) is healed — both named causes verified fixed: `.claude/rules/tooling/lsp-fallbacks.md` exists (lines 1-11, cites live paths) and the big-asks memory now carries the 11-01 calibration (modified 2026-11-01). The four moved hooks are clean. One point short of 10: one memory still contradicts an in-force decision (item 1).

**2. Suggestions**

| # | Area | Suggestion | Why (file:line) | Effort |
|---|------|-----------|------------------|--------|
| 1 | memory | Trim `model-routing-feras` to taste only, as the last run left queued — drop the stale level ladder | `.check/audit/memory/model-routing-feras.md:21-22` says Haiku "medium over Sonnet low, high over Sonnet medium", but the in-force 11-01 rule is Haiku low, medium only for >20k reads, never a Sonnet subagent (`docs/DECISIONS.md:18`) | XS |
| 2 | hooks | Add a `Notification`-event hook (input-needed alert) beside `stop_notify` | Stop is wired (`plugins/studio/hooks/hooks.json:32-37`) but nothing fires when a chat waits on input (checklist `hooks.md:27`); a silent wait parks a queue row | XS |
| 3 | agents | Delete the "until it exists" fallback clause in review-player | `plugins/studio/agents/review-player.md:14` defers to `docs/archive/audits/2026-10-26-overnight-retro.md`, but `docs/design/acceptance.md` now exists and is the live bar | XS |
| 4 | plugin | Replace the hard-coded machine paths in pm:handoff with `${CLAUDE_PROJECT_DIR}` / a bash-on-PATH lookup | `plugins/pm/skills/handoff/SKILL.md:42-43` pins `C:\dev\game` and `C:\Program Files\Git\bin\bash.exe` in committed text — works only on Feras's machine (the workaround is at least documented in-line) | XS |
| 5 | skills | Give the expiring Rodin credits a HANDOFF queue row (use or write off ~50 before the date) | `.claude/skills/3d-model/SKILL.md:8`: "credits… expire about 2026-11-17" — a dated fact inside a skill has no trigger to surface it | XS |

**3. Already great**
- Hook hygiene is test-enforced: every wired hook names a script that exists, safety gates fail closed (`tools/hooks/run.sh:5,17`), and `tools/test_plugins.py:60` (`test_every_path_the_settings_hooks_name_exists`) pins all paths.
- Docs discipline holds: CLAUDE.md is 76 lines (<100), every path and command it names verified to exist; both rules carry `paths:` frontmatter (`.claude/rules/code.md:2`, `lsp-fallbacks.md:2-4`).
- Memory is fresh and typed: all 7 entries ≤ 6 days old, wiki-links resolve, and `MEMORY.md` matches the directory exactly (7/7).

**4. Plugin gaps still open**
- Confirmation that `studio@neon` and `pm@neon` load in C:\dev\game — user-level, left to Feras (`coach-history.md:2`). Both manifests exist here (`plugins/*/.claude-plugin/plugin.json`; `settings.json:84-87` enables them), but loading is **not verified**.
- Usage log, `settings.local.json` and user-level skills are **not verified** (unreadable to this audit): permission allow-list and skill-invocation counts unknown; `/fewer-permission-prompts` stays deferred (`coach-history.md:2`).
- RTK and Context7: declined by Feras (`coach-history.md:25`) — closed, not gaps.

**5. Stale or broken references** (every path cited above was opened or globbed)
- `model-routing-feras.md:21-22` — stale *content* (contradicts `DECISIONS.md:18`); its paths are fine.
- `review-player.md:14` — obsolete *clause*; the archive path it names still exists (verified in `docs/archive/audits/`).
- `handoff/SKILL.md:42-43` — machine-specific hard-code, documented as a workaround.
- No dead paths: all 8 wired hook scripts, both plugin manifests, `CLAUDE.md` imports (`HANDOFF.md`, `docs/DECISIONS.md`, `docs/LESSONS.md`), both rules' targets, and every file path in all 7 memory files exist as written.
