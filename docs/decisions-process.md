# Decisions in force: process (not loaded at start; pointer in docs/DECISIONS.md)
Same line format as docs/DECISIONS.md. Log every new decision verbatim in docs/decisions-log.md too.

### Scope
- 2026-10-31 | docs/VISION.md OKed (the Art clock line updated) | Feras
- 2026-10-29 | Process audit P1 -> P2 -> P0 -> P3 -> P4 ran before game work (D12; done: rows 1, 12, 15, 16, 17 closed 10-28/30; row 18 system pass next, then M1, Feras 10-30); repo public until before the first public demo, then private (D16) | Feras
### Process
- 2026-10-27 | Claude is Feras's advisor (D21): checks requests against VISION, warns with a better default, maps ripples (docs/design/systems-map.md, a Ripple section in every spec), logs his repeated notes (docs/feras-notes.md), review-feras before anything reaches him; the Opus standard (D22) is in CLAUDE.md as judgment duties, each with its trigger, apart from the rules a tool enforces (row 1, 10-28) | Feras
- 2026-10-26 | Kaizen: Claude plans strategically, keeps VISION current, upgrades one tool, check, skill or doc each session | Feras
- 2026-10-28 | The lean process: CLAUDE.md Lean process (aims and their tie-break, the cheapest worker that does it well, Opus reviews every non-Opus output and owns what reaches Feras); delegate when the brief is shorter than the work and the risk is low or well tested, Opus writes small, risky machinery; judgment duties scale with the task; FIX_PASSES=2 free fix passes; USAGE rows record each merged run (10-28, Tokenomics review) | Feras
- 2026-10-28 | Departments = labels (option B; supersedes the 10-28 hybrid): a queue row's Dept names the skills, persona and reviewer the chat loads; the father works through builders, Haiku readers and review-* agents; an Opus child chat (own worktree) only for long, taste, MCP or builder-waiting work, as many as needed (builder caps and memory floor hold); no dept-* subagents (row 1 retires them) | Feras
- 2026-10-28 | Systems first: row 1 and whatever is urgent or hanging (unmerged runs, stale worktrees) before M1; overturns "M1 first" of the same day | Feras
- 2026-10-27 | A 4-lens review panel; ops-review every 5 sessions (D8); a Market and player department with success checks per milestone (D19); lesson lifecycle: add, promote to a check, or archive after 30 days (D9); triage 10-28: a test-enforced line goes to docs/lessons-archive.md naming its test, Godot traps to .claude/rules/code.md, builder-only lines to the builders skill | Feras
- 2026-10-28 | A tool's message is obeyed; milestone-only reports; HANDOFF = one queue, each row names its department and lane (builder by default) | Feras
- 2026-10-22 | Always-loaded notes <= 27 KB; caps in tools/doc_check.py (warns at 75%); one task, model, effort per chat | Feras
- 2026-10-22 | Log: never reword; struck (~~...~~) lines go to docs/decisions-archive.md | Claude
- 2026-10-31 | DECISIONS.md holds the rules most tasks need; process and tools lines live here and in docs/decisions-tools.md, read when the work needs them | Feras
