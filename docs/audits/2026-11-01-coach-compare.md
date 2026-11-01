# Coach audit: cf DeepSeek V4.1 Flash max vs Haiku 5.5 medium (2026-11-01, row 25; for Feras and Claude)
Same task, same commit (b5ab62f), same memory files, same rules: audit the Claude Code setup with the kaizen coach checklists, at most 40 lines,
cite file and line. Reports: docs/audits/2026-11-01-coach-haiku.md and docs/audits/2026-11-01-coach-dsv4.md. Sonnet checked every claim of both
against the repository (a claim counts as TRUE only after that check). Pass bar (D11): few false claims, and it finds real things the other misses.

## Result in one table
| | Haiku 5.5 medium | cf DeepSeek V4.1 Flash max |
|---|---|---|
| Score given | 8/10 (down from 9) | 9/10 (flat; "5 small defects") |
| Suggestions | 8 | 7 (+4 in the unenforced first run) |
| False or invented claims | 0 of 8 | 0 of 7 (and none in the first run's extras) |
| True and shared | LSP fallback rule; permissions allow list | LSP fallback rule; permissions allow list |
| True, found only by this one | big-asks memory contradicts the 11-01 worker rule; test that every hook script exists; coach log entry; memory overlap (model-routing, low value) | `"handoff": "name-only"` is a dead setting; OpenRouter memory line is stale (key was renewed); LSP not in reviewer tools; no Notification hook; first run also: blender in `.mcp.json`, deny list covers Edit only |
| Known already | plugin trust check (Feras) | statusline dump (an open point) |
| Cost | ~100k Claude tokens, 37 tool calls, 113 s | 0 Claude tokens, about 1 cent of Cloudflare, 6 min |
| Process note | read-only by instruction | read-only by config, but the first run was NOT enforced: the repo's own `opencode.json` allows bash and edit and outranks the audit config, so the model ran 3 listing commands (it said so). Fixed in `tools/cf_audit.sh` with inline config, probed (bash and write tools absent), tested |

## What each one is good at
- Haiku read the user-level side (memory files against the 11-01 rules, coach history) and proposed tests; its misses were things only visible in
  the plugin and settings files.
- DeepSeek read the plugin and settings layer closer (a dead override, the LSP not reaching the reviewers, missing hook types) and caught a stale memory
  claim by cross-reading memory against the decisions log. It scored the setup higher because it gave credit for closed gaps.
- Overlap is small: each found about 2 of the other's 5 true items. So the union (12 distinct true items) is far better than either alone.

## Verdict
- Calibrated (D11) as an AUDIT LENS: zero false claims in 15 checked, cited file and line, complete reports, free. Not calibrated as the sole
  auditor: it missed 3 of Haiku's 6 true items, Haiku missed 4 of its 6.
- Recommended routing: run `bash tools/cf_audit.sh` first (free, ~6 min), then one Haiku low or medium pass only for the user-level files it cannot
  read (`~/.claude`, usage log, settings.local.json); the coach score is taken from the union, not from one report.
- Score gap (8 vs 9): the difference is rating style, not facts; use the number of TRUE open items, not the model's score, as the trend.

## Third lens: cf GLM-5.3-Flash (added 11-02, same commit, same prompt; report: docs/audits/2026-11-01-coach-glmflash.md)
Flash has no effort levels (Feras 10-31): this is its default setting, run by `AUDIT_MODEL=cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash bash tools/cf_audit.sh ...`.
| Claim | Checked by Sonnet |
|---|---|
| 1 LSP fallback rule; 2 Notification hook; 6 permissions allow list; 7 CLAUDE.local.md | TRUE, all shared with Haiku or DeepSeek |
| 5 OpenRouter memory line stale | TRUE, shared with DeepSeek |
| 4 feras/BRIEFING.md cites `docs/briefs/row22-probe.md` (moved to docs/archive/briefs/) | TRUE and unique to this lens (line number wrong: it is line 75); fixed 11-02, and the doc graph's allowlist entry for it removed |
| 3 plugins/studio/README.md points to a missing probe file, "`docs/archive/` is absent" | FALSE: the file exists. The model asked for a wrong path, got "File not found", and reported the absence as fact. The one invented claim in 22 checked across the three lenses |
Score given 9.5/10 (rating style again). Result: 6 true of 7, 1 unique true item, 1 false claim. Use it as a third lens only with the claim check; it never
replaces the check. The union is now 13 distinct true items: Haiku 5 unique-or-shared, DeepSeek 6, GLM 1 unique.

## Done from these reports (Sonnet, 11-01)
LSP fallback rule written; hook-script-exists test added; memory big-asks fixed; OpenRouter memory line fixed; dead `handoff` override removed from
settings.json. Open: Notification hook (optional), LSP in reviewer tools (needs a probe that `tools: LSP` is allowed), permissions allow list,
blender in `.mcp.json` (Feras's call), model-routing memory trim.
