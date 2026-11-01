# System v3: the plan behind rows 22-25 (Opus xhigh, 2026-10-31; archive after row 25)
Feras's priorities, the higher wins: 1 output quality, 2 codebase integrity and flexibility, 3 Claude tokens and usage limits,
4 organization and simplicity, 5 speed. Decisions: docs/decisions-log.md, 2026-10-31. Delegation: the `builders` skill, Who does what.

## Measured before (last 4 days of transcripts, USAGE, coach history)
| Finding | Measured |
|---|---|
| Opus does nearly everything | 1 Sonnet chat of ~27; weekly limit reached 98% last week |
| Long chats are the cost | typical chat 120-260 calls, 17-40M cache reads; Bash the biggest call type |
| /handoff is mechanical | 8-13 calls, 1.4-3.1M cache reads, 18-37% of a small chat (4 clean chats) |
| Worker routing in 5 places | WORKFLOW (3), models.md, decisions-tools; they disagreed on Sonnet |
| Guard refusals | 29-44 a day; each a wasted call at full context |
| Rules assume the desktop app | get_usage, get_session, SendUserFile named in 20 files; the CLI has none |
| Skills list twice in worktree chats | every project skill, unscoped and scoped |

## Target
```
.claude-plugin/marketplace.json   marketplace "neon", plugins loaded from this repo
plugins/.gdignore                 keeps Godot out
plugins/studio/   how we build: skills, the 7 reviewer agents, hook wiring, Godot LSP + bridge, README
plugins/pm/       how we track: status, next, row, week, report, handoff; scripts/pm.py; HANDOFF.md stays the one source
```
Stays, with the reason:
- `tools/`: pipeline gates and all tests. Builders, CI and check.sh call them from any checkout; hook scripts stay in tools/hooks (run.sh runs the session's own copy).
- `.agents/skills`: persona source; builders read it. `.opencode/agent`: generated from it.
- `.claude/settings.json`: deny rules, skillOverrides (plugins can't hold them), and the wiring of pre_spend, review_gate and session-start.
  A plugin that fails to load drops its hooks silently, so a money gate, a review gate and the check that warns of a missing plugin must not depend on one.
- `.claude/rules/code.md` (build_pipeline pastes that path), CLAUDE.md.

## One home per topic (row 24 applies it; anywhere else gets a pointer or nothing)
| Topic | Home |
|---|---|
| Rules for every chat | CLAUDE.md |
| Which worker does what | `builders` skill, Who does what |
| Build loop steps, prompt recipes | `builders` skill |
| Model evidence and calibration | models.md |
| Departments | WORKFLOW Routing (doc_check reads it) |
| Review tiers | WORKFLOW Protocols: Review |
| Limits | tools/builders.conf, WORKFLOW Limits |
| Feras's view of the system | docs/HOW_WE_WORK.md |
| Queue, Open points, the week | HANDOFF.md (the calendar copies the week) |
| Decisions | DECISIONS and its two splits; decisions-log for history |

## Rules for rows 22-25
- Branch: each chat makes its own worktree, `git merge --ff-only origin/system-v3` (row 22: branch from origin/main), and ends with `git push origin HEAD:system-v3`.
  Rows 22-24 never push to main and never run sync_main.sh. Rollback = don't merge.
- Run in auto mode. If auto mode refuses a change, above all to `.claude/settings.json`, stop and ask Feras with the exact diff. Never go around it.
- Weekly limit: at 50% or more, tell Feras and park the lowest item; M1 needs the rest of the week.
- Hard stop Mon 23:59 GMT+3. Late items park lowest first: audit follow-ups, tidy, row 20 leftovers. Row 25 always runs. Row 22 not green by Mon 12:00: take its fallback.
- A new design question stops and asks Feras with a pick. Max 3 fix rounds on one problem, then report.
- Every worker prompt passes `tools/prompt_check.py` once row 22 ships it; until then it follows the builders Prompt recipes.
- Each worker returns the one-line result; each chat ends with /handoff, a BRIEFING entry and the next prompt ready to paste.
- Every Sonnet prompt is one message starting `/goal <condition>` (Feras 10-31): it starts the work itself, up to 4,000 characters. The condition names the row's Done-when lines, the /handoff, the next prompt and a turn cap (40). The goal check reads only the chat, so every check's result is shown there. Stuck: AskUserQuestion, never a turn ending on a question. The row 25 and M1 prompts are Opus: no `/goal`.

## Verification (row 25 prints this table; targets, not results)
| Measure | Before | Target |
|---|---|---|
| Tests passing, none removed | 582 | >= 582 |
| Real bugs cross-review finds per run | 1.2 (5 runs) | tracked in docs/runs.csv |
| First-try gate PASS, Opus fixes per merged run | not tracked as a number | tracked; a worse trend blocks the merge |
| review-feras findings on what reaches Feras | 10 on the row 21 plan | no missed Feras pick, no repeat of docs/feras-notes.md |
| Calls in a /handoff | 8-13 | <= 4 |
| Main-chat calls in a Sonnet row | 120-260 (Opus chats) | <= 80 |
| Guard refusals a day | 29-44 | <= 5 |
| Worker routing tables | 5 | 1 |
| WORKFLOW.md | 23.5 KB | <= 14 KB |
| Skills listed twice in a worktree chat | all project skills | 0 |
| Start cost, fresh chat | ~88k | not higher |
| Coach score | 9/10 | 10/10 |
